local Workspace = game:GetService("Workspace")
local SpawnManager = {}

function SpawnManager.teleport(player: Player, character: Model)
	local role = player:GetAttribute("Role")
	local map = Workspace:WaitForChild("Map", 10)

	if not map then
		warn("[TRAPSMITH Module] Map folder not found in Workspace!")
		return
	end

	local targetSpawn: BasePart? = nil
	if role == "Sniper" then
		targetSpawn = map:FindFirstChild("SniperSpawn", true) :: BasePart
	else
		targetSpawn = map:FindFirstChild("RunnerSpawn", true) :: BasePart
	end

	if targetSpawn then
		character:PivotTo(targetSpawn.CFrame + Vector3.new(0, 3, 0))
		print("[TRAPSMITH Module] " .. player.Name .. " teleported to " .. targetSpawn.Name)
	else
		warn("[TRAPSMITH Module] Spawn point not found for role: " .. tostring(role))
	end
end

return SpawnManager