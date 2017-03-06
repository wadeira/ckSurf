public void db_viewMapProRankCount()
{
	g_MapTimesCount = 0;
	char szQuery[512];
	Format(szQuery, 512, sql_selectPlayerProCount, g_szMapName);
	SQL_TQuery(g_hDb, sql_selectPlayerProCountCallback, szQuery, DBPrio_Low);
}

public void sql_selectPlayerProCountCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_selectPlayerProCountCallback): %s", error);
		if (!g_bServerDataLoaded)
			db_viewFastestBonus();
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		g_MapTimesCount = SQL_GetRowCount(hndl);
	else
		g_MapTimesCount = 0;

	if (!g_bServerDataLoaded)
		db_viewFastestBonus();

	return;
}

//
// Get players rank in current map
//
public void db_viewMapRankPro(int client)
{
	char szQuery[512];
	if (!IsValidClient(client))
		return;

	//"SELECT name,mapname FROM ck_playertimes WHERE runtimepro <= (SELECT runtimepro FROM ck_playertimes WHERE steamid = '%s' AND mapname = '%s' AND runtimepro > -1.0) AND mapname = '%s' AND runtimepro > -1.0 ORDER BY runtimepro;";
	Format(szQuery, 512, sql_selectPlayerRankProTime, g_szSteamID[client], g_szMapName, g_szMapName);
	SQL_TQuery(g_hDb, db_viewMapRankProCallback, szQuery, client, DBPrio_Low);
}

public void db_viewMapRankProCallback(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (db_viewMapRankProCallback): %s ", error);
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		g_MapRank[client] = SQL_GetRowCount(hndl);
	}
	if (!g_bSettingsLoaded[client])
		db_viewPersonalBonusRecords(client, g_szSteamID[client]);
}

//
// Players points have changed in game, make changes in database and recalculate points
//
public void db_updateStat(int client)
{
	char szQuery[512];
	//"UPDATE ck_playerrank SET finishedmaps ='%i', finishedmapspro='%i', multiplier ='%i'  where steamid='%s'";
	Format(szQuery, 512, sql_updatePlayerRank, g_pr_finishedmaps[client], g_pr_finishedmaps[client], g_pr_multiplier[client], g_szSteamID[client]);

	SQL_TQuery(g_hDb, SQL_UpdateStatCallback, szQuery, client, DBPrio_Low);

}

public void SQL_UpdateStatCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_UpdateStatCallback): %s", error);
		return;
	}

	// Calculating starts here:
	CalculatePlayerRank(data);
}

public void RecalcPlayerRank(int client, char steamid[128])
{
	int i = 66;
	while (g_bProfileRecalc[i] == true)
		i++;
	if (!g_bProfileRecalc[i])
	{
		char szQuery[255];
		char szsteamid[128 * 2 + 1];
		SQL_EscapeString(g_hDb, steamid, szsteamid, 128 * 2 + 1);
		Format(g_pr_szSteamID[i], 32, "%s", steamid);
		Format(szQuery, 255, sql_selectPlayerName, szsteamid);
		Handle pack = CreateDataPack();
		WritePackCell(pack, i);
		WritePackCell(pack, client);
		SQL_TQuery(g_hDb, sql_selectPlayerNameCallback, szQuery, pack);
	}
}

//
//  1. Point calculating starts here
// 	There are two ways:
//	- if client > MAXPLAYERS, his rank is being recalculated by an admin
//	- else player has increased his rank = recalculate points
//
public void CalculatePlayerRank(int client)
{
	if (client <= MAXPLAYERS) {
		if (g_CalculatingPoints[client])
			return;

		g_CalculatingPoints[client] = true;
	}

	char szQuery[255];
	char szSteamId[32];
	// Take old points into memory, so at the end you can show how much the points changed
	g_pr_oldpoints[client] = g_pr_points[client];
	// Initialize point calculatin
	g_pr_points[client] = 0;

	getSteamIDFromClient(client, szSteamId, 32);

	Format(szQuery, 255, "SELECT multiplier FROM ck_playerrank WHERE steamid = '%s'", szSteamId);
	SQL_TQuery(g_hDb, sql_selectRankedPlayerCallback, szQuery, client, DBPrio_Low);
}

