local addonName, addon = ...
DKAssist = addon

local LCG = LibStub("LibCustomGlow-1.0")

addon.SPELLS = {
    FESTERING_SCYTHE = {
        id   = 458128,
        name = "Festering Scythe",
        key  = "festeringScythe",
    },
    FESTERING_STRIKE = {
        id   = 85948,
        name = "Festering Strike",
        key  = "festeringScythe",
    },
    DARK_TRANSFORMATION = {
        id   = 1233448,
        name = "Dark Transformation",
        key  = nil,
    },
    PUTREFY = {
        id   = 1247378,
        name = "Putrefy",
        key  = "putrefy",
    },
    DEATH_AND_DECAY = {
        id   = 43265,
        name = "Death and Decay",
        icon = 136144,
        key  = nil,
    },
    SOUL_REAPER = {
        id   = 343294,
        name = "Soul Reaper",
        key  = nil,
    },
}

addon.GLOW_TYPES = {
    {
        id = "pixel",
        name = "Pixel Glow",
        description = "Rotating pixel lines around the button",
        start = function(frame, opts)
            if LCG and LCG.PixelGlow_Start then
                LCG.PixelGlow_Start(frame,
                    {opts.color.r, opts.color.g, opts.color.b, opts.alpha},
                    opts.lines or 8, opts.speed or 0.25, opts.length,
                    opts.thickness or 2, 0, 0, opts.border, "DKAssist")
            end
        end,
        stop = function(frame)
            if LCG and LCG.PixelGlow_Stop then LCG.PixelGlow_Stop(frame, "DKAssist") end
        end,
    },
    {
        id = "autocast",
        name = "Autocast Shine",
        description = "Sparkling particles at corners",
        start = function(frame, opts)
            if LCG and LCG.AutoCastGlow_Start then
                LCG.AutoCastGlow_Start(frame,
                    {opts.color.r, opts.color.g, opts.color.b, opts.alpha},
                    opts.particles or 4, opts.speed or 0.125, opts.scale or 1,
                    0, 0, "DKAssist")
            end
        end,
        stop = function(frame)
            if LCG and LCG.AutoCastGlow_Stop then LCG.AutoCastGlow_Stop(frame, "DKAssist") end
        end,
    },
    {
        id = "button",
        name = "Button Glow",
        description = "Classic WoW proc glow overlay",
        start = function(frame, opts)
            if LCG and LCG.ButtonGlow_Start then
                LCG.ButtonGlow_Start(frame,
                    {opts.color.r, opts.color.g, opts.color.b, opts.alpha},
                    opts.speed or 0.5)
            end
        end,
        stop = function(frame)
            if LCG and LCG.ButtonGlow_Stop then LCG.ButtonGlow_Stop(frame) end
        end,
    },
    {
        id = "proc",
        name = "Proc Border",
        description = "Animated glowing border",
        start = function(frame, opts)
            if LCG and LCG.ProcGlow_Start then
                LCG.ProcGlow_Start(frame, {
                    key = "DKAssist",
                    color = {opts.color.r, opts.color.g, opts.color.b, opts.alpha},
                    frequency = opts.speed or 0.25,
                    thickness = opts.thickness or 2,
                    startAnim = false,
                })
            end
        end,
        stop = function(frame)
            if LCG and LCG.ProcGlow_Stop then LCG.ProcGlow_Stop(frame, "DKAssist") end
        end,
    },
}

addon.GLOW_TYPE_MAP = {}
for _, glowType in ipairs(addon.GLOW_TYPES) do
    addon.GLOW_TYPE_MAP[glowType.id] = glowType
end

addon.PUTREFY_WARNING_TYPES = {
    {
        id = "cross",
        name = "Red Cross",
        description = "A bold red + cross drawn over the button",
    },
    {
        id = "glow",
        name = "Red Glow Border",
        description = "Pulsing red pixel glow border around the button",
    },
}

addon.PUTREFY_WARNING_TYPE_MAP = {}
for _, wt in ipairs(addon.PUTREFY_WARNING_TYPES) do
    addon.PUTREFY_WARNING_TYPE_MAP[wt.id] = wt
end

local DEFAULT_GLOW_SETTINGS = {
    enabled    = true,
    glowType   = "pixel",
    color      = {r = 0.0, g = 0.9, b = 0.2},
    alpha      = 1.0,
    speed      = 0.25,
    lines      = 8,
    thickness  = 2,
    particles  = 4,
    scale      = 1.0,
    border     = false,
    glowTiming = 5,
    -- Glow on entering combat while the Festering Scythe buff is missing, after
    -- combatGrace seconds. 0 grace shows it immediately.
    combatGlow  = true,
    combatGrace = 0,
}

local DEFAULT_PUTREFY_SETTINGS = {
    enabled        = true,
    warningType    = "cross",
    crossColor     = {r = 1.0, g = 0.0, b = 0.0},
    crossAlpha     = 0.9,
    crossThickness = 0.25,
    glowColor      = {r = 1.0, g = 0.0, b = 0.0},
    glowAlpha      = 1.0,
    glowSpeed      = 0.25,
    glowLines      = 8,
    glowThickness  = 3,
}

addon.DEFAULT_DB = {
    seenWelcome       = false,
    trackCDMFestering = false,
    trackCDMPutrefy   = false,
    spells = {
        festeringScythe = CopyTable(DEFAULT_GLOW_SETTINGS),
    },
    putrefy = CopyTable(DEFAULT_PUTREFY_SETTINGS),
    dnd = {
        enabled    = true,
        size       = 48,
        locked     = false,
        alwaysShow = false,
        position   = nil,  -- {point, relPoint, x, y}
    },
    soulReaper = {
        suppressMode = "off",  -- "off", "cooldown", "always"
    },
}

