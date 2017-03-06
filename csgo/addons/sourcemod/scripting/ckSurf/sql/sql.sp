
////////////////////////
//// DATABASE SETUP/////
////////////////////////

public void db_setupDatabase()
{
	////////////////////////////////
	// INIT CONNECTION TO DATABASE//
	////////////////////////////////
	char szError[255];
	g_hDb = SQL_Connect("cksurf", false, szError, 255);

	if (g_hDb == null)
	{
		SetFailState("[Surf Timer] Unable to connect to database (%s)", szError);
		return;
	}

	char szIdent[8];
	SQL_ReadDriver(g_hDb, szIdent, 8);

	if (strcmp(szIdent, "mysql", false) == 0)
	{
		g_DbType = MYSQL;
	}
	else
		if (strcmp(szIdent, "sqlite", false) == 0)
			g_DbType = SQLITE;
		else
		{
			LogError("[Surf Timer] Invalid Database-Type");
			return;
		}

	// If updating from a previous version
	SQL_LockDatabase(g_hDb);
	SQL_FastQuery(g_hDb, "SET NAMES  'utf8'");


	////////////////////////////////
	// CHECK WHICH CHANGES ARE    //
	// TO BE DONE TO THE DATABASE //
	////////////////////////////////
	g_bRenaming = false;
	g_bInTransactionChain = false;

	// If coming from KZTimer or a really old version, rename and edit tables to new format
	if (SQL_FastQuery(g_hDb, "SELECT steamid FROM playerrank LIMIT 1") && !SQL_FastQuery(g_hDb, "SELECT steamid FROM ck_playerrank LIMIT 1"))
	{
		SQL_UnlockDatabase(g_hDb);
		db_renameTables();
		return;
	}
	else // If startring for the first time and tables haven't been created yet.
		if (!SQL_FastQuery(g_hDb, "SELECT steamid FROM playerrank LIMIT 1") && !SQL_FastQuery(g_hDb, "SELECT steamid FROM ck_playerrank LIMIT 1"))
	{
		SQL_UnlockDatabase(g_hDb);
		db_createTables();
		return;
	}


	// 1.17 Command to disable checkpoint messages
	SQL_FastQuery(g_hDb, "ALTER TABLE ck_playeroptions ADD checkpoints INT DEFAULT 1;");


	////////////////////////////
	// 1.18 A bunch of changes //
	// - Zone Groups          //
	// - Zone Names           //
	// - Bonus Tiers          //
	// - Titles               //
	// - More checkpoints     //
	////////////////////////////

	SQL_FastQuery(g_hDb, "ALTER TABLE ck_zones ADD zonegroup INT NOT NULL DEFAULT 0;");
	SQL_FastQuery(g_hDb, "ALTER TABLE ck_zones ADD zonename VARCHAR(128);");
	SQL_FastQuery(g_hDb, "ALTER TABLE ck_playertemp ADD zonegroup INT NOT NULL DEFAULT 0;");
	SQL_FastQuery(g_hDb, sql_createPlayerFlags);

	SQL_FastQuery(g_hDb, "CREATE INDEX maprank ON ck_playertimes (mapname, runtimepro)");
	SQL_FastQuery(g_hDb, "CREATE INDEX bonusrank ON ck_bonus (mapname,runtime,zonegroup)");

	SQL_UnlockDatabase(g_hDb);

	for (int i = 0; i < sizeof(g_failedTransactions); i++)
		g_failedTransactions[i] = 0;

	txn_addExtraCheckpoints();
	return;
}

void txn_addExtraCheckpoints()
{
	// Add extra checkpoints to Checkpoints and add new primary key:
	if (!SQL_FastQuery(g_hDb, "SELECT cp35 FROM ck_checkpoints;"))
	{
		PrintToServer("---------------------------------------------------------------------------");
		disableServerHibernate();
		PrintToServer("[Surf Timer] Started to make changes to database. Updating from 1.17 -> 1.18.");
		PrintToServer("[Surf Timer] WARNING: DO NOT CONNECT TO THE SERVER, OR CHANGE MAP!");
		PrintToServer("[Surf Timer] Adding extra checkpoints... (1 / 6)");

		g_bInTransactionChain = true;
		Transaction h_checkpoint = SQL_CreateTransaction();

		SQL_AddQuery(h_checkpoint, "ALTER TABLE ck_checkpoints RENAME TO ck_checkpoints_temp;");
		SQL_AddQuery(h_checkpoint, sql_createCheckpoints);
		SQL_AddQuery(h_checkpoint, "INSERT INTO ck_checkpoints(steamid, mapname, zonegroup, cp1, cp2, cp3, cp4, cp5, cp6, cp7, cp8, cp9, cp10, cp11, cp12, cp13, cp14, cp15, cp16, cp17, cp18, cp19, cp20) SELECT steamid, mapname, 0, cp1, cp2, cp3, cp4, cp5, cp6, cp7, cp8, cp9, cp10, cp11, cp12, cp13, cp14, cp15, cp16, cp17, cp18, cp19, cp20 FROM ck_checkpoints_temp GROUP BY mapname, steamid;");
		SQL_AddQuery(h_checkpoint, "DROP TABLE ck_checkpoints_temp;");

		SQL_ExecuteTransaction(g_hDb, h_checkpoint, SQLTxn_Success, SQLTxn_TXNFailed, 1);
	}
	else
	{
		PrintToServer("[Surf Timer] No database update needed!");
		return;
	}
}

