public void db_checkPlayersTitles(int client)
{
	for (int i = 0; i < TITLE_COUNT; i++)
		g_bAdminFlagTitlesTemp[client][i] = false;

	char szQuery[512];
	Format(szQuery, 512, sql_selectPlayerFlags, g_szAdminSelectedSteamID[client]);

	switch (g_iAdminEditingType[client])
	{
		case 1:SQL_TQuery(g_hDb, SQL_checkPlayerFlagsCallback, szQuery, client, DBPrio_Low);
		case 3:SQL_TQuery(g_hDb, SQL_checkPlayerFlagsCallback2, szQuery, client, DBPrio_Low);
	}
}

public void SQL_checkPlayerFlagsCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_checkPlayerFlagsCallback): %s ", error);
		return;
	}

	Menu titleMenu = CreateMenu(Handler_TitleMenu);
	char id[8], menuItem[152];

	if (IsValidClient(g_iAdminSelectedClient[data]))
	{
		char szName[MAX_NAME_LENGTH];
		GetClientName(g_iAdminSelectedClient[data], szName, MAX_NAME_LENGTH);
		SetMenuTitle(titleMenu, "Select title to give to %s:", szName);
	}
	else
	{
		SetMenuTitle(titleMenu, "Select which title to give:");
	}


	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		g_bAdminSelectedHasFlag[data] = true;
		for (int i = 0; i < TITLE_COUNT; i++)
		{
			if (!StrEqual(g_szflagTitle[i], ""))
			{
				Format(id, 8, "%i", i);
				if (SQL_FetchInt(hndl, i) > 0)
				{
					g_bAdminFlagTitlesTemp[data][i] = true;
					Format(menuItem, 152, "[ON] %s", g_szflagTitle[i]);
					AddMenuItem(titleMenu, id, menuItem);
				}
				else
				{
					Format(menuItem, 152, "[OFF] %s", g_szflagTitle[i]);
					AddMenuItem(titleMenu, id, menuItem);
				}
			}
		}
	}
	else
	{
		g_bAdminSelectedHasFlag[data] = false;
		for (int i = 0; i < TITLE_COUNT; i++)
		{
			if (!StrEqual(g_szflagTitle[i], ""))
			{
				Format(id, 8, "%i", i);
				Format(menuItem, 152, "[OFF] %s", g_szflagTitle[i]);
				AddMenuItem(titleMenu, id, menuItem);
			}
		}
	}

	SetMenuExitButton(titleMenu, true);
	DisplayMenu(titleMenu, data, MENU_TIME_FOREVER);
}

public void SQL_checkPlayerFlagsCallback2(Handle owner, Handle hndl, const char[] error, any data)
{

	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_checkPlayerFlagsCallback2): %s ", error);
		return;
	}

	Menu titleMenu = CreateMenu(Handler_TitleMenu);
	char id[2], menuItem[152];

	if (IsValidClient(g_iAdminSelectedClient[data]))
	{
		char szName[MAX_NAME_LENGTH];
		GetClientName(g_iAdminSelectedClient[data], szName, MAX_NAME_LENGTH);
		SetMenuTitle(titleMenu, "Which title do you want to remove from %s:", szName);
	}
	else
	{
		SetMenuTitle(titleMenu, "Which title do you wan to remove? :");
	}


	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		g_bAdminSelectedHasFlag[data] = true;
		for (int i = 0; i < TITLE_COUNT; i++)
		{
			if (!StrEqual(g_szflagTitle_Colored[i], ""))
			{
				Format(id, 2, "%i", i);
				if (SQL_FetchInt(hndl, i) > 0)
				{
					g_bAdminFlagTitlesTemp[data][i] = true;
					Format(menuItem, 152, "[ON] %s", g_szflagTitle_Colored[i]);
					AddMenuItem(titleMenu, id, menuItem);
				}
			}
		}
	}
	else
	{
		AddMenuItem(titleMenu, "-1", "The chosen player doesn't have any titles.");
	}

	SetMenuExitButton(titleMenu, true);
	DisplayMenu(titleMenu, data, MENU_TIME_FOREVER);
}