function addon:GetGlowTypeByID(id)
    return addon.GLOW_TYPE_MAP[id] or addon.GLOW_TYPES[1]
end

local festeringOverlays    = {}
local putrefyOverlays      = {}
local cdmFesteringOverlays = {}
local cdmPutrefyOverlays   = {}
local putrefyWarningActive = false

local function CreateOverlay(targetFrame, spellKey)
    local overlay = CreateFrame("Frame", nil, targetFrame)
    overlay:SetFrameStrata("HIGH")
    overlay:SetAllPoints(targetFrame)
    overlay:SetFrameLevel(targetFrame:GetFrameLevel() + 10)
    overlay._targetFrame = targetFrame
    overlay._spellKey    = spellKey
    overlay._glowActive  = false
    overlay:Hide()
    return overlay
end

local function AttachCrossToOverlay(overlay)
    if overlay._crossH then return end
    local h = overlay:CreateTexture(nil, "OVERLAY")
    h:SetColorTexture(1, 0, 0, 0.9)
    overlay._crossH = h
    local v = overlay:CreateTexture(nil, "OVERLAY")
    v:SetColorTexture(1, 0, 0, 0.9)
    overlay._crossV = v
end

local function UpdateCrossAppearance(overlay)
    if not overlay._crossH then return end
    local settings  = DKAssistDB.putrefy
    local thickness = settings.crossThickness or 0.25
    local r = settings.crossColor.r
    local g = settings.crossColor.g
    local b = settings.crossColor.b
    local a = settings.crossAlpha or 0.9

    overlay._crossH:SetColorTexture(r, g, b, a)
    overlay._crossH:ClearAllPoints()
    overlay._crossH:SetPoint("LEFT",  overlay, "LEFT",  0, 0)
    overlay._crossH:SetPoint("RIGHT", overlay, "RIGHT", 0, 0)

    overlay._crossV:SetColorTexture(r, g, b, a)
    overlay._crossV:ClearAllPoints()
    overlay._crossV:SetPoint("TOP",    overlay, "TOP",    0, 0)
    overlay._crossV:SetPoint("BOTTOM", overlay, "BOTTOM", 0, 0)

    local w, ht = overlay:GetSize()
    if w and w > 1 then
        overlay._crossH:SetHeight(math.max(2, ht * thickness))
        overlay._crossV:SetWidth(math.max(2, w * thickness))
    end

    overlay:SetScript("OnSizeChanged", function(self, nw, nh)
        if self._crossH then
            self._crossH:SetHeight(math.max(2, nh * thickness))
            self._crossV:SetWidth(math.max(2, nw * thickness))
        end
    end)
end

function addon:CreateFesteringOverlays()
    for _, overlay in pairs(festeringOverlays) do
        if overlay._glowActive then
            local gt = self:GetGlowTypeByID(DKAssistDB.spells.festeringScythe.glowType)
            if gt and gt.stop then pcall(gt.stop, overlay) end
        end
        overlay:Hide()
        overlay:SetParent(nil)
    end
    wipe(festeringOverlays)

    for spellKey, buttons in pairs(addon.trackedButtons or {}) do
        if spellKey == "festeringScythe" then
            for _, button in ipairs(buttons) do
                festeringOverlays[button] = CreateOverlay(button, spellKey)
            end
        end
    end

    -- The overlays the glow was running on have just been thrown away. A bar
    -- rescan can happen at any time (dismounting fires one 0.5s later), so put
    -- the glow back rather than letting it silently vanish mid-combat.
    addon:RestoreFesteringGlow()
end

function addon:CreatePutrefyOverlays()
    for _, overlay in pairs(putrefyOverlays) do
        addon:_StopPutrefyOverlay(overlay)
        overlay:Hide()
        overlay:SetParent(nil)
    end
    wipe(putrefyOverlays)

    for spellKey, buttons in pairs(addon.trackedButtons or {}) do
        if spellKey == "putrefy" then
            for _, button in ipairs(buttons) do
                local overlay = CreateOverlay(button, "putrefy")
                AttachCrossToOverlay(overlay)
                putrefyOverlays[button] = overlay
            end
        end
    end
end

-- Called by CDMHook.lua after Blizzard refreshes a specific CDM item. This
-- never inspects textures or enumerates arbitrary UI frames.
function addon:RegisterCDMPutrefyFrame(frame)
    if not DKAssistDB.trackCDMPutrefy or cdmPutrefyOverlays[frame] then return end
    local overlay = CreateOverlay(frame, "putrefy")
    AttachCrossToOverlay(overlay)
    cdmPutrefyOverlays[frame] = overlay
    if putrefyWarningActive then addon:RefreshPutrefyWarnings() end
end

-- 12.1 can contain thousands of UI frames. Keep discovery bounded so a scan
-- cannot monopolize a rendered frame after login, zoning, or a spec change.
local cdmScanRunning = false
local cdmDisabledFor121 = false

