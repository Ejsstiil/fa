local UIUtil = import("/lua/ui/uiutil.lua")
local LayoutHelpers = import("/lua/maui/layouthelpers.lua")
local Group = import("/lua/maui/group.lua").Group
local Bitmap = import("/lua/maui/bitmap.lua").Bitmap
local GameCommon = import("/lua/ui/game/gamecommon.lua")
local ItemList = import("/lua/maui/itemlist.lua").ItemList
local Prefs = import("/lua/user/prefs.lua")
local options = Prefs.GetFromCurrentProfile('options')
local UnitDescriptions = import("/lua/ui/help/unitdescription.lua").Description
local WrapText = import("/lua/maui/text.lua").WrapText
local armorDefinition = import("/lua/armordefinition.lua").armordefinition

local controls = import("/lua/ui/controls.lua").Get()

local MathFloor = math.floor

View = controls.View or false
MapView = controls.MapView or false
ViewState = "full"

local enhancementSlotNames =
{
    back = "<LOC uvd_0007>Back",
    lch = "<LOC uvd_0008>LCH",
    rch = "<LOC uvd_0009>RCH",
}

function Contract()
    View:Hide()
end

function Expand()
    View:Show()
end

function GetTechLevelString(bp)
    if EntityCategoryContains(categories.TECH1, bp.BlueprintId) then
        return 1
    elseif EntityCategoryContains(categories.TECH2, bp.BlueprintId) then
        return 2
    elseif EntityCategoryContains(categories.TECH3, bp.BlueprintId) then
        return 3
    else
        return false
    end
end

function FormatTime(seconds)
    return string.format("%02d:%02d", MathFloor(seconds / 60), math.mod(seconds, 60))
end

function GetAbilityList(bp)
    local abilitiesList = {}

    return abilitiesList
end

function CheckFormat()
    if ViewState ~= Prefs.GetOption('uvd_format') then
        SetLayout()
    end
    if ViewState == "off" then
        return false
    else
        return true
    end
end

function ShowView(showUpKeep, enhancement, showecon, showShield)
    import("/lua/ui/game/unitview.lua").ShowROBox(false, false)
    View:Show()

    View.UpkeepGroup:SetHidden(not showUpKeep)

    View.BuildCostGroup:SetHidden(not showecon)
    View.UpkeepGroup:SetHidden(not showUpKeep)
    View.TimeStat:SetHidden(not showecon)
    View.HealthStat:SetHidden(not showecon)

    View.HealthStat:SetHidden(enhancement)

    View.ShieldStat:SetHidden(not showShield)

    if View.Description then
        View.Description:SetHidden(ViewState == "limited" or View.Description.Value[1]:GetText() == "")
    end
end

function ShowEnhancement(bp, bpID, iconID, iconPrefix, userUnit)
    if not CheckFormat() then
        View:Hide()
        return
    end

    -- Name / Description
    View.UnitImg:SetTexture(UIUtil.UIFile(iconPrefix..'_btn_up.dds'))

    LayoutHelpers.AtTopIn(View.UnitShortDesc, View, 10)
    View.UnitShortDesc:SetFont(UIUtil.bodyFont, 14)

    local slotName = enhancementSlotNames[string.lower(bp.Slot)]
    slotName = slotName or bp.Slot

    if bp.Name ~= nil then
        View.UnitShortDesc:SetText(LOCF("%s: %s", bp.Name, slotName))
    else
        View.UnitShortDesc:SetText(LOC(slotName))
    end
    if View.UnitShortDesc:GetStringAdvance(View.UnitShortDesc:GetText()) > View.UnitShortDesc.Width() then
        LayoutHelpers.AtTopIn(View.UnitShortDesc, View, 14)
        View.UnitShortDesc:SetFont(UIUtil.bodyFont, 10)
    end

    local showecon = true
    local showAbilities = false
    local showUpKeep = false
    local time, energy, mass
    if bp.Icon ~= nil and not string.find(bp.Name, 'Remove') then
        time, energy, mass = import("/lua/game.lua").GetConstructEconomyModel(userUnit, bp)
        time = math.max(time, 1)
        showUpKeep = DisplayResources(bp, time, energy, mass)
        View.TimeStat.Value:SetFont(UIUtil.bodyFont, 14)
        View.TimeStat.Value:SetText(string.format("%s", FormatTime(time)))
        if string.len(View.TimeStat.Value:GetText()) > 5 then
            View.TimeStat.Value:SetFont(UIUtil.bodyFont, 10)
        end
    else
        showecon = false
        if View.Description then
            View.Description:Hide()
            for i, v in View.Description.Value do
                v:SetText("")
            end
        end
    end

    if View.Description then
        -- If enhancement of preset, then remove extension. (ual0301_Engineer -> ual0301)
        if string.find(bpID, '_') then
            bpID = string.sub(bpID, 1, string.find(bpID, "_[^_]*$")-1)
        end
        WrapAndPlaceText(nil, nil, bpID.."-"..iconID, View.Description)
    end

    local showShield = false
    if bp.ShieldMaxHealth then
        showShield = true
        View.ShieldStat.Value:SetText(bp.ShieldMaxHealth)
    end

    ShowView(showUpKeep, true, showecon, showShield)
    if time == 0 and energy == 0 and mass == 0 then
        View.BuildCostGroup:Hide()
        View.TimeStat:Hide()
    end
end

