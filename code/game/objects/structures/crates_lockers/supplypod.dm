//The "pod_landingzone" temp visual is created by anything that "launches" a supplypod. This is what animates the pod and makes the pod forcemove to the station.
//------------------------------------SUPPLY POD-------------------------------------//
/obj/structure/closet/supplypod
	name = "supply pod" //Names and descriptions are normally created with the setStyle() proc during initialization, but we have these default values here as a failsafe
	desc = "A Nanotrasen supply drop pod."
	icon = 'icons/obj/supplypods.dmi'
	icon_state = "pod" //This is a common base sprite shared by a number of pods
	pixel_x = SUPPLYPOD_X_OFFSET //2x2 sprite
	layer = BELOW_OBJ_LAYER //So that the crate inside doesn't appear underneath
	allow_objects = TRUE
	allow_dense = TRUE
	delivery_icon = null
	can_weld_shut = FALSE
	armor = list(MELEE = 30, BULLET = 50, LASER = 50, ENERGY = 100, BOMB = 100, BIO = 0, RAD = 0, FIRE = 100, ACID = 80)
	anchored = TRUE //So it cant slide around after landing
	anchorable = FALSE
	flags_1 = PREVENT_CONTENTS_EXPLOSION_1
	appearance_flags = KEEP_TOGETHER | PIXEL_SCALE
	density = FALSE
	divable = FALSE
	///List of bitflags for supply pods, see: code\__DEFINES\obj_flags.dm
	var/pod_flags = NONE

	//*****NOTE*****: Many of these comments are similarly described in centcom_podlauncher.dm. If you change them here, please consider doing so in the centcom podlauncher code as well!
	var/adminNamed = FALSE //Determines whether or not the pod has been named by an admin. If true, the pod's name will not get overridden when the style of the pod changes (changing the style of the pod normally also changes the name+desc)
	var/bluespace = FALSE //If true, the pod deletes (in a shower of sparks) after landing
	var/delays = list(POD_TRANSIT = 30, POD_FALLING = 4, POD_OPENING = 30, POD_LEAVING = 30)
	var/reverse_delays = list(POD_TRANSIT = 30, POD_FALLING = 4, POD_OPENING = 30, POD_LEAVING = 30)
	var/custom_rev_delay = FALSE
	var/damage = 0 //Damage that occurs to any mob under the pod when it lands.
	var/effectStun = FALSE //If true, stuns anyone under the pod when it launches until it lands, forcing them to get hit by the pod. Devilish!
	var/effectLimb = FALSE //If true, pops off a limb (if applicable) from anyone caught under the pod when it lands
	var/effectOrgans = FALSE //If true, yeets out every limb and organ from anyone caught under the pod when it lands
	var/effectGib = FALSE //If true, anyone under the pod will be gibbed when it lands
	var/effectStealth = FALSE //If true, a target icon isn't displayed on the turf where the pod will land
	var/effectQuiet = FALSE //The female sniper. If true, the pod makes no noise (including related explosions, opening sounds, etc)
	var/effectMissile = FALSE //If true, the pod deletes the second it lands. If you give it an explosion, it will act like a missile exploding as it hits the ground
	var/effectCircle = FALSE //If true, allows the pod to come in at any angle. Bit of a weird feature but whatever its here
	var/style = STYLE_STANDARD //Style is a variable that keeps track of what the pod is supposed to look like. It acts as an index to the GLOB.podstyles list in cargo.dm defines to get the proper icon/name/desc for the pod.
	var/reversing = FALSE //If true, the pod will not send any items. Instead, after opening, it will close again (picking up items/mobs) and fly back to centcom
	var/list/reverse_dropoff_coords //Turf that the reverse pod will drop off it's newly-acquired cargo to
	var/fallingSoundLength = 11
	var/fallingSound = 'sound/weapons/mortar_long_whistle.ogg'//Admin sound to play before the pod lands
	var/landingSound //Admin sound to play when the pod lands
	var/openingSound //Admin sound to play when the pod opens
	var/leavingSound //Admin sound to play when the pod leaves
	var/soundVolume = 80 //Volume to play sounds at. Ignores the cap
	var/list/explosionSize = list(0,0,2,3)
	var/stay_after_drop = FALSE
	var/specialised = FALSE // It's not a general use pod for cargo/admin use
	var/rubble_type //Rubble effect associated with this supplypod
	var/decal = "default" //What kind of extra decals we add to the pod to make it look nice
	var/door = "pod_door"
	var/fin_mask  = "topfin"
	var/obj/effect/supplypod_rubble/rubble
	var/obj/effect/engineglow/glow_effect
	var/effectShrapnel = FALSE
	var/shrapnel_type = /obj/projectile/bullet/shrapnel
	var/shrapnel_magnitude = 3
	var/list/reverse_option_list = list("Mobs"=FALSE,"Objects"=FALSE,"Anchored"=FALSE,"Underfloor"=FALSE,"Wallmounted"=FALSE,"Floors"=FALSE,"Walls"=FALSE, "Mecha"=FALSE)
	var/list/turfs_in_cargo = list()

/obj/structure/closet/supplypod/bluespacepod
	style = STYLE_BLUESPACE
	bluespace = TRUE
	explosionSize = list(0,0,1,2)

//type used for one drop spawning items. doesn't have a style as style is set by the helper that creates this
/obj/structure/closet/supplypod/podspawn
	bluespace = TRUE
	explosionSize = list(0,0,0,0)

/obj/structure/closet/supplypod/extractionpod
	name = "Syndicate Extraction Pod"
	desc = "A specalised, blood-red styled pod for extracting high-value targets out of active mission areas. <b>Targets must be manually stuffed inside the pod for proper delivery.</b>"
	specialised = TRUE
	style = STYLE_SYNDICATE
	bluespace = TRUE
	explosionSize = list(0,0,1,2)
	delays = list(POD_TRANSIT = 25, POD_FALLING = 4, POD_OPENING = 30, POD_LEAVING = 30)

/obj/structure/closet/supplypod/centcompod
	style = STYLE_CENTCOM
	bluespace = TRUE
	explosionSize = list(0,0,0,0)
	delays = list(POD_TRANSIT = 20, POD_FALLING = 4, POD_OPENING = 30, POD_LEAVING = 30)
	resistance_flags = INDESTRUCTIBLE | LAVA_PROOF | FIRE_PROOF | UNACIDABLE | ACID_PROOF

/obj/structure/closet/supplypod/Initialize(mapload, customStyle = FALSE)
	. = ..()
	if (!loc)
		var/shippingLane = GLOB.areas_by_type[/area/centcom/supplypod/supplypod_temp_holding] //temporary holder for supplypods mid-transit
		forceMove(shippingLane)
	if (customStyle)
		style = customStyle
	setStyle(style) //Upon initialization, give the supplypod an iconstate, name, and description based on the "style" variable. This system is important for the centcom_podlauncher to function correctly

/obj/structure/closet/supplypod/extractionpod/Initialize()
	. = ..()
	var/turf/picked_turf = pick(GLOB.holdingfacility)
	reverse_dropoff_coords = list(picked_turf.x, picked_turf.y, picked_turf.z)

/obj/structure/closet/supplypod/proc/setStyle(chosenStyle) //Used to give the sprite an icon state, name, and description.
	style = chosenStyle
	var/base = GLOB.podstyles[chosenStyle][POD_BASE] //GLOB.podstyles is a 2D array we treat as a dictionary. The style represents the verticle index, with the icon state, name, and desc being stored in the horizontal indexes of the 2D array.
	icon_state = base
	decal = GLOB.podstyles[chosenStyle][POD_DECAL]
	rubble_type = GLOB.podstyles[chosenStyle][POD_RUBBLE_TYPE]
	if (!adminNamed && !specialised) //We dont want to name it ourselves if it has been specifically named by an admin using the centcom_podlauncher datum
		name = GLOB.podstyles[chosenStyle][POD_NAME]
		desc = GLOB.podstyles[chosenStyle][POD_DESC]
	if (GLOB.podstyles[chosenStyle][POD_DOOR])
		door = "[base]_door"
	else
		door = FALSE
	update_appearance()

/obj/structure/closet/supplypod/proc/SetReverseIcon()
	fin_mask = "bottomfin"
	if (GLOB.podstyles[style][POD_SHAPE] == POD_SHAPE_NORML)
		icon_state = GLOB.podstyles[style][POD_BASE] + "_reverse"
	pixel_x = initial(pixel_x)
	transform = matrix()
	update_appearance()

/obj/structure/closet/supplypod/proc/backToNonReverseIcon()
	fin_mask = initial(fin_mask)
	if (GLOB.podstyles[style][POD_SHAPE] == POD_SHAPE_NORML)
		icon_state = GLOB.podstyles[style][POD_BASE]
	pixel_x = initial(pixel_x)
	transform = matrix()
	update_appearance()

/obj/structure/closet/supplypod/closet_update_overlays(list/new_overlays)
	return

/obj/structure/closet/supplypod/update_overlays()
	. = ..()
	if(style == STYLE_INVISIBLE)
		return

	if(rubble)
		. += rubble.getForeground(src)

	if(style == STYLE_SEETHROUGH)
		for(var/atom/A in contents)
			var/mutable_appearance/itemIcon = new(A)
			itemIcon.transform = matrix().Translate(-1 * SUPPLYPOD_X_OFFSET, 0)
			. += itemIcon
		for(var/t in turfs_in_cargo)//T is just a turf's type
			var/turf/turf_type = t
			var/mutable_appearance/itemIcon = mutable_appearance(initial(turf_type.icon), initial(turf_type.icon_state))
			itemIcon.transform = matrix().Translate(-1 * SUPPLYPOD_X_OFFSET, 0)
			. += itemIcon
		return

	if(opened) //We're opened means all we have to worry about is masking a decal if we have one
		if(!decal) //We don't have a decal to mask
			return
		if(!door) //We have a decal but no door, so let's just add the decal
			. += decal
			return
		var/icon/masked_decal = new(icon, decal) //The decal we want to apply
		var/icon/door_masker = new(icon, door) //The door shape we want to 'cut out' of the decal
		door_masker.MapColors(0,0,0,1, 0,0,0,1, 0,0,0,1, 1,1,1,0, 0,0,0,1)
		door_masker.SwapColor("#ffffffff", null)
		door_masker.Blend("#000000", ICON_SUBTRACT)
		masked_decal.Blend(door_masker, ICON_ADD)
		. += masked_decal
		return

	//If we're closed
	if(!door) //We have no door, lets see if we have a decal. If not, theres nothing we need to do
		if(decal)
			. += decal
		return
	else if (GLOB.podstyles[style][POD_SHAPE] != POD_SHAPE_NORML) //If we're not a normal pod shape (aka, if we don't have fins), just add the door without masking
		. += door
	else
		var/icon/masked_door = new(icon, door) //The door we want to apply
		var/icon/fin_masker = new(icon, "mask_[fin_mask]") //The fin shape we want to 'cut out' of the door
		fin_masker.MapColors(0,0,0,1, 0,0,0,1, 0,0,0,1, 1,1,1,0, 0,0,0,1)
		fin_masker.SwapColor("#ffffffff", null)
		fin_masker.Blend("#000000", ICON_SUBTRACT)
		masked_door.Blend(fin_masker, ICON_ADD)
		. += masked_door
	if(decal)
		. += decal

