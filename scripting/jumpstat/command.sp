
void Commands_Start()
{
	RegConsoleCmd("sm_js", Command_Js, "Opens the jumpstats main menu");
	RegConsoleCmd("sm_strafetrainer", Command_CheckTrainerEnabled, "Opens the jumpstats main menu");
	RegConsoleCmd("sm_trainer", Command_CheckTrainerEnabled, "Opens the jumpstats main menu");
	RegConsoleCmd("sm_jhud", Command_CheckJhudEnabled, "Opens the jumpstats main menu");
	RegConsoleCmd("sm_offsets", Command_CheckOffsetEnabled, "Opens the jumpstats main menu");
	RegConsoleCmd("sm_offset", Command_CheckOffsetEnabled, "Opens the jumpstats main menu");
	RegConsoleCmd("sm_speedometer", Command_CheckSpeedEnabled, "Opens the jumpstats main menu");
	RegConsoleCmd("sm_speed", Command_CheckSpeedEnabled, "Opens the jumpstats main menu");
	RegConsoleCmd("sm_ssj", Command_CheckSsjEnabled, "Opens the jumpstats main menu");
	RegConsoleCmd("sm_fjt", Command_CheckFjtEnabled, "Opens the jumpstats main menu");
	RegConsoleCmd("sm_showkeys", Command_JsShowkeys, "Oopens the jumopstats showkeys menu");
}

public Action Command_Js(int client, any args)
{
	ShowJsMenu(client);
	return Plugin_Handled;
}

public Action Command_CheckFjtEnabled(int client, any args)
{
	if(g_hEnabledFjt.IntValue)
	{
		ShowFjtSettingsMenu(client);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Command_CheckJhudEnabled(int client, any args)
{
	if(g_hEnabledJhud.IntValue)
	{
		ShowJhudSettingsMenu(client);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Command_CheckTrainerEnabled(int client, any args)
{
	if(g_hEnabledTrainer.IntValue)
	{
		ShowTrainerSettingsMenu(client);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Command_CheckSpeedEnabled(int client, any args)
{
	if(g_hEnabledSpeedometer.IntValue)
	{
		ShowSpeedSettingsMenu(client);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Command_CheckOffsetEnabled(int client, any args)
{
	if(g_hEnabledOffset.IntValue)
	{
		ShowOffsetsMenu(client);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Command_CheckSsjEnabled(int client, any args)
{
	if(g_hEnabledSsj.IntValue)
	{
		ShowSSJMenu(client);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

public Action Command_JsShowkeys(int client, any args)
{
	if(g_hEnabledShowkeys.IntValue)
	{
		if(BgsShavitLoaded())
		{
			BgsPrintToChat(client, "%sWARNING: %sJumpStats showkeys can ONLY be enabled from the menu on the left. "
							..."You can turn off shavit-showkeys by toggling it again with /showkeys command, or in /hud.", g_sBstatColorsHex[Red], g_sBstatColorsHex[White]);
		}
		ShowShowkeysSettingsMenu(client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}