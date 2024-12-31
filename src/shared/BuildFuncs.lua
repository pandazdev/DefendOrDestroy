local build = {}
build.GRID = 1

function build.Snap(hit)
    local PosX = math.floor(hit.X / build.GRID + 0.5 * build.GRID)
    local PosY = math.floor(hit.Y / build.GRID + 0.5 * build.GRID) + 0.5
    local PosZ = math.floor(hit.Z / build.GRID + 0.5 * build.GRID)
    return Vector3.new(PosX, PosY, PosZ)
end

function build.IsSafe(pos)
    if pos.X < -45 or pos.X > 50 then
        return false
    end
    if pos.Z < -50 or pos.Z > 50 then
        return false
    end
    if pos.Y < 0.5 or pos.Y > 50 then
        return false
    end
    return true
end

return build