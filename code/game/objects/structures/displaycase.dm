/obj/structure/displaycase
	name = "display case"
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "glassbox"
	desc = "A display case for prized possessions."
	density = TRUE
	anchored = TRUE
	resistance_flags = ACID_PROOF
	armor = list(MELEE = 30, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 10, BIO = 0, RAD = 0, FIRE = 70, ACID = 100)
	max_integrity = 200
	integrity_failure = 0.25
	var/obj/item/showpiece = null
	var/obj/item/showpiece_type = null //This allows for showpieces that can only hold items if they're the same istype as this.
	var/alert = TRUE
	var/open = FALSE
	var/openable = TRUE
	var/custom_glass_overlay = FALSE ///If we have a custom glass overlay to use.
	var/obj/item/electronics/airlock/electronics
	var/start_showpiece_type = null //add type for items on display
	var/list/start_showpieces = list() //Takes sublists in the form of list("type" = /obj/item/bikehorn, "trophy_message" = "henk")
	var/trophy_message = ""
	var/glass_fix = TRUE

/obj/structure/displaycase/Initialize()
	. = ..()
	if(start_showpieces.len && !start_showpiece_type)
		var/list/showpiece_entry = pick(start_showpieces)
		if (showpiece_entry && showpiece_entry["type"])
			start_showpiece_type = showpiece_entry["type"]
			if (showpiece_entry["trophy_message"])
				trophy_message = showpiece_entry["trophy_message"]
	if(start_showpiece_type)
		showpiece = new start_showpiece_type (src)
	update_appearance()

/obj/structure/displaycase/vv_edit_var(vname, vval)
	. = ..()
	if(vname in list(NAMEOF(src, open), NAMEOF(src, showpiece), NAMEOF(src, custom_glass_overlay)))
		update_appearance()

/obj/structure/displaycase/handle_atom_del(atom/A)
	if(A == electronics)
		electronics = null
	if(A == showpiece)
		showpiece = null
		update_appearance()
	return ..()

/obj/structure/displaycase/Destroy()
	QDEL_NULL(electronics)
	QDEL_NULL(showpiece)
	return ..()

/obj/structure/displaycase/examine(mob/user)
	. = ..()
	if(alert)
		. += SPAN_NOTICE("Hooked up with an anti-theft system.")
	if(showpiece)
		. += SPAN_NOTICE("There's \a [showpiece] inside.")
	if(trophy_message)
		. += "The plaque reads:\n [trophy_message]"

/obj/structure/displaycase/proc/dump()
	if(QDELETED(showpiece))
		return
	showpiece.forceMove(drop_location())
	showpiece = null
	update_appearance()

/obj/structure/displaycase/play_attack_sound(damage_amount, damage_type = BRUTE, damage_flag = 0)
	switch(damage_type)
		if(BRUTE)
			playsound(src, 'sound/effects/glasshit.ogg', 75, TRUE)
		if(BURN)
			playsound(src, 'sound/items/welder.ogg', 100, TRUE)

/obj/structure/displaycase/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		dump()
		if(!disassembled)
			new /obj/item/shard(drop_location())
			trigger_alarm()
	qdel(src)

/obj/structure/displaycase/obj_break(damage_flag)
	. = ..()
	if(!broken && !(flags_1 & NODECONSTRUCT_1))
		set_density(FALSE)
		broken = TRUE
		new /obj/item/shard(drop_location())
		playsound(src, "shatter", 70, TRUE)
		update_appearance()
		trigger_alarm()

///Anti-theft alarm triggered when broken.
/obj/structure/displaycase/proc/trigger_alarm()
	if(!alert)
		return
	var/area/alarmed = get_area(src)
	alarmed.burglaralert(src)
	playsound(src, 'sound/effects/alert.ogg', 50, TRUE)

/obj/structure/displaycase/update_overlays()
	. = ..()
	if(showpiece)
		var/mutable_appearance/showpiece_overlay = mutable_appearance(showpiece.icon, showpiece.icon_state)
		showpiece_overlay.copy_overlays(showpiece)
		showpiece_overlay.transform *= 0.6
		. += showpiece_overlay
	if(custom_glass_overlay)
		return
	if(broken)
		. += "[initial(icon_state)]_broken"
		return
	if(!open)
		. += "[initial(icon_state)]_closed"
		return