//
// 2. Count points from improvements, or insert new player into the database
// Fetched values:
// multiplier
//
public void sql_selectRankedPlayerCallback(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_selectRankedPlayerCallback): %s", error);
		return;
	}


	char szSteamId[32];

	getSteamIDFromClient(client, szSteamId, 32);

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		if (IsValidClient(client))
		{
			if (GetClientTime(client) < (GetEngineTime() - g_fMapStartTime))
				db_UpdateLastSeen(client); // Update last seen on server
		}
		// Multiplier = The amount of times a player has improved on his time
		g_pr_multiplier[client] = SQL_FetchInt(hndl, 0);
		if (g_pr_multiplier[client] < 0)
			g_pr_multiplier[client] = g_pr_multiplier[client] * -1;

		// Multiplier increases players points by the set amount in ck_ranking_extra_points_improvements
		g_pr_points[client] += GetConVarInt(g_hExtraPoints) * g_pr_multiplier[client];

		if (IsValidClient(client))
			g_pr_Calculating[client] = true;

		// Next up, challenge points
		char szQuery[512];

		Format(szQuery, 512, "SELECT steamid, bet FROM ck_challenges WHERE steamid = '%s' OR steamid2 ='%s'", szSteamId, szSteamId);
		SQL_TQuery(g_hDb, sql_selectChallengesCallbackCalc, szQuery, client, DBPrio_Low);
	}
	else
	{
		// Players first time on server
		if (client <= MaxClients)
		{
			g_pr_Calculating[client] = false;
			g_pr_AllPlayers++;

			// Insert player to database
			char szQuery[255];
			char szUName[MAX_NAME_LENGTH];
			char szName[MAX_NAME_LENGTH * 2 + 1];

			GetClientName(client, szUName, MAX_NAME_LENGTH);
			SQL_EscapeString(g_hDb, szUName, szName, MAX_NAME_LENGTH * 2 + 1);

			//"INSERT INTO ck_playerrank (steamid, name, country) VALUES('%s', '%s', '%s');";
			// No need to continue calculating, as the doesn't have any records.
			Format(szQuery, 255, sql_insertPlayerRank, szSteamId, szName, g_szCountry[client]);
			SQL_TQuery(g_hDb, SQL_InsertPlayerCallBack, szQuery, client, DBPrio_Low);

			g_pr_multiplier[client] = 0;
			g_pr_finishedmaps[client] = 0;
			g_pr_finishedmaps_perc[client] = 0.0;
		}
	}
}

//
// 3. Counting points gained from challenges
// Fetched values:
// steamid, bet
public void sql_selectChallengesCallbackCalc(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_selectChallengesCallbackCalc): %s", error);
		return;
	}


	char szQuery[512];
	char szSteamId[32];
	char szSteamIdChallenge[32];


	getSteamIDFromClient(client, szSteamId, 32);

	int bet;

	if (SQL_HasResultSet(hndl))
	{
		g_Challenge_WinRatio[client] = 0;
		g_Challenge_PointsRatio[client] = 0;
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, szSteamIdChallenge, 32);
			bet = SQL_FetchInt(hndl, 1);
			if (StrEqual(szSteamIdChallenge, szSteamId)) // Won the challenge
			{
				g_Challenge_WinRatio[client]++;
				g_Challenge_PointsRatio[client] += bet;
			}
			else // Lost the challenge
			{
				g_Challenge_WinRatio[client]--;
				g_Challenge_PointsRatio[client] -= bet;
			}
		}
	}
	if (GetConVarBool(g_hChallengePoints)) // If challenge points are enabled: add them to players points
		g_pr_points[client] += g_Challenge_PointsRatio[client];

	// Next up, calculate bonus points:
	Format(szQuery, 512, "SELECT mapname, (SELECT count(1)+1 FROM ck_bonus b WHERE a.mapname=b.mapname AND a.runtime > b.runtime AND a.zonegroup = b.zonegroup) AS rank, (SELECT count(1) FROM ck_bonus b WHERE a.mapname = b.mapname AND a.zonegroup = b.zonegroup) as total FROM ck_bonus a WHERE steamid = '%s';", szSteamId);
	SQL_TQuery(g_hDb, sql_CountFinishedBonusCallback, szQuery, client, DBPrio_Low);
}

//
// 4. Calculate points gained from bonuses
// Fetched values
// mapname, rank, total
//
public void sql_CountFinishedBonusCallback(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_CountFinishedBonusCallback): %s", error);
		return;
	}


	char szMap[128], szSteamId[32], szMapName2[128];
	int totalplayers, rank;

	getSteamIDFromClient(client, szSteamId, 32);

	if (SQL_HasResultSet(hndl))
	{
		while (SQL_FetchRow(hndl))
		{
			// Total amount of players who have finished the bonus
			totalplayers = SQL_FetchInt(hndl, 2);
			rank = SQL_FetchInt(hndl, 1);
			SQL_FetchString(hndl, 0, szMap, 128);
			for (int i = 0; i < GetArraySize(g_MapList); i++) // Check that the map is in the mapcycle
			{
				GetArrayString(g_MapList, i, szMapName2, sizeof(szMapName2));
				if (StrEqual(szMapName2, szMap, false))
				{
					float percentage = 1.0 + ((1.0 / float(totalplayers)) - (float(rank) / float(totalplayers)));
					g_pr_points[client] += RoundToCeil(200.0 * percentage);
					switch (rank)
					{
						case 1:g_pr_points[client] += 200;
						case 2:g_pr_points[client] += 190;
						case 3:g_pr_points[client] += 180;
						case 4:g_pr_points[client] += 170;
						case 5:g_pr_points[client] += 150;
						case 6:g_pr_points[client] += 140;
						case 7:g_pr_points[client] += 135;
						case 8:g_pr_points[client] += 120;
						case 9:g_pr_points[client] += 115;
						case 10:g_pr_points[client] += 105;
						case 11:g_pr_points[client] += 100;
						case 12:g_pr_points[client] += 90;
						case 13:g_pr_points[client] += 80;
						case 14:g_pr_points[client] += 75;
						case 15:g_pr_points[client] += 60;
						case 16:g_pr_points[client] += 50;
						case 17:g_pr_points[client] += 40;
						case 18:g_pr_points[client] += 30;
						case 19:g_pr_points[client] += 20;
						case 20:g_pr_points[client] += 10;
					}
					break;
				}
			}
		}
	}

	// Next up: Points from maps
	char szQuery[512];
	Format(szQuery, 512, "SELECT mapname, (select count(1)+1 from ck_playertimes b where a.mapname=b.mapname and a.runtimepro > b.runtimepro) AS rank, (SELECT count(1) FROM ck_playertimes b WHERE a.mapname = b.mapname) as total FROM ck_playertimes a where steamid = '%s';", szSteamId);
	SQL_TQuery(g_hDb, sql_CountFinishedMapsCallback, szQuery, client, DBPrio_Low);
}

