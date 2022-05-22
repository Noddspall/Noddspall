/turf/closed/wall/vault
	name = "strange wall"
	smoothing_flags = NONE
	canSmoothWith = null
	smoothing_groups = null
	rcd_memory = null

/turf/closed/wall/vault/rock
	name = "rocky wall"
	desc = "You feel a strange nostalgia from looking at this..."

/turf/closed/wall/vault/sandstone
	name = "sandstone wall"
	icon_state = "sandstonevault"
	base_icon_state = "sandstonevault"

/turf/closed/wall/ice
	desc = "A wall covered in a thick sheet of ice."
	rcd_memory = null
	hardness = 35
	slicing_duration = 150 //welding through the ice+metal
	bullet_sizzle = TRUE

/turf/closed/wall/rust
	name = "rusted wall"
	desc = "A rusted metal wall."
	hardness = 45
	rusted = TRUE

/turf/closed/wall/r_wall/rust
	name = "rusted reinforced wall"
	desc = "A huge chunk of rusted reinforced metal."
	hardness = 15
	rusted = TRUE

/turf/closed/wall/mineral/bronze
	name = "clockwork wall"
	desc = "A huge chunk of bronze, decorated like gears and cogs."
	plating_material = /datum/material/bronze
	color = "#92661A" //To display in mapping softwares

/turf/closed/wall/concrete
	name = "concrete wall"
	desc = "A dense slab of reinforced stone, not much will get through this."
	hardness = 10
	explosion_block = 2
	rad_insulation = RAD_HEAVY_INSULATION

/turf/closed/wall/concrete/deconstruction_hints(mob/user)
	return SPAN_NOTICE("Nothing's going to cut that.")

/turf/closed/wall/concrete/try_decon(obj/item/I, mob/user, turf/T)
	if(I.tool_behaviour == TOOL_WELDER)
		to_chat(user, SPAN_WARNING("This wall is way too hard to cut through!"))
	return FALSE

/turf/closed/wall/concrete/rcd_vals(mob/user, obj/item/construction/rcd/the_rcd)
	return FALSE

/turf/closed/wall/concrete/rcd_act(mob/user, obj/item/construction/rcd/the_rcd, passed_mode)
	return FALSE
