local addonName, ns = ...

local frame = CreateFrame("Frame", "TargetDistanceFrame", UIParent)
frame:SetSize(90, 32)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetMovable(true)
frame:EnableMouse(false)
frame:RegisterForDrag("LeftButton")
frame:SetFrameStrata("MEDIUM")

local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
text:SetPoint("CENTER", frame, "CENTER", 0, 0)
local font = text:GetFont()
text:SetFont(font, 18, "OUTLINE")
text:SetTextColor(1, 0.82, 0)
text:SetText("")

local icon = frame:CreateTexture(nil, "ARTWORK")
icon:SetSize(18, 18)
icon:SetPoint("RIGHT", text, "LEFT", -4, 0)
icon:SetTexture("Interface\\Icons\\INV_Misc_Spyglass_02")

frame.locked = true

local function UpdateMouse()
    if frame.locked then
        frame:EnableMouse(false)
    else
        frame:EnableMouse(true)
    end
end

frame:SetScript("OnDragStart", function(self)
    if not self.locked then self:StartMoving() end
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint()
    local db = TargetDistanceDB
    if db then
        db.point = point
        db.relativePoint = relativePoint
        db.x = x
        db.y = y
    end
end)

local elapsed = 0
local lastText = ""
frame:SetScript("OnUpdate", function(self, dt)
    elapsed = elapsed + dt
    if elapsed < 0.05 then return end
    elapsed = 0
    if not UnitExists("target") then
        if lastText ~= "" then text:SetText("") ; lastText = "" end
        return
    end
    if type(UnitDistanceSquared) ~= "function" then
        if lastText ~= "" then text:SetText("") ; lastText = "" end
        return
    end
    local sq, checked = UnitDistanceSquared("target")
    if not checked then
        if lastText ~= "" then text:SetText("") ; lastText = "" end
        return
    end
    local d = math.sqrt(sq)
    local newText = string.format("%d", math.floor(d + 0.5))
    if newText ~= lastText then
        text:SetText(newText)
        lastText = newText
    end
end)

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        TargetDistanceDB = TargetDistanceDB or {}
        local db = TargetDistanceDB
        if db.point then
            self:ClearAllPoints()
            self:SetPoint(db.point, UIParent, db.relativePoint or "CENTER", db.x or 0, db.y or 0)
        end
        self.locked = db.locked
        if self.locked == nil then self.locked = true end
        db.locked = self.locked
        UpdateMouse()
        self:UnregisterEvent("ADDON_LOADED")
    end
end)

