#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>
#include <l4d2_ems_hud>

/**
----------------------------------------------------------------------------------------------------------------
-------------------------          注意！注意！注意！
-------------------------本插件仅锁定特感，没有关于坦克女巫小僵尸的设置
-------------------------实际使用需要搭配其他插件去除坦克女巫小僵尸等，详细可自己随意搭配插件组合
-------------------------单独本插件并不能完整体验生还者对抗生还者，请注意
----------------------------------------------------------------------------------------------------------------
-------------------------         模式大致说明
-------------------------随机复活模式，开局倒数时间内玩家无敌
-------------------------回合开始弹出菜单可选技能，shift + e 使用技能
-------------------------死亡玩家倒计时后随机位置复活
-------------------------每关累计击杀数量到达上限后，传送安全屋开始下一关
-------------------------救援关没有上限，想要结束请自主换图
----------------------------------------------------------------------------------------------------------------
**/

#define	SMOKER	1
#define	BOOMER	2
#define	HUNTER	3
#define	SPITTER	4
#define	JOCKEY	5
#define	CHARGER 6
#define	SI_CLASS_SIZE	7

//技能相关
#define SHIFT (buttons & IN_SPEED)
#define USE (buttons & IN_USE)
enum struct PlayerSkill
{
    int Select;
    float ClientSkillTime;
}
PlayerSkill Skill[MAXPLAYERS + 1];
bool SkillEnable;
float f_SkillTime;

ConVar z_special_limit[SI_CLASS_SIZE];
ConVar cv_FirstRoundTime, cv_RespawnTime, cv_TotalKillEnd, cv_EndRoundTime, cv_SkillTime;
int i_RespawnTime, i_TotalKillEnd;
int i_TimerNum, i_TotalKill, KillNumber[MAXPLAYERS + 1], RespawnTime[MAXPLAYERS + 1];
bool b_FinalMap, b_Print, b_End;
Handle g_hTimer;

public Plugin myinfo =
{
	name = "[L4D2]生还VS生还(随机复活)",
	author = "奈",
	description = "survivor vs survivor",
	version = "1.1.4",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public void OnPluginStart()
{
    cv_FirstRoundTime = CreateConVar("svs2_primary_round_time", "30", "首次回合时间", FCVAR_NOTIFY, true, 1.0);
    cv_RespawnTime = CreateConVar("svs2_respawn_time", "4", "玩家复活时间", FCVAR_NOTIFY, true, 1.0);
    cv_TotalKillEnd = CreateConVar("svs2_total_kill", "50", "玩家击杀总数达到多少结束回合", FCVAR_NOTIFY, true, 1.0);
    cv_EndRoundTime = CreateConVar("svs2_end_round_time", "5", "几秒后结束回合", FCVAR_NOTIFY, true, 1.0);
    cv_SkillTime = CreateConVar("svs2_skill_time", "60", "几秒使用一次技能", FCVAR_NOTIFY, true, 1.0);
    
    GetCvar();

    HookConVarChange(cv_RespawnTime, CvarChanged);
    HookConVarChange(cv_TotalKillEnd, CvarChanged);
    HookConVarChange(cv_SkillTime, CvarChanged);

    z_special_limit[SMOKER] = FindConVar("z_smoker_limit");
    z_special_limit[BOOMER] = FindConVar("z_boomer_limit");
    z_special_limit[HUNTER] = FindConVar("z_hunter_limit");
    z_special_limit[SPITTER] = FindConVar("z_spitter_limit");
    z_special_limit[JOCKEY] = FindConVar("z_jockey_limit");
    z_special_limit[CHARGER] = FindConVar("z_charger_limit");

    HookEvent("round_start", Event_RoundStart);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("map_transition", Event_RoundEnd);
    HookEvent("mission_lost", Event_RoundEnd);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("finale_vehicle_leaving", Event_RoundEnd);

    RegConsoleCmd("sm_mvp", Mvp_Info);
    RegConsoleCmd("sm_skill", cmd_Skill);
}

public void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvar();
}

void GetCvar()
{
    i_RespawnTime = GetConVarInt(cv_RespawnTime);
    i_TotalKillEnd = GetConVarInt(cv_TotalKillEnd);
    f_SkillTime = GetConVarFloat(cv_SkillTime);
}

public void OnMapStart()
{
    b_FinalMap = false;
    ResetSvs();
    ResetData();
}

