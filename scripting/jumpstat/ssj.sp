static float g_fLastJumpTime[MAXPLAYERS + 1];

public void Ssj_Process(int client, int jump, int speed, int strafecount, float heightdelta, float gain, float sync,
float eff, float yawwing, float jss, bool shavit, chatstrings_t shavitChatStrings, EngineVersion engine)
{

	float time = 0.0;
	if(shavit)
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
			SSJ_WriteMessage(i, client, jump, speed, strafecount, heightdelta, gain, sync, eff, shavit, shavitChatStrings, engine);
		}
	}
	g_fLastJumpTime[client] = time;
}

void SSJ_WriteMessage(int client, int target, int jump, int speed, int strafecount, float heightdelta, float gain, float sync,
 float eff, bool shavit, chatstrings_t shavitChatStrings, EngineVersion engine)
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
	FormatEx(sMessage, sizeof(sMessage), "J: %s%i", shavitChatStrings.sVariable, jump);
	Format(sMessage, sizeof(sMessage), "%s %s| S: %s%i", sMessage, shavitChatStrings.sText, shavitChatStrings.sVariable, speed);

	if(jump > 1)
	{
		float time = 0.0;
		if(shavit)
		{
			time = Shavit_GetClientTime(client);
		}

		if(g_iSettings[client][Bools] & SSJ_GAIN)
		{
			if(g_iSettings[client][Bools] & SSJ_GAIN_COLOR)
			{
				int idx = GetGainColorIdx(gain);
				int settingsIdx = g_iSettings[client][idx];
				Format(sMessage, sizeof(sMessage), "%s %s| G: %s%.1f%%", sMessage, shavitChatStrings.sText, g_sBstatColorsHex[settingsIdx], gain);
			}
			else
			{
				Format(sMessage, sizeof(sMessage), "%s %s| G: %s%.1f%%", sMessage, shavitChatStrings.sText, shavitChatStrings.sVariable, gain);
			}
		}

		if(g_iSettings[client][Bools] & SSJ_SYNC)
		{
			Format(sMessage, sizeof(sMessage), "%s %s| S: %s%.1f%%", sMessage, shavitChatStrings.sText, shavitChatStrings.sVariable, sync);
		}

		if(g_iSettings[client][Bools] & SSJ_EFFICIENCY)
		{
			Format(sMessage, sizeof(sMessage), "%s %s| Ef: %s%.1f%%", sMessage, shavitChatStrings.sText, shavitChatStrings.sVariable, eff);
		}

		if(g_iSettings[client][Bools] & SSJ_HEIGHTDIFF)
		{
			Format(sMessage, sizeof(sMessage), "%s %s| HΔ: %s%.1f", sMessage, shavitChatStrings.sText, shavitChatStrings.sVariable, heightdelta);
		}

		if(g_iSettings[client][Bools] & SSJ_STRAFES)
		{
			Format(sMessage, sizeof(sMessage), "%s %s| Stf: %s%i", sMessage, shavitChatStrings.sText, shavitChatStrings.sVariable, strafecount);
		}

		if(g_iSettings[client][Bools] & SSJ_SHAVIT_TIME && shavit)
		{
			Format(sMessage, sizeof(sMessage), "%s %s| T: %s%.2f", sMessage, shavitChatStrings.sText, shavitChatStrings.sVariable, time);
		}

		if(g_iSettings[client][Bools] & SSJ_SHAVIT_TIME_DELTA && shavit)
		{
			Format(sMessage, sizeof(sMessage), "%s %s| TΔ: %s%.2f", sMessage, shavitChatStrings.sText, shavitChatStrings.sVariable, (time - g_fLastJumpTime[target]));
		}
	}

	if(shavit)
	{
		Shavit_StopChatSound();
		Shavit_PrintToChat(client, "%s", sMessage); // Thank you, GAMMACASE
	}
	else
	{
		PrintToChat(client, "%s%s%s%s", (engine == Engine_CSGO) ? " ":"", shavitChatStrings.sPrefix, shavitChatStrings.sText, sMessage);
		//no clue why but this space thing is important, if you remove it and use this on css all colors break lol
	}
}
