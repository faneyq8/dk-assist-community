-- DK Assist - Runic Power cap warning
-- Glows the active Runic Power bar at 85+ so Death Knights do not overcap.

local addonName, addon = ...
local LCG = LibStub("LibCustomGlow-1.0")

local RUNIC_POWER = (Enum and Enum.PowerType and Enum.PowerType.RunicPower) or 6
local THRESHOLD = 85
local GLOW_KEY = "DKAssistRunicPower"

local activeBar = nil
local glowActive = false
local activeGlowType = nil
local fallbackCurve = nil
local fallbackCurveSettings = nil
local testing = false
local barGlows = {}

local function GetSettings()
    return DKAssistDB and DKAssistDB.runicPower
end

-- LibCustomGlow's PixelGlow is designed around square action buttons.  A
-- dedicated four-edge border stays correctly aligned with wide resource bars.
local function GetBarGlow(bar)
    local glow = barGlows[bar]
    if glow then return glow end
    if InCombatLockdown and InCombatLockdown() then return nil end

    glow = CreateFrame("Frame", nil, bar, "BackdropTemplate")
    glow:SetPoint("TOPLEFT", bar, "TOPLEFT", -3, 3)
    glow:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 3, -3)
    glow:SetFrameLevel(math.min(9999, bar:GetFrameLevel() + 10))
    glow:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 2})
    glow:SetBackdropBorderColor(0, 0.72, 1, 1)
    glow.pulse = glow:CreateAnimationGroup()
    glow.pulse:SetLooping("BOUNCE")
    local alpha = glow.pulse:CreateAnimation("Alpha")
    alpha:SetOrder(1)
    alpha:SetFromAlpha(0.35)
    alpha:SetToAlpha(1)
    glow.pulseAlpha = alpha
    glow:Hide()
    barGlows[bar] = glow
    return glow
end

function addon:StartRunicBarGlow(bar, settings)
    local glow = bar and GetBarGlow(bar)
    if not glow then return false end
    local c = settings.color
    local thickness = math.max(2, settings.thickness or 2)
    glow:SetBackdrop({edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = thickness})
    glow:SetBackdropBorderColor(c.r, c.g, c.b, 1)
    glow:SetAlpha(settings.alpha or 1)
    if settings.glowType == "button" then
        glow.pulseAlpha:SetDuration(math.max(0.15, settings.speed or 0.5))
        glow.pulse:Play()
    else
        glow.pulse:Stop()
    end
    glow:Show()
    return true
end

function addon:StopRunicBarGlowFor(bar)
    local glow = bar and barGlows[bar]
    if glow then glow.pulse:Stop(); glow:Hide() end
end

local function GetRunicPowerBar()
    -- EllesmereUI Unit Frames keeps the player's resource StatusBar on its
    -- spawned player frame. This is the visible thin Runic Power bar beneath
    -- the player's health bar in EllesmereUI.
    local euiPlayer = _G.EllesmereUIUnitFrames_Player
    if euiPlayer and euiPlayer.Power and euiPlayer.Power:IsShown() then return euiPlayer.Power end

    -- EllesmereUIResourceBars: primary power is Runic Power for Death Knights.
    if _G.ERB_PrimaryBar and _G.ERB_PrimaryBar:IsShown() then return _G.ERB_PrimaryBar end

    -- Official Blizzard player UI: this returns the active primary resource
    -- bar, including Runic Power for Death Knights.
    if PlayerFrame_GetManaBar then
        local manaBar = PlayerFrame_GetManaBar()
        if manaBar then return manaBar end
    end

    -- Older/default Blizzard resource-frame fallbacks.
    if RuneFrame then
        if RuneFrame.RunicPowerBar then return RuneFrame.RunicPowerBar end
        if RuneFrame.powerBar then return RuneFrame.powerBar end
    end
    return _G.RunicPowerBar
end

local function StopGlow()
    if glowActive and activeBar then
        addon:StopRunicBarGlowFor(activeBar)
        for _, glowType in ipairs(addon.GLOW_TYPES or {}) do
            if glowType.stop then pcall(glowType.stop, activeBar) end
        end
    end
    glowActive = false
    activeGlowType = nil
end

