local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()
local camera = workspace.CurrentCamera
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local placeEvent = remotes:WaitForChild("PlaceObstacle") :: RemoteEvent
local phaseEvent = remotes:WaitForChild("UpdatePhase") :: RemoteEvent

local currentPhase = ""
local ghostPart: Part? = nil
local freeViewEnabled = false
local orbiting = false
local cameraYaw = 0
local cameraElevation = math.rad(55)
local cameraDistance = 70
local targetCameraFov = camera.FieldOfView
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
local trapVisualsHidden = false

local MIN_CAMERA_FOV = 25
local MAX_CAMERA_FOV = 85
local CAMERA_SMOOTHING = 12
local CAMERA_MOVE_SPEED = 45

local function getRunnerSpawn(): BasePart?
	local map = workspace:FindFirstChild("Map")
	local spawn = map and map:FindFirstChild("RunnerSpawn", true)
	return if spawn and spawn:IsA("BasePart") then spawn else nil
end

local function getSegmentIndex(): number?
	local value = player:GetAttribute("SegmentIndex")
	return if typeof(value) == "number" and value >= 1 then value else nil
end

local function getSegmentDimensions(spawn: BasePart): (number, number)
	return tonumber(spawn:GetAttribute("SegmentLength")) or 70,
		tonumber(spawn:GetAttribute("SegmentWidth")) or 100
end

local function isInsideRunnerSegment(position: Vector3, spawn: BasePart, index: number): boolean
	local localPosition = spawn.CFrame:PointToObjectSpace(position)
	local length, width = getSegmentDimensions(spawn)
	local forwardDistance = -localPosition.Z
	local startDistance = (index - 1) * length
	return forwardDistance >= startDistance
		and forwardDistance <= startDistance + length
		and math.abs(localPosition.X) <= width / 2
end

local function updateTrapVisibility(hide: boolean)
	if trapVisualsHidden == hide then
		return
	end
	trapVisualsHidden = hide
	local map = workspace:FindFirstChild("Map")
	if not map then
		return
	end
	for _, descendant in map:GetDescendants() do
		if descendant:IsA("BasePart") and descendant.Name == "HiddenTrap" then
			descendant.LocalTransparencyModifier = if hide then 1 else 0
		end
	end
end

local function createWall(size: Vector3, cframe: CFrame): Part
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

local function setSegmentVisual(enabled: boolean, spawn: BasePart?)
	if not enabled or not spawn then
		if segmentVisual then
			segmentVisual:Destroy()
			segmentVisual = nil
		end
		return
	end
	if segmentVisual then
		return
	end

	local index = getSegmentIndex()
	if not index then
		return
	end
	local length, width = getSegmentDimensions(spawn)
	local offset = (index - 1) * length
	local center = spawn.CFrame * CFrame.new(0, 4, -offset - length / 2)
	local folder = Instance.new("Folder")
	folder.Name = "RunnerSegmentVisual"
	folder.Parent = workspace
	createWall(Vector3.new(0.15, 8, length), center * CFrame.new(-width / 2, 0, 0)).Parent = folder
	createWall(Vector3.new(0.15, 8, length), center * CFrame.new(width / 2, 0, 0)).Parent = folder
	createWall(Vector3.new(width, 8, 0.15), spawn.CFrame * CFrame.new(0, 4, -offset)).Parent = folder
	createWall(Vector3.new(width, 8, 0.15), spawn.CFrame * CFrame.new(0, 4, -offset - length)).Parent = folder
	segmentVisual = folder
end