void txn_addZoneGroups()
{
	// Add zonegroups to ck_bonus and make it a primary key
	if (!SQL_FastQuery(g_hDb, "SELECT zonegroup FROM ck_bonus;"))
	{
		Transaction h_bonus = SQL_CreateTransaction();

		SQL_AddQuery(h_bonus, "ALTER TABLE ck_bonus RENAME TO ck_bonus_temp;");
		SQL_AddQuery(h_bonus, sql_createBonus);
		SQL_AddQuery(h_bonus, sql_createBonusIndex);
		SQL_AddQuery(h_bonus, "INSERT INTO ck_bonus(steamid, name, mapname, runtime) SELECT steamid, name, mapname, runtime FROM ck_bonus_temp;");
		SQL_AddQuery(h_bonus, "DROP TABLE ck_bonus_temp;");

		SQL_ExecuteTransaction(g_hDb, h_bonus, SQLTxn_Success, SQLTxn_TXNFailed, 2);
	}
	else
	{
		PrintToServer("[Surf Timer] Zonegroup changes were already done! Skipping to recreating playertemp!");
		txn_recreatePlayerTemp();
	}
}

void txn_recreatePlayerTemp()
{
	// Recreate playertemp without BonusTimer
	if (SQL_FastQuery(g_hDb, "SELECT BonusTimer FROM ck_playertemp;"))
	{
		// No need to preserve temp data, just drop table
		Transaction h_playertemp = SQL_CreateTransaction();
		SQL_AddQuery(h_playertemp, "DROP TABLE IF EXISTS ck_playertemp");
		SQL_AddQuery(h_playertemp, sql_createPlayertmp);
		SQL_ExecuteTransaction(g_hDb, h_playertemp, SQLTxn_Success, SQLTxn_TXNFailed, 3);
	}
	else
	{
		PrintToServer("[Surf Timer] Playertemp was already recreated! Skipping to bonus tiers");
		txn_addBonusTiers();
	}
}

void txn_addBonusTiers()
{
	// Add bonus tiers
	if (SQL_FastQuery(g_hDb, "ALTER TABLE ck_maptier ADD btier1 INT;"))
	{
		Transaction h_maptiers = SQL_CreateTransaction();
		char sql[258];
		for (int x = 2; x < 11; x++)
		{
			Format(sql, 258, "ALTER TABLE ck_maptier ADD btier%i INT;", x);
			SQL_AddQuery(h_maptiers, sql);
		}
		SQL_ExecuteTransaction(g_hDb, h_maptiers, SQLTxn_Success, SQLTxn_TXNFailed, 4);
	}
	else
	{
		PrintToServer("[Surf Timer] Bonus tiers were already added. Skipping to spawn points");
		txn_addSpawnPoints();
	}
}
void txn_addSpawnPoints()
{
	if (!SQL_FastQuery(g_hDb, "SELECT zonegroup FROM ck_spawnlocations;"))
	{
		Transaction h_spawnPoints = SQL_CreateTransaction();
		SQL_AddQuery(h_spawnPoints, "ALTER TABLE ck_spawnlocations RENAME TO ck_spawnlocations_temp;");
		SQL_AddQuery(h_spawnPoints, sql_createSpawnLocations);
		SQL_AddQuery(h_spawnPoints, "INSERT INTO ck_spawnlocations (mapname, pos_x, pos_y, pos_z, ang_x, ang_y, ang_z) SELECT mapname, pos_x, pos_y, pos_z, ang_x, ang_y, ang_z FROM ck_spawnlocations_temp;");
		SQL_AddQuery(h_spawnPoints, "DROP TABLE ck_spawnlocations_temp");
		SQL_ExecuteTransaction(g_hDb, h_spawnPoints, SQLTxn_Success, SQLTxn_TXNFailed, 5);
	}
	else
	{
		PrintToServer("[Surf Timer] Spawnpoints were already added! Skipping to changes in zones");
		txn_changesToZones();
	}
}

void txn_changesToZones()
{
	Transaction h_changesToZones = SQL_CreateTransaction();
	// Set right zonegroups
	SQL_AddQuery(h_changesToZones, "UPDATE ck_zones SET zonegroup = 1 WHERE zonetype = 3 OR zonetype = 4;");
	SQL_AddQuery(h_changesToZones, "UPDATE ck_zones SET zonetypeid = 0 WHERE zonetype = 3 OR zonetype = 4;");

	// Remove ZoneTypes 3 & 4
	SQL_AddQuery(h_changesToZones, "UPDATE ck_zones SET zonetype = 1 WHERE zonetype = 3;");
	SQL_AddQuery(h_changesToZones, "UPDATE ck_zones SET zonetype = 2 WHERE zonetype = 4;");

	// Adjust bigger zonetype numbers to match the changes
	SQL_AddQuery(h_changesToZones, "UPDATE ck_zones SET zonetype = zonetype-2 WHERE zonetype > 4;");
	SQL_ExecuteTransaction(g_hDb, h_changesToZones, SQLTxn_Success, SQLTxn_TXNFailed, 6);
}


public void SQLTxn_Success(Handle db, any data, int numQueries, Handle[] results, any[] queryData)
{
	switch (data)
	{
		case 1:
		{
			PrintToServer("[Surf Timer] Checkpoints added succesfully! Next up: adding zonegroups to ck_bonus (2 / 6)");
			txn_addZoneGroups();
		}
		case 2:
		{
			PrintToServer("[Surf Timer] Bonus zonegroups succesfully added! Next up: recreating playertemp (3 / 6)");
			txn_recreatePlayerTemp();
		}
		case 3:
		{
			PrintToServer("[Surf Timer] Playertemp succesfully recreated! Next up: adding bonus tiers (4 / 6)");
			txn_addBonusTiers();
		}
		case 4:
		{
			PrintToServer("[Surf Timer] Bonus tiers added succesfully! Next up: adding spawn points (5 / 6)");
			txn_addSpawnPoints();
		}
		case 5:
		{
			PrintToServer("[Surf Timer] Spawnpoints added succesfully! Next up: making changes to zones, to make them match the new database (6 / 6)");
			txn_changesToZones();
		}
		case 6:
		{
			g_bInTransactionChain = false;

			revertServerHibernateSettings();
			PrintToServer("[Surf Timer] All changes succesfully done! Changing map!");
			ForceChangeLevel(g_szMapName, "[Surf Timer] Changing level after changes to the database have been done");
		}
	}
}

