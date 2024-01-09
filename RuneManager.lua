-- Ace requirements for addon setupRMScrollFrame
RM = LibStub("AceAddon-3.0"):NewAddon("RuneManager", "AceConsole-3.0")
RM.Event = LibStub("AceEvent-3.0")
RM.GUI = LibStub("AceGUI-3.0")
RM.CBH = LibStub("CallbackHandler-1.0")

RM.Init = false

RM.RMContainer = {}
RM.IconSelectionFrame = {}
RM.SaveButton = {}
RM.DeleteButton = {}
RM.ScrollContainer = {}
RM.ScrollFrame = {}
RM.IconSelectionScrollFrame = {}
RM.RuneButtonContainer = {}
RM.MacroIcons = {}
RM.SelectedIcon = {}
RM.SavedSets = {}
RM.CurrentSetEntry = nil
RM.RuneCategories = {}

function RM:OnInitialize()
    -- TODO: Restore saved settings, etc
    --RM:Print("Rune Manager loaded.") --TODO: Turn off when done debugging
    GetMacroIcons(RM.MacroIcons)
    GetRuneCategories()
    RM.DB = LibStub("AceDB-3.0"):New("RMDB")
    RM.DB.callbacks = RM.DB.callbacks or LibStub("CallbackHandler-1.0"):New(RM.DB)
    RM.DB.RegisterCallback(RM.DB, "OnDatabaseShutdown", SaveSetsToDB)
end

-- Called when the addon is enabled
function RM:OnEnable()
    RM.Event:RegisterEvent("ENGRAVING_MODE_CHANGED", OnEngravingModeChanged)
    if #RM.DB.char.savedSets > 0 then
        RM.SavedSets = RM.DB.char.savedSets
    end
end

-- Called when the addon is disabled
function RM:OnDisable()
    RM.Event:UnregisterEvent("ENGRAVING_MODE_CHANGED")
end

-- Check if engraving frame is loaded and then init 
function OnEngravingModeChanged()
    if C_AddOns.IsAddOnLoaded("Blizzard_EngravingUI") then
        if RM.Init == false then
            InitRMFrame()
            ShowRMFrame()
            InitIconSelectionFrame()
            RM.Init = true
        else
            ShowRMFrame()
        end
    end
end

-- Init functions
function InitRMFrame()
    RM.RMContainer = RM.GUI:Create("Frame")
    local charFrame = CharacterFrame
    local charFrameClosebutton = CharacterFrameCloseButton
    local charFrameTab5 = CharacterFrameTab5
    local engravingFrame = EngravingFrame
    RM.RMContainer.frame:SetParent(engravingFrame)

    RM.RMContainer:SetPoint("TOPLEFT", charFrameClosebutton, "TOPRIGHT", engravingFrame:GetWidth() + 10, 0)
    RM.RMContainer:SetPoint("BOTTOMLEFT", charFrameTab5, "CENTER", engravingFrame:GetWidth() + 10, 5)
    RM.RMContainer:SetWidth(charFrame:GetWidth())

    RM.RMContainer:SetTitle("Rune Manager")
    RM.RMContainer:SetCallback("OnClose", function(widget) RM.IconSelectionFrame:Hide(); RM.RMContainer:Hide() end)
    RM.RMContainer:SetLayout("Flow")

    RM.SaveButton = RM.GUI:Create("Button")
    RM.SaveButton:SetText("Save")
    RM.SaveButton:SetWidth(100)
    RM.RMContainer:AddChild(RM.SaveButton)

    RM.DeleteButton = RM.GUI:Create("Button")
    RM.DeleteButton:SetDisabled(true)
    RM.DeleteButton:SetText("Delete")
    RM.DeleteButton:SetWidth(100)
    RM.RMContainer:AddChild(RM.DeleteButton)

    RM.ScrollContainer = RM.GUI:Create("InlineGroup")
    RM.ScrollContainer:SetTitle("Rune Sets")
    RM.ScrollContainer:SetFullWidth(true)
    RM.ScrollContainer:SetHeight(RM.RMContainer.frame:GetHeight() / 2) -- probably?
    RM.ScrollContainer:SetLayout("Fill") -- important!
    RM.RMContainer:AddChild(RM.ScrollContainer)

    RM.ScrollFrame = RM.GUI:Create("ScrollFrame")
    RM.ScrollFrame:SetLayout("Flow") -- probably?
    RM.ScrollContainer:AddChild(RM.ScrollFrame)

    RM.RuneButtonContainer = RM.GUI:Create("InlineGroup")
    RM.RuneButtonContainer:SetTitle("Rune Set Loadout")
    RM.RuneButtonContainer:SetFullWidth(true)
    RM.RuneButtonContainer:SetHeight(RM.RMContainer.frame:GetHeight() / 2)
    RM.RuneButtonContainer:SetLayout("Flow")
    RM.RMContainer:AddChild(RM.RuneButtonContainer)

    RM.SaveButton:SetCallback("OnClick", function() OnSaveClicked() end)

    if #RM.SavedSets > 0 then
        UpdateRMScrollFrame()
    end
