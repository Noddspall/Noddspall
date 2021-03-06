/obj/item/cartridge/virus
	name = "Generic Virus PDA cart"
	var/charges = 5

/obj/item/cartridge/virus/proc/send_virus(obj/item/pda/target, mob/living/U)
	return

/obj/item/cartridge/virus/message_header()
	return "<b>[charges] viral files left.</b><HR>"

/obj/item/cartridge/virus/message_special(obj/item/pda/target)
	if (!istype(loc, /obj/item/pda))
		return ""  //Sanity check, this shouldn't be possible.
	return " (<a href='byond://?src=[REF(loc)];choice=cart;special=virus;target=[REF(target)]'>*Send Virus*</a>)"

/obj/item/cartridge/virus/special(mob/living/user, list/params)
	var/obj/item/pda/P = locate(params["target"]) in GLOB.PDAs  //Leaving it alone in case it may do something useful, I guess.
	send_virus(P,user)

/obj/item/cartridge/virus/clown
	name = "\improper Honkworks 5.0 cartridge"
	icon_state = "cart-clown"
	desc = "A data cartridge for portable microcomputers. It smells vaguely of bananas."
	access = CART_CLOWN

/obj/item/cartridge/virus/clown/send_virus(obj/item/pda/target, mob/living/U)
	if(charges <= 0)
		to_chat(U, SPAN_NOTICE("Out of charges."))
		return
	if(!isnull(target) && !target.toff)
		charges--
		to_chat(U, SPAN_NOTICE("Virus Sent!"))
		target.honkamt = (rand(15,20))
	else
		to_chat(U, SPAN_ALERT("PDA not found."))

/obj/item/cartridge/virus/mime
	name = "\improper Gestur-O 1000 cartridge"
	icon_state = "cart-mi"
	access = CART_MIME

/obj/item/cartridge/virus/mime/send_virus(obj/item/pda/target, mob/living/U)
	if(charges <= 0)
		to_chat(U, SPAN_ALERT("Out of charges."))
		return
	if(!isnull(target) && !target.toff)
		charges--
		to_chat(U, SPAN_NOTICE("Virus Sent!"))
		target.silent = TRUE
		target.ttone = "silence"
	else
		to_chat(U, SPAN_ALERT("PDA not found."))

/obj/item/cartridge/virus/syndicate
	name = "\improper Detomatix cartridge"
	icon_state = "cart"
	access = CART_REMOTE_DOOR
	remote_door_id = "smindicate" //Make sure this matches the syndicate shuttle's shield/door id!! //don't ask about the name, testing.
	charges = 4

/obj/item/cartridge/virus/syndicate/send_virus(obj/item/pda/target, mob/living/U)
	if(charges <= 0)
		to_chat(U, SPAN_NOTICE("Out of charges."))
		return
	if(!isnull(target) && !target.toff)
		charges--
		var/difficulty = 0
		if(target.cartridge)
			difficulty += BitCount(target.cartridge.access&(CART_MEDICAL | CART_SECURITY | CART_ENGINE | CART_CLOWN | CART_JANITOR | CART_MANIFEST))
			if(target.cartridge.access & CART_MANIFEST)
				difficulty++ //if cartridge has manifest access it has extra snowflake difficulty
		if(SEND_SIGNAL(target, COMSIG_PDA_CHECK_DETONATE) & COMPONENT_PDA_NO_DETONATE || prob(difficulty * 15))
			U.show_message(SPAN_DANGER("An error flashes on your [src]."), MSG_VISUAL)
		else
			log_bomber(U, "triggered a PDA explosion on", target, "[!is_special_character(U) ? "(TRIGGED BY NON-ANTAG)" : ""]")
			U.show_message(SPAN_NOTICE("Success!"), MSG_VISUAL)
			target.explode()
	else
		to_chat(U, SPAN_ALERT("PDA not found."))