//回合开始重置
void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    ResetSvs();
    ResetData();
    Kill_Hud_Enable();
}

void Kill_Hud_Enable()
{
    delete g_hTimer;
    RequestFrame(RemoveSlots);
    g_hTimer = CreateTimer(1.0, Kill_Hud, _, TIMER_REPEAT);
}

void RemoveSlots()
{
	if(HUDSlotIsUsed(HUD_MID_TOP))
		RemoveHUD(HUD_MID_TOP);
}

Action Kill_Hud(Handle timer) 
{
    if(!b_FinalMap)
        HUDSetLayout(HUD_MID_TOP, HUD_FLAG_TEXT|HUD_FLAG_NOBG|HUD_FLAG_ALIGN_CENTER|HUD_FLAG_BLINK, "累计击杀: [ %d ] | 结束数量: [ %d ]", i_TotalKill, i_TotalKillEnd);
    else
        HUDSetLayout(HUD_MID_TOP, HUD_FLAG_TEXT|HUD_FLAG_NOBG|HUD_FLAG_ALIGN_CENTER|HUD_FLAG_BLINK, "累计击杀: [ %d ] | 结束数量: [ 无限 ]", i_TotalKill);
    HUDPlace(HUD_MID_TOP, 0.00, 0.05, 1.0, 0.03);
    return Plugin_Continue;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if(!b_Print)
    {
        PrintInfos(0);
        b_Print = true;
    }
    b_End = true;
    delete g_hTimer;
    ResetData();
}

void ResetSvs()
{
    b_Print = false;
    b_End = false;
    i_TotalKill = 0;
    SkillEnable = false;
}

void ResetData()
{
    for(int i = 1; i <= MaxClients; i++)
    {
        KillNumber[i] = 0;
        RespawnTime[i] = 0;
    }   
}

//玩家死亡
void Event_PlayerDeath(Event event, const char []name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int damagetype = GetEventInt(event, "type");
    if(IsSurvivor(victim))
    {
        if(IsSurvivor(attacker))
        {
            i_TotalKill++;
            KillNumber[attacker]++;
            PrintHintTextToAll("玩家 <%N> 击杀玩家 <%N>", attacker, victim);
            CreateTimer(1.0, Timer_Respawn, victim, TIMER_REPEAT);
        }
        else if(damagetype & DMG_FALL)
        {
            i_TotalKill++;
            PrintHintTextToAll("铸币玩家 <%N> 摔死了", victim);
            CreateTimer(1.0, Timer_Respawn, victim, TIMER_REPEAT);
        }
        else if(damagetype & DMG_DROWN && GetEntProp(victim, Prop_Data, "m_nWaterLevel") > 1)
        {
            i_TotalKill++;
            PrintHintTextToAll("铸币玩家 <%N> 淹死了", victim);
            CreateTimer(1.0, Timer_Respawn, victim, TIMER_REPEAT);
        }
        else
        {
            i_TotalKill++;
            PrintHintTextToAll("铸币玩家 <%N> 死在了奇怪的位置", victim);
            CreateTimer(1.0, Timer_Respawn, victim, TIMER_REPEAT);
        }
    }

    if(!b_FinalMap && !b_End && i_TotalKill >= i_TotalKillEnd)
    {
        PrintHintTextToAll("回合将在 %d 秒后结束！", GetConVarInt(cv_EndRoundTime));
        CreateTimer(GetConVarFloat(cv_EndRoundTime), Timer_End);
        b_End = true;
    }
}

Action Timer_End(Handle timer)
{
    if(!b_End)
        return Plugin_Handled;
    
    ExecuteCommand("warp_all_survivors_to_checkpoint");
    return Plugin_Handled;
}

Action Timer_Respawn(Handle timer, int client)
{
    if(!IsSurvivor(client) || IsPlayerAlive(client) || b_End)
    {
        RespawnTime[client] = 0;
        return Plugin_Stop;
    }

    RespawnTime[client]++;

    if (RespawnTime[client] <= i_RespawnTime)
    {
        PrintCenterText(client, "将在 %d 秒后重生", i_RespawnTime - RespawnTime[client] + 1);
    }
    else
    {
        RespawnSurvivor(client);
        PrintCenterText(client, "———— 重生完成 ————");
        RespawnTime[client] = 0;
        return Plugin_Stop;
    }
    return Plugin_Continue;
}

