#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

ConVar
	cv_Weapon,
	cv_WeaponReplace,
	cv_stripper,
	cv_Rhp,
	cv_Restore,
	cv_Siammoregain,
	cv_SiNum,
	cv_SiTime,
	cv_SiMode;
	
int
	Weapon,
	WReplace,
	MapStripper,
	Rhp,
	Restore,
	Siammoregain;

public Plugin myinfo = 
{
    name        = "!xx查询信息",
    author      = "奈",
    description = "服务器信息查询",
    version     = "1.2.5",
    url         = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_xx", Status);

	cv_SiNum = FindConVar("l4d2_si_spawn_control_max_specials");
	cv_SiTime = FindConVar("l4d2_si_spawn_control_spawn_time");
	cv_SiMode = FindConVar("l4d2_si_spawn_control_together_spawn");
	
	cv_Weapon = CreateConVar("WeaponDamage", "-1", "设置武器伤害", _, true, -1.0, true, 2.0);
	cv_WeaponReplace = CreateConVar("WeaponReplace", "0", "开启大小枪", _, true, 0.0, true, 1.0);
	cv_stripper = CreateConVar("maps_stripper", "-1", "地图版本", _, true, -1.0, true, 3.0);

	Weapon = GetConVarInt(cv_Weapon);
	WReplace = GetConVarInt(cv_WeaponReplace);
	MapStripper = GetConVarInt(cv_stripper);

	HookConVarChange(cv_Weapon, CvarWeapon);
	HookConVarChange(cv_WeaponReplace, CvarWeaponReplace);
	HookConVarChange(cv_stripper, CvarMapStripper);
}

public void OnAllPluginsLoaded()
{
	cv_Rhp = FindConVar("ss_health");
	cv_Siammoregain = FindConVar("ss_siammoregain");
	cv_Restore = FindConVar("l4d2_restore_health_flag");
	cv_SiNum = FindConVar("l4d2_si_spawn_control_max_specials");
	cv_SiTime = FindConVar("l4d2_si_spawn_control_spawn_time");
	cv_SiMode = FindConVar("l4d2_si_spawn_control_together_spawn");
	ServerCommand("exec vt_cfg/bantank.cfg");
}

public void OnConfigsExecuted()
{
	if(cv_Rhp != null){
		cv_Rhp.AddChangeHook(CvarRhp);
	}
	else if(FindConVar("ss_health")){
		cv_Rhp = FindConVar("ss_health");
		cv_Rhp.AddChangeHook(CvarRhp);
	}
	if(cv_Siammoregain != null){
		cv_Siammoregain.AddChangeHook(CvarAmmo);
	}
	else if(FindConVar("ss_siammoregain")){
		cv_Siammoregain = FindConVar("ss_siammoregain");
		cv_Siammoregain.AddChangeHook(CvarAmmo);
	}
	if(cv_Restore != null){
		cv_Restore.AddChangeHook(CvarRestore);
	}
	else if(FindConVar("l4d2_restore_health_flag")){
		cv_Restore = FindConVar("l4d2_restore_health_flag");
		cv_Restore.AddChangeHook(CvarRestore);
	}
	if(FindConVar("l4d2_si_spawn_control_max_specials") && FindConVar("l4d2_si_spawn_control_spawn_time") && FindConVar("l4d2_si_spawn_control_together_spawn")){
		cv_SiNum = FindConVar("l4d2_si_spawn_control_max_specials");
		cv_SiTime = FindConVar("l4d2_si_spawn_control_spawn_time");
		cv_SiMode = FindConVar("l4d2_si_spawn_control_together_spawn");
	}
}

public void CvarWeapon(ConVar convar, const char[] oldValue, const char[] newValue)
{
	Weapon = GetConVarInt(cv_Weapon);
	if (Weapon == 0)
		ServerCommand("exec vt_cfg/weapon/zonemod.cfg");
	else if (Weapon == 1)
		ServerCommand("exec vt_cfg/weapon/AnneHappy.cfg");
	else if (Weapon == 2)
		ServerCommand("exec vt_cfg/weapon/AnneHappyPlus.cfg");
	else if (Weapon == -1)
		ServerCommand("sm_weapon_attributes_reset");
}
public void CvarWeaponReplace(ConVar convar, const char[] oldValue, const char[] newValue)
{
	WReplace = GetConVarInt(cv_WeaponReplace);
	if (WReplace == 1)
		ServerCommand("exec vt_cfg/weaponreplace.cfg");
	else if (WReplace == 0)
		ServerCommand("l4d2_resetweaponrules");
}
public void CvarMapStripper(ConVar convar, const char[] oldValue, const char[] newValue)
{
	MapStripper = GetConVarInt(cv_stripper);
	if (MapStripper == 1)
		ServerCommand("sm_cvar stripper_cfg_path cfg/stripper/zonemod");
	else if (MapStripper == 2)
		ServerCommand("sm_cvar stripper_cfg_path cfg/stripper/neomod");
	else if (MapStripper == 3)
		ServerCommand("sm_cvar stripper_cfg_path cfg/stripper/deadman");
	else if (MapStripper == 0){
		ServerCommand("sm_cvar stripper_cfg_path addons/stripper");
		cv_stripper.IntValue = -1;
	}
}
public void CvarRestore( ConVar convar, const char[] oldValue, const char[] newValue ) 
{
	Restore = GetConVarInt(cv_Restore);
}
public void CvarRhp( ConVar convar, const char[] oldValue, const char[] newValue ) 
{
	Rhp = GetConVarInt(cv_Rhp);
}
public void CvarAmmo( ConVar convar, const char[] oldValue, const char[] newValue) 
{
	Siammoregain = GetConVarInt(cv_Siammoregain);
}

void printinfo(int client = 0, bool All = true){
	char buffer[256];
	char buffer2[256];
	
	Format(buffer, sizeof(buffer), "\x03特感\x05[\x04%s%d特%d秒\x05]", (cv_SiMode !=null && cv_SiMode.BoolValue)?"固定":"自动", cv_SiNum.IntValue, cv_SiTime.IntValue);
	Format(buffer, sizeof(buffer), "%s \x03武器\x05[\x04%s\x05]", buffer, Weapon == 0?"Zone":(Weapon == 1?"Anne":(Weapon == 2?"Anne+":"默认")));
	Format(buffer, sizeof(buffer), "%s \x03地图\x05[\x04%s\x05]", buffer, MapStripper == 1?"ZoneMod":(MapStripper == 2?"NeoMod":(MapStripper == 3?"DeadMan":"默认")));

	Format(buffer2, sizeof(buffer2), "\x03回血\x05[\x04%s\x05]", Rhp > 0?"开启":"关闭");
	Format(buffer2, sizeof(buffer2), "%s \x03回弹\x05[\x04%s\x05]", buffer2, Siammoregain == 0?"关闭":"开启");
	Format(buffer2, sizeof(buffer2), "%s \x03过关满血\x05[\x04%s\x05]", buffer2, Restore == 0?"关闭":"开启");
	if(All){
		PrintToChatAll(buffer);
		PrintToChatAll(buffer2);
	}else
	{
		PrintToChat(client, buffer);
		PrintToChat(client, buffer2);
	}
}

public Action Status(int client, int args)
{ 
	printinfo(client,false);
	return Plugin_Handled;
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	printinfo();
	return Plugin_Stop;
}
