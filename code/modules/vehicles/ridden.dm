/obj/vehicle/ridden
	name = "ridden vehicle"
	can_buckle = TRUE
	max_buckled_mobs = 1
	buckle_lying = 0
	pass_flags_self = PASSTABLE
	COOLDOWN_DECLARE(message_cooldown)

/obj/vehicle/ridden/examine(mob/user)
	. = ..()
	if(key_type)
		if(!inserted_key)
			. += SPAN_NOTICE("Put a key inside it by clicking it with the key.")
		else
			. += SPAN_NOTICE("Alt-click [src] to remove the key.")

/obj/vehicle/ridden/generate_action_type(actiontype)
	var/datum/action/vehicle/ridden/A = ..()
	. = A
	if(istype(A))
		A.vehicle_ridden_target = src

/obj/vehicle/ridden/post_unbuckle_mob(mob/living/M)
	remove_occupant(M)
	return ..()

/obj/vehicle/ridden/post_buckle_mob(mob/living/M)
	add_occupant(M)
	return ..()

/obj/vehicle/ridden/attackby(obj/item/I, mob/user, params)
	if(!key_type || is_key(inserted_key) || !is_key(I))
		return ..()
	if(key_id)
		var/obj/item/key/key_item = I
		if(key_item.key_id != key_id)
			to_chat(user, SPAN_WARNING("This key does not fit!"))
			return
	if(!user.transferItemToLoc(I, src))
		to_chat(user, SPAN_WARNING("[I] seems to be stuck to your hand!"))
		return
	to_chat(user, SPAN_NOTICE("You insert \the [I] into \the [src]."))
	if(inserted_key) //just in case there's an invalid key
		inserted_key.forceMove(drop_location())
	inserted_key = I

/obj/vehicle/ridden/AltClick(mob/user)
	if(!inserted_key || !user.canUseTopic(src, BE_CLOSE, NO_DEXTERITY, FALSE))
		return ..()
	if(!is_occupant(user))
		to_chat(user, SPAN_WARNING("You must be riding the [src] to remove [src]'s key!"))
		return
	to_chat(user, SPAN_NOTICE("You remove \the [inserted_key] from \the [src]."))
	inserted_key.forceMove(drop_location())
	user.put_in_hands(inserted_key)
	inserted_key = null

/obj/vehicle/ridden/user_buckle_mob(mob/living/M, mob/user, check_loc = TRUE)
	if(!in_range(user, src) || !in_range(M, src))
		return FALSE
	return ..(M, user, FALSE)

/obj/vehicle/ridden/buckle_mob(mob/living/M, force = FALSE, check_loc = TRUE)
	if(!force && occupant_amount() >= max_occupants)
		return FALSE
	return ..()

/obj/vehicle/ridden/zap_act(power, zap_flags)
	zap_buckle_check(power)
	return ..()
