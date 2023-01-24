obs = obslua

function script_description()
    return [[Saves replays to sub-folders using the Game Capture window name.
    
Author: redraskal]]
end

function script_load()
    obs.obs_frontend_add_event_callback(obs_frontend_callback)
end

function obs_frontend_callback(event)
    if event == obs.OBS_FRONTEND_EVENT_REPLAY_BUFFER_SAVED then
        local path = get_replay_buffer_output()
        local folder = get_game_capture_window_name()
        if path ~= nil and folder ~= nil then
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

function get_game_capture_window_name()
    -- TODO: Infer source
    -- current_scene = obs.obs_frontend_get_current_scene()
    -- game_capture = obs.obs_scene_find_source(current_scene, "Game Capture")
    game_capture = obs.obs_get_source_by_name("Game Capture")
    local properties = obs.obs_source_properties(game_capture)
    local prop = obs.obs_properties_get(properties, "window")
    local setting = obs.obs_property_name(prop)
    local settings = obs.obs_source_get_settings(game_capture)
    local value = obs.obs_data_get_string(settings, setting)
    obs.obs_data_release(settings)
    obs.obs_properties_destroy(properties)
    obs.obs_source_release(game_capture)
    -- obs.obs_source_release(current_scene)
    local i, j = string.find(value, "  :")
    local title = string.sub(value, 1, j - 3)
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
