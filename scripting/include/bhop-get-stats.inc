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

// 0000 0000 0000 0000 0000 0000 0000 0000
// SX        OPX       TX        JX
// 
// 0000 0000 0000 0000 0000 0000 0000 0000
// SY        OY        TY        JY

enum //indexes of binary position locations
{
	Jhud,
	Trainer,
	Offset,
	Speed
};

char g_sHudStrs[][] = {
	"Jhud",
	"Trainer",
	"Offset",
	"Speed"
};

#define COLORS_NUMBER 9

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

char g_sBstatColorStrs[][] = { //strings for colors at same indexes as colors below
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

char g_sBstatColorsHex[][] = {
	"\x07ff0000",
	"\x07ffa500",
	"\x0700ff00",
	"\x0700ffff",
	"\x07ffffff",
	"\x07ffff00",
	"\x070000ff",
	"\x07800080",
	"\x07ee00ff"
};

int g_iBstatColors[][] = { //general colors
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

int g_iJhudSpeedValues[][] = { //jhud colors based on speeds for first 6 or first 16
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

//sMessage, number and average are different. number is on top, average is the | in the middle. they update at different rates
stock void Trainer_GetTrainerString(char sMessage[256], float number, float average) {
	char sVisualisation[32];
	Trainer_VisualisationString(sVisualisation, sizeof(sVisualisation), average);
	Format(sMessage, sizeof(sMessage), "%d\%", RoundFloat(number * 100));
	Format(sMessage, sizeof(sMessage), "%s\n══════^══════", sMessage);
	Format(sMessage, sizeof(sMessage), "%s\n %s ", sMessage, sVisualisation);
	Format(sMessage, sizeof(sMessage), "%s\n══════^══════", sMessage);
}

stock int Offset_GetColorIdx(int offset, bool overlap, bool nopress) {
    if(overlap || nopress || offset > 0) {
        return GainReallyBad;
    }
    if(offset == 0) {
		return GainGood;
    } else if(offset == -1) {
		return GainReallyGood;
    } else if(offset == -2) {
		return GainMeh;
	} else if(offset == -3) {
		return GainBad;
	} else {
		return GainReallyBad;
	}
}

stock int Bstat_GetGainColorIdx(float gain) {
	if(gain > 100) {
		return GainReallyBad;
	} else if(gain >= 90) {
		return GainReallyGood;
	} else if (gain >= 80) {
		return GainGood;
	} else if(gain >= 70) {
		return GainMeh;
	} else if(gain >= 60) {
		return GainBad;
	} else {
		return GainReallyBad;
	}
}

stock int Bstat_GetSpeedColorIdx(int jump, int speed) {
	if(jump < 0 || jump > 16) {
		return -1;
	}

	if(speed >= g_iJhudSpeedValues[jump][3]) {
		return GainReallyGood;
	} else if(speed > g_iJhudSpeedValues[jump][2]) {
		return GainGood;
	}  else if(speed > g_iJhudSpeedValues[jump][1]) {
		return GainMeh;
	}  else if(speed > g_iJhudSpeedValues[jump][0]) {
		return GainBad;
	} else {
		return GainReallyBad;
	}
}

stock int Bstat_GetHUDTarget(int client, int fallback = -1) {
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

stock int Bstat_GetIntSubValue(int num, int position, int binaryShift, int binaryMask) {
	return (num >> position * binaryShift) & binaryMask;
}

stock void Bstat_SetIntSubValue(int &editNum, int insertVal, int position, int binaryShift, int binaryMask) {
	editNum = (editNum & ~(binaryMask << (position * binaryShift))) | ((insertVal & binaryMask) << (position * binaryShift));
}

stock float Bstat_GetAdjustedHudCoordinate(int value, float scaler, float bias) {
	if(value < 0 || value > RoundToFloor(scaler)) {
		return -1.0;
	}
	float adjVal = (value / scaler) - bias; //255 - 0.01
	if(adjVal < 0.0) {
		return -1.0;
	}
	return adjVal;
}

stock int Bstat_HudCoordinateToInt(float value, int scaler, int min, int max) {
	if(value != -1.0 && (value < 0 || value > 1.0)) {
		return 0;
	}
	int adjVal = RoundToFloor(value * scaler);
	if(adjVal > max) {
		adjVal = max;
	}
	if(adjVal < min) {
		adjVal = min;
	}
	return adjVal;
}