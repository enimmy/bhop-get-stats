static float g_fLastJumpTime[MAXPLAYERS + 1];

public void Ssj_Process(int client, int jump, int speed, int strafecount, float heightdelta, float gain, float sync,
float eff, float yawwing, float jss)
{

	float time = 0.0;
	if(BgsShavitLoaded())
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

void SSJ_WriteMessage(int client, int target, int jump, int speed, int strafecount, float heightdelta, float gain, float sync,
 float eff)
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

	char message[300];
	FormatEx(message, sizeof(message), "J: %s%i", g_csChatStrings.sVariable, jump);
	Format(message, sizeof(message), "%s %s| S: %s%i", message, g_csChatStrings.sText, g_csChatStrings.sVariable, speed);

	if(jump > 1)
	{
		float time = 0.0;
		if(BgsShavitLoaded())
		{
			time = Shavit_GetClientTime(client);
		}

		if(g_iSettings[client][Bools] & SSJ_GAIN)
		{
			if(g_iSettings[client][Bools] & SSJ_GAIN_COLOR)
			{
				int idx = GetGainColorIdx(gain);
				int settingsIdx = g_iSettings[client][idx];
				Format(message, sizeof(message), "%s %s| G: %s%.1f%%", message, g_csChatStrings.sText, g_sBstatColorsHex[settingsIdx], gain);
			}
			else
			{
				Format(message, sizeof(message), "%s %s| G: %s%.1f%%", message, g_csChatStrings.sText, g_csChatStrings.sVariable, gain);
			}
		}

		if(g_iSettings[client][Bools] & SSJ_SYNC)
		{
			Format(message, sizeof(message), "%s %s| S: %s%.1f%%", message, g_csChatStrings.sText, g_csChatStrings.sVariable, sync);
		}

		if(g_iSettings[client][Bools] & SSJ_EFFICIENCY)
		{
			Format(message, sizeof(message), "%s %s| Ef: %s%.1f%%", message, g_csChatStrings.sText, g_csChatStrings.sVariable, eff);
		}

		if(g_iSettings[client][Bools] & SSJ_HEIGHTDIFF)
		{
			Format(message, sizeof(message), "%s %s| HΔ: %s%.1f", message, g_csChatStrings.sText, g_csChatStrings.sVariable, heightdelta);
		}

		if(g_iSettings[client][Bools] & SSJ_STRAFES)
		{
			Format(message, sizeof(message), "%s %s| Stf: %s%i", message, g_csChatStrings.sText, g_csChatStrings.sVariable, strafecount);
		}

		if(g_iSettings[client][Bools] & SSJ_SHAVIT_TIME && BgsShavitLoaded())
		{
			Format(message, sizeof(message), "%s %s| T: %s%.2f", message, g_csChatStrings.sText, g_csChatStrings.sVariable, time);
		}

		if(g_iSettings[client][Bools] & SSJ_SHAVIT_TIME_DELTA && BgsShavitLoaded())
		{
			Format(message, sizeof(message), "%s %s| TΔ: %s%.2f", message, g_csChatStrings.sText, g_csChatStrings.sVariable, (time - g_fLastJumpTime[target]));
		}
	}

	if(BgsShavitLoaded())
	{
		Shavit_StopChatSound();
		Shavit_PrintToChat(client, "%s", message); // Thank you, GAMMACASE
	}
	else
	{
		PrintToChat(client, "%s%s%s%s", (BgsGetEngineVersion() == Engine_CSGO) ? " ":"", g_csChatStrings.sPrefix, g_csChatStrings.sText, message);
		//no clue why but this space thing is important, if you remove it and use this on css all colors break lol
	}
}
