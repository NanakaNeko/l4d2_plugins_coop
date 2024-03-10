#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法

#include <sourcemod>
#include <colors> 
#include <builtinvotes> //https://github.com/L4D-Community/builtinvotes/actions

#define PLUGIN_VERSION			"1.5.1"
#define PLUGIN_NAME			    "match_vote"
#define DEBUG 0

public Plugin myinfo = 
{
	name = "Match Vote",
	author = "HarryPotter,奈",
	description = "Type !match/!rmatch to vote a new mode",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/profiles/76561198026784913/"
}

//bool g_bL4D2Version;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if( test == Engine_Left4Dead )
	{
		//g_bL4D2Version = false;
	}
	else if( test == Engine_Left4Dead2 )
	{
		//g_bL4D2Version = true;
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

#define MATCHMODES_PATH		"data/matchmodes.txt"

#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

#define TEAM_SPECTATOR		1
#define TEAM_SURVIVOR		2
#define TEAM_INFECTED		3

#define VOTE_TIME 20

ConVar g_hCvarEnable, g_hCvarVoteDealy, g_hCvarVoteRequired;
bool g_bCvarEnable;
int g_iCvarVoteDealy, g_iCvarVoteRequired;

Handle g_hMatchVote, VoteDelayTimer, g_hRMatchVote;
KeyValues g_hModesKV;
char g_sCfg[128], g_sCfgName[128];
int g_iLocalVoteDelay;
bool g_bVoteInProgress, g_bMatching;

public void OnPluginStart()
{
	g_hCvarEnable 		    = CreateConVar( PLUGIN_NAME ... "_enable",       "1",   "0=关, 1=开", CVAR_FLAGS, true, 0.0, true, 1.0);
	g_hCvarVoteDealy        = CreateConVar( PLUGIN_NAME ... "_delay",        "60",  "投票间隔时间", CVAR_FLAGS, true, 1.0);
	g_hCvarVoteRequired     = CreateConVar( PLUGIN_NAME ... "_required",     "1",   "最低几名玩家才可以开启模式投票", CVAR_FLAGS, true, 1.0);
	CreateConVar(                           PLUGIN_NAME ... "_version",      PLUGIN_VERSION, PLUGIN_NAME ... "插件版本", CVAR_FLAGS_PLUGIN_VERSION);
	//AutoExecConfig(true, PLUGIN_NAME);

	GetCvars();
	g_hCvarEnable.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarVoteDealy.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarVoteRequired.AddChangeHook(ConVarChanged_Cvars);

	RegConsoleCmd("sm_match", MatchRequest);
	RegConsoleCmd("sm_rmatch", ResetMatch);
}

public void OnPluginEnd()
{
	StopVote();
	delete VoteDelayTimer;
}

//Cvars-------------------------------

void ConVarChanged_Cvars(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	GetCvars();
}

void GetCvars()
{
	g_bCvarEnable = g_hCvarEnable.BoolValue;
	g_iCvarVoteDealy = g_hCvarVoteDealy.IntValue;
	g_iCvarVoteRequired = g_hCvarVoteRequired.IntValue;
}

//Sourcemod API Forward-------------------------------

public void OnMapStart()
{
    StopVote();
    g_bVoteInProgress = false;
}

public void OnMapEnd()
{
	g_iLocalVoteDelay = 0;
	delete VoteDelayTimer;
}

public void OnConfigsExecuted()
{
	delete g_hModesKV;

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), MATCHMODES_PATH);
	if( !FileExists(sPath) )
	{
		SetFailState("文件不存在: %s", sPath);
		return;
	}
	
	g_hModesKV = new KeyValues("MatchModes");
	if ( !g_hModesKV.ImportFromFile(sPath) )
	{
		SetFailState("File Format Not Correct: %s", sPath);
		delete g_hModesKV;
		return;
	}
}

//Commands-------------------------------

Action MatchRequest(int client, int args)
{
	if (client == 0)
	{
		PrintToServer("这个命令不能用于服务器.");
		return Plugin_Handled;
	}

	if (g_bCvarEnable == false)
	{
		ReplyToCommand(client, "命令被禁止.");
		return Plugin_Handled;
	}

	//show main menu
	MatchModeMenu(client);

	return Plugin_Handled;
}

//Commands-------------------------------