function addon:CreateCDMOverlays()
    for _, overlay in pairs(cdmFesteringOverlays) do
        if overlay._glowActive then
            local gt = self:GetGlowTypeByID(DKAssistDB.spells.festeringScythe.glowType)
            if gt and gt.stop then pcall(gt.stop, overlay) end
        end
        overlay:Hide()
        overlay:SetParent(nil)
    end
    wipe(cdmFesteringOverlays)

    for _, overlay in pairs(cdmPutrefyOverlays) do
        addon:_StopPutrefyOverlay(overlay)
        overlay:Hide()
        overlay:SetParent(nil)
    end
    wipe(cdmPutrefyOverlays)

    if not DKAssistDB.trackCDMFestering and not DKAssistDB.trackCDMPutrefy then return end

    local scStr  = "3997563"
    local fsStr  = "879926"
    local putStr = "7439191"

    local frame = EnumerateFrames()
    while frame do
        if frame.Icon and type(frame.Icon) == "table" and frame.Icon.GetTexture then
            local ok, matched = pcall(function()
                local tex = frame.Icon:GetTexture()
                if tex then
                    local texStr = tostring(tex)
                    if DKAssistDB.trackCDMFestering and (texStr == scStr or texStr == fsStr) then
                        return "festering"
                    elseif DKAssistDB.trackCDMPutrefy and texStr == putStr then
                        return "putrefy"
                    end
                end
                return nil
            end)
            if ok and matched == "festering" then
                local overlay = CreateFrame("Frame", nil, frame)
                overlay:SetFrameStrata("HIGH")
                overlay:SetAllPoints(frame)
                overlay:SetFrameLevel(frame:GetFrameLevel() + 10)
                overlay._targetFrame = frame
                overlay._glowActive  = false
                overlay:Hide()
                cdmFesteringOverlays[frame] = overlay
            elseif ok and matched == "putrefy" then
                local overlay = CreateFrame("Frame", nil, frame)
                overlay:SetFrameStrata("HIGH")
                overlay:SetAllPoints(frame)
                overlay:SetFrameLevel(frame:GetFrameLevel() + 10)
                overlay._targetFrame = frame
                overlay._glowActive  = false
                AttachCrossToOverlay(overlay)
                overlay:Hide()
                cdmPutrefyOverlays[frame] = overlay
            end
        end
        frame = EnumerateFrames(frame)
    end
end

-- Additive CDM overlay creation — only creates overlays for frames not already tracked
-- Called by ScanCDMSafe() to avoid disrupting active glows
function addon:CreateCDMOverlaysAdditive()
    if not DKAssistDB.trackCDMFestering and not DKAssistDB.trackCDMPutrefy then return 0 end

    local scStr  = "3997563"
    local fsStr  = "879926"
    local putStr = "7439191"
    local added  = 0

    local frame = EnumerateFrames()
    while frame do
        if frame.Icon and type(frame.Icon) == "table" and frame.Icon.GetTexture then
            -- Skip frames already tracked
            if not cdmFesteringOverlays[frame] and not cdmPutrefyOverlays[frame] then
                local ok, matched = pcall(function()
                    local tex = frame.Icon:GetTexture()
                    if tex then
                        local texStr = tostring(tex)
                        if DKAssistDB.trackCDMFestering and (texStr == scStr or texStr == fsStr) then
                            return "festering"
                        elseif DKAssistDB.trackCDMPutrefy and texStr == putStr then
                            return "putrefy"
                        end
                    end
                    return nil
                end)
                if ok and matched == "festering" then
                    local overlay = CreateFrame("Frame", nil, frame)
                    overlay:SetFrameStrata("HIGH")
                    overlay:SetAllPoints(frame)
                    overlay:SetFrameLevel(frame:GetFrameLevel() + 10)
                    overlay._targetFrame = frame
                    overlay._glowActive  = false
                    overlay:Hide()
                    cdmFesteringOverlays[frame] = overlay
                    added = added + 1
                elseif ok and matched == "putrefy" then
                    local overlay = CreateFrame("Frame", nil, frame)
                    overlay:SetFrameStrata("HIGH")
                    overlay:SetAllPoints(frame)
                    overlay:SetFrameLevel(frame:GetFrameLevel() + 10)
                    overlay._targetFrame = frame
                    overlay._glowActive  = false
                    AttachCrossToOverlay(overlay)
                    overlay:Hide()
                    cdmPutrefyOverlays[frame] = overlay
                    added = added + 1
                end
            end
        end
        frame = EnumerateFrames(frame)
    end

    return added
end

-- Override the legacy synchronous frame walk above.  The scan is deliberately
-- incremental: 40 frames per game tick keeps this compatible with the larger
-- 12.1 UI frame tree without causing a client-wide hitch.
local function StartSafeCDMScan(reset)
    -- CDM items are registered by CDMHook.lua as Blizzard refreshes them.
    -- Do not enumerate UI frames or read protected texture identifiers.
    -- Keep the legacy code below syntactically isolated while the supported
    -- CDM hook path in CDMHook.lua performs registration.
    if true then return 0 end

    -- Legacy implementation retained below for future API support.
    if not DKAssistDB.trackCDMFestering and not DKAssistDB.trackCDMPutrefy then return 0 end
    if cdmScanRunning then return 0 end

    if reset then
        for _, overlay in pairs(cdmFesteringOverlays) do
            if overlay._glowActive then
                local gt = addon:GetGlowTypeByID(DKAssistDB.spells.festeringScythe.glowType)
                if gt and gt.stop then pcall(gt.stop, overlay) end
            end
            overlay:Hide(); overlay:SetParent(nil)
        end
        for _, overlay in pairs(cdmPutrefyOverlays) do
            addon:_StopPutrefyOverlay(overlay); overlay:SetParent(nil)
        end
        wipe(cdmFesteringOverlays); wipe(cdmPutrefyOverlays)
    end

    cdmScanRunning = true
    local current, added = nil, 0
    local function ScanBatch()
        for _ = 1, 40 do
            current = EnumerateFrames(current)
            if not current then
                cdmScanRunning = false
                addon._lastCDMScanAdded = added
                return
            end
            if not cdmFesteringOverlays[current] and not cdmPutrefyOverlays[current]
                and current.Icon and type(current.Icon) == "table" and current.Icon.GetTexture then
                local ok, texture = pcall(current.Icon.GetTexture, current.Icon)
                local id = ok and texture and tostring(texture)
                local kind = nil
                if DKAssistDB.trackCDMFestering and (id == "3997563" or id == "879926") then kind = "festering" end
                if DKAssistDB.trackCDMPutrefy and id == "7439191" then kind = "putrefy" end
                if kind then
                    local overlay = CreateFrame("Frame", nil, current)
                    overlay:SetFrameStrata("HIGH"); overlay:SetAllPoints(current)
                    overlay:SetFrameLevel(current:GetFrameLevel() + 10)
                    overlay._targetFrame, overlay._glowActive = current, false
                    overlay:Hide()
                    if kind == "festering" then
                        cdmFesteringOverlays[current] = overlay
                    else
                        AttachCrossToOverlay(overlay)
                        cdmPutrefyOverlays[current] = overlay
                    end
                    added = added + 1
                end
            end
        end
        C_Timer.After(0, ScanBatch)
    end
    C_Timer.After(0, ScanBatch)
    return 0
