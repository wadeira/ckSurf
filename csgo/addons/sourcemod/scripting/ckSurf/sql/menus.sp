

public void db_selectTopProRecordHolders(int client)
{
	char szQuery[512];
	Format(szQuery, 512, sql_selectMapRecordHolders);
	SQL_TQuery(g_hDb, db_sql_selectMapRecordHoldersCallback, szQuery, client);
}

public void db_sql_selectMapRecordHoldersCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (db_sql_selectMapRecordHoldersCallback): %s", error);
		return;
	}

	char szSteamID[32];
	char szRecords[64];
	char szQuery[256];
	int records = 0;
	if (SQL_HasResultSet(hndl))
	{
		int i = SQL_GetRowCount(hndl);
		int x = i;
		g_menuTopSurfersMenu[data] = new Menu(TopProHoldersHandler1);
		g_menuTopSurfersMenu[data].SetTitle("Top 5 Pro Surfers\n#   Records       Player");
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, szSteamID, 32);
			records = SQL_FetchInt(hndl, 1);
			if (records > 9)
				Format(szRecords, 64, "%i", records);
			else
				Format(szRecords, 64, "%i  ", records);

			Handle pack = CreateDataPack();
			WritePackCell(pack, data);
			WritePackString(pack, szRecords);
			WritePackCell(pack, i);
			WritePackString(pack, szSteamID);
			Format(szQuery, 256, sql_selectRankedPlayer, szSteamID);
			SQL_TQuery(g_hDb, db_sql_selectMapRecordHoldersCallback2, szQuery, pack);
			i--;
		}
		if (x == 0)
		{
			PrintToChat(data, "%t", "NoRecordTop", MOSSGREEN, WHITE);
			ckTopMenu(data);
		}
	}
	else
	{
		PrintToChat(data, "%t", "NoRecordTop", MOSSGREEN, WHITE);
		ckTopMenu(data);
	}
}

public void db_sql_selectMapRecordHoldersCallback2(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (db_sql_selectMapRecordHoldersCallback2): %s", error);
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		char szName[MAX_NAME_LENGTH];
		char szSteamID[32];
		char szRecords[64];
		char szValue[128];

		ResetPack(data);
		int client = ReadPackCell(data);
		ReadPackString(data, szRecords, 64);
		int count = ReadPackCell(data);
		ReadPackString(data, szSteamID, 32);
		CloseHandle(data);

		SQL_FetchString(hndl, 1, szName, MAX_NAME_LENGTH);
		Format(szValue, 128, "      %s       »  %s", szRecords, szName);
		g_menuTopSurfersMenu[client].AddItem(szSteamID, szValue, ITEMDRAW_DEFAULT);
		if (count == 1)
		{
			g_menuTopSurfersMenu[client].OptionFlags = MENUFLAG_BUTTON_EXIT;
			g_menuTopSurfersMenu[client].Display(client, MENU_TIME_FOREVER);
		}
	}
}

public void db_selectTopPlayers(int client)
{
	char szQuery[128];
	Format(szQuery, 128, sql_selectTopPlayers);
	SQL_TQuery(g_hDb, db_selectTop100PlayersCallback, szQuery, client, DBPrio_Low);
}

public void db_selectTop100PlayersCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (db_selectTop100PlayersCallback): %s", error);
		return;
	}

	char szValue[128];
	char szName[64];
	char szRank[16];
	char szSteamID[32];
	char szPerc[16];
	int points;
	Menu menu = new Menu(TopPlayersMenuHandler1);
	menu.SetTitle("Top 100 Players\n    Rank   Points       Maps            Player");
	menu.Pagination = 5;
	if (SQL_HasResultSet(hndl))
	{
		int i = 1;
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, szName, 64);
			if (i == 100)
				Format(szRank, 16, "[%i.]", i);
			else
				if (i < 10)
					Format(szRank, 16, "[0%i.]  ", i);
				else
					Format(szRank, 16, "[%i.]  ", i);

			points = SQL_FetchInt(hndl, 1);
			int pro = SQL_FetchInt(hndl, 2);
			SQL_FetchString(hndl, 3, szSteamID, 32);
			float fperc;
			fperc = (float(pro) / (float(g_pr_MapCount))) * 100.0;

			if (fperc < 10.0)
				Format(szPerc, 16, "  %.1f%c  ", fperc, PERCENT);
			else
				if (fperc == 100.0)
					Format(szPerc, 16, "100.0%c", PERCENT);
				else
					if (fperc > 100.0) //player profile not refreshed after removing maps
						Format(szPerc, 16, "100.0%c", PERCENT);
					else
						Format(szPerc, 16, "%.1f%c  ", fperc, PERCENT);

			if (points < 10)
				Format(szValue, 128, "%s      %ip       %s     » %s", szRank, points, szPerc, szName);
			else
				if (points < 100)
					Format(szValue, 128, "%s     %ip       %s     » %s", szRank, points, szPerc, szName);
				else
					if (points < 1000)
						Format(szValue, 128, "%s   %ip       %s     » %s", szRank, points, szPerc, szName);
					else
						if (points < 10000)
							Format(szValue, 128, "%s %ip       %s     » %s", szRank, points, szPerc, szName);
						else
							if (points < 100000)
								Format(szValue, 128, "%s %ip     %s     » %s", szRank, points, szPerc, szName);
							else
								Format(szValue, 128, "%s %ip   %s     » %s", szRank, points, szPerc, szName);

			menu.AddItem(szSteamID, szValue, ITEMDRAW_DEFAULT);
			i++;
		}
		if (i == 1)
		{
			PrintToChat(data, "%t", "NoPlayerTop", MOSSGREEN, WHITE);
		}
		else
		{
			menu.OptionFlags = MENUFLAG_BUTTON_EXIT;
			menu.Display(data, MENU_TIME_FOREVER);
		}
	}
	else
	{
		PrintToChat(data, "%t", "NoPlayerTop", MOSSGREEN, WHITE);
	}
}

