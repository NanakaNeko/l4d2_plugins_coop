#include <sdktools>
#include <sourcemod>
#pragma newdecls required
#pragma semicolon 1

//清除部分功能，让插件通用在服务器
ConVar
	cv_ChangeName,
	cv_ServerRank,
	cv_ServerNumber,
	cv_LobbyDisable,
	cv_smPrompt,
	cv_pingCheck;
enum struct pingStruct{
	int pingTooHigh;
	int pingCheckCount;
	bool playerDisconnect;
	bool CheckFinish;
}
pingStruct pingCheck[MAXPLAYERS + 1];
int ChangeName[MAXPLAYERS + 1];
StringMap g_smSteamIDs;
bool g_bDebugMode;

public Plugin myinfo =
{
	name = "[L4D2]Server Function",
	author = "奈",
	description = "服务器一些功能实现",
	version = "1.1.8",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};


public void OnPluginStart()
{
	g_smSteamIDs = new StringMap();
	cv_ChangeName = CreateConVar("change_name_number", "6", "改名次数达到多少后踢出", FCVAR_NOTIFY, true, 0.0);
	cv_ServerRank = CreateConVar("l4d_server_rank", "233", "全球排名数", _, true, 0.0);
	cv_ServerNumber = CreateConVar("l4d_server_players_number", "6666", "加入服务器人数", _, true, 0.0);
	cv_LobbyDisable = CreateConVar("server_lobby_disable", "1", "禁用服务器匹配 官方默认:0 禁用:1", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cv_smPrompt = CreateConVar("l4d2_sm_prompt", "0", "SM提示仅限管理可见 禁用:0 启用:1", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cv_pingCheck = CreateConVar("l4d2_ping_check", "1", "进入服务器ping值检测,高于250ms踢出,仅在第一次进入检测,中途升高不检测 禁用:0 启用:1", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	RegAdminCmd("sm_restartmap", RestartMap, ADMFLAG_ROOT, "立即重启当前地图");
	RegAdminCmd("sm_restartmap5", RestartMap5, ADMFLAG_ROOT, "延迟5秒重启当前地图");
	RegAdminCmd("sm_debug", DebugMode, ADMFLAG_ROOT, "开关调试模式");
	RegConsoleCmd("sm_zs", Kill_Survivor, "幸存者自杀指令");
	RegConsoleCmd("sm_kill", Kill_Survivor, "幸存者自杀指令");
	HookUserMessage(GetUserMessageId("TextMsg"), umTextMsg, true);
	HookEvent("server_cvar", Event_ServerCvar, EventHookMode_Pre);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("player_changename", Event_PlayerChangeName);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
	//AutoExecConfig(true, "server_config");
}

public void OnPluginEnd()
{
	SetGodMode(false);
}

public void OnMapStart()
{
	SetGodMode(true);
	//重置改名次数
	for(int client = 1; client <= MaxClients; client++)
		ChangeName[client] = 0;
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	SetGodMode(false);
	return Plugin_Stop;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// 开启无敌模式
	SetGodMode(true);
	//重置改名次数
	for(int client = 1; client <= MaxClients; client++)
		ChangeName[client] = 0;
}

public void Event_PlayerChangeName(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if(IsFakeClient(client))
		return;

	if(ChangeName[client] >= cv_ChangeName.IntValue)
	{
		ChangeName[client] = 0;
		KickClient(client, "因频繁改名被踢出");
		return;
	}

	char sOldname[MAX_NAME_LENGTH], sNewname[MAX_NAME_LENGTH];
	event.GetString("oldname", sOldname, sizeof(sOldname));
	event.GetString("newname", sNewname, sizeof(sNewname));
	PrintToChatAll("\x03>> \x04%s \x05更改名称为 \x04%s", sOldname, sNewname);
	ChangeName[client]++;
}

public void OnClientPutInServer(int client)
{
	if(IsFakeClient(client))
		return;
	ChangeName[client] = 0;
	pingCheck[client].playerDisconnect = false;
	if(cv_pingCheck.BoolValue)
		CreateTimer(2.0, ping_Check, client, TIMER_REPEAT);
}

public Action ping_Check(Handle timer, int client)
{
	if(!client || pingCheck[client].playerDisconnect || pingCheck[client].CheckFinish)
		return Plugin_Stop;

	if (GetClientTime(client) < 60.0)
		return Plugin_Continue;

	//PrintToConsoleAll("开始检测ping");
	float ping = GetClientAvgLatency(client, NetFlow_Outgoing) * 1000.0;

	if(ping > 250.0)
		pingCheck[client].pingTooHigh++;
	
	pingCheck[client].pingCheckCount++;

	if(pingCheck[client].pingTooHigh >= 5){
		KickClient(client, "ping值太高了");
		return Plugin_Stop;
	}
	if(pingCheck[client].pingCheckCount > 15){
		pingCheck[client].CheckFinish = true;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

void ServerRank()
{
	GameRules_SetProp("m_iServerRank", GetConVarInt(cv_ServerRank), 4, 0, false);
	GameRules_SetProp("m_iServerPlayerCount", GetConVarInt(cv_ServerNumber), 4, 0, false);
}

public void OnClientConnected(int client)
{
	if(IsFakeClient(client))
		return;
	IsRemoveLobby(cv_LobbyDisable.BoolValue);
	ServerRank();
}

public void OnClientDisconnect(int client)
{
	if(IsFakeClient(client))
		return;
	ServerRank();
	pingCheck[client].playerDisconnect = true;
}

void IsRemoveLobby(bool dis)
{
	if(!dis)
		return;
	FindConVar("sv_allow_lobby_connect_only").SetInt(0);
	FindConVar("sv_hosting_lobby").SetInt(0);
	FindConVar("sv_lobby_cookie").SetString("0");
	ServerCommand("sv_cookie 0");
}

// ------------------------------------------------------------------------
// 游戏自带的闲置提示和sourcemod平台自带的[SM]提示 感谢 sorallll
// ------------------------------------------------------------------------
Action umTextMsg(UserMsg msg_id, BfRead msg, const int[] players, int num, bool reliable, bool init) {
	static char buffer[254];
	msg.ReadString(buffer, sizeof buffer);

	if (strcmp(buffer, "\x03#L4D_idle_spectator") == 0) //聊天栏提示：XXX 现已闲置。
		return Plugin_Handled;
	else if (StrContains(buffer, "\x03[SM]") == 0 && cv_smPrompt.BoolValue) //聊天栏以[SM]开头的消息。
	{
		DataPack dPack = new DataPack();
		dPack.WriteCell(num);
		for (int i; i < num; i++)
			dPack.WriteCell(players[i]);
		dPack.WriteString(buffer);
		RequestFrame(NextFrame_SMMessage, dPack);
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

//https://forums.alliedmods.net/showthread.php?t=187570
void NextFrame_SMMessage(DataPack dPack) {
	dPack.Reset();
	int num = dPack.ReadCell();
	int[] players = new int[num];

	int client, count;
	for (int i; i < num; i++) {
		client = dPack.ReadCell();
		if (IsClientInGame(client) && !IsFakeClient(client) && CheckCommandAccess(client, "", ADMFLAG_ROOT))
			players[count++] = client;
	}

	if (!count) {
		delete dPack;
		return;
	}

	char buffer[254];
	dPack.ReadString(buffer, sizeof buffer);
	delete dPack;

	ReplaceStringEx(buffer, sizeof buffer, "[SM]", "\x04[SM]\x05");
	BfWrite bf = view_as<BfWrite>(StartMessage("SayText2", players, count, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
	bf.WriteByte(-1);
	bf.WriteByte(true);
	bf.WriteString(buffer);
	EndMessage();
}

// ------------------------------------------------------------------------
// ConVar更改提示
// ------------------------------------------------------------------------
Action Event_ServerCvar(Event event, const char[] name, bool dontBroadcast) {
	return Plugin_Handled;
}

stock bool IsAliveSurvivor(int i)
{
    return i > 0 && i <= MaxClients && !IsFakeClient(i) && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2;
}

void SetGodMode(bool canset)
{
	int flags = GetCommandFlags("god");
	SetCommandFlags("god", flags & ~ FCVAR_NOTIFY);
	SetConVarInt(FindConVar("god"), canset);
	SetCommandFlags("god", flags);
	SetConVarInt(FindConVar("sv_infinite_ammo"), canset);
}

public Action RestartMap(int client,int args)
{
	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	ServerCommand("changelevel %s", mapname);
	return Plugin_Handled;
}

public Action RestartMap5(int client,int args)
{
	PrintHintTextToAll("地图将在5秒后重启");
	CreateTimer(5.0, Timer_Restartmap);
	return Plugin_Handled;
}

public Action Timer_Restartmap(Handle timer)
{
	char mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	ServerCommand("changelevel %s", mapname);
	return Plugin_Handled;
}

public Action Kill_Survivor(int client, int args)
{
	if(IsAliveSurvivor(client))
	{
		ForcePlayerSuicide(client);
		PrintToChatAll("\x04[提示]\x03%N\x05失去梦想,升天了.", client);
	}
	return Plugin_Handled;
}

//调试模式，感谢sorallll
public void OnClientPostAdminCheck(int client)
{
	if (!g_bDebugMode || IsFakeClient(client))
		return;

	if (CheckCommandAccess(client, "", ADMFLAG_ROOT))
		return;

	char sSteamID[32];
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof sSteamID);
	if (!g_smSteamIDs.ContainsKey(sSteamID))
		KickClient(client, "服务器调试中...");
}

void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bDebugMode)
		return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client && IsFakeClient(client))
		return;

	if (RealPlayerExist(client))
		return;

	g_bDebugMode = false;
	g_smSteamIDs.Clear();
}

bool RealPlayerExist(int exclude)
{
	for (int client = 1; client <= MaxClients; client++) {
		if (client != exclude && IsClientConnected(client) && !IsFakeClient(client))
			return true;
	}
	return false;
}

Action DebugMode(int client, int args)
{
	if (g_bDebugMode) {
		g_bDebugMode = false;
		g_smSteamIDs.Clear();
		ReplyToCommand(client, "调试模式已关闭.");
	}
	else {
		char sSteamID[32];
		for (int i = 1; i <= MaxClients; i++) {
			if (IsClientInGame(i) && !IsFakeClient(i)) {
				if (GetClientAuthId(i, AuthId_Steam2, sSteamID, sizeof sSteamID))
					g_smSteamIDs.SetValue(sSteamID, true, true);
			}
		}

		g_bDebugMode = true;
		ReplyToCommand(client, "调试模式已开启.");
	}
	
	return Plugin_Handled;
}
