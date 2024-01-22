#include <sdktools>
#include <sdkhooks>
#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <shavit>
bool g_bShavit = false;

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "bhop get stats",
	author = "Nimmy",
	description = "central plugin to call bhop stats",
	version = "1.3",
	url = "https://github.com/Nimmy2222/bhop-get-stats"
}

#define BHOP_FRAMES 10
#define YAW 1
#define FORWARDMOVE 0
#define SIDEMOVE 1
#define LEFT 0
#define RIGHT 1

bool g_bTouchesWall[MAXPLAYERS + 1];
bool g_bJumpedThisTick[MAXPLAYERS + 1];
bool g_bOverlap[MAXPLAYERS + 1];
bool g_bNoPress[MAXPLAYERS + 1];
bool g_bSawTurn[MAXPLAYERS + 1];
bool g_bSawPress[MAXPLAYERS + 1];

int g_iTicksOnGround[MAXPLAYERS + 1];
int g_iStrafeTick[MAXPLAYERS + 1];
int g_iSyncedTick[MAXPLAYERS + 1];
int g_iJump[MAXPLAYERS + 1];
int g_iStrafeCount[MAXPLAYERS + 1];
int g_iTurnTick[MAXPLAYERS + 1];
int g_iKeyTick[MAXPLAYERS + 1];
int g_iTurnDir[MAXPLAYERS + 1];
int g_iCmdNum[MAXPLAYERS + 1];

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

	g_bShavit = LibraryExists("shavit");

	JumpStatsForward = new GlobalForward("BhopStat_JumpForward", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Float,
	 																Param_Float, Param_Float, Param_Float, Param_Float, Param_Float);
	//int client, int jump, int speed, int heightdelta, int strafecount, float gain, float sync, float eff, float yawwing
	//yawing not done
	//add airpath, veer, jumpoff angle on j1

	StrafeStatsForward = new GlobalForward("BhopStat_StrafeForward", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	//int client, int offset, bool overlap, bool nopress

	TickStatsForward = new GlobalForward("BhopStat_TickForward", ET_Ignore, Param_Cell, Param_Cell, Param_Array, Param_Array, Param_Cell,
																Param_Float, Param_Float, Param_Float, Param_Float);
	//int client, int buttons, f[3] vel, f[3] angles, bool inbhop, f speed, f gain, f jss, f yawDiff

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

public void OnLibraryAdded(const char[] name)
{
	if(StrEqual(name, "shavit"))
	{
		g_bShavit = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if(StrEqual(name, "shavit"))
	{
		g_bShavit = false;
	}
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

	if(g_iJump[client] > 0 && g_iStrafeTick[client] == 0)
	{
		return;
	}

	g_iJump[client]++;
	g_bJumpedThisTick[client] = true;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3])
{
	if(!IsPlayerAlive(client))
	{
		return Plugin_Continue;
	}
	if((g_bShavit && Shavit_IsReplayEntity(client)) || IsFakeClient(client))
	{
		//in prog
	}
	else
	{
		g_fLastRunCmdVelVec[client] = g_fRunCmdVelVec[client];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", g_fRunCmdVelVec[client]);
		Bgs_ProcessRunCmd(client, buttons, vel, angles, GetEntityFlags(client), GetEntityMoveType(client));
	}

	return Plugin_Continue;
}

public void Bgs_ProcessRunCmd(int client, int &buttons, float vel[3], float angles[3], int flags, MoveType movetype)
{
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
				g_bSawPress[client] = false;
				g_bSawTurn[client] = false;
			}
			return;
		}

		if ((buttons & IN_JUMP) > 0 && g_iTicksOnGround[client] == 1)
		{
			g_iTicksOnGround[client] = 0;
			float currpos[3];
			GetClientAbsOrigin(client, currpos); //player landed, mustve jumped right?, calc veer
			float xAxisVeer = FloatAbs(currpos[0] - g_fLastJumpPosition[client][0]);
			float yAxisVeer = FloatAbs(currpos[1] - g_fLastJumpPosition[client][1]);
			g_fLastVeer[client] = xAxisVeer >= yAxisVeer ? yAxisVeer:xAxisVeer; //something about this wrong, kinda close to distbug but not fully, might need to wait till jump land
		}
	}
	else
	{
		g_iTicksOnGround[client] = 0;
	}

	if(movetype == MOVETYPE_NONE || movetype == MOVETYPE_NOCLIP || movetype == MOVETYPE_LADDER || GetEntProp(client, Prop_Data, "m_nWaterLevel") >= 2)
	{
		g_iTicksOnGround[client] = BHOP_FRAMES + 1;
	}
}


