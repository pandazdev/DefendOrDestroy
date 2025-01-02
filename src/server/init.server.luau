

local SETTINGS = {
	ProfileTemplate = {
		Cash = 0,
        BlocksPlacedAllTime = 0,
        Kills = 0,
        Wins = 0,
	}
}



----- Loaded Modules -----
local Blocks = {}

local Block = require(script.block)
local Collectors = require(script.collectors)
local Build = require(game:GetService("ReplicatedStorage").Shared.BuildFuncs)
local Team = require(game:GetService("ReplicatedStorage").Shared.Team)
local Crown = require(script.crown)
local ReplicaService = require(game:GetService("ServerScriptService").ReplicaService)
local ProfileService = require(game:GetService("ServerScriptService").ProfileService)

----- Private Variables -----
local DestroyerBarrier = game.Workspace.Useful["Destroyer Barrier"]
local BuilderBarrier = game.Workspace.Useful["Builder Barrier"]
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Teams = game:GetService("Teams")


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

local function RunFunctionOnProfiles(players, funcName, ...)
    for _, player in ipairs(players) do
        local player_profile = PlayerProfiles[player]
        if player_profile ~= nil then
            print(player_profile)
            player_profile[funcName](player_profile, ...)
        end
    end
end

local function BorderChange(bool) -- change the cancollide and the transparency of the texture inside the barrier
    if bool == true then
        BuilderBarrier.Barrier.CanCollide = true
        DestroyerBarrier.Barrier.CanCollide = true
    else
        BuilderBarrier.Barrier.CanCollide = false
        DestroyerBarrier.Barrier.CanCollide = false
    end
    for _, part in ipairs(BuilderBarrier.Barrier:GetChildren()) do
        part.Transparency = bool == true and 0.5 or 1
    end
    for _, part in DestroyerBarrier.Barrier:GetChildren() do
        part.Transparency = bool == true and 0.5 or 1
    end
end

local function Announcement(str)
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player:IsDescendantOf(Players) == false or not PlayerProfiles[player] then
            return
        end

        PlayerProfiles[player]:Announcement(str)
    end
    BuilderBarrier.Timer.SurfaceGui.Frame.TextLabel.Text = str
    DestroyerBarrier.Timer.SurfaceGui.Frame.TextLabel.Text = str
end

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
                    Data = {["Blocks"] = {}, ["TimeLeft"] = 0, ["Announcement"] = "", ["CanPlace"] = CanPlace, ["Team"] = "Lobby"},
                    Replication = "All"
                }),
				_player = player,
			}
			setmetatable(player_profile, PlayerProfile)
            PlayerProfiles[player] = player_profile
            Team.playerAdded(player, player_profile)
            player_profile.LocalReplica:ConnectOnServerEvent(function(plr, partPos) 
                player_profile:AttemptToPlaceAPart(partPos)
            end)
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

function PlayerProfile:AttemptToPlaceAPart( part_position)
    if self:IsActive() == false then
        return false
    end
    if self.LocalReplica.Data.CanPlace == false then
        return false
    end
    if #self.LocalReplica.Data.Blocks == 0 then
        return false
    end
    if not Build.IsSafe(self._player.Character.HumanoidRootPart.Position, part_position, {}) then
        return false
    end
    for k, part in Blocks do
        if part.Block == nil then
            Blocks[k] = nil
        elseif part.Block.Position == part_position then
            return false
        end
    end
    local block_name = table.remove(self.LocalReplica.Data.Blocks, 1)
    self.LocalReplica:SetValue({"Blocks"}, self.LocalReplica.Data.Blocks)
    local block = Block.new()
    block:MoveToPos(part_position)
    block:ConfigBlock(block_name)
    table.insert(Blocks, block)
end

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

function PlayerProfile:Announcement(str)
    if self:IsActive() == false then
        return
    end
    self.LocalReplica:SetValue({"Announcement"}, str)
end


----- Initialize -----

for _, player in ipairs(Players:GetPlayers()) do
    coroutine.wrap(PlayerAdded)(player)
end

task.spawn(function()
    -- while task.wait() do
    --     repeat
    --         task.wait(1)
    --     until #game.Players:GetPlayers() > 0
    --     print("Game started")
    --     Announcement("Choosing teams..") 
    --     Team.chooseTeams(game.Players:GetPlayers())
    --     task.wait(.1)
    --     BorderChange(true)
    --     print(Team.Builders, Team.Destroyers)
    --     RunFunctionOnProfiles(Team.Builders, "Announcement", "You are a Builder!")
    --     RunFunctionOnProfiles(Team.Destroyers, "Announcement", "You are a Destroyer!")
    --     task.wait(5)
    --     local CrownBlock = Crown.new()

    --     RunFunctionOnProfiles(Team.Builders, "CanPlace", true)
    --     RunFunctionOnProfiles(Team.Destroyers, "CanPlace", false)
    --     Announcement("Builders, build!")
    --     -- Let the builders build for 1 minutes, put a countdown on the screen, then let the destroyers destroy for 1 minute
    --     for i = 10, 0, -1 do
    --         task.wait(1)
    --         Announcement("Builders, build! Time left: " .. i)
    --     end
    --     RunFunctionOnProfiles(Team.Builders, "CanPlace", false)
    --     BorderChange(false)
    --     Announcement("Destroyers, DESTROY!")
    --     for i = 10, 0, -1 do
    --         task.wait(1)
    --         Announcement("Destroyers, DESTROY! Time left: " .. i)
    --         if not CrownBlock then
    --             break
    --         end
    --     end
    --     -- Make it so they can destroy the blocks
    --     local winner = "Builders"
    --     if CrownBlock.Block == nil then
    --         winner = "Destroyers"
    --     else
    --         CrownBlock:Destroy()
    --     end

    --     Announcement(winner .. " win!")
    --     for _, block in ipairs(Blocks) do 
    --         block:Destroy()
    --     end
    --     for i = 10, 0, -1 do
    --         task.wait(1)
    --         Announcement("Intermission! Time left: " .. i)
    --         if not CrownBlock then
    --             break
    --         end
    --     end
    -- end
    task.wait(5)
    RunFunctionOnProfiles(game.Players:GetPlayers(), "CanPlace", true)
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
    Team.playerLeft(player)
    local player_profile = PlayerProfiles[player]
    if player_profile ~= nil then
        player_profile.Profile:Release()
    end
end)

