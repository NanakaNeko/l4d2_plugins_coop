#pragma semicolon 1
#pragma newdecls required

#define VERSION "1.2"

#include <sourcemod>
#include <sdktools>
#include <colors>  

Handle g_hSDKCreateGift;
ConVar g_cvChance, g_cvNotify;
ArrayList g_aAwardsList, g_aGiftInitChance, g_aGiftChance;
int g_iNotify;

#define SOUND "ui/gift_pickup.wav"

enum struct AwardInfo
{
	char sCmd[128];
	char sCmdArgs[256];
	char sCmdType[32];
	char sMsg[256];
}

public Plugin myinfo = 
{
	name = "L4D2 Gift",
	author = "fdxx,奈",
	version = VERSION,
}

public void OnPluginStart()
{
	InitData();
	LoadAwardConfig();

	CreateConVar("l4d2_gift_version", VERSION, "version", FCVAR_NONE | FCVAR_DONTRECORD);
	g_cvChance = CreateConVar("l4d2_gift_chance", "10", "礼物盒子掉落概率(0-100) 当值为 0 时插件关闭", FCVAR_NONE, true, 0.0, true, 100.0);
	g_cvNotify = CreateConVar("l4d2_gift_notify", "3", "获取物品信息提示. 0=无, 1=聊天框, 2=提示音, 3=两者", FCVAR_NONE, true, 0.0, true, 3.0);

	GetCvars();

	g_cvChance.AddChangeHook(ConVarChanged);
	g_cvNotify.AddChangeHook(ConVarChanged);

	HookEvent("christmas_gift_grab", Event_GiftGrab);
	HookEvent("player_death", Event_PlayerDeath);

	RegAdminCmd("sm_reload_award_cfg", Cmd_ReloadAwardCfg, ADMFLAG_ROOT);
	RegAdminCmd("sm_print_awards_list", Cmd_PrintAwardsList, ADMFLAG_ROOT);
	RegAdminCmd("sm_print_chance_list", Cmd_PrintChanceList, ADMFLAG_ROOT);

	//AutoExecConfig(true, "l4d2_gift");
}

void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();	
}

void GetCvars()
{
	g_iNotify = g_cvNotify.IntValue;

	delete g_aGiftChance;
	g_aGiftChance = g_aGiftInitChance.Clone();

	int iChance = g_cvChance.IntValue;
	for (int i = 0; i < iChance; i++)
		g_aGiftChance.Set(i, 1);
	
	g_aGiftChance.Sort(Sort_Random, Sort_Integer);
}

public void OnMapStart()
{
	if (!IsModelPrecached("models/w_models/weapons/w_sniper_awp.mdl"))
		PrecacheModel("models/w_models/weapons/w_sniper_awp.mdl", true);
	
	PrecacheSound(SOUND, true);
}

void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (GetConVarBool(g_cvChance) && client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 3)
	{
		if (g_aGiftChance.Get(GetRandomIntEx(0, g_aGiftChance.Length-1)) == 1)
		{
			static float fPos[3], fVec[3];
			GetClientAbsOrigin(client, fPos);
			SDKCall(g_hSDKCreateGift, fPos, fVec, fVec, fVec, 0);
		}
	}
}

void Event_GiftGrab(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));

	if (GetConVarBool(g_cvChance) && client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !GetEntProp(client, Prop_Send, "m_isIncapacitated"))
	{
		static AwardInfo Award;
		
		g_aAwardsList.GetArray(GetRandomIntEx(0, g_aAwardsList.Length-1), Award);
		ExecCommand(client, Award.sCmdType, Award.sCmd, Award.sCmdArgs);

		if (g_iNotify == 1 || g_iNotify == 3)
		{
			CPrintToChatAll("[{olive}礼物{default}] {blue}%N {default}%s", client, Award.sMsg);
		}
			
		if (g_iNotify == 2 || g_iNotify == 3)
		{
			static float fPos[3];
			GetClientAbsOrigin(client, fPos);
			EmitAmbientSound(SOUND, fPos);
		}
	} 
}

