#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <colors>
#include <geoip>
#include <shop>

//玩家连接时播放的声音
#define IsConnecting        "ambient/alarms/klaxon1.wav"
//玩家连接完成播放的声音
#define IsConnected         "buttons/button11.wav"
//玩家离开时播放的声音
#define IsDisconnect        "buttons/button4.wav"
//玩家离开安全屋的声音
#define IsLeftSafeArea      "level/countdown.wav"
#define IsStart             "level/loud/bell_break.wav"

ConVar cv_SafeArea, cv_Isconnecting, cv_Country, cv_SteamId;
bool b_shop, showNotify[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "[L4D2]提示信息音效",
	description = "notify",
	author = "奈",
	version = "1.8.1",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public void OnPluginStart()
{
    cv_Isconnecting = CreateConVar("l4d2_connecting_notify", "1", "连接中提示", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cv_Country = CreateConVar("l4d2_country_notify", "1", "加入服务器后国家提示", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cv_SteamId = CreateConVar("l4d2_steamid_notify", "1", "加入服务器后SteamId提示", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    cv_SafeArea = CreateConVar("l4d2_leftsafe_sound", "1", "离开安全屋提示音", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);
}

public void OnAllPluginsLoaded()
{
    b_shop = LibraryExists("shop");
}

public void OnLibraryAdded(const char[] name)
{
    if(StrEqual(name, "shop"))
		b_shop = true;
}

public void OnLibraryRemoved(const char[] name)
{
    if(StrEqual(name, "shop"))
        b_shop = false;
}

public void OnMapStart()
{
    PrecacheSound(IsConnecting);
    PrecacheSound(IsConnected);
    PrecacheSound(IsDisconnect);
    PrecacheSound(IsLeftSafeArea);
    PrecacheSound(IsStart);
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
	if(cv_SafeArea.BoolValue){
        PlaySound(IsLeftSafeArea);
        CreateTimer(3.0, SoundTimer, _, TIMER_FLAG_NO_MAPCHANGE);
    }

	return Plugin_Continue;
}

public Action SoundTimer(Handle timer)
{
    PlaySound(IsStart);
    return Plugin_Continue;
}

//玩家连接
public void OnClientConnected(int client)
{   
	if(!IsFakeClient(client) && cv_Isconnecting.BoolValue){
        CPrintToChatAll("{green}[服务器] {olive}玩家{blue}%N{olive}申请进入牢房...", client);
        //PrintToChatAll("\x03[服务器] \x05玩家\x03%N\x05连接中...", client);
        PlaySound(IsConnecting);
    }
}

//玩家进入游戏
public void OnClientPutInServer(int client)
{
    if(!IsFakeClient(client) && !showNotify[client]){
        char buffer[128], steamid[64];
        if(cv_Country.BoolValue)
            Format(buffer, sizeof(buffer), "{olive}来自{blue}%s{olive}的", GetCountry(client));
        else
            Format(buffer, sizeof(buffer), "{olive}");
        if(cv_SteamId.BoolValue)
            Format(steamid, sizeof(steamid), "{green}(%s)", GetSteamId(client));
        else
            Format(steamid, sizeof(steamid), "");
        CPrintToChatAll("{green}[服务器] %s玩家{blue}%N%s{olive}入狱", buffer, client, steamid);
        if(b_shop)
            CPrintToChatAll("{green}[服务器] {blue}%N{olive}本服务器游玩时长 {green}%.2f {olive}小时", client, Shop_Get_GetPlayerTime(client));
        //PrintToChatAll("\x03[服务器] \x05玩家\x04%N(\x01%s\x05)加入", client, GetSteamId(client));
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

    CPrintToChatAll("{green}[服务器] {olive}玩家{blue}%N{olive}越狱 - 理由: [{green}%s{olive}]", client, message);
    //PrintToChatAll("\x03[服务器] \x05玩家\x04%N\x05退出 - 理由: [\x04%s\x05]", client, message);
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

char[] GetCountry(int client)
{
    char ip[16], Country[64];
    GetClientIP(client, ip, sizeof(ip));
    if(!GeoipCountry(ip, Country, sizeof(Country)))
        Format(Country, sizeof(Country), "未知国家");
    if(StrContains(Country, "China", false) != -1)
        Format(Country,sizeof(Country),"中国");
    else if(StrContains(Country, "Taiwan", false) != -1)
        Format(Country,sizeof(Country),"中国台湾");
    else if(StrContains(Country, "Hong Kong", false) != -1)
        Format(Country,sizeof(Country),"中国香港");
    else if(StrContains(Country, "America", false) != -1)
        Format(Country,sizeof(Country),"美国");
    else if(StrContains(Country, "South Korea", false) != -1)
        Format(Country,sizeof(Country),"韩国");
    else if(StrContains(Country, "Japan", false) != -1)
        Format(Country,sizeof(Country),"日本");
    else if(StrContains(Country, "Philippines", false) != -1)
        Format(Country,sizeof(Country),"菲律宾");
    else if(StrContains(Country, "India", false) != -1)
        Format(Country,sizeof(Country),"印度");
    else if(StrContains(Country, "Singapore", false) != -1)
        Format(Country,sizeof(Country),"新加坡");
    else if(StrContains(Country, "Indonesia", false) != -1)
        Format(Country,sizeof(Country),"印度尼西亚");
    else if(StrContains(Country, "Vietnam", false) != -1)
        Format(Country,sizeof(Country),"越南");
    else if(StrContains(Country, "Russia", false) != -1)
        Format(Country,sizeof(Country),"俄罗斯");
    return Country;
}