/obj/structure/displaycase/attackby(obj/item/W, mob/living/user, params)
	if(W.GetID() && !broken && openable)
		if(allowed(user))
			to_chat(user,  SPAN_NOTICE("You [open ? "close":"open"] [src]."))
			toggle_lock(user)
		else
			to_chat(user,  SPAN_ALERT("Access denied."))
	else if(W.tool_behaviour == TOOL_WELDER && !user.combat_mode && !broken)
		if(obj_integrity < max_integrity)
			if(!W.tool_start_check(user, amount=5))
				return

			to_chat(user, SPAN_NOTICE("You begin repairing [src]..."))
			if(W.use_tool(src, user, 40, amount=5, volume=50))
				obj_integrity = max_integrity
				update_appearance()
				to_chat(user, SPAN_NOTICE("You repair [src]."))
		else
			to_chat(user, SPAN_WARNING("[src] is already in good condition!"))
		return
	else if(!alert && W.tool_behaviour == TOOL_CROWBAR && openable) //Only applies to the lab cage and player made display cases
		if(broken)
			if(showpiece)
				to_chat(user, SPAN_WARNING("Remove the displayed object first!"))
			else
				to_chat(user, SPAN_NOTICE("You remove the destroyed case."))
				qdel(src)
		else
			to_chat(user, SPAN_NOTICE("You start to [open ? "close":"open"] [src]..."))
			if(W.use_tool(src, user, 20))
				to_chat(user,  SPAN_NOTICE("You [open ? "close":"open"] [src]."))
				toggle_lock(user)
	else if(open && !showpiece)
		insert_showpiece(W, user)
	else if(glass_fix && broken && istype(W, /obj/item/stack/sheet/glass))
		var/obj/item/stack/sheet/glass/G = W
		if(G.get_amount() < 2)
			to_chat(user, SPAN_WARNING("You need two glass sheets to fix the case!"))
			return
		to_chat(user, SPAN_NOTICE("You start fixing [src]..."))
		if(do_after(user, 20, target = src))
			G.use(2)
			broken = FALSE
			obj_integrity = max_integrity
			update_appearance()
	else
		return ..()

/obj/structure/displaycase/proc/insert_showpiece(obj/item/wack, mob/user)
	if(showpiece_type && !istype(wack, showpiece_type))
		to_chat(user, SPAN_NOTICE("This doesn't belong in this kind of display."))
		return TRUE
	if(user.transferItemToLoc(wack, src))
		showpiece = wack
		to_chat(user, SPAN_NOTICE("You put [wack] on display."))
		update_appearance()

/obj/structure/displaycase/proc/toggle_lock(mob/user)
	open = !open
	update_appearance()

/obj/structure/displaycase/attack_paw(mob/user, list/modifiers)
	return attack_hand(user, modifiers)

/obj/structure/displaycase/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	user.changeNext_move(CLICK_CD_MELEE)
	if (showpiece && (broken || open))
		to_chat(user, SPAN_NOTICE("You deactivate the hover field built into the case."))
		log_combat(user, src, "deactivates the hover field of")
		dump()
		add_fingerprint(user)
		return
	else
	    //prevents remote "kicks" with TK
		if (!Adjacent(user))
			return
		if (!user.combat_mode)
			if(!user.is_blind())
				user.examinate(src)
			return
		user.visible_message(SPAN_DANGER("[user] kicks the display case."), null, null, COMBAT_MESSAGE_RANGE)
		log_combat(user, src, "kicks")
		user.do_attack_animation(src, ATTACK_EFFECT_KICK)
		take_damage(2)

/obj/structure/displaycase_chassis
	anchored = TRUE
	density = FALSE
	name = "display case chassis"
	desc = "The wooden base of a display case."
	icon = 'icons/obj/stationobjs.dmi'
	icon_state = "glassbox_chassis"
	var/obj/item/electronics/airlock/electronics


/obj/structure/displaycase_chassis/attackby(obj/item/I, mob/user, params)
	if(I.tool_behaviour == TOOL_WRENCH) //The player can only deconstruct the wooden frame
		to_chat(user, SPAN_NOTICE("You start disassembling [src]..."))
		I.play_tool_sound(src)
		if(I.use_tool(src, user, 30))
			playsound(src.loc, 'sound/items/deconstruct.ogg', 50, TRUE)
			new /obj/item/stack/sheet/mineral/wood(get_turf(src), 5)
			qdel(src)

	else if(istype(I, /obj/item/electronics/airlock))
		to_chat(user, SPAN_NOTICE("You start installing the electronics into [src]..."))
		I.play_tool_sound(src)
		if(do_after(user, 30, target = src) && user.transferItemToLoc(I,src))
			electronics = I
			to_chat(user, SPAN_NOTICE("You install the airlock electronics."))


	else if(istype(I, /obj/item/stack/sheet/glass))
		var/obj/item/stack/sheet/glass/G = I
		if(G.get_amount() < 10)
			to_chat(user, SPAN_WARNING("You need ten glass sheets to do this!"))
			return
		to_chat(user, SPAN_NOTICE("You start adding [G] to [src]..."))
		if(do_after(user, 20, target = src))
			G.use(10)
			var/obj/structure/displaycase/noalert/display = new(src.loc)
			if(electronics)
				electronics.forceMove(display)
				display.electronics = electronics
				if(electronics.one_access)
					display.req_one_access = electronics.accesses
				else
					display.req_access = electronics.accesses
			qdel(src)
	else
		return ..()

