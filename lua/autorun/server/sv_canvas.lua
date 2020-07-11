local tag = "Canvas"
canvas = canvas or {}

print("canvas | loading server file")

util.AddNetworkString(tag)

net.Receive(tag, function(_, ply)
    local state = net.ReadUInt(4)

    if state == canvas.NET_REQUEST_MODEL then
        if not ply.__canvas_didSpawn and hook.Run("PlayerSpawnSENT", ply, canvas.CLASS_NAME) == false then return end

        local size_index = net.ReadUInt(4)

        local tr       = ply:GetEyeTrace()
        local SpawnPos = tr.HitPos + tr.HitNormal * 8
        local Angles   = ply:EyeAngles()
        Angles.p = 0

        local ent = ents.Create(canvas.CLASS_NAME)
            ent:SetPos(SpawnPos)
            ent:SetAngles(Angles)
            ent:SetSize(size_index, true)
        ent:Spawn()
        ent:Activate()

        hook.Run("PlayerSpawnedSENT", ply, ent)
        if ply.AddCleanup then
            ply:AddCleanup(canvas.CLASS_NAME, ent)

            undo.Create(tag)
                undo.AddEntity(ent)
                undo.SetPlayer(ply)
            undo.Finish()
        end

        ply.__canvas_didSpawn = nil
    elseif state == canvas.NET_REQUEST_URL then
        local ent = net.ReadEntity()
        if not ent:IsValid() then return end

        local owner = ent:CPPIGetOwner()
        if ply ~= owner and not ply:IsAdmin() then return end

        local len = net.ReadUInt(16)
        if not len or len == 0 then return end

        local url = util.Decompress(net.ReadData(len))
        if not url then return end

        ent:SetURL(url)
    end
end)

function canvas.recreateAll()
    for _, v in ipairs(ents.FindByClass(canvas.CLASS_NAME)) do pcall(v.recreate, v) end
end
g_recreateAllCanvas = canvas.recreateAll -- back compat

hook.Add("RaidStart", "canvas-fade", function()
    for _, v in ipairs(ents.FindByClass(canvas.CLASS_NAME)) do
        if not IsValid(v:CPPIGetOwner()) or v:CPPIGetOwner():InRaid() then
            v:SetNotSolid(true)
        end
    end
end)

hook.Add("RaidEnded", "canvas-fade", function()
    for _, v in ipairs(ents.FindByClass(canvas.CLASS_NAME)) do v:SetNotSolid(false) end
end)
