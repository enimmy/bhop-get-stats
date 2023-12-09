#include <sourcemod>
#include <clientprefs>
#include <bhop-get-stats>
#include <DynamicChannels>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Jump Stats Hud", 
	author = "Nimmy",
	description = "Center of screen speed stats", 
	version = "1.0", 
	url = "https://github.com/Nimmy2222/bhop-get-stats"
}
enum
{
	Enabled,
	Jss,
	Sync,
	ExtraSpeed
}
enum
{
	Position,
	GainReallyBad,
	GainBad,
	GainMeh,
	GainGood,
	GainReallyGood
}

#define BoolCookies 4
#define IntCookies 6


Cookie g_hBoolCookies[BoolCookies]; //Enabled, JSS, Sync, ExtraSpeeds
Cookie g_hIntCookies[IntCookies]; //Pos, U60, 6070, 7080, 8090, A90

bool g_bBoolSettings[MAXPLAYERS + 1][4];
int g_iIntSettings[MAXPLAYERS + 1][6];

int g_iEditGain[MAXPLAYERS + 1] = {1, ...};

Handle g_hHudSync;

enum
{
	Red, //red {255, 0, 0},
	Orange, //orange {255, 165, 0},
	Yellow, //yellow {255, 255, 0},
	Green, //green {0, 255, 0}, 
	Cyan, //cyan {0, 255, 255}, 
	Blue, //blue {0, 0, 255}, 
	Purple, //purple {128, 0, 128}, 
	Pink, //pink {238, 0, 255},
	White //white {255, 255, 255},
};

char colorStrs[][] = {
	"Red",
	"Orange",
	"Yellow",
	"Green",
	"Cyan",
	"Blue",
	"Purple",
	"Pink",
	"White"
};

int colors[][3] = {
	{255, 0, 0},
	{255, 165, 0},
	{255, 255, 0},
	{0, 255, 0},
	{0, 255, 255},
	{0, 0, 255},
	{128, 0, 128},
	{238, 0, 255},
	{255, 255, 255}
};

int values[][3] = {
	{},  				// null
	{280, 282, 287},  	// 1
	{366, 370, 375},  	// 2
	{438, 442, 450},  	// 3
	{500, 505, 515},  	// 4
	{555, 560, 570},  	// 5
	{605, 610, 620},  	// 6
	{655, 665, 675},  	// 7
	{700, 710, 725}, 	// 8
	{740, 750, 765},  	// 9
	{780, 790, 805},  	// 10
	{810, 820, 840},  	// 11
	{850, 860, 875},  	// 12
	{880, 900, 900},  	// 13
	{910, 920, 935},  	// 14
	{945, 955, 965},  	// 15
	{970, 980, 1000} 	// 16
};

enum
{
	Center,
	Top,
	Bottom
};

