local tag = "Canvas"

ENT.Type        = "anim"
ENT.Base        = "base_anim"
ENT.ClassName   = canvas.CLASS_NAME

ENT.PrintName   = tag
ENT.Author      = "Q2F2\nZeni\nuser4992"
ENT.Purpose     = "Display your custom images."
ENT.Category    = "Fun + Games"
ENT.Spawnable   = true
ENT.AdminOnly   = true
ENT.RenderGroup = RENDERGROUP_TRANSLUCENT

function ENT:SetupDataTables()
    self:NetworkVar("String", 0, "URL")
    self:NetworkVar("Int", 0, "SizeIndex")
end

function ENT:CanConstruct()
    return false
end

function ENT:CanTool(_, _, tool)
    if canvas.TOOLPROP_WHITELIST[tool] then return end

    return false
end

function ENT:CanProperty(_, prop)
    if canvas.TOOLPROP_WHITELIST[prop] then return end

    return false
end

if SERVER then
    function ENT:SpawnFunction(ply, tr, ClassName)
        net.Start(tag)
            net.WriteUInt(canvas.NET_REQUEST_MODEL, 4)
        net.Send(ply)

        ply.__canvas_didSpawn = true
    end

    function ENT:Initialize()
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)
        self:SetUseType(SIMPLE_USE)
        self:SetCollisionGroup(COLLISION_GROUP_WEAPON)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:EnableMotion(false)
        end
    end

    local function requestURL(ply, ent)
        net.Start(tag)
            net.WriteUInt(canvas.NET_REQUEST_URL, 4)
            net.WriteEntity(ent)
        net.Send(ply)
    end

    function ENT:Use(_, ply)
        local owner = self:CPPIGetOwner()
        if ply ~= owner and not ply:IsAdmin() then ply:ChatPrint("You don't own this!") return end

        requestURL(ply, self)
    end

    function ENT:SetSize(size_index, dont_respawn)
        local mdl = canvas.MODELS[size_index]
        if not mdl then return false end

        self:SetModel(mdl[1])
        self:SetSizeIndex(size_index)

        if not dont_respawn then
            self:Spawn()
            self:Activate()
        end

        return true
    end

    function ENT:recreate()
        local new = ents.Create(canvas.CLASS_NAME)
            new:SetPos(self:GetPos())
            new:SetAngles(self:GetAngles())
            new:SetURL(self:GetURL())
            new:SetSize(self:GetSizeIndex(), true)
        new:Spawn()
        new:Activate()

        new:CPPISetOwner(self:CPPIGetOwner())

        self:Remove()
    end
