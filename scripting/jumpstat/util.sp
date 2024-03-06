
static bool lateLoad;
bool g_bShavitCoreLoaded;
bool g_bShavitReplayLoaded;
bool g_bShavitZonesLoaded;

static char jumpstatsVersion[32];
static int tickrate;

static EngineVersion engineVersion;

enum struct jsChatStrings_t
{
	char sPrefix[64];
	char sText[16];
	char sWarning[16];
	char sVariable[16];
	char sVariable2[16];
	char sStyle[16];
}

jsChatStrings_t g_csChatStrings;

bool g_bEditing[MAXPLAYERS + 1]; //Setting to true enables "edit mode", menu.sp. defined in here to prevent scoping errors

//The spectator code and memory consumption below heavily reduces run time complexity by having a proper list of the players current specs, which is a lot shorter
//than looping 64 times for every player when they tick

int g_iSpecList[MAXPLAYERS + 1][MAXPLAYERS + 1]; //First dimension is client ind, second is the list of their current spectators
int g_iSpecListCurrentFrame[MAXPLAYERS + 1];
static int g_iCmdNum;

void Init_Utils(bool late, bool shavitCore, bool shavitReplays, bool shavitZones, EngineVersion engine, char[] version)
{
	lateLoad = late;
	g_bShavitCoreLoaded = shavitCore;
	g_bShavitReplayLoaded = shavitReplays;
	g_bShavitZonesLoaded = shavitZones;
	engineVersion = engine;
	tickrate = RoundToFloor(1 / GetTickInterval());


	Format(jumpstatsVersion, sizeof(jumpstatsVersion), "%s", version);
	if(shavitCore)
	{
		Shavit_OnChatConfigLoaded();
	}
}


//Updates an array storing all players current spectators every 50 ticks
Util_GameTick()
{
	g_iCmdNum++;

	if(g_iCmdNum % 50 != 0)
	{
		return;
	}

	g_iCmdNum = 0;

	for(int i = 0; i <= MaxClients; i++)
	{
		g_iSpecListCurrentFrame[i] = 0;
	}


	for(int i = 0; i <= MaxClients; i++)
	{
		if(!BgsIsValidPlayer(i) || !IsClientObserver(i))
		{
			continue;
		}

		int target = BgsGetHUDTarget(i, -1);

		if(target == -1)
		{
			continue;
		}

		//Player i, is a spectator, and has a target and correct spec state

		g_iSpecList[target][g_iSpecListCurrentFrame[target]] = i; //Place spectating players client index
		g_iSpecListCurrentFrame[target]++;
	}

}

stock bool BgsLateLoaded()
{
	return lateLoad;
}

stock void BgsVersion(char[] buffer, int len)
{
	Format(buffer, len, "%s", jumpstatsVersion);
}

stock int BgsTickRate()
{
	return tickrate;
}

stock EngineVersion BgsGetEngineVersion()
{
	return engineVersion;
}

public void Shavit_OnChatConfigLoaded()
{
	Shavit_GetChatStrings(sMessagePrefix, g_csChatStrings.sPrefix, sizeof(chatstrings_t::sPrefix));
	Shavit_GetChatStrings(sMessageText, g_csChatStrings.sText, sizeof(chatstrings_t::sText));
	Shavit_GetChatStrings(sMessageWarning, g_csChatStrings.sWarning, sizeof(chatstrings_t::sWarning));
	Shavit_GetChatStrings(sMessageVariable, g_csChatStrings.sVariable, sizeof(chatstrings_t::sVariable));
	Shavit_GetChatStrings(sMessageVariable2, g_csChatStrings.sVariable2, sizeof(chatstrings_t::sVariable2));
	Shavit_GetChatStrings(sMessageStyle, g_csChatStrings.sStyle, sizeof(chatstrings_t::sStyle));
}

stock int BgsGetHUDTarget(int client, int fallback = 0)
{
	int target = fallback;
	if(!IsClientObserver(client))
	{
		return target;
	}

	int iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
	if (iObserverMode >= 3 && iObserverMode <= 7)
	{
		int iTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		if (BgsIsValidClient(iTarget)) {
			target = iTarget;
		}
	}
	return target;
}


stock bool BgsIsValidClient(int client)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client));
}

stock bool BgsIsValidPlayer(int client)
{
	return BgsIsValidClient(client) && !IsFakeClient(client);
}


stock void BgsPrintToChat(int client, const char[] format, any...)
{
	char buffer[300];
	VFormat(buffer, sizeof(buffer), format, 3);

	if(g_bShavitCoreLoaded)
	{
		Shavit_PrintToChat(client, "%s[JumpStats]: %s%s", g_csChatStrings.sVariable, g_csChatStrings.sText, buffer)
	}
	else
	{
		PrintToChat(client, "%s%s[JumpStats]: %s%s", (BgsGetEngineVersion() == Engine_CSGO) ? " ":"", g_sBstatColorsHex[Cyan], g_sBstatColorsHex[White], buffer);
	}
}

stock void BgsSetCookie(int client, Cookie hCookie, int n)
{
	char strCookie[64];
	IntToString(n, strCookie, sizeof(strCookie));
	SetClientCookie(client, hCookie, strCookie);
}

stock int GetIntSubValue(int num, int position, int binaryShift, int binaryMask)
{
	if(num < 0)
	{
		num = ~num;
		num = num >> (position * binaryShift);
		num = ~num & binaryMask;
	}
	else
	{
	  	num = (num >> (position * binaryShift)) & binaryMask;
	}

	return num;
}

stock void SetIntSubValue(int &editNum, int insertVal, int position, int binaryShift, int binaryMask)
{
	editNum = (editNum & ~(binaryMask << (position * binaryShift))) | ((insertVal & binaryMask) << (position * binaryShift));
}

stock float GetAdjustedHudCoordinate(int value, float scaler)
{
	float rVal = -1.0;
	if(value <= 0 || value > RoundToFloor(scaler))
	{
		return rVal;
	}

	rVal = value / scaler;
	if(rVal <= 0.0 || rVal > 1.0)
	{
		return -1.0;
	}
	return rVal;
}

stock int GetHudCoordinateToInt(float value, int scaler, int min, int max)
{
	if(value < 0 || value > 1.0)
	{
		return 0;
	}

	int adjVal = RoundToFloor(value * scaler);
	if(adjVal > max)
	{
		adjVal = max;
	}
	if(adjVal < min)
	{
		adjVal = min;
	}
	return adjVal;
}

stock void BgsDisplayHud(int client, float pos[2], int rgb[3], float holdTime, int channel, bool force, const char[] message, any...)
{
	if(g_bEditing[client] && !force)
	{
		return;
	}

	char buffer[512];
	VFormat(buffer, sizeof(buffer), message, 8);
	SetHudTextParams(pos[0], pos[1], holdTime, rgb[0], rgb[1], rgb[2], 255, 0, 0.0, 0.0, 0.0);
	ShowHudText(client, channel, message);
}

stock float NormalizeAngle(float ang)
{
	while (ang > 180.0)
	{
		ang -= 360.0;
	}

	while (ang < -180.0)
	{
		ang += 360.0;
	}
	return ang;
}

stock float FloatMod(float num, float denom)
{
	return num - denom * RoundToFloor(num / denom);
}

stock float operator%(float oper1, float oper2)
{
	return FloatMod(oper1, oper2);
}
