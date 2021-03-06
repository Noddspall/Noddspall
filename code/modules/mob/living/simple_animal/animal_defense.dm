/mob/living/simple_animal/attack_hand(mob/living/carbon/human/user, list/modifiers)
	// so that martial arts don't double dip
	if (..())
		return TRUE

	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		user.do_attack_animation(src, ATTACK_EFFECT_DISARM)
		playsound(src, 'sound/weapons/thudswoosh.ogg', 50, TRUE, -1)
		var/shove_dir = get_dir(user, src)
		if(!Move(get_step(src, shove_dir), shove_dir))
			log_combat(user, src, "shoved", "failing to move it")
			user.visible_message(SPAN_DANGER("[user.name] shoves [src]!"),
				SPAN_DANGER("You shove [src]!"), SPAN_HEAR("You hear aggressive shuffling!"), COMBAT_MESSAGE_RANGE, list(src))
			to_chat(src, SPAN_USERDANGER("You're shoved by [user.name]!"))
			return TRUE
		log_combat(user, src, "shoved", "pushing it")
		user.visible_message(SPAN_DANGER("[user.name] shoves [src], pushing [p_them()]!"),
			SPAN_DANGER("You shove [src], pushing [p_them()]!"), SPAN_HEAR("You hear aggressive shuffling!"), COMBAT_MESSAGE_RANGE, list(src))
		to_chat(src, SPAN_USERDANGER("You're pushed by [user.name]!"))
		return TRUE

	if(!user.combat_mode)
		if (stat == DEAD)
			return
		visible_message(SPAN_NOTICE("[user] [response_help_continuous] [src]."), \
						SPAN_NOTICE("[user] [response_help_continuous] you."), null, null, user)
		to_chat(user, SPAN_NOTICE("You [response_help_simple] [src]."))
		playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, TRUE, -1)
	else
		if(HAS_TRAIT(user, TRAIT_PACIFISM))
			to_chat(user, SPAN_WARNING("You don't want to hurt [src]!"))
			return
		user.do_attack_animation(src, ATTACK_EFFECT_PUNCH)
		visible_message(SPAN_DANGER("[user] [response_harm_continuous] [src]!"),\
						SPAN_USERDANGER("[user] [response_harm_continuous] you!"), null, COMBAT_MESSAGE_RANGE, user)
		to_chat(user, SPAN_DANGER("You [response_harm_simple] [src]!"))
		playsound(loc, attacked_sound, 25, TRUE, -1)
		attack_threshold_check(harm_intent_damage)
		log_combat(user, src, "attacked")
		updatehealth()
		return TRUE

/mob/living/simple_animal/attack_hulk(mob/living/carbon/human/user)
	. = ..()
	if(!.)
		return
	playsound(loc, "punch", 25, TRUE, -1)
	visible_message(SPAN_DANGER("[user] punches [src]!"), \
					SPAN_USERDANGER("You're punched by [user]!"), null, COMBAT_MESSAGE_RANGE, user)
	to_chat(user, SPAN_DANGER("You punch [src]!"))
	adjustBruteLoss(15)

/mob/living/simple_animal/attack_paw(mob/living/carbon/human/user, list/modifiers)
	if(..()) //successful monkey bite.
		if(stat != DEAD)
			var/damage = rand(1, 3)
			attack_threshold_check(damage)
			return 1
	if (!user.combat_mode)
		if (health > 0)
			visible_message(SPAN_NOTICE("[user.name] [response_help_continuous] [src]."), \
							SPAN_NOTICE("[user.name] [response_help_continuous] you."), null, COMBAT_MESSAGE_RANGE, user)
			to_chat(user, SPAN_NOTICE("You [response_help_simple] [src]."))
			playsound(loc, 'sound/weapons/thudswoosh.ogg', 50, TRUE, -1)

/mob/living/simple_animal/attack_animal(mob/living/simple_animal/user, list/modifiers)
	. = ..()
	if(.)
		var/damage = rand(user.melee_damage_lower, user.melee_damage_upper)
		return attack_threshold_check(damage, user.melee_damage_type)

/mob/living/simple_animal/proc/attack_threshold_check(damage, damagetype = BRUTE, armorcheck = MELEE, actuallydamage = TRUE)
	var/temp_damage = damage
	if(!damage_coeff[damagetype])
		temp_damage = 0
	else
		temp_damage *= damage_coeff[damagetype]

	if(temp_damage >= 0 && temp_damage <= force_threshold)
		visible_message(SPAN_WARNING("[src] looks unharmed!"))
		return FALSE
	else
		if(actuallydamage)
			apply_damage(damage, damagetype, null, getarmor(null, armorcheck))
		return TRUE

/mob/living/simple_animal/bullet_act(obj/projectile/Proj, def_zone, piercing_hit = FALSE)
	apply_damage(Proj.damage, Proj.damage_type)
	Proj.on_hit(src, 0, piercing_hit)
	return BULLET_ACT_HIT

/mob/living/simple_animal/ex_act(severity, target, origin)
	if(origin && istype(origin, /datum/spacevine_mutation) && isvineimmune(src))
		return FALSE

	. = ..()
	if(QDELETED(src))
		return
	var/bomb_armor = getarmor(null, BOMB)
	switch (severity)
		if (EXPLODE_DEVASTATE)
			if(prob(bomb_armor))
				adjustBruteLoss(500)
			else
				gib()
				return
		if (EXPLODE_HEAVY)
			var/bloss = 60
			if(prob(bomb_armor))
				bloss = bloss / 1.5
			adjustBruteLoss(bloss)

		if (EXPLODE_LIGHT)
			var/bloss = 30
			if(prob(bomb_armor))
				bloss = bloss / 1.5
			adjustBruteLoss(bloss)

/mob/living/simple_animal/do_attack_animation(atom/A, visual_effect_icon, used_item, no_effect)
	if(!no_effect && !visual_effect_icon && melee_damage_upper)
		if(attack_vis_effect && !iswallturf(A)) // override the standard visual effect.
			visual_effect_icon = attack_vis_effect
		else if(melee_damage_upper < 10)
			visual_effect_icon = ATTACK_EFFECT_PUNCH
		else
			visual_effect_icon = ATTACK_EFFECT_SMASH
	..()