void ExecuteCommand(const char[] command, const char[] value = "")
{
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	ServerCommand("%s %s", command, value);
	ServerExecute();
	SetCommandFlags(command, flags);
}

Action Mvp_Info(int client, int args)
{
    PrintInfos(client);
    return Plugin_Handled;
}

void PrintInfos(int client)
{
    if(client == 0)
    {
        PrintToChatAll("\x05[\x03击杀统计\x05]");
        for(int i = 1; i <= MaxClients; i++)
        {
            if(IsSurvivor(i))
                PrintToChatAll("\x03击杀 \x04%d \x05- %N", KillNumber[i], i);
        }
    }
    else
    {
        PrintToChat(client, "\x05[\x03击杀统计\x05]");
        for(int i = 1; i <= MaxClients; i++)
        {
            if(IsSurvivor(i))
                PrintToChat(client, "\x03击杀 \x04%d \x05- %N", KillNumber[i], i);
        }
    }
}

void RespawnSurvivor(int client)
{
    if (IsSurvivor(client) && !IsPlayerAlive(client))
    {
        //复活
        L4D_RespawnPlayer(client);
        TeleportClient(client);
        //回血
        CheatCommand(client, "give", "health");
        SetEntProp(client, Prop_Send, "m_isGoingToDie", 0);
        SetEntPropFloat(client, Prop_Send, "m_healthBuffer", 0.0);
        SetEntProp(client, Prop_Send, "m_currentReviveCount", 0);
        SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 0);
        StopSound(client, SNDCHAN_STATIC, "player/heartbeatloop.wav");
    }
}

void TeleportClient(int client)
{
    if (IsSurvivor(client))
    {
        ForceCrouch(client);
        TeleportEntity(client, GetPosition(), NULL_VECTOR, NULL_VECTOR);
    }
}

float[] GetPosition()
{
    float fSpawnPos[3];
    if(L4D_GetRandomPZSpawnPosition(GetRandomSur(), GetRandomIntEx(1, 6), 30, fSpawnPos))
    {
        return fSpawnPos;
    }
    else
    {
        L4D_GetRandomPZSpawnPosition(GetRandomSur(), GetRandomIntEx(1, 6), 30, fSpawnPos);
        return fSpawnPos;
    }
}

void ForceCrouch(int client)
{
	SetEntProp(client, Prop_Send, "m_bDucked", 1);
	SetEntProp(client, Prop_Send, "m_fFlags", GetEntProp(client, Prop_Send, "m_fFlags") | FL_DUCKING);
}

//cheat命令
void CheatCommand(int client, char[] command, char[] args = "")
{
	int iFlags = GetCommandFlags(command);
	SetCommandFlags(command, iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, args);
	SetCommandFlags(command, iFlags);
}

public void OnPluginEnd()
{
    for (int i = 1; i < SI_CLASS_SIZE; i++)
        z_special_limit[i].RestoreDefault();

    FindConVar("survivor_max_incapacitated_count").RestoreDefault();
    FindConVar("director_no_mobs").RestoreDefault();
    FindConVar("director_no_specials").RestoreDefault();
    FindConVar("pipe_bomb_timer_duration").RestoreDefault();
    RemoveSlots();
    delete g_hTimer;
}

public void OnConfigsExecuted()
{
    for (int i = 1; i < SI_CLASS_SIZE; i++)
        z_special_limit[i].IntValue = 0;

    SetConVarInt(FindConVar("survivor_max_incapacitated_count"), 0);
    SetConVarInt(FindConVar("director_no_mobs"), 1);
    SetConVarInt(FindConVar("director_no_specials"), 1);
    SetConVarInt(FindConVar("pipe_bomb_timer_duration"), 3);

    if(L4D_IsMissionFinalMap(true))
        b_FinalMap = true;
}

//锁定特感生成
public Action L4D_OnSpawnSpecial(int &zombieClass, const float vecPos[3], const float vecAng[3])
{
	return Plugin_Handled;
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
    SetGodMode(true);
    i_TimerNum = GetConVarInt(cv_FirstRoundTime);
    CreateTimer(1.0, timer_god, _, TIMER_REPEAT);
    SkillEnable = true;
    for (int i = 1; i <= MaxClients; i++)
    {
        if(IsSurvivor(i) && IsPlayerAlive(i))
        {
            ShowSkillMenu(i);
            Skill[i].ClientSkillTime = GetEngineTime();
        }
    }
    return Plugin_Stop;
}

