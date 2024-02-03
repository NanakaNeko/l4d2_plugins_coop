#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <left4dhooks>

/**
----------------------------------------------------------------------------------------------------------------
-------------------------          注意！注意！注意！
-------------------------本插件仅锁定特感，没有关于坦克女巫小僵尸的设置
-------------------------实际使用需要搭配其他插件去除坦克女巫小僵尸等，详细可自己随意搭配插件组合
-------------------------单独本插件并不能完整体验生还者对抗生还者，请注意
----------------------------------------------------------------------------------------------------------------
-------------------------         模式大致说明
-------------------------固定回合模式，开局倒数时间内玩家无敌，下蹲可加速移动
-------------------------60秒内无人死亡，开启全局透视，所有玩家发光几秒，加速回合，防止玩家只蹲不进攻
-------------------------等待死亡人数为1时复活死亡玩家，重新开始回合
-------------------------每关3回合结束，传送安全屋开始下一关
-------------------------救援关5回合结束，不再复活玩家，可以选择自杀重开，或者坐载具离开，投票换图等
----------------------------------------------------------------------------------------------------------------
**/

#define	SMOKER	1
#define	BOOMER	2
#define	HUNTER	3
#define	SPITTER	4
#define	JOCKEY	5
#define	CHARGER 6
#define	SI_CLASS_SIZE	7

ConVar z_special_limit[SI_CLASS_SIZE], survivor_crouch_speed;
ConVar cv_FirstRoundTime, cv_RoundTime, cv_Color, cv_ColorTime;
int i_TimerNum, i_RoundNumber, i_Color, i_TimerColorNum, KillNumber[MAXPLAYERS + 1], i_CountSurvivor;
bool b_FinalMap, b_Print, b_RoundEnd;
Handle t_glow;

public Plugin myinfo =
{
	name = "[L4D2]生还VS生还(固定回合)",
	author = "奈",
	description = "survivor vs survivor",
	version = "1.3.2",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public void OnPluginStart()
{
    cv_FirstRoundTime = CreateConVar("svs_first_round_time", "60", "首次回合时间", FCVAR_NOTIFY, true);
    cv_RoundTime = CreateConVar("svs_round_time", "45", "回合时间", FCVAR_NOTIFY, true);
    cv_Color = CreateConVar("svs_glow_color", "255 0 0", "透视颜色");
    cv_ColorTime = CreateConVar("svs_glow_time", "3.0", "透视时间", _, true, 1.0);
    
    GetCvar();
    HookConVarChange(cv_Color, CvarChanged);

    z_special_limit[SMOKER] = FindConVar("z_smoker_limit");
    z_special_limit[BOOMER] = FindConVar("z_boomer_limit");
    z_special_limit[HUNTER] = FindConVar("z_hunter_limit");
    z_special_limit[SPITTER] = FindConVar("z_spitter_limit");
    z_special_limit[JOCKEY] = FindConVar("z_jockey_limit");
    z_special_limit[CHARGER] = FindConVar("z_charger_limit");
    survivor_crouch_speed = FindConVar("survivor_crouch_speed");

    HookEvent("round_start", Event_RoundStart);
    HookEvent("player_death", Event_PlayerDeath);
    HookEvent("map_transition", Event_RoundEnd);
    HookEvent("round_end", Event_RoundEnd);
    HookEvent("finale_vehicle_leaving", Event_RoundEnd);
    HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Pre);

    RegConsoleCmd("sm_mvp", Mvp_Info);
}

public void CvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvar();
}

void GetCvar()
{
    char ch_Cols[12];
    cv_Color.GetString(ch_Cols, sizeof(ch_Cols));

    char ch_Color[3][4];
    i_Color = ExplodeString(ch_Cols, " ", ch_Color, sizeof(ch_Color), sizeof(ch_Color[]));
    if(i_Color == 3)
    {
        i_Color = StringToInt(ch_Color[0]);
        i_Color += 256 * StringToInt(ch_Color[1]);
        i_Color += 65536 * StringToInt(ch_Color[2]);
    }
    else
        i_Color = 0;
}

