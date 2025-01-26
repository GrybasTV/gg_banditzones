# 🔥 Bandit Zones 🔥 
**Dynamic Zone Control for RedM RP Servers**  
*"Where Control Means Power—and Everyone Pays the Price."*

---

## 📜 Overview
**Bandit Zones** transforms your RedM server into a living frontier of conflict. Bandits tax civilians, sheriffs fight to restore order, and territories constantly shift hands. No more stale roleplay—**every action has consequences**.

---

## ⚡ Features
- **Dynamic Zone Control**: Claim zones, tax civilians, and defend your turf.
- **Civilian Suffering**: Lose money automatically if bandits control your area.
- **Law Enforcement Pressure**: Sheriffs must patrol or face civilian riots.
- **Gang-Exclusive Mode**: Restrict control to factions using gang tokens.
- **Discord Integration**: Real-time alerts for captures, taxes, and sheriff actions.
- **Fully Configurable**: Adjust taxes, rewards, zones, and rules via `config.lua`.

---

## 🛠️ Installation
1. Ensure you have **[VORP Core](https://github.com/VORPCORE/VORP-Core)** and **[VORP Inventory](https://github.com/VORPCORE/VORP-Inventory)** installed.
2. Clone this repository into your `resources` folder.
3. Add the following to your `server.cfg`:
   ```lua
   ensure vorp_core
   ensure vorp_inventory
   ensure BanditZones

    Configure settings in config.lua (see Configuration).

⚙️ Configuration
Key Settings in config.lua:
lua
Copy


```
Config = {
  Debug = false,
  DefaultLanguage = "en", -- Supports "en" and "lt"
  CommandFreeZone = "free", -- Command to free a zone
  Tax = {
    amount = 1.0, -- Money deducted from civilians
    itemCheck = { enabled = false, requiredItem = "gangitem" }, -- Require items to tax
    conversion = { type = "item", itemName = "dirtymoney", percentage = 100 }, -- Convert taxes to items/money
    minPlayersForReward = 2 -- Minimum online players to grant rewards
  },
  Zones = {
    -- Example zone:
    {
      id = 1,
      x = 221.6, y = 1937.04, z = 205.02, -- Zone coordinates
      radius = 100.0, -- Control radius
      requiredItem = { name = "goldnugget", amount = 1, remove = true }, -- Item to capture
      rewards = { enabled = true, items = { { name = "salt", amount = 1 } } }
    }
  },
  Jobs = { -- Jobs allowed to free zones (e.g., law enforcement)
    ["marshal"] = true,
    ["police"] = true

```    

🎮 Usage
Bandits 🏴‍☠️

    Use a gold nugget (or custom item) to capture a zone.

    Automatically tax civilians in the area.

    Defend your zone from sheriffs and rival gangs.

Civilians 👨🌾

    Lose money if bandits control your zone.

    Fight back with /free or alert sheriffs using /calert.

Sheriffs ⚖️

    Patrol zones—proximity automatically frees them.

    Ignore zones at your peril: civilians will riot!

💬 Discord Integration

    Set your webhook in config.lua:
    lua
    Copy

    Config.DiscordWebhook = "YOUR_WEBHOOK_URL"

    Receive alerts for:

        Zone captures/frees

        Tax collections

        Sheriff inactivity

Discord Example
🚀 Optional Add-Ons

    "Protection Racket": Let civilians pay bandits to avoid taxes.

    "Vigilante Perks": Reward civilians who free zones with temporary buffs.

    Bounty System: Auto-place bounties on bandits holding zones too long.

❓ Support & Contribution

    Issues: Report bugs here.

    Contributions: PRs welcome! Follow the existing code style.

    Discord: Join our support server.

📄 License

MIT License - See LICENSE for details.
Copy


---

**🔥 Download now and let the chaos begin!**  
*Perfect for servers craving drama, politics, and Wild West vendettas.*

Discord Support: 
https://discord.gg/KxSBTYr5wS
