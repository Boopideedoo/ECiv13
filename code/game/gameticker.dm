#define GAMETICKER_PREGAME_TIME 90

var/global/datum/controller/gameticker/ticker
var/global/datum/lobby_music_player/lobby_music_player = null

/datum/controller/gameticker
	var/const/restart_timeout = 300
	var/current_state = GAME_STATE_PREGAME
	var/admin_started = FALSE

	var/post_game = FALSE
	var/event_time = null
	var/event = FALSE

	var/login_music

	var/list/datum/mind/minds = list()

	var/random_players = FALSE

	var/list/syndicate_coalition = list()
	var/list/factions = list()
	var/list/availablefactions = list()

	var/pregame_timeleft = FALSE

	var/delay_end = FALSE

	var/round_end_announced = FALSE

	var/can_latejoin_ruforce = TRUE
	var/can_latejoin_geforce = TRUE

	var/players_can_join = TRUE

	var/tip = null
	var/maytip = TRUE

	var/finished = FALSE

	var/restarting_is_very_bad = FALSE

	var/obj/screen/cinematic = null

/datum/controller/gameticker/proc/pregame()
	spawn (0)
		current_state = GAME_STATE_PREGAME

		if (!lobby_music_player)
			lobby_music_player = new

		login_music = lobby_music_player.get_song()

		do
			pregame_timeleft = GAMETICKER_PREGAME_TIME
			maytip = TRUE

			to_chat(world, SPAN_NOTICE("<b>Welcome to the pre-game lobby!</b>"))
			to_chat(world, "The game will start in [pregame_timeleft] seconds.")

			while (current_state == GAME_STATE_PREGAME)
				for (var/i=0, i<10, i++)
					sleep(1)
					vote.process()
				if (round_progressing)
					pregame_timeleft--
				if (pregame_timeleft == config.vote_autogamemode_timeleft)
					if (!vote.time_remaining)
						vote.autogamemode()
						while (vote.time_remaining)
							for (var/i=0, i<10, i++)
								sleep(1)
								vote.process()
				if (pregame_timeleft == 20)
					if (tip)
						to_chat(world, SPAN_NOTICE("<b>Tip of the round:</b> [tip]"))
					else
						var/list/tips = file2list("config/tips.txt")
						if (tips.len)
							to_chat(world, SPAN_NOTICE("<b>Tip of the round:</b> [pick(tips)]"))
							qdel_list(tips)
					maytip = FALSE
				if (pregame_timeleft <= 0)
					current_state = GAME_STATE_SETTING_UP
					if (maytip)
						if (tip)
							to_chat(world, SPAN_NOTICE("<b>Tip of the round:</b> [tip]"))
						else
							var/list/tips = file2list("config/tips.txt")
							if (tips.len)
								to_chat(world, SPAN_NOTICE("<b>Tip of the round:</b> [pick(tips)]"))
								qdel_list(tips)
		while (!setup())


/datum/controller/gameticker/proc/setup()
	current_state = GAME_STATE_PLAYING

	job_master.ResetOccupations()

	if (!map || !map.can_start() && !admin_started)
		to_chat(world, "<b>Unable to start the game.</b> Not enough players, [map.required_players] active players needed. Reverting to the pre-game lobby.")
		current_state = GAME_STATE_PREGAME
		job_master.ResetOccupations()
		return FALSE

	create_characters()
	collect_minds()
	equip_characters()

	TOD_loop()

	callHook("roundstart")

	spawn(0)
		setup_autobalance()

	return TRUE

/datum/controller/gameticker/proc/close_jobs()
	for (var/datum/job/job in job_master.occupations)
		if (job.title == "Captain")
			job.total_positions = FALSE

/datum/controller/gameticker/proc/create_characters()
	for (var/mob/new_player/player in player_list)
		if (player && player.ready && player.mind)
			if (!player.mind.assigned_role)
				continue
			else
				player.create_character()
				qdel(player)

/datum/controller/gameticker/proc/collect_minds()
	for (var/mob/living/player in player_list)
		if (player.mind)
			ticker.minds += player.mind

/datum/controller/gameticker/proc/equip_characters()
	for (var/mob/living/human/player in player_list)
		if (player && player.mind && player.mind.assigned_role)
			job_master.EquipRank(player, player.mind.assigned_role, FALSE)

/datum/controller/gameticker/proc/process()
	if (current_state != GAME_STATE_PLAYING)
		return FALSE

	if (finished)
		current_state = GAME_STATE_FINISHED

		spawn(50)
			callHook("roundend")

			var/restart_after = restart_timeout
			var/next_map_name = (SSmap_loader && SSmap_loader.next_map) ? SSmap_loader.next_map.name : "TBD"

			if (!delay_end)
				to_chat(world, SPAN_NOTICE("<big>Restarting in <b>90</b> seconds. Next map: <b>[next_map_name]</b></big>"))
				if (restart_after > restart_timeout)
					restarting_is_very_bad = TRUE
					spawn (restart_after - restart_timeout)
						restarting_is_very_bad = FALSE

				sleep(restart_after)
				if (!delay_end)
					world.Reboot()
				else
					to_chat(world, SPAN_NOTICE("<b>An admin has delayed the round end.</b>"))
			else
				to_chat(world, SPAN_NOTICE("<b>An admin has delayed the round end.</b>"))

	return TRUE

/datum/controller/gameticker/proc/station_explosion_cinematic(var/station_missed=0, var/override = null)
	if(cinematic)
		return

	cinematic = new(src)
	cinematic.icon = null
	cinematic.icon_state = "start"
	cinematic.layer = 21
	cinematic.mouse_opacity = 0
	cinematic.screen_loc = "CENTER-7,CENTER-7"

	var/obj/structure/bed/temp_buckle = new(src)
	if(station_missed)
		for(var/mob/living/M in living_mob_list)
			M.buckled = temp_buckle
			if(M.client)
				M.client.screen += cinematic
	else
		for(var/mob/living/M in living_mob_list)
			M.buckled = temp_buckle
			if(M.client)
				M.client.screen += cinematic

			if(M.z == 0)
				var/turf/T = get_turf(M)
				if(T)
					M.health = 0
					M.stat = DEAD

	switch(station_missed)
		if(1)
			if(map.gamemode && !override)
				override = map.gamemode
			switch(override)
				if("nuclear emergency")
					flick("start_nuke",cinematic)
					sleep(35)
					flick("explode",cinematic)
					cinematic.icon_state = "loss_nuke"
				else
					flick("start_nuke",cinematic)
					sleep(35)
					flick("explode",cinematic)
					cinematic.icon_state = "loss_nuke"
		if(2)
			sleep(50)
		else
			if(map.gamemode && !override)
				override = map.gamemode
			switch(override)
				if("nuclear emergency")
					flick("intro_nuke",cinematic)
					sleep(35)
					flick("station_intact",cinematic)
					cinematic.icon_state = "station_intact"
				if("AI malfunction")
					flick("start_nuke",cinematic)
					sleep(35)
					flick("explode",cinematic)
					cinematic.icon_state = "loss_nuke"
				if("blob")
					flick("start_nuke",cinematic)
					sleep(35)
					flick("explode",cinematic)
					cinematic.icon_state = "loss_nuke"
				else
					flick("start_nuke",cinematic)
					sleep(35)
					flick("explode",cinematic)
					cinematic.icon_state = "loss_nuke"
			for(var/mob/living/M in living_mob_list)
				var/area/A = get_area(M)
				if(!A.nukesafe)
					M.death()

	sleep(300)

	if(cinematic)
		qdel(cinematic)
	if(temp_buckle)
		qdel(temp_buckle)
	return