function CreateLines(control, blocks)
    local i = 0
    local prevText = control.Value[1]
    for _, block in blocks do
        for _, line in block.lines do
            i = i + 1
            local text = control.Value[i]
            if text then
                text:SetText(line)
            else
                text = UIUtil.CreateText(control, line, 12, UIUtil.bodyFont)
                LayoutHelpers.Below(text, prevText)
                text.Width:Set(prevText.Width)
                text:DisableHitTest()
                control.Value[i] = text
            end
            text:SetColor(block.color)
            prevText = text
        end
    end
    if i > 0 then
        control.Height:Set(prevText.Bottom() - control.Value[1].Top() + LayoutHelpers.ScaleNumber(30))
    else
        control.Height:Set(LayoutHelpers.ScaleNumber(30))
    end
    for i = i + 1, table.getsize(control.Value) do
        control.Value[i]:SetText('')
    end
end

function DecimalToBinary(string)
    local number = tonumber(string)
    local cnt = 0
    local bitArray = {}
    while number > 0 do
        local last = math.mod(number, 2)
        bitArray[cnt] = last
        number = (number - last) / 2
        cnt = cnt + 1
    end
    return bitArray
end

function ExtractAbilityFromString(ability)
    local i = string.find(ability,'>')
    if i then
        return string.sub(ability,6,i-1)
    end
    return ability
end

function LOCStr(str)
    local id = str:lower()
    id = id:gsub(' ', '_'):gsub('%-', '_')
    return LOC('<LOC ls_'..id..'>'..str)
end

function GetShortDesc(bp)
    local desc = ''
    if bp.General.UnitName then
        desc = LOC(bp.General.UnitName)
        if desc ~='' then
            desc = desc..': '
        end
    end
    if GetTechLevelString(bp) then
        desc = desc..LOC('<LOC _Tech>')..GetTechLevelString(bp)..' '
    end
    return desc..LOC(bp.Description)
end

IsAbilityExist = {
    ability_radar = function(bp)
        return bp.Intel.RadarRadius > 0
    end,
    ability_sonar = function(bp)
        return bp.Intel.SonarRadius > 0
    end,
    ability_omni = function(bp)
        return bp.Intel.OmniRadius > 0
    end,
    ability_visionfield = function(bp)
        return bp.Intel.MaxVisionRadius > 0
    end,
    ability_scry = function(bp)
        return bp.Intel.RemoteViewingRadius > 0
           and bp.Economy.InitialRemoteViewingEnergyDrain > 0
           and bp.Economy.MaintenanceConsumptionPerSecondEnergy > 0
    end,
    ability_flying = function(bp)
        return bp.Air.CanFly
    end,
    ability_hover = function(bp)
        return bp.Physics.MotionType == 'RULEUMT_Hover'
    end,
    ability_amphibious = function(bp)
        local bitArray = DecimalToBinary(bp.Physics.BuildOnLayerCaps)
        return (bitArray[0] == 1 -- LAYER_Land
           and bitArray[1] == 1) -- LAYER_Seabed
            or bp.Physics.MotionType == 'RULEUMT_Amphibious'
    end,
    ability_aquatic = function(bp)
        local bitArray = DecimalToBinary(bp.Physics.BuildOnLayerCaps)
        return (bitArray[0] == 1 -- LAYER_Land
           and bitArray[3] == 1) -- LAYER_Water
            or bp.Physics.MotionType == 'RULEUMT_AmphibiousFloating'
    end,
    ability_sacrifice = function(bp)
        return DecimalToBinary(bp.General.CommandCaps)[16] == 1 -- RULEUCC_Sacrifice
    end,
    ability_engineeringsuite = function(bp)
        return (bp.CategoriesHash.ENGINEER or bp.CategoriesHash.ENGINEERSTATION or bp.CategoriesHash.REPAIR) and (bp.Economy.BuildRate > 0)
    end,
    ability_carrier = function(bp)
        return bp.Transport.StorageSlots > 0
           and DecimalToBinary(bp.General.CommandCaps)[8] == 1 -- RULEUCC_Transport
    end,
    ability_factory = function(bp)
        return bp.CategoriesHash.FACTORY and bp.CategoriesHash.SHOWQUEUE
    end,
    ability_upgradable = function(bp)
        return bp.General.UpgradesTo and bp.General.UpgradesTo ~= ''
    end,
    ability_tacticalmissledeflect = function(bp)
        return bp.Defense.AntiMissile.Radius > 0 and bp.Defense.AntiMissile.RedirectRateOfFire > 0
    end,
    ability_cloak = function(bp)
        return bp.Intel.Cloak
    end,
    ability_transportable = function(bp)
        return DecimalToBinary(bp.General.CommandCaps)[9] == 1 -- RULEUCC_CallTransport
    end,
    ability_transport = function(bp)
        return bp.CategoriesHash.TRANSPORTATION
           and DecimalToBinary(bp.General.CommandCaps)[8] == 1 -- RULEUCC_Transport
    end,
    ability_airstaging = function(bp)
        return bp.CategoriesHash.AIRSTAGINGPLATFORM
    end,
    ability_submersible = function(bp)
        return DecimalToBinary(bp.General.CommandCaps)[19] == 1 -- RULEUCC_Dive
    end,
    ability_jamming = function(bp)
        return bp.Intel.JammerBlips > 0 and bp.Intel.JamRadius.Max > 0
    end,
    ability_building = function(bp)
        return bp.General.BuildBones and bp.CategoriesHash.CONSTRUCTION
    end,
    ability_repairs = function(bp)
        return DecimalToBinary(bp.General.CommandCaps)[6] == 1 -- RULEUCC_Repair
    end,
    ability_reclaim = function(bp)
        return DecimalToBinary(bp.General.CommandCaps)[20] == 1 -- RULEUCC_Reclaim
    end,
    ability_capture = function(bp)
        return DecimalToBinary(bp.General.CommandCaps)[7] == 1 -- RULEUCC_Capture
    end,
    ability_personalshield = function(bp)
        return bp.Defense.Shield.PersonalShield or bp.Defense.Shield.PersonalBubble
    end,
    ability_shielddome = function(bp)
        return not(bp.Defense.Shield.PersonalShield or bp.Defense.Shield.PersonalBubble) and (bp.Defense.Shield.ShieldSize > 0)
    end,
    ability_personalstealth = function(bp)
        return bp.Intel.RadarStealth and bp.Intel.RadarStealthFieldRadius <= 0
    end,
    ability_stealthfield = function(bp)
        return bp.Intel.RadarStealthFieldRadius > 0
    end,
    ability_stealth_sonar = function(bp)
        return bp.Intel.SonarStealth and bp.Intel.SonarStealthFieldRadius <= 0
    end,
    ability_stealth_sonarfield = function(bp)
        return bp.Intel.SonarStealthFieldRadius > 0
    end,
    ability_customizable = function(bp)
        return not table.empty(bp.Enhancements)
    end,
    ability_notcap = function(bp)
        return bp.CategoriesHash.COMMAND or bp.CategoriesHash.SUBCOMMANDER or bp.BlueprintId == 'uaa0310'
    end,
    ability_massive = function(bp)
        return bp.Display.MovementEffects.Land.Footfall.Damage.Amount > 0
           and bp.Display.MovementEffects.Land.Footfall.Damage.Radius > 0
    end,
    ability_personal_teleporter = function(bp)
        return DecimalToBinary(bp.General.CommandCaps)[12] == 1 -- RULEUCC_Teleport
    end,
    ability_snipemode_prioritizes_acu = function(bp)
        return bp.CategoriesHash.SNIPEMODE
    end
}