Action ResetMatch(int client, int args)
{
	if(g_bMatching){
		if(StartRmatchVote(client)){
			CPrintToChatAll("[{olive}Match{default}] {blue}%N{default} 发起一个卸载 {green}%s {default}模式的投票.", client, g_sCfgName);
			return Plugin_Handled;
		}
	}
	else
		CPrintToChatAll("[{olive}Match{default}] 当前没有加载任何模式!");
	return Plugin_Handled;
}

bool StartRmatchVote(int client)
{
	static char sBuffer[256];
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "../../cfg/%soff.cfg", g_sCfg);
	if (!FileExists(sBuffer))
	{
		CPrintToChat(client, "[{olive}Match{default}] 文件 {green}%s {default}不存在!", sBuffer);
		return false;
	}

	if (GetClientTeam(client) == TEAM_SPECTATOR)
	{
		CPrintToChat(client, "[{olive}Match{default}] 旁观者不允许发起切换模式的投票.");
		return false;
	}

	if (g_bVoteInProgress || IsBuiltinVoteInProgress())
	{
		CPrintToChat(client, "[{olive}Match{default}] 当前有一个正在进行的投票, 无法发起新的投票.");
		return false;
	}

	if (VoteDelayTimer != null)
	{
		CPrintToChat(client, "[{olive}Match{default}] 你需要等待 {green}%d {default}秒才能重新发起投票.", g_iLocalVoteDelay);

		return false;
	}

	int iNumPlayers;
	int[] iPlayers = new int[MaxClients+1];
	//list of non-spectators players
	for (int i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == TEAM_SPECTATOR))
		{
			continue;
		}

		iPlayers[iNumPlayers++] = i;
	}

	g_hRMatchVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
	FormatEx(sBuffer, sizeof(sBuffer), "卸载 '%s' 模式?", g_sCfgName);
	SetBuiltinVoteArgument(g_hRMatchVote, sBuffer);
	SetBuiltinVoteInitiator(g_hRMatchVote, client);
	SetBuiltinVoteResultCallback(g_hRMatchVote, RmatchVoteResultHandler);
	DisplayBuiltinVote(g_hRMatchVote, iPlayers, iNumPlayers, VOTE_TIME);
	FakeClientCommand(client, "Vote Yes");

	return true;
}

void RmatchVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
    for (int i=0; i<num_items; i++)
    {
        if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_votes / 2))
			{
				DisplayBuiltinVotePass(vote, "正在卸载模式...");
				CreateTimer(3.0, Timer_RmatchVotePass, _, TIMER_FLAG_NO_MAPCHANGE);
				return;
			}
        }
    }

    DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

Action Timer_RmatchVotePass(Handle timer, int client)
{
	g_bMatching = false;
	ServerCommand("exec %soff", g_sCfg);
	return Plugin_Continue;
}

//Menu-------------------------------

void MatchModeMenu(int client)
{
	if(g_hModesKV == null) return;
	g_hModesKV.Rewind();

	Menu hMenu = new Menu(MatchModeMenuHandler);
	hMenu.SetTitle("选择模式:");
	static char sBuffer[64];
	if (g_hModesKV.GotoFirstSubKey())
	{
		do
		{
			g_hModesKV.GetSectionName(sBuffer, sizeof(sBuffer));
			hMenu.AddItem(sBuffer, sBuffer);
		} while (g_hModesKV.GotoNextKey());
	}
	hMenu.Display(client, 20);
}

int MatchModeMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		if(g_hModesKV == null) return 0;
		g_hModesKV.Rewind();
		
		static char sInfo[64], sBuffer[64];
		menu.GetItem(param2, sInfo, sizeof(sInfo));
		if (g_hModesKV.JumpToKey(sInfo) && g_hModesKV.GotoFirstSubKey())
		{
			Menu hMenu = new Menu(ConfigsMenuHandler);
			Format(sBuffer, sizeof(sBuffer), "选择 %s 配置:", sInfo);
			hMenu.SetTitle(sBuffer);

			do
			{
				g_hModesKV.GetSectionName(sInfo, sizeof(sInfo));
				g_hModesKV.GetString("name", sBuffer, sizeof(sBuffer));
				hMenu.AddItem(sInfo, sBuffer);
			} while (g_hModesKV.GotoNextKey());

			hMenu.Display(param1, 20);
		}
		else
		{
			CPrintToChat(param1, "[{olive}Match{default}] 配置文件未找到.");
			MatchModeMenu(param1);
		}
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}

	return 0;
}

int ConfigsMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		static char sInfo[128], sBuffer[64];
		menu.GetItem(param2, sInfo, sizeof(sInfo), _, sBuffer, sizeof(sBuffer));
		if (StartMatchVote(param1, sInfo, sBuffer))
		{
			strcopy(g_sCfg, sizeof(g_sCfg), sInfo);
			CPrintToChatAll("[{olive}Match{default}] {blue}%N {default}发起一个将模式更改为 {green}%s {default}的投票.", param1, sBuffer);
			return 0;
		}

		MatchModeMenu(param1);
	}
	else if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		MatchModeMenu(param1);
	}

	return 0;
}

//Vote-------------------------------

bool StartMatchVote(int client, const char[] cfgpatch, const char[] cfgname)
{
	static char sBuffer[256];
	BuildPath(Path_SM, sBuffer, sizeof(sBuffer), "../../cfg/%s.cfg", cfgpatch);
	if (!FileExists(sBuffer))
	{
		CPrintToChat(client, "[{olive}Match{default}] 文件 {green}%s {default}不存在!", sBuffer);
		return false;
	}

	if (GetClientTeam(client) == TEAM_SPECTATOR)
	{
		CPrintToChat(client, "[{olive}Match{default}] 旁观者不允许发起切换模式的投票.");
		return false;
	}

	if (g_bVoteInProgress || IsBuiltinVoteInProgress())
	{
		CPrintToChat(client, "[{olive}Match{default}] 当前有一个正在进行的投票, 无法发起新的投票.");
		return false;
	}

	if (VoteDelayTimer != null)
	{
		CPrintToChat(client, "[{olive}Match{default}] 你需要等待 {green}%d {default}秒才能重新发起投票.", g_iLocalVoteDelay);

		return false;
	}

	if (g_bMatching)
	{
		CPrintToChat(client, "[{olive}Match{default}] 你需要先 {green}!rmatch {default}卸载当前模式!");

		return false;
	}

	int iNumPlayers;
	int[] iPlayers = new int[MaxClients+1];
	//list of non-spectators players
	for (int i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == TEAM_SPECTATOR))
		{
			continue;
		}

		iPlayers[iNumPlayers++] = i;
	}

	if (iNumPlayers < g_iCvarVoteRequired)
	{
		CPrintToChat(client, "[{olive}Match{default}] 当前 {green}%d {default}玩家, 数量小于允许发起投票的最小玩家数量.", g_iCvarVoteRequired);
		return false;
	}

	g_hMatchVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);

	FormatEx(sBuffer, sizeof(sBuffer), "切换 '%s' 模式?", cfgname);
	strcopy(g_sCfgName, sizeof(g_sCfgName), cfgname);
	SetBuiltinVoteArgument(g_hMatchVote, sBuffer);
	SetBuiltinVoteInitiator(g_hMatchVote, client);
	SetBuiltinVoteResultCallback(g_hMatchVote, VoteResultHandler);
	DisplayBuiltinVote(g_hMatchVote, iPlayers, iNumPlayers, VOTE_TIME);
	FakeClientCommand(client, "Vote Yes");

	return true;
}

int VoteActionHandler(Handle vote, BuiltinVoteAction action, int param1, int param2)
{
    switch (action)
    {
        case BuiltinVoteAction_End:
        {
            delete vote;
            g_hMatchVote = null;
            VoteEnd();
        }
        case BuiltinVoteAction_Cancel:
        {

        }
    }

    return 0;
}

void VoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
    for (int i=0; i<num_items; i++)
    {
        if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_votes / 2))
			{
				DisplayBuiltinVotePass(vote, "模式正在加载...");
				CreateTimer(3.0, Timer_VotePass, _, TIMER_FLAG_NO_MAPCHANGE);

				return;
			}
        }
    }

    DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

Action Timer_VotePass(Handle timer, int client)
{
	ServerCommand("exec %s", g_sCfg);
	g_bMatching = true;
	return Plugin_Continue;
}

Action Timer_VoteDelay(Handle timer, any client)
{
    g_iLocalVoteDelay--;

    if(g_iLocalVoteDelay<=0)
    {
        VoteDelayTimer = null;
        return Plugin_Stop;
    }

    return Plugin_Continue;
}

//Others-------------------------------

void StopVote()
{
    if(g_hMatchVote!=null)
    {
        CancelBuiltinVote();
    }

    g_bVoteInProgress = false;
}

void VoteEnd()
{
    g_iLocalVoteDelay = g_iCvarVoteDealy;
    delete VoteDelayTimer;
    VoteDelayTimer = CreateTimer(1.0, Timer_VoteDelay, _, TIMER_REPEAT);

    g_bVoteInProgress = false;
}