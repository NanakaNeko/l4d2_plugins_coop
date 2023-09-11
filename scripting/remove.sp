#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

public Plugin myinfo = 
{
	name 			= "Remove Medical",
	author 			= "奈",
	description 	= "删除所有医疗物品, 开局发药",
	version 		= "1.0",
	url 			= "https://github.com/NanakaNeko/l4d2_plugins_coop"
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	GivePill();
	return Plugin_Stop;
}

public void GivePill()
{
	int flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsAliveSurvivor(client))
		{
			int item = GetPlayerWeaponSlot(client, 4);
			if (IsValidEntity(item) && IsValidEdict(item))
				RemovePlayerItem(client, item);
			FakeClientCommand(client, "give pain_pills");
		}
	}
	SetCommandFlags("give", flags|FCVAR_CHEAT);
}

stock bool IsAliveSurvivor(int i)
{
    return i > 0 && i <= MaxClients && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(strcmp(classname, "weapon_spawn") == 0) 
	{
		SDKHook(entity, SDKHook_Spawn, on_weapon_sapwn);
	}
	else
	{
		if(strcmp(classname, "weapon_first_aid_kit_spawn") == 0)
		{
			SDKHook(entity, SDKHook_Spawn, Remove_Medical);
		}
		if(strcmp(classname, "weapon_pain_pills_spawn") == 0)
		{
			SDKHook(entity, SDKHook_Spawn, Remove_Medical);
		}
		if(strcmp(classname, "weapon_defibrillator_spawn") == 0)
		{
			SDKHook(entity, SDKHook_Spawn, Remove_Medical);
		}
		if(strcmp(classname, "weapon_adrenaline_spawn") == 0)
		{
			SDKHook(entity, SDKHook_Spawn, Remove_Medical);
		}
	}
}

public Action Remove_Medical(int entity)
{
	RemoveEntity(entity);
	return Plugin_Continue;
}

public Action on_weapon_sapwn(int entity)
{
	RequestFrame(RemoveThing, EntIndexToEntRef(entity));
	return Plugin_Continue;
}

public void RemoveThing(int ref)
{
	int entity = EntRefToEntIndex(ref);
	if(entity != -1 && GetEntProp(entity, Prop_Data, "m_weaponID") == 12)
	{
		RemoveEntity(entity);
	}
	if(entity != -1 && GetEntProp(entity, Prop_Data, "m_weaponID") == 15)
	{
		RemoveEntity(entity);
	}
	if(entity != -1 && GetEntProp(entity, Prop_Data, "m_weaponID") == 23)
	{
		RemoveEntity(entity);
	}
	if(entity != -1 && GetEntProp(entity, Prop_Data, "m_weaponID") == 24)
	{
		RemoveEntity(entity);
	}
}

