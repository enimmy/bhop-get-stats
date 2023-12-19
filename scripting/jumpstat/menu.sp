int g_iEditGain[MAXPLAYERS + 1]; //Cache for menu idx, keeps track of which gain catergory (50-, 50-60, etc) the player wants to edit the color of
int g_iEditHud[MAXPLAYERS + 1]; //Cache for menu idx, keeps track of which hud (jhud, offset, etc) the player wants to edit the position of

bool g_bEditing[MAXPLAYERS + 1]; //Setting to true enables "edit mode", see OnPlayerRunCmd

void Menu_CheckEditMode(int client, int& buttons, int mouse[2]) {
	if(!g_bEditing[client])
	{
		return;
	}
	SetEntProp(client, Prop_Data, "m_fFlags",  GetEntProp(client, Prop_Data, "m_fFlags") |  FL_ATCONTROLS );
	bool edit = true;
	bool up = false;
	int editDim;
	if(buttons & IN_MOVERIGHT)
	{
		editDim = Positions_X;
	}
	else if(buttons & IN_MOVELEFT)
	{
		editDim = Positions_X;
		up = true;
	}
	else if(buttons & IN_FORWARD)
	{
		up = true;
		editDim = Positions_Y;
	}
	else if(buttons & IN_BACK)
	{
		editDim = Positions_Y;
	}
	else
	{
		edit = false;
	}
	if(edit)
	{
		EditHudPosition(client, editDim, up);
	}
	SetEntityMoveType(client, MOVETYPE_NONE);
	return;
}

void EditHudPosition(int client, int editDim, bool up)
{
	int get4;
	if(up)
	{
		get4 = GetIntSubValue(g_iSettings[client][editDim], g_iEditHud[client], POS_INT_BITS, POS_BINARY_MASK) - 1;
	}
	else
	{
		get4 = GetIntSubValue(g_iSettings[client][editDim], g_iEditHud[client], POS_INT_BITS, POS_BINARY_MASK) + 1;
	}

	if(get4 < POSITION_MIN_INT)
	{
		get4 = POSITION_MAX_INT;
	}

	if(get4 > POSITION_MAX_INT || get4 < POSITION_MIN_INT)
	{
		get4 = POSITION_MIN_INT;
	}

	SetIntSubValue(g_iSettings[client][editDim], get4, g_iEditHud[client], POS_INT_BITS, POS_BINARY_MASK);
	PushPosCache(client);
	SetHudTextParams(g_fCacheHudPositions[client][g_iEditHud[client]][X_DIM], g_fCacheHudPositions[client][g_iEditHud[client]][Y_DIM], 1.0, g_iBstatColors[GainGood][0], g_iBstatColors[GainGood][1], g_iBstatColors[GainGood][2], 255, 0, 0.0, 0.0, 0.0);
	ShowHudText(client, GetDynamicChannel(0), g_sHudStrs[g_iEditHud[client]]);
}

