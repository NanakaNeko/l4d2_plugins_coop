#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>

public Plugin myinfo = 
{
	name = "[L4D2]友伤",
	description = "L4D2 Friendly Fire",
	author = "奈",
	version = "1.2",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_setff", Cmd_FriendlyFire, ADMFLAG_ROOT, "设置友伤系数");
}

Action Cmd_FriendlyFire(int client, int args)
{
	if (args == 0)
		PrintToChat(client, "\x04[提示]\x05请输入\x03!ff off\x05关闭友伤，\x03!ff on\x05打开友伤，\x03!ff normal\x05设置普通友伤，\x03!ff top\x05设置最高友伤");
	else if (args == 1) {
		char tmp[8];
		GetCmdArg(1, tmp, sizeof(tmp));
		if (strcmp(tmp, "on", false) == 0) {
			FindConVar("survivor_friendly_fire_factor_easy").RestoreDefault();
			FindConVar("survivor_friendly_fire_factor_normal").RestoreDefault();
			FindConVar("survivor_friendly_fire_factor_hard").RestoreDefault();
			FindConVar("survivor_friendly_fire_factor_expert").RestoreDefault();
			PrintToChatAll("\x04[提示]\x05队友伤害恢复\x03正常\x05伤害.");
		}
		else if (strcmp(tmp, "off", false) == 0) {
			FindConVar("survivor_friendly_fire_factor_easy").SetFloat(0.0);
			FindConVar("survivor_friendly_fire_factor_normal").SetFloat(0.0);
			FindConVar("survivor_friendly_fire_factor_hard").SetFloat(0.0);
			FindConVar("survivor_friendly_fire_factor_expert").SetFloat(0.0);
			PrintToChatAll("\x04[提示]\x05队友伤害设置为\x03关闭.");
		}
		else if (strcmp(tmp, "normal", false) == 0) {
			FindConVar("survivor_friendly_fire_factor_easy").SetFloat(0.1);
			FindConVar("survivor_friendly_fire_factor_normal").SetFloat(0.1);
			FindConVar("survivor_friendly_fire_factor_hard").SetFloat(0.1);
			FindConVar("survivor_friendly_fire_factor_expert").SetFloat(0.1);
			PrintToChatAll("\x04[提示]\x05队友伤害设置为\x03普通\x05伤害.");
		}
		else if (strcmp(tmp, "top", false) == 0) {
			FindConVar("survivor_friendly_fire_factor_easy").SetFloat(1.0);
			FindConVar("survivor_friendly_fire_factor_normal").SetFloat(1.0);
			FindConVar("survivor_friendly_fire_factor_hard").SetFloat(1.0);
			FindConVar("survivor_friendly_fire_factor_expert").SetFloat(1.0);
			PrintToChatAll("\x04[提示]\x05队友伤害设置为\x03专家2倍\x05伤害.");
		}
		else
			PrintToChat(client, "\x04[提示]\x03请输入正确的命令!");
	}
	return Plugin_Handled;
}