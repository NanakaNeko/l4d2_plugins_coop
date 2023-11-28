//每行代码结束需填写“;”
#pragma semicolon 1
//强制新语法
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <colors>

#define PLUGIN_VERSION	"1.4.0"

char SI_Names[][] =
{
	"Unknown",
	"Smoker",
	"Boomer",
	"Hunter",
	"Spitter",
	"Jockey",
	"Charger",
	"Witch",
	"Tank",
	"Not SI"
};

float  g_fFallSpeedSafe, g_fFallSpeedFatal;
ConVar g_hFallSpeedSafe, g_hFallSpeedFatal;

bool   g_bShowPromptVariable;

public Plugin myinfo = 
{
	name 			= "l4d2_player_status",
	author 			= "豆瓣酱な | 死亡提示嫖至:sorallll",
	description 	= "幸存者各种提示.",
	version 		= PLUGIN_VERSION,
	url 			= "N/A"
}

public void OnPluginStart()
{
	HookEvent("round_end", Event_ShowPromptVariable);//回合结束.
	HookEvent("round_start", Event_RoundStart);//回合开始.
	HookEvent("finale_vehicle_leaving", Event_ShowPromptVariable);//救援离开
	HookEvent("player_ledge_grab", Event_PlayerLedgeGrab);//幸存者挂边.
	HookEvent("player_incapacitated", Event_Incapacitate);//玩家倒下.
	
	g_hFallSpeedSafe = FindConVar("fall_speed_safe");
	g_hFallSpeedFatal = FindConVar("fall_speed_fatal");
	g_hFallSpeedSafe.AddChangeHook(IsConVarChanged);
	g_hFallSpeedFatal.AddChangeHook(IsConVarChanged);

	RegConsoleCmd("sm_zs", Kill_Player, "自杀指令");
	RegConsoleCmd("sm_kill", Kill_Player, "自杀指令");
}

//地图开始.
public void OnMapStart()
{
	IsGetCvars();
	g_bShowPromptVariable = false;
}

public void IsConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsGetCvars();
}

void IsGetCvars()
{
	g_fFallSpeedSafe = g_hFallSpeedSafe.FloatValue;
	g_fFallSpeedFatal = g_hFallSpeedFatal.FloatValue;
}

//回合结束或救援离开.
public void Event_ShowPromptVariable(Event event, const char[] name, bool dontBroadcast)
{
	g_bShowPromptVariable = true;
}

//回合开始.
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bShowPromptVariable = false;
}

//幸存者挂边.
public void Event_PlayerLedgeGrab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (g_bShowPromptVariable)
		return;
	
	if(IsValidClient(client) && GetClientTeam(client) == 2)
		CPrintToChatAll("{default}[{green}!{default}] {blue}%s {olive}挂边了", GetTrueName(client));//聊天窗提示.
}

public void OnClientPutInServer(int client) 
{
	SDKHook(client, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlivePost);
}

// ------------------------------------------------------------------------
// 死亡提示
// ------------------------------------------------------------------------
void OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damagetype) 
{
	if (g_bShowPromptVariable)
		return;

	if (victim < 1 || victim > MaxClients || !IsClientInGame(victim) || GetClientTeam(victim) != 2 || GetEntProp(victim, Prop_Data, "m_iHealth") > 0)
		return;

	if (IsValidClient(attacker)) 
	{
		switch (GetClientTeam(attacker)) 
		{
			case 2: 
				CPrintToChatAll("{default}[{green}!{default}] {olive}%s {default}黑死了 {blue}%s", GetTrueName(attacker), GetTrueName(victim));//聊天窗提示.
			case 3: 
			{
				int zombie_class = GetEntProp(attacker, Prop_Send, "m_zombieClass");
				if(zombie_class >= 1 && zombie_class <= 6)
					CPrintToChatAll("{default}[{green}!{default}] {red}%N{green}(%s) {default}杀死了 {olive}%s", attacker, IsFakeClient(attacker)?"AI":SI_Names[zombie_class], GetTrueName(victim));//聊天窗提示.
				else if(zombie_class == 7)
					CPrintToChatAll("{default}[{green}!{default}] {blue}女巫 {default}杀死了 {blue}%s", GetTrueName(victim));//聊天窗提示.
				else if(zombie_class == 8)
					CPrintToChatAll("{default}[{green}!{default}] {olive}坦克{green}%s {default}杀死了 {blue}%s", GetTankName(attacker), GetTrueName(victim));
			}
		}
	}
	else
	{
		if (IsValidEntity(attacker)) 
		{
			char classname[32];
			GetEntityClassname(attacker, classname, sizeof classname);

			if (damagetype & DMG_DROWN && GetEntProp(victim, Prop_Data, "m_nWaterLevel") > 1)
				CPrintToChatAll("{default}[{green}!{default}] {blue}%s {olive}淹死了", GetTrueName(victim));//聊天窗提示.
			else if (damagetype & DMG_FALL && RoundToFloor(Pow(GetEntPropFloat(victim, Prop_Send, "m_flFallVelocity") / (g_fFallSpeedFatal - g_fFallSpeedSafe), 2.0) * 100.0) == damage)
				CPrintToChatAll("{default}[{green}!{default}] {blue}%s {olive}摔死了,亲亲也起不来了", GetTrueName(victim));//聊天窗提示.
			else if (strcmp(classname, "worldspawn") == 0 && damagetype == 131072)
				CPrintToChatAll("{default}[{green}!{default}] {blue}%s {olive}流血而死", GetTrueName(victim));//聊天窗提示.
			else if (strcmp(classname, "infected") == 0)
				CPrintToChatAll("{default}[{green}!{default}] {olive}小僵尸 {default}杀死了 {blue}%s", GetTrueName(victim));//聊天窗提示.
			else if (StrEqual(classname, "witch", false))
				CPrintToChatAll("{default}[{green}!{default}] {blue}女巫 {default}杀死了 {blue}%s", GetTrueName(victim));//聊天窗提示.
			else if (strcmp(classname, "insect_swarm") == 0)
				CPrintToChatAll("{default}[{green}!{default}] {olive}踩痰达人 {blue}%s {default}已死亡", GetTrueName(victim));//聊天窗提示.
			else
				CPrintToChatAll("{default}[{green}!{default}] {blue}%s {olive}已死亡", GetTrueName(victim));//聊天窗提示.
		}
	}
}

