/datum/transit_instance
	var/datum/virtual_level/vlevel
	var/obj/docking_port/stationary/transit/dock
	//Associative for easy lookup
	var/list/affected_movables = list()

/datum/transit_instance/New(datum/virtual_level/arg_vlevel, obj/docking_port/stationary/transit/arg_dock)
	. = ..()
	vlevel = arg_vlevel
	vlevel.transit_instance = src
	dock = arg_dock
	dock.transit_instance = src

/datum/transit_instance/Destroy()
	strand_all()
	vlevel.transit_instance = null
	vlevel = null
	dock.transit_instance = null
	dock = null
	return ..()

//Movable moved in transit
/datum/transit_instance/proc/movable_moved(atom/movable/moved, time_until_strand)
	if(!moved)
		stack_trace("null movable on Movable Moved in Transit Instance")
		return
	if(!moved.loc || !isturf(moved.loc))
		return
	if(time_until_strand > world.time)
		return
	var/turf/my_turf = moved.loc
	if(!vlevel.on_edge(my_turf))
		return
	//We've moved to be adjacent to edge or out of bounds
	//Check for things that should just disappear as they bump into the edges of the map
	//Maybe listening for this event could be done in a better way?
	if(ishuman(moved)) //Humans could disconnect and not have a client, we dont want to get them stranded
		return
	if(ismob(moved))
		var/mob/moved_mob = moved
		if(moved_mob.client) //Client things never voluntairly get stranded
			return
	strand_act(moved)

//Apply velocity to the movables we're handling
/datum/transit_instance/proc/ApplyVelocity(dir, velocity)
	return

///Strand all movables that we're managing
/datum/transit_instance/proc/strand_all()
	for(var/movable in affected_movables)
		strand_act(movable)

/datum/transit_instance/proc/strand_act(atom/movable/strander)
	return
