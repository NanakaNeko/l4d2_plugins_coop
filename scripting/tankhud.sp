#pragma semicolon 1
#pragma newdecls required

// 头文件
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
//#include <colors>
//#include "../treeutil/treeutil.sp"

#define CVAR_FLAG FCVAR_NOTIFY
#define INVALID_CLIENT -1
#define TANK_HUD_DISPLAY_TIME 3

// 团队类型
enum
{
	TEAM_SPECTATOR = 1,
	TEAM_SURVIVOR,
	TEAM_INFECTED
}

// 感染者类型
enum
{
	ZC_SMOKER = 1,
	ZC_BOOMER,
	ZC_HUNTER,
	ZC_SPITTER,
	ZC_JOCKEY,
	ZC_CHARGER,
	ZC_WITCH,
	ZC_TANK,
}

public Plugin myinfo = 
{
	name 			= "Spectator And InfectedTeam Tank Hud",
	author 			= "夜羽真白",
	description 	= "旁观者与特感团队的坦克面板",
	version 		= "1.0.1.1",
	url 			= "https://steamcommunity.com/id/saku_ra/"
}

// ConVars
ConVar
	g_hEnable,
	g_hPanelRefreshTime,
	g_hPanelTitle;
// 其他 Cvar
ConVar
	tankBurnDuration;
// Ints
int
	tankClient = INVALID_CLIENT;
// Bools
bool
	hiddenPanel[MAXPLAYERS + 1],
	inVomit[MAXPLAYERS + 1];
Handle
	g_hTankHudTimer = null;
Panel
	tankHud = null;

public void OnPluginStart()
{
	// ConVars
	g_hEnable = CreateConVar("tank_hud_enable", "1", "是否开启坦克状态面板", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hPanelRefreshTime = CreateConVar("tank_hud_refresh_interval", "0.5", "坦克状态面板刷新时间", CVAR_FLAG, true, 0.1);
	g_hPanelTitle = CreateConVar("tank_hud_title", "坦克状态面板", "坦克状态面板标题", CVAR_FLAG);
	tankBurnDuration = FindConVar("tank_burn_duration");
	// Commands
	RegConsoleCmd("sm_tankhud", Cmd_TankHud, "开启关闭坦克面板");
	// Events
	HookEvent("round_start", evt_RoundEvent, EventHookMode_PostNoCopy);
	HookEvent("round_end", evt_RoundEvent, EventHookMode_PostNoCopy);
	HookEvent("tank_spawn", evt_TankSpawn);
	HookEvent("player_death", evt_PlayerDeath);
	HookEvent("player_now_it", evt_PlayerNowIt);
}

// *********************
//		   指令
// *********************
public Action Cmd_TankHud(int client, int args)
{
	if (!hiddenPanel[client])
	{
		hiddenPanel[client] = true;
		PrintToChat(client, "\x04[TankHUD] \x05已\x03关闭\x05坦克状态面板");
		return Plugin_Continue;
	}
	hiddenPanel[client] = false;
	PrintToChat(client, "\x04[TankHUD] \x05已\x03打开\x05坦克状态面板");
	return Plugin_Continue;
}

// *********************
//		   事件
// *********************
public void evt_RoundEvent(Event event, const char[] name, bool dontBroadcast)
{
	delete g_hTankHudTimer;
	g_hTankHudTimer = null;
	delete tankHud;
	tankHud = null;
	tankClient = INVALID_CLIENT;
}

public void evt_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	tankClient = GetClientOfUserId(event.GetInt("userid"));
	// 未开启面板
	if (!g_hEnable.BoolValue) { return; }
	// 开启了面板
	delete g_hTankHudTimer;
	g_hTankHudTimer = CreateTimer(g_hPanelRefreshTime.FloatValue, Timer_RefreshPanel, _, TIMER_REPEAT);
	static int i;
	for (i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != TEAM_SURVIVOR)
		{
			if(hiddenPanel[i])
				PrintToChat(i, "\x04[TankHUD] \x05输入\x04!tankhud\x03打开\x05坦克状态面板");
			else
				PrintToChat(i, "\x04[TankHUD] \x05输入\x04!tankhud\x03关闭\x05坦克状态面板");
		}
	}
}

// 当前 Tank 死亡，查找是否还有其他的 Tank
public void evt_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (GetInfectedClass(client) != ZC_TANK) { return; }
	tankClient = hasAnyTank();
}

public void evt_PlayerNowIt(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (GetInfectedClass(client) != ZC_TANK) { return; }
	inVomit[client] = true;
	float blindTime = GetConVarFloat(FindConVar("z_vomit_fade_start"));
	float fadeTime = GetConVarFloat(FindConVar("z_vomit_fade_duration"));
	CreateTimer(blindTime + fadeTime, Timer_DisableBlind, client);
}

public Action Timer_DisableBlind(Handle timer, int client)
{
	inVomit[client] = false;
	return Plugin_Continue;
}

// 客户端退出，将客户端的 hiddenPanel 设置为 false
public void OnClientDisconnect(int client)
{
	if (!IsValidClient(client)) { return; }
	hiddenPanel[client] = false;
}

// 检查场上是否还有其他 Tank
int hasAnyTank()
{
	static int i;
	for (i = 1; i <= MaxClients; i++)
	{
		if (GetInfectedClass(i) != ZC_TANK || !IsPlayerAlive(i)) { continue; }
		return i;
	}
	return INVALID_CLIENT;
}

