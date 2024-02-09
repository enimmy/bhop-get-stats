#define SPEED_UPDATE_INTERVAL 10

static float g_fCurrentSpeed[MAXPLAYERS + 1];
static int g_iTickNumber;

void Speedometer_GameTick()
{
	if(!g_hEnabledSpeedometer.BoolValue)
	{
		return;
	}

	g_iTickNumber++;

	if(g_iTickNumber % SPEED_UPDATE_INTERVAL != 0)
	{
		return;
	}

	g_iTickNumber = 0;

	for(int i = 1; i <= MaxClients; i++)
	{
		if(!IsValidClient(i))
		{
			continue;
		}

		float vel[3];
		GetEntPropVector(i, Prop_Data, "m_vecAbsVelocity", vel);
		vel[2] = 0.0;

		float temp = g_fCurrentSpeed[i];
		g_fCurrentSpeed[i] = GetVectorLength(vel);

		int speedDelta = RoundToFloor(g_fCurrentSpeed[i] - temp);

		int speedColorIdx;

		if(speedDelta > 0)
		{
			speedColorIdx = GainReallyGood;
		}
		else if (speedDelta == 0)
		{
			speedColorIdx = GainGood;
		}
		else
		{
			speedColorIdx = GainReallyBad;
		}

		int speed = RoundToFloor(g_fCurrentSpeed[i]);

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

		for(int j = -1; j < g_iSpecListCurrentFrame[i]; j++)
		{
			int messageTarget = j == -1 ? i:g_iSpecList[i][j];

			if(!(g_iSettings[messageTarget][Bools] & SPEEDOMETER_ENABLED) || IsFakeClient(messageTarget))
			{
				continue;
			}

			char sendMessage[256];

			if(g_iSettings[messageTarget][Bools] & SPEEDOMETER_VELOCITY_DIFF)
			{
				if(speedDelta > 0)
				{
					Format(sendMessage, sizeof(sendMessage), "%s (+%i)", message, speedDelta);
				}
				else
				{
					Format(sendMessage, sizeof(sendMessage), "%s (%i)", message, speedDelta);
				}
			}

			BgsDisplayHud(messageTarget, g_fCacheHudPositions[messageTarget][Speedometer], g_iBstatColors[g_iSettings[messageTarget][speedColorIdx]], 0.2, GetDynamicChannel(4), false, sendMessage);

		}
	}
}
