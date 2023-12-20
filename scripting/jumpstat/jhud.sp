public void Jhud_Process(int client, int jump, int speed, int strafecount, float heightdelta, float gain, float sync, float eff, float yawwing, float jss)
{
	if(g_bEditing[client])
	{
		return;
	}
	for(int i = 1; i < MaxClients; i++)
	{
		if(!(g_iSettings[i][Bools] & JHUD_ENABLED) || !BgsIsValidClient(i))
		{
			continue;
		}
		if((i == client && IsPlayerAlive(i)) || (!IsPlayerAlive(i) && BgsGetHUDTarget(i) == client))
		{
			if(g_iSettings[i][Bools] & JHUD_ENABLED)
			{
				JHUD_DrawStats(i, jump, speed, gain, sync, jss);
			}
		}
	}
}

void JHUD_DrawStats(int client, int jump, int speed, float gain, float sync, float jss)
{
	int ijss = RoundToFloor(jss * 100);

	char sMessage[256];

	int settingIdx;
	if((jump <= 6 || jump == 16) || (g_iSettings[client][Bools] & JHUD_EXTRASPEED && jump <= 16))
	{
		settingIdx = GetSpeedColorIdx(jump, speed);
	}
	else
	{
		settingIdx = GetGainColorIdx(gain);
	}

	int rgb[3];
	rgb = g_iBstatColors[g_iSettings[client][settingIdx]];

	Format(sMessage, sizeof(sMessage), "%i: %i", jump, speed);
	if(jump > 1)
	{
		if(g_iSettings[client][Bools] & JHUD_JSS == JHUD_JSS)
		{
			Format(sMessage, sizeof(sMessage), "%s (%iPCT)", sMessage, ijss);
		}

		Format(sMessage, sizeof(sMessage), "%s\n%.2f", sMessage, gain);
		if(g_iSettings[client][Bools] & JHUD_SYNC == JHUD_SYNC)
		{
			Format(sMessage, sizeof(sMessage), "%s %.2fPCT", sMessage, sync);
		}
	}
	ReplaceString(sMessage, sizeof(sMessage), "PCT", "%%", true);
	SetHudTextParams(g_fCacheHudPositions[client][Jhud][X_DIM], g_fCacheHudPositions[client][Jhud][Y_DIM], 1.0, rgb[0], rgb[1], rgb[2], 255, 0, 0.0, 0.0, 0.0);
	ShowHudText(client, GetDynamicChannel(1), sMessage); //JHUD
}
