public void db_selectTopChallengers(int client)
{
	char szQuery[128];
	Format(szQuery, 128, sql_selectTopChallengers);
	SQL_TQuery(g_hDb, sql_selectTopChallengersCallback, szQuery, client, DBPrio_Low);
}

public void sql_selectTopChallengersCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_selectTopChallengersCallback): %s", error);
		return;
	}
	char szValue[128];
	char szName[MAX_NAME_LENGTH];
	char szWinRatio[32];
	char szSteamID[32];
	char szPointsRatio[32];
	int winratio;
	int pointsratio;
	Menu topChallengersMenu = new Menu(TopChallengeHandler1);
	SetMenuPagination(topChallengersMenu, 5);
	topChallengersMenu.SetTitle("Top 5 Challengers\n#   W/L P.-Ratio    Player (W/L ratio)");
	if (SQL_HasResultSet(hndl))
	{
		int i = 1;
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, szName, MAX_NAME_LENGTH);
			winratio = SQL_FetchInt(hndl, 1);
			if (!GetConVarBool(g_hChallengePoints))
				pointsratio = 0;
			else
				pointsratio = SQL_FetchInt(hndl, 2);
			SQL_FetchString(hndl, 3, szSteamID, 32);
			if (winratio >= 0)
				Format(szWinRatio, 32, "+%i", winratio);
			else
				Format(szWinRatio, 32, "%i", winratio);

			if (pointsratio >= 0)
				Format(szPointsRatio, 32, "+%ip", pointsratio);
			else
				Format(szPointsRatio, 32, "%ip", pointsratio);




			if (pointsratio < 10)
				Format(szValue, 128, "       %s         » %s (%s)", szPointsRatio, szName, szWinRatio);
			else
				if (pointsratio < 100)
					Format(szValue, 128, "       %s       » %s (%s)", szPointsRatio, szName, szWinRatio);
				else
					if (pointsratio < 1000)
						Format(szValue, 128, "       %s     » %s (%s)", szPointsRatio, szName, szWinRatio);
					else
						if (pointsratio < 10000)
							Format(szValue, 128, "       %s   » %s (%s)", szPointsRatio, szName, szWinRatio);
						else
							Format(szValue, 128, "       %s » %s (%s)", szPointsRatio, szName, szWinRatio);

			topChallengersMenu.AddItem(szSteamID, szValue, ITEMDRAW_DEFAULT);
			i++;
		}
		if (i == 1)
		{
			PrintToChat(data, "%t", "NoPlayerTop", MOSSGREEN, WHITE);
			ckTopMenu(data);
		}
		else
		{
			SetMenuOptionFlags(topChallengersMenu, MENUFLAG_BUTTON_EXIT);
			topChallengersMenu.Display(data, MENU_TIME_FOREVER);
		}
	}
	else
	{
		PrintToChat(data, "%t", "NoPlayerTop", MOSSGREEN, WHITE);
		ckTopMenu(data);
	}
}

public void db_resetPlayerResetChallenges(int client, char steamid[128])
{
	char szQuery[255];
	char szsteamid[128 * 2 + 1];
	SQL_EscapeString(g_hDb, steamid, szsteamid, 128 * 2 + 1);
	Format(szQuery, 255, sql_deleteChallenges, szsteamid);
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, steamid);
	SQL_TQuery(g_hDb, SQL_CheckCallback4, szQuery, pack);
	PrintToConsole(client, "won challenges cleared (%s)", szsteamid);
}

public void db_dropChallenges(int client)
{
	SQL_TQuery(g_hDb, SQL_CheckCallback, "UPDATE ck_playerrank SET winratio = '0',pointsratio = '0'", client);
	SQL_LockDatabase(g_hDb);
	if (g_DbType == MYSQL)
		SQL_FastQuery(g_hDb, sql_dropChallenges);
	else
		SQL_FastQuery(g_hDb, sqlite_dropChallenges);
	SQL_FastQuery(g_hDb, sql_createChallenges);
	SQL_UnlockDatabase(g_hDb);
	PrintToConsole(client, "challenge table dropped. Please restart your server!");
}

