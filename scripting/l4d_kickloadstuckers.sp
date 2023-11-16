#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法

#include <sourcemod>
#define PLUGIN_VERSION "1.3-2023/6/9"

public Plugin myinfo = 
{
	name = "L4D Kick Load Stuckers",
	author = "AtomicStryker, HarryPotter",
	description = "Kicks Clients that get stuck in server connecting state",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=103203"
}

ConVar g_hCvarDuration, g_hCvarImmuneAccess;
float g_fCvarDuration;
char g_sCvarImmuneAccess[16];

Handle LoadingTimer[MAXPLAYERS+1];

bool bLate;
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) 
{
	EngineVersion test = GetEngineVersion();
	
	if( test != Engine_Left4Dead2 && test != Engine_Left4Dead )
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	
	bLate = late;
	return APLRes_Success; 
}

public void OnPluginStart()
{
	g_hCvarDuration = 			CreateConVar("l4d_kickloadstuckers_duration", 				"150", "卡在连接状态多久被踢出服务器. (默认150秒) ", 	FCVAR_NOTIFY, true, 1.0);
	g_hCvarImmuneAccess = 		CreateConVar("l4d_kickloadstuckers_immune_access_flag", 	"z", 	"达到多少级别可以免疫被踢. (不填 = 所有, -1: 没有人)", FCVAR_NOTIFY);
	CreateConVar("l4d_kickloadstuckers_version", PLUGIN_VERSION, "Version of L4D Kick Load Stuckers", FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	//AutoExecConfig(true, "l4d_kickloadstuckers");

	GetCvars();
	g_hCvarDuration.AddChangeHook(ConVarChanged_Cvars);
	g_hCvarImmuneAccess.AddChangeHook(ConVarChanged_Cvars);

	RegAdminCmd("sm_kickloading", KickLoaders, ADMFLAG_KICK, "踢出正在连接玩家");
	RegAdminCmd("sm_kickloader", KickLoaders, ADMFLAG_KICK, "踢出正在连接玩家");

	if(bLate)
	{
		for (int client = 1; client <= MaxClients; client++)
		{
			if (IsClientConnected(client) && !IsClientInGame(client))
			{
				LoadingTimer[client] = CreateTimer(g_fCvarDuration, CheckClientIngame, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
	}
}

//Cvars-------------------------------

void ConVarChanged_Cvars(ConVar hCvar, const char[] sOldVal, const char[] sNewVal)
{
	GetCvars();
}

void GetCvars()
{
	g_fCvarDuration = g_hCvarDuration.FloatValue;
	g_hCvarImmuneAccess.GetString(g_sCvarImmuneAccess, sizeof(g_sCvarImmuneAccess));
}

//Sourcemod API Forward-------------------------------

public void OnClientConnected(int client)
{
	delete LoadingTimer[client];
	LoadingTimer[client] = CreateTimer(g_fCvarDuration, CheckClientIngame, client, TIMER_FLAG_NO_MAPCHANGE); //on successfull connect the Timer is set in motion
}

public void OnClientDisconnect(int client)
{
	delete LoadingTimer[client];
}

//Command-------------------------------

Action KickLoaders(int client, int args)
{
	PrintToChatAll("\x01[\x04!\x01] \x05管理员\x03%N\x05踢出所有正在连接玩家.", client);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsClientInGame(i))
		{
			KickClient(i, "在连接状态被管理员踢出!");
		}
	}
	return Plugin_Handled;
}

//Timer & Frame-------------------------------

Action CheckClientIngame(Handle timer, any client)
{
	LoadingTimer[client] = null;

	if (!IsClientConnected(client)) return Plugin_Continue; //OnClientDisconnect() should handle this, but you never know
	
	if (!IsClientInGame(client))
	{
		char time[21];
		FormatTime(time, sizeof(time), "%d/%m/%Y %H:%M:%S", -1);
		//player log file code. name and steamid only
		char file[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, file, sizeof(file), "logs/kickloadstuckers.log");
	
		char steamid[128];
		GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));

		if (HasAccess(steamid, g_sCvarImmuneAccess) == true)
		{
			LogToFileEx(file, "[%s] %N (%s) - 卡在连接状态太久了，但是因为有管理权限未被踢.", time, client, steamid);
			return Plugin_Continue;
		}
		
		KickClient(client, "卡在连接状态太久了!");
	
		PrintToChatAll("\x01[\x04!\x01] \x03%N\x05卡在连接状态\x04%.0f\x05秒被踢出服务器.", client, g_fCvarDuration);
		
		LogToFileEx(file, "[%s] %N (%s) - 卡在连接状态太久了被踢出服务器.", time, client, steamid); // this logs their steamids and names. to be banned.
	}
	
	return Plugin_Continue;
}

bool HasAccess(char[] steamid, char[] g_sAcclvl)
{
	// no permissions set
	if (strlen(g_sAcclvl) == 0)
		return true;

	else if (StrEqual(g_sAcclvl, "-1"))
		return false;

	// check permissions
	AdminId id = FindAdminByIdentity(AUTHMETHOD_STEAM, steamid);
	if(id == INVALID_ADMIN_ID) return false;

	int flag = id.GetFlags(Access_Real);
	if ( flag & ReadFlagString(g_sAcclvl) || flag & ADMFLAG_ROOT)
	{
		return true;
	}

	return false;
}