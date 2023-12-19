#include <sourcemod>
#include <clientprefs>
#include <bhop-get-stats>
#include <DynamicChannels>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <shavit>

#pragma semicolon 1
#pragma newdecls required

#define BHUD_SETTINGS_NUMBER 9
#define COLOR_SETTINGS_START_IDX 0 //could refactor this to use binary but idk, same way as the positions
#define COLOR_SETTINGS_END_IDX 4

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

#define TRAINER_FULLUPDATE_TICK_INTERVAL 13
#define TRAINER_TICK_INTERVAL 5
#define SPEED_UPDATE_INTERVAL 10

#define COLOR_BINARY_MIN_INT 0 //unused for now
#define COLOR_BINARY_MAX_INT 15
#define COLOR_BINARY_MASK 15
#define COLOR_BINARY_MASKF 15.0
#define COLOR_BINARY_BITS 4

#define POSITION_MIN_INT 0
#define POSITION_MAX_INT 255
#define POS_BINARY_MASK 255
#define POS_BINARY_MASKF 255.0
#define POS_COORD_BIAS 0.01
#define POS_INT_BITS 8

#define X_DIM 0
#define Y_DIM 1

public Plugin myinfo = 
{
	name = "bgs-jumpstats",
	author = "Nimmy",
	description = "all kinds of stuff", 
	version = "3.0", 
	url = "https://github.com/Nimmy2222/bhop-get-stats"
}

//Position Notes float(0 - 1) int(0 - 255)
// converted float = (int/255) - .01. Negative values return -1 (dead center)
//
// 0000 0000 0000 0000 0000 0000 0000 0000 g_iSettngs[Position_Y]
// TX        TY        JX        JY
// 
// 0000 0000 0000 0000 0000 0000 0000 0000 g_iSettngs[Position_X]
// SPX       SPY       OX        OY
//

//Dynamic Channel Notes - CSS
// Trainer 0 (here)
// Jhud 1 (here)
// Offset 2 (here)
// Widow Bash 3 (xWidows bash, just displays devs and stuff) OTHER DEVS USE THIS ONE !!!!! WRITE THIS SOMEWHERE
// Speedometer 4 (here)
// Shavit-Hud Top Left 5 (https://github.com/shavitush/bhoptimer/blob/7fb0f45c2c75714b4192f48e4b7ea030b0f9b5a9/addons/sourcemod/scripting/shavit-hud.sp#L2059)

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
Cookie g_hSettings[BHUD_SETTINGS_NUMBER];

ConVar g_hOverrideJhud;
ConVar g_hOverrideTrainer;
ConVar g_hOverrideOffset;
ConVar g_hOverrideSpeed;
ConVar g_hOverrideSsj;

int g_iSettings[MAXPLAYERS + 1][BHUD_SETTINGS_NUMBER]; //Cache settings, idxs match cookie array
int g_iEditGain[MAXPLAYERS + 1]; //Cache for menu idx, keeps track of which gain catergory (50-, 50-60, etc) the player wants to edit the color of
int g_iEditHud[MAXPLAYERS + 1]; //Cache for menu idx, keeps track of which hud (jhud, offset, etc) the player wants to edit the position of
int g_iCmdNum[MAXPLAYERS + 1]; //Tick counter managed for trainer/speedometer
bool g_bEditing[MAXPLAYERS + 1]; //Setting to true enables "edit mode", see OnPlayerRunCmd
float g_fCacheHudPositions[MAXPLAYERS + 1][4][2]; //Positions are stored in cookies as ints (0-255), this cache holds the players converted poitions

//trainer
#define FullPercent 0
#define BarPercent 1

float g_fTrainerPercents[MAXPLAYERS + 1][2];
float g_fLastAverage[MAXPLAYERS + 1];

//offsets
int g_iLastOffset[MAXPLAYERS + 1];
int g_iRepeatedOffsets[MAXPLAYERS + 1];

//speedometer
int g_iLastSpeedometerVel[MAXPLAYERS + 1];
float g_fRawGain[MAXPLAYERS + 1];

//Do we got the shavits
bool g_bShavit = false;
bool g_bLate = false;
chatstrings_t g_sChatStrings;
float g_fLastJumpTime[MAXPLAYERS + 1];
EngineVersion gEV_Type = Engine_Unknown;

