-- Connected Discord-GitHub | Discord: Trid Doe (trid147) | Roblox: Great_Warrior147 | Roblox Scripter Verification

local MagicBlock = {}
MagicBlock.__index = MagicBlock

--part and object connection
local blocksRegistry = setmetatable({}, {__mode = "k"})

--a special config for elements
const ELEMENT_CONFIG = {
	["Fire"] = {
		Material = Enum.Material.CrackedLava,
		Color = Color3.fromRGB(255, 85, 0),
		CreateEffect = function(part)
			local fire = Instance.new("Fire")
			fire.Size = part.Size.Magnitude * 1.5
			fire.Parent = part
		end
	},
	["Ice"] = {
		Material = Enum.Material.Ice,
		Color = Color3.fromRGB(170, 255, 255),
		CreateEffect = function(part)
			part.Transparency = 0.2
		end
	},
	["Electricity"] = {
		Material = Enum.Material.Neon,
		Color = Color3.fromRGB(255, 255, 0),
		CreateEffect = function(part)
			local sparkles = Instance.new("Sparkles")
			sparkles.SparkleColor = Color3.fromRGB(255, 255, 127)
			sparkles.Parent = part
		end
	},
	["Void"] = {
		Material = Enum.Material.Glass,
		Color = Color3.fromRGB(30, 0, 40),
		CreateEffect = function(part)
			local emitter = Instance.new("ParticleEmitter")
			emitter.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
			emitter.Size = NumberSequence.new(1)
			emitter.Speed = NumberRange.new(1, 3)
			emitter.Rate = 20
			emitter.Parent = part
		end
	}
}

--function to get block's volume
local function getVolume(block): number
	local size = block.Part.Size
	return size.X * size.Y * size.Z
end

--creates new magic block
function MagicBlock.new(name: string, position: Vector3, size: Vector3, color: Color3)
	local self = setmetatable({}, MagicBlock)
	
	self.Part = Instance.new("Part")
	self.Part.Name = name
	self.Part.Size = size
	self.Part.Position = position
	self.Part.Color = color
	self.Part.Material = Enum.Material.Neon
	self.Part.Parent = workspace
	
	self.Part:SetAttribute("IsMagicBlock", true)
	self.IsDestroyed = false
	
	blocksRegistry[self.Part] = self
	
	self:InitTouch()
	
	return self
end

--merges two magic blocks together
function MagicBlock.__add(blockA, blockB): any
	print("merging two blocks together")
	
	local NewName = "Merged block"
	local NewPos = (blockA.Part.Position + blockB.Part.Position) / 2 + Vector3.new(0,2,0)
	local NewSize = blockA.Part.Size + blockB.Part.Size
	local NewColor = blockA.Part.Color:Lerp(blockB.Part.Color, 0.5)
	
	blocksRegistry[blockA.Part] = nil
	blocksRegistry[blockB.Part] = nil
	
	blockA:Destroy()
	blockB:Destroy()
	
	local MergedBlock = MagicBlock.new(NewName, NewPos, NewSize, NewColor)
	return MergedBlock
end

--splits two magic blocks together
function MagicBlock.__sub(block, _): any
	print("splitting two blocks together")
	
	local NewName = "Split block"
	local NewPos = block.Part.Position
	local NewSize = block.Part.Size / 2
	local NewColor = block.Part.Color
	
	local offset = Vector3.new(block.Part.Size.X / 2, 0, 0)
	local PosA = block.Part.Position - offset
	local PosB = block.Part.Position + offset
	
	local NameA = `{NewName} A`
	local NameB = `{NewName} B`
	
	block:Destroy()
	
	local blockA = MagicBlock.new(NameA, PosA, NewSize, NewColor)
	local blockB = MagicBlock.new(NameB, PosB, NewSize, NewColor)
	
	return {blockA, blockB}
end

--multiplies the magic block
function MagicBlock.__mul(block, multiplier: number): any
	print("the block multiplied")
	
	if block.Part then
		local OldSize = block.Part.Size
		local NewSize = OldSize * multiplier
		
		block.Part.Size = NewSize
		
		local heightDifference = (NewSize.Y - OldSize.Y) / 2
		block.Part.Position = block.Part.Position + Vector3.new(0, heightDifference, 0)
	end
	
	return block
end

--compares two magic blocks
function MagicBlock.__eq(blockA, blockB): boolean
	print("comparing equality of two blocks")
	
	local volumeA = getVolume(blockA)
	local volumeB = getVolume(blockB)
	
	if volumeA == volumeB then
		return true
	else
		return false
	end
end

--compares two magic blocks
function MagicBlock.__lt(blockA, blockB): boolean
	print("comparing less the two of blocks")
	
	local volumeA = getVolume(blockA)
	local volumeB = getVolume(blockB)
	
	if volumeA < volumeB then
		return true
	else
		return false
	end
end

--makes magic block hop
function MagicBlock.__call(self): any
	self.Part.AssemblyLinearVelocity = Vector3.new(0, 50, 0)
	print("the block jumped")
end

--runs when magic block is printed
function MagicBlock.__tostring(self): string
	local printString = `MAGIC BLOCK: {self.Part.Name}`
	return printString
end

--sets an element for the block
function MagicBlock:SetElement(element: string): any
	if not self.Part then return end
	
	local config = ELEMENT_CONFIG[element]
	if not config then
		warn("invalid element")
		return
	end
	
	for _, i in self.Part:GetChildren() do
		i:Destroy()
	end
	self.Part.Transparency = 0
	
	self.Part.Material = config.Material
	self.Part.Color = config.Color
	
	config.CreateEffect(self.Part)
	print(`{self.Part.Name} is now a {element} block`)
end

--explodes the block
function MagicBlock:Explode(power: number): any
	if not self.Part then return end
	
	power = power or 10
	
	local explosion = Instance.new("Explosion")
	explosion.Position = self.Part.Position
	
	explosion.BlastRadius = power * 1.5
	explosion.BlastPressure = power * 50000
	
	explosion.Parent = workspace
	
	print(`{self.Part.Name} exploded`)
	self:Destroy()
end

--an init function for touch
function MagicBlock:InitTouch()
	if not self.Part then return end
	
	local isTouching = false
	
	self.Part.Touched:Connect(function(otherPart)
		if isTouching then return end
		isTouching = true
		
		self:OnTouch(otherPart)
		
		task.wait(0.25)
		isTouching = false
	end)
end

--function that runs when the block touches something
function MagicBlock:OnTouch(otherPart: Part)
	if otherPart:GetAttribute("IsMagicBlock") then
		local blockA = self
		local blockB = blocksRegistry[otherPart]
		
		if blockB and (not blockA.IsDestroyed) and (not blockB.IsDestroyed) and blockA ~= blockB then
			local newMergedBlock = blockA + blockB
		end
	end
end

--function to fully destroy the block and his table
function MagicBlock:Destroy()
	if self.IsDestroyed then return end
	self.IsDestroyed = true
	
	if self.Part then
		blocksRegistry[self.Part] = nil
		self.Part:Destroy()
	end
	
	setmetatable(self, nil)
	
	for k, v in self do
		self[k] = nil
	end
	
	print("the block destroyed")
end

return MagicBlock
