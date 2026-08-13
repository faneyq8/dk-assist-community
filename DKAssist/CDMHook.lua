local addonName, addon = ...

local PUTREFY_SPELL_ID = 1247378
local hooked = false

local function GetCDMSpellID(item)
    if not (item and item.GetCooldownID and C_CooldownViewer and C_CooldownViewer.GetCooldownViewerCooldownInfo) then
        return nil
    end
    local cooldownID = item:GetCooldownID()
    if not cooldownID then return nil end
    local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
    return info and info.spellID
end

local function RegisterItem(item)
    if not DKAssistDB or not DKAssistDB.trackCDMPutrefy then return end
    local ok, isPutrefy = pcall(function()
        return GetCDMSpellID(item) == PUTREFY_SPELL_ID
    end)
    if ok and isPutrefy then
        addon:RegisterCDMPutrefyFrame(item)
    end
end

local function InstallHook()
    if hooked or not CooldownViewerItemMixin then return end
    hooked = true
    hooksecurefunc(CooldownViewerItemMixin, "RefreshData", RegisterItem)
end

-- The CDM may already have built its item pool before our hook is installed.
-- Register those current items directly, then the RefreshData hook handles
-- every later layout, talent, and cooldown update.
local function RegisterExistingItems()
    local viewers = {
        EssentialCooldownViewer,
        UtilityCooldownViewer,
        BuffIconCooldownViewer,
        BuffBarCooldownViewer,
    }
    for _, viewer in ipairs(viewers) do
        if viewer and viewer.GetItemFrames then
            for _, item in ipairs(viewer:GetItemFrames()) do
                RegisterItem(item)
            end
        end
    end
end

local loader = CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
loader:RegisterEvent("PLAYER_LOGIN")
loader:SetScript("OnEvent", function(_, event, loadedAddon)
    if event == "ADDON_LOADED" and loadedAddon ~= "Blizzard_CooldownViewer" then return end
    C_Timer.After(0, function()
        InstallHook()
        RegisterExistingItems()
    end)
    C_Timer.After(2, RegisterExistingItems)
end)
