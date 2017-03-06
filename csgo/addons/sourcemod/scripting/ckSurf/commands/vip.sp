
public Action Command_Vip(int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	if (!g_bflagTitles[client][0] && g_hFreeVipAtRank.IntValue < g_PlayerRank[client])
	{
		PrintToChat(client, "[%cSurf Timer%c] This command requires the VIP title.", MOSSGREEN, WHITE);
		return Plugin_Handled;
	}

	Menu vipEffects = CreateMenu(h_vipEffects);
	char szMenuItem[128];

	SetMenuTitle(vipEffects, "Exclusive VIP effects: ");

	if (!g_bTrailOn[client])
		Format(szMenuItem, 128, "[OFF] Player Trail");
	else
		Format(szMenuItem, 128, "[ON] Player Trail");
	AddMenuItem(vipEffects, "", szMenuItem);

	Format(szMenuItem, 128, "Trail Color: %s", RGB_COLOR_NAMES[g_iTrailColor[client]]);
	AddMenuItem(vipEffects, "", szMenuItem);
	AddMenuItem(vipEffects, "", "Vote to extend map (!ve)");

	if (GetConVarBool(g_hAllowVipMute))
		AddMenuItem(vipEffects, "", "Mute a player (!vmute)");
	else
		AddMenuItem(vipEffects, "", "Mute a player (!vmute)", ITEMDRAW_DISABLED);

	AddMenuItem(vipEffects, "", "More to come...", ITEMDRAW_DISABLED);

	SetMenuExitButton(vipEffects, true);
	DisplayMenu(vipEffects, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int h_vipEffects(Menu tMenu, MenuAction action, int client, int item)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (item)
			{
				case 0:
				{
					toggleTrail(client);
					CreateTimer(0.1, RefreshVIPMenu, client, TIMER_FLAG_NO_MAPCHANGE);
				}
				case 1:
				{
					CreateTimer(0.1, RefreshVIPMenu, client, TIMER_FLAG_NO_MAPCHANGE);
					changeTrailColor(client);
				}
				case 2:
				{
					Command_VoteExtend(client, 0);
				}
				case 3:
				{
					Command_MutePlayer(client, 0);
				}
			}
		}
		case MenuAction_End:
		{
			CloseHandle(tMenu);
		}
	}
}

public Action Command_MutePlayer (int client, int args)
{
	if (!IsValidClient(client))
		return Plugin_Handled;

	if (!GetConVarBool(g_hAllowVipMute))
	{
		ReplyToCommand(client, "[%cSurf Timer%c] VIP muting has been disabled on this server.", MOSSGREEN, WHITE);
		return Plugin_Handled;
	}


	if (!g_bflagTitles[client][0] && g_hFreeVipAtRank.IntValue < g_PlayerRank[client])
	{
		ReplyToCommand(client, "[%cSurf Timer%c] This command requires the VIP title.", MOSSGREEN, WHITE);
		return Plugin_Handled;
	}

	if (args > 0)
	{
		char szName[MAX_NAME_LENGTH], szBuffer[MAX_NAME_LENGTH];
		GetCmdArg(1, szName, MAX_NAME_LENGTH);

		int target = Client_FindByName(szName, true, false);

		if (target != -1)
		{
			if (BaseComm_IsClientMuted(target))
			{
				if (BaseComm_SetClientMute(target, false))
					PrintToChatAll("[%cSurf Timer%c] %s was unmuted by a VIP.", MOSSGREEN, WHITE, szBuffer);
			}
			else
			{
				if (BaseComm_SetClientMute(target, true))
					PrintToChatAll("[%cSurf Timer%c] %s was muted by a VIP.", MOSSGREEN, WHITE, szBuffer);
			}
			return Plugin_Handled;
		}
		else
		{
			PrintToChat(client, "[%cSurf Timer%c] Could not find a player with the name of %s.", MOSSGREEN, WHITE, szName);
			return Plugin_Handled;
		}
	}

	Menu mMutePlayers = CreateMenu(h_MutePlayers);
	SetMenuTitle(mMutePlayers, "Select player to mute or unmute");
	char szMenuItem[48], id[8], count;
	for (int i = 0; i < MAXPLAYERS+1; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i) && client != i)
		{
			count++;
			IntToString(i, id, 8);
			if (BaseComm_IsClientMuted(i))
			{
				GetClientName(i, szMenuItem, 48);
				Format(szMenuItem, 48, "[ON] %s", szMenuItem);
			}
			else
			{
				GetClientName(i, szMenuItem, 48);
				Format(szMenuItem, 48, "[OFF] %s", szMenuItem);
			}
			AddMenuItem(mMutePlayers, id, szMenuItem);
		}
	}
	if (count == 0)
	{
		ReplyToCommand(client, "[%cSurf Timer%c] No valid players found.", MOSSGREEN, WHITE);
		CloseHandle(mMutePlayers);
		return Plugin_Handled;
	}
	SetMenuExitButton(mMutePlayers, true);
	DisplayMenu(mMutePlayers, client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int h_MutePlayers(Menu tMenu, MenuAction action, int client, int item)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			char aID[8];
			GetMenuItem(tMenu, item, aID, sizeof(aID));
			int clientID = StringToInt(aID);
			if (IsValidClient(clientID))
			{
				char szName[MAX_NAME_LENGTH];
				GetClientName(clientID, szName, MAX_NAME_LENGTH);
				if (BaseComm_IsClientMuted(clientID))
				{
					if (BaseComm_SetClientMute(clientID, false))
						PrintToChatAll("[%cSurf Timer%c] %s was unmuted by a VIP.", MOSSGREEN, WHITE, szName);
				}
				else
				{
					if (BaseComm_SetClientMute(clientID, true))
						PrintToChatAll("[%cSurf Timer%c] %s was muted by a VIP.", MOSSGREEN, WHITE, szName);

				}
			}
		}
		case MenuAction_End:
		{
			CloseHandle(tMenu);
		}
	}
}


