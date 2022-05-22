// Status display
// (formerly Countdown timer display)

#define CHARS_PER_LINE 5
#define FONT_SIZE "5pt"
#define FONT_COLOR "#09f"
#define FONT_STYLE "Small Fonts"
#define SCROLL_SPEED 2

#define SD_BLANK 0  // 0 = Blank
#define SD_EMERGENCY 1  // 1 = Emergency Shuttle timer
#define SD_MESSAGE 2  // 2 = Arbitrary message(s)
#define SD_PICTURE 3  // 3 = alert picture

/// Status display which can show images and scrolling text.
/obj/machinery/status_display
	name = "status display"
	desc = null
	icon = 'icons/obj/status_display.dmi'
	icon_state = "frame"
	density = FALSE
	use_power = IDLE_POWER_USE
	idle_power_usage = 10
	layer = ABOVE_WINDOW_LAYER

	maptext_height = 26
	maptext_width = 32
	maptext_y = -1

	var/message1 = "" // message line 1
	var/message2 = "" // message line 2
	var/index1 // display index for scrolling messages or 0 if non-scrolling
	var/index2

/// Immediately blank the display.
/obj/machinery/status_display/proc/remove_display()
	cut_overlays()
	if(maptext)
		maptext = ""

/// Immediately change the display to the given picture.
/obj/machinery/status_display/proc/set_picture(state)
	remove_display()
	add_overlay(state)

/// Immediately change the display to the given two lines.
/obj/machinery/status_display/proc/update_display(line1, line2)
	line1 = uppertext(line1)
	line2 = uppertext(line2)
	var/new_text = {"<div style="font-size:[FONT_SIZE];color:[FONT_COLOR];font:'[FONT_STYLE]';text-align:center;" valign="top">[line1]<br>[line2]</div>"}
	if(maptext != new_text)
		maptext = new_text

/// Prepare the display to marquee the given two lines.
///
/// Call with no arguments to disable.
/obj/machinery/status_display/proc/set_message(m1, m2)
	if(m1)
		index1 = (length_char(m1) > CHARS_PER_LINE)
		message1 = m1
	else
		message1 = ""
		index1 = 0

	if(m2)
		index2 = (length_char(m2) > CHARS_PER_LINE)
		message2 = m2
	else
		message2 = ""
		index2 = 0

// Timed process - performs default marquee action if so needed.
/obj/machinery/status_display/process()
	if(machine_stat & NOPOWER)
		// No power, no processing.
		remove_display()
		return PROCESS_KILL

	var/line1 = message1
	if(index1)
		line1 = copytext_char("[message1]|[message1]", index1, index1 + CHARS_PER_LINE)
		var/message1_len = length_char(message1)
		index1 += SCROLL_SPEED
		if(index1 > message1_len + 1)
			index1 -= (message1_len + 1)

	var/line2 = message2
	if(index2)
		line2 = copytext_char("[message2]|[message2]", index2, index2 + CHARS_PER_LINE)
		var/message2_len = length_char(message2)
		index2 += SCROLL_SPEED
		if(index2 > message2_len + 1)
			index2 -= (message2_len + 1)

	update_display(line1, line2)
	if (!index1 && !index2)
		// No marquee, no processing.
		return PROCESS_KILL

/// Update the display and, if necessary, re-enable processing.
/obj/machinery/status_display/proc/update()
	if (process(SSMACHINES_DT) != PROCESS_KILL)
		START_PROCESSING(SSmachines, src)

/obj/machinery/status_display/power_change()
	. = ..()
	update()

/obj/machinery/status_display/emp_act(severity)
	. = ..()
	if(machine_stat & (NOPOWER|BROKEN) || . & EMP_PROTECT_SELF)
		return
	set_picture("ai_bsod")

/obj/machinery/status_display/examine(mob/user)
	. = ..()
	if (message1 || message2)
		. += "The display says:"
		if (message1)
			. += "<br>\t<tt>[html_encode(message1)]</tt>"
		if (message2)
			. += "<br>\t<tt>[html_encode(message2)]</tt>"

