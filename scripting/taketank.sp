#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

ConVar cv_PbEnable;
bool IsPlayerPB[MAXPLAYERS + 1], TankBot[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[L4D2]接管坦克",
	description = "L4D2 take tank,use in coop mode",
	author = "奈",
	version = "1.2.4",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public void OnPluginStart()
{
	cv_PbEnable = CreateConVar("l4d2_take_tank_enable", "1", "开关pb玩克 开启:1 关闭:0", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookConVarChange(cv_PbEnable, CvarChange);
	RegAdminCmd("sm_tt", TakeTank, ADMFLAG_ROOT, "接管AI坦克");
	RegConsoleCmd("sm_pb", PanBian, "接管坦克预选池");

	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("tank_frustrated", Event_TankFrustrated);
	HookEvent("player_bot_replace", Event_PlayerBotReplace);
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);

	HookEvent("round_start", Event_Reset, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_Reset, EventHookMode_PostNoCopy);
	HookEvent("map_transition", Event_Reset, EventHookMode_PostNoCopy);
	HookEvent("mission_lost", Event_Reset, EventHookMode_PostNoCopy);
}

public void CvarChange( ConVar convar, const char[] oldValue, const char[] newValue )
{
	reset();
}

void Event_Reset(Event event, const char []name, bool dontBroadcast)
{
	reset();
}

public void OnMapEnd() 
{
	reset();
}

void reset()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8)
			ChangeClientTeamToSurvivor(client);
		IsPlayerPB[client] = false;
	}
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int userid = event.GetInt("userid");
	int client = GetClientOfUserId(userid);
	if (!client || !IsClientInGame(client))
		return;

	TankBot[client] = false;
	RequestFrame(NextFrame_PlayerSpawn, userid); // player_bot_replace在player_spawn之后触发, 延迟一帧进行接管判断
}

void NextFrame_PlayerSpawn(int client)
{
	if (!(client = GetClientOfUserId(client)) || !IsClientInGame(client) || IsClientInKickQueue(client) || !IsPlayerAlive(client))
		return;

	if (TankBot[client])
		return;

	if (IsFakeClient(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8)
		TakeOverTank(client);
}

void Event_TankFrustrated(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsFakeClient(client))
		return;

	RequestFrame(NextFrame_ForceChangeTeamSurvivor, GetClientUserId(client));
}

void NextFrame_ForceChangeTeamSurvivor(int client) {
	if (!(client = GetClientOfUserId(client)) || !IsClientInGame(client))
		return;

	ChangeClientTeamToSurvivor(client);
}

void Event_PlayerBotReplace(Event event, const char[] name, bool dontBroadcast)
{
	int bot = GetClientOfUserId(event.GetInt("bot"));
	int player = GetClientOfUserId(event.GetInt("player"));

	if (GetClientTeam(bot) == 3 && GetEntProp(bot, Prop_Send, "m_zombieClass") == 8)
	{
		if (!IsFakeClient(player))
			TankBot[bot] = true; // 主动或被动放弃Tank控制权(BOT替换玩家)

		SetEntProp(bot, Prop_Data, "m_iHealth", GetEntProp(player, Prop_Data, "m_iHealth"));
		SetEntProp(bot, Prop_Data, "m_iMaxHealth", GetEntProp(player, Prop_Data, "m_iMaxHealth"));
	}
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client))
		return;
	if (!IsFakeClient(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8)
		ChangeClientTeamToSurvivor(client);
}

Action TakeTank(int client, int args)
{
	int tank;
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;
	if (GetClientTeam(client) == 3 && IsPlayerAlive(client) && GetEntProp(client, Prop_Send, "m_zombieClass") == 8)
	{
		PrintToChat(client, "\x04[提示]\x05你当前已经是坦克.");
		return Plugin_Handled;
	}
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i) && GetEntProp(i, Prop_Send, "m_zombieClass") == 8)
		{
			tank = i;
			break;
		}
	}
	if (!tank)
	{
		PrintToChat(client, "\x04[提示]\x05无可供接管的坦克存在.");
		return Plugin_Handled;
	}
	if(GetClientTeam(client) == 2 || GetClientTeam(client) == 1)
	{
		int m_iHealth = GetEntProp(tank, Prop_Data, "m_iHealth");
		int m_iMaxHealth = GetEntProp(tank, Prop_Data, "m_iMaxHealth");
		ChangeClientTeam(client, 3);
		L4D_TakeOverZombieBot(client, tank);
		SetEntProp(client, Prop_Data, "m_iHealth", m_iHealth);
		SetEntProp(client, Prop_Data, "m_iMaxHealth", m_iMaxHealth);
	}
	return Plugin_Handled;
}

Action PanBian(int client, int args)
{
	if (!client || !IsClientInGame(client) || IsFakeClient(client))
		return Plugin_Handled;
	if (!cv_PbEnable.BoolValue)
	{
		PrintToChat(client, "\x04[提示]\x05叛变抽取坦克已关闭.");
		return Plugin_Handled;
	}

	if (!IsPlayerPB[client]) {
		IsPlayerPB[client] = true;
		PrintToChat(client, "已加入叛变列表");
		PrintToChat(client, "再次输入该指令可退出叛变列表");
		PrintToChat(client, "坦克出现后将会随机从叛变列表中抽取1人接管");
		PrintToChat(client, "\x05当前叛变玩家列表:");

		for (int i = 1; i <= MaxClients; i++) {
			if (IsPlayerPB[i] && IsClientInGame(i) && !IsFakeClient(i))
				PrintToChat(client, "\x04-> %N", i);
		}
	}
	else {
		IsPlayerPB[client] = false;
		PrintToChat(client, "已退出叛变列表");
	}

	return Plugin_Handled;
}

int GetPBPlayer()
{
	int client = 1;
	ArrayList aClients = new ArrayList();

	for (; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client) || IsFakeClient(client))
			continue;

		if (GetClientTeam(client) == 2 && IsPlayerPB[client])
			aClients.Push(client);
	}

	if (!aClients.Length)
		client = 0;
	else
		client = aClients.Get(Math_GetRandomInt(0, aClients.Length - 1));

	delete aClients;
	return client;
}

// https://github.com/bcserv/smlib/blob/2c14acb85314e25007f5a61789833b243e7d0cab/scripting/include/smlib/math.inc#L144-L163
#define SIZE_OF_INT	2147483647 // without 0
int Math_GetRandomInt(int min, int max) {
	int random = GetURandomInt();
	if (random == 0)
		random++;

	return RoundToCeil(float(random) / (float(SIZE_OF_INT) / float(max - min + 1))) + min - 1;
}


int TakeOverTank(int tank)
{
	int client = GetPBPlayer();
	if (!client)
		return 0;
	
	if (IsClientInGame(tank) && IsFakeClient(tank) && GetClientTeam(client) == 2)
	{
		int m_iHealth = GetEntProp(tank, Prop_Data, "m_iHealth");
		int m_iMaxHealth = GetEntProp(tank, Prop_Data, "m_iMaxHealth");
		ChangeClientTeam(client, 3);
		L4D_TakeOverZombieBot(client, tank);
		SetEntProp(client, Prop_Data, "m_iHealth", m_iHealth);
		SetEntProp(client, Prop_Data, "m_iMaxHealth", m_iMaxHealth);
		return client;
	}

	return 0;
}

void ChangeClientTeamToSurvivor(int client)
{
	ChangeClientTeam(client, 2);
	if(IsPlayerAlive(client))
		ForcePlayerSuicide(client);
}

