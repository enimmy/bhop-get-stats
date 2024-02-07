#define SPEED_UPDATE_INTERVAL 10

static int g_iLastSpeedometerVel[MAXPLAYERS + 1];
static int g_iCmdNum[MAXPLAYERS + 1];

void Speedometer_Tick(int client, float fspeed)
{
	if(!g_hEnabledSpeedometer.BoolValue)
	{
		return;
	}

	g_iCmdNum[client]++;
	bool speedometer = (g_iCmdNum[client] % SPEED_UPDATE_INTERVAL == 0);

	if(speedometer)
	{
		g_iCmdNum[client] = 0;
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
			if(speedDelta > 0)
			{
				Format(message, sizeof(message), "%s (+%i)", message, speedDelta);
			}
			else
			{
				Format(message, sizeof(message), "%s (%i)", message, speedDelta);
			}
		}

		int speedIdx;

		if(speedDelta > 0)
		{
			speedIdx = GainReallyGood;
		}
		else if (speedDelta == 0)
		{
			speedIdx = GainGood;
		}
		else
		{
			speedIdx = GainReallyBad;
		}

		for (int idx = -1; idx < g_iSpecListCurrentFrame[client]; idx++)
		{

			int messageTarget = idx == -1 ? client:idx;
			if(!(g_iSettings[messageTarget][Bools] & SPEEDOMETER_ENABLED))
			{
				continue;
			}

			BgsDisplayHud(messageTarget, g_fCacheHudPositions[messageTarget][Speedometer], g_iBstatColors[g_iSettings[messageTarget][speedIdx]], 0.2, GetDynamicChannel(4), false, message);
		}

		g_iLastSpeedometerVel[client] = speed;
	}
	return;
}
