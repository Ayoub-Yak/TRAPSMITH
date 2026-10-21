-- src/server/GameManager.server.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Require our modular components
local modules = script.Parent:WaitForChild("modules")
local RoleManager = require(modules:WaitForChild("RoleManager"))
local HealthManager = require(modules:WaitForChild("HealthManager"))
local SpawnManager = require(modules:WaitForChild("SpawnManager"))
local PlacementManager = require(modules:WaitForChild("PlacementManager"))
local CombatManager = require(modules:WaitForChild("CombatManager"))
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
	RunHunt = "RunHunt",
	Resolution = "Resolution"
}

local currentPhase = Phase.SafeZone
print("[TRAPSMITH] GameManager started (Modular Architecture). Current Phase: " .. currentPhase)

-- Initialiser les managers
PlacementManager.init(function(): string
	return currentPhase
end)
CombatManager.init()
ShopManager.init()

-- Connect player lifecycle events
Players.PlayerAdded:Connect(function(player)
	RoleManager.assignRole(player)

	player.CharacterAdded:Connect(function(character)
		task.wait(0.5) -- Small yield to ensure attributes sync
		HealthManager.setupHealth(player, character)
		SpawnManager.teleport(player, character)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	print("[TRAPSMITH] " .. player.Name .. " left the game.")
end)

-- Helper function to run a timed phase and broadcast to clients
local function runPhase(phaseName: string, duration: number)
	currentPhase = phaseName
	print(">>> PHASE: " .. phaseName .. " (" .. duration .. "s)")

	-- Countdown loop broadcasting to clients every second
	for remaining = duration, 0, -1 do
		phaseEvent:FireAllClients(currentPhase, remaining)
		task.wait(1)
	end
end

-- Main Round Loop with 20s timers
task.spawn(function()
	while true do
		-- Phase 1: Safe Zone Shop (20 seconds)[cite: 8]
		runPhase(Phase.SafeZone, 20)

		-- Phase 2: Runner obstacle placement (20 seconds)
		runPhase(Phase.RunnerPlacement, 20)

		-- Phase 3: Sniper hidden trap placement (10 seconds)
		runPhase(Phase.SniperPlacement, 10)

		-- Phase 4: Run / Hunt Phase (30 seconds of action)
		runPhase(Phase.RunHunt, 30)

		-- Phase 5: Resolution (5 seconds for scores)
		runPhase(Phase.Resolution, 5)
		
		print("--- END OF TEST ROUND LOOP. RESTARTING ---")
	end
end)