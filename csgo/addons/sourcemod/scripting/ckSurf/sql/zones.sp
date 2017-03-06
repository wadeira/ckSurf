////////////////////////////
//// SQL Zones /////////////
////////////////////////////

public void db_setZoneNames(int client, char szName[128])
{
	char szQuery[512], szEscapedName[128 * 2 + 1];
	SQL_EscapeString(g_hDb, szName, szEscapedName, 128 * 2 + 1);
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackCell(pack, g_CurrentSelectedZoneGroup[client]);
	WritePackString(pack, szEscapedName);
	// UPDATE ck_zones SET zonename = '%s' WHERE mapname = '%s' AND zonegroup = '%i';
	Format(szQuery, 512, sql_setZoneNames, szEscapedName, g_szMapName, g_CurrentSelectedZoneGroup[client]);
	SQL_TQuery(g_hDb, sql_setZoneNamesCallback, szQuery, pack, DBPrio_Low);
}

public void sql_setZoneNamesCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_setZoneNamesCallback): %s", error);
		CloseHandle(data);
		return;
	}

	char szName[64];
	ResetPack(data);
	int client = ReadPackCell(data);
	int zonegrp = ReadPackCell(data);
	ReadPackString(data, szName, 64);
	CloseHandle(data);

	for (int i = 0; i < g_mapZonesCount; i++)
	{
		if (g_mapZones[i][zoneGroup] == zonegrp)
			Format(g_mapZones[i][zoneName], 64, szName);
	}

	if (IsValidClient(client))
	{
		PrintToChat(client, "[%cSurf Timer%c] Bonus name succesfully changed.", MOSSGREEN, WHITE);
		ListBonusSettings(client);
	}
	db_selectMapZones();
}

public void db_checkAndFixZoneIds()
{
	char szQuery[512];
	//"SELECT mapname, zoneid, zonetype, zonetypeid, pointa_x, pointa_y, pointa_z, pointb_x, pointb_y, pointb_z, vis, team, zonegroup, zonename FROM ck_zones WHERE mapname = '%s' ORDER BY zoneid ASC";
	if (!g_szMapName[0])
		GetCurrentMap(g_szMapName, 128);

	Format(szQuery, 512, sql_selectZoneIds, g_szMapName);
	SQL_TQuery(g_hDb, db_checkAndFixZoneIdsCallback, szQuery, 1, DBPrio_Low);
}

public void db_checkAndFixZoneIdsCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (db_checkAndFixZoneIdsCallback): %s", error);
		return;
	}

	if (SQL_HasResultSet(hndl))
	{
		bool IDError = false;
		float x1[128], y1[128], z1[128], x2[128], y2[128], z2[128];
		int checker = 0, i, zonetype[128], zonetypeid[128], vis[128], team[128], zoneGrp[128];
		char zName[128][128];

		while (SQL_FetchRow(hndl))
		{
			i = SQL_FetchInt(hndl, 1);
			zonetype[checker] = SQL_FetchInt(hndl, 2);
			zonetypeid[checker] = SQL_FetchInt(hndl, 3);
			x1[checker] = SQL_FetchFloat(hndl, 4);
			y1[checker] = SQL_FetchFloat(hndl, 5);
			z1[checker] = SQL_FetchFloat(hndl, 6);
			x2[checker] = SQL_FetchFloat(hndl, 7);
			y2[checker] = SQL_FetchFloat(hndl, 8);
			z2[checker] = SQL_FetchFloat(hndl, 9);
			vis[checker] = SQL_FetchInt(hndl, 10);
			team[checker] = SQL_FetchInt(hndl, 11);
			zoneGrp[checker] = SQL_FetchInt(hndl, 12);
			SQL_FetchString(hndl, 13, zName[checker], 128);

			if (i != checker)
				IDError = true;

			checker++;
		}

		if (IDError)
		{
			char szQuery[256];
			Format(szQuery, 256, sql_deleteMapZones, g_szMapName);
			SQL_FastQuery(g_hDb, szQuery);

			for (int k = 0; k < checker; k++)
			{
				db_insertZoneCheap(k, zonetype[k], zonetypeid[k], x1[k], y1[k], z1[k], x2[k], y2[k], z2[k], vis[k], team[k], zoneGrp[k], zName[k], -10);
			}
		}
	}
	db_selectMapZones();
}

public void db_deleteAllZones(int client)
{
	char szQuery[128];
	Format(szQuery, 128, sql_deleteAllZones);
	SQL_TQuery(g_hDb, SQL_deleteAllZonesCallback, szQuery, client, DBPrio_Low);
}

