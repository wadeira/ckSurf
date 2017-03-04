
// - PlayerSpawn -
public Action Event_OnPlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client != 0)
	{
		g_SpecTarget[client] = -1;
		g_bPause[client] = false;
		g_bFirstTimerStart[client] = true;
		SetEntityMoveType(client, MOVETYPE_WALK);
		SetEntityRenderMode(client, RENDER_NORMAL);

		//strip weapons
		if ((GetClientTeam(client) > 1) && IsValidClient(client))
		{
			StripAllWeapons(client);
			if (!IsFakeClient(client))
				GivePlayerItem(client, "weapon_usp_silencer");
			if (!g_bStartWithUsp[client])
			{
				int weapon = GetPlayerWeaponSlot(client, 2);
				if (weapon != -1 && !IsFakeClient(client))
					SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weapon);
			}
		}

		//NoBlock
		if (GetConVarBool(g_hCvarNoBlock) || IsFakeClient(client))
			SetEntData(client, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 2, 4, true);
		else
			SetEntData(client, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 5, 4, true);

		//botmimic2
		if (g_hBotMimicsRecord[client] != null && IsFakeClient(client))
		{
			g_BotMimicTick[client] = 0;
			g_CurrentAdditionalTeleportIndex[client] = 0;
		}

		if (IsFakeClient(client))
		{
			if (client == g_InfoBot)
				CS_SetClientClanTag(client, "");
			else if (client == g_RecordBot)
				CS_SetClientClanTag(client, "REPLAY");

			return Plugin_Continue;
		}

		//change player skin
		if (GetConVarBool(g_hPlayerSkinChange) && (GetClientTeam(client) > 1))
		{
			char szBuffer[256];
			GetConVarString(g_hArmModel, szBuffer, 256);
			SetEntPropString(client, Prop_Send, "m_szArmsModel", szBuffer);

			GetConVarString(g_hPlayerModel, szBuffer, 256);
			SetEntityModel(client, szBuffer);
		}

		//1st spawn & t/ct
		if (g_bFirstSpawn[client] && (GetClientTeam(client) > 1))
		{
			float fLocation[3];
			GetClientAbsOrigin(client, fLocation);
			if (setClientLocation(client, fLocation) == -1)
			{
				g_iClientInZone[client][2] = 0;
				g_bIgnoreZone[client] = false;
			}


			StartRecording(client);
			CreateTimer(1.5, CenterMsgTimer, client, TIMER_FLAG_NO_MAPCHANGE);
			g_bFirstSpawn[client] = false;
		}

		//get start pos for challenge
		GetClientAbsOrigin(client, g_fSpawnPosition[client]);

		//restore position
		if (!g_specToStage[client])
		{

			if ((GetClientTeam(client) > 1))
			{
				if (g_bRestorePosition[client])
				{
					g_bPositionRestored[client] = true;
					teleportEntitySafe(client, g_fPlayerCordsRestore[client], g_fPlayerAnglesRestore[client], NULL_VECTOR, false);
					g_bRestorePosition[client] = false;
				}
				else
				{
					if (g_bRespawnPosition[client])
					{
						teleportEntitySafe(client, g_fPlayerCordsRestore[client], g_fPlayerAnglesRestore[client], NULL_VECTOR, false);
						g_bRespawnPosition[client] = false;
					}
					else
					{
						g_bTimeractivated[client] = false;
						g_fStartTime[client] = -1.0;
						g_fCurrentRunTime[client] = -1.0;

						// Spawn client to the start zone.
						if (GetConVarBool(g_hSpawnToStartZone))
							Command_Restart(client, 1);
					}
				}
			}
		}
		else
		{
			Array_Copy(g_fTeleLocation[client], g_fPlayerCordsRestore[client], 3);
			Array_Copy(NULL_VECTOR, g_fPlayerAnglesRestore[client], 3);
			SetEntPropVector(client, Prop_Data, "m_vecVelocity", view_as<float>( { 0.0, 0.0, -100.0 } ));
			teleportEntitySafe(client, g_fTeleLocation[client], NULL_VECTOR, view_as<float>( { 0.0, 0.0, -100.0 } ), false);
			g_specToStage[client] = false;
		}

		//hide radar
		CreateTimer(0.0, HideHud, client, TIMER_FLAG_NO_MAPCHANGE);

		//set clantag
		CreateTimer(1.5, SetClanTag, client, TIMER_FLAG_NO_MAPCHANGE);

		//set speclist
		Format(g_szPlayerPanelText[client], 512, "");

		//get speed & origin
		g_fLastSpeed[client] = GetSpeed(client);
	}
	return Plugin_Continue;
}