public int TopChallengeHandler1(Handle menu, MenuAction action, int client, int item)
{

	if (action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, item, info, sizeof(info));
		g_MenuLevel[client] = 3;
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

public void TopTpHoldersHandler1(Handle menu, MenuAction action, int param1, int param2)
{

	if (action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		g_MenuLevel[param1] = 10;
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

public int TopProHoldersHandler1(Handle menu, MenuAction action, int client, int item)
{

	if (action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, item, info, sizeof(info));
		g_MenuLevel[client] = 11;
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

public void db_viewChallengeHistory(int client, char szSteamId[32])
{
	char szQuery[1024];
	Format(szQuery, 1024, sql_selectChallenges2, szSteamId, szSteamId);
	if ((StrContains(szSteamId, "STEAM_") != -1) && IsClientInGame(client))
	{
		Handle pack = CreateDataPack();
		WritePackString(pack, szSteamId);
		WritePackString(pack, g_szProfileName[client]);
		WritePackCell(pack, client);
		SQL_TQuery(g_hDb, sql_selectChallengesCallback, szQuery, pack, DBPrio_Low);
	}
	else
		if (IsClientInGame(client))
		PrintToChat(client, "[%cSurf Timer%c] Invalid SteamID found.", RED, WHITE);
	ProfileMenu(client, -1);
}

public void sql_selectChallengesCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_selectChallengesCallback): %s", error);
		return;
	}

	//decl.
	int bet, cp_allowed = 0, client;
	int bHeader = false;
	char szMapName[32];
	char szSteamId[32];
	char szSteamId2[32];
	char szSteamIdTarget[32];
	char szNameTarget[32];
	char szDate[64];

	//get pack data
	ResetPack(data);
	ReadPackString(data, szSteamIdTarget, 32);
	ReadPackString(data, szNameTarget, 32);
	client = ReadPackCell(data);
	CloseHandle(data);

	if (SQL_HasResultSet(hndl))
	{
		//fetch rows
		while (SQL_FetchRow(hndl))
		{
			//get row data
			SQL_FetchString(hndl, 0, szSteamId, 32);
			SQL_FetchString(hndl, 1, szSteamId2, 32);
			bet = SQL_FetchInt(hndl, 2);
			SQL_FetchString(hndl, 3, szMapName, 32);
			SQL_FetchString(hndl, 4, szDate, 64);

			//header
			if (!bHeader)
			{
				PrintToConsole(client, " ");
				PrintToConsole(client, "-------------");
				PrintToConsole(client, "Challenge history");
				PrintToConsole(client, "Player: %s", szNameTarget);
				PrintToConsole(client, "SteamID: %s", szSteamIdTarget);
				PrintToConsole(client, "-------------");
				PrintToConsole(client, " ");
				bHeader = true;
				PrintToChat(client, "%t", "ConsoleOutput", LIMEGREEN, WHITE);
			}

			//won/loss?
			int WinnerTarget = 0;
			if (StrEqual(szSteamId, szSteamIdTarget))
				WinnerTarget = 1;

			//create pack
			Handle pack2 = CreateDataPack();
			WritePackCell(pack2, client);
			WritePackCell(pack2, WinnerTarget);
			WritePackString(pack2, szNameTarget);
			WritePackString(pack2, szSteamId);
			WritePackString(pack2, szSteamId2);
			WritePackString(pack2, szMapName);
			WritePackString(pack2, szDate);
			WritePackCell(pack2, bet);
			WritePackCell(pack2, cp_allowed);

			//Query
			char szQuery[512];
			if (WinnerTarget == 1)
				Format(szQuery, 512, "select name from ck_playerrank where steamid = '%s'", szSteamId2);
			else
				Format(szQuery, 512, "select name from ck_playerrank where steamid = '%s'", szSteamId);
			SQL_TQuery(g_hDb, sql_selectChallengesCallback2, szQuery, pack2, DBPrio_Low);
		}
	}
	if (!bHeader)
	{
		ProfileMenu(client, -1);
		PrintToChat(client, "[%cSurf Timer%c] No challenges found.", MOSSGREEN, WHITE);
	}
}

public void sql_selectChallengesCallback2(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_selectChallengesCallback2): %s", error);
		return;
	}

	//decl.
	char szNameTarget[32];
	char szNameOpponent[32];
	char szSteamId[32];
	char szCps[32];
	char szResult[32];
	char szSteamId2[32];
	char szMapName[32];
	char szDate[64];
	int client, bet, WinnerTarget, cp_allowed;

	//get pack data
	ResetPack(data);
	client = ReadPackCell(data);
	WinnerTarget = ReadPackCell(data);
	ReadPackString(data, szNameTarget, 32);
	ReadPackString(data, szSteamId, 32);
	ReadPackString(data, szSteamId2, 32);
	ReadPackString(data, szMapName, 32);
	ReadPackString(data, szDate, 64);
	bet = ReadPackCell(data);
	cp_allowed = ReadPackCell(data);
	CloseHandle(data);

	//default name=steamid
	if (WinnerTarget == 1)
		Format(szNameOpponent, 32, "%s", szSteamId2);
	else
		Format(szNameOpponent, 32, "%s", szSteamId);

	//query result
	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		SQL_FetchString(hndl, 0, szNameOpponent, 32);

	//format..
	if (WinnerTarget == 1)
		Format(szResult, 32, "WIN");
	else
		Format(szResult, 32, "LOSS");

	if (cp_allowed == 1)
		Format(szCps, 32, "yes");
	else
		Format(szCps, 32, "no");

	//console msg
	if (IsClientInGame(client))
		PrintToConsole(client, "(%s) %s vs. %s, map: %s, bet: %i, result: %s", szDate, szNameTarget, szNameOpponent, szMapName, bet, szCps, szResult);
}

