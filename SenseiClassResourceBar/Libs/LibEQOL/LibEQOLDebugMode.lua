local MODULE_MAJOR, MINOR = "LibEQOLDebugMode-1.0", 10000
local LibStub = _G.LibStub
assert(LibStub, MODULE_MAJOR .. " requires LibStub")

local lib, oldMinor = LibStub:GetLibrary(MODULE_MAJOR, true)

if oldMinor and oldMinor >= MINOR then
	LibStub.libs[MODULE_MAJOR] = lib
	LibStub.minors[MODULE_MAJOR] = oldMinor
	return
end

if not lib then
	lib = LibStub:NewLibrary(MODULE_MAJOR, MINOR)
else
	LibStub.libs[MODULE_MAJOR] = lib
	LibStub.minors[MODULE_MAJOR] = MINOR
end

lib.MINOR = MINOR
lib.internal = lib.internal or {}

local Internal = lib.internal

local tinsert = table.insert
local tremove = table.remove
local tconcat = table.concat
local tsort = table.sort
local tpack = function(...)
	return { n = select("#", ...), ... }
end
local unpackValues = _G.unpack
local date = _G.date
local tostringValue = tostring
local tonumberValue = tonumber
local typeValue = type
local mathFloor = math.floor
local mathMin = math.min
local stringFormat = string.format
local stringSub = string.sub
local stringGmatch = string.gmatch
local stringRep = string.rep
local stringLen = string.len

local GetTimePreciseSec = _G.GetTimePreciseSec
local GetTime = _G.GetTime
local debugstack = _G.debugstack

local TIER_OFF = "off"
local TIER_BASIC = "basic"
local TIER_DEEP = "deep"

local VALID_TIERS = {
	[TIER_OFF] = true,
	[TIER_BASIC] = true,
	[TIER_DEEP] = true,
}

local DEFAULT_LIMITS = {
	maxEventsPerSession = 500,
	maxSessions = 10,
	maxPayloadBytes = 4096,
	maxSpanDepth = 32,
}

local DEFAULT_PERSISTENCE = {
	enabled = false,
	savedRoot = nil,
	path = nil,
}

local DEFAULT_CONFIG = {
	tier = TIER_OFF,
	persistence = DEFAULT_PERSISTENCE,
	limits = DEFAULT_LIMITS,
}

Internal.addons = Internal.addons or {}
Internal.nextSessionId = Internal.nextSessionId or 0
Internal.nextEventId = Internal.nextEventId or 0
Internal.nextSpanId = Internal.nextSpanId or 0

local function nowMs()
	local nowSec
	if GetTimePreciseSec then
		nowSec = GetTimePreciseSec()
	elseif GetTime then
		nowSec = GetTime()
	else
		nowSec = 0
	end
	return mathFloor((nowSec or 0) * 1000 + 0.5)
end

local function isNonEmptyString(value)
	return typeValue(value) == "string" and value ~= ""
end

local function normalizeTier(tier)
	if not isNonEmptyString(tier) then
		return nil
	end
	tier = tier:lower()
	if VALID_TIERS[tier] then
		return tier
	end
	return nil
end

local function clampInt(value, fallback, minimum)
	local number = tonumberValue(value)
	if not number then
		return fallback
	end
	number = mathFloor(number + 0.5)
	if minimum and number < minimum then
		return fallback
	end
	return number
end

local function mixedKeySort(a, b)
	local ta, tb = typeValue(a), typeValue(b)
	if ta == tb then
		if ta == "number" or ta == "string" then
			return a < b
		end
		return tostringValue(a) < tostringValue(b)
	end
	if ta == "number" then
		return true
	end
	if tb == "number" then
		return false
	end
	return tostringValue(a) < tostringValue(b)
end

