local tag = "Canvas"
canvas = canvas or {}

print("canvas | loading client file")

language.Add("Undone_" .. tag, "Undone Canvas")

function canvas.setupCvars()
    canvas.cvars = {}

    canvas.cvars.hentai       = CreateClientConVar("canvas_allow_hentai", "0", true, true, "Should canvas show shortcut for NSFW site and display images from it?")
    canvas.cvars.yiff_in_hell = CreateClientConVar("canvas_allow_disgusting_furry_shit", "0", true, true, "ew")
    canvas.cvars.gifs         = CreateClientConVar("canvas_allow_gif", "1", true, true, "Should canvas show gifs?")
    canvas.cvars.enabled      = CreateClientConVar("canvas_enabled", "1", true, true, "Should canvas draw at all?")
end

if not canvas.cvars then
    canvas.setupCvars()
end


local function createUI()
    local frame = vgui.Create("DFrame")
    frame:SetTitle("Model selection")

    local n = 0
    for k, mdl in ipairs(canvas.MODELS) do
        local spawn = frame:Add("SpawnIcon")
        spawn:SetSize(64, 64)
        spawn:Dock(LEFT)
        spawn:SetModel(mdl[1])

        spawn.DoClick = function(self)
            if IsValid(frame) then frame:Remove() end

            net.Start(tag)
                net.WriteUInt(canvas.NET_REQUEST_MODEL, 4)
                net.WriteUInt(k, 4)
            net.SendToServer()
        end

        n = n + 1
    end

    frame:SetSize((64 + 2) * n + 4, 64 + 34)

    frame:Center()
    frame:MakePopup()
end

local function openBrowser(url, jquery, callback)
    if IsValid(g_canvasBrowser) then g_canvasBrowser:Close() end

    g_canvasBrowser = vgui.Create("DFrame")
    local f = g_canvasBrowser
        f:SetSize(ScrW() - 100, ScrH() - 130)
        f:Center()
        f:MakePopup()
        f:SetVisible(false)
        f:SetDeleteOnClose(true)
        f:SetBackgroundBlur(true)

        f:SetTitle("")

        function f:Paint() end

    f.controls = vgui.Create("DHTMLControls", f)
    local c = f.controls
        c:Dock(TOP)

    f.html = vgui.Create("DHTML", f)
    local h = f.html
        h:Dock(FILL)
        h:SetAllowLua(true)

        h:AddFunction("canvas", "callback", function(href)
            callback(href)
            g_canvasBrowser:Close()
        end)

        function h:OnFinishLoadingDocument(str)
            self:RunJavascript("$('" .. jquery .. "').click(function() {canvas.callback($(this).attr('href'));})")
        end

    c:SetHTML(h)
    c.AddressBar:SetText(url)
    h:OpenURL(url)

    g_canvasBrowser:SetVisible(true)
    g_canvasBrowser:MoveToFront()

    g_canvasBrowser:MakePopup()
    g_canvasBrowser:DoModal()
end

