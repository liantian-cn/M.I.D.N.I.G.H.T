-- LibNicknameShare-1.0
-- Central nickname hub with bridge support (shared comms + external libs)

local MAJOR, MINOR = "LibNicknameShare-1.0", 3
local lib = LibStub:NewLibrary(MAJOR, MINOR)
if not lib then return end

local SEND_PREFIX = "EQNICK"
local LOGGED_PREFIX = "EQNICK_LOG"
local OP_REQUEST = "R"
local OP_NICK = "N"
local NSRT_PREFIX = "NSI_MSG"
local NSRT_WHISPER_PREFIX = "NSI_WHISPER"
local NSRT_NICK_EVENT = "NSI_NICKNAMES_COMMS:"
local NSRT_SYNC_EVENT = "NSI_NICKNAMES_SYNC:"
local NICKTAG_PREFIX = "NickTag"
local SHARED_MAX_NICK_CHARS = 24
local CACHE_MAX_NICK_CHARS = 64
local REQUEST_COOLDOWN = 5

local SOURCE_SHARED = "SHARED"
local SOURCE_NSRT = "NSRT"
local SOURCE_CUSTOMNAMES = "CUSTOMNAMES"
local SOURCE_NICKTAG = "NICKTAG"

local floor = math.floor
local issecretvalue = _G.issecretvalue
local canaccessvalue = _G.canaccessvalue

lib.SharedData = lib.SharedData or {}
lib.UnitData = lib.SharedData -- compatibility alias
lib.SourceData = lib.SourceData or {}
lib.SourceData[SOURCE_SHARED] = lib.SourceData[SOURCE_SHARED] or lib.SharedData
lib.CanonicalData = lib.CanonicalData or {}

lib._sourceHandlers = lib._sourceHandlers or {}
lib._sourceMeta = lib._sourceMeta or {}
lib.SourceSettings = lib.SourceSettings or {
	enabled = {},
	order = {},
	resolveMode = "LAST_WRITE",
}

lib._callbacks = lib._callbacks or {
	NicknameUpdate = {},
	NicknameWipe = {},
	MyNicknameChanged = {},
	SourcesChanged = {},
	NicknameCanonicalChanged = {},
	DebugLog = {},
	DebugToggled = {},
}

lib._myNickname = lib._myNickname or ""
lib._pendingRequest = lib._pendingRequest or false
lib._pendingShare = lib._pendingShare or false
lib._pendingRosterSync = lib._pendingRosterSync or false
lib._lastRequestAt = lib._lastRequestAt or 0

lib.Debug = lib.Debug or {
	enabled = false,
	chat = true,
	keep = 200,
	logs = {},
}
lib._debugSeq = lib._debugSeq or 0
lib._debugResolveState = lib._debugResolveState or {}
lib._canonicalSeq = lib._canonicalSeq or 0
lib._syncInProgress = lib._syncInProgress or false

lib._receiverReady = lib._receiverReady or false
lib._initialized = lib._initialized or false

local serializer, deflate, aceComm

local function IsSecret(v)
	return issecretvalue and issecretvalue(v)
end

local function CanRead(v)
	if IsSecret(v) then return false end
	if not canaccessvalue then return true end
	local ok, result = pcall(canaccessvalue, v)
	if not ok then return false end
	return result ~= false
end

local function InCombat()
	return InCombatLockdown and InCombatLockdown()
end

local function GetOwnRealm()
	local realm = (GetNormalizedRealmName and GetNormalizedRealmName()) or (GetRealmName and GetRealmName()) or ""
	if IsSecret(realm) or not CanRead(realm) then return nil end
	realm = tostring(realm or ""):gsub("%s", "")
	if realm == "" then return nil end
	return realm
end

local function NormalizeRealm(realm)
	if not realm then return nil end
	if IsSecret(realm) or not CanRead(realm) then return nil end
	realm = tostring(realm):gsub("%s", "")
	if realm == "" then return nil end
	return realm
end

local function NormalizeName(name)
	if not name then return nil end
	if IsSecret(name) or not CanRead(name) then return nil end
	name = tostring(name)
	if name == "" then return nil end
	return name
end

local function BuildNameKeys(nameInput, assumeOwnRealm)
	local name = NormalizeName(nameInput)
	if not name then return nil, nil, nil, nil end

	local base, realm = name:match("^([^%-]+)%-(.+)$")
	base = NormalizeName(base)
	realm = NormalizeRealm(realm)
	if base and realm then
		local full = base .. "-" .. realm
		local short = (realm == GetOwnRealm()) and base or nil
		return full, short, base, realm
	end

	if assumeOwnRealm then
		local ownRealm = GetOwnRealm()
		if ownRealm then return name .. "-" .. ownRealm, name, name, ownRealm end
	end

	return name, nil, name, nil
end

local function GetOwnNameKeys()
	local playerName, playerRealm = UnitFullName and UnitFullName("player")
	playerName = NormalizeName(playerName)
	playerRealm = NormalizeRealm(playerRealm) or GetOwnRealm()
	if not (playerName and playerRealm) then return nil, nil end
	return playerName .. "-" .. playerRealm, playerName
end

local function SafeEquals(a, b)
	if not a or not b then return false end
	if IsSecret(a) or IsSecret(b) then return false end
	if not (CanRead(a) and CanRead(b)) then return false end
	return a == b
end

local function GroupChannel()
	if IsInRaid and IsInRaid() then
		if IsInGroup and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
		return "RAID"
	end
	if IsInGroup and IsInGroup() then
		if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
		return "PARTY"
	end
	return nil
end

local function IsGroupPlayerUnit(unit)
	if not unit or not UnitExists or not UnitExists(unit) then return false end
	if UnitIsPlayer and not UnitIsPlayer(unit) then return false end
	if UnitIsUnit and UnitIsUnit(unit, "player") then return true end
	if UnitInRaid and UnitInRaid(unit) then return true end
	if UnitInParty and UnitInParty(unit) then return true end
	return false
end

local function IsNSRTNicknameMessage(prefix, text)
	if prefix ~= NSRT_PREFIX and prefix ~= NSRT_WHISPER_PREFIX then return false end
	if not text or IsSecret(text) or not CanRead(text) then return false end
	if type(text) ~= "string" then return false end
	return text:find("^" .. NSRT_NICK_EVENT) ~= nil or text:find("^" .. NSRT_SYNC_EVENT) ~= nil
end

local function IsNickTagMessage(prefix, text)
	if prefix ~= NICKTAG_PREFIX then return false end
	if not text or IsSecret(text) or not CanRead(text) then return false end
	return type(text) == "string"
end

local function IsRestricted()
	if C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret() then
		return true
	end

	local eqol = _G.EnhanceQoL
	local isRestrictedContent = eqol and eqol.functions and eqol.functions.isRestrictedContent
	if type(isRestrictedContent) == "function" then
		local ok, restricted = pcall(isRestrictedContent, true)
		if ok and restricted == true then return true end
	end

	local restrictionTypes = Enum and Enum.AddOnRestrictionType
	local restrictedActions = _G.C_RestrictedActions
	if restrictionTypes and restrictedActions and restrictedActions.GetAddOnRestrictionState then
		for _, v in pairs(restrictionTypes) do
			if v ~= 4 and restrictedActions.GetAddOnRestrictionState(v) == 2 then
				return true
			end
		end
	end

	return false
end

local function RefreshCommLibs()
	serializer = serializer or LibStub:GetLibrary("AceSerializer-3.0", true)
	deflate = deflate or LibStub:GetLibrary("LibDeflate", true)
	aceComm = aceComm or LibStub:GetLibrary("AceComm-3.0", true)
	return serializer, deflate, aceComm
end

local function Fire(event, ...)
	local t = lib._callbacks[event]
	if not t then return end
	for i = 1, #t do
		local obj, meth = t[i][1], t[i][2]
		local fn = type(meth) == "function" and meth or (obj and obj[meth])
		if fn then pcall(fn, obj, ...) end
	end
end

local function CopyTableShallow(src)
	local out = {}
	if type(src) ~= "table" then return out end
	for k, v in pairs(src) do
		out[k] = v
	end
	return out
end