//回合开始重置
void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    CreateTimer(1.0, timer_reset);
}

Action timer_reset(Handle timer)
{
    ResetAll();
    return Plugin_Handled;
}

public void OnMapStart()
{
    b_FinalMap = false;
    b_RoundEnd = true;
    CreateTimer(3.0, timer_reset);
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if(!b_Print)
    {
        PrintInfos();
        b_Print = true;
    }
    b_RoundEnd = true;
    ResetAll();
}

void ResetAll()
{
    for(int i = 1; i <= MaxClients; i++)
        KillNumber[i] = 0;

    i_RoundNumber = 1;
    i_TimerNum = 0;
    delete t_glow;
}

//玩家死亡
void Event_PlayerDeath(Event event, const char []name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if(IsSurvivor(victim) && IsSurvivor(attacker))
    {
        KillNumber[attacker]++;
        PrintHintTextToAll("玩家 <%N> 击杀玩家 <%N>", attacker, victim);
    }

    if(CheckSurvivorCount(1))
    {
        if(!b_FinalMap && i_RoundNumber > 3)
        {
            PrintHintTextToAll("玩家 <%N> 获得最后胜利, 回合结束!", attacker);
            ExecuteCommand("warp_all_survivors_to_checkpoint");
            delete t_glow;
        }
        else if(b_FinalMap && i_RoundNumber > 5)
        {
            PrintHintTextToAll("玩家 <%N> 获得最后胜利, 请坐载具结束游戏!", attacker);
            delete t_glow;
        }
        else
        {
            PrintHintTextToAll("当前回合获胜玩家 <%N>", attacker);
            CreateTimer(3.0, timer_check);
        }
    }
}

//玩家离开游戏
void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event,"userid"));

    if (!IsValidClient(client))
        return;

    if (IsFakeClient(client))
        return;

    if(CheckSurvivorCount(1))
    {
        int attacker;
        if(!b_FinalMap && i_RoundNumber > 3)
        {
            for(int i = 1;i <= MaxClients; i++)
            {
                if(IsSurvivor(i) && IsPlayerAlive(i))
                    attacker = i;
            }
            PrintHintTextToAll("玩家 <%N> 获得最后胜利, 回合结束!", attacker);
            ExecuteCommand("warp_all_survivors_to_checkpoint");
            delete t_glow;
        }
        else if(b_FinalMap && i_RoundNumber > 5)
        {
            PrintHintTextToAll("玩家 <%N> 获得最后胜利, 请坐载具结束游戏!", attacker);
            delete t_glow;
        }
        else
        {
            for(int i = 1;i <= MaxClients; i++)
            {
                if(IsSurvivor(i) && IsPlayerAlive(i))
                    attacker = i;
            }
            PrintHintTextToAll("当前回合获胜玩家 <%N>", attacker);
            CreateTimer(3.0, timer_check);
        }
    }
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
    PrintInfos();
    return Plugin_Handled;
}

void PrintInfos()
{
    PrintToChatAll("\x03[击杀统计]");
    for(int i = 1; i <= MaxClients; i++)
        if(IsSurvivor(i))
            PrintToChatAll("\x03击杀 \x04%d \x05- %N", KillNumber[i], i);
}

Action timer_check(Handle timer)
{
    if(b_RoundEnd)
        return Plugin_Handled;
    
    delete t_glow;
    RespawnAllSurvivor();
    SetGodMode(true);
    survivor_crouch_speed.IntValue = 300;
    i_TimerNum = GetConVarInt(cv_RoundTime);
    CreateTimer(1.0, timer_god, _, TIMER_REPEAT);
    return Plugin_Handled;
}

bool CheckSurvivorCount(int Survivor)
{
    int snum = 0;
    for(int i = 1;i <= MaxClients; i++)
    {
        if(IsSurvivor(i) && IsPlayerAlive(i))
            snum++;
    }
    if(snum == Survivor)
        return true;
    else
        return false;
}

