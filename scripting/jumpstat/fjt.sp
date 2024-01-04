static bool g_bJumpInZone[MAXPLAYERS + 1];

void Fjt_Shavit_LeftZone(int client, int type)
{
	if(!BgsIsValidClient(client))
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
	if(jump != 1 || !BgsShavitLoaded() || !BgsIsValidClient(client))
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
	if(g_bEditing[client])
	{
		return;
	}
	for(int i = 1; i < MaxClients; i++)
	{
		if(( !(g_iSettings[i][Bools] & FJT_ENABLED) && !(g_iSettings[i][Bools] & FJT_CHAT) ) || !BgsIsValidClient(i))
		{
			continue;
		}
		if((i == client && IsPlayerAlive(i)) || (!IsPlayerAlive(i) && BgsGetHUDTarget(i) == client))
		{
			SetHudTextParams(g_fCacheHudPositions[i][Offset][X_DIM], g_fCacheHudPositions[i][Offset][Y_DIM] + 0.05, 2.0, 255, 255, 255, 255);
			int tick = RoundToNearest(Shavit_GetClientTime(client) * 100);
			tick = g_bJumpInZone[client] ? (tick*-1):tick;

			if(g_iSettings[i][Bools] & FJT_ENABLED)
			{
				ShowHudText(i, GetDynamicChannel(3), "FJT: %i", tick);
			}

			if(g_iSettings[i][Bools] & FJT_CHAT)
			{
				Shavit_PrintToChat(i, "%sFJT: %s%i", g_csChatStrings.sText, g_csChatStrings.sVariable, tick);
			}
		}
	}
}