local function DebugSafeString(v, maxLen)
	if v == nil then return "nil" end
	if type(v) == "string" then
		if IsSecret(v) then return "<secret>" end
		if not CanRead(v) then return "<restricted>" end
		local s = v:gsub("\n", "\\n")
		if maxLen and maxLen > 0 and #s > maxLen then
			s = s:sub(1, maxLen) .. "..."
		end
		return s
	end
	if type(v) == "number" or type(v) == "boolean" then return tostring(v) end
	if type(v) == "table" then return "<table>" end
	local ok, s = pcall(tostring, v)
	if ok then return s end
	return "<value>"
end

local function PersistDebugSettings()
	local eqol = _G.EnhanceQoL
	local db = eqol and eqol.db
	if type(db) ~= "table" then return end
	db.nicknameShareDebug = lib.Debug.enabled == true
	db.nicknameShareDebugChat = lib.Debug.chat ~= false
	db.nicknameShareDebugKeep = tonumber(lib.Debug.keep) or 200
end

local function ReadPersistedDebugSettings()
	local eqol = _G.EnhanceQoL
	local db = eqol and eqol.db
	if type(db) ~= "table" then return end

	if db.nicknameShareDebug ~= nil then
		lib.Debug.enabled = db.nicknameShareDebug == true
	end
	if db.nicknameShareDebugChat ~= nil then
		lib.Debug.chat = db.nicknameShareDebugChat ~= false
	end
	if type(db.nicknameShareDebugKeep) == "number" then
		local keep = floor(db.nicknameShareDebugKeep)
		if keep < 20 then keep = 20 end
		if keep > 2000 then keep = 2000 end
		lib.Debug.keep = keep
	end
end

