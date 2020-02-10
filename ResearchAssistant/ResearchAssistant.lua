if ResearchAssistant == nil then ResearchAssistant = {} end
local RA = ResearchAssistant

--Addon variables
RA.name		= "ResearchAssistant"
RA.version 	= "0.9.4.8"
RA.author   = "ingeniousclown, katkat42, Randactyl, Baertram"
RA.website	= "https://www.esoui.com/downloads/info111-ResearchAssistant.html"

local DECONSTRUCTION	= ZO_SmithingTopLevelDeconstructionPanelInventoryBackpack

local ORNATE_TEXTURE = [[/esoui/art/tradinghouse/tradinghouse_sell_tabicon_disabled.dds]]
local ornateTextureSizeMax = 28
local INTRICATE_TEXTURE = [[/esoui/art/progression/progression_indexicon_guilds_up.dds]]
local intricateTextureSizeMax = 30

local RASettings = nil
local RAScanner = nil

local RAlang = 'en'

--LibResearch reasons
local libResearch_Reason_ALREADY_KNOWN 	= LIBRESEARCH_REASON_ALREADY_KNOWN 	or "AlreadyKnown"
local libResearch_Reason_WRONG_ITEMTYPE = LIBRESEARCH_REASON_WRONG_ITEMTYPE or "WrongItemType"
local libResearch_Reason_ORNATE 		= LIBRESEARCH_REASON_ORNATE 		or "Ornate"
local libResearch_Reason_INTRICATE 		= LIBRESEARCH_REASON_INTRICATE 		or "Intricate"
local libResearch_Reason_TRAITLESS  	= LIBRESEARCH_REASON_TRAITLESS 		or "Traitless"

local LIBRESEARCH_REASON_WRONG_ITEMTYPElower= "baditemtype"
local LIBRESEARCH_REASON_ORNATElower 		= libResearch_Reason_ORNATE:lower()
local LIBRESEARCH_REASON_INTRICATElower 	= libResearch_Reason_INTRICATE:lower()
local LIBRESEARCH_REASON_TRAITLESSlower 	= libResearch_Reason_TRAITLESS:lower()
--Tracking status
local TRACKING_STATE_KNOWN					= "known"
local TRACKING_STATE_RESEARCHABLE			= "researchable"
local TRACKING_STATE_DUPLICATE				= "duplicate"
local TRACKING_STATE_TRAITLESS				= LIBRESEARCH_REASON_TRAITLESSlower
local TRACKING_STATE_UNTRACKED				= "untracked"
local TRACKING_STATE_CHARACTER_NOT_SCANNED_YET = "CharacterNotScannedYet"
RA.trackingStates = {
	[TRACKING_STATE_KNOWN] 			= TRACKING_STATE_KNOWN,
	[TRACKING_STATE_RESEARCHABLE] 	= TRACKING_STATE_RESEARCHABLE,
	[TRACKING_STATE_DUPLICATE] 		= TRACKING_STATE_DUPLICATE,
	[TRACKING_STATE_TRAITLESS]		= TRACKING_STATE_TRAITLESS,
	[TRACKING_STATE_UNTRACKED] 		= TRACKING_STATE_UNTRACKED,
	[TRACKING_STATE_CHARACTER_NOT_SCANNED_YET] = TRACKING_STATE_CHARACTER_NOT_SCANNED_YET,
}

local function AddTooltips(control, text)
	control:SetHandler("OnMouseEnter", function(self)
		ZO_Tooltips_ShowTextTooltip(self, TOP, text)
	end)
	control:SetHandler("OnMouseExit", function(self)
		ZO_Tooltips_HideTextTooltip()
	end)
end

local function RemoveTooltips(control)
	control:SetHandler("OnMouseEnter", nil)
	control:SetHandler("OnMouseExit", nil)
end