public void SQL_deleteAllZonesCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_deleteAllZonesCallback): %s", error);
		return;
	}

	Admin_InsertZonestoDatabase(data);
}

public void ZoneDefaultName(int zonetype, int zonegroup, char zName[128])
{
	if (zonegroup > 0)
	{
		Format(zName, 64, "BONUS %i", zonegroup);
	}
	else
		if (-1 < zonetype < ZONEAMOUNT)
			Format(zName, 128, "%s %i", g_szZoneDefaultNames[zonetype], zonegroup);
		else
			Format(zName, 64, "Unknown");
}

public void db_insertZoneCheap(int zoneid, int zonetype, int zonetypeid, float pointax, float pointay, float pointaz, float pointbx, float pointby, float pointbz, int vis, int team, int zGrp, char zName[128], int query)
{
	char szQuery[1024];
	//"INSERT INTO ck_zones (mapname, zoneid, zonetype, zonetypeid, pointa_x, pointa_y, pointa_z, pointb_x, pointb_y, pointb_z, vis, team, zonegroup, zonename) VALUES ('%s', '%i', '%i', '%i', '%f', '%f', '%f', '%f', '%f', '%f', '%i', '%i', '%i', '%s')";
	Format(szQuery, 1024, sql_insertZones, g_szMapName, zoneid, zonetype, zonetypeid, pointax, pointay, pointaz, pointbx, pointby, pointbz, vis, team, zGrp, zName);
	SQL_TQuery(g_hDb, SQL_insertZonesCheapCallback, szQuery, query, DBPrio_Low);
}

public void SQL_insertZonesCheapCallback(Handle owner, Handle hndl, const char[] error, any query)
{
	if (hndl == null)
	{
		PrintToChatAll("[%cSurf Timer%c] Failed to create a zone, attempting a fix... Recreate the zone, please.", MOSSGREEN, WHITE);
		db_checkAndFixZoneIds();
		return;
	}
	if (query == (g_mapZonesCount - 1))
		db_selectMapZones();
}

public void db_insertZone(int zoneid, int zonetype, int zonetypeid, float pointax, float pointay, float pointaz, float pointbx, float pointby, float pointbz, int vis, int team, int zonegroup)
{
	char szQuery[1024];
	char zName[128];

	if (zonegroup == g_mapZoneGroupCount)
		ZoneDefaultName(zonetype, zonegroup, zName);
	else
		Format(zName, 128, g_szZoneGroupName[zonegroup]);

	//"INSERT INTO ck_zones (mapname, zoneid, zonetype, zonetypeid, pointa_x, pointa_y, pointa_z, pointb_x, pointb_y, pointb_z, vis, team, zonegroup, zonename) VALUES ('%s', '%i', '%i', '%i', '%f', '%f', '%f', '%f', '%f', '%f', '%i', '%i', '%i', '%s')";
	Format(szQuery, 1024, sql_insertZones, g_szMapName, zoneid, zonetype, zonetypeid, pointax, pointay, pointaz, pointbx, pointby, pointbz, vis, team, zonegroup, zName);
	SQL_TQuery(g_hDb, SQL_insertZonesCallback, szQuery, 1, DBPrio_Low);
}

public void SQL_insertZonesCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{

		PrintToChatAll("[%cSurf Timer%c] Failed to create a zone, attempting a fix... Recreate the zone, please.", MOSSGREEN, WHITE);
		db_checkAndFixZoneIds();
		return;
	}

	db_selectMapZones();
}

public void db_saveZones()
{
	char szQuery[258];
	Format(szQuery, 258, sql_deleteMapZones, g_szMapName);
	SQL_TQuery(g_hDb, SQL_saveZonesCallBack, szQuery, 1, DBPrio_Low);
}

public void SQL_saveZonesCallBack(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_saveZonesCallBack): %s", error);
		return;
	}
	char szzone[128];
	for (int i = 0; i < g_mapZonesCount; i++)
	{
		Format(szzone, 128, "%s", g_szZoneGroupName[g_mapZones[i][zoneGroup]]);
		if (g_mapZones[i][PointA][0] != -1.0 && g_mapZones[i][PointA][1] != -1.0 && g_mapZones[i][PointA][2] != -1.0)
			db_insertZoneCheap(g_mapZones[i][zoneId], g_mapZones[i][zoneType], g_mapZones[i][zoneTypeId], g_mapZones[i][PointA][0], g_mapZones[i][PointA][1], g_mapZones[i][PointA][2], g_mapZones[i][PointB][0], g_mapZones[i][PointB][1], g_mapZones[i][PointB][2], g_mapZones[i][Vis], g_mapZones[i][Team], g_mapZones[i][zoneGroup], szzone, i);
	}
}

