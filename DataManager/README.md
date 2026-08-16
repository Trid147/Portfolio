# Interactive DataManager & Rank Progression System

A comprehensive server script that bridges data persistence via **ProfileStore** with interactive gameplay elements, tweened visual feedback, and a automated multi-tier rank progression mechanism.

## Key Features
* **ProfileStore Session Management:** Implements modern data session handling (`StartSessionAsync`, `EndSessionAsync`) with a auto-reconciliation fallback for new profiles.
* **Click-to-Earn Gameplay Logic:** Seamlessly handles user inputs via `ClickDetector`, complete with server-side cooldown tracking and exploitation safeguards.
* **TweenService Visual Feedback:** Animates interacting environmental objects (`ClickPart`) using smooth, asynchronous color shifts.
* **Dynamic Rank Progression:** Automatically evaluates player experience point thresholds against a linear rank array (`Beginner` to `Legend`) to scale player statuses.
* **Server Shutdown Safeguard:** Connects to `game:BindToClose` to force-save all active player session data immediately during critical server crashes or updates.

## Ranks Structure
```lua
local Ranks = {
    "Beginner", "Elementary", "Intermediate", 
    "Advanced", "Expert", "Master", "Legend"
}
```

## Setup Instructions
1. Place `DataManager.luau` inside `ServerScriptService`.
2. Ensure you have the `ProfileStore` module script located directly inside `ServerScriptService`.
3. Create a Part named `ClickPart` in `Workspace`.
4. Insert a `ClickDetector` (named `ClickDetector`), a `Sound` (named `Sound`), and an unanchored state inside that `ClickPart`.
