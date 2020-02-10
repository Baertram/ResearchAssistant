if ResearchAssistant == nil then ResearchAssistant = {} end
local RA = ResearchAssistant

local settings = nil
local _
local CONST_OFF = "-"

local currentlyLoggedInCharId = GetCurrentCharacterId()

local CAN_RESEARCH_TEXTURES = {
    ["Classic"] = {
        texturePath = [[/esoui/art/buttons/edit_disabled.dds]],
        textureSize = 30,
    },
    ["Modern"] =  {
        texturePath = [[/esoui/art/buttons/checkbox_indeterminate.dds]],
        textureSize = 16,
    },
    ["Circle"] = {
        texturePath = [[/esoui/art/miscellaneous/gamepad/pip_active.dds]],
        textureSize = 16,
    },
    ["Diamond"] = {
        texturePath = [[/esoui/art/miscellaneous/gamepad/scrollbox_elevator.dds]],
        textureSize = 16,
    },
    ["Triangle"] = {
        texturePath = [[/esoui/art/miscellaneous/slider_marker_up.dds]],
        textureSize = 16,
    },
    ["Magnifier"] = {
        texturePath = [[/esoui/art/miscellaneous/search_icon.dds]],
        textureSize = 32,
    },
}

local TEXTURE_OPTIONS = { "Classic", "Modern", "Circle", "Diamond", "Triangle", "Magnifier", }

-----------------------------
--UTIL FUNCTIONS
-----------------------------
local function RGBAToHex(r, g, b, a)
    r = (r>1 and 1) or (r<0 and 0) or r
    g = (g>1 and 1) or (g<0 and 0) or g
    b = (b>1 and 1) or (b<0 and 0) or b
    return string.format("%02x%02x%02x%02x", r * 255, g * 255, b * 255, a * 255)
end

local function HexToRGBA(hex)
    local rhex, ghex, bhex, ahex = string.sub(hex, 1, 2), string.sub(hex, 3, 4), string.sub(hex, 5, 6), string.sub(hex, 7, 8)
    return tonumber(rhex, 16)/255, tonumber(ghex, 16)/255, tonumber(bhex, 16)/255, tonumber(ahex, 16)/255
end

--Build the table of all characters of the account
local function getCharactersOfAccount(keyIsCharName)
    keyIsCharName = keyIsCharName or false
    local charactersOfAccount
    --Check all the characters of the account
    for i = 1, GetNumCharacters() do
        local name, _, _, _, _, _, characterId = GetCharacterInfo(i)
        local charName = zo_strformat(SI_UNIT_NAME, name)
        if characterId ~= nil and charName ~= "" then
            if charactersOfAccount == nil then charactersOfAccount = {} end
            if keyIsCharName then
                charactersOfAccount[charName]   = characterId
            else
                charactersOfAccount[characterId]= charName
            end
        end
    end
    return charactersOfAccount
end

------------------------------
--OBJECT FUNCTIONS
------------------------------
ResearchAssistantSettings = ZO_Object:Subclass()

function ResearchAssistantSettings:New()
    local obj = ZO_Object.New(self)
    obj:Initialize()
    return obj
end

