
public void db_insertStageRecord(int client, int stage, float runtime)
{
		char query[256];
		Format(query, sizeof(query), sql_insertStageRecord, g_szSteamID[client], g_szMapName, stage, runtime);

		DataPack pack = new DataPack();

		pack.WriteCell(client);
		pack.WriteCell(stage);

		SQL_TQuery(g_hDb, sql_insertStageRecordCallback, query, pack, DBPrio_High);
}

public void sql_insertStageRecordCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_insertStageRecordCallback): %s", error);
		return;
	}

	DataPack pack = view_as<DataPack>(data);
	pack.Reset();
	int client = pack.ReadCell();
	int stage = pack.ReadCell();

	db_updateStageRank(client, stage);

	g_StageRecords[stage][srCompletions]++;
}


public void db_updateStageRecord(int client, int stage, float runtime)
{
	char query[256];
	Format(query, sizeof(query), sql_updateStageRecord, runtime, g_szMapName, g_szSteamID[client], stage);

	DataPack pack = new DataPack();

	pack.WriteCell(client);
	pack.WriteCell(stage);

	SQL_TQuery(g_hDb, sql_updateStageRecordCallback, query, pack, DBPrio_High);
}

public void sql_updateStageRecordCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_updateStageRecordCallback): %s", error);
		return;
	}

	DataPack pack = view_as<DataPack>(data);
	pack.Reset();
	int client = pack.ReadCell();
	int stage = pack.ReadCell();

	// Update Rank
	db_updateStageRank(client, stage);
}

// todo: load all stages in 1 query
public void db_loadStageServerRecords(int stage)
{
	char query[512];
	Format(query, sizeof(query), sql_selectStageRecords, g_szMapName, stage, g_szMapName, stage);
	SQL_TQuery(g_hDb, sql_loadStageServerRecordsCallback, query, stage, DBPrio_Low);
}

public void sql_loadStageServerRecordsCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_loadStageServerRecordsCallback): %s", error);
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		int stage = SQL_FetchInt(hndl, 0);
		float runtime = SQL_FetchFloat(hndl, 1);
		char name[45];
		SQL_FetchString(hndl, 2, name, sizeof(name));
		int completions = SQL_FetchInt(hndl, 3);

		g_StageRecords[stage][srRunTime] = runtime;
		g_StageRecords[stage][srLoaded] = true;
		g_StageRecords[stage][srCompletions] = completions;

		strcopy(g_StageRecords[stage][srPlayerName], sizeof(name), name);
	}


	if (data > g_mapZonesTypeCount[0][3])
			g_bLoadingStages = false;


	// Check if we are still loading the stages
	if (g_bLoadingStages)
		db_loadStageServerRecords(data+1);

	return;
}

public void db_loadStagePlayerRecords(int client)
{
	 char query[256];
	 Format(query, sizeof(query), sql_selectStagePlayerRecords, g_szMapName, g_szSteamID[client]);
	 SQL_TQuery(g_hDb, sql_selectStagePlayerRecordsCallback, query, client, DBPrio_Low);
}


public void sql_selectStagePlayerRecordsCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_selectStagePlayerRecordsCallback): %s", error);
		return;
	}

	int client = data;

	if (SQL_HasResultSet(hndl))
	{
		while(SQL_FetchRow(hndl))
		{
			int stage = SQL_FetchInt(hndl, 0);
			float runtime = SQL_FetchFloat(hndl, 1);
			int rank = SQL_FetchInt(hndl, 3);

			g_fStagePlayerRecord[client][stage] = runtime;
			g_StagePlayerRank[client][stage] = rank;
		}
	}

	if (!g_bSettingsLoaded[client])
	{	
		db_getChatTags(client);
		g_bSettingsLoaded[client] = true;
		g_bLoadingSettings[client] = false;
		if (GetConVarBool(g_hTeleToStartWhenSettingsLoaded))
			Command_Restart(client, 1);

		// Seach for next client to load
		for (int i = 1; i < MAXPLAYERS + 1; i++)
		{
			if (IsValidClient(i) && !IsFakeClient(i) && !g_bSettingsLoaded[i] && !g_bLoadingSettings[i])
			{
				char szSteamID[32];
				GetClientAuthId(i, AuthId_Steam2, szSteamID, 32, true);
				db_viewPersonalRecords(i, szSteamID, g_szMapName);
				g_bLoadingSettings[i] = true;
				break;
			}
		}
	}
}

public void db_updateStageRank(int client, int stage)
{
	char query[256];
	Format(query, sizeof(query), "SELECT COUNT(*) FROM ck_stages WHERE runtime <= (SELECT runtime FROM ck_stages WHERE map = '%s' and stage = '%d' AND steamid = '%s') AND map = '%s' AND stage = '%d' ORDER BY runtime, date ASC;", g_szMapName, stage, g_szSteamID[client], g_szMapName, stage);

	DataPack data = new DataPack();
	data.WriteCell(client);
	data.WriteCell(stage);

	SQL_TQuery(g_hDb, SQL_updateStageRankCallback, query, data, DBPrio_Low);
}


public void SQL_updateStageRankCallback(Handle owner, Handle hndl, const char[] error, any data)
{

	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_updateStageRankCallback): %s", error);
		return;
	}

	int rank = -1;

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		rank = SQL_FetchInt(hndl, 0);

		DataPack pack = view_as<DataPack>(data);
		pack.Reset();
		int client = pack.ReadCell();
		int stage = pack.ReadCell();

		// Check if the player improved his time
		if (rank != -1 && rank < g_StagePlayerRank[client][stage])
			PrintToChat(client, "[%cSurf Timer%c] %cYou improved your time, your rank is now %c%d/%d", MOSSGREEN, WHITE, YELLOW, LIMEGREEN, rank, g_StageRecords[stage][srCompletions]);
			
		g_StagePlayerRank[client][stage] = rank;

		// Format time
		char runtime_str[32];
		FormatTimeFloat(client, g_fStagePlayerRecord[client][stage], 5, runtime_str, sizeof(runtime_str));

		g_pr_showmsg[client] = true;
		CalculatePlayerRank(client);

		// Forward
		Call_StartForward(g_StageFinishedForward);
		Call_PushCell(client);
		Call_PushFloat(g_fStagePlayerRecord[client][stage]);
		Call_PushString(runtime_str);
		Call_PushCell(stage);
		Call_PushCell(rank);
		Call_Finish();
	}
}