public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3])
{
	if(!IsPlayerAlive(client))
	{
		return;
	}
	if((g_bShavit && Shavit_IsReplayEntity(client)) || IsFakeClient(client))
	{
		//in prog
	}
	else
	{
		Bgs_ProcessPostRunCmd(client, buttons, vel, angles);
	}
}

void Bgs_ProcessPostRunCmd(int client, int buttons, const float vel[3], const float angles[3])
{
	g_fYawDifference[client] = NormalizeAngle(angles[YAW] - g_fLastAngles[client][YAW]);

	if(g_iTicksOnGround[client] == 0)
	{
		g_fTickJss[client] = 0.0;
		if(g_fYawDifference[client] != 0.0)
		{
			float finalJss = 0.0;
			if(g_fRunCmdVelVec[client][1] != 0.0 && g_fRunCmdVelVec[client][0] != 0.0 && (vel[0] != 0.0 || vel[1] != 0.0))
			{
				float perfectAngle = RadToDeg(ArcTangent2(g_fRunCmdVelVec[client][1], g_fRunCmdVelVec[client][0]));
				float adjJss = 0.0;

				if (vel[0] != 0.0 && vel[1] == 0.0)
				{
					adjJss = (g_fYawDifference[client] > 0.0 ? 1.0:-1.0) * 90.0;
				}

				if (vel[0] != 0.0 && vel[1] != 0.0)
				{
					adjJss = (vel[1] > 0.0 ? -1.0 : 1.0) * 45.0;
				}

				adjJss = vel[0] < 0.0 ? (adjJss * -1.0) : adjJss;
				perfectAngle += adjJss;

				finalJss = FloatAbs(g_fYawDifference[client] / NormalizeAngle(perfectAngle - g_fLastAngles[client][YAW]));
			}
			else
			{
				float perfectYawDiff = RadToDeg(ArcTangent(30 / GetRunCmdVelocity(client, true)));
				finalJss = FloatAbs(g_fYawDifference[client] / perfectYawDiff);
			}

			g_fAvgDiffFromPerf[client] += finalJss;
			g_fTickJss[client] = finalJss;
		}

		//offset shit
		if(g_iCmdNum[client] >= 1)
		{
			if(
				(vel[1] * g_fLastVel[client][SIDEMOVE] < 0 || (g_fLastVel[client][SIDEMOVE] == 0 && vel[1] != 0)) ||
				(vel[0] * g_fLastVel[client][FORWARDMOVE] < 0 || g_fLastVel[client][FORWARDMOVE] == 0 && vel[0] != 0))
			{
				g_iKeyTick[client] = g_iCmdNum[client];
				g_iStrafeCount[client]++;
				g_bSawPress[client] = true;
			}
		}

		if(g_fYawDifference[client] > 0)
		{
			if(g_iTurnDir[client] == RIGHT && g_iCmdNum[client] > 1)
			{
				g_iTurnTick[client] = g_iCmdNum[client];
				g_bSawTurn[client] = true;
			}

			g_iTurnDir[client] = LEFT;
		}
		else if(g_fYawDifference[client] < 0)
		{
			if(g_iTurnDir[client] == LEFT && g_iCmdNum[client] > 1)
			{
				g_iTurnTick[client] = g_iCmdNum[client];
				g_bSawTurn[client] = true;
			}

			g_iTurnDir[client] = RIGHT;
		}

		bool overlapThisTick = false;
		if(((buttons & IN_MOVELEFT) && (buttons & IN_MOVERIGHT)) || ((buttons & IN_FORWARD) && (buttons & IN_BACK)))
		{
			g_bOverlap[client] = true;
			overlapThisTick = true;
		}

		if(vel[SIDEMOVE] == 0.0 && vel[FORWARDMOVE] == 0.0 && !overlapThisTick)
		{
			g_bNoPress[client] = true;
		}

		if(g_bSawPress[client] && g_bSawTurn[client])
		{
			StartStrafeForward(client);
			g_bOverlap[client] = false;
			g_bNoPress[client] = false;
			g_bSawPress[client] = false;
			g_bSawTurn[client] = false;
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

			if(g_bTouchesWall[client] && gaincoeff > 0.5)
			{
				gaincoeff -= 1.0;
				gaincoeff = FloatAbs(gaincoeff);
			}
			g_fRawGain[client] += gaincoeff;
			g_fTickGain[client] = gaincoeff;
		}
		g_iCmdNum[client]++;
	}
	StartTickForward(client, buttons, vel, angles);

	if(g_bTouchesWall[client])
	{
		g_bTouchesWall[client] = false;
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
	}

	g_fLastAngles[client] = angles;
	g_fLastVel[client] = vel;

	return;
}

