public void Jhud_Process(int client, int jump, int speed, int strafecount, float heightdelta, float gain, float sync, float eff, float yawwing, float jss)
{
	for(int i = 1; i < MaxClients; i++)
	{
		if(!(g_iSettings[i][Bools] & JHUD_ENABLED) || !BgsIsValidClient(i))
		{
			continue;
		}
		if((i == client && IsPlayerAlive(i)) || (!IsPlayerAlive(i) && BgsGetHUDTarget(i) == client))
		{
			JHUD_DrawStats(i, jump, speed, gain, sync, jss);
		}
	}
}

void JHUD_DrawStats(int client, int jump, int speed, float gain, float sync, float jss)
{
	if(jump > g_iSettings[client][JhudCutOff] && g_iSettings[client][JhudCutOff] != 0)
	{
		return;
	}

	char message[256];

	int settingIdx;
	if((jump <= 16) && jump <= g_iSettings[client][JhudSpeedColorsJump])
	{
		settingIdx = GetSpeedColorIdx(jump, speed);
	}
	else
	{
		settingIdx = GetGainColorIdx(gain);
	}

	int rgb[3];
	rgb = g_iBstatColors[g_iSettings[client][settingIdx]];

	Format(message, sizeof(message), "%i: %i", jump, speed);
	if(jump > 1)
	{
		if(g_iSettings[client][Bools] & JHUD_JSS == JHUD_JSS)
		{
			Format(message, sizeof(message), "%s (%iPCT)", message, RoundToFloor(jss * 100.0));
		}

		Format(message, sizeof(message), "%s\n%.2f", message, gain);
		if(g_iSettings[client][Bools] & JHUD_SYNC == JHUD_SYNC)
		{
			Format(message, sizeof(message), "%s %.2fPCT", message, sync);
		}
	}
	ReplaceString(message, sizeof(message), "PCT", "%%", true);

	BgsDisplayHud(client, g_fCacheHudPositions[client][Jhud], rgb, 1.0, GetDynamicChannel(1), false,  message);
}