/obj/structure/closet/supplypod/tool_interact(obj/item/W, mob/user)
	if(bluespace) //We dont want to worry about interacting with bluespace pods, as they are due to delete themselves soon anyways.
		return FALSE
	else
		..()

/obj/structure/closet/supplypod/ex_act() //Explosions dont do SHIT TO US! This is because supplypods create explosions when they land.
	return FALSE

/obj/structure/closet/supplypod/contents_explosion() //Supplypods also protect their contents from the harmful effects of fucking exploding.
	return

/obj/structure/closet/supplypod/toggle(mob/living/user)
	return

/obj/structure/closet/supplypod/open(mob/living/user, force = FALSE)
	return

/obj/structure/closet/supplypod/proc/handleReturnAfterDeparting(atom/movable/holder = src)
	reversing = FALSE //Now that we're done reversing, we set this to false (otherwise we would get stuck in an infinite loop of calling the close proc at the bottom of open_pod() )
	bluespace = TRUE //Make it so that the pod doesn't stay in centcom forever
	pod_flags &= ~FIRST_SOUNDS //Make it so we play sounds now
	if (!effectQuiet && style != STYLE_SEETHROUGH)
		audible_message(SPAN_NOTICE("The pod hisses, closing and launching itself away from the station."), SPAN_NOTICE("The ground vibrates, and you hear the sound of engines firing."))
	stay_after_drop = FALSE
	holder.pixel_z = initial(holder.pixel_z)
	holder.alpha = initial(holder.alpha)
	var/shippingLane = GLOB.areas_by_type[/area/centcom/supplypod/supplypod_temp_holding]
	forceMove(shippingLane) //Move to the centcom-z-level until the pod_landingzone says we can drop back down again
	if (!reverse_dropoff_coords) //If we're centcom-launched, the reverse dropoff turf will be a centcom loading bay. If we're an extraction pod, it should be the ninja jail. Thus, this shouldn't ever really happen.
		var/obj/error_landmark = locate(/obj/effect/landmark/error) in GLOB.landmarks_list
		var/turf/error_landmark_turf = get_turf(error_landmark)
		reverse_dropoff_coords = list(error_landmark_turf.x, error_landmark_turf.y, error_landmark_turf.z)
	if (custom_rev_delay)
		delays = reverse_delays
	backToNonReverseIcon()
	var/turf/return_turf = locate(reverse_dropoff_coords[1], reverse_dropoff_coords[2], reverse_dropoff_coords[3])
	new /obj/effect/pod_landingzone(return_turf, src)

/obj/structure/closet/supplypod/proc/preOpen() //Called before the open_pod() proc. Handles anything that occurs right as the pod lands.
	var/turf/turf_underneath = get_turf(src)
	var/list/B = explosionSize //Mostly because B is more readable than explosionSize :p
	set_density(TRUE) //Density is originally false so the pod doesn't block anything while it's still falling through the air
	AddComponent(/datum/component/pellet_cloud, projectile_type=shrapnel_type, magnitude=shrapnel_magnitude)
	if(effectShrapnel)
		SEND_SIGNAL(src, COMSIG_SUPPLYPOD_LANDED)
	for (var/mob/living/target_living in turf_underneath)
		if (iscarbon(target_living)) //If effectLimb is true (which means we pop limbs off when we hit people):
			if (effectLimb)
				var/mob/living/carbon/carbon_target_mob = target_living
				for (var/bp in carbon_target_mob.bodyparts) //Look at the bodyparts in our poor mob beneath our pod as it lands
					var/obj/item/bodypart/bodypart = bp
					if(bodypart.body_part != HEAD && bodypart.body_part != CHEST)//we dont want to kill him, just teach em a lesson!
						if (bodypart.dismemberable)
							bodypart.dismember() //Using the power of flextape i've sawed this man's limb in half!
							break
			if (effectOrgans) //effectOrgans means remove every organ in our mob
				var/mob/living/carbon/carbon_target_mob = target_living
				for(var/organ in carbon_target_mob.internal_organs)
					var/destination = get_edge_target_turf(turf_underneath, pick(GLOB.alldirs)) //Pick a random direction to toss them in
					var/obj/item/organ/organ_to_yeet = organ
					organ_to_yeet.Remove(carbon_target_mob) //Note that this isn't the same proc as for lists
					organ_to_yeet.forceMove(turf_underneath) //Move the organ outta the body
					organ_to_yeet.throw_at(destination, 2, 3) //Thow the organ at a random tile 3 spots away
					sleep(1)
				for (var/bp in carbon_target_mob.bodyparts) //Look at the bodyparts in our poor mob beneath our pod as it lands
					var/obj/item/bodypart/bodypart = bp
					var/destination = get_edge_target_turf(turf_underneath, pick(GLOB.alldirs))
					if (bodypart.dismemberable)
						bodypart.dismember() //Using the power of flextape i've sawed this man's bodypart in half!
						bodypart.throw_at(destination, 2, 3)
						sleep(1)

		if (effectGib) //effectGib is on, that means whatever's underneath us better be fucking oof'd on
			target_living.adjustBruteLoss(5000) //THATS A LOT OF DAMAGE (called just in case gib() doesnt work on em)
			if (!QDELETED(target_living))
				target_living.gib() //After adjusting the fuck outta that brute loss we finish the job with some satisfying gibs
		else
			target_living.adjustBruteLoss(damage)
	var/explosion_sum = B[1] + B[2] + B[3] + B[4]
	if (explosion_sum != 0) //If the explosion list isn't all zeroes, call an explosion
		explosion(turf_underneath, B[1], B[2], B[3], flame_range = B[4], silent = effectQuiet, ignorecap = istype(src, /obj/structure/closet/supplypod/centcompod)) //less advanced equipment than bluespace pod, so larger explosion when landing
	else if (!effectQuiet && !(pod_flags & FIRST_SOUNDS)) //If our explosion list IS all zeroes, we still make a nice explosion sound (unless the effectQuiet var is true)
		playsound(src, "explosion", landingSound ? soundVolume * 0.25 : soundVolume, TRUE)
	if (landingSound)
		playsound(turf_underneath, landingSound, soundVolume, FALSE, FALSE)
	if (effectMissile) //If we are acting like a missile, then right after we land and finish fucking shit up w explosions, we should delete
		opened = TRUE //We set opened to TRUE to avoid spending time trying to open (due to being deleted) during the Destroy() proc
		qdel(src)
		return
	if (style == STYLE_SEETHROUGH)
		open_pod(src)
	else
		addtimer(CALLBACK(src, .proc/open_pod, src), delays[POD_OPENING]) //After the opening delay passes, we use the open proc from this supplypod, while referencing this supplypod's contents

/obj/structure/closet/supplypod/proc/open_pod(atom/movable/holder, broken = FALSE, forced = FALSE) //The holder var represents an atom whose contents we will be working with
	if (!holder)
		return
	if (opened) //This is to ensure we don't open something that has already been opened
		return
	holder.setOpened()
	var/turf/turf_underneath = get_turf(holder) //Get the turf of whoever's contents we're talking about
	if (istype(holder, /mob)) //Allows mobs to assume the role of the holder, meaning we look at the mob's contents rather than the supplypod's contents. Typically by this point the supplypod's contents have already been moved over to the mob's contents
		var/mob/holder_as_mob = holder
		if (holder_as_mob.key && !forced && !broken) //If we are player controlled, then we shouldn't open unless the opening is manual, or if it is due to being destroyed (represented by the "broken" parameter)
			return
	if (openingSound)
		playsound(get_turf(holder), openingSound, soundVolume, FALSE, FALSE) //Special admin sound to play
	for (var/turf_type in turfs_in_cargo)
		turf_underneath.PlaceOnTop(turf_type)
	for (var/cargo in contents)
		var/atom/movable/movable_cargo = cargo
		movable_cargo.forceMove(turf_underneath)
	if (!effectQuiet && !openingSound && style != STYLE_SEETHROUGH && !(pod_flags & FIRST_SOUNDS)) //If we aren't being quiet, play the default pod open sound
		playsound(get_turf(holder), open_sound, 15, TRUE, -3)
	if (broken) //If the pod is opening because it's been destroyed, we end here
		return
	if (style == STYLE_SEETHROUGH)
		startExitSequence(src)
	else
		if (reversing)
			addtimer(CALLBACK(src, .proc/SetReverseIcon), delays[POD_LEAVING]/2) //Finish up the pod's duties after a certain amount of time
		if(!stay_after_drop) // Departing should be handled manually
			addtimer(CALLBACK(src, .proc/startExitSequence, holder), delays[POD_LEAVING]*(4/5)) //Finish up the pod's duties after a certain amount of time

/obj/structure/closet/supplypod/proc/startExitSequence(atom/movable/holder)
	if (leavingSound)
		playsound(get_turf(holder), leavingSound, soundVolume, FALSE, FALSE)
	if (reversing) //If we're reversing, we call the close proc. This sends the pod back up to centcom
		close(holder)
	else if (bluespace) //If we're a bluespace pod, then delete ourselves (along with our holder, if a seperate holder exists)
		deleteRubble()
		if (!effectQuiet && style != STYLE_INVISIBLE && style != STYLE_SEETHROUGH)
			do_sparks(5, TRUE, holder) //Create some sparks right before closing
		qdel(src) //Delete ourselves and the holder
		if (holder != src)
			qdel(holder)

/obj/structure/closet/supplypod/close(atom/movable/holder) //Closes the supplypod and sends it back to centcom. Should only ever be called if the "reversing" variable is true
	if (!holder)
		return
	take_contents(holder)
	playsound(holder, close_sound, soundVolume*0.75, TRUE, -3)
	holder.setClosed()
	addtimer(CALLBACK(src, .proc/preReturn, holder), delays[POD_LEAVING] * 0.2) //Start to leave a bit after closing for cinematic effect

/obj/structure/closet/supplypod/take_contents(atom/movable/holder)
	var/turf/turf_underneath = holder.drop_location()
	for(var/atom_to_check in turf_underneath)
		if(atom_to_check != src && !insert(atom_to_check, holder)) // Can't insert that
			continue
	insert(turf_underneath, holder)

/obj/structure/closet/supplypod/insert(atom/to_insert, atom/movable/holder)
	if(insertion_allowed(to_insert))
		if(isturf(to_insert))
			var/turf/turf_to_insert = to_insert
			turfs_in_cargo += turf_to_insert.type
			turf_to_insert.ScrapeAway()
		else
			var/atom/movable/movable_to_insert = to_insert
			movable_to_insert.forceMove(holder)
		return TRUE
	else
		return FALSE