public void SQLTxn_TXNFailed(Handle db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	if (g_failedTransactions[data] == 0)
	{
		switch (data)
		{
			case 1:
			{
				PrintToServer("[Surf Timer] Error in adding extra checkpoints! Retrying.. (%s)", error);
				txn_addExtraCheckpoints();
			}
			case 2:
			{
				PrintToServer("[Surf Timer] Error in addin zonegroups! Retrying... (%s)", error);
				txn_addZoneGroups();
			}
			case 3:
			{
				PrintToServer("[Surf Timer] Error in recreating playertemp! Retrying... (%s)", error);
				txn_recreatePlayerTemp();
			}
			case 4:
			{
				PrintToServer("[Surf Timer] Error in adding bonus tiers! Retrying... (%s)", error);
				txn_addBonusTiers();
			}
			case 5:
			{
				PrintToServer("[Surf Timer] Error in adding spawn points! Retrying... (%s)", error);
				txn_addSpawnPoints();
			}
			case 6:
			{
				PrintToServer("[Surf Timer] Error in making changes to zones! Retrying... (%s)", error);
				txn_changesToZones();
			}
		}
	}
	else
	{
		revertServerHibernateSettings();
		PrintToServer("[Surf Timer]: Couldn't make changes into the database. Transaction: %i, error: %s", data, error);
		PrintToServer("[Surf Timer]: Revert back to database backup.");
		LogError("[Surf Timer]: Couldn't make changes into the database. Transaction: %i, error: %s", data, error);
		return;
	}
	g_failedTransactions[data]++;
}


public void db_createTables()
{
	Transaction createTableTnx = SQL_CreateTransaction();

	SQL_AddQuery(createTableTnx, sql_createPlayertmp);
	SQL_AddQuery(createTableTnx, sql_createPlayertimes);
	SQL_AddQuery(createTableTnx, sql_createPlayertimesIndex);
	SQL_AddQuery(createTableTnx, sql_createPlayerRank);
	SQL_AddQuery(createTableTnx, sql_createChallenges);
	SQL_AddQuery(createTableTnx, sql_createPlayerOptions);
	SQL_AddQuery(createTableTnx, sql_createLatestRecords);
	SQL_AddQuery(createTableTnx, sql_createBonus);
	SQL_AddQuery(createTableTnx, sql_createBonusIndex);
	SQL_AddQuery(createTableTnx, sql_createCheckpoints);
	SQL_AddQuery(createTableTnx, sql_createZones);
	SQL_AddQuery(createTableTnx, sql_createMapTier);
	SQL_AddQuery(createTableTnx, sql_createSpawnLocations);
	SQL_AddQuery(createTableTnx, sql_createPlayerFlags);
	SQL_AddQuery(createTableTnx, sql_createStageRecordsTable);

	SQL_ExecuteTransaction(g_hDb, createTableTnx, SQLTxn_CreateDatabaseSuccess, SQLTxn_CreateDatabaseFailed);

}

public void SQLTxn_CreateDatabaseSuccess(Handle db, any data, int numQueries, Handle[] results, any[] queryData)
{
	PrintToServer("[Surf Timer] Database tables succesfully created!");
}
public void SQLTxn_CreateDatabaseFailed(Handle db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	SetFailState("[Surf Timer] Database tables could not be created! Error: %s", error);
}


