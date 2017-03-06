public void db_resetPlayerMapRecord(int client, char steamid[128], char szMapName[128])
{
	char szQuery[255];
	char szQuery2[255];
	char szsteamid[128 * 2 + 1];

	SQL_EscapeString(g_hDb, steamid, szsteamid, 128 * 2 + 1);
	Format(szQuery, 255, sql_resetRecordPro, szsteamid, szMapName);
	Format(szQuery2, 255, sql_resetCheckpoints, szsteamid, szMapName);

	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, steamid);

	SQL_TQuery(g_hDb, SQL_CheckCallback3, szQuery, pack);
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery2, 1);
	PrintToConsole(client, "map time of %s on %s cleared.", steamid, szMapName);

	if (StrEqual(szMapName, g_szMapName))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				if (StrEqual(g_szSteamID[i], szsteamid))
				{
					Format(g_szPersonalRecord[i], 64, "NONE");
					g_fPersonalRecord[i] = 0.0;
					g_MapRank[i] = 99999;
				}
			}
		}
	}
}

public void db_resetPlayerRecords2(int client, char steamid[128], char szMapName[128])
{
	char szQuery[255];
	char szsteamid[128 * 2 + 1];

	SQL_EscapeString(g_hDb, steamid, szsteamid, 128 * 2 + 1);
	Format(szQuery, 255, sql_resetRecords2, szsteamid, szMapName);
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, steamid);
	SQL_TQuery(g_hDb, SQL_CheckCallback3, szQuery, pack);
	PrintToConsole(client, "map times of %s on %s cleared.", steamid, szMapName);

	if (StrEqual(szMapName, g_szMapName))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsValidClient(i))
			{
				if (StrEqual(g_szSteamID[i], szsteamid))
				{
					Format(g_szPersonalRecord[i], 64, "NONE");
					g_fPersonalRecord[i] = 0.0;
					g_MapRank[i] = 99999;
				}
			}
		}
	}
}

public void db_GetMapRecord_Pro()
{
	g_fRecordMapTime = 9999999.0;
	char szQuery[512];
	// SELECT MIN(runtimepro), name, steamid FROM ck_playertimes WHERE mapname = '%s' AND runtimepro > -1.0
	Format(szQuery, 512, sql_selectMapRecord, g_szMapName);
	SQL_TQuery(g_hDb, sql_selectMapRecordCallback, szQuery, DBPrio_Low);
}

public void sql_selectMapRecordCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_selectMapRecordCallback): %s", error);
		if (!g_bServerDataLoaded)
			db_viewMapProRankCount();
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		g_fRecordMapTime = SQL_FetchFloat(hndl, 0);
		if (g_fRecordMapTime > -1.0 && !SQL_IsFieldNull(hndl, 0))
		{
			g_fRecordMapTime = SQL_FetchFloat(hndl, 0);
			FormatTimeFloat(0, g_fRecordMapTime, 3, g_szRecordMapTime, 64);
			SQL_FetchString(hndl, 1, g_szRecordPlayer, MAX_NAME_LENGTH);
			SQL_FetchString(hndl, 2, g_szRecordMapSteamID, MAX_NAME_LENGTH);
		}
		else
		{
			Format(g_szRecordMapTime, 64, "N/A");
			g_fRecordMapTime = 9999999.0;
		}
	}
	else
	{
		Format(g_szRecordMapTime, 64, "N/A");
		g_fRecordMapTime = 9999999.0;
	}
	if (!g_bServerDataLoaded)
		db_viewMapProRankCount();
	return;
}


public void sql_selectProSurfersCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_selectProSurfersCallback): %s", error);
		return;
	}

	char szValue[128];
	char szSteamID[32];
	char szName[64];
	char szTime[32];
	float time;

	Menu topSurfersMenu = new Menu(MapMenuHandler3);
	topSurfersMenu.Pagination = 5;
	topSurfersMenu.SetTitle("Top 20 Map Times (local)\n    Rank   Time              Player");
	if (SQL_HasResultSet(hndl))

	{
		int i = 1;
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, szName, 64);
			time = SQL_FetchFloat(hndl, 1);
			SQL_FetchString(hndl, 2, szSteamID, 32);
			FormatTimeFloat(data, time, 3, szTime, sizeof(szTime));
			if (time < 3600.0)
				Format(szTime, 32, "  %s", szTime);
			if (i < 10)
				Format(szValue, 128, "[0%i.] %s    » %s", i, szTime, szName);
			else
				Format(szValue, 128, "[%i.] %s    » %s", i, szTime, szName);
			AddMenuItem(topSurfersMenu, szSteamID, szValue, ITEMDRAW_DEFAULT);
			i++;
		}
		if (i == 1)
		{
			PrintToChat(data, "%t", "NoMapRecords", MOSSGREEN, WHITE, g_szMapName);
		}
	}
	topSurfersMenu.OptionFlags = MENUFLAG_BUTTON_EXIT;
	topSurfersMenu.Display(data, MENU_TIME_FOREVER);
}

