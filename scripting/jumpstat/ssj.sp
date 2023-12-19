#undef REQUIRE_PLUGIN
#include <shavit>

float g_fLastJumpTime[MAXPLAYERS + 1];
bool g_bShavit = false;
chatstrings_t g_sChatStrings;
EngineVersion gEV_Type = Engine_Unknown;

public void SSJ_Start(bool late)
{
	g_bShavit = LibraryExists("shavit");
	if(late && g_bShavit)
	{
		Shavit_OnChatConfigLoaded();
	}
	gEV_Type = GetEngineVersion();
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

public void Ssj_Process(int client, int jump, int speed, int strafecount, float heightdelta, float gain, float sync, float eff, float yawwing, float jss)
{

	float time = 0.0;
	if(g_bShavit)
	{
		time = Shavit_GetClientTime(client);
	}

	for(int i = 1; i < MaxClients; i++)
	{
		if(!(g_iSettings[i][Bools] & SSJ_ENABLED) || !BgsIsValidClient(i))
		{
			continue;
		}
		if((i == client && IsPlayerAlive(i)) || (!IsPlayerAlive(i) && BgsGetHUDTarget(i) == client))
		{
			SSJ_WriteMessage(i, client, jump, speed, strafecount, heightdelta, gain, sync, eff);
		}
	}
	g_fLastJumpTime[client] = time;
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
				int idx = GetGainColorIdx(gain);
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
