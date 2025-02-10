--[[
    Zonų kontrolės serverio dalis
    
    Šis failas tvarko:
    - Zonų užėmimą ir kontrolę
    - Mokesčių rinkimą
    - Atlygio išmokėjimą
    - Sąveiką su policija
    - Vertimų sistemą
    - Discord pranešimus
]]--

-- Globalūs kintamieji
local Translations = {}
local ZoneControl = {} -- Saugo kas kontroliuoja kiekvieną zoną
local ZoneTimers = {} -- Saugo zonų mokėjimo laikmačius
local ZoneCooldowns = {} -- Saugo zonų užėmimo vėlinimus

-- Inicializuojame VorpCore
local VorpCore = {}
TriggerEvent("getCore", function(core)
    VorpCore = core
end)

-- Inicializuojame inventoriaus API
local VorpInv = exports.vorp_inventory:vorp_inventoryApi()

-- Pagalbinė funkcija vertimams inicializuoti
local function InitTranslations()
    local language = Config.DefaultLanguage or "lt"
    
    if Config.Languages[language] then
        Translations = Config.Languages[language]
    else
        print("[ERROR] Kalba nerasta. Naudojama lietuvių kalba.")
        Translations = Config.Languages["lt"]
    end
end

-- Debug pranešimų spausdinimo funkcija
local function DebugPrint(message, ...)
    if Config.Debug then
        print(string.format(message, ...))
    end
end

-- Pagalbinė funkcija vertimams gauti
function GetTranslation(key)
    if not next(Translations) then
        InitTranslations()
    end
    
    local keys = {}
    for part in string.gmatch(key, "[^.]+") do
        table.insert(keys, part)
    end
    
    local translation = Translations
    for _, k in ipairs(keys) do
        if translation[k] then
            translation = translation[k]
        else
            return key
        end
    end
    
    return translation
end

-- Pagalbinė funkcija siųsti pranešimus į Discord
local function SendToDiscord(title, message, color)
    if Config.DiscordWebhook == "" or Config.DiscordWebhook == "ĮDĖKITE_SAVO_WEBHOOK_URL_ČIA" then
        return
    end

    local embed = {
        {
            ["title"] = title,
            ["description"] = message,
            ["type"] = "rich",
            ["color"] = color,
            ["footer"] = {
                ["text"] = os.date("%Y-%m-%d %H:%M:%S")
            }
        }
    }

    PerformHttpRequest(Config.DiscordWebhook, function(err, text, headers) end, 'POST', 
        json.encode({username = "Banditų Sistema", embeds = embed}), 
        { ['Content-Type'] = 'application/json' })
end

-- Send a message about zone capture
local function SendZoneCaptureMessage(playerId, zoneId)
    local User = VorpCore.getUser(playerId)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local playerName = Character.firstname .. ' ' .. Character.lastname
    local message = string.format("**Player:** %s\n**Zone:** %d\n**Coordinates:** %.2f, %.2f", 
        playerName, 
        zoneId,
        Config.Zones[zoneId].x,
        Config.Zones[zoneId].y
    )
    
    SendToDiscord("🎯 Zone Captured", message, 65280) -- Green color
end

-- Send a message about zone being freed
local function SendZoneFreeMessage(playerId, zoneId, reason)
    local User = VorpCore.getUser(playerId)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local playerName = Character.firstname .. ' ' .. Character.lastname
    local message = string.format("**Player:** %s\n**Zone:** %d\n**Reason:** %s", 
        playerName, 
        zoneId,
        reason
    )
    
    SendToDiscord("🔓 Zone Freed", message, 15158332) -- Red color
end

-- Send a message about tax collection
local function SendTaxCollectionMessage(playerId, zoneId, amount, rewards)
    local User = VorpCore.getUser(playerId)
    if not User then return end
    
    local Character = User.getUsedCharacter
    local playerName = Character.firstname .. ' ' .. Character.lastname
    local onlineCount = #GetPlayers()
    
    -- Format rewards list
    local rewardsText = ""
    if rewards and #rewards > 0 then
        for _, reward in ipairs(rewards) do
            local itemName = GetTranslation("Items." .. reward.name) or reward.name
            rewardsText = rewardsText .. string.format("\n• %dx %s", reward.amount, itemName)
        end
    end
    
    local message = string.format(
        "**Controller:** %s\n**Zone:** %d\n**Money Received:** $%.2f%s\n**Players Online:** %d", 
        playerName,
        zoneId,
        amount,
        rewardsText,
        onlineCount
    )
    
    SendToDiscord("💰 Tax Collection", message, 15844367) -- Gold color
