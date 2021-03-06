
/////AUGMENTATION SURGERIES//////


//SURGERY STEPS

/datum/surgery_step/replace_limb
	name = "replace limb"
	implements = list(
		/obj/item/bodypart = 100)
	time = 32
	var/obj/item/bodypart/target_limb


/datum/surgery_step/replace_limb/preop(mob/user, mob/living/carbon/target, target_zone, obj/item/tool, datum/surgery/surgery)
	if(NOAUGMENTS in target.dna.species.species_traits)
		to_chat(user, SPAN_WARNING("[target] cannot be augmented!"))
		return -1
	var/obj/item/bodypart/aug = tool
	if(aug.status != BODYPART_ROBOTIC)
		to_chat(user, SPAN_WARNING("That's not an augment, silly!"))
		return -1
	if(aug.body_zone != target_zone)
		to_chat(user, SPAN_WARNING("[tool] isn't the right type for [parse_zone(target_zone)]."))
		return -1
	target_limb = surgery.operated_bodypart
	if(target_limb)
		display_results(user, target, SPAN_NOTICE("You begin to augment [target]'s [parse_zone(user.zone_selected)]..."),
			SPAN_NOTICE("[user] begins to augment [target]'s [parse_zone(user.zone_selected)] with [aug]."),
			SPAN_NOTICE("[user] begins to augment [target]'s [parse_zone(user.zone_selected)]."))
	else
		user.visible_message(SPAN_NOTICE("[user] looks for [target]'s [parse_zone(user.zone_selected)]."), SPAN_NOTICE("You look for [target]'s [parse_zone(user.zone_selected)]..."))


//ACTUAL SURGERIES

/datum/surgery/augmentation
	name = "Augmentation"
	steps = list(
		/datum/surgery_step/incise,
		/datum/surgery_step/clamp_bleeders,
		/datum/surgery_step/retract_skin,
		/datum/surgery_step/replace_limb)
	target_mobtypes = list(/mob/living/carbon/human)
	possible_locs = list(BODY_ZONE_R_ARM,BODY_ZONE_L_ARM,BODY_ZONE_R_LEG,BODY_ZONE_L_LEG,BODY_ZONE_CHEST,BODY_ZONE_HEAD)
	requires_real_bodypart = TRUE

//SURGERY STEP SUCCESSES

/datum/surgery_step/replace_limb/success(mob/living/user, mob/living/carbon/target, target_zone, obj/item/bodypart/tool, datum/surgery/surgery, default_display_results = FALSE)
	if(target_limb)
		if(istype(tool) && user.temporarilyRemoveItemFromInventory(tool))
			tool.replace_limb(target, TRUE)
		display_results(user, target, SPAN_NOTICE("You successfully augment [target]'s [parse_zone(target_zone)]."),
			SPAN_NOTICE("[user] successfully augments [target]'s [parse_zone(target_zone)] with [tool]!"),
			SPAN_NOTICE("[user] successfully augments [target]'s [parse_zone(target_zone)]!"))
		log_combat(user, target, "augmented", addition="by giving him new [parse_zone(target_zone)] COMBAT MODE: [uppertext(user.combat_mode)]")
	else
		to_chat(user, SPAN_WARNING("[target] has no organic [parse_zone(target_zone)] there!"))
	return ..()