public void db_selectTopSurfers(int client, char mapname[128])
{
	char szQuery[1024];
	Format(szQuery, 1024, sql_selectTopSurfers, mapname);
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, mapname);
	SQL_TQuery(g_hDb, sql_selectTopSurfersCallback, szQuery, pack, DBPrio_Low);
}

public void db_selectMapTopSurfers(int client, char mapname[128])
{
	char szQuery[1024];
	Format(szQuery, 1024, sql_selectTopSurfers2, PERCENT, mapname, PERCENT, mapname, mapname, PERCENT);
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, mapname);
	SQL_TQuery(g_hDb, sql_selectTopSurfersCallback, szQuery, pack, DBPrio_Low);
}


//// BONUS //////////'

public void db_selectBonusesInMap(int client, char mapname[128])
{
	// SELECT mapname, zonegroup, zonename FROM `ck_zones` WHERE mapname LIKE '%c%s%c' AND zonegroup > 0 GROUP BY zonegroup;
	char szQuery[512];
	Format(szQuery, 512, sql_selectBonusesInMap, PERCENT, mapname, PERCENT, mapname, mapname, PERCENT);
	SQL_TQuery(g_hDb, db_selectBonusesInMapCallback, szQuery, client, DBPrio_Low);
}

public void db_selectBonusesInMapCallback(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (db_selectBonusesInMapCallback): %s", error);
		return;
	}
	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		char mapname[128], MenuTitle[248], BonusName[128], MenuID[248];
		int zGrp;

		if (SQL_GetRowCount(hndl) == 1)
		{
			SQL_FetchString(hndl, 0, mapname, 128);
			db_selectBonusTopSurfers(client, mapname, SQL_FetchInt(hndl, 1));
			return;
		}

		Menu listBonusesinMapMenu = new Menu(MenuHandler_SelectBonusinMap);

		SQL_FetchString(hndl, 0, mapname, 128);
		zGrp = SQL_FetchInt(hndl, 1);
		Format(MenuTitle, 248, "Choose a Bonus in %s", mapname);
		listBonusesinMapMenu.SetTitle(MenuTitle);

		SQL_FetchString(hndl, 2, BonusName, 128);

		if (!BonusName[0])
			Format(BonusName, 128, "BONUS %i", zGrp);

		Format(MenuID, 248, "%s-%i", mapname, zGrp);

		listBonusesinMapMenu.AddItem(MenuID, BonusName);


		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 2, BonusName, 128);
			zGrp = SQL_FetchInt(hndl, 1);

			if (StrEqual(BonusName, "NULL", false))
				Format(BonusName, 128, "BONUS %i", zGrp);

			Format(MenuID, 248, "%s-%i", mapname, zGrp);

			listBonusesinMapMenu.AddItem(MenuID, BonusName);
		}

		listBonusesinMapMenu.ExitButton = true;
		listBonusesinMapMenu.Display(client, 60);
	}
	else
	{
		PrintToChat(client, "[%cSurf Timer%c] No bonuses found.", MOSSGREEN, WHITE);
		return;
	}
}

public int MenuHandler_SelectBonusinMap(Handle sMenu, MenuAction action, int client, int item)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char aID[248];
			char splits[2][128];
			GetMenuItem(sMenu, item, aID, sizeof(aID));
			ExplodeString(aID, "-", splits, sizeof(splits), sizeof(splits[]));

			db_selectBonusTopSurfers(client, splits[0], StringToInt(splits[1]));
		}
		case MenuAction_End:
		{
			delete sMenu;
		}
	}
}



public void db_selectBonusTopSurfers(int client, char mapname[128], int zGrp)
{
	char szQuery[1024];
	Format(szQuery, 1024, sql_selectTopBonusSurfers, PERCENT, mapname, PERCENT, zGrp, mapname, mapname, PERCENT);
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, mapname);
	WritePackCell(pack, zGrp);
	SQL_TQuery(g_hDb, sql_selectTopBonusSurfersCallback, szQuery, pack, DBPrio_Low);
}

