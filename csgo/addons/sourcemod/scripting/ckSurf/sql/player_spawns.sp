public void db_deleteSpawnLocations(int zGrp)
{
	g_bGotSpawnLocation[zGrp] = false;
	char szQuery[128];
	Format(szQuery, 128, sql_deleteSpawnLocations, g_szMapName, zGrp);
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, 1, DBPrio_Low);
}


public void db_updateSpawnLocations(float position[3], float angle[3], int zGrp)
{
	char szQuery[512];
	Format(szQuery, 512, sql_updateSpawnLocations, position[0], position[1], position[2], angle[0], angle[1], angle[2], g_szMapName, zGrp);
	SQL_TQuery(g_hDb, db_editSpawnLocationsCallback, szQuery, zGrp, DBPrio_Low);
}

public void db_insertSpawnLocations(float position[3], float angle[3], int zGrp)
{
	char szQuery[512];
	Format(szQuery, 512, sql_insertSpawnLocations, g_szMapName, position[0], position[1], position[2], angle[0], angle[1], angle[2], zGrp);
	SQL_TQuery(g_hDb, db_editSpawnLocationsCallback, szQuery, zGrp, DBPrio_Low);
}

public void db_editSpawnLocationsCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (db_editSpawnLocationsCallback): %s ", error);
		return;
	}
	db_selectSpawnLocations();
}

public void db_selectSpawnLocations()
{
	for (int i = 0; i < MAXZONEGROUPS; i++)
		g_bGotSpawnLocation[i] = false;

	char szQuery[254];
	Format(szQuery, 254, sql_selectSpawnLocations, g_szMapName);
	SQL_TQuery(g_hDb, db_selectSpawnLocationsCallback, szQuery, 1, DBPrio_Low);
}

public void db_selectSpawnLocationsCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (db_selectSpawnLocationsCallback): %s ", error);
		if (!g_bServerDataLoaded)
			db_ClearLatestRecords();
		return;
	}

	if (SQL_HasResultSet(hndl))
	{
		while (SQL_FetchRow(hndl))
		{
			g_bGotSpawnLocation[SQL_FetchInt(hndl, 7)] = true;
			g_fSpawnLocation[SQL_FetchInt(hndl, 7)][0] = SQL_FetchFloat(hndl, 1);
			g_fSpawnLocation[SQL_FetchInt(hndl, 7)][1] = SQL_FetchFloat(hndl, 2);
			g_fSpawnLocation[SQL_FetchInt(hndl, 7)][2] = SQL_FetchFloat(hndl, 3);
			g_fSpawnAngle[SQL_FetchInt(hndl, 7)][0] = SQL_FetchFloat(hndl, 4);
			g_fSpawnAngle[SQL_FetchInt(hndl, 7)][1] = SQL_FetchFloat(hndl, 5);
			g_fSpawnAngle[SQL_FetchInt(hndl, 7)][2] = SQL_FetchFloat(hndl, 6);
		}
	}
	if (!g_bServerDataLoaded)
		db_ClearLatestRecords();
	return;
}