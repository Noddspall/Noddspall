/obj/item/language_manual
	icon = 'icons/obj/library.dmi'
	icon_state = "book2"
	/// Number of charges the book has, limits the number of times it can be used.
	var/charges = 1
	/// Path to a language datum that the book teaches.
	var/datum/language/language = /datum/language/common
	/// Flavour text to display when the language is successfully learned.
	var/flavour_text = "suddenly your mind is filled with codewords and responses"

/obj/item/language_manual/attack_self(mob/living/user)
	if(!isliving(user))
		return

	if(user.has_language(language))
		to_chat(user, SPAN_BOLDWARNING("You start skimming through [src], but you already know [initial(language.name)]."))
		return

	to_chat(user, SPAN_BOLDANNOUNCE("You start skimming through [src], and [flavour_text]."))
	user.grant_language(language, TRUE, TRUE, LANGUAGE_MIND)

	use_charge(user)

/obj/item/language_manual/attack(mob/living/M, mob/living/user)
	if(!istype(M) || !istype(user))
		return
	if(M == user)
		attack_self(user)
		return

	playsound(loc, "punch", 25, TRUE, -1)

	if(M.stat == DEAD)
		M.visible_message(SPAN_DANGER("[user] smacks [M]'s lifeless corpse with [src]."), SPAN_USERDANGER("[user] smacks your lifeless corpse with [src]."), SPAN_HEAR("You hear smacking."))
	else if(M.has_language(language))
		M.visible_message(SPAN_DANGER("[user] beats [M] over the head with [src]!"), SPAN_USERDANGER("[user] beats you over the head with [src]!"), SPAN_HEAR("You hear smacking."))
	else
		M.visible_message(SPAN_NOTICE("[user] teaches [M] by beating [M.p_them()] over the head with [src]!"), SPAN_BOLDNOTICE("As [user] hits you with [src], [flavour_text]."), SPAN_HEAR("You hear smacking."))
		M.grant_language(language, TRUE, TRUE, LANGUAGE_MIND)
		use_charge(user)

/obj/item/language_manual/proc/use_charge(mob/user)
	charges--
	if(!charges)
		var/turf/T = get_turf(src)
		T.visible_message(SPAN_WARNING("The cover and contents of [src] start shifting and changing!"))

		qdel(src)
		var/obj/item/book/manual/random/book = new(T)
		user.put_in_active_hand(book)

/obj/item/language_manual/codespeak_manual
	name = "codespeak manual"
	desc = "The book's cover reads: \"Codespeak(tm) - Secure your communication with metaphors so elaborate, they seem randomly generated!\""
	language = /datum/language/codespeak
	flavour_text = "suddenly your mind is filled with codewords and responses"

/obj/item/language_manual/codespeak_manual/unlimited
	name = "deluxe codespeak manual"
	charges = INFINITY

/obj/item/language_manual/roundstart_species

/obj/item/language_manual/roundstart_species/Initialize()
	. = ..()
	language = pick( \
		/datum/language/voltaic, \
		/datum/language/nekomimetic, \
		/datum/language/draconic, \
		/datum/language/moffic, \
		/datum/language/calcic \
	)
	name = "[initial(language.name)] manual"
	desc = "The book's cover reads: \"[initial(language.name)] for Xenos - Learn common galactic tongues in seconds.\""
	flavour_text = "you feel empowered with a mastery over [initial(language.name)]"

/obj/item/language_manual/roundstart_species/unlimited
	charges = INFINITY

/obj/item/language_manual/roundstart_species/unlimited/Initialize()
	. = ..()
	name = "deluxe [initial(language.name)] manual"

/obj/item/language_manual/roundstart_species/five
	charges = 5

/obj/item/language_manual/roundstart_species/five/Initialize()
	. = ..()
	name = "extended [initial(language.name)] manual"
