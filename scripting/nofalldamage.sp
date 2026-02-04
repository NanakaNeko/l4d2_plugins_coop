#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>

// Lateload
new g_bLateLoad;

// Teamfilter
new Handle:g_hTeamFilter;
new g_iTeamFilter;


// ClientFilter
new Handle:g_hClientFilter;
new g_iClientFilter;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	g_hTeamFilter   = CreateConVar("sm_nofalldamage_teamfilter", "0", "团队不摔伤, 0 = 所有, 2 = 红, 3 = 蓝", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	g_hClientFilter = CreateConVar("sm_nofalldamage_clientfilter", "0", "坠落不受伤, 0 = 所有, 1 = 只有管理员可以", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	g_iTeamFilter   = GetConVarInt(g_hTeamFilter);
	g_iClientFilter = GetConVarInt(g_hClientFilter);

	HookConVarChange(g_hTeamFilter, OnCvarChanged);
	HookConVarChange(g_hClientFilter, OnCvarChanged);
	
	// LateLoad;
	if(g_bLateLoad)
	{
		for(new i; i <= MaxClients; i++)
		{
			if(IsClientAndInGame(i))
			{
				SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
			}
		}
	}
}

public OnCvarChanged(Handle:convar, const String:oldVal[], const String:newVal[])
{
	if(convar == g_hTeamFilter)
	{
		g_iTeamFilter = GetConVarInt(g_hTeamFilter);
	}
	else if(convar == g_hClientFilter)
	{
		g_iClientFilter = GetConVarInt(g_hClientFilter);
	}
}

public OnClientPostAdminCheck(client)
{
	if(IsClientAndInGame(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	// We first check if damage is falldamage and then check the others
	if(damagetype & DMG_FALL)
	{
		// Teamfilter
		if(g_iTeamFilter < 1 || g_iTeamFilter > 1 && GetClientTeam(client) == g_iTeamFilter)
		{
			// Clientfilter
			if(g_iClientFilter == 0 || g_iClientFilter == 1 && CheckCommandAccess(client, "sm_nofalldamage_immune", ADMFLAG_GENERIC, false))
			{
				return Plugin_Handled;
			}
		}
	}	
	return Plugin_Continue;
}

bool:IsClientAndInGame(index)
{
	if (index > 0 && index < MaxClients)
	{
		return IsClientInGame(index);
	}
	return false;
}

