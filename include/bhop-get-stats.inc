#if defined _bhopgetstats_included
	#endinput
#endif
#define _bhopgetstats_included

/**
 * Called after jump event and strafe statistics have been calculated.
 *
 * @param client					Client index
 * @param jump						jumpo number
 * @param speed					    Current speed
 * @param strafecount               number of strafes in the jump
 * @param heightdelta				Height change since last jump
 * @param gain						avg gain of jump
 * @param sync                      strafe sync of last jump
 * @param eff                       strafe efficency of last jump
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