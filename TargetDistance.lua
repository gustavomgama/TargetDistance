this code is only showing an icon and no number.

`local addonName, ns = ...

local frame = CreateFrame("Frame", "TargetDistanceFrame", UIParent)
frame:SetSize(90, 32)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetMovable(true)
frame:EnableMouse(false)
frame:RegisterForDrag("LeftButton")
frame:SetFrameStrata("MEDIUM")

local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
text:SetPoint("CENTER", frame, "CENTER", 0, 0)
local font, size = text:GetFont()
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
frame:SetScript("OnUpdate", function(self, dt)
    elapsed = elapsed + dt
    if elapsed < 0.1 then return end
    elapsed = 0
    if not UnitExists("target") then
        text:SetText("")
        return
    end
    local sq, checked = UnitDistanceSquared("target")
    if not checked then
        text:SetText("")
        return
    end
    local d = math.sqrt(sq)
    local low = math.floor(d / 5) * 5
    local high = low + 5
    text:SetText(string.format("%d - %d", low, high))
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
function TargetDistance_CompartmentLeave() end`