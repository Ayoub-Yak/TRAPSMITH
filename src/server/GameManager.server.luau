-- src/server/GameManager.server.luau
local Players = game:GetService("Players")

-- Require our modular components
local ServerScriptService = game:GetService("ServerScriptService")
-- Note: Depending on Rojo setup, modules are usually accessed relative to script location
local modules = script.Parent:WaitForChild("modules")
local RoleManager = require(modules:WaitForChild("RoleManager"))
local HealthManager = require(modules:WaitForChild("HealthManager"))
local SpawnManager = require(modules:WaitForChild("SpawnManager"))
local PlacementManager = require(modules:WaitForChild("PlacementManager"))
local CombatManager = require(modules:WaitForChild("CombatManager"))

-- Phase definitions
local Phase = {
	SafeZone = "SafeZone",
	Placement = "Placement",
	RunHunt = "RunHunt",
	Resolution = "Resolution"
}

local currentPhase = Phase.SafeZone
print("[TRAPSMITH] GameManager started (Modular Architecture). Current Phase: " .. currentPhase)


-- Initialiser le PlacementManager ici avant le lancement de la boucle
PlacementManager.init()

CombatManager.init()

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

-- Main Round Loop
task.spawn(function()
	while true do
		currentPhase = Phase.SafeZone
		print(">>> PHASE: Safe Zone (Shopping & Healing)")
		task.wait(10)

		currentPhase = Phase.Placement
		print(">>> PHASE: Obstacle Placement (Runners building path)")
		task.wait(10)

		currentPhase = Phase.RunHunt
		print(">>> PHASE: Run / Hunt (Sniper firing, Runners advancing)")
		task.wait(15)

		currentPhase = Phase.Resolution
		print(">>> PHASE: Resolution (Awarding coins & scores)")
		task.wait(5)
		
		print("--- END OF TEST ROUND LOOP. RESTARTING ---")
	end
end)