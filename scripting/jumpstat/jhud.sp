void Jhud_ProcessFirst(int client, int speed)
{
	if(!g_hEnabledJhud.BoolValue)
	{
		return;
	}

	for(int idx = -1; idx < g_iSpecListCurrentFrame[client]; idx++)
	{
		int messageTarget = idx == -1 ? client:g_iSpecList[client][idx];

		if(!(g_iSettings[messageTarget][Bools] & JHUD_ENABLED))
		{
			continue;
		}
		JHUD_DrawFirst(messageTarget, speed);
	}
}

void JHUD_DrawFirst(client, speed)
{
	char message[256];

	int settingIdx = GetSpeedColorIdx(1, speed);

	int rgb[3];
	rgb = g_iBstatColors[g_iSettings[client][settingIdx]];

	Format(message, sizeof(message), "1: %i", speed);

	BgsDisplayHud(client, g_fCacheHudPositions[client][Jhud], rgb, 1.0, GetDynamicChannel(1), false,  message);
}

void Jhud_Process(int client, int jump, int speed, float gain, float sync, float jss, float absJss)
{
	if(!g_hEnabledJhud.BoolValue)
	{
		return;
	}

	for(int idx = -1; idx < g_iSpecListCurrentFrame[client]; idx++)
	{
		int messageTarget = idx == -1 ? client:g_iSpecList[client][idx];

		if(!(g_iSettings[messageTarget][Bools] & JHUD_ENABLED) || !BgsIsValidPlayer(messageTarget))
		{
			continue;
		}
		JHUD_DrawStats(messageTarget, jump, speed, gain, sync, jss, absJss);
	}
}

void JHUD_DrawStats(int client, int jump, int speed, float gain, float sync, float jss, float absJss)
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
		settingIdx = GetPercentageColorIdx(gain, true);
	}

	int rgb[3];
	rgb = g_iBstatColors[g_iSettings[client][settingIdx]];

	Format(message, sizeof(message), "%i: %i", jump, speed);
	if(jump > 1)
	{
		if(g_iSettings[client][Bools] & JHUD_JSS)
		{
			Format(message, sizeof(message), "%s (%iPCT)", message, RoundToFloor(jss * 100.0));
		}
		else if(g_iSettings[client][Bools] & JHUD_GMOD_JSS)
		{
			Format(message, sizeof(message), "%s (%iPCT", message, RoundToFloor(absJss));

			if(absJss != 100)
			{
				if(RoundToFloor(jss * 100.0) > 100 )
				{
					Format(message, sizeof(message), "%s %s)", message, "↓");
				}
				else
				{
					Format(message, sizeof(message), "%s %s)", message, "↑");
				}
			}
			else
			{
				Format(message, sizeof(message), "%s %s)", message, "✓");
			}
		}

		Format(message, sizeof(message), "%s\n%.2f", message, gain);

		if(g_iSettings[client][Bools] & JHUD_SYNC)
		{
			Format(message, sizeof(message), "%s %.2fPCT", message, sync);
		}
	}
	ReplaceString(message, sizeof(message), "PCT", "%%", true);

	BgsDisplayHud(client, g_fCacheHudPositions[client][Jhud], rgb, 1.0, GetDynamicChannel(1), false,  message);
}
