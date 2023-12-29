static ConVar g_hOverrideJhud;
static ConVar g_hOverrideTrainer;
static ConVar g_hOverrideOffset;
static ConVar g_hOverrideSpeed;
static ConVar g_hOverrideSsj;
static ConVar g_hOverrideFjt;

void Commands_Start()
{
	RegConsoleCmd("sm_js", Command_Js, "Opens the jumpstats main menu");
	RegConsoleCmd("sm_strafetrainer", Command_CheckTrainerOverride, "Opens the jumpstats main menu");
	RegConsoleCmd("sm_trainer", Command_CheckTrainerOverride, "Opens the jumpstats main menu");
	RegConsoleCmd("sm_jhud", Command_CheckJhudOverride, "Opens the jumpstats main menu");
	RegConsoleCmd("sm_offsets", Command_CheckOffsetOverride, "Opens the jumpstats main menu");
	RegConsoleCmd("sm_offset", Command_CheckOffsetOverride, "Opens the jumpstats main menu");
	RegConsoleCmd("sm_speedometer", Command_CheckSpeedOverride, "Opens the jumpstats main menu");
	RegConsoleCmd("sm_speed", Command_CheckSpeedOverride, "Opens the jumpstats main menu");
	RegConsoleCmd("sm_ssj", Command_CheckSsjOverride, "Opens the jumpstats main menu");
	RegConsoleCmd("sm_fjt", Command_CheckFjtOverride, "Opens the jumpstats main menu");

	g_hOverrideJhud = CreateConVar("js-override-jhud", "1", "Override /jhud command? 0 (false) or 1 (true)");
	g_hOverrideTrainer = CreateConVar("js-override-trainer", "1", "Override /strafetrainer command? 0 (false) or 1 (true)");
	g_hOverrideOffset = CreateConVar("js-override-offset", "1", "Override /offset command? 0 (false) or 1 (true)");
	g_hOverrideSpeed = CreateConVar("js-override-speed", "1", "Override /speedometer command? 0 (false) or 1 (true)");
	g_hOverrideSsj = CreateConVar("js-override-ssj", "1", "Override /ssj command? 0 (false) or 1 (true)");
	g_hOverrideFjt = CreateConVar("js-override-fjt", "1", "Override /fjt command? 0 (false) or 1 (true)")

	AutoExecConfig();
}

public Action Command_Js(int client, any args)
{
	if(!BgsIsValidClient(client))
	{
		return Plugin_Handled;
	}

	ShowJsMenu(client);
	return Plugin_Handled;
}

public Action Command_CheckFjtOverride(int client, any args)
{
	if(g_hOverrideFjt.IntValue)
	{
		g_iSettings[client][Bools] ^= FJT_ENABLED;
		BgsPrintToChat(client, "FJT: %s", g_iSettings[client][Bools] & FJT_ENABLED ? "On":"Off");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Command_CheckJhudOverride(int client, any args)
{
	if(g_hOverrideJhud.IntValue)
	{
		g_iSettings[client][Bools] ^= JHUD_ENABLED;
		BgsPrintToChat(client, "Jhud: %s", g_iSettings[client][Bools] & JHUD_ENABLED ? "On":"Off");
		if(g_iSettings[client][Bools] & JHUD_ENABLED)
		{
			ShowJhudSettingsMenu(client);
		}
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Command_CheckTrainerOverride(int client, any args)
{
	if(g_hOverrideTrainer.IntValue)
	{
		g_iSettings[client][Bools] ^= TRAINER_ENABLED;
		BgsPrintToChat(client, "Strafe-Trainer: %s", g_iSettings[client][Bools] & TRAINER_ENABLED ? "On":"Off");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Command_CheckSpeedOverride(int client, any args)
{
	if(g_hOverrideSpeed.IntValue)
	{
		g_iSettings[client][Bools] ^= SPEEDOMETER_ENABLED;
		BgsPrintToChat(client, "Speedometer: %s", g_iSettings[client][Bools] & SPEEDOMETER_ENABLED ? "On":"Off");
		if(g_iSettings[client][Bools] & SPEEDOMETER_ENABLED)
		{
			ShowSpeedSettingsMenu(client);
		}
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Command_CheckOffsetOverride(int client, any args)
{
	if(g_hOverrideOffset.IntValue)
	{
		g_iSettings[client][Bools] ^= OFFSETS_ENABLED;
		BgsPrintToChat(client, "Offsets: %s", g_iSettings[client][Bools] & OFFSETS_ENABLED ? "On":"Off");
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Command_CheckSsjOverride(int client, any args)
{
	if(g_hOverrideSsj.IntValue)
	{
		g_iSettings[client][Bools] ^= SSJ_ENABLED;
		BgsPrintToChat(client, "SSJ: %s", g_iSettings[client][Bools] & SSJ_ENABLED ? "On":"Off");
		if(g_iSettings[client][Bools] & SSJ_ENABLED)
		{
			ShowSSJMenu(client);
		}
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
