/*
*	Gun Cabinet
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



#define PLUGIN_VERSION 		"1.8"

/*======================================================================================
	Plugin Info:

*	Name	:	[L4D & L4D2] Gun Cabinet
*	Author	:	SilverShot
*	Descrp	:	Spawns a gun cabinet with various weapons and items of your choosing.
*	Link	:	https://forums.alliedmods.net/showthread.php?t=222931
*	Plugins	:	https://sourcemod.net/plugins.php?exact=exact&sortby=title&search=1&author=Silvers

========================================================================================
	Change Log:

1.8 (11-Dec-2022)
	- Changes to fix compile warnings on SourceMod 1.11.
	- Now the solid sections are attached to the Gun Cabinet.

1.7 (10-Apr-2021)
	- Fixed conflict with "ConVars Anomaly Fixer" plugin causing errors. Thanks to "Dragokas" for reporting.

1.6 (21-Jun-2020)
	- Fixed Grenade Launcher and Chainsaw Ammo being reversed. Thanks to "AceTech" for fixing.

1.5 (10-May-2020)
	- Blocked glow command from L4D1 which does not support glows.
	- Extra checks to prevent "IsAllowedGameMode" throwing errors.
	- Various changes to tidy up code.

1.4 (01-Apr-2020)
	- Fixed "IsAllowedGameMode" from throwing errors when the "_tog" cvar was changed before MapStart.

1.3 (21-Jul-2018)
	- Fixed errors in L4D1 due to glow not being supported. Thanks to "Dragokas" for reporting.

1.2 (05-May-2018)
	- Converted plugin source to the latest syntax utilizing methodmaps. Requires SourceMod 1.8 or newer.
	- Changed cvar "l4d_gun_cabinet_modes_tog" now supports L4D1.

1.1 (20-Nov-2015)
	- Fixed Auto Shotgun ammo in L4D1 not filling.

1.0 (09-Aug-2013)
	- Initial release.

========================================================================================
	Thanks:

	This plugin was made using source code from the following plugins.
	If I have used your code and not credited you, please let me know.

*	"Zuko & McFlurry" for "[L4D2] Weapon/Zombie Spawner" - Modified SetTeleportEndPoint function.
	https://forums.alliedmods.net/showthread.php?t=109659

*	Thanks to "Boikinov" for "[L4D] Left FORT Dead builder" - RotateYaw function to rotate ground flares
	https://forums.alliedmods.net/showthread.php?t=93716

======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS			FCVAR_NOTIFY
#define CHAT_TAG			"\x04[\x05Gun Cabinet\x04] \x01"
#define CONFIG_SPAWNS		"data/l4d_gun_cabinet.cfg"
#define CONFIG_WEAPONS		"data/l4d_gun_cabinet_presets.cfg"
#define MAX_SPAWNS			5
#define MAX_DOORS			4
#define	MAX_WEAPONS			10
#define	MAX_WEAPONS2		29
#define	MAX_PRESETS			7
#define	MAX_SLOTS			16
#define	MODEL_CABINET		"models/props_unique/guncabinet01_main.mdl"
#define	MODEL_CRATE			"models/props_crates/supply_crate02_gib2.mdl"


ConVar g_hCvarAllow, g_hCvarCSS, g_hCvarGlow, g_hCvarGlowCol, g_hCvarMPGameMode, g_hCvarMaxGun, g_hCvarMaxItem, g_hCvarMaxPistol, g_hCvarModes, g_hCvarModesOff, g_hCvarModesTog, g_hCvarRandom;
int g_iCvarCSS, g_iCvarGlow, g_iCvarGlowCol, g_iCvarMaxGun, g_iCvarMaxItem, g_iCvarMaxPistol, g_iCvarRandom, g_iDoors[MAX_SPAWNS][MAX_DOORS], g_iPlayerSpawn, g_iPresets[MAX_PRESETS][MAX_SLOTS], g_iRoundStart, g_iSpawnCount, g_iSpawns[MAX_SPAWNS][MAX_SLOTS+2];
Menu g_hMenuAng, g_hMenuList, g_hMenuPos;
bool g_bCvarAllow, g_bMapStarted, g_bLeft4Dead2, g_bLoaded;

ConVar g_hAmmoAutoShot, g_hAmmoChainsaw, g_hAmmoGL, g_hAmmoHunting, g_hAmmoM60, g_hAmmoRifle, g_hAmmoShotgun, g_hAmmoSmg, g_hAmmoSniper;
int g_iAmmoAutoShot, g_iAmmoChainsaw, g_iAmmoGL, g_iAmmoHunting, g_iAmmoM60, g_iAmmoRifle, g_iAmmoShotgun, g_iAmmoSmg, g_iAmmoSniper;

static char g_sWeapons[MAX_WEAPONS][] =
{
	"weapon_rifle",
	"weapon_autoshotgun",
	"weapon_hunting_rifle",
	"weapon_smg",
	"weapon_pumpshotgun",
	"weapon_pistol",
	"weapon_molotov",
	"weapon_pipe_bomb",
	"weapon_first_aid_kit",
	"weapon_pain_pills"
};
static char g_sWeaponModels[MAX_WEAPONS][] =
{
	"models/w_models/weapons/w_rifle_m16a2.mdl",
	"models/w_models/weapons/w_autoshot_m4super.mdl",
	"models/w_models/weapons/w_sniper_mini14.mdl",
	"models/w_models/weapons/w_smg_uzi.mdl",
	"models/w_models/weapons/w_pumpshotgun_A.mdl",
	"models/w_models/weapons/w_pistol_a.mdl",
	"models/w_models/weapons/w_eq_molotov.mdl",
	"models/w_models/weapons/w_eq_pipebomb.mdl",
	"models/w_models/weapons/w_eq_medkit.mdl",
	"models/w_models/weapons/w_eq_painpills.mdl"
};
static char g_sWeapons2[MAX_WEAPONS2][] =
{
	"weapon_rifle",
	"weapon_autoshotgun",
	"weapon_hunting_rifle",
	"weapon_smg",
	"weapon_pumpshotgun",
	"weapon_shotgun_chrome",
	"weapon_rifle_desert",
	"weapon_grenade_launcher",
	"weapon_rifle_m60",
	"weapon_rifle_ak47",
	"weapon_shotgun_spas",
	"weapon_smg_silenced",
	"weapon_sniper_military",
	"weapon_chainsaw",
	"weapon_rifle_sg552",
	"weapon_smg_mp5",
	"weapon_sniper_awp",
	"weapon_sniper_scout",
	"weapon_pistol",
	"weapon_pistol_magnum",
	"weapon_molotov",
	"weapon_pipe_bomb",
	"weapon_vomitjar",
	"weapon_first_aid_kit",
	"weapon_defibrillator",
	"weapon_pain_pills",
	"weapon_adrenaline",
	"weapon_upgradepack_explosive",
	"weapon_upgradepack_incendiary"
};
static char g_sWeaponModels2[MAX_WEAPONS2][] =
{
	"models/w_models/weapons/w_rifle_m16a2.mdl",
	"models/w_models/weapons/w_autoshot_m4super.mdl",
	"models/w_models/weapons/w_sniper_mini14.mdl",
	"models/w_models/weapons/w_smg_uzi.mdl",
	"models/w_models/weapons/w_pumpshotgun_A.mdl",
	"models/w_models/weapons/w_shotgun.mdl",
	"models/w_models/weapons/w_desert_rifle.mdl",
	"models/w_models/weapons/w_grenade_launcher.mdl",
	"models/w_models/weapons/w_m60.mdl",
	"models/w_models/weapons/w_rifle_ak47.mdl",
	"models/w_models/weapons/w_shotgun_spas.mdl",
	"models/w_models/weapons/w_smg_a.mdl",
	"models/w_models/weapons/w_sniper_military.mdl",
	"models/weapons/melee/w_chainsaw.mdl",
	"models/w_models/weapons/w_rifle_sg552.mdl",
	"models/w_models/weapons/w_smg_mp5.mdl",
	"models/w_models/weapons/w_sniper_awp.mdl",
	"models/w_models/weapons/w_sniper_scout.mdl",
	"models/w_models/weapons/w_pistol_a.mdl",
	"models/w_models/weapons/w_desert_eagle.mdl",
	"models/w_models/weapons/w_eq_molotov.mdl",
	"models/w_models/weapons/w_eq_pipebomb.mdl",
	"models/w_models/weapons/w_eq_bile_flask.mdl",
	"models/w_models/weapons/w_eq_medkit.mdl",
	"models/w_models/weapons/w_eq_defibrillator.mdl",
	"models/w_models/weapons/w_eq_painpills.mdl",
	"models/w_models/weapons/w_eq_adrenaline.mdl",
	"models/w_models/weapons/w_eq_explosive_ammopack.mdl",
	"models/w_models/weapons/w_eq_incendiary_ammopack.mdl"
};



// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo =
{
	name = "[L4D & L4D2] Gun Cabinet",
	author = "SilverShot",
	description = "Spawns a gun cabinet with various weapons and items of your choosing.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=222931"
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
	g_hCvarAllow =		CreateConVar(	"l4d_gun_cabinet_allow",			"1",			"0=Plugin off, 1=Plugin on.", CVAR_FLAGS );
	g_hCvarCSS =		CreateConVar(	"l4d_gun_cabinet_css",				"1",			"0=Off, 1=Allow spawning CSS weapons when using the 'random' value in the preset config.", CVAR_FLAGS );
	if( g_bLeft4Dead2 )
	{
		g_hCvarGlow =		CreateConVar(	"l4d_gun_cabinet_glow",				"0",			"0=Off, Sets the max range at which the cabinet glows.", CVAR_FLAGS );
		g_hCvarGlowCol =	CreateConVar(	"l4d_gun_cabinet_glow_color",		"255 0 0",		"0=Default glow color. Three values between 0-255 separated by spaces. RGB: Red Green Blue.", CVAR_FLAGS );
	}
	g_hCvarModes =		CreateConVar(	"l4d_gun_cabinet_modes",			"",				"Turn on the plugin in these game modes, separate by commas (no spaces). (Empty = all).", CVAR_FLAGS );
	g_hCvarModesOff =	CreateConVar(	"l4d_gun_cabinet_modes_off",		"",				"Turn off the plugin in these game modes, separate by commas (no spaces). (Empty = none).", CVAR_FLAGS );
	g_hCvarModesTog =	CreateConVar(	"l4d_gun_cabinet_modes_tog",		"0",			"Turn on the plugin in these game modes. 0=All, 1=Coop, 2=Survival, 4=Versus, 8=Scavenge. Add numbers together.", CVAR_FLAGS );
	g_hCvarMaxGun =		CreateConVar(	"l4d_gun_cabinet_max_gun",			"8",			"Minimum number of primary weapons to spawn. (max is 10).", CVAR_FLAGS );
	g_hCvarMaxPistol =	CreateConVar(	"l4d_gun_cabinet_max_pistol",		"2",			"Maximum number of pistols to spawn (max is 4).", CVAR_FLAGS );
	g_hCvarMaxItem =	CreateConVar(	"l4d_gun_cabinet_max_item",			"1",			"Maximum number of items to spawn (max is 2).", CVAR_FLAGS );
	g_hCvarRandom =		CreateConVar(	"l4d_gun_cabinet_random",			"-1",			"-1=All, 0=None. Otherwise randomly select this many Gun Cabinets to spawn from the maps config.", CVAR_FLAGS );
	CreateConVar(						"l4d_gun_cabinet_version",			PLUGIN_VERSION, "Gun Cabinet plugin version.", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AutoExecConfig(true,				"l4d_gun_cabinet");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);
	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesOff.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModesTog.AddChangeHook(ConVarChanged_Allow);
	g_hCvarCSS.AddChangeHook(ConVarChanged_Cvars);
	if( g_bLeft4Dead2 )
	{
		g_hCvarGlow.AddChangeHook(ConVarChanged_Cvars);
		g_hCvarGlowCol.AddChangeHook(ConVarChanged_Cvars);
	}
	g_hCvarRandom.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMaxGun.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMaxPistol.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarMaxItem.AddChangeHook(ConVarChanged_Cvars);

	g_hAmmoRifle =			FindConVar("ammo_assaultrifle_max");
	g_hAmmoShotgun =		g_bLeft4Dead2 ? FindConVar("ammo_shotgun_max") : FindConVar("ammo_buckshot_max");
	g_hAmmoSmg =			FindConVar("ammo_smg_max");
	g_hAmmoHunting =		FindConVar("ammo_huntingrifle_max");

	g_hAmmoRifle.AddChangeHook(ConVarChanged_Cvars);
	g_hAmmoShotgun.AddChangeHook(ConVarChanged_Cvars);
	g_hAmmoSmg.AddChangeHook(ConVarChanged_Cvars);
	g_hAmmoHunting.AddChangeHook(ConVarChanged_Cvars);

	if( g_bLeft4Dead2 )
	{
		g_hAmmoGL =			FindConVar("ammo_grenadelauncher_max");
		g_hAmmoChainsaw =	FindConVar("ammo_chainsaw_max");
		g_hAmmoAutoShot =	FindConVar("ammo_autoshotgun_max");
		g_hAmmoM60 =		FindConVar("ammo_m60_max");
		g_hAmmoSniper =		FindConVar("ammo_sniperrifle_max");

		g_hAmmoGL.AddChangeHook(ConVarChanged_Cvars);
		g_hAmmoChainsaw.AddChangeHook(ConVarChanged_Cvars);
		g_hAmmoAutoShot.AddChangeHook(ConVarChanged_Cvars);
		g_hAmmoM60.AddChangeHook(ConVarChanged_Cvars);
		g_hAmmoSniper.AddChangeHook(ConVarChanged_Cvars);
	}

	RegAdminCmd("sm_gun_cabinet",			CmdCabinetMenu,		ADMFLAG_ROOT, 	"Opens a menu to spawn and save a Gun Cabinet to the data config for auto spawning.");
	RegAdminCmd("sm_gun_cabinet_del",		CmdCabinetDel,		ADMFLAG_ROOT, 	"Removes the Gun Cabinet you are pointing at and deletes from the config.");
	RegAdminCmd("sm_gun_cabinet_clear",		CmdCabinetClear,	ADMFLAG_ROOT, 	"Removes all Gun Cabinets from the current map.");
	RegAdminCmd("sm_gun_cabinet_wipe",		CmdCabinetWipe,		ADMFLAG_ROOT, 	"Removes all Gun Cabinets from the current map and deletes them from the config.");
	if( g_bLeft4Dead2 )
		RegAdminCmd("sm_gun_cabinet_glow",	CmdCabinetGlow,		ADMFLAG_ROOT, 	"Toggle to enable glow on all Gun Cabinets to see where they are placed.");
	RegAdminCmd("sm_gun_cabinet_list",		CmdCabinetList,		ADMFLAG_ROOT, 	"Display a list of Gun Cabinet positions and the total number of.");
	RegAdminCmd("sm_gun_cabinet_reload",	CmdCabinetReload,	ADMFLAG_ROOT, 	"Reloads the plugin, reads the preset data config and spawns any save Gun Cabinets.");
	RegAdminCmd("sm_gun_cabinet_tele",		CmdCabinetTele,		ADMFLAG_ROOT, 	"Teleport to a Gun Cabinet (Usage: sm_gun_cabinet_tele <index: 1 to MAX_SPAWNS (5)>).");
	RegAdminCmd("sm_gun_cabinet_ang",		CmdCabinetAng,		ADMFLAG_ROOT, 	"Displays a menu to adjust the Gun Cabinet angles your crosshair is over.");
	RegAdminCmd("sm_gun_cabinet_pos",		CmdCabinetPos,		ADMFLAG_ROOT, 	"Displays a menu to adjust the Gun Cabinet origin your crosshair is over.");

	LoadPresets();
}

public void OnPluginEnd()
{
	ResetPlugin();
}

public void OnMapStart()
{
	g_bMapStarted = true;

	PrecacheModel(MODEL_CABINET);
	PrecacheModel(MODEL_CRATE);

	int max = MAX_WEAPONS;
	if( g_bLeft4Dead2 ) max = MAX_WEAPONS2;
	for( int i = 0; i < max; i++ )
	{
		PrecacheModel(g_bLeft4Dead2 ? g_sWeaponModels2[i] : g_sWeaponModels[i]);
	}
}

public void OnMapEnd()
{
	g_bMapStarted = false;
	ResetPlugin(false);
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

void LoadPresets()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_WEAPONS);
	if( !FileExists(sPath) )
	{
		SetFailState("Error: Missing required preset config: %s", sPath);
	}

	KeyValues hFile = new KeyValues("presets");
	if( !hFile.ImportFromFile(sPath) )
	{
		SetFailState("Error: Cannot read the preset config: %s", sPath);
	}

	g_hMenuList = new Menu(ListMenuHandler);
	g_hMenuList.SetTitle("Spawn Cabinet");
	g_hMenuList.ExitButton = true;

	char sBuff[64], sTemp[64];
	for( int preset = 0; preset < MAX_PRESETS; preset++ )
	{
		Format(sTemp, sizeof(sTemp), "preset%d", preset + 1);
		if( hFile.JumpToKey(sTemp) )
		{
			hFile.GetString("name", sBuff, sizeof(sBuff));
			IntToString(preset + 1, sTemp, sizeof(sTemp));
			g_hMenuList.AddItem(sTemp, sBuff);

			for( int slot = 0; slot < MAX_SLOTS; slot++ )
			{
				Format(sTemp, sizeof(sTemp), "slot%d", slot + 1);
				hFile.GetString(sTemp, sBuff, sizeof(sBuff));

				if( sBuff[0] )
				{
					if( g_bLeft4Dead2 )
					{
						if( strcmp(sBuff, "random") == 0 )
						{
							if( slot < 10 )
							{
								if( g_iCvarCSS )
								{
									g_iPresets[preset][slot] = GetRandomInt(1, 18);		// Random primary - all
								} else {
									g_iPresets[preset][slot] = GetRandomInt(1, 14);		// Random primary - no css
								}
							}
							else if( slot >= 10 && slot <= 13 )		g_iPresets[preset][slot] = GetRandomInt(19, 20);	// Random pistol
							else if( slot >= 14 && slot <= 16 )		g_iPresets[preset][slot] = GetRandomInt(21, 29);	// Random medical/grenade
						} else {
							Format(sBuff, sizeof(sBuff), "weapon_%s", sBuff);

							for( int i = 0; i < MAX_WEAPONS2; i++ )
							{
								if( strcmp(sBuff, g_sWeapons2[i]) == 0 )
								{
									g_iPresets[preset][slot] = i + 1;
									break;
								}
							}
						}
					} else {
						if( strcmp(sBuff, "random") == 0 )
						{
							if( slot < 10 )							g_iPresets[preset][slot] = GetRandomInt(1, 5);		// Random primary
							else if( slot >= 11 && slot <= 14 )		g_iPresets[preset][slot] = 6;
							else if( slot >= 15 && slot <= 16 )		g_iPresets[preset][slot] = GetRandomInt(7, 10);		// Random medical/grenade
						} else {
							Format(sBuff, sizeof(sBuff), "weapon_%s", sBuff);

							for( int i = 0; i < MAX_WEAPONS; i++ )
							{
								if( strcmp(sBuff, g_sWeapons[i]) == 0 )
								{
									g_iPresets[preset][slot] = i + 1;
									break;
								}
							}
						}
					}
				}
			}
		}

		hFile.Rewind();
	}

	delete hFile;
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
	g_iCvarCSS				= g_hCvarCSS.IntValue;
	if( g_bLeft4Dead2 )
	{
		g_iCvarGlow			= g_hCvarGlow.IntValue;
		g_iCvarGlowCol		= GetColor(g_hCvarGlowCol);
	}
	g_iCvarRandom			= g_hCvarRandom.IntValue;

	g_iCvarMaxGun			= g_hCvarMaxGun.IntValue;
	g_iCvarMaxPistol		= g_hCvarMaxPistol.IntValue;
	g_iCvarMaxItem			= g_hCvarMaxItem.IntValue;

	g_iAmmoRifle			= g_hAmmoRifle.IntValue;
	g_iAmmoShotgun			= g_hAmmoShotgun.IntValue;
	g_iAmmoSmg				= g_hAmmoSmg.IntValue;
	g_iAmmoHunting			= g_hAmmoHunting.IntValue;

	if( g_bLeft4Dead2 )
	{
		g_iAmmoGL			= g_hAmmoGL.IntValue;
		g_iAmmoChainsaw		= g_hAmmoChainsaw.IntValue;
		g_iAmmoAutoShot		= g_hAmmoAutoShot.IntValue;
		g_iAmmoM60			= g_hAmmoM60.IntValue;
		g_iAmmoSniper		= g_hAmmoSniper.IntValue;
	}
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
	if( !g_bMapStarted || g_bLoaded || g_iCvarRandom == 0 ) return;
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

	// Retrieve how many anymore weapons to display
	int iCount = hFile.GetNum("num", 0);
	if( iCount == 0 )
	{
		delete hFile;
		return;
	}

	// Spawn only a select few Gun Cabinets?
	int iIndexes[MAX_SPAWNS+1];
	if( iCount > MAX_SPAWNS )
		iCount = MAX_SPAWNS;


	// Spawn saved Gun Cabinets or create random
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

	// Get the weapon origins and spawn
	char sTemp[4];
	float vPos[3], vAng[3];
	int index, preset;

	for( int i = 1; i <= iCount; i++ )
	{
		if( iRandom != -1 ) index = iIndexes[i-1];
		else index = i;

		IntToString(index, sTemp, sizeof(sTemp));

		if( hFile.JumpToKey(sTemp) )
		{
			hFile.GetVector("ang", vAng);
			hFile.GetVector("pos", vPos);
			preset = hFile.GetNum("preset");

			if( vPos[0] == 0.0 && vPos[1] == 0.0 && vPos[2] == 0.0 ) // Should never happen...
				LogError("Error: 0,0,0 origin. Iteration=%d. Index=%d. Random=%d. Count=%d.", i, index, iRandom, iCount);
			else
				CreateSpawn(vPos, vAng, index, preset-1);
			hFile.GoBack();
		}
	}

	delete hFile;
}



// ====================================================================================================
//					CREATE SPAWN
// ====================================================================================================
void CreateSpawn(const float vOrigin[3], const float vAngles[3], int index, int preset)
{
	if( g_iSpawnCount >= MAX_SPAWNS )
		return;

	if( preset + 1 > MAX_PRESETS ) // preset starts from 0 so >= matches 7 (default)
	{
		LogError("Cannot spawn index '%d' which wants to load preset '%d', maximum presets set to '%d', recompile the plugin changing MAX_PRESETS to increase or fix your config.", index, preset + 1, MAX_PRESETS);
		return;
	}

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

	int entity = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(entity, "solid", "0");
	SetEntityModel(entity, MODEL_CABINET);
	TeleportEntity(entity, vOrigin, vAngles, NULL_VECTOR);
	DispatchSpawn(entity);
	g_iSpawns[iSpawnIndex][0] = EntIndexToEntRef(entity);
	g_iSpawns[iSpawnIndex][1] = index;

	if( g_bLeft4Dead2 && g_iCvarGlow )
	{
		SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iCvarGlow);
		SetEntProp(entity, Prop_Send, "m_iGlowType", 1);
		SetEntProp(entity, Prop_Send, "m_glowColorOverride", g_iCvarGlowCol);
		AcceptEntityInput(entity, "StartGlowing");
	}

	int cabinet = entity;
	float vPos[3], vAng[3];

	// ROOF
	vPos = vOrigin;
	vAng = vAngles;
	vPos[2] += 78.0;
	entity = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(entity, "solid", "6");
	SetEntityModel(entity, MODEL_CRATE);
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, 0, 0, 0, 0);
	DispatchSpawn(entity);
	g_iDoors[iSpawnIndex][0] = EntIndexToEntRef(entity);
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", cabinet);

	// BACK
	vPos = vOrigin;
	vAng = vAngles;
	vPos[2] += 40.0;
	MoveForward(vPos, vAng, vPos, -12.0);
	vAng[0] += 90.0;
	entity = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(entity, "solid", "6");
	SetEntityModel(entity, MODEL_CRATE);
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, 0, 0, 0, 0);
	DispatchSpawn(entity);
	g_iDoors[iSpawnIndex][1] = EntIndexToEntRef(entity);
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", cabinet);

	// RIGHT
	vPos = vOrigin;
	vAng = vAngles;
	vPos[2] += 40.0;
	MoveSideway(vPos, vAng, vPos, -23.0);
	vAng[2] += 90.0;
	entity = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(entity, "solid", "6");
	SetEntityModel(entity, MODEL_CRATE);
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, 0, 0, 0, 0);
	DispatchSpawn(entity);
	g_iDoors[iSpawnIndex][2] = EntIndexToEntRef(entity);
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", cabinet);

	// LEFT
	vPos = vOrigin;
	vAng = vAngles;
	vPos[2] += 40.0;
	MoveSideway(vPos, vAng, vPos, 23.0);
	vAng[2] += 90.0;
	entity = CreateEntityByName("prop_dynamic_override");
	DispatchKeyValue(entity, "solid", "6");
	SetEntityModel(entity, MODEL_CRATE);
	SetEntityRenderMode(entity, RENDER_TRANSCOLOR);
	SetEntityRenderColor(entity, 0, 0, 0, 0);
	TeleportEntity(entity, vPos, vAng, NULL_VECTOR);
	DispatchSpawn(entity);
	g_iDoors[iSpawnIndex][3] = EntIndexToEntRef(entity);
	SetVariantString("!activator");
	AcceptEntityInput(entity, "SetParent", cabinet);


	// ARRAYS
	int iGuns[10];
	int iPist[4];
	int iItem[2];

	// MODEL TYPE
	for( int slot = 0; slot < 10; slot++ )
		iGuns[slot] = g_iPresets[preset][slot];
	for( int slot = 10; slot < 14; slot++ )
		iPist[slot-10] = g_iPresets[preset][slot];
	for( int slot = 14; slot < 16; slot++ )
		iItem[slot-14] = g_iPresets[preset][slot];

	// INDEX HOLDER
	int iAmGuns[10];
	int iAmPist[4];
	int iAmItem[2];

	// VALID COUNT
	int iCountGun;
	int iCountPis;
	int iCountIte;

	// VALIDATE AND PUSH INDEX HOLDER
	for( int i = 0; i < 10; i++ )
		if( iGuns[i] != 0 ) iAmGuns[iCountGun++] = i;
	for( int i = 0; i < 4; i++ )
		if( iPist[i] != 0 ) iAmPist[iCountPis++] = i;
	for( int i = 0; i < 2; i++ )
		if( iItem[i] != 0 ) iAmItem[iCountIte++] = i;

	int count, dex;
	if( iCountGun && g_iCvarMaxGun )
	{
		SortIntegers(iAmGuns, iCountGun, Sort_Random);

		if( g_iCvarMaxGun > iCountGun ) count = iCountGun;
		else count = g_iCvarMaxGun;

		for( int x = 0; x < count; x++ )
		{
			dex = iAmGuns[x];
			CreateWeapon(iSpawnIndex, dex, iGuns[dex] -1, vOrigin, vAngles);
		}
	}

	if( iCountPis && g_iCvarMaxPistol )
	{
		SortIntegers(iAmPist, iCountPis, Sort_Random);

		if( g_iCvarMaxPistol > iCountPis ) count = iCountPis;
		else count = g_iCvarMaxPistol;

		for( int x = 0; x < count; x++ )
		{
			dex = iAmPist[x];
			CreateWeapon(iSpawnIndex, dex + 10, iPist[dex] -1, vOrigin, vAngles);
		}
	}

	if( iCountIte && g_iCvarMaxItem )
	{
		SortIntegers(iAmItem, iCountIte, Sort_Random);

		if( g_iCvarMaxItem > iCountIte ) count = iCountIte;
		else count = g_iCvarMaxItem;

		for( int x = 0; x < count; x++ )
		{
			dex = iAmItem[x];
			CreateWeapon(iSpawnIndex, dex + 14, iItem[dex] -1, vOrigin, vAngles);
		}
	}


	// SPAWN ALL
	// int model;
	// for( int slot = 0; slot < MAX_SLOTS; slot++ )
	// {
		// model = g_iPresets[preset][slot];
		// if( model != 0 )
		// {
			// CreateWeapon(iSpawnIndex, slot, model -1, vOrigin, vAngles);
		// }
	// }

	g_iSpawnCount++;
}

int CreateWeapon(int index, int slot, int model, const float vOrigin[3], const float vAngles[3])
{
	char classname[64];
	strcopy(classname, sizeof(classname), g_bLeft4Dead2 ? g_sWeapons2[model] : g_sWeapons[model]);

	int entity_weapon = -1;
	entity_weapon = CreateEntityByName(classname);
	if( entity_weapon == -1 )
	{
		LogError("Failed to create entity '%s'", classname);
		return -1;
	}

	DispatchKeyValue(entity_weapon, "solid", "6");
	if( g_bLeft4Dead2 )
		DispatchKeyValue(entity_weapon, "model", g_sWeaponModels2[model]);
	else
		DispatchKeyValue(entity_weapon, "model", g_sWeaponModels[model]);
	DispatchKeyValue(entity_weapon, "rendermode", "3");
	DispatchKeyValue(entity_weapon, "disableshadows", "1");

	float vPos[3], vAng[3];

	vPos = vOrigin;
	vAng = vAngles;

	int fix;
	if( slot < 10 )
	{
		if( g_bLeft4Dead2 )
		{
			if( strcmp("grenade_launcher", g_sWeapons2[model][7]) == 0 )	fix = 1;
			else if( strcmp("rifle_m60", g_sWeapons2[model][7]) == 0 )		fix = 2;
		}

		vPos = vOrigin;
		vAng = vAngles;

		if( fix == 1 )
		{
			vPos[2] += 16.0;
		}
		else if( fix == 2 )
		{
			vPos[2] += 23.0;
			MoveForward(vPos, vAng, vPos, 1.0);
		} else {
			vPos[2] += 13.0;
		}

		if( g_bLeft4Dead2 )
		{
			if( strcmp("shotgun_chrome", g_sWeapons2[model][7]) == 0 )
			{
				MoveForward(vPos, vAng, vPos, 3.0);
				vPos[2] += 2.0;
			}
			else if( strcmp("pumpshotgun", g_sWeapons2[model][7]) == 0 )
			{
				MoveForward(vPos, vAng, vPos, 5.0);
				vPos[2] += 2.0;
			}
		} else {
			if( strcmp("shotgun_chrome", g_sWeapons[model][7]) == 0 )
			{
				MoveForward(vPos, vAng, vPos, 3.0);
				vPos[2] += 2.0;
			}
			else if( strcmp("pumpshotgun", g_sWeapons[model][7]) == 0 )
			{
				MoveForward(vPos, vAng, vPos, 5.0);
				vPos[2] += 2.0;
			}
		}
	}

	switch( slot )
	{
		case 0:
		{
			// RACK #1
			MoveForward(vPos, vAng, vPos, -0.1);
			MoveSideway(vPos, vAng, vPos, 19.0);
		}

		case 1:
		{
			// RACK #2
			MoveForward(vPos, vAng, vPos, -0.1);
			MoveSideway(vPos, vAng, vPos, 15.5);
		}

		case 2:
		{
			// RACK #3
			MoveForward(vPos, vAng, vPos, -0.1);
			MoveSideway(vPos, vAng, vPos, 11.25);
		}

		case 3:
		{
			// RACK #4
			MoveForward(vPos, vAng, vPos, 1.0);
			MoveSideway(vPos, vAng, vPos, 7.7);
		}

		case 4:
		{
			// RACK #5
			MoveForward(vPos, vAng, vPos, 1.0);
			MoveSideway(vPos, vAng, vPos, 4.0);
		}

		case 5:
		{
			// RACK #6
			MoveForward(vPos, vAng, vPos, 1.0);
			MoveSideway(vPos, vAng, vPos, 0.4);
		}

		case 6:
		{
			// RACK #7
			MoveForward(vPos, vAng, vPos, -5.5);
			MoveSideway(vPos, vAng, vPos, -4.5);
		}

		case 7:
		{
			// RACK #8
			MoveForward(vPos, vAng, vPos, -5.4);
			MoveSideway(vPos, vAng, vPos, -8.4);
		}

		case 8:
		{
			// RACK #9
			MoveForward(vPos, vAng, vPos, -5.4);
			MoveSideway(vPos, vAng, vPos, -12.05);
		}

		case 9:
		{
			// RACK #10
			MoveForward(vPos, vAng, vPos, -5.4);
			MoveSideway(vPos, vAng, vPos, -15.8);
		}

		case 10:
		{
			// RACK PISTOL #1 - TL
			vPos = vOrigin;
			vAng = vAngles;
			if( g_bLeft4Dead2 && strcmp("pistol_magnum", g_sWeapons2[model][7]) == 0 )
			{
				vPos[2] += 54.0;
				MoveForward(vPos, vAng, vPos, -10.0);
				MoveSideway(vPos, vAng, vPos, 9.0);
				vAng[1] -= 90.0;
			} else {
				vPos[2] += 56.0;
				MoveForward(vPos, vAng, vPos, -10.0);
				MoveSideway(vPos, vAng, vPos, 8.0);
				vAng[1] -= 90.0;
			}
		}

		case 11:
		{
			// RACK PISTOL #2 - BL
			vPos = vOrigin;
			vAng = vAngles;
			if( g_bLeft4Dead2 && strcmp("pistol_magnum", g_sWeapons2[model][7]) == 0 )
			{
				vPos[2] += 45.3;
				MoveForward(vPos, vAng, vPos, -10.0);
				MoveSideway(vPos, vAng, vPos, 9.0);
				vAng[1] -= 90.0;
			} else {
				vPos[2] += 48.0;
				MoveForward(vPos, vAng, vPos, -10.0);
				MoveSideway(vPos, vAng, vPos, 8.0);
				vAng[1] -= 90.0;
			}
		}

		case 12:
		{
			// RACK PISTOL #3 - TR
			vPos = vOrigin;
			vAng = vAngles;
			if( g_bLeft4Dead2 && strcmp("pistol_magnum", g_sWeapons2[model][7]) == 0 )
			{
				vPos[2] += 54.0;
				MoveForward(vPos, vAng, vPos, -10.0);
				MoveSideway(vPos, vAng, vPos, -6.0);
				vAng[1] -= 90.0;
			} else {
				vPos[2] += 56.0;
				MoveForward(vPos, vAng, vPos, -10.0);
				MoveSideway(vPos, vAng, vPos, -7.5);
				vAng[1] -= 90.0;
			}
		}

		case 13:
		{
			// RACK PISTOL #4 - BR
			vPos = vOrigin;
			vAng = vAngles;
			if( g_bLeft4Dead2 && strcmp("pistol_magnum", g_sWeapons2[model][7]) == 0 )
			{
				vPos[2] += 45.3;
				MoveForward(vPos, vAng, vPos, -10.0);
				MoveSideway(vPos, vAng, vPos, -6.0);
				vAng[1] -= 90.0;
			} else {
				vPos[2] += 48.0;
				MoveForward(vPos, vAng, vPos, -10.0);
				MoveSideway(vPos, vAng, vPos, -7.5);
				vAng[1] -= 90.0;
			}
		}

		case 14:
		{
			// ITEM #1 BOTTOM
			if( (!g_bLeft4Dead2 && strcmp("first_aid_kit", g_sWeapons[model][7]) == 0 )
				||
				(g_bLeft4Dead2 && (
				strcmp("first_aid_kit", g_sWeapons2[model][7]) == 0 ||
				strcmp("upgradepack_explosive", g_sWeapons2[model][7]) == 0 ||
				strcmp("upgradepack_incendiary", g_sWeapons2[model][7]) == 0
				))
			)
			{
				vPos = vOrigin;
				vAng = vAngles;
				vPos[2] += 45.0;
				MoveForward(vPos, vAng, vPos, -9.0);
				MoveSideway(vPos, vAng, vPos, -18.5);
				vAng[1] += 180.0;
				vAng[2] -= 90.0;
			} else if( (!g_bLeft4Dead2 && strcmp("molotov", g_sWeapons[model][7]) == 0)
				||
				(g_bLeft4Dead2 && strcmp("molotov", g_sWeapons2[model][7]) == 0)
			)
			{
				vPos = vOrigin;
				vAng = vAngles;
				vPos[2] += 45.0;
				MoveForward(vPos, vAng, vPos, -10.0);
				MoveSideway(vPos, vAng, vPos, -15.0);
				// vAng[1] -= 90.0;
			} else if( g_bLeft4Dead2 && strcmp("defibrillator", g_sWeapons2[model][7]) == 0 )
			{
				vPos = vOrigin;
				vAng = vAngles;
				vPos[2] += 45.0;
				MoveForward(vPos, vAng, vPos, -11.0);
				MoveSideway(vPos, vAng, vPos, -14.5);
				vAng[0] += 190.0;
				vAng[1] -= 90.0;
				vAng[2] -= 90.0;
			} else if( strcmp("pain_pills", g_sWeapons2[model][7]) == 0 || (g_bLeft4Dead2 && strcmp("adrenaline", g_sWeapons2[model][7]) == 0) )
			{
				vPos = vOrigin;
				vAng = vAngles;
				vPos[2] += 45.0;
				MoveForward(vPos, vAng, vPos, -10.0);
				MoveSideway(vPos, vAng, vPos, -14.5);
				vAng[1] += 180.0;
			} else {
				vPos = vOrigin;
				vAng = vAngles;
				vPos[2] += 45.0;
				MoveForward(vPos, vAng, vPos, -10.0);
				MoveSideway(vPos, vAng, vPos, -15.0);
				vAng[1] -= 90.0;
			}
		}

		case 15:
		{
			// ITEM #2 TOP
			if( (!g_bLeft4Dead2 && strcmp("first_aid_kit", g_sWeapons[model][7]) == 0)
				||
				(g_bLeft4Dead2 && strcmp("first_aid_kit", g_sWeapons2[model][7]) == 0)
			)
			{
				vPos = vOrigin;
				vAng = vAngles;
				vPos[2] += 63.0;
				MoveForward(vPos, vAng, vPos, -3.0);
				MoveSideway(vPos, vAng, vPos, -12.0);
				vAng[1] += 180.0;
			}
			else
			if( (!g_bLeft4Dead2 && strcmp("molotov", g_sWeapons[model][7]) == 0)
				||
				(g_bLeft4Dead2 && strcmp("molotov", g_sWeapons2[model][7]) == 0)
			)
			{
				vPos = vOrigin;
				vAng = vAngles;
				vPos[2] += 64.5;
				MoveForward(vPos, vAng, vPos, -1.0);
				MoveSideway(vPos, vAng, vPos, -14.0);
				vAng[0] -= 90.0;
				vAng[1] += 90.0;
			}
			else if(
				(!g_bLeft4Dead2 && strcmp("first_aid_kit", g_sWeapons[model][7]) == 0) ||
				(g_bLeft4Dead2 && (
				strcmp("defibrillator", g_sWeapons2[model][7]) == 0 ||
				strcmp("adrenaline", g_sWeapons2[model][7]) == 0 ||
				strcmp("upgradepack_explosive", g_sWeapons2[model][7]) == 0 ||
				strcmp("upgradepack_incendiary", g_sWeapons2[model][7]) == 0
				))
			)
			{
				vPos = vOrigin;
				vAng = vAngles;
				vPos[2] += 63.0;
				MoveForward(vPos, vAng, vPos, -3.0);
				MoveSideway(vPos, vAng, vPos, -12.0);
			}
			else if(
				(!g_bLeft4Dead2 && strcmp("pain_pills", g_sWeapons[model][7]) == 0)
				||
				(g_bLeft4Dead2 && strcmp("pain_pills", g_sWeapons2[model][7]) == 0)
			)
			{
				vPos = vOrigin;
				vAng = vAngles;
				vPos[2] += 63.0;
				MoveForward(vPos, vAng, vPos, -3.0);
				MoveSideway(vPos, vAng, vPos, -12.0);
				vAng[1] += 150.0;
			} else {
				vPos = vOrigin;
				vAng = vAngles;
				vPos[2] += 68.0;
				MoveForward(vPos, vAng, vPos, -3.0);
				MoveSideway(vPos, vAng, vPos, -12.0);
			}
		}
	}

	if( slot < 10 )
	{
		if( fix == 2 )
		{
			vAng = vAngles;
			vAng[0] -= 110.0;
			vAng[2] -= 180.0;
		} else {
			vAng[0] -= 110.0;
			vAng[2] -= 180.0;
		}
	} else {
		if( g_bLeft4Dead2 && slot == 14 && strcmp("adrenaline", g_sWeapons2[model][7]) == 0 )
		{
			vAng[1] += 180.0;
			vAng[2] -= 90.0;
		}
	}

	TeleportEntity(entity_weapon, vPos, vAng, NULL_VECTOR);
	DispatchSpawn(entity_weapon);

	int ammo;

	if( !g_bLeft4Dead2 ) g_iAmmoAutoShot = g_iAmmoShotgun;

	if( strcmp(classname[7], "smg") == 0 )
		ammo = g_iAmmoSmg;
	else if( strcmp(classname[7], "rifle") == 0 )
		ammo = g_iAmmoRifle;
	else if( strcmp(classname[7], "pumpshotgun") == 0 )
		ammo = g_iAmmoShotgun;
	else if( strcmp(classname[7], "autoshotgun") == 0 )
		ammo = g_iAmmoAutoShot;
	else if( strcmp(classname[7], "hunting_rifle") == 0 )
		ammo = g_iAmmoHunting;
	else if( g_bLeft4Dead2 )
	{
		if( strcmp(classname[7], "smg_mp5") == 0 || strcmp(classname[7], "smg_silenced") == 0 )
			ammo = g_iAmmoSmg;
		else if( strcmp(classname[7], "rifle_desert") == 0 || strcmp(classname[7], "rifle_ak47") == 0 || strcmp(classname[7], "rifle_sg552") == 0 )
			ammo = g_iAmmoRifle;
		else if( strcmp(classname[7], "shotgun_chrome") == 0 )
			ammo = g_iAmmoShotgun;
		else if( strcmp(classname[7], "shotgun_spas") == 0 )
			ammo = g_iAmmoAutoShot;
		else if( strcmp(classname[7], "grenade_launcher") == 0 )
			ammo = g_iAmmoGL;
		else if( strcmp(classname[7], "rifle_m60") == 0 )
			ammo = g_iAmmoM60;
		else if( strcmp(classname[7], "chainsaw") == 0 )
			ammo = g_iAmmoChainsaw;
		else if( strcmp(classname[7], "sniper_awp") == 0 || strcmp(classname[7], "sniper_military") == 0 || strcmp(classname[7], "sniper_scout") == 0 )
			ammo = g_iAmmoSniper;
	}

	// SetEntProp(entity_weapon, Prop_Send, "m_iGlowType", 2);
	// SetEntProp(entity_weapon, Prop_Send, "m_glowColorOverride", 2);
	SetEntProp(entity_weapon, Prop_Send, "m_iExtraPrimaryAmmo", ammo, 4);
	SetEntityMoveType(entity_weapon, MOVETYPE_NONE);

	g_iSpawns[index][slot+2] = EntIndexToEntRef(entity_weapon);

	return entity_weapon;
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

void MoveSideway(const float vPos[3], const float vAng[3], float vReturn[3], float fDistance)
{
	float vDir[3];
	GetAngleVectors(vAng, NULL_VECTOR, vDir, NULL_VECTOR);
	vReturn = vPos;
	vReturn[0] += vDir[0] * fDistance;
	vReturn[1] += vDir[1] * fDistance;
	vReturn[2] += vDir[2] * fDistance;
}



// ====================================================================================================
//					COMMANDS
// ====================================================================================================
//					sm_gun_cabinet
// ====================================================================================================
Action CmdCabinetMenu(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Gun Cabinet] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}
	else if( g_iSpawnCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Gun Cabinets. Used: (\x05%d/%d\x01).", CHAT_TAG, g_iSpawnCount, MAX_SPAWNS);
		return Plugin_Handled;
	}

	g_hMenuList.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

int ListMenuHandler(Menu menu, MenuAction action, int client, int index)
{
	if( action == MenuAction_Select )
	{
		char sTemp[4];
		menu.GetItem(index, sTemp, sizeof(sTemp));
		index = StringToInt(sTemp);
		CmdCabinetSaveMenu(client, index);

		g_hMenuList.Display(client, MENU_TIME_FOREVER);
	}

	return 0;
}

// ====================================================================================================
//					sm_gun_cabinet
// ===================================================================================================
void CmdCabinetSaveMenu(int client, int preset)
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
		PrintToChat(client, "%sError: Cannot read the Gun Cabinet config, assuming empty file. (\x05%s\x01).", CHAT_TAG, sPath);
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));
	if( !hFile.JumpToKey(sMap, true) )
	{
		PrintToChat(client, "%sError: Failed to add map to Gun Cabinet spawn config.", CHAT_TAG);
		delete hFile;
		return;
	}

	// Retrieve how many Gun Cabinets are saved
	int iCount = hFile.GetNum("num", 0);
	if( iCount >= MAX_SPAWNS )
	{
		PrintToChat(client, "%sError: Cannot add anymore Gun Cabinets. Used: (\x05%d/%d\x01).", CHAT_TAG, iCount, MAX_SPAWNS);
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
		float vPos[3], vAng[3];
		// Set player Gun Cabinet spawn location
		if( !SetTeleportEndPoint(client, vPos, vAng) )
		{
			PrintToChat(client, "%sCannot place Gun Cabinet, please try again.", CHAT_TAG);
			delete hFile;
			return;
		}

		// Save angle / origin
		hFile.SetVector("ang", vAng);
		hFile.SetVector("pos", vPos);
		hFile.SetNum("preset", preset);

		CreateSpawn(vPos, vAng, iCount, preset-1);

		// Save cfg
		hFile.Rewind();
		hFile.ExportToFile(sPath);

		PrintToChat(client, "%s(\x05%d/%d\x01) - Saved at pos:[\x05%f %f %f\x01] ang:[\x05%f %f %f\x01]", CHAT_TAG, iCount, MAX_SPAWNS, vPos[0], vPos[1], vPos[2], vAng[0], vAng[1], vAng[2]);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to save Gun Cabinet.", CHAT_TAG, iCount, MAX_SPAWNS);

	delete hFile;
}

// ====================================================================================================
//					sm_gun_cabinet_del
// ====================================================================================================
Action CmdCabinetDel(int client, int args)
{
	if( !g_bCvarAllow )
	{
		ReplyToCommand(client, "[Gun Cabinet] Plugin turned off.");
		return Plugin_Handled;
	}

	if( !client )
	{
		ReplyToCommand(client, "[Gun Cabinet] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	int entity = GetClientAimTarget(client, false);
	if( entity == -1 ) return Plugin_Handled;
	entity = EntIndexToEntRef(entity);

	int cfgindex, index = -1;
	for( int x = 0; x < MAX_SPAWNS; x++ )
	{
		for( int i = 0; i < MAX_DOORS; i++ )
		{
			if( g_iDoors[x][i] == entity )
			{
				index = x;
				break;
			}
		}
	}

	if( index == -1 )
	{
		return Plugin_Handled;
	}

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
		PrintToChat(client, "%sError: Cannot find the Gun Cabinet config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return Plugin_Handled;
	}

	KeyValues hFile = new KeyValues("spawns");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Gun Cabinet config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the Gun Cabinet config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	// Retrieve how many Gun Cabinets
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

		PrintToChat(client, "%s(\x05%d/%d\x01) - Gun Cabinet removed from config.", CHAT_TAG, iCount, MAX_SPAWNS);
	}
	else
		PrintToChat(client, "%s(\x05%d/%d\x01) - Failed to remove Gun Cabinet from config.", CHAT_TAG, iCount, MAX_SPAWNS);

	delete hFile;
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_gun_cabinet_clear
// ====================================================================================================
Action CmdCabinetClear(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Gun Cabinet] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	ResetPlugin();

	PrintToChat(client, "%s(0/%d) - All Gun Cabinets removed from the map.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_gun_cabinet_wipe
// ====================================================================================================
Action CmdCabinetWipe(int client, int args)
{
	if( !client )
	{
		ReplyToCommand(client, "[Gun Cabinet] Command can only be used %s", IsDedicatedServer() ? "in game on a dedicated server." : "in chat on a Listen server.");
		return Plugin_Handled;
	}

	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Gun Cabinet config (\x05%s\x01).", CHAT_TAG, sPath);
		return Plugin_Handled;
	}

	// Load config
	KeyValues hFile = new KeyValues("spawns");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Gun Cabinet config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return Plugin_Handled;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap, false) )
	{
		PrintToChat(client, "%sError: Current map not in the Gun Cabinet config.", CHAT_TAG);
		delete hFile;
		return Plugin_Handled;
	}

	hFile.DeleteThis();
	ResetPlugin();

	// Save to file
	hFile.Rewind();
	hFile.ExportToFile(sPath);
	delete hFile;

	PrintToChat(client, "%s(0/%d) - All Gun Cabinets removed from config, add with \x05sm_gun_cabinet_save\x01.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_gun_cabinet_glow
// ====================================================================================================
Action CmdCabinetGlow(int client, int args)
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
				SetEntProp(ent, Prop_Send, "m_glowColorOverride", 65535);
				SetEntProp(ent, Prop_Send, "m_nGlowRange", 0);
			}
		}
	}
}

// ====================================================================================================
//					sm_gun_cabinet_list
// ====================================================================================================
Action CmdCabinetList(int client, int args)
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
//					sm_gun_cabinet_reload
// ====================================================================================================
Action CmdCabinetReload(int client, int args)
{
	delete g_hMenuList;

	for( int preset = 0; preset < MAX_PRESETS; preset++ )
	{
		for( int slot = 0; slot < MAX_SLOTS; slot++ )
		{
			g_iPresets[preset][slot] = 0;
		}
	}

	g_bCvarAllow = false;
	ResetPlugin(true);
	LoadPresets();
	IsAllowed();
	return Plugin_Handled;
}

// ====================================================================================================
//					sm_gun_cabinet_tele
// ====================================================================================================
Action CmdCabinetTele(int client, int args)
{
	if( args == 1 )
	{
		char arg[16];
		GetCmdArg(1, arg, sizeof(arg));
		int index = StringToInt(arg) - 1;
		if( index > -1 && index < MAX_SPAWNS && IsValidEntRef(g_iSpawns[index][0]) )
		{
			float vPos[3], vAng[3];
			GetEntPropVector(g_iSpawns[index][0], Prop_Data, "m_vecOrigin", vPos);
			GetEntPropVector(g_iSpawns[index][0], Prop_Send, "m_angRotation", vAng);
			MoveForward(vPos, vAng, vPos, 30.0);
			vPos[2] += 20.0;
			TeleportEntity(client, vPos, NULL_VECTOR, NULL_VECTOR);
			PrintToChat(client, "%sTeleported to %d.", CHAT_TAG, index + 1);
			return Plugin_Handled;
		}

		PrintToChat(client, "%sCould not find index for teleportation.", CHAT_TAG);
	}
	else
		PrintToChat(client, "%sUsage: sm_gun_cabinet_tele <index 1-%d>.", CHAT_TAG, MAX_SPAWNS);
	return Plugin_Handled;
}

// ====================================================================================================
//					MENU ANGLE
// ====================================================================================================
Action CmdCabinetAng(int client, int args)
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
			for( int x = 0; x < MAX_DOORS; x++ )
			{
				entity = g_iDoors[i][x];

				if( entity == aim  )
				{
					entity = g_iSpawns[i][0];

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
Action CmdCabinetPos(int client, int args)
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
			for( int x = 0; x < MAX_DOORS; x++ )
			{
				entity = g_iDoors[i][x];

				if( entity == aim  )
				{
					entity = g_iSpawns[i][0];

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
	int entity = GetClientAimTarget(client, false);
	if( entity == -1 )
		return;

	entity = EntIndexToEntRef(entity);

	int cfgindex, index = -1;
	for( int x = 0; x < MAX_SPAWNS; x++ )
	{
		for( int i = 0; i < MAX_DOORS; i++ )
		{
			if( g_iDoors[x][i] == entity )
			{
				entity = g_iSpawns[x][0];
				cfgindex = g_iSpawns[x][1];
				index = x;
				break;
			}
		}
	}

	if( index == -1 )
	{
		PrintToChat(client, "%sError: Cannot find the target.", CHAT_TAG, CONFIG_SPAWNS);
		return;
	}

	// Load config
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), CONFIG_SPAWNS);
	if( !FileExists(sPath) )
	{
		PrintToChat(client, "%sError: Cannot find the Gun Cabinet config (\x05%s\x01).", CHAT_TAG, CONFIG_SPAWNS);
		return;
	}

	KeyValues hFile = new KeyValues("spawns");
	if( !hFile.ImportFromFile(sPath) )
	{
		PrintToChat(client, "%sError: Cannot load the Gun Cabinet config (\x05%s\x01).", CHAT_TAG, sPath);
		delete hFile;
		return;
	}

	// Check for current map in the config
	char sMap[64];
	GetCurrentMap(sMap, sizeof(sMap));

	if( !hFile.JumpToKey(sMap) )
	{
		PrintToChat(client, "%sError: Current map not in the Gun Cabinet config.", CHAT_TAG);
		delete hFile;
		return;
	}

	float vAng[3], vPos[3];
	char sTemp[4];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vPos);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", vAng);

	IntToString(cfgindex, sTemp, sizeof(sTemp));
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
		g_hMenuAng.AddItem("", "X + 1.0");
		g_hMenuAng.AddItem("", "Y + 1.0");
		g_hMenuAng.AddItem("", "Z + 1.0");
		g_hMenuAng.AddItem("", "X - 1.0");
		g_hMenuAng.AddItem("", "Y - 1.0");
		g_hMenuAng.AddItem("", "Z - 1.0");
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

	for( int x = 0; x < MAX_SLOTS + 2; x++ )
	{
		entity = g_iSpawns[index][x];
		g_iSpawns[index][x] = 0;

		if( x != 1 && IsValidEntRef(entity) )
		{
			if( x > 1 )
			{
				client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
				if( client < 0 || client > MaxClients || !IsClientInGame(client) )
				{
					RemoveEntity(entity);
				}
			} else {
				RemoveEntity(entity);
			}
		}
	}

	for( int i = 0; i < MAX_DOORS; i++ )
	{
		entity = g_iDoors[index][i];
		g_iDoors[index][i] = 0;
		if( IsValidEntRef(entity) )	RemoveEntity(entity);
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