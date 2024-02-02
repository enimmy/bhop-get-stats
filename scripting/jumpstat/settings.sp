#define JHUD_ENABLED 1 << 0
#define JHUD_JSS 1 << 1
#define JHUD_SYNC 1 << 2
//open slot 1 << 3 prev: jhud extra speed replacing with speed colors till 0 - 16
#define TRAINER_ENABLED 1 << 4
#define OFFSETS_ENABLED 1 << 5
#define SPEEDOMETER_ENABLED 1 << 6
#define SPEEDOMETER_VELOCITY_DIFF 1 << 7
#define SSJ_ENABLED 1 << 8
#define SSJ_REPEAT 1 << 9
#define SSJ_HEIGHTDIFF 1 << 10
#define SSJ_GAIN 1 << 11
//open slot 1 << 12 prev: ssj en gain colors no replacement (always enable)
#define SSJ_EFFICIENCY 1 << 13
#define SSJ_SHAVIT_TIME 1 << 14
#define SSJ_SHAVIT_TIME_DELTA 1 << 15
#define SSJ_STRAFES 1 << 16
#define SSJ_SYNC 1 << 17
#define FJT_ENABLED 1 << 18
#define FJT_CHAT 1 << 19
#define OFFSETS_SPAM_CONSOLE 1 << 20
#define OFFSETS_ADVANCED 1 << 21
#define SSJ_JSS 1 << 22
#define SSJ_DECIMALS 1 << 23
#define SSJ_OFFSETS 1 << 24
#define TRAINER_STRICT 1 << 25
#define SHOWKEYS_ENABLED 1 << 26
#define SHOWKEYS_SIMPLE 1 << 27
#define SHOWKEYS_UNRELIABLE 1 << 28
//closed slot 1 << 29 for jump height by tekno
//open slot 1 << 30
//open slot 1 << 31
//open slot 1 << 32 -> must solve issues (or make sure there are none) with handling sign bit if this is used

//if all slots are used, use concepts from trainer positions to remake

#define COLOR_SETTINGS_START_IDX 0
#define COLOR_SETTINGS_END_IDX 4

#define POS_MIN_INT 0
#define POS_MAX_INT 255
#define POS_BINARY_MASK 255
#define POS_BINARY_MASKF 255.0
#define POS_INT_BITS 8

#define X_DIM 0
#define Y_DIM 1

enum
{
	Jhud,
	Trainer,
	Offset,
	Speedometer,
	FJT,
	ShowKeys
};

char g_sHudStrs[][] = {
	"Jhud",
	"Trainer",
	"Offset",
	"Speedometer",
	"FJT",
	"ShowKeys"
};

float g_fDefaultHudYPositions[] = {
	-1.0,
	0.2,
	0.35,
	0.01,
	0.4,
	-1.0
};

enum
{
	Trainer_Slow,
	Trainer_Medium,
	Trainer_Fast
}

char g_sTrainerSpeed[][] = {
	"Slow",
	"Medium",
	"Fast"
}

enum //indexes of settings
{
	GainReallyBad,
	GainBad,
	GainMeh,
	GainGood,
	GainReallyGood,
	Bools,
	Usage,
	Positions_X,
	Positions_Y,
	Positions2_X,
	Positions2_Y,
	TrainerSpeed,
	JhudCutOff,
	JhudSpeedColorsJump
}

float g_fCacheHudPositions[MAXPLAYERS + 1][sizeof(g_fDefaultHudYPositions)][2]; //Positions are stored in cookies as ints (0-255), this cache holds the players converted poitions
int g_iSettings[MAXPLAYERS + 1][14];
Cookie g_hSettings[14];

