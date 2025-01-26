--[[
    Zonų kontrolės klientinė dalis
    
    Šis failas tvarko:
    - Daiktų naudojimo įvykius
    - Komunikaciją su serveriu
    - Vertimų sistemą
]]--

-- Globalūs kintamieji
local Translations = {}

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

-- Pagalbinė funkcija vertimams gauti
-- @param key: Vertimo raktas (pvz., "Messages.ZoneCaptured")
-- @return: Išverstas tekstas arba raktas, jei vertimas nerastas
function GetTranslation(key)
    if not next(Translations) then
        InitTranslations()
    end
    
    -- Padalina raktą į dalis (pvz., "Messages.ZoneCaptured" -> {"Messages", "ZoneCaptured"})
    local keys = {}
    for part in string.gmatch(key, "[^.]+") do
        table.insert(keys, part)
    end
    
    -- Ieško vertimo pagal raktą hierarchinėje struktūroje
    local translation = Translations
    for _, k in ipairs(keys) do
        if translation[k] then
            translation = translation[k]
        else
            -- Jei vertimas nerastas, grąžiname originalų raktą
            return key
        end
    end
    
    return translation
end

-- Inicializuojame vertimus kai skriptas paleidžiamas
Citizen.CreateThread(function()
    InitTranslations()
end)

--[[
    Daikto naudojimo įvykio apdorojimas
    
    Šis įvykis iškviečiamas, kai žaidėjas bando užimti zoną naudodamas daiktą.
    Įvykis patikrina ar daiktas tinkamas ir persiunčia užklausą serveriui.
    
    @param itemName: Naudojamo daikto pavadinimas
]]--
RegisterNetEvent("zonuKontrole:useItem")
AddEventHandler("zonuKontrole:useItem", function(itemName)
    -- Patikriname ar turime daikto pavadinimą
    if not itemName and Config.Debug then
        print("[ERROR] No item name provided to zonuKontrole:useItem")
        return
    end

    -- Debug informacija
    if Config.Debug then
        print("[DEBUG] Client received event: zonuKontrole:useItem with item:", itemName)
    end

    -- Siunčiame užklausą serveriui su žaidėjo ID ir daikto pavadinimu
    TriggerServerEvent("zonuKontrole:useItem", GetPlayerServerId(PlayerId()), itemName)
end)
