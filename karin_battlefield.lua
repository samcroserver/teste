local karin = {
    config = {
        totalPlayers = 50,
        waitAreaPos = Position(16796, 16956, 7),
        started = false,
        warning = 0,
        timeToStart = 5,
        minutesToEnd = 30,
    },

    functions = {
        queueEvent = function(time,self)
            time = time - 1
            if time > 0 then
                Game.broadcastMessage('Battle Field Event is starting in '..time..(time > 1 and " minutes!" or " minute!"), MESSAGE_STATUS_WARNING)
                addEvent(self.functions.queueEvent, 1 * 60 * 1000, time, self)
            else
                local red,blue = self.functions.aux.getTotalTeamPlayers(self)
                if red + blue >= 2 then
                    self.functions.startBattlefield(self)
                else
                    self.functions.stopEvent(self, true)
                end
            end
        end,
        startEvent = function(self) 
            self.eventtp = Game.createItem(1949, 1, Position(1071, 1010, 7))
            self.eventtp:setActionId(17555)
            Game.broadcastMessage('The portal to Battle Field Event was opened inside Thais temple.', MESSAGE_STATUS_WARNING)
            self.functions.queueEvent(self.config.timeToStart + 1, self)
            Game.loadMap(DATA_DIRECTORY.. '/world/battlefield/battle_area.otbm')
        end,
        stopEvent = function(self, npe)
            local winner
            if self.eventtp then
                self.eventtp:remove()
                self.eventtp = nil
            end
            if npe then
                Game.broadcastMessage('The Battle Field Event was canceled due not enough players.', MESSAGE_STATUS_WARNING)
            else
                Game.broadcastMessage('The Battle Field Event was finished.', MESSAGE_STATUS_WARNING)
                self.config.started = false
                local red,blue = self.functions.aux.getTotalTeamPlayers(self)
                if red == blue then
                    Game.broadcastMessage('We have a DRAW. No one won this event.', MESSAGE_STATUS_WARNING)
                elseif red > blue then
                    winner = 'red'
                    Game.broadcastMessage('Congratulations to the Red Team for win this event! +15 Tournament coins!', MESSAGE_STATUS_WARNING)
                else
                    winner = 'blue'
                    Game.broadcastMessage('Congratulations to the Blue Team for win this event! +15 Tournament coins!', MESSAGE_STATUS_WARNING)
                end
            end
            
            for k, player in pairs(self.teams.players) do
                local playerObject = Player(player.pid)
                if playerObject then
                    playerObject:setHealth(playerObject:getMaxHealth())
                    playerObject:teleportTo(Position(32369, 32241, 7))
                    playerObject:setOutfit(player.outfit)
                    if not npe and player.team == winner then
                        playerObject:addItem(19082, 100)
                    end
                end
            end
            self = bKarin
        end,
        enterEvent = function(self, pid, fromPosition)
            local player = Player(pid)
            if not player then return true end

            if #self.teams.players >= self.config.totalPlayers then
                player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "The event reach the max of players.")
                return true
            end

            -- if self.functions.aux.checkIfPlayerIsAlreadyInEvent(self,pid) then
            --     player:teleportTo(fromPosition)
            --     player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "MC's are not allowed.")
            --     return true
            -- end

            self.functions.aux.selectTeamToPlayer(self,player)
        end,
        startBattlefield = function(self) 
            self.eventtp:remove()
            self.eventtp = nil
            for k, player in pairs(self.teams.players) do
                local playerObject = Player(player.pid)
                if playerObject then
                    playerObject:teleportTo(self.teams[player.team].safePos)
                end
            end

            self.config.started = true
            self.config.time = os.time() + self.config.minutesToEnd * 60 * 1000
            Game.broadcastMessage('Battle Field Event was started!', MESSAGE_STATUS_WARNING)
        end,

        aux = {
            removePlayerFromEvent = function(self, pid) 
                local newPlayers = {}
                for k, player in pairs(self.teams.players) do
                   if player.pid ~= pid then
                        table.insert(newPlayers, player)
                   end
                end
                self.teams.players = newPlayers
                return true
            end,
            checkIfPlayerIsAlreadyInEvent = function(self, pid) 
                for k, player in pairs(self.teams.players) do
                    local pObj = Player(player.pid)
                    local ownpObj = Player(pid)
                   if player.pid == pid or (pObj and ownpObj and pObj:getIp() == ownpObj:getIp())then
                        return player
                   end
                end
                return false
            end,
            getTotalTeamPlayers = function(self) 
                local red = 0
                local blue = 0
                for k, player in pairs(self.teams.players) do
                    red = player.team == 'red' and red + 1 or red
                    blue = player.team == 'blue' and blue + 1 or blue
                end
                return red,blue
            end,
            selectTeamToPlayer = function(self, player)
                local red,blue = self.functions.aux.getTotalTeamPlayers(self)
                local team = ''
            
                if red == 0 and blue == 0 then
                    table.insert(self.teams.players, {
                        pid = player:getId(),
                        team = 'red',
                        outfit = player:getOutfit()
                    })
                    player:setOutfit({lookType = self.teams.red.outfit.lookType,lookFeet = self.teams.red.outfit.lookFeet,lookBody = self.teams.red.outfit.lookBody,lookLegs = self.teams.red.outfit.lookLegs,lookHead = self.teams.red.outfit.lookHead,lookAddons = 0})
                    player:teleportTo(Position(954, 1147, 6))
                elseif red > blue then
                    table.insert(self.teams.players, {
                        pid = player:getId(),
                        team = 'blue',
                        outfit = player:getOutfit()
                    })
                    player:setOutfit({lookType = self.teams.blue.outfit.lookType,lookFeet = self.teams.blue.outfit.lookFeet,lookBody = self.teams.blue.outfit.lookBody,lookLegs = self.teams.blue.outfit.lookLegs,lookHead = self.teams.blue.outfit.lookHead,lookAddons = 0})
                    player:teleportTo(Position(941, 1147, 6))
                else
                    table.insert(self.teams.players, {
                        pid = player:getId(),
                        team = 'red',
                        outfit = player:getOutfit()
                    })
                    player:setOutfit({lookType = self.teams.red.outfit.lookType,lookFeet = self.teams.red.outfit.lookFeet,lookBody = self.teams.red.outfit.lookBody,lookLegs = self.teams.red.outfit.lookLegs,lookHead = self.teams.red.outfit.lookHead,lookAddons = 0})
                    player:teleportTo(Position(954, 1147, 6))
                end
            
                if team == 'red' then
                    player:teleportTo(Position(954, 1147, 6))
                elseif team == 'blue' then
                    player:teleportTo(Position(941, 1147, 6))
                end
                player:getPosition():sendMagicEffect(CONST_ME_STORM)
                Game.broadcastMessage('The player ' .. player:getName() .. ' entered in Battle Field Event.', MESSAGE_STATUS_WARNING)
            end
        }
        
    },

    teams = {
        players = {},
        ['red'] = {
            outfit = {
                lookType = 968,
                lookHead = 94,
                lookBody = 94,
                lookLegs = 94,
                lookFeet = 94,
                lookAddons = 0,
                lookMount= 0
            },
            safePos = Position(16879,16902,6)
        },
        ['blue'] = {
            outfit = {
                lookType = 968,
                lookHead = 85,
                lookBody = 85,
                lookLegs = 85,
                lookFeet = 85,
                lookAddons = 0,
                lookMount= 0
            },
            safePos = Position(16774,16906,6)
        }
    }
}