GetAbilityDesc = {
    ability_radar = function(bp)
        return LOCF('<LOC uvd_Radius>', bp.Intel.RadarRadius)
    end,
    ability_sonar = function(bp)
        return LOCF('<LOC uvd_Radius>', bp.Intel.SonarRadius)
    end,
    ability_omni = function(bp)
        return LOCF('<LOC uvd_Radius>', bp.Intel.OmniRadius)
    end,
    ability_visionfield = function(bp)
        return LOCF('<LOC uvd_VisionField>', bp.Intel.MaxVisionRadius)
    end,
    ability_scry = function(bp)
        return LOCF('<LOC uvd_Scry>', bp.Intel.RemoteViewingRadius, bp.Economy.InitialRemoteViewingEnergyDrain, bp.Economy.MaintenanceConsumptionPerSecondEnergy)
    end,
    ability_flying = function(bp)
        return LOCF("<LOC uvd_0011>Speed: %0.1f, Turning: %0.1f", bp.Air.MaxAirspeed, bp.Air.TurnSpeed)
    end,
    ability_carrier = function(bp)
        return LOCF('<LOC uvd_StorageSlots>', bp.Transport.StorageSlots)
    end,
    ability_factory = function(bp)
        return LOCF('<LOC uvd_BuildRate>', bp.Economy.BuildRate)
    end,
    ability_upgradable = function(bp)
        return GetShortDesc(__blueprints[bp.General.UpgradesTo])
    end,
    ability_tacticalmissledeflect = function(bp)
        return LOCF('<LOC uvd_Radius>', bp.Defense.AntiMissile.Radius)..', '
             ..LOCF('<LOC uvd_FireRate>', 1 / bp.Defense.AntiMissile.RedirectRateOfFire)
    end,
    --[[ability_transportable = function(bp)
        return LOCF('<LOC uvd_UnitSize>', bp.Transport.TransportClass)
    end,]]
    ability_transport = function(bp)
        local text = LOC('<LOC uvd_Capacity>')
        return bp.Transport and bp.Transport.Class1Capacity and text..bp.Transport.Class1Capacity
            or bp.CategoriesHash.TECH1 and text..'≈6'
            or bp.CategoriesHash.TECH2 and text..'≈12'
            or bp.CategoriesHash.TECH3 and text..'≈28'
            or ''
    end,
    ability_airstaging = function(bp)
        return LOCF('<LOC uvd_RepairRate>', bp.Transport.RepairRate)..', '
             ..LOCF('<LOC uvd_DockingSlots>', bp.Transport.DockingSlots)
    end,
    ability_jamming = function(bp)
        return LOCF('<LOC uvd_Radius>', bp.Intel.JamRadius.Max)..', '
             ..LOCF('<LOC uvd_Blips>', bp.Intel.JammerBlips)
    end,
    ability_personalshield = function(bp)
        return LOCF('<LOC uvd_RegenRate>', bp.Defense.Shield.ShieldRegenRate)..', '
             ..LOCF('<LOC uvd_RechargeTime>', bp.Defense.Shield.ShieldRechargeTime)
    end,
    ability_shielddome = function(bp)
        return LOCF('<LOC uvd_Radius>', bp.Defense.Shield.ShieldSize/2)..', '
             ..LOCF('<LOC uvd_RegenRate>', bp.Defense.Shield.ShieldRegenRate)..', '
             ..LOCF('<LOC uvd_RechargeTime>', bp.Defense.Shield.ShieldRechargeTime)
    end,
    ability_stealthfield = function(bp)
        return LOCF('<LOC uvd_Radius>', bp.Intel.RadarStealthFieldRadius)
    end,
    ability_stealth_sonarfield = function(bp)
        return LOCF('<LOC uvd_Radius>', bp.Intel.SonarStealthFieldRadius)
    end,
    ability_customizable = function(bp)
        local cnt = 0
        for _, v in bp.Enhancements do
            if v.RemoveEnhancements or (not v.Slot) then continue end
            cnt = cnt + 1
        end
        return LOCF('<LOC uvd_0016>Enhancements: %d', cnt)
    end,
    ability_massive = function(bp)
        return string.format(LOC('<LOC uvd_0010>Damage: %.7g, Splash: %.3g'),
            bp.Display.MovementEffects.Land.Footfall.Damage.Amount,
            bp.Display.MovementEffects.Land.Footfall.Damage.Radius)
    end,
    ability_personal_teleporter = function(bp)
        if not bp.General.TeleportDelay then return '' end
        return LOCF('<LOC uvd_Delay>', bp.General.TeleportDelay)
    end
}