//The lab cage and captain's display case do not spawn with electronics, which is why req_access is needed.
/obj/structure/displaycase/captain
	start_showpiece_type = /obj/item/gun/energy/laser/captain
	req_access = list(ACCESS_CENT_SPECOPS) //this was intentional, presumably to make it slightly harder for caps to grab their gun roundstart

/obj/structure/displaycase/labcage
	name = "lab cage"
	desc = "A glass lab container for storing interesting creatures."
	start_showpiece_type = /obj/item/clothing/mask/facehugger/lamarr
	req_access = list(ACCESS_RD)

/obj/structure/displaycase/noalert
	alert = FALSE

/obj/structure/displaycase/trophy
	name = "trophy display case"
	desc = "Store your trophies of accomplishment in here, and they will stay forever."
	var/placer_key = ""
	var/added_roundstart = TRUE
	var/is_locked = TRUE
	integrity_failure = 0
	openable = FALSE

/obj/structure/displaycase/trophy/Initialize()
	. = ..()
	GLOB.trophy_cases += src

/obj/structure/displaycase/trophy/Destroy()
	GLOB.trophy_cases -= src
	return ..()

/obj/structure/displaycase/trophy/attackby(obj/item/W, mob/living/user, params)

	if(!user.Adjacent(src)) //no TK museology
		return
	if(user.combat_mode)
		return ..()
	if(W.tool_behaviour == TOOL_WELDER && !broken)
		return ..()

	if(user.is_holding_item_of_type(/obj/item/key/displaycase))
		if(added_roundstart)
			is_locked = !is_locked
			to_chat(user, SPAN_NOTICE("You [!is_locked ? "un" : ""]lock the case."))
		else
			to_chat(user, SPAN_WARNING("The lock is stuck shut!"))
		return

	if(is_locked)
		to_chat(user, SPAN_WARNING("The case is shut tight with an old-fashioned physical lock. Maybe you should ask the curator for the key?"))
		return

	if(!added_roundstart)
		to_chat(user, SPAN_WARNING("You've already put something new in this case!"))
		return

	if(user.transferItemToLoc(W, src))

		if(showpiece)
			to_chat(user, SPAN_NOTICE("You press a button, and [showpiece] descends into the floor of the case."))
			QDEL_NULL(showpiece)

		to_chat(user, SPAN_NOTICE("You insert [W] into the case."))
		showpiece = W
		added_roundstart = FALSE
		update_appearance()

		placer_key = user.ckey

		trophy_message = W.desc //default value

		var/chosen_plaque = stripped_input(user, "What would you like the plaque to say? Default value is item's description.", "Trophy Plaque")
		if(chosen_plaque)
			if(user.Adjacent(src))
				trophy_message = chosen_plaque
				to_chat(user, SPAN_NOTICE("You set the plaque's text."))
			else
				to_chat(user, SPAN_WARNING("You are too far to set the plaque's text!"))

		SSpersistence.SaveTrophy(src)
		return TRUE

	else
		to_chat(user, SPAN_WARNING("\The [W] is stuck to your hand, you can't put it in the [src.name]!"))

	return

/obj/structure/displaycase/trophy/dump()
	if (showpiece)
		if(added_roundstart)
			visible_message(SPAN_DANGER("The [showpiece] crumbles to dust!"))
			new /obj/effect/decal/cleanable/ash(loc)
			QDEL_NULL(showpiece)
		else
			return ..()

/obj/item/key/displaycase
	name = "display case key"
	desc = "The key to the curator's display cases."

/obj/item/showpiece_dummy
	name = "Cheap replica"

/obj/item/showpiece_dummy/Initialize(mapload, path)
	. = ..()
	var/obj/item/I = path
	name = initial(I.name)
	icon = initial(I.icon)
	icon_state = initial(I.icon_state)