end

function InitIconSelectionFrame()
    RM.IconSelectionFrame = RM.GUI:Create("Frame")
    RM.IconSelectionFrame:Hide()
    
    RM.IconSelectionFrame:SetPoint("TOPLEFT", RM.RMContainer.frame, "TOPRIGHT", 0, 0)
    RM.IconSelectionFrame:SetPoint("BOTTOMLEFT", RM.RMContainer.frame, "BOTTOMRIGHT", 0, 0)
    RM.IconSelectionFrame:SetWidth(RM.RMContainer.frame:GetWidth())

    RM.IconSelectionFrame:SetTitle("Rune Set")
    RM.IconSelectionFrame:SetLayout("Flow")

    local editbox = RM.GUI:Create("EditBox")
    editbox:SetLabel("Rune name..")
    editbox:SetWidth(100)
    RM.IconSelectionFrame:AddChild(editbox)

    local scrollContainer = RM.GUI:Create("InlineGroup") 
    scrollContainer:SetFullWidth(true)
    scrollContainer:SetHeight(RM.IconSelectionFrame.frame:GetHeight() / 1.6) 
    scrollContainer:SetLayout("Fill") -- important!
    RM.IconSelectionFrame:AddChild(scrollContainer)

    RM.IconSelectionScrollFrame = RM.GUI:Create("ScrollFrame")
    RM.IconSelectionScrollFrame:SetLayout("Flow") -- probably?
    scrollContainer:AddChild(RM.IconSelectionScrollFrame)

    local confirmButton = RM.GUI:Create("Button")
    confirmButton:SetText("Confirm")
    confirmButton:SetWidth(100)
    confirmButton:SetDisabled(true)
    RM.IconSelectionFrame:AddChild(confirmButton)

    for _, icon in ipairs(RM.MacroIcons) do
        local containerIcon = RM.GUI:Create("Icon")
        containerIcon:SetWidth(RM.IconSelectionScrollFrame.frame:GetWidth() / 10)
        containerIcon:SetHeight(RM.IconSelectionScrollFrame.frame:GetWidth() / 10)
        containerIcon:SetImage(icon)
        containerIcon:SetImageSize(RM.IconSelectionScrollFrame.frame:GetWidth() / 10 - 3, RM.IconSelectionScrollFrame.frame:GetWidth() / 10 - 3)

        local overlay = containerIcon.frame:CreateTexture(nil, "OVERLAY")
        overlay:SetAllPoints(containerIcon["image"])
        overlay:SetTexture(130723) -- Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight
        overlay:SetTexCoord(0.23, 0.77, 0.23, 0.77)
        overlay:SetBlendMode("ADD")
        
        containerIcon["RMoverlay"] = overlay
        overlay:Hide()

        containerIcon:SetCallback("OnClick", function(widget) 
            RM.SelectedIcon = icon
            HideAllOverlaysInIconSelectionFrame()
            ShowOverlay(widget)
        end)
        RM.IconSelectionScrollFrame:AddChild(containerIcon)
    end

    editbox:SetCallback("OnEnterPressed", function(widget, event, text) editbox:SetUserData("text", text) confirmButton:SetDisabled(false) end)
    confirmButton:SetCallback("OnClick", function () OnConfirmButtonClicked(editbox:GetUserData("text")); confirmButton:SetDisabled(true) end)
    RM.IconSelectionFrame:SetCallback("OnClose", function() RM.IconSelectionFrame:Hide(); editbox:SetText("") end)

    RM.IconSelectInit = true
