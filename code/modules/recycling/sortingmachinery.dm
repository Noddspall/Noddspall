/obj/structure/big_delivery
	name = "large parcel"
	desc = "A large delivery parcel."
	icon = 'icons/obj/storage.dmi'
	icon_state = "deliverycloset"
	density = TRUE
	mouse_drag_pointer = MOUSE_ACTIVE_POINTER
	var/giftwrapped = FALSE
	var/sort_tag = 0
	var/obj/item/paper/note

/obj/structure/big_delivery/Initialize()
	. = ..()
	RegisterSignal(src, COMSIG_MOVABLE_DISPOSING, .proc/disposal_handling)

/obj/structure/big_delivery/interact(mob/user)
	to_chat(user, SPAN_NOTICE("You start to unwrap the package..."))
	if(!do_after(user, 15, target = user))
		return
	playsound(src.loc, 'sound/items/poster_ripped.ogg', 50, TRUE)
	new /obj/effect/decal/cleanable/wrapping(get_turf(user))
	unwrap_contents()
	qdel(src)

/obj/structure/big_delivery/Destroy()
	var/turf/T = get_turf(src)
	for(var/atom/movable/AM in contents)
		AM.forceMove(T)
	return ..()

/obj/structure/big_delivery/contents_explosion(severity, target)
	switch(severity)
		if(EXPLODE_DEVASTATE)
			SSexplosions.high_mov_atom += contents
		if(EXPLODE_HEAVY)
			SSexplosions.med_mov_atom += contents
		if(EXPLODE_LIGHT)
			SSexplosions.low_mov_atom += contents

/obj/structure/big_delivery/examine(mob/user)
	. = ..()
	if(note)
		if(!in_range(user, src))
			. += "There's a [note.name] attached to it. You can't read it from here."
		else
			. += "There's a [note.name] attached to it..."
			. += note.examine(user)

/obj/structure/big_delivery/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/dest_tagger))
		var/obj/item/dest_tagger/O = W

		if(sort_tag != O.currTag)
			var/tag = uppertext(GLOB.TAGGERLOCATIONS[O.currTag])
			to_chat(user, SPAN_NOTICE("*[tag]*"))
			sort_tag = O.currTag
			playsound(loc, 'sound/machines/twobeep_high.ogg', 100, TRUE)

	else if(istype(W, /obj/item/pen))
		if(!user.is_literate())
			to_chat(user, SPAN_NOTICE("You scribble illegibly on the side of [src]!"))
			return
		var/str = stripped_input(user, "Label text?", "Set label", "", MAX_NAME_LEN)
		if(!user.canUseTopic(src, BE_CLOSE))
			return
		if(!str || !length(str))
			to_chat(user, SPAN_WARNING("Invalid text!"))
			return
		user.visible_message(SPAN_NOTICE("[user] labels [src] as [str]."))
		name = "[name] ([str])"

	else if(istype(W, /obj/item/stack/wrapping_paper) && !giftwrapped)
		var/obj/item/stack/wrapping_paper/WP = W
		if(WP.use(3))
			user.visible_message(SPAN_NOTICE("[user] wraps the package in festive paper!"))
			giftwrapped = TRUE
			icon_state = "gift[icon_state]"
			greyscale_config = text2path("/datum/greyscale_config/[icon_state]")
			set_greyscale(colors = WP.greyscale_colors)
		else
			to_chat(user, SPAN_WARNING("You need more paper!"))

	else if(istype(W, /obj/item/paper))
		if(note)
			to_chat(user, SPAN_WARNING("This package already has a note attached!"))
			return
		if(!user.transferItemToLoc(W, src))
			to_chat(user, SPAN_WARNING("For some reason, you can't attach [W]!"))
			return
		user.visible_message(SPAN_NOTICE("[user] attaches [W] to [src]."), SPAN_NOTICE("You attach [W] to [src]."))
		note = W
		var/overlaystring = "[icon_state]_note"
		if(giftwrapped)
			overlaystring = copytext(overlaystring, 5) //5 == length("gift") + 1
		add_overlay(overlaystring)


	else
		return ..()