local function HandleTooltips(control, text)
	if RASettings:ShowTooltips() and text ~= "" then
		control:SetMouseEnabled(true)
		AddTooltips(control, text)
	else
		control:SetMouseEnabled(false)
		RemoveTooltips(control)
	end
end

local function SetToOrnate(indicatorControl)
	local textureSize = RASettings:GetTextureSize() + 12

	if textureSize > ornateTextureSizeMax then textureSize = ornateTextureSizeMax end

	indicatorControl:SetTexture(ORNATE_TEXTURE)
	indicatorControl:SetColor(unpack(RASettings:GetOrnateColor()))
	indicatorControl:SetDimensions(textureSize, textureSize)
	indicatorControl:SetHidden(false)

	HandleTooltips(indicatorControl, RA_Strings[RAlang].TOOLTIPS.ornate)
end

local function SetToIntricate(indicatorControl)
	local textureSize = RASettings:GetTextureSize() + 10

	if textureSize > intricateTextureSizeMax then textureSize = intricateTextureSizeMax end

	indicatorControl:SetTexture(INTRICATE_TEXTURE)
	indicatorControl:SetColor(unpack(RASettings:GetIntricateColor()))
	indicatorControl:SetDimensions(textureSize, textureSize)
	indicatorControl:SetHidden(false)

	HandleTooltips(indicatorControl, RA_Strings[RAlang].TOOLTIPS.intricate)
end

local function SetToNormal(indicatorControl)
	local textureSize = RASettings:GetTextureSize()

	indicatorControl:SetTexture(RASettings:GetTexturePath())
	indicatorControl:SetDimensions(textureSize, textureSize)
	indicatorControl:SetHidden(true)
end

local function CreateIndicatorControl(parent)
	local control = WINDOW_MANAGER:CreateControl(parent:GetName() .. "Research", parent, CT_TEXTURE)

	control:ClearAnchors()
	control:SetAnchor(CENTER, parent, CENTER, RASettings:GetTextureOffset())
	control:SetDrawTier(DT_HIGH)

	SetToNormal(control)
	return control
end

local function DisplayIndicator(indicatorControl, indicatorType)
	local textureOffset = 0
	indicatorType = indicatorType or "normal"

	if indicatorType == LIBRESEARCH_REASON_INTRICATElower then
		textureOffset = RASettings:GetTextureOffset() - 6
	elseif indicatorType == LIBRESEARCH_REASON_ORNATElower then
		textureOffset = RASettings:GetTextureOffset() - 6
	else
		textureOffset = RASettings:GetTextureOffset()
	end

	local control = indicatorControl:GetParent()
	indicatorControl:ClearAnchors()

	if control.isGrid or control:GetWidth() - control:GetHeight() < 5 then
		-- we're using Grid View
		indicatorControl:ClearAnchors()
		indicatorControl:SetAnchor(TOPLEFT, control, TOPLEFT, 3)
	else
		indicatorControl:ClearAnchors()
		indicatorControl:SetAnchor(LEFT, control:GetNamedChild("Name"), RIGHT, textureOffset)
	end

	indicatorControl:SetHidden(false)
end

