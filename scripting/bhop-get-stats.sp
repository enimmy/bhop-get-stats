#include <sdktools>
#include <sdkhooks>
#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "bhop get stats",
	//I put peoples names on here who I got code from or help, if you don't want to be listed on here contact me. Just trying to show appreciation
	author = "Nimmy / Alkatraz, Nairda (ssj code) / Oblivious , Xutax(perf angle calc)",
	description = "central plugin to call bhop stats",
	version = "1.2",
	url = "https://github.com/Nimmy2222/bhop-get-stats"
}

#define BHOP_FRAMES 10
#define YAW 1
#define SIDEMOVE 1
#define LEFT 0
#define RIGHT 1
//#define DEBUG

bool g_bTouchesWall[MAXPLAYERS + 1];
bool g_bJumpedThisTick[MAXPLAYERS + 1];
bool g_bOverlap[MAXPLAYERS + 1];
bool g_bNoPress[MAXPLAYERS + 1];

int g_iTicksOnGround[MAXPLAYERS + 1];
int g_iTouchTicks[MAXPLAYERS + 1];
int g_iStrafeTick[MAXPLAYERS + 1];
int g_iSyncedTick[MAXPLAYERS + 1];
int g_iJump[MAXPLAYERS + 1];
int g_iStrafeCount[MAXPLAYERS + 1];
int g_iTurnTick[MAXPLAYERS + 1];
int g_iKeyTick[MAXPLAYERS + 1];
int g_iTurnDir[MAXPLAYERS + 1];
int g_iCmdNum[MAXPLAYERS + 1];
int g_iAvgTicksNum[MAXPLAYERS + 1];

float g_fOldHeight[MAXPLAYERS + 1];
float g_fRawGain[MAXPLAYERS + 1];
float g_fTickGain[MAXPLAYERS + 1];
float g_fTrajectory[MAXPLAYERS + 1];
float g_fTraveledDistance[MAXPLAYERS + 1][3];
float g_fRunCmdVelVec[MAXPLAYERS + 1][3];
float g_fLastRunCmdVelVec[MAXPLAYERS + 1][3]; //redo speedloss later
float g_fLastAngles[MAXPLAYERS + 1][3];
float g_fAvgDiffFromPerf[MAXPLAYERS + 1];
float g_fYawDifference[MAXPLAYERS + 1];
float g_fLastVel[MAXPLAYERS + 1][3];
float g_fLastJumpPosition[MAXPLAYERS + 1][3];
float g_fLastVeer[MAXPLAYERS + 1];
float g_fTickJss[MAXPLAYERS + 1];
float g_fTickrate = 0.01;

GlobalForward JumpStatsForward;
GlobalForward StrafeStatsForward;
GlobalForward TickStatsForward;

