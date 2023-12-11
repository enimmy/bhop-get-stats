#include <clientprefs>
#include <shavit>
#include <bhop-get-stats>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "Shavit SSJ",
	author = "Nimmy / AlkATraZ / Nairda / xWidow",
	description = "Strafe gains/efficiency etc.",
	version = SHAVIT_VERSION,
	url = "https://github.com/Nimmy2222/bhop-get-stats"
}

#define BHOP_FRAMES 10

Cookie g_hCookieEnabled = null;
Cookie g_hCookieUsageMode = null;
Cookie g_hCookieUsageRepeat = null;
Cookie g_hCookieCurrentSpeed = null;
Cookie g_hCookieFirstJump = null;
Cookie g_hCookieHeightDiff = null;
Cookie g_hCookieGainStats = null;
Cookie g_hCookieGainColors = null;
Cookie g_hCookieEfficiency = null;
Cookie g_hCookieTime = null;
Cookie g_hCookieDeltaTime = null;
Cookie g_hCookieStrafeCount = null;
Cookie g_hCookieStrafeSync = null;
Cookie g_hCookieDefaultsSet = null;

bool g_bUsageRepeat[MAXPLAYERS + 1];
bool g_bEnabled[MAXPLAYERS + 1] =  { true, ... };
bool g_bCurrentSpeed[MAXPLAYERS + 1] =  { true, ... };
bool g_bFirstJump[MAXPLAYERS + 1] =  { true, ... };
bool g_bHeightDiff[MAXPLAYERS + 1];
bool g_bGainStats[MAXPLAYERS + 1] =  { true, ... };
bool g_bGainColors[MAXPLAYERS + 1] = { true, ... };
bool g_bEfficiency[MAXPLAYERS + 1];
bool g_bTime[MAXPLAYERS + 1];
bool g_bDeltaTime[MAXPLAYERS + 1];
bool g_bStrafeSync[MAXPLAYERS + 1];
bool g_bStrafeCount[MAXPLAYERS + 1];

int g_iUsageMode[MAXPLAYERS + 1];

char g_sGainColors[5][12];

float g_fLastJumpTime[MAXPLAYERS + 1];

// misc settings
bool g_bLate = false;
bool g_bShavit = false;

EngineVersion gEV_Type = Engine_Unknown;
chatstrings_t gS_ChatStrings;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLate = late;

	return APLRes_Success;
}

public void OnPluginStart()
{
	g_sGainColors[0] = "\x07f51302"; //(gain / 10 ) - 5 -> bound check 0 <= x <= 4
	g_sGainColors[1] ="\x07fae71b";
	g_sGainColors[2] ="\x0707fa14";
	g_sGainColors[3] ="\x0707c9fa";
	g_sGainColors[4] ="\x07ffffff";

	RegConsoleCmd("sm_ssj", Command_SSJ, "Open the Speed @ Sixth Jump menu.");

	g_hCookieEnabled = RegClientCookie("ssj_enabled", "ssj_enabled", CookieAccess_Public);
	g_hCookieUsageMode = RegClientCookie("ssj_displaymode", "ssj_displaymode", CookieAccess_Public);
	g_hCookieUsageRepeat = RegClientCookie("ssj_displayrepeat", "ssj_displayrepeat", CookieAccess_Public);
	g_hCookieCurrentSpeed = RegClientCookie("ssj_currentspeed", "ssj_currentspeed", CookieAccess_Public);
	g_hCookieFirstJump = RegClientCookie("ssj_firstjump", "ssj_firstjump", CookieAccess_Public);
	g_hCookieHeightDiff = RegClientCookie("ssj_heightdiff", "ssj_heightdiff", CookieAccess_Public);
	g_hCookieGainStats = RegClientCookie("ssj_gainstats", "ssj_gainstats", CookieAccess_Public);
	g_hCookieGainColors = RegClientCookie("ssj_gaincolors", "ssj_gaincolors", CookieAccess_Public);
	g_hCookieEfficiency = RegClientCookie("ssj_efficiency", "ssj_efficiency", CookieAccess_Public);
	g_hCookieTime = RegClientCookie("ssj_time", "ssj_time", CookieAccess_Public);
	g_hCookieDeltaTime = RegClientCookie("ssj_deltatime", "ssj_deltatime", CookieAccess_Public);
	g_hCookieStrafeCount = RegClientCookie("ssj_strafecount", "ssj_strafecount", CookieAccess_Public);
	g_hCookieStrafeSync = RegClientCookie("ssj_strafesync", "ssj_strafesync", CookieAccess_Public);
	g_hCookieDefaultsSet = RegClientCookie("ssj_defaults", "ssj_defaults", CookieAccess_Public);

	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientCookiesCached(i);
		}
	}

	if(g_bLate)
	{
		Shavit_OnChatConfigLoaded();
	}

	g_bShavit = LibraryExists("shavit");
	gEV_Type = GetEngineVersion();
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "shavit"))
	{
		g_bShavit = true;
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
	Shavit_GetChatStrings(sMessagePrefix, gS_ChatStrings.sPrefix, sizeof(chatstrings_t::sPrefix));
	Shavit_GetChatStrings(sMessageText, gS_ChatStrings.sText, sizeof(chatstrings_t::sText));
	Shavit_GetChatStrings(sMessageWarning, gS_ChatStrings.sWarning, sizeof(chatstrings_t::sWarning));
	Shavit_GetChatStrings(sMessageVariable, gS_ChatStrings.sVariable, sizeof(chatstrings_t::sVariable));
	Shavit_GetChatStrings(sMessageVariable2, gS_ChatStrings.sVariable2, sizeof(chatstrings_t::sVariable2));
	Shavit_GetChatStrings(sMessageStyle, gS_ChatStrings.sStyle, sizeof(chatstrings_t::sStyle));
}