public void sql_selectTopBonusSurfersCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_selectTopBonusSurfersCallback): %s", error);
		return;
	}

	ResetPack(data);
	int client = ReadPackCell(data);
	char szMap[128];
	ReadPackString(data, szMap, 128);
	int zGrp = ReadPackCell(data);
	CloseHandle(data);

	char szFirstMap[128], szValue[128], szName[64], szSteamID[32], lineBuf[256], title[256];
	float time;
	bool bduplicat = false;
	Handle stringArray = CreateArray(100);
	Menu topMenu;

	if (StrEqual(szMap, g_szMapName))
		topMenu = new Menu(MapMenuHandler1);
	else
		topMenu = new Menu(MapTopMenuHandler2);

	topMenu.Pagination = 5;

	if (SQL_HasResultSet(hndl))
	{
		int i = 1;
		while (SQL_FetchRow(hndl))
		{
			bduplicat = false;
			SQL_FetchString(hndl, 0, szSteamID, 32);
			SQL_FetchString(hndl, 1, szName, 64);
			time = SQL_FetchFloat(hndl, 2);
			SQL_FetchString(hndl, 4, szMap, 128);
			if (i == 1 || (i > 1 && StrEqual(szFirstMap, szMap)))
			{
				int stringArraySize = GetArraySize(stringArray);
				for (int x = 0; x < stringArraySize; x++)
				{
					GetArrayString(stringArray, x, lineBuf, sizeof(lineBuf));
					if (StrEqual(lineBuf, szName, false))
						bduplicat = true;
				}
				if (bduplicat == false && i < 51)
				{
					char szTime[32];
					FormatTimeFloat(client, time, 3, szTime, sizeof(szTime));
					if (time < 3600.0)
						Format(szTime, 32, "   %s", szTime);
					if (i == 100)
						Format(szValue, 128, "[%i.] %s |    » %s", i, szTime, szName);
					if (i >= 10)
						Format(szValue, 128, "[%i.] %s |    » %s", i, szTime, szName);
					else
						Format(szValue, 128, "[0%i.] %s |    » %s", i, szTime, szName);
					topMenu.AddItem(szSteamID, szValue, ITEMDRAW_DEFAULT);
					PushArrayString(stringArray, szName);
					if (i == 1)
						Format(szFirstMap, 128, "%s", szMap);
					i++;
				}
			}
		}
		if (i == 1)
		{
			PrintToChat(client, "%t", "NoTopRecords", MOSSGREEN, WHITE, szMap);
		}
	}
	else
		PrintToChat(client, "%t", "NoTopRecords", MOSSGREEN, WHITE, szMap);
	Format(title, 256, "Top 50 Times on %s (B %i) \n    Rank    Time               Player", szFirstMap, zGrp);
	topMenu.SetTitle(title);
	topMenu.OptionFlags = MENUFLAG_BUTTON_EXIT;
	topMenu.Display(client, MENU_TIME_FOREVER);
	CloseHandle(stringArray);
}