function Derma_StringRequest_NoFocus( strTitle, strText, strDefaultText, fnEnter, fnCancel, strButtonText, strButtonCancelText )

    local Window = vgui.Create( "DFrame" )
    Window:SetTitle( strTitle or "Message Title (First Parameter)" )
    Window:SetDraggable( false )
    Window:ShowCloseButton( false )
    --Window:SetBackgroundBlur( true )
    --Window:SetDrawOnTop( true )

    local InnerPanel = vgui.Create( "DPanel", Window )
    InnerPanel:SetPaintBackground( false )

    local Text = vgui.Create( "DLabel", InnerPanel )
    Text:SetText( strText or "Message Text (Second Parameter)" )
    Text:SizeToContents()
    Text:SetContentAlignment( 5 )
    Text:SetTextColor( color_white )

    local TextEntry = vgui.Create( "DTextEntry", InnerPanel )
    TextEntry:SetText( strDefaultText or "" )
    TextEntry.OnEnter = function() Window:Close() fnEnter( TextEntry:GetValue() ) end

    local ButtonPanel = vgui.Create( "DPanel", Window )
    ButtonPanel:SetTall( 30 )
    ButtonPanel:SetPaintBackground( false )

    local Button = vgui.Create( "DButton", ButtonPanel )
    Button:SetText( strButtonText or "OK" )
    Button:SizeToContents()
    Button:SetTall( 20 )
    Button:SetWide( Button:GetWide() + 20 )
    Button:SetPos( 5, 5 )
    Button.DoClick = function() Window:Close() fnEnter( TextEntry:GetValue() ) end

    local ButtonCancel = vgui.Create( "DButton", ButtonPanel )
    ButtonCancel:SetText( strButtonCancelText or "Cancel" )
    ButtonCancel:SizeToContents()
    ButtonCancel:SetTall( 20 )
    ButtonCancel:SetWide( Button:GetWide() + 20 )
    ButtonCancel:SetPos( 5, 5 )
    ButtonCancel.DoClick = function() Window:Close() if ( fnCancel ) then fnCancel( TextEntry:GetValue() ) end end
    ButtonCancel:MoveRightOf( Button, 5 )

    ButtonPanel:SetWide( Button:GetWide() + 5 + ButtonCancel:GetWide() + 10 )

    local w, h = Text:GetSize()
    w = math.max( w, 400 )

    Window:SetSize( w + 50, h + 25 + 75 + 10 )
    Window:Center()

    InnerPanel:StretchToParent( 5, 25, 5, 45 )

    Text:StretchToParent( 5, 5, 5, 35 )

    TextEntry:StretchToParent( 5, nil, 5, nil )
    TextEntry:AlignBottom( 5 )

    TextEntry:RequestFocus()
    TextEntry:SelectAllText( true )

    ButtonPanel:CenterHorizontal()
    ButtonPanel:AlignBottom( 8 )

    Window:MakePopup()
    --Window:DoModal()

    return Window

end

net.Receive(tag, function()
    local state = net.ReadUInt(4)

    if state == canvas.NET_REQUEST_MODEL then
        createUI()
    elseif state == canvas.NET_REQUEST_URL then
        local ent = net.ReadEntity()
        if not ent:IsValid() then return end

        local pan = Derma_StringRequest_NoFocus("Input your URL",
[[WARNING: This must be THE IMAGE, ONLY THE IMAGE, AND NOTHING BUT THE IMAGE.
This means no google redirects, no blog posts, etc. Good URLs will probably end in a file extension.

Supported formats: PNG, JPG, GIF
NOTE: 'gif services' such as GIPHY are wrap their images in a HTML page, breaking support.]],
            ent:GetURL(),
            function(txt)
                ent:SendURL(txt)
            end
        )

        local sfw = vgui.Create("DButton", pan)
            sfw:SetText("Safebooru")
            sfw:SizeToContents()
            sfw:SetSize(sfw:GetWide() + 6, 20)
            function sfw:DoClick()
                openBrowser(
                    "https://safebooru.donmai.us/posts?utf8=✓",
                    [[a[href*=".donmai.us/data/"][id!="image-resize-link"]:first]],
                    function(txt)
                        ent:SendURL(txt)
                        pan:Close()
                    end
                )
            end

        local is_hentai = canvas.cvars.hentai:GetBool()

        local dan
        if is_hentai then
            dan = vgui.Create("DButton", pan)
                dan:SetText("Danbooru (NSFW)")
                dan:SizeToContents()
                dan:SetSize(dan:GetWide() + 6, 20)
                function dan:DoClick()
                    openBrowser(
                        "https://danbooru.donmai.us/posts?utf8=✓&tags=-rating:safe",
                        [[a[href*=".donmai.us/data/"][id!="image-resize-link"]:first]],
                        function(txt)
                            ent:SendURL(txt)
                            pan:Close()
                        end
                    )
                end
        end

        function pan:PerformLayout(w, h)
            DFrame.PerformLayout(self, w, h)

            sfw:SetPos(w - sfw:GetWide() - 2, 2)
            if is_hentai then dan:SetPos(w - dan:GetWide() - 2 - sfw:GetWide() - 2, 2) end
        end
    end
end)