public void db_renameTables()
{
	disableServerHibernate();

	g_bRenaming = true;
	Transaction hndl = SQL_CreateTransaction();

	SQL_AddQuery(hndl, sql_createSpawnLocations);

	if (g_DbType == MYSQL)
	{
		// Remove unused columns, if coming from KZTimer
		SQL_AddQuery(hndl, "ALTER TABLE challenges DROP COLUMN cp_allowed");
		SQL_AddQuery(hndl, "ALTER TABLE latestrecords DROP COLUMN teleports");
		SQL_AddQuery(hndl, "ALTER TABLE playeroptions2 DROP COLUMN colorchat");
		SQL_AddQuery(hndl, "ALTER TABLE playeroptions2 DROP COLUMN Surfersmenu_sounds");
		SQL_AddQuery(hndl, "ALTER TABLE playeroptions2 DROP COLUMN strafesync");
		SQL_AddQuery(hndl, "ALTER TABLE playeroptions2 DROP COLUMN cpmessage");
		SQL_AddQuery(hndl, "ALTER TABLE playeroptions2 DROP COLUMN adv_menu");
		SQL_AddQuery(hndl, "ALTER TABLE playeroptions2 DROP COLUMN jumppenalty");
		SQL_AddQuery(hndl, "ALTER TABLE playerrank DROP COLUMN finishedmapstp");
		SQL_AddQuery(hndl, "ALTER TABLE playertimes DROP COLUMN teleports");
		SQL_AddQuery(hndl, "ALTER TABLE playertimes DROP COLUMN runtime");
		SQL_AddQuery(hndl, "ALTER TABLE playertimes DROP COLUMN teleports_pro");
		SQL_AddQuery(hndl, "ALTER TABLE playertmp DROP COLUMN teleports");
		SQL_AddQuery(hndl, "ALTER TABLE playertmp DROP COLUMN checkpoints");
		SQL_AddQuery(hndl, "ALTER TABLE LatestRecords DROP COLUMN teleports");

		SQL_AddQuery(hndl, "ALTER TABLE playeroptions2 RENAME TO ck_playeroptions;");
		SQL_AddQuery(hndl, "ALTER TABLE playertimes RENAME TO ck_playertimes;");
		SQL_AddQuery(hndl, "ALTER TABLE challenges RENAME TO ck_challenges;");
		SQL_AddQuery(hndl, "ALTER TABLE playerrank RENAME TO ck_playerrank;");

	}
	else if (g_DbType == SQLITE)
	{
		// player options
		SQL_AddQuery(hndl, sql_createPlayerOptions);
		SQL_AddQuery(hndl, "INSERT INTO ck_playeroptions(steamid, speedmeter, quake_sounds, shownames, goto, showtime, hideplayers, showspecs, new1, new2, new3) SELECT steamid, speedmeter, quake_sounds, shownames, goto, showtime, hideplayers, showspecs, new1, new2, new3 FROM playeroptions2;");
		SQL_AddQuery(hndl, "DROP TABLE IF EXISTS playeroptions2");

		// player times
		SQL_AddQuery(hndl, sql_createPlayertimes);
		SQL_AddQuery(hndl, sql_createPlayertimesIndex);
		SQL_AddQuery(hndl, "INSERT INTO ck_playertimes(steamid, mapname, name, runtimepro) SELECT steamid, mapname, name, runtimepro FROM playertimes;");
		SQL_AddQuery(hndl, "DROP TABLE IF EXISTS playertimes");

		// challenges
		SQL_AddQuery(hndl, sql_createChallenges);
		SQL_AddQuery(hndl, "INSERT INTO ck_challenges(steamid, steamid2, bet, map, date) SELECT steamid, steamid2, bet, map, date FROM challenges;");
		SQL_AddQuery(hndl, "DROP TABLE IF EXISTS challenges");

		// playerrank
		SQL_AddQuery(hndl, sql_createPlayerRank);
		SQL_AddQuery(hndl, "INSERT INTO ck_playerrank(steamid, name, country, points, winratio, pointsratio, finishedmaps, multiplier, finishedmapspro, lastseen) SELECT steamid, name, country, points, winratio, pointsratio, finishedmaps, multiplier, finishedmapspro, lastseen FROM playerrank;");
		SQL_AddQuery(hndl, "DROP TABLE IF EXISTS playerrank");
	}

	SQL_AddQuery(hndl, "ALTER TABLE bonus RENAME TO ck_bonus;");
	SQL_AddQuery(hndl, "ALTER TABLE checkpoints RENAME TO ck_checkpoints;");
	SQL_AddQuery(hndl, "ALTER TABLE maptier RENAME TO ck_maptier;");
	SQL_AddQuery(hndl, "ALTER TABLE zones RENAME TO ck_zones;");

	SQL_AddQuery(hndl, sql_createPlayertmp);
	SQL_AddQuery(hndl, sql_createLatestRecords);

	// Drop useless tables from KZTimer
	SQL_AddQuery(hndl, "DROP TABLE IF EXISTS playertmp");
	SQL_AddQuery(hndl, "DROP TABLE IF EXISTS LatestRecords");
	SQL_AddQuery(hndl, "DROP TABLE IF EXISTS ck_mapbuttons");
	SQL_AddQuery(hndl, "DROP TABLE IF EXISTS playerjumpstats3");

	SQL_ExecuteTransaction(g_hDb, hndl, SQLTxn_RenameSuccess, SQLTxn_RenameFailed);
}

public void SQLTxn_RenameSuccess(Handle db, any data, int numQueries, Handle[] results, any[] queryData)
{
	g_bRenaming = false;
	revertServerHibernateSettings();
	PrintToChatAll("[%cSurf Timer%c] Database changes done succesfully, reloading the map...");
	ForceChangeLevel(g_szMapName, "Database Renaming Done. Restarting Map.");
}

public void SQLTxn_RenameFailed(Handle db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	g_bRenaming = false;
	revertServerHibernateSettings();
	SetFailState("[Surf Timer] Database changes failed! (Renaming) Error: %s", error);
}


///////////////////////
//// MISC /////////////
///////////////////////


public void db_insertLastPosition(int client, char szMapName[128], int stage, int zgroup)
{
	if (GetConVarBool(g_hcvarRestore) && !g_bRoundEnd && (StrContains(g_szSteamID[client], "STEAM_") != -1) && g_bTimeractivated[client])
	{
		Handle pack = CreateDataPack();
		WritePackCell(pack, client);
		WritePackString(pack, szMapName);
		WritePackString(pack, g_szSteamID[client]);
		WritePackCell(pack, stage);
		WritePackCell(pack, zgroup);
		char szQuery[512];
		Format(szQuery, 512, "SELECT * FROM ck_playertemp WHERE steamid = '%s'", g_szSteamID[client]);
		SQL_TQuery(g_hDb, db_insertLastPositionCallback, szQuery, pack, DBPrio_Low);
	}
}

