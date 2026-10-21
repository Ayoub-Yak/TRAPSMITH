-- src/client/PlacementClient.client.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()
local Camera = workspace.CurrentCamera

-- Wait for the RemoteEvent setup by PlacementManager
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local placeEvent = remotes:WaitForChild("PlaceObstacle") :: RemoteEvent
local phaseEvent = remotes:WaitForChild("UpdatePhase") :: RemoteEvent

-- Placement State
local ghostPart: Part? = nil
local currentPhase = ""
local freeViewEnabled = false
local orbiting = false
local cameraYaw = 0
local cameraElevation = math.rad(55)
local cameraDistance = 70
local targetCameraYaw = cameraYaw
local targetCameraElevation = cameraElevation
local targetCameraDistance = cameraDistance
local MIN_CAMERA_FOV = 25
local MAX_CAMERA_FOV = 85
local CAMERA_SMOOTHING = 12
local targetCameraFov = Camera.FieldOfView
local CAMERA_MOVE_SPEED = 45
local cameraLocalPosition = Vector3.zero
local movementKeys: {[Enum.KeyCode]: boolean} = {}
local savedCameraSubject: Instance? = nil
local savedCameraMode: Enum.CameraMode? = nil
local savedMouseBehavior: Enum.MouseBehavior? = nil
local savedFieldOfView: number? = nil
local savedWalkSpeed: number? = nil
local savedJumpPower: number? = nil
local savedAutoRotate: boolean? = nil
local savedRootAnchored: boolean? = nil
local segmentVisual: Folder? = nil

local function getRunnerSpawn(): BasePart?
	local map = workspace:FindFirstChild("Map")
	local runnerSpawn = map and map:FindFirstChild("RunnerSpawn", true)
	if runnerSpawn and runnerSpawn:IsA("BasePart") then
		return runnerSpawn
	end
	return nil
end

local function getSegmentIndex(): number?
	local segmentIndex = LocalPlayer:GetAttribute("SegmentIndex")
	if typeof(segmentIndex) == "number" and segmentIndex >= 1 then
		return segmentIndex
	end
	return nil
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

local function getSegmentDimensions(runnerSpawn: BasePart): (number, number)
	return tonumber(runnerSpawn:GetAttribute("SegmentLength")) or 55,
		tonumber(runnerSpawn:GetAttribute("SegmentWidth")) or 100
end

local function getCameraMovement(runnerSpawn: BasePart): Vector3
	local forward = Vector3.new(Camera.CFrame.LookVector.X, 0, Camera.CFrame.LookVector.Z)
	local right = Vector3.new(Camera.CFrame.RightVector.X, 0, Camera.CFrame.RightVector.Z)

	if forward.Magnitude > 0 then
		forward = forward.Unit
	end
	if right.Magnitude > 0 then
		right = right.Unit
	end

	local worldMovement = Vector3.zero
	if movementKeys[Enum.KeyCode.W] or movementKeys[Enum.KeyCode.Z] then
		worldMovement += forward
	end
	if movementKeys[Enum.KeyCode.S] then
		worldMovement -= forward
	end
	if movementKeys[Enum.KeyCode.A] or movementKeys[Enum.KeyCode.Q] then
		worldMovement -= right
	end
	if movementKeys[Enum.KeyCode.D] then
		worldMovement += right
	end

	if worldMovement.Magnitude > 1 then
		worldMovement = worldMovement.Unit
	end

	return runnerSpawn.CFrame:VectorToObjectSpace(worldMovement)
end

local function createSegmentWall(size: Vector3, cframe: CFrame): Part
	local wall = Instance.new("Part")
	wall.Name = "RunnerSegmentBoundary"
	wall.Size = size
	wall.CFrame = cframe
	wall.Anchored = true
	wall.CanCollide = false
	wall.CanQuery = false
	wall.CanTouch = false
	wall.Material = Enum.Material.Neon
	wall.Color = Color3.fromRGB(0, 255, 120)
	wall.Transparency = 0.75
	return wall
end

local function setSegmentVisual(enabled: boolean, runnerSpawn: BasePart?)
	if not enabled or not runnerSpawn then
		if segmentVisual then
			segmentVisual:Destroy()
			segmentVisual = nil
		end
		return
	end

	if segmentVisual then
		return
	end

	local segmentLength, segmentWidth = getSegmentDimensions(runnerSpawn)
	local segmentIndex = getSegmentIndex()
	if not segmentIndex then
		return
	end

	local height = 8
	local thickness = 0.15
	local folder = Instance.new("Folder")
	folder.Name = "RunnerSegmentVisual"
	folder.Parent = workspace

	local sideSize = Vector3.new(thickness, height, segmentLength)
	local endSize = Vector3.new(segmentWidth, height, thickness)
	local segmentOffset = (segmentIndex - 1) * segmentLength
	local center = runnerSpawn.CFrame * CFrame.new(0, height / 2, -segmentOffset - segmentLength / 2)
	createSegmentWall(sideSize, center * CFrame.new(-segmentWidth / 2, 0, 0)).Parent = folder
	createSegmentWall(sideSize, center * CFrame.new(segmentWidth / 2, 0, 0)).Parent = folder
	createSegmentWall(endSize, runnerSpawn.CFrame * CFrame.new(0, height / 2, -segmentOffset)).Parent = folder
	createSegmentWall(endSize, runnerSpawn.CFrame * CFrame.new(0, height / 2, -segmentOffset - segmentLength)).Parent = folder
	segmentVisual = folder
