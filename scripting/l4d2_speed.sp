#pragma semicolon 1
//強制1.7以後的新語法
#pragma newdecls required
#include <sourcemod>
#include <adminmenu>
#include <sdkhooks>
#include <colors>

#define PLUGIN_VERSION	"1.0"
#define MAX_LENGTH		32		//字符串最大值.

int g_iSelection[MAXPLAYERS + 1];

float g_fSpeedUp[MAXPLAYERS + 1] = {1.0, ...};

bool g_bWeaponHandling;

enum L4D2WeaponType {
	L4D2WeaponType_Unknown = 0,
	L4D2WeaponType_Pistol,
	L4D2WeaponType_Magnum,
	L4D2WeaponType_Rifle,
	L4D2WeaponType_RifleAk47,
	L4D2WeaponType_RifleDesert,
	L4D2WeaponType_RifleM60,
	L4D2WeaponType_RifleSg552,
	L4D2WeaponType_HuntingRifle,
	L4D2WeaponType_SniperAwp,
	L4D2WeaponType_SniperMilitary,
	L4D2WeaponType_SniperScout,
	L4D2WeaponType_SMG,
	L4D2WeaponType_SMGSilenced,
	L4D2WeaponType_SMGMp5,
	L4D2WeaponType_Autoshotgun,
	L4D2WeaponType_AutoshotgunSpas,
	L4D2WeaponType_Pumpshotgun,
	L4D2WeaponType_PumpshotgunChrome,
	L4D2WeaponType_Molotov,
	L4D2WeaponType_Pipebomb,
	L4D2WeaponType_FirstAid,
	L4D2WeaponType_Pills,
	L4D2WeaponType_Gascan,
	L4D2WeaponType_Oxygentank,
	L4D2WeaponType_Propanetank,
	L4D2WeaponType_Vomitjar,
	L4D2WeaponType_Adrenaline,
	L4D2WeaponType_Chainsaw,
	L4D2WeaponType_Defibrilator,
	L4D2WeaponType_GrenadeLauncher,
	L4D2WeaponType_Melee,
	L4D2WeaponType_UpgradeFire,
	L4D2WeaponType_UpgradeExplosive,
	L4D2WeaponType_BoomerClaw,
	L4D2WeaponType_ChargerClaw,
	L4D2WeaponType_HunterClaw,
	L4D2WeaponType_JockeyClaw,
	L4D2WeaponType_SmokerClaw,
	L4D2WeaponType_SpitterClaw,
	L4D2WeaponType_TankClaw,
	L4D2WeaponType_Gnome
}

TopMenu hTopMenu;
TopMenuObject hSpeed = INVALID_TOPMENUOBJECT;

public void OnLibraryAdded(const char[] name) {
	if (strcmp(name, "WeaponHandling") == 0)
		g_bWeaponHandling = true;
}

public void OnLibraryRemoved(const char[] name) {
	if (strcmp(name, "WeaponHandling") == 0)
		g_bWeaponHandling = false;
	
	if (StrEqual(name, "adminmenu"))
		hTopMenu = null;
}

public Plugin myinfo = 
{
	name 			= "[L4D2]武器操纵性修改",
	author 			= "sorallll",
	description 	= "生还者武器操纵性修改",
	version 		= PLUGIN_VERSION,
	url 			= "N/A"
}
//插件开始时.
public void OnPluginStart()
{
	TopMenu topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != null))
		OnAdminMenuReady(topmenu);
	RegConsoleCmd("sm_speed", MenuSpeedControl, "管理员打开武器操纵性修改菜单.");
}

public Action MenuSpeedControl(int client, int args)
{
	if(bCheckClientAccess(client) && g_bWeaponHandling)
		SpeedUp(client, 0);
	else
		CPrintToChat(client, "{default}[{green}!{default}] 你无权使用此指令.");
	return Plugin_Handled;
}

bool bCheckClientAccess(int client)
{
	if(GetUserFlagBits(client) & ADMFLAG_ROOT)
		return true;
	return false;
}

public void OnClientDisconnect(int client) {
	g_fSpeedUp[client] = 1.0;
}
 
public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu topmenu = TopMenu.FromHandle(aTopMenu);

	if (topmenu == hTopMenu)
		return;
	
	hTopMenu = topmenu;
	
	TopMenuObject objSpeedMenu = FindTopMenuCategory(hTopMenu, "OtherFeatures");
	if (objSpeedMenu == INVALID_TOPMENUOBJECT)
		objSpeedMenu = AddToTopMenu(hTopMenu, "OtherFeatures", TopMenuObject_Category, AdminMenuHandler, INVALID_TOPMENUOBJECT);
	
	hSpeed = AddToTopMenu(hTopMenu,"sm_speed",TopMenuObject_Item,InfectedMenuHandler,objSpeedMenu,"sm_speed",ADMFLAG_ROOT);
}

public void AdminMenuHandler(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayTitle)
	{
		Format(buffer, maxlength, "选择功能:", param);
	}
	else if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "其它功能", param);
	}
}

public void InfectedMenuHandler(Handle topmenu, TopMenuAction action, TopMenuObject object_id, int param, char[] buffer, int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		if (object_id == hSpeed)
			Format(buffer, maxlength, "武器操纵性", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if (object_id == hSpeed)
			SpeedUp(param, 0);
	}
}