public void Settings_Start()
{
	g_hSettings[GainReallyBad] = RegClientCookie("js-rlybadgain", "", CookieAccess_Protected);
	g_hSettings[GainBad] = RegClientCookie("js-badgain", "", CookieAccess_Protected);
	g_hSettings[GainMeh] = RegClientCookie("js-mehgain", "", CookieAccess_Protected);
	g_hSettings[GainGood] = RegClientCookie("js-goodgain", "", CookieAccess_Protected);
	g_hSettings[GainReallyGood] = RegClientCookie("js-rlygoodgain", "", CookieAccess_Protected);
	g_hSettings[Bools] = RegClientCookie("js-bools", "", CookieAccess_Protected);
	g_hSettings[Usage] = RegClientCookie("js-usage", "", CookieAccess_Protected);
	g_hSettings[Positions_X] = RegClientCookie("js-hud-positions-x", "", CookieAccess_Protected);
	g_hSettings[Positions_Y] = RegClientCookie("js-hud-positions-y", "", CookieAccess_Protected);
	g_hSettings[Positions2_X] = RegClientCookie("js-hudpositions2-x", "", CookieAccess_Protected);
	g_hSettings[Positions2_Y] = RegClientCookie("js-hudpositions2-y", "", CookieAccess_Protected);
	g_hSettings[TrainerSpeed] = RegClientCookie("js-trainer-speed", "", CookieAccess_Protected);
	g_hSettings[JhudCutOff] = RegClientCookie("js-jhud-cutoff", "", CookieAccess_Protected);
	g_hSettings[JhudSpeedColorsJump] = RegClientCookie("js-jhud-speed-colors-jump", "", CookieAccess_Protected);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
}

void PushPosCache(int client)
{
	for(int i = 0; i < sizeof(g_fDefaultHudYPositions); i++)
	{
		g_fCacheHudPositions[client][i][X_DIM] = GetAdjustedHudCoordinate(GetHudPositionInt(client, i, X_DIM), POS_BINARY_MASKF);
		g_fCacheHudPositions[client][i][Y_DIM] = GetAdjustedHudCoordinate(GetHudPositionInt(client, i, Y_DIM), POS_BINARY_MASKF);
	}
}

void SetHudPositionInt(int client, int hud, int dim, int insert)
{
	int intPos = hud / (32 / POS_INT_BITS);
	int subValPos = hud % (32 / POS_INT_BITS);

	int tinyInd = 0;
	if(dim == X_DIM)
	{
		for(int i = 0; i < sizeof(g_iSettings[]); i++)
		{
			if(i == Positions_X || i == Positions2_X)
			{
				if(intPos == tinyInd)
				{
					SetIntSubValue(g_iSettings[client][i], insert, subValPos, POS_INT_BITS, POS_BINARY_MASK);
					return;
				}
				tinyInd++;
			}
		}
	}
	else
	{
		for(int i = 0; i < sizeof(g_iSettings[]); i++)
		{
			if(i == Positions_Y || i == Positions2_Y)
			{
				if(intPos == tinyInd)
				{
					SetIntSubValue(g_iSettings[client][i], insert, subValPos, POS_INT_BITS, POS_BINARY_MASK);
					return;
				}
				tinyInd++;
			}
		}
	}
}

int GetHudPositionInt(int client, int hud, int dim)
{
	int intPos = hud / (32 / POS_INT_BITS);
	int subValPos = hud % (32 / POS_INT_BITS);

	int tinyInd = 0;

	if(dim == X_DIM)
	{
		for(int i = 0; i < sizeof(g_iSettings[]); i++)
		{
			if(i == Positions_X || i == Positions2_X)
			{
				if(intPos == tinyInd)
				{
					return GetIntSubValue(g_iSettings[client][i], subValPos, POS_INT_BITS, POS_BINARY_MASK);
				}
				tinyInd++;
			}
		}
	}
	else
	{
		for(int i = 0; i < sizeof(g_iSettings[]); i++)
		{
			if(i == Positions_Y || i == Positions2_Y)
			{
				if(intPos == tinyInd)
				{
					return GetIntSubValue(g_iSettings[client][i], subValPos, POS_INT_BITS, POS_BINARY_MASK);
				}
				tinyInd++;
			}
		}
	}
	return 0;
}

void SaveHudPositionCookies(int client)
{
	BgsSetCookie(client, g_hSettings[Positions_X], g_iSettings[client][Positions_X]);
	BgsSetCookie(client, g_hSettings[Positions_Y], g_iSettings[client][Positions_Y]);
	BgsSetCookie(client, g_hSettings[Positions2_X], g_iSettings[client][Positions2_X]);
	BgsSetCookie(client, g_hSettings[Positions2_Y], g_iSettings[client][Positions2_Y]);
}