float positions[3] = {
	-1.0,
	0.4,
	-0.4
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_hHudSync = CreateHudSynchronizer();
	if(g_hHudSync == INVALID_HANDLE) {
		Format(error, err_max, "bstat-jhud: failed to initalize hud syncronizer, your mod might not support it.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_jhud", Command_JHUD, "Opens the JHUD main menu");
	
	g_hBoolCookies[Enabled] = RegClientCookie("jhud_enabled", "jhud_enabled", CookieAccess_Protected);
	g_hBoolCookies[Jss] = RegClientCookie("jhud_strafespeed", "jhud_strafespeed", CookieAccess_Protected);
	g_hBoolCookies[ExtraSpeed] = RegClientCookie("jhud_extraspeeds", "jhud_extraspeeds", CookieAccess_Protected);
	g_hBoolCookies[Sync] = RegClientCookie("jhud_sync", "jhud_sync", CookieAccess_Protected);

	g_hIntCookies[Position] = RegClientCookie("jhud_position", "jhud_position", CookieAccess_Protected);
	g_hIntCookies[GainReallyBad] = RegClientCookie("jhud_rlybadgain", "jhud_rlybadgain", CookieAccess_Protected);
	g_hIntCookies[GainBad] = RegClientCookie("jhud_badgain", "jhud_badgain", CookieAccess_Protected);
	g_hIntCookies[GainMeh] = RegClientCookie("jhud_mehgain", "jhud_mehgain", CookieAccess_Protected);
	g_hIntCookies[GainGood] = RegClientCookie("jhud_goodgain", "jhud_goodgain", CookieAccess_Protected);
	g_hIntCookies[GainReallyGood] = RegClientCookie("jhud_rlygoodgain", "jhud_rlygoodgain", CookieAccess_Protected);

	
	for(int i = 1; i <= MaxClients; i++)
	{
		if(AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
}

public void OnClientCookiesCached(int client)
{
	char strCookie[8];
	for(int i = 0; i < BoolCookies; i++) {
		GetClientCookie(client, g_hBoolCookies[i], strCookie, sizeof(strCookie));
		if(strCookie[0] == '\0') {
			SetDefaults(client);
			return;
		}
		g_bBoolSettings[client][i] = view_as<bool>(StringToInt(strCookie));
	}

	for(int i = 0; i < IntCookies; i++) {
		GetClientCookie(client, g_hIntCookies[i], strCookie, sizeof(strCookie));
		if(strCookie[0] == '\0') {
			SetDefaults(client);
			return;
		}
		g_iIntSettings[client][i] = StringToInt(strCookie);
	}

	if(g_iIntSettings[client][Position] > 2 || g_iIntSettings[client][Position] < 0) {
		SetDefaults(client);
		return;
	}
	for(int i = 1; i < IntCookies; i++) {
		if(g_iIntSettings[client][i] > 8 || g_iIntSettings[client][i] < 0) {
			SetDefaults(client);
			return;
		}
	}
}

void SetDefaults(int client) {
	SetCookie(client, g_hBoolCookies[Enabled], true);
	SetCookie(client, g_hBoolCookies[Jss], true);
	SetCookie(client, g_hBoolCookies[Sync], true);
	SetCookie(client, g_hBoolCookies[ExtraSpeed], false);

	SetCookie(client, g_hIntCookies[Position], 0);
	SetCookie(client, g_hIntCookies[GainReallyBad], Red);
	SetCookie(client, g_hIntCookies[GainBad], Orange);
	SetCookie(client, g_hIntCookies[GainMeh], Green);
	SetCookie(client, g_hIntCookies[GainGood], Cyan);
	SetCookie(client, g_hIntCookies[GainReallyGood], White);

	g_bBoolSettings[client][Enabled] = true;
	g_bBoolSettings[client][Jss] = true;
	g_bBoolSettings[client][Sync] = true;
	g_bBoolSettings[client][ExtraSpeed] = false;

	g_iIntSettings[client][Position] = 0;
	g_iIntSettings[client][GainReallyBad] = Red;
	g_iIntSettings[client][GainBad] = Orange;
	g_iIntSettings[client][GainMeh] = Green;
	g_iIntSettings[client][GainGood] = Cyan;
	g_iIntSettings[client][GainReallyGood] = White;
}

public void BhopStat_JumpForward(int client, int jump, int speed, int strafecount, float heightdelta, float gain, float sync, float eff, float yawwing, float jss)
{

	for(int i = 1; i < MaxClients; i++)
	{
		if(!g_bBoolSettings[i][Enabled] || !IsValidClient(i)) {
			continue;
		}
		if((i == client) || (!IsPlayerAlive(i) && GetEntPropEnt(i, Prop_Data, "m_hObserverTarget") == client && GetEntProp(i, Prop_Data, "m_iObserverMode") != 7))
		{
			JHUD_DrawStats(i, jump, speed, gain, sync, jss);
		}
	}
}

void JHUD_DrawStats(int client, int jump, int speed, float gain, float sync, float jss)
{
	int rgb[3];
	jss = jss * 100;
	
	char sMessage[256];

	if((jump <= 6 || jump == 16) || (g_bBoolSettings[client][ExtraSpeed] && jump <= 16))
	{
		if(speed < values[jump][0]) //bad
		{
			rgb = colors[g_iIntSettings[client][GainReallyBad]];
		}
		else if(speed >= values[jump][0] && speed < values[jump][1]) //meh
		{
			rgb = colors[g_iIntSettings[client][GainBad]];
		}
		else if(speed >= values[jump][1] && speed < values[jump][2]) //ok
		{
			rgb = colors[g_iIntSettings[client][GainMeh]];
		}
		else //good
		{
			rgb = colors[g_iIntSettings[client][GainGood]];
		}
	}
	else
	{
		if(gain < 60)
		{
			rgb = colors[g_iIntSettings[client][GainReallyBad]];
		}
		else if(gain >= 60 && gain < 70)
		{
			rgb = colors[g_iIntSettings[client][GainBad]];
		}
		else if(gain >= 70 && gain < 80)
		{
			rgb = colors[g_iIntSettings[client][GainMeh]];
		}
		else if (gain >= 80 && gain < 90)
		{
			rgb = colors[g_iIntSettings[client][GainGood]];
		}
		else
		{
			rgb = colors[g_iIntSettings[client][GainReallyGood]];
		}
	}

	Format(sMessage, sizeof(sMessage), "%i: %i", jump, speed);
	if(jump > 1) {
		if(g_bBoolSettings[client][Jss])
		{
			Format(sMessage, sizeof(sMessage), "%s (%.0f%%%%)", sMessage, jss);
		}
		Format(sMessage, sizeof(sMessage), "%s\n%.2f%%", sMessage, gain);
		if(g_bBoolSettings[client][Sync]) {
			Format(sMessage, sizeof(sMessage), "%s %.2f%%", sMessage, sync);
		}
	}
	
	SetHudTextParams(-1.0, positions[g_iIntSettings[client][Position]], 1.0, rgb[0], rgb[1], rgb[2], 255, 0, 0.0, 0.0);
	//ShowSyncHudText(client, g_hHudSync, sMessage);
	ShowHudText(client, GetDynamicChannel(0), sMessage);
}

public Action Command_JHUD(int client, any args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	ShowJHUDMenu(client);
	return Plugin_Handled;
}

void ShowJHUDMenu(int client)
{
	Menu menu = CreateMenu(JHUD_Select);
	SetMenuTitle(menu, "JHUD - Nimmy\n \n");
	AddMenuItem(menu, "usage", (g_bBoolSettings[client][Enabled]) ? "[x] Jhud":"[ ] Jhud");
	AddMenuItem(menu, "strafespeed", (g_bBoolSettings[client][Jss]) ? "[x] Jss":"[ ] Jss");
	AddMenuItem(menu, "sync", (g_bBoolSettings[client][Sync]) ? "[x] Sync":"[ ] Sync");
	AddMenuItem(menu, "extraspeeds", (g_bBoolSettings[client][ExtraSpeed]) ? "[x] Extra speeds":"[ ] Extra speeds");

	if(g_iIntSettings[client][Position] == 0)
	{
		AddMenuItem(menu, "cyclepos", "Position: [CENTER]");
	}
	else if(g_iIntSettings[client][Position] == 1)
	{
		AddMenuItem(menu, "cyclepos", "Position: [TOP]");
	}
	else if(g_iIntSettings[client][Position] == 2)
	{
		AddMenuItem(menu, "cyclepos", "Position: [BOTTOM]");
	}
	AddMenuItem(menu, "editcolors", "Edit Color Settings");
	AddMenuItem(menu, "reset", "Reset Settings");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int JHUD_Select(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, option, info, sizeof(info));
		
		if(StrEqual(info, "usage"))
		{
			g_bBoolSettings[client][Enabled] = !g_bBoolSettings[client][Enabled];
			SetCookie(client, g_hBoolCookies[Enabled], g_bBoolSettings[client][Enabled]);
		}
		else if(StrEqual(info, "strafespeed"))
		{
			g_bBoolSettings[client][Jss] = !g_bBoolSettings[client][Jss];
			SetCookie(client, g_hBoolCookies[client][Jss], g_bBoolSettings[client][Jss]);
		}
		else if(StrEqual(info, "cyclepos"))
		{
			if(++g_iIntSettings[client][Position] < 3)
			{
				SetCookie(client, g_hIntCookies[Position], g_iIntSettings[client][Position]);
			}
			else
			{
				g_iIntSettings[client][Position] = 0;
				SetCookie(client, g_hIntCookies[Position], g_iIntSettings[client][Position]);
			}
		}
		else if(StrEqual(info, "extraspeeds"))
		{
			g_bBoolSettings[client][ExtraSpeed] = !g_bBoolSettings[client][ExtraSpeed];
			SetCookie(client, g_hBoolCookies[ExtraSpeed], g_bBoolSettings[client][ExtraSpeed]);
		}
		else if(StrEqual(info, "sync"))
		{
			g_bBoolSettings[client][Sync] = !g_bBoolSettings[client][Sync];
			SetCookie(client, g_hBoolCookies[Sync], g_bBoolSettings[client][Sync]);
		}
		else if(StrEqual(info, "editcolors"))
		{
			ShowColorOptionsMenu(client);
			return 0;
		} else if(StrEqual(info, "reset"))
		{
			SetDefaults(client);
		}
		ShowJHUDMenu(client);
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

//store int for gain editing, store int for last color selected
void ShowColorOptionsMenu(int client) {
	Menu menu = CreateMenu(Colors_Callback);
	SetMenuTitle(menu, "Colors");

	int editing = g_iEditGain[client];
	if(editing == GainReallyBad) {
		AddMenuItem(menu, "editing", "< Gain: 60- >");
	} else if (editing == GainBad) {
		AddMenuItem(menu, "editing", "< Gain: 60 - 69 >");
	} else if (editing == GainMeh) {
		AddMenuItem(menu, "editing", "< Gain: 70 - 79 >");
	} else if (editing == GainGood) {
		AddMenuItem(menu, "editing", "< Gain: 80 - 89 >");
	} else if (editing == GainReallyGood) {
		AddMenuItem(menu, "editing", "< 90+ >");
	}

	AddMenuItem(menu, "editcolor", colorStrs[g_iIntSettings[client][editing]]);
	AddMenuItem(menu, "back", "Back");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int Colors_Callback(Menu menu, MenuAction action, int client, int option) {
	if(action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, option, info, sizeof(info));
		
		if(StrEqual(info, "editing"))
		{
			g_iEditGain[client]++;
			if(g_iEditGain[client] > 5) {
				g_iEditGain[client] = 1;
			}

		}
		else if(StrEqual(info, "editcolor"))
		{
			int editing = g_iEditGain[client];
			g_iIntSettings[client][editing]++;
			if(g_iIntSettings[client][editing] > 8) {
				g_iIntSettings[client][editing] = 0;
			}
			SetCookie(client, g_hIntCookies[g_iEditGain[client]], g_iIntSettings[client][editing]);
			PrintToChat(client, "Setting %i to %i", g_iEditGain[client], g_iIntSettings[client][editing]);
		} else if(StrEqual(info, "back"))
		{
			ShowJHUDMenu(client);
			return 0;
		}
		ShowColorOptionsMenu(client);
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

bool IsValidClient(int client, bool bAlive = false)
{
	return (client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && (!bAlive || IsPlayerAlive(client)));
}