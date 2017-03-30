
#include <sourcemod>
#include <sdkhooks>
#include <adminmenu>
#include <cstrike>
#include <smlib>
#include <sdktools>
#include <basecomm>
#include <colors>
#include <ckSurf>
#undef REQUIRE_EXTENSIONS
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <mapreport>
#include <dhooks>


public Plugin myinfo =
{
	name = "Map Reporting",
	author = "",
	description = "",
	version = "1.0",
	url = ""
};

char g_currentMap[128];
char g_typeSelected[MAXPLAYERS+1][32];
char g_reason[MAXPLAYERS+1][32];
int g_number[MAXPLAYERS+1];
Handle g_hDb = null; 											// SQL driver
Handle g_reportForward;
#include "map-reporting/sql.sp"


#define MULTI_SERVER_MAPCYCLE "configs/ckSurf/multi_server_mapcycle.txt"

public void OnPluginStart() {
	RegConsoleCmd("sm_reportmap", Command_Report, "Report a broken record");
	RegConsoleCmd("sm_viewreports", Command_ViewReports, "View reports");
	g_reportForward = CreateGlobalForward("OnMapReport", ET_Event, Param_String, Param_Cell, Param_String, Param_String, Param_String);
	db_setupDatabase();
	CreateTimer(280.0, Timer_AnnounceExistance, _, TIMER_REPEAT);
}

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
   RegPluginLibrary("map-reporting");
}

public void OnMapStart() {
	GetCurrentMap(g_currentMap, 128);
}

public Action Timer_AnnounceExistance(Handle timer)
{
	PrintToChatAll("Podes reportar un mapa buggeado/record sacado con bug con el comando !reportmap. SI LO USAS AL PEDO = BAN UNA SEMANA. Solo para 5k puntos o mas");
	return Plugin_Continue;
}


public Action Command_ViewReports(int client, int args)
{
	askRun(client, g_currentMap);
	return Plugin_Handled;
}

public Action Command_Report(int client, int args)
{
	if (ckSurf_GetPlayerPoints(client) < 5000) {
		PrintToChat(client, "Solo podes reportar mapas si tenes mas de 5000 puntos");
		return Plugin_Handled;
	}

	askReason(client);
	return Plugin_Handled;
}

public void askReason(int client) {
	Menu menu = new Menu(AskReasonHandler);

	menu.SetTitle("Razon de reporte");

	menu.AddItem("record", "Record Buggeado", ITEMDRAW_DEFAULT);
	menu.AddItem("map", "No se puede pasar el mapa", ITEMDRAW_DEFAULT);
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);	 
}


public int AskReasonHandler(Menu menu, MenuAction action,int param1, int param2) 
{
	if (action == MenuAction_Select)
	{
		char info[32];

		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info, "map", true)){
			Format(g_reason[param1], 32, "%s", "map");
		} else if (StrEqual(info, "record", true)) {
			Format(g_reason[param1], 32, "%s", "record");
		}
		askRun(param1, g_currentMap);
	}
}

public void askRun(int client, char mapName[128]) {
	Menu menu = new Menu(AskRunHandler);

	menu.SetTitle("Que run esta roto en %s?", mapName);

	menu.AddItem("map", "Map", ITEMDRAW_DEFAULT);
	menu.AddItem("bonus", "Bonus", ITEMDRAW_DEFAULT);
	menu.AddItem("stage", "Stage", ITEMDRAW_DEFAULT);
	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);	 
}

public int AskRunHandler(Menu menu, MenuAction action,int param1, int param2) 
{
	if (action == MenuAction_Select)
	{
		char info[32];

		menu.GetItem(param2, info, sizeof(info));
		if (StrEqual(info, "stage", true)){
			Format(g_typeSelected[param1], 32, "%s", "stage");
			stageMenu(param1);
		} else if (StrEqual(info, "bonus", true)) {
			Format(g_typeSelected[param1], 32, "%s", "bonus");

			bonusMenu(param1);
		}
		else if (StrEqual(info, "map", true)) {
			Format(g_typeSelected[param1], 32, "%s", "map");

			db_insertReport(param1, g_currentMap, g_typeSelected[param1], 0);
		}
	}
}


public void bonusMenu(int client) {
	Menu menu = new Menu(TypeHandler);
	menu.SetTitle("Que bonus esta bug?");
	int stageCount = ckSurf_CountZoneGroups(0, 3)-1;

	for (int i = 1; i <= stageCount; i++)
	{
		char name[32];
		Format(name, sizeof(name), "Bonus %d", i);

		menu.AddItem(name, name, ITEMDRAW_DEFAULT);
	}

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);	 
}

public int TypeHandler(Menu menu, MenuAction action,int param1, int param2) 
{
	if (action == MenuAction_Select)
	{
		int number = param2+1;
		db_insertReport(param1, g_currentMap, g_typeSelected[param1], number);
	}
}

public void stageMenu(int client) {
	Menu menu = new Menu(TypeHandler);
	menu.SetTitle("Que stage esta bug?");
	int stageCount = ckSurf_CountZones(0, 3);

	for (int i = 1; i <= stageCount; i++)
	{
		char name[32];
		Format(name, sizeof(name), "Stage %d", i);

		menu.AddItem(name, name, ITEMDRAW_DEFAULT);
	}

	menu.ExitButton = true;
	menu.Display(client, MENU_TIME_FOREVER);	 
}

public void performMapReport(char type[32], int client) {
	return;
}