end

local function setFreeView(enabled: boolean)
	if freeViewEnabled == enabled then
		return
	end

	freeViewEnabled = enabled
	local character = LocalPlayer.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")

	if enabled then
		savedCameraSubject = Camera.CameraSubject
		savedCameraMode = LocalPlayer.CameraMode
		savedMouseBehavior = UserInputService.MouseBehavior
		savedFieldOfView = Camera.FieldOfView
		Camera.CameraType = Enum.CameraType.Scriptable
		LocalPlayer.CameraMode = Enum.CameraMode.Classic
		targetCameraFov = Camera.FieldOfView
		orbiting = false
		targetCameraYaw = cameraYaw
		targetCameraElevation = cameraElevation
		targetCameraDistance = cameraDistance
		local runnerSpawn = getRunnerSpawn()
		local segmentIndex = getSegmentIndex()
		if runnerSpawn and segmentIndex then
			local segmentLength = getSegmentDimensions(runnerSpawn)
			local segmentOffset = (segmentIndex - 1) * segmentLength
			cameraLocalPosition = Vector3.new(
				0,
				math.sin(cameraElevation) * cameraDistance + 3,
				-segmentOffset - segmentLength / 2
			)
		end

		if humanoid then
			savedWalkSpeed = humanoid.WalkSpeed
			savedJumpPower = humanoid.JumpPower
			savedAutoRotate = humanoid.AutoRotate
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			humanoid.AutoRotate = false
		end

		if rootPart and rootPart:IsA("BasePart") then
			savedRootAnchored = rootPart.Anchored
			rootPart.Anchored = true
		end
	else
		orbiting = false
		UserInputService.MouseBehavior = savedMouseBehavior or Enum.MouseBehavior.Default
		Camera.CameraType = Enum.CameraType.Custom
		LocalPlayer.CameraMode = savedCameraMode or Enum.CameraMode.Classic
		Camera.FieldOfView = savedFieldOfView or 70

		local currentCharacter = LocalPlayer.Character
		local currentHumanoid = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
		Camera.CameraSubject = currentHumanoid or savedCameraSubject

		if humanoid then
			humanoid.WalkSpeed = savedWalkSpeed or 16
			humanoid.JumpPower = savedJumpPower or 50
			humanoid.AutoRotate = savedAutoRotate ~= false
		end

		if rootPart and rootPart:IsA("BasePart") then
			rootPart.Anchored = savedRootAnchored == true
		end

		savedCameraSubject = nil
		savedCameraMode = nil
		savedMouseBehavior = nil
		savedFieldOfView = nil
		savedAutoRotate = nil
		savedRootAnchored = nil
		movementKeys = {}
	end
end

phaseEvent.OnClientEvent:Connect(function(phaseName: string)
	currentPhase = phaseName
	setFreeView(LocalPlayer:GetAttribute("Role") == "Runner"
		and phaseName == "Placement")
end)

-- Create a placeholder transparent part for visual preview
local function createGhostPart(): Part
	local part = Instance.new("Part")
	part.Name = "PlacementGhost"
	part.Size = Vector3.new(4, 4, 4) -- Standard block size
	part.Color = Color3.fromRGB(0, 255, 120) -- Neon Green
	part.Material = Enum.Material.ForceField -- Fixed capitalization
	part.Transparency = 0.5
	part.CanCollide = false
	part.Anchored = true
	return part
end

