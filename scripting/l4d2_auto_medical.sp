#include <sdktools>
#include <sourcemod>
#pragma newdecls required
#pragma semicolon 1

ConVar cv_AutoEnable, cv_PillandAdrenaline;
bool b_AutoEnable, b_PillandAdrenaline;
int g_iMultiple, g_iPlayerNumber;

public Plugin myinfo =
{
	name = "[L4D2]自动多倍药物",
	author = "奈",
	description = "自动多倍药物",
	version = "1.7",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public void OnPluginStart()
{
	cv_AutoEnable = CreateConVar("l4d2_auto_enable", "1", "多倍医疗是否开启", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cv_PillandAdrenaline = CreateConVar("l4d2_pill_adrenaline", "0", "多倍医疗是否增加止痛药和肾上腺素", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	b_AutoEnable = GetConVarBool(cv_AutoEnable);
	b_PillandAdrenaline = GetConVarBool(cv_PillandAdrenaline);
	HookConVarChange(cv_AutoEnable, CvarChanged);
	HookConVarChange(cv_PillandAdrenaline, CvarChanged);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	b_AutoEnable = GetConVarBool(cv_AutoEnable);
	b_PillandAdrenaline = GetConVarBool(cv_PillandAdrenaline);
}

public void OnMapStart()
{
	g_iPlayerNumber = 0;
	g_iMultiple = 0;
}

public void Event_RoundStart(Event event, const char []name, bool dontBroadcast)
{
	g_iMultiple = 0;
	CreateTimer(1.0, SetTimer, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action SetTimer(Handle timer)
{
	SetAuto(GetAllPlayerCount());
	return Plugin_Stop;
}

//玩家加入
public void OnClientConnected(int client)
{   
	if(!IsFakeClient(client))
	{
		g_iPlayerNumber += 1;
		SetAuto(g_iPlayerNumber);
	}
}

//玩家退出
public void OnClientDisconnect(int client)
{   
	if(!IsFakeClient(client))
	{
		g_iPlayerNumber -= 1;
		SetAuto(g_iPlayerNumber);
	}
}

void SetAuto(int players)
{
	if(!b_AutoEnable)
		return;
		
	int multiple = players / 4;
	if (players % 4 != 0) multiple++;
	if(multiple != g_iMultiple){
		g_iMultiple = multiple;
		if(b_PillandAdrenaline){
			SetMultMed(g_iMultiple, false);
			PrintToChatAll("\x04[提示]\x03医疗包,止痛药,肾上腺素\x05更改为\x04%d\x05倍.", multiple);
		}
		else{
			SetMultMed(g_iMultiple);
			PrintToChatAll("\x04[提示]\x03医疗包\x05更改为\x04%d\x05倍.", multiple);
		}
	}
}

void SetEntCount(const char[] ent, int count)
{
	int idx = FindEntityByClassname(-1, ent);
	while(idx != -1){
		DispatchKeyValueInt(idx, "count", count);
		idx = FindEntityByClassname(idx, ent);
	}
}

void SetMultMed(int mult, bool kit=true)
{
	if(kit)
		SetEntCount("weapon_first_aid_kit_spawn", mult);	// 医疗包
	else
	{
		SetEntCount("weapon_first_aid_kit_spawn", mult);	// 医疗包
		SetEntCount("weapon_pain_pills_spawn", mult);		// 止痛药
		SetEntCount("weapon_adrenaline_spawn", mult);		// 肾上腺素
	}
}

//获取玩家数量.
int GetAllPlayerCount()
{
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientConnected(i) && !IsFakeClient(i))
				count++;
	
	return count;
}
