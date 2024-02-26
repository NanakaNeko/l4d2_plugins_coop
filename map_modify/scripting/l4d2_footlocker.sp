/*
*	Footlocker Spawner
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



#define PLUGIN_VERSION 		"1.18"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D2] Footlocker Spawner
*	Author	:	SilverShot
*	Descrp	:	Auto-spawn footlockers on round start.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=157183
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.18 (11-Dec-2022)
	- Changes to fix compile warnings on SourceMod 1.11.

1.17 (27-Oct-2021)
	- Changed the way Firework Crates are spawned to be compatible with "Physics fix" plugin. Thanks to "Marttt" for fixing.

1.16a (23-Feb-2021)
	- Data config updated - removed bad footlocker placement on "c9m1_alleys" map. Thanks to "PEK727" for reporting.

1.16 (30-Sep-2020)
	- Fixed compile errors on SM 1.11.

1.15 (10-May-2020)
	- Various changes to tidy up code.

1.14 (12-Apr-2020)
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.

1.13 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.12 (14-Mar-2020)
	- Fixed invalid entity error. Thanks to "sxslmk" for reporting.

1.11 (04-Mar-2020)
	- Fixed potential server hanging/crashing on map change with the error:
		"Host_Error: SV_CreatePacketEntities: GetEntServerClass failed for ent 2."
	- This was caused by spawning the "info_gamemode" entity in OnMapStart. Fixed by adding a 0.1 delay.
	- Thanks to "Xanaguy" and "sxslmk" for reporting.

1.10.3 (14-Aug-2018)
	- Another fix attempt for incorrect items spawning, tested on coop/versus/hard rain.
	- Fixed "Inserted func_button with no model" error when pressing a button.

1.10.2 (18-Jun-2018)
	- Fixed spawning items not working correctly. Thanks to "Accelerator74" for reporting and testing.

1.10.1 (17-May-2018)
	- Fixed array index error, which broke spawning items in versus. Thanks to "Accelerator74" for reporting.

1.10.0 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.
	- Changed: Versus and scavenge games now spawn the same footlockers and items for both teams (except Witch).

1.9.2 (14-Jun-2015)
	- Fixed "Client index is invalid" errors.

1.9.1 (13-Apr-2015)
	- Fixed the plugin not compiling on SourceMod 1.7.x.

1.9 (21-Jul-2013)
	- Removed Sort_Random work-around. This was fixed in SourceMod 1.4.7, all should update or spawning issues will occur.

1.8 (02-Jun-2012)
	- Fixed the last update breaking a patch for the "Gear Transfer" plugin removing items.

1.7 (01-Jun-2012)
	- Added cvar "l4d2_footlocker_glow_color" to set the glow color.
	- Fixed items not respawning after being taken.
	- Fixed the witch sometimes getting stuck inside the Footlocker.
	- More prevention for players getting stuck inside the Footlocker.

1.6 (27-May-2012)
	- Fixed the witch blocking players or disappearing.

1.5 (10-May-2012)
	- Added command "sm_lockerang" to change the footlocker angle.
	- Added command "sm_lockerpos" to change the footlocker origin.
	- Added cvar "l4d2_footlocker_modes_off" to control which game modes the plugin works in.
	- Added cvar "l4d2_footlocker_modes_tog" same as above.
	- Added cvar "l4d2_footlocker_hint" to notify players who opened the footlocker.
	- Changed config format, use the "sm_silverscfg_locker" plugin and command to reformat your config.
	- Changed cvar "l4d2_footlocker_modes" to enable the plugin on specified modes.
	- Fixed another bug with the witch and firework crates.
	- Removed max entity check and related error logging.

1.4 (01-Mar-2011)
	- Fixed firework crates spawning when a witch spawns.

1.3 (14-Jan-2012)
	- Fixed the cvar "l4d2_footlocker_random" to actually work.

1.2 (01-Dec-2011)
	- Incompatibility: If you use Gear Transfer, you must update to 1.5.7 or greater.
	- Added Footlockers to these maps: Crash Course, Death Toll, Dead Air, Blood Harvest, Cold Stream.
	- Added command "sm_lockerclear" to remove all Footlockers from the current map.
	- Added cvar "l4d2_footlocker_allow" to enable or disable the plugin.
	- Changed cvar "l4d2_footlocker_random", 0 turns off spawning random footlockers, -1 spawns all.
	- Fixed server crashes due to the removal of *_spawn items.
	- Fixed adrenaline and pills not dispensing unlimited items.
	- Pushes players away if they are too close when opening footlockers to avoid them getting stuck.
	- Stopped respawning items on Hard Rain in Versus and Scavenge modes.

1.1 (22-May-2011)
	- Added cvar "l4d2_footlocker_timed" to set how many seconds it takes to open a footlocker.

1.01 (17-May-2011)
	- Stopped L4D1 characters from vocalizing (missing audio).

1.0 (17-May-2011)
	- Initial release.

========================================================================================

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	Thanks to"Zuko & McFlurry" for "[L4D2] Weapon/Zombie Spawner" - Modified the SetTeleportEndPoint()
	https://forums.alliedmods.net/showthread.php?t=109659

*	Thanks to "Boikinov" for "[L4D] Left FORT Dead builder" - RotateYaw function to rotate the footlockers
	https://forums.alliedmods.net/showthread.php?t=93716

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define CHAT_TAG			"\x04[\x05Footlocker Spawner\x04] \x01"
#define CHAT_USAGE			"Usage: <type: 1=Molotov, 2=Pipebomb, 4=Vomitjar, 8=Adrenaline, 16=Pain Pills, 32=Fireworks crate> <count, 0=infinite>"
#define CONFIG_SPAWNS		"data/l4d2_footlocker.cfg"
#define MAX_FOOTLOCKERS		20
#define MAX_ENT_STORE		17

#define MODEL_LOCKER		"models/props_waterfront/footlocker01.mdl"
#define MODEL_LOCKER2		"models/props/cs_militia/footlocker01_open.mdl"
#define MODEL_CRATE			"models/props_crates/supply_crate02_gib2.mdl"
#define MODEL_WITCH			"models/infected/witch_bride.mdl"
#define SOUND_OPEN			"doors/trunk_open.wav"


ConVar g_hCvarAllow, g_hCvarGlow, g_hCvarGlowCol, g_hCvarHint, g_hCvarMPGameMode, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarRandom, g_hCvarTimed, g_hCvarTotal, g_hCvarTypes, g_hCvarVoca, g_hCvarWitch;

Menu g_hMenuAng, g_hMenuPos;
bool g_bCvarAllow, g_bMapStarted, g_bGlow, g_bLoaded;
int g_iCvarGlow, g_iCvarGlowCol, g_iCvarHint, g_iCvarRandom, g_iCvarTimed, g_iCvarTotal, g_iCvarTypes, g_iPlayerSpawn, g_iRoundStart, g_iFootlockerCount, g_iFootlockers[MAX_FOOTLOCKERS][MAX_ENT_STORE], g_iLockerIndex[MAX_FOOTLOCKERS], g_iTotal[MAX_FOOTLOCKERS], g_iType[MAX_FOOTLOCKERS], g_iWitch[MAX_FOOTLOCKERS];
float g_vItemAngles[MAX_FOOTLOCKERS][3], g_vItemOrigin[MAX_FOOTLOCKERS][3];

// Used in HardRain to save spawned item positions.
int g_iSpawnSaveData1[MAX_FOOTLOCKERS][3];		// [0] = Locker index (relative to cfg), [1] = Open/Closed, [2] = Item Type
int g_iSpawnSaveData2[MAX_FOOTLOCKERS][3];		// c4m1 = g_iSpawnSaveData1. c4m2 = g_iSpawnSaveData2
int g_iSpawnSaveMap;							// 0 = Normal plugin behaviour. 1-4 = Hard Rain. 6 = Versus respawn.

enum
{
	TYPE_MOLOTOV		= (1 << 0),
	TYPE_PIPEBOMB		= (1 << 1),
	TYPE_VOMITJAR		= (1 << 2),
	TYPE_ADRENALINE		= (1 << 3),
	TYPE_PAINPILLS		= (1 << 4),
	TYPE_FIREWORKS		= (1 << 5)
}

static char g_sItems[6][] =
{
	"models/w_models/weapons/w_eq_molotov.mdl",
	"models/w_models/weapons/w_eq_pipebomb.mdl",
	"models/w_models/weapons/w_eq_bile_flask.mdl",
	"models/w_models/weapons/w_eq_adrenaline.mdl",
	"models/w_models/weapons/w_eq_painpills.mdl",
	"models/props_junk/explosive_box001.mdl"
};

static char g_sWeapons[5][] =
{
	"weapon_molotov",
	"weapon_pipe_bomb",
	"weapon_vomitjar",
	"weapon_adrenaline",
	"weapon_pain_pills"
};



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D2] Footlocker",
	author = "SilverShot",
	description = "Auto-spawn footlockers on round start.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=157183"
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
	g_hCvarAllow =		CreateConVar(	"l4d2_footlocker_allow",		"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
	g_hCvarGlow =		CreateConVar(	"l4d2_footlocker_glow",			"100",			"0=Off. Any other value is the range at which the glow will turn on.", CVAR_FLAGS );
	g_hCvarGlowCol =	CreateConVar(	"l4d2_footlocker_glow_color",	"0 255 0",		"0=Default glow color. Three values between 0-255 separated by spaces. RGB Color255 - Red Green Blue.", CVAR_FLAGS );
	g_hCvarHint =		CreateConVar(	"l4d2_footlocker_hint",			"1",			"0=Off. 1=Notify to all players in chat who opened the Footlocker.", CVAR_FLAGS );
	g_hCvarModes =		CreateConVar(	"l4d2_footlocker_modes",		"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d2_footlocker_modes_off",	"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d2_footlocker_modes_tog",	"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarRandom =		CreateConVar(	"l4d2_footlocker_random",		"3",			"-1=All, 0=Off, Randomly select this many footlockers to spawn from the maps config.", CVAR_FLAGS );
	g_hCvarTimed =		CreateConVar(	"l4d2_footlocker_timed",		"1",			"0=Off. How many seconds it takes to open a footlocker.", CVAR_FLAGS, true, 0.0, true, 20.0 );
	g_hCvarTotal =		CreateConVar(	"l4d2_footlocker_total",		"0",			"How many items can be taken from the locker before it's empty. 0 = Infinite.", CVAR_FLAGS, true, 0.0, true, 100.0 );
	g_hCvarTypes =		CreateConVar(	"l4d2_footlocker_types",		"63",			"Which items can spawn. 1=Molotov, 2=Pipebomb, 4=Vomitjar, 8=Adrenaline, 16=Pain Pills, 32=Fireworks crate. 63=All.", CVAR_FLAGS );
	g_hCvarVoca =		CreateConVar(	"l4d2_footlocker_vocalize",		"1",			"Allows survivors to vocalize when they see a footlocker and open it.", CVAR_FLAGS );
	g_hCvarWitch =		CreateConVar(	"l4d2_footlocker_witch",		"100",			"0=Off, 1/cvar value. The chance of a footlocker containing a witch.", CVAR_FLAGS );
	CreateConVar(						"l4d2_footlocker_version",		PLUGIN_VERSION, "Footlocker plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d2_footlocker");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarHint.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarRandom.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTimed.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTotal.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarTypes.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarGlow.AddChangeHook(ConVarChanged_Glow);
	g_hCvarGlowCol.AddChangeHook(ConVarChanged_Glow);

	RegAdminCmd("sm_locker",		CmdLockerTemp,		ADMFLAG_ROOT, 	"Spawns a temporary footlocker at your crosshair.");
	RegAdminCmd("sm_lockersave",	CmdLockerSave,		ADMFLAG_ROOT, 	"Spawns a footlocker at your crosshair and saves to config. Uses cvar defaults when no arguments.");
	RegAdminCmd("sm_lockerdel",		CmdLockerDelete,	ADMFLAG_ROOT, 	"Removes the footlocker your crosshair is pointing at.");
	RegAdminCmd("sm_lockerclear",	CmdLockerClear,		ADMFLAG_ROOT, 	"Removes the footlockers from the current map only.");
	RegAdminCmd("sm_lockerwipe",	CmdLockerWipe,		ADMFLAG_ROOT, 	"Removes all footlockers from the current map and deletes them from the config.");
	RegAdminCmd("sm_lockerglow",	CmdLockerGlow,		ADMFLAG_ROOT, 	"Toggle to enable glow on all footlockers to see where they are placed.");
	RegAdminCmd("sm_lockerlist",	CmdLockerList,		ADMFLAG_ROOT, 	"Display a list footlocker positions and the number of footlockers.");
	RegAdminCmd("sm_lockertele",	CmdLockerTele,		ADMFLAG_ROOT, 	"Teleport to a footlocker (Usage: sm_lockertele <index: 1 to MAX_FOOTLOCKERS>).");
	RegAdminCmd("sm_lockerang",		CmdLockerAng,		ADMFLAG_ROOT, 	"Displays a menu to adjust the footlocker angles your crosshair is over.");
	RegAdminCmd("sm_lockerpos",		CmdLockerPos,		ADMFLAG_ROOT, 	"Displays a menu to adjust the footlocker origin your crosshair is over.");
}

public void OnPluginEnd()
{
	ResetPlugin();
}

int g_iCurrentMode;
public void OnMapStart()
{
	g_bMapStarted = true;

	PrecacheSound(SOUND_OPEN);
	PrecacheModel(MODEL_LOCKER);
	PrecacheModel(MODEL_LOCKER2);
	PrecacheModel(MODEL_CRATE);
	PrecacheSound(MODEL_WITCH);
	for( int i = 0; i < 6; i++ )
		PrecacheModel(g_sItems[i]);

	CreateTimer(0.1, TimerDelayCheck);
}

Action TimerDelayCheck(Handle timer)
{
	SpawnGameMode();

	// Versus/Scavenge
	if( g_iCurrentMode == 4 || g_iCurrentMode == 8 )
	{
		g_iSpawnSaveMap = 0;
	} else {
		// HardRain: Save locker position
		char sMap[6];
		GetCurrentMap(sMap, sizeof(sMap));
		if( strncmp(sMap, "c4m_", 4) == 0 )
		{
			g_iSpawnSaveMap = StringToInt(sMap[3]);
		}
	}

	return Plugin_Continue;
}

void ResetSaveData()
{
	for( int i = 0; i < MAX_FOOTLOCKERS; i++ )
	{
		g_iSpawnSaveData1[i][0] = 0;
		g_iSpawnSaveData1[i][1] = 0;
		g_iSpawnSaveData1[i][2] = -1;
		g_iSpawnSaveData2[i][0] = 0;
		g_iSpawnSaveData2[i][1] = 0;
		g_iSpawnSaveData2[i][2] = -1;
	}
}



// ====================================================================================================
//					CVARS
// ====================================================================================================
public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Cvars(Handle convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void ConVarChanged_Allow(Handle convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarChanged_Glow(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_iCvarGlow = g_hCvarGlow.IntValue;
	g_iCvarGlowCol = GetColor(g_hCvarGlowCol);
	LockerGlow(g_bGlow);
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
	g_iCvarHint = g_hCvarHint.IntValue;
	g_iCvarRandom = g_hCvarRandom.IntValue;
	g_iCvarTimed = g_hCvarTimed.IntValue;
	g_iCvarTotal = g_hCvarTotal.IntValue;
	g_iCvarTypes = g_hCvarTypes.IntValue;
	g_iCvarGlow = g_hCvarGlow.IntValue;
	g_iCvarGlowCol = GetColor(g_hCvarGlowCol);
}

void IsAllowed()
{
	bool bCvarAllow = g_hCvarAllow.BoolValue;
	bool bAllowMode = IsAllowedGameMode();
	GetCvars();

	if( g_bCvarAllow == false && bCvarAllow == true && bAllowMode == true )
	{
		g_bCvarAllow = true;
		ResetSaveData();
		LoadFootlockers();
		HookEvents();
	}

	else if( g_bCvarAllow == true && (bCvarAllow == false || bAllowMode == false) )
	{
		g_bCvarAllow = false;
		ResetPlugin();
		UnhookEvents();
	}
}

void SpawnGameMode()
{
	int entity = CreateEntityByName("info_gamemode");
	if( entity != -1 )
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
}

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

		SpawnGameMode();

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
void HookEvents()
{
	HookEvent("round_end",				Event_RoundEnd,			EventHookMode_PostNoCopy);
	HookEvent("round_start",			Event_RoundStart,		EventHookMode_PostNoCopy);
	HookEvent("player_spawn",			Event_PlayerSpawn,		EventHookMode_PostNoCopy);
	HookEvent("item_pickup",			Event_ItemPickup,		EventHookMode_Pre);
	HookEvent("player_use",				Event_PlayerUse,		EventHookMode_Post);
}

void UnhookEvents()
{
	UnhookEvent("round_end",			Event_RoundEnd,			EventHookMode_PostNoCopy);
	UnhookEvent("round_start",			Event_RoundStart,		EventHookMode_PostNoCopy);
	UnhookEvent("player_spawn",			Event_PlayerSpawn,		EventHookMode_PostNoCopy);
	UnhookEvent("item_pickup",			Event_ItemPickup,		EventHookMode_Pre);
	UnhookEvent("player_use",			Event_PlayerUse,		EventHookMode_Post);
}

public void OnMapEnd()
{
	g_bMapStarted = false;

	ResetPlugin();

	// Versus, reset.
	if( g_iSpawnSaveMap == 6 )
	{
		g_iSpawnSaveMap = 0;
		ResetSaveData();
	}
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	// Reset on coop/survival
	if( g_iCurrentMode == 1 || g_iCurrentMode == 2 )
	{
		if( g_iSpawnSaveMap < 2 )
			g_iSpawnSaveMap = 0;
	// Versus, starting 2nd round.
	} else if( g_iSpawnSaveMap == 0 )
		g_iSpawnSaveMap = 6;

	ResetPlugin();
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
	LoadFootlockers();

	return Plugin_Continue;
}



// ====================================================================================================
//					LOAD FOOTLOCKERS
// ====================================================================================================
void LoadFootlockers()
{
	if( g_bLoaded || g_iCvarRandom == 0 ) return;

	int iRandom = g_iCvarRandom;

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
		return;

	// Load config
	KeyValues hFile = new KeyValues("footlockers");
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

	// Retrieve how many footlockers to display
	int iCount = hFile.GetNum("num", 0);
	if( iCount == 0 )
	{
		delete hFile;
		return;
	}

	// Spawn only a select few footlockers?
	int iIndexes[MAX_FOOTLOCKERS+1];
	if( iCount > MAX_FOOTLOCKERS )
		iCount = MAX_FOOTLOCKERS;


	// HardRain: Create lockers in the same place as previous maps.
	int i,iSaveCount = 0;
	if( g_iSpawnSaveMap == 3 ) // Map == c4m3
	{
		for( i = 0; i < MAX_FOOTLOCKERS; i++ )
		{
			if( g_iSpawnSaveData2[i][0] > 0 )
				iIndexes[iSaveCount++] = g_iSpawnSaveData2[i][0];
		}
		iRandom = 1;
	}
	else if( g_iSpawnSaveMap > 3 ) // Map == c4m4 / c4m5. Or 6 = Versus.
	{
		for( i = 0; i < MAX_FOOTLOCKERS; i++ )
		{
			if( g_iSpawnSaveData1[i][1] > 0 )
			{
				iIndexes[iSaveCount++] = g_iSpawnSaveData1[i][0];
			}
		}
		iRandom = 1;
	}

	if( iSaveCount == 0 )
	{
		if( iRandom == -1 || iRandom > iCount )
			iRandom = iCount;

		if( iRandom )
		{
			for( i = 0; i < iCount; i++ )
				iIndexes[i] = i+1;

			SortIntegers(iIndexes, iCount, Sort_Random);
			iCount = iRandom;
		}
	}

	// Get the footlocker origins and spawn
	char sTemp[4];
	float vPos[3], vAng[3];
	int index, iTotal, iType;

	for( i = 1; i <= iCount; i++ )
	{
		if( iRandom ) index = iIndexes[i-1];
		else index = i;

		IntToString(index, sTemp, sizeof(sTemp));

		if( hFile.JumpToKey(sTemp) )
		{
			hFile.GetVector("angle", vAng);
			hFile.GetVector("origin", vPos);
			iTotal = hFile.GetNum("total", g_iCvarTotal);
			iType = hFile.GetNum("types", g_iCvarTypes);

			if( vPos[0] == 0.0 && vPos[0] == 0.0 && vPos[0] == 0.0 ) // Should never happen.
				LogError("Error: 0,0,0 origin. Iteration=%d. Index=%d. Random=%d. Count=%d.", i, index, iRandom, iCount);
			else
				CreateLocker(vPos, vAng, iType, iTotal, 0, index);

			hFile.GoBack();
		}
	}

	delete hFile;
	g_bLoaded = true;
}



// ====================================================================================================
//					CREATE LOCKER
// ====================================================================================================
int GetLockerID()
{
	for( int i = 0; i < MAX_FOOTLOCKERS; i++ )
	{
		if( g_iFootlockers[i][0] == 0 || IsValidEntRef(g_iFootlockers[i][0]) == false )
		{
			return i;
		}
	}
	return -1;
}

void CreateLocker(const float vOrigin[3], const float vAngles[3], int iType = 63, int iTotal = 0, int iWitch = 0, int index = 0)
{
	if( g_iFootlockerCount >= MAX_FOOTLOCKERS )
		return;

	int iLockerIndex = GetLockerID();
	if( iLockerIndex == -1 )
		return;

	if( iTotal == 0 )
		iTotal = 999;

	g_iType[iLockerIndex] = iType;
	g_iTotal[iLockerIndex] = iTotal;
	g_iWitch[iLockerIndex] = iWitch;
	g_iLockerIndex[iLockerIndex] = index;


	// -------------------------------------------------------------------
	//	CREATE PROP_DYNAMIC
	// -------------------------------------------------------------------
	int entity;
	entity = CreateEntityByName("prop_dynamic");
	if( entity == -1 )
		ThrowError("Failed to create locker model.");

	int ent, parent;
	char sTemp[64];
	float vPos[3];
	vPos = vOrigin;
	parent = entity;

	g_iFootlockerCount++;

	g_iFootlockers[iLockerIndex][0] = EntIndexToEntRef(entity);
	SetEntityModel(entity, MODEL_LOCKER);
	Format(sTemp, sizeof(sTemp), "fl%d-locker", iLockerIndex);
	DispatchKeyValue(entity, "targetname", sTemp);
	DispatchKeyValue(entity, "solid", "0");
	DispatchKeyValue(entity, "fademaxdist", "1920");
	DispatchKeyValue(entity, "fademindist", "1501");
	DispatchSpawn(entity);
	TeleportEntity(entity, vPos, vAngles, NULL_VECTOR);

	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", parent);


	// Enable Glow
	if( g_iCvarGlow )
	{
		SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarGlowCol);
		SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iCvarGlow);
	}


	// -------------------------------------------------------------------
	//	HardRain: SAVE LOCKER OR OPEN LOCKER AND RETURN OR CONTINUE
	// -------------------------------------------------------------------
	// Store created lockers for return journey. Store open/close state and cfg index.
	int open, type, solid = 1;
	if( g_iSpawnSaveMap < 2 )
	{
		g_iSpawnSaveData1[iLockerIndex][0] = index;
		g_iSpawnSaveData1[iLockerIndex][1] = 1;
	}
	else if( g_iSpawnSaveMap == 2 )
	{
		g_iSpawnSaveData2[iLockerIndex][0] = index;
		g_iSpawnSaveData2[iLockerIndex][1] = 1;
	}
	// If open avoid spawning items by returning
	else if( (g_iSpawnSaveMap == 3 && g_iSpawnSaveData2[iLockerIndex][1] == 2) || (g_iSpawnSaveMap != 6 && g_iSpawnSaveMap > 3 && g_iSpawnSaveData1[iLockerIndex][1] == 2) )
	{
		SetEntProp(entity, Prop_Send, "m_nSequence", 3);
		CreateSolidLocker(vPos, vAngles, iLockerIndex);

		if( g_iSpawnSaveMap == 3 )
			type = g_iSpawnSaveData2[iLockerIndex][2];
		else
			type = g_iSpawnSaveData1[iLockerIndex][2];

		if( type == 5 ) // Delete the solid top for firework crates
			solid = 0;
		else
			solid = 2;
		open = 1;
	}


	// -------------------------------------------------------------------
	//	CREATE SOLID CRATE TOP
	// -------------------------------------------------------------------
	if( solid )
	{
		ent = CreateEntityByName("prop_dynamic_override");
		if( ent != -1 )
		{
			g_iFootlockers[iLockerIndex][4] = EntIndexToEntRef(ent);
			SetEntityModel(ent, MODEL_CRATE);
			DispatchKeyValue(ent, "solid", "6");
			DispatchKeyValue(ent, "fademaxdist", "1920");
			DispatchKeyValue(ent, "fademindist", "1501");
			DispatchKeyValue(ent, "disableshadows", "1");
			DispatchSpawn(ent);
			if( solid == 1 )
				vPos[2] += 10;
			TeleportEntity(ent, vPos, vAngles, NULL_VECTOR);
			vPos = vOrigin;
		}
	}

	if( open )
	{
		if( type == 5 ) return;
		CreateStaticModels(vPos, vAngles, iLockerIndex, type);
		vPos[2] += 5.0;
		CreateItem(vPos, vAngles, iLockerIndex, type);
		return;
	}


	// -------------------------------------------------------------------
	//	CREATE FUNC_BUTTON
	// -------------------------------------------------------------------
	if( g_iCvarTimed == 0.0 )	ent = CreateEntityByName("func_button");
	else						ent = CreateEntityByName("func_button_timed");

	if( ent != -1 )
	{
		g_iFootlockers[iLockerIndex][1] = EntIndexToEntRef(ent);
		DispatchKeyValue(ent, "glow", sTemp);
		DispatchKeyValue(ent, "rendermode", "3");

		if( g_iCvarTimed == 0.0 )
		{
			DispatchKeyValue(ent, "spawnflags", "1025");
			DispatchKeyValue(ent, "wait", "1");
			DispatchKeyValue(entity, "speed", "0");
			DispatchKeyValue(entity, "wait", "3");
		}
		else
		{
			DispatchKeyValue(ent, "spawnflags", "0");
			IntToString(g_iCvarTimed, sTemp, sizeof(sTemp));
			DispatchKeyValue(ent, "use_time", sTemp);
		}
		Format(sTemp, sizeof(sTemp), "fl%d-button_locker", iLockerIndex);
		DispatchKeyValue(ent, "targetname", sTemp);

		// Teleport then dispatch, or server receives "Inserted func_button with no model" error.
		// Also server may crash on some entities probably related to the above error when using Dispatch before Teleport.
		// See Footlocker main post and: https://forums.alliedmods.net/showpost.php?p=2568404&postcount=17
		TeleportEntity(ent, vPos, vAngles, NULL_VECTOR);
		DispatchSpawn(ent);
		AcceptEntityInput(ent, "Enable");

		float vMins[3];
		float vMaxs[3];
		vMins = view_as<float>({-14.0, -25.0, -12.0});
		vMaxs = view_as<float>({13.0, 25.0, 12.0});
		SetEntPropVector(ent, Prop_Send, "m_vecMins", vMins);
		SetEntPropVector(ent, Prop_Send, "m_vecMaxs", vMaxs);
		SetEntProp(entity, Prop_Send, "m_nSolidType", 0, 1);
		SetEntProp(entity, Prop_Send, "m_usSolidFlags", 4, 2);

		if( g_iCvarTimed == 0 )
		{
			SetVariantString("OnPressed !self:Kill::0.1:1");
			AcceptEntityInput(ent, "AddOutput");

			Format(sTemp, sizeof(sTemp), "OnPressed fl%d-locker:SetAnimation:opening:0:1", iLockerIndex);
			SetVariantString(sTemp);
			AcceptEntityInput(ent, "AddOutput");

			Format(sTemp, sizeof(sTemp), "OnPressed fl%d-game_event:FireEvent::0:1", iLockerIndex);
			SetVariantString(sTemp);
			AcceptEntityInput(ent, "AddOutput");
		}
		else
		{
			SetVariantString("OnTimeUp !self:Kill::0.1:1");
			AcceptEntityInput(ent, "AddOutput");

			Format(sTemp, sizeof(sTemp), "OnTimeUp fl%d-locker:SetAnimation:opening:0:1", iLockerIndex);
			SetVariantString(sTemp);
			AcceptEntityInput(ent, "AddOutput");

			Format(sTemp, sizeof(sTemp), "OnTimeUp fl%d-game_event:FireEvent::0:1", iLockerIndex);
			SetVariantString(sTemp);
			AcceptEntityInput(ent, "AddOutput");
		}

		// SetVariantString("OnPressed orator:SpeakResponseConcept:WorldFootLocker:0:1");
		// AcceptEntityInput(ent, "AddOutput");
	}


	// -------------------------------------------------------------------
	//	HOOK ANIMATION, SPAWN ITEMS
	// -------------------------------------------------------------------
	if( g_iCvarTimed == 0 )
		HookSingleEntityOutput(entity, "OnAnimationBegun", OnAnimationBegun, true);
	else
		HookSingleEntityOutput(ent, "OnTimeUp", OnTimeUp, true);


	// -------------------------------------------------------------------
	//	CREATE LOGIC_GAME_EVENT
	// -------------------------------------------------------------------
	ent = CreateEntityByName("logic_game_event");
	if( ent != -1 )
	{
		g_iFootlockers[iLockerIndex][2] = ent;
		Format(sTemp, sizeof(sTemp), "fl%d-game_event", iLockerIndex);
		DispatchKeyValue(ent, "targetname", sTemp);
		DispatchKeyValue(ent, "spawnflags", "1");
		DispatchKeyValue(ent, "eventName", "foot_locker_opened");
		DispatchSpawn(ent);
		TeleportEntity(ent, vPos, vAngles, NULL_VECTOR);
	}


	// -------------------------------------------------------------------
	//	CREATE INFO_REMARKABLE
	// -------------------------------------------------------------------
	if( g_hCvarVoca.BoolValue )
	{
		ent = CreateEntityByName("info_remarkable");
		if( ent != -1 )
		{
			g_iFootlockers[iLockerIndex][3] = EntIndexToEntRef(ent);
			DispatchKeyValue(ent, "contextsubject", "WorldFootLocker");
			DispatchSpawn(ent);
			vPos = vOrigin;
			vPos[2] += 10.0;
			TeleportEntity(ent, vPos, vAngles, NULL_VECTOR);
		}
	}
}



// ====================================================================================================
//					SPAWN SOME ITEMS
// ====================================================================================================
int CreateSolidLocker(const float vOrigin[3], const float vAng[3], int index)
{
	int entity = CreateEntityByName("prop_dynamic");
	if( entity != -1 )
	{
		g_iFootlockers[index][5] = EntIndexToEntRef(entity);
		SetEntityModel(entity, MODEL_LOCKER2);
		DispatchKeyValue(entity, "solid", "6");
		SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
		SetEntityRenderColor(entity, 255, 255, 255, 0);
		DispatchSpawn(entity);
		float vPos[3];
		vPos = vOrigin;
		vPos[2] -= 2.0;
		TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		return entity;
	}
	return -1;
}

void CreateStaticModels(const float vOrigin[3], const float vAngles[3], int index, int iType)
{
	float vAng[3], vPos[3];
	int entity;

	for( int i = 0; i < 10; i++ )
	{
		vPos = vOrigin;
		vAng = vAngles;

		if( i <= 4 )
		{
			MoveForward(vPos, vAng, vPos, 4.5);
			MoveSideway(vPos, vAng, vPos, (i - 2) * 7.0);
		}
		else
		{
			MoveForward(vPos, vAng, vPos, -4.5);
			MoveSideway(vPos, vAng, vPos, (i - 7) * 7.0);
		}

		vAng[1] = GetRandomFloat(0.0, 360.0);
		if( iType != 3 )
		{
			vAng[2] += 90.0;
			vPos[2] += 2.0;
		}
		else
			vPos[2] += 4.0;

		entity = CreateEntityByName("prop_dynamic_override");
		if( entity != -1 )
		{
			g_iFootlockers[index][6+i] = EntIndexToEntRef(entity);
			SetEntityModel(entity, g_sItems[iType]);
			DispatchKeyValue(entity, "spawnflags", "0");
			DispatchKeyValue(entity, "solid", "0");
			DispatchKeyValue(entity, "disableshadows", "1");
			DispatchSpawn(entity);
			TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
		}
	}
}



// ====================================================================================================
//					OPEN LOCKER
// ====================================================================================================
void OnTimeUp(const char[] output, int caller, int activator, float delay)
{
	OnSpawn(caller, activator, true);
}

void OnAnimationBegun(const char[] output, int caller, int activator, float delay)
{
	OnSpawn(caller, activator, false);
}

void OnSpawn(int caller, int activator, bool bTime = false)
{
	int entity;

	for( int i = 0; i < MAX_FOOTLOCKERS; i++ )
	{
		if( bTime )
			entity = g_iFootlockers[i][1];
		else
			entity = g_iFootlockers[i][0];

		if( EntRefToEntIndex(entity) == caller )
		{
			if( g_iCvarGlow )
				AcceptEntityInput(caller, "StopGlowing");

			float vPos[3], vAng[3];
			GetEntPropVector(caller, Prop_Data, "m_vecOrigin", vPos);
			GetEntPropVector(caller, Prop_Data, "m_angRotation", vAng);
			SpawnItems(vPos, vAng, i);

			if( g_iCvarHint )
			{
				if( activator >= 1 && activator <= MaxClients && IsClientInGame(activator) )
					PrintToChatAll("\x04[\x05Footlocker\x04] \x01opened by \x04%N\x01.", activator);
				else
					PrintToChatAll("\x04[\x05Footlocker\x04] \x01opened.");
			}

			break;
		}
	}
}

void SpawnItems(const float vOrigin[3], const float vAngles[3], int index)
{
	float vPos[3], vAng[3];
	int iType = -1 ;

	if( g_iSpawnSaveMap == 3 )
		iType = g_iSpawnSaveData2[index][2];
	else if( g_iSpawnSaveMap > 3 )
		iType = g_iSpawnSaveData1[index][2];



	// -------------------------------------------------------------------
	//	LOCKER OPEN SOUND
	// -------------------------------------------------------------------
	EmitAmbientSound(SOUND_OPEN, vOrigin, g_iFootlockers[index][0]);



	// -------------------------------------------------------------------
	//	ITEM TYPE
	// -------------------------------------------------------------------
	// Get type for opened locker, the same for each team in versus, or new in coop, or the same on return journey of Hard Rain.
	if( iType == -1 )
	{
		iType = g_iType[index];
		if( iType < 1 )
		{
			iType = g_iCvarTypes;
		}

		int iCount, iArray[6];

		if( TYPE_MOLOTOV & iType )		iArray[iCount++] = 0;
		if( TYPE_PIPEBOMB & iType )		iArray[iCount++] = 1;
		if( TYPE_VOMITJAR & iType )		iArray[iCount++] = 2;
		if( TYPE_ADRENALINE & iType )	iArray[iCount++] = 3;
		if( TYPE_PAINPILLS & iType )	iArray[iCount++] = 4;
		if( TYPE_FIREWORKS & iType )	iArray[iCount++] = 5;

		int iRandom = GetRandomInt(0, iCount -1);
		iType = iArray[iRandom];
	}



	// -------------------------------------------------------------------
	//	VOCALIZE
	// -------------------------------------------------------------------
	if( g_hCvarVoca.BoolValue )
	{
		int client; float fDistance; float fDist = 250.0;
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 )
			{
				GetClientAbsOrigin(i, vPos);
				fDistance = GetVectorDistance(vPos, vOrigin);
				if( fDistance < fDist )
				{
					fDist = fDistance;
					client = i;
				}
			}
		}

		if( client )
			VocalizeScene(client);
	}


	// -------------------------------------------------------------------
	//	CREATE SOLID LOCKER
	// -------------------------------------------------------------------
	int entity = CreateSolidLocker(vOrigin, vAngles, index);


	// -------------------------------------------------------------------
	//	TELEPORT STUCK PLAYERS
	// -------------------------------------------------------------------
	if( entity != -1 )
	{
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);
		CreateTimer(0.2, TimerSolidCollision, EntIndexToEntRef(entity));

		float vDir[3];
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2 )
			{
				GetClientAbsOrigin(i, vPos);
				if( GetVectorDistance(vPos, vOrigin) < 35.0 )
				{
					GetClientAbsAngles(i, vAng);
					MoveForward(vPos, vAng, vPos, 5.0);
					GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
					vDir[0] *= -50.0;
					vDir[1] *= -50.0;
					vDir[2] = 150.0;
					vPos[2] += 2.0;
					TeleportEntity(i, vPos, NULL_VECTOR, vDir);
				}
			}
		}
	}


	// -------------------------------------------------------------------
	//	CREATE WITCH?
	// -------------------------------------------------------------------
	int iWitch = g_iWitch[index];
	if( iWitch == 0 )
	{
		iWitch = g_hCvarWitch.IntValue;
		if( iWitch )
			iWitch = GetRandomInt(1, iWitch);
	}
	if( iWitch == 1 )
	{
		// Create witch
		entity = CreateEntityByName("witch");
		if( entity != -1 )
		{
			vPos = vOrigin;
			vPos[2] += 30.0;
			MoveForward(vPos, vAngles, vPos, -20.0);
			TeleportEntity(entity, vPos, vAngles, NULL_VECTOR);

			SetEntPropFloat(entity, Prop_Send, "m_rage", 0.5); // Rage!!
			SetEntProp(entity, Prop_Data, "m_nSequence", 4); // Sit
			DispatchSpawn(entity);

			SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);
			CreateTimer(0.3, TimerSolidCollision, EntIndexToEntRef(entity));
		}
	}


	// -------------------------------------------------------------------
	//	CREATE FIREWORKS
	// -------------------------------------------------------------------
	else if( iType == 5 )
	{
		for( int i = 0; i < 8; i++ )
		{
			vPos = vOrigin;
			vAng = vAngles;
			MoveSideway(vPos, vAng, vPos, (i - 3.5) * 5.8);
			vPos[2] -= 2.0;
			vAng[2] += 90.0;

			entity = CreateEntityByName("prop_physics");
			if( entity != -1 )
			{
				g_iFootlockers[index][6+i] = EntIndexToEntRef(entity);
				SetEntityModel(entity, g_sItems[5]);
				DispatchKeyValue(entity, "disableshadows", "1");
				DispatchKeyValue(entity, "spawnflags", "1"); // Prevent moving
				DispatchSpawn(entity);
				TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
				SetEntProp(entity, Prop_Data, "m_takedamage", 0); // Block damage
			}
		}
	}

	// HardRain: Save open/close state for locker spawn on return journey.
	if( g_iSpawnSaveMap < 2 )
	{
		if( g_iSpawnSaveMap == 1 )				// Only saving if the box is Open for Hard Rain, g_iSpawnSaveMap 0 is for Versus saving items for round 2, only using SaveData1 array, not 2.
			g_iSpawnSaveData1[index][1] = 2;
		g_iSpawnSaveData1[index][2] = iType;
	}
	else if( g_iSpawnSaveMap == 2 )
	{
		g_iSpawnSaveData2[index][1] = 2;
		g_iSpawnSaveData2[index][2] = iType;
	}


	// -------------------------------------------------------------------
	//	REMOVE SOLID CRATE TOP AND RETURN
	// -------------------------------------------------------------------
	if( iWitch == 1 ) // Delete solid crate top when spawning a locker which contained a witch
		iType = 5;

	if( iType == 5 ) // fireworks / witch
	{
		// Delete the solid crate top
		if( IsValidEntRef(g_iFootlockers[index][4]) )
		{
			RemoveEntity(g_iFootlockers[index][4]);
			g_iFootlockers[index][4] = 0;
		}
		return;
	}


	// -------------------------------------------------------------------
	//	LOWER THE SOLID CRATE TOP
	// -------------------------------------------------------------------
	if( IsValidEntRef(g_iFootlockers[index][4]) )
	{
		vPos = vOrigin;
		vPos[2] -= 1;
		if( iType == 3 )
			vPos[2] += 3.0;
		TeleportEntity(g_iFootlockers[index][4], vPos, NULL_VECTOR, NULL_VECTOR);
	}


	// -------------------------------------------------------------------
	//	CREATE STATIC MODELS
	// -------------------------------------------------------------------
	CreateStaticModels(vOrigin, vAngles, index, iType);


	// -------------------------------------------------------------------
	//	CREATE ITEM
	// -------------------------------------------------------------------
	vPos = vOrigin;
	vAng = vAngles;
	vPos[2] += 5.0;

	CreateItem(vPos, vAng, index, iType);
}

void CreateItem(float vPos[3], const float vAng[3], int index, int iType)
{
	int entity = CreateEntityByName(g_sWeapons[iType]);
	if( entity != -1 )
	{
		float vAngles[3];
		vAngles = vAng;
		g_iFootlockers[index][MAX_ENT_STORE-1] = EntIndexToEntRef(entity);
		if( iType != 3 ) // Adrenaline
			vAngles[2] += 90.0;

		DispatchKeyValue(entity, "disableshadows", "1");
		DispatchSpawn(entity);
		TeleportEntity(entity, vPos, vAngles, NULL_VECTOR);
		SetEntityMoveType(entity, MOVETYPE_PUSH);

		g_vItemOrigin[index] = vPos;
		g_vItemAngles[index] = vAngles;
	}
}

Action TimerSolidCollision(Handle timer, any entity)
{
	if( EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
	{
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);
	}

	return Plugin_Continue;
}



// ======================================================================================
//					ITEM PICKUP EVENTS
// ======================================================================================
// Client picked up an item. This event fires before the one below.
int g_iClientPickup[MAXPLAYERS+1];
void Event_ItemPickup(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if( !client || !IsClientInGame(client) ) return;

	if( IsFakeClient(client) )
	{
		g_iClientPickup[client] = 1;
		return;
	}

	int slot2 = GetPlayerWeaponSlot(client, 2);
	int slot4 = GetPlayerWeaponSlot(client, 4);

	if( slot2 == -1 && slot4 == -1 )
		return;

	int entity;

	for( int i = 0; i < MAX_FOOTLOCKERS; i++ )
	{
		entity = g_iFootlockers[i][MAX_ENT_STORE-1];
		if( entity && (entity = EntRefToEntIndex(entity)) != INVALID_ENT_REFERENCE )
		{
			if( slot2 == entity || slot4 == entity ) // They picked up an item from the footlockers.
			{
				DupeItem(entity, i);
				return;
			}
		}
	}
}

void Event_PlayerUse(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	int target = event.GetInt("targetid");

	if( g_iClientPickup[client] == 1 && IsFakeClient(client) && IsValidEntity(target) )
	{
		int entity = EntIndexToEntRef(target);

		for( int i = 0; i < MAX_FOOTLOCKERS; i++ )
		{
			if( g_iFootlockers[i][MAX_ENT_STORE-1] == entity ) // They picked up an item from the footlockers.
			{
				if( g_iTotal[i] == 999 || g_iTotal[i]-- > 1 ) // The count is higher than 0, re-create the item.
				{
					DupeItem(entity, i);
					return;
				}
			}
		}
	}

	g_iClientPickup[client] = 0;
}

void DupeItem(int entity, int index)
{
	if( g_iTotal[index] == 999 || g_iTotal[index]-- > 1 ) // The count is higher than 0, re-create the item.
	{
		char sTemp[32];
		float vPos[3], vAng[3];
		GetEdictClassname(entity, sTemp, sizeof(sTemp));
		vPos = g_vItemOrigin[index];
		vAng = g_vItemAngles[index];

		int ent = CreateEntityByName(sTemp);
		g_iFootlockers[index][MAX_ENT_STORE-1] = EntIndexToEntRef(ent);

		DispatchKeyValue(ent, "disableshadows", "1");
		DispatchSpawn(ent);
		TeleportEntity(ent, vPos, vAng, NULL_VECTOR);
		SetEntityMoveType(ent, MOVETYPE_PUSH);
	}
	else
	{
		g_iFootlockers[index][MAX_ENT_STORE-1] = 0;
	}
}



// Modified from:
// [Tech Demo] L4D2 Vocalize ANYTHING
// https://forums.alliedmods.net/showthread.php?t=122270
// author = "AtomicStryker"
// ======================================================================================
//					VOCALIZE
// ======================================================================================
void VocalizeScene(int client)
{
	int iMin = 1, iMax, iRandom;
	char sTemp[48];
	GetEntPropString(client, Prop_Data, "m_ModelName", sTemp, sizeof(sTemp));

	switch( sTemp[29] )
	{
		case 'c':		// Coach
		{
			iMin = 3;
			iMax = 5;
		}
		case 'b':		// Gambler
		{
			iMax = 6;
		}
		case 'h':		// Mechanic
		{
			iRandom = GetRandomInt(0, 2);
			if( iRandom ) // Avoid number 6 because he says "empty"
				iRandom = GetRandomInt(2, 5);
			else
				iRandom = GetRandomInt(7, 9);
		}
		case 'd':		// Producer
		{
			iRandom = GetRandomInt(0, 1);
			if( iRandom ) // Avoid number 3 because she says "empty"
				iRandom = GetRandomInt(1, 2);
			else
				iRandom = GetRandomInt(4, 5);
		}
		default:
		{
			return;
		}
	}

	ReplaceStringEx(sTemp, sizeof(sTemp), ".mdl", "");

	if( iMax )
		iRandom = GetRandomInt(iMin, iMax);
	Format(sTemp, sizeof(sTemp), "scenes/%s/dlc1_footlocker0%d.vcd", sTemp[26], iRandom);

	int tempent = CreateEntityByName("instanced_scripted_scene");
	DispatchKeyValue(tempent, "SceneFile", sTemp);
	DispatchSpawn(tempent);
	SetEntPropEnt(tempent, Prop_Data, "m_hOwner", client);
	ActivateEntity(tempent);
	AcceptEntityInput(tempent, "Start", client, client);
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
//					sm_locker
// ====================================================================================================
Action CmdLockerTemp(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Footlocker] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}
	else if( g_iFootlockerCount >= MAX_FOOTLOCKERS )
	{
		PrintToChat(client, "%sError: Cannot add anymore footlockers. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iFootlockerCount, MAX_FOOTLOCKERS);
		return Plugin_Handled;
	}

	float vPos[3], vAng[3];
	if( !SetTeleportEndPoint(client, vPos, vAng) )
	{
		PrintToChat(client, "%sCannot place footlocker, please try again.", CHAT_TAG);
		return Plugin_Handled;
	}

	if( args == 1 )
	{
		char sBuff[4];
		GetCmdArg(1, sBuff, sizeof(sBuff));
		if( sBuff[0] == 'w' )
			CreateLocker(vPos, vAng, 0, 0, 1);
		else
			CreateLocker(vPos, vAng, StringToInt(sBuff));
	}
	else if( args == 2 )
	{
		char sBuff[4], sBuff2[4];
		GetCmdArg(1, sBuff, sizeof(sBuff));
		GetCmdArg(2, sBuff2, sizeof(sBuff2));
		CreateLocker(vPos, vAng, StringToInt(sBuff), StringToInt(sBuff2));
	}
	else
	{
		CreateLocker(vPos, vAng, g_iCvarTypes);
	}

	PrintToChat(client, "%s%s", CHAT_TAG, CHAT_USAGE);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_lockersave
// ====================================================================================================
Action CmdLockerSave(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Footlocker] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}
	else if( g_iFootlockerCount >= MAX_FOOTLOCKERS )
	{
		PrintToChat(client, "%sError: Cannot add anymore footlockers. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iFootlockerCount, MAX_FOOTLOCKERS);
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
	KeyValues hFile = new KeyValues("footlockers");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot read the footlocker config, assuming empty file. (\x05%s\x01).", CHAT_TAG, sPath);
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if( !hFile.JumpToKey(sMap, true) )
	{
		PrintToChat(client, "%sError: Failed to add map to footlocker spawn config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many footlockers are saved
	int iCount = hFile.GetNum("num", 0);
	if( iCount >= MAX_FOOTLOCKERS )
	{
		PrintToChat(client, "%sError: Cannot add anymore footlockers. Used: (\x05%d/%d\x01).", CHAT_TAG, iCount, MAX_FOOTLOCKERS);
		delete hFile;
		return Plugin_Handled;
	}

	// Set player position as footlocker spawn location
	float vPos[3], vAng[3];
	if( !SetTeleportEndPoint(client, vPos, vAng) )
	{
		PrintToChat(client, "%sCannot place footlocker, please try again.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Save count
	iCount++;
	hFile.SetNum("num", iCount);

	// Save angle / origin
	char sTemp[4], sBuff[4];

	IntToString(iCount, sTemp, sizeof(sTemp));
	if( hFile.JumpToKey(sTemp, true) )
	{
		hFile.SetVector("angle", vAng);
		hFile.SetVector("origin", vPos);

		int num1, num2;
		if( args == 1 )
		{
			GetCmdArg(1, sBuff, sizeof(sBuff));
			num1 = StringToInt(sBuff);
			hFile.SetNum("types", num1);
			CreateLocker(vPos, vAng, num1, g_iCvarTotal, _, iCount);
		}
		else if( args == 2 )
		{
			char sBuff2[4];
			GetCmdArg(1, sBuff, sizeof(sBuff));
			GetCmdArg(2, sBuff2, sizeof(sBuff2));
			num1 = StringToInt(sBuff);
			num2 = StringToInt(sBuff2);
			hFile.SetNum("types", num1);
			hFile.SetNum("total", num2);
			CreateLocker(vPos, vAng, num1, num2, _, iCount);
		}
		else
		{
			CreateLocker(vPos, vAng, g_iCvarTypes, g_iCvarTotal, _, iCount);
		}

		// Save cfg
		hFile.Rewind();
		hFile.ExportToFile(sPath);

		PrintToChat(client, "%s(\x05%d/%d\x01) - Saved at pos:[\x05%f %f %f\x01] ang:[\x05%f %f %f\x01]", CHAT_TAG, iCount, MAX_FOOTLOCKERS, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to save Footlocker", CHAT_TAG, iCount, MAX_FOOTLOCKERS);

	delete hFile;

	// Create footlocker
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_lockerdel
// ====================================================================================================
Action CmdLockerDelete(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[SM] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Footlocker] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	int entity = GetClientAimTarget(client, false);
	if( entity == -1 ) return Plugin_Handled;
	entity = EntIndexToEntRef(entity);

	int index = -1; bool bDel;
	if( entity != -1 )
	{
		for( int i = 0; i < MAX_FOOTLOCKERS; i++ )
		{
			for( int u = 0; u < MAX_ENT_STORE; u++ )
			{
				if( g_iFootlockers[i][u] == entity )
				{
					index = i;
					bDel = true;
				}
			}
			if( bDel ) break;
		}
	}

	if( index == -1 )
		return Plugin_Handled;

	int cfgindex = g_iLockerIndex[index];
	g_iFootlockerCount--;

	if( cfgindex == 0 )
	{
		RemoveLocker(index);
		g_iSpawnSaveData1[index][0] = 0;
		g_iSpawnSaveData1[index][1] = 0;
		g_iSpawnSaveData1[index][2] = -1;
		g_iSpawnSaveData2[index][0] = 0;
		g_iSpawnSaveData2[index][1] = 0;
		g_iSpawnSaveData2[index][2] = -1;
		PrintToChat(client, "%sDeleted locker from the map. Locker was saved to the config.", CHAT_TAG);
		return Plugin_Handled;
	}

	// Load config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the footlocker config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	KeyValues hFile = new KeyValues("footlockers");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the footlocker config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the footlocker config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many footlockers
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
				RemoveLocker(index);
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
		for( int i = 0; i < MAX_FOOTLOCKERS; i++ )
		{
			if( g_iLockerIndex[i] > cfgindex )
				g_iLockerIndex[i]--;
		}

		iCount--;
		hFile.SetNum("num", iCount);

		// Save to file
		hFile.Rewind();
		hFile.ExportToFile(sPath);

		PrintToChat(client, "%s(\x05%d/%d\x01) - Footlocker removed from config.", CHAT_TAG, iCount, MAX_FOOTLOCKERS);
	}
	else
	PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to remove Footlocker from config.", CHAT_TAG, iCount, MAX_FOOTLOCKERS);

	delete hFile;
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_lockerwipe
// ====================================================================================================
Action CmdLockerWipe(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Footlocker] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the footlocker config (\x05%s\x01).", CHAT_TAG, sPath);
		return Plugin_Handled;
	}

	// Load config
	KeyValues hFile = new KeyValues("footlockers");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the footlocker config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap, false) )
	{
		PrintToChat(client, "%sError: Current map not in the footlocker config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	hFile.DeleteThis();
	ResetPlugin();

	// Save to file
	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	PrintToChat(client, "%s(0/%d) - All footlockers removed from config, add new footlockers with \x05sm_lockersave\x01.", CHAT_TAG, MAX_FOOTLOCKERS);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_lockerclear
// ====================================================================================================
Action CmdLockerClear(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Footlocker] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	ResetPlugin();

	PrintToChat(client, "%s(0/%d) - All footlockers removed from the map", CHAT_TAG, MAX_FOOTLOCKERS);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_lockerglow / sm_lockerlist / sm_lockertele
// ====================================================================================================
Action CmdLockerGlow(int client, int args)
{
	g_bGlow = !g_bGlow;
	PrintToChat(client, "%sGlow has been turned %s", CHAT_TAG, g_bGlow ? "on" : "off");

	LockerGlow(g_bGlow);
	return Plugin_Handled;
}

void LockerGlow(int glow)
{
	int entity;

	for( int i = 0; i < MAX_FOOTLOCKERS; i++ )
	{
		entity = g_iFootlockers[i][0];
		if( IsValidEntRef(entity) )
		{
			SetEntProp(entity, Prop_Send, "m_iGlowType", 3);
			SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarGlowCol);
			SetEntProp(entity, Prop_Send, "m_nGlowRange", glow ? 0 : g_iCvarGlow);
			if( glow )
				AcceptEntityInput(entity, "StartGlowing");
			else if( !glow && !g_iCvarGlow )
				AcceptEntityInput(entity, "StopGlowing");
		}
	}
}

Action CmdLockerList(int client, int args)
{
	float vPos[3];
	int count;

	for( int i = 0; i < MAX_FOOTLOCKERS; i++ )
	{
		if( IsValidEntRef(g_iFootlockers[i][0]) )
		{
			count++;
			GetEntPropVector(g_iFootlockers[i][0], Prop_Data, "m_vecOrigin", vPos);
			if( client == 0 )
				ReplyToCommand(client, "[Footlocker] %d) %f %f %f", i+1, vPos[0], vPos[1], vPos[2]);
			else
				PrintToChat(client, "%s%d) %f %f %f", CHAT_TAG, i+1, vPos[0], vPos[1], vPos[2]);
		}
	}

	if( client == 0 )
		ReplyToCommand(client, "[Footlocker] Total: %d/%d.", count, MAX_FOOTLOCKERS);
	else
		PrintToChat(client, "%sTotal: %d/%d.", CHAT_TAG, count, MAX_FOOTLOCKERS);
	return Plugin_Handled;
}

Action CmdLockerTele(int client, int args)
{
	if( args == 1 )
	{
		float vPos[3];
		char arg[4];
		GetCmdArg(1, arg, sizeof(arg));
		int index = StringToInt(arg) - 1;
		if( index > 0 && IsValidEntRef(g_iFootlockers[index][0]) )
		{
			GetEntPropVector(g_iFootlockers[index][0], Prop_Data, "m_vecOrigin", vPos);
			vPos[2] += 30.0;
			TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
			PrintToChat(client, "%sTeleported.", CHAT_TAG);
			return Plugin_Handled;
		}

		PrintToChat(client, "%sCould not find index for teleportation.", CHAT_TAG);
	}
	else
		PrintToChat(client, "%sUsage: sm_lockertele <index 1-%d>.", CHAT_TAG, MAX_FOOTLOCKERS);
	return Plugin_Handled;
}



// ====================================================================================================
//					MENU ANGLE
// ====================================================================================================
Action CmdLockerAng(int client, int args)
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

		for( int i = 0; i < MAX_FOOTLOCKERS; i++ )
		{
			for( int u = 0; u < MAX_ENT_STORE; u++ )
			{
				entity = g_iFootlockers[i][u];

				if( entity == aim )
				{
					entity = g_iFootlockers[i][0];
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
}

// ====================================================================================================
//					MENU ORIGIN
// ====================================================================================================
Action CmdLockerPos(int client, int args)
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

		for( int i = 0; i < MAX_FOOTLOCKERS; i++ )
		{
			for( int u = 0; u < MAX_ENT_STORE; u++ )
			{
				entity = g_iFootlockers[i][u];

				if( entity == aim )
				{
					entity = g_iFootlockers[i][0];
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
}

void SaveData(int client)
{
	int entity, index;
	int aim = GetClientAimTarget(client, false);
	if( aim == -1 )
		return;

	aim = EntIndexToEntRef(aim);

	for( int i = 0; i < MAX_FOOTLOCKERS; i++ )
	{
		for( int u = 0; u < MAX_ENT_STORE; u++ )
		{
			entity = g_iFootlockers[i][u];

			if( entity == aim )
			{
				entity = g_iFootlockers[i][0];
				index = g_iLockerIndex[i];
				break;
			}
		}

		if( index ) break;
	}

	if( index == 0 )
		return;

	// Load config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the footlocker config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return;
	}

	KeyValues hFile = new KeyValues("footlockers");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the footlocker config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the footlocker config.", CHAT_TAG);
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
		g_hMenuAng.SetTitle("Set Angle.");
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
		g_hMenuPos.SetTitle("Set Origin");
		g_hMenuPos.ExitButton = true;
	}
}



// ====================================================================================================
//					STUFF
// ====================================================================================================
bool IsValidEntRef(int iEnt)
{
	if( iEnt && EntRefToEntIndex(iEnt) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}

void ResetPlugin()
{
	g_bGlow = false;
	g_bLoaded = false;
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
	g_iFootlockerCount = 0;

	for( int i = 0; i < MAX_FOOTLOCKERS; i++ )
		RemoveLocker(i);
}

void RemoveLocker(int index)
{
	int i, entity;
	for( i = 0; i < MAX_ENT_STORE; i++ )
	{
		entity = g_iFootlockers[index][i];
		g_iFootlockers[index][i] = 0;

		if( IsValidEntRef(entity) )
			RemoveEntity(entity);
	}

	g_iType[index] = 0;
	g_iTotal[index] = 0;
	g_iWitch[index] = 0;
}



// ====================================================================================================
//					POSITION
// ====================================================================================================
void MoveForward(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance)
{
	fDistance *= -1.0;
	float vDir[3];
	GetAngleVectors(vAng, vDir, NULL_VECTOR, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
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
		TR_GetPlaneNormal(trace, vNorm);
		GetVectorAngles(vNorm, vAng);
		if( vNorm[2] == 1.0 )
		{
			vPos[2] += 12.0;
			vAng[0] = 0.0;
			vAng[1] = 180.0 + degrees;
		}
		else
		{
			if( degrees > vAng[1] )
				degrees = vAng[1] - degrees;
			else
				degrees = degrees - vAng[1];
			vPos[2] += 10.5;
			vAng[0] += 90.0;
			RotateYaw(vAng, degrees + 180);
		}
	}
	else
	{
		delete trace;
		return false;
	}

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
	GetAngleVectors( angles, direction, NULL_VECTOR, normal );

	float sin = Sine( degree * 0.01745328 );	 // Pi/180
	float cos = Cosine( degree * 0.01745328 );
	float a = normal[0] * sin;
	float b = normal[1] * sin;
	float c = normal[2] * sin;
	float x = direction[2] * b + direction[0] * cos - direction[1] * c;
	float y = direction[0] * c + direction[1] * cos - direction[2] * a;
	float z = direction[1] * a + direction[2] * cos - direction[0] * b;
	direction[0] = x;
	direction[1] = y;
	direction[2] = z;

	GetVectorAngles( direction, angles );

	float up[3];
	GetVectorVectors( direction, NULL_VECTOR, up );

	float roll = GetAngleBetweenVectors( up, normal, direction );
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
	NormalizeVector( direction, direction_n );
	NormalizeVector( vector1, vector1_n );
	NormalizeVector( vector2, vector2_n );
	float degree = ArcCosine( GetVectorDotProduct( vector1_n, vector2_n ) ) * 57.29577951;   // 180/Pi
	GetVectorCrossProduct( vector1_n, vector2_n, cross );

	if( GetVectorDotProduct( cross, direction_n ) < 0.0 )
		degree *= -1.0;

	return degree;
}