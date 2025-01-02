local block = {}
block.__index = block

local blockTemplate = Instance.new("MeshPart") do
    blockTemplate.Size = Vector3.new(4.5,4.5,4.5)
    blockTemplate.BrickColor = BrickColor.new("Dark stone grey")
    blockTemplate.Anchored = true
    blockTemplate.CanCollide = true
    blockTemplate.Material = Enum.Material.SmoothPlastic
    blockTemplate.Position = Vector3.new(22.5, 2.25, -4.5)
end

function block.new()
    local self = setmetatable({}, block)
    self.Block = blockTemplate:Clone()
    self.Block.Parent = workspace
    self.Health = 500 -- How much health a block has

    return self
end

function block:TakeDamage(amount : number)
    self.Health -= amount
    if self.Health <= 0 then
        self:Destroy()
    end
end


function block:Destroy()
    self.Block:Destroy()
    table.clear(self)
    setmetatable(self, nil)
end

return block