--Returns true if the given item at bag and slot can be researched with the the character set in the
--ResearchAssistant settings for the crafting type. Otherwise it returns false!
function RA.IsItemResearchableWithSettingsCharacter(bagId, slotIndex)
	--Return value, preset with "Not researchable with char" = false
	local isResearchableWithSettingsChar = false
	local itemLink = bagId and GetItemLink(bagId, slotIndex) or GetItemLink(slotIndex)

	--returns int traitKey, bool isResearchable, string reason
	local traitKey, isResearchable, reason = RAScanner:CheckIsItemResearchable(itemLink)

	if not isResearchable then
		-- if the item isn't armor or a weapon, hide and go away
		if reason == libResearch_Reason_WRONG_ITEMTYPE then
			return isResearchableWithSettingsChar
		end

		-- if the item has no trait
		if reason == libResearch_Reason_TRAITLESS then
			return isResearchableWithSettingsChar
		end

		-- if the item is ornate
		if reason == libResearch_Reason_ORNATE then
			return isResearchableWithSettingsChar
		end

		-- if the item is intricate
		if reason == libResearch_Reason_INTRICATE then
			return isResearchableWithSettingsChar
		end
	end

	--now we get into the stuff that requires the craft skill and item type
	local craftingSkill = RAScanner:GetItemCraftingSkill(itemLink)
	local itemType = RAScanner:GetResearchLineIndex(itemLink)

	--if we aren't tracking anybody for that skill, hide and go away
	if RASettings:IsMultiCharSkillOff(craftingSkill, itemType) then
		return isResearchableWithSettingsChar
	end

	--preference value for the "best" item candidate for the trait in question
	local bestTraitPreferenceScore = RASettings:GetPreferenceValueForTrait(traitKey)
	if bestTraitPreferenceScore == nil then
		-- if the item is traitless, show "researched" color. if we've never seen this trait before, show "best" color.
		if reason == libResearch_Reason_TRAITLESS then
			bestTraitPreferenceScore = true
		else
			bestTraitPreferenceScore = 999999999
		end
	end

	--Known already
	if bestTraitPreferenceScore == true then
		return isResearchableWithSettingsChar
	end

	--preference value for the current item
	local thisItemScore = RAScanner:CreateItemPreferenceValue(itemLink, bagId, slotIndex)
	local stackSize = GetSlotStackSize(bagId, slotIndex) or 0

	--d(GetItemName(bagId, slotIndex)..": "..tostring(bestTraitPreferenceScore).." best "..tostring(thisItemScore) .. " trait "..tostring(traitKey))

	--if we don't know it yet
	if bestTraitPreferenceScore ~= true then
		isResearchableWithSettingsChar = true
		if bestTraitPreferenceScore == RASettings.CONST_CHARACTER_NOT_SCANNED_YET then
			--Character to research this crafttype with was not logged in yet
			return false
		else
			if (thisItemScore > bestTraitPreferenceScore or stackSize > 1) then
				--Duplicate
				return isResearchableWithSettingsChar
			else
				--Researchable!
				return isResearchableWithSettingsChar
			end
		end
	end
	--in any other case
	return isResearchableWithSettingsChar
end


