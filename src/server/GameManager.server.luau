-- src/server/GameManager.server.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Respawns are controlled by the round system so eliminated Runners cannot
-- automatically return as active players.
Players.CharacterAutoLoads = false

-- Require our modular components
local modules = script.Parent:WaitForChild("modules")
local RoleManager = require(modules:WaitForChild("RoleManager"))
local HealthManager = require(modules:WaitForChild("HealthManager"))
type SpawnManagerApi = {
	init: (gameManagerRef: () -> string) -> (),
	teleport: (player: Player, character: Model) -> (),
	teleportActivePlayers: () -> (),
}
local SpawnManager = require(modules:WaitForChild("SpawnManager")) :: SpawnManagerApi
local PlacementManager = require(modules:WaitForChild("PlacementManager"))
local CombatManager = require(modules:WaitForChild("CombatManager"))
local ResolutionManager = require(modules:WaitForChild("ResolutionManager") :: ModuleScript)
local ShopManager = require(modules:WaitForChild("ShopManager"))

-- Setup RemoteEvent for Phase/Timer syncing
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local phaseEvent = remotes:FindFirstChild("UpdatePhase")
if not phaseEvent then
	phaseEvent = Instance.new("RemoteEvent")
	phaseEvent.Name = "UpdatePhase"
	phaseEvent.Parent = remotes
end

-- Phase definitions
local Phase = {
	SafeZone = "SafeZone",
	RunnerPlacement = "RunnerPlacement",
	SniperPlacement = "SniperPlacement",
	RunHuntCountdown = "RunHuntCountdown",
	RunHunt = "RunHunt",
	Resolution = "Resolution"
}

local currentPhase = Phase.SafeZone
print("[TRAPSMITH] GameManager started (Modular Architecture). Current Phase: " .. currentPhase)

-- Initialiser les managers
SpawnManager.init(function(): string
	return currentPhase
end)
PlacementManager.init(function(): string
	return currentPhase
end)
CombatManager.init()
ResolutionManager.init(function(): string
	return currentPhase
end)
ShopManager.init()

-- Connect player lifecycle events
Players.PlayerAdded:Connect(function(player)
	RoleManager.assignRole(player)

	player.CharacterAdded:Connect(function(character)
		if player:GetAttribute("Spectating") == true then
			character:Destroy()
			return
		end

		task.wait(0.5) -- Small yield to ensure attributes sync
		HealthManager.setupHealth(player, character)
		SpawnManager.teleport(player, character)

		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Died:Connect(function()
				if player:GetAttribute("Role") == "Runner"
					and player:GetAttribute("HasFinished") ~= true then
					player:SetAttribute("Spectating", true)
				end
			end)
		end
	end)

	if player:GetAttribute("Spectating") ~= true then
		player:LoadCharacter()
	end
end)

Players.PlayerRemoving:Connect(function(player)
	print("[TRAPSMITH] " .. player.Name .. " left the game.")
end)

-- Helper function to run a timed phase and broadcast to clients
local function 	runPhase(phaseName: string, duration: number, winner: string?)
	currentPhase = phaseName
	print(">>> PHASE: " .. phaseName .. " (" .. duration .. "s)")
	if phaseName == Phase.SafeZone
		or phaseName == Phase.RunnerPlacement
		or phaseName == Phase.SniperPlacement
		or phaseName == Phase.RunHuntCountdown
		or phaseName == Phase.RunHunt then
		SpawnManager.teleportActivePlayers()
	end

	-- Countdown loop broadcasting to clients every second
	for remaining = duration, 0, -1 do
		phaseEvent:FireAllClients(currentPhase, remaining, winner)
		task.wait(1)
	end
end

local function runHuntPhase(duration: number)
	currentPhase = Phase.RunHunt
	SpawnManager.teleportActivePlayers()
	local startedAt = os.clock()
	local lastBroadcast = -1

	while os.clock() - startedAt < duration do
		ResolutionManager.updateEliminations()

		if ResolutionManager.areAllRunnersFinished() then
			ResolutionManager.setWinner("Runners")
			return
		end

		if ResolutionManager.areAllRunnersEliminated() then
			ResolutionManager.setWinner("Sniper")
			return
		end

		local remaining = math.max(0, duration - math.floor(os.clock() - startedAt))
		if remaining ~= lastBroadcast then
			lastBroadcast = remaining
			phaseEvent:FireAllClients(currentPhase, remaining)
		end
		task.wait(0.1)
	end

	ResolutionManager.updateEliminations()
	if ResolutionManager.hasFinishedRunner() then
		ResolutionManager.setWinner("Runners")
	else
		ResolutionManager.setWinner("Sniper")
	end
end

-- Main Round Loop with 20s timers
task.spawn(function()
	while true do
		task.wait(20) -- Initial wait before starting the first round
		ResolutionManager.startRound()

		-- Phase 1: Safe Zone Shop (20 seconds)[cite: 8]
		runPhase(Phase.SafeZone, 20)

		-- Phase 2: Runner Placement (20 seconds)
		runPhase(Phase.RunnerPlacement, 3)

		-- Phase 3: Sniper Placement (10 seconds)
		runPhase(Phase.SniperPlacement, 3)

		-- Countdown before players are released onto the track.
		runPhase(Phase.RunHuntCountdown, 5)

		-- Phase 4: Run / Hunt Phase (30 seconds)
		runHuntPhase(30)

		-- Phase 5: Resolution (5 seconds)
		ResolutionManager.resolveRound()
		runPhase(Phase.Resolution, 5, ResolutionManager.getWinner())
		ResolutionManager.cleanupRound()

		print("--- END OF TEST ROUND LOOP. RESTARTING ---")
	end
end)