end

function addon:CreateCDMOverlays() return StartSafeCDMScan(true) end
function addon:CreateCDMOverlaysAdditive() return StartSafeCDMScan(false) end

local FESTERING_BUFF_DURATION = 25

local festeringTimer      = nil
local festeringGraceTimer = nil
local festeringGlowActive = false
-- The glow means "you are missing the Festering Scythe buff". It is suppressed
-- only for the fresh part of the buff: from the cast until glowTiming seconds
-- remain. Suppression keeps running out of combat because the buff does too,
-- but the glow itself is only ever rendered while in combat.
local festeringSuppressed = false

local function HideFesteringGlow()
    festeringGlowActive = false
    local function hideOverlay(overlay)
        if overlay._glowActive then
            local gt = addon:GetGlowTypeByID(DKAssistDB.spells.festeringScythe.glowType)
            if gt and gt.stop then pcall(gt.stop, overlay) end
            overlay._glowActive = false
        end
        overlay:Hide()
    end
    for _, overlay in pairs(festeringOverlays)    do hideOverlay(overlay) end
    for _, overlay in pairs(cdmFesteringOverlays) do hideOverlay(overlay) end
end

local function CancelFesteringGrace()
    if festeringGraceTimer then
        festeringGraceTimer:Cancel()
        festeringGraceTimer = nil
    end
end

-- Cancels the pending timers as well as the glow. Used when the tracking cycle
-- should be abandoned entirely (spec change, test mode ending), not when the
-- player merely drops combat.
local function StopFesteringGlow()
    if festeringTimer then
        festeringTimer:Cancel()
        festeringTimer = nil
    end
    CancelFesteringGrace()
    festeringSuppressed = false
    HideFesteringGlow()
end

local function ShowFesteringGlow()
    festeringGlowActive = true
    local settings = DKAssistDB.spells.festeringScythe
    if not settings.enabled then return end

    local function applyGlow(overlay, skipVisCheck)
        local target = overlay._targetFrame
        if target and (skipVisCheck or target:IsVisible()) then
            overlay:Show()
            if not overlay._glowActive then
                local gt = addon:GetGlowTypeByID(settings.glowType)
                if gt and gt.start then
                    gt.start(overlay, settings)
                    overlay._glowActive = true
                end
            end
        end
    end

    for _, overlay in pairs(festeringOverlays)    do applyGlow(overlay, false) end
    for _, overlay in pairs(cdmFesteringOverlays) do applyGlow(overlay, true)  end
end

local function StartFesteringTimer()
    StopFesteringGlow()

    local settings = DKAssistDB.spells.festeringScythe
    if not settings.enabled then return end

    local timing = settings.glowTiming or 5
    local delay  = math.max(1, FESTERING_BUFF_DURATION - timing)

    festeringSuppressed = true
    festeringTimer = C_Timer.NewTimer(delay, function()
        festeringTimer      = nil
        festeringSuppressed = false
        -- Only render while in combat; PLAYER_REGEN_DISABLED picks it up if the
        -- player re-enters combat later.
        if InCombatLockdown() then ShowFesteringGlow() end
    end)
end

function addon:OnFesteringScytheCast()
    StartFesteringTimer()
end

-- Leaving combat hides the glow but deliberately keeps festeringTimer running,
-- because the Festering Scythe buff keeps ticking out of combat.
local function OnFesteringCombatEnd()
    CancelFesteringGrace()
    HideFesteringGlow()
end

-- Entering combat without a fresh buff glows after combatGrace seconds, and
-- only if the player has not cast Festering Scythe or dropped combat in the
-- meantime. Entering combat with a fresh buff does nothing here; the
-- suppression timer shows the expiry warning at the right moment instead, and
-- that warning is never gated by these settings.
local function OnFesteringCombatStart()
    if festeringSuppressed then return end
    CancelFesteringGrace()

    local settings = DKAssistDB.spells.festeringScythe
    if not settings.enabled then return end
    if settings.combatGlow == false then return end

    local grace = settings.combatGrace or 0
    if grace <= 0 then
        ShowFesteringGlow()
        return
    end

    festeringGraceTimer = C_Timer.NewTimer(grace, function()
        festeringGraceTimer = nil
        if not festeringSuppressed and InCombatLockdown() then
            ShowFesteringGlow()
        end
    end)
end

-- Called from the options panel when the combat-start glow is switched off, so
-- a grace timer armed under the old setting cannot still fire.
function addon:CancelFesteringCombatGlow()
    CancelFesteringGrace()
end

