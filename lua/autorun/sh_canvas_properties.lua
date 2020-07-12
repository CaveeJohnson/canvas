local canvas_order = 3300

local function addProp(name, config)
	config.Order = canvas_order
	canvas_order = canvas_order + 1

	properties.Add(name, config)
end

local function isCanvas(_, ent, ply)
	return IsValid(ent) and IsValid(ply) and ent.GetURL and ent:GetURL() ~= ""
end

local function isCanvas2(_, ent, ply)
	return IsValid(ent) and IsValid(ply) and ent.GetURL
end

addProp(tag .. "-copyurl", {
	MenuLabel =	"Copy URL",
	MenuIcon  = "icon16/link_edit.png",
	Filter    = isCanvas,

	Action    = function(_, ent)
		SetClipboardText(ent:GetURL())
	end
})

addProp(tag .. "-openurl", {
	MenuLabel =	"Open URL",
	MenuIcon  = "icon16/link_go.png",
	Filter    = isCanvas,

	Action    = function(_, ent)
		gui.OpenURL(ent:GetURL())
	end
})

addProp(tag .. "-invalidatecache", {
	MenuLabel =	"Invalidate Cache",
	MenuIcon  = "icon16/error.png",
	Filter    = isCanvas,

	Action    = function(_, ent)
		ent:invalidateCache()
	end
})

addProp(tag .. "-changesize", {
	MenuLabel = "Change Size",
	MenuIcon = "icon16/picture_edit.png",
	Filter = function(_, ent, ply)
		return isCanvas2(_, ent, ply) and (
			ent:CPPIGetOwner() == CPPI.CPPI_NOTIMPLEMENTED or -- fucking retards who dont follow spec :V
			ent:CPPIGetOwner() == ply
		)
	end,

	MenuOpen = function(prop, option, ent)
		local submenu = option:AddSubMenu()

		for index, v in SortedPairsByMemberValue(canvas.MODELS, 2) do
			submenu:AddOption(v[3], function()
				prop:MsgStart()
					net.WriteEntity(ent)
					net.WriteUInt(index, 4)
				prop:MsgEnd()
			end):SetChecked(ent:GetSizeIndex() == index)
		end
	end,

	Receive = function(prop, _, ply)
		local ent = net.ReadEntity()
		local size_index = net.ReadUInt(4)

		if not properties.CanBeTargeted(ent, ply) then return end
		if not prop:Filter(ent, ply) then return end

		ent:SetSize(size_index)
	end
})
