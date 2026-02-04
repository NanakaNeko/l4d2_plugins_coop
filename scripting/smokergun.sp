#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define SOUND_FIRE				"player/smoker/miss/smoker_reeltonguein_01.wav"
 
#define MODEL_W_PIPEBOMB		"models/w_models/weapons/w_eq_pipebomb.mdl"
#define particle_smoker_tongue	"smoker_tongue"

enum STATE {SHOT = 1, NONE = 0}
STATE states[MAXPLAYERS+1];
float scopes[MAXPLAYERS+1];
bool count[MAXPLAYERS + 1] = {false, ...};
float time_last[MAXPLAYERS+1];
float time_hurt[MAXPLAYERS+1];
float time_jump[MAXPLAYERS+1];
int targets[MAXPLAYERS+1];
bool frees[MAXPLAYERS+1];
int ents[MAXPLAYERS+1][3];
float position_target[MAXPLAYERS+1][3];
int button_last[MAXPLAYERS+1];

ConVar Plugin_enabled;
ConVar Rope_damage;			float rope_damage;
ConVar Rope_distance;		float rope_distance;
ConVar Rope_count;			bool rope_count;
 
int g_iVelocity = 0;

public Plugin myinfo =
{
	name = "[L4D2]舌头枪",
	author = " pan xiao hai, NoroHime, 奈",
	description = "Swinging Rope like Tarzan",
	version = "3.0.5",
	url = "https://forums.alliedmods.net/showthread.php?p=2050712"
}

public void OnPluginStart()
{ 	 
	
	g_iVelocity =		FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");

	Plugin_enabled =	CreateConVar("l4d2_rope_enabled", "1", "开关插件 关:0 开:1", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	Rope_damage =		CreateConVar("l4d2_rope_damage", "10", "舌头伤害", FCVAR_NOTIFY, true);
 	Rope_distance =		CreateConVar("l4d2_rope_distance", "1200.0", "最大允许距离", FCVAR_NOTIFY, true, 1.0);
 	Rope_count =		CreateConVar("l4d2_rope_count", "0", "数量是否无限 每关一次:0 无限次:1", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	Rope_damage.AddChangeHook(OnConVarChanged);
	Rope_distance.AddChangeHook(OnConVarChanged);
	Rope_count.AddChangeHook(OnConVarChanged);
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue) {
	ApplyCvars();
}

public void OnConfigsExecuted() {
	ApplyCvars();
}

public void ApplyCvars() {
	static bool hooked = false;
	bool plugin_enabled = Plugin_enabled.BoolValue;

	if (plugin_enabled && !hooked) {

		HookEvent("player_spawn", player_spawn);
		HookEvent("player_death", player_death, EventHookMode_Pre);
		HookEvent("round_start", round_end);
		HookEvent("round_end", round_end);
		HookEvent("finale_win", round_end);
		HookEvent("mission_lost", round_end);
		HookEvent("map_transition", round_end);

		hooked = true;

	} else if (!plugin_enabled && hooked) {

		UnhookEvent("player_spawn", player_spawn);
		UnhookEvent("player_death", player_death, EventHookMode_Pre);
		UnhookEvent("round_start", round_end);
		UnhookEvent("round_end", round_end);
		UnhookEvent("finale_win", round_end);
		UnhookEvent("mission_lost", round_end);
		UnhookEvent("map_transition", round_end);

		hooked = false;
	}

	rope_damage = Rope_damage.FloatValue;
	rope_distance = Rope_distance.FloatValue;
	rope_count = Rope_count.BoolValue;
}

public void OnMapStart() {
	ResetAllState();
	PrecacheModel(MODEL_W_PIPEBOMB);
	PrecacheSound(SOUND_FIRE); 
} 

public void round_start(Event event, const char[] name, bool dontBroadcast) {
	ResetAllState();
}
 
public void round_end(Event event, const char[] name, bool dontBroadcast) {
	ResetAllState();
}

void ResetAllState() {
	for(int i = 1; i <= MaxClients; i++)
		ResetClientState(i); 
}

void ResetClientState(int client) {
	states[client] = NONE;
	ents[client][0] = 0;
	ents[client][1] = 0;
	ents[client][2] = 0;
	count[client] = false;
}

public void player_spawn(Event event, const char[] name, bool DontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));  
	ResetClientState(client);
}

public void player_death(Event event, const char[] name, bool DontBroadcast) {

	StopRope(GetClientOfUserId(GetEventInt(event, "userid")));
	//for(int i=1; i<=MaxClients; i++)
	//	if(targets[i] == dead) {
	//		targets[i]=0;
	//		StopRope(i);
	//	}

}

int grabber[MAXPLAYERS + 1];

