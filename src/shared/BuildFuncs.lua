local Players = game:GetService("Players")
local build = {}
build.GRID = 4.5 -- Grid size

function build.Snap(hit)
    -- Snap to grid, every 4.5 studs
    local PosX = math.round(hit.X / build.GRID) * build.GRID
    local PosY = math.round(hit.Y / build.GRID) * build.GRID + 2.25
    local PosZ = math.round(hit.Z / build.GRID) * build.GRID
    return Vector3.new(PosX, PosY, PosZ)
end

function build.IsSafe(plrPos, pos, ignoreTable)
    if (plrPos - pos).Magnitude > 25 then
        return false
    end
    if pos.X < -50 or pos.X > 50 then
        return false
    end
    if pos.Z < -50 or pos.Z > 50 then
        return false
    end
    if pos.Y < 0.5 or pos.Y > 50 then
        return false
    end
    local parts = game.Workspace:GetPartBoundsInBox(CFrame.new(pos), Vector3.new(4.4, 4.4, 4.4))
    if #parts > 0 then
        for i, part in ipairs(parts) do
            if part ~= table.find(ignoreTable, part) then
                return false
            end
        end
        return false
    end
    return true
end

return build