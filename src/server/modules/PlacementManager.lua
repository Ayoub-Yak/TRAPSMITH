-- src/server/modules/PlacementManager.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

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

local function createHiddenTrap(map: Instance, targetCFrame: CFrame): Part
	local trap = Instance.new("Part")
	trap.Name = "HiddenTrap"
	trap.Size = Vector3.new(4, 1, 4)
	trap.CFrame = targetCFrame
	trap.Anchored = true
	trap.CanCollide = false
	trap.Transparency = 0.5
	trap.BrickColor = BrickColor.new("Really black")
	trap.Parent = map

	local triggered = false
	trap.Touched:Connect(function(hit: BasePart)
		if triggered then
			return
		end

		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if not player or player:GetAttribute("Role") ~= "Runner" or not humanoid then
			return
		end

		triggered = true
		local previousWalkSpeed = humanoid.WalkSpeed
		local previousJumpPower = humanoid.JumpPower
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		player:SetAttribute("Stuck", true)
		trap:Destroy()

		task.delay(2, function()
			if humanoid.Parent then
				humanoid.WalkSpeed = previousWalkSpeed
				humanoid.JumpPower = previousJumpPower
			end
			if player.Parent then
				player:SetAttribute("Stuck", false)
			end
		end)
	end)

	return trap
end

function PlacementManager.init(gameManagerRef: () -> string)
	getCurrentPhase = gameManagerRef
	print("[TRAPSMITH Module] PlacementManager initialized.")

	placeEvent.OnServerEvent:Connect(function(player, modelName, targetCFrame)
		local role = player:GetAttribute("Role")
		local currentPhase = getCurrentPhase and getCurrentPhase() or ""
		if typeof(targetCFrame) ~= "CFrame" then
			warn(player.Name .. " sent an invalid placement CFrame.")
			return
		end

		if role == "Sniper" and currentPhase == "SniperPlacement" and modelName == "HiddenTrap" then
			local inventory = player:GetAttribute("HiddenTrapInventory")
			if typeof(inventory) ~= "number" or inventory < 1 then
				warn(player.Name .. " has no hidden traps available.")
				return
			end

			local map = Workspace:FindFirstChild("Map")
			if not map then
				warn("[TRAPSMITH Module] Map not found; cannot place hidden trap.")
				return
			end

			player:SetAttribute("HiddenTrapInventory", inventory - 1)
			createHiddenTrap(map, targetCFrame)
			return
		end

		if role ~= "Runner" then
			warn(player.Name .. " tried to place an obstacle, but is not a Runner.")
			return
		end

		if currentPhase ~= "RunnerPlacement" then
			warn(player.Name .. " tried to place an obstacle outside the placement phase.")
			return
		end

		if modelName ~= "BasicBlock" then
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