-- Re-applies the glow to freshly built overlays after a bar rescan. Defined on
-- addon rather than as a local because CreateFesteringOverlays sits above this
-- section in the file; it only ever runs at runtime, so the lookup is safe.
function addon:RestoreFesteringGlow()
    if festeringGlowActive then ShowFesteringGlow() end
end

function addon:RefreshFesteringGlows()
    if festeringGlowActive then
        HideFesteringGlow()
        ShowFesteringGlow()
    end
end

local putrefyWarningTimer  = nil
local putrefyDurationTimer = nil
putrefyWarningActive = false
local darkTransformationEndsAt = 0
local darkTransformationReadyAt = 0
local DARK_TRANSFORMATION_BASE_DURATION = 15
local DARK_TRANSFORMATION_COOLDOWN = 45

function addon:_StopPutrefyOverlay(overlay)
    local settings = DKAssistDB.putrefy
    if overlay._glowActive then
        if settings.warningType == "glow" and LCG and LCG.PixelGlow_Stop then
            pcall(LCG.PixelGlow_Stop, overlay, "DKAssistPutrefy")
        end
        overlay._glowActive = false
    end
    if overlay._crossH then
        overlay._crossH:Hide()
        overlay._crossV:Hide()
    end
    overlay:Hide()
end

local function StopPutrefyWarning()
    putrefyWarningActive = false
    if putrefyWarningTimer then
        putrefyWarningTimer:Cancel()
        putrefyWarningTimer = nil
    end
    if putrefyDurationTimer then
        putrefyDurationTimer:Cancel()
        putrefyDurationTimer = nil
    end
    for _, overlay in pairs(putrefyOverlays)    do addon:_StopPutrefyOverlay(overlay) end
    for _, overlay in pairs(cdmPutrefyOverlays) do addon:_StopPutrefyOverlay(overlay) end
end

local function ShowPutrefyWarning(duration)
    if putrefyDurationTimer then
        putrefyDurationTimer:Cancel()
        putrefyDurationTimer = nil
    end

    putrefyWarningActive = true
    local settings = DKAssistDB.putrefy
    if not settings.enabled then return end

    local function applyWarning(overlay, skipVisCheck)
        local target = overlay._targetFrame
        if target and (skipVisCheck or target:IsVisible()) then
            overlay:Show()
            if settings.warningType == "cross" then
                UpdateCrossAppearance(overlay)
                if overlay._crossH then overlay._crossH:Show() end
                if overlay._crossV then overlay._crossV:Show() end
                overlay._glowActive = true
            elseif settings.warningType == "glow" then
                if not overlay._glowActive then
                    if LCG and LCG.PixelGlow_Start then
                        LCG.PixelGlow_Start(overlay,
                            {settings.glowColor.r, settings.glowColor.g, settings.glowColor.b, settings.glowAlpha},
                            settings.glowLines or 8, settings.glowSpeed or 0.25, nil,
                            settings.glowThickness or 3, 0, 0, false, "DKAssistPutrefy")
                        overlay._glowActive = true
                    end
                end
            end
        end
    end

    for _, overlay in pairs(putrefyOverlays)    do applyWarning(overlay, false) end
    for _, overlay in pairs(cdmPutrefyOverlays) do applyWarning(overlay, true)  end

    if duration then
        putrefyDurationTimer = C_Timer.NewTimer(math.max(0.1, duration), function()
            putrefyDurationTimer = nil
            StopPutrefyWarning()
        end)
    end
end

function addon:ShowPutrefyHoldWarning()
    if DKAssistDB and DKAssistDB.putrefy and DKAssistDB.putrefy.enabled then
        ShowPutrefyWarning()
    end
end

function addon:OnDarkTransformationCast()
    if putrefyWarningTimer then
        putrefyWarningTimer:Cancel()
        putrefyWarningTimer = nil
    end
    if putrefyDurationTimer then
        putrefyDurationTimer:Cancel()
        putrefyDurationTimer = nil
    end
    putrefyWarningActive = false
    for _, overlay in pairs(putrefyOverlays)    do addon:_StopPutrefyOverlay(overlay) end
    for _, overlay in pairs(cdmPutrefyOverlays) do addon:_StopPutrefyOverlay(overlay) end

    darkTransformationEndsAt = GetTime() + DARK_TRANSFORMATION_BASE_DURATION
    addon:RefreshDarkTransformationWindow()
end

function addon:RefreshDarkTransformationWindow()
    if putrefyWarningTimer then putrefyWarningTimer:Cancel(); putrefyWarningTimer = nil end
    if putrefyDurationTimer then putrefyDurationTimer:Cancel(); putrefyDurationTimer = nil end

    local now = GetTime()
    local activeRemaining = darkTransformationEndsAt - now
    if activeRemaining <= 0 then
        ShowPutrefyWarning()
        return
    end

    putrefyWarningTimer = C_Timer.NewTimer(activeRemaining, function()
        putrefyWarningTimer = nil
        ShowPutrefyWarning()
    end)
end

function addon:OnDarkTransformationExtended()
    if darkTransformationEndsAt <= GetTime() then return end
    darkTransformationEndsAt = darkTransformationEndsAt + 1
    addon:RefreshDarkTransformationWindow()
end

function addon:RefreshPutrefyWarnings()
    if putrefyWarningActive then
        for _, overlay in pairs(putrefyOverlays)    do addon:_StopPutrefyOverlay(overlay) end
        for _, overlay in pairs(cdmPutrefyOverlays) do addon:_StopPutrefyOverlay(overlay) end
        ShowPutrefyWarning()
    end
end

function addon:TestFesteringGlow()
    ShowFesteringGlow()
end

function addon:TestPutrefyWarning()
    ShowPutrefyWarning()
end

function addon:StopAll()
    StopFesteringGlow()
    StopPutrefyWarning()