public void OnClientCookiesCached(int client)
{
	char cookie[256];
	for(int i = 0; i < sizeof(g_iSettings[]); i++)
	{
		GetClientCookie(client, g_hSettings[i], cookie, sizeof(cookie));

		if(cookie[0] == '\0')
		{
			SetDefaultSetting(client, i);
			break;
		}
		else
		{
			g_iSettings[client][i] = StringToInt(cookie);
		}
	}
	PushPosCache(client);
}

void SetAllDefaults(int client)
{
	PushDefaultBools(client);
	PushDefaultUsage(client);
	PushDefaultPositions1(client);
	PushDefaultPositions2(client);
	PushDefaultColors(client);
	PushDefaultTrainerSpeed(client);
	PushDefaultJhudCutoff(client);
}

void SetDefaultSetting(int client, int setting)
{
	if(setting >= COLOR_SETTINGS_START_IDX && setting <= COLOR_SETTINGS_END_IDX)
	{
		PushDefaultColors(client);
	}
	else if(setting == Bools)
	{
		PushDefaultBools(client);
	}
	else if(setting == Positions_X || setting == Positions_Y)
	{
		PushDefaultPositions1(client);
	}
	else if(setting == Positions2_X || setting == Positions2_Y)
	{
		PushDefaultPositions2(client);
	}
	else if(setting == TrainerSpeed)
	{
		PushDefaultTrainerSpeed(client);
	}
	else if(setting == JhudCutOff)
	{
		PushDefaultJhudCutoff(client);
	}
	else if(setting == JhudSpeedColorsJump)
	{
		PushDefaultJhudSpeedColorsJump(client);
	}
}

void PushDefaultBools(int client)
{
	g_iSettings[client][Bools] = 0;
	g_iSettings[client][Bools] |= JHUD_ENABLED;
	//g_iSettings[client][Bools] |= JHUD_JSS;
	g_iSettings[client][Bools] |= JHUD_SYNC;


	//g_iSettings[client][Bools] |= TRAINER_ENABLED;
	//g_iSettings[client][Bools] |= OFFSETS_ENABLED;
	//g_iSettings[client][Bools] |= SPEEDOMETER_ENABLED;
	//g_iSettings[client][Bools] |= SPEEDOMETER_VELOCITY_DIFF:
	g_iSettings[client][Bools] |= SSJ_ENABLED;
	g_iSettings[client][Bools] |= SSJ_REPEAT;
	//g_iSettings[client][Bools] |= SSJ_HEIGHTDIFF;
	g_iSettings[client][Bools] |= SSJ_GAIN;


	//g_iSettings[client][Bools] |= SSJ_EFFICIENCY;
	//g_iSettings[client][Bools] |= SSJ_SHAVIT_TIME;
	//g_iSettings[client][Bools] |= SSJ_SHAVIT_TIME_DELTA;
	g_iSettings[client][Bools] |= SSJ_STRAFES;
	g_iSettings[client][Bools] |= SSJ_SYNC;
	//g_iSettings[client][Bools] |= FJT_ENABLED;
	//g_iSettings[client][Bools] |= FJT_CHAT;
	//g_iSettings[client][Bools] |= OFFSETS_SPAM_CONSOLE;
	//g_iSettings[client][Bools] |= OFFSETS_ADVANCED;
	//g_iSettings[client][Bools] |= SSJ_JSS;
	//g_iSettings[client][Bools] |= SSJ_DECIMALS;
	//g_iSettings[client][Bools] |= SSJ_OFFSETS;
	//g_iSettings[client][Bools] |= TRAINER_STRICT;
	//g_iSettings[client][Bools] |= SHOWKEYS_ENABLED;
	//g_iSettings[client][Bools] |= SHOWKEYS_SIMPLE;

	if(BgsGetEngineVersion() == Engine_CSGO)
	{
		//g_iSettings[client][Bools] |= SHOWKEYS_UNRELIABLE;
	}
	else
	{
		g_iSettings[client][Bools] |= SHOWKEYS_UNRELIABLE;
	}

	BgsSetCookie(client, g_hSettings[Bools], g_iSettings[client][Bools]);
}

void PushDefaultUsage(int client)
{
	g_iSettings[client][Usage] = 1;
	BgsSetCookie(client, g_hSettings[Usage], g_iSettings[client][Usage]);
}

void PushDefaultJhudCutoff(int client)
{
	g_iSettings[client][JhudCutOff] = 0;
	BgsSetCookie(client, g_hSettings[JhudCutOff], g_iSettings[client][JhudCutOff]);
}

