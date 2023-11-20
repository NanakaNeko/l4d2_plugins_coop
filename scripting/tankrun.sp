#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

ConVar cv_LimitTank, cv_SpawnTankTime, cv_SniperHealth, cv_LimitPlayer, cv_CanPlayTank;
Handle g_hTimer;
bool CanPlayTank[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "[L4D2]坦克润",
	author = "奈",
	description = "tank run",
	version = "1.6",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public void OnPluginStart()
{
	cv_LimitTank = CreateConVar("l4d2_limit_tank", "8", "限制坦克数量", FCVAR_NOTIFY, true);
	cv_SpawnTankTime = CreateConVar("l4d2_sapwn_tank_time", "5", "每隔多少秒生成一个坦克", FCVAR_NOTIFY, true, 1.0);
	cv_SniperHealth = CreateConVar("l4d2_sniper_restore_health", "60", "狙击类武器救起倒地玩家恢复多少虚血量", FCVAR_NOTIFY, true, 1.0, true, 100.0);
	cv_LimitPlayer = CreateConVar("l4d2_player_tank_number", "2", "玩家克上限", FCVAR_NOTIFY, true, 0.0);
	cv_CanPlayTank = CreateConVar("l4d2_can_play_tank", "1", "是否可以玩克", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(cv_CanPlayTank, CvarChanged);

	HookEvent("player_spawn", Event_TankSpawn);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("map_transition", Event_RoundEnd);
	HookEvent("mission_lost", Event_RoundEnd);
	HookEvent("player_hurt", Event_PlayerHurt);

	RegConsoleCmd("sm_team2", cmd_Team2, "生还");
	RegConsoleCmd("sm_team3", cmd_PlayTank, "玩克");
	RegConsoleCmd("sm_playtank", cmd_PlayTank, "玩克");

	SetCvar();
}

void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(!GetConVarBool(cv_CanPlayTank))
		ChangeTeamToSurvivor();
}

public void OnPluginEnd()
{
	FindConVar("first_aid_kit_use_duration").RestoreDefault();
	FindConVar("survivor_revive_health").RestoreDefault();
	FindConVar("survivor_revive_duration").RestoreDefault();
	FindConVar("survivor_crawl_speed").RestoreDefault();
	FindConVar("rescue_min_dead_time").RestoreDefault();
}

public void OnConfigsExecuted()
{
	SetCvar();
}

public void OnMapStart()
{
	delete g_hTimer;
	CreateTimer(40.0, timer_notify, _, TIMER_FLAG_NO_MAPCHANGE);
	SetCvar();
	for(int i = 1;i <= MaxClients; i++)
		CanPlayTank[i] = true;
}

void SetCvar()
{
	SetConVarInt(FindConVar("first_aid_kit_use_duration"), 1);
	SetConVarInt(FindConVar("survivor_revive_health"), 60);
	SetConVarInt(FindConVar("survivor_revive_duration"), 1);
	SetConVarInt(FindConVar("survivor_crawl_speed"), 50);
	SetConVarInt(FindConVar("rescue_min_dead_time"), 3);
}

Action timer_notify(Handle timer)
{
	PrintToChatAll("\x04[公告] \x05狙击类武器可以救起倒地玩家,请合理使用");
	return Plugin_Continue;
}

public void GiveMedical()
{
	int flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidSurvivor(client) && IsPlayerAlive(client)) 
		{
			Delete(client);
			FakeClientCommand(client, "give first_aid_kit");
			FakeClientCommand(client, "give pain_pills");
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

void Delete(int client)
{
	for (int slot = 3; slot < 5; slot++)
	{
		int item = GetPlayerWeaponSlot(client, slot);
		if (IsValidEntity(item) && IsValidEdict(item))
		{
			RemovePlayerItem(client, item);
		}
	}
}

//出门发药包，开始生成坦克
public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	GiveMedical();
	g_hTimer = CreateTimer(GetConVarFloat(cv_SpawnTankTime), timer_spawntank, _, TIMER_REPEAT);
	return Plugin_Stop;
}

Action timer_spawntank(Handle timer)
{
    if(GetTankNumber() <= GetConVarInt(cv_LimitTank))
        SpawnTank();
    return Plugin_Continue;
}

//救倒地玩家
public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (IsValidSurvivor(attacker) && IsValidSurvivor(victim) && IsPlayerIncap(victim) && !IsPlayerFalling(victim))
	{
		int i_weapon = -1;
		i_weapon = GetPlayerWeaponSlot(attacker, 0);
		if (IsValidEntity(i_weapon))
		{
			char weaponname[64];
			GetEntityClassname(i_weapon, weaponname, sizeof(weaponname));
			if(ClearSniperAmmo(i_weapon, weaponname))
			{
				SetEntProp(victim, Prop_Send, "m_isIncapacitated", 0);
				SetEntProp(victim, Prop_Send, "m_iHealth", 1);
				SetEntPropFloat(victim, Prop_Send, "m_healthBufferTime", GetGameTime());
				SetEntPropFloat(victim, Prop_Send, "m_healthBuffer", GetConVarFloat(cv_SniperHealth));
			}
		}
	}
}