/obj/structure/big_delivery/relay_container_resist_act(mob/living/user, obj/O)
	if(ismovable(loc))
		var/atom/movable/AM = loc //can't unwrap the wrapped container if it's inside something.
		AM.relay_container_resist_act(user, O)
		return
	to_chat(user, SPAN_NOTICE("You lean on the back of [O] and start pushing to rip the wrapping around it."))
	if(do_after(user, 50, target = O))
		if(!user || user.stat != CONSCIOUS || user.loc != O || O.loc != src )
			return
		to_chat(user, SPAN_NOTICE("You successfully removed [O]'s wrapping !"))
		O.forceMove(loc)
		playsound(src.loc, 'sound/items/poster_ripped.ogg', 50, TRUE)
		new /obj/effect/decal/cleanable/wrapping(get_turf(user))
		unwrap_contents()
		qdel(src)
	else
		if(user.loc == src) //so we don't get the message if we resisted multiple times and succeeded.
			to_chat(user, SPAN_WARNING("You fail to remove [O]'s wrapping!"))

/obj/structure/big_delivery/proc/unwrap_contents()
	for(var/obj/I in src.GetAllContents())
		SEND_SIGNAL(I, COMSIG_STRUCTURE_UNWRAPPED)

/obj/structure/big_delivery/proc/disposal_handling(disposal_source, obj/structure/disposalholder/disposal_holder, obj/machinery/disposal/disposal_machine, hasmob)
	SIGNAL_HANDLER
	if(!hasmob)
		disposal_holder.destinationTag = sort_tag

/obj/item/small_delivery
	name = "parcel"
	desc = "A brown paper delivery parcel."
	icon = 'icons/obj/storage.dmi'
	icon_state = "deliverypackage3"
	inhand_icon_state = "deliverypackage"
	var/giftwrapped = 0
	var/sort_tag = 0
	var/obj/item/paper/note

/obj/item/small_delivery/Initialize()
	. = ..()
	RegisterSignal(src, COMSIG_MOVABLE_DISPOSING, .proc/disposal_handling)

/obj/item/small_delivery/contents_explosion(severity, target)
	switch(severity)
		if(EXPLODE_DEVASTATE)
			SSexplosions.high_mov_atom += contents
		if(EXPLODE_HEAVY)
			SSexplosions.med_mov_atom += contents
		if(EXPLODE_LIGHT)
			SSexplosions.low_mov_atom += contents

/obj/item/small_delivery/attack_self(mob/user)
	to_chat(user, SPAN_NOTICE("You start to unwrap the package..."))
	if(!do_after(user, 15, target = user))
		return
	user.temporarilyRemoveItemFromInventory(src, TRUE)
	unwrap_contents()
	for(var/X in contents)
		var/atom/movable/AM = X
		user.put_in_hands(AM)
	playsound(src.loc, 'sound/items/poster_ripped.ogg', 50, TRUE)
	new /obj/effect/decal/cleanable/wrapping(get_turf(user))
	qdel(src)


/obj/item/small_delivery/attack_self_tk(mob/user)
	if(ismob(loc))
		var/mob/M = loc
		M.temporarilyRemoveItemFromInventory(src, TRUE)
		for(var/X in contents)
			var/atom/movable/AM = X
			M.put_in_hands(AM)
	else
		for(var/X in contents)
			var/atom/movable/AM = X
			AM.forceMove(src.loc)
	playsound(src.loc, 'sound/items/poster_ripped.ogg', 50, TRUE)
	new /obj/effect/decal/cleanable/wrapping(get_turf(user))
	unwrap_contents()
	qdel(src)
	return COMPONENT_CANCEL_ATTACK_CHAIN


/obj/item/small_delivery/examine(mob/user)
	. = ..()
	if(note)
		if(!in_range(user, src))
			. += "There's a [note.name] attached to it. You can't read it from here."
		else
			. += "There's a [note.name] attached to it..."
			. += note.examine(user)