void PushDefaultJhudSpeedColorsJump(int client)
{
	g_iSettings[client][JhudSpeedColorsJump] = 6;
	BgsSetCookie(client, g_hSettings[JhudSpeedColorsJump], g_iSettings[client][JhudSpeedColorsJump]);
}

void PushDefaultPositions1(int client)
{
	g_iSettings[client][Positions_Y] = 0;

	SetHudPositionInt(client, Jhud, Y_DIM, GetHudCoordinateToInt(g_fDefaultHudYPositions[Jhud], POS_BINARY_MASK, POS_MIN_INT, POS_MAX_INT));
	SetHudPositionInt(client, Trainer, Y_DIM, GetHudCoordinateToInt(g_fDefaultHudYPositions[Trainer], POS_BINARY_MASK, POS_MIN_INT, POS_MAX_INT));
	SetHudPositionInt(client, Offset, Y_DIM, GetHudCoordinateToInt(g_fDefaultHudYPositions[Offset], POS_BINARY_MASK, POS_MIN_INT, POS_MAX_INT));
	SetHudPositionInt(client, Speedometer, Y_DIM, GetHudCoordinateToInt(g_fDefaultHudYPositions[Speedometer], POS_BINARY_MASK, POS_MIN_INT, POS_MAX_INT));

	g_iSettings[client][Positions_X] = 0;
	BgsSetCookie(client, g_hSettings[Positions_X], g_iSettings[client][Positions_X]);
	BgsSetCookie(client, g_hSettings[Positions_Y], g_iSettings[client][Positions_Y]);
	PushPosCache(client);
}

void PushDefaultPositions2(int client)
{
	g_iSettings[client][Positions2_Y] = 0;

	SetHudPositionInt(client, FJT, Y_DIM, GetHudCoordinateToInt(g_fDefaultHudYPositions[FJT], POS_BINARY_MASK, POS_MIN_INT, POS_MAX_INT));
	SetHudPositionInt(client, ShowKeys, Y_DIM, GetHudCoordinateToInt(g_fDefaultHudYPositions[ShowKeys], POS_BINARY_MASK, POS_MIN_INT, POS_MAX_INT));

	g_iSettings[client][Positions2_X] = 0;
	BgsSetCookie(client, g_hSettings[Positions2_X], g_iSettings[client][Positions2_X]);
	BgsSetCookie(client, g_hSettings[Positions2_Y], g_iSettings[client][Positions2_Y]);
	PushPosCache(client);
}

void PushDefaultColors(int client)
{
	g_iSettings[client][GainReallyBad] = Red;
	g_iSettings[client][GainBad] = Orange;
	g_iSettings[client][GainMeh] = Green;
	g_iSettings[client][GainGood] = Cyan;
	g_iSettings[client][GainReallyGood] = White;

	BgsSetCookie(client, g_hSettings[GainReallyBad], g_iSettings[client][GainReallyBad]);
	BgsSetCookie(client, g_hSettings[GainBad], g_iSettings[client][GainBad]);
	BgsSetCookie(client, g_hSettings[GainMeh], g_iSettings[client][GainMeh]);
	BgsSetCookie(client, g_hSettings[GainGood], g_iSettings[client][GainGood]);
	BgsSetCookie(client, g_hSettings[GainReallyGood], g_iSettings[client][GainReallyGood]);
}

void PushDefaultTrainerSpeed(int client)
{
	g_iSettings[client][TrainerSpeed] = Trainer_Slow;
	BgsSetCookie(client, g_hSettings[TrainerSpeed], g_iSettings[client][TrainerSpeed]);
}

void SetDefaultHudPos(int client, int hud)
{
	SetHudPositionInt(client, hud, X_DIM, 0);
	SetHudPositionInt(client, hud, Y_DIM, GetHudCoordinateToInt(g_fDefaultHudYPositions[hud], POS_BINARY_MASK, POS_MIN_INT, POS_MAX_INT));
	SaveHudPositionCookies(client);
	PushPosCache(client);
}

void SaveAllCookies(int client)
{
	for(int i = 0; i < sizeof(g_iSettings[]); i++)
	{
		BgsSetCookie(client, g_hSettings[i], g_iSettings[client][i]);
	}
}
