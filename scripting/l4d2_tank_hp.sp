#pragma semicolon 1
//強制1.7以後的新語法
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <colors>
//#include <l4d2_GetWitchNumber>

#define iArray	4
#define CVAR_FLAGS	FCVAR_NOTIFY
#define TankSound	"ui/pickup_secret01.wav"

int g_iMultiplesCount;
float g_fMultiples[iArray];
char g_sDifficultyName[iArray][32] = {"简单", "普通", "高级", "专家"};
char g_sDifficultyCode[iArray][32] = {"Easy", "Normal", "Hard", "Impossible"};


bool TankSpawnFinaleVehicleLeaving, g_bTankSwitch, g_bWitchSwitch;
ConVar g_hMultiples;
int    g_iTankPrompt, g_iTankHealth, g_iWitchHealth;
ConVar g_hTankSwitch, g_hTankPrompt, g_hTankHealth, g_hWitchSwitch, g_hWitchHealth;

public Plugin myinfo = 
{
	name = "L4D2 Tank Announcer",
	author = "Visor, 豆瓣酱な",
	description = "Announce in chat and via a sound when a Tank has spawned",
	version = "1.5.8",
	url = "N/A"
};

public void OnPluginStart()
{
	g_hTankSwitch		= CreateConVar("l4d2_tank_Switch", 		"1", 	"启用坦克出现时血量跟随存活的幸存者人数而增加? 0=禁用, 1=启用.", CVAR_FLAGS);
	g_hTankPrompt		= CreateConVar("l4d2_tank_prompt", 		"1", 	"设置坦克出现时的提示类型. 0=禁用, 1=聊天窗, 2=屏幕中下+聊天窗, 3=屏幕中下.", CVAR_FLAGS);
	g_hMultiples		= CreateConVar("l4d2_tank_Multiples", 	"2.5;2.0;1.5;1.0", "设置游戏难度对应的倍数(留空=使用默认值:1.0).", CVAR_FLAGS);
	g_hTankHealth		= CreateConVar("l4d2_tank_health", 		"1000", "设置每一个活着的幸存者坦克所增加的血量.", CVAR_FLAGS);
	g_hWitchSwitch		= CreateConVar("l4d2_witch_Switch", 	"1", 	"启用女巫出现时血量设置及提示. 0=禁用, 1=设置女巫血量并提示.", CVAR_FLAGS);
	g_hWitchHealth		= CreateConVar("l4d2_witch_health", 	"1000",	"女巫血量.", CVAR_FLAGS);

	g_hTankSwitch.AddChangeHook(iHealthConVarChanged);
	g_hTankPrompt.AddChangeHook(iHealthConVarChanged);
	g_hMultiples.AddChangeHook(iHealthConVarChanged);
	g_hTankHealth.AddChangeHook(iHealthConVarChanged);
	g_hWitchSwitch.AddChangeHook(iHealthConVarChanged);
	g_hWitchHealth.AddChangeHook(iHealthConVarChanged);
	
	HookEvent("round_start", Event_RoundStart);//回合开始.
	HookEvent("round_end", Event_RoundEnd);//回合结束.
	HookEvent("witch_spawn", Event_WitchSpawn);
	HookEvent("witch_harasser_set",	Event_WitchHarasserSet);//witch惊扰
	HookEvent("tank_spawn", Event_TankSpawn);
	HookEvent("finale_vehicle_leaving", Event_FinaleVehicleLeaving);//救援离开.
	
	//AutoExecConfig(true, "l4d2_tank_hp");//生成指定文件名的CFG.
}

public void OnMapStart()
{
	iHealthCvars();
	PrecacheSound(TankSound);
	TankSpawnFinaleVehicleLeaving = false;
	
}

public void iHealthConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	iHealthCvars();
}

void iHealthCvars()
{
	g_bTankSwitch	= g_hTankSwitch.BoolValue;
	g_iTankPrompt	= g_hTankPrompt.IntValue;
	g_iTankHealth	= g_hTankHealth.IntValue;
	g_bWitchSwitch	= g_hWitchSwitch.BoolValue;
	g_iWitchHealth	= g_hWitchHealth.IntValue;

	char sCmds[512], g_sMultiples[iArray][32];
	g_hMultiples.GetString(sCmds, sizeof(sCmds));
	g_iMultiplesCount = ReplaceString(sCmds, sizeof(sCmds), ";", ";", false);
	ExplodeString(sCmds, ";", g_sMultiples, g_iMultiplesCount + 1, 32);
	
	for (int i = 0; i < iArray; i++)
		g_fMultiples[i] = sCmds[0] == '\0' || IsCharSpace(sCmds[0]) || g_sMultiples[i][0] == '\0' || IsCharSpace(g_sMultiples[i][0]) || !IsCharNumeric(g_sMultiples[i][0]) ? 1.0 : StringToFloat(g_sMultiples[i]);
}
//地图结束.
public void OnMapEnd()
{
	TankSpawnFinaleVehicleLeaving = true;
}

