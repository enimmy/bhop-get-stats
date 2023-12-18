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

#define JHUD_SETTINGS_NUMBER 7
#define JHUD_SETTINGS_COLOR_START_IDX 0
#define JHUD_SETTINGS_COLOR_END_IDX 4
#define JHUD_SETTINGS_COLORS_NUMBER 9

#define JHUD_ENABLED	1 << 0
#define JHUD_JSS 		1 << 1
#define JHUD_SYNC 		1 << 2
#define JHUD_EXTRASPEED 1 << 3
#define TRAINER_ENABLED 1 << 4
#define OFFSETS_ENABLED 1 << 5

#define TRAINER_FULLUPDATE_TICK_INTERVAL 13
#define TRAINER_TICK_INTERVAL 5

enum //indexes of jhud positions
{
	Center,
	Top,
	Bottom
};

float g_iJhudPositions[3] = { //Jhud positions
	-1.0,
	0.4,
	-0.4
};

enum //indexes of settings masterhud
{
	GainReallyBad, //Red
	GainBad, //Orange
	GainMeh, //Green
	GainGood, //Cyan
	GainReallyGood, //White
	Bools,
	Position
}


enum //enum for colors same indexes as colors below
{
	Red, //for all colors structs, first 5 idxs are default, dont reorder them
	Orange,
	Green,
	Cyan,
	White,
	Yellow,
	Blue,
	Purple, 
	Pink
};

char colorStrs[][] = { //strings for colors at same indexes as colors below
	"Red",
	"Orange",
	"Green",
	"Cyan",
	"White",
	"Yellow",
	"Blue",
	"Purple",
	"Pink"
};

int colors[][3] = { //general colors
	{255, 0, 0},
	{255, 165, 0},
	{0, 255, 0},
	{0, 255, 255},
	{255, 255, 255},
	{255, 255, 0},
	{0, 0, 255},
	{128, 0, 128},
	{238, 0, 255}
};

int g_iJhudSpeedValues[][4] = { //jhud colors based on speeds for first 6 or first 16
	{},  				    // null
	{280, 282, 287, 289},  	// 1
	{366, 370, 375, 380},  	// 2
	{438, 442, 450, 455},  	// 3
	{500, 505, 515, 525},  	// 4
	{555, 560, 570, 580},  	// 5
	{605, 610, 620, 633},  	// 6
	{655, 665, 675, 680},  	// 7
	{700, 710, 725, 730}, 	// 8
	{740, 750, 765, 770},  	// 9
	{780, 790, 805, 810},  	// 10
	{810, 820, 840, 850},  	// 11
	{850, 860, 875, 885},  	// 12
	{880, 900, 900, 920},  	// 13
	{910, 920, 935, 955},  	// 14
	{945, 955, 965, 990},  	// 15
	{970, 980, 1000, 1020} 	// 16
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
 */
forward void BhopStat_StrafeForward(int client, int offset, bool overlap, bool nopress);

/**
 * returns a float comparing how close the clients angle difference to the perfect one for speed gain
 * updated runcmdPOST, updated when in air or groundticks == 1 && buttons injump
 */
native float BhopStat_GetJss(int client);

//returns a string with the | in the middle for trainer
stock void Trainer_VisualisationString(char[] buffer, int maxlength, float percentage) {
	if (0.5 <= percentage <= 1.5) {
		int Spaces = RoundFloat((percentage - 0.5) / 0.05);
		for (int i = 0; i <= Spaces + 1; i++) {
			FormatEx(buffer, maxlength, "%s ", buffer);
		}
		
		FormatEx(buffer, maxlength, "%s|", buffer);
		
		for (int i = 0; i <= (21 - Spaces); i++) {
			FormatEx(buffer, maxlength, "%s ", buffer);
		}
	}
	else {
		Format(buffer, maxlength, "%s", percentage < 1.0 ? "|                   " : "                    |");
	}
}

//writes to trainer, number and average are different. number is on top, average is the | in the middle. they update at different rates
stock void Trainer_GetTrainerString(char sMessage[256], float number, float average) {
	char sVisualisation[32];
	Trainer_VisualisationString(sVisualisation, sizeof(sVisualisation), average);
	Format(sMessage, sizeof(sMessage), "%d\%", RoundFloat(number * 100));
	Format(sMessage, sizeof(sMessage), "%s\n══════^══════", sMessage);
	Format(sMessage, sizeof(sMessage), "%s\n %s ", sMessage, sVisualisation);
	Format(sMessage, sizeof(sMessage), "%s\n══════^══════", sMessage);
}

//gets an index for Jhud based on either gain or speed, returns location of setting to get instead of color
stock int Jhud_GetJhudSettingsIdx(float gain, int jump = 0, int speed = 0, bool extraSpeed = false, bool ignoreSpeed = true) {
	if(!(ignoreSpeed) && ((jump <= 6 || jump == 16) || (extraSpeed && jump <= 16))) {
		if(speed < g_iJhudSpeedValues[jump][0]) {
			return GainReallyBad;
		}
		else if(speed >= g_iJhudSpeedValues[jump][0] && speed < g_iJhudSpeedValues[jump][1]) {
			return GainBad;
		}
		else if(speed >= g_iJhudSpeedValues[jump][1] && speed < g_iJhudSpeedValues[jump][2]) {
			return GainMeh;
		}
		else if(speed >= g_iJhudSpeedValues[jump][2] && speed < g_iJhudSpeedValues[jump][3]){
			return GainGood;
		} else {
			return GainReallyGood;
		}
	} else {
		if(gain < 60) {
			return GainReallyBad;
		}
		else if(gain >= 60 && gain < 70) {
			return GainBad;
		}
		else if(gain >= 70 && gain < 80) {
			return GainMeh;
		}
		else if (gain >= 80 && gain < 90) {
			return GainGood;
		}
		else {
			return GainReallyGood;
		}
	}
}

//jss colors trainer
stock int Trainer_GetColorIdx(float percentage) {
	if(percentage > 1.0) {
		return Red;
	} else if(percentage >= 0.9) {
		return White;
	}else if(percentage >= 0.8) {
		return Cyan;
	} else if(percentage >= 0.75) {
		return Green;
	} else if(percentage >= 0.65) {
		return Orange;
	} else {
		return Red;
	}
}

stock int Offset_GetColorIdx(int offset, bool overlap, bool nopress) {
    if(overlap || nopress || offset > 0) {
        return Red;
    }
    if(offset == 0) {
		return Cyan;
    } else if(offset == -1) {
		return White;
    } else if(offset == -2) {
		return Green;
    } else {
		return Red;
    }
}

stock int GetHUDTarget(int client, int fallback = -1) {
	int target = fallback;
	if(IsClientObserver(client)) {
		int iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
		if (iObserverMode >= 3 && iObserverMode <= 7) {
			int iTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
			if (Bstat_IsValidClient(iTarget)) {
				target = iTarget;
			}
		}
	}
	return target;
}

stock bool Bstat_IsValidClient(int client, bool bAlive = false) {
	return (client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && (!bAlive || IsPlayerAlive(client)));
}

stock void Bstat_SetCookie(int client, Cookie hCookie, int n) {
	char strCookie[64];
	IntToString(n, strCookie, sizeof(strCookie));
	SetClientCookie(client, hCookie, strCookie);
}