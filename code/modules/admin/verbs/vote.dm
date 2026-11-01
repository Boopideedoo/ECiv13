/client/proc/start_mapswap_vote()
	set category = "Server"
	set name = "Start Map Vote"
	if (!check_rights(R_ADMIN))
		return
	
	if (vote)
		vote.initiate_vote("map", usr.key)
		log_admin("[key_name(usr)] triggered a map vote.")
		message_admins("[key_name(usr)] triggered a map vote.")
	else
		src << "<span class='notice'>Voting system is not available.</span>"

/client/proc/start_epochswap_vote()
	set category = "Server"
	set name = "Start Epoch Vote"
	if (!check_rights(R_ADMIN))
		return
	
	if (vote)
		vote.initiate_vote("gamemode", usr.key)
		log_admin("[key_name(usr)] triggered an epoch/gamemode vote.")
		message_admins("[key_name(usr)] triggered an epoch/gamemode vote.")
	else
		src << "<span class='notice'>Voting system is not available.</span>"
