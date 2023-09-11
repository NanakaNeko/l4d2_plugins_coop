#pragma semicolon 1

#include <sourcemod>
#include <builtinvotes>
#include <colors>

new Handle:g_hVote;
new String:g_sSlots[32];
new Handle:hMinSlots;
new Handle:hMaxSlots;
new Handle:hDefaultSlots;
new MaxSlots;
new MinSlots;

public Plugin:myinfo =
{
	name = "[L4D2]slots",
	description = "投票增加位置",
	author = "Sir,奈",
	version = "1.0",
	url = "N/A"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_slots", SlotsRequest);
	RegConsoleCmd("sm_slot", SlotsRequest);
	hMinSlots = CreateConVar("sm_slot_vote_min", "4", "最小投票数 (不能低于1)", FCVAR_NOTIFY, true, 1.0, true, 31.0);
	hMaxSlots = CreateConVar("sm_slot_vote_max", "16", "最大投票数 (不能超过31)", FCVAR_NOTIFY, true, 1.0, true, 31.0);
	hDefaultSlots = CreateConVar("sm_slot_vote_default", "8", "默认位置数", FCVAR_NOTIFY, true, 1.0, true, 31.0);
	MaxSlots = GetConVarInt(hMaxSlots);
	MinSlots = GetConVarInt(hMinSlots);
	HookConVarChange(hMaxSlots, CVarChanged);
	HookConVarChange(hMaxSlots, CVarChanged);
	SetDefaultSlots(GetConVarInt(hDefaultSlots));
}

public SetDefaultSlots(int slots)
{
	SetConVarInt(FindConVar("sv_maxplayers"), slots);
	SetConVarInt(FindConVar("sv_visiblemaxplayers"), slots);
}

public Action:SlotsRequest(client, args)
{
	if (client < 0)
	{
		return Plugin_Handled;
	}
	if (args == 1)
	{
		new String:sSlots[64];
		GetCmdArg(1, sSlots, sizeof(sSlots));
		new Int = StringToInt(sSlots);
		if (Int > MaxSlots)
		{
			CPrintToChat(client, "{blue}[{default}Slots{blue}] {default}你不能在这个服务器上开超过 {olive}%i {default}的位置", MaxSlots);
		}
		else
		{
			if(client == 0)
			{
				CPrintToChatAll("{blue}[{default}Slots{blue}] {olive}管理员 {default}将服务器位置设为 {blue}%i {default}个", Int);
				SetConVarInt(FindConVar("sv_maxplayers"), Int);
				SetConVarInt(FindConVar("sv_visiblemaxplayers"), Int);
			}
			else if (GetUserAdmin(client) != INVALID_ADMIN_ID )
			{
				CPrintToChatAll("{blue}[{default}Slots{blue}] {olive}管理员 {default}将服务器位置设为 {blue}%i {default}个", Int);
				SetConVarInt(FindConVar("sv_maxplayers"), Int);
				SetConVarInt(FindConVar("sv_visiblemaxplayers"), Int);
			}
			else if (Int < MinSlots)
			{
				CPrintToChat(client, "{blue}[{default}Slots{blue}] {default}你不能将服务器位置设为小于{blue}%i {default}个.", MinSlots);
			}
			else if (StartSlotVote(client, sSlots))
			{
				strcopy(g_sSlots, sizeof(g_sSlots), sSlots);
				FakeClientCommand(client, "Vote Yes");
			}
		}
	}
	else
	{
		CPrintToChat(client, "{blue}[{default}Slots{blue}] {default}用法: {olive}!slots {default}<{olive}你想要设置的服务器位置数量{default}> {blue}| {default}例子: {olive}!slots 8");
	}
	return Plugin_Handled;
}

bool:StartSlotVote(client, String:Slots[])
{
	if (GetClientTeam(client) == 1)
	{
		PrintToChat(client, "旁观者不允许使用命令.");
		return false;
	}

	if (IsNewBuiltinVoteAllowed())
	{
		new iNumPlayers;
		decl iPlayers[MaxClients];
		for (new i=1; i<=MaxClients; i++)
		{
			if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == 1))
			{
				continue;
			}
			iPlayers[iNumPlayers++] = i;
		}
		
		new String:sBuffer[64];
		g_hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
		Format(sBuffer, sizeof(sBuffer), "更改服务器位置到 '%s' 个?", Slots);
		SetBuiltinVoteArgument(g_hVote, sBuffer);
		SetBuiltinVoteInitiator(g_hVote, client);
		SetBuiltinVoteResultCallback(g_hVote, SlotVoteResultHandler);
		DisplayBuiltinVote(g_hVote, iPlayers, iNumPlayers, 20);
		return true;
	}

	PrintToChat(client, "投票功能暂时不能使用.");
	return false;
}

public void SlotVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (new i=0; i<num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_votes / 2))
			{
				new Slots = StringToInt(g_sSlots, 10);
				DisplayBuiltinVotePass(vote, "更改服务器位置...");
				SetConVarInt(FindConVar("sv_maxplayers"), Slots);
				SetConVarInt(FindConVar("sv_visiblemaxplayers"), Slots);
				return;
			}
		}
	}
	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

public VoteActionHandler(Handle:vote, BuiltinVoteAction:action, param1, param2)
{
	switch (action)
	{
		case BuiltinVoteAction_End:
		{
			g_hVote = INVALID_HANDLE;
			CloseHandle(vote);
		}
		case BuiltinVoteAction_Cancel:
		{
			DisplayBuiltinVoteFail(vote, BuiltinVoteFailReason:param1);
		}
	}
}

public CVarChanged(Handle:cvar, String:oldValue[], String:newValue[])
{
	MaxSlots = GetConVarInt(hMaxSlots);
	MinSlots = GetConVarInt(hMinSlots);
}

