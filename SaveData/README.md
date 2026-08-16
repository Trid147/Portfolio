# Robust Player Data & Ability Dispatcher System

A production-ready server architecture for Roblox Studio built on top of **ProfileService**. It handles secure data persistence, exponential level-up progression, and abstract ability execution with built-in networking security.

## Key Features
* **ProfileService Integration:** Fully handles session locking, data reconciliation, and safe profile releasing to completely eliminate data loss or duplication glitches.
* **Exploit Protection (Rate Limiting):** Includes a secure client-to-server validation system that tracks RemoteEvent requests per second, instantly dropping malicious spam attempts.
* **Abstract Ability Dispatcher:** Dynamically `require()`s weapon/ability modules dynamically via `pcall` threads, separating data management from gameplay logic.
* **Auto-Scaling Progression:** Uses a custom mathematical exponential curve to calculate required experience points per level, supporting immediate multi-level jumps and visual/audio replication.
* **Memory Leak Cleanup:** Actively purges connection tokens and active user cooldown objects when players leave the server runtime.

## Tracked Data Structure
```lua
local ProfileTemplate = {
    Version = 1,
    Coins = 0,
    Level = 1,
    Experience = 0,
    TotalAbilitiesUsed = 0,
    PlayTime = 0
}
```

## Installation & Architecture
Place `SaveData.luau` inside `ServerScriptService`. 

### Prerequisites:
1. **ProfileService** module must be located directly inside `ServerScriptService`.
2. A `ReplicatedStorage.Events.AbilityRemote` RemoteEvent must exist.
3. An `Abilities` folder filled with modular ability scripts inside `ReplicatedStorage`.
