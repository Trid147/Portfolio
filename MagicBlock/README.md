# OOP Magic Block System

A highly optimized, object-oriented custom block system for Roblox Studio written in Luau. It utilizes metatables and operator overloading to perform dynamic in-game physical interactions.

## Key Features
* **Operator Overloading:** Uses `__add`, `__sub`, `__mul` metamethods to merge, split, and scale blocks seamlessly using standard math operators (e.g., `blockA + blockB`).
* **Dynamic Elements:** Built-in configuration system supporting 4 elements (**Fire, Ice, Electricity, Void**) with custom materials, colors, and unique Instance effects.
* **Memory Management:** Implements weak tables (`__mode = "k"`) in the block registry to prevent memory leaks and handle garbage collection efficiently.
* **Luau Typing:** Fully typed with `--!strict` capabilities for safe and predictable behavior.

## Performance & Behavior
* **`__eq` / `__lt`:** Compares blocks based on their calculated geometric volume.
* **`__call`:** Allows invoking the block object as a function (`block()`) to trigger a physics-based jump.
* **Custom Cleaning:** Includes a comprehensive `:Destroy()` pipeline that safely handles instance destruction, unlinking from the registry, and cleaning up references.

## Installation & Usage
Place `MagicBlock.lua` into `ReplicatedStorage` (if used by both sides) or `ServerScriptService` (for server-only logic).

```lua
local MagicBlock = require(path.to.MagicBlock)

-- Create a shiny base block
local block = MagicBlock.new("FireCube", Vector3.new(0, 10, 0), Vector3.new(4, 4, 4), Color3.fromRGB(255, 0, 0))

-- Morph it into a Void element
block:SetElement("Void")

-- Make it jump via __call
block()
```
