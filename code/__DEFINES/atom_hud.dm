// for secHUDs and medHUDs and variants. The number is the location of the image on the list hud_list
// note: if you add more HUDs, even for non-human atoms, make sure to use unique numbers for the defines!
// /datum/atom_hud expects these to be unique
// these need to be strings in order to make them associative lists
/// dead, alive, sick, health status
#define HEALTH_HUD "1"
/// a simple line rounding the mob's number health
#define STATUS_HUD "2"
/// the job asigned to your ID
#define ID_HUD "3"
/// wanted, released, parroled, security status
#define WANTED_HUD "4"
/// loyality implant
#define IMPLOYAL_HUD "5"
/// chemical implant
#define IMPCHEM_HUD "6"
/// tracking implant
#define IMPTRACK_HUD "7"
/// Silicon/Mech/Circuit Status
#define DIAG_STAT_HUD "8"
/// Silicon health bar
#define DIAG_HUD "9"
/// Borg/Mech/Circutry power meter
#define DIAG_BATT_HUD "10"
/// Mech health bar
#define DIAG_MECH_HUD "11"
/// Bot HUDs
#define DIAG_BOT_HUD "12"
/// Circuit assembly health bar
#define DIAG_CIRCUIT_HUD "13"
/// Mech/Silicon tracking beacon, Circutry long range icon
#define DIAG_TRACK_HUD "14"
/// Airlock shock overlay
#define DIAG_AIRLOCK_HUD "15"
/// Bot path indicators
#define DIAG_PATH_HUD "16"
/// Gland indicators for abductors
#define GLAND_HUD "17"
#define AI_DETECT_HUD "18"
#define NANITE_HUD "19"
#define DIAG_NANITE_FULL_HUD "20"
/// Displays launchpads' targeting reticle
#define DIAG_LAUNCHPAD_HUD "21"
//for antag huds. these are used at the /mob level
#define ANTAG_HUD "22"
// for fans to identify pins
#define FAN_HUD "23"

//by default everything in the hud_list of an atom is an image
//a value in hud_list with one of these will change that behavior
#define HUD_LIST_LIST 1

//data HUD (medhud, sechud) defines
//Don't forget to update human/New() if you change these!
#define DATA_HUD_SECURITY_BASIC 1
#define DATA_HUD_SECURITY_ADVANCED 2
#define DATA_HUD_MEDICAL_BASIC 3
#define DATA_HUD_MEDICAL_ADVANCED 4
#define DATA_HUD_DIAGNOSTIC_BASIC 5
#define DATA_HUD_DIAGNOSTIC_ADVANCED 6
#define DATA_HUD_ABDUCTOR 7
#define DATA_HUD_FAN 8

//antag HUD defines
#define ANTAG_HUD_CULT 9
#define ANTAG_HUD_REV 10
#define ANTAG_HUD_OPS 11
#define ANTAG_HUD_WIZ 12
#define ANTAG_HUD_SHADOW 13
#define ANTAG_HUD_TRAITOR 14
#define ANTAG_HUD_NINJA 15
#define ANTAG_HUD_CHANGELING 16
#define ANTAG_HUD_ABDUCTOR 17
#define ANTAG_HUD_BROTHER 18
#define ANTAG_HUD_OBSESSED 19
#define ANTAG_HUD_FUGITIVE 20
#define ANTAG_HUD_GANGSTER 21
#define ANTAG_HUD_SPACECOP 22
#define ANTAG_HUD_HERETIC 23

// Notification action types
#define NOTIFY_JUMP "jump"
#define NOTIFY_ATTACK "attack"
#define NOTIFY_ORBIT "orbit"

/// cooldown for being shown the images for any particular data hud
#define ADD_HUD_TO_COOLDOWN 20