//
// 5. Count the points gained from regular maps
// Fetching:
// mapname, rank, total
//
public void sql_CountFinishedMapsCallback(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_CountFinishedMapsCallback): %s", error);
		return;
	}

	char szMap[128], szMapName2[128], szSteamId[32];
	int finishedMaps = 0, totalplayers, rank;

	getSteamIDFromClient(client, szSteamId, 32);

	if (SQL_HasResultSet(hndl))
	{
		while (SQL_FetchRow(hndl))
		{
			// Total amount of players who have finished the map
			totalplayers = SQL_FetchInt(hndl, 2);
			// Rank in that map
			rank = SQL_FetchInt(hndl, 1);
			// Map name
			SQL_FetchString(hndl, 0, szMap, 128);

			for (int i = 0; i < GetArraySize(g_MapList); i++) // Check that the map is in the mapcycle
			{
				GetArrayString(g_MapList, i, szMapName2, sizeof(szMapName2));
				if (StrEqual(szMapName2, szMap, false))
				{
					finishedMaps++;
					float percentage = 1.0 + ((1.0 / float(totalplayers)) - (float(rank) / float(totalplayers)));
					g_pr_points[client] += RoundToCeil(200.0 * percentage);
					switch (rank)
					{
						case 1:g_pr_points[client] += 500;
						case 2:g_pr_points[client] += 400;
						case 3:g_pr_points[client] += 375;
						case 4:g_pr_points[client] += 350;
						case 5:g_pr_points[client] += 325;
						case 6:g_pr_points[client] += 300;
						case 7:g_pr_points[client] += 275;
						case 8:g_pr_points[client] += 250;
						case 9:g_pr_points[client] += 225;
						case 10:g_pr_points[client] += 200;
						case 11:g_pr_points[client] += 175;
						case 12:g_pr_points[client] += 150;
						case 13:g_pr_points[client] += 125;
						case 14:g_pr_points[client] += 100;
						case 15:g_pr_points[client] += 90;
						case 16:g_pr_points[client] += 80;
						case 17:g_pr_points[client] += 70;
						case 18:g_pr_points[client] += 60;
						case 19:g_pr_points[client] += 50;
						case 20:g_pr_points[client] += 40;
					}
					break;
				}
			}
		}
	}
	// Finished maps amount is stored in memory
	g_pr_finishedmaps[client] = finishedMaps;
	// Percentage of maps finished
	g_pr_finishedmaps_perc[client] = (float(finishedMaps) / float(g_pr_MapCount)) * 100.0;
	// Points gained from finishing maps for the first time
	g_pr_points[client] += (finishedMaps * GetConVarInt(g_hExtraPoints2));

	// Next up, calculate stage points:
	char szQuery[512];
	Format(szQuery, 512, "SELECT map, (SELECT count(1)+1 FROM ck_stages b WHERE a.map=b.map AND a.runtime > b.runtime AND a.stage = b.stage) AS rank, (SELECT count(1) FROM ck_stages b WHERE a.map = b.map AND a.stage = b.stage) as total FROM ck_stages a WHERE steamid = '%s';", szSteamId);
	SQL_TQuery(g_hDb, sql_CountFinishedStagesCallback, szQuery, client, DBPrio_Low);
}