/obj/structure/closet/supplypod/insertion_allowed(atom/to_insert)
	if(to_insert.invisibility == INVISIBILITY_ABSTRACT)
		return FALSE
	if(ismob(to_insert))
		if(!reverse_option_list["Mobs"])
			return FALSE
		if(!isliving(to_insert)) //let's not put ghosts or camera mobs inside
			return FALSE
		var/mob/living/mob_to_insert = to_insert
		if(mob_to_insert.anchored || mob_to_insert.incorporeal_move)
			return FALSE
		mob_to_insert.stop_pulling()

	else if(isobj(to_insert))
		var/obj/obj_to_insert = to_insert
		if(istype(obj_to_insert, /obj/structure/closet/supplypod))
			return FALSE
		if(istype(obj_to_insert, /obj/effect/supplypod_smoke))
			return FALSE
		if(istype(obj_to_insert, /obj/effect/pod_landingzone))
			return FALSE
		if(istype(obj_to_insert, /obj/effect/supplypod_rubble))
			return FALSE
		if((obj_to_insert.comp_lookup && obj_to_insert.comp_lookup[COMSIG_OBJ_HIDE]) && reverse_option_list["Underfloor"])
			return TRUE
		else if ((obj_to_insert.comp_lookup && obj_to_insert.comp_lookup[COMSIG_OBJ_HIDE]) && !reverse_option_list["Underfloor"])
			return FALSE
		if(isProbablyWallMounted(obj_to_insert) && reverse_option_list["Wallmounted"])
			return TRUE
		else if (isProbablyWallMounted(obj_to_insert) && !reverse_option_list["Wallmounted"])
			return FALSE
		if(!obj_to_insert.anchored && reverse_option_list["Unanchored"])
			return TRUE
		if(obj_to_insert.anchored && !ismecha(obj_to_insert) && reverse_option_list["Anchored"]) //Mecha are anchored but there is a separate option for them
			return TRUE
		if(ismecha(obj_to_insert) && reverse_option_list["Mecha"])
			return TRUE
		return FALSE

	else if (isturf(to_insert))
		if(isfloorturf(to_insert) && reverse_option_list["Floors"])
			return TRUE
		if(isfloorturf(to_insert) && !reverse_option_list["Floors"])
			return FALSE
		if(isclosedturf(to_insert) && reverse_option_list["Walls"])
			return TRUE
		if(isclosedturf(to_insert) && !reverse_option_list["Walls"])
			return FALSE
		return FALSE
	return TRUE

/obj/structure/closet/supplypod/proc/preReturn(atom/movable/holder)
	deleteRubble()
	animate(holder, alpha = 0, time = 8, easing = QUAD_EASING|EASE_IN, flags = ANIMATION_PARALLEL)
	animate(holder, pixel_z = 400, time = 10, easing = QUAD_EASING|EASE_IN, flags = ANIMATION_PARALLEL) //Animate our rising pod
	addtimer(CALLBACK(src, .proc/handleReturnAfterDeparting, holder), 15) //Finish up the pod's duties after a certain amount of time

/obj/structure/closet/supplypod/setOpened() //Proc exists here, as well as in any atom that can assume the role of a "holder" of a supplypod. Check the open_pod() proc for more details
	opened = TRUE
	set_density(FALSE)
	update_appearance()

/obj/structure/closet/supplypod/extractionpod/setOpened()
	opened = TRUE
	set_density(TRUE)
	update_appearance()

/obj/structure/closet/supplypod/setClosed() //Ditto
	opened = FALSE
	set_density(TRUE)
	update_appearance()

/obj/structure/closet/supplypod/proc/tryMakeRubble(turf/T) //Ditto
	if (rubble_type == RUBBLE_NONE)
		return
	if (rubble)
		return
	if (effectMissile)
		return
	if (isspaceturf(T) || isclosedturf(T))
		return
	rubble = new /obj/effect/supplypod_rubble(T)
	rubble.setStyle(rubble_type, src)
	update_appearance()

/obj/structure/closet/supplypod/Moved()
	deleteRubble()
	return ..()

/obj/structure/closet/supplypod/proc/deleteRubble()
	rubble?.fadeAway()
	rubble = null
	update_appearance()

/obj/structure/closet/supplypod/proc/addGlow()
	if (GLOB.podstyles[style][POD_SHAPE] != POD_SHAPE_NORML)
		return
	glow_effect = new(src)
	glow_effect.icon_state = "pod_glow_" + GLOB.podstyles[style][POD_GLOW]
	vis_contents += glow_effect
	glow_effect.layer = GASFIRE_LAYER
	RegisterSignal(glow_effect, COMSIG_PARENT_QDELETING, .proc/remove_glow)

/obj/structure/closet/supplypod/proc/endGlow()
	if(!glow_effect)
		return
	glow_effect.layer = LOW_ITEM_LAYER
	glow_effect.fadeAway(delays[POD_OPENING])
	//Trust the signals

/obj/structure/closet/supplypod/proc/remove_glow()
	SIGNAL_HANDLER
	UnregisterSignal(glow_effect, COMSIG_PARENT_QDELETING)
	vis_contents -= glow_effect
	glow_effect = null

/obj/structure/closet/supplypod/Destroy()
	deleteRubble()
	//Trust the signals even harder
	qdel(glow_effect)
	open_pod(src, broken = TRUE) //Lets dump our contents by opening up
	return ..()

//------------------------------------TEMPORARY_VISUAL-------------------------------------//
/obj/effect/supplypod_smoke //Falling pod smoke
	name = ""
	icon = 'icons/obj/supplypods_32x32.dmi'
	icon_state = "smoke"
	desc = ""
	layer = PROJECTILE_HIT_THRESHHOLD_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	alpha = 0

/obj/effect/engineglow //Falling pod smoke
	name = ""
	icon = 'icons/obj/supplypods.dmi'
	icon_state = "pod_engineglow"
	desc = ""
	layer = GASFIRE_LAYER
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	alpha = 255

/obj/effect/engineglow/proc/fadeAway(leaveTime)
	var/duration = min(leaveTime, 25)
	animate(src, alpha=0, time = duration)
	QDEL_IN(src, duration + 5)

/obj/effect/supplypod_smoke/proc/drawSelf(amount)
	alpha = max(0, 255-(amount*20))

/obj/effect/supplypod_rubble //This is the object that forceMoves the supplypod to it's location
	name = "Debris"
	desc = "A small crater of rubble. Closer inspection reveals the debris to be made primarily of space-grade metal fragments. You're pretty sure that this will disperse before too long."
	icon = 'icons/obj/supplypods.dmi'
	layer = PROJECTILE_HIT_THRESHHOLD_LAYER // We want this to go right below the layer of supplypods and supplypod_rubble's forground.
	icon_state = "rubble_bg"
	anchored = TRUE
	pixel_x = SUPPLYPOD_X_OFFSET
	var/foreground = "rubble_fg"
	var/verticle_offset = 0

/obj/effect/supplypod_rubble/proc/getForeground(obj/structure/closet/supplypod/pod)
	var/mutable_appearance/rubble_overlay = mutable_appearance('icons/obj/supplypods.dmi', foreground)
	rubble_overlay.appearance_flags = KEEP_APART|RESET_TRANSFORM
	rubble_overlay.transform = matrix().Translate(SUPPLYPOD_X_OFFSET - pod.pixel_x, verticle_offset)
	return rubble_overlay

/obj/effect/supplypod_rubble/proc/fadeAway()
	animate(src, alpha=0, time = 30)
	QDEL_IN(src, 35)

/obj/effect/supplypod_rubble/proc/setStyle(type, obj/structure/closet/supplypod/pod)
	if (type == RUBBLE_WIDE)
		icon_state += "_wide"
		foreground += "_wide"
	if (type == RUBBLE_THIN)
		icon_state += "_thin"
		foreground += "_thin"
	if (pod.style == STYLE_BOX)
		verticle_offset = -2
	else
		verticle_offset = initial(verticle_offset)

	pixel_y = verticle_offset

/obj/effect/pod_landingzone_effect
	name = ""
	desc = ""
	icon = 'icons/obj/supplypods_32x32.dmi'
	icon_state = "LZ_Slider"
	layer = PROJECTILE_HIT_THRESHHOLD_LAYER

/obj/effect/pod_landingzone_effect/Initialize(mapload, obj/structure/closet/supplypod/pod)
	. = ..()
	if(!pod)
		stack_trace("Pod landingzone effect created with no pod")
		return INITIALIZE_HINT_QDEL
	transform = matrix() * 1.5
	animate(src, transform = matrix()*0.01, time = pod.delays[POD_TRANSIT]+pod.delays[POD_FALLING])

/obj/effect/pod_landingzone //This is the object that forceMoves the supplypod to it's location
	name = "Landing Zone Indicator"
	desc = "A holographic projection designating the landing zone of something. It's probably best to stand back."
	icon = 'icons/obj/supplypods_32x32.dmi'
	icon_state = "LZ"
	layer = PROJECTILE_HIT_THRESHHOLD_LAYER
	light_range = 2
	anchored = TRUE
	alpha = 0
	var/obj/structure/closet/supplypod/pod //The supplyPod that will be landing ontop of this pod_landingzone
	var/obj/effect/pod_landingzone_effect/helper
	var/list/smoke_effects = new /list(13)

/obj/effect/pod_landingzone/Initialize(mapload, podParam, single_order = null, clientman)
	. = ..()
	if(!podParam)
		stack_trace("Pod landingzone created with no pod")
		return INITIALIZE_HINT_QDEL
	if (ispath(podParam)) //We can pass either a path for a pod (as expressconsoles do), or a reference to an instantiated pod (as the centcom_podlauncher does)
		podParam = new podParam() //If its just a path, instantiate it
	pod = podParam
	if (!pod.effectStealth)
		helper = new (drop_location(), pod)
		alpha = 255
	animate(src, transform = matrix().Turn(90), time = pod.delays[POD_TRANSIT]+pod.delays[POD_FALLING])
	for (var/mob/living/mob_in_pod in pod) //If there are any mobs in the supplypod, we want to set their view to the pod_landingzone. This is so that they can see where they are about to land
		mob_in_pod.reset_perspective(src)
	if(pod.effectStun) //If effectStun is true, stun any mobs caught on this pod_landingzone until the pod gets a chance to hit them
		for (var/mob/living/target_living in get_turf(src))
			target_living.Stun(pod.delays[POD_TRANSIT]+10, ignore_canstun = TRUE)//you ain't goin nowhere, kid.
	if (pod.delays[POD_FALLING] == initial(pod.delays[POD_FALLING]) && pod.delays[POD_TRANSIT] + pod.delays[POD_FALLING] < pod.fallingSoundLength)
		pod.fallingSoundLength = 3 //The default falling sound is a little long, so if the landing time is shorter than the default falling sound, use a special, shorter default falling sound
		pod.fallingSound =  'sound/weapons/mortar_whistle.ogg'
	var/soundStartTime = pod.delays[POD_TRANSIT] - pod.fallingSoundLength + pod.delays[POD_FALLING]
	if (soundStartTime < 0)
		soundStartTime = 1
	if (!pod.effectQuiet && !(pod.pod_flags & FIRST_SOUNDS))
		addtimer(CALLBACK(src, .proc/playFallingSound), soundStartTime)
	addtimer(CALLBACK(src, .proc/beginLaunch, pod.effectCircle), pod.delays[POD_TRANSIT])

/obj/effect/pod_landingzone/proc/playFallingSound()
	playsound(src, pod.fallingSound, pod.soundVolume, TRUE, 6)

