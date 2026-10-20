-- src/server/modules/PlacementManager.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local PlacementManager = {}

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

function PlacementManager.init(gameManagerRef)
	print("[TRAPSMITH Module] PlacementManager initialized.")

	placeEvent.OnServerEvent:Connect(function(player, modelName, targetCFrame)
		local role = player:GetAttribute("Role")
		if role ~= "Runner" then
			warn(player.Name .. " tried to place an obstacle, but is not a Runner!")
			return
		end

		-- TODO: Check if current phase is 'Placement'
		-- TODO: Validate that targetCFrame is inside the player's assigned 20m segment[cite: 9]

		-- For now, let's test spawning a basic part/model in the Map workspace
		local map = Workspace:FindFirstChild("Map")
		if map then
			local newPart = Instance.new("Part")
			newPart.Size = Vector3.new(4, 4, 4)
			newPart.Position = targetCFrame.Position
			newPart.Anchored = true
			newPart.BrickColor = BrickColor.new("Bright orange")
			newPart.Parent = map
			print("[TRAPSMITH Module] Obstacle placed by " .. player.Name)
		end
	end)
end

return PlacementManager