#pragma semicolon 1
#pragma newdecls required

// 头文件
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include <colors>
//#include "treeutil\treeutil.sp"

#define CVAR_FLAG FCVAR_NOTIFY

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

enum struct PlayerInfo
{
	int totalDamage;
	int siCount;
	int ciCount;
	int ffCount;
	int gotFFCount;
	int headShotCount;
	void init() {
		this.totalDamage = this.siCount = this.ciCount = this.ffCount = this.gotFFCount = this.headShotCount = 0;
	}
} 
PlayerInfo playerInfos[MAXPLAYERS + 1];

static int
	failCount;

static bool
	g_bHasPrint, 
	g_bHasPrintDetails;

static char
	mapName[64];

public Plugin myinfo = 
{
	name 			= "Survivor Mvp & Round Status",
	author 			= "夜羽真白",
	description 	= "生还者 MVP 统计",
	version 		= "2023-07-26",
	url 			= "https://steamcommunity.com/id/saku_ra/"
}

ConVar
	g_hAllowShowMvp,
	g_hWhichTeamToShow,
	g_hAllowShowSi,
	g_hAllowShowCi,
	g_hAllowShowFF,
	g_hAllowShowTotalDmg,
	g_hAllowShowAccuracy,
	g_hAllowShowFailCount,
	g_hAllowShowDetails,
	g_hAllowShowRank;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 && test != Engine_Left4Dead) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hAllowShowMvp = CreateConVar("mvp_allow_show", "1", "是否启用插件", CVAR_FLAG, true, 0.0, true, 1.0);

	g_hWhichTeamToShow = CreateConVar("mvp_witch_team_show", "0", "允许给哪个团队显示 MVP 信息 (0: 所有团队, 1: 仅旁观者团队, 2: 仅生还者团队, 3: 仅特感团队)", CVAR_FLAG, true, 0.0, true, 3.0);
	g_hAllowShowSi = CreateConVar("mvp_allow_show_si", "1", "是否允许显示特感击杀信息", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hAllowShowCi = CreateConVar("mvp_allow_show_ci", "1", "是否允许显示丧尸击杀信息", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hAllowShowFF = CreateConVar("mvp_allow_show_ff", "1", "是否允许显示黑枪与被黑信息", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hAllowShowTotalDmg = CreateConVar("mvp_allow_show_damage", "1", "是否允许显示总伤害信息", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hAllowShowAccuracy = CreateConVar("mvp_allow_show_acc", "1", "是否允许显示准确度信息", CVAR_FLAG, true, 0.0, true, 1.0);

	g_hAllowShowFailCount = CreateConVar("mvp_show_fail_count", "1", "是否在团灭时显示团灭次数", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hAllowShowDetails = CreateConVar("mvp_show_details", "1", "是否在过关或团灭时显示各项 MVP 数据 (每项 MVP 数据显示与否与 mvp_allow_show_xx Cvar 挂钩, 本 Cvar 关闭所有单项数据均不会显示)", CVAR_FLAG, true, 0.0, true, 1.0);
	g_hAllowShowRank = CreateConVar("mvp_show_your_rank", "1", "显示各项 MVP 数据时是否允许显示你的排名", CVAR_FLAG, true, 0.0, true, 1.0);

	// HookEvents
	HookEvent("player_death", siDeathHandler);
	HookEvent("infected_death", ciDeathHandler);
	HookEvent("player_hurt", playerHurtHandler);
	HookEvent("round_start", roundStartHandler);
	HookEvent("round_end", roundEndHandler);
	HookEvent("map_transition", roundEndHandler);
	HookEvent("mission_lost", missionLostHandler);
	HookEvent("finale_vehicle_leaving", roundEndHandler);
	// RegConsoleCmd
	RegConsoleCmd("sm_mvp", showMvpHandler);
}

public void OnMapStart()
{
	g_bHasPrint = g_bHasPrintDetails = false;
	char nowMapName[64];
	GetCurrentMap(nowMapName, sizeof(nowMapName));
	if (strlen(mapName) < 1 || strcmp(mapName, nowMapName) != 0) {
		failCount = 0;
		strcopy(mapName, sizeof(mapName), nowMapName);
	}
	clearStuff();
}

public Action showMvpHandler(int client, int args)
{
	if (!g_hAllowShowMvp.BoolValue)
	{
		ReplyToCommand(client, "[MVP]：当前生还者 MVP 统计数据已禁用");
		return Plugin_Handled;
	}
	if (!IsValidClient(client)) {
		return Plugin_Handled;
	}

	if (GetClientTeam(client) == TEAM_SPECTATOR && (g_hWhichTeamToShow.IntValue != 0 && g_hWhichTeamToShow.IntValue != 1)) {
		CPrintToChat(client, "{blue}[{default}MVP{blue}]: {default}当前生还者 MVP 统计数据不允许向旁观者显示");
		return Plugin_Handled;
	}
	else if (GetClientTeam(client) == TEAM_SURVIVOR && (g_hWhichTeamToShow.IntValue != 0 && g_hWhichTeamToShow.IntValue != 2)) {
		CPrintToChat(client, "{blue}[{default}MVP{blue}]: {default}当前生还者 MVP 统计数据不允许向生还者显示");
		return Plugin_Handled;
	}
	else if (GetClientTeam(client) == TEAM_INFECTED && (g_hWhichTeamToShow.IntValue != 0 && g_hWhichTeamToShow.IntValue != 3)) {
		CPrintToChat(client, "{blue}[{default}MVP{blue}]: {default}当前生还者 MVP 统计数据不允许向感染者显示");
		return Plugin_Handled;
	}
	printMvpStatus(client);
	if (g_hAllowShowDetails.BoolValue) {
		printParticularMvp(client);
	}

	return Plugin_Handled;
}

// 击杀特感
public void siDeathHandler(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid")), attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsValidClient(victim) || !IsValidClient(attacker) || GetClientTeam(victim) != TEAM_INFECTED || GetClientTeam(attacker) != TEAM_SURVIVOR) { return; }
	if (GetInfectedClass(victim) < ZC_SMOKER || GetInfectedClass(victim) > ZC_CHARGER) { return; }
	playerInfos[attacker].siCount++;
	if (event.GetBool("headshot")) { playerInfos[attacker].headShotCount++; }
}

// 击杀丧尸
public void ciDeathHandler(Event event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	if (!IsValidSurvivor(attacker)) { return; }
	playerInfos[attacker].ciCount++;
	if (event.GetBool("headshot")) { playerInfos[attacker].headShotCount++; }
}

// 造成伤害
public void playerHurtHandler(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid")), attacker = GetClientOfUserId(event.GetInt("attacker")), damage = event.GetInt("dmg_health");
	if (IsValidSurvivor(attacker) && IsValidSurvivor(victim))
	{
		playerInfos[attacker].ffCount += damage;
		playerInfos[victim].gotFFCount += damage;
	}
	else if (IsValidSurvivor(attacker) && IsValidInfected(victim) && GetInfectedClass(victim) >= ZC_SMOKER && GetInfectedClass(victim) <= ZC_CHARGER) { playerInfos[attacker].totalDamage += damage; }
}

public void OnClientConnected(int client) {
	playerInfos[client].init();
}

public void OnClientDisconnect(int client) {
	playerInfos[client].init();
}

public void roundStartHandler(Event event, const char[] name, bool dontBroadcast)
{
	g_bHasPrint = g_bHasPrintDetails = false;
	char nowMapName[64] = {'\0'};
	GetCurrentMap(nowMapName, sizeof(nowMapName));
	if (strlen(mapName) < 1 || strcmp(mapName, nowMapName) != 0) {
		failCount = 0;
		strcopy(mapName, sizeof(mapName), nowMapName);
	}
	clearStuff();
}

/**
* 团灭 MVP 显示
* @param 
* @return void
**/
public void missionLostHandler(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_hAllowShowMvp.BoolValue || g_bHasPrint) {
		return;
	}
	
	roundEndPrint();

	if (g_hAllowShowFailCount.BoolValue) {
		CPrintToChatAll("{blue}[{default}提示{blue}]: {default}这是你们第 {olive}%d {default}次团灭，请继续努力哦 (*･ω< )", ++failCount);
	}

	clearStuff();
}

public void roundEndHandler(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_hAllowShowMvp.BoolValue) {
		return;
	}

	roundEndPrint();

	clearStuff();
}

// 方法
void clearStuff() {
	for (int i = 1; i <= MaxClients; i++) { playerInfos[i].init(); }
}

void roundEndPrint() {
	int i;
	for (i = 1; i <= MaxClients; i++) {
		if (!IsValidClient(i)) {
			continue;
		}

		switch (g_hWhichTeamToShow.IntValue) {
			case TEAM_SPECTATOR: {
				if (GetClientTeam(i) != TEAM_SPECTATOR) {
					continue;
				}
			} case TEAM_SURVIVOR: {
				if (GetClientTeam(i) != TEAM_SURVIVOR) {
					continue;
				}
			} case TEAM_INFECTED: {
				if (GetClientTeam(i) != TEAM_INFECTED) {
					continue;
				}
			} default: {

			}
		}

		if (g_bHasPrint) {
			break;
		}
		printMvpStatus(i);
		
		if (g_hAllowShowDetails.BoolValue) {
			if (g_bHasPrintDetails) {
				break;
			}
			printParticularMvp(i);
		}
	}

	g_bHasPrint = true;
	if (g_hAllowShowDetails.BoolValue) {
		g_bHasPrintDetails = true;
	}
}

/**
* 显示主 MVP 信息 (特感击杀, 丧尸击杀, 总伤害, 黑枪/被黑, 爆头率)
* @param client 需要显示的客户端索引
* @return void
**/
void printMvpStatus(int client)
{
	int i, index = 0;
	int[] players = new int[MaxClients + 1]; 
	for (i = 1; i <= MaxClients; i++) {
		if (!IsValidClient(i) || GetClientTeam(i) != TEAM_SURVIVOR) {
			continue;
		}
		players[index++] = i;
	}
	SortCustom1D(players, index, sortByDamageFunction);

	CPrintToChat(client, "{lightgreen}[生还者 MVP 统计]");

	char buffer[128], toPrint[256];
	for (i = 0; i < index; i++) {
		// 格式化排序后一个玩家的 MVP 信息
		if (g_hAllowShowSi.BoolValue) {
			FormatEx(buffer, sizeof(buffer), "{lightgreen}特感{green}%d ", playerInfos[players[i]].siCount);
			StrCat(toPrint, sizeof(toPrint), buffer);
		}
		if (g_hAllowShowCi.BoolValue) {
			FormatEx(buffer, sizeof(buffer), "{lightgreen}丧尸{green}%d ", playerInfos[players[i]].ciCount);
			StrCat(toPrint, sizeof(toPrint), buffer);
		}
		if (g_hAllowShowTotalDmg.BoolValue) {
			FormatEx(buffer, sizeof(buffer), "{lightgreen}伤害{green}%d ", playerInfos[players[i]].totalDamage);
			StrCat(toPrint, sizeof(toPrint), buffer);
		}
		if (g_hAllowShowFF.BoolValue) {
			FormatEx(buffer, sizeof(buffer), "{lightgreen}黑/被黑{green}%d/%d ", playerInfos[players[i]].ffCount, playerInfos[players[i]].gotFFCount);
			StrCat(toPrint, sizeof(toPrint), buffer);
		}
		if (g_hAllowShowAccuracy.BoolValue) {
			float accuracy = playerInfos[players[i]].siCount + playerInfos[players[i]].ciCount == 0 ? 0.0 : float(playerInfos[players[i]].headShotCount) / float(playerInfos[players[i]].siCount + playerInfos[players[i]].ciCount);
			FormatEx(buffer, sizeof(buffer), "{lightgreen}爆头率{green}%.0f%% ", accuracy * 100.0);
			StrCat(toPrint, sizeof(toPrint), buffer);
		}
		FormatEx(buffer, sizeof(buffer), "{olive} - %N", players[i]);
		StrCat(toPrint, sizeof(toPrint), buffer);

		// 打印一个玩家的 MVP 信息
		CPrintToChat(client, "%s", toPrint);
		FormatEx(toPrint, sizeof(toPrint), "");
	}
}

/**
* 显示各项 MVP (SI, CI, FF, RANK)
* @param client 需要显示的客户端索引
* @return void
**/
void printParticularMvp(int client) {
	int siMvpClient, ciMvpClient, ffMvpClient, gotFFMvpClient;
	int dmgTotal, siTotal, ciTotal, ffTotal, gotFFTotal;

	int i;
	for (i = 1; i <= MaxClients; i++) {
		// 跳过不是生还者的
		if (!IsValidClient(i) || GetClientTeam(i) != TEAM_SURVIVOR) {
			continue;
		}
		dmgTotal += playerInfos[i].totalDamage;
		siTotal += playerInfos[i].siCount;
		ciTotal += playerInfos[i].ciCount;
		ffTotal += playerInfos[i].ffCount;
		gotFFTotal += playerInfos[i].gotFFCount;

		if (playerInfos[i].siCount > playerInfos[siMvpClient].siCount) {
			siMvpClient = i;
		}
		if (playerInfos[i].ciCount > playerInfos[ciMvpClient].ciCount) {
			ciMvpClient = i;
		}
		if (playerInfos[i].ffCount > playerInfos[ffMvpClient].ffCount) {
			ffMvpClient = i;
		}
		if (playerInfos[i].gotFFCount > playerInfos[gotFFMvpClient].gotFFCount) {
			gotFFMvpClient = i;
		}
	}

	int dmgPercent, killPercent;
	char clientName[MAX_NAME_LENGTH], buffer[512], temp[256];
	// 允许显示 SI MVP
	if (g_hAllowShowSi.BoolValue) {
		FormatEx(buffer, sizeof(buffer), "{blue}[{default}MVP{blue}] 特感: ");
		if (!IsValidClient(siMvpClient) || siTotal <= 0) {
			StrCat(buffer, sizeof(buffer), "{olive}本局还没有击杀任何特感");
		} else {

			formatMvpClientName(siMvpClient, clientName, sizeof(clientName));

			dmgPercent = RoundToNearest(float(playerInfos[siMvpClient].totalDamage) / float(dmgTotal) * 100.0);
			killPercent = RoundToNearest(float(playerInfos[siMvpClient].siCount) / float(siTotal) * 100.0);
			FormatEx(temp, sizeof(temp), "{green}%s {blue}({default}%d {olive}伤害 {blue}[{default}%d%%{blue}]{default}, %d {olive}击杀 {blue}[{default}%d%%{blue}])", clientName, playerInfos[siMvpClient].totalDamage, dmgPercent, playerInfos[siMvpClient].siCount, killPercent);
			StrCat(buffer, sizeof(buffer), temp);
		}
		CPrintToChat(client, "%s", buffer);
	}
	// 允许显示 CI MVP
	if (g_hAllowShowCi.BoolValue) {
		FormatEx(buffer, sizeof(buffer), "{blue}[{default}MVP{blue}] 丧尸: ");
		if (!IsValidClient(ciMvpClient) || ciTotal <= 0) {
			StrCat(buffer, sizeof(buffer), "{olive}本局还没有击杀任何丧尸");
		} else {

			formatMvpClientName(ciMvpClient, clientName, sizeof(clientName));

			killPercent = RoundToNearest(float(playerInfos[ciMvpClient].ciCount) / float(ciTotal) * 100.0);
			FormatEx(temp, sizeof(temp), "{green}%s {blue}({default}%d {olive}丧尸 {blue}[{default}%d%%{blue}])", clientName, playerInfos[ciMvpClient].ciCount, killPercent);
			StrCat(buffer, sizeof(buffer), temp);
		}
		CPrintToChat(client, "%s", buffer);
	}
	// 允许显示 FF MVP
	if (g_hAllowShowFF.BoolValue) {
		FormatEx(buffer, sizeof(buffer), "{blue}[{default}LVP{blue}] 黑枪: ");
		if (!IsValidClient(ffMvpClient) || ffTotal <= 0) {
			StrCat(buffer, sizeof(buffer), "{olive}大家都没有黑枪");
		} else {

			formatMvpClientName(ffMvpClient, clientName, sizeof(clientName));

			killPercent = RoundToNearest(float(playerInfos[ffMvpClient].ffCount) / float(ffTotal) * 100.0);
			FormatEx(temp, sizeof(temp), "{green}%s {blue}({default}%d {olive}友伤 {blue}[{default}%d%%{blue}])", clientName, playerInfos[ffMvpClient].ffCount, killPercent);
			StrCat(buffer, sizeof(buffer), temp);
		}
		CPrintToChat(client, "%s", buffer);

		// 被黑 MVP
		FormatEx(buffer, sizeof(buffer), "{blue}[{default}MVP{blue}] 被黑: ");
		if (!IsValidClient(gotFFMvpClient) || gotFFTotal <= 0) {
			StrCat(buffer, sizeof(buffer), "{olive}暂时没有倒霉蛋被黑得最惨");
		} else {

			formatMvpClientName(gotFFMvpClient, clientName, sizeof(clientName));

			killPercent = RoundToNearest(float(playerInfos[gotFFMvpClient].gotFFCount) / float(gotFFTotal) * 100.0);
			FormatEx(temp, sizeof(temp), "{green}%s {blue}({default}%d {olive}被黑 {blue}[{default}%d%%{blue}])", clientName, playerInfos[gotFFMvpClient].gotFFCount, killPercent);
			StrCat(buffer, sizeof(buffer), temp);
		}
		CPrintToChat(client, "%s", buffer);
	}
	// 允许显示你的排名
	if (g_hAllowShowRank.BoolValue) {
		// 不是生还者, 不显示排名
		if (!IsValidSurvivor(client)) {
			return;
		}

		int rank;
		rank = GetRank(client, sortBySiCountFunction);
		if(rank > 0 && playerInfos[client].siCount > 0 && playerInfos[client].totalDamage > 0) {
			dmgPercent = RoundToNearest(float(playerInfos[client].totalDamage) / float(dmgTotal) * 100.0);
			killPercent = RoundToNearest(float(playerInfos[client].siCount) / float(siTotal) * 100.0);
			FormatEx(buffer, sizeof(buffer), "{blue}[{default}Rank{blue}] {olive}特感: {green}#%d {blue}({default}%d {olive}伤害 {blue}[{default}%d%%{blue}]{default}, %d {olive}击杀 {blue}[{default}%d%%{blue}])", rank, playerInfos[client].totalDamage, dmgPercent, playerInfos[client].siCount, killPercent);
			CPrintToChat(client, "%s", buffer);
		}
		else
			CPrintToChat(client, "{blue}[{default}Rank{blue}] {olive}特感: {green}暂无排名");

		rank = GetRank(client, sortByCiCountFunction);
		if(rank > 0 && playerInfos[client].ciCount > 0) {
			killPercent = RoundToNearest(float(playerInfos[client].ciCount) / float(ciTotal) * 100.0);
			FormatEx(buffer, sizeof(buffer), "{blue}[{default}Rank{blue}] {olive}丧尸: {green}#%d {blue}({default}%d {olive}击杀 {blue}[{default}%d%%{blue}])", rank, playerInfos[client].ciCount, killPercent);
			CPrintToChat(client, "%s", buffer);
		}
		else
			CPrintToChat(client, "{blue}[{default}Rank{blue}] {olive}丧尸: {green}暂无排名");
	}
}

int GetRank(int client, SortFunc1D SortRank)
{
	int index = 0, rank;
	int[] players = new int[MaxClients + 1];
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsValidSurvivor(i)) {
			continue;
		}
		players[index++] = i;
	}

	SortCustom1D(players, index, SortRank);

	for (int i = 0; i < index; i++) {
		if (players[i] == client) {
			rank = i + 1;
			break;
		}
	}
	return rank;
}


