local addonName, addon = ...

local ICON_TEXTURE = "Interface\\AddOns\\DKAssist\\Media\\Icon.png"
local BUTTON_RADIUS = 88

local function OpenSettings()
    if addon.OpenStandaloneSettings then
        addon:OpenStandaloneSettings()
    elseif addon.settingsCategory then
        Settings.OpenToCategory(addon.settingsCategory:GetID())
    end
end

-- HidingBar natively listens for LibDataBroker launchers.  We use it only
-- when another addon supplies the library, so DK Assist has no new dependency.
local function RegisterDataBrokerLauncher()
    if addon.ldbLauncher or not LibStub then return end
    local LDB = LibStub("LibDataBroker-1.1", true)
    if not LDB then return end

    addon.ldbLauncher = LDB:NewDataObject("DKAssist", {
        type = "launcher",
        icon = ICON_TEXTURE,
        OnClick = OpenSettings,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("DK Assist")
            tooltip:AddLine("Click to open settings", 0.8, 0.8, 0.8)
        end,
    })
end

local function IsHidingBarLoaded()
    if C_AddOns and C_AddOns.IsAddOnLoaded then
        return C_AddOns.IsAddOnLoaded("HidingBar")
    end
    return IsAddOnLoaded and IsAddOnLoaded("HidingBar")
end

function DKAssist_AddonCompartmentClick()
    OpenSettings()
end

function DKAssist_AddonCompartmentEnter()
    GameTooltip:SetOwner(UIParent, "ANCHOR_CURSOR")
    GameTooltip:SetText("DK Assist")
    GameTooltip:AddLine("Click to open settings", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end

function DKAssist_AddonCompartmentLeave()
    GameTooltip:Hide()
end

local function UpdatePosition(button)
    -- Start below the minimap. This also gives minimap-button bars a stable
    -- initial point instead of sorting DK Assist into their upper row.
    local angle = DKAssistDB.minimapAngle or 270
    local radians = math.rad(angle)
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", math.cos(radians) * BUTTON_RADIUS, math.sin(radians) * BUTTON_RADIUS)
end

function addon:CreateMinimapButton()
    RegisterDataBrokerLauncher()
    -- Keep a direct minimap icon as well as the HidingBar/DataBroker entry.
    DKAssistDB.minimapHidden = false
    if self.minimapButton then
        UpdatePosition(self.minimapButton)
        self.minimapButton:Show()
        return
    end

    local button = CreateFrame("Button", "DKAssistMinimapButton", Minimap)
    button:SetSize(32, 32)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 10)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    -- A real NormalTexture makes the icon recognizable to HidingBar and
    -- other minimap-button collectors, not just visible on the minimap.
    button:SetNormalTexture(ICON_TEXTURE)
    local normal = button:GetNormalTexture()
    normal:SetSize(23, 23)
    normal:SetPoint("CENTER", 0, 1)
    normal:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    normal:SetVertexColor(1, 1, 1, 1)

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ICON_TEXTURE)
    icon:SetSize(23, 23)
    icon:SetPoint("CENTER", 0, 1)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    border:SetSize(52, 52)
    border:SetPoint("CENTER", 10, -11)

    button:SetScript("OnClick", function(_, mouseButton)
        if mouseButton == "LeftButton" then OpenSettings() end
    end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText("DK Assist")
        GameTooltip:AddLine("Left-click: Open settings", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("Drag: Move button", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", GameTooltip_Hide)
    button:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", function(self)
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        x, y = x / scale, y / scale
        local mx, my = Minimap:GetCenter()
        DKAssistDB.minimapAngle = math.deg(math.atan2(y - my, x - mx))
        UpdatePosition(self)
    end) end)
    button:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)

    self.minimapButton = button
    UpdatePosition(button)
    button:Show()
    -- EllesmereUI finishes its minimap-button layout shortly after login.
    -- Reapply the preferred below-minimap point once that layout has settled.
    C_Timer.After(2, function()
        if button:GetParent() == Minimap then UpdatePosition(button) end
    end)
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:SetScript("OnEvent", function()
    C_Timer.After(0, function()
        if DKAssistDB and Minimap then addon:CreateMinimapButton() end
    end)
end)
