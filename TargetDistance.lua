local addonName, ns = ...

local frame = CreateFrame("Frame", "TargetDistanceFrame", UIParent)
frame:SetSize(80, 24)
frame:SetPoint("CENTER", 0, 0)
frame:SetMovable(true)
frame:EnableMouse(false)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function(self) if not self.locked then self:StartMoving() end end)
frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

local text = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
text:SetPoint("CENTER", frame, "CENTER", 0, 0)
local font = text:GetFont()
text:SetFont(font, 18, "OUTLINE")
text:SetTextColor(1, 0.82, 0)
text:SetText("")

frame.locked = true

frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, name)
    if event == "ADDON_LOADED" and name == addonName then
        TargetDistanceDB = TargetDistanceDB or {}
        if TargetDistanceDB.point then
            self:ClearAllPoints()
            self:SetPoint(TargetDistanceDB.point, UIParent, TargetDistanceDB.relativePoint or "CENTER", TargetDistanceDB.x or 0, TargetDistanceDB.y or 0)
        end
        self.locked = TargetDistanceDB.locked
        if self.locked == nil then self.locked = true end
        TargetDistanceDB.locked = self.locked
        if self.locked then self:EnableMouse(false) else self:EnableMouse(true) end
        self:UnregisterEvent("ADDON_LOADED")
    end
    if event == "PLAYER_LOGIN" then
        print("|cff00ff00TargetDistance|r loaded - /td lock|unlock|reset")
    end
end)
frame:RegisterEvent("PLAYER_LOGIN")

local elapsed = 0
frame:SetScript("OnUpdate", function(self, dt)
    elapsed = elapsed + dt
    if elapsed < 0.1 then return end
    elapsed = 0
    if not UnitExists("target") then
        text:SetText("")
        return
    end
    if type(UnitDistanceSquared) ~= "function" then
        text:SetText("?")
        return
    end
    local sq, checked = UnitDistanceSquared("target")
    if not checked then
        local coarse = ">28"
        if not InCombatLockdown() then
            local ok, r3 = pcall(CheckInteractDistance, "target", 3)
            if ok and r3 then coarse = "<7"
            else
                local ok2, r2 = pcall(CheckInteractDistance, "target", 2)
                if ok2 and r2 then coarse = "7-8"
                else
                    local ok4, r4 = pcall(CheckInteractDistance, "target", 4)
                    if ok4 and r4 then coarse = "8-28" end
                end
            end
        end
        text:SetText(coarse)
        return
    end
    text:SetText(math.floor(math.sqrt(sq) + 0.5))
end)

SLASH_TARGETDISTANCE1 = "/td"
SlashCmdList["TARGETDISTANCE"] = function(msg)
    msg = (msg or ""):match("^%s*(.-)%s*$"):lower()
    TargetDistanceDB = TargetDistanceDB or {}
    if msg == "lock" then
        frame.locked = true
        TargetDistanceDB.locked = true
        frame:EnableMouse(false)
        print("TargetDistance: locked")
    elseif msg == "unlock" then
        frame.locked = false
        TargetDistanceDB.locked = false
        frame:EnableMouse(true)
        print("TargetDistance: unlocked")
    elseif msg == "reset" then
        frame:ClearAllPoints()
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
        TargetDistanceDB.point = "CENTER"
        TargetDistanceDB.relativePoint = "CENTER"
        TargetDistanceDB.x = 0
        TargetDistanceDB.y = 0
        print("TargetDistance: reset")
    else
        print("TargetDistance: lock, unlock, reset")
    end
end