/**
* 根据客户端是否为 BOT 在其名字后面添加 [BOT] 字样
* @param client 需要获取名称的客户端索引
* @param str 名称字符串
* @param len 字符串长度
* @return void
**/
void formatMvpClientName(int client, char[] str, int len) {
	if (IsFakeClient(client)) {
		FormatEx(str, len, "{green}%N {default}[BOT]", client);
	} else {
		FormatEx(str, len, "{green}%N", client);
	}
}

/**
* 按照生还者总伤害击杀特感数量 -> 客户端索引排序
* @param x 第一个参与排序的元素
* @param y 第二个参与排序的元素
* @param array 原数组
* @param hndl 可选句柄
* @return int
**/
stock int sortBySiCountFunction(int x, int y, const int[] array, Handle hndl) {
	return playerInfos[x].siCount > playerInfos[y].siCount ? -1 : playerInfos[x].siCount == playerInfos[y].siCount ? 0 : 1;
}

/**
* 按照生还者击杀丧尸数量 -> 客户端索引排序
* @param x 第一个参与排序的元素
* @param y 第二个参与排序的元素
* @param array 原数组
* @param hndl 可选句柄
* @return int
**/
stock int sortByCiCountFunction(int x, int y, const int[] array, Handle hndl) {
	return playerInfos[x].ciCount > playerInfos[y].ciCount ? -1 : playerInfos[x].ciCount == playerInfos[y].ciCount ? x > y ? -1 : 1 : 1;
}

