#if defined _bhopgetstats_included
	#endinput
#endif
#define _bhopgetstats_included

public SharedPlugin __pl_bhopgetstats =
{
    name = "bhop-get-stats",
    file = "bhop-get-stats.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

/**
 * Called after jump event and strafe statistics have been calculated.
 *
 * @param client					Client index
 * @param jump						jump number (resets groundticks > 10, nothing to do with timer zones)
 * @param speed					    Current speed
 * @param strafecount               number of strafes in the jump
 * @param heightdelta				Height change since last jump
 * @param gain						avg gain of jump
 * @param sync                      strafe sync of jump
 * @param eff                       strafe efficency of jump
 * @param yawwing					% of jump player was turnbinding
 * @param jss						average strafe speed of the players jump compared to perfect
 * @noreturn
 */
forward void BhopStat_JumpForward(int client, int jump, int speed, int strafecount, float heightdelta, float gain, float sync, float eff, float yawwing, float jss);

/**
 * @param client					client index
 * @param offset					keypress tick - turn tick
 * @param overlap					if the player overlapped their keys during this strafe
 * @param nopress					if the player wasnt holding one of their strafe keys during this strafe
 * @noreturn
 */
forward void BhopStat_StrafeForward(int client, int offset, bool overlap, bool nopress);

/** not called unless calculated (in air/bhopping)
 * @param client					client index
 * @param gain						gain this tick
 * @param jss						jss this tick
 * @noreturn
 */
forward void BhopStat_TickForward(int client, int speed, bool inBhop, float gain, float jss);