end

-- -------------------------------------------------------
-- Death and Decay Tracker
-- -------------------------------------------------------
local DND_DURATION  = 10
local dndFrame      = nil
local dndHideTimer  = nil

local function CreateDnDFrame()
    if dndFrame then return dndFrame end

    local f = CreateFrame("Frame", "DKAssistDnDTracker", UIParent, "BackdropTemplate")
    f:SetSize(48, 48)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, -200)
    f:SetFrameStrata("MEDIUM")
    f:SetFrameLevel(10)
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(false)

    -- Border
    f:SetBackdrop({
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    f:SetBackdropBorderColor(0, 0, 0, 1)

    -- Icon texture
    f.icon = f:CreateTexture(nil, "ARTWORK")
    f.icon:SetPoint("TOPLEFT", 1, -1)
    f.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    f.icon:SetTexture(136144)
    f.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    -- Cooldown swipe
    f.cooldown = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    f.cooldown:SetAllPoints(f.icon)
    f.cooldown:SetDrawEdge(true)
    f.cooldown:SetDrawSwipe(true)
    f.cooldown:SetReverse(true)
    f.cooldown:SetHideCountdownNumbers(false)

    -- Drag handling (only when unlocked)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if DKAssistDB.dnd and not DKAssistDB.dnd.locked then
            self:StartMoving()
        end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relPoint, x, y = self:GetPoint()
        if DKAssistDB.dnd then
            DKAssistDB.dnd.position = {point, relPoint, x, y}
        end
    end)

    f:Hide()
    dndFrame = f
    return f
end

local dndActive = false  -- true when the 10s timer is running

local function UpdateDnDDesaturation()
    if not dndFrame then return end
    if dndActive then
        dndFrame.icon:SetDesaturated(false)
        dndFrame.icon:SetVertexColor(1, 1, 1, 1)
    else
        dndFrame.icon:SetDesaturated(true)
        dndFrame.icon:SetVertexColor(0.6, 0.6, 0.6, 1)
    end
end

local function ShowDnDAlwaysShow()
    if not dndFrame then return end
    local s = DKAssistDB.dnd
    if s.alwaysShow and s.enabled then
        dndFrame:Show()
        UpdateDnDDesaturation()
    elseif not dndActive then
        dndFrame:Hide()
    end
end

local function ApplyDnDSettings()
    if not dndFrame then return end
    local s = DKAssistDB.dnd
    local size = s.size or 48
    dndFrame:SetSize(size, size)

    if s.position then
        dndFrame:ClearAllPoints()
        dndFrame:SetPoint(s.position[1], UIParent, s.position[2], s.position[3], s.position[4])
    end

    -- Enable/disable mouse for dragging based on lock state
    dndFrame:EnableMouse(not s.locked)

    ShowDnDAlwaysShow()
end

function addon:InitDnDTracker()
    CreateDnDFrame()
    ApplyDnDSettings()
end

function addon:OnDeathAndDecayCast()
    local s = DKAssistDB.dnd
    if not s or not s.enabled then return end

    if not dndFrame then CreateDnDFrame() ApplyDnDSettings() end

    -- Cancel any pending hide timer (handles recast within 10s)
    if dndHideTimer then
        dndHideTimer:Cancel()
        dndHideTimer = nil
    end

    -- Mark active and show with full color
    dndActive = true
    UpdateDnDDesaturation()

    -- Reset cooldown swipe from scratch
    dndFrame.cooldown:SetCooldown(GetTime(), DND_DURATION)
    dndFrame:Show()

    -- After duration: hide or go desaturated
    dndHideTimer = C_Timer.NewTimer(DND_DURATION, function()
        dndHideTimer = nil
        dndActive = false
        dndFrame.cooldown:Clear()
        if s.alwaysShow then
            UpdateDnDDesaturation()
        else
            dndFrame:Hide()
        end
    end)
end

function addon:TestDnDTracker()
    if not dndFrame then CreateDnDFrame() ApplyDnDSettings() end

    -- Cancel any existing hide timer
    if dndHideTimer then
        dndHideTimer:Cancel()
        dndHideTimer = nil
    end

    -- Show the frame with no swipe during test — just the icon for positioning
    dndActive = false
    dndFrame.cooldown:Clear()
    dndFrame.icon:SetDesaturated(false)
    dndFrame.icon:SetVertexColor(1, 1, 1, 1)
    dndFrame:Show()
    dndFrame:EnableMouse(true) -- always draggable during test
end

function addon:StopDnDTest()
    if dndHideTimer then
        dndHideTimer:Cancel()
        dndHideTimer = nil
    end
    if dndFrame then
        dndActive = false
        dndFrame.cooldown:Clear()
        -- Restore lock state and alwaysShow behavior
        ApplyDnDSettings()
        if not DKAssistDB.dnd.alwaysShow then
            dndFrame:Hide()
        end
    end
end

function addon:RefreshDnDTracker()
    if dndFrame then ApplyDnDSettings() end
end

function addon:RefreshDnDAlwaysShow()
    if not dndFrame then CreateDnDFrame() end
    ApplyDnDSettings()
end

-- -------------------------------------------------------
-- Soul Reaper Glow Suppression
-- -------------------------------------------------------
local SOUL_REAPER_ID = 343294

local function ShouldSuppressSoulReaperGlow()
    local s = DKAssistDB and DKAssistDB.soulReaper
    if not s then return false end
    return s.suppressMode == "always"
end

local function GetButtonSpellIDForGlow(button)
    -- Try GetSpellId (Blizzard default bars)
    if button.GetSpellId then
        local ok, id = pcall(button.GetSpellId, button)
        if ok and id then return id end
    end
    -- Try action slot lookup
    local actionSlot = nil
    if button.action and type(button.action) == "number" then
        actionSlot = button.action
    elseif button._state_action and type(button._state_action) == "number" then
        actionSlot = button._state_action
    end
    if actionSlot then
        local ok, aType, aId = pcall(GetActionInfo, actionSlot)
        if ok and aType == "spell" then return aId end
    end
    return nil
end

function addon:SetupSoulReaperHook()
    -- Hook ActionButton_ShowOverlayGlow for default Blizzard bars
    if ActionButton_ShowOverlayGlow then
        hooksecurefunc("ActionButton_ShowOverlayGlow", function(button)
            if not ShouldSuppressSoulReaperGlow() then return end
            local spellID = GetButtonSpellIDForGlow(button)
            if spellID == SOUL_REAPER_ID then
                if ActionButton_HideOverlayGlow then
                    ActionButton_HideOverlayGlow(button)
                end
            end
        end)
    end

    -- Hook LibButtonGlow for addon bars (Bartender4, ElvUI, Dominos)
    local LBG = LibStub and LibStub("LibButtonGlow-1.0", true)
    if LBG and LBG.ShowOverlayGlow then
        local origShow = LBG.ShowOverlayGlow
        LBG.ShowOverlayGlow = function(button, ...)
            if ShouldSuppressSoulReaperGlow() then
                local spellID = GetButtonSpellIDForGlow(button)
                if spellID == SOUL_REAPER_ID then
                    if LBG.HideOverlayGlow then
                        LBG.HideOverlayGlow(button)
                    end
                    return
                end
            end
            return origShow(button, ...)
        end
    end
end

local castFrame = CreateFrame("Frame")
castFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
castFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
castFrame:RegisterEvent("PLAYER_REGEN_DISABLED")

castFrame:SetScript("OnEvent", function(_, event, unit, _, spellID)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        if unit ~= "player" then return end
        if spellID == addon.SPELLS.FESTERING_SCYTHE.id then
            addon:OnFesteringScytheCast()
        elseif spellID == addon.SPELLS.DARK_TRANSFORMATION.id then
            addon:OnDarkTransformationCast()
        elseif spellID == 47541 or spellID == 207317 then -- Death Coil / Epidemic
            addon:OnDarkTransformationExtended()
        elseif spellID == addon.SPELLS.DEATH_AND_DECAY.id then
            addon:OnDeathAndDecayCast()
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        OnFesteringCombatEnd()
        StopPutrefyWarning()
        addon:ShowPutrefyHoldWarning()
    elseif event == "PLAYER_REGEN_DISABLED" then
        OnFesteringCombatStart()
    end
end)

function addon:ShowWelcomePopup()
    local popup = CreateFrame("Frame", "DKAssistWelcomePopup", UIParent, "BackdropTemplate")
    popup:SetSize(420, 210)
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    popup:SetFrameStrata("DIALOG")
    popup:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 2,
    })
    popup:SetBackdropColor(0.08, 0.08, 0.08, 0.96)
    popup:SetBackdropBorderColor(0.8, 0.0, 0.0, 1)
    popup:SetMovable(true)
    popup:EnableMouse(true)
    popup:RegisterForDrag("LeftButton")
    popup:SetScript("OnDragStart", popup.StartMoving)
    popup:SetScript("OnDragStop", popup.StopMovingOrSizing)

    local title = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", popup, "TOP", 0, -16)
    title:SetText("|cffcc0000DK Assist|r")

    local message = popup:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    message:SetPoint("TOP", title, "BOTTOM", 0, -12)
    message:SetWidth(380)
    message:SetJustifyH("CENTER")
    message:SetText(
        "Welcome to DK Assist!\n\n" ..
        "|cffaaff44Festering Scythe:|r Glows Festering Strike/Scythe when <5 seconds remaining on the buff.\n" ..
        "|cffff4444Putrefy Warning:|r Shows a warning on Putrefy when Dark Transformation has less than 15 seconds cooldown remaining.\n\n" ..
        "Open settings to configure glow styles and colors."
    )

    local settingsBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    settingsBtn:SetSize(130, 26)
    settingsBtn:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 50, 20)
    settingsBtn:SetText("Open Settings")
    settingsBtn:SetScript("OnClick", function()
        DKAssistDB.seenWelcome = true
        popup:Hide()
        if addon.settingsCategory then
            Settings.OpenToCategory(addon.settingsCategory:GetID())
        end
    end)

    local closeBtn = CreateFrame("Button", nil, popup, "UIPanelButtonTemplate")
    closeBtn:SetSize(80, 26)
    closeBtn:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -50, 20)
    closeBtn:SetText("Close")
    closeBtn:SetScript("OnClick", function()
        DKAssistDB.seenWelcome = true
        popup:Hide()
    end)

    local xBtn = CreateFrame("Button", nil, popup, "UIPanelCloseButton")
    xBtn:SetPoint("TOPRIGHT", popup, "TOPRIGHT", 2, 2)
    xBtn:SetScript("OnClick", function()
        DKAssistDB.seenWelcome = true
        popup:Hide()
    end)

    popup:Show()
