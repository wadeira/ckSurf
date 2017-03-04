public Action Event_PlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{
	if (GetConVarBool(g_hDisconnectMsg))
	{
		char szName[64];
		char disconnectReason[64];
		int clientid = GetEventInt(event, "userid");
		int client = GetClientOfUserId(clientid);
		if (!IsValidClient(client) || IsFakeClient(client))
			return Plugin_Handled;
		GetEventString(event, "name", szName, sizeof(szName));
		GetEventString(event, "reason", disconnectReason, sizeof(disconnectReason));
		for (int i = 1; i <= MaxClients; i++)
			if (IsValidClient(i) && i != client && !IsFakeClient(i))
				PrintToChat(i, "%t", "Disconnected1", WHITE, MOSSGREEN, szName, WHITE, disconnectReason);
		return Plugin_Handled;
	}
	else
	{
		SetEventBroadcast(event, true);
		return Plugin_Handled;
	}
}
