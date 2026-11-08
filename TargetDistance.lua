local addonName, ns = ...

ns.data = ns.data or {}
ns.data.distances = ns.data.distances or {}

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
end)