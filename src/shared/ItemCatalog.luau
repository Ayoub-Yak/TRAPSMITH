export type ItemDefinition = {
	Id: string,
	Name: string,
	Price: number,
	ImageId: string,
	ModelName: string?,
	Description: string,
}

local PLACEHOLDER_IMAGE = "rbxassetid://0"
local BoostImage = "rbxassetid://102192484883138"

return {
	Runners = {
		{
			Id = "SpeedBuff",
			Name = "Speed Boost",
			Price = 150,
			ImageId = BoostImage,
			ModelName = nil,
			Description = "Increase movement speed to 24 for the round.",
		},
		{
			Id = "Shield",
			Name = "Body Shield",
			Price = 300,
			ImageId = PLACEHOLDER_IMAGE,
			ModelName = nil,
			Description = "Protect your Runner with a round shield.",
		},
	} :: {ItemDefinition},
	Sniper = {
		{
			Id = "OneShotRounds",
			Name = "One-Shot Rounds",
			Price = 400,
			ImageId = PLACEHOLDER_IMAGE,
			ModelName = nil,
			Description = "Placeholder ammunition for future custom bullet behavior.",
		},
		{
			Id = "HiddenTraps",
			Name = "Hidden Traps",
			Price = 250,
			ImageId = PLACEHOLDER_IMAGE,
			ModelName = "HiddenTrap",
			Description = "Adds one hidden trap to your inventory.",
		},
	} :: {ItemDefinition},
}