--Returns true if the given item at bag and slot can be researched with the the character set in the
--ResearchAssistant settings for the crafting type.
--If the item is a researchable the return value will be true
--If the item is a duplicate the return value will be "duplicate".
--Otherwise it returns false!
function RA.IsItemResearchableOrDuplicateWithSettingsCharacter(bagId, slotIndex)
	--Return value, preset with "Not researchable with char" = false
	local isNoDuplicateResearchableWithSettingsChar = false
	local itemLink = bagId and GetItemLink(bagId, slotIndex) or GetItemLink(slotIndex)

	--returns int traitKey, bool isResearchable, string reason
	local traitKey, isResearchable, reason = RAScanner:CheckIsItemResearchable(itemLink)

	if not isResearchable then
		-- if the item isn't armor or a weapon, hide and go away
		if reason == libResearch_Reason_WRONG_ITEMTYPE then
			return isNoDuplicateResearchableWithSettingsChar
		end

		-- if the item has no trait
		if reason == libResearch_Reason_TRAITLESS  then
			return isNoDuplicateResearchableWithSettingsChar
		end

		-- if the item is ornate
		if reason == libResearch_Reason_ORNATE then
			return isNoDuplicateResearchableWithSettingsChar
		end

		-- if the item is intricate
		if reason == libResearch_Reason_INTRICATE then
			return isNoDuplicateResearchableWithSettingsChar
		end
	end

	--now we get into the stuff that requires the craft skill and item type
	local craftingSkill = RAScanner:GetItemCraftingSkill(itemLink)
	local itemType = RAScanner:GetResearchLineIndex(itemLink)

	--if we aren't tracking anybody for that skill, hide and go away
	if RASettings:IsMultiCharSkillOff(craftingSkill, itemType) then
		return isNoDuplicateResearchableWithSettingsChar
	end

	--preference value for the "best" item candidate for the trait in question
	local bestTraitPreferenceScore = RASettings:GetPreferenceValueForTrait(traitKey)
	if bestTraitPreferenceScore == nil then
		-- if the item is traitless, show "researched" color. if we've never seen this trait before, show "best" color.
		if reason == libResearch_Reason_TRAITLESS then
			bestTraitPreferenceScore = true
		else
			bestTraitPreferenceScore = 999999999
		end
	end

	--Known already
	if bestTraitPreferenceScore == true then
		return isNoDuplicateResearchableWithSettingsChar
	end

	--preference value for the current item
	local thisItemScore = RAScanner:CreateItemPreferenceValue(itemLink, bagId, slotIndex)
	local stackSize = GetSlotStackSize(bagId, slotIndex) or 0

	--d(GetItemName(bagId, slotIndex)..": "..tostring(bestTraitPreferenceScore).." best "..tostring(thisItemScore) .. " trait "..tostring(traitKey))

	--if we don't know it yet
	if bestTraitPreferenceScore ~= true then
		isNoDuplicateResearchableWithSettingsChar = true
		if bestTraitPreferenceScore == RASettings.CONST_CHARACTER_NOT_SCANNED_YET then
			--Character to research this crafttype with was not logged in yet
			return false
		else
			if (thisItemScore > bestTraitPreferenceScore or stackSize > 1) then
				--Duplicate
				return TRACKING_STATE_DUPLICATE
			else
				--Researchable!
				return isNoDuplicateResearchableWithSettingsChar
			end
		end
	end
	--in any other case
	return isNoDuplicateResearchableWithSettingsChar
end