end

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

initFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        if not DKAssistDB then
            DKAssistDB = CopyTable(addon.DEFAULT_DB)
        end

        if not DKAssistDB.spells then DKAssistDB.spells = {} end
        if not DKAssistDB.spells.festeringScythe then
            DKAssistDB.spells.festeringScythe = CopyTable(addon.DEFAULT_DB.spells.festeringScythe)
        else
            for k, v in pairs(addon.DEFAULT_DB.spells.festeringScythe) do
                if DKAssistDB.spells.festeringScythe[k] == nil then
                    DKAssistDB.spells.festeringScythe[k] = v
                end
            end
        end
        if not DKAssistDB.putrefy then
            DKAssistDB.putrefy = CopyTable(addon.DEFAULT_DB.putrefy)
        else
            for k, v in pairs(addon.DEFAULT_DB.putrefy) do
                if DKAssistDB.putrefy[k] == nil then DKAssistDB.putrefy[k] = v end
            end
        end
        if DKAssistDB.trackCDMFestering == nil then DKAssistDB.trackCDMFestering = false end
        if DKAssistDB.trackCDMPutrefy   == nil then DKAssistDB.trackCDMPutrefy   = false end

        -- Death and Decay tracker defaults
        if not DKAssistDB.dnd then
            DKAssistDB.dnd = CopyTable(addon.DEFAULT_DB.dnd)
        else
            for k, v in pairs(addon.DEFAULT_DB.dnd) do
                if DKAssistDB.dnd[k] == nil then DKAssistDB.dnd[k] = v end
            end
        end

        -- Soul Reaper defaults
        if not DKAssistDB.soulReaper then
            DKAssistDB.soulReaper = CopyTable(addon.DEFAULT_DB.soulReaper)
        else
            for k, v in pairs(addon.DEFAULT_DB.soulReaper) do
                if DKAssistDB.soulReaper[k] == nil then DKAssistDB.soulReaper[k] = v end
            end
        end

        C_Timer.After(1, function() addon:ScanAllButtons() end)
        C_Timer.After(1, function() addon:InitDnDTracker() end)
        C_Timer.After(1, function() addon:SetupSoulReaperHook() end)
        C_Timer.After(2, function() addon:ShowPutrefyHoldWarning() end)

        if addon.CreateConfigPanel then
            local panel = addon:CreateConfigPanel()
            local category = Settings.RegisterCanvasLayoutCategory(panel, "DK Assist")
            Settings.RegisterAddOnCategory(category)
            addon.settingsCategory = category

            -- The minimap button uses a dedicated DK Assist window; the same
            -- configuration remains available in Blizzard's AddOns settings.
            local window = CreateFrame("Frame", "DKAssistSettingsWindow", UIParent, "BackdropTemplate")
            window:SetSize(820, 700)
            window:SetPoint("CENTER")
            window:SetFrameStrata("DIALOG")
            window:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
                tile = true, tileSize = 32, edgeSize = 32,
                insets = { left = 11, right = 12, top = 12, bottom = 11 },
            })
            window:SetBackdropColor(0, 0, 0, 1)
            window:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
            window:EnableMouse(true)
            window:SetMovable(true)
            window:RegisterForDrag("LeftButton")
            window:SetScript("OnDragStart", window.StartMoving)
            window:SetScript("OnDragStop", window.StopMovingOrSizing)
            window:Hide()

            local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
            close:SetPoint("TOPRIGHT", window, "TOPRIGHT", -4, -4)
            close:SetScript("OnClick", function() window:Hide() end)

            local standalonePanel = addon:CreateConfigPanel(true)
            standalonePanel:SetParent(window)
            standalonePanel:SetPoint("TOPLEFT", window, "TOPLEFT", 18, -18)
            standalonePanel:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -18, 18)
            addon.standaloneSettingsWindow = window
            addon.standaloneSettingsPanel = standalonePanel
            function addon:OpenStandaloneSettings()
                if SettingsPanel and SettingsPanel:IsShown() then SettingsPanel:Hide() end
                window:Show()
                standalonePanel:Show()
                standalonePanel:RefreshControls()
            end
        end

        if not DKAssistDB.seenWelcome then
            C_Timer.After(2, function() addon:ShowWelcomePopup() end)
        end

        print("|cffcc0000DK Assist|r loaded — |cffaaaaaa/dka|r for options")

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        addon:StopAll()
        C_Timer.After(0.5, function() addon:ScanAllButtons() end)
        -- CDM rescan is handled by ButtonScanner's PLAYER_SPECIALIZATION_CHANGED handler
    end
