static bool g_bJumpInZone[MAXPLAYERS + 1];

void Fjt_Shavit_LeftZone(int client, int type)
{
	if(!g_hEnabledFjt.BoolValue || !BgsIsValidClient(client))
	{
		return;
	}

	if(g_bJumpInZone[client])
	{
		if(type == Zone_Start)
		{
			PrintJumpTick(client);
			g_bJumpInZone[client] = false;
		}
	}
}

void Fjt_OnJump(int client, int jump)
{
	if(!g_hEnabledFjt.BoolValue || jump != 1 || !BgsShavitLoaded() || !BgsIsValidClient(client))
	{
		return;
	}

	if(Shavit_InsideZone(client, Zone_Start, -1))
	{
		g_bJumpInZone[client] = true;
	}
	else if((Shavit_GetTimerStatus(client) == Timer_Running) && (Shavit_GetClientJumps(client) == 1))
	{
		PrintJumpTick(client);
	}
	return;
}


void PrintJumpTick(int client)
{
	int tick = RoundToNearest(Shavit_GetClientTime(client) * 100);
	tick = g_bJumpInZone[client] ? (tick*-1):tick;

	for(int idx = -1; idx < g_iSpecListCurrentFrame[client]; idx++)
	{
		int messageTarget = idx == -1 ? client:idx;

		if(!(g_iSettings[messageTarget][Bools] & FJT_ENABLED) && !(g_iSettings[messageTarget][Bools] & FJT_CHAT))
		{
			continue;
		}

		SetHudTextParams(g_fCacheHudPositions[messageTarget][FJT][X_DIM], g_fCacheHudPositions[messageTarget][FJT][Y_DIM], 2.0, 255, 255, 255, 255);

		if(g_iSettings[messageTarget][Bools] & FJT_ENABLED)
		{
			int channel = 5;
			if(!(g_iSettings[messageTarget][Bools] & TRAINER_ENABLED))
			{
				channel = 0;
			}
			else if(!(g_iSettings[messageTarget][Bools] & JHUD_ENABLED))
			{
				channel = 1;
			}
			else if(!(g_iSettings[messageTarget][Bools] & OFFSETS_ENABLED))
			{
				channel = 2;
			}
			else if(!(g_iSettings[messageTarget][Bools] & SHOWKEYS_ENABLED))
			{
				channel = 3;
			}
			else if(!(g_iSettings[messageTarget][Bools] & SPEEDOMETER_ENABLED))
			{
				channel = 4;
			}

			ShowHudText(messageTarget, GetDynamicChannel(channel), "FJT: %i", tick);
		}

		if(g_iSettings[messageTarget][Bools] & FJT_CHAT)
		{
			Shavit_PrintToChat(messageTarget, "%sFJT: %s%i", g_csChatStrings.sText, g_csChatStrings.sVariable, tick);
		}
	}
}
