
///////////////////////
//// Checkpoints //////
///////////////////////



public void db_viewRecordCheckpointInMap()
{
	for (int k = 0; k < MAXZONEGROUPS; k++)
	{
		g_bCheckpointRecordFound[k] = false;
		for (int i = 0; i < CPLIMIT; i++)
			g_fCheckpointServerRecord[k][i] = 0.0;
	}

	//"SELECT c.zonegroup, c.cp1, c.cp2, c.cp3, c.cp4, c.cp5, c.cp6, c.cp7, c.cp8, c.cp9, c.cp10, c.cp11, c.cp12, c.cp13, c.cp14, c.cp15, c.cp16, c.cp17, c.cp18, c.cp19, c.cp20, c.cp21, c.cp22, c.cp23, c.cp24, c.cp25, c.cp26, c.cp27, c.cp28, c.cp29, c.cp30, c.cp31, c.cp32, c.cp33, c.cp34, c.cp35 FROM ck_checkpoints c WHERE steamid = '%s' AND mapname='%s' UNION SELECT a.zonegroup, b.cp1, b.cp2, b.cp3, b.cp4, b.cp5, b.cp6, b.cp7, b.cp8, b.cp9, b.cp10, b.cp11, b.cp12, b.cp13, b.cp14, b.cp15, b.cp16, b.cp17, b.cp18, b.cp19, b.cp20, b.cp21, b.cp22, b.cp23, b.cp24, b.cp25, b.cp26, b.cp27, b.cp28, b.cp29, b.cp30, b.cp31, b.cp32, b.cp33, b.cp34, b.cp35 FROM ck_bonus a LEFT JOIN ck_checkpoints b ON a.steamid = b.steamid AND a.zonegroup = b.zonegroup WHERE a.mapname = '%s' GROUP BY a.zonegroup";
	char szQuery[1028];
	Format(szQuery, 1028, sql_selectRecordCheckpoints, g_szRecordMapSteamID, g_szMapName, g_szMapName);
	SQL_TQuery(g_hDb, sql_selectRecordCheckpointsCallback, szQuery, 1, DBPrio_Low);
}

public void sql_selectRecordCheckpointsCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_selectRecordCheckpointsCallback): %s", error);
		if (!g_bServerDataLoaded)
			db_CalcAvgRunTime();
		return;
	}

	if (SQL_HasResultSet(hndl))
	{
		int zonegroup;
		while (SQL_FetchRow(hndl))
		{
			zonegroup = SQL_FetchInt(hndl, 0);
			for (int i = 0; i < CPLIMIT; i++)
			{
				g_fCheckpointServerRecord[zonegroup][i] = SQL_FetchFloat(hndl, (i + 1));
				if (!g_bCheckpointRecordFound[zonegroup] && g_fCheckpointServerRecord[zonegroup][i] > 0.0)
					g_bCheckpointRecordFound[zonegroup] = true;
			}
		}
	}

	if (!g_bServerDataLoaded)
		db_CalcAvgRunTime();

	return;
}

public void db_viewCheckpoints(int client, char szSteamID[32], char szMapName[128])
{
	char szQuery[1024];
	//"SELECT zonegroup, cp1, cp2, cp3, cp4, cp5, cp6, cp7, cp8, cp9, cp10, cp11, cp12, cp13, cp14, cp15, cp16, cp17, cp18, cp19, cp20, cp21, cp22, cp23, cp24, cp25, cp26, cp27, cp28, cp29, cp30, cp31, cp32, cp33, cp34, cp35 FROM ck_checkpoints WHERE mapname='%s' AND steamid = '%s';";
	Format(szQuery, 1024, sql_selectCheckpoints, szMapName, szSteamID);
	SQL_TQuery(g_hDb, SQL_selectCheckpointsCallback, szQuery, client, DBPrio_Low);
}

