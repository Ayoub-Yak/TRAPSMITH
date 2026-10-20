-- src/client/PlacementClient.client.luau
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Wait for the RemoteEvent setup by PlacementManager
local remotes = ReplicatedStorage:WaitForChild("Remotes")
local placeEvent = remotes:WaitForChild("PlaceObstacle") :: RemoteEvent

-- Placement State
local ghostPart: Part? = nil

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
RunService.RenderStepped:Connect(function()
	local role = LocalPlayer:GetAttribute("Role")
	
	-- Only Runners can place
	if role ~= "Runner" then
		if ghostPart then
			ghostPart:Destroy()
			ghostPart = nil
		end
		return
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
		ghost.CFrame = CFrame.new(targetPos)
		ghost.Transparency = 0.4
	else
		ghost.Transparency = 1 -- Hide if pointing at sky
	end
end)

-- Detect Left Click to Place
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		local role = LocalPlayer:GetAttribute("Role")
		if role == "Runner" and ghostPart and ghostPart.Transparency < 1 then
			-- Send placement request to server
			placeEvent:FireServer("BasicBlock", ghostPart.CFrame)
			print("[TRAPSMITH Client] Sent placement request to server!")
		end
	end
end)