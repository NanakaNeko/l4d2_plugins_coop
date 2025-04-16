#pragma semicolon 1
#pragma newdecls required
//#include <sourcemod>
//#include <sdktools>
#include <builtinvotes>
#include <left4dhooks>

Handle g_Vote;
bool isFinal;

public Plugin myinfo =
{
	name = "[L4D2]Vote to Miss NOWChapter",
	author = "奈",
	description = "投票跳过章节",
	version = "1.0",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
}
public void OnPluginStart()
{
	RegConsoleCmd("sm_skipchapter", VoteSkipRequest);
	RegConsoleCmd("sm_sc", VoteSkipRequest);
	HookEvent("round_start", Event_RoundStart);
}
void Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	if(L4D_IsMissionFinalMap())
		isFinal = true;
	else
	isFinal = false;
}

Action VoteSkipRequest(int client, int args)
{
	if(client == 0)
	{
		PrintToServer("这个命令不能用于服务器.");
		return Plugin_Handled;
	}
	if(GetClientTeam(client) == 1)
	{
		PrintToChat(client,"\x04[提示]\x03您当前处于旁观者队伍, 禁止投票!");
		return Plugin_Handled;
	}
	if(isFinal == true)
	{
		PrintToChat(client,"\x04[提示]\x03当前是救援关, 禁止发起跳关投票!");
		return Plugin_Handled;
	}

	SkipChapterMenu(client);
	return Plugin_Handled;
}

void SkipChapterMenu(int client)
{
	Menu hMenu = new Menu(SkipChapterMenuHandler);
	char nextmap[1024];
	GetCurrentMap(nextmap,sizeof(nextmap));
	hMenu.SetTitle("是否确认投票跳关?\n当前章节:[%s]",nextmap);
	hMenu.AddItem("item0", "是");
	hMenu.AddItem("item1", "否");
	hMenu.Display(client, 20);
}

int SkipChapterMenuHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if(action == MenuAction_Select)
	{
		switch(param2)
		{
			case 0:
			{
				CreateTimer(0.1,Timer_StartVote,param1);
				PrintToChatAll("\x04[提示]\x03%N\x05发起了一个跳过当前关卡的投票.",param1);
			}
			case 1:
			{

			}
		}
	}
	else if(action == MenuAction_End)	
	{
		delete menu;
	}
	return 0;
}

Action Timer_StartVote(Handle timer,int client)
{
	if (StartVote(client))
	{
		FakeClientCommand(client, "Vote Yes");
	}
	return Plugin_Handled;
}

bool StartVote(int client)
{
	if (IsNewBuiltinVoteAllowed())
	{
		g_Vote = CreateBuiltinVote(HandleVote, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
		if (client > 0)
		{
			SetBuiltinVoteInitiator(g_Vote, client);
		}
		SetBuiltinVoteArgument(g_Vote, "跳过当前关卡?");
		DisplayBuiltinVoteToAll(g_Vote, 20);
		return true;
	}
	else
	{
		//ReplyToCommand(client, "[Vote]投票现在正在冷却中!");
		PrintToChat(client, "\x04[提示]\x03投票现在正在冷却中!");
		return false;
	}
}

int HandleVote(Handle vote, BuiltinVoteAction action, int param1, int param2)
{
	switch (action)
	{
		case BuiltinVoteAction_End:
		{
			delete vote;
			g_Vote = null;
			CloseHandle(vote);
		}
		
		case BuiltinVoteAction_Cancel:
		{

		}
		
		case BuiltinVoteAction_VoteEnd:
		{
			if (param1 == BUILTINVOTES_VOTE_YES)
			{
				DisplayBuiltinVotePass(vote, "正在传送...");

				CheatCommand(param1,"warp_all_survivors_to_checkpoint","");
				CheatCommand(param1,"warp_all_survivors_to_checkpoint","");
				CloseLockSafeDoor();
				
			}
			else if (param1 == BUILTINVOTES_VOTE_NO)
			{
				DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
			}
			else
			{
				DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Generic);
			}
		}
	}
	return 0;
}

//找门与关门锁门
stock void CloseLockSafeDoor()
{
	int EndDoor;
	while((EndDoor = FindEntityByClassname(EndDoor,"prop_door_rotating_checkpoint")) != -1)
	{
		AcceptEntityInput(EndDoor ,"Close");
		AcceptEntityInput(EndDoor ,"Lock");
	}
}

//cheat 命令
void CheatCommand(int client, char[] Command, char[] Param)
{
	int flags = GetCommandFlags(Command);
	SetCommandFlags(Command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", Command, Param);
	SetCommandFlags(Command, flags);
}