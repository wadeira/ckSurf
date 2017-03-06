public Action Event_OnPlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetEventInt(event, "userid");
	if (IsValidClient(client))
	{
		if (!IsFakeClient(client))
		{
			if (g_hRecording[client] != null)
				StopRecording(client);
			CreateTimer(2.0, RemoveRagdoll, client);
		}
		else
			if (g_hBotMimicsRecord[client] != null)
			{
				g_BotMimicTick[client] = 0;
				g_CurrentAdditionalTeleportIndex[client] = 0;
				if (GetClientTeam(client) >= CS_TEAM_T)
					CreateTimer(1.0, RespawnBot, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
			}
	}
	return Plugin_Continue;
}