end

-- Patikriname ar VorpCore tinkamai inicializuotas
if not VorpCore or not VorpCore.getUser then
    DebugPrint("[ERROR] VorpCore is not properly initialized")
    return
end

-- Inicializuojame vertimus kai skriptas paleidžiamas
InitTranslations()

-- Mokėjimų funkcija
function AtliktiMokejima(zoneId, playerId)
    -- Patikriname ar zona vis dar kontroliuojama
    if not ZoneControl[zoneId] then
        return
    end

    -- Gauname zonos konfigūraciją
    local zone = Config.Zones[zoneId]
    if not zone then
        DebugPrint("[ERROR] Zone not found with ID: %d", zoneId)
        return
    end

    -- Patikriname ar valdytojas vis dar serveryje
    local owner = VorpCore.getUser(playerId)
    if not owner then
        ZoneControl[zoneId] = nil
        DebugPrint("[INFO] Player ID: %d disconnected. Zone ID: %d is no longer controlled", playerId, zoneId)
        return
    end

    -- Mokesčių rinkimo logika
    local totalPayment = 0
    local onlinePlayers = GetPlayers()

    -- Einame per visus žaidėjus ir renkame mokesčius
    for _, player in ipairs(onlinePlayers) do
        if tonumber(player) ~= tonumber(playerId) then -- Nerenkame mokesčių iš zonos valdytojo
            local user = VorpCore.getUser(tonumber(player))
            if user then
                local character = user.getUsedCharacter
                
                -- Tikriname ar žaidėjas turi reikiamą daiktą (jei įjungta)
                local shouldPayTax = true
                if Config.Tax.itemCheck.enabled then
                    local itemCount = VorpInv.getItemCount(tonumber(player), Config.Tax.itemCheck.requiredItem)
                    shouldPayTax = itemCount > 0
                    if not shouldPayTax then
                        DebugPrint("[INFO] Player ID: %d does not have required item %s for tax", 
                            tonumber(player), Config.Tax.itemCheck.requiredItem)
                        TriggerClientEvent("vorp:Tip", tonumber(player), 
                            string.format(GetTranslation("Tips.NoRequiredItemForTax"), 
                                Config.Tax.itemCheck.requiredItem), 
                            5000)
                    end
                end

                -- Renkame mokestį jei žaidėjas turi pakankamai pinigų
                if shouldPayTax and character.money >= Config.Tax.amount then
                    character.removeCurrency(0, Config.Tax.amount)
                    totalPayment = totalPayment + Config.Tax.amount
                    TriggerClientEvent("vorp:Tip", tonumber(player), 
                        string.format(GetTranslation("Tips.PayTax"), 
                            Config.Tax.amount, 
                            "zonos"),
                        5000)
                else
                    if shouldPayTax then
                        DebugPrint("[INFO] Player ID: %d does not have enough money to pay the tax", playerId)
                    end
                end
            end
        end
    end

    -- Apskaičiuojame galutinę išmokos sumą
    local finalPayment = math.floor(totalPayment * (Config.Tax.conversion.percentage / 100))
    
    -- Išmokame atlygį zonos valdytojui
    local ownerCharacter = owner.getUsedCharacter
    if Config.Tax.conversion.type == "item" then
        VorpInv.addItem(playerId, Config.Tax.conversion.itemName, finalPayment)
    else
        ownerCharacter.addCurrency(0, finalPayment)
    end

    -- Pranešame apie gautą atlygį
    TriggerClientEvent("vorp:Tip", playerId, 
        string.format(GetTranslation("Tips.PaymentInfo"), 
            finalPayment, 
            Config.Tax.conversion.percentage, 
            totalPayment), 
        5000)

    -- Išduodame papildomus atlygio daiktus (jei įjungta)
    local receivedRewards = {}
    if zone.rewards and zone.rewards.enabled then
        -- Patikriname ar yra pakankamai žaidėjų serveryje
        local onlineCount = #GetPlayers()
        if onlineCount >= Config.Tax.minPlayersForReward then
            for _, reward in ipairs(zone.rewards.items) do
                VorpInv.addItem(playerId, reward.name, reward.amount)
              local itemName = GetTranslation("Items." .. (reward.name:gsub("^%l", string.upper))) or reward.name
                -- Įrašome išverstą daikto pavadinimą į rewards masyvą
                table.insert(receivedRewards, {name = itemName, amount = reward.amount})
                TriggerClientEvent("vorp:Tip", playerId, 
                    string.format(GetTranslation("Tips.ReceivedReward"), 
                        reward.amount, 
                        itemName,
                        finalPayment), 
                    5000)
                Citizen.Wait(1000)
            end
        else
            -- Pranešame žaidėjui, kad nepakanka žaidėjų
            TriggerClientEvent("vorp:Tip", playerId, 
                string.format(GetTranslation("Tips.NotEnoughPlayers"), 
                    Config.Tax.minPlayersForReward), 
                5000)
        end
        
        Citizen.Wait(2000)
        TriggerClientEvent("vorp:Tip", playerId, GetTranslation("Tips.FreeZoneInfo"), 10000)
    end

    -- Nustatome kitą mokėjimo laikmatį
    ZoneTimers[zoneId] = Citizen.SetTimeout(zone.paymentInterval * 60000, function()
        AtliktiMokejima(zoneId, playerId)
    end)

    -- Siunčiame pranešimą tik jei mokėjimas buvo sėkmingas
    if finalPayment > 0 then
        SendTaxCollectionMessage(playerId, zoneId, finalPayment, receivedRewards)
    end
    
    return { success = true, amount = finalPayment, rewards = receivedRewards }
