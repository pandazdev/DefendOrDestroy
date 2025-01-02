local Teams = {}

local LobbySpawn = game.Workspace.Useful.LobbySpawn
local DestroyerSpawn = game.Workspace.Useful.DestroyerSpawn
local BuilderSpawn = game.Workspace.Useful.BuilderSpawn

Teams.Lobby = {}
Teams.Destroyers = {}
Teams.Builders = {}

local PPs = {}

-- Function to remove a player from all teams
local function removePlayerFromAllTeams(player)
    for i, p in ipairs(Teams.Lobby) do
        if p == player then
            table.remove(Teams.Lobby, i)
            break
        end
    end
    for i, p in ipairs(Teams.Destroyers) do
        if p == player then
            table.remove(Teams.Destroyers, i)
            break
        end
    end
    for i, p in ipairs(Teams.Builders) do
        if p == player then
            table.remove(Teams.Builders, i)
            break
        end
    end
end

-- Function to choose teams
function Teams.chooseTeams(players)
    -- Clear previous teams
    Teams.Destroyers = {}
    Teams.Builders = {}

    -- Shuffle players
    local shuffledPlayers = {}
    for i, player in ipairs(players) do
        local pos = math.random(1, #shuffledPlayers + 1)
        table.insert(shuffledPlayers, pos, player)
        print(player, pos)
    end

    -- Split players into two teams
    local half = math.ceil(#shuffledPlayers / 2)
    for i, player in ipairs(shuffledPlayers) do
        print(player, i, half)
        if i <= half then
            player.Character.HumanoidRootPart.CFrame = BuilderSpawn.CFrame
            table.insert(Teams.Builders, player)
            if PPs[player] then
                print("Changed")
                PPs[player].LocalReplica.Data.Team = "Builders"
            end
            print("Builder")
        else
            player.Character.HumanoidRootPart.CFrame = DestroyerSpawn.CFrame
            table.insert(Teams.Destroyers, player)
            if PPs[player] then
                PPs[player].LocalReplica.Data.Team = "Destroyers"
            end
        end
    end
end

-- Function to change everyone to lobby
function Teams.changeEveryoneToLobby()
    for _, player in ipairs(Teams.Destroyers) do
        player.Character.HumanoidRootPart.CFrame = LobbySpawn.CFrame
        table.insert(Teams.Lobby, player)
        if PPs[player] then
            PPs[player].LocalReplica.Data.Team = "Lobby"
        end
    end
    for _, player in ipairs(Teams.Builders) do
        player.Character.HumanoidRootPart.CFrame = LobbySpawn.CFrame
        table.insert(Teams.Lobby, player)
        if PPs[player] then
            PPs[player].LocalReplica.Data.Team = "Lobby"
        end
    end
    Teams.Destroyers = {}
    Teams.Builders = {}
end

-- Function to handle player added
function Teams.playerAdded(player, player_profile)
    removePlayerFromAllTeams(player)
    table.insert(Teams.Lobby, player)
    player_profile.LocalReplica.Data.Team = "Lobby"
    PPs[player] = player_profile
end

-- Function to handle player left
function Teams.playerLeft(player)
    removePlayerFromAllTeams(player)
    if PPs[player] then
        PPs[player] = nil
    end
end

return Teams