SLASH_TARGETDISTANCE1 = "/td"
SlashCmdList["TARGETDISTANCE"] = function(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$"):lower()
    local db = TargetDistanceDB
    if not db then db = {} ; TargetDistanceDB = db end
    if msg == "lock" then
        frame.locked = true
        db.locked = true
        UpdateMouse()
        print("TargetDistance: locked")
    elseif msg == "unlock" then
        frame.locked = false
        db.locked = false
        UpdateMouse()
        print("TargetDistance: unlocked")
    elseif msg == "reset" then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        db.point = "CENTER"
        db.relativePoint = "CENTER"
        db.x = 0
        db.y = 0
        print("TargetDistance: reset")
    elseif msg == "pos" then
        local point, _, relativePoint, x, y = frame:GetPoint()
        print(string.format("TargetDistance pos: %s %s %d %d", point or "", relativePoint or "", x or 0, y or 0))
    else
        print("TargetDistance commands: lock, unlock, reset, pos")
    end
end

function TargetDistance_CompartmentClick()
    frame.locked = not frame.locked
    if TargetDistanceDB then TargetDistanceDB.locked = frame.locked end
    UpdateMouse()
end

function TargetDistance_CompartmentEnter() end
function TargetDistance_CompartmentLeave() end-- cursor-following distance for hovered units
local cursorFrame = CreateFrame("Frame", nil, UIParent)
cursorFrame:SetSize(60, 20)
local cursorText = cursorFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
cursorText:SetPoint("CENTER", cursorFrame, "CENTER", 0, 0)
cursorText:SetTextColor(1, 0.82, 0)
local cfont = cursorText:GetFont()
cursorText:SetFont(cfont, 14, "OUTLINE")
cursorFrame:Hide()

local nameplateUnitMap = {}
local nameplateManager = CreateFrame("Frame")
nameplateManager:RegisterEvent("NAME_PLATE_UNIT_ADDED")
nameplateManager:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
nameplateManager:SetScript("OnEvent", function(self, event, unit)
    if event == "NAME_PLATE_UNIT_ADDED" then
        local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
        if plate then
            nameplateUnitMap[plate] = unit
            if not plate.tdDist then
                local fs = plate:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                fs:SetPoint("TOP", plate, "BOTTOM", 0, -2)
                fs:SetTextColor(1, 0.82, 0)
                local f = fs:GetFont()
                fs:SetFont(f, 12, "OUTLINE")
                plate.tdDist = fs
            end
            plate.tdDist:Show()
        end
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        local plate = C_NamePlate and C_NamePlate.GetNamePlateForUnit and C_NamePlate.GetNamePlateForUnit(unit)
        if plate and plate.tdDist then
            plate.tdDist:SetText("")
            plate.tdDist:Hide()
        end
        if plate then nameplateUnitMap[plate] = nil end
    end
end)

-- extend main OnUpdate to also handle cursor + nameplates
local baseOnUpdate = frame:GetScript("OnUpdate")
local npElapsed = 0
frame:SetScript("OnUpdate", function(self, dt)
    baseOnUpdate(self, dt)
    -- cursor follow
    local mx, my = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    cursorFrame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", mx / scale + 12, my / scale + 12)
    if UnitExists("mouseover") then
        local sq, checked = UnitDistanceSquared("mouseover")
        if checked then
            cursorText:SetText(math.floor(math.sqrt(sq) + 0.5))
            cursorFrame:Show()
        else
            cursorFrame:Hide()
        end
    else
        cursorFrame:Hide()
    end
    -- nameplates (throttled)
    npElapsed = npElapsed + dt
    if npElapsed >= 0.1 then
        npElapsed = 0
        for plate, unit in pairs(nameplateUnitMap) do
            if plate.tdDist then
                local sq, checked = UnitDistanceSquared(unit)
                if checked then
                    plate.tdDist:SetText(math.floor(math.sqrt(sq) + 0.5))
                    plate.tdDist:Show()
                else
                    plate.tdDist:SetText("")
                end
            end
        end
    end
end)
-- attach distance to TargetFrame
local targetFrameHooked = false
local function EnsureTargetFrameDist()
    if targetFrameHooked then return end
    if TargetFrame then
        targetFrameHooked = true
        if not TargetFrame.tdDist then
            local fs = TargetFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fs:SetPoint("BOTTOM", TargetFrame, "BOTTOM", 0, -5)
            fs:SetTextColor(1, 0.82, 0)
            local f = fs:GetFont()
            fs:SetFont(f, 12, "OUTLINE")
            TargetFrame.tdDist = fs
        end
    end
end
local tfEvent = CreateFrame("Frame")
tfEvent:RegisterEvent("PLAYER_LOGIN")
tfEvent:RegisterEvent("ADDON_LOADED")
tfEvent:SetScript("OnEvent", function() EnsureTargetFrameDist() end)

-- update TargetFrame distance inside nameplate throttle block: appendlocal tfUpdater = CreateFrame("Frame")
local tfElapsed = 0
local tfUpdater = CreateFrame("Frame")
tfUpdater:SetScript("OnUpdate", function(self, dt)
    tfElapsed = tfElapsed + dt
    if tfElapsed < 0.1 then return end
    tfElapsed = 0
    EnsureTargetFrameDist()
    if TargetFrame and TargetFrame.tdDist then
        if UnitExists("target") then
            local sq, checked = UnitDistanceSquared("target")
            if checked then
                TargetFrame.tdDist:SetText(math.floor(math.sqrt(sq) + 0.5))
                TargetFrame.tdDist:Show()
            else
                TargetFrame.tdDist:SetText("")
            end
        else
            TargetFrame.tdDist:SetText("")
        end
    end
end)
-- show distance in tooltip for any hovered unit
local function AddTooltipDistance()
    local _, unit = GameTooltip:GetUnit()
    if not unit or not UnitExists(unit) then unit = "mouseover" end
    if UnitExists(unit) then
        local sq, checked = UnitDistanceSquared(unit)
        if checked then
            GameTooltip:AddLine("Distance: " .. math.floor(math.sqrt(sq) + 0.5), 1, 0.82, 0)
        end
    end
end

local function HookTooltip()
    if not (GameTooltip and GameTooltip.HookScript) then return end
    local ok = pcall(GameTooltip.HookScript, GameTooltip, "OnTooltipSetUnit", AddTooltipDistance)
    if not ok then
        pcall(GameTooltip.HookScript, GameTooltip, "OnShow", function()
            if GameTooltip:GetUnit() then
                AddTooltipDistance()
            end
        end)
    end
end
HookTooltip()