end

-- Daikto naudojimo registracija
VorpInv.RegisterUsableItem("goldnugget", function(data)
    -- Gauname žaidėjo duomenis
    local _source = data.source
    local User = VorpCore.getUser(_source)
    
    if not User then
        DebugPrint("[ERROR] Failed to get user object")
        return
    end
    
    local Character = User.getUsedCharacter
    if not Character then
        DebugPrint("[ERROR] Failed to get active character")
        return
    end

    local source = _source
    local playerCoords = GetEntityCoords(GetPlayerPed(source))

    -- Ieškome artimiausios zonos
    local zoneId = nil
    local currentZone = nil
    for id, zone in pairs(Config.Zones) do
        local distance = #(vector3(zone.x, zone.y, zone.z) - playerCoords)
        if distance <= zone.radius then
            zoneId = id
            currentZone = zone
            break
        end
    end

    -- Patikriname ar žaidėjas yra zonoje
    if not zoneId or not currentZone then
        TriggerClientEvent("vorp:Tip", source, GetTranslation("Tips.NoNearbyZone"), 5000)
        return
    end

    -- Pranešame buvusiam savininkui apie zonos praradimą
    if ZoneControl[zoneId] then
        local previousOwner = ZoneControl[zoneId]
        if previousOwner ~= source then
            TriggerClientEvent("vorp:Tip", previousOwner, GetTranslation("Tips.LostZoneControl"), 5000)
        end
    end

    -- Tikriname zonos užėmimo vėlinimą
    if currentZone.cooldown and currentZone.cooldown.enabled then
        if ZoneCooldowns[zoneId] and GetGameTimer() < ZoneCooldowns[zoneId] then
            local remainingTime = math.ceil((ZoneCooldowns[zoneId] - GetGameTimer()) / 1000)
            TriggerClientEvent("vorp:Tip", source, 
                string.format(GetTranslation("Tips.WaitBeforeCapture"), remainingTime), 
                5000)
            return
        end

        -- Nustatome naują vėlinimą
        ZoneCooldowns[zoneId] = GetGameTimer() + (currentZone.cooldown.time * 1000)
    end

    -- Užimame zoną
    ZoneControl[zoneId] = source
    TriggerClientEvent("vorp:Tip", source, GetTranslation("Messages.ZoneCaptured"), 5000)
    TriggerClientEvent("zonuKontrole:useItem", source, "goldnugget")
    TriggerClientEvent("vorp_inventory:CloseInv", source)
    
    -- Pašaliname daiktą jei reikia
    if currentZone.requiredItem.remove then
        VorpInv.subItem(source, currentZone.requiredItem.name, currentZone.requiredItem.amount)
    end

    -- Siunčiame pranešimą apie zonos užėmimą
    SendZoneCaptureMessage(source, zoneId)

    -- Nustatome pirmąjį mokėjimą po 10 sekundžių
    ZoneTimers[zoneId] = Citizen.SetTimeout(10000, function()
        AtliktiMokejima(zoneId, source)
    end)
end)