--[[----------------------------------------------------------------------------
	puts an additional point of data into control.dataEntry.data called
	researchAssistant
	this can be called from inventory, bank, guild bank, deconstruction window,
	or trading house which contains one of the following strings:
		"baditemtype" (not weapon or armor)
		"traitless" "ornate" "intricate" "untracked" (untracked)
		"known" "researchable" "duplicate" (tracked)
--]]----------------------------------------------------------------------------
local function AddResearchIndicatorToSlot(control, linkFunction)
	local bagId = control.dataEntry.data.bagId
	local slotIndex = control.dataEntry.data.slotIndex
	local itemLink = bagId and linkFunction(bagId, slotIndex) or linkFunction(slotIndex)

	--get indicator control, or create one if it doesnt exist
	local indicatorControl = control:GetNamedChild("Research")
	if not indicatorControl then
		indicatorControl = CreateIndicatorControl(control)
	end

	--returns int traitKey, bool isResearchable, string reason
	local traitKey, isResearchable, reason = RAScanner:CheckIsItemResearchable(itemLink)

	--now we get into the stuff that requires the craft skill and item type
	local craftingSkill = RAScanner:GetItemCraftingSkill(itemLink)
	local itemType = RAScanner:GetResearchLineIndex(itemLink)

	if not isResearchable then
		-- if the item isn't armor or a weapon, hide and go away
		if reason == libResearch_Reason_WRONG_ITEMTYPE then
			indicatorControl:SetHidden(true)
			control.dataEntry.data.researchAssistant = LIBRESEARCH_REASON_WRONG_ITEMTYPElower
			return
		end

		-- if the item has no trait and we don't want to display icon for traitless items, hide and go away
		if reason == libResearch_Reason_TRAITLESS and RASettings:ShowTraitless() == false then
			indicatorControl:SetHidden(true)
			control.dataEntry.data.researchAssistant = LIBRESEARCH_REASON_TRAITLESSlower
			return
		end

		-- if the item is ornate, make icon ornate if we show ornate and hide/go away if we don't show it
		if reason == libResearch_Reason_ORNATE then
			control.dataEntry.data.researchAssistant = LIBRESEARCH_REASON_ORNATElower
			if (craftingSkill == -1 or (RASettings:IsMultiCharSkillOff(craftingSkill, itemType))) and not RASettings:ShowUntrackedOrnate() then
				indicatorControl:SetHidden(true)
			else
				SetToOrnate(indicatorControl)
				DisplayIndicator(indicatorControl, LIBRESEARCH_REASON_ORNATElower)
			end
			return
		end

		-- if the item is intricate, make icon intricate if we show that and hide/go away if we don't
		if reason == libResearch_Reason_INTRICATE then
			control.dataEntry.data.researchAssistant = LIBRESEARCH_REASON_INTRICATElower
			if RASettings:IsMultiCharSkillOff(craftingSkill, itemType) and not RASettings:ShowUntrackedIntricate() then
				indicatorControl:SetHidden(true)
			else
				SetToIntricate(indicatorControl)
				DisplayIndicator(indicatorControl, LIBRESEARCH_REASON_INTRICATElower)
			end
			return
		end
	end

	--if we aren't tracking anybody for that skill, hide and go away
	if RASettings:IsMultiCharSkillOff(craftingSkill, itemType) then
		control.dataEntry.data.researchAssistant = TRACKING_STATE_UNTRACKED
		indicatorControl:SetHidden(true)
		return
	end

	--preference value for the "best" item candidate for the trait in question
	local bestTraitPreferenceScore = RASettings:GetPreferenceValueForTrait(traitKey)
	if bestTraitPreferenceScore == nil then
		-- if the item is traitless, show "researched" color. if we've never seen this trait before, show "best" color.
		if reason == LIBRESEARCH_REASON_TRAITLESS then
			bestTraitPreferenceScore = true
		else
			bestTraitPreferenceScore = 999999999
		end
	end

	if bestTraitPreferenceScore == true and not RASettings:ShowResearched() then
		control.dataEntry.data.researchAssistant = TRACKING_STATE_KNOWN
		indicatorControl:SetHidden(true)
		return
	end

	--here's the "display it" section
	SetToNormal(indicatorControl)
	DisplayIndicator(indicatorControl)

	--preference value for the current item
	local thisItemScore = RAScanner:CreateItemPreferenceValue(itemLink, bagId, slotIndex)
	local stackSize = control.dataEntry.data.stackCount or 0

--d("[RA]AddResearchIndicatorToSlot: " .. itemLink .. " - best: "..tostring(bestTraitPreferenceScore).. ", this: "..tostring(thisItemScore) .. ", trait: "..tostring(traitKey) .. ", stackSize: " ..tostring(stackSize))

	local whoKnows = RASettings:GetCharsWhoKnowTrait(traitKey)
	--pretty colors time!
	--if we don't know it, color the icon something fun
	if bestTraitPreferenceScore ~= true then
		if bestTraitPreferenceScore == RASettings.CONST_CHARACTER_NOT_SCANNED_YET then
			indicatorControl:SetColor(unpack(RASettings:GetNotScannedColor()))
			local researchCharOfCraftingTypeNameDecorated = RASettings:GetCraftingCharacterIdOrName(craftingSkill, itemType, true)
			HandleTooltips(indicatorControl, string.format(RA_Strings[RAlang].TOOLTIPS.notScannedWithNeededCharYet, tostring(researchCharOfCraftingTypeNameDecorated)))
			control.dataEntry.data.researchAssistant = TRACKING_STATE_CHARACTER_NOT_SCANNED_YET
			return
		else
			if (thisItemScore > bestTraitPreferenceScore or stackSize > 1) then
				indicatorControl:SetColor(unpack(RASettings:GetDuplicateUnresearchedColor()))
				if whoKnows ~= "" then
					HandleTooltips(indicatorControl, string.format(RA_Strings[RAlang].TOOLTIPS.duplicate, RA_Strings[RAlang].TOOLTIPS.knownBy) .. whoKnows)
				else
					HandleTooltips(indicatorControl, RA_Strings[RAlang].TOOLTIPS.duplicate)
				end
				control.dataEntry.data.researchAssistant = TRACKING_STATE_DUPLICATE
			else
				indicatorControl:SetColor(unpack(RASettings:GetCanResearchColor()))
				if whoKnows ~= "" then
					HandleTooltips(indicatorControl, string.format(RA_Strings[RAlang].TOOLTIPS.canResearch, RA_Strings[RAlang].TOOLTIPS.knownBy) .. whoKnows)
				else
					HandleTooltips(indicatorControl, RA_Strings[RAlang].TOOLTIPS.canResearch)
				end
				control.dataEntry.data.researchAssistant = TRACKING_STATE_RESEARCHABLE
			end
			return
		end
	end
	--in any other case, color it known
	indicatorControl:SetColor(unpack(RASettings:GetAlreadyResearchedColor()))
	HandleTooltips(indicatorControl, string.format(RA_Strings[RAlang].TOOLTIPS.alreadyResearched, RA_Strings[RAlang].TOOLTIPS.knownBy) .. whoKnows)
	if reason == libResearch_Reason_TRAITLESS then
		control.dataEntry.data.researchAssistant = TRACKING_STATE_TRAITLESS
	else
		control.dataEntry.data.researchAssistant = TRACKING_STATE_KNOWN
	end