local function DebugLog(kind, message, data)
	if not (lib.Debug and lib.Debug.enabled == true) then return end

	lib._debugSeq = (lib._debugSeq or 0) + 1
	local entry = {
		seq = lib._debugSeq,
		at = (GetServerTime and GetServerTime()) or (GetTime and floor(GetTime())) or 0,
		kind = kind or "info",
		message = message or "",
		data = (type(data) == "table") and CopyTableShallow(data) or data,
	}

	local logs = lib.Debug.logs
	logs[#logs + 1] = entry
	local keep = tonumber(lib.Debug.keep) or 200
	while #logs > keep do
		table.remove(logs, 1)
	end

	if lib.Debug.chat ~= false then
		local prefix = "|cff00ff98Enhance QoL|r [NickHub]"
		local line = string.format("%s [%s] %s", prefix, DebugSafeString(entry.kind, 24), DebugSafeString(entry.message, 220))
		print(line)
	end

	Fire("DebugLog", entry)
end

function lib.GetDebugEnabled()
	return lib.Debug and lib.Debug.enabled == true
end

function lib.GetDebugChatEnabled()
	return lib.Debug and lib.Debug.chat ~= false
end

function lib.SetDebugEnabled(enabled, chatOutput, persist)
	if not lib.Debug then lib.Debug = { enabled = false, chat = true, keep = 200, logs = {} } end
	lib.Debug.enabled = enabled == true
	if chatOutput ~= nil then
		lib.Debug.chat = chatOutput ~= false
	end
	if persist ~= false then PersistDebugSettings() end
	Fire("DebugToggled", lib.Debug.enabled, lib.Debug.chat)
	DebugLog("state", lib.Debug.enabled and "debug enabled" or "debug disabled", {
		chat = lib.Debug.chat ~= false,
	})
	return lib.Debug.enabled
end

function lib.SetDebugChatEnabled(enabled, persist)
	if not lib.Debug then lib.Debug = { enabled = false, chat = true, keep = 200, logs = {} } end
	lib.Debug.chat = enabled ~= false
	if persist ~= false then PersistDebugSettings() end
	Fire("DebugToggled", lib.Debug.enabled == true, lib.Debug.chat ~= false)
	DebugLog("state", "debug chat output changed", {
		chat = lib.Debug.chat ~= false,
	})
	return lib.Debug.chat ~= false
end

function lib.SetDebugLogLimit(keep, persist)
	keep = tonumber(keep) or 200
	keep = floor(keep)
	if keep < 20 then keep = 20 end
	if keep > 2000 then keep = 2000 end
	lib.Debug.keep = keep
	if persist ~= false then PersistDebugSettings() end
	DebugLog("state", "debug log limit changed", { keep = keep })
	return keep
end

function lib.ClearDebugLogs()
	lib.Debug.logs = {}
	lib._debugResolveState = {}
end

function lib.GetDebugLogs(limit)
	local logs = lib.Debug.logs or {}
	if not limit then
		local out = {}
		for i = 1, #logs do
			out[i] = logs[i]
		end
		return out
	end
	local n = floor(tonumber(limit) or 0)
	if n <= 0 then return {} end
	local out = {}
	local start = #logs - n + 1
	if start < 1 then start = 1 end
	for i = start, #logs do
		out[#out + 1] = logs[i]
	end
	return out
end

function lib.RegisterCallback(addonObject, event, method)
	if type(addonObject) == "string" then addonObject = _G[addonObject] end
	if not addonObject or not lib._callbacks[event] then return false end
	table.insert(lib._callbacks[event], { addonObject, method })
	return true
end

function lib.UnregisterCallback(addonObject, event, method)
	local t = lib._callbacks[event]
	if not t then return end
	for i = #t, 1, -1 do
		local e = t[i]
		if e[1] == addonObject and e[2] == method then table.remove(t, i) end
	end
end

local function Utf8Sub(str, startChar, endChar)
	if not str or IsSecret(str) or not CanRead(str) then return "" end
	local startIndex, endIndex = 1, #str
	local currentIndex, currentChar = 1, 0

	while currentIndex <= #str do
		currentChar = currentChar + 1
		if currentChar == startChar then startIndex = currentIndex end
		if endChar and currentChar > endChar then
			endIndex = currentIndex - 1
			break
		end
		local c = string.byte(str, currentIndex)
		if c < 0x80 then
			currentIndex = currentIndex + 1
		elseif c < 0xE0 then
			currentIndex = currentIndex + 2
		elseif c < 0xF0 then
			currentIndex = currentIndex + 3
		else
			currentIndex = currentIndex + 4
		end
	end

	return string.sub(str, startIndex, endIndex)
end

local function SanitizeNickname(value, maxChars)
	if value == nil then return "" end
	if type(value) ~= "string" then value = tostring(value) end
	if IsSecret(value) or not CanRead(value) then return "" end
	value = value:gsub("^%s+", ""):gsub("%s+$", "")
	if value == "" then return "" end
	if maxChars and maxChars > 0 then
		value = Utf8Sub(value, 1, maxChars)
	end
	return value
end

local function EnsureSourceDefaults()
	if type(lib.SourceSettings.resolveMode) ~= "string" then
		lib.SourceSettings.resolveMode = "LAST_WRITE"
	end
	if lib.SourceSettings.resolveMode ~= "LAST_WRITE" and lib.SourceSettings.resolveMode ~= "SOURCE_ORDER" then
		lib.SourceSettings.resolveMode = "LAST_WRITE"
	end

	local enabled = lib.SourceSettings.enabled
	enabled[SOURCE_SHARED] = (enabled[SOURCE_SHARED] ~= false)
	enabled[SOURCE_NSRT] = (enabled[SOURCE_NSRT] ~= false)
	enabled[SOURCE_CUSTOMNAMES] = (enabled[SOURCE_CUSTOMNAMES] ~= false)
	enabled[SOURCE_NICKTAG] = (enabled[SOURCE_NICKTAG] ~= false)

	local order = lib.SourceSettings.order
	if type(order) ~= "table" then
		order = {}
		lib.SourceSettings.order = order
	end
	if #order == 0 then
		order[1] = SOURCE_SHARED
		order[2] = SOURCE_CUSTOMNAMES
		order[3] = SOURCE_NSRT
		order[4] = SOURCE_NICKTAG
	else
		local has = {}
		for i = 1, #order do
			has[order[i]] = true
		end
		if not has[SOURCE_SHARED] then order[#order + 1] = SOURCE_SHARED end
		if not has[SOURCE_CUSTOMNAMES] then order[#order + 1] = SOURCE_CUSTOMNAMES end
		if not has[SOURCE_NSRT] then order[#order + 1] = SOURCE_NSRT end
		if not has[SOURCE_NICKTAG] then order[#order + 1] = SOURCE_NICKTAG end
	end
end

function lib.GetResolveMode()
	EnsureSourceDefaults()
	return lib.SourceSettings.resolveMode or "LAST_WRITE"
end

function lib.SetResolveMode(mode)
	if type(mode) ~= "string" then return false end
	mode = string.upper(mode)
	if mode ~= "LAST_WRITE" and mode ~= "SOURCE_ORDER" then return false end
	EnsureSourceDefaults()
	if lib.SourceSettings.resolveMode == mode then return true end
	lib.SourceSettings.resolveMode = mode
	DebugLog("source", "resolve mode changed", { mode = mode })
	Fire("SourcesChanged", lib.GetSourceOrder(), lib.GetSourceEnabledMap())
	return true
end

local function EnsureSourceData(sourceId)
	lib.SourceData[sourceId] = lib.SourceData[sourceId] or {}
	return lib.SourceData[sourceId]
end

local function CacheEntry(sourceId, fullKey, shortKey, nickname, extra)
	local data = EnsureSourceData(sourceId)
	if not fullKey then return nil end

	if nickname == "" or nickname == nil then
		data[fullKey] = nil
		if shortKey then data[shortKey] = nil end
		return nil
	end

	local entry = {
		fullName = fullKey,
		nickname = nickname,
		lastSeen = (GetServerTime and GetServerTime()) or (GetTime and floor(GetTime())) or 0,
	}
	if extra then
		for k, v in pairs(extra) do
			entry[k] = v
		end
	end
	data[fullKey] = entry
	if shortKey then data[shortKey] = entry end
	return entry
end

local function GetCanonicalEntryForLookup(lookup)
	if not lookup then return nil end
	local entry
	if lookup.fullName then entry = lib.CanonicalData[lookup.fullName] end
	if not entry and lookup.shortName then entry = lib.CanonicalData[lookup.shortName] end
	if not entry and lookup.raw then entry = lib.CanonicalData[lookup.raw] end
	return entry
end

local function SetCanonicalEntry(fullKey, shortKey, nickname, sourceId, seq)
	if not fullKey then return nil end
	local entry = {
		fullName = fullKey,
		shortName = shortKey,
		nickname = nickname,
		source = sourceId,
		seq = seq or 0,
		lastSeen = (GetServerTime and GetServerTime()) or (GetTime and floor(GetTime())) or 0,
	}
	lib.CanonicalData[fullKey] = entry
	if shortKey then lib.CanonicalData[shortKey] = entry end
	return entry
end

local function RemoveCanonicalEntry(fullKey, shortKey)
	local current = lib.CanonicalData[fullKey] or (shortKey and lib.CanonicalData[shortKey]) or nil
	if not current then
		if fullKey then lib.CanonicalData[fullKey] = nil end
		if shortKey then lib.CanonicalData[shortKey] = nil end
		return nil
	end
	local currentFull = current.fullName or fullKey
	local currentShort = current.shortName or shortKey
	if currentFull then lib.CanonicalData[currentFull] = nil end
	if currentShort then lib.CanonicalData[currentShort] = nil end
	if fullKey then lib.CanonicalData[fullKey] = nil end
	if shortKey then lib.CanonicalData[shortKey] = nil end
	return current
end

local function PickCanonicalFallback(fullKey, shortKey, excludedSource)
	local best = nil
	for sourceId, data in pairs(lib.SourceData) do
		if sourceId ~= excludedSource and type(data) == "table" then
			local entry = (fullKey and data[fullKey]) or (shortKey and data[shortKey]) or nil
			if type(entry) == "table" and entry.fullName then
				local nick = SanitizeNickname(entry.nickname, CACHE_MAX_NICK_CHARS)
				if nick ~= "" then
					local seq = tonumber(entry.seq) or 0
					local lastSeen = tonumber(entry.lastSeen) or 0
					if not best then
						best = {
							source = sourceId,
							fullName = entry.fullName or fullKey,
							shortName = entry.shortName or shortKey,
							nickname = nick,
							seq = seq,
							lastSeen = lastSeen,
						}
					else
						if seq > (best.seq or 0) or (seq == (best.seq or 0) and lastSeen > (best.lastSeen or 0)) then
							best = {
								source = sourceId,
								fullName = entry.fullName or fullKey,
								shortName = entry.shortName or shortKey,
								nickname = nick,
								seq = seq,
								lastSeen = lastSeen,
							}
						end
					end
				end
			end
		end
	end
	return best
end

local function IsOwnFullName(fullName)
	local own = GetOwnNameKeys()
	if not own then return false end
	return SafeEquals(fullName, own)
end

local function TryApplyBridgeNickname(targetSource, fullKey, shortKey, nickname, sourceOfTruth, seq)
	local bridge = lib._sourceHandlers[targetSource]
	if not bridge or type(bridge.Apply) ~= "function" then return false, "NO_APPLY" end

	if type(bridge.CanApply) == "function" then
		local okCan, canApply = pcall(bridge.CanApply, bridge, lib, targetSource)
		if not okCan or canApply == false then return false, "CANNOT_APPLY" end
	end

	local ok, applied = pcall(bridge.Apply, bridge, fullKey, shortKey, nickname, {
		source = sourceOfTruth,
		seq = seq,
	}, lib, targetSource)
	if not ok then return false, "APPLY_ERROR" end
	if applied == false then return false, "APPLY_REJECTED" end
	return true, "APPLIED"
end

local function PropagateNicknameToSources(sourceId, fullKey, shortKey, nickname, seq)
	if lib._syncInProgress then return end
	lib._syncInProgress = true

	local ok, err = pcall(function()
		for targetSource in pairs(lib._sourceHandlers) do
			if targetSource ~= sourceId then
				CacheEntry(targetSource, fullKey, shortKey, nickname, {
					source = targetSource,
					seq = seq,
					mirroredFrom = sourceId,
				})
				local applied, reason = TryApplyBridgeNickname(targetSource, fullKey, shortKey, nickname, sourceId, seq)
				DebugLog("sync", "propagate to source", {
					from = sourceId,
					to = targetSource,
					nickname = DebugSafeString(nickname, 60),
					applied = applied == true,
					reason = reason,
				})
			end
		end

		-- Shared comm can only announce the local player nickname.
		if sourceId ~= SOURCE_SHARED and fullKey and IsOwnFullName(fullKey) and type(nickname) == "string" then
			lib.SetMyNickname(nickname, false)
		end
	end)

	lib._syncInProgress = false
	if not ok then
		DebugLog("sync", "propagation failed", { error = DebugSafeString(err, 80) })
	end
end

local function UpsertSourceNickname(sourceId, fullKey, shortKey, nickname, opts)
	opts = opts or {}
	if type(sourceId) ~= "string" or sourceId == "" then return nil end
	if type(fullKey) ~= "string" or fullKey == "" then return nil end
	if opts.propagate == nil and lib._syncInProgress then opts.propagate = false end

	local cleanNick = SanitizeNickname(nickname, CACHE_MAX_NICK_CHARS)
	local prevEntry = EnsureSourceData(sourceId)[fullKey]
	if type(prevEntry) ~= "table" and shortKey then prevEntry = EnsureSourceData(sourceId)[shortKey] end
	local prevNick = nil
	if type(prevEntry) == "table" then prevNick = SanitizeNickname(prevEntry.nickname, CACHE_MAX_NICK_CHARS) end
	if prevNick == cleanNick and opts.force ~= true then return prevEntry end

	lib._canonicalSeq = (lib._canonicalSeq or 0) + 1
	local seq = lib._canonicalSeq

	local sourceEntry = CacheEntry(sourceId, fullKey, shortKey, cleanNick, {
		source = sourceId,
		seq = seq,
	})
	local oldCanonical = lib.CanonicalData[fullKey] or (shortKey and lib.CanonicalData[shortKey]) or nil
	local newCanonical = oldCanonical

	if cleanNick == "" then
		if oldCanonical and SafeEquals(oldCanonical.source, sourceId) then
			local fallback = PickCanonicalFallback(fullKey, shortKey, sourceId)
			if fallback then
				newCanonical = SetCanonicalEntry(fallback.fullName or fullKey, fallback.shortName or shortKey, fallback.nickname, fallback.source, seq)
			else
				newCanonical = nil
				RemoveCanonicalEntry(fullKey, shortKey)
			end
		end
	else
		newCanonical = SetCanonicalEntry(fullKey, shortKey, cleanNick, sourceId, seq)
	end

	if cleanNick == "" then
		Fire("NicknameUpdate", fullKey, nil, true, sourceId)
	else
		Fire("NicknameUpdate", fullKey, sourceEntry, false, sourceId)
	end

	local oldNick = oldCanonical and oldCanonical.nickname or nil
	local oldSource = oldCanonical and oldCanonical.source or nil
	local newNick = newCanonical and newCanonical.nickname or nil
	local newSource = newCanonical and newCanonical.source or nil
	if not SafeEquals(oldNick, newNick) or not SafeEquals(oldSource, newSource) then
		Fire("NicknameCanonicalChanged", fullKey, newNick, newCanonical, sourceId)
		DebugLog("canonical", "canonical nickname changed", {
			player = fullKey,
			nickname = DebugSafeString(newNick, 60),
			source = newSource,
			from = sourceId,
		})
	end

	if opts.propagate ~= false then
		local propagateNickname = cleanNick
		if newCanonical and type(newCanonical.nickname) == "string" then
			propagateNickname = newCanonical.nickname
		end
		PropagateNicknameToSources(sourceId, fullKey, shortKey, propagateNickname, seq)
	end

	return sourceEntry
end

local function CopyArray(arr)
	local out = {}
	if type(arr) ~= "table" then return out end
	for i = 1, #arr do out[i] = arr[i] end
	return out
end

local function SourceExists(sourceId)
	return sourceId == SOURCE_SHARED or lib._sourceHandlers[sourceId] ~= nil
end

function lib.GetSourceOrder()
	EnsureSourceDefaults()
	return CopyArray(lib.SourceSettings.order)
end

function lib.GetSourceEnabledMap()
	EnsureSourceDefaults()
	local out = {}
	for k, v in pairs(lib.SourceSettings.enabled) do out[k] = v end
	return out
end

function lib.SetSourceEnabled(sourceId, enabled)
	if type(sourceId) ~= "string" or sourceId == "" then return false end
	if not SourceExists(sourceId) then return false end
	EnsureSourceDefaults()
	lib.SourceSettings.enabled[sourceId] = enabled and true or false
	DebugLog("source", "source enabled changed", {
		source = sourceId,
		enabled = lib.SourceSettings.enabled[sourceId] == true,
	})
	Fire("SourcesChanged", lib.GetSourceOrder(), lib.GetSourceEnabledMap())
	return true
end

function lib.SetSourceOrder(order)
	if type(order) ~= "table" then return false end
	EnsureSourceDefaults()

	local seen = {}
	local nextOrder = {}
	for i = 1, #order do
		local sourceId = order[i]
		if type(sourceId) == "string" and sourceId ~= "" and not seen[sourceId] and SourceExists(sourceId) then
			seen[sourceId] = true
			nextOrder[#nextOrder + 1] = sourceId
		end
	end

	for _, sourceId in ipairs(lib.SourceSettings.order) do
		if not seen[sourceId] and SourceExists(sourceId) then
			seen[sourceId] = true
			nextOrder[#nextOrder + 1] = sourceId
		end
	end

	for sourceId in pairs(lib._sourceHandlers) do
		if not seen[sourceId] then
			nextOrder[#nextOrder + 1] = sourceId
		end
	end
	if not seen[SOURCE_SHARED] then nextOrder[#nextOrder + 1] = SOURCE_SHARED end

	lib.SourceSettings.order = nextOrder
	DebugLog("source", "source order changed", {
		order = table.concat(nextOrder, ","),
	})
	Fire("SourcesChanged", lib.GetSourceOrder(), lib.GetSourceEnabledMap())
	return true
end

function lib.GetAvailableSources()
	EnsureSourceDefaults()
	local out = {}
	local added = {}

	for _, sourceId in ipairs(lib.SourceSettings.order) do
		local meta = lib._sourceMeta[sourceId] or {}
		local bridge = lib._sourceHandlers[sourceId]
		local available = true
		if bridge and type(bridge.IsAvailable) == "function" then
			local ok, result = pcall(bridge.IsAvailable, bridge, lib, sourceId)
			available = ok and result ~= false
		end
		out[#out + 1] = {
			id = sourceId,
			label = meta.label or sourceId,
			enabled = lib.SourceSettings.enabled[sourceId] ~= false,
			available = available,
		}
		added[sourceId] = true
	end

	for sourceId, bridge in pairs(lib._sourceHandlers) do
		if not added[sourceId] then
			local meta = lib._sourceMeta[sourceId] or {}
			local available = true
			if type(bridge.IsAvailable) == "function" then
				local ok, result = pcall(bridge.IsAvailable, bridge, lib, sourceId)
				available = ok and result ~= false
			end
			out[#out + 1] = {
				id = sourceId,
				label = meta.label or sourceId,
				enabled = lib.SourceSettings.enabled[sourceId] ~= false,
				available = available,
			}
		end
	end

	if not added[SOURCE_SHARED] then
		out[#out + 1] = {
			id = SOURCE_SHARED,
			label = "Shared (EnhanceQoL)",
			enabled = lib.SourceSettings.enabled[SOURCE_SHARED] ~= false,
			available = true,
		}
	end

	return out
end

function lib.ClearSourceCache(sourceId)
	if not SourceExists(sourceId) then return false end

	local data = EnsureSourceData(sourceId)
	local toRemove, seen = {}, {}
	for key, entry in pairs(data) do
		if type(entry) == "table" then
			local full = entry.fullName or key
			if type(full) == "string" and full ~= "" and not seen[full] then
				seen[full] = true
				toRemove[#toRemove + 1] = {
					fullName = full,
					shortName = entry.shortName,
				}
			end
		elseif type(key) == "string" and key ~= "" and not seen[key] then
			seen[key] = true
			toRemove[#toRemove + 1] = {
				fullName = key,
				shortName = nil,
			}
		end
	end

	for i = 1, #toRemove do
		local row = toRemove[i]
		UpsertSourceNickname(sourceId, row.fullName, row.shortName, "", {
			propagate = false,
			force = true,
		})
	end

	for k in pairs(data) do data[k] = nil end
	DebugLog("cache", "source cache cleared", {
		source = sourceId,
	})
	if sourceId == SOURCE_SHARED then Fire("NicknameWipe") end
	return true
end

function lib.RegisterBridge(sourceId, bridge)
	if type(sourceId) ~= "string" or sourceId == "" then return false end
	if sourceId == SOURCE_SHARED then return false end
	if type(bridge) ~= "table" then return false end

	lib._sourceHandlers[sourceId] = bridge
	lib._sourceMeta[sourceId] = {
		label = (type(bridge.label) == "string" and bridge.label ~= "" and bridge.label) or sourceId,
	}
	EnsureSourceData(sourceId)
	EnsureSourceDefaults()
	if lib.SourceSettings.enabled[sourceId] == nil then
		lib.SourceSettings.enabled[sourceId] = bridge.defaultEnabled ~= false
	end

	local alreadyInOrder
	for _, id in ipairs(lib.SourceSettings.order) do
		if id == sourceId then
			alreadyInOrder = true
			break
		end
	end
	if not alreadyInOrder then
		lib.SourceSettings.order[#lib.SourceSettings.order + 1] = sourceId
	end

	if type(bridge.Start) == "function" then
		pcall(bridge.Start, bridge, lib, sourceId)
	end

	DebugLog("source", "bridge registered", {
		source = sourceId,
		label = lib._sourceMeta[sourceId] and lib._sourceMeta[sourceId].label or sourceId,
	})
	Fire("SourcesChanged", lib.GetSourceOrder(), lib.GetSourceEnabledMap())
	return true
end

local function BuildLookup(target)
	if target == nil then return nil end

	local lookup = {
		target = target,
		unit = nil,
		raw = nil,
		rawName = nil,
		fullName = nil,
		shortName = nil,
		baseName = nil,
		realm = nil,
	}

	if type(target) == "string" and UnitExists and UnitExists(target) then
		lookup.unit = target
		local rawName = UnitName and UnitName(target)
		rawName = NormalizeName(rawName)
		lookup.rawName = rawName
		lookup.raw = rawName or ""

		local name, realm = UnitFullName and UnitFullName(target)
		name = NormalizeName(name)
		realm = NormalizeRealm(realm) or GetOwnRealm()
		if name and realm then
			lookup.fullName = name .. "-" .. realm
			lookup.baseName = name
			lookup.realm = realm
			if realm == GetOwnRealm() then lookup.shortName = name end
		elseif rawName then
			lookup.shortName = rawName
			lookup.baseName = rawName
		end

		return lookup
	end

	if type(target) ~= "string" then
		return nil
	end
	if IsSecret(target) or not CanRead(target) then return nil end

	lookup.raw = target
	lookup.rawName = target

	local name, realm = target:match("^([^%-]+)%-(.+)$")
	name = NormalizeName(name)
	realm = NormalizeRealm(realm)
	if name and realm then
		lookup.fullName = name .. "-" .. realm
		lookup.baseName = name
		lookup.realm = realm
		if realm == GetOwnRealm() then lookup.shortName = name end
	else
		local base = NormalizeName(target)
		lookup.baseName = base
		lookup.shortName = base
		local ownRealm = GetOwnRealm()
		if base and ownRealm then lookup.fullName = base .. "-" .. ownRealm end
	end

	return lookup
end

local function ReadFromCache(sourceId, lookup)
	local data = EnsureSourceData(sourceId)
	local entry
	if lookup.fullName then entry = data[lookup.fullName] end
	if not entry and lookup.shortName then entry = data[lookup.shortName] end
	if not entry and lookup.raw then entry = data[lookup.raw] end
	if not entry then return nil end
	if type(entry) == "table" then
		return SanitizeNickname(entry.nickname, CACHE_MAX_NICK_CHARS)
	end
	return SanitizeNickname(entry, CACHE_MAX_NICK_CHARS)
end

local function SaveResolvedCache(sourceId, lookup, nickname)
	if not lookup then return end
	local key = lookup.fullName or lookup.shortName or lookup.raw
	if not key then return end
	UpsertSourceNickname(sourceId, lookup.fullName or key, lookup.shortName, nickname, {
		propagate = true,
	})
end

local function ShouldUseSource(sourceId)
	EnsureSourceDefaults()
	if lib.SourceSettings.enabled[sourceId] == false then return false end
	if sourceId == SOURCE_SHARED then return true end
	local bridge = lib._sourceHandlers[sourceId]
	if not bridge then return false end
	if type(bridge.IsAvailable) == "function" then
		local ok, available = pcall(bridge.IsAvailable, bridge, lib, sourceId)
		if not ok or available == false then return false end
	end
	return true
end

local function DebugResolveTrace(sourceId, lookup, status, nickname)
	if not lib.GetDebugEnabled or not lib.GetDebugEnabled() then return end
	local key = (lookup and (lookup.fullName or lookup.shortName or lookup.raw)) or "?"
	local stateKey = tostring(sourceId) .. "|" .. tostring(key)
	local payload = tostring(status or "unknown") .. "|" .. tostring(nickname or "")
	local now = GetTime and GetTime() or 0
	local prev = lib._debugResolveState[stateKey]
	if prev and prev.payload == payload and (now - (prev.time or 0)) < 0.8 then return end
	lib._debugResolveState[stateKey] = { payload = payload, time = now }

	DebugLog("resolve", "source resolve", {
		source = sourceId,
		target = DebugSafeString(key, 60),
		status = status,
		nickname = nickname and DebugSafeString(nickname, 60) or nil,
	})
end

local function ResolveFromCanonical(lookup)
	local entry = GetCanonicalEntryForLookup(lookup)
	if type(entry) ~= "table" then return nil end

	local sourceId = entry.source or SOURCE_SHARED
	if not ShouldUseSource(sourceId) then
		DebugResolveTrace(sourceId, lookup, "canonical-source-unavailable")
		return nil
	end

	local nickname = SanitizeNickname(entry.nickname, CACHE_MAX_NICK_CHARS)
	if nickname == "" then
		DebugResolveTrace(sourceId, lookup, "canonical-empty")
		return nil
	end

	if lookup.rawName and SafeEquals(nickname, lookup.rawName) then
		DebugResolveTrace(sourceId, lookup, "canonical-equal-raw")
		return nil
	end
	if lookup.baseName and SafeEquals(nickname, lookup.baseName) then
		DebugResolveTrace(sourceId, lookup, "canonical-equal-base")
		return nil
	end
	if lookup.fullName and SafeEquals(nickname, lookup.fullName) then
		DebugResolveTrace(sourceId, lookup, "canonical-equal-full")
		return nil
	end

	DebugResolveTrace(sourceId, lookup, "canonical-hit", nickname)
	return nickname
end

local function ResolveFromSource(sourceId, lookup)
	local cached = ReadFromCache(sourceId, lookup)
	if cached and cached ~= "" then
		DebugResolveTrace(sourceId, lookup, "cache-hit", cached)
		return cached
	end

	if sourceId == SOURCE_SHARED then
		DebugResolveTrace(sourceId, lookup, "miss-shared")
		return nil
	end

	local bridge = lib._sourceHandlers[sourceId]
	if not bridge or type(bridge.Resolve) ~= "function" then
		DebugResolveTrace(sourceId, lookup, "miss-no-bridge")
		return nil
	end
	if type(bridge.ShouldResolve) == "function" then
		local ok, allowed = pcall(bridge.ShouldResolve, bridge, lookup, lib, sourceId)
		if not ok or allowed == false then
			DebugResolveTrace(sourceId, lookup, ok and "skip-shouldresolve" or "skip-error", nil)
			return nil
		end
	end

	local ok, nickname = pcall(bridge.Resolve, bridge, lookup, lib, sourceId)
	if not ok then
		DebugResolveTrace(sourceId, lookup, "error-resolve")
		return nil
	end
	nickname = SanitizeNickname(nickname, CACHE_MAX_NICK_CHARS)
	if nickname == "" then
		DebugResolveTrace(sourceId, lookup, "miss-empty")
		return nil
	end

	if lookup.rawName then
		if SafeEquals(nickname, lookup.rawName) then
			DebugResolveTrace(sourceId, lookup, "miss-equal-raw")
			return nil
		end
	end
	if lookup.baseName then
		if SafeEquals(nickname, lookup.baseName) then
			DebugResolveTrace(sourceId, lookup, "miss-equal-base")
			return nil
		end
	end
	if lookup.fullName then
		if SafeEquals(nickname, lookup.fullName) then
			DebugResolveTrace(sourceId, lookup, "miss-equal-full")
			return nil
		end
	end

	SaveResolvedCache(sourceId, lookup, nickname)
	DebugResolveTrace(sourceId, lookup, "hit", nickname)
	return nickname
end

local function UpdateSharedNickname(sender, nickname, channel)
	local senderNorm = NormalizeName(sender)
	if not senderNorm then return end

	local name, realm = senderNorm:match("^([^%-]+)%-(.+)$")
	name = NormalizeName(name)
	realm = NormalizeRealm(realm)
	if not name then
		name = senderNorm
		realm = GetOwnRealm()
	end
	if not (name and realm) then return end

	local fullKey = name .. "-" .. realm
	local shortKey = (realm == GetOwnRealm()) and name or nil
	local cleanNick = SanitizeNickname(nickname, SHARED_MAX_NICK_CHARS)

	UpsertSourceNickname(SOURCE_SHARED, fullKey, shortKey, cleanNick, {
		propagate = true,
	})

	if cleanNick == "" then
		DebugLog("shared", "nickname removed from shared data", {
			player = fullKey,
			channel = channel,
		})
	else
		DebugLog("shared", "nickname updated from shared data", {
			player = fullKey,
			channel = channel,
			nickname = DebugSafeString(cleanNick, 60),
		})
	end
end

local function BuildPacket(op, nickname)
	local ser, comp = RefreshCommLibs()
	if not (ser and comp) then return nil end
	local payload = {
		v = 1,
		op = op,
		nick = nickname or "",
	}
	local serialized = ser:Serialize(payload)
	local compressed = comp:CompressDeflate(serialized, { level = 7 })
	return comp:EncodeForWoWAddonChannel(compressed)
end

local function DecodePacket(text)
	local ser, comp = RefreshCommLibs()
	if not (ser and comp) then return nil end
	if not text or IsSecret(text) or not CanRead(text) then return nil end

	local decoded = comp:DecodeForWoWAddonChannel(text)
	if not decoded then return nil end
	local data = comp:DecompressDeflate(decoded)
	if type(data) ~= "string" then return nil end

	local ok, packet = ser:Deserialize(data)
	if not ok or type(packet) ~= "table" then return nil end
	if packet.v ~= 1 then return nil end
	if type(packet.op) ~= "string" then return nil end
	return packet
end

local function IsSelfSender(sender)
	if not sender or IsSecret(sender) or not CanRead(sender) then return true end
	sender = Ambiguate and Ambiguate(sender, "none") or sender
	if not sender or sender == "" then return true end

	local myName = UnitName and UnitName("player")
	if IsSecret(myName) or not CanRead(myName) then return true end
	if sender == myName then return true end

	local myFullName, myRealm = UnitFullName and UnitFullName("player")
	myFullName = NormalizeName(myFullName)
	myRealm = NormalizeRealm(myRealm) or GetOwnRealm()
	if myFullName and myRealm then
		local full = myFullName .. "-" .. myRealm
		if sender == full then return true end
	end
	return false
end

local function IsSenderGroupMember(sender)
	if not sender or IsSecret(sender) or not CanRead(sender) then return false end
	if UnitInRaid and UnitInRaid(sender) then return true end
	if UnitInParty and UnitInParty(sender) then return true end
	return false
end

local function EnsureReceiver()
	if lib._receiverReady then return end
	local _, _, ace = RefreshCommLibs()
	if not ace then return end

	lib._ace = lib._ace or {}
	function lib._ace:OnReceiveComm(prefix, text, channel, sender)
		if prefix ~= SEND_PREFIX then return end
		lib._HandleIncoming(text, channel, sender)
	end

	ace:Embed(lib._ace)
	lib._ace:RegisterComm(SEND_PREFIX, "OnReceiveComm")
	lib._receiverReady = true
end

local function SendPacket(op, nickname)
	local channel = GroupChannel()
	if not channel then
		DebugLog("comm", "send skipped (not in group)", { op = op })
		return false
	end
	EnsureReceiver()

	if IsRestricted() or InCombat() then
		if op == OP_REQUEST then
			lib._pendingRequest = true
		else
			lib._pendingShare = true
		end
		DebugLog("comm", "send deferred (restricted or combat)", {
			op = op,
			channel = channel,
		})
		return false
	end

	local packet = BuildPacket(op, nickname)
	if not packet then
		DebugLog("comm", "send failed (packet build)")
		return false
	end

	local _, _, ace = RefreshCommLibs()
	if ace then
		ace:SendCommMessage(SEND_PREFIX, packet, channel, nil, "NORMAL")
		DebugLog("comm", "send via AceComm", { op = op, channel = channel })
		return true
	end

	if ChatThrottleLib and ChatThrottleLib.SendAddonMessageLogged then
		ChatThrottleLib:SendAddonMessageLogged("NORMAL", LOGGED_PREFIX, packet, channel)
		DebugLog("comm", "send via ChatThrottleLib", { op = op, channel = channel })
		return true
	end

	if C_ChatInfo and C_ChatInfo.SendAddonMessage then
		C_ChatInfo.SendAddonMessage(LOGGED_PREFIX, packet, channel)
		DebugLog("comm", "send via C_ChatInfo", { op = op, channel = channel })
		return true
	end

	DebugLog("comm", "send failed (no channel backend)", { op = op, channel = channel })
	return false
end

local function FlushPending()
	if IsRestricted() or InCombat() then return end
	if not GroupChannel() then
		lib._pendingRequest = false
		lib._pendingShare = false
		return
	end
	if lib._pendingRequest then
		lib._pendingRequest = false
		SendPacket(OP_REQUEST, "")
	end
	if lib._pendingShare then
		lib._pendingShare = false
		SendPacket(OP_NICK, lib._myNickname)
	end
end

function lib._HandleIncoming(text, channel, sender)
	if IsSecret(channel) or IsSecret(sender) then return end
	if channel ~= "PARTY" and channel ~= "RAID" and channel ~= "INSTANCE_CHAT" then return end
	if IsSelfSender(sender) then return end
	if not IsSenderGroupMember(sender) then return end

	local packet = DecodePacket(text)
	if not packet then
		DebugLog("comm", "incoming decode failed", {
			channel = channel,
			sender = DebugSafeString(sender, 60),
		})
		return
	end
	DebugLog("comm", "incoming packet", {
		channel = channel,
		sender = DebugSafeString(sender, 60),
		op = packet.op,
	})

	if packet.op == OP_REQUEST then
		if IsRestricted() or InCombat() then
			lib._pendingShare = true
			DebugLog("comm", "incoming request deferred", {
				channel = channel,
				sender = DebugSafeString(sender, 60),
			})
		else
			SendPacket(OP_NICK, lib._myNickname)
		end
		return
	end

	if packet.op == OP_NICK then
		UpdateSharedNickname(sender, packet.nick, channel)
		return
	end

	DebugLog("comm", "incoming unknown op", { op = DebugSafeString(packet.op, 12) })
end

function lib.SetMyNickname(nickname, silent)
	local sanitized = SanitizeNickname(nickname, SHARED_MAX_NICK_CHARS)
	if lib._myNickname == sanitized then
		local ownFull, ownShort = GetOwnNameKeys()
		if ownFull then
			UpsertSourceNickname(SOURCE_SHARED, ownFull, ownShort, sanitized, {
				propagate = true,
			})
		end
		return false
	end
	lib._myNickname = sanitized
	local ownFull, ownShort = GetOwnNameKeys()
	if ownFull then
		UpsertSourceNickname(SOURCE_SHARED, ownFull, ownShort, sanitized, {
			propagate = true,
			force = true,
		})
	end
	DebugLog("self", "my nickname changed", {
		nickname = DebugSafeString(sanitized, 60),
	})
	Fire("MyNicknameChanged", sanitized)
	if not silent then SendPacket(OP_NICK, sanitized) end
	return true
end

function lib.GetMyNickname()
	return lib._myNickname or ""
end

function lib.AnnounceMyNickname()
	return SendPacket(OP_NICK, lib._myNickname)
end

function lib.RequestNicknamesFromParty()
	if not GroupChannel() then return false end
	local now = GetTime and GetTime() or 0
	if (now - (lib._lastRequestAt or 0)) < REQUEST_COOLDOWN then
		if lib._myNickname ~= nil then SendPacket(OP_NICK, lib._myNickname) end
		DebugLog("comm", "request skipped (cooldown)")
		return false
	end
	lib._lastRequestAt = now
	SendPacket(OP_REQUEST, "")
	SendPacket(OP_NICK, lib._myNickname)
	DebugLog("comm", "request sent")
	return true
end

function lib.GetAllNicknamesInfo()
	return lib.SharedData
end

function lib.GetAllSourceData(sourceId)
	if type(sourceId) ~= "string" or sourceId == "" then return nil end
	return EnsureSourceData(sourceId)
end

function lib.WipeNicknameData()
	lib.ClearSourceCache(SOURCE_SHARED)
	DebugLog("cache", "all shared nickname data wiped")
end

function lib.GetNickname(target, sourceId)
	local lookup = BuildLookup(target)
	if not lookup then
		DebugLog("resolve", "lookup failed", { target = DebugSafeString(target, 60) })
		return nil
	end

	if sourceId then
		if not ShouldUseSource(sourceId) then
			DebugResolveTrace(sourceId, lookup, "skip-source-disabled")
			return nil
		end
		return ResolveFromSource(sourceId, lookup)
	end

	if lib.GetResolveMode() == "LAST_WRITE" then
		local nick = ResolveFromCanonical(lookup)
		if nick and nick ~= "" then return nick end
	end

	EnsureSourceDefaults()
	for _, id in ipairs(lib.SourceSettings.order) do
		if ShouldUseSource(id) then
			local nick = ResolveFromSource(id, lookup)
			if nick and nick ~= "" then return nick end
		else
			DebugResolveTrace(id, lookup, "skip-source-disabled")
		end
	end
	return nil
end

function lib.ResolveName(target)
	local lookup = BuildLookup(target)
	if not lookup then
		if type(target) == "string" then return target end
		return ""
	end

	local nick = lib.GetNickname(target)
	if nick and nick ~= "" then return nick end

	if lookup.rawName then return lookup.rawName end
	if lookup.baseName then return lookup.baseName end
	if lookup.raw then return lookup.raw end
	return ""
end

function lib.DebugResolve(target)
	local lookup = BuildLookup(target)
	local report = {
		target = target,
		lookup = lookup and {
			unit = lookup.unit,
			raw = lookup.raw,
			fullName = lookup.fullName,
			shortName = lookup.shortName,
		} or nil,
		sources = {},
		resolved = nil,
	}

	if not lookup then
		report.resolved = type(target) == "string" and target or ""
		DebugLog("debug", "debug resolve lookup failed", {
			target = DebugSafeString(target, 60),
		})
		return report
	end

	EnsureSourceDefaults()
	for _, id in ipairs(lib.SourceSettings.order) do
		local enabled = lib.SourceSettings.enabled[id] ~= false
		local usable = ShouldUseSource(id)
		local nick = nil
		if usable then
			nick = lib.GetNickname(target, id)
		end
		report.sources[#report.sources + 1] = {
			id = id,
			enabled = enabled,
			usable = usable,
			nickname = nick,
		}
	end

	report.resolved = lib.ResolveName(target)
	DebugLog("debug", "debug resolve snapshot", {
		target = DebugSafeString(target, 60),
		resolved = DebugSafeString(report.resolved, 60),
	})
	return report
end

-- Built-in bridge: NSRT
local NSRTBridge = {
	label = "Northern Sky Raid Tools",
	defaultEnabled = true,
	addon = "NorthernSkyRaidTools",
}

function NSRTBridge:IsAvailable()
	if C_AddOns and C_AddOns.IsAddOnLoaded and not C_AddOns.IsAddOnLoaded(self.addon) then
		return false
	end
	local api = _G.NSAPI
	return api and type(api.GetName) == "function"
end

function NSRTBridge:_RebuildCache()
	local nsrt = _G.NSRT
	local nicknames = nsrt and nsrt.NickNames
	if type(nicknames) ~= "table" then return end

	local ownRealm = GetOwnRealm()
	local seenFull = {}
	for fullname, nickname in pairs(nicknames) do
		if type(fullname) == "string" then
			local name, realm = fullname:match("^([^%-]+)%-(.+)$")
			name = NormalizeName(name)
			realm = NormalizeRealm(realm)
			if name and realm then
				local full = name .. "-" .. realm
				local short = (realm == ownRealm) and name or nil
				local clean = SanitizeNickname(nickname, CACHE_MAX_NICK_CHARS)
				if clean ~= "" and not SafeEquals(clean, name) and not SafeEquals(clean, full) then
					seenFull[full] = true
					UpsertSourceNickname(SOURCE_NSRT, full, short, clean, {
						propagate = true,
					})
				end
			end
		end
	end

	local stale = {}
	local sourceData = EnsureSourceData(SOURCE_NSRT)
	local handled = {}
	for key, entry in pairs(sourceData) do
		if type(entry) == "table" then
			local full = entry.fullName or key
			if type(full) == "string" and full ~= "" and not handled[full] then
				handled[full] = true
				if not seenFull[full] then
					stale[#stale + 1] = {
						fullName = full,
						shortName = entry.shortName,
					}
				end
			end
		end
	end

	for i = 1, #stale do
		local row = stale[i]
		UpsertSourceNickname(SOURCE_NSRT, row.fullName, row.shortName, "", {
			propagate = true,
			force = true,
		})
	end
end

function NSRTBridge:Start()
	self:_RebuildCache()
end

function NSRTBridge:ShouldResolve(lookup)
	if not lookup or not lookup.unit then return false end
	return IsGroupPlayerUnit(lookup.unit)
end

function NSRTBridge:Resolve(lookup)
	local api = _G.NSAPI
	local getName = api and api.GetName
	if type(getName) ~= "function" then return nil end

	local input = lookup.unit or lookup.fullName or lookup.rawName or lookup.raw
	if not input then return nil end

	local ok, resolved = pcall(getName, api, input)
	if not ok then return nil end
	return resolved
end

function NSRTBridge:OnRosterChanged()
	self:_RebuildCache()
end

function NSRTBridge:OnExternalChange()
	self:_RebuildCache()
end

-- Built-in bridge: CustomNames
local CNBridge = {
	label = "CustomNames",
	defaultEnabled = true,
	addon = "CustomNames",
}

function CNBridge:_Lib()
	return LibStub and LibStub:GetLibrary("CustomNames", true)
end

function CNBridge:IsAvailable()
	return self:_Lib() ~= nil
end

function CNBridge:Resolve(lookup)
	local cn = self:_Lib()
	if not cn then return nil end

	if lookup.unit and type(cn.UnitName) == "function" then
		local ok, custom = pcall(cn.UnitName, lookup.unit)
		if ok then return custom end
	end

	if type(cn.Get) == "function" then
		if lookup.fullName then
			local ok, custom = pcall(cn.Get, lookup.fullName)
			if ok then return custom end
		end
		if lookup.shortName then
			local ok, custom = pcall(cn.Get, lookup.shortName)
			if ok then return custom end
		end
		if lookup.raw then
			local ok, custom = pcall(cn.Get, lookup.raw)
			if ok then return custom end
		end
	end

	return nil
end

function CNBridge:Apply(fullKey, shortKey, nickname)
	local cn = self:_Lib()
	if not cn or type(cn.Set) ~= "function" then return false end
	local key = fullKey or shortKey
	if type(key) ~= "string" or key == "" then return false end
	local value = SanitizeNickname(nickname, CACHE_MAX_NICK_CHARS)
	if value == "" then value = nil end
	local ok, result = pcall(cn.Set, key, value)
	if not ok then return false end
	return result ~= false
end

function CNBridge:_OnAdded(name, customName)
	local full, short = BuildNameKeys(name, true)
	if not full then return end
	local nick = SanitizeNickname(customName, CACHE_MAX_NICK_CHARS)
	UpsertSourceNickname(SOURCE_CUSTOMNAMES, full, short, nick, {
		propagate = true,
	})
end

function CNBridge:_OnRemoved(name)
	local full, short = BuildNameKeys(name, true)
	if not full then return end
	UpsertSourceNickname(SOURCE_CUSTOMNAMES, full, short, "", {
		propagate = true,
		force = true,
	})
end

function CNBridge:Start()
	if self._registered then return end
	local cn = self:_Lib()
	if not cn or type(cn.RegisterCallback) ~= "function" then return end

	self._cbObj = self._cbObj or {}
	self._cbObj.OnAdded = self._cbObj.OnAdded or function(_, ...) self:_OnAdded(...) end
	self._cbObj.OnUpdated = self._cbObj.OnUpdated or function(_, ...) self:_OnAdded(...) end
	self._cbObj.OnRemoved = self._cbObj.OnRemoved or function(_, ...) self:_OnRemoved(...) end

	cn:RegisterCallback("Name_Added", self._cbObj.OnAdded)
	cn:RegisterCallback("Name_Update", self._cbObj.OnUpdated)
	cn:RegisterCallback("Name_Removed", self._cbObj.OnRemoved)
	self._registered = true

	if type(cn.GetList) == "function" then
		local ok, list = pcall(cn.GetList)
		if ok and type(list) == "table" then
			for name, customName in pairs(list) do
				self:_OnAdded(name, customName)
			end
		end
	end
end

-- Built-in bridge: NickTag
local NTBridge = {
	label = "NickTag",
	defaultEnabled = true,
	addon = "NickTag-1.0",
}

function NTBridge:_Lib()
	local ok, nt = pcall(LibStub.GetLibrary, LibStub, self.addon, true)
	if ok and nt then return nt end
	local global = _G.NickTag
	if global and type(global.GetNickname) == "function" then return global end
	return nil
end

function NTBridge:IsAvailable()
	local nt = self:_Lib()
	return nt and type(nt.GetNickname) == "function"
end

function NTBridge:ShouldResolve(lookup)
	if not lookup then return false end
	if lookup.unit then return IsGroupPlayerUnit(lookup.unit) end
	return true
end

function NTBridge:Resolve(lookup)
	local nt = self:_Lib()
	if not nt or type(nt.GetNickname) ~= "function" then return nil end

	local keys = {}
	local seen = {}
	local function addKey(key)
		if type(key) ~= "string" or key == "" then return end
		if seen[key] then return end
		seen[key] = true
		keys[#keys + 1] = key

		local short = key:match("^([^%-]+)%-.+$")
		if short and not seen[short] then
			seen[short] = true
			keys[#keys + 1] = short
		end
	end

	addKey(lookup.fullName)
	addKey(lookup.shortName)
	addKey(lookup.rawName)
	addKey(lookup.raw)

	for i = 1, #keys do
		local key = keys[i]
		local ok, nick = pcall(nt.GetNickname, nt, key, nil, true)
		if ok and type(nick) == "string" and nick ~= "" then
			return nick
		end
	end

	return nil
end

function NTBridge:Apply(fullKey, _, nickname)
	if not IsOwnFullName(fullKey) then return false end
	local nt = self:_Lib()
	if not nt or type(nt.SetNickname) ~= "function" then return false end
	local clean = SanitizeNickname(nickname, SHARED_MAX_NICK_CHARS)
	if clean == "" then return false end
	local ok, result = pcall(nt.SetNickname, nt, clean)
	if not ok then return false end
	return result ~= false
end

function NTBridge:_SyncOwnNickname()
	local nt = self:_Lib()
	if not nt or type(nt.GetNickname) ~= "function" then return end
	local ownFull, ownShort = GetOwnNameKeys()
	if not ownFull then return end
	local ownName = ownShort or ownFull
	local ok, nick = pcall(nt.GetNickname, nt, ownName, nil, true)
	if not ok then return end
	nick = SanitizeNickname(nick, CACHE_MAX_NICK_CHARS)
	if nick == "" then return end
	UpsertSourceNickname(SOURCE_NICKTAG, ownFull, ownShort, nick, {
		propagate = true,
	})
end

function NTBridge:Start()
	if self._registered then return end
	local nt = self:_Lib()
	if not nt then return end

	self._cbObj = self._cbObj or {}
	self._cbObj.OnUpdate = self._cbObj.OnUpdate or function()
		lib.ClearSourceCache(SOURCE_NICKTAG)
		self:_SyncOwnNickname()
	end

	if type(nt.RegisterCallback) == "function" then
		pcall(nt.RegisterCallback, nt, "NickTag_Update", self._cbObj.OnUpdate)
	end

	self._registered = true
	self:_SyncOwnNickname()
end

function NTBridge:OnExternalChange()
	lib.ClearSourceCache(SOURCE_NICKTAG)
	self:_SyncOwnNickname()
end

local function RegisterBuiltins()
	lib._sourceMeta[SOURCE_SHARED] = lib._sourceMeta[SOURCE_SHARED] or { label = "Shared (EnhanceQoL)" }
	lib.RegisterBridge(SOURCE_NSRT, NSRTBridge)
	lib.RegisterBridge(SOURCE_CUSTOMNAMES, CNBridge)
	lib.RegisterBridge(SOURCE_NICKTAG, NTBridge)
end

local function TryStartBridge(sourceId)
	local bridge = lib._sourceHandlers[sourceId]
	if not bridge or type(bridge.Start) ~= "function" then return end
	if type(bridge.IsAvailable) == "function" then
		local ok, available = pcall(bridge.IsAvailable, bridge, lib, sourceId)
		if not ok or available == false then return end
	end
	pcall(bridge.Start, bridge, lib, sourceId)
	DebugLog("source", "bridge start attempted", { source = sourceId })
end

local function HandleAddonLoaded(addonName)
	if addonName == "NorthernSkyRaidTools" then
		if lib._sourceHandlers[SOURCE_NSRT] and type(lib._sourceHandlers[SOURCE_NSRT].Start) == "function" then
			pcall(lib._sourceHandlers[SOURCE_NSRT].Start, lib._sourceHandlers[SOURCE_NSRT], lib, SOURCE_NSRT)
		else
			lib.ClearSourceCache(SOURCE_NSRT)
		end
	end
	TryStartBridge(SOURCE_CUSTOMNAMES)
	TryStartBridge(SOURCE_NICKTAG)
	DebugLog("event", "addon loaded handled", {
		addon = DebugSafeString(addonName, 60),
	})
end

local function HandleRosterChanged()
	if lib._sourceHandlers[SOURCE_NSRT] and type(lib._sourceHandlers[SOURCE_NSRT].OnRosterChanged) == "function" then
		pcall(lib._sourceHandlers[SOURCE_NSRT].OnRosterChanged, lib._sourceHandlers[SOURCE_NSRT], lib, SOURCE_NSRT)
	end
	DebugLog("event", "roster changed")
end

local function HandleNSRTMessage(prefix, text)
	if not IsNSRTNicknameMessage(prefix, text) then return end
	DebugLog("bridge", "nsrt message detected", { prefix = prefix })
	if lib._sourceHandlers[SOURCE_NSRT] and type(lib._sourceHandlers[SOURCE_NSRT].OnExternalChange) == "function" then
		pcall(lib._sourceHandlers[SOURCE_NSRT].OnExternalChange, lib._sourceHandlers[SOURCE_NSRT], lib, SOURCE_NSRT)
	else
		lib.ClearSourceCache(SOURCE_NSRT)
	end
end

local function HandleNickTagMessage(prefix, text)
	if not IsNickTagMessage(prefix, text) then return end
	DebugLog("bridge", "nicktag message detected", { prefix = prefix })
	if lib._sourceHandlers[SOURCE_NICKTAG] and type(lib._sourceHandlers[SOURCE_NICKTAG].OnExternalChange) == "function" then
		pcall(lib._sourceHandlers[SOURCE_NICKTAG].OnExternalChange, lib._sourceHandlers[SOURCE_NICKTAG], lib, SOURCE_NICKTAG)
	else
		lib.ClearSourceCache(SOURCE_NICKTAG)
	end
end

local function Initialize()
	if lib._initialized then return end
	lib._initialized = true

	ReadPersistedDebugSettings()
	if type(lib.Debug.logs) ~= "table" then lib.Debug.logs = {} end
	if type(lib.Debug.keep) ~= "number" then lib.Debug.keep = 200 end

	EnsureSourceDefaults()
	RegisterBuiltins()
	EnsureReceiver()
	DebugLog("state", "nickname hub initialized")

	if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
		C_ChatInfo.RegisterAddonMessagePrefix(LOGGED_PREFIX)
		C_ChatInfo.RegisterAddonMessagePrefix(NSRT_PREFIX)
		C_ChatInfo.RegisterAddonMessagePrefix(NSRT_WHISPER_PREFIX)
		C_ChatInfo.RegisterAddonMessagePrefix(NICKTAG_PREFIX)
	end

	local f = lib._frame or CreateFrame("Frame")
	lib._frame = f
	f:RegisterEvent("CHAT_MSG_ADDON_LOGGED")
	f:RegisterEvent("CHAT_MSG_ADDON")
	f:RegisterEvent("GROUP_ROSTER_UPDATE")
	f:RegisterEvent("PLAYER_ENTERING_WORLD")
	f:RegisterEvent("PLAYER_REGEN_ENABLED")
	f:RegisterEvent("PLAYER_LOGIN")
	f:RegisterEvent("ADDON_LOADED")
	f:SetScript("OnEvent", function(_, event, ...)
		if event == "CHAT_MSG_ADDON_LOGGED" then
			local prefix, text, channel, sender = ...
			if prefix ~= LOGGED_PREFIX then return end
			lib._HandleIncoming(text, channel, sender)
			return
		end

		if event == "CHAT_MSG_ADDON" then
			local prefix, text = ...
			HandleNSRTMessage(prefix, text)
			HandleNickTagMessage(prefix, text)
			return
		end

		if event == "PLAYER_REGEN_ENABLED" then
			FlushPending()
			return
		end

		if event == "ADDON_LOADED" then
			HandleAddonLoaded(...)
			return
		end

		if event == "PLAYER_LOGIN" then
			ReadPersistedDebugSettings()
			EnsureReceiver()
			HandleAddonLoaded("NorthernSkyRaidTools")
			HandleAddonLoaded("CustomNames")
			HandleAddonLoaded("NickTag-1.0")
			FlushPending()
			return
		end

		if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
			HandleRosterChanged()
			if not GroupChannel() then return end
			if lib._pendingRosterSync then return end
			lib._pendingRosterSync = true
			if C_Timer and C_Timer.After then
				C_Timer.After(0.25 + math.random() * 0.2, function()
					lib._pendingRosterSync = false
					if GroupChannel() then
						lib.RequestNicknamesFromParty()
					end
				end)
			else
				lib._pendingRosterSync = false
				lib.RequestNicknamesFromParty()
			end
		end
	end)

	Fire("SourcesChanged", lib.GetSourceOrder(), lib.GetSourceEnabledMap())
end

Initialize()
