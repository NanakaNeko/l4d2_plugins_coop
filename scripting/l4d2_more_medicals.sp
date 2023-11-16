#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

ConVar cv_MultiMedicalKits, cv_MultiMedicalPills;
int i_MultiMedicalKits, i_MultiMedicalPills;
public Plugin myinfo = 
{
	name = "[L4D2]多倍药物",
	description = "L4D2 MultiMedical Plugin",
	author = "奈",
	version = "1.3.6",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public void OnPluginStart()
{
	cv_MultiMedicalKits = CreateConVar("l4d2_multi_medical_kits", "1", "初始多倍医疗包", FCVAR_NOTIFY, true, 1.0);
	cv_MultiMedicalPills = CreateConVar("l4d2_multi_medical_pills", "1", "初始多倍止痛药和肾上腺素",FCVAR_NOTIFY, true, 1.0);
	i_MultiMedicalKits = GetConVarInt(cv_MultiMedicalKits);
	i_MultiMedicalPills = GetConVarInt(cv_MultiMedicalPills);
	HookConVarChange(cv_MultiMedicalKits, CvarKitChanged);
	HookConVarChange(cv_MultiMedicalPills, CvarPillChanged);
	HookEvent("round_start", Event_RoundStart);
	RegAdminCmd("sm_mmk", Cmd_SetMultKits, ADMFLAG_ROOT, "设置多倍医疗包");
	RegAdminCmd("sm_mmp", Cmd_SetMultPills, ADMFLAG_ROOT, "设置多倍止痛药和肾上腺素");
	//AutoExecConfig(true, "l4d2_more_medicals");
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer(1.0, MedicalsTimer, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action MedicalsTimer(Handle Timer)
{
	i_MultiMedicalKits = GetConVarInt(cv_MultiMedicalKits);
	SetMultMed(i_MultiMedicalKits);
	i_MultiMedicalPills = GetConVarInt(cv_MultiMedicalPills);
	SetMultMed(i_MultiMedicalPills, false);
	return Plugin_Continue;
}

public void CvarKitChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	i_MultiMedicalKits = GetConVarInt(cv_MultiMedicalKits);
	SetMultMed(i_MultiMedicalKits);
	if(i_MultiMedicalKits == 1)
	{
		PrintToChatAll("\x01[\x04!\x01] \x05多倍医疗包\x03关闭.");
	}
	else
	{
		PrintToChatAll("\x01[\x04!\x01] \x05多倍医疗包\x03开启\x05,更改为\x04%d\x05倍.", i_MultiMedicalKits);
	}
}

public void CvarPillChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	i_MultiMedicalPills = GetConVarInt(cv_MultiMedicalPills);
	SetMultMed(i_MultiMedicalPills, false);
	if(i_MultiMedicalPills == 1)
	{
		PrintToChatAll("\x01[\x04!\x01] \x05多倍止痛药和肾上腺素\x03关闭.");
	}
	else
	{
		PrintToChatAll("\x01[\x04!\x01] \x05多倍止痛药和肾上腺素\x03开启\x05,更改为\x04%d\x05倍.", i_MultiMedicalKits);
	}
}

public Action Cmd_SetMultKits(int client, int args)
{
	if(args == 0)
	{
		PrintToChat(client, "\x01[\x04!\x01] \x05请输入\x04!mmk <数字> \x05例: \x04!mmk 2");
	}
	else if(args == 1)
	{
		char tmp[3];
		GetCmdArg(1, tmp, sizeof(tmp));
		int num = StringToInt(tmp);
		SetConVarInt(cv_MultiMedicalKits, num, true);
	}
	return Plugin_Handled;
}

public Action Cmd_SetMultPills(int client, int args)
{
	if(args == 0)
	{
		PrintToChat(client, "\x01[\x04!\x01] \x05请输入\x04!mmp <数字> \x05例: \x04!mmp 2");
	}
	else if(args == 1)
	{
		char tmp[3];
		GetCmdArg(1, tmp, sizeof(tmp));
		int num = StringToInt(tmp);
		SetConVarInt(cv_MultiMedicalPills, num, true);
	}
	return Plugin_Handled;
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
	{
		SetEntCount("weapon_first_aid_kit_spawn", mult);	// 医疗包
	}
	else
	{
		SetEntCount("weapon_pain_pills_spawn", mult);		// 止痛药
		SetEntCount("weapon_adrenaline_spawn", mult);		// 肾上腺素
	}
	
}