else
    function ENT:Initialize()
        self:initPanel()
    end

    function ENT:initPanel()
        -- if CLIENT and system.IsLinux() then return end

        if IsValid(self.image_html) then self.image_html:Remove() end
        if IsValid(self.image_frame) then self.image_frame:Remove() end

        local frame = vgui.Create("DFrame")
            frame:SetSize(480 * canvas.GLOBAL_SCALE, 480 * canvas.GLOBAL_SCALE)
            frame:SetPaintedManually(true)
            frame:ShowCloseButton(false)
            frame:SetTitle("")
            frame.Paint = function() end

        local html = frame:Add("DHTML")
            frame.html = html

        frame.PerformLayout = function(this, w, h)
            if not IsValid(this.html) then return end

            this.html:SetPos(0, 0)
            this.html:SetSize(w, h)
        end

        self.image_frame = frame
        self.image_html  = html

        local url = self:GetURL()
        if url ~= "" then
            local good, _ = canvas.validateUrl(url)

            if good then
                self.image_html:SetHTML(canvas.HTML_FORMAT:Replace("{URL}", url))
                self._urlCached = url
            end
        end

        return IsValid(frame) and IsValid(html)
    end

    function ENT:invalidateCache()
        self._urlCached = nil
        self:initPanel()
    end

    local dist_sqr = 1500^2

    function ENT:DrawTranslucent()
        -- if CLIENT and system.IsLinux() then self:DrawModel() return end

        if not self.GetURL then return end -- late load hack
        if not canvas.cvars.enabled:GetBool() then
            if IsValid(self.image_html) then self.image_html:Remove() end
            if IsValid(self.image_frame) then self.image_frame:Remove() end

            self:DrawModel()
            return
        end

        --if LocalPlayer():GetPos():DistToSqr(self:GetPos()) > dist_sqr then return end

        local url = self:GetURL()
        if not self.image_frame:IsValid() and not self:initPanel() then error(tag .. ": Failed to created HTML panel") end

        local wep = LocalPlayer():GetActiveWeapon()
        local not_cached = not self._urlCached or self._urlCached ~= url
        if (IsValid(wep) and canvas.DRAW_WEPS[wep:GetClass()]) or not_cached then
            render.SetBlend(0.3)
                self:DrawModel()
            render.SetBlend(1)
        else
            self:DestroyShadow()
        end

        local size_index = self:GetSizeIndex()
        if size_index <= 0 then return end

        local _size = canvas.MODELS[size_index][2]
        local pos = self:GetPos()
        pos = pos + self:GetForward() * (23.975 * _size)
        pos = pos + self:GetUp() * -1.44
        pos = pos + self:GetRight() * (-23.975 * _size)

        local ang = self:GetAngles()
        ang:RotateAroundAxis(self:GetUp(), -90)

        cam.Start3D2D(pos, ang, _size / (10 * canvas.GLOBAL_SCALE))
            self:DrawDisplay(url, not_cached)
        cam.End3D2D()
    end

    function ENT:DrawDisplay(url, not_cached)
        if url == "" then
            draw.SimpleText("Press E to set URL.", "DermaLarge", 240 * canvas.GLOBAL_SCALE, 240 * canvas.GLOBAL_SCALE, nil, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        elseif not_cached then
            local good, msg = canvas.validateUrl(url)

            if good then
                self.image_html:SetHTML(canvas.HTML_FORMAT:Replace("{URL}", url))
                self._urlCached = url
            else
                draw.SimpleText(msg, "DermaLarge", 240 * canvas.GLOBAL_SCALE, 240 * canvas.GLOBAL_SCALE, nil, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
        else
            if not canvas.cvars.hentai:GetBool() and (
                (url:match("https?://.-%.donmai%.us") and not url:match("https?://safebooru%.donmai%.us")) or
                url:match("gelbooru") or url:match("hentai") or url:match("waifu2x") or url:match("shadbase")
            ) then
                draw.SimpleText("NSFW content hidden: canvas_allow_hentai 1", "DermaLarge", 240 * canvas.GLOBAL_SCALE, 240 * canvas.GLOBAL_SCALE, nil, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            elseif not canvas.cvars.yiff_in_hell:GetBool() and (
                url:match("e621") or url:match("facdn.net/art") or url:match("rule34.xxx")
            ) then
                draw.SimpleText("Furry content hidden: canvas_allow_disgusting_furry_shit 1", "DermaLarge", 240 * canvas.GLOBAL_SCALE, 240 * canvas.GLOBAL_SCALE, nil, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            elseif not canvas.cvars.gifs:GetBool() and url:match("gif$") then
                draw.SimpleText("GIF hidden: canvas_allow_gifs 1", "DermaLarge", 240 * canvas.GLOBAL_SCALE, 240 * canvas.GLOBAL_SCALE, nil, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            else
                self.image_frame:PaintManual()
            end
        end
    end

    local function compressData(data)
        local compressed = util.Compress(data)
        local len        = string.len(compressed)

        return len, compressed
    end

    function ENT:SendURL(url)
        net.Start(tag)
            net.WriteUInt(canvas.NET_REQUEST_URL, 4)
            net.WriteEntity(self)

            local len, data = compressData(url)
            net.WriteUInt(len, 16)
            net.WriteData(data, len)
        net.SendToServer()
    end

    function ENT:OnRemove()
        -- if CLIENT and system.IsLinux() then return end

        if self.image_html and self.image_html:IsValid() then
            self.image_html:Remove()
        end

        if self.image_frame and self.image_frame:IsValid() then
            self.image_frame:Remove()
        end
    end
end