public void sql_selectTopSurfersCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_selectTopSurfersCallback): %s", error);
		return;
	}

	ResetPack(data);
	int client = ReadPackCell(data);
	char szMap[128];
	ReadPackString(data, szMap, 128);
	CloseHandle(data);

	char szFirstMap[128];
	char szValue[128];
	char szName[64];
	float time;
	char szSteamID[32];
	char lineBuf[256];
	Handle stringArray = CreateArray(100);
	Handle menu;
	if (StrEqual(szMap, g_szMapName))
		menu = CreateMenu(MapMenuHandler1);
	else
		menu = CreateMenu(MapTopMenuHandler2);
	SetMenuPagination(menu, 5);
	bool bduplicat = false;
	char title[256];
	if (SQL_HasResultSet(hndl))
	{
		int i = 1;
		while (SQL_FetchRow(hndl))
		{
			bduplicat = false;
			SQL_FetchString(hndl, 0, szSteamID, 32);
			SQL_FetchString(hndl, 1, szName, 64);
			time = SQL_FetchFloat(hndl, 2);
			SQL_FetchString(hndl, 4, szMap, 128);
			if (i == 1 || (i > 1 && StrEqual(szFirstMap, szMap)))
			{
				int stringArraySize = GetArraySize(stringArray);
				for (int x = 0; x < stringArraySize; x++)
				{
					GetArrayString(stringArray, x, lineBuf, sizeof(lineBuf));
					if (StrEqual(lineBuf, szName, false))
						bduplicat = true;
				}
				if (bduplicat == false && i < 51)
				{
					char szTime[32];
					FormatTimeFloat(client, time, 3, szTime, sizeof(szTime));
					if (time < 3600.0)
						Format(szTime, 32, "   %s", szTime);
					if (i == 100)
						Format(szValue, 128, "[%i.] %s |    » %s", i, szTime, szName);
					if (i >= 10)
						Format(szValue, 128, "[%i.] %s |    » %s", i, szTime, szName);
					else
						Format(szValue, 128, "[0%i.] %s |    » %s", i, szTime, szName);
					AddMenuItem(menu, szSteamID, szValue, ITEMDRAW_DEFAULT);
					PushArrayString(stringArray, szName);
					if (i == 1)
						Format(szFirstMap, 128, "%s", szMap);
					i++;
				}
			}
		}
		if (i == 1)
		{
			PrintToChat(client, "%t", "NoTopRecords", MOSSGREEN, WHITE, szMap);
		}
	}
	else
		PrintToChat(client, "%t", "NoTopRecords", MOSSGREEN, WHITE, szMap);
	Format(title, 256, "Top 50 Times on %s \n    Rank    Time               Player", szFirstMap);
	SetMenuTitle(menu, title);
	SetMenuOptionFlags(menu, MENUFLAG_BUTTON_EXIT);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
	CloseHandle(stringArray);
}

public void db_selectProSurfers(int client)
{
	char szQuery[1024];
	Format(szQuery, 1024, sql_selectProSurfers, g_szMapName);
	SQL_TQuery(g_hDb, sql_selectProSurfersCallback, szQuery, client, DBPrio_Low);
}

public void db_currentRunRank(int client)
{
	if (!IsValidClient(client))
		return;

	char szQuery[512];
	Format(szQuery, 512, "SELECT count(runtimepro)+1 FROM `ck_playertimes` WHERE `mapname` = '%s' AND `runtimepro` < %f;", g_szMapName, g_fFinalTime[client]);
	SQL_TQuery(g_hDb, SQL_CurrentRunRankCallback, szQuery, client, DBPrio_Low);
}

public void SQL_CurrentRunRankCallback(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_CurrentRunRankCallback): %s", error);
		return;
	}
	// Get players rank, 9999999 = error
	int rank;
	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		rank = SQL_FetchInt(hndl, 0);
	}

	MapFinishedMsgs(client, rank);
}

//
// Get clients record from database
// Called when a player finishes a map
//
public void db_selectRecord(int client)
{
	if (!IsValidClient(client))
		return;

	char szQuery[255];
	Format(szQuery, 255, "SELECT runtimepro FROM ck_playertimes WHERE steamid = '%s' AND mapname = '%s' AND runtimepro > -1.0", g_szSteamID[client], g_szMapName);
	SQL_TQuery(g_hDb, sql_selectRecordCallback, szQuery, client, DBPrio_Low);
}

public void sql_selectRecordCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_selectRecordCallback): %s", error);
		return;
	}

	if (!IsValidClient(data))
		return;


	char szQuery[512];

	// Found old time from database
	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		float time = SQL_FetchFloat(hndl, 0);

		// If old time was slower than the new time, update record
		if ((g_fFinalTime[data] <= time || time <= 0.0))
		{
			db_updateRecordPro(data);
		}
	}
	else
	{  // No record found from database - Let's insert

		// Escape name for SQL injection protection
		char szName[MAX_NAME_LENGTH * 2 + 1], szUName[MAX_NAME_LENGTH];
		GetClientName(data, szUName, MAX_NAME_LENGTH);
		SQL_EscapeString(g_hDb, szUName, szName, MAX_NAME_LENGTH);

		// Move required information in datapack
		Handle pack = CreateDataPack();
		WritePackFloat(pack, g_fFinalTime[data]);
		WritePackCell(pack, data);

		//"INSERT INTO ck_playertimes (steamid, mapname, name,runtimepro) VALUES('%s', '%s', '%s', '%f');";
		Format(szQuery, 512, sql_insertPlayerTime, g_szSteamID[data], g_szMapName, szName, g_fFinalTime[data]);
		SQL_TQuery(g_hDb, SQL_UpdateRecordProCallback, szQuery, pack, DBPrio_Low);
	}
}

