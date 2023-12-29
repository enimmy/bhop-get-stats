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

#define BHUD_SETTINGS_NUMBER 9
#define COLOR_SETTINGS_START_IDX 0
#define COLOR_SETTINGS_END_IDX 4

#define JUMPSTATS_HUD_NUMBER 4

#define COLOR_BINARY_MIN_INT 0
#define COLOR_BINARY_MAX_INT 15
#define COLOR_BINARY_MASK 15
#define COLOR_BINARY_MASKF 15.0
#define COLOR_BINARY_BITS 4

#define POS_MIN_INT 0
#define POS_MAX_INT 255
#define POS_BINARY_MASK 255
#define POS_BINARY_MASKF 255.0
#define POS_INT_BITS 8

#define X_DIM 0
#define Y_DIM 1

//Position Notes float(0 - 1) int(0 - 255)
// converted float = (int/255). 0 values return -1 (dead center)
//
// 0000 0000 0000 0000 0000 0000 0000 0000 g_iSettngs[Position_Y]
// TX        TY        JX        JY
//
// 0000 0000 0000 0000 0000 0000 0000 0000 g_iSettngs[Position_X]
// SPX       SPY       OX        OY
//
// FJT tied to Offset


// 0000 0000 0000 0000 0000 0000 0000 0000
//                 Rg   G    M    B    RB

enum //indexes of binary position locations
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

static float g_fDefaultHudYPositions[] = {
	-1.0,
	0.2,
	0.35,
	0.01
};

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
	Positions_Y
}

float g_fCacheHudPositions[MAXPLAYERS + 1][4][2]; //Positions are stored in cookies as ints (0-255), this cache holds the players converted poitions
int g_iSettings[MAXPLAYERS + 1][BHUD_SETTINGS_NUMBER];
Cookie g_hSettings[BHUD_SETTINGS_NUMBER];

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
	for(int i = 0; i < 4; i++)
	{
		g_fCacheHudPositions[client][i][X_DIM] = GetAdjustedHudCoordinate(GetIntSubValue(g_iSettings[client][Positions_X], i, POS_INT_BITS, POS_BINARY_MASK), POS_BINARY_MASKF);
		g_fCacheHudPositions[client][i][Y_DIM] = GetAdjustedHudCoordinate(GetIntSubValue(g_iSettings[client][Positions_Y], i, POS_INT_BITS, POS_BINARY_MASK), POS_BINARY_MASKF);
		PrintDebugMsg(client, "Master-Hud: %s X,Y (%f, %f)", g_sHudStrs[i], g_fCacheHudPositions[client][i][X_DIM], g_fCacheHudPositions[client][i][Y_DIM]);
	}
}

public void OnClientCookiesCached(int client)
{
	char cookie[256];
	bool forceDefaults;
	for(int i = 0; i < BHUD_SETTINGS_NUMBER; i++)
	{
		GetClientCookie(client, g_hSettings[i], cookie, sizeof(cookie));
		if(cookie[0] == '\0')
		{
			forceDefaults = true;
			break;
		}
		g_iSettings[client][i] = StringToInt(cookie);
	}

	for(int i = COLOR_SETTINGS_START_IDX; i < COLOR_SETTINGS_END_IDX; i++)
	{
		if(g_iSettings[client][i] >= COLORS_NUMBER  || g_iSettings[client][i] < 0)
		{
			forceDefaults = true;
			break;
		}
	}

	if(forceDefaults)
	{
		SetDefaults(client);
	}
	else
	{
		PushPosCache(client);
	}
}

void SetDefaults(int client)
{
	//Just comment or uncomment stuff to enable or disable
	g_iSettings[client][Bools] = 0;
	g_iSettings[client][Bools] |= JHUD_ENABLED;
	g_iSettings[client][Bools] |= JHUD_JSS;
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

	g_iSettings[client][Positions_Y] = 0;
	for(int i = 0; i < JUMPSTATS_HUD_NUMBER; i++)
	{
		SetIntSubValue(g_iSettings[client][Positions_Y], GetHudCoordinateToInt(g_fDefaultHudYPositions[i], POS_BINARY_MASK, POS_MIN_INT, POS_MAX_INT), i, POS_INT_BITS, POS_BINARY_MASK);
	}

	g_iSettings[client][Positions_X] = 0;
	g_iSettings[client][Usage] = 1;
	g_iSettings[client][GainReallyBad] = Red;
	g_iSettings[client][GainBad] = Orange;
	g_iSettings[client][GainMeh] = Green;
	g_iSettings[client][GainGood] = Cyan;
	g_iSettings[client][GainReallyGood] = White;
	SaveAllCookies(client);
	PushPosCache(client);
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
	for(int i = 0; i < BHUD_SETTINGS_NUMBER; i++)
	{
		BgsSetCookie(client, g_hSettings[i], g_iSettings[client][i]);
	}
}