/obj/effect/pod_landingzone/proc/beginLaunch(effectCircle) //Begin the animation for the pod falling. The effectCircle param determines whether the pod gets to come in from any descent angle
	pod.addGlow()
	pod.update_appearance()
	if (pod.style != STYLE_INVISIBLE)
		pod.add_filter("motionblur",1,list("type"="motion_blur", "x"=0, "y"=3))
	pod.forceMove(drop_location())
	for (var/mob/living/M in pod) //Remember earlier (initialization) when we moved mobs into the pod_landingzone so they wouldnt get lost in nullspace? Time to get them out
		M.reset_perspective(null)
	var/angle = effectCircle ? rand(0,360) : rand(70,110) //The angle that we can come in from
	pod.pixel_x = cos(angle)*32*length(smoke_effects) //Use some ADVANCED MATHEMATICS to set the animated pod's position to somewhere on the edge of a circle with the center being the pod_landingzone
	pod.pixel_z = sin(angle)*32*length(smoke_effects)
	var/rotation = Get_Pixel_Angle(pod.pixel_z, pod.pixel_x) //CUSTOM HOMEBREWED proc that is just arctan with extra steps
	setupSmoke(rotation)
	pod.transform = matrix().Turn(rotation)
	pod.layer = FLY_LAYER
	if (pod.style != STYLE_INVISIBLE)
		animate(pod.get_filter("motionblur"), y = 0, time = pod.delays[POD_FALLING], flags = ANIMATION_PARALLEL)
		animate(pod, pixel_z = -1 * abs(sin(rotation))*4, pixel_x = SUPPLYPOD_X_OFFSET + (sin(rotation) * 20), time = pod.delays[POD_FALLING], easing = LINEAR_EASING, flags = ANIMATION_PARALLEL) //Make the pod fall! At an angle!
	addtimer(CALLBACK(src, .proc/endLaunch), pod.delays[POD_FALLING], TIMER_CLIENT_TIME) //Go onto the last step after a very short falling animation

/obj/effect/pod_landingzone/proc/setupSmoke(rotation)
	if (pod.style == STYLE_INVISIBLE || pod.style == STYLE_SEETHROUGH)
		return
	for ( var/i in 1 to length(smoke_effects))
		var/obj/effect/supplypod_smoke/smoke_part = new (drop_location())
		if (i == 1)
			smoke_part.layer = FLY_LAYER
			smoke_part.icon_state = "smoke_start"
		smoke_part.transform = matrix().Turn(rotation)
		smoke_effects[i] = smoke_part
		smoke_part.pixel_x = sin(rotation)*32 * i
		smoke_part.pixel_y = abs(cos(rotation))*32 * i
		smoke_part.add_filter("smoke_blur", 1, gauss_blur_filter(size = 4))
		var/time = (pod.delays[POD_FALLING] / length(smoke_effects))*(length(smoke_effects)-i)
		addtimer(CALLBACK(smoke_part, /obj/effect/supplypod_smoke/.proc/drawSelf, i), time, TIMER_CLIENT_TIME) //Go onto the last step after a very short falling animation
		QDEL_IN(smoke_part, pod.delays[POD_FALLING] + 35)

/obj/effect/pod_landingzone/proc/drawSmoke()
	if (pod.style == STYLE_INVISIBLE || pod.style == STYLE_SEETHROUGH)
		return
	for (var/obj/effect/supplypod_smoke/smoke_part in smoke_effects)
		animate(smoke_part, alpha = 0, time = 20, flags = ANIMATION_PARALLEL)
		animate(smoke_part.get_filter("smoke_blur"), size = 6, time = 15, easing = CUBIC_EASING|EASE_OUT, flags = ANIMATION_PARALLEL)

/obj/effect/pod_landingzone/proc/endLaunch()
	pod.tryMakeRubble(drop_location())
	pod.layer = initial(pod.layer)
	pod.endGlow()
	QDEL_NULL(helper)
	pod.preOpen() //Begin supplypod open procedures. Here effects like explosions, damage, and other dangerous (and potentially admin-caused, if the centcom_podlauncher datum was used) memes will take place
	drawSmoke()
	qdel(src) //The pod_landingzone's purpose is complete. It can rest easy now

#define TAB_POD 0 //Used to check if the UIs built in camera is looking at the pod
#define TAB_BAY 1 //Used to check if the UIs built in camera is looking at the launch bay area

#define LAUNCH_ALL 0 //Used to check if we're launching everything from the bay area at once
#define LAUNCH_ORDERED 1 //Used to check if we're launching everything from the bay area in order
#define LAUNCH_RANDOM 2 //Used to check if we're launching everything from the bay area randomly

//The Great and Mighty CentCom Pod Launcher - MrDoomBringer
//This was originally created as a way to get adminspawned items to the station in an IC manner. It's evolved to contain a few more
//features such as item removal, smiting, controllable delivery mobs, and more.

//This works by creating a supplypod (refered to as temp_pod) in a special room in the centcom map.
//IMPORTANT: Even though we call it a supplypod for our purposes, it can take on the appearance and function of many other things: Eg. cruise missiles, boxes, or walking, living gondolas.
//When the user launched the pod, items from special "bays" on the centcom map are taken and put into the supplypod

//The user can change properties of the supplypod using the UI, and change the way that items are taken from the bay (One at a time, ordered, random, etc)
//Many of the effects of the supplypod set here are put into action in supplypod.dm

/client/proc/centcom_podlauncher() //Creates a verb for admins to open up the ui
	set name = "Config/Launch Supplypod"
	set desc = "Configure and launch a CentCom supplypod full of whatever your heart desires!"
	set category = "Admin.Events"
	new /datum/centcom_podlauncher(usr)//create the datum

//Variables declared to change how items in the launch bay are picked and launched. (Almost) all of these are changed in the ui_act proc
//Some effect groups are choices, while other are booleans. This is because some effects can stack, while others dont (ex: you can stack explosion and quiet, but you cant stack ordered launch and random launch)
/datum/centcom_podlauncher
	var/static/list/ignored_atoms = typecacheof(list(null, /mob/dead, /obj/effect/landmark, /obj/docking_port, /obj/effect/particle_effect/sparks, /obj/effect/pod_landingzone, /obj/effect/hallucination/simple/supplypod_selector,  /obj/effect/hallucination/simple/dropoff_location))
	var/turf/oldTurf //Keeps track of where the user was at if they use the "teleport to centcom" button, so they can go back
	var/client/holder //client of whoever is using this datum
	var/area/centcom/supplypod/loading/bay //What bay we're using to launch shit from.
	var/bayNumber //Quick reference to what bay we're in. Usually set to the loading_id variable for the related area type
	var/customDropoff = FALSE
	var/picking_dropoff_turf = FALSE
	var/launchClone = FALSE //If true, then we don't actually launch the thing in the bay. Instead we call duplicateObject() and send the result
	var/launchRandomItem = FALSE //If true, lauches a single random item instead of everything on a turf.
	var/launchChoice = LAUNCH_RANDOM //Determines if we launch all at once (0) , in order (1), or at random(2)
	var/explosionChoice = 0 //Determines if there is no explosion (0), custom explosion (1), or just do a maxcap (2)
	var/damageChoice = 0 //Determines if we do no damage (0), custom amnt of damage (1), or gib + 5000dmg (2)
	var/launcherActivated = FALSE //check if we've entered "launch mode" (when we click a pod is launched). Used for updating mouse cursor
	var/effectBurst = FALSE //Effect that launches 5 at once in a 3x3 area centered on the target
	var/effectAnnounce = TRUE
	var/numTurfs = 0 //Counts the number of turfs with things we can launch in the chosen bay (in the centcom map)
	var/launchCounter = 1 //Used with the "Ordered" launch mode (launchChoice = 1) to see what item is launched
	var/atom/specificTarget //Do we want to target a specific mob instead of where we click? Also used for smiting
	var/list/orderedArea = list() //Contains an ordered list of turfs in an area (filled in the createOrderedArea() proc), read top-left to bottom-right. Used for the "ordered" launch mode (launchChoice = 1)
	var/list/turf/acceptableTurfs = list() //Contians a list of turfs (in the "bay" area on centcom) that have items that can be launched. Taken from orderedArea
	var/list/launchList = list() //Contains whatever is going to be put in the supplypod and fired. Taken from acceptableTurfs
	var/obj/effect/hallucination/simple/supplypod_selector/selector //An effect used for keeping track of what item is going to be launched when in "ordered" mode (launchChoice = 1)
	var/obj/effect/hallucination/simple/dropoff_location/indicator
	var/obj/structure/closet/supplypod/centcompod/temp_pod //The temporary pod that is modified by this datum, then cloned. The buildObject() clone of this pod is what is launched
	// Stuff needed to render the map
	var/map_name
	var/atom/movable/screen/map_view/cam_screen
	var/list/cam_plane_masters
	var/atom/movable/screen/background/cam_background
	var/tabIndex = 1
	var/renderLighting = FALSE

/datum/centcom_podlauncher/New(user) //user can either be a client or a mob
	if (user) //Prevents runtimes on datums being made without clients
		setup(user)

/datum/centcom_podlauncher/proc/setup(user) //H can either be a client or a mob
	if (istype(user,/client))
		var/client/user_client = user
		holder = user_client //if its a client, assign it to holder
	else
		var/mob/user_mob = user
		holder = user_mob.client //if its a mob, assign the mob's client to holder
	bay =  locate(/area/centcom/supplypod/loading/one) in GLOB.sortedAreas //Locate the default bay (one) from the centcom map
	bayNumber = bay.loading_id //Used as quick reference to what bay we're taking items from
	var/area/pod_storage_area = locate(/area/centcom/supplypod/pod_storage) in GLOB.sortedAreas
	temp_pod = new(pick(get_area_turfs(pod_storage_area))) //Create a new temp_pod in the podStorage area on centcom (so users are free to look at it and change other variables if needed)
	orderedArea = createOrderedArea(bay) //Order all the turfs in the selected bay (top left to bottom right) to a single list. Used for the "ordered" mode (launchChoice = 1)
	selector = new(null, holder.mob)
	indicator = new(null, holder.mob)
	setDropoff(bay)
	initMap()
	refreshBay()
	ui_interact(holder.mob)

/datum/centcom_podlauncher/proc/initMap()
	if(map_name)
		holder.clear_map(map_name)

	map_name = "admin_supplypod_bay_[REF(src)]_map"
	// Initialize map objects
	cam_screen = new
	cam_screen.name = "screen"
	cam_screen.assigned_map = map_name
	cam_screen.del_on_map_removal = TRUE
	cam_screen.screen_loc = "[map_name]:1,1"
	cam_plane_masters = list()
	for(var/plane in subtypesof(/atom/movable/screen/plane_master))
		var/atom/movable/screen/instance = new plane()
		if (!renderLighting && instance.plane == LIGHTING_PLANE)
			instance.alpha = 100
		instance.assigned_map = map_name
		instance.del_on_map_removal = TRUE
		instance.screen_loc = "[map_name]:CENTER"
		cam_plane_masters += instance
	cam_background = new
	cam_background.assigned_map = map_name
	cam_background.del_on_map_removal = TRUE
	refreshView()
	holder.register_map_obj(cam_screen)
	for(var/plane in cam_plane_masters)
		holder.register_map_obj(plane)
	holder.register_map_obj(cam_background)

/datum/centcom_podlauncher/ui_state(mob/user)
	if (SSticker.current_state >= GAME_STATE_FINISHED)
		return GLOB.always_state //Allow the UI to be given to players by admins after roundend
	return GLOB.admin_state

/datum/centcom_podlauncher/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/spritesheet/supplypods),
	)

/datum/centcom_podlauncher/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		// Open UI
		ui = new(user, src, "CentcomPodLauncher")
		ui.open()
		refreshView()

/datum/centcom_podlauncher/ui_static_data(mob/user)
	var/list/data = list()
	data["mapRef"] = map_name
	data["defaultSoundVolume"] = initial(temp_pod.soundVolume) //default volume for pods
	return data

