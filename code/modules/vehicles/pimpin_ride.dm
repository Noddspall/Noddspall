//PIMP-CART
/obj/vehicle/ridden/janicart
	name = "janicart (pimpin' ride)"
	desc = "A brave janitor cyborg gave its life to produce such an amazing combination of speed and utility."
	icon_state = "pussywagon"
	key_type = /obj/item/key
	key_id = KEY_ID_JANICART
	var/obj/item/storage/bag/trash/mybag = null
	var/floorbuffer = FALSE
	movedelay = 1

/obj/vehicle/ridden/janicart/Initialize(mapload)
	. = ..()
	update_appearance()
	AddElement(/datum/element/ridable, /datum/component/riding/vehicle/janicart)

	if(floorbuffer)
		AddElement(/datum/element/cleaning)

/obj/vehicle/ridden/janicart/Destroy()
	if(mybag)
		QDEL_NULL(mybag)
	return ..()

/obj/item/janiupgrade
	name = "floor buffer upgrade"
	desc = "An upgrade for mobile janicarts."
	icon = 'icons/obj/vehicles.dmi'
	icon_state = "upgrade"

/obj/vehicle/ridden/janicart/examine(mob/user)
	. = ..()
	if(floorbuffer)
		. += "It has been upgraded with a floor buffer."

/obj/vehicle/ridden/janicart/attackby(obj/item/I, mob/user, params)
	if(istype(I, /obj/item/storage/bag/trash))
		if(mybag)
			to_chat(user, SPAN_WARNING("[src] already has a trashbag hooked!"))
			return
		if(!user.transferItemToLoc(I, src))
			return
		to_chat(user, SPAN_NOTICE("You hook the trashbag onto [src]."))
		mybag = I
		update_appearance()
	else if(istype(I, /obj/item/janiupgrade))
		if(floorbuffer)
			to_chat(user, SPAN_WARNING("[src] already has a floor buffer!"))
			return
		floorbuffer = TRUE
		qdel(I)
		to_chat(user, SPAN_NOTICE("You upgrade [src] with the floor buffer."))
		AddElement(/datum/element/cleaning)
		update_appearance()
	else if(mybag)
		mybag.attackby(I, user)
	else
		return ..()

/obj/vehicle/ridden/janicart/update_overlays()
	. = ..()
	if(mybag)
		. += "cart_garbage"
	if(floorbuffer)
		. += "cart_buffer"

/obj/vehicle/ridden/janicart/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(. || !mybag)
		return
	mybag.forceMove(get_turf(user))
	user.put_in_hands(mybag)
	mybag = null
	update_appearance()

/obj/vehicle/ridden/janicart/upgraded
	floorbuffer = TRUE