-- Policijos patruliavimo gija
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000) -- Tikriname kas 5 sekundes
        for _, zone in pairs(Config.Zones) do
            local players = GetPlayers()
            for _, player in ipairs(players) do
                local user = VorpCore.getUser(tonumber(player))
                if user then
                    local character = user.getUsedCharacter
                    -- Tikriname ar žaidėjas yra policijos pareigūnas
                    if Config.Jobs[character.job] then
                        local playerCoords = GetEntityCoords(GetPlayerPed(tonumber(player)))
                        local distance = #(vector3(zone.x, zone.y, zone.z) - playerCoords)

                        -- Jei pareigūnas yra zonoje, išlaisviname ją
                        if distance <= zone.radius and ZoneControl[zone.id] then
                            ZoneControl[zone.id] = nil
                            TriggerClientEvent("vorp:Tip", -1, GetTranslation("Messages.ZoneCleared"), 5000)                            
                            DebugPrint("[INFO] Zone #%d was cleared by the sheriff", zone.id)
                        end
                    end
                end
            end
        end
    end
end)

-- Zonos išlaisvinimo komanda
RegisterCommand(Config.Commandfreezone, function(source, args, rawCommand)
    local source = tonumber(source)
    local User = VorpCore.getUser(source)
    
    if not User then
        DebugPrint("[ERROR] Failed to get user object")
        return
    end

    local Character = User.getUsedCharacter
    if not Character then
        DebugPrint("[ERROR] Failed to get active character")
        return
    end

    -- Ieškome zonos, kurią žaidėjas gali išlaisvinti
    local playerCoords = GetEntityCoords(GetPlayerPed(source))
    local zoneToClear = nil

    -- Pirma tikriname ar žaidėjas yra zonoje
    for zoneId, zone in pairs(Config.Zones) do
        local distance = #(vector3(zone.x, zone.y, zone.z) - playerCoords)
        if distance <= zone.radius then
            if ZoneControl[zoneId] then
                zoneToClear = zoneId
                break
            end
        end
    end

    -- Jei nerado zonos pagal poziciją, tikriname ar žaidėjas valdo kokią nors zoną
    if not zoneToClear then
        for zoneId, ownerId in pairs(ZoneControl) do
            if ownerId == source then
                zoneToClear = zoneId
                break
            end
        end
    end

    -- Jei zona nerasta, pranešame žaidėjui
    if not zoneToClear then
        TriggerClientEvent("vorp:Tip", source, GetTranslation("Tips.NoZoneControl"), 5000)
        return
    end

    -- Pranešame buvusiam savininkui
    local previousOwner = ZoneControl[zoneToClear]
    if previousOwner and previousOwner ~= source then
        TriggerClientEvent("vorp:Tip", previousOwner, GetTranslation("Tips.LostZoneControl"), 5000)
    end

    -- Pašaliname zonos kontrolę
    ZoneControl[zoneToClear] = nil
    TriggerClientEvent("vorp:Tip", source, GetTranslation("Tips.ReleasedControl"), 5000)
    SendZoneFreeMessage(source, zoneToClear, "Savanoriškas atsisakymas")
    DebugPrint("[INFO] Player ID: %d freed zone ID: %d", source, zoneToClear)
end, false)

-- Atnaujinu zonos išlaisvinimo komandą
RegisterCommand(Config.Commandfreezone, function(source, args, rawCommand)
    local result = callback(source, args, raw)
    if result and result.success then
        SendZoneFreeMessage(source, result.zoneId, "Savanoriškas atsisakymas")
    end
    return result
end)

-- Atnaujinu policijos patruliavimo giją
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000)
        for _, zone in pairs(Config.Zones) do
            local players = GetPlayers()
            for _, player in ipairs(players) do
                local user = VorpCore.getUser(tonumber(player))
                if user then
                    local character = user.getUsedCharacter
                    if Config.Jobs[character.job] then
                        local playerCoords = GetEntityCoords(GetPlayerPed(tonumber(player)))
                        local distance = #(vector3(zone.x, zone.y, zone.z) - playerCoords)

                        if distance <= zone.radius and ZoneControl[zone.id] then
                            local previousOwner = ZoneControl[zone.id]
                            ZoneControl[zone.id] = nil
                            TriggerClientEvent("vorp:Tip", -1, GetTranslation("Messages.ZoneCleared"), 5000)
                            SendZoneFreeMessage(previousOwner, zone.id, "Policijos išlaisvinimas")
                            DebugPrint("[INFO] Zone #%d was cleared by the sheriff", zone.id)
                        end
                    end
                end
            end
        end
    end
end)

----- Discord webhook -----


