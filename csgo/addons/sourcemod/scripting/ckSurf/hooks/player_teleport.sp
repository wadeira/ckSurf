
//dhooks
public MRESReturn DHooks_OnTeleport(int client, Handle hParams)
{

	if (!IsValidClient(client))
		return MRES_Ignored;

	if (g_bPushing[client])
	{
		g_bPushing[client] = false;
		return MRES_Ignored;
	}

	if (g_bFixingRamp[client])
	{
		g_bFixingRamp[client] = false;
		return MRES_Ignored;
	}

	g_vLastGroundTouch[client][2] = -99999.0;

	// This one is currently mimicing something.
	if (g_hBotMimicsRecord[client] != null)
	{
		// We didn't allow that teleporting. STOP THAT.
		if (!g_bValidTeleportCall[client])
			return MRES_Supercede;
		g_bValidTeleportCall[client] = false;
		return MRES_Ignored;
	}

	// Don't care if he's not recording.
	if (g_hRecording[client] == null)
		return MRES_Ignored;

	bool bOriginNull = DHookIsNullParam(hParams, 1);
	bool bAnglesNull = DHookIsNullParam(hParams, 2);
	bool bVelocityNull = DHookIsNullParam(hParams, 3);

	float origin[3], angles[3], velocity[3];

	if (!bOriginNull)
		DHookGetParamVector(hParams, 1, origin);

	if (!bAnglesNull)
	{
		for (int i = 0; i < 3; i++)
			angles[i] = DHookGetParamObjectPtrVar(hParams, 2, i * 4, ObjectValueType_Float);
	}

	if (!bVelocityNull)
		DHookGetParamVector(hParams, 3, velocity);

	if (bOriginNull && bAnglesNull && bVelocityNull)
		return MRES_Ignored;

	int iAT[AT_SIZE];
	Array_Copy(origin, iAT[atOrigin], 3);
	Array_Copy(angles, iAT[atAngles], 3);
	Array_Copy(velocity, iAT[atVelocity], 3);

	// Remember,
	if (!bOriginNull)
		iAT[atFlags] |= ADDITIONAL_FIELD_TELEPORTED_ORIGIN;
	if (!bAnglesNull)
		iAT[atFlags] |= ADDITIONAL_FIELD_TELEPORTED_ANGLES;
	if (!bVelocityNull)
		iAT[atFlags] |= ADDITIONAL_FIELD_TELEPORTED_VELOCITY;

	if (g_hRecordingAdditionalTeleport[client] != null)
		PushArrayArray(g_hRecordingAdditionalTeleport[client], iAT, AT_SIZE);

	return MRES_Ignored;
}