end

--[[----------------------------------------------------------------------------
	a simple event buffer to make sure that the scan doesn't happen more than
	once in a single instance, as EVENT_INVENTORY_SINGLE_SLOT_UPDATE is very
	spammy, especially with junk and bank management add-ons
--]]----------------------------------------------------------------------------
local canUpdate = true
local wasInCombatAsWantedToScan = false

local function scanBagsNow()
	if canUpdate == false then
		--d("[RA]scanBagsNow")
		RAScanner:RescanBags()
		canUpdate = true
		wasInCombatAsWantedToScan = false
	end
end

--EVENT_INVENTORY_SINGLE_SLOT_UPDATE (number eventCode, Bag bagId, number slotId, boolean isNewItem, ItemUISoundCategory itemSoundCategory, number inventoryUpdateReason, number stackCountChange)
function ResearchAssistant_InvUpdate(eventCode, bagId, slotId, isNewItem, itemSoundCategory, inventoryUpdateReason, stackCountChange)
	--d("[RA]ResearchAssistant_InvUpdate")
	--Check if we are in combat and do not update then
	if wasInCombatAsWantedToScan == true or IsUnitInCombat("player") == true then
		canUpdate = false
		wasInCombatAsWantedToScan = true
		--d("<inCombat, aborted!")
		return
	end
	--InventoryScan can be done?
	if canUpdate == true then
		canUpdate = false
		zo_callLater(function()
			scanBagsNow()
		end, 25)
	end
end

local function RA_HookTrading()
	EVENT_MANAGER:UnregisterForEvent("RA_TRADINGHOUSE", EVENT_TRADING_HOUSE_RESPONSE_RECEIVED)
	local hookedFunction = TRADING_HOUSE.searchResultsList.dataTypes[1].setupCallback
	if hookedFunction then
		SecurePostHook(TRADING_HOUSE.searchResultsList.dataTypes[1], "setupCallback", function(row, data)
			AddResearchIndicatorToSlot(row, GetTradingHouseSearchResultItemLink)
		end)
	end
end

