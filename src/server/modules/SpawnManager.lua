local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local getCurrentPhase: (() -> string)? = nil

type SpawnManagerApi = {
	init: (gameManagerRef: () -> string) -> (),
	teleport: (player: Player, character: Model) -> (),
	teleportActivePlayers: () -> (),
}

local SpawnManager: SpawnManagerApi = {} :: SpawnManagerApi

function SpawnManager.init(gameManagerRef: () -> string)
	getCurrentPhase = gameManagerRef
end

local function getSpawnName(role: string?, phase: string): string
	if role == "Sniper" then
		if phase == "SafeZone"
			or phase == "RunnerPlacement"
			or phase == "SniperPlacement"
			or phase == "RunHuntCountdown" then
			return "SniperSafeZoneSpawn"
		end
		return "SniperSpawn"
	end

	if phase == "SafeZone"
		or phase == "RunnerPlacement"
		or phase == "SniperPlacement"
		or phase == "RunHuntCountdown" then
		return "RunnerSafeZoneSpawn"
	end
	return "RunnerSpawn"
end

function SpawnManager.teleport(player: Player, character: Model)
	if player:GetAttribute("Spectating") == true then
		return
	end

	local role = player:GetAttribute("Role")
	local map = Workspace:WaitForChild("Map", 10)

	if not map then
		warn("[TRAPSMITH Module] Map folder not found in Workspace!")
		return
	end

	local phase = if getCurrentPhase then getCurrentPhase() else "RunHunt"
	local targetSpawn = map:FindFirstChild(getSpawnName(role, phase), true)

	if targetSpawn and targetSpawn:IsA("BasePart") then
		character:PivotTo(targetSpawn.CFrame + Vector3.new(0, 3, 0))
		print("[TRAPSMITH Module] " .. player.Name .. " teleported to " .. targetSpawn.Name)
	else
		warn("[TRAPSMITH Module] Spawn point not found for role "
			.. tostring(role) .. " in phase " .. phase)
	end
end

function SpawnManager.teleportActivePlayers()
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("Spectating") ~= true
			and player.Character then
			SpawnManager.teleport(player, player.Character)
		end
	end
end

return SpawnManager