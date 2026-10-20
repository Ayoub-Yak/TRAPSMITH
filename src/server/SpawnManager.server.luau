-- src/server/SpawnManager.server.luau
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local function teleportPlayer(player: Player, character: Model)
	local role = player:GetAttribute("Role")
	local map = Workspace:WaitForChild("Map", 10)
	
	if not map then
		warn("[TRAPSMITH] Dossier 'Map' introuvable dans Workspace!")
		return
	end
	
	local targetSpawn: BasePart? = nil
	
	if role == "Sniper" then
		targetSpawn = map:FindFirstChild("SniperSpawn", true) :: BasePart
	else
		targetSpawn = map:FindFirstChild("RunnerSpawn", true) :: BasePart
	end
	
	if targetSpawn then
		-- Placer le joueur 3 studs au-dessus du point d'apparition
		character:PivotTo(targetSpawn.CFrame + Vector3.new(0, 3, 0))
		print("[TRAPSMITH] " .. player.Name .. " (" .. tostring(role) .. ") téléporté à " .. targetSpawn.Name)
	else
		warn("[TRAPSMITH] Point d'apparition introuvable pour le rôle : " .. tostring(role))
	end
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- Attendre un court instant que le rôle soit attribué
		task.wait(0.6)
		teleportPlayer(player, character)
	end)
end)