public void db_insertLastPositionCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (db_insertLastPositionCallback): %s", error);
		return;
	}

	char szQuery[1024];
	char szMapName[128];
	char szSteamID[32];

	ResetPack(data);
	int client = ReadPackCell(data);
	ReadPackString(data, szMapName, 128);
	ReadPackString(data, szSteamID, 32);
	int stage = ReadPackCell(data);
	int zgroup = ReadPackCell(data);
	CloseHandle(data);

	if (1 <= client <= MaxClients)
	{
		if (!g_bTimeractivated[client])
			g_fPlayerLastTime[client] = -1.0;
		int tickrate = g_Server_Tickrate * 5 * 11;
		if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		{
			Format(szQuery, 1024, sql_updatePlayerTmp, g_fPlayerCordsLastPosition[client][0], g_fPlayerCordsLastPosition[client][1], g_fPlayerCordsLastPosition[client][2], g_fPlayerAnglesLastPosition[client][0], g_fPlayerAnglesLastPosition[client][1], g_fPlayerAnglesLastPosition[client][2], g_fPlayerLastTime[client], szMapName, tickrate, stage, zgroup, szSteamID);
			SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, DBPrio_Low);
		}
		else
		{
			Format(szQuery, 1024, sql_insertPlayerTmp, g_fPlayerCordsLastPosition[client][0], g_fPlayerCordsLastPosition[client][1], g_fPlayerCordsLastPosition[client][2], g_fPlayerAnglesLastPosition[client][0], g_fPlayerAnglesLastPosition[client][1], g_fPlayerAnglesLastPosition[client][2], g_fPlayerLastTime[client], szSteamID, szMapName, tickrate, stage, zgroup);
			SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, DBPrio_Low);
		}
	}
}

public void db_deletePlayerTmps()
{
	char szQuery[64];
	Format(szQuery, 64, "delete FROM ck_playertemp");
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, DBPrio_Low);
}

public void db_ViewLatestRecords(int client)
{
	SQL_TQuery(g_hDb, sql_selectLatestRecordsCallback, sql_selectLatestRecords, client, DBPrio_Low);
}

public void sql_selectLatestRecordsCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_selectLatestRecordsCallback): %s", error);
		return;
	}

	char szName[64];
	char szMapName[64];
	char szDate[64];
	char szTime[32];
	float ftime;
	PrintToConsole(data, "----------------------------------------------------------------------------------------------------");
	PrintToConsole(data, "Last map records:");
	if (SQL_HasResultSet(hndl))
	{
		int i = 1;
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, szName, 64);
			ftime = SQL_FetchFloat(hndl, 1);
			FormatTimeFloat(data, ftime, 3, szTime, sizeof(szTime));
			SQL_FetchString(hndl, 2, szMapName, 64);
			SQL_FetchString(hndl, 3, szDate, 64);
			PrintToConsole(data, "%s: %s on %s - Time %s", szDate, szName, szMapName, szTime);
			i++;
		}
		if (i == 1)
			PrintToConsole(data, "No records found.");
	}
	else
		PrintToConsole(data, "No records found.");
	PrintToConsole(data, "----------------------------------------------------------------------------------------------------");
	PrintToChat(data, "[%cSurf Timer%c] See console for output!", MOSSGREEN, WHITE);
}


public void db_InsertLatestRecords(char szSteamID[32], char szName[32], float FinalTime)
{
	char szQuery[512];
	Format(szQuery, 512, sql_insertLatestRecords, szSteamID, szName, FinalTime, g_szMapName);
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, DBPrio_Low);
}

public void GetDBName(int client, char szSteamId[32])
{
	char szQuery[512];
	Format(szQuery, 512, sql_selectRankedPlayer, szSteamId);
	SQL_TQuery(g_hDb, GetDBNameCallback, szQuery, client, DBPrio_Low);
}

public void GetDBNameCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (GetDBNameCallback): %s", error);
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 1, g_szProfileName[data], MAX_NAME_LENGTH);
		db_viewPlayerAll(data, g_szProfileName[data]);
	}
}

public void db_CalcAvgRunTime()
{
	char szQuery[256];
	Format(szQuery, 256, sql_selectAllMapTimesinMap, g_szMapName);
	SQL_TQuery(g_hDb, SQL_db_CalcAvgRunTimeCallback, szQuery, DBPrio_Low);
}

public void SQL_db_CalcAvgRunTimeCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_db_CalcAvgRunTimeCallback): %s", error);

		if (!g_bServerDataLoaded && g_bhasBonus)
			db_CalcAvgRunTimeBonus();
		else if (!g_bServerDataLoaded)
			db_CalculatePlayerCount();

		return;
	}

	g_favg_maptime = 0.0;
	if (SQL_HasResultSet(hndl))
	{
		int rowcount = SQL_GetRowCount(hndl);
		int i, protimes;
		float ProTime;
		while (SQL_FetchRow(hndl))
		{
			float pro = SQL_FetchFloat(hndl, 0);
			if (pro > 0.0)
			{
				ProTime += pro;
				protimes++;
			}
			i++;
			if (rowcount == i)
			{
				g_favg_maptime = ProTime / protimes;
			}
		}
	}

	if (g_bhasBonus)
		db_CalcAvgRunTimeBonus();
	else
		db_CalculatePlayerCount();
}
public void db_CalcAvgRunTimeBonus()
{
	char szQuery[256];
	Format(szQuery, 256, sql_selectAllBonusTimesinMap, g_szMapName);
	SQL_TQuery(g_hDb, SQL_db_CalcAvgRunBonusTimeCallback, szQuery, 1, DBPrio_Low);
}

public void SQL_db_CalcAvgRunBonusTimeCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_db_CalcAvgRunTimeCallback): %s", error);
		if (!g_bServerDataLoaded)
			db_CalculatePlayerCount();
		return;
	}

	for (int i = 1; i < MAXZONEGROUPS; i++)
		g_fAvg_BonusTime[i] = 0.0;

	if (SQL_HasResultSet(hndl))
	{
		int zonegroup, runtimes[MAXZONEGROUPS];
		float runtime[MAXZONEGROUPS], time;
		while (SQL_FetchRow(hndl))
		{
			zonegroup = SQL_FetchInt(hndl, 0);
			time = SQL_FetchFloat(hndl, 1);
			if (time > 0.0)
			{
				runtime[zonegroup] += time;
				runtimes[zonegroup]++;
			}
		}

		for (int i = 1; i < MAXZONEGROUPS; i++)
			g_fAvg_BonusTime[i] = runtime[i] / runtimes[i];
	}

	if (!g_bServerDataLoaded)
		db_CalculatePlayerCount();

	return;
}

