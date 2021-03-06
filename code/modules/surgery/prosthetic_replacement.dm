/datum/surgery/prosthetic_replacement
	name = "Prosthetic replacement"
	steps = list(
		/datum/surgery_step/incise,
		/datum/surgery_step/clamp_bleeders,
		/datum/surgery_step/retract_skin,
		/datum/surgery_step/add_prosthetic)
	target_mobtypes = list(/mob/living/carbon/human)
	possible_locs = list(BODY_ZONE_R_ARM, BODY_ZONE_L_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG, BODY_ZONE_HEAD)
	requires_bodypart = FALSE //need a missing limb
	requires_bodypart_type = 0

/datum/surgery/prosthetic_replacement/can_start(mob/user, mob/living/carbon/target)
	if(!iscarbon(target))
		return FALSE
	var/mob/living/carbon/carbon_target = target
	if(!carbon_target.get_bodypart(user.zone_selected)) //can only start if limb is missing
		return TRUE
	return FALSE



/datum/surgery_step/add_prosthetic
	name = "add prosthetic"
	implements = list(
		/obj/item/bodypart = 100,
		/obj/item/chainsaw = 100,
		/obj/item/melee/synthetic_arm_blade = 100)
	time = 32
	var/organ_rejection_dam = 0

/datum/surgery_step/add_prosthetic/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	if(istype(tool, /obj/item/bodypart))
		var/obj/item/bodypart/bodypart_to_attach = tool
		if(ismonkey(target))// monkey patient only accept organic monkey limbs
			if(bodypart_to_attach.status == BODYPART_ROBOTIC || bodypart_to_attach.animal_origin != MONKEY_BODYPART)
				to_chat(user, SPAN_WARNING("[bodypart_to_attach] doesn't match the patient's morphology."))
				return -1
		if(bodypart_to_attach.status != BODYPART_ROBOTIC)
			organ_rejection_dam = 10
			if(ishuman(target))
				if(bodypart_to_attach.animal_origin)
					to_chat(user, SPAN_WARNING("[bodypart_to_attach] doesn't match the patient's morphology."))
					return -1
				var/mob/living/carbon/human/human_target = target
				if(human_target.dna.species.id != bodypart_to_attach.species_id)
					organ_rejection_dam = 30

		if(target_zone == bodypart_to_attach.body_zone) //so we can't replace a leg with an arm, or a human arm with a monkey arm.
			display_results(user, target, SPAN_NOTICE("You begin to replace [target]'s [parse_zone(target_zone)] with [tool]..."),
				SPAN_NOTICE("[user] begins to replace [target]'s [parse_zone(target_zone)] with [tool]."),
				SPAN_NOTICE("[user] begins to replace [target]'s [parse_zone(target_zone)]."))
		else
			to_chat(user, SPAN_WARNING("[tool] isn't the right type for [parse_zone(target_zone)]."))
			return -1
	else if(target_zone == BODY_ZONE_L_ARM || target_zone == BODY_ZONE_R_ARM)
		display_results(user, target, SPAN_NOTICE("You begin to attach [tool] onto [target]..."),
			SPAN_NOTICE("[user] begins to attach [tool] onto [target]'s [parse_zone(target_zone)]."),
			SPAN_NOTICE("[user] begins to attach something onto [target]'s [parse_zone(target_zone)]."))
	else
		to_chat(user, SPAN_WARNING("[tool] must be installed onto an arm."))
		return -1

/datum/surgery_step/add_prosthetic/success(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery, default_display_results = FALSE)
	. = ..()
	if(istype(tool, /obj/item/bodypart) && user.temporarilyRemoveItemFromInventory(tool))
		var/obj/item/bodypart/limb_to_attach = tool
		if(!limb_to_attach.attach_limb(target))
			display_results(user, target, SPAN_WARNING("You fail in replacing [target]'s [parse_zone(target_zone)]! Their body has rejected [limb_to_attach]!"),
				SPAN_WARNING("[user] fails to replace [target]'s [parse_zone(target_zone)]!"),
				SPAN_WARNING("[user] fails to replaces [target]'s [parse_zone(target_zone)]!"))
			return
		if(organ_rejection_dam)
			target.adjustToxLoss(organ_rejection_dam)
		display_results(user, target, SPAN_NOTICE("You succeed in replacing [target]'s [parse_zone(target_zone)]."),
			SPAN_NOTICE("[user] successfully replaces [target]'s [parse_zone(target_zone)] with [tool]!"),
			SPAN_NOTICE("[user] successfully replaces [target]'s [parse_zone(target_zone)]!"))
		return
	else
		var/obj/item/bodypart/limb_to_attach = target.newBodyPart(target_zone, FALSE, FALSE)
		limb_to_attach.is_pseudopart = TRUE
		if(!limb_to_attach.attach_limb(target))
			display_results(user, target, SPAN_WARNING("You fail in attaching [target]'s [parse_zone(target_zone)]! Their body has rejected [limb_to_attach]!"),
				SPAN_WARNING("[user] fails to attach [target]'s [parse_zone(target_zone)]!"),
				SPAN_WARNING("[user] fails to attach [target]'s [parse_zone(target_zone)]!"))
			limb_to_attach.forceMove(target.loc)
			return
		user.visible_message(SPAN_NOTICE("[user] finishes attaching [tool]!"), SPAN_NOTICE("You attach [tool]."))
		display_results(user, target, SPAN_NOTICE("You attach [tool]."),
			SPAN_NOTICE("[user] finishes attaching [tool]!"),
			SPAN_NOTICE("[user] finishes the attachment procedure!"))
		qdel(tool)
		if(istype(tool, /obj/item/chainsaw))
			var/obj/item/mounted_chainsaw/new_arm = new(target)
			target_zone == BODY_ZONE_R_ARM ? target.put_in_r_hand(new_arm) : target.put_in_l_hand(new_arm)
			return
	return ..() //if for some reason we fail everything we'll print out some text okay?
