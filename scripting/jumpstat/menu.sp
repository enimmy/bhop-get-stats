static int g_iEditColor[MAXPLAYERS + 1]; //menu cache for which color type the player wants to mess with
static int g_iEditHud[MAXPLAYERS + 1]; //menu cache for which hud the player wants to mess with
static int g_iCmdNum[MAXPLAYERS + 1]; //counter for editmode onplayerruncmd

static bool g_xLocked[MAXPLAYERS + 1]; //bool for editmode, player locked X through the menu
static bool g_yLocked[MAXPLAYERS + 1]; //bool for editmode, player locked Y through the menu
static bool g_bEditLastTick[MAXPLAYERS + 1]; //player was editing, so if their g_bEditing is false they mustve just stopped. do stuff

#define TEST_POS_UPDATE_INTERVAL 7

//Edit Mode

void Menu_CheckEditMode(int client, int& buttons, int mouse[2]) {
	if(!g_bEditing[client])
	{
		if(g_bEditLastTick[client])
		{
			g_bEditLastTick[client] = false;
			g_iCmdNum[client] = 0;
			SetEntProp(client, Prop_Data, "m_fFlags",  GetEntProp(client, Prop_Data, "m_fFlags") ^ FL_ATCONTROLS);
			SaveAllCookies(client);
			PushPosCache(client);
		}
		return;
	}

	g_iCmdNum[client]++;
	g_bEditLastTick[client] = true;

	SetEntProp(client, Prop_Data, "m_fFlags",  GetEntProp(client, Prop_Data, "m_fFlags") |  FL_ATCONTROLS );
	SetEntityMoveType(client, MOVETYPE_NONE);

	bool xLock = view_as<bool>(buttons & IN_SPEED);
	bool yLock = view_as<bool>(buttons & IN_DUCK);

	if(!xLock && !g_xLocked[client])
	{
		if(buttons & IN_MOVERIGHT && !g_xLocked[client])
		{
			EditHudPosition(client, Positions_X, 1);
		}
		else if(buttons & IN_MOVELEFT && !g_xLocked[client])
		{
			EditHudPosition(client, Positions_X, -1);
		}
	}

	if(!yLock && !g_yLocked[client])
	{
		if(buttons & IN_FORWARD && !g_yLocked[client])
		{
			EditHudPosition(client, Positions_Y, -1);
		}
		else if(buttons & IN_BACK && !g_yLocked[client])
		{
			EditHudPosition(client, Positions_Y, 1);
		}
	}


	if(mouse[X_DIM] != 0 || mouse[Y_DIM] != 0)
	{
		if(mouse[X_DIM] != 0 && !g_xLocked[client] && !xLock)
		{
			EditHudPosition(client, Positions_X, mouse[X_DIM]);
		}
		if(mouse[Y_DIM] != 0 && !g_yLocked[client] && !yLock)
		{
			EditHudPosition(client, Positions_Y, mouse[Y_DIM]);
		}
	}

	if(g_iCmdNum[client] % TEST_POS_UPDATE_INTERVAL == 0) //Other huds can interfere, so we need to at least give prio to editing hud
	{
		PushPosCache(client);

		SetHudTextParams(g_fCacheHudPositions[client][g_iEditHud[client]][X_DIM], g_fCacheHudPositions[client][g_iEditHud[client]][Y_DIM], 1.0, g_iBstatColors[GainGood][0], g_iBstatColors[GainGood][1], g_iBstatColors[GainGood][2], 255, 0, 0.0, 0.0, 0.0);
		ShowHudText(client, GetDynamicChannel(g_iEditHud[client]), g_sHudStrs[g_iEditHud[client]]);

		for(int i = 0; i < sizeof(g_fDefaultHudYPositions); i++)
		{
			if(i != g_iEditHud[client])
			{
				SetHudTextParams(g_fCacheHudPositions[client][i][X_DIM], g_fCacheHudPositions[client][i][Y_DIM], 1.0, g_iBstatColors[GainGood][0], g_iBstatColors[GainGood][1], g_iBstatColors[GainGood][2], 255, 0, 0.0, 0.0, 0.0);
				ShowHudText(client, GetDynamicChannel(i), g_sHudStrs[i]);
			}
		}
	}
	return;
}

