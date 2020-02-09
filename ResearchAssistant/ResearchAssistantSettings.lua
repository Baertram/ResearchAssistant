ResearchAssistantSettings = ZO_Object:Subclass()
if ResearchAssistant == nil then ResearchAssistant = {} end
local RA = ResearchAssistant

local LAM = LibAddonMenu2
if not LAM and LibStub then LibStub("LibAddonMenu-2.0", true) end
local settings = nil
local _

local charName = GetUnitName("player")

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

------------------------------
--OBJECT FUNCTIONS
------------------------------
function ResearchAssistantSettings:New()
    local obj = ZO_Object.New(self)
    obj:Initialize()
    return obj
end

function ResearchAssistantSettings:Initialize()
    local defaults = {
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

        --knownCharacters = { "off", "all" },
        knownCharacters = { "off" },
        blacksmithCharacter = {},
        weaponsmithCharacter = {},
        woodworkingCharacter = {},
        clothierCharacter = {},
        leatherworkerCharacter = {},
        jewelryCraftingCharacter = {},

        debug = false,

        --non settings variables
        acquiredTraits = {},
		}

    settings = ZO_SavedVars:NewAccountWide("ResearchAssistant_Settings", 2, nil, defaults)

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

    if(not settings.blacksmithCharacter[charName]) then
        settings.blacksmithCharacter[charName] = charName
    end
    if (not settings.weaponsmithCharacter[charName]) then
        settings.weaponsmithCharacter[charName] = settings.blacksmithCharacter[charName]
    end
    if (not settings.woodworkingCharacter[charName]) then
        settings.woodworkingCharacter[charName] = charName
    end
    if (not settings.clothierCharacter[charName]) then
        settings.clothierCharacter[charName] = charName
    end
    if (not settings.leatherworkerCharacter[charName]) then
        settings.leatherworkerCharacter[charName] = settings.clothierCharacter[charName]
    end
    if (not settings.jewelryCraftingCharacter[charName]) then
        settings.jewelryCraftingCharacter[charName] = charName
    end
    if (not settings.acquiredTraits[charName]) then
        settings.acquiredTraits[charName] = { }
    end

    local addme = true
    local addoff = true
    --local addany = true
    for k, v in pairs(settings.knownCharacters) do
        if v == charName then addme = false end
        if v == "off" then addoff = false end
        --if v == "any" then addany = false end
    end
    if addme then table.insert(settings.knownCharacters, charName) end
    if addoff then table.insert(settings.knownCharacters, "off") end
    --if addany then table.insert(settings.knownCharacters, "any") end

    self:CreateOptionsMenu()
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
    settings.acquiredTraits[GetUnitName("player")] = traitsTable
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
        crafter = settings.blacksmithCharacter[charName]
    elseif(craftingSkillType == CRAFTING_TYPE_BLACKSMITHING and itemType <= 7) then
        crafter = settings.weaponsmithCharacter[charName]
    elseif(craftingSkillType == CRAFTING_TYPE_CLOTHIER and itemType <= 7) then
        crafter = settings.clothierCharacter[charName]
    elseif(craftingSkillType == CRAFTING_TYPE_CLOTHIER and itemType > 7) then
        crafter = settings.leatherworkerCharacter[charName]
    elseif(craftingSkillType == CRAFTING_TYPE_WOODWORKING) then
        crafter = settings.woodworkingCharacter[charName]
    elseif(craftingSkillType == CRAFTING_TYPE_JEWELRYCRAFTING) then
        crafter = settings.jewelryCraftingCharacter[charName]
    else
        crafter = charName
    end

    if crafter == "off" then
      return
    --[[elseif crafter == "any" then
        local retarray
        for _, charname in pairs(settings.knownCharacters) do
            if charname ~= "any" and charname ~= "off" then
                for trait, pref in pairs(settings.acquiredTraits[charname]) do
                    if (retarray[trait] == nil) or (type(retarray[trait]) == "boolean" and type(pref) ~= "boolean") or retarray[trait] > pref then
                        retarray[trait] = pref
                    end
                end
            end
        end
        return retarray]]
    else
        return settings.acquiredTraits[crafter]
    end
end

function ResearchAssistantSettings:GetPlayerTraits()
    return settings.acquiredTraits[GetUnitName("player")]
end

function ResearchAssistantSettings:GetTraits()
    return settings.acquiredTraits
end