---@param bp UnitBlueprint
---@param builder UserUnit
---@param descID string
---@param control Control
function WrapAndPlaceText(bp, builder, descID, control)
    local lines = {}
    local blocks = {}
    --Unit description
    local text = LOC(UnitDescriptions[descID])
    if text and text ~='' then
        table.insert(blocks, {color = UIUtil.fontColor,
            lines = WrapText(text, control.Value[1].Width(), function(text)
                return control.Value[1]:GetStringAdvance(text)
            end)})
        table.insert(blocks, {color = UIUtil.bodyColor, lines = {''}})
    end

    if builder and bp.EnhancementPresetAssigned then
        table.insert(lines, LOC('<LOC uvd_upgrades>')..':')
        for _, v in bp.EnhancementPresetAssigned.Enhancements do
            table.insert(lines, '    '..LOC(bp.Enhancements[v].Name))
        end
        table.insert(blocks, {color = 'FFB0FFB0', lines = lines})
    elseif bp then
        --Get not autodetected abilities
        if bp.Display.Abilities then
            for _, id in bp.Display.Abilities do
                local ability = ExtractAbilityFromString(id)
                if not IsAbilityExist[ability] then
                    table.insert(lines, LOC(id))
                end
            end
        end
        --Autodetect abilities exclude engineering
        for id, func in IsAbilityExist do
            if (id ~= 'ability_engineeringsuite') and (id ~= 'ability_building') and
               (id ~= 'ability_repairs') and (id ~= 'ability_reclaim') and (id ~= 'ability_capture') and func(bp) then
                local ability = LOC('<LOC '..id..'>')
                if GetAbilityDesc[id] then
                    local desc = GetAbilityDesc[id](bp)
                    if desc ~= '' then
                        ability = ability..' - '..desc
                    end
                end
                table.insert(lines, ability)
            end
        end
        if not table.empty(lines) then
            table.insert(lines, '')
        end
        table.insert(blocks, {color = 'FF7FCFCF', lines = lines})
        --Autodetect engineering abilities
        if IsAbilityExist.ability_engineeringsuite(bp) then
            lines = {}
            table.insert(lines, LOC('<LOC '..'ability_engineeringsuite'..'>')
                ..' - '..LOCF('<LOC uvd_BuildRate>', bp.Economy.BuildRate)
                ..', '..LOCF('<LOC uvd_Radius>', bp.Economy.MaxBuildDistance))
            local orders = LOC('<LOC order_0011>')
            if IsAbilityExist.ability_building(bp) then
                orders = orders..', '..LOC('<LOC order_0001>')
            end
            if IsAbilityExist.ability_repairs(bp) then
                orders = orders..', '..LOC('<LOC order_0005>')
            end
            if IsAbilityExist.ability_reclaim(bp) then
                orders = orders..', '..LOC('<LOC order_0006>')
            end
            if IsAbilityExist.ability_capture(bp) then
                orders = orders..', '..LOC('<LOC order_0007>')
            end
            table.insert(lines, orders)
            table.insert(lines, '')
            table.insert(blocks, {color = 'FFFFFFB0', lines = lines})
        end

        if options.gui_render_armament_detail == 1 then
            --Armor values
            lines = {}
            local armorType = bp.Defense.ArmorType
            if armorType and armorType ~= '' then
                local spaceWidth = control.Value[1]:GetStringAdvance(' ')
                local headerString = LOC('<LOC uvd_ArmorType>')..LOC('<LOC at_'..armorType..'>')
                local spaceCount = (195 - control.Value[1]:GetStringAdvance(headerString)) / spaceWidth
                local takesAdjustedDamage = false
                for _, armor in armorDefinition do
                    if armor[1] == armorType then
                        local row = 0
                        local armorDetails = ''
                        local elemCount = table.getsize(armor)
                        for i = 2, elemCount do
                            if string.find(armor[i], '1.0') > 0 then continue end
                            takesAdjustedDamage = true
                            local armorName = armor[i]
                            armorName = string.sub(armorName, 1, string.find(armorName, ' ') - 1)
                            armorName = LOC('<LOC an_'..armorName..'>')..' - '..string.format('%0.1f', tonumber(armor[i]:sub(armorName:len() + 2, armor[i]:len())) * 100)
                            if row < 1 then
                                armorDetails = armorName
                                row = 1
                            else
                                local spaceCount = (195 - control.Value[1]:GetStringAdvance(armorDetails)) / spaceWidth
                                armorDetails = armorDetails..string.rep(' ', spaceCount)..armorName
                                table.insert(lines, armorDetails)
                                armorDetails = ''
                                row = 0
                            end
                        end
                        if armorDetails ~= '' then
                            table.insert(lines, armorDetails)
                        end
                    end
                end
                table.insert(lines, '')

                if takesAdjustedDamage then
                    headerString = headerString..string.rep(' ', spaceCount)..LOC('<LOC uvd_DamageTaken>')
                end
                table.insert(lines, 1, headerString)

                table.insert(blocks, {color = 'FF7FCFCF', lines = lines})
            end
            --Weapons
            if not table.empty(bp.Weapon) then
                local weapons = {upgrades = {normal = {}, death = {}},
                                    basic = {normal = {}, death = {}}}
                local totalWeaponCount = 0
                for _, weapon in bp.Weapon do
                    if not weapon.WeaponCategory then continue end
                    local dest = weapons.basic
                    if weapon.EnabledByEnhancement then
                        dest = weapons.upgrades
                    end
                    if (weapon.FireOnDeath) or (weapon.WeaponCategory == 'Death') then
                        dest = dest.death
                    else
                        dest = dest.normal
                    end
                    if dest[weapon.DisplayName] then
                        dest[weapon.DisplayName].count = dest[weapon.DisplayName].count + 1
                    else
                        dest[weapon.DisplayName] = {info = weapon, count = 1}
                    end
                    if not dest.death then
                        totalWeaponCount = totalWeaponCount + 1
                    end
                end
                for k, v in weapons do
                    if not table.empty(v.normal) or not table.empty(v.death) then
                        table.insert(blocks, {color = UIUtil.fontColor, lines = {LOC('<LOC uvd_'..k..'>')..':'}})
                    end
                    local totalDirectFireDPS = 0
                    local totalIndirectFireDPS = 0
                    local totalNavalDPS = 0
                    local totalAADPS = 0
                    for name, weapon in v.normal do
                        local info = weapon.info
                        local weaponDetails1 = LOCStr(name)..' ('..LOCStr(info.WeaponCategory)..') '
                        if info.ManualFire then
                            weaponDetails1 = weaponDetails1..LOC('<LOC uvd_ManualFire>')
                        end
                        local weaponDetails2
                        if info.NukeInnerRingDamage then
                            weaponDetails2 = string.format(LOC('<LOC uvd_0014>Damage: %.8g - %.8g, Splash: %.3g - %.3g')..', '..LOC('<LOC uvd_Range>'),
                                info.NukeInnerRingDamage + info.NukeOuterRingDamage, info.NukeOuterRingDamage,
                                info.NukeInnerRingRadius, info.NukeOuterRingRadius, info.MinRadius, info.MaxRadius)
                        else
                            --DPS Calculations
                            local Damage = info.Damage
                            if info.DamageToShields then
                                Damage = Damage + info.DamageToShields
                            end
                            if info.BeamLifetime > 0 then
                                Damage = Damage * (1 + MathFloor(MATH_IRound(info.BeamLifetime*10)/(MATH_IRound(info.BeamCollisionDelay*10)+1)))
                            else
                                Damage = Damage * (info.DoTPulses or 1) + (info.InitialDamage or 0)
                                local ProjectilePhysics = __blueprints[info.ProjectileId].Physics
                                while ProjectilePhysics do
                                    Damage = Damage * (ProjectilePhysics.Fragments or 1)
                                    ProjectilePhysics = __blueprints[string.lower(ProjectilePhysics.FragmentId or '')].Physics
                                end
                            end

                            --Simulate the firing cycle to get the reload time.
                            local CycleProjs = 0 --Projectiles fired per cycle
                            local CycleTime = 0

                            --Various delays need to be adapted to game tick format.
                            local FiringCooldown = math.max(0.1, MATH_IRound(10 / info.RateOfFire) / 10)
                            local ChargeTime = info.RackSalvoChargeTime or 0
                            if ChargeTime > 0 then
                                ChargeTime = math.max(0.1, MATH_IRound(10 * ChargeTime) / 10)
                            end
                            local MuzzleDelays = info.MuzzleSalvoDelay or 0
                            if MuzzleDelays > 0 then
                                MuzzleDelays = math.max(0.1, MATH_IRound(10 * MuzzleDelays) / 10)
                            end
                            local MuzzleChargeDelay = info.MuzzleChargeDelay or 0
                            if MuzzleChargeDelay and MuzzleChargeDelay > 0 then
                                MuzzleDelays = MuzzleDelays + math.max(0.1, MATH_IRound(10 * MuzzleChargeDelay) / 10)
                            end
                            local ReloadTime = info.RackSalvoReloadTime or 0
                            if ReloadTime > 0 then
                                ReloadTime = math.max(0.1, MATH_IRound(10 * ReloadTime) / 10)
                            end

                            -- Keep track that the firing cycle has a constant rate
                            local singleShot = true
                            --OnFire is called from FireReadyState at this point, so we need to track time
                            --to know how much the fire rate cooldown has progressed during our fire cycle.
                            local SubCycleTime = 0
                            local RackBones = info.RackBones
                            if RackBones then --Teleport damage will not have a rack bone
                                --Save the rack count so we can correctly calculate the final rack's fire cooldown
                                local RackCount = table.getsize(RackBones)
                                for index, Rack in RackBones do
                                    local MuzzleCount = info.MuzzleSalvoSize
                                    if info.MuzzleSalvoDelay == 0 then
                                        MuzzleCount = table.getsize(Rack.MuzzleBones)
                                    end
                                    if MuzzleCount > 1 or info.RackFireTogether and RackCount > 1 then singleShot = false end
                                    CycleProjs = CycleProjs + MuzzleCount

                                    SubCycleTime = SubCycleTime + MuzzleCount * MuzzleDelays
                                    if not info.RackFireTogether and index ~= RackCount then
                                        if FiringCooldown <= SubCycleTime + ChargeTime then
                                            CycleTime = CycleTime + SubCycleTime + ChargeTime + math.max(0.1, FiringCooldown - SubCycleTime - ChargeTime)
                                        else
                                            CycleTime = CycleTime + FiringCooldown
                                        end
                                        SubCycleTime = 0
                                    end
                                end
                            end
                            if FiringCooldown <= (SubCycleTime + ChargeTime + ReloadTime) then
                                CycleTime = CycleTime + SubCycleTime + ReloadTime + ChargeTime + math.max(0.1, FiringCooldown - SubCycleTime - ChargeTime - ReloadTime)
                            else
                                CycleTime = CycleTime + FiringCooldown
                            end

                            local DPS = 0
                            if not info.ManualFire and info.WeaponCategory ~= 'Kamikaze' and info.WeaponCategory ~= 'Defense' then
                                --Round DPS, or else it gets floored in string.format.
                                DPS = MATH_IRound(Damage * CycleProjs / CycleTime)
                                weaponDetails1 = weaponDetails1..LOCF('<LOC uvd_DPS>', DPS)
                                -- Do not calulcate the DPS total if the unit only has one valid weapon.
                                if totalWeaponCount > 1 then
                                    if (info.WeaponCategory == 'Direct Fire' or info.WeaponCategory == 'Direct Fire Naval' or info.WeaponCategory == 'Direct Fire Experimental') and not info.IgnoreIfDisabled then
                                        totalDirectFireDPS = totalDirectFireDPS + DPS * weapon.count
                                    elseif info.WeaponCategory == 'Indirect Fire' or info.WeaponCategory == 'Missile' or info.WeaponCategory == 'Artillery' or info.WeaponCategory == 'Bomb' then
                                        totalIndirectFireDPS = totalIndirectFireDPS + DPS * weapon.count
                                    elseif info.WeaponCategory == 'Anti Navy' then
                                        totalNavalDPS = totalNavalDPS + DPS * weapon.count
                                    elseif info.WeaponCategory == 'Anti Air' then
                                        totalAADPS = totalAADPS + DPS * weapon.count
                                    end
                                end
                            end

                            -- Avoid saying a unit fires a salvo when it in fact has a constant rate of fire
                            if singleShot and ReloadTime == 0 and CycleProjs > 1 then
                                CycleTime = CycleTime / CycleProjs
                                CycleProjs = 1
                            end

                            if CycleProjs > 1 then
                                weaponDetails2 = string.format(LOC('<LOC uvd_0015>Damage: %.8g x%d, Splash: %.3g')..', '..LOC('<LOC uvd_Range>')..', '..LOC('<LOC uvd_Reload>'),
                                Damage, CycleProjs, info.DamageRadius, info.MinRadius, info.MaxRadius, CycleTime)
                            -- Do not display Reload stats for Kamikaze weapons
                            elseif info.WeaponCategory == 'Kamikaze' then
                                weaponDetails2 = string.format(LOC('<LOC uvd_0010>Damage: %.7g, Splash: %.3g')..', '..LOC('<LOC uvd_Range>'),
                                Damage, info.DamageRadius, info.MinRadius, info.MaxRadius)
                            -- Do not display 'Range' and Reload stats for 'Teleport in' weapons
                            elseif info.WeaponCategory == 'Teleport' then
                                weaponDetails2 = string.format(LOC('<LOC uvd_0010>Damage: %.7g, Splash: %.3g'),
                                Damage, info.DamageRadius)
                            else
                                weaponDetails2 = string.format(LOC('<LOC uvd_0010>Damage: %.7g, Splash: %.3g')..', '..LOC('<LOC uvd_Range>')..', '..LOC('<LOC uvd_Reload>'),
                                Damage, info.DamageRadius, info.MinRadius, info.MaxRadius, CycleTime)
                            end

                        end
                        if weapon.count > 1 then
                            weaponDetails1 = weaponDetails1..' x'..weapon.count
                        end
                        table.insert(blocks, {color = UIUtil.fontColor, lines = {weaponDetails1}})

                        if info.DamageType == 'Overcharge' then
                            table.insert(blocks, {color = 'FF5AB34B', lines = {weaponDetails2}}) -- Same color as auto-overcharge highlight (autocast_green.dds)
                        elseif info.WeaponCategory == 'Kamikaze' then
                            table.insert(blocks, {color = 'FFFF2C2C', lines = {weaponDetails2}})
                        else
                            table.insert(blocks, {color = 'FFFFB0B0', lines = {weaponDetails2}})
                        end

                        if info.EnergyRequired > 0 and info.EnergyDrainPerSecond > 0 then
                            local weaponDetails3 = string.format(LOC('<LOC uvd_cost>Charge Cost: -%d E (-%d E/s)'), info.EnergyRequired, info.EnergyDrainPerSecond)
                            table.insert(blocks, {color = 'FFFF9595', lines = {weaponDetails3}})
                        end

                        local ProjectileEco = __blueprints[info.ProjectileId].Economy
                        if ProjectileEco and (ProjectileEco.BuildCostMass > 0 or ProjectileEco.BuildCostEnergy > 0) and ProjectileEco.BuildTime > 0 then
                            local weaponDetails4 = string.format(LOC('<LOC uvd_missile>Missile Cost: %d M, %d E, %d BT'), ProjectileEco.BuildCostMass, ProjectileEco.BuildCostEnergy, ProjectileEco.BuildTime)
                            table.insert(blocks, {color = 'FFFF9595', lines = {weaponDetails4}})
                        end
                    end
                    lines = {}
                    for name, weapon in v.death do
                        local info = weapon.info
                        local weaponDetails = LOCStr(name)..' ('..LOCStr(info.WeaponCategory)..') '
                        if info.NukeInnerRingDamage then
                            weaponDetails = weaponDetails..LOCF('<LOC uvd_0014>Damage: %.8g - %.8g, Splash: %.3g - %.3g',
                                info.NukeInnerRingDamage + info.NukeOuterRingDamage, info.NukeOuterRingDamage,
                                info.NukeInnerRingRadius, info.NukeOuterRingRadius)
                        else
                            weaponDetails = weaponDetails..LOCF('<LOC uvd_0010>Damage: %.7g, Splash: %.3g',
                                info.Damage, info.DamageRadius)
                        end
                        if weapon.count > 1 then
                            weaponDetails = weaponDetails..' x'..weapon.count
                        end
                        table.insert(lines, weaponDetails)
                        table.insert(blocks, {color = 'FFFF0000', lines = lines})
                    end
                    
                    -- Only display the totalDPS stats if they are greater than 0.
                    -- Prevent the totalDPS stats from being displayed under the 'Upgrades' tab and avoid the doubling of empty lines.
                    local upgradesAvailable = not table.empty(weapons.upgrades.normal) or not table.empty(weapons.upgrades.death)
                    if k == 'basic' then
                        if totalDirectFireDPS > 0 then
                            table.insert(blocks, {color = 'FFA600', lines = {LOCF('<LOC uvd_0018>', totalDirectFireDPS)}})
                        end
                        if totalIndirectFireDPS > 0 then
                            table.insert(blocks, {color = 'FFA600', lines = {LOCF('<LOC uvd_0019>', totalIndirectFireDPS)}})
                        end
                        if totalNavalDPS > 0 then
                            table.insert(blocks, {color = 'FFA600', lines = {LOCF('<LOC uvd_0020>', totalNavalDPS)}})
                        end
                        if totalAADPS > 0 then
                            table.insert(blocks, {color = 'FFA600', lines = {LOCF('<LOC uvd_0021>', totalAADPS)}})
                        end
                        if not upgradesAvailable then
                            table.insert(blocks, {color = UIUtil.fontColor, lines = {''}}) -- Empty line
                        end
                    end
                    -- Avoid the doubling of empty lines when the unit has upgrades.
                    if upgradesAvailable then
                        table.insert(blocks, {color = UIUtil.fontColor, lines = {''}}) -- Empty line
                    end
                end
            end
        end
        --Other parameters
        lines = {}
        table.insert(lines, LOCF("<LOC uvd_0013>Vision: %d, Underwater Vision: %d, Regen: %.3g, Cap Cost: %.3g",
            bp.Intel.VisionRadius, bp.Intel.WaterVisionRadius, bp.Defense.RegenRate, bp.General.CapCost))

        if (bp.Physics.MotionType ~= 'RULEUMT_Air' and bp.Physics.MotionType ~= 'RULEUMT_None')
        or (bp.Physics.AltMotionType ~= 'RULEUMT_Air' and bp.Physics.AltMotionType ~= 'RULEUMT_None') then
            table.insert(lines, LOCF("<LOC uvd_0012>Speed: %.3g, Reverse: %.3g, Acceleration: %.3g, Turning: %d",
                bp.Physics.MaxSpeed, bp.Physics.MaxSpeedReverse, bp.Physics.MaxAcceleration, bp.Physics.TurnRate))
        end
        
        -- Display the TransportSpeedReduction stat in the UI.
        -- Naval units and land experimentals also have this stat, but it since it is not relevant for non-modded games, we do not display it by default.
        -- If a mod wants to display the TransportSpeedReduction stat for naval units or experimentals, this file can be hooked.
        if bp.Physics.TransportSpeedReduction and not (bp.CategoriesHash.NAVAL or bp.CategoriesHash.EXPERIMENTAL) then
            table.insert(lines, LOCF("<LOC uvd_0017>Transport Speed Reduction: %.3g",
            bp.Physics.TransportSpeedReduction))
        end

        table.insert(blocks, {color = 'FFB0FFB0', lines = lines})
    end
    CreateLines(control, blocks)