public void sql_CountFinishedStagesCallback(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_CountFinishedStagesCallback): %s", error);
		return;
	}


	char szMap[128], szSteamId[32], szMapName2[128];
	int totalplayers, rank;

	getSteamIDFromClient(client, szSteamId, 32);

	if (SQL_HasResultSet(hndl))
	{
		while (SQL_FetchRow(hndl))
		{
			// Total amount of players who have finished the bonus
			totalplayers = SQL_FetchInt(hndl, 2);
			rank = SQL_FetchInt(hndl, 1);
			SQL_FetchString(hndl, 0, szMap, 128);
			for (int i = 0; i < GetArraySize(g_MapList); i++) // Check that the map is in the mapcycle
			{
				GetArrayString(g_MapList, i, szMapName2, sizeof(szMapName2));
				if (StrEqual(szMapName2, szMap, false))
				{
					float percentage = 1.0 + ((1.0 / float(totalplayers)) - (float(rank) / float(totalplayers)));
					g_pr_points[client] += RoundToCeil(20.0 * percentage);
					switch (rank)
					{
						case 1:g_pr_points[client] += 50;
						case 2:g_pr_points[client] += 45;
						case 3:g_pr_points[client] += 40;
						case 4:g_pr_points[client] += 35;
						case 5:g_pr_points[client] += 30;
						case 6:g_pr_points[client] += 25;
						case 7:g_pr_points[client] += 20;
						case 8:g_pr_points[client] += 15;
						case 9:g_pr_points[client] += 10;
						case 10:g_pr_points[client] += 5;
					}
					break;
				}
			}
		}
	}

	// Done checking, update points
	db_updatePoints(client);
}

//
// 6. Updating points to database
//
public void db_updatePoints(int client)
{
	char szQuery[512];
	char szName[MAX_NAME_LENGTH * 2 + 1];
	char szSteamId[32];
	if (client > MAXPLAYERS && g_pr_RankingRecalc_InProgress || client > MAXPLAYERS && g_bProfileRecalc[client])
	{
		SQL_EscapeString(g_hDb, g_pr_szName[client], szName, MAX_NAME_LENGTH * 2 + 1);
		Format(szQuery, 512, sql_updatePlayerRankPoints, szName, g_pr_points[client], g_pr_finishedmaps[client], g_Challenge_WinRatio[client], g_Challenge_PointsRatio[client], g_pr_szSteamID[client]);
		SQL_TQuery(g_hDb, sql_updatePlayerRankPointsCallback, szQuery, client, DBPrio_Low);
	}
	else
	{
		if (IsValidClient(client))
		{
			GetClientName(client, szName, MAX_NAME_LENGTH);
			GetClientAuthId(client, AuthId_Steam2, szSteamId, MAX_NAME_LENGTH, true);
			//GetClientAuthString(client, szSteamId, MAX_NAME_LENGTH);
			Format(szQuery, 512, sql_updatePlayerRankPoints2, szName, g_pr_points[client], g_pr_finishedmaps[client], g_Challenge_WinRatio[client], g_Challenge_PointsRatio[client], g_szCountry[client], szSteamId);
			SQL_TQuery(g_hDb, sql_updatePlayerRankPointsCallback, szQuery, client, DBPrio_Low);
		}
	}
}

//
// 7. Calculations done, if calculating all, move forward, if not announce changes.
//
public void sql_updatePlayerRankPointsCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_updatePlayerRankPointsCallback): %s", error);
		return;
	}

	// If was recalculating points, go to the next player, announce or end calculating
	if (data > MAXPLAYERS && g_pr_RankingRecalc_InProgress || data > MAXPLAYERS && g_bProfileRecalc[data])
	{
		if (g_bProfileRecalc[data] && !g_pr_RankingRecalc_InProgress)
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					if (StrEqual(g_szSteamID[i], g_pr_szSteamID[data]))
						CalculatePlayerRank(i);
				}
			}
		}
		g_bProfileRecalc[data] = false;
		if (g_pr_RankingRecalc_InProgress)
		{
			//console info
			if (IsValidClient(g_pr_Recalc_AdminID) && g_bManualRecalc)
				PrintToConsole(g_pr_Recalc_AdminID, "%i/%i", g_pr_Recalc_ClientID, g_pr_TableRowCount);
			int x = 66 + g_pr_Recalc_ClientID;
			if (StrContains(g_pr_szSteamID[x], "STEAM", false) != -1)
			{
				ContinueRecalc(x);
			}
			else
			{
				for (int i = 1; i <= MaxClients; i++)
					if (1 <= i <= MaxClients && IsValidEntity(i) && IsValidClient(i))
					{
						if (g_bManualRecalc)
							PrintToChat(i, "%t", "PrUpdateFinished", MOSSGREEN, WHITE, LIMEGREEN);
					}
				g_bManualRecalc = false;
				g_pr_RankingRecalc_InProgress = false;

				if (IsValidClient(g_pr_Recalc_AdminID))
					CreateTimer(0.1, RefreshAdminMenu, g_pr_Recalc_AdminID, TIMER_FLAG_NO_MAPCHANGE);
			}
			g_pr_Recalc_ClientID++;
		}
	}
	else // Gaining points normally
	{
		// Player recalculated own points in !profile
		if (g_bRecalcRankInProgess[data] && data <= MAXPLAYERS)
		{
			ProfileMenu(data, -1);
			if (IsValidClient(data))
				PrintToChat(data, "%t", "Rc_PlayerRankFinished", MOSSGREEN, WHITE, GRAY, PURPLE, g_pr_points[data], GRAY);
			g_bRecalcRankInProgess[data] = false;
		}
		if (IsValidClient(data) && g_pr_showmsg[data]) // Player gained points
		{
			char szName[MAX_NAME_LENGTH];
			GetClientName(data, szName, MAX_NAME_LENGTH);
			int diff = g_pr_points[data] - g_pr_oldpoints[data];
			
			if (diff > 0) // if player earned points -> Announce
				PrintToChat(data, "[%cSurf Timer%c] You earned %c%d %cpoints (%c%d %cTotal)", MOSSGREEN, WHITE, ORANGE, diff, WHITE, ORANGE, g_pr_points[data], WHITE);

			g_pr_showmsg[data] = false;
			db_CalculatePlayersCountGreater0();
		}
		g_pr_Calculating[data] = false;
		db_GetPlayerRank(data);
		g_CalculatingPoints[data] = false;
		CreateTimer(1.0, SetClanTag, data, TIMER_FLAG_NO_MAPCHANGE);
	}
}