public void db_GetDynamicTimelimit()
{
	if (!GetConVarBool(g_hDynamicTimelimit))
	{
		if (!g_bServerDataLoaded)
			loadAllClientSettings();
		return;
	}
	char szQuery[256];
	Format(szQuery, 256, sql_selectAllMapTimesinMap, g_szMapName);
	SQL_TQuery(g_hDb, SQL_db_GetDynamicTimelimitCallback, szQuery, DBPrio_Low);
}


public void SQL_db_GetDynamicTimelimitCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_db_GetDynamicTimelimitCallback): %s", error);
		loadAllClientSettings();
		return;
	}

	if (SQL_HasResultSet(hndl))
	{
		int maptimes = 0;
		float total = 0.0, time = 0.0;
		while (SQL_FetchRow(hndl))
		{
			time = SQL_FetchFloat(hndl, 0);
			if (time > 0.0)
			{
				total += time;
				maptimes++;
			}
		}
		//requires min. 5 map times
		if (maptimes > 5)
		{
			int scale_factor = 3;
			int avg = RoundToNearest((total) / 60.0 / float(maptimes));

			//scale factor
			if (avg <= 10)
				scale_factor = 5;
			if (avg <= 5)
				scale_factor = 8;
			if (avg <= 3)
				scale_factor = 10;
			if (avg <= 2)
				scale_factor = 12;
			if (avg <= 1)
				scale_factor = 14;

			avg = avg * scale_factor;

			//timelimit: min 20min, max 120min
			if (avg < 20)
				avg = 20;
			if (avg > 120)
				avg = 120;

			//set timelimit
			char szTimelimit[32];
			Format(szTimelimit, 32, "mp_timelimit %i;mp_roundtime %i", avg, avg);
			ServerCommand(szTimelimit);
			ServerCommand("mp_restartgame 1");
		}
		else
			ServerCommand("mp_timelimit 50");
	}

	if (!g_bServerDataLoaded)
		loadAllClientSettings();

	return;
}


public void db_CalculatePlayerCount()
{
	char szQuery[255];
	Format(szQuery, 255, sql_CountRankedPlayers);
	SQL_TQuery(g_hDb, sql_CountRankedPlayersCallback, szQuery, DBPrio_Low);
}

public void db_CalculatePlayersCountGreater0()
{
	char szQuery[255];
	Format(szQuery, 255, sql_CountRankedPlayers2);
	SQL_TQuery(g_hDb, sql_CountRankedPlayers2Callback, szQuery, DBPrio_Low);
}



public void sql_CountRankedPlayersCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_CountRankedPlayersCallback): %s", error);
		db_CalculatePlayersCountGreater0();
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		g_pr_AllPlayers = SQL_FetchInt(hndl, 0);
	}
	else
		g_pr_AllPlayers = 1;

	//get amount of players with actual player points
	db_CalculatePlayersCountGreater0();
	return;
}

public void sql_CountRankedPlayers2Callback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_CountRankedPlayers2Callback): %s", error);
		if (!g_bServerDataLoaded)
			db_selectSpawnLocations();
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		g_pr_RankedPlayers = SQL_FetchInt(hndl, 0);
	}
	else
		g_pr_RankedPlayers = 0;

	if (!g_bServerDataLoaded)
		db_selectSpawnLocations();

	return;
}


public void db_ClearLatestRecords()
{
	if (g_DbType == MYSQL)
		SQL_TQuery(g_hDb, SQL_CheckCallback, "DELETE FROM ck_latestrecords WHERE date < NOW() - INTERVAL 1 WEEK", DBPrio_Low);
	else
		SQL_TQuery(g_hDb, SQL_CheckCallback, "DELETE FROM ck_latestrecords WHERE date <= date('now','-7 day')", DBPrio_Low);

	if (!g_bServerDataLoaded)
		db_GetDynamicTimelimit();
}

public void db_viewUnfinishedMaps(int client, char szSteamId[32])
{
	if (IsValidClient(client))
	{
		PrintToChat(client, "%t", "ConsoleOutput", LIMEGREEN, WHITE);
		ProfileMenu(client, -1);
	}
	else
		return;

	char szQuery[720];
	// Gets all players unfinished maps and bonuses from the database
	Format(szQuery, 720, "SELECT mapname, zonegroup, zonename FROM ck_zones a WHERE (zonetype = 1 OR zonetype = 5) AND (SELECT runtimepro FROM ck_playertimes b WHERE b.mapname = a.mapname AND a.zonegroup = 0 AND steamid = '%s' UNION SELECT runtime FROM ck_bonus c WHERE c.mapname = a.mapname AND c.zonegroup = a.zonegroup AND steamid = '%s') IS NULL GROUP BY mapname, zonegroup ORDER BY mapname, zonegroup ASC;", szSteamId, szSteamId);
	SQL_TQuery(g_hDb, db_viewUnfinishedMapsCallback, szQuery, client, DBPrio_Low);
}

