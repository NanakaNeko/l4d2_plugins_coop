#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>
#include <l4d2_ems_hud>			

enum struct KillData {
	int TotalSI;
	int TotalCI;

	void Clean() {
		this.TotalSI = 0;
		this.TotalCI = 0;
	}
}

//对抗模式.
char g_sModeVersus[][] = 
{
	"versus",		//对抗模式
	"teamversus ",	//团队对抗
	"scavenge",		//团队清道夫
	"teamscavenge",	//团队清道夫
	"community3",	//骑师派对
	"community6",	//药抗模式
	"mutation11",	//没有救赎
	"mutation12",	//写实对抗
	"mutation13",	//清道肆虐
	"mutation15",	//生存对抗
	"mutation18",	//失血对抗
	"mutation19"	//坦克派对?
};

//单人模式.
char g_sModeSingle[][] = 
{
	"mutation1", //孤身一人
	"mutation17" //孤胆枪手
};
static char mapName[64];
static int g_iFailCount;
ConVar hud_style;
KillData g_eData;
Handle g_hTimer;
bool g_bflow;
int g_ihud, g_iPlayerNum, g_iMaxChapters, g_iCurrentChapter;

public Plugin myinfo = 
{
	name = "Server Info Hud",
	author = "sorallll,豆瓣酱な,奈",
	description = "结合sorallll和豆瓣酱な制作的hud",
	version = "1.1.8",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion game = GetEngineVersion();
	if (game!=Engine_Left4Dead2)
	{
		strcopy(error, err_max, "本插件只支持 Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart() 
{
	hud_style = CreateConVar("l4d2_hud_style", "1", "hud样式切换", _, true, 0.0, true, 5.0);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
	HookEvent("infected_death", Event_InfectedDeath);
	HookEvent("mission_lost", Event_MissionLost);
	g_ihud = GetConVarInt(hud_style);
	HookConVarChange(hud_style, CvarChanged);

	hud_start();
}

public void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_ihud = GetConVarInt(hud_style);
	hud_start(true);
}

public void OnConfigsExecuted() 
{
	g_iMaxChapters = L4D_GetMaxChapters();
	g_iCurrentChapter = L4D_GetCurrentChapter();
}


//玩家连接
public void OnClientConnected(int client)
{   
	if (!IsFakeClient(client))
		g_iPlayerNum += 1;
}

//玩家离开.
public void OnClientDisconnect(int client)
{   
	if (!IsFakeClient(client))
		g_iPlayerNum -= 1;
}

public void OnMapStart() 
{
	char nowMapName[64];
	GetCurrentMap(nowMapName, sizeof(nowMapName));
	if (strlen(mapName) < 1 || strcmp(mapName, nowMapName) != 0) {
		g_iFailCount = 0;
		strcopy(mapName, sizeof(mapName), nowMapName);
	}

	g_iPlayerNum = 0;
	EnableHUD();
}

public void OnMapEnd() 
{
	delete g_hTimer;
	g_eData.Clean();
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast) 
{
	delete g_hTimer;
	g_eData.Clean();
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast) 
{
	char nowMapName[64] = {'\0'};
	GetCurrentMap(nowMapName, sizeof(nowMapName));
	if (strlen(mapName) < 1 || strcmp(mapName, nowMapName) != 0) {
		g_iFailCount = 0;
		strcopy(mapName, sizeof(mapName), nowMapName);
	}

	g_bflow = true;
	hud_start();
}

void Event_MissionLost(Event event, const char[] name, bool dontBroadcast) 
{
	g_iFailCount++;
}

void hud_start(bool restart=false)
{
	if(g_ihud == 0){
		delete g_hTimer;
		if(restart)
			RestartMap();
	}
	else if(g_ihud == 1){
		delete g_hTimer;
		g_hTimer = CreateTimer(1.0, tmrUpdate1, _, TIMER_REPEAT);
		if(restart)
			RestartMap();
	}
	else if(g_ihud == 2){
		delete g_hTimer;
		g_hTimer = CreateTimer(1.0, tmrUpdate2, _, TIMER_REPEAT);
		if(restart)
			RestartMap();
	}
	else if(g_ihud == 3){
		delete g_hTimer;
		g_hTimer = CreateTimer(1.0, tmrUpdate3, _, TIMER_REPEAT);
		if(restart)
			RestartMap();
	}
	else if(g_ihud == 4){
		delete g_hTimer;
		g_hTimer = CreateTimer(1.0, tmrUpdate4, _, TIMER_REPEAT);
		if(restart)
			RestartMap();
	}
	else if(g_ihud == 5){
		delete g_hTimer;
		g_hTimer = CreateTimer(1.0, tmrUpdate5, _, TIMER_REPEAT);
		if(restart)
			RestartMap();
	}
}

void RestartMap()
{
	char mapbuffer[64];
	GetCurrentMap(mapbuffer, sizeof(mapbuffer));
	ServerCommand("changelevel %s", mapbuffer);
}

Action tmrUpdate1(Handle timer) 
{
	static char buffer[128];
	static int roundNumber;
	if(g_bflow)
	{
		g_bflow = false;
		char tank[16];
		char witch[16];
		roundNumber = GameRules_GetProp("m_bInSecondHalfOfRound");
		IntToString(RoundToCeil(L4D2Direct_GetVSTankFlowPercent(roundNumber) * 100.0), tank, sizeof(tank));
		StrCat(tank, sizeof(tank), "%");
		Format(buffer, sizeof(buffer), "坦克: [%s]", L4D2Direct_GetVSTankToSpawnThisRound(roundNumber) ? tank : "固定");

		IntToString(RoundToCeil(L4D2Direct_GetVSWitchFlowPercent(roundNumber) * 100.0), witch, sizeof(witch));
		StrCat(witch, sizeof(witch), "%");
		Format(buffer, sizeof(buffer), "%s%s女巫: [%s]", buffer, GetAddSpacesMax(5, " "), L4D2Direct_GetVSWitchToSpawnThisRound(roundNumber) ? witch : "固定");
	}

	static int client;
	static float maxFlow;
	static float highestFlow;
	maxFlow = L4D2Direct_GetMapMaxFlowDistance();
	highestFlow = (client = L4D_GetHighestFlowSurvivor()) != -1 ? L4D2Direct_GetFlowDistance(client) : L4D2_GetFurthestSurvivorFlow();
	if (highestFlow)
		highestFlow = highestFlow / maxFlow * 100;

	HUDSetLayout(HUD_SCORE_1, HUD_FLAG_TEXT|HUD_FLAG_NOBG|HUD_FLAG_ALIGN_LEFT, "路程: [%d%%]%s%s", RoundToCeil(highestFlow), GetAddSpacesMax(5, " "), buffer);
	HUDPlace(HUD_SCORE_1, 0.02, 0.00, 1.0, 0.03);

	char Time[128];
	FormatEx(Time, sizeof(Time), "%s %s %s%s", GetDate(), GetWeek(), GetAPM(), Get12Time());
	HUDSetLayout(HUD_SCORE_2, HUD_FLAG_ALIGN_RIGHT|HUD_FLAG_NOBG|HUD_FLAG_TEXT, Time);
	HUDPlace(HUD_SCORE_2, -0.02, 0.00, 1.0, 0.03);

	HUDSetLayout(HUD_SCORE_3, HUD_FLAG_TEXT|HUD_FLAG_NOBG|HUD_FLAG_ALIGN_RIGHT, "团灭: %d次 关卡: [%d/%d] 人数: [%d/%d]", g_iFailCount, g_iCurrentChapter, g_iMaxChapters, g_iPlayerNum, GetMaxPlayers());
	HUDPlace(HUD_SCORE_3, -0.02, 0.03, 1.0, 0.03);

	HUDSetLayout(HUD_SCORE_4, HUD_FLAG_TEXT|HUD_FLAG_NOBG|HUD_FLAG_ALIGN_RIGHT, "统计: 特感:%d 僵尸:%d", g_eData.TotalSI, g_eData.TotalCI);
	HUDPlace(HUD_SCORE_4, -0.02, 0.06, 1.0, 0.03);

	return Plugin_Continue;
}

Action tmrUpdate2(Handle timer) 
{
	static char buffer[192];
	static int roundNumber;
	if(g_bflow)
	{
		g_bflow = false;
		char tank[16];
		char witch[16];
		roundNumber = GameRules_GetProp("m_bInSecondHalfOfRound");
		IntToString(RoundToCeil(L4D2Direct_GetVSTankFlowPercent(roundNumber) * 100.0), tank, sizeof(tank));
		StrCat(tank, sizeof(tank), "%");
		Format(buffer, sizeof(buffer), "坦克: [%s]", L4D2Direct_GetVSTankToSpawnThisRound(roundNumber) ? tank : "固定");

		IntToString(RoundToCeil(L4D2Direct_GetVSWitchFlowPercent(roundNumber) * 100.0), witch, sizeof(witch));
		StrCat(witch, sizeof(witch), "%");
		Format(buffer, sizeof(buffer), "%s%s女巫: [%s]", buffer, GetAddSpacesMax(5, " "), L4D2Direct_GetVSWitchToSpawnThisRound(roundNumber) ? witch : "固定");
	}

	static int client;
	static float maxFlow;
	static float highestFlow;
	maxFlow = L4D2Direct_GetMapMaxFlowDistance();
	highestFlow = (client = L4D_GetHighestFlowSurvivor()) != -1 ? L4D2Direct_GetFlowDistance(client) : L4D2_GetFurthestSurvivorFlow();
	if (highestFlow)
		highestFlow = highestFlow / maxFlow * 100;

	HUDSetLayout(HUD_SCORE_1, HUD_FLAG_TEXT|HUD_FLAG_NOBG|HUD_FLAG_ALIGN_LEFT, "路程: [%d%%]%s%s", RoundToCeil(highestFlow), GetAddSpacesMax(5, " "), buffer);
	HUDPlace(HUD_SCORE_1, 0.05, 0.00, 1.0, 0.03);

	HUDSetLayout(HUD_SCORE_2, HUD_FLAG_TEXT|HUD_FLAG_NOBG|HUD_FLAG_ALIGN_RIGHT, "%s[%d/%d]", GetHostName(), g_iPlayerNum, GetMaxPlayers());
	HUDPlace(HUD_SCORE_2, -0.05, 0.00, 1.0, 0.03);

	return Plugin_Continue;
}

Action tmrUpdate3(Handle timer) 
{
	static char buffer[128];
	static int roundNumber;
	if(g_bflow)
	{
		g_bflow = false;
		char tank[16];
		char witch[16];
		roundNumber = GameRules_GetProp("m_bInSecondHalfOfRound");
		IntToString(RoundToCeil(L4D2Direct_GetVSTankFlowPercent(roundNumber) * 100.0), tank, sizeof(tank));
		StrCat(tank, sizeof(tank), "%");
		Format(buffer, sizeof(buffer), "坦克: [%s]", L4D2Direct_GetVSTankToSpawnThisRound(roundNumber) ? tank : "固定");

		IntToString(RoundToCeil(L4D2Direct_GetVSWitchFlowPercent(roundNumber) * 100.0), witch, sizeof(witch));
		StrCat(witch, sizeof(witch), "%");
		Format(buffer, sizeof(buffer), "%s%s女巫: [%s]", buffer, GetAddSpacesMax(5, " "), L4D2Direct_GetVSWitchToSpawnThisRound(roundNumber) ? witch : "固定");
	}

	HUDSetLayout(HUD_SCORE_1, HUD_FLAG_TEXT|HUD_FLAG_NOBG|HUD_FLAG_ALIGN_LEFT, "%s", buffer);
	HUDPlace(HUD_SCORE_1, 0.02, 0.00, 1.0, 0.03);

	HUDSetLayout(HUD_SCORE_2, HUD_FLAG_TEXT|HUD_FLAG_NOBG|HUD_FLAG_ALIGN_CENTER, "%s", GetHostName());
	HUDPlace(HUD_SCORE_2, 0.00, 0.00, 1.0, 0.03);

	HUDSetLayout(HUD_SCORE_3, HUD_FLAG_TEXT|HUD_FLAG_NOBG|HUD_FLAG_ALIGN_RIGHT, "人数: [%d/%d]%s关卡: [%d/%d]", g_iPlayerNum, GetMaxPlayers(), GetAddSpacesMax(5, " "), g_iCurrentChapter, g_iMaxChapters);
	HUDPlace(HUD_SCORE_3, -0.02, 0.00, 1.0, 0.03);

	return Plugin_Continue;
}

Action tmrUpdate4(Handle timer) 
{
	HUDSetLayout(HUD_SCORE_1, HUD_FLAG_TEXT|HUD_FLAG_NOBG|HUD_FLAG_ALIGN_LEFT, "关卡: [%d/%d]%s人数: [%d/%d]", g_iCurrentChapter, g_iMaxChapters, GetAddSpacesMax(5, " "), g_iPlayerNum, GetMaxPlayers());
	HUDPlace(HUD_SCORE_1, 0.02, 0.00, 1.0, 0.03);

	HUDSetLayout(HUD_SCORE_2, HUD_FLAG_TEXT|HUD_FLAG_NOBG|HUD_FLAG_ALIGN_CENTER, "%s", GetHostName());
	HUDPlace(HUD_SCORE_2, 0.00, 0.00, 1.0, 0.03);

	HUDSetLayout(HUD_SCORE_3, HUD_FLAG_TEXT|HUD_FLAG_NOBG|HUD_FLAG_ALIGN_RIGHT, "统计: 特感:%d 僵尸:%d", g_eData.TotalSI, g_eData.TotalCI);
	HUDPlace(HUD_SCORE_3, -0.02, 0.00, 1.0, 0.03);

	return Plugin_Continue;
}

Action tmrUpdate5(Handle timer) 
{
	HUDSetLayout(HUD_SCORE_1, HUD_FLAG_TEXT|HUD_FLAG_NOBG|HUD_FLAG_ALIGN_LEFT, "统计: 特感:%d 僵尸:%d", g_eData.TotalSI, g_eData.TotalCI);
	HUDPlace(HUD_SCORE_1, 0.05, 0.00, 1.0, 0.03);

	char Time[128];
	FormatEx(Time, sizeof(Time), "%s %s %s%s", GetDate(), GetWeek(), GetAPM(), Get12Time());
	HUDSetLayout(HUD_SCORE_2, HUD_FLAG_ALIGN_RIGHT|HUD_FLAG_NOBG|HUD_FLAG_TEXT, Time);
	HUDPlace(HUD_SCORE_2, -0.05, 0.00, 1.0, 0.03);

	HUDSetLayout(HUD_SCORE_3, HUD_FLAG_TEXT|HUD_FLAG_NOBG|HUD_FLAG_ALIGN_RIGHT, "团灭: %d次 关卡: [%d/%d] 人数: [%d/%d]",g_iFailCount, g_iCurrentChapter, g_iMaxChapters, g_iPlayerNum, GetMaxPlayers());
	HUDPlace(HUD_SCORE_3, -0.05, 0.03, 1.0, 0.03);

	return Plugin_Continue;
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast) 
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	if (!victim || !IsClientInGame(victim) || GetClientTeam(victim) != 3)
		return;

	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!attacker || !IsClientInGame(attacker) || GetClientTeam(attacker) != 2)
		return;

	g_eData.TotalSI++;
}