public void OnClientCookiesCached(int client)
{
	char sCookie[8];

	GetClientCookie(client, g_hCookieDefaultsSet, sCookie, 8);

	if(StringToInt(sCookie) == 0)
	{
		SetCookie(client, g_hCookieEnabled, true);
		SetCookie(client, g_hCookieUsageMode, 6);
		SetCookie(client, g_hCookieUsageRepeat, false);
		SetCookie(client, g_hCookieCurrentSpeed, true);
		SetCookie(client, g_hCookieFirstJump, true);
		SetCookie(client, g_hCookieHeightDiff, false);
		SetCookie(client, g_hCookieGainStats, true);
		SetCookie(client, g_hCookieGainColors, true);
		SetCookie(client, g_hCookieEfficiency, false);
		SetCookie(client, g_hCookieTime, false);
		SetCookie(client, g_hCookieDeltaTime, false);
		SetCookie(client, g_hCookieStrafeCount, false);
		SetCookie(client, g_hCookieStrafeSync, false);
		SetCookie(client, g_hCookieDefaultsSet, true);
	}

	GetClientCookie(client, g_hCookieEnabled, sCookie, 8);
	g_bEnabled[client] = view_as<bool>(StringToInt(sCookie));

	GetClientCookie(client, g_hCookieUsageMode, sCookie, 8);
	g_iUsageMode[client] = StringToInt(sCookie);

	GetClientCookie(client, g_hCookieUsageRepeat, sCookie, 8);
	g_bUsageRepeat[client] = view_as<bool>(StringToInt(sCookie));

	GetClientCookie(client, g_hCookieCurrentSpeed, sCookie, 8);
	g_bCurrentSpeed[client] = view_as<bool>(StringToInt(sCookie));

	GetClientCookie(client, g_hCookieFirstJump, sCookie, 8);
	g_bFirstJump[client] = view_as<bool>(StringToInt(sCookie));

	GetClientCookie(client, g_hCookieHeightDiff, sCookie, 8);
	g_bHeightDiff[client] = view_as<bool>(StringToInt(sCookie));

	GetClientCookie(client, g_hCookieGainStats, sCookie, 8);
	g_bGainStats[client] = view_as<bool>(StringToInt(sCookie));

	GetClientCookie(client, g_hCookieGainColors, sCookie, 8);
	g_bGainColors[client] = view_as<bool>(StringToInt(sCookie));

	GetClientCookie(client, g_hCookieEfficiency, sCookie, 8);
	g_bEfficiency[client] = view_as<bool>(StringToInt(sCookie));

	GetClientCookie(client, g_hCookieTime, sCookie, 8);
	g_bTime[client] = view_as<bool>(StringToInt(sCookie));

	GetClientCookie(client, g_hCookieDeltaTime, sCookie, 8);
	g_bDeltaTime[client] = view_as<bool>(StringToInt(sCookie));

	GetClientCookie(client, g_hCookieStrafeCount, sCookie, 8);
	g_bStrafeCount[client] = view_as<bool>(StringToInt(sCookie));

	GetClientCookie(client, g_hCookieStrafeSync, sCookie, 8);
	g_bStrafeSync[client] = view_as<bool>(StringToInt(sCookie));
}

int GetHUDTarget(int client)
{
	int target = client;

	if(IsValidClient(client))
	{
		int iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");

		if(iObserverMode >= 3 && iObserverMode <= 5)
		{
			int iTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");

			if(IsValidClient(iTarget))
			{
				target = iTarget;
			}
		}
	}

	return target;
}