public void db_viewUnfinishedMapsCallback(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (db_viewUnfinishedMapsCallback): %s", error);
		return;
	}

	if (SQL_HasResultSet(hndl))
	{
		char szMap[128], szMap2[128], tmpMap[128], consoleString[1024], unfinishedBonusBuffer[772], zName[128];
		bool mapUnfinished, bonusUnfinished;
		int zGrp, count, mapCount, bonusCount, mapListSize = GetArraySize(g_MapList), digits;
		float time = 0.5;
		while (SQL_FetchRow(hndl))
		{
			// Get the map and check that it is in the mapcycle
			SQL_FetchString(hndl, 0, szMap, 128);
			for (int i = 0; i < mapListSize; i++)
			{
				GetArrayString(g_MapList, i, szMap2, 128);
				if (StrEqual(szMap, szMap2, false))
				{
					// Map is in the mapcycle, and is unfinished

					// Initialize the name
					if (!tmpMap[0])
						strcopy(tmpMap, 128, szMap);

					// Check if the map changed, if so announce to client's console
					if (!StrEqual(szMap, tmpMap, false))
					{
						if (count < 10)
							digits = 1;
						else
							if (count < 100)
								digits = 2;
							else
								digits = 3;

						if (strlen(tmpMap) < (13-digits)) // <- 11
							Format(tmpMap, 128, "%s:\t\t\t\t", tmpMap);
						else
							if ((12-digits) < strlen(tmpMap) < (21-digits)) // 12 - 19
								Format(tmpMap, 128, "%s:\t\t\t", tmpMap);
							else
								if ((20-digits) < strlen(tmpMap) < (28-digits)) // 20 - 25
									Format(tmpMap, 128, "%s:\t\t", tmpMap);
								else
									Format(tmpMap, 128, "%s:\t", tmpMap);

						count++;
						if (!mapUnfinished) // Only bonus is unfinished
							Format(consoleString, 1024, "%i. %s\t\t|  %s", count, tmpMap, unfinishedBonusBuffer);
						else
							if (!bonusUnfinished) // Only map is unfinished
								Format(consoleString, 1024, "%i. %sMap unfinished\t|", count, tmpMap);
							else // Both unfinished
								Format(consoleString, 1024, "%i. %sMap unfinished\t|  %s", count, tmpMap, unfinishedBonusBuffer);

						// Throttle messages to not cause errors on huge mapcycles
						time = time + 0.1;
						Handle pack = CreateDataPack();
						WritePackCell(pack, client);
						WritePackString(pack, consoleString);
						CreateTimer(time, PrintUnfinishedLine, pack);

						mapUnfinished = false;
						bonusUnfinished = false;
						consoleString[0] = '\0';
						unfinishedBonusBuffer[0] = '\0';
						strcopy(tmpMap, 128, szMap);
					}

					zGrp = SQL_FetchInt(hndl, 1);
					if (zGrp < 1)
					{
						mapUnfinished = true;
						mapCount++;
					}
					else
					{
						SQL_FetchString(hndl, 2, zName, 128);

						if (!zName[0])
							Format(zName, 128, "BONUS %i", zGrp);

						if (bonusUnfinished)
							Format(unfinishedBonusBuffer, 772, "%s, %s", unfinishedBonusBuffer, zName);
						else
						{
							bonusUnfinished = true;
							Format(unfinishedBonusBuffer, 772, "Bonus: %s", zName);
						}
						bonusCount++;
					}
					break;
				}
			}
		}
		if (IsValidClient(client))
		{
			PrintToConsole(client, " ");
			PrintToConsole(client, "------- User Stats -------");
			PrintToConsole(client, "%i unfinished maps of total %i maps", mapCount, g_pr_MapCount);
			PrintToConsole(client, "%i unfinished bonuses", bonusCount);
			PrintToConsole(client, "SteamID: %s", g_szProfileSteamId[client]);
			PrintToConsole(client, "--------------------------");
			PrintToConsole(client, " ");
			PrintToConsole(client, "------------------------------ Map Details -----------------------------");
		}
	}
	return;
}
public Action PrintUnfinishedLine(Handle timer, any pack)
{
	ResetPack(pack);
	int client = ReadPackCell(pack);
	char teksti[1024];
	ReadPackString(pack, teksti, 1024);
	CloseHandle(pack);
	PrintToConsole(client, teksti);

}

/*
void PrintUnfinishedLine(Handle pack)
{
	ResetPack(pack);
	int client = ReadPackCell(pack);
	char teksti[1024];
	ReadPackString(pack, teksti, 1024);
	CloseHandle(pack);
	PrintToConsole(client, teksti);
}
*/
public void db_viewPlayerProfile1(int client, char szPlayerName[MAX_NAME_LENGTH])
{
	char szQuery[512];
	char szName[MAX_NAME_LENGTH * 2 + 1];
	SQL_EscapeString(g_hDb, szPlayerName, szName, MAX_NAME_LENGTH * 2 + 1);
	Format(szQuery, 512, sql_selectPlayerRankAll2, szName);
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, szPlayerName);
	SQL_TQuery(g_hDb, SQL_ViewPlayerProfile1Callback, szQuery, pack, DBPrio_Low);
}

public void SQL_ViewPlayerProfile1Callback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_ViewPlayerProfile1Callback): %s", error);
		return;
	}
	char szPlayerName[MAX_NAME_LENGTH];

	ResetPack(data);
	int client = ReadPackCell(data);
	ReadPackString(data, szPlayerName, MAX_NAME_LENGTH);
	CloseHandle(data);

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 1, g_szProfileSteamId[client], 32);
		db_viewPlayerRank(client, g_szProfileSteamId[client]);
	}
	else
	{
		char szQuery[512];
		char szName[MAX_NAME_LENGTH * 2 + 1];
		SQL_EscapeString(g_hDb, szPlayerName, szName, MAX_NAME_LENGTH * 2 + 1);
		Format(szQuery, 512, sql_selectPlayerRankAll, PERCENT, szName, PERCENT);
		SQL_TQuery(g_hDb, SQL_ViewPlayerProfile2Callback, szQuery, client, DBPrio_Low);
	}
}


public void sql_selectPlayerNameCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_selectPlayerNameCallback): %s", error);
		return;
	}

	ResetPack(data);
	int clientid = ReadPackCell(data);
	int client = ReadPackCell(data);
	CloseHandle(data);

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, g_pr_szName[clientid], 64);
		g_bProfileRecalc[clientid] = true;
		if (IsValidClient(client))
			PrintToConsole(client, "Profile refreshed (%s).", g_pr_szSteamID[clientid]);
	}
	else
		if (IsValidClient(client))
			PrintToConsole(client, "SteamID %s not found.", g_pr_szSteamID[clientid]);
}

