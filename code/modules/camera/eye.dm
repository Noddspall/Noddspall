// AI EYE
//
// An invisible (no icon) mob that the AI controls to look around the station with.
// It streams chunks as it moves around, which will show it what the AI can and cannot see.
/mob/camera/ai_eye
	name = "Inactive AI Eye"

	icon_state = "ai_camera"
	icon = 'icons/mob/cameramob.dmi'
	invisibility = INVISIBILITY_MAXIMUM
	hud_possible = list(ANTAG_HUD, AI_DETECT_HUD = HUD_LIST_LIST)
	var/list/visibleCameraChunks = list()
	var/mob/living/silicon/ai/ai = null
	var/relay_speech = FALSE
	var/use_static = TRUE
	var/static_visibility_range = 16

/mob/camera/ai_eye/Initialize()
	. = ..()
	GLOB.aiEyes += src
	setLoc(loc, TRUE)

/mob/camera/ai_eye/proc/get_visible_turfs()
	if(!isturf(loc))
		return list()
	var/client/C = GetViewerClient()
	var/view = C ? getviewsize(C.view) : getviewsize(world.view)
	var/turf/lowerleft = locate(max(1, x - (view[1] - 1)/2), max(1, y - (view[2] - 1)/2), z)
	var/turf/upperright = locate(min(world.maxx, lowerleft.x + (view[1] - 1)), min(world.maxy, lowerleft.y + (view[2] - 1)), lowerleft.z)
	return block(lowerleft, upperright)

// Use this when setting the aiEye's location.
// It will also stream the chunk that the new loc is in.

/mob/camera/ai_eye/proc/setLoc(destination, force_update = FALSE)
	if(ai)
		if(!isturf(ai.loc))
			return
		destination = get_turf(destination)
		if(!force_update && (destination == get_turf(src)) )
			return //we are already here!
		if (destination)
			if(!force_update)
				var/datum/map_zone/mapzone = loc.get_map_zone()
				if(!mapzone.is_in_bounds(destination))
					return
			abstract_move(destination)
		else
			moveToNullspace()
		update_parallax_contents()

//it uses setLoc not forceMove, talks to the sillycone and not the camera mob
/mob/camera/ai_eye/zMove(dir, feedback = FALSE)
	if(dir != UP && dir != DOWN)
		return FALSE
	var/turf/target = get_step_multiz(src, dir)
	if(!target)
		if(feedback)
			to_chat(ai, SPAN_WARNING("There's nowhere to go in that direction!"))
		return FALSE
	if(!canZMove(dir, target))
		if(feedback)
			to_chat(ai, SPAN_WARNING("You couldn't move there!"))
		return FALSE
	setLoc(target, TRUE)
	return TRUE

/mob/camera/ai_eye/canZMove(direction, turf/target) //cameras do not respect these FLOORS you speak so much of
	return TRUE

/mob/camera/ai_eye/Move()
	return

/mob/camera/ai_eye/proc/GetViewerClient()
	if(ai)
		return ai.client
	return null

/mob/camera/ai_eye/Destroy()
	for(var/V in visibleCameraChunks)
		var/datum/camerachunk/c = V
		c.remove(src)
	GLOB.aiEyes -= src
	return ..()