end

function Show(bp, builderUnit, bpID)
    if not CheckFormat() then
        View:Hide()
        return
    end

    -- Name / Description
    LayoutHelpers.AtTopIn(View.UnitShortDesc, View, 10)
    View.UnitShortDesc:SetFont(UIUtil.bodyFont, 14)

    View.UnitShortDesc:SetText(GetShortDesc(bp))

    local scale = View.UnitShortDesc.Width() / View.UnitShortDesc.TextAdvance()
    if scale < 1 then
        LayoutHelpers.AtTopIn(View.UnitShortDesc, View, 10 / scale)
        View.UnitShortDesc:SetFont(UIUtil.bodyFont, 14 * scale)
    end
    local showecon = true
    local showUpKeep = false
    local showAbilities = false
    if builderUnit ~= nil then
        -- Differential upgrading. Check to see if building this would be an upgrade
        local targetBp = bp
        local builderBp = builderUnit:GetBlueprint()

        local performUpgrade = false

        if targetBp.General.UpgradesFrom == builderBp.BlueprintId then
            performUpgrade = true
        elseif targetBp.General.UpgradesFrom == builderBp.General.UpgradesTo then
            performUpgrade = true
        elseif targetBp.General.UpgradesFromBase ~= "none" then
            -- try testing against the base
            if targetBp.General.UpgradesFromBase == builderBp.BlueprintId then
                performUpgrade = true
            elseif targetBp.General.UpgradesFromBase == builderBp.General.UpgradesFromBase then
                performUpgrade = true
            end
        end

        local time, energy, mass

        if performUpgrade then
            time, energy, mass = import("/lua/game.lua").GetConstructEconomyModel(builderUnit, bp.Economy, builderBp.Economy)
        else
            time, energy, mass = import("/lua/game.lua").GetConstructEconomyModel(builderUnit, bp.Economy)
        end

        time = math.max(time, 1)
        showUpKeep = DisplayResources(bp, time, energy, mass)
        View.TimeStat.Value:SetFont(UIUtil.bodyFont, 14)
        View.TimeStat.Value:SetText(string.format("%s", FormatTime(time)))
        if string.len(View.TimeStat.Value:GetText()) > 5 then
            View.TimeStat.Value:SetFont(UIUtil.bodyFont, 10)
        end
    else
        showecon = false
    end

    -- Health stat
    View.HealthStat.Value:SetText(string.format("%d", bp.Defense.MaxHealth))

    if View.Description then
        WrapAndPlaceText(bp, builderUnit, bpID, View.Description)
    end
    local showShield = false
    if bp.Defense.Shield and bp.Defense.Shield.ShieldMaxHealth then
        showShield = true
        View.ShieldStat.Value:SetText(bp.Defense.Shield.ShieldMaxHealth)
    end

    local iconName = GameCommon.GetCachedUnitIconFileNames(bp)
    View.UnitImg:SetTexture(iconName)
    LayoutHelpers.SetDimensions(View.UnitImg, 46, 46)

    ShowView(showUpKeep, false, showecon, showShield)