void StartRope(int client) {
	if(!rope_count)
		if(count[client])
			return;
	
	if(states[client] != NONE) return;
	
	float pos[3], angle[3], hitpos[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client, angle);	
 
	int target = GetEnt(client, pos, angle, hitpos); 
	if(GetVectorDistance(pos, hitpos) > rope_distance) {
		PrintHintText(client, "太远啦");
		return;
	}

	scopes[client] = GetVectorDistance(pos, hitpos);
	frees[client] = true;

	time_hurt[client] = GetEngineTime() - 1.0;
	time_last[client] = GetEngineTime() - 0.01;
	time_jump[client] = GetEngineTime() - 0.5;
	
	states[client] = SHOT; 
	CreateRope(client, target, pos, hitpos); 
	CopyVector(hitpos, position_target[client]);
	
	if (isClient(target)) {
		grabber[target] = client;
		PrintHintText(client, "抓住了 %N", target);
	}
	EmitSoundToAll(SOUND_FIRE, 0,  SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, pos, NULL_VECTOR, true, 0.0);

}

static const float VOID_VECTOR[3];
void StopRope(int client) {

	if (states[client] == SHOT) {
		states[client]=NONE;
		
		ClearClientEnts(client);

		for (int i = 1; i <= MaxClients; i++) {
			if (grabber[i] == client)
				grabber[i] = 0;
		}

		if(!rope_count)
			count[client] = true;
	}
}

void ClearClientEnts(int client) {
	int ent_target = ents[client][0],
		ent_source = ents[client][1],
		ent_particle = ents[client][2];

	if (IsValidEdict(ent_target)) {
		AcceptEntityInput(ent_target, "ClearParent");  
		TeleportEntity(ent_target, VOID_VECTOR, NULL_VECTOR, NULL_VECTOR);
		ents[client][0] = 0;
		CreateTimer(1.0, Timer_KillEntity, ent_target);
	}

	if (IsValidEdict(ent_source)) {
		AcceptEntityInput(ent_source, "ClearParent");  
		TeleportEntity(ent_source, VOID_VECTOR, NULL_VECTOR, NULL_VECTOR);
		ents[client][1] = 0;
		CreateTimer(1.0, Timer_KillEntity, ent_source);
	}

	if (IsValidEdict(ent_particle)) {
		AcceptEntityInput(ent_particle, "Stop"); 
		CreateTimer(1.0, Timer_KillEntity, ent_particle);
		ents[client][2] = 0;
	}
}

public Action Timer_KillEntity(Handle timer, int entity) {

	if (IsValidEdict(entity)) {
		AcceptEntityInput(entity, "Kill");
		RemoveEdict(entity);
	}
	return Plugin_Handled;
}

int CreateDummyEnt() {
	int ent = CreateEntityByName("prop_dynamic_override");//	 pipe_bomb_projectile
	SetEntityModel(ent, MODEL_W_PIPEBOMB);	 // MODEL_W_PIPEBOMB
	DispatchSpawn(ent);  
	SetEntityMoveType(ent, MOVETYPE_NONE);   
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 2);   
	SetEntityRenderMode(ent, view_as<RenderMode>(3));
	SetEntityRenderColor(ent, 0,0, 0,0);	
	return ent;
}

void CreateRope(int client, int target, float pos[3], float endpos[3]) {
	
	int dummy_target = CreateDummyEnt();
	int dummy_source = CreateDummyEnt();
	
	if(isClient(target)) {
		SetVector(pos, 0.0, 0.0, 50.0);	
		AttachEnt(target, dummy_target, "", pos, NULL_VECTOR);
		SetVector(pos, 0.0, 0.0, 0.0);	
		targets[client]=target;
	} else {	
		targets[client]=0;
		TeleportEntity(dummy_target, endpos, NULL_VECTOR, NULL_VECTOR);
	}
	
	SetVector(pos,   10.0,  0.0, 0.0); 
	AttachEnt(client, dummy_source, "armL", pos, NULL_VECTOR);
	
	//TeleportEntity(dummy_source, pos, NULL_VECTOR, NULL_VECTOR);
		
	char dummy_target_name[64];
	char dummy_source_name[64];
	Format(dummy_target_name, sizeof(dummy_target_name), "target%d", dummy_target);
	Format(dummy_source_name, sizeof(dummy_source_name), "target%d", dummy_source);
	DispatchKeyValue(dummy_target, "targetname", dummy_target_name);
	DispatchKeyValue(dummy_source, "targetname", dummy_source_name);
	
	int particle = CreateEntityByName("info_particle_system");

	DispatchKeyValue(particle, "effect_name", particle_smoker_tongue);
	DispatchKeyValue(particle, "cpoint1", dummy_target_name);
	
	DispatchSpawn(particle);
	ActivateEntity(particle); 
	
	SetVector(pos, 0.0, 0.0, 0.0);	
	AttachEnt(dummy_source, particle, "", pos, NULL_VECTOR);
	
	AcceptEntityInput(particle, "start");  
	
	ents[client][0]=dummy_target;
	ents[client][1]=dummy_source;
	ents[client][2]=particle; 
}

