local HealthManager = {}

function HealthManager.setupHealth(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	local role = player:GetAttribute("Role")

	if role == "Sniper" then
		humanoid.MaxHealth = 10000
		humanoid.Health = 10000
		print("[TRAPSMITH Module] " .. player.Name .. " health set to SNIPER (10,000 HP).")
	else
		humanoid.MaxHealth = 1000
		humanoid.Health = 1000
		print("[TRAPSMITH Module] " .. player.Name .. " health set to RUNNER (1,000 HP).")
	end
end

return HealthManager