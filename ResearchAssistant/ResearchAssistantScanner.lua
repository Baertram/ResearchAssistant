--Local variables for the class
local BLACKSMITH 		= CRAFTING_TYPE_BLACKSMITHING
local CLOTHIER 			= CRAFTING_TYPE_CLOTHIER
local WOODWORK 			= CRAFTING_TYPE_WOODWORKING
local JEWELRY_CRAFTING 	= CRAFTING_TYPE_JEWELRYCRAFTING

--LibResearch reasons
local libResearch_Reason_ALREADY_KNOWN 	= LIBRESEARCH_REASON_ALREADY_KNOWN or "AlreadyKnown"
local libResearch_Reason_WRONG_ITEMTYPE = LIBRESEARCH_REASON_WRONG_ITEMTYPE or "WrongItemType"

--House bank bags
local maxHouseBankBag = BAG_HOUSE_BANK_TEN
local houseBankBags = {}
for bagHouseBank = BAG_HOUSE_BANK_ONE, maxHouseBankBag, 1 do
	houseBankBags[bagHouseBank] = true
end

--LibResearch
local libResearch

--Class ResearchAssistantScanner
ResearchAssistantScanner = ZO_Object:Subclass()

function ResearchAssistantScanner:Initialize(settings)
	self.ownedTraits = {}
	self.ownedTraits_Bank = nil
	self.ownedTraits_SubscriberBank = nil
	self.ownedTraits_HouseBank = nil
	self.isScanning = false
	self.scanMore = 0
	self.settingsPtr = settings
	self.bankScanEnabled = false
	self.houseBankScanEnabled = false
	self.debug = false

	libResearch = ResearchAssistant.libResearch or LibResearch

	self:RescanBags()
end

function ResearchAssistantScanner:New(...)
	local obj = ZO_Object.New(self)
	obj:Initialize(...)
	return obj
end

function ResearchAssistantScanner:SetBankScanEnabled(value)
	self.bankScanEnabled=value
end

function ResearchAssistantScanner:IsBankScanEnabled()
	return self.bankScanEnabled
end

function ResearchAssistantScanner:SetHouseBankScanEnabled(value, scanHouseBankOnFirstOpen)
	scanHouseBankOnFirstOpen = scanHouseBankOnFirstOpen or false
	self.houseBankScanEnabled=value

	--HouseBank is currently opened? Check if it wasn't scanned yet and scan on first open
	if scanHouseBankOnFirstOpen == true and value == true and IsBankOpen() and self.ownedTraits_HouseBank == nil then
		local isHouseBankBag = houseBankBags[GetBankingBag()] or false
		if isHouseBankBag == true then
			--Scan the house bank bags now
			self.ownedTraits_HouseBank = {}
			for bagHouseBank = BAG_HOUSE_BANK_ONE, maxHouseBankBag, 1 do
				self:ScanBag(bagHouseBank)
			end
		end
	end
end

function ResearchAssistantScanner:IsHouseBankScanEnabled()
	return self.houseBankScanEnabled
end

function ResearchAssistantScanner:SetDebug(value)
	self.debug=value
end

function ResearchAssistantScanner:IsDebug()
	return self.debug
end

function ResearchAssistantScanner:SetScanning(value)
	self.isScanning = value
end

function ResearchAssistantScanner:IsScanning()
	return self.isScanning
end

function ResearchAssistantScanner:CreateItemPreferenceValue(itemLink, bagId, slotIndex)
	local quality = GetItemLinkQuality(itemLink)
	if not quality then
		quality = 1
	end

	local level = GetItemLinkRequiredLevel(itemLink)
	if not level then
		level = 1
	end

	local isSet = GetItemLinkSetInfo(itemLink, false)
	isSet = isSet or false
	local set = (isSet == true and 1) or 0

	local bagToWhere = {
		[BAG_BANK] 				= 1,
		[BAG_SUBSCRIBER_BANK] 	= 1,
		[BAG_BACKPACK] 			= 2,
		[BAG_GUILDBANK] 		= 3,
	}
	for bagHouseBank = BAG_HOUSE_BANK_ONE, maxHouseBankBag, 1 do
		bagToWhere[bagHouseBank] = 4
	end
	local where = bagToWhere[bagId] or 1

	--wxxxyzzz
	--The lowest preference value is the "preferred" value for a research!
	--
	--Standard checks are:
	--level
	--quality
	--set item (no set=0, set=1)
	--
	--Where is the item located:
	--bank is lowest number, will be orange if you have a dupe in your inventory
	--bag is middle number, will be yellow if you have a dupe in the inventory
	--gbank is 2nd highest number, will be yellow if you have a dupe in the inventory
	--housebank is highest number, will be yellow if you have a dupe in the inventory
	return quality * 10000000 + set * 1000000 + level * 10000 + where * 1000 + (slotIndex or 0)
end

