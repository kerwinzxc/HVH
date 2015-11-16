if HVHSniperSelect == nil then
	HVHSniperSelect = class({})
end

SNIPER_SELECT_REASON_KILLED = 0
SNIPER_SELECT_REASON_FREEBIE = 1

function HVHSniperSelect:Setup()
	CustomGameEventManager:RegisterListener("sniper_select_choose_ability", Dynamic_Wrap(HVHSniperSelect, "ChooseAbility"))
end

function HVHSniperSelect:Check(killer, killed)
	local teamKiller = killer:GetTeam()
	local teamKilled = killed:GetTeam()
	--print(killer:GetUnitName() .. " owned by " .. killer:GetPlayerOwnerID())

	-- If Team Sniper kills NightStalker, we have a success. Possibilities:
	---- 1. Sniper killed NS and has empty ability slot. That player gets the prompt.
	---- 2. Sniper's minion killed NS. Find owner of minion, and check that player's hero, as above.
	---- 3. Hound kills NS. Pick random eligible teammate.
	---- 4. Sniper no longer has an empty ability slot. Pick random eligible teammate.
	if teamKiller == DOTA_TEAM_GOODGUYS and teamKilled == DOTA_TEAM_BADGUYS then
		local player = killer:GetPlayerOwner()
		if player then
			killer = player:GetAssignedHero()
		end

		if killer:IsRealHero() and self:HasEmptySlot(killer) then
			self:MakeMenuVisible(player, SNIPER_SELECT_REASON_KILLED)
		else
			self:MakeMenuVisibleToRandomEligibleTeammate()
		end
	end
end

function HVHSniperSelect:HasEmptySlot(hero)
	local ability = hero:FindAbilityByName("sniper_empty")
	
	if ability then
		return true
	else
		return false
	end
end

function HVHSniperSelect:MakeMenuVisible(player, sniper_select_reason)
	--print("Making menu visible to player ".. player:GetPlayerID())
	CustomGameEventManager:Send_ServerToPlayer(player, "sniper_select_make_visible", { reason = sniper_select_reason})
end

function HVHSniperSelect:MakeMenuVisibleToRandomEligibleTeammate()
	local heroList = HeroList:GetAllHeroes()
	local validSniperList = {}

	for _,hero in pairs(heroList) do
		if hero:GetTeam() == DOTA_TEAM_GOODGUYS and self:HasEmptySlot(hero) then
			table.insert(validSniperList, hero)
		end
	end

	if #validSniperList > 0 then
		local r = RandomInt(1, #validSniperList)
		self:MakeMenuVisible(validSniperList[r], SNIPER_SELECT_REASON_FREEBIE)
	end
end

function HVHSniperSelect:ChooseAbility(args)
	local playerID = args.playerID
	local player = PlayerResource:GetPlayer(playerID)
	local hero = player:GetAssignedHero()
	local character = args.character
	local abilityName = ""

	if character == "Kardel" then
		abilityName = "sniper_sharpshooter"
	elseif character == "Riggs" then
		abilityName = "sniper_flush"
	elseif character == "Florax" then
		abilityName = "sniper_teleportation"
	elseif character == "Jebby" then
		abilityName = "sniper_concoction"
	end

	hero:RemoveAbility("sniper_empty")
	hero:AddAbility(abilityName)
	HVHGameMode:LevelupAbility(hero, abilityName, true)

	CustomGameEventManager:Send_ServerToAllClients("sniper_select_disable_choice", { character = character })
end