//victim
//玩家倒下.
public void Event_Incapacitate(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bShowPromptVariable)
		return;
	
	int damagetype = GetEventInt(event, "type");
	int entity = GetEventInt(event, "attackerentid");
	int client = GetClientOfUserId(event.GetInt("userid"));
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if (IsValidClient(client) && GetClientTeam(client) == 2)
	{
		if (IsValidClient(attacker))
		{
			switch (GetClientTeam(attacker)) 
			{
				case 2: 
					CPrintToChatAll("{default}[{green}!{default}] {olive}%s {default}黑倒了 {blue}%s", GetTrueName(attacker), GetTrueName(client));//聊天窗提示.
				case 3: 
				{
					int zombie_class = GetEntProp(attacker, Prop_Send, "m_zombieClass");
					if(zombie_class >= 1 && zombie_class <= 6)
						CPrintToChatAll("{default}[{green}!{default}] {red}%N{green}(%s) {default}制服了 {olive}%s", attacker, IsFakeClient(attacker)?"AI":SI_Names[zombie_class], GetTrueName(client));//聊天窗提示.
					else if(zombie_class == 7)
						CPrintToChatAll("{default}[{green}!{default}] {blue}女巫 {default}制服了 {blue}%s", GetTrueName(client));//聊天窗提示.
					else if(zombie_class == 8)
						CPrintToChatAll("{default}[{green}!{default}] {olive}坦克{green}%s {default}制服了 {blue}%s", GetTankName(attacker), GetTrueName(client));
				}
			}
		}
		else
		{
			if (IsValidEntity(entity)) 
			{
				char classname[32];
				GetEntityClassname(entity, classname, sizeof(classname));

				if (damagetype & DMG_DROWN && GetEntProp(client, Prop_Data, "m_nWaterLevel") > 1)
					CPrintToChatAll("{default}[{green}!{default}] {blue}%s {olive}晕倒了", GetTrueName(client));//聊天窗提示.
				else if (damagetype & DMG_FALL)
					CPrintToChatAll("{default}[{green}!{default}] {blue}%s {olive}摔倒了,需要亲亲才能起来", GetTrueName(client));//聊天窗提示.
				else if (strcmp(classname, "infected") == 0)
					CPrintToChatAll("{default}[{green}!{default}] {olive}小僵尸 {default}制服了 {blue}%s", GetTrueName(client));//聊天窗提示.
				else if (StrEqual(classname, "witch", false))
					CPrintToChatAll("{default}[{green}!{default}] {blue}女巫 {default}制服了 {blue}%s", GetTrueName(client));//聊天窗提示.
				else if (strcmp(classname, "insect_swarm") == 0)
					CPrintToChatAll("{default}[{green}!{default}] {olive}踩痰达人 {blue}%s {default}倒下了", GetTrueName(client));//聊天窗提示.
				else
					CPrintToChatAll("{default}[{green}!{default}] {blue}%s {olive}倒下了", GetTrueName(client));//聊天窗提示.
			}
		}
	}
}

public Action Kill_Player(int client, int args)
{
	if(IsAliveSurvivor(client))
	{
		ForcePlayerSuicide(client);
		CPrintToChatAll("{default}[{green}!{default}] {olive}生还者 {blue}%N {olive}失去梦想,殒命了", client);
	}
	else if(IsAliveInfected(client))
	{
		ForcePlayerSuicide(client);
		CPrintToChatAll("{default}[{green}!{default}] {olive}感染者 {red}%N {olive}失去梦想,归天了", client);
	}
	else
		CPrintToChat(client, "{default}[{green}!{default}] {olive}当前状态无法自杀");

	return Plugin_Handled;
}

stock bool IsAliveSurvivor(int client)
{
    return IsValidClient(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 2;
}

stock bool IsAliveInfected(int client)
{
    return IsValidClient(client) && !IsFakeClient(client) && IsPlayerAlive(client) && GetClientTeam(client) == 3;
}

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

char[] GetTankName(int client)
{
	char sName[32];
	if (!IsFakeClient(client))
		FormatEx(sName, sizeof(sName), "{blue}[%N]", client);
	else
	{
		GetClientName(client, sName, sizeof(sName));
		SplitString(sName, "Tank", sName, sizeof(sName));
		StrCat(sName, sizeof(sName), "{blue}[AI]");
	}
	return sName;
}

char[] GetTrueName(int client)
{
	char g_sName[32];
	int Bot = IsClientIdle(client);
	
	if(Bot != 0)
		Format(g_sName, sizeof(g_sName), "闲置:%N", Bot);
	else
		GetClientName(client, g_sName, sizeof(g_sName));
	return g_sName;
}

int IsClientIdle(int client)
{
	if (!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		return 0;

	return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}
