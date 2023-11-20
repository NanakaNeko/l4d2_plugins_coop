#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
ConVar
	cvarServerNameFormatCase1,
	cvarMpGameMode,
	cvarHostName,
	cvarMainName,
	cvarMod,
	cvarHostPort;
Handle
	HostName = INVALID_HANDLE;
char
	SavePath[256],
	g_sDefaultN[68];
static Handle
	g_hHostNameFormat;

public Plugin myinfo = 
{
	name = "[L4D2]Server Name",
	author = "东,奈",
	description = "基于Anne的服务器名修改，用于zonemod药抗",
	version = "1.0",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public void OnPluginStart()
{
	HostName = CreateKeyValues("servername");
	BuildPath(Path_SM, SavePath, 255, "data/servername.txt");
	if (FileExists(SavePath))
	{
		FileToKeyValues(HostName, SavePath);
	}
	cvarHostName = FindConVar("hostname");
	cvarHostPort = FindConVar("hostport");
	cvarMainName = CreateConVar("sn_main_name", "求死之路");
	g_hHostNameFormat = CreateConVar("sn_hostname_format", "{hostname}{gamemode}");
	cvarServerNameFormatCase1 = CreateConVar("sn_hostname_format1", "{Confogl}{Full}{MOD}");
	cvarMod = FindConVar("l4d2_addons_eclipse");
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	HookEvent("player_bot_replace", Event_PlayerTeam, EventHookMode_Post);
	HookEvent("bot_player_replace", Event_PlayerTeam, EventHookMode_Post);

	Update();
}

public void OnPluginEnd(){
	cvarMpGameMode = null;
	cvarMpGameMode = null;
	cvarMod = null;
}

public void OnAllPluginsLoaded()
{
	cvarMpGameMode = FindConVar("l4d_ready_cfg_name");
	cvarMod = FindConVar("l4d2_addons_eclipse");
}

public void OnConfigsExecuted()
{	
	if(cvarMpGameMode != null){
		cvarMpGameMode.AddChangeHook(OnCvarChanged);
	}else if(FindConVar("l4d_ready_cfg_name")){
		cvarMpGameMode = FindConVar("l4d_ready_cfg_name");
		cvarMpGameMode.AddChangeHook(OnCvarChanged);
	}
	if(cvarMod != null){
		cvarMod.AddChangeHook(OnCvarChanged);
	}else if(FindConVar("l4d2_addons_eclipse")){
		cvarMpGameMode = FindConVar("l4d2_addons_eclipse");
		cvarMpGameMode.AddChangeHook(OnCvarChanged);
	}
	Update();
}

public void Event_PlayerTeam( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	Update();
}

public void OnMapStart()
{
	HostName = CreateKeyValues("servername");
	BuildPath(Path_SM, SavePath, 255, "data/servername.txt");
	FileToKeyValues(HostName, SavePath);
}

public void Update(){

	if(cvarMpGameMode == null){
		ChangeServerName();
	}else{
		UpdateServerName();
	}
}

public void OnCvarChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	Update();
}

public void UpdateServerName(){
	char sReadyUpCfgName[128], FinalHostname[128], buffer[128];
	GetConVarString(cvarServerNameFormatCase1, FinalHostname, sizeof(FinalHostname));
	GetConVarString(cvarMpGameMode, sReadyUpCfgName, sizeof(sReadyUpCfgName));	
	
	GetConVarString(cvarMpGameMode, buffer, sizeof(buffer));
	Format(buffer, sizeof(buffer),"[%s]", buffer);
	ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}", buffer);

	if(IsTeamFull()){
		ReplaceString(FinalHostname, sizeof(FinalHostname), "{Full}", "");
	}else
	{
		ReplaceString(FinalHostname, sizeof(FinalHostname), "{Full}", "[缺人]");
	}
	if(cvarMod == null || (cvarMod != null && GetConVarInt(cvarMod) != 0)){
		ReplaceString(FinalHostname, sizeof(FinalHostname), "{MOD}", "");
	}else
	{
		ReplaceString(FinalHostname, sizeof(FinalHostname), "{MOD}", "[无MOD]");
	}
	ChangeServerName(FinalHostname);
}

bool IsTeamFull(){
	int sum = 0;
	for(int i = 1; i <= MaxClients; i++){
		if(IsPlayer(i) && !IsFakeClient(i)){
			sum ++;
		}
	}
	if(sum == 0){
		return true;
	}

	return sum >= (GetConVarInt(FindConVar("survivor_limit")) + GetConVarInt(FindConVar("z_max_player_zombies")));
	
}
bool IsPlayer(int client)
{
	if(IsValidClient(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3)){
		return true;
	}
	else{
		return false;
	}
}


void ChangeServerName(char[] sReadyUpCfgName = "")
{
	char sPath[128], ServerPort[128];
	GetConVarString(cvarHostPort, ServerPort, sizeof(ServerPort));
	KvJumpToKey(HostName, ServerPort, false);
	KvGetString(HostName,"hostname", sPath, sizeof(sPath));
	KvGoBack(HostName);
	char sNewName[128];
	if(strlen(sPath) == 0)
	{
		GetConVarString(cvarMainName, sNewName, sizeof(sNewName));
	}
	else
	{
		GetConVarString(g_hHostNameFormat, sNewName, sizeof(sNewName));
		ReplaceString(sNewName, sizeof(sNewName), "{hostname}", sPath);
		ReplaceString(sNewName, sizeof(sNewName), "{gamemode}", sReadyUpCfgName);
	}
	SetConVarString(cvarHostName, sNewName);
	SetConVarString(cvarMainName, sNewName);
	Format(g_sDefaultN, sizeof(g_sDefaultN), "%s", sNewName);
}

public bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}