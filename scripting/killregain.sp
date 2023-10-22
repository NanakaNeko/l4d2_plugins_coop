#pragma semicolon 1
#pragma newdecls required

/*
	第二版本：2021.10.23：①将回复子弹的数量和回复备弹的数量从宏定义更改为Cvar，更好控制，无需重新编译	
						  ②优化了一些结构和功能，功能性Cvar更改为0为关闭>0为开启，减少了代码数量，增加了一些注释，便于维护
*/

// 头文件
#include <sourcemod>
#include <sdktools>
// 团队
#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
// 枪械最大子弹上限
#define MAX_AK47 40
#define MAX_M16 50
#define MAX_SCAR 60
#define MAX_SMG 50
#define MAX_FIRSTSHOTGUN 8
#define MAX_SECONDSHOTGUN 10
#define MAX_FIRSTSNIPER 15
#define MAX_SECONDSNIPER 30
#define MAX_M60 150
#define MAX_GRENADE_LAUNCHER 1
// 其他
#define IsValidClient(%1) (1 <= %1 <= MaxClients && IsClientInGame(%1))

// 句柄
ConVar g_AmmoFillClip, g_AmmoRegain, g_Health, g_HealthRegain, g_TempHealthRegain, g_SpecialAmmoRegain, g_SpecialClip, g_RIFLE, g_SMG, g_SHOTGUN,
	g_SNIPER, g_M60, g_LAUNCHER, g_CLIP_AK47, g_CLIP_M16, g_CLIP_SCAR, g_CLIP_SMG, g_CLIP_FIRSTSHOTGUN, g_CLIP_SECONDSHOTGUN, g_CLIP_FIRSTSNIPER, g_CLIP_SECONDSNIPER,
	g_CLIP_LAUNCHER, g_witch_restore;
int g_iAmmoFillClip, g_iAmmoRegain, g_iHealth, g_iHealthRegain, g_iTempHealthRegain, g_iSpecialAmmoRegain, g_iSpecialClip, g_iRIFLE, g_iSMG, g_iSHOTGUN,
	g_iSNIPER, g_iLAUNCHER, g_iCLIP_AK47, g_iCLIP_M16, g_iCLIP_SCAR, g_iCLIP_SMG, g_iCLIP_FIRSTSHOTGUN, g_iCLIP_SECONDSHOTGUN, g_iCLIP_FIRSTSNIPER, g_iCLIP_SECONDSNIPER,
	g_iCLIP_LAUNCHER;

Handle pain_pills_decay_rate;
// 变量
int ammocount[MAXPLAYERS+1];
int clipcount[MAXPLAYERS+1];
int sicount[MAXPLAYERS+1];
int siammocount[MAXPLAYERS+1];
int siclipcount[MAXPLAYERS+1];

public Plugin myinfo =
{
    name = "杀特回血，子弹，杀ss回子弹",
    author = "世界第一可爱夜羽真白",
    description = "When kill a special infected or zombie, regain certain health or ammo",
	version = "1.0.2.0",
	url = "https://steamcommunity.com/id/saku_ra/"
};

