public void db_viewPlayerOptions(int client, char szSteamId[32])
{
	char szQuery[512];
	Format(szQuery, 512, sql_selectPlayerOptions, szSteamId);
	SQL_TQuery(g_hDb, db_viewPlayerOptionsCallback, szQuery, client, DBPrio_Low);
}

public void db_viewPlayerOptionsCallback(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (db_viewPlayerOptionsCallback): %s", error);
		if (!g_bSettingsLoaded[client])
			db_viewPersonalFlags(client, g_szSteamID[client]);
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		//"SELECT speedmeter, quake_sounds, shownames, goto, showtime, hideplayers, showspecs, knife, new1, new2, new3, checkpoints FROM ck_playeroptions where steamid = '%s'";

		g_bInfoPanel[client] = view_as<bool>(SQL_FetchInt(hndl, 0));
		g_bEnableQuakeSounds[client] = view_as<bool>(SQL_FetchInt(hndl, 1));
		g_bShowNames[client] = view_as<bool>(SQL_FetchInt(hndl, 2));
		g_bGoToClient[client] = view_as<bool>(SQL_FetchInt(hndl, 3));
		g_bShowTime[client] = view_as<bool>(SQL_FetchInt(hndl, 4));
		g_bHide[client] = view_as<bool>(SQL_FetchInt(hndl, 5));
		g_bShowSpecs[client] = view_as<bool>(SQL_FetchInt(hndl, 6));
		g_bStartWithUsp[client] = view_as<bool>(SQL_FetchInt(hndl, 7));
		g_bHideChat[client] = view_as<bool>(SQL_FetchInt(hndl,9));
		g_bViewModel[client] = view_as<bool>(SQL_FetchInt(hndl, 10));
		g_bCheckpointsEnabled[client] = view_as<bool>(SQL_FetchInt(hndl, 11));
		g_bHideLeftHud[client] = view_as<bool>(SQL_FetchInt(hndl, 12));

		//org
		g_borg_InfoPanel[client] = g_bInfoPanel[client];
		g_borg_EnableQuakeSounds[client] = g_bEnableQuakeSounds[client];
		g_borg_ShowNames[client] = g_bShowNames[client];
		g_borg_GoToClient[client] = g_bGoToClient[client];
		g_borg_ShowTime[client] = g_bShowTime[client];
		g_borg_Hide[client] = g_bHide[client];
		g_borg_StartWithUsp[client] = g_bStartWithUsp[client];
		g_borg_ShowSpecs[client] = g_bShowSpecs[client];
		g_borg_HideChat[client] = g_bHideChat[client];
		g_borg_ViewModel[client] = g_bViewModel[client];
		g_borg_CheckpointsEnabled[client] = g_bCheckpointsEnabled[client];
	}
	else
	{
		char szQuery[512];
		if (!IsValidClient(client))
			return;

		//"INSERT INTO ck_playeroptions (steamid, speedmeter, quake_sounds, shownames, goto, showtime, hideplayers, showspecs, knife, new1, new2, new3) VALUES('%s', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%s', '%i', '%i', '%i');";

		Format(szQuery, 512, sql_insertPlayerOptions, g_szSteamID[client], 1, 1, 1, 1, 1, 0, 0, 1, "weapon_knife", 0, 0, 1, 1, 0);
		SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, DBPrio_Low);
		g_borg_InfoPanel[client] = true;
		g_borg_EnableQuakeSounds[client] = true;
		g_borg_ShowNames[client] = true;
		g_borg_GoToClient[client] = true;
		g_borg_ShowTime[client] = false;
		g_borg_Hide[client] = false;
		g_borg_ShowSpecs[client] = true;
		// weapon_knife
		g_borg_StartWithUsp[client] = false;
		g_borg_HideChat[client] = false;
		g_borg_ViewModel[client] = true;
		g_borg_CheckpointsEnabled[client] = true;
	}
	if (!g_bSettingsLoaded[client])
		db_viewPersonalFlags(client, g_szSteamID[client]);
	return;
}

public void db_updatePlayerOptions(int client)
{
	if (g_borg_ViewModel[client] != g_bViewModel[client] || g_borg_HideChat[client] != g_bHideChat[client] || g_borg_StartWithUsp[client] != g_bStartWithUsp[client] || g_borg_InfoPanel[client] != g_bInfoPanel[client] || g_borg_EnableQuakeSounds[client] != g_bEnableQuakeSounds[client] || g_borg_ShowNames[client] != g_bShowNames[client] || g_borg_GoToClient[client] != g_bGoToClient[client] || g_borg_ShowTime[client] != g_bShowTime[client] || g_borg_Hide[client] != g_bHide[client] || g_borg_ShowSpecs[client] != g_bShowSpecs[client] || g_borg_CheckpointsEnabled[client] != g_bCheckpointsEnabled[client])
	{
		char szQuery[1024];

		Format(szQuery, 1024, sql_updatePlayerOptions, BooltoInt(g_bInfoPanel[client]), BooltoInt(g_bEnableQuakeSounds[client]), BooltoInt(g_bShowNames[client]), BooltoInt(g_bGoToClient[client]), BooltoInt(g_bShowTime[client]), BooltoInt(g_bHide[client]), BooltoInt(g_bShowSpecs[client]), "weapon_knife", BooltoInt(g_bStartWithUsp[client]), BooltoInt(g_bHideChat[client]), BooltoInt(g_bViewModel[client]), BooltoInt(g_bCheckpointsEnabled[client]), BooltoInt(g_bHideLeftHud[client]), g_szSteamID[client]);
		SQL_TQuery(g_hDb, SQL_CheckCallback, szQuery, client, DBPrio_Low);
	}
}