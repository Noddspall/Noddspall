/*
	The monitoring computer for the messaging server.
	Lets you read PDA and request console messages.
*/

#define LINKED_SERVER_NONRESPONSIVE  (!linkedServer || (linkedServer.machine_stat & (NOPOWER|BROKEN)))

#define MSG_MON_SCREEN_MAIN 0
#define MSG_MON_SCREEN_LOGS 1
#define MSG_MON_SCREEN_HACKED 2
#define MSG_MON_SCREEN_CUSTOM_MSG 3
#define MSG_MON_SCREEN_REQUEST_LOGS 4

// The monitor itself.
/obj/machinery/computer/message_monitor
	name = "message monitor console"
	desc = "Used to monitor the crew's PDA messages, as well as request console messages."
	icon_screen = "comm_logs"
	circuit = /obj/item/circuitboard/computer/message_monitor
	light_color = LIGHT_COLOR_GREEN
	//Server linked to.
	var/obj/machinery/telecomms/message_server/linkedServer = null
	//Sparks effect - For emag
	var/datum/effect_system/spark_spread/spark_system = new /datum/effect_system/spark_spread
	//Messages - Saves me time if I want to change something.
	var/noserver = SPAN_ALERT("ALERT: No server detected.")
	var/incorrectkey = SPAN_WARNING("ALERT: Incorrect decryption key!")
	var/defaultmsg = SPAN_NOTICE("Welcome. Please select an option.")
	var/rebootmsg = SPAN_WARNING("%$&(£: Critical %$$@ Error // !RestArting! <lOadiNg backUp iNput ouTput> - ?pLeaSe wAit!")
	//Computer properties
	var/screen = MSG_MON_SCREEN_MAIN // 0 = Main menu, 1 = Message Logs, 2 = Hacked screen, 3 = Custom Message
	var/hacking = FALSE // Is it being hacked into by the AI/Cyborg
	var/message = SPAN_NOTICE("System bootup complete. Please select an option.") // The message that shows on the main menu.
	var/auth = FALSE // Are they authenticated?
	var/optioncount = 7
	// Custom Message Properties
	var/customsender = "System Administrator"
	var/obj/item/pda/customrecepient = null
	var/customjob = "Admin"
	var/custommessage = "This is a test, please ignore."


/obj/machinery/computer/message_monitor/attackby(obj/item/O, mob/living/user, params)
	if(O.tool_behaviour == TOOL_SCREWDRIVER && (obj_flags & EMAGGED))
		//Stops people from just unscrewing the monitor and putting it back to get the console working again.
		to_chat(user, SPAN_WARNING("It is too hot to mess with!"))
	else
		return ..()

/obj/machinery/computer/message_monitor/emag_act(mob/user)
	if(obj_flags & EMAGGED)
		return
	if(!isnull(linkedServer))
		obj_flags |= EMAGGED
		screen = MSG_MON_SCREEN_HACKED
		spark_system.set_up(5, 0, src)
		spark_system.start()
		var/obj/item/paper/monitorkey/MK = new(loc, linkedServer)
		// Will help make emagging the console not so easy to get away with.
		MK.info += "<br><br><font color='red'>£%@%(*$%&(£&?*(%&£/{}</font>"
		var/time = 100 * length(linkedServer.decryptkey)
		addtimer(CALLBACK(src, .proc/UnmagConsole), time)
		message = rebootmsg
	else
		to_chat(user, SPAN_NOTICE("A no server error appears on the screen."))

/obj/machinery/computer/message_monitor/New()
	..()
	GLOB.telecomms_list += src

/obj/machinery/computer/message_monitor/Initialize()
	..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/message_monitor/LateInitialize()
	//Is the server isn't linked to a server, and there's a server available, default it to the first one in the list.
	if(!linkedServer)
		for(var/obj/machinery/telecomms/message_server/S in GLOB.telecomms_list)
			linkedServer = S
			break

/obj/machinery/computer/message_monitor/Destroy()
	GLOB.telecomms_list -= src
	return ..()