public void OnPluginStart() 
{
	// 添加几个Cvar
	g_AmmoFillClip = CreateConVar ("ss_ammoclip", "0", "杀多少小ss回复一个弹夹的子弹, 0 = 关闭此功能, >0 = Cvar数值", FCVAR_NOTIFY, true, 0.0);
	g_AmmoRegain = CreateConVar ("ss_ammoregain", "0", "杀多少小ss能回复子弹, 0 = 关闭此功能, >0 = Cvar数值", FCVAR_NOTIFY, true, 0.0);
	g_Health = CreateConVar ("ss_health", "0", "杀多少特殊感染者能回复血量, 0 = 关闭此功能, >0 = Cvar数值", FCVAR_NOTIFY, true, 0.0);
	g_HealthRegain = CreateConVar ("ss_healthregain", "2", "杀上面数量特殊感染者回复多少实血", FCVAR_NOTIFY, true, 0.0);
	g_TempHealthRegain = CreateConVar ("ss_temphealth", "0", "杀上面数量特殊感染者回复多少虚血", FCVAR_NOTIFY, true, 0.0);
	g_SpecialAmmoRegain = CreateConVar ("ss_siammoregain", "0", "杀多少特殊感染者回复子弹, 0 = 关闭此功能, >0 = Cvar数值", FCVAR_NOTIFY, true, 0.0);
	g_SpecialClip = CreateConVar ("ss_siammoclip", "0", "杀多少特殊感染者回复一个弹夹的子弹, 0 = 关闭此功能, >0 = Cvar数值", FCVAR_NOTIFY, true, 0.0);
	// 子弹设置
	g_RIFLE = CreateConVar ("ammo_rifle", "2", "给步枪回复多少子弹", FCVAR_NOTIFY, true, 0.0);
	g_SMG = CreateConVar ("ammo_smg", "2", "给smg回复多少子弹", FCVAR_NOTIFY, true, 0.0);
	g_SHOTGUN = CreateConVar ("ammo_shotgun", "1", "给散弹回复多少子弹", FCVAR_NOTIFY, true, 0.0);
	g_SNIPER = CreateConVar ("ammo_sniper", "1", "给狙击回复多少子弹", FCVAR_NOTIFY, true, 0.0);
	g_M60 = CreateConVar("ammo_m60", "2", "给 M60 回复多少子弹", FCVAR_NOTIFY, true, 0.0);
	g_LAUNCHER = CreateConVar ("ammo_launcher", "1", "给榴弹回复多少子弹", FCVAR_NOTIFY, true, 0.0);
	// 后备弹夹
	g_CLIP_AK47	= CreateConVar ("clip_ak", "40", "不说了，给ak回一个弹夹的子弹，子弹数量自定义", FCVAR_NOTIFY, true, 0.0);
	g_CLIP_M16 = CreateConVar ("clip_m16", "50", "给m16回一个弹夹的子弹，子弹数量自定义", FCVAR_NOTIFY, true, 0.0);
	g_CLIP_SCAR = CreateConVar ("clip_scar", "60", "给scar回一个弹夹的子弹，子弹数量自定义", FCVAR_NOTIFY, true, 0.0);
	g_CLIP_SMG = CreateConVar ("clip_smg", "50", "给smg回一个弹夹的子弹，子弹数量自定义", FCVAR_NOTIFY, true, 0.0);
	g_CLIP_FIRSTSHOTGUN = CreateConVar ("clip_firstshotgun", "8", "给单喷回一个弹夹的子弹，子弹数量自定义", FCVAR_NOTIFY, true, 0.0);
	g_CLIP_SECONDSHOTGUN = CreateConVar ("clip_secondshotgun", "10", "给连喷回一个弹夹的子弹，子弹数量自定义", FCVAR_NOTIFY, true, 0.0);
	g_CLIP_FIRSTSNIPER = CreateConVar ("clip_firstsniper", "15", "给一代连狙回一个弹夹的子弹，子弹数量自定义", FCVAR_NOTIFY, true, 0.0);
	g_CLIP_SECONDSNIPER = CreateConVar ("clip_secondsniper", "30", "给二代连狙回一个弹夹的子弹，子弹数量自定义", FCVAR_NOTIFY, true, 0.0);
	g_CLIP_LAUNCHER = CreateConVar ("clip_launcher", "3", "给榴弹回一个弹夹的子弹，子弹数量自定义", FCVAR_NOTIFY, true, 0.0);
	//女巫击杀回血
	g_witch_restore = CreateConVar ("kill_witch_restore", "10", "击杀女巫回多少血", FCVAR_NOTIFY, true, 0.0);
	// Hook掉两个事件
	HookEvent("infected_death", evt_killnormal);
	HookEvent("player_death", evt_kill_infected);
	HookEvent("witch_killed", WitchKilled_Event);
	// 先获取一下Cvar
	GetNewCvars();
	// Add Cvar Change Hook
	g_AmmoFillClip.AddChangeHook(ConVarChanged_Cvars);
	g_AmmoRegain.AddChangeHook(ConVarChanged_Cvars);
	g_Health.AddChangeHook(ConVarChanged_Cvars);
	g_HealthRegain.AddChangeHook(ConVarChanged_Cvars);
	g_TempHealthRegain.AddChangeHook(ConVarChanged_Cvars);
	g_SpecialAmmoRegain.AddChangeHook(ConVarChanged_Cvars);
	g_SpecialClip.AddChangeHook(ConVarChanged_Cvars);
	// 子弹Cvar
	g_RIFLE.AddChangeHook(ConVarChanged_Cvars);
	g_SMG.AddChangeHook(ConVarChanged_Cvars);
	g_SHOTGUN.AddChangeHook(ConVarChanged_Cvars);
	g_SNIPER.AddChangeHook(ConVarChanged_Cvars);
	g_LAUNCHER.AddChangeHook(ConVarChanged_Cvars);
	g_CLIP_AK47.AddChangeHook(ConVarChanged_Cvars);
	g_CLIP_M16.AddChangeHook(ConVarChanged_Cvars);
	g_CLIP_SCAR.AddChangeHook(ConVarChanged_Cvars);
	g_CLIP_SMG.AddChangeHook(ConVarChanged_Cvars);
	g_CLIP_FIRSTSHOTGUN.AddChangeHook(ConVarChanged_Cvars);
	g_CLIP_SECONDSHOTGUN.AddChangeHook(ConVarChanged_Cvars);
	g_CLIP_FIRSTSNIPER.AddChangeHook(ConVarChanged_Cvars);
	g_CLIP_SECONDSNIPER.AddChangeHook(ConVarChanged_Cvars);
	g_CLIP_LAUNCHER.AddChangeHook(ConVarChanged_Cvars);
	// 虚血衰减
	pain_pills_decay_rate = FindConVar("pain_pills_decay_rate");
	// 是否写出Config文件，要用config文件控制就把这个注释删了
	// AutoExecConfig(true, "KillRegain");
}

