#if defined _player_time_included
 #endinput
#endif
#define _player_time_included

/**
* @根据id返回玩家总游戏时间
*
* @client	需要获取数据的玩家id
*
* @return	总游戏时间
*
*/
native int Time_Get_TotalTime(int client);

/**
* @根据id返回玩家实际游戏时间
*
* @client	需要获取数据的玩家id
*
* @return	实际游戏时间
*
*/
native int Time_Get_GetRealTime(int client);

/**
* @根据id返回玩家最近两周时间
*
* @client	需要获取数据的玩家id
*
* @return	最近两周时间
*
*/
native int Time_Get_GetWeekTime(int client);

public SharedPlugin __pl_player_time = 
{
	name = "l4d2_player_time",
	file = "l4d2_player_time.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_player_time_SetNTVOptional()
{
	MarkNativeAsOptional("Time_Get_TotalTime");
	MarkNativeAsOptional("Time_Get_GetRealTime");
	MarkNativeAsOptional("Time_Get_GetWeekTime");
}
#endif