-- Update Ghost Position every frame
RunService.RenderStepped:Connect(function(deltaTime: number)
	local role = LocalPlayer:GetAttribute("Role")

	-- Only Runners can place
	local canPlace = role == "Runner" and currentPhase == "Placement"
	if not canPlace then
		if ghostPart then
			ghostPart:Destroy()
			ghostPart = nil
		end
		setFreeView(false)
		setSegmentVisual(false, nil)
		return
	end
	setFreeView(true)

	local runnerSpawn = getRunnerSpawn()
	local segmentIndex = getSegmentIndex()
	if freeViewEnabled and runnerSpawn and segmentIndex then
		setSegmentVisual(true, runnerSpawn)
		local segmentLength, segmentWidth = getSegmentDimensions(runnerSpawn)
		local segmentOffset = (segmentIndex - 1) * segmentLength
		local movement = getCameraMovement(runnerSpawn)
		if movement.Magnitude > 0 then
			cameraLocalPosition += movement * CAMERA_MOVE_SPEED * deltaTime
		end

		local segmentStart = -segmentOffset - segmentLength
		local segmentEnd = -segmentOffset
		local cameraBoundaryPadding = 20
		cameraLocalPosition = Vector3.new(
			math.clamp(
				cameraLocalPosition.X,
				-segmentWidth / 2 - cameraBoundaryPadding,
				segmentWidth / 2 + cameraBoundaryPadding
			),
			math.sin(targetCameraElevation) * targetCameraDistance + 3,
			math.clamp(
				cameraLocalPosition.Z,
				segmentStart - cameraBoundaryPadding,
				segmentEnd + cameraBoundaryPadding
			)
		)

		local cameraPosition = runnerSpawn.CFrame:PointToWorldSpace(cameraLocalPosition)
		local horizontalLook = Vector3.new(
			math.sin(targetCameraYaw) * math.cos(targetCameraElevation),
			-math.sin(targetCameraElevation),
			-math.cos(targetCameraYaw) * math.cos(targetCameraElevation)
		)
		local lookPosition = runnerSpawn.CFrame:PointToWorldSpace(
			cameraLocalPosition + horizontalLook * targetCameraDistance
		)
		local targetCameraCFrame = CFrame.lookAt(cameraPosition, lookPosition)
		Camera.CFrame = Camera.CFrame:Lerp(
			targetCameraCFrame,
			math.clamp(deltaTime * CAMERA_SMOOTHING, 0, 1)
		)
		Camera.FieldOfView += (targetCameraFov - Camera.FieldOfView)
			* math.clamp(deltaTime * CAMERA_SMOOTHING, 0, 1)
	end

	-- Create ghost if it doesn't exist
	if not ghostPart then
		local newGhost = createGhostPart()
		newGhost.Parent = workspace
		ghostPart = newGhost
	end

	-- Type assertion check for Luau
	local ghost = ghostPart
	if not ghost then return end

	-- Raycast from mouse to find position on floor/ground
	local mouseRay = Mouse.UnitRay
	local raycastParams = RaycastParams.new()

	local filterList = {ghost}
	if LocalPlayer.Character then
		table.insert(filterList, LocalPlayer.Character)
	end

	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = filterList

	local result = workspace:Raycast(mouseRay.Origin, mouseRay.Direction * 200, raycastParams)

	if result then
		-- Position ghost slightly above ground so it sits nicely
		local targetPos = result.Position + Vector3.new(0, ghost.Size.Y / 2, 0)
		local targetSpawn = getRunnerSpawn()
		local targetSegmentIndex = getSegmentIndex()
		if targetSpawn and targetSegmentIndex
			and isInsideRunnerSegment(targetPos, targetSpawn, targetSegmentIndex) then
			ghost.CFrame = CFrame.new(targetPos)
			ghost.Transparency = 0.4
		else
			ghost.Transparency = 1
		end
	else
		ghost.Transparency = 1 -- Hide if pointing at sky
	end
end)

-- Detect Left Click to Place
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if freeViewEnabled and input.UserInputType == Enum.UserInputType.Keyboard then
		movementKeys[input.KeyCode] = true
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 and freeViewEnabled then
		orbiting = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
		return
	end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local role = LocalPlayer:GetAttribute("Role")
		local canPlace = currentPhase == "Placement"
		if role == "Runner" and canPlace and ghostPart and ghostPart.Transparency < 1 then
			-- Send placement request to server
			placeEvent:FireServer("BasicBlock", ghostPart.CFrame)
			print("[TRAPSMITH Client] Sent placement request to server!")
		end
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		movementKeys[input.KeyCode] = nil
	end

	if input.UserInputType == Enum.UserInputType.MouseButton2 and orbiting then
		orbiting = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end)

UserInputService.InputChanged:Connect(function(input, gameProcessed)
	if gameProcessed or not freeViewEnabled then return end

	if input.UserInputType == Enum.UserInputType.MouseWheel then
		targetCameraFov = math.clamp(
			targetCameraFov - input.Position.Z * 5,
			MIN_CAMERA_FOV,
			MAX_CAMERA_FOV
		)
	elseif input.UserInputType == Enum.UserInputType.MouseMovement and orbiting then
		targetCameraYaw -= input.Delta.X * 0.005
		targetCameraElevation = math.clamp(
			targetCameraElevation + input.Delta.Y * 0.005,
			math.rad(25),
			math.rad(85)
		)
	end
end)