void Event_InfectedDeath(Event event, const char[] name, bool dontBroadcast) 
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!attacker || !IsClientInGame(attacker) || GetClientTeam(attacker) != 2)
		return;

	g_eData.TotalCI++;
}

//返回服务器名字.
char[] GetHostName()
{
	char g_sHostName[256];
	FindConVar("hostname").GetString(g_sHostName, sizeof(g_sHostName));
	return g_sHostName;
}

//返回当前年月日.
char[] GetDate()
{
	char g_sDate[64];
	FormatTime(g_sDate, sizeof(g_sDate), "%Y年%m月%d日");
	return g_sDate;
}

//返回当前周几.
char[] GetWeek()
{
	char g_sWeek[8];
	char g_sWeekName[][] = {"周一", "周二", "周三", "周四", "周五", "周六", "周日"};
	FormatTime(g_sWeek, sizeof(g_sWeek), "%u");
	return g_sWeekName[StringToInt(g_sWeek) - 1];
}

//返回上午下午
char[] GetAPM()
{
	char g_sAPM[4], g_sMaA[8];
	FormatTime(g_sAPM, sizeof(g_sAPM), "%p");
	if(StrContains(g_sAPM, "AM", false) != -1)
		Format(g_sMaA, sizeof(g_sMaA), "上午");
	else if(StrContains(g_sAPM, "PM", false) != -1)
		Format(g_sMaA, sizeof(g_sMaA), "下午");
	else
		Format(g_sMaA, sizeof(g_sMaA), "");
	return g_sMaA;
}

