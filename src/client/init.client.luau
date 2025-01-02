--[[
[Game]

-[ReplicaTestClient]---------------------------------------
	(ProfileServiceExample)
	Brief functionality test of ReplicaService; Client-side

	TO RUN THIS TEST:
		Setup ProfileService: https://madstudioroblox.github.io/ProfileService/tutorial/settingup/
		Parent:
			ReplicaTestServer -> ServerScriptService
			ReplicaTestClient -> StarterPlayerScripts
			TestWriteLib -> ReplicatedStorage
		(Only one test can be run at a time)

	What happens: 
		All players will receive a payout every 3 seconds. Cash is saved
		to the DataStore with ProfileService. We're going to replicate
		the cash state of individual players to everyone.
		
--]]

local SETTINGS = {

}


local blockTemplate = Instance.new("Part") do
    blockTemplate.Size = Vector3.new(4.5,4.5,4.5)
    blockTemplate.BrickColor = BrickColor.new("Dark stone grey")
    blockTemplate.Anchored = true
    blockTemplate.CanCollide = false
    blockTemplate.Material = Enum.Material.SmoothPlastic
    blockTemplate.Transparency = 0.5
    blockTemplate.Name = "BlockTemplate"
    blockTemplate.CanQuery  = false
end

----- Module Table -----

----- Loaded Modules -----
local Block = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("block"))
local ReplicaController = require(game:GetService("ReplicatedStorage"):WaitForChild("ReplicaController"))
local BuildFuncs = require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("BuildFuncs"))
----- Private Variables -----
local canPlace = nil
local local_rep = nil
local preview_part = nil
local placing = false

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local rs = game:GetService("RunService")
local ms = LocalPlayer:GetMouse()
----- Private functions -----

ms.Button1Down:Connect(function()
    if not placing then
        return
    end
    if not canPlace then
        return
    end
    if not BuildFuncs.IsSafe(LocalPlayer.Character.HumanoidRootPart.Position, preview_part.Block.Position, {preview_part.Block}) then
        return
    end
    local_rep:FireServer(preview_part.Block.Position)
end)

local function PlacePreview()
    preview_part = setmetatable({}, Block)
    preview_part.Block = blockTemplate:Clone()
    preview_part.Block.Parent = workspace
    preview_part.Health = 100 -- How much health a block has
    preview_part.Weight = 1 -- How much it subtracts from players walkspeed
    preview_part.PickUpTime = 1 -- Seconds
    setmetatable(preview_part, Block)
    preview_part.Block.Parent = workspace
    placing = true

    local lastTexture = nil
    while canPlace and #local_rep.Data.Blocks >= 1 and rs.Heartbeat:Wait() do
        -- if not local_rep.Data.Blocks[1] then
        --      return
        -- end
        -- if not canPlace == false then
        --     return
        -- end
        if lastTexture ~= local_rep.Data.Blocks[1] then
            lastTexture = local_rep.Data.Blocks[1]
            preview_part:ConfigBlock(lastTexture)
        end
        local origin = ms.UnitRay.Origin
        local direction = ms.UnitRay.Direction * 1000 -- Extend the ray far enough
    
    
        -- Create RaycastParams to ignore specific objects
        local raycastParams = RaycastParams.new()
        raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
        raycastParams.FilterDescendantsInstances = {preview_part.Block, LocalPlayer.Character, game.Workspace.Spawners, game.Workspace.Useful, game.Workspace.Map} -- Add parts or models to ignore
    
        -- Perform the raycast
        local raycastResult :RaycastResult = workspace:Raycast(origin, direction, raycastParams)
        if raycastResult and raycastResult.Position then  
                
            local pos = BuildFuncs.Snap(raycastResult.Position)
            preview_part.Block.Position = pos
            if BuildFuncs.IsSafe(LocalPlayer.Character.HumanoidRootPart.Position, pos, {preview_part.Block}) then
                preview_part.Block.Color = Color3.new(0,1,0)--Block.BlockConfigs[local_rep.Data.Blocks[1]].Color
            else
                preview_part.Block.Color = Color3.new(1,0,0)
            end
        end

    end
    placing = false
    preview_part.Block:Destroy()
    table.clear(preview_part)
    setmetatable(preview_part, nil)
end

----- Public functions -----

----- Initialize -----

ReplicaController.RequestData()

----- Connections -----


ReplicaController.ReplicaOfClassCreated("GameData", function(replica)
	local is_local = replica.Tags.Player == LocalPlayer
	local player_name = is_local and "your" or replica.Tags.Player.Name .. "'s"
	local replica_data = replica.Data

	print("Received " .. player_name .. " player game data, DATA:", replica_data)
    if is_local then
        local_rep = replica
        replica:ListenToChange({"Blocks"}, function(new_value)
            print(player_name .. " blocks changed:", new_value)
            if canPlace and placing == false then
                coroutine.wrap(PlacePreview)()
            end
        end)
        replica:ListenToChange({"CanPlace"}, function(new_value)
            print(player_name .. " can place changed:", new_value)
            canPlace = new_value
            if new_value == true then
                coroutine.wrap(PlacePreview)()
            end
        end)
        replica:ListenToChange({"Announcement"}, function(new_value)
            LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("Main"):WaitForChild("Top"):WaitForChild("TopFrame"):WaitForChild("AnnouncementFrame"):WaitForChild("Announcement").Text = new_value
        end)
    end
end)







