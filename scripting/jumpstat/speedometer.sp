#define SPEED_UPDATE_INTERVAL 10

static float g_fCurrentSpeed[MAXPLAYERS + 1];
static float g_fCurrentVerticalSpeed[MAXPLAYERS + 1];
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

        float horizontalVel[3];
        horizontalVel[0] = vel[0];
        horizontalVel[1] = vel[1];
        horizontalVel[2] = 0.0;

        float tempHorizontal = g_fCurrentSpeed[i];
        g_fCurrentSpeed[i] = GetVectorLength(horizontalVel);
        int speedDelta = RoundToFloor(g_fCurrentSpeed[i] - tempHorizontal);
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

        int horizontalSpeed = RoundToFloor(g_fCurrentSpeed[i]);

        float tempVertical = g_fCurrentVerticalSpeed[i];
        g_fCurrentVerticalSpeed[i] = FloatAbs(vel[2]);
        int verticalDelta = RoundToFloor(g_fCurrentVerticalSpeed[i] - tempVertical);
        int verticalSpeed = RoundToFloor(g_fCurrentVerticalSpeed[i]);

        for(int j = -1; j < g_iSpecListCurrentFrame[i]; j++)
        {
            int messageTarget = j == -1 ? i : g_iSpecList[i][j];

            if(!(g_iSettings[messageTarget][Bools] & SPEEDOMETER_ENABLED) || !BgsIsValidPlayer(messageTarget))
            {
                continue;
            }

            char message[256];
            char horizontalPart[128];
            char verticalPart[128];

            Format(horizontalPart, sizeof(horizontalPart), "%4i", horizontalSpeed);

            if(g_iSettings[messageTarget][Bools] & SPEEDOMETER_VELOCITY_DIFF)
            {
                if(speedDelta > 0)
                    Format(horizontalPart, sizeof(horizontalPart), "%s (+%i)", horizontalPart, speedDelta);
                else
                    Format(horizontalPart, sizeof(horizontalPart), "%s (%i)", horizontalPart, speedDelta);
            }

            Format(message, sizeof(message), "%s", horizontalPart);

            if(g_iSettings[messageTarget][Bools] & SPEEDOMETER_VERTICAL_ENABLED)
            {
                if(g_iSettings[messageTarget][Bools] & SPEEDOMETER_VELOCITY_DIFF)
                {
                    if(verticalDelta > 0)
                        Format(verticalPart, sizeof(verticalPart), "%4i (+%i)", verticalSpeed, verticalDelta);
                    else
                        Format(verticalPart, sizeof(verticalPart), "%4i (%i)", verticalSpeed, verticalDelta);
                }
                else
                {
                    Format(verticalPart, sizeof(verticalPart), "%4i", verticalSpeed);
                }

                Format(message, sizeof(message), "%s\n%s", message, verticalPart);
            }

            BgsDisplayHud(
                messageTarget,
                g_fCacheHudPositions[messageTarget][Speedometer],
                g_iBstatColors[g_iSettings[messageTarget][speedColorIdx]],
                0.2,
                GetDynamicChannel(4),
                false,
                message
            );
        }
    }
}