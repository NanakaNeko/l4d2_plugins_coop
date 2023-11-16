#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

int tanknum;
bool IsKickTank, IsFinal;

//使用一次指令整关只会出一个克，换图重开失败都会重置
//救援关使用会卡关，虽然加了检测但是最好别用

public Plugin myinfo = 
{
	name = "[L4D2]踢出多余坦克",
	description = "kick more tank",
	author = "奈",
	version = "1.2",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public void OnPluginStart()
{
    RegAdminCmd("sm_kickmoretank", KickMoreTanks, ADMFLAG_ROOT, "踢出多余坦克");
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("round_start", Event_Reset);
    HookEvent("finale_start", Event_FinaleStart);
}

public void Event_FinaleStart(Handle event, char[] name, bool dontBroadcast)
{
    IsFinal = true;
    KickMoreTank(0);
}

void Event_Reset(Event event, const char[] name, bool dontBroadcast)
{
    tanknum = 0;
    IsKickTank = false;
    IsFinal = false;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int userid = event.GetInt("userid");
    int client = GetClientOfUserId(userid);
    if (!client || !IsClientInGame(client) || IsClientInKickQueue(client) || !IsPlayerAlive(client))
        return;
    if (IsFakeClient(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == 8)
        KickMoreTank(client);
}

void KickMoreTank(int client)
{
    tanknum += 1;
    if(IsFinal && IsKickTank)
    {
        IsKickTank = false;
        PrintToChatAll("\x01[\x04!\x01] \x05救援关恢复正常刷克.");
    }
    if(tanknum > 1 && IsKickTank)
        KickClient(client);
}

Action KickMoreTanks(int client, int args)
{
    if(args == 0)
        PrintToChat(client, "\x01[\x04!\x01] \x05请输入正确命令!");
    else if(args == 1)
    {
        char tmp[4];
        GetCmdArg(1, tmp, sizeof(tmp));
        if (strcmp(tmp, "on", false) == 0) {
            IsKickTank = true;
            PrintToChatAll("\x01[\x04!\x01] \x05开启单个坦克,本次关卡只会刷出一个坦克.");
        }
        else if (strcmp(tmp, "off", false) == 0) {
            IsKickTank = false;
            PrintToChatAll("\x01[\x04!\x01] \x05关闭单个坦克,本次关卡正常生成坦克.");
        }
        else
            PrintToChat(client, "\x01[\x04!\x01] \x05请输入正确的命令!");
    }
    return Plugin_Handled;
}