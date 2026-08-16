-- Connected Discord-GitHub | Discord: Trid Doe (trid147) | Roblox: Great_Warrior147 | Roblox Scripter Verification

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-- ============================================================================
-- 1. PROFILE SERVICE INITIALIZATION
-- ============================================================================
local ProfileService = require(ServerScriptService:WaitForChild("ProfileService"))

local ProfileTemplate = {
	Version = 1,
	Coins = 0,
	Level = 1,
	Experience = 0,
	TotalAbilitiesUsed = 0,
	PlayTime = 0
}

local ProfileStore = ProfileService.GetProfileStore(
	"PlayerData_Production_v3",
	ProfileTemplate
)

local Profiles = {}
local Cooldowns = {}
local SessionStartTimes = {}

-- ============================================================================
-- 2. GAME SETTINGS & CONFIGURATION
-- ============================================================================
local GAME_CONFIG = {
	LevelCap = 100,
	BaseXP = 100, 
	XPMultiplier = 1.35,
	MaxRequestsPerSecond = 10,
	LevelUpSoundId = "rbxassetid://2865227271",
	LevelUpParticleId = "rbxassetid://258128463"
}

local Events = ReplicatedStorage:WaitForChild("Events")
local AbilityRemote = Events:WaitForChild("AbilityRemote")
local AbilitiesFolder = ReplicatedStorage:WaitForChild("Abilities")

-- ============================================================================
-- 3. UTILITY & SECURITY FUNCTIONS
-- ============================================================================

-- Formats and outputs system logs for server debugging
local function SystemLog(category, message, player)
    local timestamp = os.date("%H:%M:%S")
    local prefix = player and (`[{player.Name}]`) or "[SERVER]"
    print(`[{timestamp}] {prefix} [{category}]: {message}`)
end

-- Prevents exploiters from spamming RemoteEvents and crashing the server
local RateLimitCache = {}
local function IsRateLimited(player)
	local userId = player.UserId
	local now = os.clock()

	if not RateLimitCache[userId] then
		RateLimitCache[userId] = { Requests = 1, LastReset = now }
		return false
	end

	if now - RateLimitCache[userId].LastReset > 1 then
		RateLimitCache[userId].Requests = 1
		RateLimitCache[userId].LastReset = now
		return false
	end

	RateLimitCache[userId].Requests += 1
	if RateLimitCache[userId].Requests > GAME_CONFIG.MaxRequestsPerSecond then
		return true
	end

	return false
end

-- ============================================================================
-- 4. CORE GAMEPLAY API (Passed to Ability Modules)
-- ============================================================================
local GameAPI = {}

-- Calculates required XP for the next level using an exponential growth curve
function GameAPI.GetRequiredXP(level)
	if level >= GAME_CONFIG.LevelCap then
		return math.huge
	end
	return math.floor(GAME_CONFIG.BaseXP * (level ^ GAME_CONFIG.XPMultiplier))
end

-- Safely creates visual and audio effects on the character when leveling up
local function PlayLevelUpEffect(character)
	if not character then return end
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then return end

	local attachment = Instance.new("Attachment")
	attachment.Name = "LevelUpFX"
	attachment.Parent = rootPart

	local emitter = Instance.new("ParticleEmitter")
	emitter.Texture = GAME_CONFIG.LevelUpParticleId
	emitter.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0), Color3.fromRGB(255, 150, 0))
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.5, 2),
		NumberSequenceKeypoint.new(1, 0)
	})
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.2, 0),
		NumberSequenceKeypoint.new(0.8, 0),
		NumberSequenceKeypoint.new(1, 1)
	})
	emitter.EmissionDirection = Enum.NormalId.Top
	emitter.Speed = NumberRange.new(8, 12)
	emitter.Drag = 2
	emitter.Lifetime = NumberRange.new(1.5, 2.5)
	emitter.Rate = 150
	emitter.Parent = attachment

	local sound = Instance.new("Sound")
	sound.SoundId = GAME_CONFIG.LevelUpSoundId
	sound.Volume = 1.2
	sound.Parent = rootPart
	sound:Play()

	task.delay(1, function()
		emitter.Enabled = false
	end)
	Debris:AddItem(attachment, 3)
	Debris:AddItem(sound, 3)
end

-- Adds XP, handles leveling up math, and updates leaderstats
function GameAPI.AddXP(player, amount)
	local profile = Profiles[player]
	if not profile then return end

	local data = profile.Data
	if data.Level >= GAME_CONFIG.LevelCap then return end

	data.Experience += amount
	local requiredXP = GameAPI.GetRequiredXP(data.Level)
	local didLevelUp = false

	-- Loop catches instances where player earns enough XP to jump multiple levels at once
	while data.Experience >= requiredXP and data.Level < GAME_CONFIG.LevelCap do
		data.Experience -= requiredXP
		data.Level += 1
		didLevelUp = true
		requiredXP = GameAPI.GetRequiredXP(data.Level)
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local levelObj = leaderstats:FindFirstChild("Level")
		local xpObj = leaderstats:FindFirstChild("XP")
		if levelObj then levelObj.Value = data.Level end
		if xpObj then xpObj.Value = data.Experience end
	end

	if didLevelUp then
		SystemLog("PROGRESSION", "Leveled up to " .. tostring(data.Level), player)
		PlayLevelUpEffect(player.Character)
	end
