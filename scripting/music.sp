#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

KeyValues key;
bool b_playing, b_leftarea;
char SavePath[PLATFORM_MAX_PATH], sPath[PLATFORM_MAX_PATH], sName[255];

public Plugin myinfo = 
{
	name = "[L4D2]点歌",
	author = "奈",
	description = "在安全区域可以点歌给所有人",
	version = "1.0.2",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public void OnPluginStart()
{
    init();
    RegConsoleCmd("sm_music", Cmd_MusicMenu);
}

void init()
{
    key = CreateKeyValues("Music");
    BuildPath(Path_SM, SavePath, 255, "data/Music.cfg");
    if(!FileExists(SavePath))
	{
		SetFailState("文件不存在: %s", SavePath);
		return;
	}
    if(!key.ImportFromFile(SavePath))
	{
        SetFailState("无法加载%s文件!", SavePath);
        return;
    }
}

public void OnMapStart()
{
    LoadSound();
}

void LoadSound()
{
    char sInfo[PLATFORM_MAX_PATH];
    KvRewind(key);
    if (key.GotoFirstSubKey())
    {
        do
        {
            KvGetSectionName(key, sInfo, sizeof(sInfo));
            PrecacheSound(sInfo);
        }
        while(KvGotoNextKey(key, true));
    }
}

Action Cmd_MusicMenu(int client, int args)
{
    if(!b_leftarea)
        MusicMenu(client);
    else
        PrintToChat(client, "\x03[提示] \x05已离开安全区域,无法点歌");
    return Plugin_Handled;
}

void MusicMenu(int client)
{
	Menu menu = new Menu(MusicMenuDetail);
	menu.SetTitle("音乐菜单\n——————————————\n提示:三方音乐请下载扩充包\n——————————————");
	menu.AddItem("a", "播放音乐");
	menu.AddItem("b", "停止音乐");
	menu.Display(client, 20);
}

//主面板菜单选择后执行
public int MusicMenuDetail(Menu menu, MenuAction action, int client, int param)
{
    if(b_leftarea)
        return 0;
    char info[2];
    menu.GetItem(param, info, sizeof(info));
    if(action == MenuAction_Select)
	{
		switch(info[0])
		{
			case 'a':
			{
				PlayMusic(client);
			}
			case 'b':
			{
				StopMusic(client);
			}
        }
    }
    else if(action == MenuAction_End)
        delete menu;
    return 0;
}

void PlayMusic(int client)
{
	Menu menu = new Menu(PlayMusicDetail);
	menu.SetTitle("选择音乐:");
	char sBuffer[255];
	char sInfo[PLATFORM_MAX_PATH];
	KvRewind(key);
	if (key.GotoFirstSubKey())
	{
        do
        {
            KvGetSectionName(key, sInfo, sizeof(sInfo));
            KvGetString(key, "name", sBuffer, sizeof(sBuffer));
            menu.AddItem(sInfo, sBuffer);
        }
        while(KvGotoNextKey(key, true));
	}
	menu.Display(client, 20);
}

//主面板菜单选择后执行
public int PlayMusicDetail(Menu menu, MenuAction action, int client, int param)
{
    if(b_leftarea)
        return 0;
    if(b_playing)
    {
        PrintToChat(client, "\x03[音乐] \x05当前有歌曲正在播放");
        return 0;
    }
    if(action == MenuAction_Select)
	{
        char sInfo[PLATFORM_MAX_PATH], sBuffer[255];
        menu.GetItem(param, sInfo, sizeof(sInfo), _, sBuffer, sizeof(sBuffer));
        strcopy(sPath, sizeof(sPath), sInfo);
        strcopy(sName, sizeof(sName), sBuffer);
        PlaySound(sInfo, client);
        b_playing = true;
	}
    else if(action == MenuAction_End)
        delete menu;
    return 0;
}

//播放声音.
void PlaySound(const char[] sample,int client)
{
    for(int i = 1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
	        EmitSoundToClient(i, sample, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
    }
    CreateTimer(1.0, timer_notify, _, TIMER_REPEAT);
    PrintToChatAll("\x03[音乐] \x05%N \x04点歌 \x05%s", client, sName);
}

Action timer_notify(Handle timer)
{
    if(b_playing)
    {
        PrintCenterTextAll("正在播放 - %s", sName);
        return Plugin_Continue;
    }
    else
    {
        PrintCenterTextAll("播放结束 - %s", sName);
        return Plugin_Stop;
    }
}

void StopMusic(int client)
{
    if(!b_playing)
    {
        PrintToChat(client, "\x03[音乐] \x05当前没有正在播放歌曲");
        return;
    }
    for(int i = 1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
	        StopSound(i, SNDCHAN_STATIC, sPath);
    }
    b_playing = false;
    PrintToChatAll("\x03[音乐] \x05%N \x04关闭了 \x05%s", client, sName);
}

public void OnClientPutInServer(int client)
{
    if(IsClientInGame(client) && !IsFakeClient(client) && b_playing)
        EmitSoundToClient(client, sPath, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}

public void OnClientDisconnect(int client)
{
    if(IsClientInGame(client) && !IsFakeClient(client) && b_playing)
        StopSound(client, SNDCHAN_STATIC, sPath);
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
    if(b_playing)
        StopMusic(0);
    b_leftarea = true;
    return Plugin_Stop;
}