/obj/item/small_delivery/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/dest_tagger))
		var/obj/item/dest_tagger/O = W

		if(sort_tag != O.currTag)
			var/tag = uppertext(GLOB.TAGGERLOCATIONS[O.currTag])
			to_chat(user, SPAN_NOTICE("*[tag]*"))
			sort_tag = O.currTag
			playsound(loc, 'sound/machines/twobeep_high.ogg', 100, TRUE)

	else if(istype(W, /obj/item/pen))
		if(!user.is_literate())
			to_chat(user, SPAN_NOTICE("You scribble illegibly on the side of [src]!"))
			return
		var/str = stripped_input(user, "Label text?", "Set label", "", MAX_NAME_LEN)
		if(!user.canUseTopic(src, BE_CLOSE))
			return
		if(!str || !length(str))
			to_chat(user, SPAN_WARNING("Invalid text!"))
			return
		user.visible_message(SPAN_NOTICE("[user] labels [src] as [str]."))
		name = "[name] ([str])"

	else if(istype(W, /obj/item/stack/wrapping_paper) && !giftwrapped)
		var/obj/item/stack/wrapping_paper/WP = W
		if(WP.use(1))
			user.visible_message(SPAN_NOTICE("[user] wraps the package in festive paper!"))
			giftwrapped = TRUE
			icon_state = "gift[icon_state]"
			greyscale_config = text2path("/datum/greyscale_config/[icon_state]")
			set_greyscale(colors = WP.greyscale_colors)
		else
			to_chat(user, SPAN_WARNING("You need more paper!"))

	else if(istype(W, /obj/item/paper))
		if(note)
			to_chat(user, SPAN_WARNING("This package already has a note attached!"))
			return
		if(!user.transferItemToLoc(W, src))
			to_chat(user, SPAN_WARNING("For some reason, you can't attach [W]!"))
			return
		user.visible_message(SPAN_NOTICE("[user] attaches [W] to [src]."), SPAN_NOTICE("You attach [W] to [src]."))
		note = W
		var/overlaystring = "[icon_state]_note"
		if(giftwrapped)
			overlaystring = copytext_char(overlaystring, 5) //5 == length("gift") + 1
		add_overlay(overlaystring)

/obj/item/small_delivery/proc/unwrap_contents()
	for(var/obj/I in src.GetAllContents())
		SEND_SIGNAL(I, COMSIG_ITEM_UNWRAPPED)

/obj/item/small_delivery/proc/disposal_handling(disposal_source, obj/structure/disposalholder/disposal_holder, obj/machinery/disposal/disposal_machine, hasmob)
	SIGNAL_HANDLER
	if(!hasmob)
		disposal_holder.destinationTag = sort_tag

/obj/item/dest_tagger
	name = "destination tagger"
	desc = "Used to set the destination of properly wrapped packages."
	icon = 'icons/obj/device.dmi'
	icon_state = "cargotagger"
	worn_icon_state = "cargotagger"
	var/currTag = 0 //Destinations are stored in code\globalvars\lists\flavor_misc.dm
	var/locked_destination = FALSE //if true, users can't open the destination tag window to prevent changing the tagger's current destination
	w_class =  WEIGHT_CLASS_TINY
	inhand_icon_state = "electronic"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BELT

/obj/item/dest_tagger/suicide_act(mob/living/user)
	user.visible_message(SPAN_SUICIDE("[user] begins tagging [user.p_their()] final destination! It looks like [user.p_theyre()] trying to commit suicide!"))
	if (islizard(user))
		to_chat(user, SPAN_NOTICE("*HELL*"))//lizard nerf
	else
		to_chat(user, SPAN_NOTICE("*HEAVEN*"))
	playsound(src, 'sound/machines/twobeep_high.ogg', 100, TRUE)
	return BRUTELOSS

/obj/item/dest_tagger/proc/openwindow(mob/user)
	var/dat = "<tt><center><h1><b>TagMaster 2.2</b></h1></center>"

	dat += "<table style='width:100%; padding:4px;'><tr>"
	for (var/i = 1, i <= GLOB.TAGGERLOCATIONS.len, i++)
		dat += "<td><a href='?src=[REF(src)];nextTag=[i]'>[GLOB.TAGGERLOCATIONS[i]]</a></td>"

		if(i%4==0)
			dat += "</tr><tr>"

	dat += "</tr></table><br>Current Selection: [currTag ? GLOB.TAGGERLOCATIONS[currTag] : "None"]</tt>"

	user << browse(dat, "window=destTagScreen;size=450x350")
	onclose(user, "destTagScreen")

/obj/item/dest_tagger/attack_self(mob/user)
	if(!locked_destination)
		openwindow(user)
		return

/obj/item/dest_tagger/Topic(href, href_list)
	add_fingerprint(usr)
	if(href_list["nextTag"])
		var/n = text2num(href_list["nextTag"])
		currTag = n
	openwindow(usr)