void ShowJsMenu(int client)
{
	Menu menu = new Menu(Js_Select);
	SetMenuTitle(menu, "JumpStats - Nimmy\n \n");
	AddMenuItem(menu, "chat", "Chat");
	AddMenuItem(menu, "hud", "Hud");
	AddMenuItem(menu, "colors", "Colors");
	AddMenuItem(menu, "reset", "Reset Settings");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int Js_Select(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));

		if(StrEqual(info, "chat"))
		{
			ShowSSJMenu(client);
			return 0;
		}
		else if(StrEqual(info, "hud"))
		{
			ShowBHUDMenu(client);
			return 0;
		}
		else if(StrEqual(info, "colors"))
		{
			ShowColorsMenu(client);
			return 0;
		}
		else if(StrEqual(info, "reset"))
		{
			SetDefaults(client);
		}
		ShowJsMenu(client);
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void ShowSSJMenu(int client)
{
	Menu menu = new Menu(Ssj_Select);
	menu.ExitBackButton = true;
	SetMenuTitle(menu, "Chat Jump Stats \n \n");
	AddMenuItem(menu, "enSsj", (g_iSettings[client][Bools] & SSJ_ENABLED) ? "[x] Enabled":"[ ] Enabled");
	AddMenuItem(menu, "enRepeat", (g_iSettings[client][Bools] & SSJ_REPEAT) ? "[x] Repeat":"[ ] Repeat");

	char sMessage[256];
	Format(sMessage, sizeof(sMessage), "Usage: %i",g_iSettings[client][Usage]);
	AddMenuItem(menu, "enUsage", sMessage);

	AddMenuItem(menu, "enGain", (g_iSettings[client][Bools] & SSJ_GAIN) ? "[x] Gain":"[ ] Gain");
	AddMenuItem(menu, "enGainColor", (g_iSettings[client][Bools] & SSJ_GAIN_COLOR) ? "[x] Gain Colors":"[ ] Gain Color");
	AddMenuItem(menu, "enSync", (g_iSettings[client][Bools] & SSJ_SYNC) ? "[x] Sync":"[ ] Sync");
	AddMenuItem(menu, "enStrafes", (g_iSettings[client][Bools] & SSJ_STRAFES) ? "[x] Strafes":"[ ] Strafes");
	AddMenuItem(menu, "enEff", (g_iSettings[client][Bools] & SSJ_EFFICIENCY) ? "[x] Efficiency":"[ ] Efficiency");
	AddMenuItem(menu, "enHeight", (g_iSettings[client][Bools] & SSJ_HEIGHTDIFF) ? "[x] Height Difference":"[ ] Height Difference");
	AddMenuItem(menu, "enTime", (g_iSettings[client][Bools] & SSJ_SHAVIT_TIME) ? "[x] Time":"[ ] Time");
	AddMenuItem(menu, "enTimeDelta", (g_iSettings[client][Bools] & SSJ_SHAVIT_TIME_DELTA) ? "[x] Time Difference":"[ ] Time Difference");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int Ssj_Select(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));

		if(StrEqual(info, "enSsj"))
		{
			g_iSettings[client][Bools] ^= SSJ_ENABLED;
		}
		else if(StrEqual(info, "enRepeat"))
		{
			g_iSettings[client][Bools] ^= SSJ_REPEAT;
		}
		else if(StrEqual(info, "enUsage"))
		{
			g_iSettings[client][Usage]++; //cycle
			if(g_iSettings[client][Usage] > 16) {
				g_iSettings[client][Usage] = 1;
			}
			BgsSetCookie(client, g_hSettings[Usage], g_iSettings[client][Usage]);
		}
		else if(StrEqual(info, "enGain"))
		{
			g_iSettings[client][Bools] ^= SSJ_GAIN;
		}
		else if(StrEqual(info, "enGainColor"))
		{
			g_iSettings[client][Bools] ^= SSJ_GAIN_COLOR;
		}
		else if(StrEqual(info, "enSync"))
		{
			g_iSettings[client][Bools] ^= SSJ_SYNC;
		}
		else if(StrEqual(info, "enStrafes"))
		{
			g_iSettings[client][Bools] ^= SSJ_STRAFES;
		}
		else if(StrEqual(info, "enEff"))
		{
			g_iSettings[client][Bools] ^= SSJ_EFFICIENCY;
		}
		else if(StrEqual(info, "enHeight"))
		{
			g_iSettings[client][Bools] ^= SSJ_HEIGHTDIFF;
		}
		else if(StrEqual(info, "enTime"))
		{
			g_iSettings[client][Bools] ^= SSJ_SHAVIT_TIME;
		}
		else if(StrEqual(info, "enTimeDelta"))
		{
			g_iSettings[client][Bools] ^= SSJ_SHAVIT_TIME_DELTA;
		}
		BgsSetCookie(client, g_hSettings[Bools], g_iSettings[client][Bools]);
		ShowSSJMenu(client);
	}
	else if(action == MenuAction_Cancel)
	{
		ShowJsMenu(client);
		return 0;
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void ShowBHUDMenu(int client)
{
	Menu menu = new Menu(BHUD_Select);
	menu.ExitBackButton = true;
	SetMenuTitle(menu, "HUD Jump Stats\n \n");
	AddMenuItem(menu, "enJhud", (g_iSettings[client][Bools] & JHUD_ENABLED) ? "[x] Jhud":"[ ] Jhud");
	AddMenuItem(menu, "enTrainer", (g_iSettings[client][Bools] & TRAINER_ENABLED) ? "[x] Trainer":"[ ] Trainer");
	AddMenuItem(menu, "enOffset", (g_iSettings[client][Bools] & OFFSETS_ENABLED) ? "[x] Offsets":"[ ] Offsets");
	AddMenuItem(menu, "enSpeed", (g_iSettings[client][Bools] & SPEEDOMETER_ENABLED) ? "[x] Speedometer":"[ ] Speedometer");
	AddMenuItem(menu, "jhudSettings", "JHUD Settings");
	AddMenuItem(menu, "speedSettings", "Speedometer Settings");
	AddMenuItem(menu, "posEditor", "Hud Positions Editor");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int BHUD_Select(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));

		if(StrEqual(info, "enJhud"))
		{
			g_iSettings[client][Bools] ^= JHUD_ENABLED;
		}
		else if(StrEqual(info, "enTrainer"))
		{
			g_iSettings[client][Bools] ^= TRAINER_ENABLED;
		}
		else if(StrEqual(info, "enOffset"))
		{
			g_iSettings[client][Bools] ^= OFFSETS_ENABLED;
		}
		else if(StrEqual(info, "enSpeed"))
		{
			g_iSettings[client][Bools] ^= SPEEDOMETER_ENABLED;
		}
		else if(StrEqual(info, "jhudSettings"))
		{
			ShowJhudSettingsMenu(client);
			return 0;
		}
		else if(StrEqual(info, "speedSettings"))
		{
			ShowSpeedSettingsMenu(client);
			return 0;
		}
		else if(StrEqual(info, "posEditor"))
		{
			ShowPosEditMenu(client);
			return 0;
		}
		BgsSetCookie(client, g_hSettings[Bools], g_iSettings[client][Bools]);
		ShowBHUDMenu(client);
	}
	else if(action == MenuAction_Cancel)
	{
		ShowJsMenu(client);
		return 0;
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void ShowColorsMenu(int client)
{
	Menu menu = new Menu(Colors_Callback);
	menu.ExitBackButton = true;
	SetMenuTitle(menu, "Colors Settings");

	int editing = g_iEditGain[client];
	if(editing == GainReallyBad)
	{
		AddMenuItem(menu, "editing", "< Very Bad >");
	}
	else if (editing == GainBad)
	{
		AddMenuItem(menu, "editing", "< Bad >");
	}
	else if (editing == GainMeh)
	{
		AddMenuItem(menu, "editing", "< Gain: Okay >");
	}
	else if (editing == GainGood)
	{
		AddMenuItem(menu, "editing", "< Gain: Good >");
	}
	else if (editing == GainReallyGood)
	{
		AddMenuItem(menu, "editing", "< Very Good >");
	}

	AddMenuItem(menu, "editcolor", g_sBstatColorStrs[g_iSettings[client][editing]]);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int Colors_Callback(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));

		if(StrEqual(info, "editing"))
		{
			g_iEditGain[client]++;
			if(g_iEditGain[client] > COLOR_SETTINGS_END_IDX)
			{
				g_iEditGain[client] = COLOR_SETTINGS_START_IDX;
			}

		}
		else if(StrEqual(info, "editcolor"))
		{
			int editing = g_iEditGain[client];
			g_iSettings[client][editing]++;
			if(g_iSettings[client][editing] > 8)
			{
				g_iSettings[client][editing] = 0;
			}

			BgsSetCookie(client, g_hSettings[g_iEditGain[client]], g_iSettings[client][editing]);
		}
		ShowColorsMenu(client);
	}
	else if(action == MenuAction_Cancel)
	{
		ShowJsMenu(client);
		return 0;
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

void ShowJhudSettingsMenu(int client)
{
	Menu menu = new Menu(Jhud_SettingSelect);
	menu.ExitBackButton = true;
	SetMenuTitle(menu, "JHUD SETTINGS\n \n");
	AddMenuItem(menu, "strafespeed", (g_iSettings[client][Bools] & JHUD_JSS) ? "[x] Jss":"[ ] Jss");
	AddMenuItem(menu, "sync", (g_iSettings[client][Bools] & JHUD_SYNC) ? "[x] Sync":"[ ] Sync");
	AddMenuItem(menu, "extraspeeds", (g_iSettings[client][Bools] & JHUD_EXTRASPEED) ? "[x] Extra speeds":"[ ] Extra speeds");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void ShowSpeedSettingsMenu(int client)
{
	Menu menu = new Menu(Speedometer_SettingSelect);
	menu.ExitBackButton = true;
	SetMenuTitle(menu, "SPEED SETTINGS\n \n");
	AddMenuItem(menu, "speedGainColor", (g_iSettings[client][Bools] & SPEEDOMETER_GAIN_COLOR) ? "[x] Gain Based Color":"[ ] Gain Based Color");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void ShowPosEditMenu(int client)
{
	Menu menu = new Menu(Pos_Edit_Handler);
	menu.ExitBackButton = true;
	SetMenuTitle(menu, "POSITIONS \n \n");
	char sMessage[256];
	Format(sMessage, sizeof(sMessage), "Editing Hud: %s", g_sHudStrs[g_iEditHud[client]]);
	AddMenuItem(menu, "editingHud", sMessage);
	AddMenuItem(menu, "center", "Dead Center");
	AddMenuItem(menu, "editMode", "Enter Edit Mode");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int Pos_Edit_Handler(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));
		if(StrEqual(info, "editingHud"))
		{
			g_iEditHud[client]++;
			if(g_iEditHud[client] >= 4)
			{
				g_iEditHud[client] = 0;
			}
		}
		else if(StrEqual(info, "center"))
		{
			SetIntSubValue(g_iSettings[client][Positions_X], 0, g_iEditHud[client], POS_INT_BITS, POS_BINARY_MASK);
			SetIntSubValue(g_iSettings[client][Positions_Y], 0, g_iEditHud[client], POS_INT_BITS, POS_BINARY_MASK);
			PushPosCache(client);
		}
		else if(StrEqual(info, "editMode"))
		{
			g_bEditing[client] = !g_bEditing[client];
		}
		BgsSetCookie(client, g_hSettings[Positions_X], g_iSettings[client][Positions_X]);
		BgsSetCookie(client, g_hSettings[Positions_Y], g_iSettings[client][Positions_Y]);
		ShowPosEditMenu(client);
	}
	else if(action == MenuAction_Cancel)
	{
		g_bEditing[client] = false;
		ShowBHUDMenu(client);
		return 0;
	}
	else if(action == MenuAction_End)
	{
		g_bEditing[client] = false;
		delete menu;
	}
	return 0;
}

public int Jhud_SettingSelect(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));

		if(StrEqual(info, "strafespeed"))
		{
			g_iSettings[client][Bools] ^= JHUD_JSS;
		}
		else if(StrEqual(info, "extraspeeds"))
		{
			g_iSettings[client][Bools] ^= JHUD_EXTRASPEED;
		}
		else if(StrEqual(info, "sync"))
		{
			g_iSettings[client][Bools] ^= JHUD_SYNC;
		}
		BgsSetCookie(client, g_hSettings[Bools], g_iSettings[client][Bools]);
		ShowJhudSettingsMenu(client);
	}
	else if(action == MenuAction_Cancel)
	{
		ShowBHUDMenu(client);
		return 0;
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int Speedometer_SettingSelect(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));

		if(StrEqual(info, "speedGainColor"))
		{
			g_iSettings[client][Bools] ^= SPEEDOMETER_GAIN_COLOR;
		}
		BgsSetCookie(client, g_hSettings[Bools], g_iSettings[client][Bools]);
		ShowSpeedSettingsMenu(client);
	}
	else if(action == MenuAction_Cancel)
	{
		ShowBHUDMenu(client);
		return 0;
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}
