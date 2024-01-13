#define TRAINER_FULLUPDATE_TICK_INTERVAL 13

static float g_fTrainerPercentsNumber[MAXPLAYERS + 1];
static float g_fLastAverageNumber[MAXPLAYERS + 1];

static float g_fTrainerPercentsBarSlow[MAXPLAYERS + 1];
static float g_fTrainerPercentsBarMedium[MAXPLAYERS + 1];
static float g_fTrainerPercentsBarFast[MAXPLAYERS + 1];

static int g_iCmdNum[MAXPLAYERS + 1];

public void Trainer_Tick(int client, float speed, bool inbhop, float gain, float jss)
{
	g_iCmdNum[client]++;

	if(!inbhop)
	{
		g_fTrainerPercentsNumber[client] = 0.0;
		g_fTrainerPercentsBarSlow[client] = 0.0;
		g_fTrainerPercentsBarMedium[client] = 0.0;
		g_fTrainerPercentsBarFast[client] = 0.0;
		return;
	}
	else
	{
		g_fTrainerPercentsNumber[client] += jss;
		g_fTrainerPercentsBarSlow[client] += jss;
		g_fTrainerPercentsBarMedium[client] += jss;
		g_fTrainerPercentsBarFast[client] += jss;

		if(g_iCmdNum[client] % TRAINER_FULLUPDATE_TICK_INTERVAL == 0 ||
		g_iCmdNum[client] % g_iTrainerSpeeds[Trainer_Slow] == 0 ||
		g_iCmdNum[client] % g_iTrainerSpeeds[Trainer_Medium] == 0 ||
		g_iCmdNum[client] % g_iTrainerSpeeds[Trainer_Fast] == 0)
		{

			if(g_iCmdNum[client] % TRAINER_FULLUPDATE_TICK_INTERVAL == 0)
			{
				g_fLastAverageNumber[client] = g_fTrainerPercentsNumber[client] / TRAINER_FULLUPDATE_TICK_INTERVAL;
				g_fTrainerPercentsNumber[client] = 0.0;
			}

			float speeds[3] = { -1.0, ...};
			if (g_iCmdNum[client] % g_iTrainerSpeeds[Trainer_Slow] == 0)
			{
				speeds[Trainer_Slow] = g_fTrainerPercentsBarSlow[client] / g_iTrainerSpeeds[Trainer_Slow];
				g_fTrainerPercentsBarSlow[client] = 0.0;
			}

			if(g_iCmdNum[client] % g_iTrainerSpeeds[Trainer_Medium] == 0)
			{
				speeds[Trainer_Medium] = g_fTrainerPercentsBarMedium[client] / g_iTrainerSpeeds[Trainer_Medium];
				g_fTrainerPercentsBarMedium[client] = 0.0;
			}

			if(g_iCmdNum[client] % g_iTrainerSpeeds[Trainer_Fast] == 0)
			{
				speeds[Trainer_Fast] = g_fTrainerPercentsBarFast[client] / g_iTrainerSpeeds[Trainer_Fast];
				g_fTrainerPercentsBarFast[client] = 0.0;
			}

			PushTrainerToClients(client, speeds, g_iCmdNum[client]);
		}
	}
	return;
}

void PushTrainerToClients(int client, float speeds[3], int cmdnum)
{
	char speedMessages[sizeof(g_iTrainerSpeeds)][256];

	if(speeds[Trainer_Slow] != -1.0)
	{
		Trainer_GetTrainerString(client, speedMessages[Trainer_Slow], g_fLastAverageNumber[client], speeds[Trainer_Slow]);
	}

	if(speeds[Trainer_Medium] != -1.0)
	{
		Trainer_GetTrainerString(client, speedMessages[Trainer_Medium], g_fLastAverageNumber[client], speeds[Trainer_Medium]);
	}

	if(speeds[Trainer_Fast] != -1.0)
	{
		Trainer_GetTrainerString(client, speedMessages[Trainer_Fast], g_fLastAverageNumber[client], speeds[Trainer_Fast]);
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		if(!(g_iSettings[i][Bools] & TRAINER_ENABLED) || !BgsIsValidClient(i))
		{
			continue;
		}

		int trainerSpeedIdx = g_iSettings[i][TrainerSpeed];
		int trainerSpeed = g_iTrainerSpeeds[trainerSpeedIdx];

		if(cmdnum % trainerSpeed != 0)
		{
			continue;
		}

		if((i == client && IsPlayerAlive(i)) || (BgsGetHUDTarget(i) == client && !IsPlayerAlive(i)))
		{
			float avg = speeds[trainerSpeedIdx] * 100;
			int idx = GetGainColorIdx(avg);
			if(avg > 100.0 && !(g_iSettings[i][Bools] & TRAINER_STRICT))
			{
				if(avg <= 105.0)
				{
					idx = GainGood;
				}
				else if(avg <= 110.0)
				{
					idx = GainMeh;
				}
				else if(avg <= 115.0)
				{
					idx = GainBad;
				}
				else
				{
					idx = GainReallyBad;
				}
			}

			float holdTime = trainerSpeed / (BgsTickRate() * 1.0) + 0.05;
			BgsDisplayHud(i, g_fCacheHudPositions[i][Trainer], g_iBstatColors[g_iSettings[i][idx]], holdTime, GetDynamicChannel(0), false, speedMessages[trainerSpeedIdx])
		}
	}
}

//message, number and average are different. number is on top, average is the | in the middle. they update at different rates
void Trainer_GetTrainerString(int client, char message[256], float number, float average)
{
	char sVisualisation[32];
	Trainer_VisualisationString(sVisualisation, sizeof(sVisualisation), average);
	if(g_fCacheHudPositions[client][Trainer][X_DIM] == -1.0)
	{
		Format(message, sizeof(message), "%i\n", RoundFloat(number * 100));
	}
	else
	{
		Format(message, sizeof(message), "              %i\n", RoundFloat(number * 100));
	}
	Format(message, sizeof(message), "%s══════^══════\n", message);
	Format(message, sizeof(message), "%s %s \n", message, sVisualisation);
	Format(message, sizeof(message), "%s══════^══════", message);
}

void Trainer_VisualisationString(char[] buffer, int maxlength, float percentage)
{
	if (0.5 <= percentage <= 1.5)
	{
		int Spaces = RoundFloat((percentage - 0.5) / 0.05);
		for (int i = 0; i <= Spaces + 1; i++)
		{
			FormatEx(buffer, maxlength, "%s ", buffer);
		}

		FormatEx(buffer, maxlength, "%s|", buffer);

		for (int i = 0; i <= (21 - Spaces); i++)
		{
			FormatEx(buffer, maxlength, "%s ", buffer);
		}
	}
	else
	{
		Format(buffer, maxlength, "%s", percentage < 1.0 ? "|                   " : "                    |");
	}
}
