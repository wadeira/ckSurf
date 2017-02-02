#include <sourcemod>
#include <ckSurf>
#include <discord>


#define MAP_RECORD "{\"username\": \"{BOTNAME}\",\"content\": \"@here\",\"attachments\": [{\"color\": \"#d10000\",\"title\": \"A new map record was set!\",\"fields\": [{\"title\": \"Player\",\"value\": \"{PLAYER}\",\"short\": true},{\"title\": \"Map\",\"value\": \"{MAP}\",\"short\": true},{\"title\": \"Time\",\"value\": \"{TIME}\",\"short\": true}]}]}"
#define BONUS_RECORD "{\"username\": \"{BOTNAME}\",\"content\": \"@here\",\"attachments\": [{\"color\": \"#d8ff00\",\"title\": \"A new bonus record was set!\",\"fields\": [{\"title\": \"Player\",\"value\": \"{PLAYER}\",\"short\": true},{\"title\": \"Map\",\"value\": \"{MAP}\",\"short\": true},{\"title\": \"Bonus\",\"value\": \"{BONUS}\",\"short\": true},{\"title\": \"Time\",\"value\": \"{TIME}\",\"short\": true}]}]}"
#define STAGE_RECORD "{\"username\": \"{BOTNAME}\",\"content\": \"@here\",\"attachments\": [{\"color\": \"#00cbff\",\"title\": \"A new stage record was set!\",\"fields\": [{\"title\": \"Player\",\"value\": \"{PLAYER}\",\"short\": true},{\"title\": \"Map\",\"value\": \"{MAP}\",\"short\": true},{\"title\": \"Stage\",\"value\": \"{STAGE}\",\"short\": true},{\"title\": \"Time\",\"value\": \"{TIME}\",\"short\": true}]}]}"


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

	g_cvWebHookUrl = CreateConVar("st_discord_webhook", "", "Key value of webhook in discord.cfg", FCVAR_PROTECTED);
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

public Action ckSurf_OnMapFinished(int client, float ftime, char stime[54], int rank, int total, bool improved) {
	if (!improved || rank > 1)
		return Plugin_Continue;

	char player_name[(MAX_NAME_LENGTH + 1) * 2];	// Needs to be doubled since we have to escape it
	GetClientName(client, player_name, sizeof(player_name));
	Discord_EscapeString(player_name, sizeof(player_name));


	char client_name[32];
	g_cvClientName.GetString(client_name, sizeof(client_name));

	char msg[1024] = MAP_RECORD;
	ReplaceString(msg, sizeof(msg), "{BOTNAME}", client_name);
	ReplaceString(msg, sizeof(msg), "{PLAYER}", player_name);
	ReplaceString(msg, sizeof(msg), "{MAP}", g_cMapName);
	ReplaceString(msg, sizeof(msg), "{TIME}", stime);

	char webhook_url[128]
	g_cvWebHookUrl.GetString(webhook_url, sizeof(webhook_url));

	Discord_SendMessage(webhook_url, msg);
	return Plugin_Continue;
}


public Action ckSurf_OnBonusFinished(int client, float ftime, char stime[54], int rank, int total, int bonusid, bool improved) {
	if ((!improved && total > 1)  || rank > 1)
		return Plugin_Continue;

	char player_name[(MAX_NAME_LENGTH + 1) * 2];	// Needs to be doubled since we have to escape it
	GetClientName(client, player_name, sizeof(player_name));
	Discord_EscapeString(player_name, sizeof(player_name));


	char client_name[32];
	g_cvClientName.GetString(client_name, sizeof(client_name));

	// Get bonus number to string
	char bonus[2];
	IntToString(bonusid, bonus, sizeof(bonus));

	char msg[1024] = BONUS_RECORD;
	ReplaceString(msg, sizeof(msg), "{BOTNAME}", client_name);
	ReplaceString(msg, sizeof(msg), "{PLAYER}", player_name);
	ReplaceString(msg, sizeof(msg), "{MAP}", g_cMapName);
	ReplaceString(msg, sizeof(msg), "{BONUS}", bonus);
	ReplaceString(msg, sizeof(msg), "{TIME}", stime);

	char webhook_url[128]
	g_cvWebHookUrl.GetString(webhook_url, sizeof(webhook_url));

	Discord_SendMessage(webhook_url, msg);
	return Plugin_Continue;
}

public Action ckSurf_OnStageFinished(int client, float fRuntime, char[] sRuntime, int stage, int rank) {
	if (rank > 1)
		return Plugin_Continue;

	char player_name[(MAX_NAME_LENGTH + 1) * 2];	// Needs to be doubled since we have to escape it
	GetClientName(client, player_name, sizeof(player_name));
	Discord_EscapeString(player_name, sizeof(player_name));


	char client_name[32];
	g_cvClientName.GetString(client_name, sizeof(client_name));

	char stage_str[2];
	IntToString(stage, stage_str, sizeof(stage_str));

	char msg[1024] = STAGE_RECORD;
	ReplaceString(msg, sizeof(msg), "{BOTNAME}", client_name);
	ReplaceString(msg, sizeof(msg), "{PLAYER}", player_name);
	ReplaceString(msg, sizeof(msg), "{MAP}", g_cMapName);
	ReplaceString(msg, sizeof(msg), "{STAGE}", stage_str);
	ReplaceString(msg, sizeof(msg), "{TIME}", sRuntime);

	char webhook_url[128]
	g_cvWebHookUrl.GetString(webhook_url, sizeof(webhook_url));

	Discord_SendMessage(webhook_url, msg);
	return Plugin_Continue;
}