public void SQL_ViewPlayerProfile2Callback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_ViewPlayerProfile2Callback): %s", error);
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 1, g_szProfileSteamId[data], 32);
		db_viewPlayerRank(data, g_szProfileSteamId[data]);
	}
	else
		if (IsClientInGame(data))
		PrintToChat(data, "%t", "PlayerNotFound", MOSSGREEN, WHITE, g_szProfileName[data]);
}

public int ProfileMenuHandler(Handle menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		switch (item)
		{
			case 0:db_viewRecord(client, g_szProfileSteamId[client], g_szMapName);
			case 1:db_viewChallengeHistory(client, g_szProfileSteamId[client]);
			case 2:
			{
				db_viewAllRecords(client, g_szProfileSteamId[client]);
			}
			case 3:
			{
				if (g_bRecalcRankInProgess[client])
				{
					PrintToChat(client, "[%cSurf Timer%c] %cRecalculation in progress. Please wait!", MOSSGREEN, WHITE, GRAY);
				}
				else
				{

					g_bRecalcRankInProgess[client] = true;
					PrintToChat(client, "%t", "Rc_PlayerRankStart", MOSSGREEN, WHITE, GRAY);
					CalculatePlayerRank(client);
				}
			}
		}
	}
	else
		if (action == MenuAction_Cancel)
		{
			if (1 <= client <= MaxClients && IsValidClient(client))
			{
				switch (g_MenuLevel[client])
				{
					case 0:db_selectTopPlayers(client);
					case 3:db_selectTopChallengers(client);
					case 9:db_selectProSurfers(client);
					case 11:db_selectTopProRecordHolders(client);

				}
				if (g_MenuLevel[client] < 0)
				{
					if (g_bSelectProfile[client])
						ProfileMenu(client, 0);
				}
			}
		}
		else
		if (action == MenuAction_End)
		{
			CloseHandle(menu);
		}
}

public int TopPlayersMenuHandler1(Handle menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, item, info, sizeof(info));
		g_MenuLevel[client] = 0;
		db_viewPlayerRank(client, info);
	}
	if (action == MenuAction_Cancel)
	{
		ckTopMenu(client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public int MapMenuHandler1(Handle menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, item, info, sizeof(info));
		g_MenuLevel[client] = 1;
		db_viewPlayerRank(client, info);
	}
	if (action == MenuAction_Cancel)
	{
		ckTopMenu(client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public int MapTopMenuHandler2(Handle menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, item, info, sizeof(info));
		g_MenuLevel[client] = 1;
		db_viewPlayerRank(client, info);
	}
}

public void MapMenuHandler2(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		g_MenuLevel[param1] = 8;
		db_viewPlayerRank(param1, info);
	}
	if (action == MenuAction_Cancel)
	{
		ckTopMenu(param1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}


public int MapMenuHandler3(Handle menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, item, info, sizeof(info));
		g_MenuLevel[client] = 9;
		db_viewPlayerRank(client, info);
	}
	if (action == MenuAction_Cancel)
	{
		ckTopMenu(client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}


public int MenuHandler2(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Cancel || action == MenuAction_Select)
	{
		ProfileMenu(client, -1);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public int RecordPanelHandler(Handle menu, MenuAction action, int client, int item)
{
	if (action == MenuAction_Select)
	{
		ProfileMenu(client, -1);
	}
}

public void RecordPanelHandler2(Handle menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		ckTopMenu(param1);
	}
}


public void db_viewStageRecords(int client, int stage)
{

	char query[256];
	Format(query, sizeof(query), sql_viewStageTop, stage, g_szMapName);
	SQL_TQuery(g_hDb, sql_viewStageRecordsCallback, query, client, DBPrio_Low);
}

public void sql_viewStageRecordsCallback(Handle owner, Handle hndl, const char[] error, any data)
{

	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_viewStageRecordsCallback): %s", error);
		return;
	}

	int client = data;

	if (SQL_HasResultSet(hndl))
	{
		Menu menu = new Menu(ViewStageRecordsMenuCallback);
		menu.SetTitle("Stage records:\n    Rank   Time              Player");
		int rank = 1;

		while(SQL_FetchRow(hndl))
		{
			char name[32], steamid[32];
			SQL_FetchString(hndl, 0, name, sizeof(name));
			float runtime = SQL_FetchFloat(hndl, 1);
			SQL_FetchString(hndl, 2, steamid, sizeof(steamid));

			char runtime_str[32];
			FormatTimeFloat(client, runtime, 5, runtime_str, sizeof(runtime_str));

			char display[128];

			if (rank < 10)
				Format(display, sizeof(display), "[0%i.] %s    » %s", rank, runtime_str, name);
			else
				Format(display, sizeof(display), "[%i.] %s    » %s", rank, runtime_str, name);

			menu.AddItem(steamid, display);

			rank++;
		}

		menu.Display(client, 60);
	}
}

public int ViewStageRecordsMenuCallback(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		g_MenuLevel[param1] = -1;
		db_viewPlayerRank(param1, info);
	}
}