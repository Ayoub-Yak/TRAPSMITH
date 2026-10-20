-- src/server/GameManager.server.luau
local Players = game:GetService("Players")

-- Phase definitions based on your 1-round design
local Phase = {
	SafeZone = "SafeZone",
	Placement = "Placement",
	RunHunt = "RunHunt",
	Resolution = "Resolution"
}

local currentPhase = Phase.SafeZone
print("[TRAPSMITH] GameManager started. Current Phase: " .. currentPhase)

local function assignRoles(player: Player)
	-- For testing 1 round: First player is Sniper, rest are Runners
	if #Players:GetPlayers() == 1 then
		player:SetAttribute("Role", "Sniper")
		print(player.Name .. " assigned as SNIPER (10,000 HP, Sniper Scope view).")
	else
		player:SetAttribute("Role", "Runner")
		print(player.Name .. " assigned as RUNNER (1,000 HP).")
	end
end

Players.PlayerAdded:Connect(function(player)
	assignRoles(player)
end)

-- Simple function to simulate transitioning through the 4 phases of a round
task.spawn(function()
	while true do
		-- Phase 1: Safe Zone Shop (50 seconds or until all arrive)[cite: 8]
		currentPhase = Phase.SafeZone
		print(">>> PHASE: Safe Zone (Shopping & Healing)")
		task.wait(10) -- Shortened to 10s for quick testing (Normally 50s)[cite: 8]

		-- Phase 2: Obstacle Placement (20s per Runner)[cite: 8, 9]
		currentPhase = Phase.Placement
		print(">>> PHASE: Obstacle Placement (Runners building path)")
		task.wait(10) -- Shortened for testing

		-- Phase 3: Run / Hunt Phase (Action!)[cite: 8]
		currentPhase = Phase.RunHunt
		print(">>> PHASE: Run / Hunt (Sniper firing, Runners advancing)")
		task.wait(15) -- Shortened for testing

		-- Phase 4: Resolution (Award coins & check win/loss)[cite: 8, 9]
		currentPhase = Phase.Resolution
		print(">>> PHASE: Resolution (Awarding coins & scores)")
		task.wait(5)
		
		print("--- END OF TEST ROUND LOOP. RESTARTING ---")
	end
end)