void AttachEnt(int owner, int ent, char[] positon="medkit", float pos[3]=NULL_VECTOR,float ang[3]=NULL_VECTOR) {
	char tname[64];
	Format(tname, sizeof(tname), "target%d", owner);
	DispatchKeyValue(owner, "targetname", tname); 		
	DispatchKeyValue(ent, "parentname", tname);
	
	SetVariantString(tname);
	AcceptEntityInput(ent, "SetParent",ent, ent, 0); 	
	if(strlen(positon)!=0)
	{
		SetVariantString(positon); 
		AcceptEntityInput(ent, "SetParentAttachment");
	}
	TeleportEntity(ent, pos, ang, NULL_VECTOR);
}

bool IsEnt(int ent) {
	return ent && IsValidEdict(ent);
}

public Action Timer_StopRope(Handle timer, int client)
{
	if(states[client] == SHOT)
		StopRope(client);
	return Plugin_Handled;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(!rope_count)
		if(count[client])
			return Plugin_Continue;

	if (grabber[client] && buttons & IN_ZOOM) {
		StopRope(grabber[client]);
	}
	
	bool start_rope = ((buttons & IN_ZOOM) && !(button_last[client] & IN_ZOOM));
	bool on_ground = GetEntityFlags(client) & FL_ONGROUND ? true : false;

	if (start_rope)
	{
		char clientWeapon[32];
		GetClientWeapon(client, clientWeapon, sizeof(clientWeapon));
		if(!StrEqual("weapon_pistol", clientWeapon, false))
			return Plugin_Continue;
		
		if(states[client] == NONE)
		{
			StartRope(client);
			if(!rope_count)
				CreateTimer(10.0, Timer_StopRope, client);
		}
		else 
			StopRope(client);
	}
	
	if (states[client] == SHOT) {

		int last_button = button_last[client];
		float engine_time = GetEngineTime();
		
		float duration = engine_time-time_last[client];

		if(duration > 1.0)
			duration=1.0;
		else if (duration <= 0.0)
			duration=0.01;

		time_last[client] = engine_time; 
		
		int target = targets[client];
		float target_position[3];
		
		float client_angle[3];
		GetClientEyeAngles(client, client_angle);  
		 
		float client_eye_position[3];
		GetClientEyePosition(client, client_eye_position);
		
		if (on_ground && GetVectorDistance(client_eye_position, position_target[client]) > rope_distance) {
			PrintHintText(client, "太远啦");
			StopRope(client);
			return Plugin_Continue;
		}
		
		if (IsEnt(target)) {
			GetEntPropVector(target, Prop_Send, "m_vecOrigin", target_position);
			target_position[2] += 50.0;
			CopyVector(target_position, position_target[client]);	
		} else {
			targets[client] = 0;
			if(target > 0) {
				StopRope(client);
				return Plugin_Continue;
			}
			target = 0; 
			CopyVector(position_target[client], target_position);	
		} 
		
		float dir[3];

		if (target > 0 && (buttons & IN_SPEED)) {
			GetAngleVectors(client_angle, dir, NULL_VECTOR, NULL_VECTOR);
		 
			NormalizeVector(dir, dir);
			ScaleVector(dir, 90.0);
			AddVectors(dir, client_eye_position,client_eye_position);	
			
			float force[3];
			SubtractVectors(target_position, client_eye_position, force);
			float rope_length = GetVectorLength(force);
			scopes[client] = rope_length;
			
			NormalizeVector(force, force); 
 
			float drag_force = 300.0;
			if (rope_length < 50.0)drag_force = rope_length;
			
			ScaleVector(force, -1.0 * drag_force);
			TeleportEntity(target, NULL_VECTOR, NULL_VECTOR,force);
			
			bool hurt_target = false;
			if (engine_time - time_hurt[client]>0.1)
			{
				hurt_target = true;
				time_hurt[client] = engine_time;
			}
			
			if(hurt_target && isInfected(target)) {
				SDKHooks_TakeDamage(target, 0, client, rope_damage, DMG_ENERGYBEAM);
			}	
		} else if(target == 0) { 
			float target_distacne=GetVectorDistance(target_position, client_eye_position);
			if (on_ground) {
				on_ground = true; 
				SetEntityGravity(client, 1.0);
			}
			
			if (on_ground) {
				scopes[client] = target_distacne; 
				frees[client] = true;
			}

			if (!on_ground && (buttons & IN_SPEED)) {
				scopes[client] -= 360.0 * duration; 
				if (scopes[client] < 20.0) scopes[client] = 20.0;
				frees[client] = false;
				
			}
 
			if (!on_ground && (buttons & IN_DUCK)) {
				scopes[client] += 350.0 * duration; 
				frees[client] = false;
			} 
			
			if (!frees[client]) {
				
				float diff = target_distacne-scopes[client];
				if (diff > 20.0) {
					if ((client_eye_position[2] < target_position[2]))
						scopes[client] = target_distacne-20.0;
					diff = 20.0;
				}
				if (diff > 0) {
					float grivaty_dir[3];
					grivaty_dir[2] =- 1.0;
								 	
					float drag_dir[3];
					SubtractVectors(target_position, client_eye_position,drag_dir);
					NormalizeVector(drag_dir, drag_dir); 
					
					float add_force_dir[3];
					AddVectors(grivaty_dir,drag_dir,add_force_dir);
					NormalizeVector(add_force_dir, add_force_dir); 
					
					float client_vel[3];
					GetEntDataVector(client, g_iVelocity, client_vel);
					
					float plane[3];
					CopyVector(drag_dir, plane);
					
					float vel_on_plane[3];
					GetProjection(plane, client_vel, vel_on_plane); 
			 		
					float factor = diff / 20.0;
					
					ScaleVector(drag_dir, factor * 350.0);
					
					float new_vel[3];
					AddVectors(vel_on_plane,drag_dir,new_vel); 
	 	
					if(client_eye_position[2] < target_position[2]) {
						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, new_vel);
					}
				 		
					if((buttons & IN_JUMP) && !(last_button & IN_JUMP) && engine_time - time_jump[client] > 1.0) {
						time_jump[client] = engine_time;
						GetAngleVectors(client_angle, dir, NULL_VECTOR, NULL_VECTOR); 
						NormalizeVector(dir, dir);
						
						grivaty_dir[2] = 1.0;
						AddVectors(dir,grivaty_dir,dir);
						NormalizeVector(dir, dir);
						ScaleVector(dir, 3000.0);
						TeleportEntity(client, NULL_VECTOR, NULL_VECTOR,dir);
						scopes[client] += 10.0;
					}
				}
					
			} else {
				if(GetVectorDistance(target_position, client_eye_position) > rope_distance) {
					StopRope(client);
					return Plugin_Continue;
				}
			}
			CheckSpeed(client);		
		}
	}
	
	button_last[client]=buttons;
	return Plugin_Continue;
}

