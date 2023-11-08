#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define UNLOCK 0
#define LOCK 1

ConVar sb_unstick, cv_LockDoorEnable, cv_ForceLockDoor, cv_MinSurvivorPercent, cv_TimeUnlockDoor, cv_TankAliveLock;
int g_iEndCheckpointDoor, i_MinSurvivorPercent, i_TimeUnlockDoor, tmrNum;
bool b_FinalMap, b_UnlockDoor, b_TankAliveLock, b_CTimer;

public Plugin myinfo = 
{
	name = "[L4D2]终点安全门锁定",
	author = "奈",
	description = "Locks Saferoom Door Until Enough People Open It.",
	version = "1.0.5",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public void OnPluginStart()
{
	cv_LockDoorEnable = CreateConVar("lock_door_enable", "1", "开关插件 0:关闭 1:开启", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cv_ForceLockDoor = CreateConVar("lock_door_force", "0", "锁死终点安全门无法打开 0:关闭 1:开启", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cv_MinSurvivorPercent = CreateConVar("lock_door_persent", "70", "百分之多少人可以打开安全门 0:关闭", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	cv_TimeUnlockDoor = CreateConVar("unlock_door_time", "5", "需要几秒解锁安全门", FCVAR_NOTIFY, true, 0.0);
	cv_TankAliveLock = CreateConVar("lock_door_tank_alive", "1", "当前场上有存活坦克是否锁定安全门 1:锁定 0:不锁定", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(cv_LockDoorEnable, CvarChanged);
	HookConVarChange(cv_MinSurvivorPercent, CvarChanged);
	HookConVarChange(cv_TimeUnlockDoor, CvarChanged);
	HookConVarChange(cv_TankAliveLock, CvarChanged);
	i_MinSurvivorPercent = GetConVarInt(cv_MinSurvivorPercent);
	i_TimeUnlockDoor = GetConVarInt(cv_TimeUnlockDoor);
	b_TankAliveLock = GetConVarBool(cv_TankAliveLock);
	sb_unstick = FindConVar("sb_unstick");
	HookEvent("round_start", Event_RoundStart);
}

public void OnMapStart()
{
	b_FinalMap = false;
}

public void OnConfigsExecuted()
{
	if(L4D_IsMissionFinalMap(true))
		b_FinalMap = true;
}

void CvarChanged(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	i_MinSurvivorPercent = GetConVarInt(cv_MinSurvivorPercent);
	i_TimeUnlockDoor = GetConVarInt(cv_TimeUnlockDoor);
	b_TankAliveLock = GetConVarBool(cv_TankAliveLock);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(1.0, tmrStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iEndCheckpointDoor = -1;
}

Action tmrStart(Handle timer)
{
	if(!cv_LockDoorEnable.BoolValue)
		return Plugin_Continue;

	if (b_FinalMap)
		return Plugin_Continue;

	b_UnlockDoor = false;
	b_CTimer = false;
	InitDoor();
	sb_unstick.SetBool(false);
	return Plugin_Continue;
}

Action OnUse_EndCheckpointDoor(int door, int client, int caller, UseType type, float value)
{
	if (cv_ForceLockDoor.BoolValue)
	{
		PrintHintTextToAll("安全门已锁死, 无法打开!");
		return Plugin_Handled;
	}

	if (!cv_LockDoorEnable.BoolValue)
		return Plugin_Continue;

	if (b_FinalMap)
		return Plugin_Continue;
	
	if (IsSurvivor(client))
	{
		if(IsFakeClient(client))
			return Plugin_Handled;

		if (!IsPlayerAlive(client))
			return Plugin_Continue;
		
		int state = GetEntProp(door, Prop_Data, "m_eDoorState");
		if (state==DOOR_STATE_CLOSED)
		{
			if(!b_UnlockDoor)
			{
				//坦克存活锁定安全门
				if(b_TankAliveLock)
				{
					int tanknum = 0;
					for(int j = 1;j <= MaxClients; j++)
					{
						if(IsAliveTank(j))
							tanknum++;
					}
					if(tanknum > 0)
					{
						PrintHintTextToAll("当前还有%d个坦克存活,安全门锁定", tanknum);
						return Plugin_Handled;
					}
				}
				
				//根据玩家数量锁定安全门
				if(i_MinSurvivorPercent > 0)
				{
					float clientOrigin[3];
					float doorOrigin[3];
					int iParam = 0, iReached = 0;
					GetEntPropVector(door, Prop_Send, "m_vecOrigin", doorOrigin);
					for (int i = 1; i <= MaxClients; i++)
					{
						if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && !IsPlayerIncap(i))
						{
							iParam ++;
							GetClientAbsOrigin(i, clientOrigin);
							if (GetVectorDistance(clientOrigin, doorOrigin, true) <= 1000 * 1000)
								iReached++;
						}
					}

					iParam = RoundToCeil(i_MinSurvivorPercent / 100.0 * iParam);
					if(iReached < iParam)
					{
						PrintHintTextToAll("当前有%d人到达安全屋附近(需%d人解锁)", iReached, iParam);
						return Plugin_Handled;
					}
				}

				if(!b_CTimer)
				{
					//解锁安全门
					tmrNum = 0;
					CreateTimer(1.0, tmrUnlockDoor, _, TIMER_REPEAT);
					b_CTimer = true;
				}
			}
		}
	}

	return Plugin_Continue;
}

Action tmrUnlockDoor(Handle timer)
{
	if(tmrNum < i_TimeUnlockDoor)
	{
		PrintHintTextToAll("安全门还有 %d 秒解锁", i_TimeUnlockDoor - tmrNum);
		PlaySound("ambient/alarms/klaxon1.wav");
		tmrNum++;
		return Plugin_Continue;
	}
	PrintHintTextToAll("安全门已解锁");
	b_UnlockDoor = true;
	ControlDoor(g_iEndCheckpointDoor, UNLOCK);
	return Plugin_Stop;
}

//初始化
void InitDoor()
{
	g_iEndCheckpointDoor = L4D_GetCheckpointLast();
	if(g_iEndCheckpointDoor == -1)
	{
		g_iEndCheckpointDoor = FindEndSafeRoomDoor();
		return;
	}
	else
	{
		char sModelName[128];
		GetEntPropString(g_iEndCheckpointDoor, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));
		if( strcmp(sModelName, "models/props_doors/checkpoint_door_01.mdl", false) == 0 ||
			strcmp(sModelName, "models/props_doors/checkpoint_door_-01.mdl", false) == 0 ||
			strcmp(sModelName, "models/lighthouse/checkpoint_door_lighthouse01.mdl", false) == 0) //选错安全门重新抓
		{
			g_iEndCheckpointDoor = FindEndSafeRoomDoor();
		}
	}

	if(g_iEndCheckpointDoor == -1)
	{
		g_iEndCheckpointDoor = 0;
		return;
	}
	
	ControlDoor(g_iEndCheckpointDoor, LOCK);

	SDKHook(g_iEndCheckpointDoor, SDKHook_Use, OnUse_EndCheckpointDoor);

	g_iEndCheckpointDoor = EntIndexToEntRef(g_iEndCheckpointDoor);
}

//找终点安全屋
int FindEndSafeRoomDoor()
{
	int ent = MaxClients+1;
	char sModelName[128];
	while((ent = FindEntityByClassname(ent, "prop_door_rotating_checkpoint")) != -1)
	{
		if(!IsValidEntity(ent)) continue;

		GetEntPropString(ent, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));
		if( strcmp(sModelName, "models/props_doors/checkpoint_door_02.mdl", false) == 0 ||
			strcmp(sModelName, "models/props_doors/checkpoint_door_-02.mdl", false) == 0 ||
			strcmp(sModelName, "models/lighthouse/checkpoint_door_lighthouse02.mdl", false) == 0)
		{
			return ent;
		}
	}

	return -1;
}

//控制安全门
void ControlDoor(int entity, int iOperation)
{
	switch (iOperation)
	{
		case LOCK:
		{
			AcceptEntityInput(entity, "Close");
			AcceptEntityInput(entity, "Lock");
			AcceptEntityInput(entity, "ForceClosed");
			SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", LOCK);
		}
		case UNLOCK:
		{
			SetEntProp(entity, Prop_Data, "m_hasUnlockSequence", UNLOCK);
			AcceptEntityInput(entity, "Unlock");
			AcceptEntityInput(entity, "ForceClosed");
			AcceptEntityInput(entity, "Open");
		}
	}
}

//播放声音.
void PlaySound(const char[] sample)
{
	EmitSoundToAll(sample, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}

stock bool IsValidPlayer(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

//是否是生还者
stock bool IsSurvivor(int client)
{
	return IsValidPlayer(client) && GetClientTeam(client) == 2;
}

// 玩家是否倒地
stock bool IsPlayerIncap(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

// 是否是存活坦克
stock bool IsAliveTank(int client)
{
	return IsValidPlayer(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8 && IsPlayerAlive(client);
}