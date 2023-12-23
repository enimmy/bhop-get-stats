
//#define DEBUG
static bool lateLoad;
static bool shavitLoaded;
static EngineVersion engineVersion;
chatstrings_t g_csChatStrings;

void Init_Utils(bool late, bool shavit, EngineVersion engine)
{
	lateLoad = late;
	shavitLoaded = shavit;
	engineVersion = engine;
	if(shavitLoaded)
	{
		Shavit_OnChatConfigLoaded();
	}
}

bool BgsLateLoaded()
{
	return lateLoad;
}

bool BgsShavitLoaded()
{
	return shavitLoaded;
}

EngineVersion BgsGetEngineVersion()
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

int BgsGetHUDTarget(int client, int fallback = 0)
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

bool BgsIsValidClient(int client, bool bAlive = false)
{
	return (client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && (!bAlive || IsPlayerAlive(client)));
}

void BgsSetCookie(int client, Cookie hCookie, int n)
{
	char strCookie[64];
	IntToString(n, strCookie, sizeof(strCookie));
	SetClientCookie(client, hCookie, strCookie);
	PrintDebugMsg(client, "Attempting to set cookie to %i", n);
}

int GetIntSubValue(int num, int position, int binaryShift, int binaryMask)
{
	return (num >> position * binaryShift) & binaryMask;
}

void SetIntSubValue(int &editNum, int insertVal, int position, int binaryShift, int binaryMask)
{
	editNum = (editNum & ~(binaryMask << (position * binaryShift))) | ((insertVal & binaryMask) << (position * binaryShift));
}

float GetAdjustedHudCoordinate(int value, float scaler)
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

int HudCoordinateToInt(float value, int scaler, int min, int max)
{
	if(value != -1.0 || value < 0 || value > 1.0)
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

void PrintDebugMsg(int client, const char[] msg, any...)
{
	#if defined DEBUG
	char buffer[300];
	VFormat(buffer, sizeof(buffer), msg, 3);
	PrintToConsole(client, "jumpstats: %s", buffer);
	#endif
}