public Action Command_VoteExtend(int client, int args)
{
	if(!IsValidClient(client))
		return Plugin_Handled;

	if (!g_bflagTitles[client][0] && g_hFreeVipAtRank.IntValue < g_PlayerRank[client])
	{
		ReplyToCommand(client, "[Surf Timer] This command requires the VIP title.");
		return Plugin_Handled;
	}

	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[Surf Timer] Please wait until the current vote has finished.");
		return Plugin_Handled;
	}

	if (g_VoteExtends >= GetConVarInt(g_hMaxVoteExtends))
	{
		ReplyToCommand(client, "[Surf Timer] There have been too many extends this map.");
		return Plugin_Handled;
	}

	// Here we go through and make sure this user has not already voted. This persists throughout map.
	for (int i = 0; i < g_VoteExtends; i++)
	{
		if (StrEqual(g_szUsedVoteExtend[i], g_szSteamID[client], false))
		{
			ReplyToCommand(client, "[Surf Timer] You have already used your vote to extend this map.");
			return Plugin_Handled;
		}
	}

	StartVoteExtend(client);
	return Plugin_Handled;
}

public void StartVoteExtend(int client)
{
	char szPlayerName[MAX_NAME_LENGTH];
	GetClientName(client, szPlayerName, MAX_NAME_LENGTH);
	CPrintToChatAll("[{olive}CK{default}] Vote to Extend started by {green}%s{default}", szPlayerName);

	g_szUsedVoteExtend[g_VoteExtends] = g_szSteamID[client];	// Add the user's steam ID to the list
	g_VoteExtends++;	// Increment the total number of vote extends so far

	Menu voteExtend = CreateMenu(H_VoteExtend);
	SetVoteResultCallback(voteExtend, H_VoteExtendCallback);
	char szMenuTitle[128];

	char buffer[8];
	IntToString(RoundToFloor(GetConVarFloat(g_hVoteExtendTime)), buffer, sizeof(buffer));

	Format(szMenuTitle, sizeof(szMenuTitle), "Extend map for %s minutes?", buffer);
	SetMenuTitle(voteExtend, szMenuTitle);

	AddMenuItem(voteExtend, "", "Yes");
	AddMenuItem(voteExtend, "", "No");
	SetMenuExitButton(voteExtend, false);
	VoteMenuToAll(voteExtend, 20);
}

public int H_VoteExtend(Menu tMenu, MenuAction action, int client, int item)
{
	if (action == MenuAction_End)
	{
		CloseHandle(tMenu);
	}
}

public void H_VoteExtendCallback(Menu menu, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	int votesYes = 0;
	int votesNo = 0;

	if (item_info[0][VOTEINFO_ITEM_INDEX] == 0)
	{	// If the winner is Yes
		votesYes = item_info[0][VOTEINFO_ITEM_VOTES];
		if (num_items > 1)
		{
			votesNo = item_info[1][VOTEINFO_ITEM_VOTES];
		}
	}
	else
	{	// If the winner is No
		votesNo = item_info[0][VOTEINFO_ITEM_VOTES];
		if (num_items > 1)
		{
			votesYes = item_info[1][VOTEINFO_ITEM_VOTES];
		}
	}

	if (votesYes > votesNo) // A tie is a failure
	{
		CPrintToChatAll("[{olive}CK{default}] Vote to Extend succeeded - Votes Yes: %i | Votes No: %i", votesYes, votesNo);
		ExtendMapTimeLimit(RoundToFloor(GetConVarFloat(g_hVoteExtendTime)*60));
	}
	else
	{
		CPrintToChatAll("[{olive}CK{default}] Vote to Extend failed - Votes Yes: %i | Votes No: %i", votesYes, votesNo);
	}
}