//int client, int jump, int speed, int heightdelta, int strafecount, float gain, float sync, float eff, float yawwing
void StartJumpForward(int client)
{
	float velocity[3];
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", velocity);
	velocity[2] = 0.0;
	int speed = RoundToFloor(GetVectorLength(velocity));

	if(g_iJump[client] == 1) //probs a better way to do this idk
	{
		Call_StartForward(JumpStatsForward);
		Call_PushCell(client);
		Call_PushCell(g_iJump[client]);
		Call_PushCell(speed);
		Call_PushCell(-1);
		Call_PushFloat(-1.0);
		Call_PushFloat(-1.0);
		Call_PushFloat(-1.0);
		Call_PushFloat(-1.0);
		Call_PushFloat(-1.0);
		Call_PushFloat(-1.0);
		Call_Finish();
	}
	else
	{
		float origin[3];
		GetClientAbsOrigin(client, origin);

		float coeffsum = g_fRawGain[client];
		coeffsum /= g_iStrafeTick[client];
		coeffsum *= 100.0;

		float distance = GetVectorLength(g_fTraveledDistance[client]);

		if(distance > g_fTrajectory[client])
		{
			distance = g_fTrajectory[client];
		}

		float efficiency = 0.0;

		if(distance > 0.0)
		{
			efficiency = coeffsum * distance / g_fTrajectory[client];
		}

		coeffsum = RoundToFloor(coeffsum * 100.0 + 0.5) / 100.0;
		efficiency = RoundToFloor(efficiency * 100.0 + 0.5) / 100.0;

		Call_StartForward(JumpStatsForward);
		Call_PushCell(client);
		Call_PushCell(g_iJump[client]);
		Call_PushCell(speed);
		Call_PushCell(g_iStrafeCount[client]);
		Call_PushFloat(origin[2] - g_fOldHeight[client]);
		Call_PushFloat(coeffsum);
		Call_PushFloat(100.0 * g_iSyncedTick[client] / g_iStrafeTick[client]);
		Call_PushFloat(efficiency);
		Call_PushFloat(-1.0);
		Call_PushFloat(g_fAvgDiffFromPerf[client] / g_iStrafeTick[client]);
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

//int client, int buttons, f[3] vel, f[3] angles, bool inbhop, f speed, f gain, f jss, f yawDiff
void StartTickForward(int client, int buttons, const float vel[3], const float angles[3])
{
	Call_StartForward(TickStatsForward);
	Call_PushCell(client);
	Call_PushCell(buttons);
	Call_PushArray(vel, 3);
	Call_PushArray(angles, 3);
	Call_PushCell(view_as<int>((g_iTicksOnGround[client] == 0)));
	Call_PushFloat(GetRunCmdVelocity(client, true));
	Call_PushFloat(g_fTickGain[client]);
	Call_PushFloat(g_fTickJss[client]);
	Call_PushFloat(g_fYawDifference[client]);
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
