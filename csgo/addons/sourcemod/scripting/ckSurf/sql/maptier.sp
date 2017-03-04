public void db_insertMapTier(int tier, int zGrp)
{
	char szQuery[256];
	if (g_bTierEntryFound)
	{
		if (zGrp > 0)
		{
			Format(szQuery, 256, sql_updateBonusTier, zGrp, tier, g_szMapName);
		}
		else
		{
			Format(szQuery, 256, sql_updatemaptier, tier, g_szMapName);
		}
		SQL_TQuery(g_hDb, db_insertMapTierCallback, szQuery, 1, DBPrio_Low);
	}
	else
	{
		if (zGrp > 0)
		{
			Format(szQuery, 256, sql_insertBonusTier, zGrp, tier, g_szMapName);
		}
		else
		{
			Format(szQuery, 256, sql_insertmaptier, g_szMapName, tier);
		}
		SQL_TQuery(g_hDb, db_insertMapTierCallback, szQuery, 1, DBPrio_Low);
	}
}

public void db_insertMapTierCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (db_insertMapTierCallback): %s", error);
		return;
	}

	db_selectMapTier();
}

public void db_selectMapTier()
{
	g_bTierEntryFound = false;

	char szQuery[1024];
	Format(szQuery, 1024, sql_selectMapTier, g_szMapName);
	SQL_TQuery(g_hDb, SQL_selectMapTierCallback, szQuery, 1, DBPrio_Low);
}

public void SQL_selectMapTierCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_selectMapTierCallback): %s", error);
		if (!g_bServerDataLoaded)
			db_viewRecordCheckpointInMap();
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		g_bTierEntryFound = true;
		int tier;

		// Format tier string for all
		for (int i = 0; i < 11; i++)
		{
			tier = SQL_FetchInt(hndl, i);
			if (0 < tier < 7)
			{
				g_bTierFound[i] = true;
				if (i == 0)
				{
					Format(g_sTierString[0], 512, " [%cSurf Timer%c] %cMap: %c%s %c| ", MOSSGREEN, WHITE, GREEN, LIMEGREEN, g_szMapName, GREEN);
					switch (tier)
					{
						case 1:Format(g_sTierString[0], 512, "%s%cTier %i %c| ", g_sTierString[0], GRAY, tier, GREEN);
						case 2:Format(g_sTierString[0], 512, "%s%cTier %i %c| ", g_sTierString[0], LIGHTBLUE, tier, GREEN);
						case 3:Format(g_sTierString[0], 512, "%s%cTier %i %c| ", g_sTierString[0], BLUE, tier, GREEN);
						case 4:Format(g_sTierString[0], 512, "%s%cTier %i %c| ", g_sTierString[0], DARKBLUE, tier, GREEN);
						case 5:Format(g_sTierString[0], 512, "%s%cTier %i %c| ", g_sTierString[0], RED, tier, GREEN);
						case 6:Format(g_sTierString[0], 512, "%s%cTier %i %c| ", g_sTierString[0], DARKRED, tier, GREEN);
						default:Format(g_sTierString[0], 512, "%s%cTier %i %c| ", g_sTierString[0], GRAY, tier, GREEN);
					}
					if (g_bhasStages)
						Format(g_sTierString[0], 512, "%s%c%i Stages", g_sTierString[0], MOSSGREEN, (g_mapZonesTypeCount[0][3] + 1));
					else
						Format(g_sTierString[0], 512, "%s%cLinear", g_sTierString[0], LIMEGREEN);

					if (g_bhasBonus)
						if (g_mapZoneGroupCount > 2)
							Format(g_sTierString[0], 512, "%s %c|%c %i Bonuses", g_sTierString[0], GREEN, YELLOW, (g_mapZoneGroupCount - 1));
						else
							Format(g_sTierString[0], 512, "%s %c|%c Bonus", g_sTierString[0], GREEN, YELLOW, (g_mapZoneGroupCount - 1));
				}
				else
				{
					switch (tier)
					{
						case 1:Format(g_sTierString[i], 512, "[%cSurf Timer%c] &c%s Tier: %i", MOSSGREEN, WHITE, GRAY, g_szZoneGroupName[i], tier);
						case 2:Format(g_sTierString[i], 512, "[%cSurf Timer%c] &c%s Tier: %i", MOSSGREEN, WHITE, LIGHTBLUE, g_szZoneGroupName[i], tier);
						case 3:Format(g_sTierString[i], 512, "[%cSurf Timer%c] &c%s Tier: %i", MOSSGREEN, WHITE, BLUE, g_szZoneGroupName[i], tier);
						case 4:Format(g_sTierString[i], 512, "[%cSurf Timer%c] &c%s Tier: %i", MOSSGREEN, WHITE, DARKBLUE, g_szZoneGroupName[i], tier);
						case 5:Format(g_sTierString[i], 512, "[%cSurf Timer%c] &c%s Tier: %i", MOSSGREEN, WHITE, RED, g_szZoneGroupName[i], tier);
						case 6:Format(g_sTierString[i], 512, "[%cSurf Timer%c] &c%s Tier: %i", MOSSGREEN, WHITE, DARKRED, g_szZoneGroupName[i], tier);
					}
				}
			}
		}
	}
	else
		g_bTierEntryFound = false;

	if (!g_bServerDataLoaded)
		db_viewRecordCheckpointInMap();

	return;
}


public void db_deleteAllMaptiers(int client)
{
	char szQuery[128];
	Format(szQuery, 128, sql_deleteAllMapTiers);
	SQL_TQuery(g_hDb, SQL_deleteAllMapTiersCallback, szQuery, client, DBPrio_Low);
}

public void SQL_deleteAllMapTiersCallback(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_deleteAllMapTiersCallback): %s", error);
		return;
	}

	Admin_InsertMapTierstoDatabase(data);
}