Action timer_god(Handle timer)
{
    if(b_End)
        return Plugin_Stop;
    
    if(i_TimerNum > 0)
    {
        PrintHintTextToAll("回合开始剩余 %d 秒", i_TimerNum--);
        PlaySound("weapons/hegrenade/beep.wav");
        return Plugin_Continue;
    }
    else
    {
        SetGodMode(false);
        PrintHintTextToAll("回合开始！");
        PlaySound("ui/survival_medal.wav");
        return Plugin_Stop;
    }
}

void SetGodMode(bool canset)
{
	int flags = GetCommandFlags("god");
	SetCommandFlags("god", flags & ~ FCVAR_NOTIFY);
	SetConVarInt(FindConVar("god"), canset);
	SetCommandFlags("god", flags);
}

int GetRandomSur()
{
	ArrayList array = new ArrayList();
	int client;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivor(i) && IsPlayerAlive(i))
		{
			array.Push(i);
		}
	}

	if (array.Length > 0)
	{
		client = array.Get(GetRandomIntEx(0, array.Length-1));
	}

	delete array;
	return client;
}

// https://github.com/bcserv/smlib/blob/transitional_syntax/scripting/include/smlib/math.inc
int GetRandomIntEx(int min, int max)
{
	int random = GetURandomInt();

	if (random == 0)
		random++;

	return RoundToCeil(float(random) / (float(2147483647) / float(max - min + 1))) + min - 1;
}