local function ResearchAssistant_Loaded(eventCode, addOnName)
	if addOnName ~= RA.name then return end

	local libResearch = LibResearch
	if libResearch == nil then d("[ResearchAssistant]Needed library \"LibResearch\" was not loaded. This addon won't work without this library!") return end
	RA.libResearch = libResearch
	local LAM = LibAddonMenu2
	if not LAM and LibStub then LibStub("LibAddonMenu-2.0", true) end
	if LAM == nil then d("[ResearchAssistant]Needed library \"LibAddonMenu-2.0\" was not loaded. This addon won't work without this library!") return end
	RA.lam = LAM

	wasInCombatAsWantedToScan = false

	RASettings = ResearchAssistantSettings:New()
	RAScanner = ResearchAssistantScanner:New(RASettings)
	RAScanner:SetDebug(RASettings:IsDebug())
	RA.scanner = RAScanner
	RA.settings = RASettings

	--Get the language of the client
	RAlang = RASettings:GetLanguage()

	--inventories hook
	for _, v in pairs(PLAYER_INVENTORY.inventories) do
		local listView = v.listView
		if listView and listView.dataTypes and listView.dataTypes[1] then
			SecurePostHook(listView.dataTypes[1], "setupCallback", function(rowControl, slot)
				AddResearchIndicatorToSlot(rowControl, GetItemLink)
			end)
		end
	end

	--deconstruction hook
	SecurePostHook(DECONSTRUCTION.dataTypes[1], "setupCallback", function(rowControl, slot)
		AddResearchIndicatorToSlot(rowControl, GetItemLink)
	end)

	--EVENT_PLAYER_COMBAT_STATE callback function
	local function RA_CombatState(eventCode, inCombat)
		--d("[RA]Combat event, inCombat: " ..tostring(inCombat))
		--Scan of bags was tried within combat but suppressed? Try after combat again
		if inCombat == false then
			if wasInCombatAsWantedToScan == true then
				--d(">scanning bags after combat now!")
				scanBagsNow()
			end
		end
	end

	local function RA_EnableBankScan(bankBag)
		if IsHouseBankBag(bankBag) == true then
			--Scan the house bank on first open automatically!
			RAScanner:SetHouseBankScanEnabled(true, true)
		else
			RAScanner:SetBankScanEnabled(true)
		end
	end

	local function RA_DisableBankScan()
		RAScanner:SetBankScanEnabled(false)
		RAScanner:SetHouseBankScanEnabled(false)
	end

	--trading house hook
	EVENT_MANAGER:RegisterForEvent("RA_DISABLE_BANK_SCAN", EVENT_END_CRAFTING_STATION_INTERACT, RA_DisableBankScan)
	EVENT_MANAGER:RegisterForEvent("RA_DISABLE_BANK_SCAN", EVENT_CLOSE_BANK, RA_DisableBankScan)
	EVENT_MANAGER:RegisterForEvent("RA_ENABLE_BANK_SCAN", EVENT_CRAFTING_STATION_INTERACT, RA_EnableBankScan)
	EVENT_MANAGER:RegisterForEvent("RA_ENABLE_BANK_SCAN", EVENT_OPEN_BANK, function(eventId, bankBag) RA_EnableBankScan(bankBag) end)

	EVENT_MANAGER:RegisterForEvent("RA_TRADINGHOUSE", EVENT_TRADING_HOUSE_RESPONSE_RECEIVED, RA_HookTrading)
	EVENT_MANAGER:RegisterForEvent("RA_COMBAT_STATE", EVENT_PLAYER_COMBAT_STATE, RA_CombatState)
	--Items in bag changed: Rescan it
	EVENT_MANAGER:RegisterForEvent("RA_INV_SLOT_UPDATE", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, ResearchAssistant_InvUpdate)
	--Add event filter to only scan upon updates of real items and not on durability changes etc.
	EVENT_MANAGER:AddFilterForEvent("RA_INV_SLOT_UPDATE", EVENT_INVENTORY_SINGLE_SLOT_UPDATE, REGISTER_FILTER_INVENTORY_UPDATE_REASON, INVENTORY_UPDATE_REASON_DEFAULT)
end

EVENT_MANAGER:RegisterForEvent(RA.name .."Loaded", EVENT_ADD_ON_LOADED, ResearchAssistant_Loaded)