public void sql_disableTitleFromAllbyIndex(int index)
{
	// Do a transaction
	Transaction h_disableUnusedTitles = SQL_CreateTransaction();
	char query[248];
	for (int i = index; i < TITLE_COUNT; i++)
	{
		switch (i)
		{
			case 0:
			{
				SQL_AddQuery(h_disableUnusedTitles, "UPDATE ck_playertitles SET vip = 0;");
				SQL_AddQuery(h_disableUnusedTitles, "UPDATE ck_playertitles SET inuse = -1 WHERE inuse = 0;");
			}
			case 1:
			{
				SQL_AddQuery(h_disableUnusedTitles, "UPDATE ck_playertitles SET mapper = 0;");
				SQL_AddQuery(h_disableUnusedTitles, "UPDATE ck_playertitles SET inuse = -1 WHERE inuse = 1;");
			}
			case 2:
			{
				SQL_AddQuery(h_disableUnusedTitles, "UPDATE ck_playertitles SET teacher = 0;");
				SQL_AddQuery(h_disableUnusedTitles, "UPDATE ck_playertitles SET inuse = -1 WHERE inuse = 2;");
			}
			default:
			{
				if (i > 2 && i < TITLE_COUNT)
				{
					Format(query, 248, "UPDATE ck_playertitles SET custom%i = 0;", (i - 2));
					SQL_AddQuery(h_disableUnusedTitles, query);
					Format(query, 248, "UPDATE ck_playertitles SET inuse = -1 WHERE inuse = %i;", i);
					SQL_AddQuery(h_disableUnusedTitles, query);
				}
			}
		}
	}
	SQL_ExecuteTransaction(g_hDb, h_disableUnusedTitles, _, _);
}


public void db_viewPersonalFlags(int client, char SteamID[32])
{
	char szQuery[728];
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, SteamID);
	Format(szQuery, 728, sql_selectPlayerFlags, SteamID);
	SQL_TQuery(g_hDb, SQL_PersonalFlagCallback, szQuery, pack, DBPrio_Low);
}

public void SQL_PersonalFlagCallback(Handle owner, Handle hndl, const char[] error, any pack)
{
	ResetPack(pack);
	int client = ReadPackCell(pack);
	char szSteamID[32];
	ReadPackString(pack, szSteamID, 32);
	CloseHandle(pack);

	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_PersonalFlagCallback): %s ", error);
		if (!g_bSettingsLoaded[client])
			db_viewCheckpoints(client, szSteamID, g_szMapName);
		return;
	}


	for (int i = 0; i < TITLE_COUNT; i++)
		g_bflagTitles[client][i] = false;

	g_bHasTitle[client] = false;
	bool hasTitleRow;

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		hasTitleRow = true;
		for (int i = 0; i < TITLE_COUNT; i++)
		{
			if (SQL_FetchInt(hndl, i) > 0)
			{
				g_bHasTitle[client] = true;
				g_bflagTitles[client][i] = true;
			}
		}
		g_iTitleInUse[client] = SQL_FetchInt(hndl, 23);
	}

	if (IsValidClient(client) && g_bAutoVIPFlag)
	{
		if ((GetUserFlagBits(client) & g_AutoVIPFlag))
		{
			if (!g_bHasTitle[client])
				db_updateAdminVIP(client, szSteamID, hasTitleRow);
			else
				if (!g_bflagTitles[client][0])
				db_updateAdminVIP(client, szSteamID, hasTitleRow);
		}
	}

	Array_Copy(g_bflagTitles[client], g_bflagTitles_orig[client], TITLE_COUNT);

	if (!g_bSettingsLoaded[client])
		db_viewCheckpoints(client, szSteamID, g_szMapName);

}

public void db_updateAdminVIP(int client, char SteamID[32], bool hasTitleRow)
{
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, SteamID);

	char szQuery[420];
	if (!hasTitleRow)
		Format(szQuery, 420, "INSERT INTO `ck_playertitles`(`steamid`, `vip`, `mapper`, `teacher`, `custom1`, `custom2`, `custom3`, `custom4`, `custom5`, `custom6`, `custom7`, `custom8`, `custom9`, `custom10`, `custom11`, `custom12`, `custom13`, `custom14`, `custom15`, `custom16`, `custom17`, `custom18`, `custom19`, `custom20`, `inuse`) VALUES ('%s',1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);", SteamID);
	else
		Format(szQuery, 420, "UPDATE `ck_playertitles` SET `vip`= 1, `inuse`= 0 WHERE `steamid` = '%s'", SteamID);
	SQL_TQuery(g_hDb, db_updateVIPAdminCallback, szQuery, pack, DBPrio_Low);
}

