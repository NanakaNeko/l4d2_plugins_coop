#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

//玩家连接时播放的声音
#define IsConnecting        "ambient/alarms/klaxon1.wav"
//玩家连接完成播放的声音
#define IsConnected         "buttons/button11.wav"
//玩家离开时播放的声音
#define IsDisconnect        "buttons/button4.wav"

ConVar cv_Isconnecting;
bool showNotify[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[L4D2]加入退出提示",
	description = "connected and disconnected message",
	author = "奈",
	version = "1.0",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public void OnPluginStart()
{
    cv_Isconnecting = CreateConVar("l4d2_connecting_notify", "1", "连接中提示", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

public void OnMapStart()
{
    PrecacheSound(IsConnecting);
    PrecacheSound(IsConnected);
    PrecacheSound(IsDisconnect);
}

//玩家连接
public void OnClientConnected(int client)
{   
	if(!IsFakeClient(client) && cv_Isconnecting.BoolValue){
        PrintToChatAll("\x04[服务器] \x05玩家\x03%N\x05连接中...", client);
        PlaySound(IsConnecting);
    }
}

//玩家进入游戏
public void OnClientPutInServer(int client)
{
    if(!IsFakeClient(client) && !showNotify[client]){
        PrintToChatAll("\x04[服务器] \x05玩家\x03%N\x04(%s)\x05加入", client, GetSteamId(client));
        PlaySound(IsConnected);
        showNotify[client] = true;
    }
}

//玩家离开游戏
public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    event.BroadcastDisabled = true;

    int client = GetClientOfUserId(GetEventInt(event,"userid"));

    if (!(1 <= client <= MaxClients))
        return Plugin_Handled;

    if (!IsClientInGame(client))
        return Plugin_Handled;

    if (IsFakeClient(client))
        return Plugin_Handled;

    char reason[64], message[64];
    GetEventString(event, "reason", reason, sizeof(reason));

    if(StrContains(reason, "connection rejected", false) != -1)
    {
        Format(message,sizeof(message),"连接被拒绝");
    }
    else if(StrContains(reason, "timed out", false) != -1)
    {
        Format(message,sizeof(message),"超时");
    }
    else if(StrContains(reason, "by console", false) != -1)
    {
        Format(message,sizeof(message),"控制台退出");
    }
    else if(StrContains(reason, "by user", false) != -1)
    {
        Format(message,sizeof(message),"主动断开连接");
    }
    else if(StrContains(reason, "ping is too high", false) != -1)
    {
        Format(message,sizeof(message),"ping太高了");
    }
    else if(StrContains(reason, "No Steam logon", false) != -1)
    {
        Format(message,sizeof(message),"steam验证失败/游戏闪退");
    }
    else if(StrContains(reason, "Steam account is being used in another", false) != -1)
    {
        Format(message,sizeof(message),"steam账号被顶");
    }
    else if(StrContains(reason, "Steam Connection lost", false) != -1)
    {
        Format(message,sizeof(message),"steam断线");
    }
    else if(StrContains(reason, "This Steam account does not own this game", false) != -1)
    {
        Format(message,sizeof(message),"家庭共享账号");
    }
    else if(StrContains(reason, "Validation Rejected", false) != -1)
    {
        Format(message,sizeof(message),"验证失败");
    }
    else if(StrContains(reason, "Certificate Length", false) != -1)
    {
        Format(message,sizeof(message),"certificate length");
    }
    else if(StrContains(reason, "Pure server", false) != -1)
    {
        Format(message,sizeof(message),"纯净服务器");
    }
    else
    {
        message = reason;
    }

    PrintToChatAll("\x04[服务器] \x05玩家\x03%N\x05退出 - 理由: [\x04%s\x05]", client, message);
    PlaySound(IsDisconnect);
    showNotify[client] = false;
    return Plugin_Handled;
}

//播放声音.
void PlaySound(const char[] sample) {
	EmitSoundToAll(sample, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}

//获取steamid
char[] GetSteamId(int client)
{
	char id[32];
	GetClientAuthId(client, AuthId_Engine, id, sizeof(id), true);
	return id;
}