local function setFreeView(enabled: boolean)
	if freeViewEnabled == enabled then
		return
	end
	freeViewEnabled = enabled
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")

	if enabled then
		savedCameraSubject = camera.CameraSubject
		savedCameraMode = player.CameraMode
		savedMouseBehavior = UserInputService.MouseBehavior
		savedFieldOfView = camera.FieldOfView
		camera.CameraType = Enum.CameraType.Scriptable
		player.CameraMode = Enum.CameraMode.Classic
		local spawn = getRunnerSpawn()
		local index = getSegmentIndex()
		if spawn then
			local length = getSegmentDimensions(spawn)
			local offset = if index then (index - 1) * length else 0
			cameraLocalPosition = Vector3.new(0, 60, if index then -offset - length / 2 else 0)
		else
			cameraLocalPosition = Vector3.new(0, 60, 0)
		end
		if humanoid then
			savedWalkSpeed = humanoid.WalkSpeed
			savedJumpPower = humanoid.JumpPower
			savedAutoRotate = humanoid.AutoRotate
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
			humanoid.AutoRotate = false
		end
		if root and root:IsA("BasePart") then
			savedRootAnchored = root.Anchored
			root.Anchored = true
		end
	else
		orbiting = false
		UserInputService.MouseBehavior = savedMouseBehavior or Enum.MouseBehavior.Default
		camera.CameraType = Enum.CameraType.Custom
		player.CameraMode = savedCameraMode or Enum.CameraMode.Classic
		camera.FieldOfView = savedFieldOfView or 70
		local currentCharacter = player.Character
		camera.CameraSubject = currentCharacter and currentCharacter:FindFirstChildOfClass("Humanoid")
			or savedCameraSubject
		if humanoid then
			humanoid.WalkSpeed = savedWalkSpeed or 16
			humanoid.JumpPower = savedJumpPower or 50
			humanoid.AutoRotate = savedAutoRotate ~= false
		end
		if root and root:IsA("BasePart") then
			root.Anchored = savedRootAnchored == true
		end
		savedCameraSubject = nil
		savedCameraMode = nil
		savedMouseBehavior = nil
		savedFieldOfView = nil
		savedWalkSpeed = nil
		savedJumpPower = nil
		savedAutoRotate = nil
		savedRootAnchored = nil
		movementKeys = {}
	end
end

local function createGhost(): Part
	local part = Instance.new("Part")
	part.Name = "PlacementGhost"
	part.Size = Vector3.new(4, 4, 4)
	part.Color = Color3.fromRGB(0, 255, 120)
	part.Material = Enum.Material.ForceField
	part.Transparency = 1
	part.CanCollide = false
	part.Anchored = true
	part.Parent = workspace
	return part
end

phaseEvent.OnClientEvent:Connect(function(phaseName: string)
	currentPhase = phaseName
	local role = player:GetAttribute("Role")
	setFreeView(
		(role == "Runner" and phaseName == "RunnerPlacement")
			or (role == "Sniper" and phaseName == "SniperPlacement")
	)
end)