public Action Command_SSJ(int client, int args)
{
	if(client == 0)
	{
		ReplyToCommand(client, "[SM] This command can only be used in-game.");

		return Plugin_Handled;
	}

	return ShowSSJMenu(client);
}

Action ShowSSJMenu(int client, int item = 0)
{
	Menu menu = new Menu(SSJ_MenuHandler);
	menu.SetTitle("Speed @ Sixth Jump\n ");

	menu.AddItem("usage", (g_bEnabled[client]) ? "[x] Enabled":"[ ] Enabled");

	char sMenu[64];
	FormatEx(sMenu, 64, "[%d] Jump", g_iUsageMode[client]);

	menu.AddItem("mode", sMenu);
	menu.AddItem("repeat", (g_bUsageRepeat[client]) ? "[x] Repeat":"[ ] Repeat");
	menu.AddItem("curspeed", (g_bCurrentSpeed[client]) ? "[x] Current speed":"[ ] Current speed");
	menu.AddItem("firstjump", (g_bFirstJump[client]) ? "[x] First jump":"[ ] First jump");
	menu.AddItem("height", (g_bHeightDiff[client]) ? "[x] Height difference":"[ ] Height difference");
	menu.AddItem("gain", (g_bGainStats[client]) ? "[x] Gain percentage":"[ ] Gain percentage");
	menu.AddItem("gaincolors", (g_bGainColors[client]) ? "[x] Gain colors":"[ ] Gain colors");
	menu.AddItem("efficiency", (g_bEfficiency[client]) ? "[x] Strafe efficiency":"[ ] Strafe efficiency");
	menu.AddItem("time", (g_bTime[client]) ? "[x] Time counter":"[ ] Time counter");
	menu.AddItem("deltatime", (g_bDeltaTime[client]) ? "[x] Time delta":"[ ] Time delta");
	menu.AddItem("strafe", (g_bStrafeCount[client]) ? "[x] Strafe":"[ ] Strafe");
	menu.AddItem("sync", (g_bStrafeSync[client]) ? "[x] Synchronization":"[ ] Synchronization");

	menu.ExitButton = true;
	menu.DisplayAt(client, item, 0);

	return Plugin_Handled;
}

