/obj/machinery/wish_granter
	name = "wish granter"
	desc = "You're not so sure about this, anymore..."
	icon = 'icons/obj/device.dmi'
	icon_state = "syndbeacon"

	use_power = NO_POWER_USE
	density = TRUE

	var/charges = 1
	var/insisting = 0

/obj/machinery/wish_granter/attack_hand(mob/living/carbon/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(charges <= 0)
		to_chat(user, SPAN_BOLDNOTICE("The Wish Granter lies silent."))
		return

	else if(!ishuman(user))
		to_chat(user, SPAN_BOLDNOTICE("You feel a dark stirring inside of the Wish Granter, something you want nothing of. Your instincts are better than any man's."))
		return

	else if(is_special_character(user))
		to_chat(user, SPAN_BOLDNOTICE("Even to a heart as dark as yours, you know nothing good will come of this. Something instinctual makes you pull away."))

	else if (!insisting)
		to_chat(user, SPAN_BOLDNOTICE("Your first touch makes the Wish Granter stir, listening to you. Are you really sure you want to do this?"))
		insisting++

	else
		to_chat(user, SPAN_BOLDNOTICE("You speak. [pick("I want the station to disappear","Humanity is corrupt, mankind must be destroyed","I want to be rich", "I want to rule the world","I want immortality.")]. The Wish Granter answers."))
		to_chat(user, SPAN_BOLDNOTICE("Your head pounds for a moment, before your vision clears. You are the avatar of the Wish Granter, and your power is LIMITLESS! And it's all yours. You need to make sure no one can take it from you. No one can know, first."))

		charges--
		insisting = 0

		to_chat(user, SPAN_WARNING("You have a very bad feeling about this."))

	return