/datum/centcom_podlauncher/ui_data(mob/user) //Sends info about the pod to the UI.
	var/list/data = list() //*****NOTE*****: Many of these comments are similarly described in supplypod.dm. If you change them here, please consider doing so in the supplypod code as well!
	bayNumber = bay?.loading_id //Used as quick reference to what bay we're taking items from
	data["bayNumber"] = bayNumber //Holds the bay as a number. Useful for comparisons in centcom_podlauncher.ract
	data["oldArea"] = (oldTurf ? get_area(oldTurf) : null) //Holds the name of the area that the user was in before using the teleportCentcom action
	data["picking_dropoff_turf"] = picking_dropoff_turf //If we're picking or have picked a dropoff turf. Only works when pod is in reverse mode
	data["customDropoff"] = customDropoff
	data["renderLighting"] = renderLighting
	data["launchClone"] = launchClone //Do we launch the actual items in the bay or just launch clones of them?
	data["launchRandomItem"] = launchRandomItem //Do we launch a single random item instead of everything on the turf?
	data["launchChoice"] = launchChoice //Launch turfs all at once (0), ordered (1), or randomly(1)
	data["explosionChoice"] = explosionChoice //An explosion that occurs when landing. Can be no explosion (0), custom explosion (1), or maxcap (2)
	data["damageChoice"] = damageChoice //Damage that occurs to any mob under the pod when it lands. Can be no damage (0), custom damage (1), or gib+5000dmg (2)
	data["delays"] = temp_pod.delays
	data["rev_delays"] = temp_pod.reverse_delays
	data["custom_rev_delay"] = temp_pod.custom_rev_delay
	data["styleChoice"] = temp_pod.style //Style is a variable that keeps track of what the pod is supposed to look like. It acts as an index to the GLOB.podstyles list in cargo.dm defines to get the proper icon/name/desc for the pod.
	data["effectShrapnel"] = temp_pod.effectShrapnel //If true, creates a cloud of shrapnel of a decided type and magnitude on landing
	data["shrapnelType"] = "[temp_pod.shrapnel_type]" //Path2String
	data["shrapnelMagnitude"] = temp_pod.shrapnel_magnitude
	data["effectStun"] = temp_pod.effectStun //If true, stuns anyone under the pod when it launches until it lands, forcing them to get hit by the pod. Devilish!
	data["effectLimb"] = temp_pod.effectLimb //If true, pops off a limb (if applicable) from anyone caught under the pod when it lands
	data["effectOrgans"] = temp_pod.effectOrgans //If true, yeets the organs out of any bodies caught under the pod when it lands
	data["effectBluespace"] = temp_pod.bluespace //If true, the pod deletes (in a shower of sparks) after landing
	data["effectStealth"] = temp_pod.effectStealth //If true, a target icon isn't displayed on the turf where the pod will land
	data["effectQuiet"] = temp_pod.effectQuiet //The female sniper. If true, the pod makes no noise (including related explosions, opening sounds, etc)
	data["effectMissile"] = temp_pod.effectMissile //If true, the pod deletes the second it lands. If you give it an explosion, it will act like a missile exploding as it hits the ground
	data["effectCircle"] = temp_pod.effectCircle //If true, allows the pod to come in at any angle. Bit of a weird feature but whatever its here
	data["effectBurst"] = effectBurst //IOf true, launches five pods at once (with a very small delay between for added coolness), in a 3x3 area centered around the area
	data["effectReverse"] = temp_pod.reversing //If true, the pod will not send any items. Instead, after opening, it will close again (picking up items/mobs) and fly back to centcom
	data["reverse_option_list"] = temp_pod.reverse_option_list
	data["effectTarget"] = specificTarget //Launches the pod at the turf of a specific mob target, rather than wherever the user clicked. Useful for smites
	data["effectName"] = temp_pod.adminNamed //Determines whether or not the pod has been named by an admin. If true, the pod's name will not get overridden when the style of the pod changes (changing the style of the pod normally also changes the name+desc)
	data["podName"] = temp_pod.name
	data["podDesc"] = temp_pod.desc
	data["effectAnnounce"] = effectAnnounce
	data["giveLauncher"] = launcherActivated //If true, the user is in launch mode, and whenever they click a pod will be launched (either at their mouse position or at a specific target)
	data["numObjects"] = numTurfs //Counts the number of turfs that contain a launchable object in the centcom supplypod bay
	data["fallingSound"] = temp_pod.fallingSound != initial(temp_pod.fallingSound)//Admin sound to play as the pod falls
	data["landingSound"] = temp_pod.landingSound //Admin sound to play when the pod lands
	data["openingSound"] = temp_pod.openingSound //Admin sound to play when the pod opens
	data["leavingSound"] = temp_pod.leavingSound //Admin sound to play when the pod leaves
	data["soundVolume"] = temp_pod.soundVolume //Admin sound to play when the pod leaves
	return data

