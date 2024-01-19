#define UPDATE_RATE 7

UserMsg g_hCenterTextId = view_as<UserMsg>(-1);
static int g_iCmdNum;

void ShowKeys_Start()
{
	g_hCenterTextId = GetUserMessageId("TextMsg");
}

void ShowKeys_Tick(int client, int buttons, float yawDiff)
{


	for(int i = 1; i <= MaxClients; i++)
	{
		if(i == client && IsPlayerAlive(i) || BgsGetHUDTarget(i) == client && !IsPlayerAlive(i))
		{
			ShowKeys_Send(i, buttons, yawDiff);
		}
	}
}

void ShowKeys_Send(client, buttons, yawDiff)
{
	g_iCmdNum++;

	if(g_iCmdNum % UPDATE_RATE != 0)
	{
		return;
	}

	char message[512];
	int size = BgsGetEngineVersion() == Engine_CSGO ? 512 : 254;

	if(g_iSettings[client][Bools] & SHOWKEYS_SIMPLE) //thanks shavit + xwidow
	{
		if(BgsGetEngineVersion == Engine_CSGO)
		{
			FormatEx(message, size, "%s   %s\n%s\n%s%s　 %s 　%s%s\n%s　　%s",
				(buttons & IN_JUMP) ? "Ｊ":" ", 
				(buttons & IN_DUCK) ? "Ｃ":" ",
				(buttons & IN_FORWARD) ? "Ｗ":" ", 
				(fAngleDiff > 0) ? "←":" ", 
				(buttons & IN_MOVELEFT) ? "Ａ":" ",
				(buttons & IN_BACK) ? "Ｓ":" ", 
				(buttons & IN_MOVERIGHT) ? "Ｄ":" ", 
				(fAngleDiff < 0) ? "→":" ",
				(buttons & IN_LEFT) ? "Ｌ":" ", 
				(buttons & IN_RIGHT) ? "Ｒ":" ");
		}
		else
		{
			FormatEx(message, size, "　  %s　　%s\n      %s    \n  %s%s　 %s 　%s%s\n　  %s　　%s",
				(buttons & IN_JUMP) > 0? "Ｊ":" ", 
				(buttons & IN_DUCK) > 0? "Ｃ":" ",
				(buttons & IN_FORWARD) > 0 ? "Ｗ":"  ",
				(fAngleDiff > 0) ? "←":"  ", 
				(buttons & IN_MOVELEFT) > 0? "Ａ":" ", 
				(buttons & IN_BACK) > 0? "Ｓ":" ",
				(buttons & IN_MOVERIGHT) > 0? "Ｄ":" ", 
				(fAngleDiff < 0) ? "→":" ",
				(buttons & IN_LEFT) > 0? "Ｌ":" ", 
				(buttons & IN_RIGHT) > 0? "Ｒ":" ");
		}
	}
	else
	{
		FormatEx(message, size, "%s   %s\n%s  %s  %s\n%s　 %s 　%s\n %s　　%s",
			(buttons & IN_JUMP) > 0? "Ｊ":"ｰ", 
			(buttons & IN_DUCK) > 0? "Ｃ":"ｰ",
			(yawDiff > 0) ? "<":"ｰ", 
			(buttons & IN_FORWARD) > 0 ? "Ｗ":"ｰ", 
			(yawDiff < 0) ? ">":"ｰ",
			(buttons & IN_MOVELEFT) > 0? "Ａ":"ｰ", 
			(buttons & IN_BACK) > 0? "Ｓ":"ｰ", 
			(buttons & IN_MOVERIGHT) > 0? "Ｄ":"ｰ",
			(buttons & IN_LEFT) > 0? "Ｌ":" ", 
			(buttons & IN_RIGHT) > 0? "Ｒ":" ");
	}


	if(g_iSettings[client][Bools] & UnreliableHud)
	{
		UnreliablePrintCenterText(client, message);
	}
	else
	{
		BgsDisplayHud(client, g_fCacheHudPositions[cient][ShowKeys], {255,255,255}, 0.7, GetDynamicChannel(3), false, message);
	}

}


//maybe refactor to send all at once in an array, need to test if array needs to be dynamically allocated or not
void UnreliablePrintCenterText(int client, const char[] str) //thanks shavit
{
	int clients[1];
	clients[0] = client;

	// Start our own message instead of using PrintCenterText so we can exclude USERMSG_RELIABLE.
	// This makes the HUD update visually faster.
	BfWrite msg = view_as<BfWrite>(StartMessageEx(g_hCenterTextId, clients, 1, USERMSG_BLOCKHOOKS));
	msg.WriteByte(HUD_PRINTCENTER);
	msg.WriteString(str);
	msg.WriteString("");
	msg.WriteString("");
	msg.WriteString("");
	msg.WriteString("");
	EndMessage();
}
