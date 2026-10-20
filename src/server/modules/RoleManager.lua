local Players = game:GetService("Players")
local RoleManager = {}

function RoleManager.assignRole(player: Player)
	if #Players:GetPlayers() == 1 then
		player:SetAttribute("Role", "Sniper")
		print("[TRAPSMITH Module] " .. player.Name .. " assigned as SNIPER.")
	else
		player:SetAttribute("Role", "Runner")
		print("[TRAPSMITH Module] " .. player.Name .. " assigned as RUNNER.")
	end
end

return RoleManager
