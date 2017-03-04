// PlayerDamage (if godmode 0)
public Action Hook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (GetConVarBool(g_hCvarGodMode))
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
