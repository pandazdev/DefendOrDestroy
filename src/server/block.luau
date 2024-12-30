local block = {}
block.__index = block

local Storage = Instance.new("Folder", game.ServerStorage)
Storage.Name = "PartStorage<SS/Block>"

local blockTemplate = Instance.new("Part") do
    blockTemplate.Size = Vector3.new(1,1,1)
    blockTemplate.BrickColor = BrickColor.new("Dark stone grey")
    blockTemplate.Anchored = true
    blockTemplate.CanCollide = false
end


function block.new()
    local self = setmetatable({}, block)
    self.Block = Storage:GetChildren()[1] or blockTemplate:Clone()
    self.Block.Parent = workspace

    self.Health = 100

    return self
end

function block:TakeDamage(amount : number)
    self.Health -= amount
    if self.Health >= 0 then
        self:Destory()
    end
 end

function block:Destory()
    self.Block:Destory()
    table.clear(self)
    setmetatable(self, nil)
end

return block