function ResearchAssistantSettings:IsMultiCharSkillOff(craftingSkillType, itemType)
    if(craftingSkillType == CRAFTING_TYPE_BLACKSMITHING and itemType > 7) then
        return settings.blacksmithCharacter[charName] == "off"
    elseif(craftingSkillType == CRAFTING_TYPE_BLACKSMITHING and itemType <= 7) then
        return settings.weaponsmithCharacter[charName] == "off"
    elseif(craftingSkillType == CRAFTING_TYPE_CLOTHIER and itemType <= 7) then
        return settings.clothierCharacter[charName] == "off"
    elseif(craftingSkillType == CRAFTING_TYPE_CLOTHIER and itemType > 7) then
        return settings.leatherworkerCharacter[charName] == "off"
    elseif(craftingSkillType == CRAFTING_TYPE_WOODWORKING) then
        return settings.woodworkingCharacter[charName] == "off"
    elseif(craftingSkillType == CRAFTING_TYPE_JEWELRYCRAFTING) then
        return settings.jewelryCraftingCharacter[charName] == "off"
    else
        return true
    end
end

function ResearchAssistantSettings:GetTrackedCharForSkill(craftingSkillType, itemType)
    if(craftingSkillType == CRAFTING_TYPE_BLACKSMITHING and itemType > 7) then
        return settings.blacksmithCharacter[charName]
    elseif(craftingSkillType == CRAFTING_TYPE_BLACKSMITHING and itemType <= 7) then
        return settings.weaponsmithCharacter[charName]
    elseif(craftingSkillType == CRAFTING_TYPE_CLOTHIER and itemType <= 7) then
        return settings.clothierCharacter[charName]
    elseif(craftingSkillType == CRAFTING_TYPE_CLOTHIER and itemType > 7) then
        return settings.leatherworkerCharacter[charName]
    elseif(craftingSkillType == CRAFTING_TYPE_WOODWORKING) then
        return settings.woodworkingCharacter[charName]
    elseif(craftingSkillType == CRAFTING_TYPE_JEWELRYCRAFTING) then
        return settings.jewelryCraftingCharacter[charName] == "off"
    else
        return "off"
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
                settings.leatherworkerCharacter[charName] = settings.clothierCharacter[charName]
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
                settings.weaponsmithCharacter[charName] = settings.blacksmithCharacter[charName]
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
        choices = settings.knownCharacters,
        getFunc = function() return settings.weaponsmithCharacter[charName] end,
        setFunc = function(value)
            settings.weaponsmithCharacter[charName] = value
            ResearchAssistant_InvUpdate()
        end,
        disabled = function() return not settings.separateSmithing end,
    })
    table.insert(optionsData, {
        type = "dropdown",
        name = str.BS_CHAR_LABEL,
        tooltip = str.BS_CHAR_TOOLTIP,
        choices = settings.knownCharacters,
        getFunc = function() return settings.blacksmithCharacter[charName] end,
        setFunc = function(value)
            settings.blacksmithCharacter[charName] = value
            if not settings.separateSmithing then
                settings.weaponsmithCharacter[charName] = value
            end
            ResearchAssistant_InvUpdate()
        end,
    })
    table.insert(optionsData, {
        type = "dropdown",
        name = str.LW_CHAR_LABEL,
        tooltip = str.LW_CHAR_TOOLTIP,
        choices = settings.knownCharacters,
        getFunc = function() return settings.leatherworkerCharacter[charName] end,
        setFunc = function(value)
            settings.leatherworkerCharacter[charName] = value
            ResearchAssistant_InvUpdate()
        end,
        disabled = function() return not settings.separateClothier end,
    })
    table.insert(optionsData, {
        type = "dropdown",
        name = str.CL_CHAR_LABEL,
        tooltip = str.CL_CHAR_TOOLTIP,
        choices = settings.knownCharacters,
        getFunc = function() return settings.clothierCharacter[charName] end,
        setFunc = function(value)
            settings.clothierCharacter[charName] = value
            if not settings.separateClothier then
                settings.leatherworkerCharacter[charName] = value
            end
            ResearchAssistant_InvUpdate()
        end,
    })
    table.insert(optionsData, {
        type = "dropdown",
        name = str.WW_CHAR_LABEL,
        tooltip = str.WW_CHAR_TOOLTIP,
        choices = settings.knownCharacters,
        getFunc = function() return settings.woodworkingCharacter[charName] end,
        setFunc = function(value)
            settings.woodworkingCharacter[charName] = value
            ResearchAssistant_InvUpdate()
        end,
    })
    table.insert(optionsData, {
        type = "dropdown",
        name = str.JC_CHAR_LABEL,
        tooltip = str.JC_CHAR_TOOLTIP,
        choices = settings.knownCharacters,
        getFunc = function() return settings.jewelryCraftingCharacter[charName] end,
        setFunc = function(value)
            settings.jewelryCraftingCharacter[charName] = value
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