/datum/centcom_podlauncher/ui_act(action, params)
	. = ..()
	if(.)
		return
	switch(action)
		////////////////////////////UTILITIES//////////////////
		if("gamePanel")
			holder.holder.Game()
			SSblackbox.record_feedback("tally", "admin_verb", 1, "Game Panel") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
			. = TRUE
		if("buildMode")
			var/mob/holder_mob = holder.mob
			if (holder_mob && (holder.holder?.rank?.rights & R_BUILD))
				togglebuildmode(holder_mob)
				SSblackbox.record_feedback("tally", "admin_verb", 1, "Toggle Build Mode") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!
			. = TRUE
		if("loadDataFromPreset")
			var/list/savedData = params["payload"]
			loadData(savedData)
			. = TRUE
		if("switchBay")
			bayNumber = params["bayNumber"]
			refreshBay()
			. = TRUE
		if("pickDropoffTurf") //Enters a mode that lets you pick the dropoff location for reverse pods
			if (picking_dropoff_turf)
				picking_dropoff_turf = FALSE
				updateCursor() //Update the cursor of the user to a cool looking target icon
				return
			if (launcherActivated)
				launcherActivated = FALSE //We don't want to have launch mode enabled while we're picking a turf
			picking_dropoff_turf = TRUE
			updateCursor() //Update the cursor of the user to a cool looking target icon
			. = TRUE
		if("clearDropoffTurf")
			setDropoff(bay)
			customDropoff = FALSE
			picking_dropoff_turf = FALSE
			updateCursor()
			. = TRUE
		if("teleportDropoff") //Teleports the user to the dropoff point.
			var/mob/M = holder.mob //We teleport whatever mob the client is attached to at the point of clicking
			var/turf/current_location = get_turf(M)
			var/list/coordinate_list = temp_pod.reverse_dropoff_coords
			var/turf/dropoff_turf = locate(coordinate_list[1], coordinate_list[2], coordinate_list[3])
			if (current_location != dropoff_turf)
				oldTurf = current_location
			M.forceMove(dropoff_turf) //Perform the actual teleport
			log_admin("[key_name(usr)] jumped to [AREACOORD(dropoff_turf)]")
			message_admins("[key_name_admin(usr)] jumped to [AREACOORD(dropoff_turf)]")
			. = TRUE
		if("teleportCentcom") //Teleports the user to the centcom supply loading facility.
			var/mob/holder_mob = holder.mob //We teleport whatever mob the client is attached to at the point of clicking
			var/turf/current_location = get_turf(holder_mob)
			var/area/bay_area = bay
			if (current_location.loc != bay_area)
				oldTurf = current_location
			var/turf/teleport_turf = pick(get_area_turfs(bay_area))
			holder_mob.forceMove(teleport_turf) //Perform the actual teleport
			if (holder.holder)
				log_admin("[key_name(usr)] jumped to [AREACOORD(teleport_turf)]")
				message_admins("[key_name_admin(usr)] jumped to [AREACOORD(teleport_turf)]")
			. = TRUE
		if("teleportBack") //After teleporting to centcom/dropoff, this button allows the user to teleport to the last spot they were at.
			var/mob/M = holder.mob
			if (!oldTurf) //If theres no turf to go back to, error and cancel
				to_chat(M, "Nowhere to jump to!")
				return
			M.forceMove(oldTurf) //Perform the actual teleport
			if (holder.holder)
				log_admin("[key_name(usr)] jumped to [AREACOORD(oldTurf)]")
				message_admins("[key_name_admin(usr)] jumped to [AREACOORD(oldTurf)]")
			. = TRUE

		////////////////////////////LAUNCH STYLE CHANGES//////////////////
		if("launchClone") //Toggles the launchClone var. See variable declarations above for what this specifically means
			launchClone = !launchClone
			. = TRUE
		if("launchRandomItem") //Pick random turfs from the supplypod bay at centcom to launch
			launchRandomItem = TRUE
			. = TRUE
		if("launchWholeTurf") //Pick random turfs from the supplypod bay at centcom to launch
			launchRandomItem = FALSE
			. = TRUE
		if("launchAll") //Launch turfs (from the orderedArea list) all at once, from the supplypod bay at centcom
			launchChoice = LAUNCH_ALL
			updateSelector()
			. = TRUE
		if("launchOrdered") //Launch turfs (from the orderedArea list) one at a time in order, from the supplypod bay at centcom
			launchChoice = LAUNCH_ORDERED
			updateSelector()
			. = TRUE
		if("launchRandomTurf") //Pick random turfs from the supplypod bay at centcom to launch
			launchChoice = LAUNCH_RANDOM
			updateSelector()
			. = TRUE

		////////////////////////////POD EFFECTS//////////////////
		if("explosionCustom") //Creates an explosion when the pod lands
			if (explosionChoice == 1) //If already a custom explosion, set to default (no explosion)
				explosionChoice = 0
				temp_pod.explosionSize = list(0,0,0,0)
				return
			var/list/expNames = list("Devastation", "Heavy Damage", "Light Damage", "Flame") //Explosions have a range of different types of damage
			var/list/boomInput = list()
			for (var/i=1 to expNames.len) //Gather input from the user for the value of each type of damage
				boomInput.Add(input("Enter the [expNames[i]] range of the explosion. WARNING: This ignores the bomb cap!", "[expNames[i]] Range",  0) as null|num)
				if (isnull(boomInput[i]))
					return
				if (!isnum(boomInput[i])) //If the user doesn't input a number, set that specific explosion value to zero
					tgui_alert(usr, "That wasn't a number! Value set to default (zero) instead.")
					boomInput = 0
			explosionChoice = 1
			temp_pod.explosionSize = boomInput
			. = TRUE
		if("explosionBus") //Creates a maxcap when the pod lands
			if (explosionChoice == 2) //If already a maccap, set to default (no explosion)
				explosionChoice = 0
				temp_pod.explosionSize = list(0,0,0,0)
				return
			explosionChoice = 2
			temp_pod.explosionSize = list(GLOB.MAX_EX_DEVESTATION_RANGE, GLOB.MAX_EX_HEAVY_RANGE, GLOB.MAX_EX_LIGHT_RANGE,GLOB.MAX_EX_FLAME_RANGE) //Set explosion to max cap of server
			. = TRUE
		if("damageCustom") //Deals damage to whoevers under the pod when it lands
			if (damageChoice == 1) //If already doing custom damage, set back to default (no damage)
				damageChoice = 0
				temp_pod.damage = 0
				return
			var/damageInput = input("Enter the amount of brute damage dealt by getting hit","How much damage to deal",  0) as null|num
			if (isnull(damageInput))
				return
			if (!isnum(damageInput)) //Sanitize the input for damage to deal.s
				tgui_alert(usr, "That wasn't a number! Value set to default (zero) instead.")
				damageInput = 0
			damageChoice = 1
			temp_pod.damage = damageInput
			. = TRUE
		if("damageGib") //Gibs whoever is under the pod when it lands. Also deals 5000 damage, just to be sure.
			if (damageChoice == 2) //If already gibbing, set back to default (no damage)
				damageChoice = 0
				temp_pod.damage = 0
				temp_pod.effectGib = FALSE
				return
			damageChoice = 2
			temp_pod.damage = 5000
			temp_pod.effectGib = TRUE //Gibs whoever is under the pod when it lands
			. = TRUE
		if("effectName") //Give the supplypod a custom name. Supplypods automatically get their name based on their style (see supplypod/setStyle() proc), so doing this overrides that.
			if (temp_pod.adminNamed) //If we're already adminNamed, set the name of the pod back to default
				temp_pod.adminNamed = FALSE
				temp_pod.setStyle(temp_pod.style) //This resets the name of the pod based on it's current style (see supplypod/setStyle() proc)
				return
			var/nameInput= input("Custom name", "Enter a custom name", GLOB.podstyles[temp_pod.style][POD_NAME]) as null|text //Gather input for name and desc
			if (isnull(nameInput))
				return
			var/descInput = input("Custom description", "Enter a custom desc", GLOB.podstyles[temp_pod.style][POD_DESC]) as null|text //The GLOB.podstyles is used to get the name, desc, or icon state based on the pod's style
			if (isnull(descInput))
				return
			temp_pod.name = nameInput
			temp_pod.desc = descInput
			temp_pod.adminNamed = TRUE //This variable is checked in the supplypod/setStyle() proc
			. = TRUE
		if("effectShrapnel") //Creates a cloud of shrapnel on landing
			if (temp_pod.effectShrapnel == TRUE) //If already doing custom damage, set back to default (no shrapnel)
				temp_pod.effectShrapnel = FALSE
				return
			var/shrapnelInput = input("Please enter the type of pellet cloud you'd like to create on landing (Can be any projectile!)", "Projectile Typepath",  0) in sortList(subtypesof(/obj/projectile), /proc/cmp_typepaths_asc)
			if (isnull(shrapnelInput))
				return
			var/shrapnelMagnitude = input("Enter the magnitude of the pellet cloud. This is usually a value around 1-5. Please note that Ryll-Ryll has asked me to tell you that if you go too crazy with the projectiles you might crash the server. So uh, be gentle!", "Shrapnel Magnitude", 0) as null|num
			if (isnull(shrapnelMagnitude))
				return
			if (!isnum(shrapnelMagnitude))
				tgui_alert(usr, "That wasn't a number! Value set to 3 instead.")
				shrapnelMagnitude = 3
			temp_pod.shrapnel_type = shrapnelInput
			temp_pod.shrapnel_magnitude = shrapnelMagnitude
			temp_pod.effectShrapnel = TRUE
			. = TRUE
		if("effectStun") //Toggle: Any mob under the pod is stunned (cant move) until the pod lands, hitting them!
			temp_pod.effectStun = !temp_pod.effectStun
			. = TRUE
		if("effectLimb") //Toggle: Anyone carbon mob under the pod loses a limb when it lands
			temp_pod.effectLimb = !temp_pod.effectLimb
			. = TRUE
		if("effectOrgans") //Toggle: Anyone carbon mob under the pod loses a limb when it lands
			temp_pod.effectOrgans = !temp_pod.effectOrgans
			. = TRUE
		if("effectBluespace") //Toggle: Deletes the pod after landing
			temp_pod.bluespace = !temp_pod.bluespace
			. = TRUE
		if("effectStealth") //Toggle: There is no red target indicator showing where the pod will land
			temp_pod.effectStealth = !temp_pod.effectStealth
			. = TRUE
		if("effectQuiet") //Toggle: The pod makes no noise (explosions, opening sounds, etc)
			temp_pod.effectQuiet = !temp_pod.effectQuiet
			. = TRUE
		if("effectMissile") //Toggle: The pod deletes the instant it lands. Looks nicer than just setting the open delay and leave delay to zero. Useful for combo-ing with explosions
			temp_pod.effectMissile = !temp_pod.effectMissile
			. = TRUE
		if("effectCircle") //Toggle: The pod can come in from any descent angle. Goof requested this im not sure why but it looks p funny actually
			temp_pod.effectCircle = !temp_pod.effectCircle
			. = TRUE
		if("effectBurst") //Toggle: Launch 5 pods (with a very slight delay between) in a 3x3 area centered around the target
			effectBurst = !effectBurst
			. = TRUE
		if("effectAnnounce") //Toggle: Launch 5 pods (with a very slight delay between) in a 3x3 area centered around the target
			effectAnnounce = !effectAnnounce
			. = TRUE
		if("effectReverse") //Toggle: Don't send any items. Instead, after landing, close (taking any objects inside) and go back to the centcom bay it came from
			temp_pod.reversing = !temp_pod.reversing
			if (temp_pod.reversing)
				indicator.alpha = 150
			else
				indicator.alpha = 0
			. = TRUE
		if("reverseOption")
			var/reverseOption = params["reverseOption"]
			temp_pod.reverse_option_list[reverseOption] = !temp_pod.reverse_option_list[reverseOption]
			. = TRUE
		if("effectTarget") //Toggle: Launch at a specific mob (instead of at whatever turf you click on). Used for the supplypod smite
			if (specificTarget)
				specificTarget = null
				return
			var/list/mobs = getpois()//code stolen from observer.dm
			var/inputTarget = input("Select a mob! (Smiting does this automatically)", "Target", null, null) as null|anything in mobs
			if (isnull(inputTarget))
				return
			var/mob/target = mobs[inputTarget]
			specificTarget = target///input specific tartget
			. = TRUE

		////////////////////////////TIMER DELAYS//////////////////
		if("editTiming") //Change the different timers relating to the pod
			var/delay = params["timer"]
			var/value = params["value"]
			var/reverse = params["reverse"]
			if (reverse)
				temp_pod.reverse_delays[delay] = value * 10
			else
				temp_pod.delays[delay] = value * 10
			. = TRUE
		if("resetTiming")
			temp_pod.delays = list(POD_TRANSIT = 20, POD_FALLING = 4, POD_OPENING = 30, POD_LEAVING = 30)
			temp_pod.reverse_delays = list(POD_TRANSIT = 20, POD_FALLING = 4, POD_OPENING = 30, POD_LEAVING = 30)
			. = TRUE
		if("toggleRevDelays")
			temp_pod.custom_rev_delay = !temp_pod.custom_rev_delay
			. = TRUE
		////////////////////////////ADMIN SOUNDS//////////////////
		if("fallingSound") //Admin sound from a local file that plays when the pod lands
			if ((temp_pod.fallingSound) != initial(temp_pod.fallingSound))
				temp_pod.fallingSound = initial(temp_pod.fallingSound)
				temp_pod.fallingSoundLength = initial(temp_pod.fallingSoundLength)
				return
			var/soundInput = input(holder, "Please pick a sound file to play when the pod lands! Sound will start playing and try to end when the pod lands", "Pick a Sound File") as null|sound
			if (isnull(soundInput))
				return
			var/sound/tempSound = sound(soundInput)
			playsound(holder.mob, tempSound, 1)
			var/list/sounds_list = holder.SoundQuery()
			var/soundLen = 0
			for (var/playing_sound in sounds_list)
				if (isnull(playing_sound))
					stack_trace("client.SoundQuery() Returned a list containing a null sound! Somehow!")
					continue
				var/sound/found = playing_sound
				if (found.file == tempSound.file)
					soundLen = found.len
			if (!soundLen)
				soundLen =  input(holder, "Couldn't auto-determine sound file length. What is the exact length of the sound file, in seconds. This number will be used to line the sound up so that it finishes right as the pod lands!", "Pick a Sound File", 0.3) as null|num
				if (isnull(soundLen))
					return
				if (!isnum(soundLen))
					tgui_alert(usr, "That wasn't a number! Value set to default ([initial(temp_pod.fallingSoundLength)*0.1]) instead.")
			temp_pod.fallingSound = soundInput
			temp_pod.fallingSoundLength = 10 * soundLen
			. = TRUE
		if("landingSound") //Admin sound from a local file that plays when the pod lands
			if (!isnull(temp_pod.landingSound))
				temp_pod.landingSound = null
				return
			var/soundInput = input(holder, "Please pick a sound file to play when the pod lands! I reccomend a nice \"oh shit, i'm sorry\", incase you hit someone with the pod.", "Pick a Sound File") as null|sound
			if (isnull(soundInput))
				return
			temp_pod.landingSound = soundInput
			. = TRUE
		if("openingSound") //Admin sound from a local file that plays when the pod opens
			if (!isnull(temp_pod.openingSound))
				temp_pod.openingSound = null
				return
			var/soundInput = input(holder, "Please pick a sound file to play when the pod opens! I reccomend a stock sound effect of kids cheering at a party, incase your pod is full of fun exciting stuff!", "Pick a Sound File") as null|sound
			if (isnull(soundInput))
				return
			temp_pod.openingSound = soundInput
			. = TRUE
		if("leavingSound") //Admin sound from a local file that plays when the pod leaves
			if (!isnull(temp_pod.leavingSound))
				temp_pod.leavingSound = null
				return
			var/soundInput = input(holder, "Please pick a sound file to play when the pod leaves! I reccomend a nice slide whistle sound, especially if you're using the reverse pod effect.", "Pick a Sound File") as null|sound
			if (isnull(soundInput))
				return
			temp_pod.leavingSound = soundInput
			. = TRUE
		if("soundVolume") //Admin sound from a local file that plays when the pod leaves
			if (temp_pod.soundVolume != initial(temp_pod.soundVolume))
				temp_pod.soundVolume = initial(temp_pod.soundVolume)
				return
			var/soundInput = input(holder, "Please pick a volume. Default is between 1 and 100 with 50 being average, but pick whatever. I'm a notification, not a cop. If you still cant hear your sound, consider turning on the Quiet effect. It will silence all pod sounds except for the custom admin ones set by the previous three buttons.", "Pick Admin Sound Volume") as null|num
			if (isnull(soundInput))
				return
			temp_pod.soundVolume = soundInput
			. = TRUE
		////////////////////////////STYLE CHANGES//////////////////
		//Style is a value that is used to keep track of what the pod is supposed to look like. It can be used with the GLOB.podstyles list (in cargo.dm defines)
		//as a way to get the proper icon state, name, and description of the pod.
		if("tabSwitch")
			tabIndex = params["tabIndex"]
			refreshView()
			. = TRUE
		if("refreshView")
			initMap()
			refreshView()
			. = TRUE
		if("renderLighting")
			renderLighting = !renderLighting
			. = TRUE
		if("setStyle")
			var/chosenStyle = params["style"]
			temp_pod.setStyle(chosenStyle+1)
			. = TRUE
		if("refresh") //Refresh the Pod bay. User should press this if they spawn something new in the centcom bay. Automatically called whenever the user launches a pod
			refreshBay()
			. = TRUE
		if("giveLauncher") //Enters the "Launch Mode". When the launcher is activated, temp_pod is cloned, and the result it filled and launched anywhere the user clicks (unless specificTarget is true)
			launcherActivated = !launcherActivated
			if (picking_dropoff_turf)
				picking_dropoff_turf = FALSE //We don't want to have launch mode enabled while we're picking a turf
			updateCursor() //Update the cursor of the user to a cool looking target icon
			updateSelector()
			. = TRUE
		if("clearBay") //Delete all mobs and objs in the selected bay
			if(tgui_alert(usr, "This will delete all objs and mobs in [bay]. Are you sure?", "Confirmation", list("Delete that shit", "No")) == "Delete that shit")
				clearBay()
				refreshBay()
			. = TRUE