/obj/machinery/computer/message_monitor/ui_interact(mob/living/user)
	. = ..()
	//If the computer is being hacked or is emagged, display the reboot message.
	if(hacking || (obj_flags & EMAGGED))
		message = rebootmsg
	var/dat = "<center><font color='blue'[message]</font></center>"

	if(auth)
		dat += "<h4><dd><A href='?src=[REF(src)];auth=1'>&#09;<font color='green'>\[Authenticated\]</font></a>&#09;/"
		dat += " Server Power: <A href='?src=[REF(src)];active=1'>[linkedServer?.on ? "<font color='green'>\[On\]</font>":"<font color='red'>\[Off\]</font>"]</a></h4>"
	else
		dat += "<h4><dd><A href='?src=[REF(src)];auth=1'>&#09;<font color='red'>\[Unauthenticated\]</font></a>&#09;/"
		dat += " Server Power: <u>[linkedServer?.on ? "<font color='green'>\[On\]</font>":"<font color='red'>\[Off\]</font>"]</u></h4>"

	if(hacking || (obj_flags & EMAGGED))
		screen = MSG_MON_SCREEN_HACKED
	else if(!auth || LINKED_SERVER_NONRESPONSIVE)
		if(LINKED_SERVER_NONRESPONSIVE)
			message = noserver
		screen = MSG_MON_SCREEN_MAIN

	switch(screen)
		//Main menu
		if(MSG_MON_SCREEN_MAIN)
			//&#09; = TAB
			var/i = 0
			dat += "<dd><A href='?src=[REF(src)];find=1'>&#09;[++i]. Link To A Server</a></dd>"
			if(auth)
				if(LINKED_SERVER_NONRESPONSIVE)
					dat += "<dd><A>&#09;ERROR: Server not found!</A><br></dd>"
				else
					dat += "<dd><A href='?src=[REF(src)];view_logs=1'>&#09;[++i]. View Message Logs </a><br></dd>"
					dat += "<dd><A href='?src=[REF(src)];view_requests=1'>&#09;[++i]. View Request Console Logs </a></br></dd>"
					dat += "<dd><A href='?src=[REF(src)];clear_logs=1'>&#09;[++i]. Clear Message Logs</a><br></dd>"
					dat += "<dd><A href='?src=[REF(src)];clear_requests=1'>&#09;[++i]. Clear Request Console Logs</a><br></dd>"
					dat += "<dd><A href='?src=[REF(src)];pass=1'>&#09;[++i]. Set Custom Key</a><br></dd>"
					dat += "<dd><A href='?src=[REF(src)];msg=1'>&#09;[++i]. Send Admin Message</a><br></dd>"
			else
				for(var/n = ++i; n <= optioncount; n++)
					dat += "<dd><font color='blue'>&#09;[n]. ---------------</font><br></dd>"
			dat += "<br>"

			//Bottom message
			if(!auth)
				dat += "<br><hr><dd>[SPAN_NOTICE("Please authenticate with the server in order to show additional options.")]"
			else
				dat += "<br><hr><dd>[SPAN_WARNING("Reg, #514 forbids sending messages to a Head of Staff containing Erotic Rendering Properties.")]"

		//Message Logs
		if(MSG_MON_SCREEN_LOGS)
			var/index = 0
			dat += "<center><A href='?src=[REF(src)];back=1'>Back</a> - <A href='?src=[REF(src)];refresh=1'>Refresh</a></center><hr>"
			dat += "<table border='1' width='100%'><tr><th width = '5%'>X</th><th width='15%'>Sender</th><th width='15%'>Recipient</th><th width='300px' word-wrap: break-word>Message</th></tr>"
			for(var/datum/data_pda_msg/pda in linkedServer.pda_msgs)
				index++
				if(index > 3000)
					break
				// Del - Sender   - Recepient - Message
				// X   - Al Green - Your Mom  - WHAT UP!?
				dat += "<tr><td width = '5%'><center><A href='?src=[REF(src)];delete_logs=[REF(pda)]' style='color: rgb(255,0,0)'>X</a></center></td><td width='15%'>[pda.sender]</td><td width='15%'>[pda.recipient]</td><td width='300px'>[pda.message][pda.picture ? " <a href='byond://?src=[REF(pda)];photo=1'>(Photo)</a>":""]</td></tr>"
			dat += "</table>"
		//Hacking screen.
		if(MSG_MON_SCREEN_HACKED)
			dat += "Brute-forcing for server key.<br> It will take 20 seconds for every character that the password has."
			dat += "In the meantime, this console can reveal your true intentions if you let someone access it. Make sure no humans enter the room during that time."

		//Fake messages
		if(MSG_MON_SCREEN_CUSTOM_MSG)
			dat += "<center><A href='?src=[REF(src)];back=1'>Back</a> - <A href='?src=[REF(src)];Reset=1'>Reset</a></center><hr>"

			dat += {"<table border='1' width='100%'>
					<tr><td width='20%'><A href='?src=[REF(src)];select=Sender'>Sender</a></td>
					<td width='20%'><A href='?src=[REF(src)];select=RecJob'>Sender's Job</a></td>
					<td width='20%'><A href='?src=[REF(src)];select=Recepient'>Recipient</a></td>
					<td width='300px' word-wrap: break-word><A href='?src=[REF(src)];select=Message'>Message</a></td></tr>"}
				//Sender  - Sender's Job  - Recepient - Message
				//Al Green- Your Dad   - Your Mom  - WHAT UP!?

			dat += {"<tr><td width='20%'>[customsender]</td>
			<td width='20%'>[customjob]</td>
			<td width='20%'>[customrecepient ? customrecepient.owner : "NONE"]</td>
			<td width='300px'>[custommessage]</td></tr>"}
			dat += "</table><br><center><A href='?src=[REF(src)];select=Send'>Send</a>"

		//Request Console Logs
		if(MSG_MON_SCREEN_REQUEST_LOGS)

			var/index = 0
			/* data_rc_msg
				X  - 5%
				var/rec_dpt = "Unspecified" //name of the person - 15%
				var/send_dpt = "Unspecified" //name of the sender- 15%
				var/message = "Blank" //transferred message  - 300px
				var/stamp = "Unstamped"  - 15%
				var/id_auth = "Unauthenticated"  - 15%
				var/priority = "Normal"  - 10%
			*/
			dat += "<center><A href='?src=[REF(src)];back=1'>Back</a> - <A href='?src=[REF(src)];refresh=1'>Refresh</a></center><hr>"
			dat += {"<table border='1' width='100%'><tr><th width = '5%'>X</th><th width='15%'>Sending Dep.</th><th width='15%'>Receiving Dep.</th>
			<th width='300px' word-wrap: break-word>Message</th><th width='15%'>Stamp</th><th width='15%'>ID Auth.</th><th width='15%'>Priority.</th></tr>"}
			for(var/datum/data_rc_msg/rc in linkedServer.rc_msgs)
				index++
				if(index > 3000)
					break
				// Del - Sender   - Recepient - Message
				// X   - Al Green - Your Mom  - WHAT UP!?
				dat += {"<tr><td width = '5%'><center><A href='?src=[REF(src)];delete_requests=[REF(rc)]' style='color: rgb(255,0,0)'>X</a></center></td><td width='15%'>[rc.send_dpt]</td>
				<td width='15%'>[rc.rec_dpt]</td><td width='300px'>[rc.message]</td><td width='15%'>[rc.stamp]</td><td width='15%'>[rc.id_auth]</td><td width='15%'>[rc.priority]</td></tr>"}
			dat += "</table>"

	message = defaultmsg
	var/datum/browser/popup = new(user, "hologram_console", name, 700, 700)
	popup.set_content(dat)
	popup.open()

/obj/machinery/computer/message_monitor/proc/BruteForce(mob/user)
	if(isnull(linkedServer))
		to_chat(user, SPAN_WARNING("Could not complete brute-force: Linked Server Disconnected!"))
	else
		var/currentKey = linkedServer.decryptkey
		to_chat(user, SPAN_WARNING("Brute-force completed! The key is '[currentKey]'."))
	hacking = FALSE
	screen = MSG_MON_SCREEN_MAIN // Return the screen back to normal

/obj/machinery/computer/message_monitor/proc/UnmagConsole()
	obj_flags &= ~EMAGGED

/obj/machinery/computer/message_monitor/proc/ResetMessage()
	customsender = "System Administrator"
	customrecepient = null
	custommessage = "This is a test, please ignore."
	customjob = "Admin"

/obj/machinery/computer/message_monitor/Topic(href, href_list)
	if(..())
		return

	if(usr.contents.Find(src) || (in_range(src, usr) && isturf(loc)))
		//Authenticate
		if (href_list["auth"])
			if(LINKED_SERVER_NONRESPONSIVE)
				message = noserver
			else if(auth)
				auth = FALSE
				screen = MSG_MON_SCREEN_MAIN
			else
				var/dkey = trim(input(usr, "Please enter the decryption key.") as text|null)
				if(dkey && dkey != "")
					if(linkedServer.decryptkey == dkey)
						auth = TRUE
					else
						message = incorrectkey

		//Turn the server on/off.
		if (href_list["active"])
			if(LINKED_SERVER_NONRESPONSIVE)
				message = noserver
			else if(auth)
				linkedServer.toggled = !linkedServer.toggled
		//Find a server
		if (href_list["find"])
			var/list/message_servers = list()
			for (var/obj/machinery/telecomms/message_server/M in GLOB.telecomms_list)
				message_servers += M

			if(message_servers.len > 1)
				linkedServer = input(usr, "Please select a server.", "Select a server.", null) as null|anything in message_servers
				message = SPAN_ALERT("NOTICE: Server selected.")
			else if(message_servers.len > 0)
				linkedServer = message_servers[1]
				message =  SPAN_NOTICE("NOTICE: Only Single Server Detected - Server selected.")
			else
				message = noserver

		//View the logs - KEY REQUIRED
		if (href_list["view_logs"])
			if(LINKED_SERVER_NONRESPONSIVE)
				message = noserver
			else if(auth)
				screen = MSG_MON_SCREEN_LOGS

		//Clears the logs - KEY REQUIRED
		if (href_list["clear_logs"])
			if(LINKED_SERVER_NONRESPONSIVE)
				message = noserver
			else if(auth)
				linkedServer.pda_msgs = list()
				message = SPAN_NOTICE("NOTICE: Logs cleared.")
		//Clears the request console logs - KEY REQUIRED
		if (href_list["clear_requests"])
			if(LINKED_SERVER_NONRESPONSIVE)
				message = noserver
			else if(auth)
				linkedServer.rc_msgs = list()
				message = SPAN_NOTICE("NOTICE: Logs cleared.")
		//Change the password - KEY REQUIRED
		if (href_list["pass"])
			if(LINKED_SERVER_NONRESPONSIVE)
				message = noserver
			else if(auth)
				var/dkey = stripped_input(usr, "Please enter the decryption key.")
				if(dkey && dkey != "")
					if(linkedServer.decryptkey == dkey)
						var/newkey = stripped_input(usr,"Please enter the new key (3 - 16 characters max):")
						if(length(newkey) <= 3)
							message = SPAN_NOTICE("NOTICE: Decryption key too short!")
						else if(length(newkey) > 16)
							message = SPAN_NOTICE("NOTICE: Decryption key too long!")
						else if(newkey && newkey != "")
							linkedServer.decryptkey = newkey
						message = SPAN_NOTICE("NOTICE: Decryption key set.")
					else
						message = incorrectkey

		//Delete the log.
		if (href_list["delete_logs"])
			//Are they on the view logs screen?
			if(screen == MSG_MON_SCREEN_LOGS)
				if(LINKED_SERVER_NONRESPONSIVE)
					message = noserver
				else //if(istype(href_list["delete_logs"], /datum/data_pda_msg))
					linkedServer.pda_msgs -= locate(href_list["delete_logs"]) in linkedServer.pda_msgs
					message = SPAN_NOTICE("NOTICE: Log Deleted!")
		//Delete the request console log.
		if (href_list["delete_requests"])
			//Are they on the view logs screen?
			if(screen == MSG_MON_SCREEN_REQUEST_LOGS)
				if(LINKED_SERVER_NONRESPONSIVE)
					message = noserver
				else //if(istype(href_list["delete_logs"], /datum/data_pda_msg))
					linkedServer.rc_msgs -= locate(href_list["delete_requests"]) in linkedServer.rc_msgs
					message = SPAN_NOTICE("NOTICE: Log Deleted!")
		//Create a custom message
		if (href_list["msg"])
			if(LINKED_SERVER_NONRESPONSIVE)
				message = noserver
			else if(auth)
				screen = MSG_MON_SCREEN_CUSTOM_MSG
		//Fake messaging selection - KEY REQUIRED
		if (href_list["select"])
			if(LINKED_SERVER_NONRESPONSIVE)
				message = noserver
				screen = MSG_MON_SCREEN_MAIN
			else
				switch(href_list["select"])

					//Reset
					if("Reset")
						ResetMessage()

					//Select Your Name
					if("Sender")
						customsender = stripped_input(usr, "Please enter the sender's name.") || customsender

					//Select Receiver
					if("Recepient")
						//Get out list of viable PDAs
						var/list/obj/item/pda/sendPDAs = get_viewable_pdas()
						if(GLOB.PDAs && GLOB.PDAs.len > 0)
							customrecepient = input(usr, "Select a PDA from the list.") as null|anything in sendPDAs
						else
							customrecepient = null

					//Enter custom job
					if("RecJob")
						customjob = stripped_input(usr, "Please enter the sender's job.") || customjob

					//Enter message
					if("Message")
						custommessage = stripped_input(usr, "Please enter your message.") || custommessage

					//Send message
					if("Send")
						if(isnull(customsender) || customsender == "")
							customsender = "UNKNOWN"

						if(isnull(customrecepient))
							message = SPAN_NOTICE("NOTICE: No recepient selected!")
							return attack_hand(usr)

						if(isnull(custommessage) || custommessage == "")
							message = SPAN_NOTICE("NOTICE: No message entered!")
							return attack_hand(usr)

						var/datum/signal/subspace/messaging/pda/signal = new(src, list(
							"name" = "[customsender]",
							"job" = "[customjob]",
							"message" = custommessage,
							"targets" = list("[customrecepient.owner] ([customrecepient.ownjob])")
						))
						// this will log the signal and transmit it to the target
						linkedServer.receive_information(signal, null)
						usr.log_message("(PDA: [name] | [usr.real_name]) sent \"[custommessage]\" to [signal.format_target()]", LOG_PDA)


		//Request Console Logs - KEY REQUIRED
		if(href_list["view_requests"])
			if(LINKED_SERVER_NONRESPONSIVE)
				message = noserver
			else if(auth)
				screen = MSG_MON_SCREEN_REQUEST_LOGS

		if (href_list["back"])
			screen = MSG_MON_SCREEN_MAIN

	return attack_hand(usr)

/obj/machinery/computer/message_monitor/proc/finish_bruteforce(mob/user)
	if(!QDELETED(user))
		BruteForce(user)
		return
	hacking = FALSE
	screen = MSG_MON_SCREEN_MAIN

#undef MSG_MON_SCREEN_MAIN
#undef MSG_MON_SCREEN_LOGS
#undef MSG_MON_SCREEN_HACKED
#undef MSG_MON_SCREEN_CUSTOM_MSG
#undef MSG_MON_SCREEN_REQUEST_LOGS

#undef LINKED_SERVER_NONRESPONSIVE

/obj/item/paper/monitorkey
	name = "monitor decryption key"

/obj/item/paper/monitorkey/Initialize(mapload, obj/machinery/telecomms/message_server/server)
	..()
	if (server)
		print(server)
		return INITIALIZE_HINT_NORMAL
	else
		return INITIALIZE_HINT_LATELOAD

/obj/item/paper/monitorkey/proc/print(obj/machinery/telecomms/message_server/server)
	info = "<center><h2>Daily Key Reset</h2></center><br>The new message monitor key is '[server.decryptkey]'.<br>Please keep this a secret and away from the clown.<br>If necessary, change the password to a more secure one."
	add_overlay("paper_words")

/obj/item/paper/monitorkey/LateInitialize()
	for (var/obj/machinery/telecomms/message_server/preset/server in GLOB.telecomms_list)
		if (server.decryptkey)
			print(server)
			break