end

function DisplayResources(bp, time, energy, mass)
    -- Cost Group
    if time > 0 then
        local consumeEnergy = -energy / time
        local consumeMass = -mass / time
        View.BuildCostGroup.EnergyValue:SetText(string.format("%d (%d)",-energy,consumeEnergy))
        View.BuildCostGroup.MassValue:SetText(string.format("%d (%d)",-mass,consumeMass))

        View.BuildCostGroup.EnergyValue:SetColor("FFF05050")
        View.BuildCostGroup.MassValue:SetColor("FFF05050")
    end

    -- Upkeep Group
    local upkeepEnergy, upkeepMass = GetUpkeep(bp)
    local showUpkeep = false
    if upkeepEnergy ~= 0 or upkeepMass ~= 0 then
        View.UpkeepGroup.Label:SetText(LOC("<LOC uvd_0002>Yield"))
        View.UpkeepGroup.EnergyValue:SetText(string.format("%d",upkeepEnergy))
        View.UpkeepGroup.MassValue:SetText(string.format("%d",upkeepMass))
        if upkeepEnergy >= 0 then
            View.UpkeepGroup.EnergyValue:SetColor("FF50F050")
        else
            View.UpkeepGroup.EnergyValue:SetColor("FFF05050")
        end

        if upkeepMass >= 0 then
            View.UpkeepGroup.MassValue:SetColor("FF50F050")
        else
            View.UpkeepGroup.MassValue:SetColor("FFF05050")
        end
        showUpkeep = true
    elseif bp.Economy and (bp.Economy.StorageEnergy ~= 0 or bp.Economy.StorageMass ~= 0) then
        View.UpkeepGroup.Label:SetText(LOC("<LOC uvd_0006>Storage"))
        local upkeepEnergy = bp.Economy.StorageEnergy or 0
        local upkeepMass = bp.Economy.StorageMass or 0
        View.UpkeepGroup.EnergyValue:SetText(string.format("%d",upkeepEnergy))
        View.UpkeepGroup.MassValue:SetText(string.format("%d",upkeepMass))
        View.UpkeepGroup.EnergyValue:SetColor("FF50F050")
        View.UpkeepGroup.MassValue:SetColor("FF50F050")
        showUpkeep = true
    end

    return showUpkeep