--Is the item protected against research by any means?
--e.g. item is locked by ZOs lock functionality, or by other addons like
--FCOItemSaver
function ResearchAssistantScanner:IsItemProtectedAgainstResearch(bagId, slotIndex, itemLink)
	if not bagId or not slotIndex then return false end
	--Setting to exclude protected items is enabled?
	local settings = self.settingsPtr.sv
	local respectZOs = settings.respectItemProtectionByZOs
	local respectFCOIS = settings.respectItemProtectionByFCOIS
	local isLocked = false
	if respectZOs == true or respectFCOIS == true then
		if respectZOs == true then
			isLocked = IsItemPlayerLocked(bagId, slotIndex)
		end
		if respectFCOIS == true and FCOIS ~= nil then
			if itemLink == nil or itemLink == "" then
				itemLink = GetItemLink(bagId, slotIndex)
			end
			local equipType = GetItemLinkEquipType(itemLink)
			if equipType == EQUIP_TYPE_NECK or equipType == EQUIP_TYPE_RING then
				isLocked = FCOIS.IsJewelryResearchLocked(bagId, slotIndex)
			else
				isLocked = FCOIS.IsResearchLocked(bagId, slotIndex)
			end
		end
		return isLocked
	end
	return false
end

function ResearchAssistantScanner:ScanBag(bagId)
	local traits = {}
	local numSlots = GetBagSize(bagId)
	if self.debug == true then
		d("[ReasearchAssistant]Scanner:ScanBag("..tostring(bagId).."), entries: " ..tostring(numSlots))
	end
	for i = 0, numSlots do
		local itemLink = GetItemLink(bagId, i)
		if itemLink ~= "" then
			--Is the item protected against research by any means?
			local traitKey, isResearchable, reason = self:CheckIsItemResearchable(itemLink)
			if self:IsItemProtectedAgainstResearch(bagId, i, itemLink) == false then
				local prefValue = self:CreateItemPreferenceValue(itemLink, bagId, i)
				if self.debug == true then
					if bagId == BAG_BACKPACK and reason ~= libResearch_Reason_WRONG_ITEMTYPE then
						d(">>"..tostring(i).." "..GetItemLinkName(itemLink)..": trait "..tostring(traitKey).." can? "..tostring(isResearchable).." why? "..tostring(reason).." pref: "..prefValue)
					end
				end
				--is this item researchable?
				if isResearchable then
					-- if so, is this item preferable to the one we already have on record?
					if prefValue < (traits[traitKey] or RA_CON_MAX_PREFRENCE_VALUE) then
						traits[traitKey] = prefValue
					end
				else
					--if we're here,
					if reason == libResearch_Reason_ALREADY_KNOWN then
						--either we already know it
						traits[traitKey] = true
					else
						--or it has no trait, in which case we ignore it
						traits[traitKey] = nil
					end
				end
			else
				--or it is protected, in which case we ignore it
				traits[traitKey] = nil
			end
		end
	end
	return traits
end

function ResearchAssistantScanner:JoinCachedOwnedTraits(traits)
	if not traits then return end
	for traitKey, value in pairs(traits) do
		local valType = type(value)
		local valIsNumber = (valType == "number") or false
		local ownedTraitsOfKey = self.ownedTraits[traitKey]
		local compareValue = ((valIsNumber and ownedTraitsOfKey ~= nil) and ownedTraitsOfKey) or RA_CON_MAX_PREFRENCE_VALUE
		--Value boolean true: Known
		--Value number: Preference number
		if value == nil and (value == true or (value < compareValue)) then
			self.ownedTraits[traitKey] = value
		end
	end
end

function ResearchAssistantScanner:ScanKnownTraits()
	for researchLineIndex = 1, GetNumSmithingResearchLines(BLACKSMITH) do
		for traitIndex = 1, 9 do
			if self:WillCharacterKnowTrait(BLACKSMITH, researchLineIndex, traitIndex) then
				self.ownedTraits[self:GetTraitKey(BLACKSMITH, researchLineIndex, traitIndex)] = true
			end
		end
	end
	for researchLineIndex = 1, GetNumSmithingResearchLines(CLOTHIER) do
		for traitIndex = 1, 9 do
			if self:WillCharacterKnowTrait(CLOTHIER, researchLineIndex, traitIndex) then
				self.ownedTraits[self:GetTraitKey(CLOTHIER, researchLineIndex, traitIndex)] = true
			end
		end
	end
	for researchLineIndex = 1, GetNumSmithingResearchLines(WOODWORK) do
		for traitIndex = 1, 9 do
			if self:WillCharacterKnowTrait(WOODWORK, researchLineIndex, traitIndex) then
				self.ownedTraits[self:GetTraitKey(WOODWORK, researchLineIndex, traitIndex)] = true
			end
		end
	end
	for researchLineIndex = 1, GetNumSmithingResearchLines(JEWELRY_CRAFTING) do
		for traitIndex = 1, 9 do
			if self:WillCharacterKnowTrait(JEWELRY_CRAFTING, researchLineIndex, traitIndex) then
				self.ownedTraits[self:GetTraitKey(JEWELRY_CRAFTING, researchLineIndex, traitIndex)] = true
			end
		end
	end
