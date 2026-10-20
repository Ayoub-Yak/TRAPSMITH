-- src/server/PlayerSetup.server.luau
local Players = game:GetService("Players")

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid") :: Humanoid
		
		-- Attendre un court instant pour s'assurer que le rôle est attribué par le GameManager
		task.wait(0.5)
		local role = player:GetAttribute("Role")
		
		if role == "Sniper" then
			-- Sniper : 10 000 PV (nécessite 20 tirs de Runners)[cite: 8, 10]
			humanoid.MaxHealth = 10000
			humanoid.Health = 10000
			print("[TRAPSMITH] " .. player.Name .. " configuré en tant que SNIPER (10 000 HP).")
		else
			-- Runners : 1 000 PV (meurent après 2 tirs normaux / 3 avec bouclier)[cite: 8, 10]
			humanoid.MaxHealth = 1000
			humanoid.Health = 1000
			print("[TRAPSMITH] " .. player.Name .. " configuré en tant que RUNNER (1 000 HP).")
		end
	end)
end)