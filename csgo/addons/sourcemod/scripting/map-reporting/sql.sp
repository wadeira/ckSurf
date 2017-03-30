// CREATE TABLE map_reports (map VARCHAR(128), type VARCHAR(32), number int);


char sql_insertReport[] = "INSERT INTO map_reports (map, type, number, steamid, reason) VALUES ('%s', '%s', '%i', '%s', '%s')";


public void db_setupDatabase() {
	////////////////////////////////
	// INIT CONNECTION TO DATABASE//
	////////////////////////////////
	char szError[255];
	g_hDb = SQL_Connect("cksurf", false, szError, 255);
	
	if (g_hDb == null)
	{
		SetFailState("Unable to connect to database (%s)", szError);
		return;
	}
	
	char szIdent[8];
	SQL_ReadDriver(g_hDb, szIdent, 8);

	return;
}

public void db_insertReport(int client, char mapName[128], char type[32], int number) {
	char szQuery[256];
	char szSteamId[32];
	GetClientAuthId(client, AuthId_Steam2, szSteamId, 32, true);
	Format(szQuery, 256, sql_insertReport, mapName, type, number, szSteamId, g_reason[client]);
	SQL_TQuery(g_hDb, insertReportCallback, szQuery, client, DBPrio_Low);
}


public void insertReportCallback(Handle owner, Handle hndl, const char[] error, any data) {
	if (hndl == null) {
		PrintToChat(data, "Este run ya fue reportado y falta que sea revisado por un administrador.")
		LogError("Error inserting poll option:  %s", error);
		return;
	}
	/* Start function call */
	Call_StartForward(g_reportForward);

	/* Push parameters one at a time */
	char szSteamId[32];
	int client = data;
	GetClientAuthId(client, AuthId_Steam2, szSteamId, 32, true);
	Call_PushString(g_typeSelected[client]);
	Call_PushCell(g_number[client]);
	Call_PushString(g_reason[client]);
	Call_PushString(g_currentMap);
	Call_PushString(szSteamId);


	/* Finish the call, get the result */
	Call_Finish();
	PrintToChat(data, "\x02[SURFLATAM] Report recibido.");
	
}