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

#define BHUD_SETTINGS_NUMBER 9
#define COLOR_SETTINGS_START_IDX 0
#define COLOR_SETTINGS_END_IDX 4

#define JUMPSTATS_HUD_NUMBER 4

#define COLOR_BINARY_MIN_INT 0
#define COLOR_BINARY_MAX_INT 15
#define COLOR_BINARY_MASK 15
#define COLOR_BINARY_MASKF 15.0
#define COLOR_BINARY_BITS 4

#define POSITION_MIN_INT 0
#define POSITION_MAX_INT 255
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
	"Offset\nFJT",
	"Speed"
};

//bhud
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
	char strCookie[256];
	bool forceDefaults;
	for(int i = 0; i < BHUD_SETTINGS_NUMBER; i++)
	{
		GetClientCookie(client, g_hSettings[i], strCookie, sizeof(strCookie));
		if(strCookie[0] == '\0')
		{
			forceDefaults = true;
			break;
		}
		g_iSettings[client][i] = StringToInt(strCookie);
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
	g_iSettings[client][Bools] = 203079; //0000 0000 0000 0011 0001 1001 0100 0111
	g_iSettings[client][Positions_X] = 0; //all center
	g_iSettings[client][Positions_Y] = 5845913; //0000 0000 0101 1001 0011 0011 1001 1001 speed -1 offsets .35 trainer .2 jhud .6
	g_iSettings[client][Usage] = 6;
	g_iSettings[client][GainReallyBad] = Red;
	g_iSettings[client][GainBad] = Orange;
	g_iSettings[client][GainMeh] = Green;
	g_iSettings[client][GainGood] = Cyan;
	g_iSettings[client][GainReallyGood] = White;
	SaveAllCookies(client);
	PushPosCache(client);
}

void SaveAllCookies(int client)
{
	for(int i = 0; i < BHUD_SETTINGS_NUMBER; i++)
	{
		BgsSetCookie(client, g_hSettings[i], g_iSettings[client][i]);
	}
}
