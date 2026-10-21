local Players = game:GetService("Players")
local RoleManager = {}

function RoleManager.assignRole(player: Player)
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