// https://github.com/bcserv/smlib/blob/transitional_syntax/scripting/include/smlib/math.inc
int GetRandomIntEx(int min, int max)
{
	int random = GetURandomInt();

	if (random == 0)
		random++;

	return RoundToCeil(float(random) / (float(2147483647) / float(max - min + 1))) + min - 1;
}

void ExecCommand(int client, const char[] sType, const char[] sCommand, const char[] sArgs = "")
{
	// Valve cvars cheat command. (give xx)
	if (strcmp(sType, "CheatCommand") == 0)
	{
		int iFlags = GetCommandFlags(sCommand);
		SetCommandFlags(sCommand, iFlags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", sCommand, sArgs);
		SetCommandFlags(sCommand, iFlags);
	}

	// Normal client command. (RegConsoleCmd)
	else if (strcmp(sType, "ClientCommand") == 0)
	{
		ClientCommand(client, "%s %s", sCommand, sArgs);
	}

	// Server command. (RegServerCmd)
	else if (strcmp(sType, "ServerCommand") == 0)
	{
		ServerCommand("%s %s", sCommand, sArgs);
	}
}

void LoadAwardConfig()
{
	delete g_aAwardsList;
	g_aAwardsList = new ArrayList(sizeof(AwardInfo));

	char sCfgPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sCfgPath, sizeof(sCfgPath), "data/l4d2_gift.cfg");

	KeyValues kv = new KeyValues("");
	
	if (kv.ImportFromFile(sCfgPath) && kv.GotoFirstSubKey())
	{
		int iWeights, index, i;
		char sBuffer[256];

		do
		{
			AwardInfo Award;

			iWeights = kv.GetNum("weights");
			if (iWeights <= 0) continue;
			if (iWeights > 100) iWeights = 100;

			kv.GetString("type", Award.sCmdType, sizeof(Award.sCmdType));
			kv.GetString("message", Award.sMsg, sizeof(Award.sMsg));
			kv.GetString("command", sBuffer, sizeof(sBuffer));

			index = SplitString(sBuffer, " ", Award.sCmd, sizeof(Award.sCmd));
			if (index != -1)
				strcopy(Award.sCmdArgs, sizeof(Award.sCmdArgs), sBuffer[index]);
			else strcopy(Award.sCmd, sizeof(Award.sCmd), sBuffer);

			for (i = 0; i < iWeights; i++)
				g_aAwardsList.PushArray(Award);
		}
		while (kv.GotoNextKey());
	}
	else SetFailState("Failed to load l4d2_gift.cfg file");

	g_aAwardsList.Sort(Sort_Random, Sort_String);
	delete kv;
}

void InitData()
{
	GameData hGameData = new GameData("l4d2_gift");
	if (hGameData == null)
		SetFailState("Failed to load l4d2_gift.txt file");

	// https://forums.alliedmods.net/showthread.php?t=320067
	StartPrepSDKCall(SDKCall_Static);
	if (!PrepSDKCall_SetFromConf(hGameData, SDKConf_Signature, "CHolidayGift::Create"))
		SetFailState("Failed to load signature CHolidayGift::Create");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
	g_hSDKCreateGift = EndPrepSDKCall();
	if (g_hSDKCreateGift == null)
		SetFailState("Could not prep the CHolidayGift::Create function");

	delete hGameData;

	delete g_aGiftInitChance;
	g_aGiftInitChance = new ArrayList();
	for (int i = 0; i < 100; i++)
		g_aGiftInitChance.Push(0);
}

Action Cmd_ReloadAwardCfg(int client, int args)
{
	LoadAwardConfig();
	return Plugin_Handled;
}

Action Cmd_PrintAwardsList(int client, int args)
{
	static AwardInfo Award;
	for (int i = 0; i < g_aAwardsList.Length; i++)
	{
		g_aAwardsList.GetArray(i, Award);
		ReplyToCommand(client, "[%i] %s, %s, %s", i, Award.sCmd, Award.sCmdArgs, Award.sMsg);
	}
	return Plugin_Handled;
}

Action Cmd_PrintChanceList(int client, int args)
{
	for (int i = 0; i < g_aGiftChance.Length; i++)
	{
		ReplyToCommand(client, "index %i = %i", i, g_aGiftChance.Get(i));
	}
	return Plugin_Handled;
}