//
// If latest record was faster than old - Update time
//
public void db_updateRecordPro(int client)
{
	char szUName[MAX_NAME_LENGTH];

	if (IsValidClient(client))
		GetClientName(client, szUName, MAX_NAME_LENGTH);
	else
		return;

	// Also updating name in database, escape string
	char szName[MAX_NAME_LENGTH * 2 + 1];
	SQL_EscapeString(g_hDb, szUName, szName, MAX_NAME_LENGTH * 2 + 1);

	// Packing required information for later
	Handle pack = CreateDataPack();
	WritePackFloat(pack, g_fFinalTime[client]);
	WritePackCell(pack, client);

	char szQuery[1024];
	//"UPDATE ck_playertimes SET name = '%s', runtimepro = '%f' WHERE steamid = '%s' AND mapname = '%s';";
	Format(szQuery, 1024, sql_updateRecordPro, szName, g_fFinalTime[client], g_szSteamID[client], g_szMapName);
	SQL_TQuery(g_hDb, SQL_UpdateRecordProCallback, szQuery, pack, DBPrio_Low);
}


public void SQL_UpdateRecordProCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_UpdateRecordProCallback): %s", error);
		return;
	}

	if (data != INVALID_HANDLE)
	{
		ResetPack(data);
		float time = ReadPackFloat(data);
		int client = ReadPackCell(data);
		CloseHandle(data);

		// Find out how many times are are faster than the players time
		char szQuery[512];
		Format(szQuery, 512, "SELECT count(runtimepro) FROM `ck_playertimes` WHERE `mapname` = '%s' AND `runtimepro` < %f;", g_szMapName, time);
		SQL_TQuery(g_hDb, SQL_UpdateRecordProCallback2, szQuery, client, DBPrio_Low);

	}
}

public void SQL_UpdateRecordProCallback2(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_UpdateRecordProCallback2): %s", error);
		return;
	}
	// Get players rank, 9999999 = error
	int rank = 9999999;
	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		rank = (SQL_FetchInt(hndl, 0)+1);
	}
	g_MapRank[data] = rank;
	MapFinishedMsgs(data);
}

public void db_viewRecord(int client, char szSteamId[32], char szMapName[128])
{
	char szQuery[512];
	// SELECT runtimepro, name FROM ck_playertimes WHERE mapname = '%s' AND steamid = '%s' AND runtimepro > 0.0
	Handle pack = CreateDataPack();
	WritePackString(pack, szMapName);
	WritePackString(pack, szSteamId);
	WritePackCell(pack, client);

	Format(szQuery, 512, sql_selectPersonalRecords, szSteamId, szMapName);
	SQL_TQuery(g_hDb, SQL_ViewRecordCallback, szQuery, pack, DBPrio_Low);
}



public void SQL_ViewRecordCallback(Handle owner, Handle hndl, const char[] error, any pack)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_ViewRecordCallback): %s", error);
		return;
	}

	char szSteamId[32];
	char szMapName[128];

	ResetPack(pack);
	ReadPackString(pack, szMapName, 128);
	ReadPackString(pack, szSteamId, 32);
	int client = ReadPackCell(pack);

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{

		char szName[MAX_NAME_LENGTH];

		SQL_FetchString(hndl, 1, szName, MAX_NAME_LENGTH);
		float runtime = SQL_FetchFloat(hndl, 0);

		Handle pack1 = CreateDataPack();
		WritePackString(pack1, szMapName);
		WritePackString(pack1, szSteamId);
		WritePackString(pack1, szName);
		WritePackCell(pack1, client);
		WritePackFloat(pack1, runtime);

		char szQuery[512];
		Format(szQuery, 512, sql_selectPlayerRankProTime, szSteamId, szMapName, szMapName);
		SQL_TQuery(g_hDb, SQL_ViewRecordCallback2, szQuery, pack1, DBPrio_Low);
	}
	else
	{
		Panel panel = new Panel();
		panel.DrawText("Current map time");
		panel.DrawText(" ");
		panel.DrawText("No record found on this map.");
		panel.DrawItem("exit");
		panel.Send(client, MenuHandler2, 300);
		delete panel;
	}
}

