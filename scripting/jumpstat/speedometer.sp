#define SPEED_UPDATE_INTERVAL 10

static int g_iLastSpeedometerVel[MAXPLAYERS + 1];
static float g_fRawGain[MAXPLAYERS + 1];
static int g_iCmdNum[MAXPLAYERS + 1];

void Speedometer_Tick(int client, int speed, bool inbhop, float gain)
{
	if(g_bEditing[client])
	{
		return;
	}
	g_iCmdNum[client]++;
	bool speedometer = (g_iCmdNum[client] % SPEED_UPDATE_INTERVAL == 0);

	if(!inbhop)
	{
		g_fRawGain[client] = 0.0;
		if(speedometer)
		{
			g_iCmdNum[client] = 0;
		}
	}
	else
	{
		g_fRawGain[client] += gain;
	}

	if(speedometer)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(!IsValidClient(i) || !(g_iSettings[i][Bools] & SPEEDOMETER_ENABLED))
			{
				continue;
			}

			if((i == client && IsPlayerAlive(i)) || (BgsGetHUDTarget(i) == client && !IsPlayerAlive(i)))
			{
				int idx;
				char sMessage[256];
				Format(sMessage, sizeof(sMessage), "%i", speed);
				float coeffsum = g_fRawGain[client];
				coeffsum /= SPEED_UPDATE_INTERVAL;
				coeffsum *= 100.0;
				coeffsum = RoundToFloor(coeffsum * 100.0 + 0.5) / 100.0;
				if(g_iSettings[i][Bools] & SPEEDOMETER_GAIN_COLOR && inbhop)
				{
					idx = GetGainColorIdx(coeffsum);
				}
				else
				{
					if(speed > g_iLastSpeedometerVel[client])
					{
						idx = GainReallyGood;
					}
					else if (speed == g_iLastSpeedometerVel[client])
					{
						idx = GainGood;
					}
					else
					{
						idx = GainReallyBad;
					}
				}

				int settingsIdx = g_iSettings[client][idx];
				SetHudTextParams(g_fCacheHudPositions[client][Speed][X_DIM], g_fCacheHudPositions[client][Speed][Y_DIM], 0.2, g_iBstatColors[settingsIdx][0], g_iBstatColors[settingsIdx][1], g_iBstatColors[settingsIdx][2], 255, 0, 0.0, 0.0, 0.0);
				ShowHudText(i, GetDynamicChannel(4), sMessage);
			}
		}

		g_fRawGain[client] = 0.0;
		g_iLastSpeedometerVel[client] = speed;
	}
	return;
}
