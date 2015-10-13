--------------------------------------------------------------------------------------------------------
-- Tower AI
--------------------------------------------------------------------------------------------------------
function Spawn( entityKeyValues )
	Timers:CreateTimer(120.0, function()
		if AICore:IsTargetValid(thisEntity) then
			thisEntity:ForceKill(false)
			--print("Destroying tower for inactivity")
		end
	end)
end

-- TODO: tower death
