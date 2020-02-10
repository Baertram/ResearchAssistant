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
local traitTypes = {
	[ITEM_TRAIT_TYPE_NONE] = GetString(SI_ITEMTRAITTYPE0), --None
	[ITEM_TRAIT_TYPE_WEAPON_POWERED] = GetString(SI_ITEMTRAITTYPE1), --Powered
	[ITEM_TRAIT_TYPE_WEAPON_CHARGED] = GetString(SI_ITEMTRAITTYPE2), --Charged
	[ITEM_TRAIT_TYPE_WEAPON_PRECISE] = GetString(SI_ITEMTRAITTYPE3), --Precise
	[ITEM_TRAIT_TYPE_WEAPON_INFUSED] = GetString(SI_ITEMTRAITTYPE4), --Infused
	[ITEM_TRAIT_TYPE_WEAPON_DEFENDING] = GetString(SI_ITEMTRAITTYPE5), --Defending
	[ITEM_TRAIT_TYPE_WEAPON_TRAINING] = GetString(SI_ITEMTRAITTYPE6), --Training
	[ITEM_TRAIT_TYPE_WEAPON_SHARPENED] = GetString(SI_ITEMTRAITTYPE7), --Sharpened
	[ITEM_TRAIT_TYPE_WEAPON_DECISIVE] = GetString(SI_ITEMTRAITTYPE8), --Decisive
	[ITEM_TRAIT_TYPE_WEAPON_INTRICATE] = GetString(SI_ITEMTRAITTYPE9), --Intricate weapon
	[ITEM_TRAIT_TYPE_WEAPON_ORNATE] = GetString(SI_ITEMTRAITTYPE10), --Ornate weapon

	[ITEM_TRAIT_TYPE_ARMOR_STURDY] = GetString(SI_ITEMTRAITTYPE11), --Sturdy
	[ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE] = GetString(SI_ITEMTRAITTYPE12), --Impenetrable
	[ITEM_TRAIT_TYPE_ARMOR_REINFORCED] = GetString(SI_ITEMTRAITTYPE13), --Reinforced
	[ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED] = GetString(SI_ITEMTRAITTYPE14), --Well-fitted
	[ITEM_TRAIT_TYPE_ARMOR_TRAINING] = GetString(SI_ITEMTRAITTYPE15), --Training
	[ITEM_TRAIT_TYPE_ARMOR_INFUSED] = GetString(SI_ITEMTRAITTYPE16), --Infused
	[ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS] = GetString(SI_ITEMTRAITTYPE17), --Prosperous
	[ITEM_TRAIT_TYPE_ARMOR_DIVINES] = GetString(SI_ITEMTRAITTYPE18), --Divines
	[ITEM_TRAIT_TYPE_ARMOR_ORNATE] = GetString(SI_ITEMTRAITTYPE19), --Ornate armor
	[ITEM_TRAIT_TYPE_ARMOR_INTRICATE] = GetString(SI_ITEMTRAITTYPE20), --Intricate armor

	[ITEM_TRAIT_TYPE_JEWELRY_HEALTHY] = GetString(SI_ITEMTRAITTYPE21), --Healthy
	[ITEM_TRAIT_TYPE_JEWELRY_ARCANE] = GetString(SI_ITEMTRAITTYPE22), --Arcane
	[ITEM_TRAIT_TYPE_JEWELRY_ROBUST] = GetString(SI_ITEMTRAITTYPE23), --Robust
	[ITEM_TRAIT_TYPE_JEWELRY_ORNATE] = GetString(SI_ITEMTRAITTYPE24), --Ornate

	[ITEM_TRAIT_TYPE_ARMOR_NIRNHONED] = GetString(SI_ITEMTRAITTYPE25), --Nirnhoned armor
	[ITEM_TRAIT_TYPE_WEAPON_NIRNHONED] = GetString(SI_ITEMTRAITTYPE26), --Nirnhoned weapon

	[ITEM_TRAIT_TYPE_JEWELRY_INTRICATE] = GetString(SI_ITEMTRAITTYPE27), --Intricate jewelry
	[ITEM_TRAIT_TYPE_JEWELRY_SWIFT] = GetString(SI_ITEMTRAITTYPE28), --Swift
	[ITEM_TRAIT_TYPE_JEWELRY_HARMONY] = GetString(SI_ITEMTRAITTYPE29), --Harmony
	[ITEM_TRAIT_TYPE_JEWELRY_TRIUNE] = GetString(SI_ITEMTRAITTYPE30), --Triune
	[ITEM_TRAIT_TYPE_JEWELRY_BLOODTHIRSTY] = GetString(SI_ITEMTRAITTYPE31), --Bloodthirsty
	[ITEM_TRAIT_TYPE_JEWELRY_PROTECTIVE] = GetString(SI_ITEMTRAITTYPE32), --Protective
	[ITEM_TRAIT_TYPE_JEWELRY_INFUSED] = GetString(SI_ITEMTRAITTYPE33), --Infused
}
RA.traitTypes = traitTypes
local traitTextures = {
	--belebend: esoui/art/icons/crafting_jewelry_base_garnet_r3.dds
	--Verstärkt: esoui/art/icons/crafting_enchantment_base_sardonyx_r2.dds
	--Armor
	[ITEM_TRAIT_TYPE_NONE]					= "",
	[ITEM_TRAIT_TYPE_ARMOR_ORNATE]			= "esoui/art/inventory/inventory_trait_ornate_icon.dds",
	[ITEM_TRAIT_TYPE_ARMOR_INTRICATE]		= "esoui/art/inventory/inventory_trait_intricate_icon.dds",
	[ITEM_TRAIT_TYPE_ARMOR_DIVINES]			= "esoui/art/icons/crafting_accessory_sp_names_001.dds",
	[ITEM_TRAIT_TYPE_ARMOR_IMPENETRABLE]	= "esoui/art/icons/crafting_jewelry_base_diamond_r3.dds",
	[ITEM_TRAIT_TYPE_ARMOR_INFUSED]			= "esoui/art/icons/crafting_enchantment_baxe_bloodstone_r2.dds",
	[ITEM_TRAIT_TYPE_ARMOR_NIRNHONED]		= "EsoUI/art/icons/crafting_potent_nirncrux_dust.dds",
	[ITEM_TRAIT_TYPE_ARMOR_PROSPEROUS]		= "esoui/art/icons/crafting_jewelry_base_garnet_r3.dds",
	[ITEM_TRAIT_TYPE_ARMOR_REINFORCED]		= "esoui/art/icons/crafting_enchantment_base_sardonyx_r2.dds",
	[ITEM_TRAIT_TYPE_ARMOR_STURDY]			= "esoui/art/icons/crafting_runecrafter_plug_component_002.dds",
	[ITEM_TRAIT_TYPE_ARMOR_TRAINING]		= "esoui/art/icons/crafting_jewelry_base_emerald_r2.dds",
	[ITEM_TRAIT_TYPE_ARMOR_WELL_FITTED]		= "esoui/art/icons/crafting_accessory_sp_names_002.dds",
	--Jewelry
	[ITEM_TRAIT_TYPE_JEWELRY_ORNATE]		= "esoui/art/inventory/inventory_trait_ornate_icon.dds",
	[ITEM_TRAIT_TYPE_JEWELRY_INTRICATE]		= "esoui/art/inventory/inventory_trait_intricate_icon.dds",
	[ITEM_TRAIT_TYPE_JEWELRY_ARCANE]		= "esoui/art/icons/jewelrycrafting_trait_refined_cobalt.dds",
	[ITEM_TRAIT_TYPE_JEWELRY_HEALTHY]		= "esoui/art/icons/jewelrycrafting_trait_refined_antimony.dds",
	[ITEM_TRAIT_TYPE_JEWELRY_ROBUST]		= "esoui/art/icons/jewelrycrafting_trait_refined_zinc.dds",
	[ITEM_TRAIT_TYPE_JEWELRY_BLOODTHIRSTY]	= "esoui/art/icons/crafting_enchantment_baxe_bloodstone_r1.dds",
	[ITEM_TRAIT_TYPE_JEWELRY_HARMONY]		= "esoui/art/icons/crafting_metals_tin.dds",
	[ITEM_TRAIT_TYPE_JEWELRY_INFUSED]		= "esoui/art/icons/crafting_enchantment_base_jade_r1.dds",
	[ITEM_TRAIT_TYPE_JEWELRY_PROTECTIVE]	= "esoui/art/icons/crafting_runecrafter_armor_component_006.dds",
	[ITEM_TRAIT_TYPE_JEWELRY_SWIFT]			= "esoui/art/icons/crafting_outfitter_plug_component_002.dds",
	[ITEM_TRAIT_TYPE_JEWELRY_TRIUNE]		= "esoui/art/icons/jewelrycrafting_trait_refined_dawnprism.dds",
	--Weapons
	[ITEM_TRAIT_TYPE_WEAPON_ORNATE]			= "esoui/art/inventory/inventory_trait_ornate_icon.dds",
	[ITEM_TRAIT_TYPE_WEAPON_INTRICATE]		= "esoui/art/inventory/inventory_trait_intricate_icon.dds",
	[ITEM_TRAIT_TYPE_WEAPON_CHARGED]		= "esoui/art/icons/crafting_jewelry_base_amethyst_r3.dds",
	[ITEM_TRAIT_TYPE_WEAPON_DECISIVE]		= "esoui/art/icons/crafting_smith_potion__sp_names_003.dds",
	[ITEM_TRAIT_TYPE_WEAPON_DEFENDING]		= "esoui/art/icons/crafting_jewelry_base_turquoise_r3.dds",
	[ITEM_TRAIT_TYPE_WEAPON_INFUSED]		= "esoui/art/icons/crafting_enchantment_base_jade_r3.dds",
	[ITEM_TRAIT_TYPE_WEAPON_NIRNHONED]		= "esoui/art/icons/crafting_potent_nirncrux_dust.dds",
	[ITEM_TRAIT_TYPE_WEAPON_POWERED]		= "esoui/art/icons/crafting_runecrafter_potion_008.dds",
	[ITEM_TRAIT_TYPE_WEAPON_PRECISE]		= "esoui/art/icons/crafting_jewelry_base_ruby_r3.dds",
	[ITEM_TRAIT_TYPE_WEAPON_SHARPENED]		= "esoui/art/icons/crafting_enchantment_base_fire_opal_r3.dds",
	[ITEM_TRAIT_TYPE_WEAPON_TRAINING] 		= "esoui/art/icons/crafting_runecrafter_armor_component_004.dds",
}
RA.traitTextures = traitTextures

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