function ResearchAssistantSettings:Initialize()
    local defaults = {
        debug = false,

        raToggle = true,
        multiCharacter = false,

        textureName = "Modern",
        textureSize = 16,
        textureOffset = 0,
        showTooltips = false,
        separateClothier = false,
        separateSmithing = false,

        canResearchColor = RGBAToHex(1, .25, 0, 1),
        duplicateUnresearchedColor = RGBAToHex(1, 1, 0, 1),
        alreadyResearchedColor = RGBAToHex(.5, .5, .5, 1),
        ornateColor = RGBAToHex(1, 1, 0, 1),
				intricateColor = RGBAToHex(0, 1, 1, 1),

        showResearched = true,
        showTraitless = true,
        showUntrackedOrnate = true,
        showUntrackedIntricate = true,

        blacksmithCharacter = {},
        weaponsmithCharacter = {},
        woodworkingCharacter = {},
        clothierCharacter = {},
        leatherworkerCharacter = {},
        jewelryCraftingCharacter = {},

        --non settings variables
        acquiredTraits = {},
		}
    --Old non-server dependent character name settings
    --settings = ZO_SavedVars:NewAccountWide("ResearchAssistant_Settings", 2, nil, defaults)
    --New server dependent character unique ID settings
    --ZO_SavedVars:NewAccountWide(savedVariableTable, version, namespace, defaults, profile, displayName)
    settings = ZO_SavedVars:NewAccountWide("ResearchAssistant_Settings_Server", 2, nil, defaults, GetWorldName(), nil)

    if settings.isBlacksmith then settings.isBlacksmith = nil end
    if settings.isWoodworking then settings.isWoodworking = nil end
    if settings.isClothier then settings.isClothier = nil end
    if settings.isLeatherworker then settings.isLeatherworker = nil end
    if settings.isWeaponsmith then settings.isWeaponsmith = nil end
    if settings.useCrossCharacter then settings.useCrossCharacter = nil end
    if settings.showInGrid then settings.showInGrid = nil end

    if (not settings.showResearched) and settings.showTraitless then
        settings.showTraitless = false
    end

    if(not settings.blacksmithCharacter[currentlyLoggedInCharId]) then
        settings.blacksmithCharacter[currentlyLoggedInCharId] = currentlyLoggedInCharId
    end
    if (not settings.weaponsmithCharacter[currentlyLoggedInCharId]) then
        settings.weaponsmithCharacter[currentlyLoggedInCharId] = settings.blacksmithCharacter[currentlyLoggedInCharId]
    end
    if (not settings.woodworkingCharacter[currentlyLoggedInCharId]) then
        settings.woodworkingCharacter[currentlyLoggedInCharId] = currentlyLoggedInCharId
    end
    if (not settings.clothierCharacter[currentlyLoggedInCharId]) then
        settings.clothierCharacter[currentlyLoggedInCharId] = currentlyLoggedInCharId
    end
    if (not settings.leatherworkerCharacter[currentlyLoggedInCharId]) then
        settings.leatherworkerCharacter[currentlyLoggedInCharId] = settings.clothierCharacter[currentlyLoggedInCharId]
    end
    if (not settings.jewelryCraftingCharacter[currentlyLoggedInCharId]) then
        settings.jewelryCraftingCharacter[currentlyLoggedInCharId] = currentlyLoggedInCharId
    end
    if (not settings.acquiredTraits[currentlyLoggedInCharId]) then
        settings.acquiredTraits[currentlyLoggedInCharId] = { }
    end

    --Build a list of characters of the current acount
    --Key is the unique character Id, value is the name
    self.charId2Name = getCharactersOfAccount(false)
    --Key is the name, value the unique character Id
    self.charName2Id = getCharactersOfAccount(true)
    --The LAM settings character values table
    self.lamCharNamesTable = {}
    --Build the known characters table for the LAM dropdown controls
    self.lamCharIdTable = {}
    table.insert(self.lamCharNamesTable, 1, "-")
    for l_charId, l_charName in pairs(self.charId2Name) do
        table.insert(self.lamCharNamesTable, l_charName)
    end
    table.insert(self.lamCharIdTable, 1, 0)
    for idx, l_charName in ipairs(self.lamCharNamesTable) do
        table.insert(self.lamCharIdTable, idx, self.charName2Id[l_charName])
    end

    self:CreateOptionsMenu()

    self.sv = settings
end

function ResearchAssistantSettings:IsActivated()
    return settings.raToggle
end

function ResearchAssistantSettings:GetCanResearchColor()
    local r, g, b, a = HexToRGBA(settings.canResearchColor)
    return {r, g, b, a}
end

