#include <sourcemod>
#include <clientprefs>
#include <bhop-get-stats>
#include <DynamicChannels>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name = "Bhop Huds", 
	author = "Nimmy",
	description = "all kinds of stuff", 
	version = "1.0", 
	url = "https://github.com/Nimmy2222/bhop-get-stats"
}

//jhud
Cookie g_hSettings[JHUD_SETTINGS_NUMBER];
int g_iSettings[MAXPLAYERS + 1][JHUD_SETTINGS_NUMBER];
int g_iEditGain[MAXPLAYERS + 1] = {2, ...};

//trainer
float g_fPercents[MAXPLAYERS + 1];
float g_fLastAverage[MAXPLAYERS + 1];
int g_iCmdNum[MAXPLAYERS + 1];
int g_iGroundTicks[MAXPLAYERS + 1];

//offsets
int g_iLastOffset[MAXPLAYERS + 1];
int g_iRepeatedOffsets[MAXPLAYERS + 1];

//vars
ConVar g_hOverrideJhud;
ConVar g_hOverrideTrainer;

public void OnPluginStart() {
	RegConsoleCmd("sm_bhud", Command_JHUD, "Opens the bhud main menu");
	RegConsoleCmd("sm_offsets", Command_JHUD, "Opens the bhud main menu");
	RegConsoleCmd("sm_offset", Command_JHUD, "Opens the bhud main menu");
	
	RegConsoleCmd("sm_strafetrainer", Command_CheckTrainerOverride, "Opens the bhud main menu");
	RegConsoleCmd("sm_trainer", Command_CheckTrainerOverride, "Opens the bhud main menu");
	RegConsoleCmd("sm_jhud", Command_CheckJhudOverride, "Opens the bhud main menu");

	g_hOverrideJhud = CreateConVar("bstat-master-override-jhud", "1", "Override /jhud command? 0 (false) or 1 (true)");
	g_hOverrideTrainer = CreateConVar("bstat-master-override-trainer", "1", "Override /strafetrainer command? 0 (false) or 1 (true)");

	g_hSettings[Bools] = RegClientCookie("bstat-master-bools", "what stuff is on/off", CookieAccess_Protected);
	g_hSettings[Position] = RegClientCookie("jhud_position", "jhud_position", CookieAccess_Protected);
	g_hSettings[GainReallyBad] = RegClientCookie("jhud_rlybadgain", "jhud_rlybadgain", CookieAccess_Protected);
	g_hSettings[GainBad] = RegClientCookie("jhud_badgain", "jhud_badgain", CookieAccess_Protected);
	g_hSettings[GainMeh] = RegClientCookie("jhud_mehgain", "jhud_mehgain", CookieAccess_Protected);
	g_hSettings[GainGood] = RegClientCookie("jhud_goodgain", "jhud_goodgain", CookieAccess_Protected);
	g_hSettings[GainReallyGood] = RegClientCookie("jhud_rlygoodgain", "jhud_rlygoodgain", CookieAccess_Protected);

	for(int i = 1; i <= MaxClients; i++) {
		if(AreClientCookiesCached(i)) {
			OnClientCookiesCached(i);
		}
	}
	AutoExecConfig();
}

public Action Command_JHUD(int client, any args) {
	if(!Bstat_IsValidClient(client))
	{
		return Plugin_Handled;
	}
	ShowBHUDMenu(client);
	return Plugin_Handled;
}

