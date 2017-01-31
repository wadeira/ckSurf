#include <sourcemod>
#include <ckSurf>
#include <discord>


/*****************************
 * Plugin Info
 *****************************/

public Plugin myinfo = {
	name = "Surf Timer - Discord announcer",
	author = "marcowmadeira",
	description = "Displays announcements on discord when a new record is set.",
	version = "1.0",
	url = "http://marcowmadeira.com"
};


/*****************************
 * Variables
 *****************************/

char g_cMapName[128];


/*****************************
 * Console Variables
 *****************************/

ConVar g_cvWebHookUrl;
ConVar g_cvClientName;


public void OnPluginStart() {

	g_cvWebHookUrl = CreateConVar("st_discord_webhook", "", "Discord's webhook url", FCVAR_PROTECTED);
	g_cvClientName = CreateConVar("st_discord_name", "Surf Timer", "Name of the bot");

	AutoExecConfig(true, "surftimer_discord");
}

public void OnMapStart() {
	// Get mapname
	GetCurrentMap(g_cMapName, 128);

	// Workshop fix
	char mapPieces[6][128];
	int lastPiece = ExplodeString(g_cMapName, "/", mapPieces, sizeof(mapPieces), sizeof(mapPieces[]));
	Format(g_cMapName, sizeof(g_cMapName), "%s", mapPieces[lastPiece - 1]);
}


public DiscordWebHook GetHook() {

	// Get the webhook url from cvar
	char webhook_url[128]
	g_cvWebHookUrl.GetString(webhook_url, sizeof(webhook_url));

	// Init a new webhook instance
	DiscordWebHook hook = new DiscordWebHook(webhook_url);

	hook.SlackMode = true;

	// Get the bot name
	char client_name[32];
	g_cvClientName.GetString(client_name, sizeof(client_name));

	// Set the name
	hook.SetUsername(client_name);


	// Notify users
	hook.SetContent("@here");

	return hook;
}


public Action ckSurf_OnMapFinished(int client, float ftime, char stime[54], int rank, int total, bool improved) {
	if (!improved || rank > 1)
		return Plugin_Continue;

	char player_name[32];
	GetClientName(client, player_name, sizeof(player_name));

	DiscordWebHook hook = GetHook();

	hook.SetColor("#d10000");
	hook.SetTitle("A new map record was set!")
	hook.AddField("Player:", player_name, true);
	hook.AddField("Map:", g_cMapName, true);
	hook.AddField("Time:", stime, true);

	hook.Send();
	delete hook;
}


public Action ckSurf_OnBonusFinished(int client, float ftime, char stime[54], int rank, int total, int bonusid, bool improved) {
	if (!improved || rank > 1)
		return Plugin_Continue;

	char player_name[32];
	GetClientName(client, player_name, sizeof(player_name));

	// Get bonus number to string
	char bonus[2];
	IntToString(bonusid, bonus, sizeof(bonus));

	DiscordWebHook hook = GetHook();

	hook.SetColor("#d8ff00");
	hook.SetTitle("A new bonus record was set!")
	hook.AddField("Player:", player_name, true);
	hook.AddField("Map:", g_cMapName, true);
	hook.AddField("Bonus:", bonus, true);
	hook.AddField("Time:", stime, true);

	hook.Send();
	delete hook;
}

public Action ckSurf_OnStageFinished(int client, float fRuntime, char[] sRuntime, int stage, int rank) {
	if (rank > 1)
		return Plugin_Continue;

	char player_name[32];
	GetClientName(client, player_name, sizeof(player_name));

	char stage_str[2];
	IntToString(stage, stage_str, sizeof(stage_str));

	DiscordWebHook hook = GetHook();
	

	hook.SetColor("#00cbff");
	hook.SetTitle("A new stage record was set!")
	hook.AddField("Player:", player_name, true);
	hook.AddField("Map:", g_cMapName, true);
	hook.AddField("Stage:", stage_str, true);
	hook.AddField("Time:", sRuntime, true);

	hook.Send();
	delete hook;
}