public void OnPluginStart()
{
	HookEvent("player_jump", Player_Jump);
	g_fTickrate = GetTickInterval();

	JumpStatsForward = new GlobalForward("BhopStat_JumpForward", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Float, Param_Float, Param_Float, Param_Float, Param_Float);
	//int client, int jump, int speed, int heightdelta, int strafecount, float gain, float sync, float eff, float yawwing
	//yawing not done
	//add airpath, veer, jumpoff angle on j1

	StrafeStatsForward = new GlobalForward("BhopStat_StrafeForward", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	//int client, int offset, bool overlap, bool nopress

	TickStatsForward = new GlobalForward("BhopStat_TickForward", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Float, Param_Float);
	//int client, int speed, float gain, float jss);

	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("bhop-get-stats");
	return APLRes_Success;
}

public void OnClientPutInServer(int client)
{
	g_iJump[client] = 0;
	g_iStrafeTick[client] = 0;
	g_iSyncedTick[client] = 0;
	g_fRawGain[client] = 0.0;
	g_fOldHeight[client] = 0.0;
	g_fTrajectory[client] = 0.0;
	g_fTraveledDistance[client] = NULL_VECTOR;
	g_iTicksOnGround[client] = 0;
	g_iStrafeCount[client] = 0;
	g_iCmdNum[client] = 0;
	SDKHook(client, SDKHook_Touch, OnTouch);
}

public Action OnTouch(int client, int entity)
{
	if ((GetEntProp(entity, Prop_Data, "m_usSolidFlags") & 12) == 0)
	{
		g_bTouchesWall[client] = true;
	}
	return Plugin_Continue;
}

public void Player_Jump(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if(IsFakeClient(client) || (g_iJump[client] > 0 && g_iStrafeTick[client] == 0))
	{
		return;
	}

	g_iJump[client]++;
	g_bJumpedThisTick[client] = true;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	int flags = GetEntityFlags(client);

	g_fLastRunCmdVelVec[client] = g_fRunCmdVelVec[client];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", g_fRunCmdVelVec[client]);

	if(flags & FL_ONGROUND)
	{

		g_iTicksOnGround[client]++;
		if(g_iTicksOnGround[client] >= BHOP_FRAMES)
		{
			if(g_iTicksOnGround[client] == BHOP_FRAMES)
			{
				g_iJump[client] = 0;
				g_iStrafeTick[client] = 0;
				g_iSyncedTick[client] = 0;
				g_fRawGain[client] = 0.0;
				g_fTrajectory[client] = 0.0;
				g_iStrafeCount[client] = 0;
				g_fTraveledDistance[client] = NULL_VECTOR;
				g_iCmdNum[client] = 0;
				g_bNoPress[client] = false;
				g_bOverlap[client] = false;
			}
			return Plugin_Continue;
		}

		if ((buttons & IN_JUMP) > 0 && g_iTicksOnGround[client] == 1)
		{
			g_iTicksOnGround[client] = 0;
			float currpos[3];
			GetClientAbsOrigin(client, currpos); //player landed, mustve jumped right?, calc veer
			float xAxisVeer = FloatAbs(currpos[0] - g_fLastJumpPosition[client][0]);
			float yAxisVeer = FloatAbs(currpos[1] - g_fLastJumpPosition[client][1]);
			g_fLastVeer[client] = xAxisVeer >= yAxisVeer ? yAxisVeer:xAxisVeer; //something about this wrong, kinda close to distbug but not fully
			//PrintToChat(client, "veer %f", g_fLastVeer[client]);
		}
	}
	else
	{
		g_iTicksOnGround[client] = 0;
	}

	MoveType movetype = GetEntityMoveType(client);
	if(movetype == MOVETYPE_NONE || movetype == MOVETYPE_NOCLIP || movetype == MOVETYPE_LADDER || GetEntProp(client, Prop_Data, "m_nWaterLevel") >= 2)
	{
		g_iTicksOnGround[client] = BHOP_FRAMES + 1; //lol
	}

	return Plugin_Continue;
}


public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3])
{

	if(g_iTicksOnGround[client] == 0)
	{
		//jss calculation, probably overly complex rn
		g_fYawDifference[client] = NormalizeAngle(angles[YAW] - g_fLastAngles[client][YAW]);

		float vel_yaw = ArcTangent2(g_fRunCmdVelVec[client][1], g_fRunCmdVelVec[client][0]) * 180.0 / FLOAT_PI;
		float delta_opt = -NormalizeAngle(angles[1] - vel_yaw);

		if (GetRunCmdVelocity(client, true) == 0.0)
		{
			delta_opt = 90.0;
		}

		if (vel[0] != 0.0 && vel[1] == 0.0)
		{
			float sign = vel[0] > 0.0 ? -1.0 : 1.0;
			delta_opt = -NormalizeAngle(angles[1] - (vel_yaw + (90.0 * sign)));
		}

		if (vel[0] != 0.0 && vel[1] != 0.0)
		{
			float sign = vel[1] > 0.0 ? -1.0 : 1.0;
			if (vel[0] < 0.0)
				sign = -sign;
			delta_opt = -NormalizeAngle(angles[1] - (vel_yaw + (45.0 * sign)));
		}

		float perfyaw = NormalizeAngle(angles[1] + delta_opt);
		float newangdiff = FloatAbs(NormalizeAngle(perfyaw - g_fLastAngles[client][1]));

		g_fAvgDiffFromPerf[client] += (FloatAbs(g_fYawDifference[client]) / newangdiff);
		g_fTickJss[client] = (FloatAbs(g_fYawDifference[client]) / newangdiff);
		g_iAvgTicksNum[client]++;

		PrintDebugMsg(client, "Tick Jss: %f", g_fTickJss[client]);
		PrintDebugMsg(client, "Avg Jss: %f", g_fAvgDiffFromPerf[client] / g_iAvgTicksNum[client]);

		//offset shit
		if(g_iCmdNum[client] >= 1)
		{
			if(vel[1]* g_fLastVel[client][SIDEMOVE] < 0 || (g_fLastVel[client][SIDEMOVE] == 0 && vel[1] != 0))
			{
				g_iKeyTick[client] = g_iCmdNum[client];
				g_iStrafeCount[client]++;
			}
		}

		if(g_fYawDifference[client] > 0)
		{
			if(g_iTurnDir[client] == RIGHT && g_iCmdNum[client] > 1)
			{
				g_iTurnTick[client] = g_iCmdNum[client];
			}

			g_iTurnDir[client] = LEFT;
		}
		else if(g_fYawDifference[client] < 0)
		{
			if(g_iTurnDir[client] == LEFT && g_iCmdNum[client] > 1)
			{
				g_iTurnTick[client] = g_iCmdNum[client];
			}

			g_iTurnDir[client] = RIGHT;
		}

		if ((!(buttons & IN_MOVELEFT) && !(buttons & IN_MOVERIGHT)))
		{
			g_bNoPress[client] = true;
		}

		if(((buttons & IN_MOVELEFT) && (buttons & IN_MOVERIGHT)) || ((buttons & IN_FORWARD) && (buttons & IN_BACK)))
		{
			g_bOverlap[client] = true;
		}

		//doesnt work with sideways for now, can do it i think
		if((g_iTurnTick[client] == g_iCmdNum[client] || g_iKeyTick[client] == g_iCmdNum[client]) &&
		((g_iTurnDir[client] == RIGHT && vel[1] > 0) ||
		(g_iTurnDir[client] == LEFT && vel[1] < 0) ))
		{
			StartStrafeForward(client);
			g_bOverlap[client] = false;
			g_bNoPress[client] = false;
		}

		g_iStrafeTick[client]++;

		float speedmulti = GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue");

		g_fTraveledDistance[client][0] += g_fRunCmdVelVec[client][0] * g_fTickrate * speedmulti;
		g_fTraveledDistance[client][1] += g_fRunCmdVelVec[client][1] * g_fTickrate * speedmulti;

		g_fTrajectory[client] += GetRunCmdVelocity(client, true) * g_fTickrate * speedmulti;

		float fore[3];
		float side[3];
		GetAngleVectors(angles, fore, side, NULL_VECTOR);

		fore[2] = 0.0;
		NormalizeVector(fore, fore);

		side[2] = 0.0;
		NormalizeVector(side, side);

		float wishvel[3];
		float wishdir[3];

		for (int i = 0; i < 2; i++)
		{
			wishvel[i] = fore[i] * vel[0] + side[i] * vel[1];
		}

		float wishspeed = NormalizeVector(wishvel, wishdir);
		float maxspeed = GetEntPropFloat(client, Prop_Send, "m_flMaxspeed");

		if(maxspeed != 0.0 && wishspeed > maxspeed)
		{
			wishspeed = maxspeed;
		}

		if(wishspeed > 0.0)
		{
			float wishspd = (wishspeed > 30.0) ? 30.0 : wishspeed;
			float currentgain = GetVectorDotProduct(g_fRunCmdVelVec[client], wishdir);
			float gaincoeff = 0.0;

			if(currentgain < 30.0)
			{
				g_iSyncedTick[client]++;
				gaincoeff = (wishspd - FloatAbs(currentgain)) / wishspd;
			}

			if(g_bTouchesWall[client] && g_iTouchTicks[client] && gaincoeff > 0.5)
			{
				gaincoeff -= 1.0;
				gaincoeff = FloatAbs(gaincoeff);
			}
			g_fRawGain[client] += gaincoeff;
			g_fTickGain[client] = gaincoeff;

			PrintDebugMsg(client, "Tick Gain: %f", g_fTickGain[client]);
			if(g_iStrafeTick[client])
			{
				PrintDebugMsg(client, "Gain: %f", g_fRawGain[client] / g_fRawGain[client]);
			}
		}
	}
	StartTickForward(client);

	if(g_bTouchesWall[client])
	{
		g_iTouchTicks[client]++;
		g_bTouchesWall[client] = false;
	} else
	{
		g_iTouchTicks[client] = 0;
	}

	//run order RunCmd -> Jump Hook -> PostCmd | if you compare runcmd and postcmd gain calcs runcmd has 1 extra raw gain tick if you dont wait till here to finalize
	if(g_bJumpedThisTick[client])
	{
		GetClientAbsOrigin(client, g_fLastJumpPosition[client]);
		g_bJumpedThisTick[client] = false;
		StartJumpForward(client);
		float origin[3];
		GetClientAbsOrigin(client, origin);
		g_fRawGain[client] = 0.0;
		g_iStrafeTick[client] = 0;
		g_iSyncedTick[client] = 0;
		g_iStrafeCount[client] = 0;
		g_fOldHeight[client] = origin[2];
		g_fTrajectory[client] = 0.0;
		g_fTraveledDistance[client] = NULL_VECTOR;
		g_fAvgDiffFromPerf[client] = 0.0;
		g_iAvgTicksNum[client] = 0;
	}

	g_iCmdNum[client]++;
	g_fLastAngles[client] = angles;
	g_fLastVel[client] = vel;

	return;
}