RunService.RenderStepped:Connect(function(deltaTime: number)
	local role = player:GetAttribute("Role")
	local runnerPlacement = role == "Runner" and currentPhase == "RunnerPlacement"
	local sniperPlacement = role == "Sniper" and currentPhase == "SniperPlacement"
	local canPlace = runnerPlacement or sniperPlacement
	updateTrapVisibility(role == "Runner")

	if not canPlace then
		if ghostPart then
			ghostPart:Destroy()
			ghostPart = nil
		end
		setFreeView(false)
		setSegmentVisual(false, nil)
		return
	end

	local spawn = getRunnerSpawn()
	local index = getSegmentIndex()
	setSegmentVisual(runnerPlacement and index ~= nil, spawn)
	if freeViewEnabled and spawn then
		local forward = Vector3.new(camera.CFrame.LookVector.X, 0, camera.CFrame.LookVector.Z)
		local right = Vector3.new(camera.CFrame.RightVector.X, 0, camera.CFrame.RightVector.Z)
		if forward.Magnitude > 0 then forward = forward.Unit end
		if right.Magnitude > 0 then right = right.Unit end
		local movement = Vector3.zero
		if movementKeys[Enum.KeyCode.W] or movementKeys[Enum.KeyCode.Z] then movement += forward end
		if movementKeys[Enum.KeyCode.S] then movement -= forward end
		if movementKeys[Enum.KeyCode.A] or movementKeys[Enum.KeyCode.Q] then movement -= right end
		if movementKeys[Enum.KeyCode.D] then movement += right end
		if movement.Magnitude > 1 then movement = movement.Unit end
		cameraLocalPosition += spawn.CFrame:VectorToObjectSpace(movement) * CAMERA_MOVE_SPEED * deltaTime

		if runnerPlacement and index then
			local length, width = getSegmentDimensions(spawn)
			local offset = (index - 1) * length
			cameraLocalPosition = Vector3.new(
				math.clamp(cameraLocalPosition.X, -width / 2 - 20, width / 2 + 20),
				cameraLocalPosition.Y,
				math.clamp(cameraLocalPosition.Z, -offset - length - 20, -offset + 20)
			)
		end

		local worldPosition = spawn.CFrame:PointToWorldSpace(cameraLocalPosition)
		local lookDirection = Vector3.new(
			math.sin(cameraYaw) * math.cos(cameraElevation),
			-math.sin(cameraElevation),
			-math.cos(cameraYaw) * math.cos(cameraElevation)
		)
		local target = spawn.CFrame:PointToWorldSpace(cameraLocalPosition + lookDirection * cameraDistance)
		camera.CFrame = camera.CFrame:Lerp(CFrame.lookAt(worldPosition, target), math.clamp(deltaTime * CAMERA_SMOOTHING, 0, 1))
		camera.FieldOfView += (targetCameraFov - camera.FieldOfView) * math.clamp(deltaTime * CAMERA_SMOOTHING, 0, 1)
	end

	if not ghostPart then
		ghostPart = createGhost()
	end
	local ghost = ghostPart
	if not ghost then
		return
	end
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude
	rayParams.FilterDescendantsInstances = {ghost, player.Character}
	local distance = if sniperPlacement then 1000 else 200
	local result = workspace:Raycast(mouse.UnitRay.Origin, mouse.UnitRay.Direction * distance, rayParams)
	if not result then
		ghost.Transparency = 1
		return
	end

	local position = result.Position + Vector3.new(0, ghost.Size.Y / 2, 0)
	local valid = sniperPlacement
		or (spawn ~= nil and index ~= nil and isInsideRunnerSegment(position, spawn, index))
	ghost.CFrame = CFrame.new(position)
	ghost.Transparency = if valid then 0.4 else 1
end)

UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed then return end
	if freeViewEnabled and input.UserInputType == Enum.UserInputType.Keyboard then
		movementKeys[input.KeyCode] = true
	end
	if input.UserInputType == Enum.UserInputType.MouseButton2 and freeViewEnabled then
		orbiting = true
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
	elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
		local role = player:GetAttribute("Role")
		local runnerCanPlace = role == "Runner" and currentPhase == "RunnerPlacement"
		local sniperCanPlace = role == "Sniper" and currentPhase == "SniperPlacement"
		if (runnerCanPlace or sniperCanPlace) and ghostPart and ghostPart.Transparency < 1 then
			placeEvent:FireServer(if sniperCanPlace then "HiddenTrap" else "BasicBlock", ghostPart.CFrame)
		end
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject)
	if input.UserInputType == Enum.UserInputType.Keyboard then
		movementKeys[input.KeyCode] = nil
	elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
		orbiting = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end)

UserInputService.InputChanged:Connect(function(input: InputObject, gameProcessed: boolean)
	if gameProcessed or not freeViewEnabled then return end
	if input.UserInputType == Enum.UserInputType.MouseWheel then
		targetCameraFov = math.clamp(targetCameraFov - input.Position.Z * 5, MIN_CAMERA_FOV, MAX_CAMERA_FOV)
	elseif input.UserInputType == Enum.UserInputType.MouseMovement and orbiting then
		cameraYaw -= input.Delta.X * 0.005
		cameraElevation = math.clamp(cameraElevation + input.Delta.Y * 0.005, math.rad(25), math.rad(85))
	end
end)

workspace.DescendantAdded:Connect(function(descendant)
	if descendant:IsA("BasePart") and descendant.Name == "HiddenTrap" then
		descendant.LocalTransparencyModifier = if player:GetAttribute("Role") == "Runner" then 1 else 0
	end
end)