void SpeedUp(int client, int item) {
	if(!g_bWeaponHandling)
		return;
	Menu menu = new Menu(SpeedUp_MenuHandler);
	menu.SetTitle("倍率");
	menu.AddItem("1.0", "1.0(恢复默认)");
	menu.AddItem("1.1", "1.1x");
	menu.AddItem("1.2", "1.2x");
	menu.AddItem("1.3", "1.3x");
	menu.AddItem("1.4", "1.4x");
	menu.AddItem("1.5", "1.5x");
	menu.AddItem("1.6", "1.6x");
	menu.AddItem("1.7", "1.7x");
	menu.AddItem("1.8", "1.8x");
	menu.AddItem("1.9", "1.9x");
	menu.AddItem("2.0", "2.0x");
	menu.AddItem("2.1", "2.1x");
	menu.AddItem("2.2", "2.2x");
	menu.AddItem("2.3", "2.3x");
	menu.AddItem("2.4", "2.4x");
	menu.AddItem("2.5", "2.5x");
	menu.AddItem("2.6", "2.6x");
	menu.AddItem("2.7", "2.7x");
	menu.AddItem("2.8", "2.8x");
	menu.AddItem("2.9", "2.9x");
	menu.AddItem("3.0", "3.0x");
	menu.AddItem("3.1", "3.1x");
	menu.AddItem("3.2", "3.2x");
	menu.AddItem("3.3", "3.3x");
	menu.AddItem("3.4", "3.4x");
	menu.AddItem("3.5", "3.5x");
	menu.ExitBackButton = true;
	menu.DisplayAt(client, item, MENU_TIME_FOREVER);
}

int SpeedUp_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[12];
			menu.GetItem(param2, item, sizeof item);
			g_iSelection[client] = menu.Selection;
			WeaponSpeedUp(client, item);
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				SpeedUp(client, 0);
		}
	
		case MenuAction_End:
			delete menu;
	}

	return 0;
}

void WeaponSpeedUp(int client, const char[] speedUp) {
	char info[32];
	char str[2][16];
	char disp[MAX_NAME_LENGTH];
	Menu menu = new Menu(WeaponSpeedUp_MenuHandler);
	menu.SetTitle("目标玩家");
	strcopy(str[0], sizeof str[], speedUp);
	strcopy(str[1], sizeof str[], "a");
	ImplodeStrings(str, sizeof str, "|", info, sizeof info);
	menu.AddItem(info, "所有");
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			FormatEx(str[1], sizeof str[], "%d", GetClientUserId(i));
			FormatEx(disp, sizeof disp, "[%.1fx] - %N", g_fSpeedUp[i], i);
			ImplodeStrings(str, sizeof str, "|", info, sizeof info);
			menu.AddItem(info, disp);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

int WeaponSpeedUp_MenuHandler(Menu menu, MenuAction action, int client, int param2) {
	switch (action) {
		case MenuAction_Select: {
			char item[12];
			menu.GetItem(param2, item, sizeof item);
			char info[2][16];
			ExplodeString(item, "|", info, sizeof info, sizeof info[]);
			float fSpeedUp = StringToFloat(info[0]);
			if (info[1][0] == 'a') {
				for (int i = 1; i <= MaxClients; i++) {
					if (IsClientInGame(i))
						g_fSpeedUp[i] = fSpeedUp;
				}
				CPrintToChat(client, "{default}[{green}!{default}] {blue}所有玩家 {default}的武器操纵性已被设置为 {green}%.1fx", fSpeedUp);
				SpeedUp(client, 0);
			}
			else {
				int target = GetClientOfUserId(StringToInt(info[1]));
				if (target && IsClientInGame(target)) {
						g_fSpeedUp[target] = fSpeedUp;
						CPrintToChat(client, "{default}[{green}!{default}] {blue}%N {default}的武器操纵性已被设置为 {green}%.1fx", target, fSpeedUp);
				}
				else
					CPrintToChat(client, "{default}[{green}!{default}] 目标玩家已失效");
						
				SpeedUp(client, g_iSelection[client]);
			}
		}

		case MenuAction_Cancel: {
			if (param2 == MenuCancel_ExitBack)
				SpeedUp(client, g_iSelection[client]);
		}

		case MenuAction_End:
			delete menu;
	}

	return 0;
}

// ====================================================================================================
//					WEAPON HANDLING
// ====================================================================================================
public void WH_OnMeleeSwing(int client, int weapon, float &speedmodifier) {
	speedmodifier = SpeedModifier(client, speedmodifier); //send speedmodifier to be modified
}

public void WH_OnStartThrow(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier) {
	speedmodifier = SpeedModifier(client, speedmodifier);
}

public void WH_OnReadyingThrow(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier) {
	speedmodifier = SpeedModifier(client, speedmodifier);
}

public void WH_OnReloadModifier(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier) {
	speedmodifier = SpeedModifier(client, speedmodifier);
}

public void WH_OnGetRateOfFire(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier) {
	switch (weapontype) {
		case L4D2WeaponType_Rifle, L4D2WeaponType_RifleSg552, L4D2WeaponType_SMG, L4D2WeaponType_RifleAk47, L4D2WeaponType_SMGMp5, L4D2WeaponType_SMGSilenced, L4D2WeaponType_RifleM60:
			return;
	}

	speedmodifier = SpeedModifier(client, speedmodifier);
}

public void WH_OnDeployModifier(int client, int weapon, L4D2WeaponType weapontype, float &speedmodifier) {
	speedmodifier = SpeedModifier(client, speedmodifier);
}

float SpeedModifier(int client, float speedmodifier) {
	if (g_fSpeedUp[client] > 1.0)
		speedmodifier = speedmodifier * g_fSpeedUp[client];// multiply current modifier to not overwrite any existing modifiers already

	return speedmodifier;
}