public void SQL_ViewRecordCallback2(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_ViewRecordCallback2): %s", error);
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		char szQuery[512];
		int rank = SQL_GetRowCount(hndl);
		char szMapName[128];
		char szSteamId[32];
		char szName[MAX_NAME_LENGTH];

		WritePackCell(data, rank);
		ResetPack(data);
		ReadPackString(data, szMapName, 128);
		ReadPackString(data, szSteamId, 32);
		ReadPackString(data, szName, MAX_NAME_LENGTH);

		Format(szQuery, 512, sql_selectPlayerProCount, szMapName);
		SQL_TQuery(g_hDb, SQL_ViewRecordCallback3, szQuery, data, DBPrio_Low);
	}
}


public void SQL_ViewRecordCallback3(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_ViewRecordCallback3): %s", error);
		return;
	}

	//if there is a player record
	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		int count1 = SQL_GetRowCount(hndl);
		char szMapName[128];
		char szSteamId[32];
		char szName[MAX_NAME_LENGTH];
		float runtime = ReadPackFloat(data);

		ResetPack(data);
		ReadPackString(data, szMapName, 128);
		ReadPackString(data, szSteamId, 32);
		ReadPackString(data, szName, MAX_NAME_LENGTH);
		int client = ReadPackCell(data);
		int rank = ReadPackCell(data);

		if (runtime != -1.0)
		{
			Panel panel = new Panel();
			char szVrItem[256];
			Format(szVrItem, 256, "Map time of %s", szName);
			panel.DrawText(szVrItem);
			panel.DrawText(" ");

			FormatTimeFloat(client, runtime, 3, szVrItem, sizeof(szVrItem));
			Format(szVrItem, 256, "Time: %s", szVrItem);
			panel.DrawText(szVrItem);

			panel.DrawText("Map time:");
			Format(szVrItem, 256, "Rank: %i of %i", rank, count1);
			panel.DrawText(szVrItem);
			panel.DrawText(" ");

			panel.DrawItem("Exit");
			CloseHandle(data);
			panel.Send(client, RecordPanelHandler, 300);
			CloseHandle(panel);
		}
		else
			if (runtime != 0.000000)
		{
			WritePackCell(data, count1);
			char szQuery[512];
			Format(szQuery, 512, sql_selectPlayerRankProTime, szSteamId, szMapName, szMapName);
			SQL_TQuery(g_hDb, SQL_ViewRecordCallback4, szQuery, data, DBPrio_Low);
		}
	}
}

public void SQL_ViewRecordCallback4(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_ViewRecordCallback4): %s", error);
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{

		char szQuery[512];
		int rankPro = SQL_GetRowCount(hndl);
		char szMapName[128];

		WritePackCell(data, rankPro);
		ResetPack(data);
		ReadPackString(data, szMapName, 128);

		Format(szQuery, 512, sql_selectPlayerProCount, szMapName);
		SQL_TQuery(g_hDb, SQL_ViewRecordCallback5, szQuery, data, DBPrio_Low);
	}
}

public void SQL_ViewRecordCallback5(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_ViewRecordCallback5): %s", error);
		return;
	}

	//if there is a player record
	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		int countPro = SQL_GetRowCount(hndl);
		//retrieve all values
		ResetPack(data);
		char szMapName[128];
		ReadPackString(data, szMapName, 128);
		char szSteamId[32];
		ReadPackString(data, szSteamId, 32);
		char szName[MAX_NAME_LENGTH];
		ReadPackString(data, szName, MAX_NAME_LENGTH);
		int client = ReadPackCell(data);
		float runtime = ReadPackFloat(data);
		int rank = ReadPackCell(data);
		int count1 = ReadPackCell(data);
		int rankPro = ReadPackCell(data);
		if (runtime != -1.0)
		{
			Handle panel = CreatePanel();
			char szVrName[256];
			Format(szVrName, 256, "Map time of %s", szName);
			DrawPanelText(panel, szVrName);
			Format(szVrName, 256, "on %s", g_szMapName);
			DrawPanelText(panel, " ");

			char szVrRank[32];
			char szVrRankPro[32];
			char szVrTimePro[256];
			FormatTimeFloat(client, runtime, 3, szVrTimePro, sizeof(szVrTimePro));
			Format(szVrTimePro, 256, "Time: %s", szVrTimePro);

			Format(szVrRank, 32, "Rank: %i of %i", rank, count1);
			Format(szVrRankPro, 32, "Rank: %i of %i", rankPro, countPro);

			DrawPanelText(panel, szVrRank);
			DrawPanelText(panel, " ");
			DrawPanelText(panel, "Time:");
			DrawPanelText(panel, szVrTimePro);
			DrawPanelText(panel, szVrRankPro);
			DrawPanelText(panel, " ");
			DrawPanelItem(panel, "exit");
			SendPanelToClient(panel, client, RecordPanelHandler, 300);
			CloseHandle(panel);
		}
	}
	CloseHandle(data);
}