//
// Called when player joins server
//
public void db_viewPlayerPoints(int client)
{
	g_pr_multiplier[client] = 0;
	g_pr_finishedmaps[client] = 0;
	g_pr_finishedmaps_perc[client] = 0.0;
	g_pr_points[client] = 0;
	char szQuery[255];
	if (!IsValidClient(client))
		return;

	//"SELECT steamid, name, points, finishedmapspro, multiplier, country, lastseen from ck_playerrank where steamid='%s'";
	Format(szQuery, 255, sql_selectRankedPlayer, g_szSteamID[client]);
	SQL_TQuery(g_hDb, db_viewPlayerPointsCallback, szQuery, client, DBPrio_Low);
}

public void db_viewPlayerPointsCallback(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (db_viewPlayerPointsCallback): %s", error);
		if (!g_bSettingsLoaded[client])
			db_viewPlayerOptions(client, g_szSteamID[client]);
		return;
	}

	// Old player - get points
	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		g_pr_points[client] = SQL_FetchInt(hndl, 2);
		g_pr_finishedmaps[client] = SQL_FetchInt(hndl, 3);
		g_pr_multiplier[client] = SQL_FetchInt(hndl, 4);
		if (g_pr_multiplier[client] < 0)
			g_pr_multiplier[client] = -1 * g_pr_multiplier[client];
		g_pr_finishedmaps_perc[client] = (float(g_pr_finishedmaps[client]) / float(g_pr_MapCount)) * 100.0;
		if (IsValidClient(client)) // Count players rank
			db_GetPlayerRank(client);
	}
	else
	{  // New player - insert
		if (IsValidClient(client))
		{
			//insert
			char szQuery[512];
			char szUName[MAX_NAME_LENGTH];

			if (IsValidClient(client))
				GetClientName(client, szUName, MAX_NAME_LENGTH);
			else
				return;

			// SQL injection protection
			char szName[MAX_NAME_LENGTH * 2 + 1];
			SQL_EscapeString(g_hDb, szUName, szName, MAX_NAME_LENGTH * 2 + 1);

			Format(szQuery, 512, sql_insertPlayerRank, g_szSteamID[client], szName, g_szCountry[client]);
			SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, DBPrio_Low);
			db_GetPlayerRank(client); // Count players rank
		}
	}
}

//
// Get the amount of palyers, who have more points
//
public void db_GetPlayerRank(int client)
{
	char szQuery[512];
	//"SELECT name FROM ck_playerrank WHERE points >= (SELECT points FROM ck_playerrank WHERE steamid = '%s') ORDER BY points";
	Format(szQuery, 512, sql_selectRankedPlayersRank, g_szSteamID[client]);
	SQL_TQuery(g_hDb, sql_selectRankedPlayersRankCallback, szQuery, client, DBPrio_Low);
}

public void sql_selectRankedPlayersRankCallback(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (sql_selectRankedPlayersRankCallback): %s", error);
		if (!g_bSettingsLoaded[client])
			db_viewPlayerOptions(client, g_szSteamID[client]);
		return;
	}

	if (!IsValidClient(client))
		return;

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		g_PlayerRank[client] = SQL_GetRowCount(hndl);
		// Sort players by rank in scoreboard
		if (g_pr_AllPlayers < g_PlayerRank[client])
			CS_SetClientContributionScore(client, 0);
		else
			CS_SetClientContributionScore(client, (g_pr_AllPlayers - SQL_GetRowCount(hndl)));
	}

	if (!g_bSettingsLoaded[client])
		db_viewPlayerOptions(client, g_szSteamID[client]);
}

public void db_resetPlayerRecords(int client, char steamid[128])
{
	char szQuery[255];
	char szsteamid[128 * 2 + 1];
	SQL_EscapeString(g_hDb, steamid, szsteamid, 128 * 2 + 1);
	Format(szQuery, 255, sql_resetRecords, szsteamid);
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery);
	PrintToConsole(client, "map times of %s cleared.", szsteamid);
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, steamid);
	SQL_TQuery(g_hDb, SQL_CheckCallback3, "UPDATE ck_playerrank SET multiplier ='0'", pack);
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

