static bool g_bJumpInZone[MAXPLAYERS + 1];
int g_iFjtJumpTick[MAXPLAYERS + 1];

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

void Fjt_OnJump(int client)
{
	if(!g_hEnabledFjt.BoolValue || !g_bShavitZonesLoaded || !g_bShavitCoreLoaded || !BgsIsValidClient(client))
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
	int tick = RoundToNearest(Shavit_GetClientTime(client) * BgsTickRate());
	tick = g_bJumpInZone[client] ? (tick*-1):tick;

	g_iFjtJumpTick[client] = tick;

	for(int idx = -1; idx < g_iSpecListCurrentFrame[client]; idx++)
	{
		int messageTarget = idx == -1 ? client:g_iSpecList[client][idx];

		if((!(g_iSettings[messageTarget][Bools] & FJT_ENABLED) && !(g_iSettings[messageTarget][Bools] & FJT_CHAT)) || !BgsIsValidPlayer(messageTarget))
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
			Shavit_StopChatSound();
			Shavit_PrintToChat(messageTarget, "%sFJT: %s%i", g_csChatStrings.sText, g_csChatStrings.sVariable, tick);
		}
	}
}

public void Shavit_OnFinish(int client, int style, float time, int jumps, int strafes, float sync, int track, float oldtime, float perfs, float avgvel, float maxvel, int timestamp)
{
	int tick = g_iFjtJumpTick[client];

	for (int idx = -1; idx < g_iSpecListCurrentFrame[client]; idx++)
	{
		int messageTarget = idx == -1 ? client : g_iSpecList[client][idx];

		if ((!(g_iSettings[messageTarget][Bools] & FJT_ENABLED) && !(g_iSettings[messageTarget][Bools] & FJT_CHAT)) || !BgsIsValidPlayer(messageTarget))
		{
			continue;
		}

		if (g_iSettings[messageTarget][Bools] & FJT_CHAT)
		{
			Shavit_StopChatSound();
			Shavit_PrintToChat(messageTarget, "%sYour FJT was: %s%i", g_csChatStrings.sText, g_csChatStrings.sVariable, tick);
		}
	}
}