-- Since 12.1, some UI values can be "secret" while in combat.  A normal Lua
-- comparison is not allowed then.  This colour curve asks the game to perform
-- the 85% threshold check itself, and returns a colour that can be applied to
-- a texture safely.  It is the fallback for protected resource bars.
local function GetFallbackCurve(settings)
    local c = settings.color
    local threshold = settings.threshold or THRESHOLD
    local h = fallbackCurveSettings
    if fallbackCurve and h and h.r == c.r and h.g == c.g and h.b == c.b
        and h.a == settings.alpha and h.threshold == threshold then return fallbackCurve end
    if not (C_CurveUtil and C_CurveUtil.CreateColorCurve and CreateColor) then return nil end

    local curve = C_CurveUtil.CreateColorCurve()
    curve:AddPoint(0, CreateColor(0, 0, 0, 0))
    local point = math.max(0.01, math.min(1, threshold / 100))
    curve:AddPoint(math.max(0, point - 0.0001), CreateColor(0, 0, 0, 0))
    curve:AddPoint(point, CreateColor(c.r, c.g, c.b, settings.alpha or 1))
    curve:AddPoint(1, CreateColor(c.r, c.g, c.b, settings.alpha or 1))
    fallbackCurve = curve
    fallbackCurveSettings = {r = c.r, g = c.g, b = c.b, a = settings.alpha, threshold = threshold}
    return curve
end

local function GetFallbackGlow(bar)
    return GetBarGlow(bar)
end

local function UpdateSecretSafeGlow(bar, settings)
    local glow = GetFallbackGlow(bar)
    local curve = GetFallbackCurve(settings)
    if not (glow and curve and UnitPowerPercent) then return end

    local ok, color = pcall(UnitPowerPercent, "player", RUNIC_POWER, false, curve)
    if ok and color and color.GetRGBA then
        -- This mirrors Blizzard's secret-safe threshold colouring: no Lua
        -- comparison is made with the protected resource number.
        glow:SetBackdropBorderColor(color:GetRGBA())
        glow:Show()
    end
end

local function UpdateRunicPowerGlow()
    local settings = GetSettings()
    if not settings or settings.enabled == false then
        StopGlow()
        return
    end

    local powerType = UnitPowerType("player")
    if powerType ~= RUNIC_POWER then
        StopGlow()
        return
    end

    local bar = GetRunicPowerBar()
    if activeBar ~= bar then
        StopGlow()
        activeBar = bar
    end
    if not bar then return end
    if not (InCombatLockdown and InCombatLockdown()) then GetBarGlow(bar) end
    if testing then return end

    local current = UnitPower("player", RUNIC_POWER)
    if issecretvalue and issecretvalue(current) then
        -- Do not leave an old PixelGlow visible after the value becomes secret.
        StopGlow()
        UpdateSecretSafeGlow(bar, settings)
        return
    end

    addon:StopRunicBarGlowFor(bar)

    local shouldGlow = bar and bar:IsVisible() and current >= (settings.threshold or THRESHOLD)
    local glowTypeID = settings.glowType or "pixel"
    if shouldGlow and (not glowActive or activeGlowType ~= glowTypeID) then
        StopGlow()
        if glowTypeID == "pixel" or glowTypeID == "button" then
            addon:StartRunicBarGlow(bar, settings)
        else
            local glowType = addon:GetGlowTypeByID(glowTypeID)
            if glowType and glowType.start then glowType.start(bar, settings) end
        end
        glowActive = true
        activeGlowType = glowTypeID
    elseif not shouldGlow and glowActive then
        StopGlow()
    end
end

function addon:TestRunicPowerGlow()
    local settings = GetSettings()
    local bar = GetRunicPowerBar()
    if not (settings and bar) then
        print("|cffcc0000DK Assist:|r Runic Power bar was not found. Try Rescan Bars.")
        return
    end

    testing = true
    StopGlow()
    activeBar = bar
    addon:StopRunicBarGlowFor(bar)

    local glowTypeID = settings.glowType or "pixel"
    if glowTypeID == "pixel" or glowTypeID == "button" then
        addon:StartRunicBarGlow(bar, settings)
    else
        local glowType = addon:GetGlowTypeByID(glowTypeID)
        if glowType and glowType.start then glowType.start(bar, settings) end
    end
    if glowTypeID == "pixel" or glowTypeID == "button" or addon:GetGlowTypeByID(glowTypeID) then
        glowActive = true
        activeGlowType = glowTypeID
    end
end

function addon:StopRunicPowerGlow()
    testing = false
    StopGlow()
    addon:StopRunicBarGlowFor(activeBar)
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
frame:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
frame:RegisterUnitEvent("UNIT_MAXPOWER", "player")

frame:SetScript("OnEvent", function(_, event, unit, powerToken)
    if event == "UNIT_POWER_UPDATE" and powerToken and powerToken ~= "RUNIC_POWER" then return end
    if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_SPECIALIZATION_CHANGED" then
        C_Timer.After(1, UpdateRunicPowerGlow)
    else
        UpdateRunicPowerGlow()
    end
end)

addon.UpdateRunicPowerGlow = UpdateRunicPowerGlow
