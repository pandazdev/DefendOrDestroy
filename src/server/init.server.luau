

local SETTINGS = {
	ProfileTemplate = {
		Cash = 0,
        BlocksPlacedAllTime = 0,
        Kills = 0,
        Wins = 0,
	}
}



----- Loaded Modules -----
local Block = require(script.block)
local Collectors = require(script.collectors)

local ReplicaService = require(game:GetService("ServerScriptService").ReplicaService)
local ProfileService = require(game:GetService("ServerScriptService").ProfileService)

----- Private Variables -----

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local PlayerProfileClassToken = ReplicaService.NewClassToken("PlayerProfile")
local PlayerBlockDataToken = ReplicaService.NewClassToken("GameData")

local CanPlace = false

local GameProfileStore = ProfileService.GetProfileStore(
	"PlayerData",
	SETTINGS.ProfileTemplate
)

local PlayerProfile -- PlayerProfile object
local PlayerProfiles = {} -- [player] = {Profile = profile, Replica = replica}

----- Private functions -----

local function PlayerAdded(player)
    local profile = GameProfileStore:LoadProfileAsync(
        "Player_" .. player.UserId,
        "ForceLoad"
    )
    if profile ~= nil then
		profile:AddUserId(player.UserId)
        profile:Reconcile()
		profile:ListenToRelease(function()
			PlayerProfiles[player].ProfileReplica:Destroy()
            PlayerProfiles[player].LocalReplica:Destroy()
            PlayerProfiles[player] = nil
            player:Kick()
        end)
		if player:IsDescendantOf(Players) == true then
			local player_profile = {
				Profile = profile,
				ProfileReplica = ReplicaService.NewReplica({
					ClassToken = PlayerProfileClassToken,
					Tags = {Player = player},
					Data = profile.Data,
					Replication = "All",
				}),
                LocalReplica = ReplicaService.NewReplica({
                    ClassToken = PlayerBlockDataToken,
                    Tags = {Player = player},
                    Data = {["Blocks"] = {}, ["TimeLeft"] = 0, ["Announcement"] = "", ["CanPlace"] = CanPlace},
                    Replication = "All"
                }),
				_player = player,
			}
			setmetatable(player_profile, PlayerProfile)
            PlayerProfiles[player] = player_profile
        else
            profile:Release()
        end
    else
        player:Kick() 
    end
end

----- Public functions -----

-- PlayerProfile object:
PlayerProfile = {
	--[[
		_player = player,
	--]]
}
PlayerProfile.__index = PlayerProfile

function PlayerProfile:GiveCash(cash_amount)
	if self:IsActive() == false then
		return
	end
	self.ProfileReplica:SetValue({"Cash"}, (self.ProfileReplica.Data.Cash or 0) + cash_amount)
end

function PlayerProfile:GiveBlock(block_name)
    if self:IsActive() == false then
        return
    end
    if #self.LocalReplica.Data.Blocks >= 5 then
        return
    end
    table.insert(self.LocalReplica.Data.Blocks, block_name)
    self.LocalReplica:SetValue({"Blocks"}, self.LocalReplica.Data.Blocks)
end

function  PlayerProfile:CanPlace(bool)
    if self:IsActive() == false then
        return
    end

    self.LocalReplica.Data.CanPlace = bool
    self.LocalReplica:SetValue({"CanPlace"}, self.LocalReplica.Data.CanPlace)
end

function PlayerProfile:IsActive() --> is_active
	return PlayerProfiles[self._player] ~= nil
end


----- Initialize -----

for _, player in ipairs(Players:GetPlayers()) do
    coroutine.wrap(PlayerAdded)(player)
end

task.spawn(function()
    task.wait(10)
    for _, player in Players:GetPlayers() do
        local player_profile = PlayerProfiles[player]
    if player_profile ~= nil then
        player_profile:CanPlace(true)
    end
    end
end)

----- Connections -----

Collectors.GiveBlockToPlayer:Connect(function(player, block_name)
    local player_profile = PlayerProfiles[player]
    if player_profile ~= nil then
        player_profile:GiveBlock(block_name)
    end
end)

Players.PlayerAdded:Connect(PlayerAdded)

Players.PlayerRemoving:Connect(function(player)
    local player_profile = PlayerProfiles[player]
    if player_profile ~= nil then
        player_profile.Profile:Release()
    end
end)

