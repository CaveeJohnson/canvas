local tag = "Canvas"
canvas = canvas or {}

canvas.SMALL_PLATE  = 1
canvas.NORMAL_PLATE = 2
canvas.BIG_PLATE    = 3
canvas.HUGE_PLATE   = 4
canvas.HOLYSHIT_PLATE = 5

-- image resolution, also makes text smaller, think of it like DPI
canvas.GLOBAL_SCALE = 2

canvas.MODELS = {
	[SMALL_PLATE   ] = {"models/hunter/plates/plate1x1.mdl", 1, "Small"},
	[NORMAL_PLATE  ] = {"models/hunter/plates/plate2x2.mdl", 2, "Normal"},
	[BIG_PLATE     ] = {"models/hunter/plates/plate3x3.mdl", 3, "Large"},
	[HUGE_PLATE    ] = {"models/hunter/plates/plate4x4.mdl", 4, "Huge"},
	[HOLYSHIT_PLATE] = {"models/hunter/plates/plate16x16.mdl", 16, "Holy Shit"},
}

canvas.TOOLPROP_WHITELIST = {
	["weld"] = true,
	["precision"] = true,
	["camera"] = true,
	["nocollide"] = true,
	["remover"] = true,

	["remove"] = true,
	["keepupright"] = true,
	["extinguish"] = true,
}

-- allowed forms, example bad.example.com
-- example
-- bad.example
-- bad.example.com
--
-- you can blacklist danbooru while not safebooru (same domain)
-- for example
canvas.DOMAIN_BLACKLIST = {

}

canvas.DRAW_WEPS = {
	["weapon_physgun"] = true,
	["gmod_tool"] = true,
}

canvas.HTML_FORMAT = [[<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
"http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
	<style>
		html, body {
			margin: 0;
		}

		img {
			text-align: center;
			position: absolute;
			margin: auto;
			top: 0;
			right: 0;
			bottom: 0;
			left: 0;

			max-width: 100%;
			max-height: 100%;
		}
	</style>
</head>
<body>
	<img src="{URL}"></img>
</body>
</html>
]]

canvas.NET_REQUEST_MODEL = 1
canvas.NET_REQUEST_URL   = 2

local URL_START   = "^https?://"
local PNG_HEADER  = "^\x89\x50\x4E\x47"
local JPG_HEADER  = "^\xFF\xD8"
local GIF_HEADER  = "^\x47\x49\x46\x38"
local WEBP_HEADER = "^\x52\x49\x46\x46"

local URL_PARSE_CACHE_DENY = {}
local URL_PARSE_CACHE_WAIT = {}

-- return good, loading
function canvas.validateUrl(url)
    -- if CLIENT and system.IsLinux() then return end
    if URL_PARSE_CACHE_DENY[url] then return false, URL_PARSE_CACHE_DENY[url] end

    local is_done = URL_PARSE_CACHE_WAIT[url]
    if is_done ~= nil then
        if not is_done then
            return false, "Loading..."
        end

        return true, nil
    end

    if not url:match(URL_START) then
        URL_PARSE_CACHE_DENY[url] = "Not a valid URL."
        return false, URL_PARSE_CACHE_DENY[url]
    end

    local domain = url:match(URL_START .. "(.-)/")
    if not domain then
        URL_PARSE_CACHE_DENY[url] = "Not a valid URL."
        return false, URL_PARSE_CACHE_DENY[url]
    end

    local domain_seg = domain:Split(".")
    local domain_seg_count = #domain_seg
    if
        DOMAIN_BLACKLIST[domain] or
        (domain_seg_count == 2 and DOMAIN_BLACKLIST[domain_seg[1]]) or
        DOMAIN_BLACKLIST[domain_seg[domain_seg_count-1]] or
        (domain_seg_count > 2 and DOMAIN_BLACKLIST[domain_seg[domain_seg_count-2] ..  "." .. domain_seg[domain_seg_count-1]])
    then
        URL_PARSE_CACHE_DENY[url] = "Blacklisted domain '" .. domain .. "'.'"
        return false, URL_PARSE_CACHE_DENY[url]
    end

    URL_PARSE_CACHE_WAIT[url] = false
    http.Fetch(url, function(body, size, headers, code)
        if code >= 400 and code < 600 then -- bad code
            URL_PARSE_CACHE_DENY[url] = "Failed to validate: http status " .. tostring(code)
            return
        end

        if not (body:match(PNG_HEADER) or body:match(JPG_HEADER) or body:match(GIF_HEADER) or body:match(WEBP_HEADER)) then
            URL_PARSE_CACHE_DENY[url] = "Failed to validate: not a recognised format"
            return
        end

        URL_PARSE_CACHE_WAIT[url] = true
    end, function(err)
        URL_PARSE_CACHE_DENY[url] = "Failed to validate: " .. err
    end)

    return false, "Loading..."
end