void RespawnAllSurvivor()
{
    for (int i = 1; i <= MaxClients; i++)
	{
		if (IsSurvivor(i))
		{
			//死亡玩家复活
			if(!IsPlayerAlive(i))
			{
				L4D_RespawnPlayer(i);
				TeleportClient(i);
			}
				
			//回血
			CheatCommand(i, "give", "health");
			SetEntProp(i, Prop_Send, "m_isGoingToDie", 0);
			SetEntPropFloat(i, Prop_Send, "m_healthBuffer", 0.0);
			SetEntProp(i, Prop_Send, "m_currentReviveCount", 0);
			SetEntProp(i, Prop_Send, "m_bIsOnThirdStrike", 0);
			StopSound(i, SNDCHAN_STATIC, "player/heartbeatloop.wav");
		}
	}
}

void TeleportClient(int client)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		float Origin[3];
		if (IsSurvivor(i) && i != client)
		{
			ForceCrouch(client);
			GetClientAbsOrigin(i, Origin);
			TeleportEntity(client, Origin, NULL_VECTOR, NULL_VECTOR);
			break;
		}
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
    
    survivor_crouch_speed.RestoreDefault();

    FindConVar("survivor_max_incapacitated_count").RestoreDefault();
    FindConVar("director_no_mobs").RestoreDefault();
    FindConVar("director_no_specials").RestoreDefault();
    FindConVar("pipe_bomb_timer_duration").RestoreDefault();

    delete t_glow;
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
    survivor_crouch_speed.IntValue = 300;
    i_TimerNum = GetConVarInt(cv_FirstRoundTime);
    b_RoundEnd = false;
    CreateTimer(1.0, timer_god, _, TIMER_REPEAT);
    b_Print = false;
    return Plugin_Stop;
}

Action timer_god(Handle timer)
{
    if(b_RoundEnd)
        return Plugin_Stop;

    if(i_TimerNum > 0)
    {
        PrintHintTextToAll("第 %d 回合开始剩余 %d 秒", i_RoundNumber, i_TimerNum--);
        PlaySound("weapons/hegrenade/beep.wav");
        return Plugin_Continue;
    }
    else
    {
        SetGodMode(false);
        survivor_crouch_speed.RestoreDefault();
        PrintHintTextToAll("无敌时间已过，回合开始！");
        PlaySound("ui/survival_medal.wav");
        i_RoundNumber++;
        i_CountSurvivor = CountSur();
        i_TimerColorNum = 0;
        t_glow = CreateTimer(1.0, timer_glow, _, TIMER_REPEAT);
        return Plugin_Stop;
    }
}

Action timer_glow(Handle timer)
{
    if(b_RoundEnd)
        return Plugin_Stop;
    
    if(i_CountSurvivor == CountSur())
    {
        if(i_TimerColorNum++ < 60)
            return Plugin_Continue;

        for(int i = 1;i <= MaxClients; i++)
        {
            if(IsSurvivor(i) && IsPlayerAlive(i))
            {
                SetEntProp(i, Prop_Send, "m_iGlowType", 3);
                SetEntProp(i, Prop_Send, "m_glowColorOverride", i_Color);
                CreateTimer(GetConVarFloat(cv_ColorTime), timer_removeglow, i);
            }
        }

        i_TimerColorNum = 0;
    }
    else
    {
        i_CountSurvivor = CountSur();
        i_TimerColorNum = 0;
    }

    return Plugin_Continue;
}

Action timer_removeglow(Handle timer, int client)
{
    SetEntProp(client, Prop_Send, "m_iGlowType", 0);
    SetEntProp(client, Prop_Send, "m_glowColorOverride", 0);
    return Plugin_Handled;
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

void SetGodMode(bool canset)
{
	int flags = GetCommandFlags("god");
	SetCommandFlags("god", flags & ~ FCVAR_NOTIFY);
	SetConVarInt(FindConVar("god"), canset);
	SetCommandFlags("god", flags);
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