local function buildItemTraitIconText(text, traitId)
	local itemTraitIconText = text
	if traitId ~= ITEM_TRAIT_TYPE_NONE then
		--itemTraitIconText = zo_iconTextFormat(traitTextures[traitId], 20, 20, itemTraitIconText)
		itemTraitIconText = zo_strformat(text .. " <<1>>", zo_iconFormat(traitTextures[traitId], 20, 20))
	end
	return itemTraitIconText
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

local function getWhoKnowsAndTraitTextAndTexture(p_itemLink, p_traitKey)
	local r_traitName
	local r_whoKnows = RASettings:GetCharsWhoKnowTrait(p_traitKey)
	if r_whoKnows and r_whoKnows ~= "" then
		local traitId = GetItemLinkTraitType(p_itemLink)
		if traitId then
			r_traitName = traitTypes[traitId]
			r_traitName = " " .. buildItemTraitIconText(r_traitName, traitId)
		end
	end
	return r_whoKnows, r_traitName
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
			control.dataEntry.data.researchAssistant = LIBRESEARCH_REASON_WRONG_ITEMTYPElower
			indicatorControl:SetHidden(true)
			return
		-- if the item has no trait and we don't want to display icon for traitless items, hide and go away
		elseif reason == libResearch_Reason_TRAITLESS then
			control.dataEntry.data.researchAssistant = LIBRESEARCH_REASON_TRAITLESSlower
			if not RASettings:ShowTraitless() then
				indicatorControl:SetHidden(true)
				return
			end
		-- if the item is ornate, make icon ornate if we show ornate and hide/go away if we don't show it
		elseif reason == libResearch_Reason_ORNATE then
			control.dataEntry.data.researchAssistant = LIBRESEARCH_REASON_ORNATElower
			if not RASettings:ShowUntrackedOrnate() or (craftingSkill == -1 or (RASettings:IsMultiCharSkillOff(craftingSkill, itemType) == true)) then
				indicatorControl:SetHidden(true)
			else
				SetToOrnate(indicatorControl)
				DisplayIndicator(indicatorControl, LIBRESEARCH_REASON_ORNATElower)
			end
			return
		-- if the item is intricate, make icon intricate if we show that and hide/go away if we don't
		elseif reason == libResearch_Reason_INTRICATE then
			control.dataEntry.data.researchAssistant = LIBRESEARCH_REASON_INTRICATElower
			if not RASettings:ShowUntrackedIntricate() or (craftingSkill == -1 or (RASettings:IsMultiCharSkillOff(craftingSkill, itemType) == true))  then
				indicatorControl:SetHidden(true)
			else
				SetToIntricate(indicatorControl)
				DisplayIndicator(indicatorControl, LIBRESEARCH_REASON_INTRICATElower)
			end
			return
		end
	end

	--if we aren't tracking anybody for that skill, hide and go away
	if RASettings:IsMultiCharSkillOff(craftingSkill, itemType) == true then
		control.dataEntry.data.researchAssistant = TRACKING_STATE_UNTRACKED
		indicatorControl:SetHidden(true)
		return
	end

	--preference value for the "best" item candidate for the trait in question
	local bestTraitPreferenceScore = RASettings:GetPreferenceValueForTrait(traitKey)
	--research character of that item
	local researchCharOfCraftingTypeNameDecorated = RASettings:GetTrackedCharForSkill(craftingSkill, itemType, true)

	if bestTraitPreferenceScore == nil then
		-- if the item is traitless, show "researched" color. if we've never seen this trait before, show "best" color.
		if reason == libResearch_Reason_TRAITLESS then
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

	local stackSize = control.dataEntry.data.stackCount or 0

	--Who knows the trait already?
	local whoKnows = ""
	local traitName
	local showTooltips = RASettings:ShowTooltips()
	--d(">" .. string.format("traitKey: %s, isResearchable: %s, reason: %s, score: %s, stackSize: %s, char: %s, whoKnows: %s", tostring(traitKey), tostring(isResearchable), tostring(reason), tostring(bestTraitPreferenceScore), tostring(stackSize), tostring(researchCharOfCraftingTypeNameDecorated), tostring(whoKnows)))

	--pretty colors time!
	--if we don't know it, color the icon something fun
	if bestTraitPreferenceScore ~= true then
		if bestTraitPreferenceScore == RASettings.CONST_CHARACTER_NOT_SCANNED_YET then
			indicatorControl:SetColor(unpack(RASettings:GetNotScannedColor()))
			HandleTooltips(indicatorControl, string.format(RA_Strings[RAlang].TOOLTIPS.notScannedWithNeededCharYet, researchCharOfCraftingTypeNameDecorated))
			control.dataEntry.data.researchAssistant = TRACKING_STATE_CHARACTER_NOT_SCANNED_YET
			return
		else
			--preference value for the current item
			local thisItemScore = RAScanner:CreateItemPreferenceValue(itemLink, bagId, slotIndex)
			if (thisItemScore > bestTraitPreferenceScore or stackSize > 1) then
				indicatorControl:SetColor(unpack(RASettings:GetDuplicateUnresearchedColor()))
				if showTooltips == true then
					whoKnows, traitName = getWhoKnowsAndTraitTextAndTexture(itemLink, traitKey)
				end
				if showTooltips == true and whoKnows ~= "" then
					HandleTooltips(indicatorControl, string.format(RA_Strings[RAlang].TOOLTIPS.duplicate, string.format(RA_Strings[RAlang].TOOLTIPS.knownBy, traitName)) .. whoKnows)
				else
					HandleTooltips(indicatorControl, string.format(RA_Strings[RAlang].TOOLTIPS.duplicate, ""))
				end
				control.dataEntry.data.researchAssistant = TRACKING_STATE_DUPLICATE
			else
				indicatorControl:SetColor(unpack(RASettings:GetCanResearchColor()))
				if showTooltips == true then
					whoKnows, traitName = getWhoKnowsAndTraitTextAndTexture(itemLink, traitKey)
				end
				if showTooltips == true and whoKnows ~= "" then
					HandleTooltips(indicatorControl, string.format(RA_Strings[RAlang].TOOLTIPS.canResearch, string.format(RA_Strings[RAlang].TOOLTIPS.knownBy, traitName)) .. whoKnows)
				else
					HandleTooltips(indicatorControl, string.format(RA_Strings[RAlang].TOOLTIPS.canResearch, ""))
				end
				control.dataEntry.data.researchAssistant = TRACKING_STATE_RESEARCHABLE
			end
			return
		end
	end
	--in any other case, color it known
	indicatorControl:SetColor(unpack(RASettings:GetAlreadyResearchedColor()))
	if showTooltips == true then
		whoKnows, traitName = getWhoKnowsAndTraitTextAndTexture(itemLink, traitKey)
	end
	if showTooltips == true and whoKnows ~= "" then
		HandleTooltips(indicatorControl, string.format(RA_Strings[RAlang].TOOLTIPS.alreadyResearched, string.format(RA_Strings[RAlang].TOOLTIPS.knownBy, traitName)) .. whoKnows)
	else
		HandleTooltips(indicatorControl, string.format(RA_Strings[RAlang].TOOLTIPS.alreadyResearched, ""))
	end
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