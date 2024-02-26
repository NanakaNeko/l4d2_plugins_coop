/*
*	Melee Weapon Spawner
*	Copyright (C) 2022 Silvers
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



#define PLUGIN_VERSION 		"1.7"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Melee Weapon Spawner
*	Author	:	SilverShot
*	Descrp	:	Spawns a single melee weapon fixed in position, these can be temporary or saved for auto-spawning.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=223020
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.7 (11-Dec-2022)
	- Various changes to tidy up code.

1.6 (26-May-2022)
	- Menu now displays the last page that was selected instead of returning to the first page.

1.5 (24-Sep-2020)
	- Compatibility update for L4D2's "The Last Stand" update.
	- Added support for the 2 new melee weapons.

1.4 (10-May-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.

1.3 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.2 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.

1.1.1 (18-Aug-2013)
	- Changed the randomise slightly so melee spawn positions are better.

1.1 (09-Aug-2013)
	- Added cvar "l4d2_melee_spawn_randomise" to randomise the spawns based on a chance out of 100.

1.0 (09-Aug-2013)
	- Initial release.

========================================================================================
	Thanks:

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	"Zuko & McFlurry" for "[L4D2] Weapon/Zombie Spawner" - Modified SetTeleportEndPoint function.
	https://forums.alliedmods.net/showthread.php?t=109659

*	Thanks to "Boikinov" for "[L4D] Left FORT Dead builder" - RotateYaw function
	https://forums.alliedmods.net/showthread.php?t=93716

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define CHAT_TAG			"\x04[\x05Melee Spawn\x04] \x01"
#define CONFIG_SPAWNS		"data/l4d2_melee_spawn.cfg"
#define MAX_SPAWNS			32
#define	MAX_MELEE			13


Menu g_hMenuAng, g_hMenuList, g_hMenuPos;
ConVar g_hCvarAllow, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarRandom, g_hCvarRandomise;
int g_iCvarRandom, g_iCvarRandomise, g_iPlayerSpawn, g_iRoundStart, g_iSave[MAXPLAYERS+1], g_iSpawnCount, g_iSpawns[MAX_SPAWNS][2];
bool g_bCvarAllow, g_bMapStarted, g_bLoaded;

char g_sWeaponNames[MAX_MELEE][] =
{
	"Axe",
	"Baseball Bat",
	"Cricket Bat",
	"Crowbar",
	"Frying Pan",
	"Golf Club",
	"Guitar",
	"Katana",
	"Machete",
	"Nightstick",
	"Knife",
	"Pitchfork",
	"Shovel"
	// "Shield"
};
char g_sScripts[MAX_MELEE][] =
{
	"fireaxe",
	"baseball_bat",
	"cricket_bat",
	"crowbar",
	"frying_pan",
	"golfclub",
	"electric_guitar",
	"katana",
	"machete",
	"tonfa",
	"knife",
	"pitchfork",
	"shovel"
	// "riotshield"
};



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Melee Weapon Spawner",
	author = "SilverShot",
	description = "Spawns a single melee weapon fixed in position, these can be temporary or saved for auto-spawning.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=223020"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarAllow =		CreateConVar(	"l4d2_melee_spawn_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d2_melee_spawn_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d2_melee_spawn_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d2_melee_spawn_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarRandom =		CreateConVar(	"l4d2_melee_spawn_random",			"-1",			"-1=All, 0=None. Otherwise randomly select this many melee weapons to spawn from the maps config.", CVAR_FLAGS );
	g_hCvarRandomise =	CreateConVar(	"l4d2_melee_spawn_randomise",		"25",			"0=Off. Chance out of 100 to randomise the type of melee weapon regardless of what it's set to.", CVAR_FLAGS );
	CreateConVar(						"l4d2_melee_spawn_version",			PLUGIN_VERSION, "Melee Weapon Spawner plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d2_melee_spawn");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarRandom.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRandomise.AddChangeHook(ConVarChanged_Cvars);

	RegAdminCmd("sm_melee_spawn",			CmdSpawnerTemp,		ADMFLAG_ROOT, 	"Opens a menu of melee weapons to spawn. Spawns a temporary melee weapon at your crosshair.");
	RegAdminCmd("sm_melee_spawn_save",		CmdSpawnerSave,		ADMFLAG_ROOT, 	"Opens a menu of melee weapons to spawn. Spawns a melee weapon at your crosshair and saves to config.");
	RegAdminCmd("sm_melee_spawn_del",		CmdSpawnerDel,		ADMFLAG_ROOT, 	"Removes the melee weapon you are pointing at and deletes from the config if saved.");
	RegAdminCmd("sm_melee_spawn_clear",		CmdSpawnerClear,	ADMFLAG_ROOT, 	"Removes all melee weapons spawned by this plugin from the current map.");
	RegAdminCmd("sm_melee_spawn_wipe",		CmdSpawnerWipe,		ADMFLAG_ROOT, 	"Removes all melee weapons spawned by this plugin from the current map and deletes them from the config.");
	RegAdminCmd("sm_melee_spawn_glow",		CmdSpawnerGlow,		ADMFLAG_ROOT, 	"Toggle to enable glow on all melee weapons to see where they are placed.");
	RegAdminCmd("sm_melee_spawn_list",		CmdSpawnerList,		ADMFLAG_ROOT, 	"Display a list melee weapon positions and the total number of.");
	RegAdminCmd("sm_melee_spawn_tele",		CmdSpawnerTele,		ADMFLAG_ROOT, 	"Teleport to a melee weapon (Usage: sm_melee_spawn_tele <index: 1 to MAX_SPAWNS (32)>).");
	RegAdminCmd("sm_melee_spawn_ang",		CmdSpawnerAng,		ADMFLAG_ROOT, 	"Displays a menu to adjust the melee weapon angles your crosshair is over.");
	RegAdminCmd("sm_melee_spawn_pos",		CmdSpawnerPos,		ADMFLAG_ROOT, 	"Displays a menu to adjust the melee weapon origin your crosshair is over.");



	g_hMenuList = new Menu(ListMenuHandler);
	for( int i = 0; i < MAX_MELEE; i++ )
	{
		g_hMenuList.AddItem("", g_sWeaponNames[i]);
	}
	g_hMenuList.SetTitle("Spawn Melee");
	g_hMenuList.ExitBackButton = true;
}

public void OnPluginEnd()
{
	ResetPlugin();
}

public void OnMapStart()
{
	g_bMapStarted = true;

	// Taken from MeleeInTheSaferoom
	PrecacheModel("models/weapons/melee/v_bat.mdl", true);
	PrecacheModel("models/weapons/melee/v_cricket_bat.mdl", true);
	PrecacheModel("models/weapons/melee/v_crowbar.mdl", true);
	PrecacheModel("models/weapons/melee/v_electric_guitar.mdl", true);
	PrecacheModel("models/weapons/melee/v_fireaxe.mdl", true);
	PrecacheModel("models/weapons/melee/v_frying_pan.mdl", true);
	PrecacheModel("models/weapons/melee/v_golfclub.mdl", true);
	PrecacheModel("models/weapons/melee/v_katana.mdl", true);
	PrecacheModel("models/weapons/melee/v_machete.mdl", true);
	PrecacheModel("models/weapons/melee/v_tonfa.mdl", true);
	PrecacheModel("models/weapons/melee/v_pitchfork.mdl", true);
	PrecacheModel("models/weapons/melee/v_shovel.mdl", true);

	PrecacheModel("models/weapons/melee/w_bat.mdl", true);
	PrecacheModel("models/weapons/melee/w_cricket_bat.mdl", true);
	PrecacheModel("models/weapons/melee/w_crowbar.mdl", true);
	PrecacheModel("models/weapons/melee/w_electric_guitar.mdl", true);
	PrecacheModel("models/weapons/melee/w_fireaxe.mdl", true);
	PrecacheModel("models/weapons/melee/w_frying_pan.mdl", true);
	PrecacheModel("models/weapons/melee/w_golfclub.mdl", true);
	PrecacheModel("models/weapons/melee/w_katana.mdl", true);
	PrecacheModel("models/weapons/melee/w_machete.mdl", true);
	PrecacheModel("models/weapons/melee/w_tonfa.mdl", true);
	PrecacheModel("models/weapons/melee/w_pitchfork.mdl", true);
	PrecacheModel("models/weapons/melee/w_shovel.mdl", true);

	PrecacheGeneric("scripts/melee/baseball_bat.txt", true);
	PrecacheGeneric("scripts/melee/cricket_bat.txt", true);
	PrecacheGeneric("scripts/melee/crowbar.txt", true);
	PrecacheGeneric("scripts/melee/electric_guitar.txt", true);
	PrecacheGeneric("scripts/melee/fireaxe.txt", true);
	PrecacheGeneric("scripts/melee/frying_pan.txt", true);
	PrecacheGeneric("scripts/melee/golfclub.txt", true);
	PrecacheGeneric("scripts/melee/katana.txt", true);
	PrecacheGeneric("scripts/melee/machete.txt", true);
	PrecacheGeneric("scripts/melee/tonfa.txt", true);
	PrecacheGeneric("scripts/melee/pitchfork.txt", true);
	PrecacheGeneric("scripts/melee/shovel.txt", true);
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetPlugin(false);
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarRandom = g_hCvarRandom.IntValue;
	g_iCvarRandomise = g_hCvarRandomise.IntValue;
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		LoadSpawns();
		g_bCvarAllow = true;
		HookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		HookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		HookEvent("round_end",			Event_RoundEnd,		EventHookMode_PostNoCopy);
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		ResetPlugin();
		g_bCvarAllow = false;
		UnhookEvent("player_spawn",		Event_PlayerSpawn,	EventHookMode_PostNoCopy);
		UnhookEvent("round_start",		Event_RoundStart,	EventHookMode_PostNoCopy);
		UnhookEvent("round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy);
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

void OnGamemode(const char[] output, int caller, int activator, float delay)
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
void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetPlugin(false);
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 1 && g_iRoundStart == 0 )
		CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPlayerSpawn == 0 && g_iRoundStart == 1 )
		CreateTimer(1.0, TimerStart, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

Action TimerStart(Handle timer)
{
	ResetPlugin();
	LoadSpawns();
	return Plugin_Continue;
}



// ====================================================================================================
//					LOAD SPAWNS
// ====================================================================================================
void LoadSpawns()
{
	if( g_bLoaded || g_iCvarRandom == 0 ) return;
	g_bLoaded = true;

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		return;

	// Load config
	KeyValues hFile = new KeyValues("spawns");
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

	// Retrieve how many Melees to display
	int iCount = hFile.GetNum("num", 0);
	if( iCount == 0 )
	{
		delete hFile;
		return;
	}

	// Spawn only a select few Melees?
	int iIndexes[MAX_SPAWNS+1];
	if( iCount > MAX_SPAWNS )
		iCount = MAX_SPAWNS;


	// Spawn saved Melees or create random
	int iRandom = g_iCvarRandom;
	if( iRandom == -1 || iRandom > iCount)
		iRandom = iCount;
	if( iRandom != -1 )
	{
		for( int i = 1; i <= iCount; i++ )
			iIndexes[i-1] = i;

		SortIntegers(iIndexes, iCount, Sort_Random);
		iCount = iRandom;
	}

	// Get the Melee origins and spawn
	char sTemp[4];
	float vPos[3], vAng[3];
	int index, iMod;
	for( int i = 1; i <= iCount; i++ )
	{
		if( iRandom != -1 ) index = iIndexes[i-1];
		else index = i;

		IntToString(index, sTemp, sizeof(sTemp));

		if( hFile.JumpToKey(sTemp) )
		{
			hFile.GetVector("ang", vAng);
			hFile.GetVector("pos", vPos);
			iMod = hFile.GetNum("mod");

			if( vPos[0] == 0.0 && vPos[1] == 0.0 && vPos[2] == 0.0 ) // Should never happen...
				LogError("Error: 0,0,0 origin. Iteration=%d. Index=%d. Random=%d. Count=%d.", i, index, iRandom, iCount);
			else
				CreateSpawn(vPos, vAng, index, iMod, true);
			hFile.GoBack();
		}
	}

	delete hFile;
}



// ====================================================================================================
//					CREATE SPAWN
// ====================================================================================================
void CreateSpawn(const float vOrigin[3], const float vAngles[3], int index = 0, int model = 0, int autospawn = false)
{
	if( g_iSpawnCount >= MAX_SPAWNS )
		return;

	int iSpawnIndex = -1;
	for( int i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iSpawns[i][0] == 0 )
		{
			iSpawnIndex = i;
			break;
		}
	}

	if( iSpawnIndex == -1 )
		return;


	int entity_weapon = -1;
	entity_weapon = CreateEntityByName("weapon_melee");
	if( entity_weapon == -1 )
		ThrowError("Failed to create entity 'weapon_melee'.");

	if( autospawn && g_iCvarRandomise && GetRandomInt(0, 100) <= g_iCvarRandomise )
		model = GetRandomInt(0, MAX_MELEE-1);

	DispatchKeyValue(entity_weapon, "solid", "6");
	DispatchKeyValue(entity_weapon, "melee_script_name", g_sScripts[model]);
	DispatchSpawn(entity_weapon);

	if( model == 4 || model == 6 )
	{
		if( model == 4 )
		{
			float vPos[3];
			vPos = vOrigin;
			vPos[2] += 0.6;
			TeleportEntity(entity_weapon, vPos, vAngles, NULL_VECTOR);
		} else {
			float vAng[3];
			vAng = vAngles;
			vAng[0] += 180.0;
			vAng[1] += 180.0;
			TeleportEntity(entity_weapon, vOrigin, vAng, NULL_VECTOR);
		}
	} else {
		TeleportEntity(entity_weapon, vOrigin, vAngles, NULL_VECTOR);
	}

	SetEntityMoveType(entity_weapon, MOVETYPE_NONE);

	g_iSpawns[iSpawnIndex][0] = EntIndexToEntRef(entity_weapon);
	g_iSpawns[iSpawnIndex][1] = index;

	g_iSpawnCount++;
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
//					sm_melee_spawn
// ====================================================================================================
int ListMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Select )
	{
		if( g_iSave[client] == 0 )
		{
			CmdSpawnerTempMenu(client, index);
		} else {
			CmdSpawnerSaveMenu(client, index);
		}

		g_hMenuList.DisplayAt(client, g_hMenuList.Selection, MENU_TIME_FOREVER);
	}

	return 0;
}

Action CmdSpawnerTemp(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Melee Spawn] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}
	else if( g_iSpawnCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Melees. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iSpawnCount, MAX_SPAWNS);
		return Plugin_Handled;
	}

	g_iSave[client] = 0;
	g_hMenuList.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

void CmdSpawnerTempMenu(int client, int weapon)
{
	if( !client )
	{
		ReplyToCommand(client, "[Melee Spawn] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return;
	}
	else if( g_iSpawnCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Melees. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iSpawnCount, MAX_SPAWNS);
		return;
	}

	float vPos[3], vAng[3];
	if( !SetTeleportEndPoint(client, vPos, vAng) )
	{
		PrintToChat(client, "%sCannot place Melee, please try again.", CHAT_TAG);
		return;
	}

	CreateSpawn(vPos, vAng, 0, weapon);
	return;
}

// ====================================================================================================
//					sm_melee_spawn_save
// ====================================================================================================
Action CmdSpawnerSave(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Melee Spawn] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}
	else if( g_iSpawnCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Melees. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iSpawnCount, MAX_SPAWNS);
		return Plugin_Handled;
	}

	g_iSave[client] = 1;
	g_hMenuList.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

void CmdSpawnerSaveMenu(int client, int weapon)
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		File hCfg = OpenFile(sPath, "w");
		hCfg.WriteLine("");
		delete hCfg;
	}

	// Load config
	KeyValues hFile = new KeyValues("spawns");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot read the Melee Spawn config, assuming empty file. (\x05%s\x01).", CHAT_TAG, sPath);
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if( !hFile.JumpToKey(sMap, true) )
	{
		PrintToChat(client, "%sError: Failed to add map to Melee Spawn config.", CHAT_TAG);
		delete hFile;
		return;
	}

	// Retrieve how many Melee Spawns are saved
	int iCount = hFile.GetNum("num", 0);
	if( iCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Melee Spawns. Used: (\x05%d/%d\x01).", CHAT_TAG, iCount, MAX_SPAWNS);
		delete hFile;
		return;
	}

	// Save count
	iCount++;
	hFile.SetNum("num", iCount);

	char sTemp[4];
	IntToString(iCount, sTemp, sizeof(sTemp));

	if( hFile.JumpToKey(sTemp, true) )
	{
		// Set player position as Melee Spawn location
		float vPos[3], vAng[3];
		if( !SetTeleportEndPoint(client, vPos, vAng) )
		{
			PrintToChat(client, "%sCannot place Melee Spawn, please try again.", CHAT_TAG);
			delete hFile;
			return;
		}

		// Save angle / origin
		hFile.SetVector("ang", vAng);
		hFile.SetVector("pos", vPos);
		hFile.SetNum("mod", weapon);

		CreateSpawn(vPos, vAng, iCount, weapon);

		// Save cfg
		hFile.Rewind();
		hFile.ExportToFile(sPath);

		PrintToChat(client, "%s(\x05%d/%d\x01) - Saved at pos:[\x05%f %f %f\x01] ang:[\x05%f %f %f\x01]", CHAT_TAG, iCount, MAX_SPAWNS, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to save Melee Spawn.", CHAT_TAG, iCount, MAX_SPAWNS);

	delete hFile;
}

// ====================================================================================================
//					sm_melee_spawn_del
// ====================================================================================================
Action CmdSpawnerDel(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[Melee Spawn] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Melee Spawn] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	int entity = GetClientAimTarget(client, false);
	if( entity == -1 ) return Plugin_Handled;
	entity = EntIndexToEntRef(entity);

	int cfgindex, index = -1;
	for( int i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iSpawns[i][0] == entity )
		{
			index = i;
			break;
		}
	}

	if( index == -1 )
		return Plugin_Handled;

	cfgindex = g_iSpawns[index][1];
	if( cfgindex == 0 )
	{
		RemoveSpawn(index);
		return Plugin_Handled;
	}

	for( int i = 0; i < MAX_SPAWNS; i++ )
	{
		if( g_iSpawns[i][1] > cfgindex )
			g_iSpawns[i][1]--;
	}

	g_iSpawnCount--;

	// Load config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Melee Spawn config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	KeyValues hFile = new KeyValues("spawns");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Melee Spawn config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the Melee Spawn config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many Melee Spawns
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
				bMove = true;
				hFile.DeleteThis();
				RemoveSpawn(index);
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

		PrintToChat(client, "%s(\x05%d/%d\x01) - Melee Spawn removed from config.", CHAT_TAG, iCount, MAX_SPAWNS);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to remove Melee Spawn from config.", CHAT_TAG, iCount, MAX_SPAWNS);

	delete hFile;
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_melee_spawn_clear
// ====================================================================================================
Action CmdSpawnerClear(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Melee Spawn] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	ResetPlugin();

	PrintToChat(client, "%s(0/%d) - All Melee Spawns removed from the map.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_melee_spawn_wipe
// ====================================================================================================
Action CmdSpawnerWipe(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Melee Spawn] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Melee Spawn config (\x05%s\x01).", CHAT_TAG, sPath);
		return Plugin_Handled;
	}

	// Load config
	KeyValues hFile = new KeyValues("spawns");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Melee Spawn config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap, false) )
	{
		PrintToChat(client, "%sError: Current map not in the Melee Spawn config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	hFile.DeleteThis();
	ResetPlugin();

	// Save to file
	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	PrintToChat(client, "%s(0/%d) - All Melee Spawns removed from config, add with \x05sm_melee_spawn_save\x01.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_melee_spawn_glow
// ====================================================================================================
Action CmdSpawnerGlow(int client, int args)
{
	static bool glow;
	glow = !glow;
	PrintToChat(client, "%sGlow has been turned %s", CHAT_TAG, glow ? "on" : "off");

	VendorGlow(glow);
	return Plugin_Handled;
}

void VendorGlow(int glow)
{
	int ent;

	for( int i = 0; i < MAX_SPAWNS; i++ )
	{
		ent = g_iSpawns[i][0];
		if( IsValidEntRef(ent) )
		{
			SetEntProp(ent, Prop_Send, "m_iGlowType", glow ? 3 : 0);
			if( glow )
			{
				SetEntProp(ent, Prop_Send, "m_glowColorOverride", 255);
				SetEntProp(ent, Prop_Send, "m_nGlowRange", glow ? 0 : 50);
			}
		}
	}
}

// ====================================================================================================
//					sm_melee_spawn_list
// ====================================================================================================
Action CmdSpawnerList(int client, int args)
{
	float vPos[3];
	int count;
	for( int i = 0; i < MAX_SPAWNS; i++ )
	{
		if( IsValidEntRef(g_iSpawns[i][0]) )
		{
			count++;
			GetEntPropVector(g_iSpawns[i][0], Prop_Data, "m_vecOrigin", vPos);
			PrintToChat(client, "%s%d) %f %f %f", CHAT_TAG, i+1, vPos[0], vPos[1], vPos[2]);
		}
	}
	PrintToChat(client, "%sTotal: %d.", CHAT_TAG, count);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_melee_spawn_tele
// ====================================================================================================
Action CmdSpawnerTele(int client, int args)
{
	if( args == 1 )
	{
		char arg[16];
		GetCmdArg(1, arg, sizeof(arg));
		int index = StringToInt(arg) - 1;
		if( index > -1 && index < MAX_SPAWNS && IsValidEntRef(g_iSpawns[index][0]) )
		{
			float vPos[3];
			GetEntPropVector(g_iSpawns[index][0], Prop_Data, "m_vecOrigin", vPos);
			vPos[2] += 20.0;
			TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
			PrintToChat(client, "%sTeleported to %d.", CHAT_TAG, index + 1);
			return Plugin_Handled;
		}

		PrintToChat(client, "%sCould not find index for teleportation.", CHAT_TAG);
	}
	else
		PrintToChat(client, "%sUsage: sm_melee_spawn_tele <index 1-%d>.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					MENU ANGLE
// ====================================================================================================
Action CmdSpawnerAng(int client, int args)
{
	ShowMenuAng(client);
	return Plugin_Handled;
}

void ShowMenuAng(int client)
{
	CreateMenus();
	g_hMenuAng.Display(client, MENU_TIME_FOREVER);
}

int AngMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Select )
	{
		if( index == 6 )
			SaveData(client);
		else
			SetAngle(client, index);
		ShowMenuAng(client);
	}

	return 0;
}

void SetAngle(int client, int index)
{
	int aim = GetClientAimTarget(client, false);
	if( aim != -1 )
	{
		float vAng[3];
		int entity;
		aim = EntIndexToEntRef(aim);

		for( int i = 0; i < MAX_SPAWNS; i++ )
		{
			entity = g_iSpawns[i][0];

			if( entity == aim  )
			{
				GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

				switch( index )
				{
					case 0: vAng[0] += 2.0;
					case 1: vAng[1] += 2.0;
					case 2: vAng[2] += 2.0;
					case 3: vAng[0] -= 2.0;
					case 4: vAng[1] -= 2.0;
					case 5: vAng[2] -= 2.0;
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
Action CmdSpawnerPos(int client, int args)
{
	ShowMenuPos(client);
	return Plugin_Handled;
}

void ShowMenuPos(int client)
{
	CreateMenus();
	g_hMenuPos.Display(client, MENU_TIME_FOREVER);
}

int PosMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Select )
	{
		if( index == 6 )
			SaveData(client);
		else
			SetOrigin(client, index);
		ShowMenuPos(client);
	}

	return 0;
}

void SetOrigin(int client, int index)
{
	int aim = GetClientAimTarget(client, false);
	if( aim != -1 )
	{
		float vPos[3];
		int entity;
		aim = EntIndexToEntRef(aim);

		for( int i = 0; i < MAX_SPAWNS; i++ )
		{
			entity = g_iSpawns[i][0];

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

	for( int i = 0; i < MAX_SPAWNS; i++ )
	{
		entity = g_iSpawns[i][0];

		if( entity == aim  )
		{
			index = g_iSpawns[i][1];
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
		PrintToChat(client, "%sError: Cannot find the Melee Spawn config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return;
	}

	KeyValues hFile = new KeyValues("spawns");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Melee Spawn config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the Melee Spawn config.", CHAT_TAG);
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
		hFile.SetVector("ang", vAng);
		hFile.SetVector("pos", vPos);

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
		g_hMenuAng.AddItem("", "X + 2.0");
		g_hMenuAng.AddItem("", "Y + 2.0");
		g_hMenuAng.AddItem("", "Z + 2.0");
		g_hMenuAng.AddItem("", "X - 2.0");
		g_hMenuAng.AddItem("", "Y - 2.0");
		g_hMenuAng.AddItem("", "Z - 2.0");
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



// ====================================================================================================
//					STUFF
// ====================================================================================================
bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

void ResetPlugin(bool all = true)
{
	g_bLoaded = false;
	g_iSpawnCount = 0;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;

	if( all )
		for( int i = 0; i < MAX_SPAWNS; i++ )
			RemoveSpawn(i);
}

void RemoveSpawn(int index)
{
	int entity, client;

	entity = g_iSpawns[index][0];
	g_iSpawns[index][0] = 0;
	g_iSpawns[index][1] = 0;

	if( IsValidEntRef(entity) )
	{
		client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if( client < 0 || client > MaxClients || !IsClientInGame(client) )
		{
			RemoveEntity(entity);
		}
	}
}



// ====================================================================================================
//					POSITION
// ====================================================================================================
float GetGroundHeight(float vPos[3])
{
	float vAng[3];

	Handle trace = TR_TraceRayFilterEx(vPos, view_as<float>({ 90.0, 0.0, 0.0 }), MASK_ALL, RayType_Infinite, _TraceFilter);
	if( TR_DidHit(trace) )
		TR_GetEndPosition(vAng, trace);

	delete trace;
	return vAng[2];
}

// Taken from "[L4D2] Weapon/Zombie Spawner"
// By "Zuko & McFlurry"
bool SetTeleportEndPoint(int client, float vPos[3], float vAng[3])
{
	GetClientEyePosition(client, vPos);
	GetClientEyeAngles(client, vAng);

	Handle trace = TR_TraceRayFilterEx(vPos, vAng, MASK_SHOT, RayType_Infinite, _TraceFilter);

	if( TR_DidHit(trace) )
	{
		float vNorm[3];
		float degrees = vAng[1];
		TR_GetEndPosition(vPos, trace);

		GetGroundHeight(vPos);
		vPos[2] += 1.0;

		TR_GetPlaneNormal(trace, vNorm);
		GetVectorAngles(vNorm, vAng);

		if( vNorm[2] == 1.0 )
		{
			vAng[0] = 0.0;
			vAng[1] = degrees + 180;
		}
		else
		{
			if( degrees > vAng[1] )
				degrees = vAng[1] - degrees;
			else
				degrees = degrees - vAng[1];
			vAng[0] += 90.0;
			RotateYaw(vAng, degrees + 180);
		}
	}
	else
	{
		delete trace;
		return false;
	}

	vAng[1] += 90.0;
	vAng[2] -= 90.0;
	delete trace;
	return true;
}

bool _TraceFilter(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}



//---------------------------------------------------------
// do a specific rotation on the given angles
//---------------------------------------------------------
void RotateYaw(float angles[3], float degree)
{
	float direction[3], normal[3];
	GetAngleVectors(angles, direction, NULL_VECTOR, normal);

	float sin = Sine(degree * 0.01745328);	 // Pi/180
	float cos = Cosine(degree * 0.01745328);
	float a = normal[0] * sin;
	float b = normal[1] * sin;
	float c = normal[2] * sin;
	float x = direction[2] * b + direction[0] * cos - direction[1] * c;
	float y = direction[0] * c + direction[1] * cos - direction[2] * a;
	float z = direction[1] * a + direction[2] * cos - direction[0] * b;
	direction[0] = x;
	direction[1] = y;
	direction[2] = z;

	GetVectorAngles(direction, angles);

	float up[3];
	GetVectorVectors(direction, NULL_VECTOR, up);

	float roll = GetAngleBetweenVectors(up, normal, direction);
	angles[2] += roll;
}

//---------------------------------------------------------
// calculate the angle between 2 vectors
// the direction will be used to determine the sign of angle (right hand rule)
// all of the 3 vectors have to be normalized
//---------------------------------------------------------
float GetAngleBetweenVectors(const float vector1[3], const float vector2[3], const float direction[3])
{
	float vector1_n[3], vector2_n[3], direction_n[3], cross[3];
	NormalizeVector(direction, direction_n);
	NormalizeVector(vector1, vector1_n);
	NormalizeVector(vector2, vector2_n);
	float degree = ArcCosine(GetVectorDotProduct(vector1_n, vector2_n )) * 57.29577951;   // 180/Pi
	GetVectorCrossProduct(vector1_n, vector2_n, cross);

	if( GetVectorDotProduct( cross, direction_n ) < 0.0 )
		degree *= -1.0;

	return degree;
}