ConVar g_hOverrideJhud;
ConVar g_hOverrideTrainer;
ConVar g_hOverrideOffset;
ConVar g_hOverrideSpeed;
ConVar g_hOverrideSsj;

void Commands_Start()
{
	RegConsoleCmd("sm_js", Command_Js, "Opens the bhud main menu");
	RegConsoleCmd("sm_strafetrainer", Command_CheckTrainerOverride, "Opens the bhud main menu");
	RegConsoleCmd("sm_trainer", Command_CheckTrainerOverride, "Opens the bhud main menu");
	RegConsoleCmd("sm_jhud", Command_CheckJhudOverride, "Opens the bhud main menu");
	RegConsoleCmd("sm_offsets", Command_CheckOffsetOverride, "Opens the bhud main menu");
	RegConsoleCmd("sm_offset", Command_CheckOffsetOverride, "Opens the bhud main menu");
	RegConsoleCmd("sm_speedometer", Command_CheckSpeedOverride, "Opens the bhud main menu");
	RegConsoleCmd("sm_speed", Command_CheckSpeedOverride, "Opens the bhud main menu");
	RegConsoleCmd("sm_ssj", Command_CheckSsjOverride, "Opens the bhud main menu");

	g_hOverrideJhud 			= CreateConVar("js-override-jhud", "1", "Override /jhud command? 0 (false) or 1 (true)");
	g_hOverrideTrainer 			= CreateConVar("js-override-trainer", "1", "Override /strafetrainer command? 0 (false) or 1 (true)");
	g_hOverrideOffset 			= CreateConVar("js-override-offset", "1", "Override /offset command? 0 (false) or 1 (true)");
	g_hOverrideSpeed			= CreateConVar("js-override-speed", "1", "Override /speedometer command? 0 (false) or 1 (true)");
	g_hOverrideSsj 				= CreateConVar("js-override-ssj", "1", "Override /ssj command? 0 (false) or 1 (true)");
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

public Action Command_CheckJhudOverride(int client, any args)
{
	if(g_hOverrideJhud.IntValue)
	{
		Command_Js(client, 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_CheckTrainerOverride(int client, any args)
{
	if(g_hOverrideTrainer.IntValue)
	{
		Command_Js(client, 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_CheckSpeedOverride(int client, any args)
{
	if(g_hOverrideSpeed.IntValue)
	{
		Command_Js(client, 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_CheckOffsetOverride(int client, any args)
{
	if(g_hOverrideOffset.IntValue)
	{
		Command_Js(client, 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_CheckSsjOverride(int client, any args)
{
	if(g_hOverrideSsj.IntValue)
	{
		Command_Js(client, 0);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