//
// 0. Admins counting players points starts here
//
public void RefreshPlayerRankTable(int max)
{
	g_pr_Recalc_ClientID = 1;
	g_pr_RankingRecalc_InProgress = true;
	char szQuery[255];

	//SELECT steamid, name from ck_playerrank where points > 0 ORDER BY points DESC";
	Format(szQuery, 255, sql_selectRankedPlayers);
	SQL_TQuery(g_hDb, sql_selectRankedPlayersCallback, szQuery, max, DBPrio_Low);
}

public void sql_selectRankedPlayersCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_selectRankedPlayersCallback): %s", error);
		return;
	}

	if (SQL_HasResultSet(hndl))
	{
		int i = 66;
		int x;
		g_pr_TableRowCount = SQL_GetRowCount(hndl);
		if (g_pr_TableRowCount == 0)
		{
			for (int c = 1; c <= MaxClients; c++)
				if (1 <= c <= MaxClients && IsValidEntity(c) && IsValidClient(c))
				{
					if (g_bManualRecalc)
						PrintToChat(c, "%t", "PrUpdateFinished", MOSSGREEN, WHITE, LIMEGREEN);
				}
			g_bManualRecalc = false;
			g_pr_RankingRecalc_InProgress = false;

			if (IsValidClient(g_pr_Recalc_AdminID))
			{
				PrintToConsole(g_pr_Recalc_AdminID, ">> Recalculation finished");
				CreateTimer(0.1, RefreshAdminMenu, g_pr_Recalc_AdminID, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		if (MAX_PR_PLAYERS != data && g_pr_TableRowCount > data)
			x = 66 + data;
		else
			x = 66 + g_pr_TableRowCount;

		if (g_pr_TableRowCount > MAX_PR_PLAYERS)
			g_pr_TableRowCount = MAX_PR_PLAYERS;

		if (x > MAX_PR_PLAYERS)
			x = MAX_PR_PLAYERS - 1;
		if (IsValidClient(g_pr_Recalc_AdminID) && g_bManualRecalc)
		{
			int max = MAX_PR_PLAYERS - 66;
			PrintToConsole(g_pr_Recalc_AdminID, " \n>> Recalculation started! (Only Top %i because of performance reasons)", max);
		}
		while (SQL_FetchRow(hndl))
		{
			if (i <= x)
			{
				g_pr_points[i] = 0;
				SQL_FetchString(hndl, 0, g_pr_szSteamID[i], 32);
				SQL_FetchString(hndl, 1, g_pr_szName[i], 64);

				g_bProfileRecalc[i] = true;
				i++;
			}
			if (i == x)
			{
				CalculatePlayerRank(66);
			}
		}
	}
	else
		PrintToConsole(g_pr_Recalc_AdminID, " \n>> No valid players found!");
}

public void db_Cleanup()
{
	char szQuery[255];

	//tmps
	Format(szQuery, 255, "DELETE FROM ck_playertemp where mapname != '%s'", g_szMapName);
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery);

	//times
	SQL_TQuery(g_hDb, SQL_CheckCallback, "DELETE FROM ck_playertimes where runtimepro = -1.0");
}

public void db_resetMapRecords(int client, char szMapName[128])
{
	char szQuery[255];
	Format(szQuery, 255, sql_resetMapRecords, szMapName);
	SQL_TQuery(g_hDb, SQL_CheckCallback2, szQuery, DBPrio_Low);
	PrintToConsole(client, "player times on %s cleared.", szMapName);
	if (StrEqual(szMapName, g_szMapName))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				Format(g_szPersonalRecord[i], 64, "NONE");
				g_fPersonalRecord[i] = 0.0;
				g_MapRank[i] = 99999;
			}
		}
	}
}

public void SQL_InsertPlayerCallBack(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_InsertPlayerCallBack): %s", error);
		return;
	}

	if (IsClientInGame(data))
		db_UpdateLastSeen(data);
}


public void db_UpdateLastSeen(int client)
{
	if ((StrContains(g_szSteamID[client], "STEAM_") != -1) && !IsFakeClient(client))
	{
		char szQuery[512];
		if (g_DbType == MYSQL)
			Format(szQuery, 512, sql_UpdateLastSeenMySQL, g_szSteamID[client]);
		else
			if (g_DbType == SQLITE)
			Format(szQuery, 512, sql_UpdateLastSeenSQLite, g_szSteamID[client]);
		SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, DBPrio_Low);
	}
}


/////////////////////////////
///// DEFAULT CALLBACKS /////
/////////////////////////////

public void SQL_CheckCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_CheckCallback): %s", error);
		return;
	}
}


public void SQL_CheckCallback2(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_CheckCallback2): %s", error);
		return;
	}

	db_viewMapProRankCount();
	db_GetMapRecord_Pro();
}

public void SQL_CheckCallback3(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_CheckCallback3): %s", error);
		return;
	}

	char steamid[128];

	ResetPack(data);
	int client = ReadPackCell(data);
	ReadPackString(data, steamid, 128);
	CloseHandle(data);

	RecalcPlayerRank(client, steamid);
	db_viewMapProRankCount();
	db_GetMapRecord_Pro();
}

public void SQL_CheckCallback4(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_CheckCallback4): %s", error);
		return;
	}
	char steamid[128];

	ResetPack(data);
	int client = ReadPackCell(data);
	ReadPackString(data, steamid, 128);
	CloseHandle(data);

	RecalcPlayerRank(client, steamid);
}
