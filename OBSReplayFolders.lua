obs = obslua

current_game = "Click 'Detect Game' to check"

function script_description()
	return [[Saves replays to sub-folders using the current fullscreen video game executable name.
	
Author: redraskal]]
end

function detect_current_game(props, prop)
	local game = get_running_game()
	if game ~= nil then
		current_game = game
	else
		current_game = "No game detected"
	end
	obs.obs_property_set_description(obs.obs_properties_get(props, "current_game_info"), "Current Game: " .. current_game)
	return true
end

function script_properties()
	local props = obs.obs_properties_create()
	obs.obs_properties_add_button(props, "detect_game_button", "DEBUG: Detect Game", detect_current_game)
	obs.obs_properties_add_text(props, "current_game_info", "Current Game: " .. current_game, obs.OBS_TEXT_INFO)
	return props
end

function script_load()
	ffi = require("ffi")
	ffi.cdef[[
		int get_fullscreen_window_friendly_name(char* buffer, int buffer_len)
	]]
	detect_fullscreen = ffi.load(script_path() .. "detect_fullscreen.dll")
	obs.obs_frontend_add_event_callback(obs_frontend_callback)
end

function obs_frontend_callback(event)
	if event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_SAVED then
		local path = get_replay_buffer_output()
		local folder = get_running_game()
		if path ~= nil and folder ~= nil then
			print("Moving " .. path .. " to " .. folder)
			move(path, folder)
		end
	end
end

function get_replay_buffer_output()
	local replay_buffer = obs.obs_frontend_get_replay_buffer_output()
	local cd = obs.calldata_create()
	local ph = obs.obs_output_get_proc_handler(replay_buffer)
	obs.proc_handler_call(ph, "get_last_replay", cd)
	local path = obs.calldata_string(cd, "path")
	obs.calldata_destroy(cd)
	obs.obs_output_release(replay_buffer)
	return path
end

function get_running_game()
	local name = ffi.new("char[?]", 260)
	local result = detect_fullscreen.get_fullscreen_window_friendly_name(name, 260)
	if result ~= 0 then
		return nil
	end
	result = ffi.string(name)
	local len = #result
	if len == 0 then
		return nil
	end
	return result
end

function move(path, folder)
	local sep = string.match(path, "^.*()/")
	local root = string.sub(path, 1, sep) .. folder
	local file_name = string.sub(path, sep, string.len(path))
	local adjusted_path = root .. file_name
	if obs.os_file_exists(root) == false then
		obs.os_mkdir(root)
	end
	obs.os_rename(path, adjusted_path)
end
