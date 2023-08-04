obs = obslua

function script_description()
	return [[Saves replays to sub-folders using the current fullscreen video game executable name.
	
Author: redraskal]]
end

function script_load()
	ffi = require("ffi")
	ffi.cdef[[
		int get_running_fullscreen_game_path(char* buffer, int bufferSize)
	]]
	detect_game = ffi.load(script_path() .. "detect_game.dll")
	print(get_running_game_title())
	obs.obs_frontend_add_event_callback(obs_frontend_callback)
end

function obs_frontend_callback(event)
	if event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_SAVED then
		local path = get_replay_buffer_output()
		local folder = get_running_game_title()
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

function get_running_game_title()
	local path = ffi.new("char[?]", 260)
	local result = detect_game.get_running_fullscreen_game_path(path, 260)
	if result ~= 0 then
		return nil
	end
	result = ffi.string(path)
	local len = #result
	if len == 0 then
		return nil
	end
	local title = ""
	local i = 1
	local max = len - 4
	while i <= max do
		local char = result:sub(i, i)
		if char == "\\" then
			title = ""
		else
			title = title .. char
		end
		i = i + 1
	end
	return title
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