public void db_dropPlayerRanks(int client)
{
	SQL_LockDatabase(g_hDb);
	if (g_DbType == MYSQL)
		SQL_FastQuery(g_hDb, sql_dropPlayerRank);
	else
		SQL_FastQuery(g_hDb, sqlite_dropPlayerRank);

	SQL_FastQuery(g_hDb, sql_createPlayerRank);
	SQL_UnlockDatabase(g_hDb);
	PrintToConsole(client, "playerranks table dropped. Please restart your server!");
}

public void db_dropPlayer(int client)
{
	SQL_TQuery(g_hDb, sql_selectMutliplierCallback, "UPDATE ck_playerrank SET multiplier ='0'", client);
	SQL_LockDatabase(g_hDb);
	if (g_DbType == MYSQL)
		SQL_FastQuery(g_hDb, sql_dropPlayer);
	else
		SQL_FastQuery(g_hDb, sqlite_dropPlayer);
	SQL_FastQuery(g_hDb, sql_createPlayertimes);
	SQL_FastQuery(g_hDb, sql_createPlayertimesIndex);
	SQL_UnlockDatabase(g_hDb);
	PrintToConsole(client, "playertimes table dropped. Please restart your server!");
}

public void db_viewPlayerRank(int client, char szSteamId[32])
{
	char szQuery[512];
	Format(g_pr_szrank[client], 512, "");
	Format(szQuery, 512, sql_selectRankedPlayer, szSteamId);
	SQL_TQuery(g_hDb, SQL_ViewRankedPlayerCallback, szQuery, client, DBPrio_Low);
}

public void SQL_ViewRankedPlayerCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_ViewRankedPlayerCallback): %s", error);
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		char szQuery[512];
		char szName[MAX_NAME_LENGTH];
		char szCountry[100];
		char szLastSeen[100];
		char szSteamId[32];
		int finishedmapspro;
		int points;
		g_MapRecordCount[data] = 0;

		//get the result
		SQL_FetchString(hndl, 0, szSteamId, 32);
		SQL_FetchString(hndl, 1, szName, MAX_NAME_LENGTH);
		points = SQL_FetchInt(hndl, 2);
		finishedmapspro = SQL_FetchInt(hndl, 3);
		SQL_FetchString(hndl, 5, szCountry, 100);
		SQL_FetchString(hndl, 6, szLastSeen, 100);
		Handle pack_pr = CreateDataPack();
		WritePackString(pack_pr, szName);
		WritePackString(pack_pr, szSteamId);
		WritePackCell(pack_pr, data);
		WritePackCell(pack_pr, points);
		WritePackCell(pack_pr, finishedmapspro);
		WritePackString(pack_pr, szCountry);
		WritePackString(pack_pr, szLastSeen);
		Format(szQuery, 512, sql_selectRankedPlayersRank, szSteamId);
		SQL_TQuery(g_hDb, SQL_ViewRankedPlayerCallback2, szQuery, pack_pr, DBPrio_Low);
	}
}




public void SQL_ViewRankedPlayerCallback2(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_ViewRankedPlayerCallback2): %s", error);
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		char szQuery[512];
		char szSteamId[32];
		char szName[MAX_NAME_LENGTH];
		int rank = SQL_GetRowCount(hndl);

		WritePackCell(data, rank);
		ResetPack(data);
		ReadPackString(data, szName, MAX_NAME_LENGTH);
		ReadPackString(data, szSteamId, 32);
		Format(szQuery, 512, sql_selectMapRecordCount, szSteamId);
		SQL_TQuery(g_hDb, SQL_ViewRankedPlayerCallback4, szQuery, data, DBPrio_Low);
	}
}

public void SQL_ViewRankedPlayerCallback4(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_ViewRankedPlayerCallback4): %s", error);
		return;
	}

	char szQuery[512];
	char szSteamId[32];
	char szName[MAX_NAME_LENGTH];

	ResetPack(data);
	ReadPackString(data, szName, MAX_NAME_LENGTH);
	ReadPackString(data, szSteamId, 32);
	int client = ReadPackCell(data);
	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
		g_MapRecordCount[client] = SQL_FetchInt(hndl, 1); //pack full?
	Format(szQuery, 512, sql_selectChallenges, szSteamId, szSteamId);
	SQL_TQuery(g_hDb, SQL_ViewRankedPlayerCallback5, szQuery, data, DBPrio_Low);
}

