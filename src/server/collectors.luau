local signal = require(game.ReplicatedStorage.Shared.FastSignal)
local BlocksConfig = require(game.ServerScriptService.Server.block).BlockConfigs

local Spawners = workspace.Spawners:GetChildren()
local Collectors = {}

Collectors.GiveBlockToPlayer = signal.new()
Collectors.PlayersInSpawners = {}

local function getPlayersInPart(part)
    local players = {}
    for _, player in pairs(game.Players:GetPlayers()) do
        local character = player.Character
        if character and character:FindFirstChild("HumanoidRootPart") then
            local rootPart = character:FindFirstChild("HumanoidRootPart")
            if part:IsA("BasePart") and part:IsDescendantOf(workspace) then
                local overlapParams = OverlapParams.new()
                overlapParams.FilterType = Enum.RaycastFilterType.Include
                overlapParams.FilterDescendantsInstances = {rootPart}
                local partsInPart = workspace:GetPartsInPart(part, overlapParams)
                if #partsInPart > 0 then
                    table.insert(players, player.Name)
                end
            end
        end
    end
    return players
end

for _, object in Spawners do
    if not BlocksConfig[object.Name] then return end
    local config = BlocksConfig[object.Name]
    local pickupTime = config.PickUpTime
    local hitBox = object:FindFirstChild("Hitbox")

    if hitBox then
        local collectingPlayers = {}

        game:GetService("RunService").Heartbeat:Connect(function()
            local playersInPart = getPlayersInPart(hitBox)

            -- Handle players entering the hitbox
            for _, playerName in ipairs(playersInPart) do
                if not collectingPlayers[playerName] then
                    collectingPlayers[playerName] = {
                        StartTime = os.clock(),
                        Progress = 0
                    }
                end
            end

            -- Handle players leaving the hitbox
            for playerName, data in pairs(collectingPlayers) do
                if not table.find(playersInPart, playerName) then
                    collectingPlayers[playerName] = nil
                end
            end

            -- Update progress for players in the hitbox
            for playerName, data in pairs(collectingPlayers) do
                local elapsedTime = os.clock() - data.StartTime
                if elapsedTime >= pickupTime then
                    -- Player successfully collects the block
                    print("Player successfully collects the ",object.Name,"!")
                    Collectors.GiveBlockToPlayer:Fire(game.Players[playerName], object.Name)
                    collectingPlayers[playerName] = nil
                else
                    data.Progress = elapsedTime / pickupTime
                end
            end
        end)
    end
end

return Collectors
