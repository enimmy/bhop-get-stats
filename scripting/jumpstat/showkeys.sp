#define UPDATE_RATE 7

static int g_iCmdNum[MAXPLAYERS + 1];


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
	char message[256];
	bool simple = g_iSettings[client][Bools] & SHOWKEYS_SIMPLE;


	if(buttons & IN_MOVELEFT)
	{
		if(simple)
		{

		}
		else
		{
			
		}
	}
	if(buttons & IN_MOVERIGHT)
	{
		if(simple)
		{

		}
		else
		{
			
		}
	}
	if(buttons & IN_FORWARDS)
	{
		if(simple)
		{

		}
		else
		{
			
		}
	}
	if(buttons & IN_BACKWARDS)
	{
		if(simple)
		{

		}
		else
		{
			
		}
	}
	if(buttons & IN_RIGHT)
	{
		if(simple)
		{

		}
		else
		{
			
		}
	}
	if(buttons & IN_LEFT)
	{
		if(simple)
		{

		}
		else
		{
			
		}
	}
	if(buttons & IN_DUCK)
	{
		if(simple)
		{

		}
		else
		{
			
		}
	}

	bool turnRight = false;
	if(yawDiff < 0.0)
	{

	}
	else
	{
		
	}

	if(simple)
	{

	}
	else
	{
		
	}

	if(g_iSettings[client][Bools] & UnreliableHud)
	{
		PrintCenterText(client, message);
	}
	else
	{
		BgsDisplayHud(client, g_fCacheHudPositions[cient][ShowKeys], {255,255,255}, 0.7, GetDynamicChannel(3), false, message);
	}

}
