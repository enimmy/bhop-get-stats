ConVar g_hEnabledJhud;
ConVar g_hEnabledTrainer;
ConVar g_hAllowTrainerFastMode;
ConVar g_hAllowTrainerMediumMode;
ConVar g_hShowSpectatorsTrainer;
ConVar g_hEnabledOffset;
ConVar g_hEnabledSpeedometer;
ConVar g_hEnabledSsj;
ConVar g_hEnabledFjt;
ConVar g_hEnabledShowkeys;

void Cvar_Start()
{
	g_hEnabledJhud = CreateConVar("js-enabled-jhud", "1", "enable jhud? 0 or 1");
	g_hEnabledTrainer = CreateConVar("js-enabled-trainer", "1", "enable trainer? 0 or 1");
	g_hAllowTrainerFastMode = CreateConVar("js-allow-trainer-fast", "0", "enable strafe trainer to use VERY FAST updating (might be laggy) 0 or 1");
	g_hAllowTrainerMediumMode = CreateConVar("js-allow-trainer-medium", "0", "enable strafe trainer to use pretty fast updating (might be laggy) 0 or 1");
	g_hShowSpectatorsTrainer = CreateConVar("js-show-spectators-trainer", "1", "exp feature show trainer to spectators mode");
	g_hEnabledOffset = CreateConVar("js-enabled-offset", "1", "enable offsets? 0 or 1");
	g_hEnabledSpeedometer = CreateConVar("js-enabled-speedometer", "1", "enable speedometer? 0 or 1");
	g_hEnabledSsj = CreateConVar("js-enabled-ssj", "1", "enable ssj? 0 or 1");
	g_hEnabledFjt = CreateConVar("js-enabled-fjt", "1", "enable shavit fjt? 0 or 1");
	g_hEnabledShowkeys = CreateConVar("js-enabled-showkeys", "1", "enable showkeys? 0 or 1");

	AutoExecConfig();
}
