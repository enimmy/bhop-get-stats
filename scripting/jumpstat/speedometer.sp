#define SPEED_UPDATE_INTERVAL 10

static int g_iLastSpeedometerVel[MAXPLAYERS + 1];
static float g_fRawGain[MAXPLAYERS + 1];
static int g_iCmdNum[MAXPLAYERS + 1];

void Speedometer_Tick(int client, float fspeed, bool inbhop, float gain)
{
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
		int speed = RoundToFloor(fspeed);

		char message[256];

		if(speed < 10)
		{
			Format(message, sizeof(message), "   %i", speed);
		}
		else if(speed < 10)
		{
			Format(message, sizeof(message), "  %i", speed);
		}
		else if(speed < 1000)
		{
			Format(message, sizeof(message), " %i", speed);
		}
		else
		{
			Format(message, sizeof(message), "%i", speed);
		}

		float coeffsum = g_fRawGain[client];
		coeffsum /= SPEED_UPDATE_INTERVAL;
		coeffsum *= 100.0;
		coeffsum = RoundToFloor(coeffsum * 100.0 + 0.5) / 100.0;

		int speedIdx, gainIdx;
		gainIdx = GetGainColorIdx(coeffsum);

		if(speed > g_iLastSpeedometerVel[client])
		{
			speedIdx = GainReallyGood;
		}
		else if (speed == g_iLastSpeedometerVel[client])
		{
			speedIdx = GainGood;
		}
		else
		{
			speedIdx = GainReallyBad;
		}

		for (int i = 1; i <= MaxClients; i++)
		{
			if(!BgsIsValidClient(i) || !(g_iSettings[i][Bools] & SPEEDOMETER_ENABLED))
			{
				continue;
			}

			if((i == client && IsPlayerAlive(i)) || (BgsGetHUDTarget(i) == client && !IsPlayerAlive(i)))
			{
				int settingsIdx = g_iSettings[i][speedIdx];

				if(g_iSettings[i][Bools] & SPEEDOMETER_GAIN_COLOR && inbhop)
				{
					settingsIdx = g_iSettings[i][gainIdx];
				}

				BgsDisplayHud(i, g_fCacheHudPositions[i][Speedometer], g_iBstatColors[settingsIdx], 0.2, GetDynamicChannel(4), false, message);
			}
		}

		g_fRawGain[client] = 0.0;
		g_iLastSpeedometerVel[client] = speed;
	}
	return;
}