/**
* 按照生还者总伤害 -> 客户端索引排序
* @param x 第一个参与排序的元素
* @param y 第二个参与排序的元素
* @param array 原数组
* @param hndl 可选句柄
* @return int
**/
stock int sortByTotalDamageFunction(int x, int y, const int[] array, Handle hndl) {
	return playerInfos[x].totalDamage > playerInfos[y].totalDamage ? -1 : playerInfos[x].totalDamage == playerInfos[y].totalDamage ? x > y ? -1 : 1 : 1;
}

/**
* 按照生还者总伤害 -> 爆头率 -> 客户端索引排序
* @param x 第一个参与排序的元素
* @param y 第二个参与排序的元素
* @param array 原数组
* @param hndl 可选句柄
* @return int
**/
stock int sortByDamageFunction(int x, int y, const int[] array, Handle hndl) {
	int xDamage = playerInfos[x].totalDamage, yDamage = playerInfos[y].totalDamage;

	int xCount = playerInfos[x].siCount + playerInfos[x].ciCount,
		yCount = playerInfos[y].siCount + playerInfos[y].ciCount;
	float xAcc = xCount == 0 ? 0.0 : float(playerInfos[x].headShotCount) / float(xCount),
		yAcc = yCount == 0 ? 0.0 : float(playerInfos[y].headShotCount) / float(yCount);
	// 先按总伤害排名，总伤害一样按爆头率排名, 爆头率一样按客户端索引排名
	return xDamage > yDamage ? -1 : xDamage == yDamage ? FloatCompare(xAcc, yAcc) > 0 ? -1 : FloatCompare(xAcc, yAcc) == 0 ? x > y ? -1 : 1 : 1 : 1;
}