public int SSJ_MenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		switch (param2)
		{
			case 0:
			{
				g_bEnabled[param1] = !g_bEnabled[param1];
				SetCookie(param1, g_hCookieEnabled, g_bEnabled[param1]);
			}

			case 1:
			{
				g_iUsageMode[param1] = (g_iUsageMode[param1] % 9) + 1;
				SetCookie(param1, g_hCookieUsageMode, g_iUsageMode[param1]);
			}

			case 2:
			{
				g_bUsageRepeat[param1] = !g_bUsageRepeat[param1];
				SetCookie(param1, g_hCookieUsageRepeat, g_bUsageRepeat[param1]);
			}

			case 3:
			{
				g_bCurrentSpeed[param1] = !g_bCurrentSpeed[param1];
				SetCookie(param1, g_hCookieCurrentSpeed, g_bCurrentSpeed[param1]);
			}

			case 4:
			{
				g_bFirstJump[param1] = !g_bFirstJump[param1];
				SetCookie(param1, g_hCookieFirstJump, g_bFirstJump[param1]);
			}

			case 5:
			{
				g_bHeightDiff[param1] = !g_bHeightDiff[param1];
				SetCookie(param1, g_hCookieHeightDiff, g_bHeightDiff[param1]);
			}

			case 6:
			{
				g_bGainStats[param1] = !g_bGainStats[param1];
				SetCookie(param1, g_hCookieGainStats, g_bGainStats[param1]);
			}

			case 7:
			{
				g_bGainColors[param1] = !g_bGainColors[param1];
				SetCookie(param1, g_hCookieGainColors, g_bGainColors[param1]);
			}

			case 8:
			{
				g_bEfficiency[param1] = !g_bEfficiency[param1];
				SetCookie(param1, g_hCookieEfficiency, g_bEfficiency[param1]);
			}

			case 9:
			{
				g_bTime[param1] = !g_bTime[param1];
				SetCookie(param1, g_hCookieTime, g_bTime[param1]);
			}

			case 10:
			{
				g_bDeltaTime[param1] = !g_bDeltaTime[param1];
				SetCookie(param1, g_hCookieDeltaTime, g_bDeltaTime[param1]);
			}

			case 11:
			{
				g_bStrafeCount[param1] = !g_bStrafeCount[param1];
				SetCookie(param1, g_hCookieStrafeCount, g_bStrafeCount[param1]);
			}

			case 12:
			{
				g_bStrafeSync[param1] = !g_bStrafeSync[param1];
				SetCookie(param1, g_hCookieStrafeSync, g_bStrafeSync[param1]);
			}

		}

		ShowSSJMenu(param1, GetMenuSelectionPosition());
	}

	else if(action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

//bool SSJ_PrintStats(int client, int target)
public void BhopStat_JumpForward(int client, int jump, int speed, int strafecount, float heightdelta, float gain, float sync, float eff, float yawwing, float jss)
{
	float time = Shavit_GetClientTime(client);
	for (int i = 1; i <= MaxClients; i++)
	{
		if(!g_bEnabled[i] || !IsValidClient(i) || GetHUDTarget(i) != client)
		{
			continue;
		}
		PrepareMessage(i, client, jump, speed, strafecount, heightdelta, gain, sync, eff);
	}
	g_fLastJumpTime[client] = time;
	return;
}

void PrepareMessage(int client, int target, int jump, int speed, int strafecount, float heightdelta, float gain, float sync, float eff)
{
	if(jump == 1)
	{
		if(!g_bFirstJump[client] && g_iUsageMode[client] != 1)
		{
			return;
		}
	}

	else if(g_bUsageRepeat[client])
	{
		if(jump % g_iUsageMode[client] != 0)
		{
			return;
		}
	}

	else if(jump != g_iUsageMode[client])
	{
		return;
	}

	char sMessage[300];
	FormatEx(sMessage, sizeof(sMessage), "J: %s%i", gS_ChatStrings.sVariable, jump);

	if(g_bCurrentSpeed[client])
	{
		Format(sMessage, sizeof(sMessage), "%s %s| S: %s%i", sMessage, gS_ChatStrings.sText, gS_ChatStrings.sVariable, speed);
	}

	if(jump > 1)
	{
		float time = Shavit_GetClientTime(client);
		if(g_bGainStats[client])
		{
			if(g_bGainColors[client]) {
				int idx = ColorBoundsCheck(RoundToFloor((gain / 10) - 5));
				Format(sMessage, sizeof(sMessage), "%s %s| G: %s%.1f%%", sMessage, gS_ChatStrings.sText, g_sGainColors[idx], gain);
			} else {
				Format(sMessage, sizeof(sMessage), "%s %s| G: %s%.1f%%", sMessage, gS_ChatStrings.sText, gS_ChatStrings.sVariable, gain);
			}
		}

		if(g_bStrafeSync[client])
		{
			Format(sMessage, sizeof(sMessage), "%s %s| S: %s%.1f%%", sMessage, gS_ChatStrings.sText, gS_ChatStrings.sVariable, sync);
		}

		if(g_bEfficiency[client])
		{
			Format(sMessage, sizeof(sMessage), "%s %s| Ef: %s%.1f%%", sMessage, gS_ChatStrings.sText, gS_ChatStrings.sVariable, eff);
		}

		if(g_bHeightDiff[client])
		{
			Format(sMessage, sizeof(sMessage), "%s %s| HΔ: %s%.1f", sMessage, gS_ChatStrings.sText, gS_ChatStrings.sVariable, heightdelta);
		}

		if(g_bStrafeCount[client])
		{
			Format(sMessage, sizeof(sMessage), "%s %s| Stf: %s%i", sMessage, gS_ChatStrings.sText, gS_ChatStrings.sVariable, strafecount);
		}

		if(g_bTime[client])
		{
			Format(sMessage, sizeof(sMessage), "%s %s| T: %s%.2f", sMessage, gS_ChatStrings.sText, gS_ChatStrings.sVariable, time);
		}
		if(g_bDeltaTime[client])
		{
			Format(sMessage, sizeof(sMessage), "%s %s| TΔ: %s%.2f", sMessage, gS_ChatStrings.sText, gS_ChatStrings.sVariable, (time - g_fLastJumpTime[target]));
		}
	}
	PrintToClient(client, "%s", sMessage);
}

void PrintToClient(int client, const char[] message, any...)
{
	char buffer[300];
	VFormat(buffer, sizeof(buffer), message, 3);

	if(g_bShavit)
	{
		Shavit_StopChatSound();
		Shavit_PrintToChat(client, "%s", buffer); // Thank you, GAMMACASE
	}

	else
	{
		PrintToChat(client, "%s%s%s%s", (gEV_Type == Engine_CSGO) ? " ":"", gS_ChatStrings.sPrefix, gS_ChatStrings.sText, buffer);
		//no clue why but this space thing is important, if you remove it and use this on css all colors break lol
	}
}

void SetCookie(int client, Handle hCookie, int n)
{
	char sCookie[8];
	IntToString(n, sCookie, 8);

	SetClientCookie(client, hCookie, sCookie);
}

int ColorBoundsCheck(int idx) {
	if(idx < 0) {
		idx = 0;
	}
	if(idx > 4) {
		idx = 4;
	}
	return idx;
}