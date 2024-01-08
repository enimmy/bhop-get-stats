#define JHUD_ENABLED 1 << 0
#define JHUD_JSS 1 << 1
#define JHUD_SYNC 1 << 2
#define JHUD_EXTRASPEED 1 << 3
#define TRAINER_ENABLED 1 << 4
#define OFFSETS_ENABLED 1 << 5
#define SPEEDOMETER_ENABLED 1 << 6
#define SPEEDOMETER_GAIN_COLOR 1 << 7
#define SSJ_ENABLED 1 << 8
#define SSJ_REPEAT 1 << 9
#define SSJ_HEIGHTDIFF 1 << 10
#define SSJ_GAIN 1 << 11
#define SSJ_GAIN_COLOR 1 << 12
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
	Speedometer
};

char g_sHudStrs[][] = {
	"Jhud",
	"Trainer",
	"Offset\nFJT",
	"Speedometer"
};

float g_fDefaultHudYPositions[] = {
	-1.0,
	0.2,
	0.35,
	0.01
};

enum
{
	Trainer_Slow,
	Trainer_Medium,
	Trainer_Fast
}

int g_iTrainerSpeeds[] = {
	13,
	6,
	2
};

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
	TrainerSpeed
}

float g_fCacheHudPositions[MAXPLAYERS + 1][sizeof(g_fDefaultHudYPositions)][2]; //Positions are stored in cookies as ints (0-255), this cache holds the players converted poitions
int g_iSettings[MAXPLAYERS + 1][10];
Cookie g_hSettings[10];

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
	g_hSettings[TrainerSpeed] = RegClientCookie("js-trainer-speed", "", CookieAccess_Protected);

	for(int i = 1; i <= MaxClients; i++)
	{
		if(AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
}

public void PushPosCache(int client)
{
	for(int i = 0; i < sizeof(g_fDefaultHudYPositions); i++)
	{
		g_fCacheHudPositions[client][i][X_DIM] = GetAdjustedHudCoordinate(GetIntSubValue(g_iSettings[client][Positions_X], i, POS_INT_BITS, POS_BINARY_MASK), POS_BINARY_MASKF);
		g_fCacheHudPositions[client][i][Y_DIM] = GetAdjustedHudCoordinate(GetIntSubValue(g_iSettings[client][Positions_Y], i, POS_INT_BITS, POS_BINARY_MASK), POS_BINARY_MASKF);
		PrintDebugMsg(client, "Master-Hud: %s X,Y (%f, %f)", g_sHudStrs[i], g_fCacheHudPositions[client][i][X_DIM], g_fCacheHudPositions[client][i][Y_DIM]);
	}
}

public void OnClientCookiesCached(int client)
{
	char cookie[256];
	for(int i = 0; i < sizeof(g_iSettings[]); i++)
	{
		GetClientCookie(client, g_hSettings[i], cookie, sizeof(cookie));

		if(cookie[0] == '\0')
		{
			g_iSettings[client][i] = -1;
		}
		else
		{
			g_iSettings[client][i] = StringToInt(cookie);
		}
	}

	for(int i = 0; i < sizeof(g_iSettings[]); i++)
	{
		int checkVal = g_iSettings[client][i];
		if(i >= COLOR_SETTINGS_START_IDX && i <= COLOR_SETTINGS_END_IDX && (checkVal == -1 || checkVal >= sizeof(g_iBstatColors)))
		{
			PushDefaultColors(client);
		}
		else if(i == Bools && checkVal == -1)
		{
			PushDefaultBools(client);
		}
		else if(i == Usage && checkVal == -1)
		{
			PushDefaultUsage(client);
		}
		else if(i == Positions_X || i == Positions_Y && (checkVal == -1 || checkVal > 255))
		{
			PushDefaultPositions(client);
		}
		else if(i == TrainerSpeed && (checkVal == -1 || checkVal >= sizeof(g_iTrainerSpeeds)))
		{
			PushDefaultTrainerSpeed(client);
		}
	}
	PushPosCache(client);
}

void SetAllDefaults(int client)
{
	PushDefaultBools(client);
	PushDefaultUsage(client);
	PushDefaultPositions(client);
	PushDefaultColors(client);
	PushDefaultTrainerSpeed(client);
}

void PushDefaultBools(int client)
{
	g_iSettings[client][Bools] = 0;
	g_iSettings[client][Bools] |= JHUD_ENABLED;
	//g_iSettings[client][Bools] |= JHUD_JSS;
	g_iSettings[client][Bools] |= JHUD_SYNC;
	//g_iSettings[client][Bools] |= JHUD_EXTRASPEED;
	//g_iSettings[client][Bools] |= TRAINER_ENABLED;
	//g_iSettings[client][Bools] |= OFFSETS_ENABLED;
	//g_iSettings[client][Bools] |= SPEEDOMETER_ENABLED;
	g_iSettings[client][Bools] |= SPEEDOMETER_GAIN_COLOR;
	g_iSettings[client][Bools] |= SSJ_ENABLED;
	g_iSettings[client][Bools] |= SSJ_REPEAT;
	//g_iSettings[client][Bools] |= SSJ_HEIGHTDIFF;
	g_iSettings[client][Bools] |= SSJ_GAIN;
	g_iSettings[client][Bools] |= SSJ_GAIN_COLOR;
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

	BgsSetCookie(client, g_hSettings[Bools], g_iSettings[client][Bools]);
}

void PushDefaultUsage(int client)
{
	g_iSettings[client][Usage] = 1;
	BgsSetCookie(client, g_hSettings[Usage], g_iSettings[client][Usage]);
}

void PushDefaultPositions(int client)
{
	g_iSettings[client][Positions_Y] = 0;
	for(int i = 0; i < sizeof(g_fDefaultHudYPositions); i++)
	{
		SetIntSubValue(g_iSettings[client][Positions_Y], GetHudCoordinateToInt(g_fDefaultHudYPositions[i], POS_BINARY_MASK, POS_MIN_INT, POS_MAX_INT), i, POS_INT_BITS, POS_BINARY_MASK);
	}

	g_iSettings[client][Positions_X] = 0;
	BgsSetCookie(client, g_hSettings[Positions_X], g_iSettings[client][Positions_X]);
	BgsSetCookie(client, g_hSettings[Positions_Y], g_iSettings[client][Positions_Y]);
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
	SetIntSubValue(g_iSettings[client][Positions_X], 0, hud, POS_INT_BITS, POS_BINARY_MASK);
	SetIntSubValue(g_iSettings[client][Positions_Y], GetHudCoordinateToInt(g_fDefaultHudYPositions[hud], POS_BINARY_MASK, POS_MIN_INT, POS_MAX_INT), hud, POS_INT_BITS, POS_BINARY_MASK);

	BgsSetCookie(client, g_hSettings[Positions_X], g_iSettings[client][Positions_X]);
	BgsSetCookie(client, g_hSettings[Positions_Y], g_iSettings[client][Positions_Y]);
	PushPosCache(client);
}

void SaveAllCookies(int client)
{
	for(int i = 0; i < sizeof(g_iSettings[]); i++)
	{
		BgsSetCookie(client, g_hSettings[i], g_iSettings[client][i]);
	}
}
