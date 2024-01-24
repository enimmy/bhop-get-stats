#define SPEED_UPDATE_INTERVAL 10

static int g_iLastSpeedometerVel[MAXPLAYERS + 1];
static int g_iCmdNum[MAXPLAYERS + 1];

void Speedometer_Tick(int client, float fspeed, bool inbhop)
{
	g_iCmdNum[client]++;
	bool speedometer = (g_iCmdNum[client] % SPEED_UPDATE_INTERVAL == 0);

	if(!inbhop)
	{
		g_iCmdNum[client] = 0;
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

		int speedDelta = speed - g_iLastSpeedometerVel[client];

		if(g_iSettings[client][Bools] & SPEEDOMETER_VELOCITY_DIFF)
		{
			Format(message, sizeof(message), "%s (%i)", speedDelta);
		}

		int speedIdx;

		if(speedDelta > 0)
		{
			speedIdx = GainReallyGood;
		}
		else if (speed == 0)
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
				BgsDisplayHud(i, g_fCacheHudPositions[i][Speedometer], g_iBstatColors[g_iSettings[i][speedIdx]], 0.2, GetDynamicChannel(4), false, message);
			}
		}

		g_iLastSpeedometerVel[client] = speed;
	}
	return;
}