//回合结束.
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	TankSpawnFinaleVehicleLeaving = true;
}

//回合开始.
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	TankSpawnFinaleVehicleLeaving = false;
}

//救援离开时.
public void Event_FinaleVehicleLeaving(Event event, const char[] name, bool dontBroadcast)
{
	TankSpawnFinaleVehicleLeaving = true;
}

public void Event_WitchSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (g_bWitchSwitch)
		SetWitchHealth(client, g_iWitchHealth);
}

void SetWitchHealth(int client, int iHealth)
{
	SetClientHealth(client, iHealth);
	if (!TankSpawnFinaleVehicleLeaving)
		CPrintToChatAll("{default}[{green}!{default}] 前方{blue} 女巫 {default}出现!");//聊天窗提示.
}

// ------------------------------------------------------------------------
// Witch惊扰提示
// ------------------------------------------------------------------------
void Event_WitchHarasserSet(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!client || !IsClientInGame(client))
		return;

	switch (GetClientTeam(client)) {
		case 2: {
			int idleplayer = GetIdlePlayerOfBot(client);
			if (!idleplayer)
				CPrintToChatAll("{default}[{green}!{default}] {blue}%N{default} 惊扰了 {blue}女巫", client);
			else
				CPrintToChatAll("{default}[{green}!{default}] ({olive}闲置{default}){blue}%N{default} 惊扰了 {blue}女巫", idleplayer);
		}

		case 3:
			CPrintToChatAll("{default}[{green}!{default}] {olive}%N{default} 惊扰了 {blue}女巫", client);
	}
}

public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bTankSwitch)
		return;
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (IsValidTank(client))
	{
		EmitSoundToAll(TankSound);//给所有玩家播放声音.
		for (int i = 0; i < iArray; i++)
			if (StrEqual(GetGameDifficulty(), g_sDifficultyCode[i], false))
				SetTankHealth(client, g_fMultiples[i] == 0 ? 1.0 : g_fMultiples[i], g_sDifficultyName[i]);
	}
}

void SetTankHealth(int client, float Multiples, char[] sName)
{
	//这里使用下一帧显示提示.
	DataPack hPack = new DataPack();
	hPack.WriteCell(client);
	hPack.WriteString(sName);
	RequestFrame(IsClientPrint, hPack);
	SetClientHealth(client, RoundFloat(Multiples * (IsCountPlayersTeam() * g_iTankHealth)));
}

void SetClientHealth(int client, int iHealth)
{
	SetEntProp(client, Prop_Data, "m_iHealth", iHealth);
	SetEntProp(client, Prop_Data, "m_iMaxHealth", iHealth);
}

void IsClientPrint(DataPack hPack)
{
	hPack.Reset();
	char sName[64];
	int  client = hPack.ReadCell();
	hPack.ReadString(sName, sizeof(sName));
	if(IsValidTank(client) && g_iTankPrompt != 0 && !TankSpawnFinaleVehicleLeaving)
	{
		if(g_iTankPrompt == 1 || g_iTankPrompt == 2)
			CPrintToChatAll("{default}[{green}!{default}] {blue}Tank {default}({olive}控制者：%s{default}) 已经生成！\n{default}[{green}!{default}] {blue}难度:{green}%s {blue}存活生还:{green}%d {blue}血量:{green}%d", GetSurvivorName(client), sName, IsCountPlayersTeam(), GetClientHealth(client));//聊天窗提示.
		if(g_iTankPrompt == 2 || g_iTankPrompt == 3)
			PrintHintTextToAll("坦克 %s 出现! 难度:%s 存活生还:%d 血量:%d", GetSurvivorName(client), sName, IsCountPlayersTeam(), GetClientHealth(client));//屏幕中下提示.
	}
	delete hPack;
}

char[] GetSurvivorName(int tank)
{
	char sTankName[MAX_NAME_LENGTH];
	// 是否玩家Tank
	if (!IsFakeClient(tank) && IsClientInGame(tank) && GetClientTeam(tank) == 3 && GetEntProp(tank, Prop_Send, "m_zombieClass") == 8)
	{
		FormatEx(sTankName, sizeof(sTankName), "(玩家) %N", tank);
	}
	else if (tank != 0 && GetClientTeam(tank) == 3 && GetEntProp(tank, Prop_Send, "m_zombieClass") == 8)
	{
		FormatEx(sTankName, sizeof(sTankName), "(AI) %N", tank);
	}
	return sTankName;
}

char[] GetGameDifficulty()
{
	char sGameDifficulty[32];
	GetConVarString(FindConVar("z_difficulty"), sGameDifficulty, sizeof(sGameDifficulty));
	return sGameDifficulty;
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

stock bool IsValidTank(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8 && IsPlayerAlive(client);
}

int IsCountPlayersTeam()
{
	int iCount = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
			iCount++;
	}
	return iCount;
}

int GetIdlePlayerOfBot(int client) {
	if (!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		return 0;

	return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}