#include <sourcemod>
#include <clientprefs>
#include <bhop-get-stats>
#include <DynamicChannels>
#include <sdktools>

#include <jumpstat/colors.sp>
#include <jumpstat/settings.sp>
#include <jumpstat/util.sp>
#include <jumpstat/commands.sp>
#include <jumpstat/menu.sp>
#include <jumpstat/jhud.sp>
#include <jumpstat/offsets.sp>
#include <jumpstat/speedometer.sp>
#include <jumpstat/ssj.sp>
#include <jumpstat/trainer.sp>

#undef REQUIRE_PLUGIN
#include <shavit>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "bgs-jumpstats",
	author = "Nimmy",
	description = "all kinds of stuff",
	version = "3.0",
	url = "https://github.com/Nimmy2222/bhop-get-stats"
}

//Dynamic Channel Notes - CSS
// Trainer 0 (here)
// Jhud 1 (here)
// Offset 2 (here)
// Widow Bash 3 (xWidows bash, just displays devs and stuff) OTHER DEVS USE THIS ONE !!!!! WRITE THIS SOMEWHERE
// Speedometer 4 (here)
// Shavit-Hud Top Left 5 (https://github.com/shavitush/bhoptimer/blob/7fb0f45c2c75714b4192f48e4b7ea030b0f9b5a9/addons/sourcemod/scripting/shavit-hud.sp#L2059)
bool g_bLate = false;
bool g_bShavit = false;
chatstrings_t g_sChatStrings;
EngineVersion g_hEType = Engine_Unknown;

public void OnPluginStart()
{
	g_hEType = GetEngineVersion();
	g_bShavit = LibraryExists("shavit");
	if(g_bLate && g_bShavit)
	{
		Shavit_OnChatConfigLoaded();
	}

	Commands_Start();
	Settings_Start();
}

public void Shavit_OnChatConfigLoaded()
{
	Shavit_GetChatStrings(sMessagePrefix, g_sChatStrings.sPrefix, sizeof(chatstrings_t::sPrefix));
	Shavit_GetChatStrings(sMessageText, g_sChatStrings.sText, sizeof(chatstrings_t::sText));
	Shavit_GetChatStrings(sMessageWarning, g_sChatStrings.sWarning, sizeof(chatstrings_t::sWarning));
	Shavit_GetChatStrings(sMessageVariable, g_sChatStrings.sVariable, sizeof(chatstrings_t::sVariable));
	Shavit_GetChatStrings(sMessageVariable2, g_sChatStrings.sVariable2, sizeof(chatstrings_t::sVariable2));
	Shavit_GetChatStrings(sMessageStyle, g_sChatStrings.sStyle, sizeof(chatstrings_t::sStyle));
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if(late)
	{
		late=true;
	}
	return APLRes_Success;
}

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "shavit"))
	{
		g_bShavit = true;
		Shavit_OnChatConfigLoaded();
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if(StrEqual(name, "shavit"))
	{
		g_bShavit = false;
	}
}

public void BhopStat_TickForward(int client, int speed, bool inbhop, float gain, float jss)
{
	Speedometer_Tick(client, speed, inbhop, gain);
	Trainer_Tick(client, speed, inbhop, gain, jss);
}

public void BhopStat_JumpForward(int client, int jump, int speed, int strafecount, float heightdelta, float gain, float sync, float eff, float yawwing, float jss)
{
	Jhud_Process(client, jump, speed, strafecount, heightdelta, gain, sync, eff, yawwing, jss);
	Ssj_Process(client, jump, speed, strafecount, heightdelta, gain, sync, eff, yawwing, jss, g_bShavit, g_sChatStrings, g_hEType);
}

public void BhopStat_StrafeForward(int client, int offset, bool overlap, bool nopress)
{
	Offset_Process(client, offset, overlap, nopress);
}

public Action OnPlayerRunCmd(int client, int& buttons, int& impulse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	Menu_CheckEditMode(client, buttons, mouse);
	return Plugin_Continue;
}