public void SQL_ViewRankedPlayerCallback5(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_ViewRankedPlayerCallback5): %s", error);
		return;
	}

	char szChallengesPoints[32];
	Format(szChallengesPoints, 32, "0p");
	char szChallengesWinRatio[32];
	Format(szChallengesWinRatio, 32, "0");

	char szName[MAX_NAME_LENGTH];
	char szSteamId[32];
	char szSteamIdChallenge[32];
	char szCountry[100];
	char szLastSeen[100];
	char szNextRank[32];
	char szSkillGroup[32];

	ResetPack(data);
	ReadPackString(data, szName, MAX_NAME_LENGTH);
	ReadPackString(data, szSteamId, 32);
	int client = ReadPackCell(data);
	int points = ReadPackCell(data);
	int finishedmapspro = ReadPackCell(data);
	ReadPackString(data, szCountry, 100);
	ReadPackString(data, szLastSeen, 100);
	if (StrEqual(szLastSeen, ""))
		Format(szLastSeen, 100, "Unknown");
	int rank = ReadPackCell(data);
	int prorecords = g_MapRecordCount[client];
	Format(g_szProfileSteamId[client], 32, "%s", szSteamId);
	Format(g_szProfileName[client], MAX_NAME_LENGTH, "%s", szName);
	bool master = false;
	int RankDifference;
	CloseHandle(data);

	int bet;

	if (StrEqual(szSteamId, g_szSteamID[client]))
		g_PlayerRank[client] = rank;

	//get challenge results
	int challenges = 0;
	int challengeswon = 0;
	int challengespoints = 0;
	if (SQL_HasResultSet(hndl))
	{
		challenges = SQL_GetRowCount(hndl);
		while (SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 0, szSteamIdChallenge, 32);
			bet = SQL_FetchInt(hndl, 2);
			if (StrEqual(szSteamIdChallenge, szSteamId))
			{
				challengespoints += bet;
				challengeswon++;
			}
			else
			{
				challengespoints -= bet;
				challengeswon--;
			}
		}
	}

	if (!GetConVarBool(g_hChallengePoints))
		challengespoints = 0;

	if (challengespoints > 0)
		Format(szChallengesPoints, 32, "+%ip", challengespoints);
	else
		if (challengespoints <= 0 && GetConVarBool(g_hChallengePoints))
			Format(szChallengesPoints, 32, "%ip", challengespoints);
		else
			if (challengespoints <= 0 && !GetConVarBool(g_hChallengePoints))
				Format(szChallengesPoints, 32, "0p (disabled)");


	if (challengeswon > 0)
		Format(szChallengesWinRatio, 32, "+%i", challengeswon);
	else
		if (challengeswon < 0)
		Format(szChallengesWinRatio, 32, "%i", challengeswon);


	if (finishedmapspro > g_pr_MapCount)
		finishedmapspro = g_pr_MapCount;


	int index = GetSkillgroupFromPoints(points), RankValue[SkillGroup];
	GetArrayArray(g_hSkillGroups, index, RankValue[0]);

	Format(szSkillGroup, 32, "%s", RankValue[RankName]);

	if (index == (GetArraySize(g_hSkillGroups)-1))
	{
		RankDifference = 0;
		Format(szNextRank, 32, " ");
		master = true;
	}
	else
	{
		GetArrayArray(g_hSkillGroups, (index+1), RankValue[0]);
		RankDifference = RankValue[PointReq] - points;
		Format(szNextRank, 32, " (%s)", RankValue[RankName]);
	}

	char szRank[32];
	if (rank > g_pr_RankedPlayers || points == 0)
		Format(szRank, 32, "-");
	else
		Format(szRank, 32, "%i", rank);

	char szRanking[255];
	Format(szRanking, 255, "");
	if (master == false)
	{
		if (GetConVarBool(g_hPointSystem))
			Format(szRanking, 255, "Rank: %s/%i (%i)\nPoints: %ip (%s)\nNext skill group in: %ip%s\n", szRank, g_pr_RankedPlayers, g_pr_AllPlayers, points, szSkillGroup, RankDifference, szNextRank);
		Format(g_pr_szrank[client], 512, "Rank: %s/%i (%i)\nPoints: %ip (%s)\nNext skill group in: %ip%s\nMaps completed: %i/%i (records: %i)\nPlayed challenges: %i\n╘W/L Ratio: %s\n╘W/L Points ratio: %s\n ", szRank, g_pr_RankedPlayers, g_pr_AllPlayers, points, szSkillGroup, RankDifference, szNextRank, finishedmapspro, g_pr_MapCount, prorecords, challenges, szChallengesWinRatio, szChallengesPoints);
	}
	else
	{
		if (GetConVarBool(g_hPointSystem))
			Format(szRanking, 255, "Rank: %s/%i (%i)\nPoints: %ip (%s)\n", szRank, g_pr_RankedPlayers, g_pr_AllPlayers, points, szSkillGroup);
		Format(g_pr_szrank[client], 512, "Rank: %s/%i (%i)\nPoints: %ip (%s)\nMaps completed: %i/%i (records: %i)\nPlayed challenges: %i\n╘ W/L Ratio: %s\n╘ W/L points ratio: %s\n ", szRank, g_pr_RankedPlayers, g_pr_AllPlayers, points, szSkillGroup, finishedmapspro, g_pr_MapCount, prorecords, challenges, szChallengesWinRatio, szChallengesPoints);

	}
	char szID[32][2];
	ExplodeString(szSteamId, "_", szID, 2, 32);
	char szTitle[1024];
	if (GetConVarBool(g_hCountry))
		Format(szTitle, 1024, "Player: %s\nSteamID: %s\nNationality: %s \nLast seen: %s\n \n%s\n", szName, szID[1], szCountry, szLastSeen, g_pr_szrank[client]);
	else
		Format(szTitle, 1024, "Player: %s\nSteamID: %s\nLast seen: %s\n \n%s\n", szName, szID[1], szLastSeen, g_pr_szrank[client]);

	Menu profileMenu = new Menu(ProfileMenuHandler);
	profileMenu.SetTitle(szTitle);
	profileMenu.AddItem("Current Map time", "Current Map time");
	profileMenu.AddItem("Challenge history", "Challenge history");
	profileMenu.AddItem("Finished maps", "Finished maps");

	if (IsValidClient(client))
	{
		if (StrEqual(szSteamId, g_szSteamID[client]))
		{
			if (GetConVarBool(g_hPointSystem))
				profileMenu.AddItem("Refresh my profile", "Refresh my profile");
		}
	}


	profileMenu.ExitButton = true;
	profileMenu.Display(client, MENU_TIME_FOREVER);
}

