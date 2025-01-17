LUAGUI_NAME = "Clock"
LUAGUI_AUTH = "adamboy7"
LUAGUI_DESC = "Add clock and stopwatch functionality to the pause menu"
local canExecute = false

local LoadingIndicator = 0x8EC540
local game_Time = 0x9ABC74
local input = 0xBF3120

local timer_Start = os.clock()
local timer_End = os.clock()
local heart = false
local bounce = ReadLong(input)

local mode = Nil

function get_Time_24_Hour()
    -- Get current time as a table
    time = os.date("*t", os.time())

    -- Convert hours/minutes/seconds to 60ths of a second
    time_Since_Midnight = time.hour * 216000 + time.min * 3600 + time.sec * 60

    return time_Since_Midnight
end

function get_Time_12_Hour()
    -- Get current time as a table
    time = os.date("*t", os.time())

    -- Adjust hour for 12-hour format (1-12)
    hour = time.hour % 12
    if hour == 0 then hour = 12 end  -- Adjust so 12 AM or PM shows as 12, not 0

    -- Convert hours/minutes/seconds to 60ths of a second
    time_Since_Midnight = hour * 216000 + time.min * 3600 + time.sec * 60

    return time_Since_Midnight
end

function calculate_Game_Time() -- Re-calculate game time from the timers on the world map
	-- World of Darkness, Twilight Town, Destiny Islands, Hollow Bastion, Beast's Castle, Olympus Coliseum, Agrabah, Land of Dragons, 100 Acre Wood, Pride Lands, Atlantica, Disney Castle, Timeless River, Halloween Town, World Map, Port Royal, Space Paranoids, The World that Never Was
	world_Timers = {0x9ABC80, 0x9ABC84, 0x9ABC88, 0x9ABC8C, 0x9ABC90, 0x9ABC94, 0x9ABC98, 0x9ABC9C, 0x9ABCA0, 0x9ABCA4, 0x9ABCA8, 0x9ABCAC, 0x9ABCB0, 0x9ABCB4, 0x9ABCB8, 0x9ABCBC, 0x9ABCC0, 0x9ABCC4}

	calculated_Game_Time = 0
	for _, address in ipairs(world_Timers) do
		calculated_Game_Time = calculated_Game_Time + ReadInt(address)
	end
	return calculated_Game_Time
end

function clock()
	if mode == 12 then
		WriteInt(game_Time, get_Time_12_Hour()) -- Write the time in 12 hour format
	end

	if mode == 24 then
		WriteInt(game_Time, get_Time_24_Hour()) -- Write the time in 24 hour format
	end
end

function timer()
    if heart == true then
        WriteInt(LoadingIndicator, 1119092736) -- Enable Heart icon
    end

    if mode == "Timer" and heart == true then
        runtime = ((os.clock() - timer_Start) * 60) * 60 -- Convert seconds to minutes and minutes to hours for better timer resolution
        if runtime <= 12959999 then
            WriteInt(game_Time, runtime)
        else
            WriteInt(game_Time, (runtime / 60)) -- Timer reached an hour, return to standard units
        end
    end

    if mode == "Timer" and heart == false then
        runtime = ((timer_End - timer_Start) * 60) * 60 -- Convert seconds to minutes and minutes to hours for better timer resolution
        if runtime <= 12959999 then
            WriteInt(game_Time, runtime)
        else
            WriteInt(game_Time, (runtime / 60)) -- Timer reached an hour, return to standard units
        end
    end
end


function _OnInit()
	if GAME_ID == 0x431219CC and ENGINE_TYPE == "BACKEND" then
		ConsolePrint("Clock - installed")
		canExecute = true
	else
		ConsolePrint("Clock - failed")
		canExecute = false
	end
end

function _OnFrame()
	if canExecute == true then
		timer()

		controller = ReadLong(input) -- Get controller state

		-- Set 12 hour time
		if controller == 55834640448 or controller == 196672 then -- L2 + R2 + Left
			if bounce ~= controller then
				mode = 12
			end
		end

		-- Set 24 hour time
		if controller == 55834591248 or controller == 196624 then -- L2 + R2 + Up
			if bounce ~= controller then
				mode = 24
			end
		end

		-- Restore game time
		if controller == 56103010432 or controller == 196736 then -- L2 + R2 + Right
			if bounce ~= controller then
				mode = Nil
				WriteInt(game_Time, calculate_Game_Time())
			end
		end

		-- Toggle timer
		if controller == 55834607648 or controller == 196640 then -- L2 + R2 + Down
			if bounce ~= controller then
				if heart == false then
					timer_Start = os.clock()
					WriteInt(game_Time, 0)
				end
				if heart == true then
					timer_End = os.clock()
				end
				mode = "Timer"
				heart = not heart
			end
		end

		if mode == 12 or mode == 24 then
			clock()
		end

		bounce = controller -- Update controller state to avoid executing multiple times per button press
	end
end