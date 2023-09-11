#pragma semicolon 1
#pragma newdecls required //強制1.7以後的新語法

#include <sourcemod>

#define ZOEY 0
#define LOUIS 1
#define FRANCIS 2
#define BILL 3
#define ROCHELLE 4
#define COACH 5
#define ELLIS 6
#define NICK 7


public Plugin myinfo =
{
	name = "L4D Black and White Notifier",
	author = "DarkNoghri, HarryPotter, 奈",
	description = "Notify people when player is black and white.",
	version = "2.3",
	url = "https://steamcommunity.com/profiles/76561198026784913/"
};

ConVar h_cvarNoticeType, h_cvarPrintType;
int bandw_notice, bandw_type;

bool g_bLastlife[MAXPLAYERS + 1];
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test != Engine_Left4Dead2 )
	{
		strcopy(error, err_max, "本插件仅支持 Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("revive_success", EventReviveSuccess);
	HookEvent("heal_begin", Event_Check);
	HookEvent("heal_success", EventHealSuccess);

	h_cvarNoticeType = CreateConVar("l4d_bandw_notice", "2", "0=关闭提示, 1=仅提示生还, 2=全部提示, 3=仅提示感染.", FCVAR_NOTIFY, true, 0.0, true, 3.0);
	h_cvarPrintType = CreateConVar("l4d_bandw_type", "2", "0=聊天框提示, 1=hint弹出提示, 2=两个一起提示.", FCVAR_NOTIFY, true, 0.0, true, 2.0);

	GetCvars();
	
	h_cvarNoticeType.AddChangeHook(ChangeVars);
	h_cvarPrintType.AddChangeHook(ChangeVars);
}

public void ChangeVars(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	bandw_notice = h_cvarNoticeType.IntValue;
	bandw_type = h_cvarPrintType.IntValue;
}

public void EventReviveSuccess(Event event, const char[] name, bool dontBroadcast) 
{
	int target = GetClientOfUserId(event.GetInt("subject"));

	if(target < 1 || target > MaxClients) return;

	if(!IsClientInGame(target) || !IsPlayerAlive(target)) return;

	if(event.GetBool("lastlife"))
	{
		//获取闲置玩家
		int idleplayer = GetIdlePlayerOfBot(target);
		//turned off
		if(bandw_notice == 0) return;
		
		//print to all
		else if(bandw_notice == 2) 
		{
			if(IsFakeClient(target))
			{
				if(bandw_type == 1 || bandw_type == 2) 
					if(!idleplayer)
						PrintHintTextToAll("%N黑白了,即将死亡.", target);
					else
						PrintHintTextToAll("闲置:%N(%N)黑白了,即将死亡.", idleplayer, target);
				if(bandw_type == 0 || bandw_type == 2)
					if(!idleplayer)
						PrintToChatAll("\x04[提示]\x03%N\x05黑白了,即将死亡.", target);
					else
						PrintToChatAll("\x04[提示]\x03闲置:%N\x01(\x03%N\x01)\x05黑白了,即将死亡.", idleplayer, target);
			}
			else
			{
				if(bandw_type == 1 || bandw_type == 2) 
					PrintHintTextToAll("%N(%s)黑白了,即将死亡.", target, GetBotName(target));
				if(bandw_type == 0 || bandw_type == 2)
					PrintToChatAll("\x04[提示]\x03%N\x01(\x03%s\x01)\x05黑白了,即将死亡.", target, GetBotName(target));
			}
		}
		//print to infected
		else if(bandw_notice == 3)
		{
			for( int x = 1; x <= MaxClients; x++)
			{
				if(!IsClientInGame(x) || GetClientTeam(x) == GetClientTeam(target) || x == target || IsFakeClient(x))
					continue;

				if(IsFakeClient(target))
				{	
					if(bandw_type == 1 || bandw_type == 2) 
						if(!idleplayer)
							PrintHintText(x, "%N黑白了,即将死亡.", target);
						else
							PrintHintText(x, "闲置:%N(%N)黑白了,即将死亡.", idleplayer, target);
					if(bandw_type == 0 || bandw_type == 2)
						if(!idleplayer)
							PrintToChat(x, "\x04[提示]\x03%N\x05黑白了,即将死亡.", target);
						else
							PrintToChat(x, "\x04[提示]\x03闲置:%N\x01(\x03%N\x01)\x05黑白了,即将死亡.", idleplayer, target);
				}
				else
				{
					if(bandw_type == 1 || bandw_type == 2)
						PrintHintText(x, "%N(%s)黑白了,即将死亡.", target, GetBotName(target));
					if(bandw_type == 0 || bandw_type == 2)
						PrintToChat(x, "\x04[提示]\x03%N\x01(\x03%s\x01)\x05黑白了,即将死亡.", target, GetBotName(target));	
				}
			}
		}
		//print to survivors
		else if(bandw_notice == 1)
		{
			for( int x = 1; x <= MaxClients; x++)
			{
				if(!IsClientInGame(x) || GetClientTeam(x) != GetClientTeam(target) || x == target || IsFakeClient(x)) 
					continue;
				if(IsFakeClient(target))
				{		
					if(bandw_type == 1 || bandw_type == 2) 
						if(!idleplayer)
							PrintHintText(x, "%N黑白了,即将死亡.", target);
						else
							PrintHintText(x, "闲置:%N(%N)黑白了,即将死亡.", idleplayer, target);
					if(bandw_type == 0 || bandw_type == 2)
						if(!idleplayer)
							PrintToChat(x, "\x04[提示]\x03%N\x05黑白了,即将死亡.", target);
						else
							PrintToChat(x, "\x04[提示]\x03闲置:%N\x01(\x03%N\x01)\x05黑白了,即将死亡.", idleplayer, target);
				}
				else
				{
					if(bandw_type == 1 || bandw_type == 2) 
						PrintHintText(x, "%N(%s)黑白了,即将死亡.", target, GetBotName(target));
					if(bandw_type == 0 || bandw_type == 2)
						PrintToChat(x, "\x04[提示]\x03%N\x01(\x03%s\x01)\x05黑白了,即将死亡.", target, GetBotName(target));					
				}
			}
		}	
	}
	
}

public void Event_Check(Event event, const char[] name, bool dontBroadcast)
{
	static ConVar cv;
	if (!cv)
		cv = FindConVar("survivor_max_incapacitated_count");
	int maxInc = cv.IntValue;

	int target = GetClientOfUserId(event.GetInt("subject"));
	if(target < 1 || target > MaxClients) return;
	if(!IsClientInGame(target) || !IsPlayerAlive(target)) return;

	if(GetEntProp(target, Prop_Send, "m_currentReviveCount") >= maxInc)
		g_bLastlife[target] = true;
	else
		g_bLastlife[target] = false;
}

public void EventHealSuccess(Event event, const char[] name, bool dontBroadcast)
{
	int target = GetClientOfUserId(event.GetInt("subject"));
	
	if(target < 1 || target > MaxClients) return;

	if(!IsClientInGame(target) || !IsPlayerAlive(target)) return;

	if(g_bLastlife[target])
	{
		//获取闲置玩家
		int idleplayer = GetIdlePlayerOfBot(target);
		//turned off
		if(bandw_notice == 0) return;
		
		//print to all
		else if(bandw_notice == 2) 
		{
			if(IsFakeClient(target))
			{
				if(bandw_type == 1 || bandw_type == 2) 
					if(!idleplayer)
						PrintHintTextToAll("%N治疗完成,不再黑白.", target);
					else
						PrintHintTextToAll("闲置:%N(%N)治疗完成,不再黑白.", idleplayer, target);
				if(bandw_type == 0 || bandw_type == 2)
					if(!idleplayer)
						PrintToChatAll("\x04[提示]\x03%N\x05治疗完成,不再黑白.", target);
					else
						PrintToChatAll("\x04[提示]\x03闲置:%N\x01(\x03%N\x01)\x05治疗完成,不再黑白.", idleplayer, target);
			}
			else
			{
				if(bandw_type == 1 || bandw_type == 2) 
					PrintHintTextToAll("%N(%s)治疗完成,不再黑白.", target, GetBotName(target));
				if(bandw_type == 0 || bandw_type == 2)
					PrintToChatAll("\x04[提示]\x03%N\x01(\x03%s\x01)\x05治疗完成,不再黑白.", target, GetBotName(target));
			}
		}
		//print to infected
		else if(bandw_notice == 3)
		{
			for( int x = 1; x <= MaxClients; x++)
			{
				if(!IsClientInGame(x) || GetClientTeam(x) == GetClientTeam(target) || x == target || IsFakeClient(x))
					continue;

				if(IsFakeClient(target))
				{	
					if(bandw_type == 1 || bandw_type == 2) 
						if(!idleplayer)
							PrintHintText(x, "%N治疗完成,不再黑白.", target);
						else
							PrintHintText(x, "闲置:%N(%N)治疗完成,不再黑白.", idleplayer, target);
					if(bandw_type == 0 || bandw_type == 2)
						if(!idleplayer)
							PrintToChat(x, "\x04[提示]\x03%N\x05治疗完成,不再黑白.", target);
						else
							PrintToChat(x, "\x04[提示]\x03闲置:%N\x01(\x03%N\x01)\x05治疗完成,不再黑白.", idleplayer, target);
				}
				else
				{
					if(bandw_type == 1 || bandw_type == 2) 
						PrintHintText(x, "%N(%s)治疗完成,不再黑白.", target, GetBotName(target));
					if(bandw_type == 0 || bandw_type == 2)
						PrintToChat(x, "\x04[提示]\x03%N\x01(\x03%s\x01)\x05治疗完成,不再黑白.", target, GetBotName(target));	
				}
			}
		}
		//print to survivors
		else if(bandw_notice == 1)
		{
			for( int x = 1; x <= MaxClients; x++)
			{
				if(!IsClientInGame(x) || GetClientTeam(x) != GetClientTeam(target) || x == target || IsFakeClient(x)) 
					continue;
				if(IsFakeClient(target))
				{		
					if(bandw_type == 1 || bandw_type == 2) 
						if(!idleplayer)
							PrintHintText(x, "%N治疗完成,不再黑白.", target);
						else
							PrintHintText(x, "闲置:%N(%N)治疗完成,不再黑白.", idleplayer, target);
					if(bandw_type == 0 || bandw_type == 2)
						if(!idleplayer)
							PrintToChat(x, "\x04[提示]\x03%N\x05治疗完成,不再黑白.", target);
						else
							PrintToChat(x, "\x04[提示]\x03闲置:%N\x01(\x03%N\x01)\x05治疗完成,不再黑白.", idleplayer, target);
				}
				else
				{
					if(bandw_type == 1 || bandw_type == 2) 
						PrintHintText(x, "%N(%s)治疗完成,不再黑白.", target, GetBotName(target));
					if(bandw_type == 0 || bandw_type == 2)
						PrintToChat(x, "\x04[提示]\x03%N\x01(\x03%s\x01)\x05治疗完成,不再黑白.", target, GetBotName(target));					
				}
			}
		}
	}	
	
}

char[] GetBotName(int target)
{
	char targetModel[128]; 
	char charName[32];
	GetClientModel(target, targetModel, sizeof(targetModel));
	//fill string with character names
	if(StrContains(targetModel, "teenangst", false) > 0) 
	{
		strcopy(charName, sizeof(charName), "Zoey");
	}
	else if(StrContains(targetModel, "biker", false) > 0)
	{
		strcopy(charName, sizeof(charName), "Francis");
	}
	else if(StrContains(targetModel, "manager", false) > 0)
	{
		strcopy(charName, sizeof(charName), "Louis");
	}
	else if(StrContains(targetModel, "namvet", false) > 0)
	{
		strcopy(charName, sizeof(charName), "Bill");
	}
	else if(StrContains(targetModel, "producer", false) > 0)
	{
		strcopy(charName, sizeof(charName), "Rochelle");
	}
	else if(StrContains(targetModel, "mechanic", false) > 0)
	{
		strcopy(charName, sizeof(charName), "Ellis");
	}
	else if(StrContains(targetModel, "coach", false) > 0)
	{
		strcopy(charName, sizeof(charName), "Coach");
	}
	else if(StrContains(targetModel, "gambler", false) > 0)
	{
		strcopy(charName, sizeof(charName), "Nick");
	}
	else{
		strcopy(charName, sizeof(charName), "Unknown");
	}
	return charName;
}

int GetIdlePlayerOfBot(int client) 
{
	if (!HasEntProp(client, Prop_Send, "m_humanSpectatorUserID"))
		return 0;

	return GetClientOfUserId(GetEntProp(client, Prop_Send, "m_humanSpectatorUserID"));
}