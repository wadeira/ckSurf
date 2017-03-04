public void db_deleteTmp(int client)
{
	char szQuery[256];
	if (!IsValidClient(client))
		return;
	Format(szQuery, 256, sql_deletePlayerTmp, g_szSteamID[client]);
	SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, client, DBPrio_Low);
}

public void db_selectLastRun(int client)
{
	char szQuery[512];
	if (!IsValidClient(client))
		return;
	Format(szQuery, 512, sql_selectPlayerTmp, g_szSteamID[client], g_szMapName);
	SQL_TQuery(g_hDb, SQL_LastRunCallback, szQuery, client, DBPrio_Low);
}

public void SQL_LastRunCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_LastRunCallback): %s", error);
		return;
	}

	g_bTimeractivated[data] = false;
	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl) && IsValidClient(data))
	{

		//"SELECT cords1,cords2,cords3, angle1, angle2, angle3,runtimeTmp, EncTickrate, Stage, zonegroup FROM ck_playertemp WHERE steamid = '%s' AND mapname = '%s';";

		//Get last psition
		g_fPlayerCordsRestore[data][0] = SQL_FetchFloat(hndl, 0);
		g_fPlayerCordsRestore[data][1] = SQL_FetchFloat(hndl, 1);
		g_fPlayerCordsRestore[data][2] = SQL_FetchFloat(hndl, 2);
		g_fPlayerAnglesRestore[data][0] = SQL_FetchFloat(hndl, 3);
		g_fPlayerAnglesRestore[data][1] = SQL_FetchFloat(hndl, 4);
		g_fPlayerAnglesRestore[data][2] = SQL_FetchFloat(hndl, 5);


		int zGroup;
		zGroup = SQL_FetchInt(hndl, 9);

		g_iClientInZone[data][2] = zGroup;

		g_Stage[zGroup][data] = SQL_FetchInt(hndl, 8);

		//Set new start time
		float fl_time = SQL_FetchFloat(hndl, 6);
		int tickrate = RoundFloat(float(SQL_FetchInt(hndl, 7)) / 5.0 / 11.0);
		if (tickrate == g_Server_Tickrate)
		{
			if (fl_time > 0.0)
			{
				g_fStartTime[data] = GetGameTime() - fl_time;
				g_bTimeractivated[data] = true;
			}

			if (SQL_FetchFloat(hndl, 0) == -1.0 && SQL_FetchFloat(hndl, 1) == -1.0 && SQL_FetchFloat(hndl, 2) == -1.0)
			{
				g_bRestorePosition[data] = false;
				g_bRestorePositionMsg[data] = false;
			}
			else
			{
				if (g_bLateLoaded && IsPlayerAlive(data) && !g_specToStage[data])
				{
					g_bPositionRestored[data] = true;
					TeleportEntity(data, g_fPlayerCordsRestore[data], g_fPlayerAnglesRestore[data], NULL_VECTOR);
					g_bRestorePosition[data] = false;
				}
				else
				{
					g_bRestorePosition[data] = true;
					g_bRestorePositionMsg[data] = true;
				}

			}
		}
	}
	else
	{

		g_bTimeractivated[data] = false;
	}
}