function ResearchAssistantSettings:GetDuplicateUnresearchedColor()
    local r, g, b, a = HexToRGBA(settings.duplicateUnresearchedColor)
    return {r, g, b, a}
end

function ResearchAssistantSettings:GetAlreadyResearchedColor()
    local r, g, b, a = HexToRGBA(settings.alreadyResearchedColor)
    return {r, g, b, a}
end

function ResearchAssistantSettings:GetOrnateColor()
    local r, g, b, a = HexToRGBA(settings.ornateColor)
    return {r, g, b, a}
end

function ResearchAssistantSettings:GetIntricateColor()
    local r, g, b, a = HexToRGBA(settings.intricateColor)
    return {r, g, b, a}
end

function ResearchAssistantSettings:ShowResearched()
    return settings.showResearched
end

function ResearchAssistantSettings:ShowTraitless()
    return settings.showTraitless
end

function ResearchAssistantSettings:ShowUntrackedOrnate()
    return settings.showUntrackedOrnate
end

function ResearchAssistantSettings:ShowUntrackedIntricate()
    return settings.showUntrackedIntricate
end

function ResearchAssistantSettings:ShowTooltips()
    return settings.showTooltips
end

function ResearchAssistantSettings:SetKnownTraits(traitsTable)
    settings.acquiredTraits[currentlyLoggedInCharId] = traitsTable
end

function ResearchAssistantSettings:GetCharsWhoKnowTrait(traitKey)
    local knowers = ""
    for curChar, traitList in pairs(settings.acquiredTraits) do
        if traitList[traitKey] == true then knowers = knowers .. ", " .. curChar end
    end
    return string.sub(knowers, 3)
end

function ResearchAssistantSettings:GetCraftingCharacterTraits(craftingSkillType, itemType)
    local crafter
    if(craftingSkillType == CRAFTING_TYPE_BLACKSMITHING and itemType > 7) then
        crafter = settings.blacksmithCharacter[currentlyLoggedInCharId]
    elseif(craftingSkillType == CRAFTING_TYPE_BLACKSMITHING and itemType <= 7) then
        crafter = settings.weaponsmithCharacter[currentlyLoggedInCharId]
    elseif(craftingSkillType == CRAFTING_TYPE_CLOTHIER and itemType <= 7) then
        crafter = settings.clothierCharacter[currentlyLoggedInCharId]
    elseif(craftingSkillType == CRAFTING_TYPE_CLOTHIER and itemType > 7) then
        crafter = settings.leatherworkerCharacter[currentlyLoggedInCharId]
    elseif(craftingSkillType == CRAFTING_TYPE_WOODWORKING) then
        crafter = settings.woodworkingCharacter[currentlyLoggedInCharId]
    elseif(craftingSkillType == CRAFTING_TYPE_JEWELRYCRAFTING) then
        crafter = settings.jewelryCraftingCharacter[currentlyLoggedInCharId]
    else
        crafter = currentlyLoggedInCharId
    end

    if crafter == CONST_OFF then
      return
    else
        return settings.acquiredTraits[crafter]
    end
end

function ResearchAssistantSettings:GetPlayerTraits()
    return settings.acquiredTraits[currentlyLoggedInCharId]
end

function ResearchAssistantSettings:GetTraits()
    return settings.acquiredTraits
end

function ResearchAssistantSettings:IsMultiCharSkillOff(craftingSkillType, itemType)
    if(craftingSkillType == CRAFTING_TYPE_BLACKSMITHING and itemType > 7) then
        return settings.blacksmithCharacter[currentlyLoggedInCharId] == CONST_OFF
    elseif(craftingSkillType == CRAFTING_TYPE_BLACKSMITHING and itemType <= 7) then
        return settings.weaponsmithCharacter[currentlyLoggedInCharId] == CONST_OFF
    elseif(craftingSkillType == CRAFTING_TYPE_CLOTHIER and itemType <= 7) then
        return settings.clothierCharacter[currentlyLoggedInCharId] == CONST_OFF
    elseif(craftingSkillType == CRAFTING_TYPE_CLOTHIER and itemType > 7) then
        return settings.leatherworkerCharacter[currentlyLoggedInCharId] == CONST_OFF
    elseif(craftingSkillType == CRAFTING_TYPE_WOODWORKING) then
        return settings.woodworkingCharacter[currentlyLoggedInCharId] == CONST_OFF
    elseif(craftingSkillType == CRAFTING_TYPE_JEWELRYCRAFTING) then
        return settings.jewelryCraftingCharacter[currentlyLoggedInCharId] == CONST_OFF
    else
        return true
    end