public void db_updateZone(int zoneid, int zonetype, int zonetypeid, float[] Point1, float[] Point2, int vis, int team, int zonegroup)
{
	char szQuery[1024];
	Format(szQuery, 1024, sql_updateZone, zonetype, zonetypeid, Point1[0], Point1[1], Point1[2], Point2[0], Point2[1], Point2[2], vis, team, zonegroup, zoneid, g_szMapName);
	SQL_TQuery(g_hDb, SQL_updateZoneCallback, szQuery, 1, DBPrio_Low);
}

public void SQL_updateZoneCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_updateZoneCallback): %s", error);
		return;
	}

	db_selectMapZones();
}

public int db_deleteZonesInGroup(int client)
{
	char szQuery[258];

	if (g_CurrentSelectedZoneGroup[client] < 1)
	{
		if(IsValidClient(client))
			PrintToChat(client, "[%cSurf Timerc%] Invalid zonegroup index selected, aborting. (%i)", MOSSGREEN, WHITE, g_CurrentSelectedZoneGroup[client]);

		PrintToServer("[Surf Timer] Invalid zonegroup index selected, aborting. (%i)", g_CurrentSelectedZoneGroup[client]);
	}

	Transaction h_DeleteZoneGroup = SQL_CreateTransaction();

	Format(szQuery, 258, sql_deleteZonesInGroup, g_szMapName, g_CurrentSelectedZoneGroup[client]);
	SQL_AddQuery(h_DeleteZoneGroup, szQuery);

	Format(szQuery, 258, "UPDATE ck_zones SET zonegroup = zonegroup-1 WHERE zonegroup > %i AND mapname = '%s';", g_CurrentSelectedZoneGroup[client], g_szMapName);
	SQL_AddQuery(h_DeleteZoneGroup, szQuery);

	Format(szQuery, 258, "DELETE FROM ck_bonus WHERE zonegroup = %i AND mapname = '%s';", g_CurrentSelectedZoneGroup[client], g_szMapName);
	SQL_AddQuery(h_DeleteZoneGroup, szQuery);

	Format(szQuery, 258, "UPDATE ck_bonus SET zonegroup = zonegroup-1 WHERE zonegroup > %i AND mapname = '%s';", g_CurrentSelectedZoneGroup[client], g_szMapName);
	SQL_AddQuery(h_DeleteZoneGroup, szQuery);

	SQL_ExecuteTransaction(g_hDb, h_DeleteZoneGroup, SQLTxn_ZoneGroupRemovalSuccess, SQLTxn_ZoneGroupRemovalFailed, client);

}

public void SQLTxn_ZoneGroupRemovalSuccess(Handle db, any client, int numQueries, Handle[] results, any[] queryData)
{
	PrintToServer("[Surf Timer] Zonegroup removal was successful");

	db_selectMapZones();
	db_viewFastestBonus();
	db_viewBonusTotalCount();
	db_viewRecordCheckpointInMap();

	if (IsValidClient(client))
	{
		ZoneMenu(client);
		PrintToChat(client, "[%cSurf Timer%c] Zone group deleted.", MOSSGREEN, WHITE);
	}
	return;
}

public void SQLTxn_ZoneGroupRemovalFailed(Handle db, any client, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	if(IsValidClient(client))
		PrintToChat(client, "[%cSurf Timer%c] Zonegroup removal failed! (Error: %s)", MOSSGREEN, WHITE, error);

	PrintToServer("[Surf Timer] Zonegroup removal failed (Error: %s)", error);
	return;
}

public void db_selectzoneTypeIds(int zonetype, int client, int zonegrp)
{
	char szQuery[258];
	Format(szQuery, 258, sql_selectzoneTypeIds, g_szMapName, zonetype, zonegrp);
	SQL_TQuery(g_hDb, SQL_selectzoneTypeIdsCallback, szQuery, client, DBPrio_Low);
}

