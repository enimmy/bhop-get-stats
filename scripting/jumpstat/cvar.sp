ConVar g_hEnabledJhud;
ConVar g_hEnabledTrainer;
ConVar g_hAllowTrainerFastMode;
ConVar g_hAllowTrainerMediumMode;
ConVar g_hEnabledOffset;
ConVar g_hEnabledSpeedometer;
ConVar g_hEnabledSsj;
ConVar g_hEnabledFjt;
ConVar g_hEnabledShowkeys;

void Cvar_Start()
{
	g_hEnabledJhud = CreateConVar("js-Enabled-jhud", "1", "Enabled /jhud command? 0 (false) or 1 (true)");
	g_hEnabledTrainer = CreateConVar("js-Enabled-trainer", "1", "Enabled /strafetrainer command? 0 (false) or 1 (true)");
	g_hAllowTrainerFastMode = CreateConVar("js-allow-trainer-fast", "0", "Enable strafe trainer to use VERY FAST updating (might be laggy) 0 or 1");
	g_hAllowTrainerMediumMode = CreateConVar("js-allow-trainer-medium", "0", "Enable strafe trainer to use pretty fast updating (might be laggy) 0 or 1");
	g_hEnabledOffset = CreateConVar("js-Enabled-offset", "1", "Enabled /offset command? 0 (false) or 1 (true)");
	g_hEnabledSpeedometer = CreateConVar("js-Enabled-speed", "1", "Enabled /speedometer command? 0 (false) or 1 (true)");
	g_hEnabledSsj = CreateConVar("js-Enabled-ssj", "1", "Enabled /ssj command? 0 (false) or 1 (true)");
	g_hEnabledFjt = CreateConVar("js-Enabled-fjt", "1", "Enabled /fjt command? 0 (false) or 1 (true)");
	g_hEnabledShowkeys = CreateConVar("js-Enabled-showkeys", "1", "Enabled /showkeys command? (false) or 1 (true)");

	AutoExecConfig();
}