public void db_updateVIPAdminCallback(Handle owner, Handle hndl, const char[] error, any pack)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (db_updateVIPAdminCallback): %s ", error);
		return;
	}

	ResetPack(pack);
	int client = ReadPackCell(pack);
	char szSteamID[32];
	ReadPackString(pack, szSteamID, 32);
	CloseHandle(pack);

	db_checkChangesInTitle(client, szSteamID);
}




public void db_checkChangesInTitle(int client, char SteamID[32])
{
	char szQuery[728];
	Format(szQuery, 728, sql_selectPlayerFlags, SteamID);

	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, SteamID);

	SQL_TQuery(g_hDb, db_checkChangesInTitleCallback, szQuery, pack, DBPrio_Low);
}

public void db_checkChangesInTitleCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (db_checkChangesInTitleCallback): %s ", error);
		return;
	}


	ResetPack(data);
	int client = ReadPackCell(data);
	char steamid[32];
	ReadPackString(data, steamid, 32);
	CloseHandle(data);

	if (IsValidClient(client))
	{
		for (int i = 0; i < TITLE_COUNT; i++)
			g_bflagTitles[client][i] = false;

		g_bHasTitle[client] = false;

		if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		{
			for (int i = 0; i < TITLE_COUNT; i++)
				if (SQL_FetchInt(hndl, i) > 0)
				{
					g_bHasTitle[client] = true;
					g_bflagTitles[client][i] = true;
				}

			//g_iTitleInUse[client] = SQL_FetchInt(hndl, 23);
		}
	}
	else
	{
		db_updatePlayerTitleInUse(-1, steamid);
		return;
	}

	for (int i = 0; i < TITLE_COUNT; i++)
	{
		if (g_bflagTitles[client][i] != g_bflagTitles_orig[client][i])
		{
			if (g_bflagTitles[client][i])
				ClientCommand(client, "play commander\\commander_comment_0%i", GetRandomInt(1, 9));
			else
				ClientCommand(client, "play commander\\commander_comment_%i", GetRandomInt(20, 23));
			switch (i)
			{
				case 0:
				{
					g_bflagTitles_orig[client][i] = g_bflagTitles[client][i];
					if (g_bflagTitles[client][i])
						PrintToChat(client, "[%cSurf Timer%c] Congratulations! You have gained the VIP privileges!", MOSSGREEN, WHITE);
					else
					{
						if (g_iTitleInUse[client] == i)
						{
							g_iTitleInUse[client] = -1;
							db_updatePlayerTitleInUse(-1, steamid);
						}

						g_bTrailOn[client] = false;
						PrintToChat(client, "[%cSurf Timer%c] You have lost your VIP privileges!", MOSSGREEN, WHITE);
					}
					break;
				}
				default:
				{

					g_bflagTitles_orig[client][i] = g_bflagTitles[client][i];
					if (g_bflagTitles[client][i])
						PrintToChat(client, "[%cSurf Timer%c] Congratulations! You have gained the custom title \"%s\"!", MOSSGREEN, WHITE, g_szflagTitle_Colored[i]);
					else
					{
						if (g_iTitleInUse[client] == i)
						{
							g_iTitleInUse[client] = -1;
							db_updatePlayerTitleInUse(-1, steamid);
						}

						PrintToChat(client, "[%cSurf Timer%c] You have lost your custom title \"%s\"!", MOSSGREEN, WHITE, g_szflagTitle_Colored[i]);
					}
					break;
				}
			}
		}
	}
}

public void db_insertPlayerTitles(int client, int titleID)
{
	char szQuery[1024];
	Format(szQuery, 1024, sql_insertPlayerFlags, g_szAdminSelectedSteamID[client], BooltoInt(g_bAdminFlagTitlesTemp[client][0]), BooltoInt(g_bAdminFlagTitlesTemp[client][1]), BooltoInt(g_bAdminFlagTitlesTemp[client][2]), BooltoInt(g_bAdminFlagTitlesTemp[client][3]), BooltoInt(g_bAdminFlagTitlesTemp[client][4]), BooltoInt(g_bAdminFlagTitlesTemp[client][5]), BooltoInt(g_bAdminFlagTitlesTemp[client][6]), BooltoInt(g_bAdminFlagTitlesTemp[client][7]), BooltoInt(g_bAdminFlagTitlesTemp[client][8]), BooltoInt(g_bAdminFlagTitlesTemp[client][9]), BooltoInt(g_bAdminFlagTitlesTemp[client][10]), BooltoInt(g_bAdminFlagTitlesTemp[client][11]), BooltoInt(g_bAdminFlagTitlesTemp[client][12]), BooltoInt(g_bAdminFlagTitlesTemp[client][13]), BooltoInt(g_bAdminFlagTitlesTemp[client][14]), BooltoInt(g_bAdminFlagTitlesTemp[client][15]), BooltoInt(g_bAdminFlagTitlesTemp[client][16]), BooltoInt(g_bAdminFlagTitlesTemp[client][17]), BooltoInt(g_bAdminFlagTitlesTemp[client][18]), BooltoInt(g_bAdminFlagTitlesTemp[client][19]), BooltoInt(g_bAdminFlagTitlesTemp[client][20]), BooltoInt(g_bAdminFlagTitlesTemp[client][21]), BooltoInt(g_bAdminFlagTitlesTemp[client][22]), titleID);
	SQL_TQuery(g_hDb, SQL_insertFlagCallback, szQuery, client, DBPrio_Low);
}

