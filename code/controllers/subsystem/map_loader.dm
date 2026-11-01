/datum/map_info
    var/name = ""
    var/id = ""
    var/path = ""
    var/voteable = TRUE

/datum/controller/subsystem/map_loader
    name = "Eciv13 Map Subsystem"
    var/list/datum/map_info/available_maps = list()
    var/datum/map_info/current_map = null
    var/datum/map_info/next_map = null

/datum/controller/subsystem/map_loader/Initialize()
    load_map_config()
    load_selected_map()
    return ..()

/datum/controller/subsystem/map_loader/proc/load_map_config()
    var/config_path = "maps/maps.json"
    if (!fexists(config_path))
        log_world("MAP ERROR: maps/maps.json missing!")
        return FALSE

    var/json_text = file2text(config_path)
    var/list/parsed = json_decode(json_text)
    
    if (!parsed || !parsed["maps"]) return FALSE

    for (var/list/map_data in parsed["maps"])
        var/datum/map_info/M = new()
        M.name = map_data["name"]
        M.id = map_data["id"]
        M.path = map_data["path"]
        M.voteable = map_data["voteable"]
        available_maps[M.id] = M

    // Check if next_map.txt has a saved choice from a vote
    if (fexists("data/next_map.txt"))
        var/saved_id = trim(file2text("data/next_map.txt"))
        if (available_maps[saved_id])
            next_map = available_maps[saved_id]
        fdel("data/next_map.txt")

    if (!next_map && parsed["default_map"])
        next_map = available_maps[parsed["default_map"]]

/datum/controller/subsystem/map_loader/proc/load_selected_map()
    if (!next_map) return FALSE
    current_map = next_map
    log_world("ECIV13 MAP LOADING: [current_map.name] ([current_map.path])")

    if (fexists(current_map.path))
        world.load_mode(current_map.path)
        return TRUE
    return FALSE

/datum/controller/subsystem/map_loader/proc/set_next_map_from_vote(var/map_id)
    if (!available_maps[map_id]) return FALSE
    var/datum/map_info/chosen = available_maps[map_id]
    next_map = chosen

    if (fexists("data/next_map.txt")) fdel("data/next_map.txt")
    map_id >> "data/next_map.txt"
    world << "<span class='boldannounce'>Next round map set to: <b>[chosen.name]</b></span>"
    return TRUE