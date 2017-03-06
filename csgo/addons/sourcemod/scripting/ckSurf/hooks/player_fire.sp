//attack spam protection
public Action Event_OnFire(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client > 0 && IsClientInGame(client) && GetConVarBool(g_hAttackSpamProtection))
	{
		char weapon[64];
		GetEventString(event, "weapon", weapon, 64);
		if (StrContains(weapon, "knife", true) == -1 && g_AttackCounter[client] < 41)
		{
			if (g_AttackCounter[client] < 41)
			{
				g_AttackCounter[client]++;
				if (StrContains(weapon, "grenade", true) != -1 || StrContains(weapon, "flash", true) != -1)
				{
					g_AttackCounter[client] = g_AttackCounter[client] + 9;
					if (g_AttackCounter[client] > 41)
						g_AttackCounter[client] = 41;
				}
			}
		}
	}
}