end

function ResearchAssistantSettings:GetTrackedCharForSkill(craftingSkillType, itemType)
    if(craftingSkillType == CRAFTING_TYPE_BLACKSMITHING and itemType > 7) then
        return settings.blacksmithCharacter[currentlyLoggedInCharId]
    elseif(craftingSkillType == CRAFTING_TYPE_BLACKSMITHING and itemType <= 7) then
        return settings.weaponsmithCharacter[currentlyLoggedInCharId]
    elseif(craftingSkillType == CRAFTING_TYPE_CLOTHIER and itemType <= 7) then
        return settings.clothierCharacter[currentlyLoggedInCharId]
    elseif(craftingSkillType == CRAFTING_TYPE_CLOTHIER and itemType > 7) then
        return settings.leatherworkerCharacter[currentlyLoggedInCharId]
    elseif(craftingSkillType == CRAFTING_TYPE_WOODWORKING) then
        return settings.woodworkingCharacter[currentlyLoggedInCharId]
    elseif(craftingSkillType == CRAFTING_TYPE_JEWELRYCRAFTING) then
        return settings.jewelryCraftingCharacter[currentlyLoggedInCharId] == CONST_OFF
    else
        return CONST_OFF
    end
end

function ResearchAssistantSettings:GetPreferenceValueForTrait(traitKey)
    if (not traitKey) or (traitKey == 0) then return nil end
    local craft = zo_floor(traitKey / 10000)
    local item = zo_floor((traitKey - (craft * 10000)) / 100)
    local traits = self:GetCraftingCharacterTraits(craft, item)
    return traits[traitKey]
end

function ResearchAssistantSettings:GetTexturePath()
    return CAN_RESEARCH_TEXTURES[settings.textureName].texturePath
end

function ResearchAssistantSettings:GetTextureSize()
    return settings.textureSize
end

function ResearchAssistantSettings:GetTextureOffset()
    return settings.textureOffset + 70
end

function ResearchAssistantSettings:IsDebug()
    return settings.debug
end

