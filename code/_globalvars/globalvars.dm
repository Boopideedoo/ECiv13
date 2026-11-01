// ============================================================================
// GLOBALS.DM - Centralized Global Variables & Subsystem References
// ============================================================================
// Instructions for adding new globals:
//   1. Declare your global variable or subsystem pointer below using standard 
//      explicit typing (e.g., var/datum/type/name).
//   2. Ensure this file is included near the top of your civ13.dme file so 
//      that all other game logic and datums can see these variables globally.
// ============================================================================

// --- Subsystem & Controller Globals ---
var/datum/controller/subsystem/map_loader/SSmap_loader
var/global/datum/vote/vote = new()

// --- Future Expansion Examples (Uncomment and modify as needed) ---
// var/datum/controller/subsystem/economy/SSeconomy
// var/datum/controller/subsystem/weather/SSweather
// var/global/server_boot_time = 0
