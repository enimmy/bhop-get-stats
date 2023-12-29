static int g_iLastOffset[MAXPLAYERS + 1];
static int g_iRepeatedOffsets[MAXPLAYERS + 1];

#define OFFSETS_MAX_FRAME 15

static int g_iOffsetHistory[MAXPLAYERS + 1][OFFSETS_MAX_FRAME];
static int g_iCurrentFrame[MAXPLAYERS + 1];

void Offset_Process(int client, int offset, bool overlap, bool nopress)
{
	if(g_bEditing[client])
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

	for(int i = 1; i < MaxClients; i++)
	{
		if(!(g_iSettings[i][Bools] & OFFSETS_ENABLED) || !BgsIsValidClient(i))
		{
			continue;
		}

		if((i == client && IsPlayerAlive(i)) || (!IsPlayerAlive(i) && BgsGetHUDTarget(i) == client))
		{
			Offset_DrawOffset(i, offset, overlap, nopress);
		}
	}
	g_iLastOffset[client] = offset;
}

void Offset_Dump(int client, int jump, float sync)
{
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
			PrintToConsole(client, "%s", message);
		}
	}
	g_iCurrentFrame[client] = 0;
}

void Offset_DrawOffset(int client, int offset, bool overlap, bool nopress)
{
	char message[256];
	Format(message, 256, "%d (%i)", offset, g_iRepeatedOffsets[client]);
	if(overlap)
	{
		Format(message, 256, "%s Overlap", message);
	}

	if(nopress)
	{
		Format(message, 256, "%s No Press", message);
	}

	int colorIdx = Offset_GetColorIdx(offset, overlap, nopress);
	int settingsIdx = g_iSettings[client][colorIdx];
	SetHudTextParams(g_fCacheHudPositions[client][Offset][X_DIM], g_fCacheHudPositions[client][Offset][Y_DIM], 0.5, g_iBstatColors[settingsIdx][0], g_iBstatColors[settingsIdx][1], g_iBstatColors[settingsIdx][2], 255, 0, 0.0, 0.0, 0.0);
	ShowHudText(client, GetDynamicChannel(2), message);
}

int Offset_GetColorIdx(int offset, bool overlap, bool nopress) {
    if(overlap || nopress || offset > 0)
	{
        return GainReallyBad;
    }

    if(offset == 0)
	{
		return GainGood;
    } else if(offset == -1)
	{
		return GainReallyGood;
    } else if(offset == -2)
	{
		return GainMeh;
	} else if(offset == -3)
	{
		return GainBad;
	} else
	{
		return GainReallyBad;
	}
}
