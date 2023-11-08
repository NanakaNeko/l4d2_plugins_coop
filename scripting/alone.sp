#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <colors>

#define	SMOKER	1
#define	BOOMER	2
#define	HUNTER	3
#define	SPITTER	4
#define	JOCKEY	5
#define	CHARGER 6

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

ConVar cv_Damage;

public Plugin myinfo = 
{
	name = "[L4D2]单人模式",
	author = "奈",
	description = "alone mode",
	version = "1.0",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public void OnPluginStart()
{
	cv_Damage = CreateConVar("infected_kill_damage", "10", "被控扣血", FCVAR_NOTIFY, true, 1.0);
	HookEvent("player_hurt", OnPlayerHurt, EventHookMode_Post);
}

public void OnClientPutInServer(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype)
{
	if (damage <= 0.0) return Plugin_Continue;

	if (IsValidSur(victim) && IsPlayerAlive(victim))
	{
		if (IsValidSI(attacker) && IsPlayerAlive(attacker))
		{
			int zombie_class = GetEntProp(attacker, Prop_Send, "m_zombieClass");

			switch(zombie_class)
			{
				case SMOKER, HUNTER, JOCKEY, CHARGER:
				{
					if (GetPinnedSurvivor(attacker, zombie_class) == victim)
					{
						damage = GetConVarFloat(cv_Damage);
						return Plugin_Changed;
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

void OnPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	int victim = GetClientOfUserId(GetEventInt(event, "userid"));

	if (!IsValidSI(attacker) && !IsValidSur(victim)) return;

	int damage = GetEventInt(event, "dmg_health");
	int zombie_class = GetEntProp(attacker, Prop_Send, "m_zombieClass");

	if ((zombie_class == SMOKER ||
		zombie_class == HUNTER ||
		zombie_class == JOCKEY ||
		zombie_class == CHARGER) && damage >= GetConVarInt(cv_Damage))
	{
		int remaining_health = GetClientHealth(attacker);
		CPrintToChatAll("[{olive}伤害报告{default}] {red}%N{default}({green}%s{default}) 还剩下 {green}%d{default} 血! 造成了 {green}%2.1f{default} 点伤害!", attacker, IsFakeClient(attacker)?"AI":SI_Names[zombie_class], remaining_health, GetConVarFloat(cv_Damage));
		ForcePlayerSuicide(attacker);
	}
}

int GetPinnedSurvivor(int iSpecial, int zombie_class)
{
	switch (zombie_class)
	{
		case SMOKER: return GetEntPropEnt(iSpecial, Prop_Send, "m_tongueVictim");
		case HUNTER: return GetEntPropEnt(iSpecial, Prop_Send, "m_pounceVictim");
		case JOCKEY: return GetEntPropEnt(iSpecial, Prop_Send, "m_jockeyVictim");
		case CHARGER: return GetEntPropEnt(iSpecial, Prop_Send, "m_pummelVictim");
	}
	return -1;
}

bool IsValidSI(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3;
}

bool IsValidSur(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2;
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	SDKHook(client, SDKHook_PostThinkPost, CancelGetup);
	return Plugin_Continue;
}

public Action CancelGetup(int client)
{
	if ((client > 0 && IsClientInGame(client)))
		SetEntPropFloat(client, Prop_Send, "m_flCycle", 1000.0, 0);
	return Plugin_Continue;
}