end

-- Safely adds coins and updates leaderstats immediately
function GameAPI.AddCoins(player, amount)
	local profile = Profiles[player]
	if not profile then return end

	profile.Data.Coins += amount
	local leaderstats = player:FindFirstChild("leaderstats")

	if leaderstats then
		local coinsObj = leaderstats:FindFirstChild("Coins")
		if coinsObj then
			coinsObj.Value = profile.Data.Coins
		end
	end
end

-- ============================================================================
-- 5. DATASTORE MANAGEMENT
-- ============================================================================

local function InitializeLeaderstats(player, data)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local levelValue = Instance.new("IntValue")
	levelValue.Name = "Level"
	levelValue.Value = data.Level
	levelValue.Parent = leaderstats

	local xpValue = Instance.new("IntValue")
	xpValue.Name = "XP"
	xpValue.Value = data.Experience
	xpValue.Parent = leaderstats

	local coinsValue = Instance.new("IntValue")
	coinsValue.Name = "Coins"
	coinsValue.Value = data.Coins
	coinsValue.Parent = leaderstats
end

local function OnPlayerAdded(player)
	SessionStartTimes[player.UserId] = os.clock()
	local profileKey = "User_" .. tostring(player.UserId)
	local profile = ProfileStore:LoadProfileAsync(profileKey)

	if profile ~= nil then
		profile:AddUserId(player.UserId)
		profile:Reconcile()

		profile:ListenToRelease(function()
			Profiles[player] = nil
			player:Kick("Your data session was released. Please rejoin.")
		end)

		if player:IsDescendantOf(Players) then
			Profiles[player] = profile
			InitializeLeaderstats(player, profile.Data)
			SystemLog("DATASTORE", "Profile loaded successfully.", player)
		else
			profile:Release()
		end
	else
		player:Kick("Critical Error: Failed to load data. Please rejoin.")
	end
end

local function OnPlayerRemoving(player)
	local userId = player.UserId
	local idString = tostring(userId)

	if SessionStartTimes[userId] then
		local sessionDuration = os.clock() - SessionStartTimes[userId]
		local profile = Profiles[player]
		if profile then
			profile.Data.PlayTime += sessionDuration
		end
		SessionStartTimes[userId] = nil
	end

	-- Clean up active cooldowns to prevent memory leaks over long server uptimes
	for key, _ in pairs(Cooldowns) do
		if string.match(key, "^" .. idString) then
			Cooldowns[key] = nil
		end
	end

	RateLimitCache[userId] = nil

	local profile = Profiles[player]
	if profile ~= nil then
		profile:Release()
		SystemLog("DATASTORE", "Profile saved and released.", player)
	end
end

Players.PlayerAdded:Connect(OnPlayerAdded)
Players.PlayerRemoving:Connect(OnPlayerRemoving)

-- ============================================================================
-- 6. ABILITY DISPATCHER (SERVER NETWORK)
-- ============================================================================

AbilityRemote.OnServerEvent:Connect(function(player, abilityName)
	if IsRateLimited(player) then
		SystemLog("SECURITY", "Rate limit dropped request for ability.", player)
		return
	end

	local profile = Profiles[player] 
	if not profile then return end

	if type(abilityName) ~= "string" then 
		SystemLog("SECURITY", "Invalid abilityName parameter type.", player)
		return 
	end

	local moduleScript = AbilitiesFolder:FindFirstChild(abilityName)
	if not moduleScript or not moduleScript:IsA("ModuleScript") then 
		SystemLog("SECURITY", "Attempted to use invalid ability: " .. tostring(abilityName), player)
		return 
	end

	-- Securely require the module using pcall to prevent bad code from crashing the thread
	local success, config = pcall(require, moduleScript)
	if not success or type(config) ~= "table" then
		SystemLog("ERROR", "Failed to require ability module: " .. abilityName, player)
		return
	end

	local cooldownKey = player.UserId .. "_" .. abilityName

	if Cooldowns[cooldownKey] then
		local timePassed = os.clock() - Cooldowns[cooldownKey]
		if timePassed < config.Cooldown then
			return -- Silently drop if client tries to bypass cooldown
		end
	end

	local char = player.Character
	if not char then return end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	local hum = char:FindFirstChild("Humanoid")
	if not hrp or not hum or hum.Health <= 0 then return end

	Cooldowns[cooldownKey] = os.clock()
	profile.Data.TotalAbilitiesUsed += 1

	-- Inject GameAPI directly into the module so it can safely handle rewards
	task.spawn(function()
		local actionSuccess, errorMessage = pcall(function()
			config.Action(player, config, char, hrp, GameAPI)
		end)

		if not actionSuccess then
			SystemLog("ERROR", "Ability Execution Failed: " .. tostring(errorMessage), player)
		end
	end)
end)