// Helper procs for child display types.
/obj/machinery/status_display/proc/display_shuttle_status(obj/docking_port/mobile/shuttle)
	if(!shuttle)
		// the shuttle is missing - no processing
		update_display("shutl?","")
		return PROCESS_KILL
	else if(shuttle.timer)
		var/line1 = "-[shuttle.getModeStr()]-"
		var/line2 = shuttle.getTimerStr()

		if(length_char(line2) > CHARS_PER_LINE)
			line2 = "error"
		update_display(line1, line2)
	else
		// don't kill processing, the timer might turn back on
		remove_display()

/obj/machinery/status_display/proc/examine_shuttle(mob/user, obj/docking_port/mobile/shuttle)
	if (shuttle)
		var/modestr = shuttle.getModeStr()
		if (modestr)
			if (shuttle.timer)
				modestr = "<br>\t<tt>[modestr]: [shuttle.getTimerStr()]</tt>"
			else
				modestr = "<br>\t<tt>[modestr]</tt>"
		return "The display says:<br>\t<tt>[shuttle.name]</tt>[modestr]"
	else
		return "The display says:<br>\t<tt>Shuttle missing!</tt>"


/// Evac display which shows shuttle timer or message set by Command.
/obj/machinery/status_display/evac
	var/frequency = FREQ_STATUS_DISPLAYS
	var/mode = SD_EMERGENCY
	var/friendc = FALSE      // track if Friend Computer mode
	var/last_picture  // For when Friend Computer mode is undone


/obj/machinery/status_display/evac/directional/north
	dir = SOUTH
	pixel_y = 32

/obj/machinery/status_display/evac/directional/south
	dir = NORTH
	pixel_y = -32

/obj/machinery/status_display/evac/directional/east
	dir = WEST
	pixel_x = 32

/obj/machinery/status_display/evac/directional/west
	dir = EAST
	pixel_x = -32

/obj/machinery/status_display/evac/Initialize()
	. = ..()
	// register for radio system
	SSradio.add_object(src, frequency)

/obj/machinery/status_display/evac/Destroy()
	SSradio.remove_object(src,frequency)
	return ..()

/obj/machinery/status_display/evac/process()
	if(machine_stat & NOPOWER)
		// No power, no processing.
		remove_display()
		return PROCESS_KILL

	if(friendc) //Makes all status displays except supply shuttle timer display the eye -- Urist
		set_picture("ai_friend")
		return PROCESS_KILL

	switch(mode)
		if(SD_BLANK)
			remove_display()
			return PROCESS_KILL

		if(SD_EMERGENCY)
			return display_shuttle_status(SSshuttle.emergency)

		if(SD_MESSAGE)
			return ..()

		if(SD_PICTURE)
			set_picture(last_picture)
			return PROCESS_KILL

/obj/machinery/status_display/evac/examine(mob/user)
	. = ..()
	if(mode == SD_EMERGENCY)
		. += examine_shuttle(user, SSshuttle.emergency)
	else if(!message1 && !message2)
		. += "The display is blank."

/obj/machinery/status_display/evac/receive_signal(datum/signal/signal)
	switch(signal.data["command"])
		if("blank")
			mode = SD_BLANK
			set_message(null, null)
		if("shuttle")
			mode = SD_EMERGENCY
			set_message(null, null)
		if("message")
			mode = SD_MESSAGE
			set_message(signal.data["msg1"], signal.data["msg2"])
		if("alert")
			mode = SD_PICTURE
			last_picture = signal.data["picture_state"]
			set_picture(last_picture)
		if("friendcomputer")
			friendc = !friendc
	update()

#undef CHARS_PER_LINE
#undef FONT_SIZE
#undef FONT_COLOR
#undef FONT_STYLE
#undef SCROLL_SPEED
