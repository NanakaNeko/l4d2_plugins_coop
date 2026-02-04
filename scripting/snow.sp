#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

int g_iSnow;
bool g_bSnow;

public Plugin myinfo =
{
	name = "[L4D2]飘雪特效",
	author = "奈",
	description = "snow",
	version = "1.1",
	url = "https://github.com/NanakaNeko/l4d2_plugins_coop"
};

public void OnPluginStart()
{
    RegAdminCmd("sm_snow", CmdSnow, ADMFLAG_ROOT, "开关飘雪");
}

Action CmdSnow(int client, int args)
{
    if(IsValidEntRef(g_iSnow))
    {
        RemoveEntity(g_iSnow);
        g_iSnow = 0;
        g_bSnow = false;
        PrintToChatAll("\x03[天气] \x05飘雪特效 \x04关闭");
    }
    else
    {
        CreateSnow();
        g_bSnow = true;
        PrintToChat(client, "\x03[天气] \x05飘雪特效 \x04开启");
    }
    return Plugin_Handled;
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client)
{
    if(g_bSnow)
        CreateSnow();
    return Plugin_Stop;
}

void CreateSnow()
{
    int value, entity = -1;
    while( (entity = FindEntityByClassname(entity, "func_precipitation")) != INVALID_ENT_REFERENCE )
    {
        value = GetEntProp(entity, Prop_Data, "m_nPrecipType");
        if( value < 0 || value == 4 || value > 5 )
            RemoveEntity(entity);
    }

    entity = CreateEntityByName("func_precipitation");
    if( entity != -1 )
    {
        char buffer[128];
        GetCurrentMap(buffer, sizeof(buffer));
        Format(buffer, sizeof(buffer), "maps/%s.bsp", buffer);

        DispatchKeyValue(entity, "model", buffer);
        DispatchKeyValue(entity, "targetname", "silver_snow");
        DispatchKeyValue(entity, "preciptype", "3");
        DispatchKeyValue(entity, "renderamt", "100");
        DispatchKeyValue(entity, "rendercolor", "200 200 200");

        g_iSnow = EntIndexToEntRef(entity);

        float vBuff[3], vMins[3], vMaxs[3];
        GetEntPropVector(0, Prop_Data, "m_WorldMins", vMins);
        GetEntPropVector(0, Prop_Data, "m_WorldMaxs", vMaxs);
        SetEntPropVector(g_iSnow, Prop_Send, "m_vecMins", vMins);
        SetEntPropVector(g_iSnow, Prop_Send, "m_vecMaxs", vMaxs);

        bool found = false;
        for( int i = 1; i <= MaxClients; i++ )
        {
            if( !found && IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) )
            {
                found = true;
                GetClientAbsOrigin(i, vBuff);
                break;
            }
        }

        if( !found )
        {
            vBuff[0] = vMins[0] + vMaxs[0];
            vBuff[1] = vMins[1] + vMaxs[1];
            vBuff[2] = vMins[2] + vMaxs[2];
        }

        DispatchSpawn(g_iSnow);
        ActivateEntity(g_iSnow);
        TeleportEntity(g_iSnow, vBuff, NULL_VECTOR, NULL_VECTOR);
    }
    else
        LogError("Failed to create Snow %d 'func_precipitation'");

}

bool IsValidEntRef(int entity)
{
	if( entity && EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE )
		return true;
	return false;
}
