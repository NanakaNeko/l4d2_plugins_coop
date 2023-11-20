#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <colors>  

#define VERSION "0.4"

float g_fLastLerp[MAXPLAYERS+1];

public Plugin myinfo = 
{
	name = "Lerp Monitor",
	author = "ProdigySim, Die Teetasse, vintik, fdxx",
	version = VERSION,
}

public void OnPluginStart()
{
	CreateConVar("lerp_monitor_version", VERSION, "插件版本", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	HookEvent("player_team", Event_PlayerTeamChanged);
	RegConsoleCmd("sm_lerps", Cmd_Lerps, "List the Lerps of all players in game");
	RegConsoleCmd("sm_lerp", Cmd_Lerps, "List the Lerps of all players in game");
}

public void OnClientPutInServer(int client)
{
	if (!IsFakeClient(client))
		g_fLastLerp[client] = GetClientLerp(client);
}

public void OnClientSettingsChanged(int client)
{
	if (client > 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		float fNewLerp = GetClientLerp(client);
		if (fNewLerp != g_fLastLerp[client])
		{
			if (GetClientTeam(client) > 1)
				CPrintToChatAllEx(client, "{olive}<lerp> {teamcolor}%N {default}@ {teamcolor}%.1f {default}<== {teamcolor}%.1f", client, fNewLerp*1000, g_fLastLerp[client]*1000);
			g_fLastLerp[client] = fNewLerp;
		}
	}
}

void Event_PlayerTeamChanged(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	bool bDisconnect = event.GetBool("disconnect");
	int iNewTeam = event.GetInt("team");

	if (iNewTeam > 1 && !bDisconnect && client > 0 && IsClientInGame(client) && !IsFakeClient(client))
		CreateTimer(0.1, PlayerTeamChanged_Timer, userid, TIMER_FLAG_NO_MAPCHANGE);
}

Action PlayerTeamChanged_Timer(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if (client > 0 && IsClientInGame(client) && !IsFakeClient(client))
		CPrintToChatAllEx(client, "{olive}<lerp> {teamcolor}%N {default}@ {teamcolor}%.1f", client, g_fLastLerp[client]*1000);

	return Plugin_Continue;
}

Action Cmd_Lerps(int client, int args)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 1)
			ReplyToCommand(client, "%N: %.1f", i, GetClientLerp(i)*1000);
	}
	return Plugin_Handled;
}

float GetClientLerp(int client)
{
	static char sLerp[64];
	GetClientInfo(client, "cl_interp", sLerp, sizeof(sLerp));
	return StringToFloat(sLerp);
}
