static float g_fLastJumpTime[MAXPLAYERS + 1];

public void Ssj_Process(int client, int jump, int speed, int strafecount, float heightdelta, float gain, float sync,
float eff, float yawwing, float jss)
{

	if(!g_hEnabledSsj.BoolValue)
	{
		return;
	}

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
			SSJ_WriteMessage(i, client, jump, speed, strafecount, heightdelta, gain, sync, eff, jss);
		}
	}
	g_fLastJumpTime[client] = time;
}

void SSJ_WriteMessage(int client, int target, int jump, int speed, int strafecount, float heightdelta, float gain, float sync,
 float eff, float jss)
{
	if(jump != 1)
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
	}

	char message[230]; //Max is slightly more but shavit needs to add stuff
	int maxlen = sizeof(message) - 30;
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
			int idx = GetGainColorIdx(gain);
			int settingsIdx = g_iSettings[client][idx];

			if(g_iSettings[client][Bools] & SSJ_DECIMALS)
			{
				Format(message, sizeof(message), "%s %s| G: %s%.2f%%", message, g_csChatStrings.sText, g_sBstatColorsHex[settingsIdx], gain);
			}
			else
			{
				Format(message, sizeof(message), "%s %s| G: %s%i%%", message, g_csChatStrings.sText, g_sBstatColorsHex[settingsIdx], RoundToFloor(gain));
			}
		}

		if(g_iSettings[client][Bools] & SSJ_SYNC)
		{
			if(g_iSettings[client][Bools] & SSJ_DECIMALS)
			{
				Format(message, sizeof(message), "%s %s| S: %s%.2f%%", message, g_csChatStrings.sText, g_csChatStrings.sVariable, sync);
			}
			else
			{
				Format(message, sizeof(message), "%s %s| S: %s%i%%", message, g_csChatStrings.sText, g_csChatStrings.sVariable, RoundToFloor(sync));
			}
		}

		if(g_iSettings[client][Bools] & SSJ_STRAFES)
		{
			Format(message, sizeof(message), "%s %s| Stf: %s%i", message, g_csChatStrings.sText, g_csChatStrings.sVariable, strafecount);
		}

		if(g_iSettings[client][Bools] & SSJ_JSS)
		{
			Format(message, sizeof(message), "%s %s| Jss: %s%i", message, g_csChatStrings.sText, g_csChatStrings.sVariable, RoundToFloor(jss * 100));
		}

		if(g_iSettings[client][Bools] & SSJ_EFFICIENCY)
		{
			if(g_iSettings[client][Bools] & SSJ_DECIMALS)
			{
				Format(message, sizeof(message), "%s %s| Ef: %s%.2f%%", message, g_csChatStrings.sText, g_csChatStrings.sVariable, eff);
			}
			else
			{
				Format(message, sizeof(message), "%s %s| Ef: %s%i%%", message, g_csChatStrings.sText, g_csChatStrings.sVariable, RoundToFloor(eff));
			}
		}

		if(g_iSettings[client][Bools] & SSJ_HEIGHTDIFF)
		{
			Format(message, sizeof(message), "%s %s| HΔ: %s%.1f", message, g_csChatStrings.sText, g_csChatStrings.sVariable, heightdelta);
		}

		if(g_iSettings[client][Bools] & SSJ_SHAVIT_TIME && BgsShavitLoaded())
		{
			Format(message, sizeof(message), "%s %s| T: %s%.2f", message, g_csChatStrings.sText, g_csChatStrings.sVariable, time);
		}

		if(strlen(message) < maxlen && g_iSettings[client][Bools] & SSJ_SHAVIT_TIME_DELTA && BgsShavitLoaded())
		{
			Format(message, sizeof(message), "%s %s| TΔ: %s%.2f", message, g_csChatStrings.sText, g_csChatStrings.sVariable, (time - g_fLastJumpTime[target]));
		}

		if(strlen(message) < maxlen && g_iSettings[client][Bools] & SSJ_SHAVIT_TIME_DELTA)
		{
			Format(message, sizeof(message), "%s %s| TΔ: %s%.2f", message, g_csChatStrings.sText, g_csChatStrings.sVariable, (time - g_fLastJumpTime[target]));
		}

		if(strlen(message) < maxlen && g_iCurrentFrame[target] >= 1 && g_iSettings[client][Bools] & SSJ_OFFSETS)
		{
			Format(message, sizeof(message), "%s %s| Of:%s", message, g_csChatStrings.sText, g_csChatStrings.sVariable);
			for(int i = 0; i < g_iCurrentFrame[target]; i++)
			{
				if(strlen(message) >= (sizeof(message) - 1))
				{
					break;
				}
				if(i == 0)
				{
					Format(message, sizeof(message), "%s %i", message, g_iOffsetHistory[target][i]);
				}
				else
				{
					Format(message, sizeof(message), "%s, %i", message, g_iOffsetHistory[target][i]);
				}
			}
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
