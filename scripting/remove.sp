#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

ConVar cv_DeleteSlots;

public Plugin myinfo = 
{
	name 			= "Remove Medical",
	author 			= "奈",
	description 	= "删除所有医疗物品, 开局发药",
	version 		= "1.1",
	url 			= "https://github.com/NanakaNeko/l4d2_plugins_coop"
}

public void OnPluginStart()
{
	cv_DeleteSlots = CreateConVar("l4d2_delete_slots", "0", "清除武器 关闭:0 开启:1", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookEvent("map_transition", Event_ResetInventory, EventHookMode_Post);
}

public Action Event_ResetInventory(Event event, const char[] name, bool dontBroadcast)
{
	if(cv_DeleteSlots.BoolValue)
		ResetInventory();
	return Plugin_Continue;
}

// 清除物品
void ResetInventory()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsAliveSurvivor(client))
		{
			for (int slot = 0; slot < 5; slot++)
				DeleteInventoryItem(client, slot);
			GiveCommand(client, "pistol");
		}
	}
}

void DeleteInventoryItem(int client, int slot)
{
	int item = GetPlayerWeaponSlot(client, slot);
	if (IsValidEntity(item) && IsValidEdict(item))
		RemovePlayerItem(client, item);
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	GivePill();
	return Plugin_Stop;
}

public void GivePill()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsAliveSurvivor(client))
		{
			int item = GetPlayerWeaponSlot(client, 4);
			if (IsValidEntity(item) && IsValidEdict(item))
				RemovePlayerItem(client, item);
			GiveCommand(client, "pain_pills");
		}
	}
}

//cheat give命令
void GiveCommand(int client, char[] args = "")
{
	int iFlags = GetCommandFlags("give");
	SetCommandFlags("give", iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", args);
	SetCommandFlags("give", iFlags);
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

