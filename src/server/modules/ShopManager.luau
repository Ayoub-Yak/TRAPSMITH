local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ShopManager = {}

type ShopItem = {
	Price: number,
}

local runnerItems: {[string]: ShopItem} = {
	SpeedBuff = { Price = 150 },
	Shield = { Price = 300 },
}

local sniperItems: {[string]: ShopItem} = {
	OneShotRounds = { Price = 400 },
	HiddenTraps = { Price = 250 },
}

local remotes = ReplicatedStorage:FindFirstChild("Remotes") or Instance.new("Folder")
remotes.Name = "Remotes"
remotes.Parent = ReplicatedStorage

local function getOrCreateRemote(name: string): RemoteEvent
	local remote = remotes:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end

	local newRemote = Instance.new("RemoteEvent")
	newRemote.Name = name
	newRemote.Parent = remotes
	return newRemote
end

local buyRunnerItem = getOrCreateRemote("BuyItem")
local buySniperItem = getOrCreateRemote("BuySniperItem")

local function setupCoins(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	if not leaderstats:FindFirstChild("Coins") then
		local coins = Instance.new("IntValue")
export type ShopItem = {
	DisplayName: string,
	Price: number,
}

local ItemCatalog: {[string]: ShopItem} = {
	SpeedBuff = {
		DisplayName = "Speed Boost",
		Price = 150,
	},
	Shield = {
		DisplayName = "Body Shield",
		Price = 300,
	},
}

local SniperItemCatalog: {[string]: ShopItem} = {
	OneShotRounds = {
		DisplayName = "One-Shot Rounds",
		Price = 400,
	},
	HiddenTraps = {
		DisplayName = "Hidden Traps",
		Price = 250,
	},
}

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local buyEvent = remotes:FindFirstChild("BuyItem")
if not buyEvent then
	buyEvent = Instance.new("RemoteEvent")
	buyEvent.Name = "BuyItem"
	buyEvent.Parent = remotes
end

local buySniperEvent = remotes:FindFirstChild("BuySniperItem")
if not buySniperEvent then
	buySniperEvent = Instance.new("RemoteEvent")
	buySniperEvent.Name = "BuySniperItem"
	buySniperEvent.Parent = remotes
end

local function setupLeaderstats(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end

	local coins = leaderstats:FindFirstChild("Coins")
	if not coins then
		coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Value = 500
		coins.Parent = leaderstats
	end
end

local function purchase(player: Player, itemId: any, role: string, catalog: {[string]: ShopItem})
	if player:GetAttribute("Role") ~= role or typeof(itemId) ~= "string" then
local function applyItem(player: Player, itemId: string)
	if itemId == "SpeedBuff" then
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 24
		end
	elseif itemId == "Shield" then
		player:SetAttribute("HasShield", true)
	end
end

local function applySniperItem(player: Player, itemId: string)
	if itemId == "OneShotRounds" then
		-- Placeholder for future custom bullet logic and ammunition assets.
		player:SetAttribute("HasOneShotRounds", true)
	elseif itemId == "HiddenTraps" then
		-- Replace this inventory attribute with real trap models when assets are ready.
		local currentTraps = player:GetAttribute("HiddenTrapInventory")
		local trapCount = if typeof(currentTraps) == "number" then currentTraps else 0
		player:SetAttribute("HiddenTrapInventory", trapCount + 1)
	end
end

local function processPurchase(
	player: Player,
	itemId: any,
	expectedRole: string,
	catalog: {[string]: ShopItem},
	applyPurchase: (Player, string) -> ()
)
	if player:GetAttribute("Role") ~= expectedRole or typeof(itemId) ~= "string" then
		return
	end

	local item = catalog[itemId]
	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if not item or not coins or not coins:IsA("IntValue") or coins.Value < item.Price then
	if not item then
		warn("[TRAPSMITH Shop] Invalid item requested by " .. player.Name .. ".")
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	local coins = leaderstats and leaderstats:FindFirstChild("Coins")
	if not coins or not coins:IsA("IntValue") then
		warn("[TRAPSMITH Shop] Coins not found for " .. player.Name .. ".")
		return
	end

	if coins.Value < item.Price then
		return
	end

	coins.Value -= item.Price
	if itemId == "SpeedBuff" then
		local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
		if humanoid then humanoid.WalkSpeed = 24 end
	elseif itemId == "Shield" then
		player:SetAttribute("HasShield", true)
	elseif itemId == "OneShotRounds" then
		player:SetAttribute("HasOneShotRounds", true)
	elseif itemId == "HiddenTraps" then
		local count = player:GetAttribute("HiddenTrapInventory")
		player:SetAttribute("HiddenTrapInventory", (if typeof(count) == "number" then count else 0) + 1)
	end
end

function ShopManager.init()
	for _, player in Players:GetPlayers() do setupCoins(player) end
	Players.PlayerAdded:Connect(setupCoins)
	buyRunnerItem.OnServerEvent:Connect(function(player, itemId)
		purchase(player, itemId, "Runner", runnerItems)
	end)
	buySniperItem.OnServerEvent:Connect(function(player, itemId)
		purchase(player, itemId, "Sniper", sniperItems)
	applyPurchase(player, itemId)
end

function ShopManager.init()
	for _, player in Players:GetPlayers() do
		setupLeaderstats(player)
	end

	Players.PlayerAdded:Connect(setupLeaderstats)

	buyEvent.OnServerEvent:Connect(function(player: Player, itemId: any)
		processPurchase(player, itemId, "Runner", ItemCatalog, applyItem)
	end)

	buySniperEvent.OnServerEvent:Connect(function(player: Player, itemId: any)
		processPurchase(player, itemId, "Sniper", SniperItemCatalog, applySniperItem)
	end)
end

return ShopManager