//int client, int jump, int speed, int heightdelta, int strafecount, float gain, float sync, float eff, float yawwing
void StartJumpForward(int target)
{
	float velocity[3];
	GetEntPropVector(target, Prop_Data, "m_vecAbsVelocity", velocity);
	velocity[2] = 0.0;
	int speed = RoundToFloor(GetVectorLength(velocity));

	if(g_iJump[target] == 1) //probs a better way to do this idk
	{
		Call_StartForward(JumpStatsForward);
		Call_PushCell(target);
		Call_PushCell(g_iJump[target]);
		Call_PushCell(speed);
		Call_PushCell(-1);
		Call_PushFloat(-1.0);
		Call_PushFloat(-1.0);
		Call_PushFloat(-1.0);
		Call_PushFloat(-1.0);
		Call_PushFloat(-1.0);
		Call_PushFloat(-1.0);
		Call_Finish();
		//PrintToChat(target, "jump %i sp %i", g_iJump[target], speed);
	}
	else
	{
		float origin[3];
		GetClientAbsOrigin(target, origin);

		float coeffsum = g_fRawGain[target];
		coeffsum /= g_iStrafeTick[target];
		coeffsum *= 100.0;

		float distance = GetVectorLength(g_fTraveledDistance[target]);

		if(distance > g_fTrajectory[target])
		{
			distance = g_fTrajectory[target];
		}

		float efficiency = 0.0;

		if(distance > 0.0)
		{
			efficiency = coeffsum * distance / g_fTrajectory[target];
		}

		coeffsum = RoundToFloor(coeffsum * 100.0 + 0.5) / 100.0;
		efficiency = RoundToFloor(efficiency * 100.0 + 0.5) / 100.0;

		Call_StartForward(JumpStatsForward);
		Call_PushCell(target);
		Call_PushCell(g_iJump[target]);
		Call_PushCell(speed);
		Call_PushCell(g_iStrafeCount[target]);
		Call_PushFloat(origin[2] - g_fOldHeight[target]);
		Call_PushFloat(coeffsum);
		Call_PushFloat(100.0 * g_iSyncedTick[target] / g_iStrafeTick[target]);
		Call_PushFloat(efficiency);
		Call_PushFloat(-1.0);
		Call_PushFloat(g_fAvgDiffFromPerf[target] / g_iAvgTicksNum[target]);
		Call_Finish();
	}
}