void CheckSpeed(int client) {

	float velocity[3];
	GetEntDataVector(client, g_iVelocity, velocity);

	float vel = GetVectorLength(velocity);

	if(vel > 500.0) {

		NormalizeVector(velocity, velocity);
		ScaleVector(velocity, 500.0);
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
	}
}
 
void CopyVector(float source[3], float target[3]) {
	target[0] = source[0];
	target[1] = source[1];
	target[2] = source[2];
}

void SetVector(float target[3], float x, float y, float z) {
	target[0] = x;
	target[1] = y;
	target[2] = z;
}


int GetEnt(int client, float pos[3], float angle[3], float hitpos[3]) {

	Handle trace = TR_TraceRayFilterEx(
		pos, 
		angle, 
		MASK_SOLID, 
		RayType_Infinite, 
		TraceRayDontHitSelf2, 
		client
	);

	int ent =-1;
 
	if (TR_DidHit(trace)) {			
		ent = 0;
		TR_GetEndPosition(hitpos, trace);
		ent = TR_GetEntityIndex(trace);
	}

	CloseHandle(trace); 
	return ent;
}
public bool TraceRayDontHitSelf2 (int entity, int contentsMask, any data) {
	return !(entity <= 0 || entity == data);
}

void GetProjection(float n[3], float t[3], float r[3]) {
	float A=n[0];
	float B=n[1];
	float C=n[2];
	
	float a=t[0];
	float b=t[1];
	float c=t[2];
	
	float p=-1.0*(A*a+B*b+C*c)/(A*A+B*B+C*C);
	r[0]=A*p+a;
	r[1]=B*p+b;
	r[2]=C*p+c; 
}

bool isInfected(int client) {
	return isClient(client) && GetClientTeam(client) == 3;
}

bool isClient(int client) {
	return isClientIndex(client) && IsValidEntity(client) && IsClientInGame(client);
}

bool isClientIndex(int client) {
	return (1 <= client <= MaxClients);
}

public Action L4D_OnLedgeGrabbed(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}
	

	return Plugin_Continue;
}