public void sql_selectChallengesCompareCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_selectChallengesCompareCallback): %s", error);
		return;
	}

	int winratio = 0;
	int challenges = SQL_GetRowCount(hndl);
	int pointratio = 0;
	char szWinRatio[32];
	char szPointsRatio[32];
	char szName[MAX_NAME_LENGTH];

	ResetPack(data);
	int client = ReadPackCell(data);
	ReadPackString(data, szName, MAX_NAME_LENGTH);
	CloseHandle(data);

	if (!IsValidClient(client))
		return;

	if (SQL_HasResultSet(hndl))
	{
		while (SQL_FetchRow(hndl))
		{
			char szID[32];
			int bet;
			SQL_FetchString(hndl, 0, szID, 32);
			bet = SQL_FetchInt(hndl, 2);
			if (StrEqual(szID, g_szSteamID[client]))
			{
				winratio++;
				pointratio += bet;
			}
			else
			{
				winratio--;
				pointratio -= bet;
			}
		}
		if (winratio > 0)
			Format(szWinRatio, 32, "+%i", winratio);
		else
			Format(szWinRatio, 32, "%i", winratio);

		if (pointratio > 0)
			Format(szPointsRatio, 32, "+%ip", pointratio);
		else
			Format(szPointsRatio, 32, "%ip", pointratio);

		if (winratio > 0)
		{
			if (pointratio > 0)
				PrintToChat(client, "[%cSurf Timer%c] %cYou have played %c%i%c challenges against %c%s%c (win/loss ratio: %c%s%c, points ratio: %c%s%c)", MOSSGREEN, WHITE, GRAY, PURPLE, challenges, GRAY, PURPLE, szName, GRAY, GREEN, szWinRatio, GRAY, GREEN, szPointsRatio, GRAY);
			else
				if (pointratio < 0)
					PrintToChat(client, "[%cSurf Timer%c] %cYou have played %c%i%c challenges against %c%s%c (win/loss ratio: %c%s%c, points ratio: %c%s%c)", MOSSGREEN, WHITE, GRAY, PURPLE, challenges, GRAY, PURPLE, szName, GRAY, GREEN, szWinRatio, GRAY, RED, szPointsRatio, GRAY);
				else
					PrintToChat(client, "[%cSurf Timer%c] %cYou have played %c%i%c challenges against %c%s%c (win/loss ratio: %c%s%c, points ratio: %c%s%c)", MOSSGREEN, WHITE, GRAY, PURPLE, challenges, GRAY, PURPLE, szName, GRAY, GREEN, szWinRatio, GRAY, YELLOW, szPointsRatio, GRAY);
		}
		else
		{
			if (winratio < 0)
			{
				if (pointratio > 0)
					PrintToChat(client, "[%cSurf Timer%c] %cYou have played %c%i%c challenges against %c%s%c (win/loss ratio: %c%s%c, points ratio: %c%s%c)", MOSSGREEN, WHITE, GRAY, PURPLE, challenges, GRAY, PURPLE, szName, GRAY, RED, szWinRatio, GRAY, GREEN, szPointsRatio, GRAY);
				else
					if (pointratio < 0)
						PrintToChat(client, "[%cSurf Timer%c] %cYou have played %c%i%c challenges against %c%s%c (win/loss ratio: %c%s%c, points ratio: %c%s%c)", MOSSGREEN, WHITE, GRAY, PURPLE, challenges, GRAY, PURPLE, szName, GRAY, RED, szWinRatio, GRAY, RED, szPointsRatio, GRAY);
					else
						PrintToChat(client, "[%cSurf Timer%c] %cYou have played %c%i%c challenges against %c%s%c (win/loss ratio: %c%s%c, points ratio: %c%s%c)", MOSSGREEN, WHITE, GRAY, PURPLE, challenges, GRAY, PURPLE, szName, GRAY, RED, szWinRatio, GRAY, YELLOW, szPointsRatio, GRAY);

			}
			else
			{
				if (pointratio > 0)
					PrintToChat(client, "[%cSurf Timer%c] %cYou have played %c%i%c challenges against %c%s%c (win/loss ratio: %c%s%c, points ratio: %c%s%c)", MOSSGREEN, WHITE, GRAY, PURPLE, challenges, GRAY, PURPLE, szName, GRAY, YELLOW, szWinRatio, GRAY, GREEN, szPointsRatio, GRAY);
				else
					if (pointratio < 0)
						PrintToChat(client, "[%cSurf Timer%c] %cYou have played %c%i%c challenges against %c%s%c (win/loss ratio: %c%s%c, points ratio: %c%s%c)", MOSSGREEN, WHITE, GRAY, PURPLE, challenges, GRAY, PURPLE, szName, GRAY, YELLOW, szWinRatio, GRAY, RED, szPointsRatio, GRAY);
					else
						PrintToChat(client, "[%cSurf Timer%c] %cYou have played %c%i%c challenges against %c%s%c (win/loss ratio: %c%s%c, points ratio: %c%s%c)", MOSSGREEN, WHITE, GRAY, PURPLE, challenges, GRAY, PURPLE, szName, GRAY, YELLOW, szWinRatio, GRAY, YELLOW, szPointsRatio, GRAY);
			}
		}
	}
	else
		PrintToChat(client, "[%cSurf Timer%c] No challenges againgst %s found", szName);
}

public void db_insertPlayerChallenge(int client)
{
	if (!IsValidClient(client))
		return;
	char szQuery[255];
	int points;
	points = g_Challenge_Bet[client] * g_pr_PointUnit;

	Format(szQuery, 255, sql_insertChallenges, g_szSteamID[client], g_szChallenge_OpponentID[client], points, g_szMapName);
	SQL_TQuery(g_hDb, sql_insertChallengesCallback, szQuery, client, DBPrio_Low);
}

public void sql_insertChallengesCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_insertChallengesCallback): %s", error);
		return;
	}
}