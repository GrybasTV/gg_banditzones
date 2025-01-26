fx_version 'adamant'
game 'rdr3'

lua54 'yes'

author 'GrybasTv'
description 'Banditu Skriptas'
version '1.0.1'

rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

-- Bendri skriptai (vykdomi tiek serveryje, tiek kliente)
shared_scripts {    
    'config.lua'  -- Konfigūracijos failas  
}

-- Serverio skriptai
server_scripts {
    'server.lua'   -- Serverio logika
}

-- Kliento skriptai
client_scripts {   
    'client.lua'   -- Kliento logika
}

-- Priklausomybės
dependencies {
    'vorp_core',       -- Reikalingas VORP Core framework
    'vorp_inventory'   -- Reikalingas VORP Inventory sistema    
}

-- Failai, kurie nebus užšifruoti
escrow_ignore {
    'config.lua'
}