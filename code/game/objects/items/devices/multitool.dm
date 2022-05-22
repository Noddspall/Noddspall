#define PROXIMITY_NONE ""
#define PROXIMITY_ON_SCREEN "_red"
#define PROXIMITY_NEAR "_yellow"

/**
 * Multitool -- A multitool is used for hacking electronic devices.
 *
 */




/obj/item/multitool
	name = "multitool"
	desc = "Used for pulsing wires to test which to cut. Not recommended by doctors."
	icon = 'icons/obj/device.dmi'
	icon_state = "multitool"
	inhand_icon_state = "multitool"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	force = 5
	w_class = WEIGHT_CLASS_SMALL
	tool_behaviour = TOOL_MULTITOOL
	throwforce = 0
	throw_range = 7
	throw_speed = 3
	drop_sound = 'sound/items/handling/multitool_drop.ogg'
	pickup_sound =  'sound/items/handling/multitool_pickup.ogg'
	custom_materials = list(/datum/material/iron=50, /datum/material/glass=20)
	custom_premium_price = PAYCHECK_HARD * 3
	toolspeed = 1
	usesound = 'sound/weapons/empty.ogg'
	var/obj/machinery/buffer // simple machine buffer for device linkage
	var/mode = 0

/obj/item/multitool/examine(mob/user)
	. = ..()
	. += SPAN_NOTICE("Its buffer [buffer ? "contains [buffer]." : "is empty."]")

/obj/item/multitool/suicide_act(mob/living/carbon/user)
	user.visible_message(SPAN_SUICIDE("[user] puts the [src] to [user.p_their()] chest. It looks like [user.p_theyre()] trying to pulse [user.p_their()] heart off!"))
	return OXYLOSS//theres a reason it wasn't recommended by doctors

