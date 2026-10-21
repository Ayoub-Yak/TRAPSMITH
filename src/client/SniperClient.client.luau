-- src/client/SniperClient.client.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local shootEvent = remotes:WaitForChild("SniperShoot") :: RemoteEvent

-- Sniper Zoom Settings
local isZoomed = false
local NORMAL_FOV = 70
local SNIPER_ZOOM_FOV = 15

-- Create Procedural CS:GO Scope UI
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local scopeGui = Instance.new("ScreenGui")
scopeGui.Name = "SniperScopeGui"
scopeGui.ResetOnSpawn = false
scopeGui.Enabled = false
scopeGui.Parent = PlayerGui

-- Dark scope overlay with crosshair
local scopeFrame = Instance.new("Frame")
scopeFrame.Size = UDim2.new(1, 0, 1, 0)
scopeFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
scopeFrame.BackgroundTransparency = 0.4
scopeFrame.Parent = scopeGui

-- Circular Scope Reticle Cutout
local reticle = Instance.new("Frame")
reticle.AnchorPoint = Vector2.new(0.5, 0.5)
reticle.Position = UDim2.new(0.5, 0, 0.5, 0)
reticle.Size = UDim2.new(0, 400, 0, 400)
reticle.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
reticle.BackgroundTransparency = 0.9
reticle.BorderSizePixel = 3
reticle.BorderColor3 = Color3.fromRGB(0, 0, 0)
reticle.Parent = scopeFrame

local function createCrosshairLine(size, position)
	local line = Instance.new("Frame")
	line.Size = size
	line.Position = position
	line.AnchorPoint = Vector2.new(0.5, 0.5)
	line.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	line.BorderSizePixel = 0
	line.Parent = scopeFrame
end

createCrosshairLine(UDim2.new(1, 0, 0, 2), UDim2.new(0.5, 0, 0.5, 0))
createCrosshairLine(UDim2.new(0, 2, 1, 0), UDim2.new(0.5, 0, 0.5, 0))

local function setScoped(scoped: boolean)
	isZoomed = scoped
	scopeGui.Enabled = scoped

	if scoped then
		Camera.FieldOfView = SNIPER_ZOOM_FOV
		LocalPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
		
		if LocalPlayer.Character then
			for _, part in LocalPlayer.Character:GetDescendants() do
				if part:IsA("BasePart") then
					part.LocalTransparencyModifier = 1
				end
			end
		end
	else
		Camera.FieldOfView = NORMAL_FOV
		LocalPlayer.CameraMode = Enum.CameraMode.Classic
		
		-- Explicitly push the camera back out to third-person distance
		LocalPlayer.CameraMinZoomDistance = 10
		LocalPlayer.CameraMaxZoomDistance = 40
		Camera.CFrame = Camera.CFrame * CFrame.new(0, 0, 10) -- Pushes camera backward instantly
		
		if LocalPlayer.Character then
			for _, part in LocalPlayer.Character:GetDescendants() do
				if part:IsA("BasePart") then
					part.LocalTransparencyModifier = 0
				end
			end
		end
	end
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	local role = LocalPlayer:GetAttribute("Role")
	if role ~= "Sniper" then return end

	-- Right Click to Toggle Scope Zoom
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		setScoped(not isZoomed)
	end

	-- Left Click to Shoot (Raycast from exact center of camera view)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and isZoomed then
		local rayOrigin = Camera.CFrame.Position
		local rayDirection = Camera.CFrame.LookVector * 1000
		shootEvent:FireServer(rayOrigin, rayDirection)
	end
end)

RunService.RenderStepped:Connect(function()
	local role = LocalPlayer:GetAttribute("Role")
	if role ~= "Sniper" and isZoomed then
		setScoped(false)
	end
end)