public void SQL_selectzoneTypeIdsCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_selectzoneTypeIdsCallback): %s", error);
		return;
	}

	if (SQL_HasResultSet(hndl))
	{
		int availableids[MAXZONES] =  { 0, ... }, i;
		while (SQL_FetchRow(hndl))
		{
			i = SQL_FetchInt(hndl, 0);
			if (i < MAXZONES)
				availableids[i] = 1;
		}
		Menu TypeMenu = new Menu(Handle_EditZoneTypeId);
		char MenuNum[24], MenuInfo[6], MenuItemName[24];
		int x = 0;
		// Types: Start(1), End(2), Stage(3), Checkpoint(4), Speed(5), TeleToStart(6), Validator(7), Chekcer(8), Stop(0)
		switch (g_CurrentZoneType[data])
		{
			case 0:Format(MenuItemName, 24, "Stop");
			case 1:Format(MenuItemName, 24, "Start");
			case 2:Format(MenuItemName, 24, "End");
			case 3:
			{
				Format(MenuItemName, 24, "Stage");
				x = 2;
			}
			case 4:Format(MenuItemName, 24, "Checkpoint");
			case 5:Format(MenuItemName, 24, "Speed");
			case 6:Format(MenuItemName, 24, "TeleToStart");
			case 7:Format(MenuItemName, 24, "Validator");
			case 8:Format(MenuItemName, 24, "Checker");
			default:Format(MenuItemName, 24, "Unknown");
		}

		for (int k = 0; k < 35; k++)
		{
			if (availableids[k] == 0)
			{
				Format(MenuNum, sizeof(MenuNum), "%s-%i", MenuItemName, (k + x));
				Format(MenuInfo, sizeof(MenuInfo), "%i", k);
				TypeMenu.AddItem(MenuInfo, MenuNum);
			}
		}
		TypeMenu.ExitButton = true;
		TypeMenu.Display(data, MENU_TIME_FOREVER);
	}
}
/*
public checkZoneTypeIds()
{
	InitZoneVariables();

	char szQuery[258];
	Format(szQuery, 258, "SELECT `zonegroup` ,`zonetype`, `zonetypeid`  FROM `ck_zones` WHERE `mapname` = '%s';", g_szMapName);
	SQL_TQuery(g_hDb, checkZoneTypeIdsCallback, szQuery, 1, DBPrio_High);
}

public checkZoneTypeIdsCallback(Handle owner, Handle hndl, const char[] error, any:data)
{
	if(hndl == null)
	{
		LogError("[Surf Timer] SQL Error (checkZoneTypeIds): %s", error);
		return;
	}
	if(SQL_HasResultSet(hndl))
	{
		int idChecker[MAXZONEGROUPS][ZONEAMOUNT][MAXZONES], idCount[MAXZONEGROUPS][ZONEAMOUNT];
		char szQuery[258];
		//  Fill array with id's
		// idChecker = map zones in
		while (SQL_FetchRow(hndl))
		{
			idChecker[SQL_FetchInt(hndl, 0)][SQL_FetchInt(hndl, 1)][SQL_FetchInt(hndl, 2)] = 1;
			idCount[SQL_FetchInt(hndl, 0)][SQL_FetchInt(hndl, 1)]++;
		}
		for (int i = 0; i < MAXZONEGROUPS; i++)
		{
			for (int j = 0; j < ZONEAMOUNT; j++)
			{
				for (int k = 0; k < idCount[i][j]; k++)
				{
					if (idChecker[i][j][k] == 1)
						continue;
					else
					{
						PrintToServer("[Surf Timer] Error on zonetype: %i, zonetypeid: %i", i, idChecker[i][k]);
						Format(szQuery, 258, "UPDATE `ck_zones` SET zonetypeid = zonetypeid-1 WHERE mapname = '%s' AND zonetype = %i AND zonetypeid > %i AND zonegroup = %i;", g_szMapName, j, k, i);
						SQL_LockDatabase(g_hDb);
						SQL_FastQuery(g_hDb, szQuery);
						SQL_UnlockDatabase(g_hDb);
					}
				}
			}
		}

		Format(szQuery, 258, "SELECT `zoneid` FROM `ck_zones` WHERE mapname = '%s' ORDER BY zoneid ASC;", g_szMapName);
		SQL_TQuery(g_hDb, checkZoneIdsCallback, szQuery, 1, DBPrio_High);
	}
}

public checkZoneIdsCallback(Handle owner, Handle hndl, const char[] error, any:data)
{
	if(hndl == null)
	{
		LogError("[Surf Timer] SQL Error (checkZoneIdsCallback): %s", error);
		return;
	}

	if(SQL_HasResultSet(hndl))
	{
		int i = 0;
		char szQuery[258];
		while (SQL_FetchRow(hndl))
		{
			if (SQL_FetchInt(hndl, 0) == i)
			{
				i++;
				continue;
			}
			else
			{
				PrintToServer("[Surf Timer] Found an error in ZoneID's. Fixing...");
				Format(szQuery, 258, "UPDATE `ck_zones` SET zoneid = %i WHERE mapname = '%s' AND zoneid = %i", i, g_szMapName, SQL_FetchInt(hndl, 0));
				SQL_LockDatabase(g_hDb);
				SQL_FastQuery(g_hDb, szQuery);
				SQL_UnlockDatabase(g_hDb);
				i++;
			}
		}

		char szQuery2[258];
		Format(szQuery2, 258, "SELECT `zonegroup` FROM `ck_zones` WHERE `mapname` = '%s' ORDER BY `zonegroup` ASC;", g_szMapName);
		SQL_TQuery(g_hDb, checkZoneGroupIds, szQuery2, 1, DBPrio_Low);
	}
}

public checkZoneGroupIds(Handle owner, Handle hndl, const char[] error, any:data)
{
	if(hndl == null)
	{
		LogError("[Surf Timer] SQL Error (checkZoneGroupIds): %s", error);
		return;
	}

	if(SQL_HasResultSet(hndl))
	{
		int i = 0;
		char szQuery[258];
		while (SQL_FetchRow(hndl))
		{
			if (SQL_FetchInt(hndl, 0) == i)
				continue;
			else if (SQL_FetchInt(hndl, 0) == (i+1))
				i++;
			else
			{
				i++;
				PrintToServer("[Surf Timer] Found an error in zoneGroupID's. Fixing...");
				Format(szQuery, 258, "UPDATE `ck_zones` SET `zonegroup` = %i WHERE `mapname` = '%s' AND `zonegroup` = %i", i, g_szMapName, SQL_FetchInt(hndl, 0));
				SQL_LockDatabase(g_hDb);
				SQL_FastQuery(g_hDb, szQuery);
				SQL_UnlockDatabase(g_hDb);
			}
		}
		db_selectMapZones();
	}
}
*/
public void db_selectMapZones()
{
	char szQuery[258];
	Format(szQuery, 258, sql_selectMapZones, g_szMapName);
	SQL_TQuery(g_hDb, SQL_selectMapZonesCallback, szQuery, 1, DBPrio_High);
}

