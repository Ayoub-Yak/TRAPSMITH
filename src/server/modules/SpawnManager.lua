local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local getCurrentPhase: (() -> string)? = nil

type SpawnManagerApi = {
	init: (gameManagerRef: () -> string) -> (),
	teleport: (player: Player, character: Model) -> (),
	teleportActivePlayers: () -> (),
	updateRunnerSpawn: () -> (),
}

local SpawnManager: SpawnManagerApi = {} :: SpawnManagerApi

local MAX_RUNNERS = 10
local SEGMENT_LENGTH = 70
local BASE_RUNNER_SPAWN_POSITION = Vector3.new(-73, 2.3, 400)

function SpawnManager.init(gameManagerRef: () -> string)
	getCurrentPhase = gameManagerRef
end

local function getActiveRunnerCount(): number
	local count = 0
	for _, player in Players:GetPlayers() do
		if player:GetAttribute("Role") == "Runner"
			and player:GetAttribute("Spectating") ~= true then
			count += 1
		end
	end
	return count
end

function SpawnManager.updateRunnerSpawn()
	local map = Workspace:FindFirstChild("Map")
	local runnerSpawn = map and map:FindFirstChild("RunnerSpawn", true)
	if not runnerSpawn or not runnerSpawn:IsA("BasePart") then
		warn("[TRAPSMITH Spawn] RunnerSpawn not found; cannot scale the track.")
		return
	end

	local activeRunnerCount = math.clamp(getActiveRunnerCount(), 0, MAX_RUNNERS)
	local missingRunnerCount = MAX_RUNNERS - activeRunnerCount
	local zPosition = BASE_RUNNER_SPAWN_POSITION.Z - missingRunnerCount * SEGMENT_LENGTH
	runnerSpawn.CFrame = CFrame.new(
		Vector3.new(BASE_RUNNER_SPAWN_POSITION.X, BASE_RUNNER_SPAWN_POSITION.Y, zPosition)
	) * runnerSpawn.CFrame.Rotation
	runnerSpawn:SetAttribute("SegmentLength", SEGMENT_LENGTH)

	print(string.format(
		"[TRAPSMITH Spawn] RunnerSpawn moved to Z=%d for %d active Runner(s).",
		zPosition,
		activeRunnerCount
	))
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