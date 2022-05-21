/obj/item/firing_pin
	name = "electronic firing pin"
	desc = "A small authentication device, to be inserted into a firearm receiver to allow operation. NT safety regulations require all new designs to incorporate one."
	icon = 'icons/obj/device.dmi'
	icon_state = "firing_pin"
	inhand_icon_state = "pen"
	worn_icon_state = "pen"
	flags_1 = CONDUCT_1
	w_class = WEIGHT_CLASS_TINY
	attack_verb_continuous = list("pokes")
	attack_verb_simple = list("poke")
	var/fail_message = SPAN_WARNING("INVALID USER.")
	var/selfdestruct = FALSE // Explode when user check is failed.
	var/force_replace = FALSE // Can forcefully replace other pins.
	var/pin_removeable = FALSE // Can be replaced by any pin.
	var/obj/item/gun/gun

/obj/item/firing_pin/New(newloc)
	..()
	if(istype(newloc, /obj/item/gun))
		gun = newloc

/obj/item/firing_pin/afterattack(atom/target, mob/user, proximity_flag)
	. = ..()
	if(proximity_flag)
		if(istype(target, /obj/item/gun))
			var/obj/item/gun/G = target
			var/obj/item/firing_pin/old_pin = G.pin
			if(old_pin && (force_replace || old_pin.pin_removeable))
				to_chat(user, SPAN_NOTICE("You remove [old_pin] from [G]."))
				if(Adjacent(user))
					user.put_in_hands(old_pin)
				else
					old_pin.forceMove(G.drop_location())
				old_pin.gun_remove(user)

			if(!G.pin)
				if(!user.temporarilyRemoveItemFromInventory(src))
					return
				gun_insert(user, G)
				to_chat(user, SPAN_NOTICE("You insert [src] into [G]."))
			else
				to_chat(user, SPAN_NOTICE("This firearm already has a firing pin installed."))

/obj/item/firing_pin/emag_act(mob/user)
	if(obj_flags & EMAGGED)
		return
	obj_flags |= EMAGGED
	to_chat(user, SPAN_NOTICE("You override the authentication mechanism."))

/obj/item/firing_pin/proc/gun_insert(mob/living/user, obj/item/gun/G)
	gun = G
	forceMove(gun)
	gun.pin = src
	return

/obj/item/firing_pin/proc/gun_remove(mob/living/user)
	gun.pin = null
	gun = null
	return

/obj/item/firing_pin/proc/pin_auth(mob/living/user)
	return TRUE

/obj/item/firing_pin/proc/auth_fail(mob/living/user)
	if(user)
		user.show_message(fail_message, MSG_VISUAL)
	if(selfdestruct)
		if(user)
			user.show_message("[SPAN_DANGER("SELF-DESTRUCTING...")]<br>", MSG_VISUAL)
			to_chat(user, SPAN_USERDANGER("[gun] explodes!"))
		explosion(src, devastation_range = -1, light_impact_range = 2, flash_range = 3)
		if(gun)
			qdel(gun)


/obj/item/firing_pin/magic
	name = "magic crystal shard"
	desc = "A small enchanted shard which allows magical weapons to fire."


// Test pin, works only near firing range.
/obj/item/firing_pin/test_range
	name = "test-range firing pin"
	desc = "This safety firing pin allows weapons to be fired within proximity to a firing range."
	fail_message = SPAN_WARNING("TEST RANGE CHECK FAILED.")
	pin_removeable = TRUE

/obj/item/firing_pin/test_range/pin_auth(mob/living/user)
	if(!istype(user))
		return FALSE
	if (istype(get_area(user), /area/security/range))
		return TRUE
	return FALSE


// Implant pin, checks for implant
/obj/item/firing_pin/implant
	name = "implant-keyed firing pin"
	desc = "This is a security firing pin which only authorizes users who are implanted with a certain device."
	fail_message = SPAN_WARNING("IMPLANT CHECK FAILED.")
	var/obj/item/implant/req_implant = null

/obj/item/firing_pin/implant/pin_auth(mob/living/user)
	if(user)
		for(var/obj/item/implant/I in user.implants)
			if(req_implant && I.type == req_implant)
				return TRUE
	return FALSE

