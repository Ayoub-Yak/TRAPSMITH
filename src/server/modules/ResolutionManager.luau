local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local ResolutionManager = {}

local RUNNER_WIN_PAYOUT = 500
local SNIPER_BASE_PAYOUT = 500
local SNIPER_KILL_PAYOUT = 100

local getCurrentPhase: (() -> string)? = nil
local finishConnection: RBXScriptConnection? = nil
local roundWinner: string? = nil
local runnerFinishOrder: {Player} = {}
local finishedRunners: {[Player]: boolean} = {}
local eliminatedRunners: {[Player]: boolean} = {}
local trackedRunners: {[Player]: boolean} = {}

local function getCoins(player: Player): IntValue?
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if coins and coins:IsA("IntValue") then
		return coins
	end
	return nil
end

local function addCoins(player: Player, amount: number)
	local coins = getCoins(player)
	if coins then
		coins.Value += amount
	end
end

local function isRunnerAlive(player: Player): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function markFinished(player: Player)
	if trackedRunners[player] and not player:GetAttribute("HasFinished") then
		player:SetAttribute("HasFinished", true)
		finishedRunners[player] = true
		table.insert(runnerFinishOrder, player)
	end
end

local function connectFinishLine()
	if finishConnection then
		finishConnection:Disconnect()
		finishConnection = nil
	end

	local map = Workspace:FindFirstChild("Map")
	local finishLine = map and (
		map:FindFirstChild("finishLine", true)
			or map:FindFirstChild("finishline", true)
	)
	if not finishLine or not finishLine:IsA("BasePart") then
		warn("[TRAPSMITH Resolution] Map part 'finishLine' was not found.")
		return
	end

	finishConnection = finishLine.Touched:Connect(function(hit: BasePart)
		if getCurrentPhase and getCurrentPhase() ~= "RunHunt" then
			return
		end

		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if player and player:GetAttribute("Role") == "Runner" then
			markFinished(player)
		end
	end)
end

function ResolutionManager.init(gameManagerRef: () -> string)
	getCurrentPhase = gameManagerRef
	connectFinishLine()
	print("[TRAPSMITH Module] ResolutionManager initialized.")
end

function ResolutionManager.startRound()
	roundWinner = nil
	runnerFinishOrder = {}
	finishedRunners = {}
	eliminatedRunners = {}
	trackedRunners = {}

	for _, player in Players:GetPlayers() do
		player:SetAttribute("HasFinished", false)
		player:SetAttribute("RoundKills", 0)
		if player:GetAttribute("Role") == "Runner"
			and player:GetAttribute("Spectating") ~= true then
			trackedRunners[player] = true
		end
	end

	connectFinishLine()
end

function ResolutionManager.updateEliminations()
	for player in trackedRunners do
		if not eliminatedRunners[player] and not isRunnerAlive(player) then
			eliminatedRunners[player] = true
			player:SetAttribute("Spectating", true)
			local sniper = Players:GetPlayers()[1]
			for _, candidate in Players:GetPlayers() do
				if candidate:GetAttribute("Role") == "Sniper" then
					sniper = candidate
					break
				end
			end
			if sniper then
				local kills = sniper:GetAttribute("RoundKills")
				sniper:SetAttribute("RoundKills", (if typeof(kills) == "number" then kills else 0) + 1)
			end
		end
	end
end

function ResolutionManager.areAllRunnersFinished(): boolean
	local runnerCount = 0
	for player in trackedRunners do
		runnerCount += 1
		if not player:GetAttribute("HasFinished") then
			return false
		end
	end
	return runnerCount > 0
end

function ResolutionManager.hasFinishedRunner(): boolean
	return #runnerFinishOrder > 0
end

function ResolutionManager.areAllRunnersEliminated(): boolean
	local runnerCount = 0
	for player in trackedRunners do
		runnerCount += 1
		if not eliminatedRunners[player] then
			return false
		end
	end
	return runnerCount > 0
end

function ResolutionManager.setWinner(winner: string)
	roundWinner = winner
end

function ResolutionManager.getWinner(): string?
	return roundWinner
end

function ResolutionManager.resolveRound()
	local winner = roundWinner
	if winner == "Runners" then
		for index, player in ipairs(runnerFinishOrder) do
			if player.Parent then
				addCoins(player, math.max(1, math.floor(RUNNER_WIN_PAYOUT * (0.9 ^ (index - 1)))))
			end
		end
	elseif winner == "Sniper" then
		for _, player in Players:GetPlayers() do
			if player:GetAttribute("Role") == "Sniper" then
				local kills = player:GetAttribute("RoundKills")
				local killCount = if typeof(kills) == "number" then kills else 0
				addCoins(player, SNIPER_BASE_PAYOUT + killCount * SNIPER_KILL_PAYOUT)
				break
			end
		end
	end
end

function ResolutionManager.cleanupRound()
	local map = Workspace:FindFirstChild("Map")
	if map then
		for _, descendant in map:GetDescendants() do
			if descendant:IsA("BasePart")
				and (descendant.Name == "BasicBlock" or descendant.Name == "HiddenTrap") then
				descendant:Destroy()
			end
		end
	end

	for _, player in Players:GetPlayers() do
		player:SetAttribute("Stuck", false)
		if player:GetAttribute("Role") == "Runner" then
			-- The server-side finish set is authoritative. Do not rely on a
			-- character attribute, which can be reset during round cleanup.
			local finished = finishedRunners[player] == true
			player:SetAttribute("Spectating", not finished)
			player:SetAttribute("HiddenTrapInventory", 0)
		end
		player:SetAttribute("HasFinished", false)

		if player:GetAttribute("Spectating") ~= true then
			player:LoadCharacter()
		elseif player.Character then
			-- Remove an alive non-finisher so they cannot participate in the
			-- next round while remaining in the server as a spectator.
			player.Character:Destroy()
		end
	end
end

return ResolutionManager
