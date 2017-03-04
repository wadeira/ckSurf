
public void db_getChatTags(int client) {
	char query[256];
	Format(query, sizeof(query), "SELECT tag, name FROM ck_playerchat WHERE steamid = '%s'", g_szSteamID[client]);

	SQL_TQuery(g_hDb, SQL_getCustomChatTags, query, client, DBPrio_Low);
}


public void SQL_getCustomChatTags(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_getCustomChatTags): %s", error);
		return;
	}

	if (SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		g_bHasChatTag[client] = true;

		SQL_FetchString(hndl, 0, g_cChatTag[client], sizeof(g_cChatTag[]));
		SQL_FetchString(hndl, 1, g_cCustomName[client], sizeof(g_cCustomName[]));

		if (strlen(g_cCustomName[client]) <= 0)
		{
			Format(g_cCustomName[client], sizeof(g_cCustomName[]), "{teamcolor}%N", client);
		}
	}
}


public void db_setPlayerTag(int client, const char[] tag)
{
	char query[256];
	Format(query, sizeof(query), "INSERT INTO ck_playerchat (`tag`, `steamid`) VALUES ('%s', '%s') ON DUPLICATE KEY UPDATE tag=VALUES(`tag`)", tag, g_szSteamID[client]);

	SQL_TQuery(g_hDb, SQL_setPlayerTag, query, client, DBPrio_Low);
}


public void SQL_setPlayerTag(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_setPlayerTag): %s", error);
		return;
	}

	db_getChatTags(client);
}


public void db_setPlayerName(int client, const char[] name)
{
	char query[256];
	Format(query, sizeof(query), "INSERT INTO ck_playerchat (`name`, `steamid`) VALUES ('%s', '%s') ON DUPLICATE KEY UPDATE name=VALUES(`name`)", name, g_szSteamID[client]);

	SQL_TQuery(g_hDb, SQL_setPlayerName, query, client, DBPrio_Low);
}


public void SQL_setPlayerName(Handle owner, Handle hndl, const char[] error, any client)
{
	if (hndl == null)
	{
		LogError("[Surf Timer] SQL Error (SQL_setPlayerName): %s", error);
		return;
	}

	db_getChatTags(client);
}