end

function ResearchAssistantScanner:RescanBags()
	if self.isScanning then
		self.scanMore = self.scanMore + 1
		return
	end
	self:SetScanning(true)

	local startTime
	if self.debug == true then
		d("[ReasearchAssistant]Scanner:ScanBags()")
		startTime = GetGameTimeMilliseconds()
	end
	self.ownedTraits = self:ScanBag(BAG_BACKPACK)
	if self.debug == true then
		d(">backpack scan elapsed: ".. (GetGameTimeMilliseconds()-startTime))
	end

	if(self:IsBankScanEnabled() == true or self.ownedTraits_Bank==nil) then
		if self.debug == true then
			startTime = GetGameTimeMilliseconds()
		end
		self.ownedTraits_Bank = self:ScanBag(BAG_BANK)
		if self.debug == true then
			d(">bank scan elapsed: ".. (GetGameTimeMilliseconds()-startTime))
			startTime = GetGameTimeMilliseconds()
		end
		self.ownedTraits_SubscriberBank = self:ScanBag(BAG_SUBSCRIBER_BANK)
		if self.debug == true then
			d(">subscriber bank scan elapsed: ".. (GetGameTimeMilliseconds()-startTime))
		end
	end
	--Check if inside a house & house bank was opened -> Prerequisite to scan the house banks
	--as it cannot be accessed from outside a house
	local isInHouseAtHouseBank = self:IsHouseBankScanEnabled()
	if isInHouseAtHouseBank == true then
		--For each possible house bank coffer scan the bag
		self.ownedTraits_HouseBank = self.ownedTraits_HouseBank or {}
		for houseBankBag=BAG_HOUSE_BANK_ONE, maxHouseBankBag, 1 do
			if self.debug == true then
				startTime = GetGameTimeMilliseconds()
			end
			self.ownedTraits_HouseBank[houseBankBag] = self:ScanBag(houseBankBag)
			if self.debug == true then
				d(">house bank " .. tostring(houseBankBag) .." scan elapsed: ".. (GetGameTimeMilliseconds()-startTime))
			end
		end
	end

	self:JoinCachedOwnedTraits(self.ownedTraits_Bank)
	self:JoinCachedOwnedTraits(self.ownedTraits_SubscriberBank)
	--For each possible house bank coffer: Join the scanned house bank trait items to the total table
	if self.ownedTraits_HouseBank then
		for houseBankBag=BAG_HOUSE_BANK_ONE, maxHouseBankBag, 1 do
			self:JoinCachedOwnedTraits(self.ownedTraits_HouseBank[houseBankBag])
		end
	end

	self:ScanKnownTraits()
	self.settingsPtr:SetKnownTraits(self.ownedTraits)

	if self.scanMore ~= 0 then
		self.scanMore = self.scanMore - 1
		self:SetScanning(false)
		self:RescanBags()
	else
		self:SetScanning(false)
	end
end

function ResearchAssistantScanner:GetTrait(traitKey)
	return self.ownedTraits[traitKey]
end

-- returns int traitKey, bool isResearchable, string reason ["WrongItemType" "Ornate" "Intricate" "Traitless" "AlreadyKnown"]
function ResearchAssistantScanner:CheckIsItemResearchable(itemLink)
	return libResearch:GetItemTraitResearchabilityInfo(itemLink)
end

function ResearchAssistantScanner:GetTraitKey(craftingSkillType, researchLineIndex, traitIndex)
	return libResearch:GetTraitKey(craftingSkillType, researchLineIndex, traitIndex)
end

function ResearchAssistantScanner:GetItemCraftingSkill(itemLink)
	return libResearch:GetItemCraftingSkill(itemLink)
end

function ResearchAssistantScanner:GetResearchTraitIndex(itemLink)
	return libResearch:GetResearchTraitIndex(itemLink)
end

function ResearchAssistantScanner:GetResearchLineIndex(itemLink)
	return libResearch:GetResearchLineIndex(itemLink)
end

function ResearchAssistantScanner:GetItemResearchInfo(itemLink)
	return libResearch:GetItemResearchInfo(itemLink)
end

function ResearchAssistantScanner:IsBigThreeCrafting(craftingSkillType)
	return libResearch:IsBigThreeCrafting(craftingSkillType)
end

function ResearchAssistantScanner:WillCharacterKnowTrait(craftingSkillType, researchLineIndex, traitIndex)
	return libResearch:WillCharacterKnowTrait(craftingSkillType, researchLineIndex, traitIndex)
end