public void SQL_selectCheckpointsCallback(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_selectCheckpointsCallback): %s", error);
		return;
	}

	int zoneGrp;

	if (!IsValidClient(client))
		return;

	if (SQL_HasResultSet(hndl))
	{
		while (SQL_FetchRow(hndl))
		{
			zoneGrp = SQL_FetchInt(hndl, 0);
			g_bCheckpointsFound[zoneGrp][client] = true;
			int k = 1;
			for (int i = 0; i < CPLIMIT; i++)
			{
				g_fCheckpointTimesRecord[zoneGrp][client][i] = SQL_FetchFloat(hndl, k);
				k++;
			}
		}
	}

	if (!g_bSettingsLoaded[client])
		db_loadStagePlayerRecords(client);
}

public void db_viewCheckpointsinZoneGroup(int client, char szSteamID[32], char szMapName[128], int zonegroup)
{
	char szQuery[1024];
	//"SELECT cp1, cp2, cp3, cp4, cp5, cp6, cp7, cp8, cp9, cp10, cp11, cp12, cp13, cp14, cp15, cp16, cp17, cp18, cp19, cp20, cp21, cp22, cp23, cp24, cp25, cp26, cp27, cp28, cp29, cp30, cp31, cp32, cp33, cp34, cp35 FROM ck_checkpoints WHERE mapname='%s' AND steamid = '%s' AND zonegroup = %i;";
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackCell(pack, zonegroup);

	Format(szQuery, 1024, sql_selectCheckpointsinZoneGroup, szMapName, szSteamID, zonegroup);
	SQL_TQuery(g_hDb, db_viewCheckpointsinZoneGroupCallback, szQuery, pack, DBPrio_Low);
}

public void db_viewCheckpointsinZoneGroupCallback(Handle owner, Handle hndl, const char[] error, any pack)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_selectCheckpointsCallback): %s", error);
		return;
	}

	ResetPack(pack);
	int client = ReadPackCell(pack);
	int zonegrp = ReadPackCell(pack);
	CloseHandle(pack);

	if (!IsValidClient(client))
		return;

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		g_bCheckpointsFound[zonegrp][client] = true;
		for (int i = 0; i < CPLIMIT; i++)
		{
			g_fCheckpointTimesRecord[zonegrp][client][i] = SQL_FetchFloat(hndl, i);
		}
	}
	else
	{
		g_bCheckpointsFound[zonegrp][client] = false;
	}
}



