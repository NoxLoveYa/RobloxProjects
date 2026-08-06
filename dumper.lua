-- ===========================================================================
-- Holy Dumper v2 -- Universal game structure dumper
-- Works on ANY Roblox game, not just simulator/clicker genres
-- ===========================================================================

-- ---------- CONFIG ----------
local CONFIG = {
	OUT_ROOT         = "MCI_Dump",
	DO_SAVEINSTANCE  = false,   -- heavy: full-place .rbxl dump
	BATCH            = 15,      -- scripts per heartbeat; lower to 5 if it stutters
	SKIP_OVER_BYTES  = 9999999,  -- skip modules >400KB (needs getscriptbytecode)

	DO_TREE          = true,    -- _TREE.txt: game hierarchy
	DO_ATTRIBUTES    = true,    -- _ATTRIBUTES.txt (reads every instance)
	DO_TAGS          = true,    -- _TAGS.txt: CollectionService tags
	DO_JSON          = true,    -- _dump.json: machine-readable export
	DO_JSON_SCRIPTS  = false,   -- include script source bodies in JSON (huge)
	DO_PLAYER_STATE  = true,    -- _PLAYER_*.txt: character, backpack, gui, scripts
	DO_ASSETS        = true,    -- _ASSETS.txt: sounds, animations, effects
	DO_GUI_DUMP      = true,    -- _GUI.txt: ScreenGui/SurfaceGui/BillboardGui
	DO_DEPENDENCIES  = true,    -- _DEPENDENCIES.txt: require() graph
	DO_SERVER_DEC    = false,   -- try decompiling server Scripts (usually fails on client)
tDO_REMOTE_API    = true,    -- _REMOTE_API.txt: call signatures + heatmap
tDO_BYTECODE_DUMP = true,    -- dump .luac for skipped-large scripts
}

local SERVICES = {
	"Workspace", "ReplicatedStorage", "ReplicatedFirst", "StarterGui",
	"StarterPack", "StarterPlayer", "Players", "Lighting", "SoundService",
	"Chat", "TextChatService", "ServerStorage", "ServerScriptService",
	"CollectionService", "Teams",
}

local SKIP_TREE_CLASSES = {
	Script = true, LocalScript = true, ModuleScript = true,
}

	local AC_PATTERNS_SUBSTRING = {
		"AntiCheat", "AntiExploit", "AntiHack", "Anti%-Cheat", "Anticheat",
		"Detection", "Detector", "Moderator", "AdminCheck", "Sentinel",
		"Watchdog", "Validator", "SanityCheck", "RemoteSpy", "AntiInjection", "Integrity",
	}
	local AC_PATTERNS_WORD = {
		"Ban", "Kick", "Guard", "Verify", "AC_",
	}
	-- helper: frontier pattern word-boundary match
	local function acWordMatch(str, word)
		return str:find("%%f[%%a]" .. word:gsub("%-", "%%-") .. "%%f[%%a]") ~= nil
	end
	local GREP_PATTERNS = {
		"GiveUnits", "SetWins", "GiveWins", "Admin", "godmode",
		"runcode", "Teleport", "Free", "Bypass",
		"DeveloperProduct", "MarketplaceService", "HttpService",
		"FireServer", "InvokeServer", "FireClient", "InvokeClient",
	}

-- ---------- compat (same as v1) ----------
local function has(f) return typeof(f) == "function" end
local W  = has(writefile)    and writefile
local MF = has(makefolder)   and makefolder
local ISF= has(isfile)       and isfile
local DC = has(decompile)    and decompile
local GB = has(getscriptbytecode) and getscriptbytecode
local SI = has(saveinstance) and saveinstance
assert(W and MF, "executor lacks writefile/makefolder - cannot dump")

local Players     = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local CS = pcall(function() return game:GetService("CollectionService") end)
	and game:GetService("CollectionService") or nil