public void ConVarChanged_Cvars (Handle convar, const char[] oldValue, const char[] newValue)
{
	GetNewCvars();
}

void GetNewCvars()
{
	g_iAmmoFillClip = g_AmmoFillClip.IntValue;
	g_iAmmoRegain = g_AmmoRegain.IntValue;
	g_iHealth = g_Health.IntValue;
	g_iHealthRegain = g_HealthRegain.IntValue;
	g_iTempHealthRegain = g_TempHealthRegain.IntValue;
	g_iSpecialAmmoRegain = g_SpecialAmmoRegain.IntValue;
	g_iSpecialClip = g_SpecialClip.IntValue;
	g_iRIFLE = g_RIFLE.IntValue;
	g_iSMG = g_SMG.IntValue;
	g_iSHOTGUN = g_SHOTGUN.IntValue;
	g_iSNIPER = g_SNIPER.IntValue;
	g_iLAUNCHER = g_LAUNCHER.IntValue;
	g_iCLIP_AK47 = g_CLIP_AK47.IntValue;
	g_iCLIP_M16 = g_CLIP_M16.IntValue;
	g_iCLIP_SCAR = g_CLIP_SCAR.IntValue;
	g_iCLIP_SMG = g_CLIP_SMG.IntValue;
	g_iCLIP_FIRSTSHOTGUN = g_CLIP_FIRSTSHOTGUN.IntValue;
	g_iCLIP_SECONDSHOTGUN = g_CLIP_SECONDSHOTGUN.IntValue;
	g_iCLIP_FIRSTSNIPER = g_CLIP_FIRSTSNIPER.IntValue;
	g_iCLIP_SECONDSNIPER = g_CLIP_SECONDSNIPER.IntValue;
	g_iCLIP_LAUNCHER = g_CLIP_LAUNCHER.IntValue;
}