//int client, int offset, bool overlap, bool nopress
void StartStrafeForward(int client)
{
	Call_StartForward(StrafeStatsForward);
	Call_PushCell(client);
	Call_PushCell(g_iKeyTick[client] - g_iTurnTick[client]);
	Call_PushCell(view_as<int>(g_bOverlap[client]));
	Call_PushCell(view_as<int>(g_bNoPress[client]));
	Call_Finish();
}

//int client, int speed, float gain, float jss
void StartTickForward(int client)
{
	Call_StartForward(TickStatsForward);
	Call_PushCell(client);
	Call_PushCell(RoundToFloor(GetRunCmdVelocity(client, true)));
	Call_PushCell(view_as<int>((g_iTicksOnGround[client] == 0)));
	Call_PushFloat(g_fTickGain[client]);
	Call_PushFloat(g_fTickJss[client]);
	Call_Finish();
}

float GetRunCmdVelocity(int client, bool twodimensions)
{
	float vel[3];
	vel = g_fRunCmdVelVec[client];
	if(twodimensions)
	{
		vel[2] = 0.0;
	}
	return GetVectorLength(vel);
}

float NormalizeAngle(float ang)
{
	while (ang > 180.0)
	{
		ang -= 360.0;
	}

	while (ang < -180.0)
	{
		ang += 360.0;
	}
	return ang;
}

void PrintDebugMsg(int client, const char[] msg, any...)
{
	#if defined DEBUG
	char buffer[300];
	VFormat(buffer, sizeof(buffer), msg, 3);
	PrintToConsole(client, "BStat-Debug: %s", buffer);
	#endif
}
