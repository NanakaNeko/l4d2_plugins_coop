#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
 
public Plugin myinfo =
{
	name = "开局发包药",
	author = "奈",
	description = "回合开始发包药",
	version = "1.2",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	GiveMedicals();
	return Plugin_Stop;
}

public void GiveMedicals()
{
	int flags = GetCommandFlags("give");	
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);	
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client)==2) 
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