public void SQL_selectMapZonesCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_selectMapZonesCallback): %s", error);
		if (!g_bServerDataLoaded)
			db_GetMapRecord_Pro();
		return;
	}

	RemoveZones();

	if (SQL_HasResultSet(hndl))
	{
		g_mapZonesCount = 0;
		g_bhasStages = false;
		g_bhasBonus = false;
		g_mapZoneGroupCount = 0; // 1 = No Bonus, 2 = Bonus, >2 = Multiple bonuses

		for (int i = 0; i < MAXZONES; i++)
		{
			g_mapZones[i][zoneId] = -1;
			g_mapZones[i][PointA] = -1.0;
			g_mapZones[i][PointB] = -1.0;
			g_mapZones[i][zoneId] = -1;
			g_mapZones[i][zoneType] = -1;
			g_mapZones[i][zoneTypeId] = -1;
			g_mapZones[i][zoneName] = 0;
			g_mapZones[i][Vis] = 0;
			g_mapZones[i][Team] = 0;
			g_mapZones[i][zoneGroup] = 0;
			g_mapZones[i][TeleportPosition] = -1.0;
			g_mapZones[i][TeleportAngles] = -1.0;
		}

		for (int x = 0; x < MAXZONEGROUPS; x++)
		{
			g_mapZoneCountinGroup[x] = 0;
			for (int k = 0; k < ZONEAMOUNT; k++)
				g_mapZonesTypeCount[x][k] = 0;
		}

		int zoneIdChecker[MAXZONES], zoneTypeIdChecker[MAXZONEGROUPS][ZONEAMOUNT][MAXZONES], zoneTypeIdCheckerCount[MAXZONEGROUPS][ZONEAMOUNT], zoneGroupChecker[MAXZONEGROUPS];

		// Types: Start(1), End(2), Stage(3), Checkpoint(4), Speed(5), TeleToStart(6), Validator(7), Chekcer(8), Stop(0)
		while (SQL_FetchRow(hndl))
		{
			g_mapZones[g_mapZonesCount][zoneId] = SQL_FetchInt(hndl, 0);
			g_mapZones[g_mapZonesCount][zoneType] = SQL_FetchInt(hndl, 1);
			g_mapZones[g_mapZonesCount][zoneTypeId] = SQL_FetchInt(hndl, 2);
			g_mapZones[g_mapZonesCount][PointA][0] = SQL_FetchFloat(hndl, 3);
			g_mapZones[g_mapZonesCount][PointA][1] = SQL_FetchFloat(hndl, 4);
			g_mapZones[g_mapZonesCount][PointA][2] = SQL_FetchFloat(hndl, 5);
			g_mapZones[g_mapZonesCount][PointB][0] = SQL_FetchFloat(hndl, 6);
			g_mapZones[g_mapZonesCount][PointB][1] = SQL_FetchFloat(hndl, 7);
			g_mapZones[g_mapZonesCount][PointB][2] = SQL_FetchFloat(hndl, 8);
			g_mapZones[g_mapZonesCount][Vis] = SQL_FetchInt(hndl, 9);
			g_mapZones[g_mapZonesCount][Team] = SQL_FetchInt(hndl, 10);
			g_mapZones[g_mapZonesCount][zoneGroup] = SQL_FetchInt(hndl, 11);


			/**
			* Initialize error checking
			* 0 = zone not found
			* 1 = zone found
			*
			* IDs must be in order 0, 1, 2.... n
			* Duplicate zoneids not possible due to primary key
			*/
			zoneIdChecker[g_mapZones[g_mapZonesCount][zoneId]]++;
			if (zoneGroupChecker[g_mapZones[g_mapZonesCount][zoneGroup]] != 1)
			{
				// 1 = No Bonus, 2 = Bonus, >2 = Multiple bonuses
				g_mapZoneGroupCount++;
				zoneGroupChecker[g_mapZones[g_mapZonesCount][zoneGroup]] = 1;
			}

			// You can have the same zonetype and zonetypeid values in different zonegroups
			zoneTypeIdChecker[g_mapZones[g_mapZonesCount][zoneGroup]][g_mapZones[g_mapZonesCount][zoneType]][g_mapZones[g_mapZonesCount][zoneTypeId]]++;
			zoneTypeIdCheckerCount[g_mapZones[g_mapZonesCount][zoneGroup]][g_mapZones[g_mapZonesCount][zoneType]]++;

			SQL_FetchString(hndl, 12, g_mapZones[g_mapZonesCount][zoneName], 128);

			if (!g_mapZones[g_mapZonesCount][zoneName][0])
			{
				switch (g_mapZones[g_mapZonesCount][zoneType])
				{
					case 0:
					{
						Format(g_mapZones[g_mapZonesCount][zoneName], 128, "Stop-%i", g_mapZones[g_mapZonesCount][zoneTypeId]);
					}
					case 1:
					{
						if (g_mapZones[g_mapZonesCount][zoneGroup] > 0)
						{
							g_bhasBonus = true;
							Format(g_mapZones[g_mapZonesCount][zoneName], 128, "BonusStart-%i", g_mapZones[g_mapZonesCount][zoneTypeId]);
							Format(g_szZoneGroupName[g_mapZones[g_mapZonesCount][zoneGroup]], 128, "BONUS %i", g_mapZones[g_mapZonesCount][zoneGroup]);
						}
						else
							Format(g_mapZones[g_mapZonesCount][zoneName], 128, "Start-%i", g_mapZones[g_mapZonesCount][zoneTypeId]);
					}
					case 2:
					{
						if (g_mapZones[g_mapZonesCount][zoneGroup] > 0)
							Format(g_mapZones[g_mapZonesCount][zoneName], 128, "BonusEnd-%i", g_mapZones[g_mapZonesCount][zoneTypeId]);
						else
							Format(g_mapZones[g_mapZonesCount][zoneName], 128, "End-%i", g_mapZones[g_mapZonesCount][zoneTypeId]);
					}
					case 3:
					{
						g_bhasStages = true;
						Format(g_mapZones[g_mapZonesCount][zoneName], 128, "Stage-%i", (g_mapZones[g_mapZonesCount][zoneTypeId] + 2));
					}
					case 4:
					{
						Format(g_mapZones[g_mapZonesCount][zoneName], 128, "Checkpoint-%i", g_mapZones[g_mapZonesCount][zoneTypeId]);
					}
					case 5:
					{
						Format(g_mapZones[g_mapZonesCount][zoneName], 128, "Speed-%i", g_mapZones[g_mapZonesCount][zoneTypeId]);
					}
					case 6:
					{
						Format(g_mapZones[g_mapZonesCount][zoneName], 128, "TeleToStart-%i", g_mapZones[g_mapZonesCount][zoneTypeId]);
					}
					case 7:
					{
						Format(g_mapZones[g_mapZonesCount][zoneName], 128, "Validator-%i", g_mapZones[g_mapZonesCount][zoneTypeId]);
					}
					case 8:
					{
						Format(g_mapZones[g_mapZonesCount][zoneName], 128, "Checker-%i", g_mapZones[g_mapZonesCount][zoneTypeId]);
					}
				}
			}
			else
			{
				switch (g_mapZones[g_mapZonesCount][zoneType])
				{
					case 1:
					{
						if (g_mapZones[g_mapZonesCount][zoneGroup] > 0)
							g_bhasBonus = true;
						Format(g_szZoneGroupName[g_mapZones[g_mapZonesCount][zoneGroup]], 128, "%s", g_mapZones[g_mapZonesCount][zoneName]);
					}
					case 3:
					g_bhasStages = true;

				}
			}

			/**
			*	Count zone center
			**/
			// Center
			float posA[3], posB[3], result[3];
			Array_Copy(g_mapZones[g_mapZonesCount][PointA], posA, 3);
			Array_Copy(g_mapZones[g_mapZonesCount][PointB], posB, 3);
			AddVectors(posA, posB, result);
			g_mapZones[g_mapZonesCount][CenterPoint][0] = FloatDiv(result[0], 2.0);
			g_mapZones[g_mapZonesCount][CenterPoint][1] = FloatDiv(result[1], 2.0);
			g_mapZones[g_mapZonesCount][CenterPoint][2] = FloatDiv(result[2], 2.0);

			for (int i = 0; i < 3; i++)
			{
				g_fZoneCorners[g_mapZonesCount][0][i] = g_mapZones[g_mapZonesCount][PointA][i];
				g_fZoneCorners[g_mapZonesCount][7][i] = g_mapZones[g_mapZonesCount][PointB][i];
			}

			// Zone counts:
			g_mapZonesTypeCount[g_mapZones[g_mapZonesCount][zoneGroup]][g_mapZones[g_mapZonesCount][zoneType]]++;
			g_mapZonesCount++;
		}

		for (int x = 0; x < g_mapZonesCount; x++)
		{
			// Count zone corners
			// https://forums.alliedmods.net/showpost.php?p=2006539&postcount=8
			for(int i = 1; i < 7; i++)
			{
				for(int j = 0; j < 3; j++)
				{
					g_fZoneCorners[x][i][j] = g_fZoneCorners[x][((i >> (2-j)) & 1) * 7][j];
				}
			}

			// Find info_teleport_destination insize zones
			int ent = -1;
			while((ent = FindEntityByClassname(ent, "info_teleport_destination")) != -1)
			{
				float pos[3], ang[3];
				GetEntPropVector(ent, Prop_Data, "m_vecOrigin", pos);
				GetEntPropVector(ent, Prop_Data, "m_angRotation", ang);

				// Check if entity is inside zone
				if (IsInsideZone(pos) == x)
				{
					Array_Copy(pos, g_mapZones[x][TeleportPosition], 3);
					Array_Copy(ang, g_mapZones[x][TeleportAngles], 3);
					break;
				}
			}
		}

		/**
		* Check for errors
		*
		* 1. ZoneId
		*/
		char szQuery[258];
		for (int i = 0; i < g_mapZonesCount; i++)
			if (zoneIdChecker[i] == 0)
			{
				PrintToServer("[Surf Timer] Found an error in zoneid : %i", i);
				Format(szQuery, 258, "UPDATE `ck_zones` SET zoneid = zoneid-1 WHERE mapname = '%s' AND zoneid > %i", g_szMapName, i);
				PrintToServer("Query: %s", szQuery);
				SQL_TQuery(g_hDb, sql_zoneFixCallback, szQuery, -1, DBPrio_Low);
				return;
			}

		// 2nd ZoneGroup
		for (int i = 0; i < g_mapZoneGroupCount; i++)
			if (zoneGroupChecker[i] == 0)
			{
				PrintToServer("[Surf Timer] Found an error in zonegroup %i (ZoneGroups total: %i)", i, g_mapZoneGroupCount);
				Format(szQuery, 258, "UPDATE `ck_zones` SET `zonegroup` = zonegroup-1 WHERE `mapname` = '%s' AND `zonegroup` > %i", g_szMapName, i);
				SQL_TQuery(g_hDb, sql_zoneFixCallback, szQuery, zoneGroupChecker[i], DBPrio_Low);
				return;
			}

		// 3rd ZoneTypeId
		for (int i = 0; i < g_mapZoneGroupCount; i++)
			for (int k = 0; k < ZONEAMOUNT; k++)
				for (int x = 0; x < zoneTypeIdCheckerCount[i][k]; x++)
					if (zoneTypeIdChecker[i][k][x] != 1 && (k == 3) || (k == 4))
					{
						if (zoneTypeIdChecker[i][k][x] == 0)
						{
							PrintToServer("[Surf Timer] ZoneTypeID missing! [ZoneGroup: %i ZoneType: %i, ZonetypeId: %i]", i, k, x);
							Format(szQuery, 258, "UPDATE `ck_zones` SET zonetypeid = zonetypeid-1 WHERE mapname = '%s' AND zonetype = %i AND zonetypeid > %i AND zonegroup = %i;", g_szMapName, k, x, i);
							SQL_TQuery(g_hDb, sql_zoneFixCallback, szQuery, -1, DBPrio_Low);
							return;
						}
						else if (zoneTypeIdChecker[i][k][x] > 1)
						{
							char szerror[258];
							Format(szerror, 258, "[Surf Timer] Duplicate Stage Zone ID's on %s [ZoneGroup: %i, ZoneType: 3, ZoneTypeId: %i]", g_szMapName, k, x);
							LogError(szerror);
						}
					}

		RefreshZones();

		// Set mapzone count in group
		for (int x = 0; x < g_mapZoneGroupCount; x++)
			for (int k = 0; k < ZONEAMOUNT; k++)
				if (g_mapZonesTypeCount[x][k] > 0)
					g_mapZoneCountinGroup[x]++;

		if (!g_bServerDataLoaded)
			db_GetMapRecord_Pro();

		// Clear old stage records
		for (int i = 0; i < CPLIMIT; i++)
		{
			g_StageRecords[i][srRunTime] = 9999999.0;
			g_StageRecords[i][srLoaded] = false;
			g_StageRecords[i][srCompletions] = 0;

			g_fStageMaxVelocity[i] = g_hStagePreSpeed.FloatValue;
			g_bStageIgnorePrehop[i] = false;
		}

		// Load custom map config
		char map_cfg_path[PLATFORM_MAX_PATH], map_cfg_path2[PLATFORM_MAX_PATH];
		Format(map_cfg_path, sizeof(map_cfg_path), "sourcemod/ckSurf/maps/%s.cfg", g_szMapName);
		Format(map_cfg_path2, sizeof(map_cfg_path2), "cfg/%s", map_cfg_path);

		if (FileExists(map_cfg_path2))
			ServerCommand("exec %s", map_cfg_path);

		// Start loading stages
		g_bLoadingStages = true;
		db_loadStageServerRecords(0);

		return;
	}
}