/obj/item/firing_pin/implant/mindshield
	name = "mindshield firing pin"
	desc = "This Security firing pin authorizes the weapon for only mindshield-implanted users."
	icon_state = "firing_pin_loyalty"
	req_implant = /obj/item/implant/weapons_auth

/obj/item/firing_pin/implant/pindicate
	name = "syndicate firing pin"
	icon_state = "firing_pin_pindi"
	req_implant = /obj/item/implant/weapons_auth


// DNA-keyed pin.
// When you want to keep your toys for yourself.
/obj/item/firing_pin/dna
	name = "DNA-keyed firing pin"
	desc = "This is a DNA-locked firing pin which only authorizes one user. Attempt to fire once to DNA-link."
	icon_state = "firing_pin_dna"
	fail_message = SPAN_WARNING("DNA CHECK FAILED.")
	var/unique_enzymes = null

/obj/item/firing_pin/dna/afterattack(atom/target, mob/user, proximity_flag)
	. = ..()
	if(proximity_flag && iscarbon(target))
		var/mob/living/carbon/M = target
		if(M.dna && M.dna.unique_enzymes)
			unique_enzymes = M.dna.unique_enzymes
			to_chat(user, SPAN_NOTICE("DNA-LOCK SET."))

/obj/item/firing_pin/dna/pin_auth(mob/living/carbon/user)
	if(user && user.dna && user.dna.unique_enzymes)
		if(user.dna.unique_enzymes == unique_enzymes)
			return TRUE
	return FALSE

/obj/item/firing_pin/dna/auth_fail(mob/living/carbon/user)
	if(!unique_enzymes)
		if(user && user.dna && user.dna.unique_enzymes)
			unique_enzymes = user.dna.unique_enzymes
			to_chat(user, SPAN_NOTICE("DNA-LOCK SET."))
	else
		..()

/obj/item/firing_pin/dna/dredd
	desc = "This is a DNA-locked firing pin which only authorizes one user. Attempt to fire once to DNA-link. It has a small explosive charge on it."
	selfdestruct = TRUE

// Explorer Firing Pin- Prevents use on station Z-Level, so it's justifiable to give Explorers guns that don't suck.
/obj/item/firing_pin/explorer
	name = "outback firing pin"
	desc = "A firing pin used by the austrailian defense force, retrofit to prevent weapon discharge on the station."
	icon_state = "firing_pin_explorer"
	fail_message = SPAN_WARNING("CANNOT FIRE WHILE ON STATION, MATE!")

// This checks that the user isn't on the station Z-level.
/obj/item/firing_pin/explorer/pin_auth(mob/living/user)
	var/turf/station_check = get_turf(user)
	if(!station_check||is_station_level(station_check))
		to_chat(user, SPAN_WARNING("You cannot use your weapon while on the station!"))
		return FALSE
	return TRUE

// Laser tag pins
/obj/item/firing_pin/tag
	name = "laser tag firing pin"
	desc = "A recreational firing pin, used in laser tag units to ensure users have their vests on."
	fail_message = SPAN_WARNING("SUIT CHECK FAILED.")
	var/obj/item/clothing/suit/suit_requirement = null
	var/tagcolor = ""

/obj/item/firing_pin/tag/pin_auth(mob/living/user)
	if(ishuman(user))
		var/mob/living/carbon/human/M = user
		if(istype(M.wear_suit, suit_requirement))
			return TRUE
	to_chat(user, SPAN_WARNING("You need to be wearing [tagcolor] laser tag armor!"))
	return FALSE

/obj/item/firing_pin/tag/red
	name = "red laser tag firing pin"
	icon_state = "firing_pin_red"
	suit_requirement = /obj/item/clothing/suit/redtag
	tagcolor = "red"

/obj/item/firing_pin/tag/blue
	name = "blue laser tag firing pin"
	icon_state = "firing_pin_blue"
	suit_requirement = /obj/item/clothing/suit/bluetag
	tagcolor = "blue"

/obj/item/firing_pin/Destroy()
	if(gun)
		gun.pin = null
	return ..()
