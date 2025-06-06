﻿--******************************************************************************************************
--** Copyright (c) 2023 FAForever
--**
--** Permission is hereby granted, free of charge, to any person obtaining a copy
--** of this software and associated documentation files (the "Software"), to deal
--** in the Software without restriction, including without limitation the rights
--** to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
--** copies of the Software, and to permit persons to whom the Software is
--** furnished to do so, subject to the following conditions:
--**
--** The above copyright notice and this permission notice shall be included in all
--** copies or substantial portions of the Software.
--**
--** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
--** IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
--** FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
--** AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
--** LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
--** OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
--** SOFTWARE.
--******************************************************************************************************

local SHeavyCavitationTorpedo = import("/lua/seraphimprojectiles.lua").SHeavyCavitationTorpedo
local SHeavyCavitationTorpedoOnEnterWater = SHeavyCavitationTorpedo.OnEnterWater
local SHeavyCavitationTorpedoOnCreate = SHeavyCavitationTorpedo.OnCreate

local SplitComponent = import('/lua/sim/projectiles/components/splitcomponent.lua').SplitComponent

local EffectTemplate = import("/lua/effecttemplates.lua")

-- upvalue scope for performance
local CreateEmitterAtEntity = CreateEmitterAtEntity

--- Heavy Cavitation Torpedo Projectile script, XSA0204
---@class SANHeavyCavitationTorpedo01 : SHeavyCavitationTorpedo, SplitComponent
SANHeavyCavitationTorpedo01 = ClassProjectile(SHeavyCavitationTorpedo, SplitComponent) {
    FxSplashScale = 0.4,
    FxTrails = {
        EffectTemplate.SHeavyCavitationTorpedoFxTrails02
    },

    FxEnterWater = EffectTemplate.WaterSplash01,

    FxSplit = {
        -- '/effects/emitters/seraphim_heayvcavitation_torpedo_projectile_hit_01_emit.bp', -- large white flash, which we exclude because it looks bad in large quantities
        '/effects/emitters/seraphim_heayvcavitation_torpedo_projectile_hit_02_emit.bp', -- soft small water splash
        '/effects/emitters/seraphim_heayvcavitation_torpedo_projectile_hit_03_emit.bp', -- large white flare
        '/effects/emitters/seraphim_heayvcavitation_torpedo_projectile_hit_04_emit.bp', -- small black flare
        '/effects/emitters/seraphim_heayvcavitation_torpedo_projectile_hit_05_emit.bp', -- soft large water splash
    },

    ChildCount = 3,
    ChildProjectileBlueprint = '/projectiles/SANHeavyCavitationTorpedo04/SANHeavyCavitationTorpedo04_proj.bp',

    ---@param self SANHeavyCavitationTorpedo01
    OnCreate = function(self)
        SHeavyCavitationTorpedoOnCreate(self)

        -- let gravity take over
        self:TrackTarget(false)
    end,

    ---@param self SANHeavyCavitationTorpedo01
    OnEnterWater = function(self)
        SHeavyCavitationTorpedoOnEnterWater(self)

        -- create a split effect
        local army = self.Army
        for _, emit in self.FxSplit do
            CreateEmitterAtEntity(self, army, emit)
        end

        -- split damage over each child
        self.DamageData.DamageAmount = self.DamageData.DamageAmount / self.ChildCount
        
        self:OnSplit(false)
        self:Destroy()
    end,
}
TypeClass = SANHeavyCavitationTorpedo01