public void db_viewPlayerRank2(int client, char szSteamId[32])
{
	char szQuery[512];
	Format(g_pr_szrank[client], 512, "");
	Format(szQuery, 512, sql_selectRankedPlayer, szSteamId);
	SQL_TQuery(g_hDb, SQL_ViewRankedPlayer2Callback, szQuery, client, DBPrio_Low);
}

public void SQL_ViewRankedPlayer2Callback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_ViewRankedPlayer2Callback): %s", error);
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		if (!IsValidClient(data))
			return;

		char szQuery[512];
		char szName[MAX_NAME_LENGTH];
		char szSteamIdTarget[32];
		SQL_FetchString(hndl, 0, szSteamIdTarget, 32);
		SQL_FetchString(hndl, 1, szName, MAX_NAME_LENGTH);

		Handle pack = CreateDataPack();
		WritePackCell(pack, data);
		WritePackString(pack, szName);
		Format(szQuery, 512, sql_selectChallengesCompare, g_szSteamID[data], szSteamIdTarget, szSteamIdTarget, g_szSteamID[data]);
		SQL_TQuery(g_hDb, sql_selectChallengesCompareCallback, szQuery, pack, DBPrio_Low);
	}
}

public void db_viewPlayerAll2(int client, char szPlayerName[MAX_NAME_LENGTH])
{
	char szQuery[512];
	char szName[MAX_NAME_LENGTH * 2 + 1];
	SQL_EscapeString(g_hDb, szPlayerName, szName, MAX_NAME_LENGTH * 2 + 1);
	Format(szQuery, 512, sql_selectPlayerRankAll, PERCENT, szName, PERCENT);
	Handle pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackString(pack, szPlayerName);
	SQL_TQuery(g_hDb, SQL_ViewPlayerAll2Callback, szQuery, pack, DBPrio_Low);
}

public void SQL_ViewPlayerAll2Callback(Handle owner, Handle hndl, const char[] error, any data)
{

	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_ViewPlayerAll2Callback): %s", error);
		return;
	}

	char szName[MAX_NAME_LENGTH];
	char szSteamId2[32];

	ResetPack(data);
	int client = ReadPackCell(data);
	ReadPackString(data, szName, MAX_NAME_LENGTH);
	if (!IsValidClient(client))
	{
		CloseHandle(data);
		return;
	}
	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 1, szSteamId2, 32);
		if (!StrEqual(szSteamId2, g_szSteamID[client]))
			db_viewPlayerRank2(client, szSteamId2);
	}
	else
		PrintToChat(client, "%t", "PlayerNotFound", MOSSGREEN, WHITE, szName);
	CloseHandle(data);
}



public void db_viewPlayerAll(int client, char szPlayerName[MAX_NAME_LENGTH])
{
	char szQuery[512];
	char szName[MAX_NAME_LENGTH * 2 + 1];
	SQL_EscapeString(g_hDb, szPlayerName, szName, MAX_NAME_LENGTH * 2 + 1);
	Format(szQuery, 512, sql_selectPlayerRankAll, PERCENT, szName, PERCENT);
	SQL_TQuery(g_hDb, SQL_ViewPlayerAllCallback, szQuery, client, DBPrio_Low);
}


public void SQL_ViewPlayerAllCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_ViewPlayerAllCallback): %s", error);
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

public void ContinueRecalc(int client)
{
	//ON RECALC ALL
	if (client > MAXPLAYERS)
		CalculatePlayerRank(client);
	else
	{
		//ON CONNECT
		if (!IsValidClient(client) || IsFakeClient(client))
			return;
		float diff = GetGameTime() - g_fMapStartTime + 1.5;
		if (GetClientTime(client) < diff)
		{
			CalculatePlayerRank(client);
		}
		else
		{
			db_viewPlayerPoints(client);
		}
	}
}