void EditHudPosition(int client, int editDim, int val)
{
	int subValue = GetIntSubValue(g_iSettings[client][editDim], g_iEditHud[client], POS_INT_BITS, POS_BINARY_MASK);
	if(subValue == 0) //Position was dead center
	{
		subValue = POS_BINARY_MASK / 2; //move to a pos close to center, but not dead center
	}
	else
	{
		subValue += val;
	}

	if(subValue > POS_MAX_INT)
	{
		subValue = POS_MAX_INT;
	}

	if(subValue < (POS_MIN_INT + 1))
	{
		subValue = POS_MIN_INT + 1;
	}

	SetIntSubValue(g_iSettings[client][editDim], subValue, g_iEditHud[client], POS_INT_BITS, POS_BINARY_MASK);
}

//Menus

void ShowJsMenu(int client)
{
	if(!BgsIsValidClient(client))
	{
		return;
	}

	Menu menu = new Menu(Js_Select);
	char title[256];
	char version[32];
	BgsVersion(version, sizeof(version));
	Format(title, sizeof(title), "JumpStats %s - Nimmy\n\n", version)
	SetMenuTitle(menu, title);
	AddMenuItem(menu, "stats", "Statistics");
	AddMenuItem(menu, "hud", "Hud Position Editor");
	AddMenuItem(menu, "colors", "Colors");
	AddMenuItem(menu, "reset", "Reset");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void ShowStatOverviewMenu(int client)
{
	if(!BgsIsValidClient(client))
	{
		return;
	}

	Menu menu = new Menu(StatOverview_Select);
	menu.ExitBackButton = true;
	SetMenuTitle(menu, "Jump Stats\n \n");
	AddMenuItem(menu, "ssj", "SSJ (Chat)");
	AddMenuItem(menu, "jhud", "Jhud (HUD)");
	AddMenuItem(menu, "offsets", "Offsets (HUD/Console)");
	AddMenuItem(menu, "speedometer", "Speedometer (HUD)");

	if(BgsShavitLoaded())
	{
		AddMenuItem(menu, "fjt", "FJT (HUD/Chat)");
	}

	AddMenuItem(menu, "trainer", "Trainer (HUD)");

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void ShowSSJMenu(int client, int pos = 0)
{
	if(!BgsIsValidClient(client))
	{
		return;
	}

	Menu menu = new Menu(Ssj_Select);
	menu.ExitBackButton = true;
	SetMenuTitle(menu, "Chat Jump Stats \n \n");
	AddMenuItem(menu, "enSsj", (g_iSettings[client][Bools] & SSJ_ENABLED) ? "[x] Enabled":"[ ] Enabled");
	AddMenuItem(menu, "enRepeat", (g_iSettings[client][Bools] & SSJ_REPEAT) ? "[x] Repeat":"[ ] Repeat");

	char message[256];
	Format(message, sizeof(message), "Usage: %i",g_iSettings[client][Usage]);
	AddMenuItem(menu, "enUsage", message);
	AddMenuItem(menu, "enDecimals", (g_iSettings[client][Bools] & SSJ_DECIMALS) ? "[x] Decimals":"[ ] Decimals");

	AddMenuItem(menu, "enGain", (g_iSettings[client][Bools] & SSJ_GAIN) ? "[x] Gain":"[ ] Gain");
	AddMenuItem(menu, "enGainColor", (g_iSettings[client][Bools] & SSJ_GAIN_COLOR) ? "[x] Gain Colors":"[ ] Gain Color");
	AddMenuItem(menu, "enSync", (g_iSettings[client][Bools] & SSJ_SYNC) ? "[x] Sync":"[ ] Sync");
	AddMenuItem(menu, "enStrafes", (g_iSettings[client][Bools] & SSJ_STRAFES) ? "[x] Strafes":"[ ] Strafes");
	AddMenuItem(menu, "enJss", (g_iSettings[client][Bools] & SSJ_JSS) ? "[x] Jss":"[ ] Jss");
	AddMenuItem(menu, "enEff", (g_iSettings[client][Bools] & SSJ_EFFICIENCY) ? "[x] Efficiency":"[ ] Efficiency");
	AddMenuItem(menu, "enOffset", (g_iSettings[client][Bools] & SSJ_OFFSETS) ? "[x] Offsets":"[ ] Offsets");
	AddMenuItem(menu, "enHeight", (g_iSettings[client][Bools] & SSJ_HEIGHTDIFF) ? "[x] Height Difference":"[ ] Height Difference");

	if(BgsShavitLoaded())
	{
		AddMenuItem(menu, "enTime", (g_iSettings[client][Bools] & SSJ_SHAVIT_TIME) ? "[x] Time":"[ ] Time");
		AddMenuItem(menu, "enTimeDelta", (g_iSettings[client][Bools] & SSJ_SHAVIT_TIME_DELTA) ? "[x] Time Difference":"[ ] Time Difference");
	}

	while(pos % GetMenuPagination(menu) != 0)
	{
		pos--;
	}

	DisplayMenuAtItem(menu, client, pos, MENU_TIME_FOREVER);
}

void ShowJhudSettingsMenu(int client)
{
	if(!BgsIsValidClient(client))
	{
		return;
	}

	Menu menu = new Menu(Jhud_Select);
	menu.ExitBackButton = true;
	SetMenuTitle(menu, "Jhud Settings\n \n");
	AddMenuItem(menu, "en", (g_iSettings[client][Bools] & JHUD_ENABLED) ? "[x] Enabled":"[ ] Enabled")
	AddMenuItem(menu, "strafespeed", (g_iSettings[client][Bools] & JHUD_JSS) ? "[x] Jss":"[ ] Jss");
	AddMenuItem(menu, "sync", (g_iSettings[client][Bools] & JHUD_SYNC) ? "[x] Sync":"[ ] Sync");
	AddMenuItem(menu, "extraspeeds", (g_iSettings[client][Bools] & JHUD_EXTRASPEED) ? "[x] Extra speeds":"[ ] Extra speeds");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void ShowOffsetsMenu(int client)
{
	if(!BgsIsValidClient(client))
	{
		return;
	}

	Menu menu = new Menu(Offsets_Select);
	menu.ExitBackButton = true;
	SetMenuTitle(menu, "Offsets Settings\n \n");
	AddMenuItem(menu, "en", (g_iSettings[client][Bools] & OFFSETS_ENABLED) ? "[x] HUD":"[ ] HUD");
	AddMenuItem(menu, "spam", (g_iSettings[client][Bools] & OFFSETS_SPAM_CONSOLE) ? "[x] Console Dump":"[ ] Console Dump");
	AddMenuItem(menu, "adv", (g_iSettings[client][Bools] & OFFSETS_ADVANCED) ? "[x] NoPress/Overlap Text":"[ ] NoPress/Overlap Text");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void ShowFjtSettingsMenu(int client)
{
	if(!BgsIsValidClient(client))
	{
		return;
	}

	Menu menu = new Menu(Fjt_Select);
	menu.ExitBackButton = true;
	SetMenuTitle(menu, "FJT Settings\n \n");
	AddMenuItem(menu, "en", (g_iSettings[client][Bools] & FJT_ENABLED) ? "[x] HUD":"[ ] HUD");
	AddMenuItem(menu, "chat", (g_iSettings[client][Bools] & FJT_CHAT) ? "[x] Chat":"[ ] Chat");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void ShowSpeedSettingsMenu(int client)
{
	if(!BgsIsValidClient(client))
	{
		return;
	}

	Menu menu = new Menu(Speedometer_Select);
	menu.ExitBackButton = true;
	SetMenuTitle(menu, "Speed Settings\n \n");
	AddMenuItem(menu, "en", (g_iSettings[client][Bools] & SPEEDOMETER_ENABLED) ? "[x] Enabled":"[ ] Enabled");
	AddMenuItem(menu, "speedGainColor", (g_iSettings[client][Bools] & SPEEDOMETER_GAIN_COLOR) ? "[x] Gain Based Color":"[ ] Gain Based Color");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void ShowTrainerSettingsMenu(int client)
{
	if(!BgsIsValidClient(client))
	{
		return;
	}

	Menu menu = new Menu(Trainer_Select);
	menu.ExitBackButton = true;
	SetMenuTitle(menu, "Trainer Settings\n \n");
	AddMenuItem(menu, "en", (g_iSettings[client][Bools] & TRAINER_ENABLED) ? "[x] Enabled":"[ ] Enabled");
	AddMenuItem(menu, "strict", (g_iSettings[client][Bools] & TRAINER_STRICT) ? "[x] Strict Colors":"[ ] Strict Colors");

	char message[256];
	Format(message, sizeof(message), "Trainer Speeds: %s", g_sTrainerSpeed[g_iSettings[client][TrainerSpeed]]);
	AddMenuItem(menu, "speed", message);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void ShowPosEditMenu(int client)
{
	if(!BgsIsValidClient(client))
	{
		return;
	}

	Menu menu = new Menu(PosEdit_Select);
	menu.ExitBackButton = true;
	SetMenuTitle(menu, "Position Editor\n \n");
	char message[256];
	Format(message, sizeof(message), "%s", g_sHudStrs[g_iEditHud[client]]);
	ReplaceString(message, sizeof(message), "\n", " / ");
	Format(message, sizeof(message), "Editing Hud: %s", message);
	AddMenuItem(menu, "editingHud", message);
	AddMenuItem(menu, "center", "Dead Center");
	AddMenuItem(menu, "default", "Default Position");

	Format(message, sizeof(message), "Edit Mode: %s", g_bEditing[client] ? "On":"Off");
	AddMenuItem(menu, "editMode", message);

	if(g_bEditing[client])
	{
		AddMenuItem(menu, "lockX", g_xLocked[client] ? "[x] Lock X / Walk":"[ ] Lock X / Walk");
		AddMenuItem(menu, "lockY", g_yLocked[client] ? "[x] Lock Y / Duck":"[ ] Lock Y / Duck");
		AddMenuItem(menu, "ignore", "Use WASD/Mouse to Adjust HUDs \n"
								..."Disable JoyStick (joystick 0) if mouse isn't working. \n"
								..."You can use menu to lock dimensions, or hold Walk/Duck", ITEMDRAW_DISABLED);
	}

	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

void ShowColorsMenu(int client)
{
	if(!BgsIsValidClient(client))
	{
		return;
	}

	Menu menu = new Menu(Colors_Select);
	menu.ExitBackButton = true;
	SetMenuTitle(menu, "Color Editor\n \n");

	int editing = g_iEditColor[client];
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
		AddMenuItem(menu, "editing", "< Okay >");
	}
	else if (editing == GainGood)
	{
		AddMenuItem(menu, "editing", "< Good >");
	}
	else if (editing == GainReallyGood)
	{
		AddMenuItem(menu, "editing", "< Very Good >");
	}

	AddMenuItem(menu, "editcolor", g_sBstatColorStrs[g_iSettings[client][editing]]);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

//Handlers

public int Js_Select(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));

		if(StrEqual(info, "stats"))
		{
			ShowStatOverviewMenu(client);
		}
		else if(StrEqual(info, "hud"))
		{
			ShowPosEditMenu(client);
		}
		else if(StrEqual(info, "colors"))
		{
			ShowColorsMenu(client);
		}
		else if(StrEqual(info, "reset"))
		{
			SetAllDefaults(client);
			ShowJsMenu(client);
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
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
		}
		else if(StrEqual(info, "enDecimals"))
		{
			g_iSettings[client][Bools] ^= SSJ_DECIMALS;
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
		else if(StrEqual(info, "enJss"))
		{
			g_iSettings[client][Bools] ^= SSJ_JSS;
		}
		else if(StrEqual(info, "enEff"))
		{
			g_iSettings[client][Bools] ^= SSJ_EFFICIENCY;
		}
		else if(StrEqual(info, "enHeight"))
		{
			g_iSettings[client][Bools] ^= SSJ_HEIGHTDIFF;
		}
		else if(StrEqual(info, "enOffset"))
		{
			g_iSettings[client][Bools] ^= SSJ_OFFSETS;
		}
		else if(StrEqual(info, "enTime"))
		{
			g_iSettings[client][Bools] ^= SSJ_SHAVIT_TIME;
		}
		else if(StrEqual(info, "enTimeDelta"))
		{
			g_iSettings[client][Bools] ^= SSJ_SHAVIT_TIME_DELTA;
		}

		BgsSetCookie(client, g_hSettings[Usage], g_iSettings[client][Usage]);
		BgsSetCookie(client, g_hSettings[Bools], g_iSettings[client][Bools]);
		ShowSSJMenu(client, option);
	}
	else if(action == MenuAction_Cancel)
	{
		if(option == MenuCancel_ExitBack)
		{
			ShowStatOverviewMenu(client);
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int StatOverview_Select(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));

		if(StrEqual(info, "ssj"))
		{
			ShowSSJMenu(client);
		}
		else if(StrEqual(info, "jhud"))
		{
			ShowJhudSettingsMenu(client);
		}
		else if(StrEqual(info, "trainer"))
		{
			ShowTrainerSettingsMenu(client);
		}
		else if(StrEqual(info, "offsets"))
		{
			ShowOffsetsMenu(client);
		}
		else if(StrEqual(info, "fjt"))
		{
			ShowFjtSettingsMenu(client);
		}
		else if(StrEqual(info, "speedometer"))
		{
			ShowSpeedSettingsMenu(client);
		}
	}
	else if(action == MenuAction_Cancel)
	{
		if(option == MenuCancel_ExitBack)
		{
			ShowJsMenu(client);
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int Colors_Select(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));

		if(StrEqual(info, "editing"))
		{
			g_iEditColor[client]++;
			if(g_iEditColor[client] > COLOR_SETTINGS_END_IDX)
			{
				g_iEditColor[client] = COLOR_SETTINGS_START_IDX;
			}

		}
		else if(StrEqual(info, "editcolor"))
		{
			int editing = g_iEditColor[client];
			g_iSettings[client][editing]++;
			if(g_iSettings[client][editing] >= sizeof(g_iBstatColors))
			{
				g_iSettings[client][editing] = 0;
			}
			BgsSetCookie(client, g_hSettings[editing], g_iSettings[client][editing]);
		}
		ShowColorsMenu(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(option == MenuCancel_ExitBack)
		{
			ShowJsMenu(client);
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int PosEdit_Select(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));
		if(StrEqual(info, "editingHud"))
		{
			g_iEditHud[client]++;
			if(g_iEditHud[client] >= sizeof(g_fDefaultHudYPositions))
			{
				g_iEditHud[client] = 0;
			}
		}
		else if(StrEqual(info, "center"))
		{
			SetIntSubValue(g_iSettings[client][Positions_X], 0, g_iEditHud[client], POS_INT_BITS, POS_BINARY_MASK);
			SetIntSubValue(g_iSettings[client][Positions_Y], 0, g_iEditHud[client], POS_INT_BITS, POS_BINARY_MASK);
			BgsSetCookie(client, g_hSettings[Positions_X], g_iSettings[client][Positions_X]);
			BgsSetCookie(client, g_hSettings[Positions_Y], g_iSettings[client][Positions_Y]);
			PushPosCache(client);
		}
		else if(StrEqual(info, "default"))
		{
			SetDefaultHudPos(client, g_iEditHud[client]);
		}
		else if(StrEqual(info, "editMode"))
		{
			g_bEditing[client] = !g_bEditing[client];
		}
		else if(StrEqual(info, "lockX"))
		{
			g_xLocked[client] = !g_xLocked[client];
		}
		else if(StrEqual(info, "lockY"))
		{
			g_yLocked[client] = !g_yLocked[client];
		}
		ShowPosEditMenu(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(option == MenuCancel_ExitBack)
		{
			ShowJsMenu(client);
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int Jhud_Select(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));

		if(StrEqual(info, "en"))
		{
			g_iSettings[client][Bools] ^= JHUD_ENABLED;
		}
		else if(StrEqual(info, "strafespeed"))
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
		if(option == MenuCancel_ExitBack)
		{
			ShowStatOverviewMenu(client);
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int Offsets_Select(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));

		if(StrEqual(info, "en"))
		{
			g_iSettings[client][Bools] ^= OFFSETS_ENABLED;
			if(g_iSettings[client][Bools] & OFFSETS_ENABLED)
			{
				BgsPrintToChat(client, "Advanced offsets information in your console!");
				PrintToConsole(client,
				"JumpStats: You've enabled offsets, so this section will explain some"
				... "of its features and some mechanics behind offsets. \n"
				... "Offset - A time comparison (in ticks) of when you turned your mouse and pressed the strafe key.\n"
				... "------------------------------------------------------------------------------------------------\n"
				... "-1 - Perfect offset, you pressed your strafe key 1 tick before you turned your mouse.\n"
				... "------------------------------------------------------------------------------------------------\n");
				PrintToConsole(client,
				"0 - A 0 offset loses you speed depending on how fast your strafe speed is the tick after you turned.\n"
				... "The higher your strafe speed, the most speed loss. So if you hit a 0 and have low strafe speed, that\n"
				... "is an okay, and human option, for gaining speed. Lower strafe speeds are generally only optimal for\n"
				... "gaining distance though, so in most cases a robot perfect strafe (inhuman) wouldn't want a 0, but its\n"
				... "but in real practice it can be good for your speed as long as your strafe speed is right for it.\n"
				... "------------------------------------------------------------------------------------------------\n"
				... "-2 - A -2 offset will result in ticks where you don't gain speed, the higher you strafe speed is\n"
				... "the lesser this effects your speed, so this is the second best option if your strafe speed is higher\n");
				PrintToConsole(client,
				"Overlap - You pressed A/D or W/S at the same time, go turn on nulls.\n"
				... "No Press - You let go of the opposing key too early when you turned.\n");
			}
		}
		else if(StrEqual(info, "spam"))
		{
			g_iSettings[client][Bools] ^= OFFSETS_SPAM_CONSOLE;
		}
		else if(StrEqual(info, "adv"))
		{
			g_iSettings[client][Bools] ^= OFFSETS_ADVANCED;
		}
		BgsSetCookie(client, g_hSettings[Bools], g_iSettings[client][Bools]);
		ShowOffsetsMenu(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(option == MenuCancel_ExitBack)
		{
			ShowStatOverviewMenu(client);
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int Fjt_Select(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));

		if(StrEqual(info, "en"))
		{
			g_iSettings[client][Bools] ^= FJT_ENABLED;
		}
		else if(StrEqual(info, "chat"))
		{
			g_iSettings[client][Bools] ^= FJT_CHAT;
		}
		BgsSetCookie(client, g_hSettings[Bools], g_iSettings[client][Bools]);
		ShowFjtSettingsMenu(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(option == MenuCancel_ExitBack)
		{
			ShowStatOverviewMenu(client);
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int Speedometer_Select(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));
		if(StrEqual(info, "en"))
		{
			g_iSettings[client][Bools] ^= SPEEDOMETER_ENABLED;
		}
		else if(StrEqual(info, "speedGainColor"))
		{
			g_iSettings[client][Bools] ^= SPEEDOMETER_GAIN_COLOR;
		}
		BgsSetCookie(client, g_hSettings[Bools], g_iSettings[client][Bools]);
		ShowSpeedSettingsMenu(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(option == MenuCancel_ExitBack)
		{
			ShowStatOverviewMenu(client);
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}

public int Trainer_Select(Menu menu, MenuAction action, int client, int option)
{
	if(action == MenuAction_Select)
	{
		char info[32];
		menu.GetItem(option, info, sizeof(info));
		if(StrEqual(info, "en"))
		{
			g_iSettings[client][Bools] ^= TRAINER_ENABLED;
		}
		else if(StrEqual(info, "speed"))
		{
			g_iSettings[client][TrainerSpeed]++;
			if(g_iSettings[client][TrainerSpeed] >= sizeof(g_iTrainerSpeeds))
			{
				g_iSettings[client][TrainerSpeed] = Trainer_Slow;
			}
		}
		else if(StrEqual(info, "strict"))
		{
			g_iSettings[client][Bools] ^= TRAINER_STRICT;
		}
		BgsSetCookie(client, g_hSettings[Bools], g_iSettings[client][Bools]);
		BgsSetCookie(client, g_hSettings[TrainerSpeed], g_iSettings[client][TrainerSpeed]);
		ShowTrainerSettingsMenu(client);
	}
	else if(action == MenuAction_Cancel)
	{
		if(option == MenuCancel_ExitBack)
		{
			ShowStatOverviewMenu(client);
		}
	}
	else if(action == MenuAction_End)
	{
		delete menu;
	}
	return 0;
}
