#pragma semicolon 1
#pragma newdecls required

#include <sourcemod> 
#include <sdktools>

public Plugin myinfo = 
{
    name        = "!rpg惩罚",
    author      = "奈",
    description = "惩罚没事输入!rpg的人",
    version     = "final",
    url         = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_rpg", SpawnTank);
}

public Action SpawnTank(int client, int args)
{
	if(!IsValidPlayer(client)) 
		return Plugin_Handled;
	//计时器，60秒后全员暴毙
	CreateTimer(60.0, timerTankHandler);
	//传送起点安全屋
	CheatCommand(client, "warp_to_start_area", "");
	for(int i = 0; i < 5; i++){
		//生成克
		CheatCommand(client, "z_spawn", "tank");
	}
	//改死门模式
	ServerCommand("sm_cvar mp_gamemode community5");
	//召唤尸潮
	CheatCommand(client, "director_force_panic_event", "");
	//提示
	PrintToChat(client, "\x04[提示]\x05!rpg个屁，给你来5个坦克玩玩");
	//全体提示
	PrintHintTextToAll("%N输入!rpg召唤了5个坦克并在1分钟后处死全员", client);
	return Plugin_Handled;
}

//cheat命令
void CheatCommand(int client, char[] command, char[] args = "")
{
	int iFlags = GetCommandFlags(command);
	SetCommandFlags(command, iFlags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, args);
	SetCommandFlags(command, iFlags);
}

//判断生还状态
stock bool IsValidPlayer(int Client)
{
	if (Client < 1 || Client > MaxClients)
		return false;
	if (!IsClientConnected(Client) || !IsClientInGame(Client))
		return false;
	if (!(GetClientTeam(Client) == 2))
		return false;
	if (IsFakeClient(Client))
		return false;
	if (!IsPlayerAlive(Client))
		return false;
	return true;
}

//计时器，60秒后全员暴毙
public Action timerTankHandler(Handle timer)
{
	PrintHintTextToAll("60秒倒计时结束，全队暴毙.");
	for(int client=1; client<=MaxClients; client++)
		ForcePlayerSuicide(client);
	
	return Plugin_Continue;
}
