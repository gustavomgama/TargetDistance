local addonName, ns = ...

ns.data = ns.data or {}
ns.data.distances = ns.data.distances or {}
ns.debug = false

local tracked = {}  -- unitToken -> true

local function FetchUnit(unit)
    if not unit or not UnitExists(unit) then
        ns.data.distances[unit] = nil
        return nil
    end
    if type(UnitDistanceSquared) ~= "function" then
        ns.data.distances[unit] = nil
        return nil
    end
    local sq, checked = UnitDistanceSquared(unit)
    if not checked then
        ns.data.distances[unit] = nil
        return nil
    end
    local d = math.sqrt(sq)
    ns.data.distances[unit] = d
    return d
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
frame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")

frame:SetScript("OnEvent", function(self, event, unit, ...)
    if event == "ADDON_LOADED" and unit == addonName then
        TargetDistanceDB = TargetDistanceDB or {}
        ns.db = TargetDistanceDB
    elseif event == "PLAYER_LOGIN" then
        print("|cff00ff00TargetDistance|r backend loaded")
    elseif event == "NAME_PLATE_UNIT_ADDED" then
        tracked[unit] = true
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        tracked[unit] = nil
        ns.data.distances[unit] = nil
    end
end)

local elapsed = 0
frame:SetScript("OnUpdate", function(self, dt)
    elapsed = elapsed + dt
    if elapsed < 0.1 then return end
    elapsed = 0
    FetchUnit("target")
    FetchUnit("mouseover")
    FetchUnit("focus")
    for unit in pairs(tracked) do
        FetchUnit(unit)
    end
    if ns.debug then
        local parts = {}
        if ns.data.distances["target"] then table.insert(parts, "target=" .. math.floor(ns.data.distances["target"] + 0.5)) end
        if ns.data.distances["mouseover"] then table.insert(parts, "mouseover=" .. math.floor(ns.data.distances["mouseover"] + 0.5)) end
        local n = 0
        for _ in pairs(tracked) do n = n + 1 end
        print("|cff00ff00TD|r " .. table.concat(parts, " ") .. " nameplates=" .. n)
        if TargetDistanceDB then
            TargetDistanceDB.log = TargetDistanceDB.log or {}
            table.insert(TargetDistanceDB.log, date("%H:%M:%S") .. " " .. table.concat(parts, " ") .. " nameplates=" .. n)
            if #TargetDistanceDB.log > 200 then table.remove(TargetDistanceDB.log, 1) end
        end
    end
end)SLASH_TARGETDISTANCE1 = "/td"
SlashCmdList["TARGETDISTANCE"] = function(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$"):lower()
    if msg == "debug" then
        ns.debug = not ns.debug
        print("|cff00ff00TargetDistance|r debug " .. (ns.debug and "ON" or "OFF"))
    elseif msg == "log" then
        if TargetDistanceDB and TargetDistanceDB.log then
            for _, line in ipairs(TargetDistanceDB.log) do print(line) end
        else
            print("no log")
        end
    elseif msg == "clearlog" then
        if TargetDistanceDB then TargetDistanceDB.log = {} end
        print("log cleared")
    else
        print("|cff00ff00TargetDistance|r commands: debug, log, clearlog")
    end
end
