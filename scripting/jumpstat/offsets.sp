static int g_iLastOffset[MAXPLAYERS + 1];
static int g_iRepeatedOffsets[MAXPLAYERS + 1];

static offset_t g_otDelayingOffset[MAXPLAYERS + 1];
static int g_bOffsetDelayed[MAXPLAYERS + 1];

enum struct offset_t
{
	int offset;
	bool overlap;
	bool nopress;
}

#define OFFSETS_MAX_FRAME 15

int g_iOffsetHistory[MAXPLAYERS + 1][OFFSETS_MAX_FRAME];
int g_iCurrentFrame[MAXPLAYERS + 1];


void Offset_Tick(int client, float speed, bool inbhop, float gain, float jss)
{
	if(!inbhop)
	{
		return;
	}

	if(g_bOffsetDelayed[client])
	{
		Offset_Delay_Process(client, g_otDelayingOffset[client].offset, g_otDelayingOffset[client].overlap, g_otDelayingOffset[client].nopress, jss);
	}

	g_bOffsetDelayed[client] = false;
}

void Offset_Process(int client, int offset, bool overlap, bool nopress)
{
	g_otDelayingOffset[client].offset = offset;
	g_otDelayingOffset[client].nopress = nopress;
	g_otDelayingOffset[client].overlap = overlap;
	g_bOffsetDelayed[client] = true;
}

void Offset_Delay_Process(int client, int offset, bool overlap, bool nopress, float jss)
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
			Offset_DrawOffset(i, offset, g_iRepeatedOffsets[client], overlap, nopress, jss)
		}
	}
	g_iLastOffset[client] = offset;
}

void Offset_DrawOffset(int client, int offset, int repeats, bool overlap, bool nopress, float tickjss)
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

		if(offset == 0 && tickjss <= 0.80)
		{
			colorIdx = GainGood;
		}

		if(offset == -2 && tickjss >= 0.80)
		{
			colorIdx = GainGood;
		}
	}

	int settingsIdx = g_iSettings[client][colorIdx];
	SetHudTextParams(g_fCacheHudPositions[client][Offset][X_DIM], g_fCacheHudPositions[client][Offset][Y_DIM], 0.5, g_iBstatColors[settingsIdx][0], g_iBstatColors[settingsIdx][1], g_iBstatColors[settingsIdx][2], 255, 0, 0.0, 0.0, 0.0);
	ShowHudText(client, GetDynamicChannel(2), message);
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

int Offset_GetColorIdx(int offset) {
    if(offset > 0)
	{
        return GainReallyBad;
    }

    if(offset == 0)
	{
		return GainMeh;
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