public void db_UpdateCheckpoints(int client, char szSteamID[32], int zGroup)
{
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackCell(pack, zGroup);
	if (g_bCheckpointsFound[zGroup][client])
	{
		char szQuery[1024];
		Format(szQuery, 1024, sql_updateCheckpoints, g_fCheckpointTimesNew[zGroup][client][0], g_fCheckpointTimesNew[zGroup][client][1], g_fCheckpointTimesNew[zGroup][client][2], g_fCheckpointTimesNew[zGroup][client][3], g_fCheckpointTimesNew[zGroup][client][4], g_fCheckpointTimesNew[zGroup][client][5], g_fCheckpointTimesNew[zGroup][client][6], g_fCheckpointTimesNew[zGroup][client][7], g_fCheckpointTimesNew[zGroup][client][8], g_fCheckpointTimesNew[zGroup][client][9], g_fCheckpointTimesNew[zGroup][client][10], g_fCheckpointTimesNew[zGroup][client][11], g_fCheckpointTimesNew[zGroup][client][12], g_fCheckpointTimesNew[zGroup][client][13], g_fCheckpointTimesNew[zGroup][client][14], g_fCheckpointTimesNew[zGroup][client][15], g_fCheckpointTimesNew[zGroup][client][16], g_fCheckpointTimesNew[zGroup][client][17], g_fCheckpointTimesNew[zGroup][client][18], g_fCheckpointTimesNew[zGroup][client][19], g_fCheckpointTimesNew[zGroup][client][20], g_fCheckpointTimesNew[zGroup][client][21], g_fCheckpointTimesNew[zGroup][client][22], g_fCheckpointTimesNew[zGroup][client][23], g_fCheckpointTimesNew[zGroup][client][24], g_fCheckpointTimesNew[zGroup][client][25], g_fCheckpointTimesNew[zGroup][client][26], g_fCheckpointTimesNew[zGroup][client][27], g_fCheckpointTimesNew[zGroup][client][28], g_fCheckpointTimesNew[zGroup][client][29], g_fCheckpointTimesNew[zGroup][client][30], g_fCheckpointTimesNew[zGroup][client][31], g_fCheckpointTimesNew[zGroup][client][32], g_fCheckpointTimesNew[zGroup][client][33], g_fCheckpointTimesNew[zGroup][client][34], szSteamID, g_szMapName, zGroup);
		SQL_TQuery(g_hDb, SQL_updateCheckpointsCallback, szQuery, pack, DBPrio_Low);
	}
	else
	{
		char szQuery[1024];
		Format(szQuery, 1024, sql_insertCheckpoints, szSteamID, g_szMapName, g_fCheckpointTimesNew[zGroup][client][0], g_fCheckpointTimesNew[zGroup][client][1], g_fCheckpointTimesNew[zGroup][client][2], g_fCheckpointTimesNew[zGroup][client][3], g_fCheckpointTimesNew[zGroup][client][4], g_fCheckpointTimesNew[zGroup][client][5], g_fCheckpointTimesNew[zGroup][client][6], g_fCheckpointTimesNew[zGroup][client][7], g_fCheckpointTimesNew[zGroup][client][8], g_fCheckpointTimesNew[zGroup][client][9], g_fCheckpointTimesNew[zGroup][client][10], g_fCheckpointTimesNew[zGroup][client][11], g_fCheckpointTimesNew[zGroup][client][12], g_fCheckpointTimesNew[zGroup][client][13], g_fCheckpointTimesNew[zGroup][client][14], g_fCheckpointTimesNew[zGroup][client][15], g_fCheckpointTimesNew[zGroup][client][16], g_fCheckpointTimesNew[zGroup][client][17], g_fCheckpointTimesNew[zGroup][client][18], g_fCheckpointTimesNew[zGroup][client][19], g_fCheckpointTimesNew[zGroup][client][20], g_fCheckpointTimesNew[zGroup][client][21], g_fCheckpointTimesNew[zGroup][client][22], g_fCheckpointTimesNew[zGroup][client][23], g_fCheckpointTimesNew[zGroup][client][24], g_fCheckpointTimesNew[zGroup][client][25], g_fCheckpointTimesNew[zGroup][client][26], g_fCheckpointTimesNew[zGroup][client][27], g_fCheckpointTimesNew[zGroup][client][28], g_fCheckpointTimesNew[zGroup][client][29], g_fCheckpointTimesNew[zGroup][client][30], g_fCheckpointTimesNew[zGroup][client][31], g_fCheckpointTimesNew[zGroup][client][32], g_fCheckpointTimesNew[zGroup][client][33], g_fCheckpointTimesNew[zGroup][client][34], zGroup);
		SQL_TQuery(g_hDb, SQL_updateCheckpointsCallback, szQuery, pack, DBPrio_Low);
	}
}

public void SQL_updateCheckpointsCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_updateCheckpointsCallback): %s", error);
		return;
	}
	ResetPack(data);
	int client = ReadPackCell(data);
	int zonegrp = ReadPackCell(data);
	CloseHandle(data);

	db_viewCheckpointsinZoneGroup(client, g_szSteamID[client], g_szMapName, zonegrp);
}

public void db_deleteCheckpoints()
{
	char szQuery[258];
	Format(szQuery, 258, sql_deleteCheckpoints, g_szMapName);
	SQL_TQuery(g_hDb, SQL_deleteCheckpointsCallback, szQuery, 1, DBPrio_Low);
}

public void SQL_deleteCheckpointsCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_deleteCheckpointsCallback): %s", error);
		return;
	}
}