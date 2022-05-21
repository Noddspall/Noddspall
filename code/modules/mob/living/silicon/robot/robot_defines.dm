/***************************************************************************************
 * # robot_defines
 *
 * Definitions for /mob/living/silicon/robot and its children, including AI shells.
 *
 ***************************************************************************************/

/mob/living/silicon/robot
	name = "Cyborg"
	real_name = "Cyborg"
	icon = 'icons/mob/robots.dmi'
	icon_state = "robot"
	maxHealth = 100
	health = 100
	bubble_icon = "robot"
	designation = "Default" //used for displaying the prefix & getting the current model of cyborg
	has_limbs = TRUE
	hud_type = /datum/hud/robot

	///Represents the cyborg's model (engineering, medical, etc.)
	var/obj/item/robot_model/model = null

	radio = /obj/item/radio/borg

	blocks_emissive = EMISSIVE_BLOCK_UNIQUE
	light_system = MOVABLE_LIGHT_DIRECTIONAL
	light_on = FALSE

	//AI shell
	var/shell = FALSE
	var/deployed = FALSE
	var/mob/living/silicon/ai/mainframe = null
	var/datum/action/innate/undeployment/undeployment_action = new

// ------------------------------------------ Parts
	var/custom_name = ""
	var/braintype = "Cyborg"
	var/obj/item/mmi/mmi = null
	///Used for deconstruction to remember what the borg was constructed out of.
	var/obj/item/robot_suit/robot_suit = null
	///If this is a path, this gets created as an object in Initialize.
	var/obj/item/stock_parts/cell/cell = /obj/item/stock_parts/cell/high

	///If the lamp isn't broken.
	var/lamp_functional = TRUE
	///If the lamp is turned on
	var/lamp_enabled = FALSE
	///Set lamp color
	var/lamp_color = COLOR_WHITE
	///Set to true if a doomsday event is locking our lamp to on and RED
	var/lamp_doom = FALSE
	///Lamp brightness. Starts at 3, but can be 1 - 5.
	var/lamp_intensity = 3

	var/mutable_appearance/eye_lights

// ------------------------------------------ Hud
	var/atom/movable/screen/inv1 = null
	var/atom/movable/screen/inv2 = null
	var/atom/movable/screen/inv3 = null
	var/atom/movable/screen/hands = null

	///Used to determine whether they have the module menu shown or not
	var/shown_robot_modules = FALSE
	var/atom/movable/screen/robot_modules_background

	///Lamp button reference
	var/atom/movable/screen/robot/lamp/lampButton

	///The reference to the built-in tablet that borgs carry.
	var/obj/item/modular_computer/tablet/integrated/modularInterface
	var/atom/movable/screen/robot/modPC/interfaceButton

	var/sight_mode = 0
	hud_possible = list(ANTAG_HUD, DIAG_STAT_HUD, DIAG_HUD, DIAG_BATT_HUD, DIAG_TRACK_HUD)

// ------------------------------------------ Modules (tool slots)
	var/obj/item/module_active = null
	held_items = list(null, null, null) //we use held_items for the module holding, because that makes sense to do!

	///For checking which modules are disabled or not.
	var/disabled_modules

// ------------------------------------------ Status
	var/mob/living/silicon/ai/connected_ai = null

	var/opened = FALSE
	var/emagged = FALSE
	var/emag_cooldown = 0
	var/wiresexposed = FALSE

	var/lawupdate = TRUE //Cyborgs will sync their laws with their AI by default
	///Used to determine if a borg shows up on the robotics console.  Setting to TRUE hides them.
	var/scrambledcodes = FALSE
	///Boolean of whether the borg is locked down or not
	var/lockcharge = FALSE

	///Random serial number generated for each cyborg upon its initialization
	var/ident = 0
	var/locked = TRUE
	var/list/req_access = list(ACCESS_ROBOTICS)

	///Whether the robot has no charge left.
	var/low_power_mode = FALSE
	///So they can initialize sparks whenever/N
	var/datum/effect_system/spark_spread/spark_system

	///Magboot-like effect.
	var/magpulse = FALSE
	///Jetpack-like effect.
	var/ionpulse = FALSE
	///Jetpack-like effect.
	var/ionpulse_on = FALSE
	///Ionpulse effect.
	var/datum/effect_system/trail_follow/ion/ion_trail

	var/alarms = list(
		"Motion" = list(),
		"Fire" = list(),
		"Atmosphere" = list(),
		"Power" = list(),
		"Camera" = list(),
		"Burglar" = list())

// ------------------------------------------ Misc
	var/toner = 0
	var/tonermax = 40

	var/list/upgrades = list()

	var/hasExpanded = FALSE
	var/obj/item/hat
	var/hat_offset = -3

	///What types of mobs are allowed to ride/buckle to this mob
	var/static/list/can_ride_typecache = typecacheof(/mob/living/carbon/human)
	can_buckle = TRUE
	buckle_lying = 0

	/// the last health before updating - to check net change in health
	var/previous_health


/***************************************************************************************
 *                          Defining specific kinds of robots
 ***************************************************************************************/
///This is the subtype that gets created by robot suits. It's needed so that those kind of borgs don't have a useless cell in them
/mob/living/silicon/robot/nocell
	cell = null

/mob/living/silicon/robot/shell
	shell = TRUE
	cell = null

/mob/living/silicon/robot/model
	var/set_model = /obj/item/robot_model

/mob/living/silicon/robot/model/Initialize()
	. = ..()
	model.transform_to(set_model)

// --------------------- Clown
/mob/living/silicon/robot/model/clown
	set_model = /obj/item/robot_model/clown
	icon_state = "clown"

// --------------------- Engineering
/mob/living/silicon/robot/model/engineering
	set_model = /obj/item/robot_model/engineering
	icon_state = "engineer"

// --------------------- Janitor
/mob/living/silicon/robot/model/janitor
	set_model = /obj/item/robot_model/janitor
	icon_state = "janitor"

// --------------------- Medical
/mob/living/silicon/robot/model/medical
	set_model = /obj/item/robot_model/medical
	icon_state = "medical"

// --------------------- Miner
/mob/living/silicon/robot/model/miner
	set_model = /obj/item/robot_model/miner
	icon_state = "miner"

// --------------------- Peacekeeper
/mob/living/silicon/robot/model/peacekeeper
	set_model = /obj/item/robot_model/peacekeeper
	icon_state = "peace"

// --------------------- Security
/mob/living/silicon/robot/model/security
	set_model = /obj/item/robot_model/security
	icon_state = "sec"

// --------------------- Service (formerly Butler)
/mob/living/silicon/robot/model/service
	set_model = /obj/item/robot_model/service
	icon_state = "brobot"
