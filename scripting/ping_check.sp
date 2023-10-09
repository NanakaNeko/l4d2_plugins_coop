#pragma newdecls required
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

enum struct pingStruct{
	int pingTooHigh;
	int pingCheckCount;
	bool CheckDisconnect;
	bool CheckFinish;
}
pingStruct pingCheck[MAXPLAYERS + 1];
char g_sLogPath[PLATFORM_MAX_PATH];

public Plugin myinfo =
{
	name = "[L4D2]ping check",
	author = "奈",
	description = "检测ping值",
	version = "1.0",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public void OnPluginStart()
{
    BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/ping_kick.log");
    HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

public void OnClientPutInServer(int client)
{
	if(IsFakeClient(client))
		return;
	pingCheck[client].CheckDisconnect = false;
	CreateTimer(1.0, ping_Check, client, TIMER_REPEAT);
}

public Action ping_Check(Handle timer, int client)
{
	if(!(0 < client <= MaxClients))
		return Plugin_Stop;

	if(pingCheck[client].CheckDisconnect)
		return Plugin_Stop;

	if(!(0 < client < MaxClients))
		return Plugin_Stop;

	if(!IsClientConnected(client))
		return Plugin_Stop;

	if(pingCheck[client].CheckFinish)
		return Plugin_Stop;

	if (GetClientTime(client) < 90.0)
		return Plugin_Continue;

	float ping = GetClientAvgLatency(client, NetFlow_Outgoing) * 1000.0;
	//PrintToConsoleAll("开始检测ping");

	if(ping > 250.0)
		pingCheck[client].pingTooHigh++;
	
	pingCheck[client].pingCheckCount++;

	if(pingCheck[client].pingTooHigh >= 5)
	{
		KickClient(client, "ping值太高了");
		LogToFileEx(g_sLogPath, "[ping] %N 因为ping太高被踢出", client);
		return Plugin_Stop;
	}
	if(pingCheck[client].pingCheckCount > 30)
	{
		pingCheck[client].CheckFinish = true;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
	if(IsFakeClient(client))
		return;
	pingCheck[client].CheckDisconnect = true;
}

void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event,"userid"));

	if (!(1 <= client <= MaxClients))
		return;

	if (IsFakeClient(client))
		return;

	pingCheck[client].CheckFinish = false;
}