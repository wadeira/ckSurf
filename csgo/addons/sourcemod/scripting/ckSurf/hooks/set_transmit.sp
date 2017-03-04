
public Action Hook_SetTransmit(int entity, int client)
{
	if (client != entity && (0 < entity <= MaxClients) && IsValidClient(client))
	{
		if (g_bChallenge[client] && !g_bHide[client])
		{
			if (!StrEqual(g_szSteamID[entity], g_szChallenge_OpponentID[client], false))
				return Plugin_Handled;
		}
		else
			if (g_bHide[client] && entity != g_SpecTarget[client])
				return Plugin_Handled;
			else
				if (entity == g_InfoBot && entity != g_SpecTarget[client])
					return Plugin_Handled;
	}
	return Plugin_Continue;
}
