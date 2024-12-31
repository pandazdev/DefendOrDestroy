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
end

----- Module Table -----

----- Loaded Modules -----

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
    local_rep:FireServer()
end)

local function PlacePreview()
    preview_part = blockTemplate:Clone()
    preview_part.Parent = workspace
    placing = true
    while canPlace and #local_rep.Blocks > 1 and rs.Heartbeat:Wait() do
        local pos = BuildFuncs.Snap(ms.Hit)
        preview_part.Position = pos
        if BuildFuncs.IsSafe(pos) then
            preview_part.Color = Color3.new(0,1,0)
            else
            preview_part.Color = Color3.new(1,0,0)
        end
    end
    placing = false
    preview_part:Destroy()
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
        local_rep = replica_data
        replica:ListenToChange({"Blocks"}, function(new_value)
            print(player_name .. " blocks changed:", new_value)
            if canPlace and placing == false then
                coroutine.wrap(PlacePreview)()
            end
        end)
        replica:ListenToChange({"CanPlace"}, function(new_value)
            canPlace = new_value
            if new_value == true then
                coroutine.wrap(PlacePreview)()
            end
        end)
    end
end)







