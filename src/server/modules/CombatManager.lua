-- src/server/modules/CombatManager.lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local _Workspace = game:GetService("Workspace")

local CombatManager = {}

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local shootEvent = remotes:FindFirstChild("SniperShoot")
if not shootEvent then
	shootEvent = Instance.new("RemoteEvent")
	shootEvent.Name = "SniperShoot"
	shootEvent.Parent = remotes
end

function CombatManager.init()
	print("[TRAPSMITH Module] CombatManager initialized.")

	shootEvent.OnServerEvent:Connect(function(player, rayOrigin, rayDirection)
		local role = player:GetAttribute("Role")
		if role ~= "Sniper" then
			warn(player.Name .. " tried to fire sniper rifle, but is not the Sniper!")
			return
		end

		local character = player.Character
		if not character then return end

		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Exclude
		raycastParams.FilterDescendantsInstances = {character}

		local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

		if result and result.Instance then
			local hitPart = result.Instance
			local hitModel = hitPart:FindFirstAncestorWhichIsA("Model")

			if hitModel then
				local humanoid = hitModel:FindFirstChildOfClass("Humanoid")
				if humanoid then
					-- Deal 500 damage (Runners have 1000 HP, so 2 hits defeat them)
					humanoid.Health = math.max(0, humanoid.Health - 500)
					print("[TRAPSMITH Combat] Sniper hit " .. hitModel.Name .. " for 500 damage! Remaining HP: " .. humanoid.Health)
				end
			end
		end
	end)
end

return CombatManager