public void db_viewAllRecords(int client, char szSteamId[32])
{
	//"SELECT db1.name, db2.steamid, db2.mapname, db2.runtimepro as overall, db1.steamid FROM ck_playertimes as db2 INNER JOIN ck_playerrank as db1 on db2.steamid = db1.steamid WHERE db2.steamid = '%s' AND db2.runtimepro > -1.0 ORDER BY mapname ASC;";

	char szQuery[1024];
	Format(szQuery, 1024, sql_selectPersonalAllRecords, szSteamId, szSteamId);
	if ((StrContains(szSteamId, "STEAM_") != -1))
		SQL_TQuery(g_hDb, SQL_ViewAllRecordsCallback, szQuery, client, DBPrio_Low);
	else
		if (IsClientInGame(client))
		PrintToChat(client, "[%cSurf Timer%c] Invalid SteamID found.", RED, WHITE);
	ProfileMenu(client, -1);
}


public void SQL_ViewAllRecordsCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_ViewAllRecordsCallback): %s", error);
		return;
	}

	int bHeader = false;
	char szUncMaps[1024];
	int mapcount = 0;
	char szName[MAX_NAME_LENGTH];
	char szSteamId[32];
	if (SQL_HasResultSet(hndl))
	{
		float time;
		char szMapName[128];
		char szMapName2[128];
		char szQuery[1024];
		Format(szUncMaps, sizeof(szUncMaps), "");
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, szName, MAX_NAME_LENGTH);
			SQL_FetchString(hndl, 1, szSteamId, MAX_NAME_LENGTH);
			SQL_FetchString(hndl, 2, szMapName, 128);

			time = SQL_FetchFloat(hndl, 3);

			int mapfound = false;

			//map in rotation?
			for (int i = 0; i < GetArraySize(g_MapList); i++)
			{
				GetArrayString(g_MapList, i, szMapName2, sizeof(szMapName2));
				if (StrEqual(szMapName2, szMapName, false))
				{
					if (!bHeader)
					{
						PrintToConsole(data, " ");
						PrintToConsole(data, "-------------");
						PrintToConsole(data, "Finished Maps");
						PrintToConsole(data, "Player: %s", szName);
						PrintToConsole(data, "SteamID: %s", szSteamId);
						PrintToConsole(data, "-------------");
						PrintToConsole(data, " ");
						bHeader = true;
						PrintToChat(data, "%t", "ConsoleOutput", LIMEGREEN, WHITE);
					}
					Handle pack = CreateDataPack();
					WritePackString(pack, szName);
					WritePackString(pack, szSteamId);
					WritePackString(pack, szMapName);
					WritePackFloat(pack, time);
					WritePackCell(pack, data);

					Format(szQuery, 1024, sql_selectPlayerRankProTime, szSteamId, szMapName, szMapName);
					SQL_TQuery(g_hDb, SQL_ViewAllRecordsCallback2, szQuery, pack, DBPrio_Low);
					mapfound = true;
					continue;
				}
			}
			if (!mapfound)
			{
				mapcount++;
				if (!mapfound && mapcount == 1)
				{
					Format(szUncMaps, sizeof(szUncMaps), "%s", szMapName);
				}
				else
				{
					if (!mapfound && mapcount > 1)
					{
						Format(szUncMaps, sizeof(szUncMaps), "%s, %s", szUncMaps, szMapName);
					}
				}
			}
		}
	}
	if (!StrEqual(szUncMaps, ""))
	{
		if (!bHeader)
		{
			PrintToChat(data, "%t", "ConsoleOutput", LIMEGREEN, WHITE);
			PrintToConsole(data, " ");
			PrintToConsole(data, "-------------");
			PrintToConsole(data, "Finished Maps");
			PrintToConsole(data, "Player: %s", szName);
			PrintToConsole(data, "SteamID: %s", szSteamId);
			PrintToConsole(data, "-------------");
			PrintToConsole(data, " ");
		}
		PrintToConsole(data, "Times on maps which are not in the mapcycle.txt (Records still count but you don't get points): %s", szUncMaps);
	}
	if (!bHeader && StrEqual(szUncMaps, ""))
	{
		ProfileMenu(data, -1);
		PrintToChat(data, "%t", "PlayerHasNoMapRecords", LIMEGREEN, WHITE, g_szProfileName[data]);
	}
}