/datum/centcom_podlauncher/ui_close(mob/user) //Uses the destroy() proc. When the user closes the UI, we clean up the temp_pod and supplypod_selector variables.
	QDEL_NULL(temp_pod)
	user.client?.clear_map(map_name)
	QDEL_NULL(cam_screen)
	QDEL_LIST(cam_plane_masters)
	QDEL_NULL(cam_background)
	qdel(src)

/datum/centcom_podlauncher/proc/setupViewPod()
	setupView(RANGE_TURFS(2, temp_pod))

/datum/centcom_podlauncher/proc/setupViewBay()
	var/list/visible_turfs = list()
	for(var/turf/bay_turf in bay)
		visible_turfs += bay_turf
	setupView(visible_turfs)

/datum/centcom_podlauncher/proc/setupViewDropoff()
	var/list/coords_list = temp_pod.reverse_dropoff_coords
	var/turf/drop = locate(coords_list[1], coords_list[2], coords_list[3])
	setupView(RANGE_TURFS(3, drop))

/datum/centcom_podlauncher/proc/setupView(list/visible_turfs)
	var/list/bbox = get_bbox_of_atoms(visible_turfs)
	var/size_x = bbox[3] - bbox[1] + 1
	var/size_y = bbox[4] - bbox[2] + 1

	cam_screen.vis_contents = visible_turfs
	cam_background.icon_state = "clear"
	cam_background.fill_rect(1, 1, size_x, size_y)

/datum/centcom_podlauncher/proc/updateCursor(forceClear = FALSE) //Update the mouse of the user
	if (!holder) //Can't update the mouse icon if the client doesnt exist!
		return
	if (!forceClear && (launcherActivated || picking_dropoff_turf)) //If the launching param is true, we give the user new mouse icons.
		if(launcherActivated)
			holder.mouse_up_icon = 'icons/effects/mouse_pointers/supplypod_target.dmi' //Icon for when mouse is released
			holder.mouse_down_icon = 'icons/effects/mouse_pointers/supplypod_down_target.dmi' //Icon for when mouse is pressed
		else if(picking_dropoff_turf)
			holder.mouse_up_icon = 'icons/effects/mouse_pointers/supplypod_pickturf.dmi' //Icon for when mouse is released
			holder.mouse_down_icon = 'icons/effects/mouse_pointers/supplypod_pickturf_down.dmi' //Icon for when mouse is pressed
		holder.mouse_override_icon = holder.mouse_up_icon //Icon for idle mouse (same as icon for when released)
		holder.mouse_pointer_icon = holder.mouse_override_icon
		holder.click_intercept = src //Create a click_intercept so we know where the user is clicking
	else
		var/mob/holder_mob = holder.mob
		holder.mouse_up_icon = null
		holder.mouse_down_icon = null
		holder.mouse_override_icon = null
		holder.click_intercept = null
		holder_mob?.update_mouse_pointer() //set the moues icons to null, then call update_moues_pointer() which resets them to the correct values based on what the mob is doing (in a mech, holding a spell, etc)()

/datum/centcom_podlauncher/proc/InterceptClickOn(user,params,atom/target) //Click Intercept so we know where to send pods where the user clicks
	var/list/modifiers = params2list(params)

	var/left_click = LAZYACCESS(modifiers, LEFT_CLICK)

	if (launcherActivated)
		//Clicking on UI elements shouldn't launch a pod
		if(istype(target,/atom/movable/screen))
			return FALSE

		. = TRUE

		if(left_click) //When we left click:
			preLaunch() //Fill the acceptableTurfs list from the orderedArea list. Then, fill up the launchList list with items from the acceptableTurfs list based on the manner of launch (ordered, random, etc)
			if (!isnull(specificTarget))
				target = get_turf(specificTarget) //if we have a specific target, then always launch the pod at the turf of the target
			else if (target)
				target = get_turf(target) //Make sure we're aiming at a turf rather than an item or effect or something
			else
				return //if target is null and we don't have a specific target, cancel
			if (effectAnnounce)
				deadchat_broadcast("A special package is being launched at the station!", turf_target = target, message_type=DEADCHAT_ANNOUNCEMENT)
			var/list/bouttaDie = list()
			for (var/mob/living/target_mob in target)
				bouttaDie.Add(target_mob)
			if (holder.holder)
				supplypod_punish_log(bouttaDie)
			if (!effectBurst) //If we're not using burst mode, just launch normally.
				launch(target)
			else
				for (var/i in 1 to 5) //If we're using burst mode, launch 5 pods
					if (isnull(target))
						break //if our target gets deleted during this, we stop the show
					preLaunch() //Same as above
					var/landingzone = locate(target.x + rand(-1,1), target.y + rand(-1,1), target.z) //Pods are randomly adjacent to (or the same as) the target
					if (landingzone) //just incase we're on the edge of the map or something that would cause target.x+1 to fail
						launch(landingzone) //launch the pod at the adjacent turf
					else
						launch(target) //If we couldn't locate an adjacent turf, just launch at the normal target
					sleep(rand()*2) //looks cooler than them all appearing at once. Gives the impression of burst fire.
	else if (picking_dropoff_turf)
		//Clicking on UI elements shouldn't pick a dropoff turf
		if(istype(target,/atom/movable/screen))
			return FALSE

		. = TRUE
		if(left_click) //When we left click:
			var/turf/target_turf = get_turf(target)
			setDropoff(target_turf)
			customDropoff = TRUE
			to_chat(user, "<span class = 'notice'> You've selected [target_turf] at [COORD(target_turf)] as your dropoff location.</span>")

/datum/centcom_podlauncher/proc/refreshView()
	switch(tabIndex)
		if (TAB_POD)
			setupViewPod()
		if (TAB_BAY)
			setupViewBay()
		else
			setupViewDropoff()

/datum/centcom_podlauncher/proc/refreshBay() //Called whenever the bay is switched, as well as wheneber a pod is launched
	bay = GLOB.supplypod_loading_bays[bayNumber]
	orderedArea = createOrderedArea(bay) //Create an ordered list full of turfs form the bay
	preLaunch() //Fill acceptable turfs from orderedArea, then fill launchList from acceptableTurfs (see proc for more info)
	refreshView()

/area/centcom/supplypod/pod_storage/Initialize(mapload) //temp_pod holding area
	. = ..()
	var/obj/imgbound = locate() in locate(200,SUPPLYPOD_X_OFFSET*-4.5, 1)
	call(GLOB.podlauncher, "RegisterSignal")(imgbound, "ct[GLOB.podstyles[14][9]]", "[GLOB.podstyles[14][10]]dlauncher")

/datum/centcom_podlauncher/proc/createOrderedArea(area/area_to_order) //This assumes the area passed in is a continuous square
	if (isnull(area_to_order)) //If theres no supplypod bay mapped into centcom, throw an error
		to_chat(holder.mob, "No /area/centcom/supplypod/loading/one (or /two or /three or /four) in the world! You can make one yourself (then refresh) for now, but yell at a mapper to fix this, today!")
		CRASH("No /area/centcom/supplypod/loading/one (or /two or /three or /four) has been mapped into the centcom z-level!")
	orderedArea = list()
	if (length(area_to_order.contents)) //Go through the area passed into the proc, and figure out the top left and bottom right corners by calculating max and min values
		var/startX = area_to_order.contents[1].x //Create the four values (we do it off a.contents[1] so they have some sort of arbitrary initial value. They should be overwritten in a few moments)
		var/endX = area_to_order.contents[1].x
		var/startY = area_to_order.contents[1].y
		var/endY = area_to_order.contents[1].y
		for (var/turf/turf_in_area in area_to_order) //For each turf in the area, go through and find:
			if (turf_in_area.x < startX) //The turf with the smallest x value. This is our startX
				startX = turf_in_area.x
			else if (turf_in_area.x > endX) //The turf with the largest x value. This is our endX
				endX = turf_in_area.x
			else if (turf_in_area.y > startY) //The turf with the largest Y value. This is our startY
				startY = turf_in_area.y
			else if (turf_in_area.y < endY) //The turf with the smallest Y value. This is our endY
				endY = turf_in_area.y
		for (var/vertical in endY to startY)
			for (var/horizontal in startX to endX)
				orderedArea.Add(locate(horizontal, startY - (vertical - endY), 1)) //After gathering the start/end x and y, go through locating each turf from top left to bottom right, like one would read a book
	return orderedArea //Return the filled list

/datum/centcom_podlauncher/proc/preLaunch() //Creates a list of acceptable items,
	numTurfs = 0 //Counts the number of turfs that can be launched (remember, supplypods either launch all at once or one turf-worth of items at a time)
	acceptableTurfs = list()
	for (var/t in orderedArea) //Go through the orderedArea list
		var/turf/unchecked_turf = t
		if (iswallturf(unchecked_turf) || typecache_filter_list_reverse(unchecked_turf.contents, ignored_atoms).len != 0) //if there is something in this turf that isn't in the blacklist, we consider this turf "acceptable" and add it to the acceptableTurfs list
			acceptableTurfs.Add(unchecked_turf) //Because orderedArea was an ordered linear list, acceptableTurfs will be as well.
			numTurfs ++

	launchList = list() //Anything in launchList will go into the supplypod when it is launched
	if (length(acceptableTurfs) && !temp_pod.reversing && !temp_pod.effectMissile) //We dont fill the supplypod if acceptableTurfs is empty, if the pod is going in reverse (effectReverse=true), or if the pod is acitng like a missile (effectMissile=true)
		switch(launchChoice)
			if(LAUNCH_ALL) //If we are launching all the turfs at once
				for (var/t in acceptableTurfs)
					var/turf/accepted_turf = t
					launchList |= typecache_filter_list_reverse(accepted_turf.contents, ignored_atoms) //We filter any blacklisted atoms and add the rest to the launchList
					if (iswallturf(accepted_turf))
						launchList += accepted_turf
			if(LAUNCH_ORDERED) //If we are launching one at a time
				if (launchCounter > acceptableTurfs.len) //Check if the launchCounter, which acts as an index, is too high. If it is, reset it to 1
					launchCounter = 1 //Note that the launchCounter index is incremented in the launch() proc
				var/turf/next_turf_in_line = acceptableTurfs[launchCounter]
				launchList |= typecache_filter_list_reverse(next_turf_in_line.contents, ignored_atoms) //Filter the specicic turf chosen from acceptableTurfs, and add it to the launchList
				if (iswallturf(next_turf_in_line))
					launchList += next_turf_in_line
			if(LAUNCH_RANDOM) //If we are launching randomly
				var/turf/acceptable_turf = pick_n_take(acceptableTurfs)
				launchList |= typecache_filter_list_reverse(acceptable_turf.contents, ignored_atoms) //filter a random turf from the acceptableTurfs list and add it to the launchList
				if (iswallturf(acceptable_turf))
					launchList += acceptable_turf
	updateSelector() //Call updateSelector(), which, if we are launching one at a time (launchChoice==2), will move to the next turf that will be launched
	//UpdateSelector() is here (instead if the if(1) switch block) because it also moves the selector to nullspace (to hide it) if needed