public void sql_zoneFixCallback(Handle owner, Handle hndl, const char[] error, any zongeroup)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_zoneFixCallback): %s", error);
		return;
	}
	if (zongeroup == -1)
	{
		db_selectMapZones();
	}
	else
	{
		char szQuery[258];
		Format(szQuery, 258, "DELETE FROM `ck_bonus` WHERE `mapname` = '%s' AND `zonegroup` = %i;", g_szMapName, zongeroup);
		SQL_TQuery(g_hDb, sql_zoneFixCallback2, szQuery, zongeroup, DBPrio_Low);
	}
}

public void sql_zoneFixCallback2(Handle owner, Handle hndl, const char[] error, any zongeroup)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_zoneFixCallback2): %s", error);
		return;
	}

	char szQuery[258];
	Format(szQuery, 258, "UPDATE ck_bonus SET zonegroup = zonegroup-1 WHERE `mapname` = '%s' AND `zonegroup` = %i;", g_szMapName, zongeroup);
	SQL_TQuery(g_hDb, sql_zoneFixCallback, szQuery, -1, DBPrio_Low);
}

public void db_deleteMapZones()
{
	char szQuery[258];
	Format(szQuery, 258, sql_deleteMapZones, g_szMapName);
	SQL_TQuery(g_hDb, SQL_deleteMapZonesCallback, szQuery, 1, DBPrio_Low);
}