//清空弹夹
bool ClearSniperAmmo(int weapon, const char[] weaponname)
{
	if(strcmp(weaponname, "weapon_hunting_rifle") == 0 ||
		strcmp(weaponname, "weapon_sniper_military") == 0 ||
		strcmp(weaponname, "weapon_sniper_scout") == 0 || 
		strcmp(weaponname, "weapon_sniper_awp") == 0)
	{
		SetEntProp(weapon, Prop_Send, "m_iClip1", 0);
		return true;
	}
	else
		return false;
}

void Event_RoundStart(Event event, const char []name, bool dontBroadcast)
{
	delete g_hTimer;
	ReplaceWeapon();
}

//更改狙击武器只能拿一次
Action ReplaceWeapon()
{
	for (int entity = 1; entity <= GetEntityCount(); entity++)
	{
		if (IsValidEntity(entity))
		{
			char entityname[128];
			GetEntityClassname(entity, entityname, sizeof(entityname));
			if (strcmp(entityname, "weapon_spawn") == 0)
			{
				if (GetEntProp(entity, Prop_Data, "m_weaponID") == 6 ||
					GetEntProp(entity, Prop_Data, "m_weaponID") == 10 ||
					GetEntProp(entity, Prop_Data, "m_weaponID") == 35 ||
					GetEntProp(entity, Prop_Data, "m_weaponID") == 36)
					DispatchKeyValue(entity, "count", "1");
			}
			else
			{
				if (strcmp(entityname, "weapon_hunting_rifle_spawn") == 0 ||
					strcmp(entityname, "weapon_sniper_military_spawn") == 0 ||
					strcmp(entityname, "weapon_sniper_awp_spawn") == 0 ||
					strcmp(entityname, "weapon_sniper_scout_spawn") == 0)
					DispatchKeyValue(entity, "count", "1");
			}
		}
	}
	return Plugin_Continue;
}

void Event_RoundEnd(Event event, const char []name, bool dontBroadcast)
{
	delete g_hTimer;
	ChangeTeamToSurvivor();
}

void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if(GetTankNumber() > GetConVarInt(cv_LimitTank) && IsTank(client))
	{
		if(IsFakeClient(client))
			KickClient(client);
		else
			KickClient(GetAnyTankBot());
	}
}

Action cmd_PlayTank(int client, int args)
{
	if(!GetConVarBool(cv_CanPlayTank))
	{
		PrintToChat(client, "\x04[提示] \x05游玩坦克已经禁用");
		return Plugin_Handled;
	}

	if(IsInfected(client))
	{
		PrintToChat(client, "\x04[提示] \x05你当前已经是坦克");
		return Plugin_Handled;
	}

	if(GetInfectedNumber() >= GetConVarInt(cv_LimitPlayer))
	{
		PrintToChat(client, "\x04[提示] \x05玩家坦克数量达到上限 \x04%d \x05个", GetConVarInt(cv_LimitPlayer));
		return Plugin_Handled;
	}

	if(CanPlayTank[client])
	{
		ChangeClientTeam(client, 3);
		CanPlayTank[client] = false;
	}
	else
		PrintToChat(client, "\x04[提示] \x05每局仅能游玩一次坦克");
		
	return Plugin_Handled;
}

Action cmd_Team2(int client, int args)
{
	if(IsInfected(client))
		ChangeClientTeam(client, 2);
	else if(IsValidSurvivor(client))
		PrintToChat(client, "\x04[提示] \x05你当前已经是生还者");
	else
		PrintToChat(client, "\x04[提示] \x05你当前不是正在游戏中玩家");
	return Plugin_Handled;
}

//更改玩家到生还
void ChangeTeamToSurvivor()
{
	for(int i = 1;i <= MaxClients; i++)
	{
		if(IsInfected(i) && !IsFakeClient(i))
			ChangeClientTeam(i, 2);
	}
}

//获取坦克数量
int GetTankNumber()
{
    int tanknum = 0;
    for(int i = 1;i <= MaxClients; i++)
    {
        if(IsAliveTank(i))
            tanknum++;
    }
    return tanknum;
}

//获取特感数量
int GetInfectedNumber()
{
	int infectednum = 0;
	for(int i = 1;i <= MaxClients; i++)
	{
		if(IsInfected(i) && !IsFakeClient(i))
			infectednum++;
	}
	return infectednum;
}

//获取随机坦克id
int GetAnyTankBot()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsTank(i) && IsFakeClient(i))
			return i;
	}
	return 0;
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

//是否是生还
stock bool IsValidSurvivor(int client)
{
	return IsValidClient(client) && IsClientConnected(client) && GetClientTeam(client) == 2;
}

// 是否是特感
stock bool IsInfected(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 3;
}

// 是否是坦克
stock bool IsTank(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8;
}

// 是否是存活坦克
stock bool IsAliveTank(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8 && IsPlayerAlive(client);
}

//倒地
stock bool IsPlayerIncap(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

//挂边
stock bool IsPlayerFalling(int client)
{
	return GetEntProp(client, Prop_Send, "m_isIncapacitated") && GetEntProp(client, Prop_Send, "m_isHangingFromLedge");
}

void SpawnTank()
{
	CheatCommand(GetAnyClient(), "z_spawn_old", "tank auto");
}

void CheatCommand(int client, const char[] command, const char[] arguments)
{
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
}

int GetAnyClient()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			return i;
	}
	return 0;
}