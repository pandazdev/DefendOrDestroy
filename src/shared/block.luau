local block = {}
block.__index = block




local blockTemplate = Instance.new("Part") do
    blockTemplate.Size = Vector3.new(4.5,4.5,4.5)
    blockTemplate.BrickColor = BrickColor.new("Dark stone grey")
    blockTemplate.Anchored = true
    blockTemplate.CanCollide = true
    blockTemplate.Material = Enum.Material.SmoothPlastic
end

export type TextureName = "Wood" | "Stone" | "Iron" | "Gold" | "Diamond"

block.BlockConfigs = {
    ["Wood"] = {
        ["Color"] = Color3.fromRGB(121, 87, 64),
        ["Texture"] = "rbxassetid://10024179514",
        ["TextureTransparency"] = 0.9,
        ["Health"] = 50,
        ["PickUpTime"] = 1
    },

    ["Stone"] = {
        ["Color"] = Color3.fromRGB(114, 123, 129),
        ["Texture"] = "rbxassetid://10045324955",
        ["TextureTransparency"] = 0.9,
        ["Health"] = 80,
        ["PickUpTime"] = 1
    },

    ["Iron"] = {
        ["Color"] = Color3.fromRGB(255, 255, 255),
        ["Texture"] = "rbxassetid://10044280909",
        ["TextureTransparency"] = 0.9,
        ["Health"] = 100,
        ["PickUpTime"] = 1
    },

    ["Gold"] = {
        ["Color"] = Color3.fromRGB(255, 156, 75),
        ["Texture"] = "rbxassetid://10025638200",
        ["TextureTransparency"] = 0.9,
        ["Health"] = 150,
        ["PickUpTime"] = 1
    },

    ["Diamond"] = {
        ["Color"] = Color3.fromRGB(46, 147, 255),
        ["Texture"] = "rbxassetid://10025641656",
        ["TextureTransparency"] = 0.8,
        ["Health"] = 200,
        ["PickUpTime"] = 1
    }
}

local Sides = {
    "Back",
    "Bottom",
    "Left",
    "Right",
    "Front",
    "Top"
}

function block.new()
    local self = setmetatable({}, block)
    self.Block = blockTemplate:Clone()
    self.Health = 100 -- How much health a block has
    self.Weight = 1 -- How much it subtracts from players walkspeed
    self.PickUpTime = 1 -- Seconds

    return self
end

function block:TakeDamage(amount : number)
    self.Health -= amount
    if self.Health <= 0 then
        self:Destroy()
    end
end

function block:MoveToPos(pos:Vector3)
    self.Block.Position = pos
end

function block:ModifyPosition(pos:Vector3)
    self.Block.Position += pos
end

function block:ConfigBlock(ConfigName: TextureName)
    local config = block.BlockConfigs[ConfigName]
    if not config then return end
    self.Block.Name = ConfigName
    self.Block.Color = config.Color
    self.Health = config.Health
    self.PickUpTime = config.PickUpTime

    for _, name in ipairs(Sides) do
        local existingTexture = self.Block:FindFirstChild(name)
        if existingTexture and existingTexture:IsA("Texture") then
            existingTexture.Texture = config.Texture
        else
            local texture = Instance.new("Texture")
            texture.Transparency = config.TextureTransparency
            texture.Face = Enum.NormalId[name]
            texture.Texture = config.Texture
            texture.Parent = self.Block
            texture.Name = name
            texture.StudsPerTileU = 9
            texture.StudsPerTileV = 9
        end
    end
end

function block:Destroy()
    self.Block:Destroy()
    table.clear(self)
    setmetatable(self, nil)
end

return block