public void SQL_deleteMapZonesCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_deleteMapZonesCallback): %s", error);
		return;
	}
}

public void db_deleteZone(int client, int zoneid)
{
	char szQuery[258];
	Transaction h_deleteZone = SQL_CreateTransaction();

	Format(szQuery, 258, sql_deleteZone, g_szMapName, zoneid);
	SQL_AddQuery(h_deleteZone, szQuery);

	Format(szQuery, 258, "UPDATE ck_zones SET zoneid = zoneid-1 WHERE mapname = '%s' AND zoneid > %i", g_szMapName, zoneid);
	SQL_AddQuery(h_deleteZone, szQuery);

	SQL_ExecuteTransaction(g_hDb, h_deleteZone, SQLTxn_ZoneRemovalSuccess, SQLTxn_ZoneRemovalFailed, client);
}

public void SQLTxn_ZoneRemovalSuccess(Handle db, any client, int numQueries, Handle[] results, any[] queryData)
{
	if (IsValidClient(client))
		PrintToChat(client, "[%cSurf Timer%c] Zone Removed Succesfully", MOSSGREEN, WHITE);
	PrintToServer("[Surf Timer] Zone Removed Succesfully");
}

public void SQLTxn_ZoneRemovalFailed(Handle db, any client, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	if (IsValidClient(client))
		PrintToChat(client, "[%cSurf Timer%c] %cZone Removal Failed! Error:%c %s", MOSSGREEN, WHITE, RED, WHITE, error);
	PrintToServer("[Surf Timer] Zone Removal Failed. Error: %s", error);
	return;
}