end

-- Show/Hide functions

function ShowRMFrame()
    RM.RMContainer:Show()
end

function ShowIconFrame()
    RM.IconSelectionFrame:Show()
end

function ShowOverlay(widget)
    if widget["RMoverlay"] then
        widget["RMoverlay"]:Show()
    end
end

function HideOverlay(widget)
    if widget["RMoverlay"] then
        widget["RMoverlay"]:Hide()
    end
end

function HideAllOverlaysInScrollFrame()
    for i=1, #RM.ScrollFrame.children do
        HideOverlay(RM.ScrollFrame.children[i])
    end
end

function HideAllOverlaysInIconSelectionFrame()
    for i=1, #RM.IconSelectionScrollFrame.children do
        HideOverlay(RM.IconSelectionScrollFrame.children[i])
    end
end

-- Rune loadout functions
function GetRuneCategories()
    RM.RuneCategories = C_Engraving.GetRuneCategories(false, false)
end

function GetLoadout()
    local loadout = {}
    for i=1, #RM.RuneCategories do
        tinsert(loadout, C_Engraving.GetRuneForEquipmentSlot(RM.RuneCategories[i]))
    end

    return loadout
end

function GetLoadoutFromSavedSet(savedSet)
    local loadout = {}

    for i=1, #savedSet do
        loadout[i] = savedSet[i]
    end
    return loadout
end

-- Create overlay on widget
function CreateOverlay(widget)
    local overlay = widget.frame:CreateTexture(nil, "OVERLAY")
    overlay:SetAllPoints(widget["image"])
    overlay:SetTexture(130723) -- Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight
    overlay:SetTexCoord(0.23, 0.77, 0.23, 0.77)
    overlay:SetBlendMode("ADD")
    
    widget["RMoverlay"] = overlay
    overlay:Hide()
end

-- Callback functions
function OnSaveClicked()
    HideAllOverlaysInScrollFrame()

    RM:Print("Save button clicked")
    local setEntry = RM.GUI:Create("Icon")
    setEntry:SetWidth(RM.ScrollFrame.frame:GetWidth() / 5)
    setEntry:SetHeight(RM.ScrollFrame.frame:GetWidth() / 5)
    setEntry:SetImage("Interface\\ICONS\\INV_Misc_QuestionMark")
    setEntry:SetImageSize(40, 40)
    setEntry:SetLabel("Rune Set")

    CreateOverlay(setEntry)
    
    RM.DeleteButton:SetDisabled(true)
    RM.CurrentSetEntry = setEntry

    ShowIconFrame()
       
    setEntry:SetCallback("OnClick", function(widget) OnSetEntryClicked(widget) end)
end


function OnConfirmButtonClicked(text) 
    HideAllOverlaysInScrollFrame()
    HideAllOverlaysInIconSelectionFrame()

    RM.CurrentSetEntry:SetLabel(text)
    RM.CurrentSetEntry["RMlabel"] = text
    if RM.SelectedIcon then
        RM.CurrentSetEntry:SetImage(RM.SelectedIcon)
        RM.CurrentSetEntry["RMimage"] = RM.SelectedIcon
    end
    RM.CurrentSetEntry["RMloadout"] = GetLoadout()
    RM.ScrollFrame:AddChild(RM.CurrentSetEntry)

    local savedSet = {}
    savedSet["RMlabel"] = RM.CurrentSetEntry["RMlabel"]
    savedSet["RMimage"] = RM.CurrentSetEntry["RMimage"]
    savedSet["RMloadout"] = RM.CurrentSetEntry["RMloadout"]

    tinsert(RM.SavedSets, savedSet)

    RM.IconSelectionFrame:Hide()
end