public void SQL_insertFlagCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_insertFlagCallback): %s ", error);
		return;
	}

	if (IsValidClient(data))
		PrintToChat(data, "[%cSurf Timer%c] Succesfully granted title to a player", MOSSGREEN, WHITE);

	db_checkChangesInTitle(g_iAdminSelectedClient[data], g_szAdminSelectedSteamID[data]);
}

public void db_updatePlayerTitles(int client, int titleID)
{
	char szQuery[1024];
	Format(szQuery, 1024, sql_updatePlayerFlags, g_bAdminFlagTitlesTemp[client][0], g_bAdminFlagTitlesTemp[client][1], g_bAdminFlagTitlesTemp[client][2], g_bAdminFlagTitlesTemp[client][3], g_bAdminFlagTitlesTemp[client][4], g_bAdminFlagTitlesTemp[client][5], g_bAdminFlagTitlesTemp[client][6], g_bAdminFlagTitlesTemp[client][7], g_bAdminFlagTitlesTemp[client][8], g_bAdminFlagTitlesTemp[client][9], g_bAdminFlagTitlesTemp[client][10], g_bAdminFlagTitlesTemp[client][11], g_bAdminFlagTitlesTemp[client][12], g_bAdminFlagTitlesTemp[client][13], g_bAdminFlagTitlesTemp[client][14], g_bAdminFlagTitlesTemp[client][15], g_bAdminFlagTitlesTemp[client][16], g_bAdminFlagTitlesTemp[client][17], g_bAdminFlagTitlesTemp[client][18], g_bAdminFlagTitlesTemp[client][19], g_bAdminFlagTitlesTemp[client][20], g_bAdminFlagTitlesTemp[client][21], g_bAdminFlagTitlesTemp[client][22], titleID, g_szAdminSelectedSteamID[client]);
	SQL_TQuery(g_hDb, SQL_updatePlayerFlagsCallback, szQuery, client, DBPrio_Low);
}

public void SQL_updatePlayerFlagsCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_updatePlayerFlagsCallback): %s ", error);
		return;
	}

	if (IsValidClient(data))
		PrintToChat(data, "[%cSurf Timer%c] Succesfully updated player's titles", MOSSGREEN, WHITE);

	if (g_iAdminSelectedClient[data] != -1)
		db_checkChangesInTitle(g_iAdminSelectedClient[data], g_szAdminSelectedSteamID[data]);
}

public void db_updatePlayerTitleInUse(int inUse, char szSteamId[32])
{
	char szQuery[512];
	Format(szQuery, 512, sql_updatePlayerFlagsInUse, inUse, szSteamId);
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, -1, DBPrio_Low);
}

public void db_deletePlayerTitles(int client)
{
	if (IsValidClient(g_iAdminSelectedClient[client]))
	{
		GetClientAuthId(g_iAdminSelectedClient[client], AuthId_Steam2, g_szAdminSelectedSteamID[client], MAX_NAME_LENGTH, true);
	}
	else if (StrEqual(g_szAdminSelectedSteamID[client], ""))
		return;

	char szQuery[258];
	Format(szQuery, 258, sql_deletePlayerFlags, g_szAdminSelectedSteamID[client]);
	SQL_TQuery(g_hDb, SQL_deletePlayerTitlesCallback, szQuery, client, DBPrio_Low);
}

public void SQL_deletePlayerTitlesCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_deletePlayerTitlesCallback): %s ", error);
		return;
	}

	PrintToChat(data, "[%cSurf Timer%c] Succesfully deleted player's titles.", MOSSGREEN, WHITE);
	db_checkChangesInTitle(g_iAdminSelectedClient[data], g_szAdminSelectedSteamID[data]);
}