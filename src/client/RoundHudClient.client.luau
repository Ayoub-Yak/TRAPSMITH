local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = Players.LocalPlayer
local phaseEvent = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("UpdatePhase") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "RoundHudGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local topBar = Instance.new("Frame")
topBar.Name = "TopBar"
topBar.Size = UDim2.new(1, 0, 0, 54)
topBar.BackgroundColor3 = Color3.fromRGB(14, 15, 20)
topBar.BackgroundTransparency = 0.08
topBar.BorderSizePixel = 0
topBar.Parent = gui

local phaseLabel = Instance.new("TextLabel")
phaseLabel.Size = UDim2.new(0.65, 0, 1, 0)
phaseLabel.Position = UDim2.fromOffset(24, 0)
phaseLabel.BackgroundTransparency = 1
phaseLabel.TextColor3 = Color3.new(1, 1, 1)
phaseLabel.Font = Enum.Font.GothamBold
phaseLabel.TextSize = 20
phaseLabel.TextXAlignment = Enum.TextXAlignment.Left
phaseLabel.Parent = topBar

local timerLabel = Instance.new("TextLabel")
timerLabel.Size = UDim2.new(0.25, 0, 1, 0)
timerLabel.Position = UDim2.new(0.72, 0, 0, 0)
timerLabel.BackgroundTransparency = 1
timerLabel.TextColor3 = Color3.fromRGB(255, 70, 85)
timerLabel.Font = Enum.Font.GothamBold
timerLabel.TextSize = 22
timerLabel.TextXAlignment = Enum.TextXAlignment.Right
timerLabel.Parent = topBar

local resultBanner = Instance.new("TextLabel")
resultBanner.Name = "ResultBanner"
resultBanner.AnchorPoint = Vector2.new(0.5, 0.5)
resultBanner.Position = UDim2.fromScale(0.5, 0.42)
resultBanner.Size = UDim2.fromOffset(560, 100)
resultBanner.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
resultBanner.BackgroundTransparency = 0.12
resultBanner.BorderColor3 = Color3.fromRGB(255, 70, 85)
resultBanner.BorderSizePixel = 2
resultBanner.TextColor3 = Color3.new(1, 1, 1)
resultBanner.Font = Enum.Font.GothamBold
resultBanner.TextSize = 34
resultBanner.Visible = false
resultBanner.Parent = gui

local previousPhase = ""
phaseEvent.OnClientEvent:Connect(function(phaseName: string, remaining: number, winner: string?)
	phaseLabel.Text = string.upper(phaseName)
	timerLabel.Text = string.format("%02d", remaining)

	if phaseName == "Resolution" and previousPhase ~= "Resolution" then
		local isRunner = LocalPlayer:GetAttribute("Role") == "Runner"
		local won = (winner == "Runners" and isRunner)
			or (winner == "Sniper" and not isRunner)
		resultBanner.Text = won and "VICTORY" or "DEFEAT"
		resultBanner.TextColor3 = if won
			then Color3.fromRGB(90, 255, 145)
			else Color3.fromRGB(255, 90, 100)
		resultBanner.Visible = true
	elseif phaseName ~= "Resolution" then
		resultBanner.Visible = false
	end

	previousPhase = phaseName
end)