// 杀死小ss
public Action evt_killnormal (Event event, const char[] name, bool dontBroadcast)
{
	int killer = GetClientOfUserId(event.GetInt("attacker"));
	// 是否是近战，所有近战武器数字id都是19，如果是近战则不执行下面语句
	int nowweapon = event.GetInt("weapon_id");
	if (nowweapon == 19)
	{
		return Plugin_Continue;
	}
	else
	{
		// 检查玩家有效性
		if (!(killer > 0 && killer <= MaxClients && IsClientConnected(killer) && IsClientInGame(killer) && !IsFakeClient(killer) && GetClientTeam(killer) == TEAM_SURVIVOR))
		{
			return Plugin_Continue;
		}
		int g_weapon = GetPlayerWeaponSlot(killer, 0);
		// 是否是无效的武器
		if (!IsValidEntity(g_weapon))
		{
			return Plugin_Continue;
		}
		char weaponname[64];
		GetEdictClassname(g_weapon, weaponname, sizeof(weaponname));
		// 检测玩家是否有效
		// PrintToChatAll("[Debug]：杀小ss回复子弹的Cvar的值为：%d", g_iAmmoRegain);
		// PrintToChatAll("[Debug]：杀小ss回复一个弹夹的子弹的Cvar的值为：%d", g_iAmmoFillClip);
		if(IsValidClient(killer) && IsClientInGame(killer) && GetClientTeam(killer) == TEAM_SURVIVOR && !IsFakeClient(killer))
		{
			// 杀小ss计数，先是加前置弹夹的子弹
			if (g_iAmmoRegain == 0)
			{
				// do nothing
				// PrintToChatAll("[Debug]：由于杀小ss的Cvar设置为0，因此不执行下面的命令");
			}
			else
			{
				if(ammocount[killer] < g_iAmmoRegain - 1)
				{
					ammocount[killer] += 1;
					// PrintToChatAll("[Debug]：你已经杀了：%d 个小ss", ammocount[killer]);
				}
				else
				{
					ammocount[killer] = 0;
					StartAmmoRegain_Top (g_weapon, weaponname);
					// PrintToChatAll("[Debug]：已回复子弹");
				}
			}
			// 再加备弹
			if (g_iAmmoFillClip == 0)
			{
				// do nothing
				// PrintToChatAll("[Debug]：由于杀小ss回复一个弹夹的子弹的Cvar设置为0，因此不执行下面的命令");
			}
			else
			{
				if (clipcount[killer] < g_iAmmoFillClip - 1)
				{
					clipcount[killer] += 1;
					// PrintToChatAll("[Debug]：你已经杀了：%d 个小ss", clipcount[killer]);
				}
				else
				{
					clipcount[killer] = 0;
					StartAmmoRegain_Clip (killer, g_weapon, weaponname);
					// PrintToChatAll("[Debug]：已回复子弹到弹夹");
				}
			}
		}
	}
	return Plugin_Continue;
}

