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

#if !defined REQUIRE_PLUGIN
public void __pl_myfile_SetNTVOptional()
{
    MarkNativeAsOptional("BhopStat_GetJss");
}
#endif

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
 */
forward void BhopStat_StrafeForward(int client, int offset, bool overlap, bool nopress);

/**
 * returns a float comparing how close the clients angle difference to the perfect one for speed gain
 * updated runcmdPOST, updated when in air or groundticks == 1 && buttons injump
 */
native float BhopStat_GetJss(int client);