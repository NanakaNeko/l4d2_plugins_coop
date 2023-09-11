#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

#define HOSTNAME_CONFIG "data/hostname.txt"
#define MODE 16
#define Difficulty 4
ConVar cv_hostname, cv_hostport, cv_difficulty, cv_gamemode;
static KeyValues key;
char c_ModeName[MODE][64] = {"[战役]","[写实]","[绝境求生]","[特感速递]","[血流不止]","[四剑客]","[四分五裂]","[侏儒治愈]","[猎头者]","[狩猎盛宴]","[钢铁侠]","[侏儒卫队]","[死亡之门]","[感染季节]","[生还者模式]","[噩梦经历]"};
char c_ModeCode[MODE][64] = {"coop","realism","mutation4","community1","mutation3","mutation5","mutation14","mutation20","mutation2","mutation16","mutation8","mutation9","community5","community2","survival","community4"};
char c_DifficultyName[Difficulty][32] = {"[简单]", "[普通]", "[高级]", "[专家]"};
char c_DifficultyCode[Difficulty][32] = {"Easy", "Normal", "Hard", "Impossible"};

public Plugin myinfo = {
	name = "服务器名字",
	author = "奈",
	description = "服务器名",
	version = "1.3",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion game = GetEngineVersion();
	if (game!=Engine_Left4Dead && game!=Engine_Left4Dead2)
	{
		strcopy(error, err_max, "本插件只支持 Left 4 Dead 1&2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	key = new KeyValues("hostname");
	cv_hostport = FindConVar("hostport");
	cv_hostname = FindConVar("hostname");
	cv_difficulty = FindConVar("z_difficulty");
	cv_gamemode = FindConVar("mp_gamemode");
	HookConVarChange(cv_difficulty, CvarChange);
	HookConVarChange(cv_gamemode, CvarChange);

	char filePath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, filePath, sizeof(filePath), HOSTNAME_CONFIG);
	if (FileExists(filePath))
	{
		if (!key.ImportFromFile(filePath))
		{
			SetFailState("导入 %s 失败！", filePath);
		}
	}
	setHostname();
}

public void CvarChange(ConVar convar, const char[] oldValue, const char[] newValue) 
{
	setHostname();
}

public void OnClientPutInServer(int client)
{
	setHostname();
}

public void setHostname()
{
	char port[16], ch_hostname[256];
	FormatEx(port, sizeof(port), "%d", cv_hostport.IntValue);
	key.JumpToKey(port);
	key.GetString("hostname", ch_hostname, sizeof(ch_hostname), "求死之路");
	if(!isServerEmpty())
	{
		//模式
		for (int i = 0; i < MODE; i++)
			if(StrEqual(GetGameMode(), c_ModeCode[i]))
				StrCat(ch_hostname, sizeof(ch_hostname), c_ModeName[i]);
		//难度
		for (int i = 0; i < Difficulty; i++)
			if(StrEqual(GetGameDifficulty(), c_DifficultyCode[i], false))
				StrCat(ch_hostname, sizeof(ch_hostname), c_DifficultyName[i]);
	}
	cv_hostname.SetString(ch_hostname);
}

public void OnConfigsExecuted()
{
	setHostname();
}

bool isServerEmpty()
{
	for (int i = 1; i <= MaxClients; i++) { if (IsClientConnected(i) && !IsFakeClient(i)) { return false; } }
	return true;
}

char[] GetGameMode()
{
	char GameMode[32];
	GetConVarString(cv_gamemode, GameMode, sizeof(GameMode));
	return GameMode;
}
char[] GetGameDifficulty()
{
	char GameDifficulty[32];
	GetConVarString(cv_difficulty, GameDifficulty, sizeof(GameDifficulty));
	return GameDifficulty;
}