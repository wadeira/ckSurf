public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{

	if (g_bRoundEnd || !IsValidClient(client))
		return Plugin_Continue;

	if (IsPlayerAlive(client))
	{
		g_bLastOnGround[client] = g_bOnGround[client];
		if (GetEntityFlags(client) & FL_ONGROUND) {
			g_bOnGround[client] = true;
			GetEntPropVector(client, Prop_Data, "m_vecOrigin", g_vLastGroundTouch[client]);
		}
		else
			g_bOnGround[client] = false;

		float newVelocity[3];
		// Slope Boost Fix by Mev, & Blacky
		// https://forums.alliedmods.net/showthread.php?t=266888
		//if (GetConVarBool(g_hSlopeFixEnable) == true)
		if (GetConVarBool(g_hSlopeFixEnable) == true && !IsFakeClient(client))
		{
			g_vLast[client][0] = g_vCurrent[client][0];
			g_vLast[client][1] = g_vCurrent[client][1];
			g_vLast[client][2] = g_vCurrent[client][2];
			g_vCurrent[client][0] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[0]");
			g_vCurrent[client][1] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[1]");
			g_vCurrent[client][2] = GetEntPropFloat(client, Prop_Send, "m_vecVelocity[2]");

			// Check if player landed on the ground
			if (g_bOnGround[client] == true && g_bLastOnGround[client] == false)
			{
				// Set up and do tracehull to find out if the player landed on a slope
				float vPos[3];
				GetEntPropVector(client, Prop_Data, "m_vecOrigin", vPos);

				float vMins[3];
				GetEntPropVector(client, Prop_Send, "m_vecMins", vMins);

				float vMaxs[3];
				GetEntPropVector(client, Prop_Send, "m_vecMaxs", vMaxs);

				float vEndPos[3];
				vEndPos[0] = vPos[0];
				vEndPos[1] = vPos[1];
				vEndPos[2] = vPos[2] - FindConVar("sv_maxvelocity").FloatValue;

				TR_TraceHullFilter(vPos, vEndPos, vMins, vMaxs, MASK_PLAYERSOLID_BRUSHONLY, TraceRayDontHitSelf, client);

				if (TR_DidHit())
				{
					// Gets the normal vector of the surface under the player
					float vPlane[3], vLast[3];
					TR_GetPlaneNormal(INVALID_HANDLE, vPlane);

					// Make sure it's not flat ground and not a surf ramp (1.0 = flat ground, < 0.7 = surf ramp)
					if (0.7 <= vPlane[2] < 1.0)
					{
						/*
						Copy the ClipVelocity function from sdk2013
						(https://mxr.alliedmods.net/hl2sdk-sdk2013/source/game/shared/gamemovement.cpp#3145)
						With some minor changes to make it actually work
						*/
						vLast[0] = g_vLast[client][0];
						vLast[1] = g_vLast[client][1];
						vLast[2] = g_vLast[client][2];
						vLast[2] -= (FindConVar("sv_gravity").FloatValue * GetTickInterval() * 0.5);

						float fBackOff = GetVectorDotProduct(vLast, vPlane);

						float change, vVel[3];
						for (int i; i < 2; i++)
						{
							change = vPlane[i] * fBackOff;
							vVel[i] = vLast[i] - change;
						}

						float fAdjust = GetVectorDotProduct(vVel, vPlane);
						if (fAdjust < 0.0)
						{
							for (int i; i < 2; i++)
							{
								vVel[i] -= (vPlane[i] * fAdjust);
							}
						}

						vVel[2] = 0.0;
						vLast[2] = 0.0;

						// Make sure the player is going down a ramp by checking if they actually will gain speed from the boost
						if (GetVectorLength(vVel) > GetVectorLength(vLast))
						{
							// Teleport the player, also adds basevelocity
							if (GetEntityFlags(client) & FL_BASEVELOCITY)
							{
								float vBase[3];
								GetEntPropVector(client, Prop_Data, "m_vecBaseVelocity", vBase);

								AddVectors(vVel, vBase, vVel);
							}
							g_bFixingRamp[client] = true;
							Array_Copy(vVel, newVelocity, 3);
							TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel);
						}
					}
				}
			}
		}

		if (newVelocity[0] == 0.0 && newVelocity[1] == 0.0 && newVelocity[2] == 0.0)
		{
			RecordReplay(client, buttons, subtype, seed, impulse, weapon, angles, vel);
			if (IsFakeClient(client) && g_bIsPlayingReplay)
				PlayReplay(client, buttons, subtype, seed, impulse, weapon, angles, vel);
		}
		else
		{
			RecordReplay(client, buttons, subtype, seed, impulse, weapon, angles, newVelocity);
			if (IsFakeClient(client) && g_bIsPlayingReplay)
				PlayReplay(client, buttons, subtype, seed, impulse, weapon, angles, newVelocity);
		}

		float speed, origin[3], ang[3];
		GetClientAbsOrigin(client, origin);
		GetClientEyeAngles(client, ang);

		speed = GetSpeed(client);


		checkTrailStatus(client, speed);

		//menu refreshing
		CheckRun(client);

		NoClipCheck(client);
		AttackProtection(client, buttons);

		// If in start zone, cap speed
		LimitSpeed(client);

		g_fLastSpeed[client] = speed;
		g_LastButton[client] = buttons;

		BeamBox_OnPlayerRunCmd(client);

		// Check if player is jumping
		if (!g_bPlayerIsJumping[client] && !(GetEntityFlags(client) & FL_ONGROUND))
		{
			g_PlayerJumpsInStage[client] += 1;
			g_bPlayerIsJumping[client] = true;
		}
		else if (GetEntityFlags(client) & FL_ONGROUND)
		{
			// Reset jump count if player is not bhopping
			if (!(buttons & IN_JUMP))
				g_PlayerJumpsInStage[client] = 0;

			g_bPlayerIsJumping[client] = false;
		}
	}

	if (GetClientTeam(client) == 1 && buttons & IN_USE) {

		int target = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");

		if (target == g_RecordBot)
			Command_Replay(client, 0);

	}

	return Plugin_Continue;
}