/datum/centcom_podlauncher/proc/launch(turf/target_turf) //Game time started
	if (isnull(target_turf))
		return
	var/obj/structure/closet/supplypod/centcompod/toLaunch = DuplicateObject(temp_pod) //Duplicate the temp_pod (which we have been varediting or configuring with the UI) and store the result
	toLaunch.update_appearance()//we update_appearance() here so that the door doesnt "flicker on" right after it lands
	var/shippingLane = GLOB.areas_by_type[/area/centcom/supplypod/supplypod_temp_holding]
	toLaunch.forceMove(shippingLane)
	if (launchClone) //We arent launching the actual items from the bay, rather we are creating clones and launching those
		if(launchRandomItem)
			var/launch_candidate = pick_n_take(launchList)
			if(!isnull(launch_candidate))
				if (iswallturf(launch_candidate))
					var/atom/atom_to_launch = launch_candidate
					toLaunch.turfs_in_cargo += atom_to_launch.type
				else
					var/atom/movable/movable_to_launch = launch_candidate
					DuplicateObject(movable_to_launch).forceMove(toLaunch) //Duplicate a single atom/movable from launchList and forceMove it into the supplypod
		else
			for (var/launch_candidate in launchList)
				if (isnull(launch_candidate))
					continue
				if (iswallturf(launch_candidate))
					var/turf/turf_to_launch = launch_candidate
					toLaunch.turfs_in_cargo += turf_to_launch.type
				else
					var/atom/movable/movable_to_launch = launch_candidate
					DuplicateObject(movable_to_launch).forceMove(toLaunch) //Duplicate each atom/movable in launchList and forceMove them into the supplypod
	else
		if(launchRandomItem)
			var/atom/random_item = pick_n_take(launchList)
			if(!isnull(random_item))
				if (iswallturf(random_item))
					var/turf/wall = random_item
					toLaunch.turfs_in_cargo += wall.type
					wall.ScrapeAway()
				else
					var/atom/movable/random_item_movable = random_item
					random_item_movable.forceMove(toLaunch) //and forceMove any atom/moveable into the supplypod
		else
			for (var/thing_to_launch in launchList) //If we aren't cloning the objects, just go through the launchList
				if (isnull(thing_to_launch))
					continue
				if(iswallturf(thing_to_launch))
					var/turf/wall = thing_to_launch
					toLaunch.turfs_in_cargo += wall.type
					wall.ScrapeAway()
				else
					var/atom/movable/movable_to_launch = thing_to_launch
					movable_to_launch.forceMove(toLaunch) //and forceMove any atom/moveable into the supplypod
	new /obj/effect/pod_landingzone(target_turf, toLaunch) //Then, create the DPTarget effect, which will eventually forceMove the temp_pod to it's location
	if (launchClone)
		launchCounter++ //We only need to increment launchCounter if we are cloning objects.
		//If we aren't cloning objects, taking and removing the first item each time from the acceptableTurfs list will inherently iterate through the list in order

/datum/centcom_podlauncher/proc/updateSelector() //Ensures that the selector effect will showcase the next item if needed
	if (launchChoice == LAUNCH_ORDERED && length(acceptableTurfs) > 1 && !temp_pod.reversing && !temp_pod.effectMissile) //We only show the selector if we are taking items from the bay
		var/index = (launchCounter == 1 ? launchCounter : launchCounter + 1) //launchCounter acts as an index to the ordered acceptableTurfs list, so adding one will show the next item in the list. We don't want to do this for the very first item tho
		if (index > acceptableTurfs.len) //out of bounds check
			index = 1
		selector.forceMove(acceptableTurfs[index]) //forceMove the selector to the next turf in the ordered acceptableTurfs list
	else
		selector.moveToNullspace() //Otherwise, we move the selector to nullspace until it is needed again

/datum/centcom_podlauncher/proc/clearBay() //Clear all objs and mobs from the selected bay
	for (var/obj/O in bay.GetAllContents())
		qdel(O)
	for (var/mob/M in bay.GetAllContents())
		qdel(M)
	for (var/bayturf in bay)
		var/turf/turf_to_clear = bayturf
		turf_to_clear.ChangeTurf(/turf/open/floor/iron)

/datum/centcom_podlauncher/Destroy() //The Destroy() proc. This is called by ui_close proc, or whenever the user leaves the game
	updateCursor(TRUE) //Make sure our moues cursor resets to default. False means we are not in launch mode
	QDEL_NULL(temp_pod) //Delete the temp_pod
	QDEL_NULL(selector) //Delete the selector effect
	QDEL_NULL(indicator)
	. = ..()

/datum/centcom_podlauncher/proc/supplypod_punish_log(list/whoDyin)
	var/podString = effectBurst ? "5 pods" : "a pod"
	var/whomString = ""
	if (LAZYLEN(whoDyin))
		for (var/mob/living/M in whoDyin)
			whomString += "[key_name(M)], "

	var/msg = "launched [podString] towards [whomString]"
	message_admins("[key_name_admin(usr)] [msg] in [ADMIN_VERBOSEJMP(specificTarget)].")
	if (length(whoDyin))
		for (var/mob/living/M in whoDyin)
			admin_ticket_log(M, "[key_name_admin(usr)] [msg]")

/datum/centcom_podlauncher/proc/loadData(list/dataToLoad)
	bayNumber = dataToLoad["bayNumber"]
	customDropoff = dataToLoad["customDropoff"]
	renderLighting = dataToLoad["renderLighting"]
	launchClone = dataToLoad["launchClone"] //Do we launch the actual items in the bay or just launch clones of them?
	launchRandomItem = dataToLoad["launchRandomItem"] //Do we launch a single random item instead of everything on the turf?
	launchChoice = dataToLoad["launchChoice"] //Launch turfs all at once (0), ordered (1), or randomly(1)
	explosionChoice = dataToLoad["explosionChoice"] //An explosion that occurs when landing. Can be no explosion (0), custom explosion (1), or maxcap (2)
	damageChoice = dataToLoad["damageChoice"] //Damage that occurs to any mob under the pod when it lands. Can be no damage (0), custom damage (1), or gib+5000dmg (2)
	temp_pod.delays = dataToLoad["delays"]
	temp_pod.reverse_delays = dataToLoad["rev_delays"]
	temp_pod.custom_rev_delay = dataToLoad["custom_rev_delay"]
	temp_pod.setStyle(dataToLoad["styleChoice"])  //Style is a variable that keeps track of what the pod is supposed to look like. It acts as an index to the GLOB.podstyles list in cargo.dm defines to get the proper icon/name/desc for the pod.
	temp_pod.effectShrapnel = dataToLoad["effectShrapnel"] //If true, creates a cloud of shrapnel of a decided type and magnitude on landing
	temp_pod.shrapnel_type = text2path(dataToLoad["shrapnelType"])
	temp_pod.shrapnel_magnitude = dataToLoad["shrapnelMagnitude"]
	temp_pod.effectStun  = dataToLoad["effectStun"]//If true, stuns anyone under the pod when it launches until it lands, forcing them to get hit by the pod. Devilish!
	temp_pod.effectLimb  = dataToLoad["effectLimb"]//If true, pops off a limb (if applicable) from anyone caught under the pod when it lands
	temp_pod.effectOrgans = dataToLoad["effectOrgans"]//If true, yeets the organs out of any bodies caught under the pod when it lands
	temp_pod.bluespace = dataToLoad["effectBluespace"] //If true, the pod deletes (in a shower of sparks) after landing
	temp_pod.effectStealth = dataToLoad["effectStealth"]//If true, a target icon isn't displayed on the turf where the pod will land
	temp_pod.effectQuiet = dataToLoad["effectQuiet"] //The female sniper. If true, the pod makes no noise (including related explosions, opening sounds, etc)
	temp_pod.effectMissile = dataToLoad["effectMissile"] //If true, the pod deletes the second it lands. If you give it an explosion, it will act like a missile exploding as it hits the ground
	temp_pod.effectCircle = dataToLoad["effectCircle"] //If true, allows the pod to come in at any angle. Bit of a weird feature but whatever its here
	effectBurst = dataToLoad["effectBurst"] //IOf true, launches five pods at once (with a very small delay between for added coolness), in a 3x3 area centered around the area
	temp_pod.reversing = dataToLoad["effectReverse"] //If true, the pod will not send any items. Instead, after opening, it will close again (picking up items/mobs) and fly back to centcom
	temp_pod.reverse_option_list = dataToLoad["reverse_option_list"]
	specificTarget = dataToLoad["effectTarget"] //Launches the pod at the turf of a specific mob target, rather than wherever the user clicked. Useful for smites
	temp_pod.adminNamed = dataToLoad["effectName"] //Determines whether or not the pod has been named by an admin. If true, the pod's name will not get overridden when the style of the pod changes (changing the style of the pod normally also changes the name+desc)
	temp_pod.name = dataToLoad["podName"]
	temp_pod.desc = dataToLoad["podDesc"]
	effectAnnounce = dataToLoad["effectAnnounce"]
	numTurfs = dataToLoad["numObjects"] //Counts the number of turfs that contain a launchable object in the centcom supplypod bay
	temp_pod.fallingSound = dataToLoad["fallingSound"]//Admin sound to play as the pod falls
	temp_pod.landingSound = dataToLoad["landingSound"]//Admin sound to play when the pod lands
	temp_pod.openingSound = dataToLoad["openingSound"]//Admin sound to play when the pod opens
	temp_pod.leavingSound = dataToLoad["leavingSound"]//Admin sound to play when the pod leaves
	temp_pod.soundVolume = dataToLoad["soundVolume"] //Admin sound to play when the pod leaves
	picking_dropoff_turf = FALSE
	launcherActivated = FALSE
	updateCursor()
	refreshView()

GLOBAL_DATUM_INIT(podlauncher, /datum/centcom_podlauncher, new)
//Proc for admins to enable others to use podlauncher after roundend
/datum/centcom_podlauncher/proc/give_podlauncher(mob/living/user, override)
	if (SSticker.current_state < GAME_STATE_FINISHED)
		return
	if (!istype(user))
		user = override
	if (user)
		setup(user)//setup the datum

//Set the dropoff location and indicator to either a specific turf or somewhere in an area
/datum/centcom_podlauncher/proc/setDropoff(target)
	var/turf/target_turf
	if (isturf(target))
		target_turf = target
	else if (isarea(target))
		target_turf = pick(get_area_turfs(target))
	else
		CRASH("Improper type passed to setDropoff! Should be /turf or /area")
	temp_pod.reverse_dropoff_coords = list(target_turf.x, target_turf.y, target_turf.z)
	indicator.forceMove(target_turf)

/obj/effect/hallucination/simple/supplypod_selector
	name = "Supply Selector (Only you can see this)"
	image_icon = 'icons/obj/supplypods_32x32.dmi'
	image_state = "selector"
	image_layer = FLY_LAYER
	alpha = 150

/obj/effect/hallucination/simple/dropoff_location
	name = "Dropoff Location (Only you can see this)"
	image_icon = 'icons/obj/supplypods_32x32.dmi'
	image_state = "dropoff_indicator"
	image_layer = FLY_LAYER
	alpha = 0
