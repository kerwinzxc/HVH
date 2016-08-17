if HVHCycles == nil then
	HVHCycles = class({})

	-- SetTimeOfDay() takes a float from 0.0 to 1.0, where ~0.25 is sunrise and ~0.75 is sunset
	TIME_NEXT_DAWN    = 0.25
	TIME_NEXT_EVENING = 0.75
end

-- Cycle: Full day + night
-- Half-cycle: Either day OR night

-- Allows manual adjustment of day/night durations
function HVHCycles:SetupFastTime()
  local mode = GameRules:GetGameModeEntity()

  -- dota starts during day, but we can instead start at night
  if START_WITH_DAY then
  	mode.HalfCycleTimeRemaining = self:GenerateHalfCycleTime(START_WITH_DAY)
  else
  	self:TransitionToNextHalfCycle() -- this will set mode.HalfCycleTimeRemaining (global) for us
  end

  local t = 1.0
  Timers:CreateTimer(t, function()
    mode.HalfCycleTimeRemaining = mode.HalfCycleTimeRemaining - t
    --print(mode.HalfCycleTimeRemaining .. " seconds left.")
    if mode.HalfCycleTimeRemaining <= 0.0 then
      self:TransitionToNextHalfCycle()
    end
    return t
  end)
end

function HVHCycles:GenerateHalfCycleTime(day)
  local time,rng = 0,0
  if day then
    rng = RandomFloat(-1 * DAY_SECONDS_RANDOM_EXTRA, DAY_SECONDS_RANDOM_EXTRA)
    time = DAY_SECONDS + rng
  else
    rng = RandomFloat(-1 * NIGHT_SECONDS_RANDOM_EXTRA, NIGHT_SECONDS_RANDOM_EXTRA)
    time = NIGHT_SECONDS + rng
  end
  --print(time .. " seconds generated.")
  return time
end

function HVHCycles:TransitionToNextHalfCycle()
  local mode = GameRules:GetGameModeEntity()
  local extraSec = math.abs(mode.HalfCycleTimeRemaining) -- convert a deficit to a positive
  local nextTimeTransition = nil

  -- if it's day, generate time for night half-cycle (false)
  -- if it's night, then generate time for day half-cycle (true)
  if GameRules:IsDaytime() then
	nextTimeTransition = TIME_NEXT_EVENING
    mode.HalfCycleTimeRemaining = self:GenerateHalfCycleTime(false) + extraSec
  else
    nextTimeTransition = TIME_NEXT_DAWN
    mode.HalfCycleTimeRemaining = self:GenerateHalfCycleTime(true) + extraSec
  end

  -- finally, do the transition from current day/night to next day/night
  GameRules:SetTimeOfDay(nextTimeTransition) 
end

-- heal the NS for a small percentage of max hp
function HVHCycles:MoonRockPickup(unit)
    local hp = unit:GetMaxHealth() * NS_CHEST_HEAL
    unit:Heal(hp, unit)
    PopupHealing(unit, hp)

    local partString = "particles/items_fx/bloodstone_heal.vpcf"
    local sfxString = "n_creep_ForestTrollHighPriest.Heal"
    ParticleManager:CreateParticle(partString,  PATTACH_ABSORIGIN_FOLLOW, unit )
    unit:EmitSound(sfxString) 
end


-- grant an sun shard item, usable on phoenix
function HVHCycles:SunShardPickup(unit)
	unit:AddItemByName("item_sun_shard_hvh")
    local partString = "particles/ui/ui_generic_treasure_impact.vpcf"
    local sfxString = "ui.treasure_reveal"
    ParticleManager:CreateParticle(partString,  PATTACH_ABSORIGIN_FOLLOW, unit )
    unit:EmitSound(sfxString)
end