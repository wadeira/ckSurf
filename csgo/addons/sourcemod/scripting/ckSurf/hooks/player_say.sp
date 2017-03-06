public Action SayText2(UserMsg msg_id, Handle bf, int[] players, int playersNum, bool reliable, bool init)
{
	if (!reliable)return Plugin_Continue;
	char buffer[25];
	if (GetUserMessageType() == UM_Protobuf)
	{
		PbReadString(bf, "msg_name", buffer, sizeof(buffer));
		if (StrEqual(buffer, "#Cstrike_Name_Change"))
			return Plugin_Handled;
	}
	else
	{
		BfReadChar(bf);
		BfReadChar(bf);
		BfReadString(bf, buffer, sizeof(buffer));

		if (StrEqual(buffer, "#Cstrike_Name_Change"))
			return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Say_Hook(int client, const char[] command, int argc)
{
	//Call Admin - Own Reason
	if (g_bClientOwnReason[client])
	{
		g_bClientOwnReason[client] = false;
		return Plugin_Continue;
	}

	char sText[1024];
	GetCmdArgString(sText, sizeof(sText));

	StripQuotes(sText);
	TrimString(sText);

	if (IsValidClient(client) && g_ClientRenamingZone[client])
	{
		Admin_renameZone(client, sText);
		return Plugin_Handled;
	}

	if (!GetConVarBool(g_henableChatProcessing))
		return Plugin_Continue;

	if (IsValidClient(client))
	{
		if (client > 0)
			if (BaseComm_IsClientGagged(client))
			return Plugin_Handled;

		//blocked commands
		for (int i = 0; i < sizeof(g_BlockedChatText); i++)
		{
			if (StrEqual(g_BlockedChatText[i], sText, true))
			{

				return Plugin_Handled;
			}
		}

		// !s and !stage commands
		if (StrContains(sText, "!s", false) == 0 || StrContains(sText, "!stage", false) == 0)
			return Plugin_Handled;

		// !b and !bonus commands
		if (StrContains(sText, "!b", false) == 0 || StrContains(sText, "!bonus", false) == 0)
			return Plugin_Handled;

		//empty message
		if (StrEqual(sText, " ") || !sText[0])
			return Plugin_Handled;

		if (checkSpam(client))
			return Plugin_Handled;

		parseColorsFromString(sText, 1024);

		//lowercase
		if ((sText[0] == '/') || (sText[0] == '!'))
		{
			if (IsCharUpper(sText[1]))
			{
				for (int i = 0; i <= strlen(sText); ++i)
					sText[i] = CharToLower(sText[i]);
				FakeClientCommand(client, "say %s", sText);
				return Plugin_Handled;
			}
		}

		//chat trigger?
		if ((IsChatTrigger() && sText[0] == '/') || (sText[0] == '@' && (GetUserFlagBits(client) & ADMFLAG_ROOT || GetUserFlagBits(client) & ADMFLAG_GENERIC)))
		{
			return Plugin_Continue;
		}

		char szName[64];
		GetClientName(client, szName, 64);

		//log the chat of the player to the server so that tools such as HLSW/HLSTATX see it and also it remains logged in the log file
		WriteChatLog(client, "say", sText);
		PrintToServer("%s: %s", szName, sText);

		parseColorsFromString(szName, 64);

		if (GetConVarBool(g_hPointSystem) && GetConVarBool(g_hColoredNames))
			setNameColor(szName, g_PlayerChatRank[client], 64);

		if (g_bHasChatTag[client])
		{
			if (strlen(g_cChatTag[client]) < 1)
				CPrintToChatAllEx(client, "%s %s{default}: %s", g_pr_chat_coloredrank[client], g_cCustomName[client], sText);
			else
				CPrintToChatAllEx(client, "%s %s{default}: %s", g_cChatTag[client], g_cCustomName[client], sText);

			return Plugin_Handled;
		}


		if (GetClientTeam(client) == 1)
		{
			PrintSpecMessageAll(client);
			return Plugin_Handled;
		}
		else
		{
			char szChatRank[64];
			Format(szChatRank, 64, "%s", g_pr_chat_coloredrank[client]);

			if (GetConVarBool(g_hCountry) && (GetConVarBool(g_hPointSystem) || (StrEqual(g_pr_rankname[client], "ADMIN", false) && GetConVarBool(g_hAdminClantag))))
			{
				if (IsPlayerAlive(client))
					CPrintToChatAllEx(client, "{green}%s{default} %s {teamcolor}%s{default}: %s", g_szCountryCode[client], szChatRank, szName, sText);
				else
					CPrintToChatAllEx(client, "{green}%s{default} %s {teamcolor}*DEAD* %s{default}: %s", g_szCountryCode[client], szChatRank, szName, sText);
				return Plugin_Handled;
			}
			else
			{
				if (GetConVarBool(g_hPointSystem) || ((StrEqual(g_pr_rankname[client], "ADMIN", false)) && GetConVarBool(g_hAdminClantag)))
				{
					if (IsPlayerAlive(client))
						CPrintToChatAllEx(client, "%s {teamcolor}%s{default}: %s", szChatRank, szName, sText);
					else
						CPrintToChatAllEx(client, "%s {teamcolor}*DEAD* %s{default}: %s", szChatRank, szName, sText);
					return Plugin_Handled;
				}
				else
					if (GetConVarBool(g_hCountry))
				{
					if (IsPlayerAlive(client))
						CPrintToChatAllEx(client, "[{green}%s{default}] {teamcolor}%s{default}: %s", g_szCountryCode[client], szName, sText);
					else
						CPrintToChatAllEx(client, "[{green}%s{default}] {teamcolor}*DEAD* %s{default}: %s", g_szCountryCode[client], szName, sText);
					return Plugin_Handled;
				}
			}
		}
	}
	return Plugin_Continue;
}