/**
* 按照生还者黑枪 -> 被黑 -> 客户端索引排序
* @param x 第一个参与排序的元素
* @param y 第二个参与排序的元素
* @param array 原数组
* @param hndl 可选句柄
* @return int
**/
stock int sortByFriendlyFireFunction(int x, int y, const int[] array, Handle hndl) {
	int xFF = playerInfos[x].ffCount, yFF = playerInfos[y].ffCount;
	int xGotFF = playerInfos[x].gotFFCount, yGotFF = playerInfos[y].gotFFCount;
	// 先按黑枪排名, 友伤一样按被黑排名, 黑枪一样按客户端索引排名
	return xFF > yFF ? -1 : xFF == yFF ? xGotFF > yGotFF ? -1 : xGotFF == yGotFF ? x > y ? -1 : 1 : 1 : 1;
}

/**
* 按照生还者被黑 -> 客户端索引排序
* @param x 第一个参与排序的元素
* @param y 第二个参与排序的元素
* @param array 原数组
* @param hndl 可选句柄
* @return int
**/
stock int sortByFFReceiveFunction(int x, int y, const int[] array, Handle hndl) {
	return playerInfos[x].gotFFCount > playerInfos[y].gotFFCount ? -1 : playerInfos[x].gotFFCount == playerInfos[y].gotFFCount ? x > y ? -1 : 1 : 1;
}

// 判断是否有效玩家 id，有效返回 true，无效返回 false
// @client：需要判断的生还者客户端索引
stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}
// 判断生还者是否有效，有效返回 true，无效返回 false
// @client：需要判断的生还者客户端索引
stock bool IsValidSurvivor(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == view_as<int>(TEAM_SURVIVOR);
}
// 判断特感是否有效，有效返回 true，无效返回 false
stock bool IsValidInfected(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == TEAM_INFECTED;
}
// 获取特感类型，成功返回特感类型，失败返回 -1
stock int GetInfectedClass(int client)
{
	return IsValidInfected(client) ? GetEntProp(client, Prop_Send, "m_zombieClass") : -1;
}