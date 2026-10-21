local Players = game:GetService("Players")
local RoleManager = {}

function RoleManager.assignRole(player: Player)
	local sniperAlreadyAssigned = false
	for _, otherPlayer in Players:GetPlayers() do
		if otherPlayer ~= player and otherPlayer:GetAttribute("Role") == "Sniper" then
			sniperAlreadyAssigned = true
			break
		end
	end

	if not sniperAlreadyAssigned then
		player:SetAttribute("Role", "Sniper")
		player:SetAttribute("SegmentIndex", nil)
		print("[TRAPSMITH Module] " .. player.Name .. " assigned as SNIPER.")
		return
	end

	player:SetAttribute("Role", "Runner")
	local usedIndexes: {[number]: boolean} = {}
	for _, otherPlayer in Players:GetPlayers() do
		local segmentIndex = otherPlayer:GetAttribute("SegmentIndex")
		if typeof(segmentIndex) == "number" then
			usedIndexes[segmentIndex] = true
		end
	end

	local nextIndex = 1
	while usedIndexes[nextIndex] do
		nextIndex += 1
	end

	player:SetAttribute("SegmentIndex", nextIndex)
	print("[TRAPSMITH Module] " .. player.Name .. " assigned Runner segment " .. nextIndex .. ".")
end

return RoleManager
