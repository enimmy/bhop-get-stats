#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <clientprefs>
#include <bhop-get-stats>
#include <DynamicChannels>

#define NUMBER_TICK_INTERVAL 13
#define TRAINER_TICK_INTERVAL 5

Handle g_hHudSync;
Cookie g_bEnabledCookie;

float g_fPercents[MAXPLAYERS + 1];
float g_fLastAverage[MAXPLAYERS + 1];

int g_iCmdNum[MAXPLAYERS + 1];
int g_iLastColors[MAXPLAYERS + 1][3];
int g_iGroundTicks[MAXPLAYERS + 1];

bool g_bEnabled[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Bhop Strafe Trainer",
	author = "Nimmy / PaxPlay",
	description = "Bhop Strafe Trainer",
	version = "1.1",
	url = "https://github.com/Nimmy2222/bhop-get-stats"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_hHudSync = CreateHudSynchronizer();
	if(g_hHudSync == INVALID_HANDLE) {
		Format(error, err_max, "bstat-trainer: failed to initalize hud syncronizer, your mod might not support it.");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{	
	RegConsoleCmd("sm_strafetrainer", Command_StrafeTrainer, "Toggles the Strafe trainer.");
	g_bEnabledCookie = RegClientCookie("strafetrainer_enabled", "strafetrainer_enabled", CookieAccess_Protected);
	
	// Late loading
	for(int i = 1; i <= MaxClients; i++)
	{
		if(AreClientCookiesCached(i))
		{
			OnClientCookiesCached(i);
		}
	}
}

public void OnClientDisconnect(int client)
{
	g_bEnabled[client] = false;
}

public void OnClientCookiesCached(int client)
{
	char sValue[8];
	GetClientCookie(client, g_bEnabledCookie, sValue, sizeof(sValue));
	if(sValue[0] == '\0') {
		SetClientCookie(client, g_bEnabledCookie, "0");
	}
	GetClientCookie(client, g_bEnabledCookie, sValue, sizeof(sValue));
	g_bEnabled[client] = view_as<bool>(StringToInt(sValue));
}

public Action Command_StrafeTrainer(int client, int args)
{
	if(!IsValidClient(client)) {
		return Plugin_Handled;
	}
	g_bEnabled[client] = !g_bEnabled[client];
	char sValue[8];
	IntToString(g_bEnabled[client], sValue, sizeof(sValue));
	SetClientCookie(client, g_bEnabledCookie, sValue);
	PrintToChat(client, "Strafe-Trainer: %s", g_bEnabled[client] ? "Enabled" : "Disabled");
	return Plugin_Handled;
}

void VisualisationString(char[] buffer, int maxlength, float percentage)
{
	
	if (0.5 <= percentage <= 1.5)
	{
		int Spaces = RoundFloat((percentage - 0.5) / 0.05);
		for (int i = 0; i <= Spaces + 1; i++)
		{
			FormatEx(buffer, maxlength, "%s ", buffer);
		}
		
		FormatEx(buffer, maxlength, "%s|", buffer);
		
		for (int i = 0; i <= (21 - Spaces); i++)
		{
			FormatEx(buffer, maxlength, "%s ", buffer);
		}
	}
	else
		Format(buffer, maxlength, "%s", percentage < 1.0 ? "|                   " : "                    |");
}

void GetPercentageColor(float percentage, int &r, int &g, int &b)
{
	if(percentage > 1.0) {
		// Red
		r = 228;
		g = 23;
		b = 2;
	} else if(percentage >= 0.9) {
		// White
		r = 255;
		g = 255;
		b = 255;
	}else if(percentage >= 0.8) {
		// Lightblue
		r = 0;
		g = 255;
		b = 255;
	} else if(percentage >= 0.75) {
		// Light Green
		r = 101;
		g = 255;
		b = 77;
	} else if(percentage >= 0.65) {
		// Dark Green
		r = 27;
		g = 210;
		b = 0;
	} else if(percentage >= 0.6) {
		// Yellow
		r = 255;
		g = 255;
		b = 0;
	} else {
		// Dark Red
		r = 255;
		g = 0;
		b = 0;
	}
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

	bool update, full;
	g_fPercents[client] += (BhopStat_GetJss(client));
	float AveragePercentage = g_fPercents[client] / g_iCmdNum[client];
	if (g_iCmdNum[client] % NUMBER_TICK_INTERVAL == 0)
	{
		g_fLastAverage[client] = AveragePercentage;
		update = true;
		full = true;
		g_fPercents[client] = 0.0;
		g_iCmdNum[client] = 1;
	} else if(g_iCmdNum[client] % TRAINER_TICK_INTERVAL == 0) {
		update = true;
	}
	if(update) {
		for (int i = 1; i <= MaxClients; i++)
		{
			if(!g_bEnabled[i]|| !IsValidClient(i))
			{
				continue;
			}
			if((i == client && IsPlayerAlive(i)) || (GetHUDTarget(i) == client && !IsPlayerAlive(i))) {
				WriteTrainer(i, AveragePercentage, full);
			}
		}
	}
	
	g_iCmdNum[client]++;
	return;
}

void WriteTrainer(int client, float number, bool fullUpdate) {
	char sVisualisation[32]; // get the visualisation string
	VisualisationString(sVisualisation, sizeof(sVisualisation), number);

	// format the message
	char sMessage[256];
	if(fullUpdate) {
		Format(sMessage, sizeof(sMessage), "%d\%", RoundFloat(number * 100));
		GetPercentageColor(number, g_iLastColors[client][0], g_iLastColors[client][1], g_iLastColors[client][2]);
	} else {
		Format(sMessage, sizeof(sMessage), "%d\%", RoundFloat(g_fLastAverage[client] * 100));
	}
	Format(sMessage, sizeof(sMessage), "%s\n══════^══════", sMessage);
	Format(sMessage, sizeof(sMessage), "%s\n %s ", sMessage, sVisualisation);
	Format(sMessage, sizeof(sMessage), "%s\n══════^══════", sMessage);
	
	// print the text
	if(g_hHudSync != INVALID_HANDLE)
	{
		SetHudTextParams(-1.0, 0.2, 0.1, g_iLastColors[client][0], g_iLastColors[client][1], g_iLastColors[client][2], 255, 0, 0.0, 0.0, 0.1);
		//ShowSyncHudText(client, g_hHudSync, sMessage);
		ShowHudText(client, GetDynamicChannel(1), sMessage);
	}
}

bool IsValidClient(int client, bool bAlive = false)
{
	return (client >= 1 && client <= MaxClients && IsClientInGame(client) && !IsClientSourceTV(client) && (!bAlive || IsPlayerAlive(client)));
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