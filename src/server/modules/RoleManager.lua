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
		player:SetAttribute("Spectating", false)
		print("[TRAPSMITH Module] " .. player.Name .. " assigned as SNIPER.")
		return
	end

	player:SetAttribute("Role", "Runner")
	player:SetAttribute("Spectating", false)

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

function RoleManager.reassignActiveRunnerSegments()
	local nextIndex = 1
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("Role") == "Runner"
			and player:GetAttribute("Spectating") ~= true then
			player:SetAttribute("SegmentIndex", nextIndex)
			nextIndex += 1
		elseif player:GetAttribute("Role") == "Runner" then
			player:SetAttribute("SegmentIndex", nil)
		end
	end
end

return RoleManager