local bKarin = karin


-- Move events

local battleFieldEventEnter = MoveEvent()

function battleFieldEventEnter.onStepIn(creature, item, position, fromPosition)
    if not creature:isPlayer() then
        return false
    end
    
    karin.functions.enterEvent(karin, creature:getId(), fromPosition)
    position:sendMagicEffect(CONST_ME_WATERSPLASH)
    return true
end

battleFieldEventEnter:aid(17555)
battleFieldEventEnter:register()

----------------------------------------------------------------------------------------

-- Start
-- Talk Actions
local BattleFieldEvent = TalkAction("!battlefield")
function BattleFieldEvent.onSay(player, words, param)
    if not player:getGroup():getAccess() then
        return true
    end
    
    if player:getAccountType() < ACCOUNT_TYPE_GOD then
        return false
    end
    
    karin.functions.startEvent(karin)

    return false
end
BattleFieldEvent:register()

-- Start without queue
local BattleFieldEventStart = TalkAction("!battlefields")
function BattleFieldEventStart.onSay(player, words, param)
    if not player:getGroup():getAccess() then
        return true
    end
    
    if player:getAccountType() < ACCOUNT_TYPE_GOD then
        return false
    end
    
    karin.functions.startBattlefield(karin)

    return false
end
BattleFieldEventStart:register()

-- Cancel
local BattleFieldEventCancel = TalkAction("!battlefieldc")
function BattleFieldEventCancel.onSay(player, words, param)
    if not player:getGroup():getAccess() then
        return true
    end
    
    if player:getAccountType() < ACCOUNT_TYPE_GOD then
        return false
    end
    
    karin.functions.stopEvent(karin)

    return false
end
BattleFieldEventCancel:register()

----------------------------------------------------------------------------------------

-- OnPrepareDeath
local battleFieldDeath = CreatureEvent("battlefield_PrepareDeath")
function battleFieldDeath.onPrepareDeath(player, killer)
    if player then
        local playerInEvent = karin.functions.aux.checkIfPlayerIsAlreadyInEvent(karin, player:getId())
        if playerInEvent then
            karin.functions.aux.removePlayerFromEvent(karin, player:getId())
            player:teleportTo(Position(32369, 32241, 7))
            player:getPosition():sendMagicEffect(CONST_ME_MORTAREA)
            player:setOutfit(playerInEvent.outfit)
            player:setHealth(player:getMaxHealth())
            if killer then
                player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You was killed by " .. killer:getName() .. " in Battle Field Event.")
            else
                player:sendTextMessage(MESSAGE_EVENT_ADVANCE, "You was killed in Battle Field Event.")
            end
            return false
        end
    end
  return true
end
battleFieldDeath:register()
----------------------------------------------------------------------------------------

-- OnLogout

local battlefieldLogout = CreatureEvent("battlefield_Logout")
function battlefieldLogout.onLogout(player)
    if karin.config.started then
        if player then
            player:teleportTo(Position(32369, 32241, 7))
            karin.functions.aux.removePlayerFromEvent(karin, player:getId())
        end
    end
	return true
end

battlefieldLogout:register()

----------------------------------------------------------------------------------------

-- Global Event

local battleFieldGlobalEvent = GlobalEvent("battleFieldGlobalEvent")

function battleFieldGlobalEvent.onThink(interval)
    if karin.config.started then
        local red,blue = karin.functions.aux.getTotalTeamPlayers(karin)
        if red == 0 or blue == 0 then
            karin.functions.stopEvent(karin)
        elseif karin.config.time <= os.time() then
            karin.functions.stopEvent(karin)
        end
    end
    return true
end

battleFieldGlobalEvent:interval(3000)
battleFieldGlobalEvent:register()
----------------------------------------------------------------------------------------