end)

SLASH_DKASSIST1 = "/dka"
SLASH_DKASSIST2 = "/dkassist"

SlashCmdList["DKASSIST"] = function(msg)
    local cmd = (msg or ""):lower():trim()

    if cmd == "scan" then
        addon:ScanAllButtons()
        print("|cffcc0000DK Assist:|r Rescanned action bars")
    elseif cmd == "cdmscan" then
        if DKAssistDB and (DKAssistDB.trackCDMFestering or DKAssistDB.trackCDMPutrefy) then
            addon:CreateCDMOverlays()
            print("|cffcc0000DK Assist:|r Rescanned Cooldown Manager frames")
        else
            print("|cffcc0000DK Assist:|r Cooldown Manager tracking is disabled")
        end
    elseif cmd == "debug" then
        addon:ToggleDebug()
    elseif cmd == "minimap" then
        if addon.CreateMinimapButton then
            DKAssistDB.minimapHidden = false
            addon:CreateMinimapButton()
            if addon.minimapButton then
                addon.minimapButton:Show()
                print("|cffcc0000DK Assist:|r Minimap button shown")
            end
        end
    else
        if addon.settingsCategory then
            Settings.OpenToCategory(addon.settingsCategory:GetID())
        else
            print("|cffcc0000DK Assist:|r /dka scan - Rescan action bars")
            print("|cffcc0000DK Assist:|r /dka cdmscan - Rescan Cooldown Manager")
            print("|cffcc0000DK Assist:|r /dka debug - Toggle debug logging")
            print("|cffcc0000DK Assist:|r /dka minimap - Show Minimap button")
        end
    end
end