function OnSetEntryClicked(setEntry)
    --RM:Print("Chest: " .. setEntry["RMloadout"]["CHESTSLOT"].name .. " ---- Pants: " .. setEntry["RMloadout"]["LEGSSLOT"].name .. " ---- Gloves: " .. setEntry["RMloadout"]["HANDSSLOT"].name)
    -- TODO: Make tooltips when hovering over runeApplyButtons that show the skill 
    -- TODO: Make rune set highlighted upon click
    RM.RuneButtonContainer:ReleaseChildren()
    HideAllOverlaysInScrollFrame()

    ShowOverlay(setEntry)

    for i=1, #setEntry["RMloadout"] do
        local runeApplyButton = RM.GUI:Create("Icon")
        runeApplyButton:SetWidth(28)
        runeApplyButton:SetHeight(28)
        runeApplyButton:SetImage(setEntry["RMloadout"][i].iconTexture)
        runeApplyButton:SetImageSize(25, 25)
        runeApplyButton:SetCallback("OnClick", function() OnRuneApplyButtonClicked(setEntry["RMloadout"][i]) end)
        RM.RuneButtonContainer:AddChild(runeApplyButton)
    end

    if not RM.IconSelectionFrame:IsShown() then
        RM.DeleteButton:SetDisabled(false)
    end
    RM.DeleteButton:SetCallback("OnClick", function() OnDeleteSetClicked(setEntry) end)
end

function OnRuneApplyButtonClicked(rune)
    HideAllOverlaysInScrollFrame()


    if not InCombatLockdown()
    and not UnitIsDeadOrGhost("player")
    and not UnitCastingInfo("player")
    and not IsPlayerMoving()
    and not C_Engraving.IsRuneEquipped(rune.skillLineAbilityID)
    then
        C_Engraving.CastRune(rune.skillLineAbilityID)
        PickupInventoryItem(rune.equipmentSlot)
        ClearCursor()
        -- accepts the replace enchant popup
        StaticPopup1Button1:Click()
        ClearCursor()
    elseif C_Engraving.IsRuneEquipped(rune.skillLineAbilityID) then
        UIErrorsFrame:AddExternalErrorMessage("That rune is already equipped!")
    elseif InCombatLockdown() then
        UIErrorsFrame:AddExternalErrorMessage("Can't do that in combat!")
    elseif UnitIsDeadOrGhost("player") then
        UIErrorsFrame:AddExternalErrorMessage("Can't do that while dead!")
    elseif UnitCastingInfo("player") then
        UIErrorsFrame:AddExternalErrorMessage("You're already casting!")
    elseif IsPlayerMoving() then
        UIErrorsFrame:AddExternalErrorMessage("Can't do that while moving!")
    end
end

function OnDeleteSetClicked(setEntry)
    HideAllOverlaysInScrollFrame()

    RM.DeleteButton:SetDisabled(true)
    RM.RuneButtonContainer:ReleaseChildren()

    for i=1, #RM.SavedSets do
        if RM.SavedSets[i]["RMloadout"] == setEntry["RMloadout"] then
            table.remove(RM.SavedSets, i)
            break
        end
    end
    UpdateRMScrollFrame()
end

-- Refresh the scroll frame after a delete or at addon initialization
function UpdateRMScrollFrame()
    RM.ScrollFrame:ReleaseChildren()
    if #RM.SavedSets > 0 then
        for i=1, #RM.SavedSets do
            local setEntry = RM.GUI:Create("Icon")
            setEntry:SetWidth(RM.ScrollFrame.frame:GetWidth() / 5)
            setEntry:SetHeight(RM.ScrollFrame.frame:GetWidth() / 5)
            setEntry:SetImage(RM.SavedSets[i]["RMimage"])
            setEntry["RMimage"] = RM.SavedSets[i]["RMimage"]
            setEntry:SetImageSize(40, 40)
            setEntry:SetLabel(RM.SavedSets[i]["RMlabel"])
            setEntry["RMlabel"] = RM.SavedSets[i]["RMlabel"]
            setEntry["RMloadout"] = RM.SavedSets[i]["RMloadout"]

            CreateOverlay(setEntry)

            setEntry:SetCallback("OnClick", function(widget) OnSetEntryClicked(widget) end)
            RM.ScrollFrame:AddChild(setEntry)
        end
    end
    RM.CurrentSetEntry = nil
end

-- Persist data
function SaveSetsToDB()
    RM.DB.char.savedSets = RM.SavedSets
end