static int g_iLastOffset[MAXPLAYERS + 1];
static int g_iRepeatedOffsets[MAXPLAYERS + 1];

#define OFFSETS_MAX_FRAME 15

int g_iOffsetHistory[MAXPLAYERS + 1][OFFSETS_MAX_FRAME];
int g_iCurrentFrame[MAXPLAYERS + 1];

void Offset_Process(int client, int offset, bool overlap, bool nopress)
{
	if(!g_hEnabledOffset.BoolValue)
	{
		return;
	}

	if(g_iLastOffset[client] == offset)
	{
		g_iRepeatedOffsets[client]++;
	}
	else
	{
		g_iRepeatedOffsets[client] = 0;
	}

	g_iOffsetHistory[client][g_iCurrentFrame[client]] = offset;
	g_iCurrentFrame[client]++;
	if(g_iCurrentFrame[client] >= OFFSETS_MAX_FRAME)
	{
		g_iCurrentFrame[client] = 0;
	}

	for(int idx = -1; idx < g_iSpecListCurrentFrame[client]; idx++)
	{
		int messageTarget = idx == -1 ? client:g_iSpecList[client][idx];

		if(!(g_iSettings[messageTarget][Bools] & OFFSETS_ENABLED))
		{
			continue;
		}

		Offset_DrawOffset(messageTarget, offset, g_iRepeatedOffsets[client], overlap, nopress)
	}
	g_iLastOffset[client] = offset;
}

void Offset_DrawOffset(int client, int offset, int repeats, bool overlap, bool nopress)
{
	char message[256];
	Format(message, sizeof(message), "%d (%i)", offset, repeats);
	int colorIdx = Offset_GetColorIdx(offset);

	if(g_iSettings[client][Bools] & OFFSETS_ADVANCED)
	{
		if(overlap)
		{
			Format(message, sizeof(message), "%s Overlap", message);
			colorIdx = GainReallyBad;
		}

		if(nopress)
		{
			Format(message, sizeof(message), "%s No Press", message);
			colorIdx = GainReallyBad;
		}
	}

	BgsDisplayHud(client, g_fCacheHudPositions[client][Offset], g_iBstatColors[g_iSettings[client][colorIdx]], 0.5, GetDynamicChannel(2), false, message)
}

void Offset_Dump(int client, int jump, float sync)
{
	if(!g_hEnabledOffset.BoolValue)
	{
		return;
	}

	if(jump == 1)
	{
		g_iCurrentFrame[client] = 0;
		return;
	}

	char message[256];
	Format(message, sizeof(message), "[JumpStats] Jump: %i Sync: %2.f", jump, sync);
	for(int i = 0; i < g_iCurrentFrame[client]; i++)
	{
		Format(message, sizeof(message), "%s %i,", message, g_iOffsetHistory[client][i]);
	}

	for(int i = 1; i < MaxClients; i++)
	{
		if(!(g_iSettings[i][Bools] & OFFSETS_SPAM_CONSOLE) || !BgsIsValidClient(i))
		{
			continue;
		}

		if((i == client && IsPlayerAlive(i)) || (!IsPlayerAlive(i) && BgsGetHUDTarget(i) == client))
		{
			PrintToConsole(i, "%s", message);
		}
	}

	g_iCurrentFrame[client] = 0;
}

int Offset_GetColorIdx(int offset) {
    if(offset > 0)
	{
        return GainReallyBad;
    }

    if(offset == 0)
	{
		return GainMeh;
    }
	else if(offset == -1)
	{
		return GainReallyGood;
    }
	else if(offset == -2)
	{
		return GainGood;
	}
	else if(offset == -3)
	{
		return GainBad;
	}
	else
	{
		return GainReallyBad;
	}
}