local function sortedKeys(input)
	local keys = {}
	for key in pairs(input) do
		keys[#keys + 1] = key
	end
	tsort(keys, mixedKeySort)
	return keys
end

local function deepCopy(value, depth, seen, maxItems)
	if depth <= 0 then
		return "<max-depth>"
	end
	if typeValue(value) ~= "table" then
		return value
	end
	if seen[value] then
		return "<cycle>"
	end
	seen[value] = true
	local copied = {}
	local count = 0
	for _, key in ipairs(sortedKeys(value)) do
		count = count + 1
		if maxItems and count > maxItems then
			copied["..."] = "<truncated>"
			break
		end
		local copiedKey = deepCopy(key, depth - 1, seen, maxItems)
		copied[copiedKey] = deepCopy(value[key], depth - 1, seen, maxItems)
	end
	seen[value] = nil
	return copied
end

local function truncateString(input, maxBytes)
	if not maxBytes or maxBytes < 1 then
		return ""
	end
	if stringLen(input) <= maxBytes then
		return input
	end
	return stringSub(input, 1, maxBytes) .. "...(truncated)"
end

local function serializeValue(value, opts, depth, seen)
	opts = opts or {}
	depth = depth or 0
	seen = seen or {}

	local valueType = typeValue(value)
	if valueType == "nil" then
		return "nil"
	elseif valueType == "boolean" or valueType == "number" then
		return tostringValue(value)
	elseif valueType == "string" then
		local maxString = opts.maxString or 512
		return stringFormat("%q", truncateString(value, maxString))
	elseif valueType ~= "table" then
		return stringFormat("<%s>", valueType)
	end

	if seen[value] then
		return "<cycle>"
	end

	if depth >= (opts.maxDepth or 5) then
		return "{<max-depth>}"
	end

	seen[value] = true
	local parts = {}
	local keys = sortedKeys(value)
	local maxItems = opts.maxItems or 30
	for index, key in ipairs(keys) do
		if index > maxItems then
			parts[#parts + 1] = "..."
			break
		end
		local encodedKey = serializeValue(key, opts, depth + 1, seen)
		local encodedValue = serializeValue(value[key], opts, depth + 1, seen)
		parts[#parts + 1] = "[" .. encodedKey .. "]=" .. encodedValue
	end
	seen[value] = nil
	return "{" .. tconcat(parts, ", ") .. "}"
end

local function sanitizePayload(payload, byteLimit)
	if payload == nil then
		return nil
	end

	local ok, serialized = pcall(serializeValue, payload, {
		maxDepth = 5,
		maxItems = 40,
		maxString = byteLimit and mathMin(1024, byteLimit) or 1024,
	})

	if not ok then
		serialized = tostringValue(payload)
	end

	if byteLimit and byteLimit > 0 and stringLen(serialized) > byteLimit then
		return truncateString(serialized, byteLimit)
	end

	if typeValue(payload) == "table" then
		return deepCopy(payload, 8, {}, 200)
	end

	return payload
end

local function normalizePath(path)
	if typeValue(path) == "string" then
		local segments = {}
		for segment in stringGmatch(path, "[^%.]+") do
			if segment ~= "" then
				segments[#segments + 1] = segment
			end
		end
		if #segments == 0 then
			return nil
		end
		return segments
	elseif typeValue(path) == "table" then
		local segments = {}
		for _, segment in ipairs(path) do
			if segment == nil then
				return nil
			end
			segment = tostringValue(segment)
			if segment == "" then
				return nil
			end
			segments[#segments + 1] = segment
		end
		if #segments == 0 then
			return nil
		end
		return segments
	end
	return nil
end

local function copyLimits(source)
	local limits = source or {}
	return {
		maxEventsPerSession = clampInt(limits.maxEventsPerSession, DEFAULT_LIMITS.maxEventsPerSession, 1),
		maxSessions = clampInt(limits.maxSessions, DEFAULT_LIMITS.maxSessions, 1),
		maxPayloadBytes = clampInt(limits.maxPayloadBytes, DEFAULT_LIMITS.maxPayloadBytes, 1),
		maxSpanDepth = clampInt(limits.maxSpanDepth, DEFAULT_LIMITS.maxSpanDepth, 1),
	}
end

local function copyPersistence(source)
	source = source or {}
	return {
		enabled = not not source.enabled,
		savedRoot = source.savedRoot,
		path = normalizePath(source.path),
	}
end

local function defaultConfig()
	return {
		tier = DEFAULT_CONFIG.tier,
		persistence = copyPersistence(DEFAULT_CONFIG.persistence),
		limits = copyLimits(DEFAULT_CONFIG.limits),
	}
end

local function mergeConfig(current, incoming)
	local merged = defaultConfig()
	if typeValue(current) == "table" then
		local currentTier = normalizeTier(current.tier)
		if currentTier then
			merged.tier = currentTier
		end
		merged.persistence = copyPersistence(current.persistence)
		merged.limits = copyLimits(current.limits)
	end

	if typeValue(incoming) ~= "table" then
		return merged
	end

	if incoming.tier ~= nil then
		local normalizedTier = normalizeTier(incoming.tier)
		if normalizedTier then
			merged.tier = normalizedTier
		end
	end

	if typeValue(incoming.persistence) == "table" then
		local persistence = incoming.persistence
		if persistence.enabled ~= nil then
			merged.persistence.enabled = not not persistence.enabled
		end
		if persistence.savedRoot ~= nil then
			merged.persistence.savedRoot = persistence.savedRoot
		end
		if persistence.path ~= nil then
			merged.persistence.path = normalizePath(persistence.path)
		end
	end

	if typeValue(incoming.limits) == "table" then
		local limits = incoming.limits
		if limits.maxEventsPerSession ~= nil then
			merged.limits.maxEventsPerSession = clampInt(
				limits.maxEventsPerSession,
				merged.limits.maxEventsPerSession,
				1
			)
		end
		if limits.maxSessions ~= nil then
			merged.limits.maxSessions = clampInt(limits.maxSessions, merged.limits.maxSessions, 1)
		end
		if limits.maxPayloadBytes ~= nil then
			merged.limits.maxPayloadBytes = clampInt(limits.maxPayloadBytes, merged.limits.maxPayloadBytes, 1)
		end
		if limits.maxSpanDepth ~= nil then
			merged.limits.maxSpanDepth = clampInt(limits.maxSpanDepth, merged.limits.maxSpanDepth, 1)
		end
	end

	return merged
end

local function buildPersistenceSignature(persistence)
	if typeValue(persistence) ~= "table" or not persistence.enabled then
		return nil
	end
	local path = persistence.path or {}
	return tostringValue(persistence.savedRoot) .. "::" .. tconcat(path, ".")
end

local function normalizeStoredEvent(event, limits)
	if typeValue(event) ~= "table" then
		return nil
	end
	if not tonumberValue(event.id) then
		return nil
	end

	local normalized = {
		id = clampInt(event.id, nil, 1),
		kind = isNonEmptyString(event.kind) and event.kind or "trace",
		name = event.name,
		where = event.where,
		error = event.error,
		parentId = clampInt(event.parentId, nil, 1),
		spanId = clampInt(event.spanId, nil, 1),
		status = event.status,
		timeMs = clampInt(event.timeMs, 0, 0),
		relMs = clampInt(event.relMs, 0, 0),
	}
	if event.payload ~= nil then
		normalized.payload = sanitizePayload(event.payload, limits.maxPayloadBytes)
	end
	return normalized
end

local function normalizeStoredSession(session, addonKey, limits)
	if typeValue(session) ~= "table" then
		return nil
	end
	local id = clampInt(session.id, nil, 1)
	if not id then
		return nil
	end

	local normalizedTier = normalizeTier(session.tier) or TIER_OFF
	local normalized = {
		id = id,
		addonKey = addonKey,
		tier = normalizedTier,
		startedAtMs = clampInt(session.startedAtMs, 0, 0),
		stoppedAtMs = clampInt(session.stoppedAtMs, nil, 0),
		stopReason = session.stopReason,
		events = {},
	}

	if typeValue(session.events) == "table" then
		for _, event in ipairs(session.events) do
			local normalizedEvent = normalizeStoredEvent(event, limits)
			if normalizedEvent then
				normalized.events[#normalized.events + 1] = normalizedEvent
			end
		end
	end

	local maxEvents = limits.maxEventsPerSession
	if #normalized.events > maxEvents then
		local startIndex = #normalized.events - maxEvents + 1
		local trimmed = {}
		for i = startIndex, #normalized.events do
			trimmed[#trimmed + 1] = normalized.events[i]
		end
		normalized.events = trimmed
	end

	return normalized
end

local function normalizeStoredSessions(rawSessions, addonKey, limits)
	local sessions = {}
	if typeValue(rawSessions) ~= "table" then
		return sessions
	end

	for _, rawSession in ipairs(rawSessions) do
		local session = normalizeStoredSession(rawSession, addonKey, limits)
		if session then
			sessions[#sessions + 1] = session
		end
	end

	local maxSessions = limits.maxSessions
	while #sessions > maxSessions do
		tremove(sessions, 1)
	end

	return sessions
end

local function validateAddonKey(addonKey)
	if isNonEmptyString(addonKey) then
		return true
	end
	return nil, "addonKey must be a non-empty string"
end

local function getAddon(addonKey)
	return Internal.addons[addonKey]
end

local function ensureAddon(addonKey)
	local addon = Internal.addons[addonKey]
	if addon then
		return addon
	end

	addon = {
		key = addonKey,
		config = defaultConfig(),
		activeSession = nil,
		sessions = {},
		persistenceSignature = nil,
		persistenceLoaded = false,
	}
	Internal.addons[addonKey] = addon
	return addon
end

local function resolvePersistenceNode(addon, createMissing)
	local persistence = addon and addon.config and addon.config.persistence
	if not (persistence and persistence.enabled) then
		return nil, nil
	end
	if typeValue(persistence.savedRoot) ~= "table" then
		return nil, "persistence.savedRoot must be a table when persistence is enabled"
	end
	if typeValue(persistence.path) ~= "table" or #persistence.path == 0 then
		return nil, "persistence.path must be provided when persistence is enabled"
	end

	local node = persistence.savedRoot
	for _, segment in ipairs(persistence.path) do
		local current = node[segment]
		if current == nil then
			if not createMissing then
				return nil, nil
			end
			current = {}
			node[segment] = current
		elseif typeValue(current) ~= "table" then
			return nil, stringFormat("persistence path segment '%s' is not a table", segment)
		end
		node = current
	end

	return node, nil
end

local function computeEventStats(events)
	local stats = {
		trace = 0,
		error = 0,
		span_start = 0,
		span_end = 0,
	}
	for _, event in ipairs(events or {}) do
		local kind = event.kind
		if stats[kind] ~= nil then
			stats[kind] = stats[kind] + 1
		end
	end
	return stats
end

local function copyEvent(event)
	local copied = {}
	for key, value in pairs(event) do
		if key == "payload" and typeValue(value) == "table" then
			copied[key] = deepCopy(value, 8, {}, 200)
		else
			copied[key] = value
		end
	end
	return copied
end

local function copyEvents(events)
	local copied = {}
	for _, event in ipairs(events or {}) do
		copied[#copied + 1] = copyEvent(event)
	end
	return copied
end

local function copySessionForStorage(session)
	return {
		id = session.id,
		addonKey = session.addonKey,
		tier = session.tier,
		startedAtMs = session.startedAtMs,
		stoppedAtMs = session.stoppedAtMs,
		stopReason = session.stopReason,
		events = copyEvents(session.events),
	}
end

local function persistSessions(addon)
	if not addon or not addon.config.persistence.enabled then
		return true
	end

	local node, err = resolvePersistenceNode(addon, true)
	if err then
		return nil, err
	end
	if typeValue(node) ~= "table" then
		return nil, "could not resolve persistence node"
	end

	local sessionsForStorage = {}
	for _, session in ipairs(addon.sessions) do
		sessionsForStorage[#sessionsForStorage + 1] = copySessionForStorage(session)
	end

	node.version = 1
	node.addonKey = addon.key
	node.updatedAtMs = nowMs()
	node.sessions = sessionsForStorage

	return true
end

local function maybeLoadPersistedSessions(addon)
	if not addon then
		return
	end
	if not addon.config.persistence.enabled then
		addon.persistenceLoaded = false
		return
	end

	local signature = buildPersistenceSignature(addon.config.persistence)
	if signature ~= addon.persistenceSignature then
		addon.persistenceSignature = signature
		addon.persistenceLoaded = false
	end

	if addon.persistenceLoaded then
		return
	end

	local node = resolvePersistenceNode(addon, false)
	if typeValue(node) == "table" and typeValue(node.sessions) == "table" then
		addon.sessions = normalizeStoredSessions(node.sessions, addon.key, addon.config.limits)
	end
	addon.persistenceLoaded = true
end

local function trimSessionEvents(session, maxEvents)
	while #session.events > maxEvents do
		tremove(session.events, 1)
	end
end

local function trimStoredSessions(addon)
	local maxSessions = addon.config.limits.maxSessions
	while #addon.sessions > maxSessions do
		tremove(addon.sessions, 1)
	end
end

local function createEvent(session, kind, name, data)
	Internal.nextEventId = Internal.nextEventId + 1
	local timestamp = nowMs()
	local event = {
		id = Internal.nextEventId,
		kind = kind,
		name = name,
		timeMs = timestamp,
		relMs = timestamp - session.startedAtMs,
		parentId = data and data.parentId or nil,
		payload = data and data.payload or nil,
		where = data and data.where or nil,
		error = data and data.error or nil,
		spanId = data and data.spanId or nil,
		status = data and data.status or nil,
	}

	tinsert(session.events, event)
	trimSessionEvents(session, session.limits.maxEventsPerSession)

	return event
end

local function getDefaultParentId(session, explicitParentId)
	if explicitParentId ~= nil then
		return clampInt(explicitParentId, nil, 1)
	end
	if session.tier ~= TIER_DEEP then
		return nil
	end
	local topSpanId = session.spanStack[#session.spanStack]
	if not topSpanId then
		return nil
	end
	local span = session.spans[topSpanId]
	if not span then
		return nil
	end
	return span.startEventId
end

local function getActiveCaptureSession(addonKey)
	local addon = getAddon(addonKey)
	if not addon then
		return nil, nil
	end
	local session = addon.activeSession
	if not session then
		return nil, nil
	end
	if session.tier == TIER_OFF then
		return nil, nil
	end
	return addon, session
end

local function findSessionById(addon, sessionId)
	sessionId = clampInt(sessionId, nil, 1)
	if not sessionId then
		return nil
	end
	if addon.activeSession and addon.activeSession.id == sessionId then
		return addon.activeSession, true
	end
	for _, session in ipairs(addon.sessions) do
		if session.id == sessionId then
			return session, false
		end
	end
	return nil
end

local function resolveSession(addon, opts)
	opts = opts or {}
	if opts.sessionId ~= nil then
		return findSessionById(addon, opts.sessionId)
	end

	if opts.latestStored then
		if #addon.sessions > 0 then
			return addon.sessions[#addon.sessions], false
		end
		return nil
	end

	if addon.activeSession then
		return addon.activeSession, true
	end

	if #addon.sessions > 0 then
		return addon.sessions[#addon.sessions], false
	end

	return nil
end

local function buildTree(events)
	local nodesById = {}
	local roots = {}

	for _, event in ipairs(events) do
		nodesById[event.id] = {
			event = event,
			children = {},
		}
	end

	for _, event in ipairs(events) do
		local node = nodesById[event.id]
		local parentNode = event.parentId and nodesById[event.parentId]
		if parentNode and event.parentId ~= event.id then
			tinsert(parentNode.children, node)
		else
			tinsert(roots, node)
		end
	end

	return roots
end

local function formatTimestamp(ms)
	if not ms then
		return "n/a"
	end
	if date then
		return date("%Y-%m-%d %H:%M:%S", mathFloor(ms / 1000))
	end
	return tostringValue(ms)
end

local function formatEventLine(event)
	local rel = stringFormat("+%.3fs", (event.relMs or 0) / 1000)
	if event.kind == "error" then
		local where = event.where or event.name or "unknown"
		local message = event.error or "<no error>"
		return stringFormat("%s [error] %s: %s", rel, where, message)
	elseif event.kind == "span_start" then
		return stringFormat("%s [span.start] %s", rel, event.name or "unnamed")
	elseif event.kind == "span_end" then
		local status = event.status or "ok"
		return stringFormat("%s [span.end] %s (%s)", rel, event.name or "unnamed", status)
	end
	return stringFormat("%s [trace] %s", rel, event.name or "trace")
end

local function appendPayload(line, payload)
	if payload == nil then
		return line
	end
	local payloadText = serializeValue(payload, {
		maxDepth = 3,
		maxItems = 12,
		maxString = 160,
	})
	if payloadText == "" then
		return line
	end
	return line .. " payload=" .. payloadText
end

local function buildReportLines(timeline)
	local lines = {}
	lines[#lines + 1] = "[LibEQOLDebugMode] Bug Report"
	lines[#lines + 1] = "Addon: " .. timeline.addonKey
	lines[#lines + 1] = "Session: " .. tostringValue(timeline.sessionId)
	lines[#lines + 1] = "Tier: " .. timeline.tier
	lines[#lines + 1] = "Active: " .. tostringValue(timeline.isActive)
	lines[#lines + 1] = "Started: " .. formatTimestamp(timeline.startedAtMs)
	lines[#lines + 1] = "Stopped: " .. formatTimestamp(timeline.stoppedAtMs)
	lines[#lines + 1] = "DurationMs: " .. tostringValue(timeline.durationMs)
	lines[#lines + 1] = "Reason: " .. tostringValue(timeline.stopReason or "")
	lines[#lines + 1] = "Counts: trace="
		.. tostringValue(timeline.stats.trace)
		.. " error="
		.. tostringValue(timeline.stats.error)
		.. " span_start="
		.. tostringValue(timeline.stats.span_start)
		.. " span_end="
		.. tostringValue(timeline.stats.span_end)
	lines[#lines + 1] = "Timeline:"

	if #timeline.tree == 0 then
		lines[#lines + 1] = "- (empty)"
		return lines
	end

	local function walk(node, depth)
		local line = formatEventLine(node.event)
		line = appendPayload(line, node.event.payload)
		lines[#lines + 1] = stringRep("  ", depth) .. "- " .. line
		for _, child in ipairs(node.children) do
			walk(child, depth + 1)
		end
	end

	for _, root in ipairs(timeline.tree) do
		walk(root, 0)
	end

	return lines
end

local function withOptionalSpanParent(session, parentId)
	return getDefaultParentId(session, parentId)
end

function lib:RegisterAddon(addonKey, config)
	local ok, err = validateAddonKey(addonKey)
	if not ok then
		return nil, err
	end

	local addon = ensureAddon(addonKey)
	addon.config = mergeConfig(addon.config, config)
	maybeLoadPersistedSessions(addon)
	trimStoredSessions(addon)

	return true
end

function lib:UnregisterAddon(addonKey)
	local ok, err = validateAddonKey(addonKey)
	if not ok then
		return nil, err
	end
	local addon = getAddon(addonKey)
	if not addon then
		return nil, "addon is not registered"
	end
	if addon.activeSession then
		self:StopSession(addonKey, "unregistered")
	end
	Internal.addons[addonKey] = nil
	return true
end

function lib:SetTier(addonKey, tier)
	local ok, err = validateAddonKey(addonKey)
	if not ok then
		return nil, err
	end
	local addon = getAddon(addonKey)
	if not addon then
		return nil, "addon is not registered"
	end
	local normalizedTier = normalizeTier(tier)
	if not normalizedTier then
		return nil, "tier must be one of: off, basic, deep"
	end
	addon.config.tier = normalizedTier
	return normalizedTier
end

function lib:GetTier(addonKey)
	local addon = getAddon(addonKey)
	if not addon then
		return nil
	end
	return addon.config.tier
end

function lib:StartSession(addonKey, opts)
	local ok, err = validateAddonKey(addonKey)
	if not ok then
		return nil, err
	end
	local addon = getAddon(addonKey)
	if not addon then
		return nil, "addon is not registered"
	end
	if addon.activeSession then
		return nil, "a session is already active for this addon"
	end

	maybeLoadPersistedSessions(addon)

	local tier = addon.config.tier
	if typeValue(opts) == "table" and opts.tier ~= nil then
		local overrideTier = normalizeTier(opts.tier)
		if not overrideTier then
			return nil, "opts.tier must be one of: off, basic, deep"
		end
		tier = overrideTier
	end

	if tier == TIER_OFF then
		return nil, "tier is off"
	end

	if addon.config.persistence.enabled then
		local _, persistenceErr = resolvePersistenceNode(addon, false)
		if persistenceErr then
			return nil, persistenceErr
		end
	end

	Internal.nextSessionId = Internal.nextSessionId + 1
	local session = {
		id = Internal.nextSessionId,
		addonKey = addonKey,
		tier = tier,
		startedAtMs = nowMs(),
		stoppedAtMs = nil,
		stopReason = nil,
		events = {},
		spans = {},
		spanStack = {},
		limits = copyLimits(addon.config.limits),
	}

	addon.activeSession = session
	return session.id
end

function lib:StopSession(addonKey, reason)
	local ok, err = validateAddonKey(addonKey)
	if not ok then
		return nil, err
	end
	local addon = getAddon(addonKey)
	if not addon or not addon.activeSession then
		return nil, "no active session"
	end

	local session = addon.activeSession
	while #session.spanStack > 0 do
		local spanId = session.spanStack[#session.spanStack]
		if not self:EndSpan(addonKey, spanId, "auto_closed") then
			break
		end
	end

	session.stoppedAtMs = nowMs()
	if reason ~= nil then
		session.stopReason = tostringValue(reason)
	end

	local stored = copySessionForStorage(session)
	addon.activeSession = nil
	addon.sessions[#addon.sessions + 1] = stored
	trimStoredSessions(addon)

	local _, persistErr = persistSessions(addon)
	if persistErr then
		return stored.id, persistErr
	end

	return stored.id
end

function lib:IsSessionActive(addonKey)
	local addon = getAddon(addonKey)
	return not not (addon and addon.activeSession)
end

function lib:GetActiveSessionId(addonKey)
	local addon = getAddon(addonKey)
	if not addon or not addon.activeSession then
		return nil
	end
	return addon.activeSession.id
end

function lib:Trace(addonKey, eventName, payload, parentId)
	local _, session = getActiveCaptureSession(addonKey)
	if not session then
		return nil
	end

	local event = createEvent(session, "trace", eventName or "trace", {
		parentId = withOptionalSpanParent(session, parentId),
		payload = sanitizePayload(payload, session.limits.maxPayloadBytes),
	})
	return event.id
end

function lib:CaptureError(addonKey, where, errValue, payload, parentId)
	local _, session = getActiveCaptureSession(addonKey)
	if not session then
		return nil
	end

	local event = createEvent(session, "error", where or "error", {
		where = where,
		error = tostringValue(errValue),
		parentId = withOptionalSpanParent(session, parentId),
		payload = sanitizePayload(payload, session.limits.maxPayloadBytes),
	})
	return event.id
end

function lib:BeginSpan(addonKey, spanName, payload, parentId)
	local _, session = getActiveCaptureSession(addonKey)
	if not session or session.tier ~= TIER_DEEP then
		return nil
	end

	if #session.spanStack >= session.limits.maxSpanDepth then
		return nil
	end

	Internal.nextSpanId = Internal.nextSpanId + 1
	local spanId = Internal.nextSpanId
	local parentEventId = withOptionalSpanParent(session, parentId)

	local startEvent = createEvent(session, "span_start", spanName or "span", {
		parentId = parentEventId,
		payload = sanitizePayload(payload, session.limits.maxPayloadBytes),
		spanId = spanId,
	})

	session.spans[spanId] = {
		id = spanId,
		name = spanName or "span",
		startEventId = startEvent.id,
		parentEventId = parentEventId,
		startTimeMs = startEvent.timeMs,
		ended = false,
	}
	tinsert(session.spanStack, spanId)

	return spanId
end

function lib:EndSpan(addonKey, spanId, status, payload)
	local _, session = getActiveCaptureSession(addonKey)
	if not session or session.tier ~= TIER_DEEP then
		return nil
	end

	spanId = clampInt(spanId, nil, 1)
	if not spanId then
		return nil
	end

	local span = session.spans[spanId]
	if not span or span.ended then
		return nil
	end

	span.ended = true
	for i = #session.spanStack, 1, -1 do
		if session.spanStack[i] == spanId then
			tremove(session.spanStack, i)
			break
		end
	end

	local endEvent = createEvent(session, "span_end", span.name, {
		parentId = span.startEventId,
		payload = sanitizePayload(payload, session.limits.maxPayloadBytes),
		spanId = spanId,
		status = status and tostringValue(status) or "ok",
	})

	span.endEventId = endEvent.id
	span.endTimeMs = endEvent.timeMs
	return endEvent.id
end

function lib:Wrap(addonKey, where, fn, opts)
	if typeValue(fn) ~= "function" then
		return nil, "fn must be a function"
	end
	opts = opts or {}

	return function(...)
		local args = tpack(...)
		local spanId
		if opts.span ~= false then
			spanId = lib:BeginSpan(addonKey, where or "wrapped", opts.spanPayload, opts.parentId)
		end

		local function onError(err)
			local message = tostringValue(err)
			if debugstack then
				local stack = debugstack(3, 20, 20)
				if stack and stack ~= "" then
					message = message .. "\n" .. stack
				end
			end
			return message
		end

		local result = tpack(xpcall(function()
			return fn(unpackValues(args, 1, args.n))
		end, onError))

		if result[1] then
			if spanId then
				lib:EndSpan(addonKey, spanId, "ok")
			end
			return unpackValues(result, 2, result.n)
		end

		local errMessage = result[2]
		lib:CaptureError(addonKey, where or "wrapped", errMessage, opts.errorPayload, opts.parentId)
		if spanId then
			lib:EndSpan(addonKey, spanId, "error")
		end

		if opts.rethrow == false then
			return nil, errMessage
		end

		error(errMessage, 0)
	end
end

function lib:GetTimeline(addonKey, opts)
	local ok, err = validateAddonKey(addonKey)
	if not ok then
		return nil, err
	end
	local addon = getAddon(addonKey)
	if not addon then
		return nil, "addon is not registered"
	end

	local session, isActive = resolveSession(addon, opts)
	if not session then
		return nil, "session not found"
	end

	local events = copyEvents(session.events)
	local timeline = {
		addonKey = addon.key,
		sessionId = session.id,
		tier = session.tier,
		startedAtMs = session.startedAtMs,
		stoppedAtMs = session.stoppedAtMs,
		stopReason = session.stopReason,
		isActive = not not isActive,
		durationMs = ((session.stoppedAtMs or nowMs()) - (session.startedAtMs or nowMs())),
		events = events,
		tree = buildTree(events),
		stats = computeEventStats(events),
	}
	return timeline
end

function lib:BuildReport(addonKey, opts)
	local timeline, err = self:GetTimeline(addonKey, opts)
	if not timeline then
		return nil, nil, err
	end

	local lines = buildReportLines(timeline)
	local reportText = tconcat(lines, "\n")
	local report = {
		addonKey = timeline.addonKey,
		sessionId = timeline.sessionId,
		tier = timeline.tier,
		isActive = timeline.isActive,
		startedAtMs = timeline.startedAtMs,
		stoppedAtMs = timeline.stoppedAtMs,
		durationMs = timeline.durationMs,
		stopReason = timeline.stopReason,
		stats = timeline.stats,
		eventCount = #timeline.events,
		tree = timeline.tree,
		events = timeline.events,
	}

	return report, reportText
end

function lib:ClearActiveSession(addonKey)
	local ok, err = validateAddonKey(addonKey)
	if not ok then
		return nil, err
	end
	local addon = getAddon(addonKey)
	if not addon then
		return nil, "addon is not registered"
	end
	addon.activeSession = nil
	return true
end

function lib:ClearStoredSessions(addonKey)
	local ok, err = validateAddonKey(addonKey)
	if not ok then
		return nil, err
	end
	local addon = getAddon(addonKey)
	if not addon then
		return nil, "addon is not registered"
	end
	addon.sessions = {}
	local _, persistErr = persistSessions(addon)
	if persistErr then
		return nil, persistErr
	end
	return true
end

local umbrella = _G.LibEQOL
if typeValue(umbrella) == "table" then
	umbrella.DebugMode = lib
end

return lib