-- ---------- utilities ----------
local function sanitize(s)
	s = tostring(s):gsub('[<>:"/\\|%?%*%c]', "_")
	return (#s > 80) and s:sub(1, 80) or s
end
local function out(rel, text) W(CONFIG.OUT_ROOT .. "/" .. rel, text) end
local function relPath(inst)
	local parts, cur = {}, inst
	while cur and cur ~= game do
		table.insert(parts, 1, sanitize(cur.Name))
		cur = cur.Parent
	end
	return table.concat(parts, "/")
end

-- recursive hierarchy → indented lines
-- opts: {maxDepth=99, showClass=false, skipClasses={}, header=nil}
local function tree(inst, depth, opts, seen)
	opts = opts or {}
	local maxD = opts.maxDepth or 99
	local lines = {}
	if depth > maxD then return lines end
	seen = seen or {}
	if seen[inst] then
		table.insert(lines, string.rep("\t", depth) .. sanitize(inst.Name) .. " [CYCLE]")
		return lines
	end
	seen[inst] = true

	local label = sanitize(inst.Name)
	if opts.showClass then
		pcall(function()
			label = label .. " (" .. inst.ClassName .. ")"
		end)
	end
	table.insert(lines, string.rep("\t", depth) .. label)

	pcall(function()
		local children = inst:GetChildren()
		table.sort(children, function(a, b) return a.Name:lower() < b.Name:lower() end)
		for _, child in ipairs(children) do
			local ok, cls = pcall(function() return child.ClassName end)
			if ok and opts.skipClasses and opts.skipClasses[cls] then
				-- skip but still recurse into folders/models
				if cls == "Folder" or cls == "Model" or cls == "Configuration" then
					for _, line in ipairs(tree(child, depth + 1, opts, seen)) do
						table.insert(lines, line)
					end
				end
			else
				for _, line in ipairs(tree(child, depth + 1, opts, seen)) do
					table.insert(lines, line)
				end
			end
		end
	end)
	return lines
end

-- ---------- JSON encoder (no library, manual) ----------
local function jsonEscape(s)
	s = tostring(s)
	s = s:gsub("\\", "\\\\"):gsub('"', '\\"'):gsub("\n", "\\n")
		:gsub("\r", "\\r"):gsub("\t", "\\t"):gsub("\b", "\\b"):gsub("\f", "\\f")
	return s
end
local function jsonEncode(val, depth, seen)
	depth = (depth or 0) + 1
	if depth > 16 then return '"[[max depth]]"' end
	seen = seen or {}
	local t = type(val)
	if t == "nil" then return "null"
	elseif t == "boolean" then return val and "true" or "false"
	elseif t == "number" then return tostring(val)
	elseif t == "string" then return '"' .. jsonEscape(val) .. '"'
	elseif t == "table" then
		if seen[val] then return '"[[cyclic]]"' end
		seen[val] = true
		-- detect array (consecutive integer keys starting at 1)
		local isArr = true
		local count = 0
		for k, _ in pairs(val) do
			if type(k) ~= "number" or k < 1 or k > #val or k % 1 ~= 0 then
				isArr = false
			end
			count = count + 1
		end
		if count == 0 then return "[]" end
		if isArr then
			local parts = {}
			for i = 1, #val do
				table.insert(parts, jsonEncode(val[i], depth, seen))
			end
			return "[" .. table.concat(parts, ",") .. "]"
		else
			local parts = {}
			-- sort keys for stable output
			local skeys = {}
			for k in pairs(val) do table.insert(skeys, k) end
			table.sort(skeys, function(a, b) return tostring(a) < tostring(b) end)
			for _, k in ipairs(skeys) do
				local encK = jsonEncode(tostring(k), depth, seen)
				local encV = jsonEncode(val[k], depth, seen)
				table.insert(parts, encK .. ":" .. encV)
			end
			return "{" .. table.concat(parts, ",") .. "}"
		end
	else
		return '"[[' .. t .. ']]"'
	end
end
local function writeJSON(filename, tbl)
	out(filename, jsonEncode(tbl))
end

-- ---------- setup ----------
MF(CONFIG.OUT_ROOT)
MF(CONFIG.OUT_ROOT .. "/scripts")

-- ---------- Stage 1: gather ALL instances ----------
local seen, all = {}, {}
for _, svc in ipairs(SERVICES) do
	local ok, s = pcall(game.GetService, game, svc)
	if ok and s then
		for _, inst in ipairs(s:GetDescendants()) do
			if not seen[inst] then seen[inst] = true; table.insert(all, inst) end
		end
	end
end

local remotes, serverScripts, values, interactives, clientScripts = {}, {}, {}, {}, {}
local sounds, animations, effects, booleans = {}, {}, {}, {}
local guis, billboardGuis, touchInterests = {}, {}, {}
local acNameMatches = {}

for _, inst in ipairs(all) do
	local ok, cls = pcall(function() return inst.ClassName end)
	if ok then
	
		-- anti-cheat name scan (runs always, cheap)
			local instName = inst.Name:lower()
			local matched = false
			for _, pat in ipairs(AC_PATTERNS_SUBSTRING) do
				if instName:find(pat:lower(), 1, true) then matched = true; break end
			end
			if not matched then
				for _, pat in ipairs(AC_PATTERNS_WORD) do
					if acWordMatch(instName, pat:lower()) then matched = true; break end
				end
			end
			if matched then
				acNameMatches[#acNameMatches + 1] = { class = cls, path = inst:GetFullName() }
			end
	
		if cls == "RemoteEvent" or cls == "RemoteFunction" or cls == "UnreliableRemoteEvent"
			or cls == "BindableEvent" or cls == "BindableFunction" then
			table.insert(remotes, inst)
		elseif cls == "LocalScript" or cls == "ModuleScript" then
			table.insert(clientScripts, inst)
		elseif cls == "Script" then
			table.insert(serverScripts, inst)
		elseif cls:match("Value$") then
			table.insert(values, inst)
			if cls == "BoolValue" then table.insert(booleans, inst) end
		elseif cls == "ClickDetector" or cls == "ProximityPrompt"
			or cls == "TouchInterest" or cls == "TouchTransmitter" then
			table.insert(interactives, inst)
			if cls == "TouchInterest" or cls == "TouchTransmitter" then
				table.insert(touchInterests, inst)
			end
		elseif cls == "Sound" then
			table.insert(sounds, inst)
		elseif cls == "Animation" then
			table.insert(animations, inst)
		elseif cls:match("Emitter$") or cls == "Beam" or cls == "Trail" then
			table.insert(effects, inst)
		elseif cls:match("Gui$") then
			if cls == "BillboardGui" then
				table.insert(billboardGuis, inst)
			else
				table.insert(guis, inst)
			end
		end
	end
end

-- ---------- Stage 2: tags & attributes ----------
local tags = {}
if CONFIG.DO_TAGS and CS then
	pcall(function()
		local tagNames = CS:GetTags()
		for _, tag in ipairs(tagNames) do
			local tagged = {}
			pcall(function()
				for _, obj in ipairs(CS:GetTagged(tag)) do
					tagged[#tagged + 1] = obj:GetFullName()
				end
			end)
			tags[tag] = tagged
		end
	end)
end

local attrList = {} -- {{path, key, val}, ...}
if CONFIG.DO_ATTRIBUTES then
	for _, inst in ipairs(all) do
		pcall(function()
			local attrs = inst:GetAttributes()
			local has = false
			for _ in pairs(attrs) do has = true; break end
			if has then
				table.insert(attrList, {path = inst:GetFullName(), attrs = attrs})
			end
		end)
	end
end

-- ---------- Stage 3: instant output files ----------

-- 3a. _INFO.txt
do
	local placeName, placeVersion = "unknown", "?"
	pcall(function()
		placeName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
	end)
	pcall(function() placeVersion = tostring(game.PlaceVersion) end)

	local serviceStats = {}
	for _, svc in ipairs(SERVICES) do
		local ok, s = pcall(game.GetService, game, svc)
		if ok and s then
			local count = 0
			pcall(function() count = #s:GetDescendants() end)
			serviceStats[svc] = count
		end
	end

	local wsLines = {
		"FilteringEnabled  : " .. tostring(pcall(function() return game.Workspace.FilteringEnabled end) and game.Workspace.FilteringEnabled or "?"),
		"StreamingEnabled  : " .. tostring(pcall(function() return game.Workspace.StreamingEnabled end) and game.Workspace.StreamingEnabled or "?"),
		"Gravity           : " .. tostring(pcall(function() return game.Workspace.Gravity end) and game.Workspace.Gravity or "?"),
	}

	out("_INFO.txt", table.concat({
		"PlaceName    : " .. placeName,
		"PlaceId      : " .. tostring(game.PlaceId),
		"PlaceVersion : " .. placeVersion,
		"GameId       : " .. tostring(game.GameId),
		"JobId        : " .. tostring(game.JobId),
		"Player       : " .. (LocalPlayer and LocalPlayer.Name or "?"),
		"Time         : " .. os.date("%Y-%m-%d %H:%M:%S"),
		"Decompiler   : " .. (DC and "available" or "MISSING"),
		"Counts       : " .. ("%d client | %d server | %d remotes | %d values | %d interactives")
			:format(#clientScripts, #serverScripts, #remotes, #values, #interactives),
		"              : " .. ("%d sounds | %d animations | %d effects | %d GUIs | %d billboardGUIs | %d touchInterest")
			:format(#sounds, #animations, #effects, #guis, #billboardGuis, #touchInterests),
		"",
		"-- Workspace --",
		table.concat(wsLines, "\n"),
		"",
		"-- Instance counts per service --",
	}, "\n") .. "\n" .. (function()
		local slines = {}
		for _, svc in ipairs(SERVICES) do
			if serviceStats[svc] then
				table.insert(slines, ("  %-30s : %d"):format(svc, serviceStats[svc]))
			end
		end
		return table.concat(slines, "\n")
	end)())
end

-- 3b. _TREE.txt
if CONFIG.DO_TREE then
	local lines = tree(game, 0, {
		maxDepth = 6,
		showClass = true,
		skipClasses = SKIP_TREE_CLASSES,
	})
	out("_TREE.txt", table.concat(lines, "\n"))
end

-- 3c. _REMOTES.txt (grouped by parent)
do
	table.sort(remotes, function(a, b) return a:GetFullName():lower() < b:GetFullName():lower() end)
	local bindables, netRemotes = {}, {}
	for _, r in ipairs(remotes) do
		if r.ClassName == "BindableEvent" or r.ClassName == "BindableFunction" then
			table.insert(bindables, r)
		else
			table.insert(netRemotes, r)
		end
	end
	local lines = {"== Network Remotes (RemoteEvent / RemoteFunction / UnreliableRemoteEvent) ==", ""}
	local lastParent = nil
	for _, r in ipairs(netRemotes) do
		local parent = r.Parent and r.Parent:GetFullName() or "(orphan)"
		if parent ~= lastParent then
			table.insert(lines, "=== " .. parent .. " ===")
			lastParent = parent
		end
		table.insert(lines, "  [" .. r.ClassName .. "] " .. r.Name)
	end
	if #bindables > 0 then
		table.insert(lines, "")
		table.insert(lines, "== BindableEvents / BindableFunctions (internal, not network-visible) ==")
		table.insert(lines, "  NOTE: These fire within the same machine only -- not exploitable from client")
		table.insert(lines, "  Still useful for understanding server-internal architecture.")
		table.insert(lines, "")
		lastParent = nil
		for _, b in ipairs(bindables) do
			local parent = b.Parent and b.Parent:GetFullName() or "(orphan)"
			if parent ~= lastParent then
				table.insert(lines, "=== " .. parent .. " ===")
				lastParent = parent
			end
			table.insert(lines, "  [" .. b.ClassName .. "] " .. b.Name)
		end
	end
	out("_REMOTES.txt", table.concat(lines, "\n"))
end

-- 3d. _SERVER_SCRIPTS.txt
do
	local lines = {}
	for _, s in ipairs(serverScripts) do table.insert(lines, s:GetFullName()) end
	out("_SERVER_SCRIPTS.txt", table.concat(lines, "\n"))
end

-- 3e. _VALUES.txt (expanded)
do
	local lines = {}

	-- leaderstats
	local ls = LocalPlayer and LocalPlayer:FindFirstChild("leaderstats")
	if ls then
		table.insert(lines, "== leaderstats ==")
		for _, v in ipairs(ls:GetDescendants()) do
			if v:IsA("ValueBase") then
				local ok, val = pcall(function() return v.Value end)
				table.insert(lines, ("  %s = %s"):format(v:GetFullName(), ok and tostring(val) or "?"))
			end
		end
		table.insert(lines, "")
	end

	-- all BoolValues (feature flags / toggles)
	table.insert(lines, "== BoolValues / Boolean flag dump ==")
	for _, v in ipairs(booleans) do
		local ok, val = pcall(function() return v.Value end)
		table.insert(lines, ("  [%s] %s = %s"):format(v.ClassName, v:GetFullName(), ok and tostring(val) or "?"))
	end

	-- currency-looking values (heuristic)
	table.insert(lines, "")
	table.insert(lines, "== Currency-looking values ==")
	for _, v in ipairs(values) do
		local p = v:GetFullName()
		local l = p:lower()
		if l:find("money") or l:find("cash") or l:find("coin") or l:find("gem")
			or l:find("stat") or l:find("amount") or l:find("multi")
			or l:find("click") or l:find("rebirth") or l:find("level")
			or pcall(function() return v:IsDescendantOf(game:GetService("ReplicatedStorage")) end) then
			local ok, val = pcall(function() return v.Value end)
			table.insert(lines, ("  [%s] %s = %s"):format(v.ClassName, p, ok and tostring(val) or "?"))
		end
	end

	-- all remaining values
	table.insert(lines, "")
	table.insert(lines, "== All other values ==")
	for _, v in ipairs(values) do
		local p = v:GetFullName()
		local l = p:lower()
		if not (l:find("money") or l:find("cash") or l:find("coin") or l:find("gem")
			or l:find("stat") or l:find("amount") or l:find("multi")
			or l:find("click") or l:find("rebirth") or l:find("level")
			or pcall(function() return v:IsDescendantOf(game:GetService("ReplicatedStorage")) end)) then
			local ok, val = pcall(function() return v.Value end)
			table.insert(lines, ("  [%s] %s = %s"):format(v.ClassName, p, ok and tostring(val) or "?"))
		end
	end

	out("_VALUES.txt", table.concat(lines, "\n"))
end

-- 3f. _INTERACTIVES.txt (+ TouchInterest)
do
	local lines = {}
	for _, v in ipairs(interactives) do
		table.insert(lines, ("[%s] %s"):format(v.ClassName, v:GetFullName()))
	end
	if #touchInterests > 0 then
		table.insert(lines, "\n== TouchInterest / TouchTransmitter parents ==")
		local tiParents = {}
		for _, ti in ipairs(touchInterests) do
			tiParents[ti.Parent] = true
		end
		for p in pairs(tiParents) do
			table.insert(lines, "  " .. p:GetFullName())
		end
	end
	out("_INTERACTIVES.txt", table.concat(lines, "\n"))
end

-- 3g. _TAGS.txt
if CONFIG.DO_TAGS then
	local lines = {"[CollectionService Tags Report]", ""}
	if not CS then
		table.insert(lines, "CollectionService not available on this executor.")
	else
		local tagNames = {}
		for tag in pairs(tags) do table.insert(tagNames, tag) end
		table.sort(tagNames)
		if #tagNames == 0 then
			table.insert(lines, "No tags found in this game.")
		else
			for _, tag in ipairs(tagNames) do
				local insts = tags[tag]
				table.insert(lines, ("Tag: \"%s\" (%d instances)"):format(tag, #insts))
				for _, path in ipairs(insts) do
					table.insert(lines, "  " .. path)
				end
				table.insert(lines, "")
			end
		end
	end
	out("_TAGS.txt", table.concat(lines, "\n"))
end

-- 3h. _ATTRIBUTES.txt
if CONFIG.DO_ATTRIBUTES then
	local lines = {"[Instance Attributes Report -- only instances with non-empty attributes]", ""}
	for _, entry in ipairs(attrList) do
		table.insert(lines, entry.path .. " (" .. (function()
			local ks = {}
			for k in pairs(entry.attrs) do table.insert(ks, k) end
			return #ks .. " attributes"
		end)() .. ")")
		for k, v in pairs(entry.attrs) do
			table.insert(lines, ("  %s = %s"):format(tostring(k), tostring(v)))
		end
		table.insert(lines, "")
	end
	out("_ATTRIBUTES.txt", table.concat(lines, "\n"))
end

-- 3i. _ASSETS.txt
if CONFIG.DO_ASSETS then
	local lines = {}
	if #sounds > 0 then
		table.insert(lines, "== Sounds ==")
		for _, s in ipairs(sounds) do
			local id = "?"
			pcall(function() id = s.SoundId end)
			table.insert(lines, ("  [%s] %s  ->  %s"):format(s.ClassName, s:GetFullName(), id))
		end
		table.insert(lines, "")
	end
	if #animations > 0 then
		table.insert(lines, "== Animations ==")
		for _, a in ipairs(animations) do
			local id = "?"
			pcall(function() id = a.AnimationId end)
			table.insert(lines, ("  [%s] %s  ->  %s"):format(a.ClassName, a:GetFullName(), id))
		end
		table.insert(lines, "")
	end
	if #effects > 0 then
		table.insert(lines, "== Effects (Emitters / Beams / Trails) ==")
		for _, e in ipairs(effects) do
			local extra = ""
			pcall(function()
				if e.Texture and e.Texture ~= "" then
					extra = "  Texture=" .. e.Texture
				elseif e.Color then
					extra = "  Color=(" .. tostring(e.Color) .. ")"
				end
			end)
			table.insert(lines, ("  [%s] %s%s"):format(e.ClassName, e:GetFullName(), extra))
		end
	end
	out("_ASSETS.txt", table.concat(lines, "\n"))
end

-- 3j. _GUI.txt
if CONFIG.DO_GUI_DUMP then
	local lines = {}
	if #guis > 0 then
		table.insert(lines, "== ScreenGui / SurfaceGui ==")
		for _, g in ipairs(guis) do
			for _, line in ipairs(tree(g, 0, {maxDepth = 4, showClass = true})) do
				table.insert(lines, "  " .. line)
			end
			table.insert(lines, "")
		end
	end
	if #billboardGuis > 0 then
		table.insert(lines, "== BillboardGui ==")
		for _, b in ipairs(billboardGuis) do
			table.insert(lines, ("  [%s] %s  (parent: %s)"):format(b.ClassName, b.Name, b.Parent and b.Parent:GetFullName() or "?"))
		end
		table.insert(lines, "")
	end
	out("_GUI.txt", table.concat(lines, "\n"))
end

-- 3k. _ANTICHEAT.txt (name-based)
do
	local lines = {}
	if #acNameMatches > 0 then
		table.insert(lines, "== Instance names matching anti-cheat patterns (pre-decompile) ==")
		table.insert(lines, "")
		for _, m in ipairs(acNameMatches) do
			table.insert(lines, ("  [%s] %s"):format(m.class, m.path))
		end
	else
		table.insert(lines, "No instance names matched anti-cheat patterns.")
	end
	out("_ANTICHEAT.txt", table.concat(lines, "\n"))
end

-- 3l. Player state dumps
if CONFIG.DO_PLAYER_STATE and LocalPlayer then
	do
		local char = LocalPlayer.Character
		local lines = {}
		if char then
			lines = tree(char, 0, {maxDepth = 5, showClass = true})
		else
			lines = {"No character spawned."}
		end
		out("_PLAYER_CHARACTER.txt", table.concat(lines, "\n"))
	end
	do
		local bp = LocalPlayer:FindFirstChild("Backpack")
		local lines = {}
		if bp then
			lines = tree(bp, 0, {maxDepth = 3, showClass = true})
		else
			lines = {"No Backpack found."}
		end
		out("_PLAYER_BACKPACK.txt", table.concat(lines, "\n"))
	end
	do
		local pg = LocalPlayer:FindFirstChild("PlayerGui")
		local lines = {}
		if pg then
			lines = tree(pg, 0, {maxDepth = 5, showClass = true})
		else
			lines = {"No PlayerGui found."}
		end
		out("_PLAYER_PLAYERGUI.txt", table.concat(lines, "\n"))
	end
	do
		local ps = LocalPlayer:FindFirstChild("PlayerScripts")
		local lines = {}
		if ps then
			lines = tree(ps, 0, {maxDepth = 4, showClass = true})
		else
			lines = {"No PlayerScripts found."}
		end
		out("_PLAYER_PLAYERSCRIPTS.txt", table.concat(lines, "\n"))
	end
end

	-- 3m2. _PLAYER_STATS.txt (deep recursive stat walk)
	do
		local lines = {"[All Player Stats -- deep recursive walk]", ""}
		local function walkStats(inst, prefix)
			prefix = prefix or ""
			local fullPath = prefix == "" and inst.Name or prefix .. "/" .. inst.Name
			pcall(function()
				if inst:IsA("ValueBase") then
					table.insert(lines, ("  [%s] %s = %s"):format(inst.ClassName, fullPath, tostring(inst.Value)))
				end
			end)
			pcall(function()
				local children = inst:GetChildren()
				table.sort(children, function(a, b) return a.Name:lower() < b.Name:lower() end)
				for _, child in ipairs(children) do
					if child:IsA("ValueBase") or child:IsA("Folder") or child:IsA("Configuration") or child:IsA("Model") then
						walkStats(child, fullPath)
					end
				end
			end)
		end
		local roots = {
			LocalPlayer and LocalPlayer:FindFirstChild("leaderstats"),
			LocalPlayer and LocalPlayer:FindFirstChild("PlayerStats"),
			LocalPlayer and LocalPlayer:FindFirstChild("Stats"),
			LocalPlayer and LocalPlayer:FindFirstChild("stats"),
			LocalPlayer and LocalPlayer:FindFirstChild("inventory"),
		}
		for _, root in ipairs(roots) do
			if root then walkStats(root) end
		end
		out("_PLAYER_STATS.txt", table.concat(lines, "\n"))
	end

	-- 3m3. _UI_POSITIONS.txt (pixel-click automation data)
	if CONFIG.DO_PLAYER_STATE and LocalPlayer then
		local uiLines = {"[UI Element Positions -- for click-simulation cheats]", ""}
		local function walkUI(inst, depth)
			depth = depth or 0
			if depth > 6 then return end
			pcall(function()
				if inst:IsA("GuiObject") then
					local pos, size, visible = "?", "?", "?"
					pcall(function() pos = ("%d, %d"):format(inst.AbsolutePosition.X, inst.AbsolutePosition.Y) end)
					pcall(function() size = ("%d x %d"):format(inst.AbsoluteSize.X, inst.AbsoluteSize.Y) end)
					pcall(function() visible = tostring(inst.Visible) end)
					table.insert(uiLines, ("  [%s] %s"):format(inst.ClassName, inst:GetFullName()))
					table.insert(uiLines, ("    Pos: %s   Size: %s   Visible: %s"):format(pos, size, visible))
				end
			end)
			pcall(function()
				for _, child in ipairs(inst:GetChildren()) do
					walkUI(child, depth + 1)
				end
			end)
		end
		pcall(function()
			local pg = LocalPlayer:FindFirstChild("PlayerGui")
			if pg then walkUI(pg) end
		end)
		if #uiLines > 2 then
			out("_UI_POSITIONS.txt", table.concat(uiLines, "\n"))
		end
	end
-- 3m. _GLOBALS.txt (_G + shared keys)
do
	local gKeys, sharedKeys = {}, {}
	pcall(function() for k in pairs(_G) do gKeys[#gKeys + 1] = tostring(k) end end)
	pcall(function() for k in pairs(shared) do sharedKeys[#sharedKeys + 1] = tostring(k) end end)
	table.sort(gKeys)
	table.sort(sharedKeys)
	local lines = {}
	if #gKeys > 0 then
		table.insert(lines, "== _G keys ==")
		for _, k in ipairs(gKeys) do table.insert(lines, "  " .. k) end
		table.insert(lines, "")
	end
	if #sharedKeys > 0 then
		table.insert(lines, "== shared keys ==")
		for _, k in ipairs(sharedKeys) do table.insert(lines, "  " .. k) end
	end
	if #lines > 0 then
		out("_GLOBALS.txt", table.concat(lines, "\n"))
	end
end

print(("[dumper] stage A done: %d remotes, %d client scripts, %d values, %d tags, %d attrs, %d assets"):format(
	#remotes, #clientScripts, #values,
	(function() local n = 0; for _ in pairs(tags) do n = n + 1 end; return n end)(),
	#attrList, #sounds + #animations + #effects))

-- ===========================================================================
-- Stage 4: DECOMPILATION (batched, resumable, enhanced)
-- ===========================================================================

local SUSPICIOUS = {
	["RemoteCall"] = {"FireServer", "InvokeServer", "InvokeClient", "FireClient", "FireAllClients"},
	["Economy"]    = {"money", "cash", "coin", "balance", "gem", "currency", "gold", "diamond", "credit", "buck"},
	["Stats"]      = {"leaderstat", "addstat", "setstat", "updatestat", "getstat", "stat", "level", "xp", "exp", "experience"},
	["Admin"]      = {"admin", "mod", "kick", "ban", "god", "fly", "esp", "teleport", "noclip", "infinite", "give", "spawn"},
	["Combat"]     = {"damage", "health", "kill", "death", "hit", "attack", "weapon", "sword", "gun", "shoot", "explosion"},
	["Items"]      = {"purchase", "buy", "sell", "shop", "item", "inventory", "equip", "unequip", "skin", "pet", "hatch"},
	["Movement"]   = {"walkspeed", "jumppower", "speed", "teleport", "cframe", "position", "velocity", "fly", "noclip", "tween"},
}

	local remoteIndex = {}
	for _, r in ipairs(remotes) do
		remoteIndex[r.Name] = r:GetFullName()
	end
-- decompiled source cache for dependency analysis
local decompiledSources = {} -- [fullName] = sourceString
local requireMap = {}        -- [moduleFullName] = {requirerFullName, ...}

local function extractRequires(fullName, source)
	local mods = {}
	for rr in (source .. "\n"):gmatch("require%s*%(%s*(%d+)%s*%)") do
		-- numeric require (common in Roblox): require(123456789)
		mods[#mods + 1] = tostring(rr)
	end
	for rr in (source .. "\n"):gmatch("require%s*%(%s*script[%.:][^)]+%)") do
		-- path-based require: require(script.Parent.Utils)
		mods[#mods + 1] = rr
	end
	return mods
end

-- remote call extraction (cheat-dev tooling)
local remoteCallMap = {}     -- [resolvedName] = {{script, lineNum, method, args}, ...}
local remoteCallCount = {}   -- [resolvedName] = count (client->server only)
local grepMatches = {}       -- {{script, lineNum, line, pattern}, ...}

-- resolve a remote variable name to its full path using Stage 1 remotes bucket
local function resolveRemote(varName, remoteIndex)
	-- try exact match first
	if remoteIndex[varName] then return remoteIndex[varName] end
	-- strip prefix: self.net.SendMoney -> SendMoney, events.Sell -> Sell
	local stripped = varName:match("%.([^%.]+)$")
	if stripped and remoteIndex[stripped] then return remoteIndex[stripped] end
	-- try lowercase match
	local low = varName:lower()
	for rn, rp in pairs(remoteIndex) do
		if rn:lower() == low then return rp end
	end
	return nil
end

local LP = string.char(40)
local RP = string.char(41)
local function extractRemoteCalls(source, scriptPath, remoteIndex)
	local function scan(methodName)
		local prefix = methodName .. LP
		local pos = 1
		while true do
			local s, e = source:find(prefix, pos, true)
			if not s then break end
			-- find the matching closing paren (skip nested)
			local depth, cp = 1, e + 1
			while cp <= #source and depth > 0 do
				local ch = source:sub(cp, cp)
				if ch == LP then depth = depth + 1
				elseif ch == RP then depth = depth - 1
				end
				cp = cp + 1
			end
			local args = source:sub(e + 1, cp - 2):sub(1, 255)
			-- find the variable before the colon
			local before = source:sub(1, s - 1)
			local remoteVar = before:match("(%S+):$") or "?"
			local resolved = resolveRemote(remoteVar, remoteIndex)
			local name = resolved or remoteVar
			if not remoteCallMap[name] then remoteCallMap[name] = {} end
			table.insert(remoteCallMap[name], {
				script = scriptPath, method = methodName, args = args
			})
			if methodName == "FireServer" or methodName == "InvokeServer" then
				remoteCallCount[name] = (remoteCallCount[name] or 0) + 1
			end
			pos = cp
		end
	end
	scan("FireServer")
	scan("InvokeServer")
	scan("FireClient")
	scan("InvokeClient")	scan("InvokeClient")
	-- GREP scan per-line (single pass)
	if GREP_PATTERNS then
		local ln = 0
		for line in (source .. "\n"):gmatch("(.-)\n") do
			ln = ln + 1
			local low = line:lower()
			for _, pat in ipairs(GREP_PATTERNS) do
				if low:find(pat:lower(), 1, true) then
					table.insert(grepMatches, {
						script = scriptPath,
						lineNum = ln,
						line = line:gsub("^%s+", ""):sub(1, 200),
						pattern = pat,
					})
				end
			end
		end
	end
end

if DC then
	local indexLines, suspLines = {}, {}
	local usedPaths, done, skipped, failed = {}, 0, 0, 0

	for i, s in ipairs(clientScripts) do
		local okStep, errStep = pcall(function()
			if GB then
				local okB, bc = pcall(GB, s)
				if okB and type(bc) == "string" and #bc > CONFIG.SKIP_OVER_BYTES then
					skipped = skipped + 1
					table.insert(indexLines, ("[SKIP-big] %s (%d bytes)"):format(s:GetFullName(), #bc))
				if CONFIG.DO_BYTECODE_DUMP then
						MF(CONFIG.OUT_ROOT .. "/scripts/bytelarge")
						out("scripts/bytelarge/" .. relPath(s) .. ".luac", bc)
					end
					return
				end
			end

			local rel = relPath(s)
			local fileRel = "scripts/" .. rel .. ".lua"
			if usedPaths[fileRel] then
				local n = 2
				while usedPaths[fileRel:gsub("%.lua$", "") .. "_" .. n .. ".lua"] do n = n + 1 end
				fileRel = fileRel:gsub("%.lua$", "") .. "_" .. n .. ".lua"
			end
			usedPaths[fileRel] = true

			if ISF and ISF(CONFIG.OUT_ROOT .. "/" .. fileRel) then
				done = done + 1
				table.insert(indexLines, ("[RESUME-skip] %s"):format(s:GetFullName()))
				return
			end

			local acc = CONFIG.OUT_ROOT
			for seg in fileRel:gmatch("([^/]+)/") do acc = acc .. "/" .. seg; MF(acc) end

			local ok, src = pcall(DC, s)
			if ok and type(src) == "string" then
				out(fileRel, ("-- Dumped from: %s\n-- Class: %s\n\n"):format(s:GetFullName(), s.ClassName) .. src)
				done = done + 1
				decompiledSources[s:GetFullName()] = src

				-- dependency extraction (ModuleScripts only)
				if s.ClassName == "ModuleScript" then
					local reqs = extractRequires(s:GetFullName(), src)
					if #reqs > 0 then
						for _, r in ipairs(reqs) do
							if not requireMap[r] then requireMap[r] = {} end
							table.insert(requireMap[r], s:GetFullName())
						end
					end
				end
					-- remote API + GREP scan
					if CONFIG.DO_REMOTE_API then
						extractRemoteCalls(src, s:GetFullName(), remoteIndex)
					end

				-- categorized suspicious scan
				local categories = {}
				local hits, ln = {}, 0
				for line in (src .. "\n"):gmatch("(.-)\n") do
					ln = ln + 1
					local low = line:lower()
					for cat, kws in pairs(SUSPICIOUS) do
						for _, kw in ipairs(kws) do
							if low:find(kw:lower(), 1, true) then
								table.insert(hits, ("    L%d: %s"):format(ln, line:gsub("^%s+", ""):sub(1, 200)))
								categories[cat] = true
								break
							end
						end
					end
				end

				local catStr = ""
				if next(categories) then
					local catList = {}
					for cat in pairs(categories) do table.insert(catList, cat) end
					table.sort(catList)
					catStr = " [" .. table.concat(catList, ",") .. "]"
				end

				if #hits > 0 then
					table.insert(indexLines, ("[OK%s] %s  ->  %s"):format(catStr, s:GetFullName(), fileRel))
					table.insert(suspLines, ("== %s (%s)%s =="):format(s:GetFullName(), fileRel, catStr))
					for _, h in ipairs(hits) do table.insert(suspLines, h) end
					table.insert(suspLines, "")
				else
					table.insert(indexLines, ("[OK]   %s  ->  %s"):format(s:GetFullName(), fileRel))
				end
			else
				failed = failed + 1
				table.insert(indexLines, ("[FAIL] %s (%s)"):format(s:GetFullName(), tostring(src or "unknown error")))
			end
		end)
		if not okStep then
			failed = failed + 1
			table.insert(indexLines, ("[ERROR] %s"):format(tostring(errStep or "unknown error")))
		end

		if i % CONFIG.BATCH == 0 then
			out("_SCRIPTS_INDEX.txt", table.concat(indexLines, "\n"))
			out("_SUSPICIOUS.txt", table.concat(suspLines, "\n"))
			out("_PROGRESS.txt", ("%d/%d done=%d failed=%d skipped=%d"):format(i, #clientScripts, done, failed, skipped))
			print(("[dumper] %d/%d (done=%d failed=%d skipped=%d)"):format(i, #clientScripts, done, failed, skipped))
			task.wait()
		end
	end

	-- optional: attempt server scripts
	if CONFIG.DO_SERVER_DEC then
		local sDone, sFailed = 0, 0
		for i, s in ipairs(serverScripts) do
			local ok = pcall(function()
				local rel = "scripts/" .. relPath(s) .. ".server.lua"
				local okD, src = pcall(DC, s)
				if okD and type(src) == "string" then
					out(rel, ("-- Server script: %s\n-- Class: %s\n\n"):format(s:GetFullName(), s.ClassName) .. src)
					sDone = sDone + 1
					table.insert(indexLines, ("[SERVER-OK] %s  ->  %s"):format(s:GetFullName(), rel))
				else
					sFailed = sFailed + 1
					table.insert(indexLines, ("[SERVER-FAIL] %s (%s)"):format(s:GetFullName(), tostring(src or "?")))
				end
			end)
			if not ok then sFailed = sFailed + 1 end
			if i % CONFIG.BATCH == 0 then task.wait() end
		end
		print(("[dumper] server scripts: done=%d failed=%d"):format(sDone, sFailed))
	end

	-- write dependency map
	if CONFIG.DO_DEPENDENCIES then
		local depLines = {"[Dependency Map -- which scripts require() each ModuleScript]", ""}
		-- resolve numeric IDs to names
		local idToName = {}
		for _, s in ipairs(clientScripts) do
			if s.ClassName == "ModuleScript" then
				local nm = s:GetFullName()
				idToName[nm] = nm
			end
		end
		local sortedMods = {}
		for modRef in pairs(requireMap) do
			table.insert(sortedMods, modRef)
		end
		table.sort(sortedMods)

		if #sortedMods == 0 then
			table.insert(depLines, "No require() calls found in decompiled scripts.")
		else
			for _, modRef in ipairs(sortedMods) do
				local dependents = requireMap[modRef]
				table.insert(depLines, ("Module: %s (%d dependents)"):format(modRef, #dependents))
				for _, dep in ipairs(dependents) do
					table.insert(depLines, "  <= " .. dep)
				end
				table.insert(depLines, "")
			end
		end
		-- orphan modules (decompiled but never required)
		local orphans = {}
		for fullName in pairs(decompiledSources) do
			local s = nil
			for _, cs in ipairs(clientScripts) do
				if cs:GetFullName() == fullName then s = cs; break end
			end
			if s and s.ClassName == "ModuleScript" then
				local isDependent = false
				for _, dependents in pairs(requireMap) do
					for _, d in ipairs(dependents) do
						if d == fullName then isDependent = true; break end
					end
					if isDependent then break end
				end
				local usedAsRef = requireMap[fullName] ~= nil
				if not isDependent and not usedAsRef then
					table.insert(orphans, fullName)
				end
			end
		end
		if #orphans > 0 then
			table.insert(depLines, "[Orphan Modules] (never require()'d)")
			table.sort(orphans)
			for _, o in ipairs(orphans) do
				table.insert(depLines, "  " .. o)
			end
		end
		out("_DEPENDENCIES.txt", table.concat(depLines, "\n"))
	end

	-- append decompile-level anti-cheat hits to _ANTICHEAT.txt
	do
		local acSrcLines = {}
		for _, s in ipairs(clientScripts) do
				local src = decompiledSources[s:GetFullName()]
				if src then
					local srcLow = src:lower()
					local matched = false
					for _, pat in ipairs(AC_PATTERNS_SUBSTRING) do
						if srcLow:find(pat:lower(), 1, true) then matched = true; break end
					end
					if not matched then
						for _, pat in ipairs(AC_PATTERNS_WORD) do
							if srcLow:find("%%f[%%a]" .. pat:lower():gsub("%-", "%%-") .. "%%f[%%a]") then matched = true; break end
						end
					end
					if matched then
						acSrcLines[#acSrcLines + 1] = ("  [DECOMPILED] %s matches pattern"):format(s:GetFullName())
					end
				end
		end
		if #acSrcLines > 0 then
			local existing = ""
			pcall(function()
				existing = readfile(CONFIG.OUT_ROOT .. "/_ANTICHEAT.txt") or ""
			end)
			local parts = {existing}
			if #existing > 0 then table.insert(parts, "") end
			table.insert(parts, "== Script content matches (post-decompile) ==")
			table.insert(parts, "")
			for _, l in ipairs(acSrcLines) do table.insert(parts, l) end
			out("_ANTICHEAT.txt", table.concat(parts, "\n"))
		end
	end

		-- _REMOTE_API.txt (cheat-dev remote signatures + heatmap)
		if CONFIG.DO_REMOTE_API then
			local apiLines = {}
			-- split into client->server and server->client by method type
			local csEntries, scEntries = {}, {}
			for remoteName, callSites in pairs(remoteCallMap) do
				local isCS = false
				for _, cs in ipairs(callSites) do
					if cs.method == "FireServer" or cs.method == "InvokeServer" then
						isCS = true
						break
					end
				end
				if isCS then
					table.insert(csEntries, {name = remoteName, sites = callSites})
				else
					table.insert(scEntries, {name = remoteName, sites = callSites})
				end
			end
			table.sort(csEntries, function(a, b) return #a.sites > #b.sites end)
			table.sort(scEntries, function(a, b) return #a.sites > #b.sites end)

			if #csEntries > 0 then
				table.insert(apiLines, "=== Client->Server (callable from cheat) ==============================")
				table.insert(apiLines, "")
				for _, entry in ipairs(csEntries) do
					table.insert(apiLines, ("[%s]  (%d call sites)"):format(entry.name, #entry.sites))
					for _, cs in ipairs(entry.sites) do
						table.insert(apiLines, ("  -> %s"):format(cs.script))
						table.insert(apiLines, ("     %s(%s)"):format(cs.method, cs.args))
					end
					table.insert(apiLines, "")
				end
				-- heatmap
				table.insert(apiLines, "=== Call Frequency (client->server only, sorted) =====================")
				table.insert(apiLines, "")
				local freqList = {}
				for name, count in pairs(remoteCallCount) do
					table.insert(freqList, {name = name, count = count})
				end
				table.sort(freqList, function(a, b) return a.count > b.count end)
				for _, f in ipairs(freqList) do
					table.insert(apiLines, ("  %4d  %s"):format(f.count, f.name))
				end
			end
			if #scEntries > 0 then
				table.insert(apiLines, "")
				table.insert(apiLines, "=== Server->Client (monitoring only, NOT callable) =====================")
				table.insert(apiLines, "")
				for _, entry in ipairs(scEntries) do
					table.insert(apiLines, ("[%s]  (%d call sites)"):format(entry.name, #entry.sites))
					for _, cs in ipairs(entry.sites) do
						table.insert(apiLines, ("  -> %s"):format(cs.script))
						table.insert(apiLines, ("     %s(%s)"):format(cs.method, cs.args))
					end
					table.insert(apiLines, "")
				end
			end
			out("_REMOTE_API.txt", table.concat(apiLines, "\n"))
		end

		-- _GREP.txt (custom pattern search)
		if #grepMatches > 0 then
			local grepLines = {"[Custom GREP Pattern Matches]", ""}
			for _, m in ipairs(grepMatches) do
				table.insert(grepLines, ("[%s] %s:%d"):format(m.pattern, m.script, m.lineNum))
				table.insert(grepLines, ("  " .. m.line))
			end
			out("_GREP.txt", table.concat(grepLines, "\n"))
		end
	out("_SCRIPTS_INDEX.txt", table.concat(indexLines, "\n"))
	out("_SUSPICIOUS.txt", table.concat(suspLines, "\n"))
	out("_PROGRESS.txt", ("FINISHED %d/%d done=%d failed=%d skipped=%d"):format(#clientScripts, #clientScripts, done, failed, skipped))
else
	out("_PROGRESS.txt", "no decompile() on this executor - script source skipped")
	print("[dumper] no decompile() available - script source skipped")
end

-- ===========================================================================
-- Stage 5: JSON output
-- ===========================================================================
if CONFIG.DO_JSON then
	local json = {}

	-- info block
	json.info = {
		placeName = "unknown",
		placeId = game.PlaceId,
		placeVersion = pcall(function() return game.PlaceVersion end) and game.PlaceVersion or nil,
		gameId = game.GameId,
		jobId = game.JobId,
		playerName = LocalPlayer and LocalPlayer.Name or nil,
		time = os.date("%Y-%m-%d %H:%M:%S"),
		decompiler = DC ~= nil,
	}
	pcall(function()
		json.info.placeName = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
	end)
	pcall(function() json.info.placeVersion = game.PlaceVersion end)

	-- counts
	json.counts = {
		clientScripts = #clientScripts,
		serverScripts = #serverScripts,
		remotes = #remotes,
		values = #values,
		interactives = #interactives,
		sounds = #sounds,
		animations = #animations,
		effects = #effects,
		guis = #guis,
		billboardGuis = #billboardGuis,
		touchInterests = #touchInterests,
		tags = (function() local n = 0; for _ in pairs(tags) do n = n + 1 end; return n end)(),
		attributes = #attrList,
	}

	-- remotes (structured)
	json.remotes = {}
	for _, r in ipairs(remotes) do
		table.insert(json.remotes, {
			class = r.ClassName,
			path = r:GetFullName(),
			parent = r.Parent and r.Parent:GetFullName() or nil,
		})
	end

	-- booleans
	json.booleans = {}
	for _, v in ipairs(booleans) do
		local ok, val = pcall(function() return v.Value end)
		table.insert(json.booleans, {path = v:GetFullName(), value = ok and val or nil})
	end

	-- values (subset: currency-looking only, to keep json small)
	json.values = {}
	for _, v in ipairs(values) do
		local p = v:GetFullName()
		local l = p:lower()
		if l:find("money") or l:find("cash") or l:find("coin") or l:find("gem")
			or l:find("stat") or l:find("amount") or l:find("multi")
			or l:find("click") or l:find("rebirth") or l:find("level") then
			local ok, val = pcall(function() return v.Value end)
			table.insert(json.values, {class = v.ClassName, path = p, value = ok and tostring(val) or nil})
		end
	end

	-- tags
	json.tags = tags

	-- attributes
	json.attributes = {}
	for _, entry in ipairs(attrList) do
		local flat = {}
		for k, v in pairs(entry.attrs) do flat[tostring(k)] = tostring(v) end
		if next(flat) then
			table.insert(json.attributes, {path = entry.path, attributes = flat})
		end
	end

	-- assets
	json.assets = {sounds = {}, animations = {}, effects = {}}
	for _, s in ipairs(sounds) do
		local id = nil
		pcall(function() id = s.SoundId end)
		table.insert(json.assets.sounds, {path = s:GetFullName(), soundId = id})
	end
	for _, a in ipairs(animations) do
		local id = nil
		pcall(function() id = a.AnimationId end)
		table.insert(json.assets.animations, {path = a:GetFullName(), animationId = id})
	end
	for _, e in ipairs(effects) do
		table.insert(json.assets.effects, {class = e.ClassName, path = e:GetFullName()})
	end

	-- anti-cheat
	json.anticheat = {nameBased = {}}
	for _, m in ipairs(acNameMatches) do
		table.insert(json.anticheat.nameBased, {class = m.class, path = m.path})
	end

	-- player state
	if LocalPlayer then
		json.player = {}
		pcall(function()
			local char = LocalPlayer.Character
			if char then
				json.player.character = {name = char.Name, className = char.ClassName}
			end
		end)
	end

	-- workspace properties
	json.workspace = {}
	pcall(function() json.workspace.FilteringEnabled = game.Workspace.FilteringEnabled end)
	pcall(function() json.workspace.StreamingEnabled = game.Workspace.StreamingEnabled end)
	pcall(function() json.workspace.Gravity = game.Workspace.Gravity end)

	-- script sources (only if enabled)
	if CONFIG.DO_JSON_SCRIPTS then
		json.scripts = decompiledSources
	end

	writeJSON("_dump.json", json)
	print("[dumper] JSON written to _dump.json")
end

-- ===========================================================================
-- Stage 6: saveinstance (optional full-place dump)
-- ===========================================================================
if CONFIG.DO_SAVEINSTANCE and SI then
	print("[dumper] saveinstance running - game may freeze for minutes, do NOT close it")
	pcall(function()
		local ok2 = pcall(SI, { FileName = CONFIG.OUT_ROOT .. "/MCI_fullplace", Decompile = true, Noscripts = false })
		if not ok2 then SI(CONFIG.OUT_ROOT .. "/MCI_fullplace") end
	end)
end

print("[dumper] DONE -> workspace/" .. CONFIG.OUT_ROOT)
print("  Read order: _SUSPICIOUS.txt → _REMOTES.txt → _TAGS.txt → _ATTRIBUTES.txt → _VALUES.txt")
if CONFIG.DO_JSON then print("  Machine-readable: _dump.json") end
