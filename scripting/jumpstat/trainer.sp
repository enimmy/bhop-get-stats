#define TRAINER_FULLUPDATE_TICK_INTERVAL 13
#define TRAINER_SIZE 13 // needs to be odd (even numbers of spaces around middle)
#define TRAINER_MIN_GAIN 0.3 // is also max, 0.3 means trainer range is 0.3 - 1.7
#define TRAINER_GOAL_SYNC_MIN 0.8
#define TRAINER_GOAL_SYNC_MAX 1.2

static float g_fTrainerPercentsNumber[MAXPLAYERS + 1];
static float g_fLastAverageNumber[MAXPLAYERS + 1];

static float g_fTrainerPercentsBarSlow[MAXPLAYERS + 1];
static float g_fTrainerPercentsBarMedium[MAXPLAYERS + 1];
static float g_fTrainerPercentsBarFast[MAXPLAYERS + 1];

int g_iTrainerSpeeds[3];

static int g_iCmdNum[MAXPLAYERS + 1];

void Trainer_Start()
{
	g_iTrainerSpeeds[Trainer_Slow] = RoundToFloor(BgsTickRate() * (TRAINER_FULLUPDATE_TICK_INTERVAL / 100.0));
	g_iTrainerSpeeds[Trainer_Medium] = RoundToFloor(BgsTickRate() * 0.09);
	g_iTrainerSpeeds[Trainer_Fast] = RoundToFloor(BgsTickRate() * 0.05);
}

public void Trainer_Tick(int client, float speed, bool inbhop, float gain, float jss)
{
	if(!g_hEnabledTrainer.BoolValue)
	{
		return;
	}

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

		if(
		g_iCmdNum[client] % TRAINER_FULLUPDATE_TICK_INTERVAL == 0 ||
		g_iCmdNum[client] % g_iTrainerSpeeds[Trainer_Slow] == 0 ||
		(g_iCmdNum[client] % g_iTrainerSpeeds[Trainer_Medium] == 0 && g_hAllowTrainerMediumMode.BoolValue) ||
		(g_iCmdNum[client] % g_iTrainerSpeeds[Trainer_Fast] == 0 && g_hAllowTrainerFastMode.BoolValue)
		)
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

			if(g_iCmdNum[client] % g_iTrainerSpeeds[Trainer_Medium] == 0 && g_hAllowTrainerMediumMode.BoolValue)
			{
				speeds[Trainer_Medium] = g_fTrainerPercentsBarMedium[client] / g_iTrainerSpeeds[Trainer_Medium];
				g_fTrainerPercentsBarMedium[client] = 0.0;
			}

			if(g_iCmdNum[client] % g_iTrainerSpeeds[Trainer_Fast] == 0 && g_hAllowTrainerFastMode.BoolValue)
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
		Trainer_GetTrainerString(speedMessages[Trainer_Slow], g_fLastAverageNumber[client], speeds[Trainer_Slow]);
	}

	if(speeds[Trainer_Medium] != -1.0)
	{
		Trainer_GetTrainerString(speedMessages[Trainer_Medium], g_fLastAverageNumber[client], speeds[Trainer_Medium]);
	}

	if(speeds[Trainer_Fast] != -1.0)
	{
		Trainer_GetTrainerString(speedMessages[Trainer_Fast], g_fLastAverageNumber[client], speeds[Trainer_Fast]);
	}

	for (int idx = -1; idx < g_iSpecListCurrentFrame[client]; idx++)
	{

		int messageTarget = idx == -1 ? client:g_iSpecList[client][idx];

		if(!(g_iSettings[messageTarget][Bools] & TRAINER_ENABLED) || !BgsIsValidPlayer(messageTarget))
		{
			continue;
		}

		int trainerSpeedIdx = g_iSettings[messageTarget][TrainerSpeed];
		int trainerSpeed = g_iTrainerSpeeds[trainerSpeedIdx];

		if(cmdnum % trainerSpeed != 0)
		{
			continue;
		}

		float avg = speeds[trainerSpeedIdx] * 100;
		int cidx = GetPercentageColorIdx(avg, (g_iSettings[messageTarget][Bools] & TRAINER_STRICT) > 0);

		float holdTime = trainerSpeed / (BgsTickRate() * 1.0) + 0.05;
		g_fCacheHudPositions[messageTarget][Trainer][X_DIM] = -1.0;
		BgsDisplayHud(messageTarget, g_fCacheHudPositions[messageTarget][Trainer], g_iBstatColors[g_iSettings[messageTarget][cidx]], holdTime, GetDynamicChannel(0), false, speedMessages[trainerSpeedIdx]);
	}
}

//message, number and average are different. number is on top, average is the | in the middle. they update at different rates
void Trainer_GetTrainerString(char message[256], float number, float average)
{
	Format(message, sizeof(message), "%i\n", RoundFloat(number * 100));

	int center = GetTrainerIndex(1.0, TRAINER_SIZE);

	for (int i = 0; i < TRAINER_SIZE; i++)
	{
		if (i != center)
		{
			Format(message, sizeof(message), "%s\xE2\x94\x80", message); //u+2500
		}
		else
		{
			Format(message, sizeof(message), "%s|", message);
		}
	}

	char sVisualisation[56]; // todo: proper value here so it doesnt overflow ((TRAINER_SIZE + 1) * 2) or smth
	Trainer_VisualisationString(sVisualisation, sizeof(sVisualisation), average, TRAINER_SIZE * 2);
	Format(message, sizeof(message), "%s\n %s \n", message, sVisualisation);

	for (int i = 0; i < TRAINER_SIZE; i++)
	{
		if (i != center)
		{
			Format(message, sizeof(message), "%s\xE2\x94\x80", message);
		}
		else
		{
			Format(message, sizeof(message), "%s|", message);
		}
	}
}

void Trainer_VisualisationString(char[] buffer, int bufferSize, float percentage, int size)
{
	float remainder;
	int index = GetTrainerPreciseIndex(percentage, size, remainder);

	for (int i = 0; i < size; i++)
	{
		if (i != index)
		{
			FormatEx(buffer, bufferSize, "%s ", buffer);
		}
		else
		{
			if (remainder >= 0.5)
			{
				FormatEx(buffer, bufferSize, "%s⎹", buffer); //U+23B9
			}
			else
			{
				FormatEx(buffer, bufferSize, "%s⎸", buffer); //U+23B8
			}
		}
	}
}

float ClampPos(float pos, int maxIndex)
{
	float maxPos = float(maxIndex);

	if (pos < 0.0)
	{
		pos = 0.0;
	}
	if (pos >= maxPos)
	{
		pos = maxPos;
	}

	return pos;
}

float GetTrainerPos(float percentage, int size)
{
	int maxIndex = size - 1;

	float minPercent = TRAINER_MIN_GAIN;
	float maxPercent = 1.0 + (1.0 - TRAINER_MIN_GAIN);

	percentage = (percentage - minPercent) / (maxPercent - minPercent);

	return ClampPos(percentage * maxIndex, maxIndex);
}

int GetTrainerIndex(float percentage, int size)
{
	float pos = GetTrainerPos(percentage, size);
	return RoundFloat(pos);
}

int GetTrainerPreciseIndex(float percentage, int size, float& remainder)
{
	float pos = GetTrainerPos(percentage, size);
	remainder = pos % 1.0;
	return RoundToFloor(pos);
}