public void OnPluginStart() 
{
	RegConsoleCmd("sm_js", Command_Js, "Opens the bhud main menu");
	RegConsoleCmd("sm_strafetrainer", Command_CheckTrainerOverride, "Opens the bhud main menu");
	RegConsoleCmd("sm_trainer", Command_CheckTrainerOverride, "Opens the bhud main menu");
	RegConsoleCmd("sm_jhud", Command_CheckJhudOverride, "Opens the bhud main menu");
	RegConsoleCmd("sm_offsets", Command_CheckOffsetOverride, "Opens the bhud main menu");
	RegConsoleCmd("sm_offset", Command_CheckOffsetOverride, "Opens the bhud main menu");
	RegConsoleCmd("sm_speedometer", Command_CheckSpeedOverride, "Opens the bhud main menu");
	RegConsoleCmd("sm_speed", Command_CheckSpeedOverride, "Opens the bhud main menu");
	RegConsoleCmd("sm_ssj", Command_CheckSsjOverride, "Opens the bhud main menu");

	g_hOverrideJhud 			= CreateConVar("js-override-jhud", "1", "Override /jhud command? 0 (false) or 1 (true)");
	g_hOverrideTrainer 			= CreateConVar("js-override-trainer", "1", "Override /strafetrainer command? 0 (false) or 1 (true)");
	g_hOverrideOffset 			= CreateConVar("js-override-offset", "1", "Override /offset command? 0 (false) or 1 (true)");
	g_hOverrideSpeed			= CreateConVar("js-override-speed", "1", "Override /speedometer command? 0 (false) or 1 (true)");
	g_hOverrideSsj 				= CreateConVar("js-override-ssj", "1", "Override /ssj command? 0 (false) or 1 (true)");

	g_hSettings[GainReallyBad] 	= RegClientCookie("js-rlybadgain", "", CookieAccess_Protected);
	g_hSettings[GainBad] 		= RegClientCookie("js-badgain", "", CookieAccess_Protected);
	g_hSettings[GainMeh] 		= RegClientCookie("js-mehgain", "", CookieAccess_Protected);
	g_hSettings[GainGood] 		= RegClientCookie("js-goodgain", "", CookieAccess_Protected);
	g_hSettings[GainReallyGood] = RegClientCookie("js-rlygoodgain", "", CookieAccess_Protected);
	g_hSettings[Bools] 			= RegClientCookie("js-bools", "", CookieAccess_Protected);
	g_hSettings[Usage] 			= RegClientCookie("js-usage", "", CookieAccess_Protected);
	g_hSettings[Positions_X] 	= RegClientCookie("js-hud-positions-x", "", CookieAccess_Protected);
	g_hSettings[Positions_Y] 	= RegClientCookie("js-hud-positions-y", "", CookieAccess_Protected);

	for(int i = 1; i <= MaxClients; i++) 
	{
		if(AreClientCookiesCached(i)) 
		{
			OnClientCookiesCached(i);
		}
	}

	g_bShavit = LibraryExists("shavit");
	if(g_bLate && g_bShavit) 
	{
		Shavit_OnChatConfigLoaded();
	}
	gEV_Type = GetEngineVersion();
	AutoExecConfig();
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "shavit")) 
	{
		g_bShavit = true;
		Shavit_OnChatConfigLoaded();
	}
}

public void OnLibraryRemoved(const char[] name) 
{
	if(StrEqual(name, "shavit")) 
	{
		g_bShavit = false;
	}
}

public void Shavit_OnChatConfigLoaded() 
{
	Shavit_GetChatStrings(sMessagePrefix, g_sChatStrings.sPrefix, sizeof(chatstrings_t::sPrefix));
	Shavit_GetChatStrings(sMessageText, g_sChatStrings.sText, sizeof(chatstrings_t::sText));
	Shavit_GetChatStrings(sMessageWarning, g_sChatStrings.sWarning, sizeof(chatstrings_t::sWarning));
	Shavit_GetChatStrings(sMessageVariable, g_sChatStrings.sVariable, sizeof(chatstrings_t::sVariable));
	Shavit_GetChatStrings(sMessageVariable2, g_sChatStrings.sVariable2, sizeof(chatstrings_t::sVariable2));
	Shavit_GetChatStrings(sMessageStyle, g_sChatStrings.sStyle, sizeof(chatstrings_t::sStyle));
}

public Action Command_Js(int client, any args) 
{
	if(!Bstat_IsValidClient(client)) 
	{
		return Plugin_Handled;
	}
	ShowJsMenu(client);
	return Plugin_Handled;
}