public Action Command_CheckJhudOverride(int client, any args) {
	if(g_hOverrideJhud.IntValue) {
		Command_JHUD(client, 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_CheckTrainerOverride(int client, any args) {
	if(g_hOverrideTrainer.IntValue) {
		Command_JHUD(client, 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public void OnClientCookiesCached(int client) {
	char strCookie[8];

	for(int i = 0; i < JHUD_SETTINGS_NUMBER; i++) {
		GetClientCookie(client, g_hSettings[i], strCookie, sizeof(strCookie));
		if(strCookie[0] == '\0') {
			SetDefaults(client);
			return;
		}
		g_iSettings[client][i] = StringToInt(strCookie);
	}

	if(g_iSettings[client][Position] > 2 || g_iSettings[client][Position] < 0) {
		SetDefaults(client);
		return;
	}
	for(int i = 2; i < JHUD_SETTINGS_NUMBER; i++) {
		if(g_iSettings[client][i] > 8 || g_iSettings[client][i] < 0) {
			SetDefaults(client);
			return;
		}
	}
}

void SetDefaults(int client) {
	Bstat_SetCookie(client, g_hSettings[Bools], 23);
	Bstat_SetCookie(client, g_hSettings[Position], 0);
	Bstat_SetCookie(client, g_hSettings[GainReallyBad], Red);
	Bstat_SetCookie(client, g_hSettings[GainBad], Orange);
	Bstat_SetCookie(client, g_hSettings[GainMeh], Green);
	Bstat_SetCookie(client, g_hSettings[GainGood], Cyan);
	Bstat_SetCookie(client, g_hSettings[GainReallyGood], White);

	g_iSettings[client][Bools] = 23;
	g_iSettings[client][Position] = 0;
	g_iSettings[client][GainReallyBad] = Red;
	g_iSettings[client][GainBad] = Orange;
	g_iSettings[client][GainMeh] = Green;
	g_iSettings[client][GainGood] = Cyan;
	g_iSettings[client][GainReallyGood] = White;
}

public void BhopStat_JumpForward(int client, int jump, int speed, int strafecount, float heightdelta, float gain, float sync, float eff, float yawwing, float jss) {
	for(int i = 1; i < MaxClients; i++) {
		if(!(g_iSettings[i][Bools] & JHUD_ENABLED) || !Bstat_IsValidClient(i)) {
			continue;
		}
		if((i == client && IsPlayerAlive(i)) || (!IsPlayerAlive(i) && GetHUDTarget(i) == client)) {
			JHUD_DrawStats(i, jump, speed, gain, sync, jss);
		}
	}
}

public void BhopStat_StrafeForward(int client, int offset, bool overlap, bool nopress) {
	if(g_iLastOffset[client] == offset) {
		g_iRepeatedOffsets[client]++;
	} else {
		g_iRepeatedOffsets[client] = 0;
	}
	for(int i = 1; i < MaxClients; i++) {
		if(!(g_iSettings[i][Bools] & OFFSETS_ENABLED) || !Bstat_IsValidClient(i)) {
			continue;
		}
		if((i == client && IsPlayerAlive(i)) || (!IsPlayerAlive(i) && GetHUDTarget(i) == client)) {
			Offset_DrawOffset(i, offset, overlap, nopress);
		}
	}
	g_iLastOffset[client] = offset;
}

public void OnPlayerRunCmdPost(int client, int buttons)
{
	if ((GetEntityMoveType(client) == MOVETYPE_NOCLIP) || (GetEntityMoveType(client) == MOVETYPE_LADDER))
		return;
	
	if(GetEntityFlags(client) & FL_ONGROUND == FL_ONGROUND) {
		g_iGroundTicks[client]++;
		if ((buttons & IN_JUMP) > 0 && g_iGroundTicks[client] == 1) {
			g_iGroundTicks[client] = 0;
		}
	} else {
		g_iGroundTicks[client] = 0;
	}

	if(g_iGroundTicks[client] > 10) {
		g_iCmdNum[client] = 1;
		g_fPercents[client] = 0.0;
		return;
	}
	if(g_iGroundTicks[client] >= 1) {
		return;
	}

	g_fPercents[client] += (BhopStat_GetJss(client));
	float AveragePercentage = g_fPercents[client] / g_iCmdNum[client];
	if (g_iCmdNum[client] % TRAINER_FULLUPDATE_TICK_INTERVAL == 0)
	{
		g_fLastAverage[client] = AveragePercentage;
		g_fPercents[client] = 0.0;
		g_iCmdNum[client] = 1;
	}

	if(g_iCmdNum[client] % TRAINER_FULLUPDATE_TICK_INTERVAL == 0 || g_iCmdNum[client] % TRAINER_TICK_INTERVAL == 0) {
		for (int i = 1; i <= MaxClients; i++)
		{
			if(!Bstat_IsValidClient(i) || !(g_iSettings[client][Bools] & TRAINER_ENABLED))
			{
				continue;
			}
			if((i == client && IsPlayerAlive(i)) || (GetHUDTarget(i) == client && !IsPlayerAlive(i))) {
				int idx = Trainer_GetColorIdx(AveragePercentage);
				char sMessage[256];
				Trainer_GetTrainerString(sMessage, g_fLastAverage[client], AveragePercentage);
				SetHudTextParams(-1.0, 0.2, 0.1, colors[idx][0], colors[idx][1], colors[idx][2], 255, 0, 0.0, 0.0, 0.1);
				ShowHudText(i, GetDynamicChannel(0), sMessage);
			}
		}
	}
	
	g_iCmdNum[client]++;
	return;
}

void JHUD_DrawStats(int client, int jump, int speed, float gain, float sync, float jss) {
	jss = jss * 100;
	
	char sMessage[256];

	int settingIdx = Jhud_GetJhudSettingsIdx(gain, jump, speed, view_as<bool>(g_iSettings[client][Bools] & JHUD_EXTRASPEED), false);
	int rgb[3];
	rgb = colors[g_iSettings[client][settingIdx]];

	Format(sMessage, sizeof(sMessage), "%i: %i", jump, speed);
	if(jump > 1) {
		if(g_iSettings[client][Bools] & JHUD_JSS == JHUD_JSS) {
			Format(sMessage, sizeof(sMessage), "%s (%.0f%%%%)", sMessage, jss);
		}
		Format(sMessage, sizeof(sMessage), "%s\n%.2f%%", sMessage, gain);
		if(g_iSettings[client][Bools] & JHUD_SYNC == JHUD_SYNC) {
			Format(sMessage, sizeof(sMessage), "%s %.2f%%", sMessage, sync);
		}
	}
	
	SetHudTextParams(-1.0, g_iJhudPositions[g_iSettings[client][Position]], 1.0, rgb[0], rgb[1], rgb[2], 255, 0, 0.0, 0.0);
	ShowHudText(client, GetDynamicChannel(1), sMessage);
}

public void Offset_DrawOffset(int client, int offset, bool overlap, bool nopress) {
	int colorIdx = Offset_GetColorIdx(offset, overlap, nopress);
	SetHudTextParams(-1.0, 0.35, 0.5, colors[colorIdx][0], colors[colorIdx][1], colors[colorIdx][2], 255, 0, 0.0, 0.0, 0.1);

	char msg[256];
	Format(msg, 256, "%d (%i)", offset, g_iRepeatedOffsets[client]);
	if(overlap) {
		Format(msg, 256, "%s Overlap", msg);
	}
	if(nopress) {
		Format(msg, 256, "%s No Press", msg);
	}
	ShowHudText(client, GetDynamicChannel(2), msg);
}

void ShowBHUDMenu(int client)
{
	Menu menu = CreateMenu(BHUD_Select);
	SetMenuTitle(menu, "BHUD - Nimmy\n \n");
	AddMenuItem(menu, "enJhud", (g_iSettings[client][Bools] & JHUD_ENABLED) ? "[x] Jhud":"[ ] Jhud");
	AddMenuItem(menu, "enTrainer", (g_iSettings[client][Bools] & TRAINER_ENABLED) ? "[x] Trainer":"[ ] Trainer");
	AddMenuItem(menu, "enOffset", (g_iSettings[client][Bools] & OFFSETS_ENABLED) ? "[x] Offsets":"[ ] Offsets");
	AddMenuItem(menu, "jhudSettings", "JHUD Settings");
	AddMenuItem(menu, "reset", "Reset Settings");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int BHUD_Select(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, option, info, sizeof(info));
		
		if(StrEqual(info, "enJhud"))
		{
			g_iSettings[client][Bools] ^= JHUD_ENABLED;
			Bstat_SetCookie(client, g_hSettings[Bools], g_iSettings[client][Bools]);
		}
		else if(StrEqual(info, "enTrainer"))
		{
			g_iSettings[client][Bools] ^= TRAINER_ENABLED;
			Bstat_SetCookie(client, g_hSettings[Bools], g_iSettings[client][Bools]);
		}
		else if(StrEqual(info, "enOffset"))
		{
			g_iSettings[client][Bools] ^= OFFSETS_ENABLED;
			Bstat_SetCookie(client, g_hSettings[Bools], g_iSettings[client][Bools]);
		}
		else if(StrEqual(info, "jhudSettings"))
		{
			ShowJhudSettingsMenu(client);
			return 0;
		} else if(StrEqual(info, "reset"))
		{
			SetDefaults(client);
		}
		ShowBHUDMenu(client);
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void ShowJhudSettingsMenu(int client) {
	Menu menu = CreateMenu(JHUD_Select);
	SetMenuTitle(menu, "JHUD SETTINGS\n \n");
	AddMenuItem(menu, "strafespeed", (g_iSettings[client][Bools] & JHUD_JSS) ? "[x] Jss":"[ ] Jss");
	AddMenuItem(menu, "sync", (g_iSettings[client][Bools] & JHUD_SYNC) ? "[x] Sync":"[ ] Sync");
	AddMenuItem(menu, "extraspeeds", (g_iSettings[client][Bools] & JHUD_EXTRASPEED) ? "[x] Extra speeds":"[ ] Extra speeds");

	if(g_iSettings[client][Position] == 0)
	{
		AddMenuItem(menu, "cyclepos", "Position: [CENTER]");
	}
	else if(g_iSettings[client][Position] == 1)
	{
		AddMenuItem(menu, "cyclepos", "Position: [TOP]");
	}
	else if(g_iSettings[client][Position] == 2)
	{
		AddMenuItem(menu, "cyclepos", "Position: [BOTTOM]");
	}
	AddMenuItem(menu, "editcolors", "Edit Color Settings");
	AddMenuItem(menu, "back", "Back");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int JHUD_Select(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, option, info, sizeof(info));
		
		if(StrEqual(info, "strafespeed"))
		{
			g_iSettings[client][Bools] ^= JHUD_JSS;
			Bstat_SetCookie(client, g_hSettings[Bools], g_iSettings[client][Bools]);
		}
		else if(StrEqual(info, "cyclepos"))
		{
			if(++g_iSettings[client][Position] < 3)
			{
				Bstat_SetCookie(client, g_hSettings[Position], g_iSettings[client][Position]);
			}
			else
			{
				g_iSettings[client][Position] = 0;
				Bstat_SetCookie(client, g_hSettings[Position], g_iSettings[client][Position]);
			}
		}
		else if(StrEqual(info, "extraspeeds"))
		{
			g_iSettings[client][Bools] ^= JHUD_EXTRASPEED;
			Bstat_SetCookie(client, g_hSettings[Bools], g_iSettings[client][Bools]);
		}
		else if(StrEqual(info, "sync"))
		{
			g_iSettings[client][Bools] ^= JHUD_SYNC;
			Bstat_SetCookie(client, g_hSettings[Bools], g_iSettings[client][Bools]);
		}
		else if(StrEqual(info, "editcolors"))
		{
			ShowColorOptionsMenu(client);
			return 0;
		}
 		else if(StrEqual(info, "back"))
		{
			ShowBHUDMenu(client);
			return 0;
		}
		ShowJhudSettingsMenu(client);
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

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

	AddMenuItem(menu, "editcolor", colorStrs[g_iSettings[client][editing]]);
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
			if(g_iEditGain[client] > JHUD_SETTINGS_COLOR_END_IDX) {
				g_iEditGain[client] = JHUD_SETTINGS_COLOR_START_IDX;
			}

		}
		else if(StrEqual(info, "editcolor"))
		{
			int editing = g_iEditGain[client];
			g_iSettings[client][editing]++;
			if(g_iSettings[client][editing] > 8) {
				g_iSettings[client][editing] = 0;
			}
			Bstat_SetCookie(client, g_hSettings[g_iEditGain[client]], g_iSettings[client][editing]);
			PrintToChat(client, "Setting %i to %i", g_iEditGain[client], g_iSettings[client][editing]);
		} else if(StrEqual(info, "back"))
		{
			ShowJhudSettingsMenu(client);
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