function ResearchAssistantSettings:CreateOptionsMenu()
    local LAM = RA.lam
    local str = RA_Strings[self:GetLanguage()].SETTINGS

    local panel = {
        type = "panel",
        name = RA.name,
        author = RA.author,
        version = RA.version,
        website = RA.website,
        slashCommand = "/researchassistant",
        registerForRefresh = true
    }

    local icon = WINDOW_MANAGER:CreateControl("RA_Icon", ZO_OptionsWindowSettingsScrollChild, CT_TEXTURE)
    icon:SetColor(1, 1, 1, 1)
    icon:SetHandler("OnShow", function()
        self:SetTexture(CAN_RESEARCH_TEXTURES[settings.textureName].texturePath)
        icon:SetDimensions(settings.textureSize, settings.textureSize)
    end)

    local optionsData = { }
    table.insert(optionsData, {
        type = "header",
        name = "Debug",
    })
    table.insert(optionsData, {
        type = "checkbox",
        name = "Debug",
        tooltip = "Debug",
        getFunc = function() return settings.debug end,
        setFunc = function(value)
            settings.debug = value
            RA.scanner:SetDebug(value)
        end,
    })
    table.insert(optionsData, {
        type = "header",
        name = str.GENERAL_HEADER,
    })
    table.insert(optionsData, {
        type = "dropdown",
        name = str.ICON_LABEL,
        tooltip = str.ICON_TOOLTIP,
        choices = TEXTURE_OPTIONS,
        getFunc = function() return settings.textureName end,
        setFunc = function(value)
            settings.textureName = value
            settings.textureSize = CAN_RESEARCH_TEXTURES[value].textureSize
            icon:SetTexture(CAN_RESEARCH_TEXTURES[value].texturePath)
            icon:SetDimensions(settings.textureSize, settings.textureSize)
            ResearchAssistant_InvUpdate()
        end,
        reference = "RA_Icon_Dropdown"
    })
    table.insert(optionsData, {
        type = "slider",
        name = str.ICON_SIZE,
        tooltip = str.ICON_SIZE_TOOLTIP,
        min = 8,
        max = 64,
        step = 4,
        getFunc = function() return settings.textureSize end,
        setFunc = function(size)
            settings.textureSize = size
            icon:SetDimensions(size, size)
            ResearchAssistant_InvUpdate()
        end,
        width="full",
        default = settings.textureSize,
    })
    table.insert(optionsData, {
        type = "slider",
        name = str.ICON_OFFSET,
        tooltip = str.ICON_OFFSET_TOOLTIP,
        min = -490,
        max = 60,
        step = 1,
        getFunc = function() return settings.textureOffset end,
        setFunc = function(offset)
            settings.textureOffset = offset
            ResearchAssistant_InvUpdate()
        end,
        width="full",
        default = settings.textureOffset,
    })
    table.insert(optionsData, {
        type = "checkbox",
        name = str.SHOW_TOOLTIPS_LABEL,
        tooltip = str.SHOW_TOOLTIPS_TOOLTIP,
        getFunc = function() return settings.showTooltips end,
        setFunc = function(value)
            settings.showTooltips = value
            ResearchAssistant_InvUpdate()
        end,
    })
    table.insert(optionsData, {
        type = "checkbox",
        name = str.SEPARATE_LW_LABEL,
        tooltip = str.SEPARATE_LW_TOOLTIP,
        getFunc = function() return settings.separateClothier end,
        setFunc = function(value)
            if not value then
                settings.leatherworkerCharacter[currentlyLoggedInCharId] = settings.clothierCharacter[currentlyLoggedInCharId]
            end
            settings.separateClothier = value
            ResearchAssistant_InvUpdate()
        end,
    })
    table.insert(optionsData, {
        type = "checkbox",
        name = str.SEPARATE_SMITH_LABEL,
        tooltip = str.SEPARATE_SMITH_TOOLTIP,
        getFunc = function() return settings.separateSmithing end,
        setFunc = function(value)
            if not value then
                settings.weaponsmithCharacter[currentlyLoggedInCharId] = settings.blacksmithCharacter[currentlyLoggedInCharId]
            end
            settings.separateSmithing = value
            ResearchAssistant_InvUpdate()
        end
    })
    table.insert(optionsData, {
        type = "header",
        name = str.CHARACTER_HEADER,
    })
    table.insert(optionsData, {
        type = "dropdown",
        name = str.WS_CHAR_LABEL,
        tooltip = str.WS_CHAR_TOOLTIP,
        choices = self.lamCharNamesTable,
        choicesValues = self.lamCharIdTable,
        getFunc = function() return settings.weaponsmithCharacter[currentlyLoggedInCharId] end,
        setFunc = function(value)
            settings.weaponsmithCharacter[currentlyLoggedInCharId] = value
            ResearchAssistant_InvUpdate()
        end,
        disabled = function() return not settings.separateSmithing end,
    })
    table.insert(optionsData, {
        type = "dropdown",
        name = str.BS_CHAR_LABEL,
        tooltip = str.BS_CHAR_TOOLTIP,
        choices = self.lamCharNamesTable,
        choicesValues = self.lamCharIdTable,
        getFunc = function() return settings.blacksmithCharacter[currentlyLoggedInCharId] end,
        setFunc = function(value)
            settings.blacksmithCharacter[currentlyLoggedInCharId] = value
            if not settings.separateSmithing then
                settings.weaponsmithCharacter[currentlyLoggedInCharId] = value
            end
            ResearchAssistant_InvUpdate()
        end,
    })
    table.insert(optionsData, {
        type = "dropdown",
        name = str.LW_CHAR_LABEL,
        tooltip = str.LW_CHAR_TOOLTIP,
        choices = self.lamCharNamesTable,
        choicesValues = self.lamCharIdTable,
        getFunc = function() return settings.leatherworkerCharacter[currentlyLoggedInCharId] end,
        setFunc = function(value)
            settings.leatherworkerCharacter[currentlyLoggedInCharId] = value
            ResearchAssistant_InvUpdate()
        end,
        disabled = function() return not settings.separateClothier end,
    })
    table.insert(optionsData, {
        type = "dropdown",
        name = str.CL_CHAR_LABEL,
        tooltip = str.CL_CHAR_TOOLTIP,
        choices = self.lamCharNamesTable,
        choicesValues = self.lamCharIdTable,
        getFunc = function() return settings.clothierCharacter[currentlyLoggedInCharId] end,
        setFunc = function(value)
            settings.clothierCharacter[currentlyLoggedInCharId] = value
            if not settings.separateClothier then
                settings.leatherworkerCharacter[currentlyLoggedInCharId] = value
            end
            ResearchAssistant_InvUpdate()
        end,
    })
    table.insert(optionsData, {
        type = "dropdown",
        name = str.WW_CHAR_LABEL,
        tooltip = str.WW_CHAR_TOOLTIP,
        choices = self.lamCharNamesTable,
        choicesValues = self.lamCharIdTable,
        getFunc = function() return settings.woodworkingCharacter[currentlyLoggedInCharId] end,
        setFunc = function(value)
            settings.woodworkingCharacter[currentlyLoggedInCharId] = value
            ResearchAssistant_InvUpdate()
        end,
    })
    table.insert(optionsData, {
        type = "dropdown",
        name = str.JC_CHAR_LABEL,
        tooltip = str.JC_CHAR_TOOLTIP,
        choices = self.lamCharNamesTable,
        choicesValues = self.lamCharIdTable,
        getFunc = function() return settings.jewelryCraftingCharacter[currentlyLoggedInCharId] end,
        setFunc = function(value)
            settings.jewelryCraftingCharacter[currentlyLoggedInCharId] = value
            ResearchAssistant_InvUpdate()
        end,
    })
    table.insert(optionsData, {
        type = "header",
        name = str.HIDDEN_HEADER,
    })
    table.insert(optionsData, {
        type = "checkbox",
        name = str.SHOW_RESEARCHED_LABEL,
        tooltip = str.SHOW_RESEARCHED_TOOLTIP,
        getFunc = function() return settings.showResearched end,
        setFunc = function(value)
            settings.showResearched = value
            if not value then settings.showTraitless = false end
            ResearchAssistant_InvUpdate()
        end,
    })
    table.insert(optionsData, {
        type = "checkbox",
        name = str.SHOW_TRAITLESS_LABEL,
        tooltip = str.SHOW_TRAITLESS_TOOLTIP,
        getFunc = function() return settings.showTraitless end,
        setFunc = function(value)
            settings.showTraitless = value
            ResearchAssistant_InvUpdate()
        end,
        disabled = function() return not settings.showResearched end
    })
    table.insert(optionsData, {
        type = "checkbox",
        name = str.SHOW_ORNATE_LABEL,
        tooltip = str.SHOW_ORNATE_TOOLTIP,
        getFunc = function() return settings.showUntrackedOrnate end,
        setFunc = function(value)
            settings.showUntrackedOrnate = value
            ResearchAssistant_InvUpdate()
        end,
    })
    table.insert(optionsData, {
        type = "checkbox",
        name = str.SHOW_INTRICATE_LABEL,
        tooltip = str.SHOW_INTRICATE_TOOLTIP,
        getFunc = function() return settings.showUntrackedIntricate end,
        setFunc = function(value)
            settings.showUntrackedIntricate = value
            ResearchAssistant_InvUpdate()
        end,
    })
    table.insert(optionsData, {
        type = "header",
        name = str.COLORS_HEADER,
    })
    table.insert(optionsData, {
        type = "colorpicker",
        name = str.RESEARCHABLE_LABEL,
        tooltip = str.RESEARCHABLE_TOOLTIP,
        getFunc = function()
            local r, g, b, a = HexToRGBA(settings.canResearchColor)
            return r, g, b
        end,
        setFunc = function(r, g, b)
            settings.canResearchColor = RGBAToHex(r, g, b, 1)
            ResearchAssistant_InvUpdate()
        end,
    })
    table.insert(optionsData, {
        type = "colorpicker",
        name = str.DUPLICATE_LABEL,
        tooltip = str.DUPLICATE_TOOLTIP,
        getFunc = function()
            local r, g, b, a = HexToRGBA(settings.duplicateUnresearchedColor)
            return r, g, b
        end,
        setFunc = function(r, g, b)
            settings.duplicateUnresearchedColor = RGBAToHex(r, g, b, 1)
            ResearchAssistant_InvUpdate()
        end,
    })
    table.insert(optionsData, {
        type = "colorpicker",
        name = str.RESEARCHED_LABEL,
        tooltip = str.RESEARCHED_TOOLTIP,
        getFunc = function()
            local r, g, b, a = HexToRGBA(settings.alreadyResearchedColor)
            return r, g, b
        end,
        setFunc = function(r, g, b)
            settings.alreadyResearchedColor = RGBAToHex(r, g, b, 1)
            ResearchAssistant_InvUpdate()
        end,
    })
    table.insert(optionsData, {
        type = "colorpicker",
        name = str.ORNATE_LABEL,
        tooltip = str.ORNATE_TOOLTIP,
        getFunc = function()
            local r, g, b, a = HexToRGBA(settings.ornateColor)
            return r, g, b
        end,
        setFunc = function(r, g, b)
            settings.ornateColor = RGBAToHex(r, g, b, 1)
            ResearchAssistant_InvUpdate()
        end,
    })
    table.insert(optionsData, {
        type = "colorpicker",
        name = str.INTRICATE_LABEL,
        tooltip = str.INTRICATE_TOOLTIP,
        getFunc = function()
            local r, g, b, a = HexToRGBA(settings.intricateColor)
            return r, g, b
        end,
        setFunc = function(r, g, b)
            settings.intricateColor = RGBAToHex(r, g, b, 1)
            ResearchAssistant_InvUpdate()
        end,
    })
    LAM:RegisterAddonPanel("ResearchAssistantSettingsPanel", panel)
    LAM:RegisterOptionControls("ResearchAssistantSettingsPanel", optionsData)

    CALLBACK_MANAGER:RegisterCallback("LAM-PanelControlsCreated", function()
        icon:SetParent(RA_Icon_Dropdown)
        icon:SetTexture(CAN_RESEARCH_TEXTURES[settings.textureName].texturePath)
        icon:SetDimensions(settings.textureSize, settings.textureSize)
        icon:SetAnchor(CENTER, RA_Icon_Dropdown, CENTER, 36, 0)
    end)
end

function ResearchAssistantSettings:GetLanguage()
    local lang = GetCVar("language.2")
    local supportedLanguages = {
        ["de"] = "de",
        ["en"] = "en",
        ["es"] = "es",
        ["fr"] = "fr",
        ["jp"] = "jp",
    }
    --return english if not supported
    local langSupported = supportedLanguages[lang] or "en"
    return langSupported
end
