
require("ai/ai_core")
require("hvh_utils")

-- todo: not sure if this needs to be put on the entity since there are multiple
behaviorSystem = {}

function Spawn( entityKeyValues )

	thisEntity.Feed = function(feedDuration)
		thisEntity._FeedTime = GameRules:GetGameTime()
		thisEntity._FeedDuration = feedDuration
	end

	thisEntity.IsFed = function()
		--local currentTime = GameRules:GetGameTime() 
		--return (thisEntity._FeedTime + thisEntity._FeedDuration) <= currentTime
		-- todo: placeholder for testing
		return true
	end

	-- This stores the location we started wandering from so the dog
	-- can't just run across the entire map.
	thisEntity._WanderingOrigin = Vector(0, 0)
	thisEntity._MaxWanderingDistance = 300.0

	thisEntity._FeedDuration = 0
	-- Arbitraryly age this so the dog doesn't start fed.
	thisEntity._FeedTime = GameRules:GetGameTime() - 60

	thisEntity:SetContextThink("ThinkDog", ThinkDog, 0.25)
	behaviorSystem = AICore:CreateBehaviorSystem({
		BehaviorWander,
		BehaviorPursue,
		BehaviorSleep
	})
	HVHDebugPrint(string.format("Starting AI for %s. Entity Index: %s", thisEntity:GetUnitName(), thisEntity:GetEntityIndex()))
end

function ThinkDog()
	if thisEntity:IsNull() or not thisEntity:IsAlive() then
		return nil -- deactivate this think function
	end
	return behaviorSystem:Think()
end

--------------------------------------------------------------------------------------------------------
-- Wander behavior

BehaviorWander = 
{
	order = 
	{
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_POSITION,
		Position = thisEntity:GetAbsOrigin()
	}
}

function BehaviorWander:Evaluate()
	local isFed = thisEntity:IsFed()
	local wanderOrder = 1

	if GameRules:IsDaytime() and not isFed then
		wanderOrder = 3
	elseif GameRules:IsDaytime() then
		wanderOrder = 2
	end

	return wanderOrder
end

function BehaviorWander:Initialize()

end

function BehaviorWander:Begin()
	thisEntity._WanderingOrigin = thisEntity:GetAbsOrigin()

	self.order.Position = self:GetWanderDestination()

	-- Indicate how long the wander behavior should last
	self.endTime = GameRules:GetGameTime() + self:GetWanderDuration()
end

function BehaviorWander:Continue()
	self.order.Position = self:GetWanderDestination()
	self.endTime = GameRules:GetGameTime() + self:GetWanderDuration()
end

function BehaviorWander:End()
	-- nothing to do
end

function BehaviorWander:Think(dt)
	-- Nothing to do
end

function BehaviorWander:GetWanderDuration()
	local moveSpeed = thisEntity:GetMoveSpeedModifier(thisEntity:GetBaseMoveSpeed())
	local wanderDuration = thisEntity._MaxWanderingDistance / moveSpeed
	return wanderDuration
end

function BehaviorWander:GetWanderDestination()
	local wanderingDelta = RandomVector(thisEntity._MaxWanderingDistance)
	local wanderingDestination = thisEntity._WanderingOrigin + wanderingDelta
	return wanderingDestination
end

--------------------------------------------------------------------------------------------------------
-- Pursue behavior

BehaviorPursue = 
{
	order =
	{
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_MOVE_TO_TARGET,
		TargetIndex = nil
	}
}

function BehaviorPursue:Evaluate()
	local isFed = thisEntity:IsFed()
	local target = self:FindTarget()
	local pursueOrder = 1
	if GameRules:IsDaytime() and isFed and self:IsTargetValid(target) then
		pursueOrder = 3
	end

	return pursueOrder
end

function BehaviorPursue:Initialize()

end

function BehaviorPursue:Begin()
	local pursuitTarget = self:FindTarget()

	if self:IsTargetValid(pursuitTarget) then
		self.order.TargetIndex = pursuitTarget:GetEntityIndex()
	end

	self.endTime = GameRules:GetGameTime() + 1
end

function BehaviorPursue:Continue()
	self.endTime = GameRules:GetGameTime() + 1
end

function BehaviorPursue:End()
	self.order.TargetIndex = nil
end

function BehaviorPursue:Think(dt)
	-- No longer a valid target, so end this behavior.
	local pursuitTarget = EntIndexToHScript(self.order.TargetIndex)
	if not self:IsTargetValid(pursuitTarget) then
		--thisEntity:MoveToNPC(pursuitTarget)
	--else
		self.endTime = GameRules:GetGameTime()
	end
end

function BehaviorPursue:FindTarget()
	local units = FindUnitsInRadius(DOTA_TEAM_BADGUYS,
								 	thisEntity:GetAbsOrigin(),
									nil,
									FIND_UNITS_EVERYWHERE,
									DOTA_UNIT_TARGET_TEAM_FRIENDLY,
									DOTA_UNIT_TARGET_HERO,
									DOTA_UNIT_TARGET_FLAG_NONE,
									FIND_CLOSEST,
									false)
	return units[1]
end

function BehaviorPursue:IsTargetValid(target)
	return target and not target:IsNull() and target:IsAlive()
end

--------------------------------------------------------------------------------------------------------
-- Sleep behavior

BehaviorSleep = 
{
	order = 
	{
		UnitIndex = thisEntity:entindex(),
		OrderType = DOTA_UNIT_ORDER_HOLD_POSITION
	}
}

function BehaviorSleep:Evaluate()
	local sleepPriority = 1
	if not GameRules:IsDaytime() then
		sleepPriority = 3
	end
	return sleepPriority
end

function BehaviorSleep:Initialize()

end

function BehaviorSleep:Begin()
	self.order.OrderType = DOTA_UNIT_ORDER_HOLD_POSITION
	self.endTime = GameRules:GetGameTime() + 1
end

function BehaviorSleep:Continue()
	-- Without this, the animation will keep restarting similar to 
	-- spamming hold position on a hero.
	self.order.OrderType = DOTA_UNIT_ORDER_NONE
	self.endTime = GameRules:GetGameTime() + 1
end

function BehaviorSleep:End()
	self.order.OrderType = DOTA_UNIT_ORDER_HOLD_POSITION
end

function BehaviorSleep:Think(dt)
end