// 部分代码来自 Zonemod spechud.sp（Hyper-V HUD Manager） by Visor, Forgetest，link：https://github.com/Target5150/MoYu_Server_Stupid_Plugins
public Action Timer_RefreshPanel(Handle timer)
{
	delete tankHud;
	tankHud = new Panel();
	// 场上没有任何 Tank 了，清除 Hud
	if (!IsValidClient(tankClient) || !IsPlayerAlive(tankClient) || hasAnyTank() < 1)
	{
		delete tankHud;
		tankHud = null;
		g_hTankHudTimer = null;
		return Plugin_Stop;
	}
	static int
			i,
			health,
			maxHealth;
	static char title[128],
				info[64],
				name[MAX_NAME_LENGTH],
				rage[32];
	g_hPanelTitle.GetString(title, sizeof(title));
	// 标题显示
	tankHud.SetTitle(title);
	tankHud.DrawText(" \n");
	// 控制者显示
	if (!IsFakeClient(tankClient))
	{
		GetClientFixedName(tankClient, name, sizeof(name));
		FormatEx(info, sizeof(info), "▶ 控制：%s", name);
	}
	else { FormatEx(info, sizeof(info), "▶ 控制：%N (AI)", tankClient); }
	tankHud.DrawText(info);
	// 生命显示
	if (!IsClientIncapped(tankClient))
	{
		health = GetEntProp(tankClient, Prop_Data, "m_iHealth");
		maxHealth = GetEntProp(tankClient, Prop_Send, "m_iMaxHealth");
		// 除零异常
		FormatEx(info, sizeof(info), "▶ 生命值：%d / %.1f%%", health, maxHealth > 0 ? 100.0 * health / maxHealth : 0.0);
	}
	else { FormatEx(info, sizeof(info), "▶ 当前：已死亡"); }
	tankHud.DrawText(info);
	// 控制权显示
	int passCount = L4D2Direct_GetTankPassedCount();
	switch (passCount)
	{
		case 0: { FormatEx(info, sizeof(info), "Native"); }
		case 1: { FormatEx(info, sizeof(info), "%dst", passCount); }
		case 2: { FormatEx(info, sizeof(info), "%dnd", passCount); }
		case 3: { FormatEx(info, sizeof(info), "%drd", passCount); }
		default: { FormatEx(info, sizeof(info), "%dth", passCount); }
	}
	FormatEx(rage, sizeof(rage), "▶ 控制权：%d%% (%s)", GetTankFrustration(tankClient), info);
	tankHud.DrawText(rage);
	// 是否着火
	if (GetEntityFlags(tankClient) & FL_ONFIRE)
	{
		if (!IsClientIncapped(tankClient))
		{
			FormatEx(info, sizeof(info), "▶ 着火状态：%.1f 秒后死亡", health / tankBurnDuration.FloatValue);
		}
		else
		{
			FormatEx(info, sizeof(info), "▶ 着火状态：无 (已死亡)");
		}
	}
	else { FormatEx(info, sizeof(info), "▶ 着火状态：未被燃烧"); }
	tankHud.DrawText(info);
	// 是否被胆汁
	if (inVomit[tankClient]) { FormatEx(info, sizeof(info), "▶ 胆汁状态：正在胆汁效果中"); }
	else { FormatEx(info, sizeof(info), "▶ 胆汁状态：无"); }
	tankHud.DrawText(info);
	// 网络状态
	if (!IsFakeClient(tankClient))
	{
		FormatEx(info, sizeof(info), "▶ 网络：%dms", RoundToNearest(GetClientAvgLatency(tankClient, NetFlow_Both) * 100.0));
	}
	else { FormatEx(info, sizeof(info), "▶ 网络：无 (AI)"); }
	tankHud.DrawText(info);
	// 将面板发送至旁观者与感染者团队
	for (i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) == TEAM_SURVIVOR || hiddenPanel[i]) { continue; }
		tankHud.Send(i, PanelHandler, TANK_HUD_DISPLAY_TIME);
	}
	return Plugin_Continue;
}

public int PanelHandler(Menu menu, MenuAction action, int client, int item)
{
	return 0;
}

int GetTankFrustration(int client)
{
	return GetInfectedClass(client) == ZC_TANK ? 100 - GetEntProp(client, Prop_Send, "m_frustration") : 0;
}

void GetClientFixedName(int client, char[] name, int len)
{
	if (!IsValidClient(client)) { strcopy(name, len, "Unknown"); }
	GetClientName(client, name, len);
	if (name[0] == '[')
	{
		char temp[MAX_NAME_LENGTH];
		strcopy(temp, sizeof(temp), name);
		temp[sizeof(temp) - 2] = '\0';
		strcopy(name[1], len - 1, temp);
		name[0] = ' ';
	}
	if (strlen(name) > 18)
	{
		name[15] = name[16] = name[17] = '.';
		name[18] = '\0';
	}
}

// 获取特感类型，成功返回特感类型，失败返回 -1
stock int GetInfectedClass(int client)
{
	return IsValidInfected(client) ? GetEntProp(client, Prop_Send, "m_zombieClass") : -1;
}

// 判断特感是否有效，有效返回 true，无效返回 false
stock bool IsValidInfected(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == TEAM_INFECTED;
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

stock bool IsClientIncapped(int client)
{
	if (!IsValidClient(client) || !IsPlayerAlive(client)) { return false; }
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}