end

function GetUpkeep(bp)
    local upkeepEnergy = (bp.Economy.ProductionPerSecondEnergy or 0) - (bp.Economy.MaintenanceConsumptionPerSecondEnergy or 0)
    local upkeepMass = (bp.Economy.ProductionPerSecondMass or 0) - (bp.Economy.MaintenanceConsumptionPerSecondMass or 0)
    upkeepEnergy = upkeepEnergy + (bp.ProductionPerSecondEnergy or 0) - (bp.MaintenanceConsumptionPerSecondEnergy or 0)
    upkeepMass = upkeepMass + (bp.ProductionPerSecondMass or 0) - (bp.MaintenanceConsumptionPerSecondMass or 0)

    if bp.EnhancementPresetAssigned then
        for _, v in bp.EnhancementPresetAssigned.Enhancements do
            local Enh = bp.Enhancements[v]
            upkeepEnergy = upkeepEnergy + (Enh.ProductionPerSecondEnergy or 0) - (Enh.MaintenanceConsumptionPerSecondEnergy or 0)
            upkeepMass = upkeepMass + (Enh.ProductionPerSecondMass or 0) - (Enh.MaintenanceConsumptionPerSecondMass or 0)
        end
    end

    return upkeepEnergy, upkeepMass
end

function OnNIS()
    if View then
        View:Hide()
    end
end

function Hide()
    View:Hide()
end

function SetLayout()
    import(UIUtil.GetLayoutFilename('unitviewDetail')).SetLayout()
end

function SetupUnitViewLayout(parent)
    if View then
        View:Destroy()
        View = nil
    end
    MapView = parent
    controls.MapView = MapView
    SetLayout()
    controls.View = View
    View:Hide()
    View:DisableHitTest(true)
end