public void SQL_ViewAllRecordsCallback2(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_ViewAllRecordsCallback2): %s", error);
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		char szQuery[512];
		char szName[MAX_NAME_LENGTH];
		char szSteamId[32];
		char szMapName[128];

		int rank = SQL_GetRowCount(hndl);
		WritePackCell(data, rank);
		ResetPack(data);
		ReadPackString(data, szName, MAX_NAME_LENGTH);
		ReadPackString(data, szSteamId, 32);
		ReadPackString(data, szMapName, 128);

		Format(szQuery, 512, sql_selectPlayerProCount, szMapName);
		SQL_TQuery(g_hDb, SQL_ViewAllRecordsCallback3, szQuery, data, DBPrio_Low);
	}
}

public void SQL_ViewAllRecordsCallback3(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_ViewAllRecordsCallback3): %s", error);
		return;
	}

	//if there is a player record
	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		int count = SQL_GetRowCount(hndl);
		char szTime[32];
		char szMapName[128];
		char szSteamId[32];
		char szName[MAX_NAME_LENGTH];

		ResetPack(data);
		ReadPackString(data, szName, MAX_NAME_LENGTH);
		ReadPackString(data, szSteamId, 32);
		ReadPackString(data, szMapName, 128);
		float time = ReadPackFloat(data);
		int client = ReadPackCell(data);
		int rank = ReadPackCell(data);
		CloseHandle(data);

		FormatTimeFloat(client, time, 3, szTime, sizeof(szTime));
		if (IsValidClient(client))
			PrintToConsole(client, "%s, Time: %s, Rank: %i/%i", szMapName, szTime, rank, count);
	}
}


public void db_selectPlayer(int client)
{
	char szQuery[255];
	if (!IsValidClient(client))
		return;
	Format(szQuery, 255, sql_selectPlayer, g_szSteamID[client], g_szMapName);
	SQL_TQuery(g_hDb, SQL_SelectPlayerCallback, szQuery, client, DBPrio_Low);
}

public void SQL_SelectPlayerCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_SelectPlayerCallback): %s", error);
		return;
	}

	if (!SQL_HasResultSet(hndl) && !SQL_FetchRow(hndl) && !IsValidClient(data))
		db_insertPlayer(data);
}

public void db_insertPlayer(int client)
{
	char szQuery[255];
	char szUName[MAX_NAME_LENGTH];
	if (IsValidClient(client))
	{
		GetClientName(client, szUName, MAX_NAME_LENGTH);
	}
	else
		return;
	char szName[MAX_NAME_LENGTH * 2 + 1];
	SQL_EscapeString(g_hDb, szUName, szName, MAX_NAME_LENGTH * 2 + 1);
	Format(szQuery, 255, sql_insertPlayer, g_szSteamID[client], g_szMapName, szName);
	SQL_TQuery(g_hDb, SQL_InsertPlayerCallBack, szQuery, client, DBPrio_Low);
}

//
// Getting player settings starts here
//
public void db_viewPersonalRecords(int client, char szSteamId[32], char szMapName[128])
{
	char szQuery[1024];
	Format(szQuery, 1024, "SELECT runtimepro FROM ck_playertimes WHERE steamid = '%s' AND mapname ='%s' AND runtimepro > 0.0;", szSteamId, szMapName);
	SQL_TQuery(g_hDb, SQL_selectPersonalRecordsCallback, szQuery, client, DBPrio_Low);
}


public void SQL_selectPersonalRecordsCallback(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_selectPersonalRecordsCallback): %s", error);
		if (!g_bSettingsLoaded[client])
			db_viewPersonalBonusRecords(client, g_szSteamID[client]);
		return;
	}

	g_fPersonalRecord[client] = 0.0;
	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		g_fPersonalRecord[client] = SQL_FetchFloat(hndl, 0);

		if (g_fPersonalRecord[client] > 0.0)
		{
			FormatTimeFloat(client, g_fPersonalRecord[client], 3, g_szPersonalRecord[client], 64);
			// Time found, get rank in current map
			db_viewMapRankPro(client);
			return;
		}
		else
		{
			Format(g_szPersonalRecord[client], 64, "NONE");
			g_fPersonalRecord[client] = 0.0;
		}
	}
	if (!g_bSettingsLoaded[client])
		db_viewPersonalBonusRecords(client, g_szSteamID[client]);
	return;
}