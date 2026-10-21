-- src/server/modules/PlacementManager.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlacementManager = {}
local getCurrentPhase: (() -> string)? = nil

-- Setup RemoteEvent for client-to-server communication
local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local placeEvent = remotes:FindFirstChild("PlaceObstacle")
if not placeEvent then
	placeEvent = Instance.new("RemoteEvent")
	placeEvent.Name = "PlaceObstacle"
	placeEvent.Parent = remotes
end

local function isInsideRunnerSegment(position: Vector3, runnerSpawn: BasePart, segmentIndex: number): boolean
	local localPosition = runnerSpawn.CFrame:PointToObjectSpace(position)
	local segmentLength = tonumber(runnerSpawn:GetAttribute("SegmentLength")) or 55
	local segmentWidth = tonumber(runnerSpawn:GetAttribute("SegmentWidth")) or 100
	local forwardDistance = -localPosition.Z
	local segmentStart = (segmentIndex - 1) * segmentLength

	return forwardDistance >= segmentStart
		and forwardDistance <= segmentStart + segmentLength
		and math.abs(localPosition.X) <= segmentWidth / 2
end

function PlacementManager.init(gameManagerRef: () -> string)
	getCurrentPhase = gameManagerRef
	print("[TRAPSMITH Module] PlacementManager initialized.")

	placeEvent.OnServerEvent:Connect(function(player, modelName, targetCFrame)
		local role = player:GetAttribute("Role")
		if role ~= "Runner" then
			warn(player.Name .. " tried to place an obstacle, but is not a Runner!")
			return
		end

		local currentPhase = getCurrentPhase and getCurrentPhase() or ""
		if currentPhase ~= "Placement" then
			warn(player.Name .. " tried to place an obstacle outside the placement phase.")
			return
		end

		if modelName ~= "BasicBlock" or typeof(targetCFrame) ~= "CFrame" then
			warn(player.Name .. " sent an invalid obstacle placement request.")
			return
		end

		local segmentIndex = player:GetAttribute("SegmentIndex")
		if typeof(segmentIndex) ~= "number" or segmentIndex < 1 then
			warn(player.Name .. " has no valid placement segment assigned.")
			return
		end

		local map = Workspace:FindFirstChild("Map")
		local runnerSpawn = map and map:FindFirstChild("RunnerSpawn", true)
		if not map or not runnerSpawn or not runnerSpawn:IsA("BasePart") then
			warn("[TRAPSMITH Module] RunnerSpawn not found; cannot validate obstacle placement.")
			return
		end

		if not isInsideRunnerSegment(targetCFrame.Position, runnerSpawn, segmentIndex) then
			warn(player.Name .. " tried to place an obstacle outside Runner segment " .. segmentIndex .. ".")
			return
		end

		local newPart = Instance.new("Part")
		newPart.Size = Vector3.new(4, 4, 4)
		newPart.CFrame = targetCFrame
		newPart.Anchored = true
		newPart.BrickColor = BrickColor.new("Bright orange")
		newPart.Parent = map
		print("[TRAPSMITH Module] Obstacle placed by " .. player.Name)
	end)
end

return PlacementManager