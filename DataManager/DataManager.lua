-- Connected Discord-GitHub | Discord: Trid Doe (trid147) | Roblox: Great_Warrior147 | Roblox Scripter Verification

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local ProfileStore = require(ServerScriptService.ProfileStore)

-- Rank progression table
local Ranks = {
	"Beginner",
	"Elementary",
	"Intermediate",
	"Advanced",
	"Expert",
	"Master",
	"Legend"
}

type PlayerData = {
	PlayTime: number,
	Coins: number,
	XP: number,
	Rank: string
}

-- Default profile structure for new players
local DefaultData: PlayerData = {
	PlayTime = 0,
	Coins = 0,
	XP = 0,
	Rank = "Beginner"
}

local ClickPart = Workspace.ClickPart
local CD = ClickPart.ClickDetector

local GAME_CONFIG = {
	XP_Multiplier = 1.35,
	Base_XP = 100,
	Cooldown = 0.5
}

local PlayerStore = ProfileStore.New("PlayerData", DefaultData)

local Profiles = {}
local JoinTimes = {}
local Cooldowns = {}

local Animating = false

-- Visual effect to emphasize leveling up
local function PlayLevelUpEffect(player: Player)
	local character = player.Character
	if character and character:FindFirstChild("HumanoidRootPart") then
		local attachment = Instance.new("Attachment")
		attachment.Parent = character.HumanoidRootPart

		local particles = Instance.new("ParticleEmitter")
		particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
		particles.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0)})
		particles.Rate = 50
		particles.Speed = NumberRange.new(5, 10)
		particles.Parent = attachment

		task.delay(1.5, function()
			particles.Enabled = false
			task.wait(2)
			attachment:Destroy()
		end)
	end
end

local function UpdateLeaderstats(player: Player)
	local profile = Profiles[player]
	
	if profile ~= nil then
		local leaderstats = player:FindFirstChild("leaderstats")
		
		if not leaderstats then
			leaderstats = Instance.new("Folder")
			leaderstats.Name = "leaderstats"
			leaderstats.Parent = player

			local coins = Instance.new("IntValue")
			coins.Name = "Coins"
			coins.Value = profile.Data.Coins
			coins.Parent = leaderstats

			local rank = Instance.new("StringValue")
			rank.Name = "Rank"
			rank.Value = profile.Data.Rank
			rank.Parent = leaderstats

			local xp = Instance.new("IntValue")
			xp.Name = "XP"
			xp.Value = profile.Data.XP
			xp.Parent = leaderstats
		else
			local xp = leaderstats:FindFirstChild("XP")
			local coins = leaderstats:FindFirstChild("Coins")
			local rank = leaderstats:FindFirstChild("Rank")
			
			if xp ~= nil then
				xp.Value = profile.Data.XP
			end
			
			if coins ~= nil then
				coins.Value = profile.Data.Coins
			end
			
			if rank ~= nil then
				rank.Value = profile.Data.Rank
			end
		end
	end
end

local function CheckRankUpdate(player: Player): boolean
	local profile = Profiles[player]
	
	if profile ~= nil then
		local xp = profile.Data.XP
		local rank = profile.Data.Rank
		
		local MaxRank = #Ranks
		local RankIndex = table.find(Ranks, rank)
		
		if RankIndex == nil then
			RankIndex = 1
		end
		
		while RankIndex < MaxRank and xp >= (RankIndex + 1) * GAME_CONFIG.XP_Multiplier * GAME_CONFIG.Base_XP do
			RankIndex += 1
		end
		
		if rank ~= Ranks[RankIndex] then
			profile.Data.Rank = Ranks[RankIndex]
			return true
		end
		
		return false
	end
end

local function ClickPartAnimation()
	if Animating then return end
	Animating = true
	local info = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true, 0)
	local goals = {Color = Color3.fromRGB(255, 0, 0)}
	
	local tween = TweenService:Create(ClickPart, info, goals)
	tween:Play()
	
	tween.Completed:Connect(function(playbackState: Enum.PlaybackState) Animating = false end)
end

local function OnClick(player: Player)
	if Cooldowns[player.UserId] ~= nil then
		local last_click = Cooldowns[player.UserId]
		if os.clock() - last_click < GAME_CONFIG.Cooldown then
			warn(`{player.Name} is on cooldown!`)
			return
		end
	end
	
	ClickPart.Sound:Play()
	ClickPartAnimation()
	
	Cooldowns[player.UserId] = os.clock()
	
	local profile = Profiles[player]
	
	if profile ~= nil then
		profile.Data.Coins += 1
		profile.Data.XP += math.random(1, 5)
		
		local didLvlUp = CheckRankUpdate(player)
		
		if didLvlUp then
			PlayLevelUpEffect(player)
			print(`{player.Name} leveled up!`)
		end
		UpdateLeaderstats(player)
	end
end

local function PlayerAdded(player: Player)
	local profileKey = `player_{player.UserId}`

	local profile = PlayerStore:StartSessionAsync(profileKey)
	
	if profile ~= nil then
		profile:AddUserId(player.UserId)
		
		profile:Reconcile()
		
		profile.OnSessionEnd:Connect(function()  
			Profiles[player] = nil
			JoinTimes[player] = nil
			player:Kick("Your data session is ended.")
		end)
		
		if player.Parent == Players then
			Profiles[player] = profile
			JoinTimes[player] = os.clock()
			print(`Profile loaded for {player.Name}! His total playtime is: {profile.Data.PlayTime}`)
			
			UpdateLeaderstats(player)
		else
			profile:EndSession()
		end
	else
		player:Kick("Unable to load your data.")
	end
end

local function PlayerRemoving(player: Player)
	local profile = Profiles[player]
	local JoinTime = JoinTimes[player]
	
	if profile ~= nil and JoinTime ~= nil then
		local sessionTime = math.floor(os.clock() - JoinTime)
		profile.Data.PlayTime += sessionTime
		
		profile:EndSession()
	end
	
	-- Free server memory
	Profiles[player] = nil
	JoinTimes[player] = nil
end

Players.PlayerAdded:Connect(PlayerAdded)
Players.PlayerRemoving:Connect(PlayerRemoving)
CD.MouseClick:Connect(OnClick)

-- Catch players who joined before the script initialized
for _, player in Players:GetPlayers() do
	task.spawn(PlayerAdded, player)
end

game:BindToClose(function()
	print("Server closing. Saving all profiles...")
	for _, player in Players:GetPlayers() do
		PlayerRemoving(player)
	end
	task.wait(2) 
	print("All profiles processed.")
end)