public Action Command_CheckJhudOverride(int client, any args) 
{
	if(g_hOverrideJhud.IntValue) 
	{
		Command_Js(client, 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_CheckTrainerOverride(int client, any args) 
{
	if(g_hOverrideTrainer.IntValue) 
	{
		Command_Js(client, 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_CheckSpeedOverride(int client, any args) 
{
	if(g_hOverrideSpeed.IntValue) 
	{
		Command_Js(client, 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_CheckOffsetOverride(int client, any args) 
{
	if(g_hOverrideOffset.IntValue) 
	{
		Command_Js(client, 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_CheckSsjOverride(int client, any args) 
{
	if(g_hOverrideSsj.IntValue) 
	{
		Command_Js(client, 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void PushPosCache(int client)
{
	for(int i = 0; i < 4; i++) 
	{
		g_fCacheHudPositions[client][i][X_DIM] = Bstat_GetAdjustedHudCoordinate(Bstat_GetIntSubValue(g_iSettings[client][Positions_X], i, POS_INT_BITS, POS_BINARY_MASK), POS_BINARY_MASKF, POS_COORD_BIAS);
		g_fCacheHudPositions[client][i][Y_DIM] = Bstat_GetAdjustedHudCoordinate(Bstat_GetIntSubValue(g_iSettings[client][Positions_Y], i, POS_INT_BITS, POS_BINARY_MASK), POS_BINARY_MASKF, POS_COORD_BIAS);
		PrintToConsole(client, "Master-Hud: %s X,Y (%f, %f)", g_sHudStrs[i], g_fCacheHudPositions[client][i][X_DIM], g_fCacheHudPositions[client][i][Y_DIM]);
	}
}

public void OnClientCookiesCached(int client)
{
	char strCookie[8];

	for(int i = 0; i < BHUD_SETTINGS_NUMBER; i++) 
	{
		GetClientCookie(client, g_hSettings[i], strCookie, sizeof(strCookie));
		if(strCookie[0] == '\0') 
		{
			SetDefaults(client);
			return;
		}
		g_iSettings[client][i] = StringToInt(strCookie);
	}

	for(int i = COLOR_SETTINGS_START_IDX; i < COLOR_SETTINGS_END_IDX; i++) 
	{
		if(g_iSettings[client][i] >= COLORS_NUMBER  || g_iSettings[client][i] < 0) 
		{
			SetDefaults(client);
			return;
		}
	}
	PushPosCache(client);
	g_bEditing[client] = false;
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
	PushPosCache(client);
	SaveAllCookies(client);
}

void SaveAllCookies(int client) 
{
	for(int i = 0; i < BHUD_SETTINGS_NUMBER; i++) 
	{
		SetCookie(client, g_hSettings[i], g_iSettings[client][i]);
	}
}

public void BhopStat_JumpForward(int client, int jump, int speed, int strafecount, float heightdelta, float gain, float sync, float eff, float yawwing, float jss) 
{
	
	float time = 0.0;
	if(g_bShavit) 
	{
		time = Shavit_GetClientTime(client);
	}

	for(int i = 1; i < MaxClients; i++) 
	{
		if((!(g_iSettings[i][Bools] & JHUD_ENABLED) && !(g_iSettings[i][Bools] & SSJ_ENABLED)) || !Bstat_IsValidClient(i)) 
		{
			continue;
		}
		if((i == client && IsPlayerAlive(i)) || (!IsPlayerAlive(i) && Bstat_GetHUDTarget(i) == client)) 
		{
			if(g_iSettings[i][Bools] & JHUD_ENABLED) 
			{
				JHUD_DrawStats(i, jump, speed, gain, sync, jss);
			}
			if(g_iSettings[i][Bools] & SSJ_ENABLED) 
			{
				SSJ_WriteMessage(i, client, jump, speed, strafecount, heightdelta, gain, sync, eff);
			}
		}
	}
	g_fLastJumpTime[client] = time;
}

public void BhopStat_StrafeForward(int client, int offset, bool overlap, bool nopress) 
{
	if(g_iLastOffset[client] == offset) 
	{
		g_iRepeatedOffsets[client]++;
	} 
	else 
	{
		g_iRepeatedOffsets[client] = 0;
	}
	for(int i = 1; i < MaxClients; i++) 
	{
		if(!(g_iSettings[i][Bools] & OFFSETS_ENABLED) || !Bstat_IsValidClient(i))
		{
			continue;
		}

		if((i == client && IsPlayerAlive(i)) || (!IsPlayerAlive(i) && Bstat_GetHUDTarget(i) == client))
		{
			Offset_DrawOffset(i, offset, overlap, nopress);
		}
	}
	g_iLastOffset[client] = offset;
}

public void BhopStat_TickForward(int client, int speed, bool inbhop, float gain, float jss) 
{
	g_iCmdNum[client]++;
	bool speedometer = (g_iCmdNum[client] % SPEED_UPDATE_INTERVAL == 0);
	bool trainer = (g_iCmdNum[client] % TRAINER_FULLUPDATE_TICK_INTERVAL == 0 || g_iCmdNum[client] % TRAINER_TICK_INTERVAL == 0);
	
	if(!inbhop) 
	{
		g_fTrainerPercents[client][FullPercent] = 0.0;
		g_fTrainerPercents[client][BarPercent] = 0.0;
		g_fRawGain[client] = 0.0;
		if(speedometer) 
		{
			g_iCmdNum[client] = 0;
		}
	}
	else 
	{
		g_fTrainerPercents[client][FullPercent] += jss;
		g_fTrainerPercents[client][BarPercent] += jss;
		g_fRawGain[client] += gain;

		if(trainer) 
		{
			float AveragePercentage;
			bool fullUpdate = (g_iCmdNum[client] % TRAINER_FULLUPDATE_TICK_INTERVAL == 0);

			if (fullUpdate) 
			{
				AveragePercentage = g_fTrainerPercents[client][FullPercent] / TRAINER_FULLUPDATE_TICK_INTERVAL;
				g_fTrainerPercents[client][FullPercent] = 0.0;
				g_fLastAverage[client] = AveragePercentage;
			}

			if (g_iCmdNum[client] % TRAINER_TICK_INTERVAL == 0) 
			{
				if(!fullUpdate) 
				{
					AveragePercentage = g_fTrainerPercents[client][BarPercent] / TRAINER_TICK_INTERVAL;
				}
				g_fTrainerPercents[client][BarPercent] = 0.0;
			}
			for (int i = 1; i <= MaxClients; i++) 
			{
				if(!Bstat_IsValidClient(i) || !(g_iSettings[client][Bools] & TRAINER_ENABLED))
				{
					continue;
				}

				if((i == client && IsPlayerAlive(i)) || (Bstat_GetHUDTarget(i) == client && !IsPlayerAlive(i))) 
				{
					char sMessage[256];
					Trainer_GetTrainerString(sMessage, g_fLastAverage[client], AveragePercentage);

					int idx = Bstat_GetGainColorIdx(AveragePercentage * 100);
					int settingsIdx = g_iSettings[client][idx];
					SetHudTextParams(g_fCacheHudPositions[client][Trainer][X_DIM], g_fCacheHudPositions[client][Trainer][Y_DIM], 0.1, g_iBstatColors[settingsIdx][0], g_iBstatColors[settingsIdx][1], g_iBstatColors[settingsIdx][2], 255, 0, 0.0, 0.0, 0.0);
					ShowHudText(i, GetDynamicChannel(0), sMessage); //TRAINER
				}
			}
		}
	}

	if(speedometer) {
		for (int i = 1; i <= MaxClients; i++) 
		{
			if(!Bstat_IsValidClient(i) || !(g_iSettings[i][Bools] & SPEEDOMETER_ENABLED))
			{
				continue;
			}

			if((i == client && IsPlayerAlive(i)) || (Bstat_GetHUDTarget(i) == client && !IsPlayerAlive(i))) 
			{
				int idx;
				char sMessage[256];
				Format(sMessage, sizeof(sMessage), "%i", speed);
				float coeffsum = g_fRawGain[client];
				coeffsum /= SPEED_UPDATE_INTERVAL;
				coeffsum *= 100.0;
				coeffsum = RoundToFloor(coeffsum * 100.0 + 0.5) / 100.0;
				if(g_iSettings[i][Bools] & SPEEDOMETER_GAIN_COLOR && inbhop) 
				{
					idx = Bstat_GetGainColorIdx(coeffsum);
				} 
				else 
				{
					if(speed > g_iLastSpeedometerVel[client]) 
					{
						idx = GainReallyGood;
					} 
					else if (speed == g_iLastSpeedometerVel[client]) 
					{
						idx = GainGood;
					} 
					else 
					{
						idx = GainReallyBad;
					}
				}
				int settingsIdx = g_iSettings[client][idx];
				SetHudTextParams(g_fCacheHudPositions[client][Speed][X_DIM], g_fCacheHudPositions[client][Speed][Y_DIM], 0.2, g_iBstatColors[settingsIdx][0], g_iBstatColors[settingsIdx][1], g_iBstatColors[settingsIdx][2], 255, 0, 0.0, 0.0, 0.0);
				ShowHudText(i, GetDynamicChannel(4), sMessage); //SPEEDOMETER -1, -1
			}
		}
		g_fRawGain[client] = 0.0;
		g_iLastSpeedometerVel[client] = speed;
	}
	return;
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2]) {
	if(!g_bEditing[client])
	{
		return Plugin_Continue;
	}
	
	bool edit = true;
	bool up = false;
	int editDim;
	if(buttons & IN_MOVERIGHT) 
	{
		editDim = Positions_X;
	} 
	else if(buttons & IN_MOVELEFT) 
	{
		editDim = Positions_X;
		up = true;
	} 
	else if(buttons & IN_FORWARD) 
	{
		up = true;
		editDim = Positions_Y;
	} 
	else if(buttons & IN_BACK) 
	{
		editDim = Positions_Y;
	} 
	else 
	{
		edit = false;
	}
	if(edit) 
	{
		EditHudPosition(client, editDim, up);
	}
	SetEntityMoveType(client, MOVETYPE_NONE);
	return Plugin_Continue;
}

public void EditHudPosition(int client, int editDim, bool up) 
{
	int get4;
	if(up)
	{
		get4 = Bstat_GetIntSubValue(g_iSettings[client][editDim], g_iEditHud[client], POS_INT_BITS, POS_BINARY_MASK) - 1;
	}
	else
	{
		get4 = Bstat_GetIntSubValue(g_iSettings[client][editDim], g_iEditHud[client], POS_INT_BITS, POS_BINARY_MASK) + 1;
	}
	
	if(get4 < POSITION_MIN_INT)
	{
		get4 = POSITION_MAX_INT;
	}

	if(get4 > POSITION_MAX_INT || get4 < POSITION_MIN_INT)
	{
		get4 = POSITION_MIN_INT;
	}

	Bstat_SetIntSubValue(g_iSettings[client][editDim], get4, g_iEditHud[client], POS_INT_BITS, POS_BINARY_MASK);
	PushPosCache(client);
	SetHudTextParams(g_fCacheHudPositions[client][g_iEditHud[client]][X_DIM], g_fCacheHudPositions[client][g_iEditHud[client]][Y_DIM], 1.0, g_iBstatColors[GainGood][0], g_iBstatColors[GainGood][1], g_iBstatColors[GainGood][2], 255, 0, 0.0, 0.0, 0.0);
	ShowHudText(client, GetDynamicChannel(0), g_sHudStrs[g_iEditHud[client]]);
}

void JHUD_DrawStats(int client, int jump, int speed, float gain, float sync, float jss) 
{
	int ijss = RoundToFloor(jss * 100);
	
	char sMessage[256];

	int settingIdx;
	if((jump <= 6 || jump == 16) || (g_iSettings[client][Bools] & JHUD_EXTRASPEED && jump <= 16))
	{
		settingIdx = Bstat_GetSpeedColorIdx(jump, speed);
	}
	else
	{
		settingIdx = Bstat_GetGainColorIdx(gain);
	}

	int rgb[3];
	rgb = g_iBstatColors[g_iSettings[client][settingIdx]];

	Format(sMessage, sizeof(sMessage), "%i: %i", jump, speed);
	if(jump > 1) 
	{
		if(g_iSettings[client][Bools] & JHUD_JSS == JHUD_JSS)
		{
			Format(sMessage, sizeof(sMessage), "%s (%iPCT)", sMessage, ijss);
		}

		Format(sMessage, sizeof(sMessage), "%s\n%.2f", sMessage, gain);
		if(g_iSettings[client][Bools] & JHUD_SYNC == JHUD_SYNC)
		{
			Format(sMessage, sizeof(sMessage), "%s %.2fPCT", sMessage, sync);
		}
	}
	ReplaceString(sMessage, sizeof(sMessage), "PCT", "%%", true);
	SetHudTextParams(g_fCacheHudPositions[client][Jhud][X_DIM], g_fCacheHudPositions[client][Jhud][Y_DIM], 1.0, rgb[0], rgb[1], rgb[2], 255, 0, 0.0, 0.0, 0.0);
	ShowHudText(client, GetDynamicChannel(1), sMessage); //JHUD
}

void SSJ_WriteMessage(int client, int target, int jump, int speed, int strafecount, float heightdelta, float gain, float sync, float eff) 
{
	if(g_iSettings[client][Bools] & SSJ_REPEAT) 
	{
		if(jump % g_iSettings[client][Usage] != 0)
		{
			return;
		}
	} 
	else if(jump != g_iSettings[client][Usage])
	{
		return;
	}

	char sMessage[300];
	FormatEx(sMessage, sizeof(sMessage), "J: %s%i", g_sChatStrings.sVariable, jump);
	Format(sMessage, sizeof(sMessage), "%s %s| S: %s%i", sMessage, g_sChatStrings.sText, g_sChatStrings.sVariable, speed);

	if(jump > 1) 
	{
		float time = 0.0;
		if(g_bShavit)
		{
			time = Shavit_GetClientTime(client);
		}

		if(g_iSettings[client][Bools] & SSJ_GAIN) 
		{
			if(g_iSettings[client][Bools] & SSJ_GAIN_COLOR) 
			{
				int idx = Bstat_GetGainColorIdx(gain);
				int settingsIdx = g_iSettings[client][idx];
				Format(sMessage, sizeof(sMessage), "%s %s| G: %s%.1f%%", sMessage, g_sChatStrings.sText, g_sBstatColorsHex[settingsIdx], gain);
			} 
			else
			{
				Format(sMessage, sizeof(sMessage), "%s %s| G: %s%.1f%%", sMessage, g_sChatStrings.sText, g_sChatStrings.sVariable, gain);
			}
		}

		if(g_iSettings[client][Bools] & SSJ_SYNC)
		{
			Format(sMessage, sizeof(sMessage), "%s %s| S: %s%.1f%%", sMessage, g_sChatStrings.sText, g_sChatStrings.sVariable, sync);
		}

		if(g_iSettings[client][Bools] & SSJ_EFFICIENCY)
		{
			Format(sMessage, sizeof(sMessage), "%s %s| Ef: %s%.1f%%", sMessage, g_sChatStrings.sText, g_sChatStrings.sVariable, eff);
		}

		if(g_iSettings[client][Bools] & SSJ_HEIGHTDIFF)
		{
			Format(sMessage, sizeof(sMessage), "%s %s| HΔ: %s%.1f", sMessage, g_sChatStrings.sText, g_sChatStrings.sVariable, heightdelta);
		}

		if(g_iSettings[client][Bools] & SSJ_STRAFES)
		{
			Format(sMessage, sizeof(sMessage), "%s %s| Stf: %s%i", sMessage, g_sChatStrings.sText, g_sChatStrings.sVariable, strafecount);
		}

		if(g_iSettings[client][Bools] & SSJ_SHAVIT_TIME && g_bShavit)
		{
			Format(sMessage, sizeof(sMessage), "%s %s| T: %s%.2f", sMessage, g_sChatStrings.sText, g_sChatStrings.sVariable, time);
		}

		if(g_iSettings[client][Bools] & SSJ_SHAVIT_TIME_DELTA && g_bShavit)
		{
			Format(sMessage, sizeof(sMessage), "%s %s| TΔ: %s%.2f", sMessage, g_sChatStrings.sText, g_sChatStrings.sVariable, (time - g_fLastJumpTime[target]));
		}
	}

	if(g_bShavit) 
	{
		Shavit_StopChatSound();
		Shavit_PrintToChat(client, "%s", sMessage); // Thank you, GAMMACASE
	}
	else
	{
		PrintToChat(client, "%s%s%s%s", (gEV_Type == Engine_CSGO) ? " ":"", g_sChatStrings.sPrefix, g_sChatStrings.sText, sMessage);
		//no clue why but this space thing is important, if you remove it and use this on css all colors break lol
	}
}

public void Offset_DrawOffset(int client, int offset, bool overlap, bool nopress) 
{
	char msg[256];
	Format(msg, 256, "%d (%i)", offset, g_iRepeatedOffsets[client]);
	if(overlap)
	{
		Format(msg, 256, "%s Overlap", msg);
	}

	if(nopress)
	{
		Format(msg, 256, "%s No Press", msg);
	}

	int colorIdx = Offset_GetColorIdx(offset, overlap, nopress);
	int settingsIdx = g_iSettings[client][colorIdx];
	SetHudTextParams(g_fCacheHudPositions[client][Offset][X_DIM], g_fCacheHudPositions[client][Offset][Y_DIM], 0.5, g_iBstatColors[settingsIdx][0], g_iBstatColors[settingsIdx][1], g_iBstatColors[settingsIdx][2], 255, 0, 0.0, 0.0, 0.0);
	ShowHudText(client, GetDynamicChannel(2), msg); //OFFSET
}

void ShowJsMenu(int client)
{
	Menu menu = new Menu(Js_Select);
	SetMenuTitle(menu, "JumpStats - Nimmy\n \n");
	AddMenuItem(menu, "chat", "Chat");
	AddMenuItem(menu, "hud", "Hud");
	AddMenuItem(menu, "colors", "Colors");
	AddMenuItem(menu, "reset", "Reset Settings");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int Js_Select(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));
		
		if(StrEqual(info, "chat"))
		{
			ShowSSJMenu(client);
			return 0;
		}
		else if(StrEqual(info, "hud"))
		{
			ShowBHUDMenu(client);
			return 0;
		}
		else if(StrEqual(info, "colors"))
		{
			ShowColorsMenu(client);
			return 0;
		}
		else if(StrEqual(info, "reset"))
		{
			SetDefaults(client);
		}
		ShowJsMenu(client);
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void ShowSSJMenu(int client)
{
	Menu menu = new Menu(Ssj_Select);
	menu.ExitBackButton = true;
	SetMenuTitle(menu, "Chat Jump Stats \n \n");
	AddMenuItem(menu, "enSsj", (g_iSettings[client][Bools] & SSJ_ENABLED) ? "[x] Enabled":"[ ] Enabled");
	AddMenuItem(menu, "enRepeat", (g_iSettings[client][Bools] & SSJ_REPEAT) ? "[x] Repeat":"[ ] Repeat");
	
	char sMessage[256];
	Format(sMessage, sizeof(sMessage), "Usage: %i",g_iSettings[client][Usage]);
	AddMenuItem(menu, "enUsage", sMessage);
	
	AddMenuItem(menu, "enGain", (g_iSettings[client][Bools] & SSJ_GAIN) ? "[x] Gain":"[ ] Gain");
	AddMenuItem(menu, "enGainColor", (g_iSettings[client][Bools] & SSJ_GAIN_COLOR) ? "[x] Gain Colors":"[ ] Gain Color");
	AddMenuItem(menu, "enSync", (g_iSettings[client][Bools] & SSJ_SYNC) ? "[x] Sync":"[ ] Sync");
	AddMenuItem(menu, "enStrafes", (g_iSettings[client][Bools] & SSJ_STRAFES) ? "[x] Strafes":"[ ] Strafes");
	AddMenuItem(menu, "enEff", (g_iSettings[client][Bools] & SSJ_EFFICIENCY) ? "[x] Efficiency":"[ ] Efficiency");
	AddMenuItem(menu, "enHeight", (g_iSettings[client][Bools] & SSJ_HEIGHTDIFF) ? "[x] Height Difference":"[ ] Height Difference");
	AddMenuItem(menu, "enTime", (g_iSettings[client][Bools] & SSJ_SHAVIT_TIME) ? "[x] Time":"[ ] Time");
	AddMenuItem(menu, "enTimeDelta", (g_iSettings[client][Bools] & SSJ_SHAVIT_TIME_DELTA) ? "[x] Time Difference":"[ ] Time Difference");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int Ssj_Select(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));
		
		if(StrEqual(info, "enSsj"))
		{
			g_iSettings[client][Bools] ^= SSJ_ENABLED;
		}
		else if(StrEqual(info, "enRepeat"))
		{
			g_iSettings[client][Bools] ^= SSJ_REPEAT;
		}
		else if(StrEqual(info, "enUsage"))
		{
			g_iSettings[client][Usage]++; //cycle
			if(g_iSettings[client][Usage] > 16) {
				g_iSettings[client][Usage] = 1;
			}
			SetCookie(client, g_hSettings[Usage], g_iSettings[client][Usage]);
		}
		else if(StrEqual(info, "enGain"))
		{
			g_iSettings[client][Bools] ^= SSJ_GAIN;
		}
		else if(StrEqual(info, "enGainColor"))
		{
			g_iSettings[client][Bools] ^= SSJ_GAIN_COLOR;
		} 
		else if(StrEqual(info, "enSync"))
		{
			g_iSettings[client][Bools] ^= SSJ_SYNC;
		}
		else if(StrEqual(info, "enStrafes"))
		{
			g_iSettings[client][Bools] ^= SSJ_STRAFES;
		}
		else if(StrEqual(info, "enEff"))
		{
			g_iSettings[client][Bools] ^= SSJ_EFFICIENCY;
		}
		else if(StrEqual(info, "enHeight"))
		{
			g_iSettings[client][Bools] ^= SSJ_HEIGHTDIFF;
		}
		else if(StrEqual(info, "enTime"))
		{
			g_iSettings[client][Bools] ^= SSJ_SHAVIT_TIME;
		}
		else if(StrEqual(info, "enTimeDelta"))
		{
			g_iSettings[client][Bools] ^= SSJ_SHAVIT_TIME_DELTA;
		}
		SetCookie(client, g_hSettings[Bools], g_iSettings[client][Bools]);
		ShowSSJMenu(client);
	}
	else if(action == MenuAction_Cancel)
	{
		ShowJsMenu(client);
		return 0;
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void ShowBHUDMenu(int client)
{
	Menu menu = new Menu(BHUD_Select);
	menu.ExitBackButton = true;
	SetMenuTitle(menu, "HUD Jump Stats\n \n");
	AddMenuItem(menu, "enJhud", (g_iSettings[client][Bools] & JHUD_ENABLED) ? "[x] Jhud":"[ ] Jhud");
	AddMenuItem(menu, "enTrainer", (g_iSettings[client][Bools] & TRAINER_ENABLED) ? "[x] Trainer":"[ ] Trainer");
	AddMenuItem(menu, "enOffset", (g_iSettings[client][Bools] & OFFSETS_ENABLED) ? "[x] Offsets":"[ ] Offsets");
	AddMenuItem(menu, "enSpeed", (g_iSettings[client][Bools] & SPEEDOMETER_ENABLED) ? "[x] Speedometer":"[ ] Speedometer");
	AddMenuItem(menu, "jhudSettings", "JHUD Settings");
	AddMenuItem(menu, "speedSettings", "Speedometer Settings");
	AddMenuItem(menu, "posEditor", "Hud Positions Editor");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int BHUD_Select(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));
		
		if(StrEqual(info, "enJhud"))
		{
			g_iSettings[client][Bools] ^= JHUD_ENABLED;
		}
		else if(StrEqual(info, "enTrainer"))
		{
			g_iSettings[client][Bools] ^= TRAINER_ENABLED;
		}
		else if(StrEqual(info, "enOffset"))
		{
			g_iSettings[client][Bools] ^= OFFSETS_ENABLED;
		}
		else if(StrEqual(info, "enSpeed"))
		{
			g_iSettings[client][Bools] ^= SPEEDOMETER_ENABLED;
		}
		else if(StrEqual(info, "jhudSettings"))
		{
			ShowJhudSettingsMenu(client);
			return 0;
		} 
		else if(StrEqual(info, "speedSettings"))
		{
			ShowSpeedSettingsMenu(client);
			return 0;
		}
		else if(StrEqual(info, "posEditor"))
		{
			ShowPosEditMenu(client);
			return 0;
		}
		SetCookie(client, g_hSettings[Bools], g_iSettings[client][Bools]);
		ShowBHUDMenu(client);
	}
	else if(action == MenuAction_Cancel)
	{
		ShowJsMenu(client);
		return 0;
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void ShowColorsMenu(int client) 
{
	Menu menu = new Menu(Colors_Callback);
	menu.ExitBackButton = true;
	SetMenuTitle(menu, "Colors Settings");

	int editing = g_iEditGain[client];
	if(editing == GainReallyBad) 
	{
		AddMenuItem(menu, "editing", "< Very Bad >");
	} 
	else if (editing == GainBad) 
	{
		AddMenuItem(menu, "editing", "< Bad >");
	} 
	else if (editing == GainMeh) 
	{
		AddMenuItem(menu, "editing", "< Gain: Okay >");
	} 
	else if (editing == GainGood) 
	{
		AddMenuItem(menu, "editing", "< Gain: Good >");
	} 
	else if (editing == GainReallyGood)
	{
		AddMenuItem(menu, "editing", "< Very Good >");
	}

	AddMenuItem(menu, "editcolor", g_sBstatColorStrs[g_iSettings[client][editing]]);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int Colors_Callback(Menu menu, MenuAction action, int client, int option) 
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));
		
		if(StrEqual(info, "editing"))
		{
			g_iEditGain[client]++;
			if(g_iEditGain[client] > COLOR_SETTINGS_END_IDX)
			{
				g_iEditGain[client] = COLOR_SETTINGS_START_IDX;
			}

		}
		else if(StrEqual(info, "editcolor"))
		{
			int editing = g_iEditGain[client];
			g_iSettings[client][editing]++;
			if(g_iSettings[client][editing] > 8)
			{
				g_iSettings[client][editing] = 0;
			}

			SetCookie(client, g_hSettings[g_iEditGain[client]], g_iSettings[client][editing]);
		}
		ShowColorsMenu(client);
	}
	else if(action == MenuAction_Cancel)
	{
		ShowJsMenu(client);
		return 0;
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void ShowJhudSettingsMenu(int client) 
{
	Menu menu = new Menu(Jhud_SettingSelect);
	menu.ExitBackButton = true;
	SetMenuTitle(menu, "JHUD SETTINGS\n \n");
	AddMenuItem(menu, "strafespeed", (g_iSettings[client][Bools] & JHUD_JSS) ? "[x] Jss":"[ ] Jss");
	AddMenuItem(menu, "sync", (g_iSettings[client][Bools] & JHUD_SYNC) ? "[x] Sync":"[ ] Sync");
	AddMenuItem(menu, "extraspeeds", (g_iSettings[client][Bools] & JHUD_EXTRASPEED) ? "[x] Extra speeds":"[ ] Extra speeds");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void ShowSpeedSettingsMenu(int client) 
{
	Menu menu = new Menu(Speedometer_SettingSelect);
	menu.ExitBackButton = true;
	SetMenuTitle(menu, "SPEED SETTINGS\n \n");
	AddMenuItem(menu, "speedGainColor", (g_iSettings[client][Bools] & SPEEDOMETER_GAIN_COLOR) ? "[x] Gain Based Color":"[ ] Gain Based Color");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void ShowPosEditMenu(int client) 
{
	Menu menu = new Menu(Pos_Edit_Handler);
	menu.ExitBackButton = true;
	SetMenuTitle(menu, "POSITIONS \n \n");
	char sMessage[256];
	Format(sMessage, sizeof(sMessage), "Editing Hud: %s", g_sHudStrs[g_iEditHud[client]]);
	AddMenuItem(menu, "editingHud", sMessage);
	AddMenuItem(menu, "center", "Dead Center");
	AddMenuItem(menu, "editMode", "Enter Edit Mode");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int Pos_Edit_Handler(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));
		if(StrEqual(info, "editingHud"))
		{
			g_iEditHud[client]++;
			if(g_iEditHud[client] >= 4) 
			{
				g_iEditHud[client] = 0;
			}
		}
		else if(StrEqual(info, "center"))
		{
			Bstat_SetIntSubValue(g_iSettings[client][Positions_X], 0, g_iEditHud[client], POS_INT_BITS, POS_BINARY_MASK);
			Bstat_SetIntSubValue(g_iSettings[client][Positions_Y], 0, g_iEditHud[client], POS_INT_BITS, POS_BINARY_MASK);
			PushPosCache(client);
		}
		else if(StrEqual(info, "editMode")) 
		{
			g_bEditing[client] = !g_bEditing[client];
		}
		SetCookie(client, g_hSettings[Positions_X], g_iSettings[client][Positions_X]);
		SetCookie(client, g_hSettings[Positions_Y], g_iSettings[client][Positions_Y]);
		ShowPosEditMenu(client);
	}
	else if(action == MenuAction_Cancel)
	{
		g_bEditing[client] = false;
		ShowBHUDMenu(client);
		return 0;
	}
	else if(action == MenuAction_End)
	{
		g_bEditing[client] = false;
		delete menu;
	}
	return 0;
}

public int Jhud_SettingSelect(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));
		
		if(StrEqual(info, "strafespeed"))
		{
			g_iSettings[client][Bools] ^= JHUD_JSS;
		}
		else if(StrEqual(info, "extraspeeds"))
		{
			g_iSettings[client][Bools] ^= JHUD_EXTRASPEED;
		}
		else if(StrEqual(info, "sync"))
		{
			g_iSettings[client][Bools] ^= JHUD_SYNC;
		}
		SetCookie(client, g_hSettings[Bools], g_iSettings[client][Bools]);
		ShowJhudSettingsMenu(client);
	}
	else if(action == MenuAction_Cancel)
	{
		ShowBHUDMenu(client);
		return 0;
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int Speedometer_SettingSelect(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));
		
		if(StrEqual(info, "speedGainColor"))
		{
			g_iSettings[client][Bools] ^= SPEEDOMETER_GAIN_COLOR;
		}
		SetCookie(client, g_hSettings[Bools], g_iSettings[client][Bools]);
		ShowSpeedSettingsMenu(client);
	}
	else if(action == MenuAction_Cancel)
	{
		ShowBHUDMenu(client);
		return 0;
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void SetCookie(int client, Cookie hCookie, int n) 
{
	char strCookie[64];
	IntToString(n, strCookie, sizeof(strCookie));
	SetClientCookie(client, hCookie, strCookie);
}