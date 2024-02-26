/*
*	Health Cabinet
*	Copyright (C) 2021 Silvers
*
*	This program is free software: you can redistribute it and/or modify
*	it under the terms of the GNU General Public License as published by
*	the Free Software Foundation, either version 3 of the License, or
*	(at your option) any later version.
*
*	This program is distributed in the hope that it will be useful,
*	but WITHOUT ANY WARRANTY; without even the implied warranty of
*	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*	GNU General Public License for more details.
*
*	You should have received a copy of the GNU General Public License
*	along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/



#define PLUGIN_VERSION		"1.11"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Health Cabinet
*	Author	:	SilverShot
*	Descrp	:	Auto-Spawns Health Cabinets.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=175154
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.11 (01-Jul-2021)
	- Now precaches the door opening sound to stop server console saying it's not cached.

1.10 (10-May-2020)
	- Various changes to tidy up code.

1.9 (29-Apr-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Fixed rare invalid handle errors.

1.8 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.7.1 (03-Jul-2019)
	- Fixed minor memory leak when saving or creating a temporary cabinet.

1.7 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.
	- Changed cvar "l4d_cabinet_modes_tog" now supports L4D1.

1.6 (18-Jul-2013)
	- Fixed spawning issues.

1.5.1 (05-Jun-2012)
	- Fixed print to chat error from the command "sm_cabinetglow".

1.5.0 (01-Jun-2012)
	- Added cvar "l4d_cabinet_glow_color" to set the glow color, L4D2 only.
	- Fixed bugs with deleting Cabinets.
	- Prevention for empty Cabinets, now spawns 1 second after opening when bugged.
	- Versus games now spawn the same cabinets and items for both teams - Requested by "Dont Fear The Reaper".

1.4 (10-May-2012)
	- Added command "sm_cabinetglow" to see where cabinets are placed.
	- Added command "sm_cabinettele" to teleport to a cabinet.
	- Added command "sm_cabinetang" to change the cabinet angle.
	- Added command "sm_cabinetpos" to change the cabinet origin.
	- Fixed a bug causing errors when deleting cabinets.

1.3 (03-Mar-2012)
	- Added cvar "l4d_cabinet_modes_off" to control which game modes the plugin works in.
	- Added cvar "l4d_cabinet_modes_tog" same as above, but only works for L4D2.
	- Added cvar "l4d_cabinet_spawn_adren" to set the chance of spawning adrenaline.
	- Added cvar "l4d_cabinet_spawn_defib" to set the chance of spawning defibrillators.
	- Added cvar "l4d_cabinet_spawn_first" to set the chance of spawning first aid kits.
	- Added cvar "l4d_cabinet_spawn_pills" to set the chance of spawning pain pills.
	- Changed command "sm_cabinet" and "sm_cabinetsave" usage: sm_cabinetsave <first> <pills> <adren> <defib>.
	- Changed default values of some cvars.
	- Changed the data config format. Please use the "sm_silvercfg" plugin to convert reformat the config.
	- Removed cvar "l4d_cabinet_type".
	- Removed cvar "l4d_cabinet_type1".
	- Removed cvar "l4d_cabinet_type2".

1.2 (02-Jan-2012)
	- Temporary update:
	- Fixed bots auto-grabbing items from closed cabinets.
	- Added cvar "l4d_cabinet_type1".
	- Added cvar "l4d_cabinet_type2".
	- Changed command "sm_cabinet" and "sm_cabinetsave" usage.

1.1 (31-Dec-2011)
	- Removed useless code.

1.0 (31-Dec-2011)
	- Initial release.

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define CHAT_TAG			"\x05[Health Cabinet] \x01"
#define CONFIG_SPAWNS		"data/l4d_cabinet.cfg"
#define MAX_ALLOWED			16

#define MODEL_CABINET		"models/props_interiors/medicalcabinet02.mdl"
#define SOUND_CABINET		"doors/MedKit_Doors_Open.wav"


ConVar g_hCvarAllow, g_hCvarGlow, g_hCvarGlowCol, g_hCvarMPGameMode, g_hCvarMax, g_hCvarMin, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarRandom, g_hCvarSpawn1, g_hCvarSpawn2, g_hCvarSpawn3, g_hCvarSpawn4;
Handle g_hTimerStart;
Menu g_hMenuAng, g_hMenuPos;
int g_iCabinetItems[MAX_ALLOWED][4], g_iCabinetRandom[MAX_ALLOWED], g_iCabinetType[MAX_ALLOWED][4], g_iCfgIndex[MAX_ALLOWED], g_iCount, g_iCvarGlow, g_iCvarGlowCol, g_iCvarMax, g_iCvarMin, g_iCvarRandom, g_iCvarSpawn1, g_iCvarSpawn2, g_iCvarSpawn3, g_iCvarSpawn4, g_iEntities[MAX_ALLOWED], g_iOrder, g_iPlayerSpawn, g_iRoundStart, g_iSpawned[MAX_ALLOWED];
bool g_bCvarAllow, g_bMapStarted, g_bLeft4Dead2, g_bLoaded, g_bGlow;
float g_vCabinetAng[MAX_ALLOWED][3], g_vCabinetPos[MAX_ALLOWED][3];



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Health Cabinet",
	author = "SilverShot",
	description = "Auto-Spawns Health Cabinets.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=175154"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();

	if( test == Engine_Left4Dead ) g_bLeft4Dead2 = false;
	else if( test == Engine_Left4Dead2 ) g_bLeft4Dead2 = true;
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarAllow = CreateConVar("l4d_cabinet_allow", "1", "0=禁用插件, 1=启用插件.", CVAR_FLAGS);
	g_hCvarModes =	CreateConVar("l4d_cabinet_modes", "", "在这些模式中启用插件, 逗号分隔 (没有空格). (空白 = 全部).", CVAR_FLAGS);
	g_hCvarModesOff =	CreateConVar("l4d_cabinet_modes_off", "", "在这些模式中禁用插件, 逗号分隔 (没有空格). (空白 = 没有).", CVAR_FLAGS );
	g_hCvarModesTog = CreateConVar("l4d_cabinet_modes_tog", "0", "在这些游戏模式开启插件. 0=全部, 1=战役, 2=生存, 4=对抗, 8=清道夫. 数字可加起来.", CVAR_FLAGS );
	if( g_bLeft4Dead2 == true )
	{
		g_hCvarGlow = CreateConVar("l4d_cabinet_glow", "150", "0=关闭. 医疗柜发光范围.", CVAR_FLAGS);
		g_hCvarGlowCol = CreateConVar("l4d_cabinet_glow_color", "255 0 0", "0=默认发光颜色. 医疗柜发光颜色(可参考RGB颜色设置).", CVAR_FLAGS );
	}
	g_hCvarMax = CreateConVar("l4d_cabinet_max", "4", "医疗柜最大物品数量.", CVAR_FLAGS, true, 0.0, true, 4.0);
	g_hCvarMin = CreateConVar("l4d_cabinet_min", "1", "医疗柜最小物品数量.", CVAR_FLAGS, true, 0.0, true, 4.0);
	g_hCvarRandom =	CreateConVar("l4d_cabinet_random", "2", "-1=全部, 0=禁用, 随机生成医疗柜配置.", CVAR_FLAGS);
	g_hCvarSpawn3 =	CreateConVar("l4d_cabinet_spawn_adren", "0", "医疗柜出现针管几率.", CVAR_FLAGS, true, 0.0, true, 100.0);
	g_hCvarSpawn4 =	CreateConVar("l4d_cabinet_spawn_defib", "0", "医疗柜出现电击器几率.", CVAR_FLAGS, true, 0.0, true, 100.0);
	g_hCvarSpawn1 =	CreateConVar("l4d_cabinet_spawn_first", "100", "医疗柜出现医疗包几率.", CVAR_FLAGS, true, 0.0, true, 100.0);
	g_hCvarSpawn2 =	CreateConVar("l4d_cabinet_spawn_pills", "50", "医疗柜出现止痛药几率.", CVAR_FLAGS, true, 0.0, true, 100.0);
	CreateConVar("l4d_cabinet_version", PLUGIN_VERSION, "医疗柜插件版本.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true, "l4d_cabinet");


	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	if( g_bLeft4Dead2 )
	{
		g_hCvarGlow.AddChangeHook(ConVarChanged_Glow);
		g_hCvarGlowCol.AddChangeHook(ConVarChanged_Glow);
	}
	g_hCvarMax.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMin.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRandom.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpawn1.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpawn2.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpawn3.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarSpawn4.AddChangeHook(ConVarChanged_Cvars);


	RegAdminCmd("sm_cabinet", CmdCabinet, ADMFLAG_ROOT, "Spawns a temporary Health Cabinet at your crosshair.  Usage: sm_cabinetsave <first> <pills> <adren> <defib>.");
	RegAdminCmd("sm_cabinetsave", CmdCabinetSave, ADMFLAG_ROOT, "Spawns a Health Cabinet at your crosshair and saves to config. Usage: sm_cabinetsave <first> <pills> <adren> <defib>.");
	RegAdminCmd("sm_cabinetlist", CmdCabinetList, ADMFLAG_ROOT, "Displays a list of Health Cabinets spawned by the plugin and their locations.");
	if( g_bLeft4Dead2 )
		RegAdminCmd("sm_cabinetglow", CmdCabinetGlow, ADMFLAG_ROOT, "Toggle to enable glow on all cabinets to see where they are placed.");
	RegAdminCmd("sm_cabinettele", CmdCabinetTele, ADMFLAG_ROOT, "Teleport to a cabinet (Usage: sm_cabinettele <index: 1 to MAX_CABINETS>).");
	RegAdminCmd("sm_cabinetdel", CmdCabinetDelete, ADMFLAG_ROOT, "Removes the Health Cabinet you are aiming at and deletes from the config if saved.");
	RegAdminCmd("sm_cabinetclear", CmdCabinetClear, ADMFLAG_ROOT, "Removes all Health Cabinets from the current map.");
	RegAdminCmd("sm_cabinetwipe", CmdCabinetWipe, ADMFLAG_ROOT, "Removes all Health Cabinets from the current map and deletes them from the config.");
	RegAdminCmd("sm_cabinetang", CmdCabinetAng, ADMFLAG_ROOT, "Displays a menu to adjust the cabinet angles your crosshair is over.");
	RegAdminCmd("sm_cabinetpos", CmdCabinetPos, ADMFLAG_ROOT, "Displays a menu to adjust the cabinet origin your crosshair is over.");
}

public void OnPluginEnd()
{
	ResetPlugin();
}

public void OnMapStart()
{
	g_bMapStarted = true;
	g_iOrder = 0;
	g_iCount = 0;
	PrecacheModel(MODEL_CABINET, true);
	PrecacheSound(SOUND_CABINET, true);
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	g_iOrder = 0;
	g_iCount = 0;
	ResetPlugin();
}

void ResetPlugin()
{
	g_bLoaded = false;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;

	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		DeleteEntity(i);
	}

	delete g_hTimerStart;
}

void DeleteEntity(int index)
{
	g_iCfgIndex[index] = 0;

	int entity = g_iEntities[index];
	g_iEntities[index] = 0;

	if( IsValidEntRef(entity) )
		AcceptEntityInput(entity, "Kill");

	for( int i = 0; i < sizeof(g_iCabinetItems[]); i++ )
	{
		entity = g_iCabinetItems[index][i];
		g_iCabinetItems[index][i] = 0;

		if( IsValidEntRef(entity) )
		{
			if( GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == -1 )
				AcceptEntityInput(entity, "Kill");
		}
	}
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

public void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

public void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

public void ConVarChanged_Glow(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_iCvarGlow = g_hCvarGlow.IntValue;
	g_iCvarGlowCol = GetColor(g_hCvarGlowCol);
	ToggleGlow(g_bGlow);
}

int GetColor(ConVar hCvar)
{
	char sTemp[12];
	hCvar.GetString(sTemp, sizeof(sTemp));

	if( sTemp[0] == 0 )
		return 0;

	char sColors[3][4];
	int color = ExplodeString(sTemp, " ", sColors, sizeof(sColors), sizeof(sColors[]));

	if( color != 3 )
		return 0;

	color = StringToInt(sColors[0]);
	color += 256 * StringToInt(sColors[1]);
	color += 65536 * StringToInt(sColors[2]);

	return color;
}

void GetCvars()
{
	if( g_bLeft4Dead2 == true )
	{
		g_iCvarGlow =	g_hCvarGlow.IntValue;
		g_iCvarGlowCol = GetColor(g_hCvarGlowCol);
	}

	g_iCvarMax =	g_hCvarMax.IntValue;
	g_iCvarMin =	g_hCvarMin.IntValue;
	g_iCvarRandom =	g_hCvarRandom.IntValue;
	g_iCvarSpawn1 =	g_hCvarSpawn1.IntValue;
	g_iCvarSpawn2 =	g_hCvarSpawn2.IntValue;
	g_iCvarSpawn3 =	g_hCvarSpawn3.IntValue;
	g_iCvarSpawn4 =	g_hCvarSpawn4.IntValue;
}

void IsAllowed()
{
	bool bAllowCvar = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bAllowCvar == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		LoadCabinets();
		HookEvents();
	}

	else if( g_bCvarAllow == true && (bAllowCvar == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		ResetPlugin();
		UnhookEvents();

		delete g_hTimerStart;
	}
}

int g_iCurrentMode;
bool IsAllowedGameMode()
{
	if( g_hCvarMPGameMode == null )
		return false;

	int iCvarModesTog = g_hCvarModesTog.IntValue;
	if( iCvarModesTog != 0 )
	{
		if( g_bMapStarted == false )
			return false;

		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if( g_iCurrentMode == 0 )
			return false;

		if( !(iCvarModesTog & g_iCurrentMode) )
			return false;
	}

	char sGameModes[64], sGameMode[64];
	g_hCvarMPGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);

	g_hCvarModes.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) == -1 )
			return false;
	}

	g_hCvarModesOff.GetString(sGameModes, sizeof(sGameModes));
	if( sGameModes[0] )
	{
		Format(sGameModes, sizeof(sGameModes), ",%s,", sGameModes);
		if( StrContains(sGameModes, sGameMode, false) != -1 )
			return false;
	}

	return true;
}

public void OnGamemode(const char[] output, int caller, int activator, float delay)
{
	if( strcmp(output, "OnCoop") == 0 )
		g_iCurrentMode = 1;
	else if( strcmp(output, "OnSurvival") == 0 )
		g_iCurrentMode = 2;
	else if( strcmp(output, "OnVersus") == 0 )
		g_iCurrentMode = 4;
	else if( strcmp(output, "OnScavenge") == 0 )
		g_iCurrentMode = 8;
}



// ====================================================================================================
//					EVENTS
// ====================================================================================================
void HookEvents()
{
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_PostNoCopy);
	HookEvent("player_use", Event_PlayerUse);
}

void UnhookEvents()
{
	UnhookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	UnhookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	UnhookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_PostNoCopy);
	UnhookEvent("player_use", Event_PlayerUse);
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin();
	g_iOrder = 1;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		g_hTimerStart = CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		g_hTimerStart = CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

public Action TimerStart(Handle timer)
{
	g_hTimerStart = null;
	g_bGlow = false;

	if(	g_iOrder == 0 )
	{
		ResetPlugin();
		g_iCount = 0;
	}
	else
	{
		g_iCurrentMode = 0;

		int entity = CreateEntityByName("info_gamemode");
		if( IsValidEntity(entity) )
		{
			DispatchSpawn(entity);
			HookSingleEntityOutput(entity, "OnCoop", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnSurvival", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnVersus", OnGamemode, true);
			HookSingleEntityOutput(entity, "OnScavenge", OnGamemode, true);
			ActivateEntity(entity);
			AcceptEntityInput(entity, "PostSpawnActivate");
			if( IsValidEntity(entity) ) // Because sometimes "PostSpawnActivate" seems to kill the ent.
				RemoveEdict(entity); // Because multiple plugins creating at once, avoid too many duplicate ents in the same frame
		}

		if( g_iCurrentMode != 4 && g_iCurrentMode != 8 )
		{
			ResetPlugin();
			g_iOrder = 0;
			g_iCount = 0;
		}
	}

	LoadCabinets();
}

void LoadCabinets()
{
	if( g_bLoaded == true ) return;
	g_bLoaded = true;

	if( g_iCvarRandom == 0 )
		return;

	if( g_iOrder == 1 )
	{
		for( int i = 0; i < g_iCount; i++ )
		{
			SpawnCabinet(g_vCabinetAng[i], g_vCabinetPos[i], g_iCabinetType[i][0], g_iCabinetType[i][1], g_iCabinetType[i][2], g_iCabinetType[i][3], g_iCfgIndex[i]);
		}

		return;
	}

	g_iCount = 0;

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		return;

	// Load config
	KeyValues hFile = new KeyValues("cabinets");
	if( !hFile.ImportFromFile(sPath) )
	{
		delete hFile;
		return;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		delete hFile;
		return;
	}

	// Retrieve how many to display
	int iCount = hFile.GetNum("num", 0);
	if( iCount == 0 )
	{
		delete hFile;
		return;
	}

	// Spawn only a select few?
	int index, i;
	int iIndexes[MAX_ALLOWED+1];
	if( iCount > MAX_ALLOWED )
		iCount = MAX_ALLOWED;


	// Spawn saved cabinets or create random
	int iRandom = g_iCvarRandom;
	if( iRandom > iCount)
		iRandom = iCount;
	if( iRandom != -1 )
	{
		for( i = 0; i < iCount; i++ )
			iIndexes[i] = i + 1;

		SortIntegers(iIndexes, iCount, Sort_Random);
		iCount = iRandom;
	}

	// Get the cabinets origins and spawn
	char sTemp[4];
	float vPos[3], vAng[3];
	int type1, type2, type3, type4;

	for( i = 1; i <= iCount; i++ )
	{
		if( iRandom != -1 ) index = iIndexes[i-1];
		else index = i;

		IntToString(index, sTemp, sizeof(sTemp));

		if( hFile.JumpToKey(sTemp) )
		{
			hFile.GetVector("angle", vAng);
			hFile.GetVector("origin", vPos);
			type1 = hFile.GetNum("adren", -1);
			type2 = hFile.GetNum("defib", -1);
			type3 = hFile.GetNum("first", -1);
			type4 = hFile.GetNum("pills", -1);

			hFile.GoBack();

			if( vPos[0] == 0.0 && vPos[0] == 0.0 && vPos[0] == 0.0 ) // Should never happen.
			{
				LogError("Error: 0,0,0 origin. Iteration=%d. Index=%d. Count=%d.", i, index, iCount);
			}
			else
			{
				g_vCabinetAng[g_iCount] = vAng;
				g_vCabinetPos[g_iCount] = vPos;
				g_iCount++;
				SpawnCabinet(vAng, vPos, type1, type2, type3, type4, index);
			}
		}
	}

	delete hFile;
}

int SetupCabinet(int client, float vAng[3] = NULL_VECTOR, float vPos[3] = NULL_VECTOR, int type1, int type2, int type3, int type4)
{
	GetClientEyeAngles(client, vAng);
	GetClientEyePosition(client, vPos);

	Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, TraceFilter, client);

	if( TR_DidHit(trace) )
	{
		TR_GetEndPosition(vPos, trace);
		TR_GetPlaneNormal(trace, vAng);
		GetVectorAngles(vAng, vAng);
		delete trace;

		float vDir[3];
		GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
		vPos[0] += vDir[0];
		vPos[1] += vDir[1];
		vPos[2] -= 50.0;

		return SpawnCabinet(vAng, vPos, type1, type2, type3, type4);
	}

	delete trace;
	return -1;
}

public bool TraceFilter(int entity, int contentsMask, any client)
{
	if( entity == client )
		return false;
	return true;
}

int SpawnCabinet(float vAng[3], float vPos[3], int type1, int type2, int type3, int type4, int cfgindex = 0)
{
	int index = -1;

	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		if( !IsValidEntRef(g_iEntities[i]) )
		{
			index = i;
			break;
		}
	}

	if( index == -1 ) return -1;

	int entity = CreateEntityByName("prop_health_cabinet");
	g_iEntities[index] = EntIndexToEntRef(entity);
	g_iCfgIndex[index] = cfgindex;
	g_iSpawned[index] = 0;

	DispatchKeyValue(entity, "model", MODEL_CABINET);
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	DispatchSpawn(entity);
	SetEntityMoveType(entity, MOVETYPE_NONE);

	g_iCabinetType[index][0] = type1;
	g_iCabinetType[index][1] = type2;
	g_iCabinetType[index][2] = type3;
	g_iCabinetType[index][3] = type4;

	if( g_bLeft4Dead2 && g_iCvarGlow )
	{
		SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarGlowCol);
		SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iCvarGlow);
		SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", 1);
	}

	HookSingleEntityOutput(entity, "OnAnimationDone", OnAnimationDone, true);

	return index;
}

public void OnAnimationDone(const char[] output, int entity, int activator, float delay)
{
	SpawnItems(entity);
}

public void Event_PlayerUse(Event event, const char[] name, bool dontBroadcast)
{
	int entity = event.GetInt("targetid");

	if( entity > MaxClients && IsValidEntity(entity) == true )
	{
		SpawnItems(entity);
	}
}

void SpawnItems(int entity)
{
	entity = EntIndexToEntRef(entity);
	int index = -1;

	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		if( entity == g_iEntities[i] )
		{
			index = i;
			break;
		}
	}

	if( index == -1 ) return;

	UnhookSingleEntityOutput(entity, "OnAnimationDone", OnAnimationDone);

	if( g_iSpawned[index] == 1 ) return;
	g_iSpawned[index] = 1;

	int random;

	if( g_iOrder == 0 || g_iCabinetRandom[index] == 0 )
	{
		if( g_iCvarMin == 0 )
		{
			random = GetRandomInt(g_iCvarMin, g_iCvarMax * 2);
			if( random > 2 )
				random = (random + 1) / 2;
		}
		else
		{
			random = GetRandomInt(g_iCvarMin, g_iCvarMax);
		}

		if( random == 0 )
		{
			g_iCabinetRandom[index] = -1;
			return;
		}
		else
		{
			g_iCabinetRandom[index] = random;
		}
	}
	else
	{
		random = g_iCabinetRandom[index];
		if( random == -1 )
			random = 0;
	}


	if( random == 0 ) return;

	int type1 = g_iCabinetType[index][0];
	if( type1 == -1 ) type1 = g_iCvarSpawn1;
	int type2 = g_iCabinetType[index][1];
	if( type2 == -1 ) type2 = g_iCvarSpawn2;
	int type3 = g_iCabinetType[index][2];
	if( type3 == -1 ) type3 = g_iCvarSpawn3;
	int type4 = g_iCabinetType[index][3];
	if( type4 == -1 ) type4 = g_iCvarSpawn4;

	if( g_bLeft4Dead2 == false )
	{
		type3 = 0;
		type4 = 0;
	}

	float vTempPos[3], vTempAng[3], vAng[3], vPos[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vPos);
	GetEntPropVector(entity, Prop_Data, "m_angRotation", vAng);

	int place[5] = { 1, 2, 3, 4 }, placed;
	SortIntegers(place, 4, Sort_Random);

	int randomselect, selected;
	for( int i = 0; i < random; i++ )
	{
		if( g_iOrder == 0 || g_iCabinetType[index][i] >= 0 )
		{
			randomselect = type1 + type2 + type3 + type4;
			selected = GetRandomInt(1, randomselect);

			if( selected <= type1 )
				selected = 1;
			else if( selected <= type1 + type2 )
				selected = 2;
			else if( selected <= type1 + type2 + type3 )
				selected = 3;
			else if( selected <= randomselect )
				selected = 4;

			g_iCabinetType[index][i] = selected - 5;
		}
		else
		{
			selected = g_iCabinetType[index][i] + 5;
		}

		switch( selected )
		{
			case 1:		entity = CreateEntityByName("weapon_first_aid_kit");
			case 2:		entity = CreateEntityByName("weapon_pain_pills");
			case 3:		entity = CreateEntityByName("weapon_adrenaline");
			case 4:		entity = CreateEntityByName("weapon_defibrillator");
		}

		DispatchKeyValue(entity, "solid", "0");
		DispatchKeyValue(entity, "disableshadows", "1");

		g_iCabinetItems[index][i] = EntIndexToEntRef(entity);

		vTempPos = vPos;
		MoveForward(vTempPos, vAng, vTempPos, 3.0);

		placed = place[i];

		if( placed == 1 )
		{
			MoveSideway(vTempPos, vAng, vTempPos, -9.0);
			vTempPos[2] += 37.0;
		}
		else if( placed == 2 )
		{
			MoveSideway(vTempPos, vAng, vTempPos, 9.0);
			vTempPos[2] += 37.0;
		}
		else if( placed == 3 )
		{
			MoveSideway(vTempPos, vAng, vTempPos, 9.0);
			vTempPos[2] += 51.0;
		}
		else if( placed == 4 )
		{
			MoveSideway(vTempPos, vAng, vTempPos, -9.0);
			vTempPos[2] += 51.0;
		}
		vTempAng = vAng;
		vTempAng[1] += 180.0;

		DispatchSpawn(entity);
		TeleportEntity(entity, vTempPos, vTempAng, NULL_VECTOR);
		SetEntityMoveType(entity, MOVETYPE_PUSH);
	}
}

void MoveSideway(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance)
{
	fDistance *= -1.0;
	float vDir[3];
	GetAngleVectors(vAng, NULL_VECTOR, vDir, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
}

void MoveForward(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance)
{
	float vDir[3];
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
	vReturn[2] += vDir[2] * fDistance;
}



// ====================================================================================================
//					COMMANDS - TEMP, SAVE, LIST, DELETE, CLEAR, WIPE
// ====================================================================================================

// ====================================================================================================
//					sm_cabinet
// ====================================================================================================
public Action CmdCabinet(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Health Cabinet] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	int type1 = -1, type2 = -1, type3 = -1, type4 = -1;
	if( args == 1 )
	{
		char sTemp[4];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type1 = StringToInt(sTemp);
	}
	else if( args == 2 )
	{
		char sTemp[4];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type1 = StringToInt(sTemp);
		GetCmdArg(2, sTemp, sizeof(sTemp));
		type2 = StringToInt(sTemp);
	}
	else if( args == 3 )
	{
		char sTemp[4];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type1 = StringToInt(sTemp);
		GetCmdArg(2, sTemp, sizeof(sTemp));
		type2 = StringToInt(sTemp);
		GetCmdArg(3, sTemp, sizeof(sTemp));
		type3 = StringToInt(sTemp);
	}
	else if( args == 4 )
	{
		char sTemp[4];
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type1 = StringToInt(sTemp);
		GetCmdArg(2, sTemp, sizeof(sTemp));
		type2 = StringToInt(sTemp);
		GetCmdArg(3, sTemp, sizeof(sTemp));
		type3 = StringToInt(sTemp);
		GetCmdArg(4, sTemp, sizeof(sTemp));
		type4 = StringToInt(sTemp);
	}

	float vAng[3], vPos[3];
	SetupCabinet(client, vAng, vPos, type1, type2, type3, type4);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_cabinetsave
// ====================================================================================================
public Action CmdCabinetSave(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Health Cabinet] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		File hCfg = OpenFile(sPath, "w");
		hCfg.WriteLine("");
		delete hCfg;
	}

	// Load config
	KeyValues hFile = new KeyValues("cabinets");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot read the Health Cabinet config, assuming empty file. (\x05%s\x01).", CHAT_TAG, sPath);
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if( !hFile.JumpToKey(sMap, true) )
	{
		PrintToChat(client, "%sError: Failed to add map to Health Cabinet spawn config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many are saved
	int iCount = hFile.GetNum("num", 0);
	if( iCount >= MAX_ALLOWED )
	{
		PrintToChat(client, "%sError: Cannot add anymore Health Cabinets. Used: (\x05%d/%d\x01).", CHAT_TAG, iCount, MAX_ALLOWED);
		delete hFile;
		return Plugin_Handled;
	}

	char sTemp[4];
	int type1 = -1, type2 = -1, type3 = -1, type4 = -1;
	if( args == 1 )
	{
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type1 = StringToInt(sTemp);
	}
	else if( args == 2 )
	{
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type1 = StringToInt(sTemp);
		GetCmdArg(2, sTemp, sizeof(sTemp));
		type2 = StringToInt(sTemp);
	}
	else if( args == 3 )
	{
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type1 = StringToInt(sTemp);
		GetCmdArg(2, sTemp, sizeof(sTemp));
		type2 = StringToInt(sTemp);
		GetCmdArg(3, sTemp, sizeof(sTemp));
		type3 = StringToInt(sTemp);
	}
	else if( args == 4 )
	{
		GetCmdArg(1, sTemp, sizeof(sTemp));
		type1 = StringToInt(sTemp);
		GetCmdArg(2, sTemp, sizeof(sTemp));
		type2 = StringToInt(sTemp);
		GetCmdArg(3, sTemp, sizeof(sTemp));
		type3 = StringToInt(sTemp);
		GetCmdArg(4, sTemp, sizeof(sTemp));
		type4 = StringToInt(sTemp);
	}

	float vAng[3], vPos[3];
	int index = SetupCabinet(client, vAng, vPos, type1, type2, type3, type4);

	if( index != -1 )
	{
		g_iCfgIndex[index] = iCount + 1;
	}

	// Save count
	iCount++;
	hFile.SetNum("num", iCount);

	IntToString(iCount, sTemp, sizeof(sTemp));
	if( hFile.JumpToKey(sTemp, true) )
	{
		hFile.SetVector("angle", vAng);
		hFile.SetVector("origin", vPos);

		if( type1 != -1 )		hFile.SetNum("adren", type1);
		if( type2 != -1 )		hFile.SetNum("defib", type2);
		if( type3 != -1 )		hFile.SetNum("first", type3);
		if( type4 != -1 )		hFile.SetNum("pills", type4);

		// Save cfg
		hFile.Rewind();
		hFile.ExportToFile(sPath);

		PrintToChat(client, "%s(\x05%d/%d\x01) - Saved at pos:[\x05%f %f %f\x01] ang:[\x05%f %f %f\x01]", CHAT_TAG, iCount, MAX_ALLOWED, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to save Cabinet", CHAT_TAG, iCount, MAX_ALLOWED);

	delete hFile;

	return Plugin_Handled;
}

// ====================================================================================================
//					sm_cabinetlist
// ====================================================================================================
public Action CmdCabinetList(int client, int args)
{
	float vPos[3];
	int i, ent, count;

	for( i = 0; i < MAX_ALLOWED; i++ )
	{
		ent = g_iEntities[i];

		if( IsValidEntRef(ent) )
		{
			count++;
			GetEntPropVector(ent, Prop_Data, "m_vecOrigin", vPos);
			if( client == 0 )
				ReplyToCommand(client, "[Health Cabinet] %d) %f %f %f", i+1, vPos[0], vPos[1], vPos[2]);
			else
				PrintToChat(client, "%s%d) %f %f %f", CHAT_TAG, i+1, vPos[0], vPos[1], vPos[2]);
		}
	}

	if( client == 0 )
		PrintToChat(client, "[Health Cabinet] Total: %d.", count);
	else
		ReplyToCommand(client, "%sTotal: %d.", CHAT_TAG, count);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_cabinetglow
// ====================================================================================================
public Action CmdCabinetGlow(int client, int args)
{
	g_bGlow = !g_bGlow;
	ToggleGlow(g_bGlow);

	if( client )
		PrintToChat(client, "%sGlow has been turned %s", CHAT_TAG, g_bGlow ? "on" : "off");
	else
		ReplyToCommand(client, "[Cabinet] Glow has been turned %s", g_bGlow ? "on" : "off");
	return Plugin_Handled;
}

void ToggleGlow(int glow)
{
	int entity;

	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		entity = g_iEntities[i];
		if( IsValidEntRef(entity) )
		{
			SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
			SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarGlowCol);
			SetEntProp(entity, Prop_Send, "m_nGlowRange", glow ? 0 : g_iCvarGlow);
			SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", 20);
			if( glow )
				AcceptEntityInput(entity, "StartGlowing");
			else if( !glow && !g_iCvarGlow )
				AcceptEntityInput(entity, "StopGlowing");
		}
	}
}

// ====================================================================================================
//					sm_cabinettele
// ====================================================================================================
public Action CmdCabinetTele(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Health Cabinet] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	if( args == 1 )
	{
		char arg[16];
		GetCmdArg(1, arg, sizeof(arg));
		int index = StringToInt(arg) - 1;
		if( index > -1 && index < MAX_ALLOWED && IsValidEntRef(g_iEntities[index]) )
		{
			float vPos[3], vAng[3];
			GetEntPropVector(g_iEntities[index], Prop_Data, "m_vecOrigin", vPos);
			GetEntPropVector(g_iEntities[index], Prop_Data, "m_angRotation", vAng);
			MoveForward(vPos, vAng, vPos, 35.0);

			TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
			PrintToChat(client, "%sTeleported to %d.", CHAT_TAG, index + 1);
			return Plugin_Handled;
		}

		PrintToChat(client, "%sCould not find index for teleportation.", CHAT_TAG);
	}
	else
		PrintToChat(client, "%sUsage: sm_cabinettele <index 1-%d>.", CHAT_TAG, MAX_ALLOWED);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_cabinetdel
// ====================================================================================================
public Action CmdCabinetDelete(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Health Cabinet] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	int entity = GetClientAimTarget(client, false);
	if( entity == -1 ) return Plugin_Handled;
	entity = EntIndexToEntRef(entity);

	int index = -1;
	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		if( g_iEntities[i] == entity )
		{
			index = i;
			break;
		}
	}

	if( index == -1 )
		return Plugin_Handled;

	int cfgindex = g_iCfgIndex[index];
	if( cfgindex == 0 )
	{
		DeleteEntity(index);
		return Plugin_Handled;
	}

	// Load config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sWarning: Cannot find the Health Cabinet config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	KeyValues hFile = new KeyValues("cabinets");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sWarning: Cannot load the Health Cabinet config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		PrintToChat(client, "%sWarning: Current map not in the Health Cabinet config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many
	int iCount = hFile.GetNum("num", 0);
	if( iCount == 0 )
	{
		delete hFile;
		return Plugin_Handled;
	}

	bool bMove;
	char sTemp[4];

	// Move the other entries down
	for( int i = cfgindex; i <= iCount; i++ )
	{
		IntToString(i, sTemp, sizeof(sTemp));
		if( hFile.JumpToKey(sTemp) )
		{
			if( !bMove )
			{
				for( int u = 0; u < MAX_ALLOWED; u++ )
				{
					if( g_iCfgIndex[u] >= cfgindex )
					{
						g_iCfgIndex[u]--;
					}
				}
				DeleteEntity(index);

				bMove = true;
				hFile.DeleteThis();
			}
			else
			{
				IntToString(i-1, sTemp, sizeof(sTemp));
				hFile.SetSectionName(sTemp);
			}
		}

		hFile.Rewind();
		hFile.JumpToKey(sMap);
	}

	if( bMove )
	{
		iCount--;
		hFile.SetNum("num", iCount);

		// Save to file
		hFile.Rewind();
		hFile.ExportToFile(sPath);

		PrintToChat(client, "%s(\x05%d/%d\x01) - Health Cabinet removed from config.", CHAT_TAG, iCount, MAX_ALLOWED);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to remove Cabinet from config.", CHAT_TAG, iCount, MAX_ALLOWED);

	delete hFile;
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_cabinetclear
// ====================================================================================================
public Action CmdCabinetClear(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	ResetPlugin();
	if( client )
		PrintToChat(client, "%sAll Health Cabinets removed from the map.", CHAT_TAG);
	else
		ReplyToCommand(client, "[Helth Cabinet] All Health Cabinets removed from the map.");
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_cabinetwipe
// ====================================================================================================
public Action CmdCabinetWipe(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Health Cabinet] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Health Cabinet config (\x05%s\x01).", CHAT_TAG, sPath);
		return Plugin_Handled;
	}

	// Load config
	KeyValues hFile = new KeyValues("cabinets");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Health Cabinet config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap, false) )
	{
		PrintToChat(client, "%sError: Current map not in the Health Cabinet config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	hFile.DeleteThis();

	// Save to file
	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	ResetPlugin();
	PrintToChat(client, "%s(0/%d) - All Health Cabinets removed from config, add new with \x05sm_cabinetsave\x01.", CHAT_TAG, MAX_ALLOWED);
	return Plugin_Handled;
}



// ====================================================================================================
//					MENU ANGLE
// ====================================================================================================
public Action CmdCabinetAng(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Health Cabinet] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	ShowMenuAng(client);
	return Plugin_Handled;
}

void ShowMenuAng(int client)
{
	CreateMenus();
	g_hMenuAng.Display(client, MENU_TIME_FOREVER);
}

public int AngMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Select )
	{
		if( index == 6 )
			SaveData(client);
		else
			SetAngle(client, index);
		ShowMenuAng(client);
	}
}

void SetAngle(int client, int index)
{
	int aim = GetClientAimTarget(client, false);
	if( aim != -1 )
	{
		float vAng[3];
		int entity;
		aim = EntIndexToEntRef(aim);

		for( int i = 0; i < MAX_ALLOWED; i++ )
		{
			entity = g_iEntities[i];

			if( entity == aim  )
			{
				GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

				switch( index )
				{
					case 0: vAng[0] += 5.0;
					case 1: vAng[1] += 5.0;
					case 2: vAng[2] += 5.0;
					case 3: vAng[0] -= 5.0;
					case 4: vAng[1] -= 5.0;
					case 5: vAng[2] -= 5.0;
				}

				TeleportEntity(entity, NULL_VECTOR, vAng, NULL_VECTOR);

				PrintToChat(client, "%sNew angles: %f %f %f", CHAT_TAG, vAng[0], vAng[1], vAng[2]);
				break;
			}
		}
	}
}

// ====================================================================================================
//					MENU ORIGIN
// ====================================================================================================
public Action CmdCabinetPos(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Health Cabinet] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	ShowMenuPos(client);
	return Plugin_Handled;
}

void ShowMenuPos(int client)
{
	CreateMenus();
	g_hMenuPos.Display(client, MENU_TIME_FOREVER);
}

public int PosMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Select )
	{
		if( index == 6 )
			SaveData(client);
		else
			SetOrigin(client, index);
		ShowMenuPos(client);
	}
}

void SetOrigin(int client, int index)
{
	int aim = GetClientAimTarget(client, false);
	if( aim != -1 )
	{
		float vPos[3];
		int entity;
		aim = EntIndexToEntRef(aim);

		for( int i = 0; i < MAX_ALLOWED; i++ )
		{
			entity = g_iEntities[i];

			if( entity == aim  )
			{
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);

				switch( index )
				{
					case 0: vPos[0] += 0.5;
					case 1: vPos[1] += 0.5;
					case 2: vPos[2] += 0.5;
					case 3: vPos[0] -= 0.5;
					case 4: vPos[1] -= 0.5;
					case 5: vPos[2] -= 0.5;
				}

				TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);

				PrintToChat(client, "%sNew origin: %f %f %f", CHAT_TAG, vPos[0], vPos[1], vPos[2]);
				break;
			}
		}
	}
}

void SaveData(int client)
{
	int entity, index;
	int aim = GetClientAimTarget(client, false);
	if( aim == -1 )
		return;

	aim = EntIndexToEntRef(aim);

	for( int i = 0; i < MAX_ALLOWED; i++ )
	{
		entity = g_iEntities[i];

		if( entity == aim  )
		{
			index = g_iCfgIndex[i];
			break;
		}
	}

	if( index == 0 )
		return;

	// Load config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the cabinet config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return;
	}

	KeyValues hFile = new KeyValues("cabinets");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the cabinet config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the cabinet config.", CHAT_TAG);
		delete hFile;
		return;
	}

	float vAng[3], vPos[3];
	char sTemp[4];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

	IntToString(index, sTemp, sizeof(sTemp));
	if( hFile.JumpToKey(sTemp) )
	{
		hFile.SetVector("angle", vAng);
		hFile.SetVector("origin", vPos);

		// Save cfg
		hFile.Rewind();
		hFile.ExportToFile(sPath);

		PrintToChat(client, "%sSaved origin and angles to the data config", CHAT_TAG);
	}
}

void CreateMenus()
{
	if( g_hMenuAng == null )
	{
		g_hMenuAng = new Menu(AngMenuHandler);
		g_hMenuAng.AddItem("", "X + 5.0");
		g_hMenuAng.AddItem("", "Y + 5.0");
		g_hMenuAng.AddItem("", "Z + 5.0");
		g_hMenuAng.AddItem("", "X - 5.0");
		g_hMenuAng.AddItem("", "Y - 5.0");
		g_hMenuAng.AddItem("", "Z - 5.0");
		g_hMenuAng.AddItem("", "SAVE");
		g_hMenuAng.SetTitle("Set Angle");
		g_hMenuAng.ExitButton = true;
	}

	if( g_hMenuPos == null )
	{
		g_hMenuPos = new Menu(PosMenuHandler);
		g_hMenuPos.AddItem("", "X + 0.5");
		g_hMenuPos.AddItem("", "Y + 0.5");
		g_hMenuPos.AddItem("", "Z + 0.5");
		g_hMenuPos.AddItem("", "X - 0.5");
		g_hMenuPos.AddItem("", "Y - 0.5");
		g_hMenuPos.AddItem("", "Z - 0.5");
		g_hMenuPos.AddItem("", "SAVE");
		g_hMenuPos.SetTitle("Set Position");
		g_hMenuPos.ExitButton = true;
	}
}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}