// 杀死特感
public Action evt_kill_infected (Event event, const char[] name, bool dontBroadcast)
{
	int zombieClass = 0, g_weapon = -1;
	int killer = GetClientOfUserId(event.GetInt("attacker"));
	int deadbody = GetClientOfUserId(event.GetInt("userid"));
	// 检测击杀者是否为玩家
	if (killer > 0 && killer <= MaxClients && IsClientConnected(killer) && IsClientInGame(killer) && !IsFakeClient(killer) && GetClientTeam(killer) == TEAM_SURVIVOR)
	{
		g_weapon = GetPlayerWeaponSlot(killer, 0);
	}
	// 检测武器是否有效
	if (IsValidEntity(g_weapon))
	{
		char weaponname[64];
		GetEntityClassname(g_weapon, weaponname, sizeof(weaponname));
		char weapon[64];
		event.GetString("weapon", weapon, sizeof(weapon));
		if (0 < killer <= MaxClients && deadbody != 0)
		{
			// 检测是否杀死队友
			if(GetClientTeam(deadbody) == TEAM_SURVIVOR)
			{
				return Plugin_Continue;
			}
			if(GetClientTeam(killer) == TEAM_SURVIVOR)
			{
				zombieClass = GetEntProp(deadbody, Prop_Send, "m_zombieClass");
				// 除坦克和Witch外所有类型特感
				if(zombieClass == 1 || zombieClass == 2 || zombieClass == 3 || zombieClass == 4 || zombieClass == 5 || zombieClass == 6)
				{
					// 回子弹，如果回子弹的Cvar是0，不作任何事情，跳到下一个判断
					if (g_iSpecialAmmoRegain == 0)
					{
						// do nothing
					}
					else
					{
						if (siammocount[killer] < g_iSpecialAmmoRegain - 1)
						{
							siammocount[killer] += 1;
						}
						else
						{
							if (StrEqual(weapon, "melee"))
							{
								// 如果是用近战杀的, do noting
							}
							else
							{
								siammocount[killer] = 0;
								StartAmmoRegain_Top(g_weapon, weaponname);
							}
						}
					}
					
					if (g_iSpecialClip == 0)
					{
						// do nothing
					}
					else
					{
						if (siclipcount[killer] < g_iSpecialClip - 1)
						{
							siclipcount[killer] += 1;
						}
						else
						{
							if (StrEqual(weapon, "melee"))
							{
								// 如果是用近战杀的, do nothing too
							}
							else
							{
								siclipcount[killer] = 0;
								StartAmmoRegain_Clip(killer, g_weapon, weaponname);
							}
						}
					}
					// 开始回血
					if (g_iHealth == 0)
					{
						// do nothing
					}
					else
					{
						if(IsPlayerIncap(killer))
						{
							//倒地不检测回血
						}
						else
						{
							if (sicount[killer] < g_iHealth - 1)
							{
								sicount[killer] += 1;
							}
							else
							{
								sicount[killer] = 0;
								// 计算目标生命值
								int TargetHealth = GetSurvivorPermHealth(killer) + g_iHealthRegain;
								float TargetTemp = GetSurvivorTempHealth(killer) + g_iTempHealthRegain;
								// 设置生命值，判断加血量超过100直接设置成100
								if (GetSurvivorPermHealth(killer) + g_iHealthRegain > 100)
								{
									SetSurvivorPermHealth(killer, 100);
								}
								else
								{
									// 加血量没超过100就加相应的血
									SetSurvivorPermHealth(killer, TargetHealth);
									SetSurvivorTempHealth(killer, TargetTemp);
								}
							}
						}
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

// 一些方法
public void StartAmmoRegain_Top (int weapon, const char[] weaponname)
{
	int maxClipSize = GetEntProp (weapon, Prop_Send, "m_iClip1", 1);
	// 检测不同武器，回复子弹
	if (strcmp(weaponname, "weapon_smg") == 0 || strcmp(weaponname, "weapon_smg_silenced") == 0 || strcmp(weaponname, "weapon_smg_mp5") == 0)
	{
		(maxClipSize + g_iSMG > MAX_SMG) ? SetGunAmmo(weapon, MAX_SMG) : SetGunAmmo(weapon, maxClipSize + g_iSMG);
	}
	else if (strcmp(weaponname, "weapon_pumpshotgun") == 0 || strcmp(weaponname, "weapon_shotgun_chrome") == 0)
	{
		(maxClipSize + g_iSHOTGUN > MAX_FIRSTSHOTGUN) ? SetGunAmmo(weapon, MAX_FIRSTSHOTGUN) : SetGunAmmo(weapon, maxClipSize + g_iSHOTGUN);
	}
	else if (strcmp(weaponname, "weapon_autoshotgun") == 0 || strcmp(weaponname, "weapon_shotgun_spas") == 0)
	{
		(maxClipSize + g_iSHOTGUN > MAX_SECONDSHOTGUN) ? SetGunAmmo(weapon, MAX_SECONDSHOTGUN) : SetGunAmmo(weapon, maxClipSize + g_iSHOTGUN);
	}
	else if (strcmp(weaponname, "weapon_rifle") == 0 || strcmp(weaponname, "weapon_rifle_sg552") == 0)
	{
		(maxClipSize + g_iRIFLE > MAX_M16) ? SetGunAmmo(weapon, MAX_M16) : SetGunAmmo(weapon, maxClipSize + g_iRIFLE);
	}
	else if (strcmp(weaponname, "weapon_rifle_ak47") == 0)
	{
		(maxClipSize + g_iRIFLE > MAX_AK47) ? SetGunAmmo(weapon, MAX_AK47) : SetGunAmmo(weapon, maxClipSize + g_iRIFLE);
	}
	else if (strcmp(weaponname, "weapon_rifle_desert") == 0)
	{
		(maxClipSize + g_iRIFLE > MAX_SCAR) ? SetGunAmmo(weapon, MAX_SCAR) : SetGunAmmo(weapon, maxClipSize + g_iRIFLE);
	}
	else if (strcmp(weaponname, "weapon_hunting_rifle") == 0 || strcmp(weaponname, "weapon_sniper_scout") == 0 || strcmp(weaponname, "weapon_sniper_awp") == 0)
	{
		(maxClipSize + g_iSNIPER > MAX_FIRSTSNIPER) ? SetGunAmmo(weapon, MAX_FIRSTSNIPER) : SetGunAmmo(weapon, maxClipSize + g_iSNIPER);
	}
	else if (strcmp(weaponname, "weapon_sniper_military") == 0)
	{
		(maxClipSize + g_iSNIPER > MAX_SECONDSNIPER) ? SetGunAmmo(weapon, MAX_SECONDSNIPER) : SetGunAmmo(weapon, maxClipSize + g_iSNIPER);
	}
	else if (strcmp(weaponname, "weapon_grenade_launcher") == 0)
	{
		(maxClipSize + g_iLAUNCHER > MAX_GRENADE_LAUNCHER) ? SetGunAmmo(weapon, MAX_GRENADE_LAUNCHER) : SetGunAmmo(weapon, maxClipSize + g_iLAUNCHER);
	}
	// M60 子弹设置
	else if (strcmp(weaponname, "weapon_rifle_m60") == 0)
	{
		(maxClipSize + g_M60.IntValue > MAX_M60) ? SetGunAmmo(weapon, MAX_M60) : SetGunAmmo(weapon, maxClipSize + g_M60.IntValue);
	}
}

public void StartAmmoRegain_Clip (int client, int weapon, const char[] weaponname)
{
	// 获取武器备弹
	int ammoregain;
	int primtype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
	int nowammo = GetEntProp(client, Prop_Send, "m_iAmmo", _, primtype);
	if (strcmp(weaponname, "weapon_smg") == 0 || strcmp(weaponname, "weapon_smg_silenced") == 0 || strcmp(weaponname, "weapon_smg_mp5") == 0)
	{
		ammoregain = g_iCLIP_SMG;
	}
	else if (strcmp(weaponname, "weapon_pumpshotgun") == 0 || strcmp(weaponname, "weapon_shotgun_chrome") == 0)
	{
		ammoregain = g_iCLIP_FIRSTSHOTGUN;
	}
	else if (strcmp(weaponname, "weapon_autoshotgun") == 0 || strcmp(weaponname, "weapon_shotgun_spas") == 0)
	{
		ammoregain = g_iCLIP_SECONDSHOTGUN;
	}
	else if (strcmp(weaponname, "weapon_rifle") == 0 || strcmp(weaponname, "weapon_rifle_sg552") == 0)
	{
		ammoregain = g_iCLIP_M16;
	}
	else if (strcmp(weaponname, "weapon_rifle_ak47") == 0)
	{
		ammoregain = g_iCLIP_AK47;
	}
	else if (strcmp(weaponname, "weapon_rifle_desert") == 0)
	{
		ammoregain = g_iCLIP_SCAR;
	}
	else if (strcmp(weaponname, "weapon_hunting_rifle") == 0 || strcmp(weaponname, "weapon_sniper_scout") == 0 || strcmp(weaponname, "weapon_sniper_awp") == 0)
	{
		ammoregain = g_iCLIP_FIRSTSNIPER;
	}
	else if (strcmp(weaponname, "weapon_sniper_military") == 0)
	{
		ammoregain = g_iCLIP_SECONDSNIPER;
	}
	else if (strcmp(weaponname, "weapon_grenade_launcher") == 0)
	{
		ammoregain = g_iCLIP_LAUNCHER;
	}
	SetGunClip(client, nowammo + ammoregain, primtype);
}

stock void SetGunAmmo(int client, int ammo)
{
	SetEntProp(client, Prop_Send, "m_iClip1", ammo);
}

stock void SetGunClip(int client, int clipammo, int weapontype)
{
	SetEntProp(client, Prop_Send, "m_iAmmo", clipammo, _, weapontype);
}

stock int GetSurvivorPermHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

stock float GetSurvivorTempHealth(int client)
{
	float tmp = GetEntPropFloat(client, Prop_Send, "m_healthBuffer") - ((GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime")) * GetConVarFloat(pain_pills_decay_rate));
	return tmp > 0 ? tmp : 0.0;
}

stock void SetSurvivorPermHealth(int client, int health)
{
	SetEntProp(client, Prop_Send, "m_iHealth", health);
}

stock void SetSurvivorTempHealth(int client, float newOverheal)
{
	SetEntPropFloat(client, Prop_Send, "m_healthBufferTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_healthBuffer", newOverheal);
}

//秒妹回血
public void WitchKilled_Event(Handle event, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client) && !IsPlayerIncap(client))
	{
		int maxhp = GetEntProp(client, Prop_Data, "m_iMaxHealth");
		int targetHealth = GetSurvivorPermHealth(client) + GetConVarInt(g_witch_restore);
		if(targetHealth > maxhp)
		{
			targetHealth = maxhp;
		}
		SetSurvivorPermHealth(client, targetHealth);
	}
}

stock bool IsPlayerIncap(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}