//返回时间
char[] Get12Time()
{
	char g_sTime[8];
	FormatTime(g_sTime, sizeof(g_sTime), "%I:%M");
	return g_sTime;
}

//填入对应数量的内容.
char[] GetAddSpacesMax(int Value, char[] sContent)
{
	char g_sBlank[64];
	
	if(Value > 0)
	{
		char g_sFill[32][64];
		if(Value > sizeof(g_sFill))
			Value = sizeof(g_sFill);
		for (int i = 0; i < Value; i++)
			strcopy(g_sFill[i], sizeof(g_sFill[]), sContent);
		ImplodeStrings(g_sFill, sizeof(g_sFill), "", g_sBlank, sizeof(g_sBlank));//打包字符串.
	}
	return g_sBlank;
}

//返回最大人数.
int GetMaxPlayers()
{
	static Handle g_hMaxPlayers;
	g_hMaxPlayers = FindConVar("sv_maxplayers");
	if (g_hMaxPlayers == null)
		return GetDefaultNumber();
		
	int g_iMaxPlayers = GetConVarInt(g_hMaxPlayers);
	if(g_iMaxPlayers <= -1)
		return GetDefaultNumber();
	
	return g_iMaxPlayers;
}

int GetDefaultNumber()
{
	for (int i = 0; i < sizeof(g_sModeVersus); i++)
		if(strcmp(GetGameMode(), g_sModeVersus[i]) == 0)
			return 8;
	for (int i = 0; i < sizeof(g_sModeSingle); i++)
		if(strcmp(GetGameMode(), g_sModeSingle[i]) == 0)
			return 1;
	return 4;
}

char[] GetGameMode()
{
	char g_sMode[32];
	GetConVarString(FindConVar("mp_gamemode"), g_sMode, sizeof(g_sMode));
	return g_sMode;
}
