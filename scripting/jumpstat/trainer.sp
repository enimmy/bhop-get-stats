#define FullPercent 0
#define BarPercent 1
#define TRAINER_FULLUPDATE_TICK_INTERVAL 13
#define TRAINER_TICK_INTERVAL 5

static float g_fTrainerPercents[MAXPLAYERS + 1][2];
static float g_fLastAverage[MAXPLAYERS + 1];
static int g_iCmdNum[MAXPLAYERS + 1];

public void Trainer_Tick(int client, int speed, bool inbhop, float gain, float jss)
{
	if(g_bEditing[client])
	{
		return;
	}
	g_iCmdNum[client]++;
	bool trainer = (g_iCmdNum[client] % TRAINER_FULLUPDATE_TICK_INTERVAL == 0 || g_iCmdNum[client] % TRAINER_TICK_INTERVAL == 0);

	if(!inbhop)
	{
		g_fTrainerPercents[client][FullPercent] = 0.0;
		g_fTrainerPercents[client][BarPercent] = 0.0;
	}
	else
	{
		g_fTrainerPercents[client][FullPercent] += jss;
		g_fTrainerPercents[client][BarPercent] += jss;

		if(trainer)
		{
			float AveragePercentage;
			bool fullUpdate = (g_iCmdNum[client] % TRAINER_FULLUPDATE_TICK_INTERVAL == 0);

			if (fullUpdate)
			{
				AveragePercentage = g_fTrainerPercents[client][FullPercent] / TRAINER_FULLUPDATE_TICK_INTERVAL;
				g_fTrainerPercents[client][FullPercent] = 0.0;
				g_fLastAverage[client] = AveragePercentage;
			}

			if (g_iCmdNum[client] % TRAINER_TICK_INTERVAL == 0)
			{
				if(!fullUpdate)
				{
					AveragePercentage = g_fTrainerPercents[client][BarPercent] / TRAINER_TICK_INTERVAL;
				}
				g_fTrainerPercents[client][BarPercent] = 0.0;
			}
			for (int i = 1; i <= MaxClients; i++)
			{
				if(!IsValidClient(i) || !(g_iSettings[client][Bools] & TRAINER_ENABLED))
				{
					continue;
				}

				if((i == client && IsPlayerAlive(i)) || (BgsGetHUDTarget(i) == client && !IsPlayerAlive(i)))
				{
					char sMessage[256];
					Trainer_GetTrainerString(client, sMessage, g_fLastAverage[client], AveragePercentage);

					int idx = GetGainColorIdx(AveragePercentage * 100);
					int settingsIdx = g_iSettings[client][idx];
					SetHudTextParams(g_fCacheHudPositions[client][Trainer][X_DIM], g_fCacheHudPositions[client][Trainer][Y_DIM], 0.1, g_iBstatColors[settingsIdx][0], g_iBstatColors[settingsIdx][1], g_iBstatColors[settingsIdx][2], 255, 0, 0.0, 0.0, 0.0);
					ShowHudText(i, GetDynamicChannel(0), sMessage); //TRAINER
				}
			}
		}
	}
	return;
}

//returns a string with the | in the middle for trainer
void Trainer_VisualisationString(char[] buffer, int maxlength, float percentage) {
	if (0.5 <= percentage <= 1.5) {
		int Spaces = RoundFloat((percentage - 0.5) / 0.05);
		for (int i = 0; i <= Spaces + 1; i++) {
			FormatEx(buffer, maxlength, "%s ", buffer);
		}

		FormatEx(buffer, maxlength, "%s|", buffer);

		for (int i = 0; i <= (21 - Spaces); i++) {
			FormatEx(buffer, maxlength, "%s ", buffer);
		}
	}
	else {
		Format(buffer, maxlength, "%s", percentage < 1.0 ? "|                   " : "                    |");
	}
}

//sMessage, number and average are different. number is on top, average is the | in the middle. they update at different rates
void Trainer_GetTrainerString(int client, char sMessage[256], float number, float average) {
	char sVisualisation[32];
	Trainer_VisualisationString(sVisualisation, sizeof(sVisualisation), average);
	if(g_fCacheHudPositions[client][Trainer][X_DIM] == -1.0)
	{
		Format(sMessage, sizeof(sMessage), "%i\n", RoundFloat(number * 100));
	}
	else
	{
		Format(sMessage, sizeof(sMessage), "              %i\n", RoundFloat(number * 100));
	}
	Format(sMessage, sizeof(sMessage), "%s══════^══════\n", sMessage);
	Format(sMessage, sizeof(sMessage), "%s %s \n", sMessage, sVisualisation);
	Format(sMessage, sizeof(sMessage), "%s══════^══════", sMessage);
}
