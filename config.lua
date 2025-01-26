Config = {}

Config.Debug = false  -- Enable/disable debug messages

Config.DefaultLanguage = 'en' -- Default language

-- Discord Webhook konfigūracija
Config.DiscordWebhook = ''  -- Discord webhook URL

Config.Tax = {
    amount = 1.0, -- Amount of money charged from players
    itemCheck = {
        enabled = false, -- Whether to check items before charging tax
        requiredItem = "gangitem" -- Which item must be in inventory
    },
    conversion = {
        type = "item",  -- Possible values: "item" or "money"
        itemName = "dirty_money", -- If type = "item", which item to convert collected taxes to        
        -- If type = "item", collected taxes are converted to items
        -- If type = "money", taxes are transferred directly to money
        percentage = 100, -- What percentage of collected amount the zone controller receives        
    },
    minPlayersForReward = 2 -- Minimalus žaidėjų skaičius serveryje, kad būtų duodama druskos
}

Config.Zones = {
    {
        id = 1, 
        x = 221.6, 
        y = 1937.04, 
        z = 205.02, 
        radius = 100.0,  
        requiredItem = {
            name = 'goldnugget', 
            amount = 1,
            remove = true -- Whether to remove item after zone capture
        },
        paymentInterval = 15, -- Payment interval in minutes
        cooldown = {
            enabled = true,
            time = 300 -- Cooldown time in seconds (300 = 5 minutes)
        },
        rewards = { -- Additional rewards for zone control
            enabled = true,
            items = {
                {name = "salt", amount = 1}, -- Additional reward for zone control
                -- {name = "water", amount = 2}, -- Can add as many items as needed
            }
        }
    }
}

--- Anyone can use this command to free the zone when they are in the zone
Config.Commandfreezone = 'free'

Config.Jobs = {
    ['valsheriff'] = true,
    ['police'] = true,
    ['marshal'] = true,
}

Config.Commands = {
    capture = {
        commands = {            
            "alertpolice", 
            "calert"
        },
        delay = 1000 -- delay between commands
    }
}

Config.Languages = {
    ['en'] = {
        Messages = {
            ZoneCaptured = "Zone successfully captured!",
            MissingItem = "You don't have the required item!",
            ZoneCleared = "Zone was cleared by the sheriff!",        
        },
        Tips = {
            PayTax = "You paid $%.2f to bandits for %s protection.",
            NotEnoughMoney = "You don't have enough money to pay the tax.",
            ReceivedPayment = "You received $%.2f for zone control!",
            ReceivedReward = "You received %dx %s and $%.2f for zone control!",
            FreeZoneInfo = "If you want to free the zone, type /freezone",
            NoNearbyZone = "There is no zone nearby that you could capture.",
            LostZoneControl = "You lost zone control!",
            WaitBeforeCapture = "You need to wait %d seconds before capturing the zone again!",
            NoZoneControl = "You don't have any zone control.",
            ReleasedControl = "You released zone control!",
            PaymentInfo = "You received $%.2f (%.0f%% from $%.2f) for zone control!",
            ReceivedMultipleRewards = "You received reward items: %s",
            NoNearbyZoneToFree = "There is no captured zone nearby that you could free.",
            NoRequiredItemForTax = "You don't have %s, so the tax was not charged.",            
        },
        Items = {
            Salt = "Salt"
        }
    },
    ['lt'] = {
        Messages = {
            ZoneCaptured = "Zona užimta!",
            MissingItem = "Neturite reikiamo daikto!",
            ZoneCleared = "Zona buvo išlaisvinta šerifo!",        
        },
        Tips = {
            PayTax = "Sumokejote $%.2f banditams už %s apsaugą.",
            NotEnoughMoney = "Neturite pakankamai pinigų mokėti mokestį banditams.",
            ReceivedPayment = "Gavote $%.2f už zonos kontrolę!",
            ReceivedReward = "Gavote %dx %s ir $%.2f už zonos kontrolę!",
            FreeZoneInfo = "Jeigu norite išslaisvinti zoną, parašykite komandą /islaisvintizona",
            NoNearbyZone = "Netoliese nėra zonos, kurią galėtumėte užimti.",
            LostZoneControl = "Praradote zonos kontrolę!",
            WaitBeforeCapture = "Turite palaukti %d sekundžių prieš vėl užimant zoną!",
            NoZoneControl = "Neturite jokios zonos kontrolės.",
            ReleasedControl = "Zona Laisva!",
            PaymentInfo = "Gavote $%.2f (%.0f%% nuo $%.2f) už zonos kontrolę!",
            ReceivedMultipleRewards = "Gavote atlygio daiktus: %s",
            NoNearbyZoneToFree = "Netoliese nėra užimtos zonos, kurią galėtumėte išlaisvinti.",
            NoRequiredItemForTax = "Neturite %s, todėl mokestis nebuvo nuskaičiuotas.",            
        },
        Items = {
            Salt = "Druskos"
        }
    }
}