//播放声音.
void PlaySound(const char[] sample)
{
	EmitSoundToAll(sample, SOUND_FROM_PLAYER, SNDCHAN_STATIC, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

//是否是生还者
stock bool IsSurvivor(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 2;
}

/**
------------------------------技能设置----------------------------------
**/

Action cmd_Skill(int client, int args)
{
    ShowSkillMenu(client);
    return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
    if(SkillEnable && Skill[client].Select != 0)
    {
        if(SHIFT && USE)
        {
            float fTime = GetEngineTime() - Skill[client].ClientSkillTime - f_SkillTime;
            if (fTime < 0.0)
            {
                return Plugin_Continue;
            }
            
            if(Skill[client].Select == 1)
            {
                Stealth(client);
            }
            else if(Skill[client].Select == 2)
            {
                HealSur(client);
            }
            else if(Skill[client].Select == 3)
            {
                Laser(client);
            }
            else if(Skill[client].Select == 4)
            {
                GiveRandomGrenade(client);
            }
            else if(Skill[client].Select == 5)
            {
                GlowSur(client);
            }
            PrintToChat(client, "\x01[\x04!\x01] \x03%s \x05技能使用成功，请等待 \x04%.0f \x05秒后再次使用技能", SkillName(client), f_SkillTime);
            Skill[client].ClientSkillTime = GetEngineTime();
        }
    }
    return Plugin_Continue;
}

//技能面板
void ShowSkillMenu(int client)
{
	if(!SkillEnable)
	{
		PrintToChat(client, "\x01[\x04!\x01] \x03技能选择在出门后才可启动！");
		return;
	}
	if(IsSurvivor(client))
	{
        Menu menu = new Menu(ShowSkillMenuDetail);
        menu.SetTitle("技能选择菜单\n技能CD: %.0f 秒\n按shift+e使用技能\n————————————", f_SkillTime);
        menu.AddItem("skill0", "无技能");
        if(Skill[client].Select == 1) menu.AddItem("skill1", "隐身(3秒)[已启用]");
        else menu.AddItem("skill1", "隐身(3秒)");
        if(Skill[client].Select == 2) menu.AddItem("skill2", "随机药品[已启用]");
        else menu.AddItem("skill2", "随机药品");
        if(Skill[client].Select == 3) menu.AddItem("skill3", "激光瞄准[已启用]");
        else menu.AddItem("skill3", "激光瞄准");
        if(Skill[client].Select == 4) menu.AddItem("skill4", "随机手雷[已启用]");
        else menu.AddItem("skill4", "随机手雷");
        if(Skill[client].Select == 5) menu.AddItem("skill5", "透视(3秒)[已启用]");
        else menu.AddItem("skill5", "透视(3秒)");
        menu.Display(client, 30);
	}
}

//获取技能名称
char[] SkillName(int client)
{
    char Name[64];
    if(Skill[client].Select == 0)
        Format(Name, sizeof(Name), "无");
    else if(Skill[client].Select == 1)
        Format(Name, sizeof(Name), "隐身");
    else if(Skill[client].Select == 2)
        Format(Name, sizeof(Name), "随机药品");
    else if(Skill[client].Select == 3)
        Format(Name, sizeof(Name), "激光瞄准");
    else if(Skill[client].Select == 4)
        Format(Name, sizeof(Name), "随机手雷");
    else if(Skill[client].Select == 5)
        Format(Name, sizeof(Name), "透视");
    return Name;
}

//主面板菜单选择后执行
int ShowSkillMenuDetail(Menu menu, MenuAction action, int client, int num)
{
    if (action == MenuAction_Select)
    {
        switch(num)
        {
            case 0:
            {
                Skill[client].Select = 0;
            }
            case 1:
            {
                Skill[client].Select = 1;
            }
            case 2:
            {
                Skill[client].Select = 2;
            }
            case 3:
            {
                Skill[client].Select = 3;
            }
            case 4:
            {
                Skill[client].Select = 4;
            }
            case 5:
            {
                Skill[client].Select = 5;
            }
        }
        PrintToChat(client, "\x01[\x04!\x01] \x05选择 \x03%s \x05技能成功！", SkillName(client));
    }
    if (action == MenuAction_End)	
        delete menu;
    return 0;
}

//隐身
void Stealth(int client)
{
    int r, g, b, a;
    GetEntityRenderColor(client, r, g, b, a);
    SetEntityRenderColor(client, 0, 0, 0, 0);
    DataPack dp = new DataPack();
    dp.WriteCell(r);
    dp.WriteCell(g);
    dp.WriteCell(b);
    dp.WriteCell(a);
    dp.WriteCell(client);
    CreateTimer(3.0, Timer_Stealth, dp);
}

Action Timer_Stealth(Handle timer, DataPack dp)
{
    dp.Reset();
    int r, g, b, a, client;
    r = dp.ReadCell();
    g = dp.ReadCell();
    b = dp.ReadCell();
    a = dp.ReadCell();
    client = dp.ReadCell();
    SetEntityRenderColor(client, r, g, b, a);
    delete dp;
    return Plugin_Handled;
}

//回血
void HealSur(int client)
{
    int random = GetRandomIntEx(0, 1);
    if(random)
        CheatCommand(client, "give", "pain_pills");
    else
        CheatCommand(client, "give", "adrenaline");
}

//激光瞄准
void Laser(int client)
{
    CheatCommand(client, "upgrade_add", "laser_sight");
}

//给雷
void GiveRandomGrenade(int client)
{
    int random = GetRandomIntEx(0, 2);
    if(random == 0)
        CheatCommand(client, "give", "molotov");
    else if(random == 1)
        CheatCommand(client, "give", "pipe_bomb");
    else if(random == 2)
        CheatCommand(client, "give", "vomitjar");
}

void GlowSur(int client)
{
    if(CountSur() < 2)
    {
        PrintHintText(client, "当前玩家不足，技能使用失败！ %.0f 秒后再使用技能！", f_SkillTime);
        return;
    }
    
    int victim = GetRandomSur();
    if(victim != client)
    {
        SetGlow(victim, true);
        PrintHintText(victim, "被技能命中！全图发光显示 3 秒！");
        PrintHintText(client, "技能命中 %N ！命中玩家全图发光 3 秒！", victim);
        CreateTimer(3.0, Timer_RemoveGlow, victim);
    }
    else
    {
        GlowSur(client);
    }
}

Action Timer_RemoveGlow(Handle timer, int client)
{
    SetGlow(client, false);
    return Plugin_Handled;
}

void SetGlow(int client, bool glow)
{
    if(glow)
    {
        SetEntProp(client, Prop_Send, "m_iGlowType", 3);
        SetEntProp(client, Prop_Send, "m_glowColorOverride", 255);
    }
    else
    {
        SetEntProp(client, Prop_Send, "m_iGlowType", 0);
        SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
    }
}

int CountSur()
{
    int snum = 0;
    for(int i = 1;i <= MaxClients; i++)
    {
        if(IsSurvivor(i) && IsPlayerAlive(i))
            snum++;
    }
    return snum;
}