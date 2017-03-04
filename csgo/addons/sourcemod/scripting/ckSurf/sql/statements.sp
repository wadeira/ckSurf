
//TABLE PLAYERRANK
char sql_createPlayerRank[] = "CREATE TABLE IF NOT EXISTS ck_playerrank (steamid VARCHAR(32), name VARCHAR(32), country VARCHAR(32), points INT(12)  DEFAULT '0', winratio INT(12)  DEFAULT '0', pointsratio INT(12)  DEFAULT '0',finishedmaps INT(12) DEFAULT '0', multiplier INT(12) DEFAULT '0', finishedmapspro INT(12) DEFAULT '0', lastseen DATE, PRIMARY KEY(steamid));";
char sql_insertPlayerRank[] = "INSERT INTO ck_playerrank (steamid, name, country) VALUES('%s', '%s', '%s');";
char sql_updatePlayerRankPoints[] = "UPDATE ck_playerrank SET name ='%s', points ='%i', finishedmapspro='%i',winratio = '%i',pointsratio = '%i' where steamid='%s'";
char sql_updatePlayerRankPoints2[] = "UPDATE ck_playerrank SET name ='%s', points ='%i', finishedmapspro='%i',winratio = '%i',pointsratio = '%i', country ='%s' where steamid='%s'";
char sql_updatePlayerRank[] = "UPDATE ck_playerrank SET finishedmaps ='%i', finishedmapspro='%i', multiplier ='%i'  where steamid='%s'";
char sql_selectPlayerRankAll[] = "SELECT name, steamid FROM ck_playerrank where name like '%c%s%c'";
char sql_selectPlayerRankAll2[] = "SELECT name, steamid FROM ck_playerrank where name = '%s'";
char sql_selectPlayerName[] = "SELECT name FROM ck_playerrank where steamid = '%s'";
char sql_UpdateLastSeenMySQL[] = "UPDATE ck_playerrank SET lastseen = NOW() where steamid = '%s';";
char sql_UpdateLastSeenSQLite[] = "UPDATE ck_playerrank SET lastseen = date('now') where steamid = '%s';";
char sql_selectTopPlayers[] = "SELECT name, points, finishedmapspro, steamid FROM ck_playerrank ORDER BY points DESC LIMIT 100";
char sql_selectTopChallengers[] = "SELECT name, winratio, pointsratio, steamid FROM ck_playerrank ORDER BY pointsratio DESC LIMIT 5";
char sql_selectRankedPlayer[] = "SELECT steamid, name, points, finishedmapspro, multiplier, country, lastseen from ck_playerrank where steamid='%s'";
char sql_selectRankedPlayersRank[] = "SELECT name FROM ck_playerrank WHERE points >= (SELECT points FROM ck_playerrank WHERE steamid = '%s') ORDER BY points";
char sql_selectRankedPlayers[] = "SELECT steamid, name from ck_playerrank where points > 0 ORDER BY points DESC";
char sql_CountRankedPlayers[] = "SELECT COUNT(steamid) FROM ck_playerrank";
char sql_CountRankedPlayers2[] = "SELECT COUNT(steamid) FROM ck_playerrank where points > 0";

//TABLE PLAYERTIMES
char sql_createPlayertimes[] = "CREATE TABLE IF NOT EXISTS ck_playertimes (steamid VARCHAR(32), mapname VARCHAR(32), name VARCHAR(32), runtimepro FLOAT NOT NULL DEFAULT '-1.0', PRIMARY KEY(steamid,mapname));";
char sql_createPlayertimesIndex[] = "CREATE INDEX maprank ON ck_playertimes (mapname, runtimepro);";
char sql_insertPlayer[] = "INSERT INTO ck_playertimes (steamid, mapname, name) VALUES('%s', '%s', '%s');";
char sql_insertPlayerTime[] = "INSERT INTO ck_playertimes (steamid, mapname, name,runtimepro) VALUES('%s', '%s', '%s', '%f');";
char sql_updateRecordPro[] = "UPDATE ck_playertimes SET name = '%s', runtimepro = '%f' WHERE steamid = '%s' AND mapname = '%s';";
char sql_selectPlayer[] = "SELECT steamid FROM ck_playertimes WHERE steamid = '%s' AND mapname = '%s';";
char sql_selectMapRecord[] = "SELECT MIN(runtimepro), name, steamid FROM ck_playertimes WHERE mapname = '%s' AND runtimepro > -1.0";
char sql_selectPersonalRecords[] = "SELECT runtimepro, name FROM ck_playertimes WHERE mapname = '%s' AND steamid = '%s' AND runtimepro > 0.0";
char sql_selectPersonalAllRecords[] = "SELECT db1.name, db2.steamid, db2.mapname, db2.runtimepro as overall, db1.steamid FROM ck_playertimes as db2 INNER JOIN ck_playerrank as db1 on db2.steamid = db1.steamid WHERE db2.steamid = '%s' AND db2.runtimepro > -1.0 ORDER BY mapname ASC;";
char sql_selectProSurfers[] = "SELECT db1.name, db2.runtimepro, db2.steamid, db1.steamid FROM ck_playertimes as db2 INNER JOIN ck_playerrank as db1 on db2.steamid = db1.steamid WHERE db2.mapname = '%s' AND db2.runtimepro > -1.0 ORDER BY db2.runtimepro ASC LIMIT 20";
char sql_selectTopSurfers2[] = "SELECT db2.steamid, db1.name, db2.runtimepro as overall, db1.steamid, db2.mapname FROM ck_playertimes as db2 INNER JOIN ck_playerrank as db1 on db2.steamid = db1.steamid WHERE db2.mapname LIKE '%c%s%c' AND db2.runtimepro > -1.0 ORDER BY (CASE WHEN db2.mapname = '%s' THEN 1 WHEN db2.mapname LIKE '%s%c' THEN 2 ELSE 3 END), mapname, overall ASC LIMIT 100;";
char sql_selectTopSurfers[] = "SELECT db2.steamid, db1.name, db2.runtimepro as overall, db1.steamid, db2.mapname FROM ck_playertimes as db2 INNER JOIN ck_playerrank as db1 on db2.steamid = db1.steamid WHERE db2.mapname = '%s' AND db2.runtimepro > -1.0 ORDER BY overall ASC LIMIT 100;";
char sql_selectPlayerProCount[] = "SELECT name FROM ck_playertimes WHERE mapname = '%s' AND runtimepro  > -1.0;";
char sql_selectPlayerRankProTime[] = "SELECT name,mapname FROM ck_playertimes WHERE runtimepro <= (SELECT runtimepro FROM ck_playertimes WHERE steamid = '%s' AND mapname = '%s' AND runtimepro > -1.0) AND mapname = '%s' AND runtimepro > -1.0 ORDER BY runtimepro;";
char sql_selectMapRecordHolders[] = "SELECT y.steamid, COUNT(*) AS rekorde FROM (SELECT s.steamid FROM ck_playertimes s INNER JOIN (SELECT mapname, MIN(runtimepro) AS runtimepro FROM ck_playertimes where runtimepro > -1.0 GROUP BY mapname) x ON s.mapname = x.mapname AND s.runtimepro = x.runtimepro) y GROUP BY y.steamid ORDER BY rekorde DESC , y.steamid LIMIT 5;";
char sql_selectMapRecordCount[] = "SELECT y.steamid, COUNT(*) AS rekorde FROM (SELECT s.steamid FROM ck_playertimes s INNER JOIN (SELECT mapname, MIN(runtimepro) AS runtimepro FROM ck_playertimes where runtimepro > -1.0  GROUP BY mapname) x ON s.mapname = x.mapname AND s.runtimepro = x.runtimepro) y where y.steamid = '%s' GROUP BY y.steamid ORDER BY rekorde DESC , y.steamid;";
char sql_selectAllMapTimesinMap[] = "SELECT runtimepro from ck_playertimes WHERE mapname = '%s';";

// STAGES
char sql_createStageRecordsTable[] = "CREATE TABLE IF NOT EXISTS `ck_stages` (`id` int(11) NOT NULL AUTO_INCREMENT, `steamid` varchar(45) NOT NULL, `map` varchar(45) NOT NULL, `stage` int(11) NOT NULL, `runtime` float NOT NULL, `date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY (`id`), UNIQUE KEY `id_UNIQUE` (`id`)) AUTO_INCREMENT=1;";
char sql_selectStageRecords[] = "SELECT stage, runtime, name, (SELECT COUNT(runtime) FROM ck_stages c WHERE c.map = '%s' AND c.stage = '%d') as completions FROM ck_stages a JOIN ck_playerrank p ON a.steamid = p.steamid WHERE map = '%s' AND stage = '%d' ORDER BY runtime ASC LIMIT 1;";
char sql_selectStagePlayerRecords[] = "SELECT stage as stg, runtime as rt, map as mp, (SELECT COUNT(*) FROM ck_stages a WHERE a.map = mp AND a.stage = stg AND runtime <= rt) as rank FROM ck_stages WHERE map = '%s' AND steamid = '%s'";
char sql_insertStageRecord[] = "INSERT INTO ck_stages (steamid, map, stage, runtime) VALUES ('%s', '%s', '%d', '%f')";
char sql_updateStageRecord[] = "UPDATE ck_stages SET runtime = '%f', date = CURRENT_TIMESTAMP WHERE map = '%s' AND steamid = '%s' AND stage = '%d'";
char sql_viewStageTop[] = "SELECT name, runtime, s.steamid FROM ck_stages s JOIN ck_playerrank p ON p.steamid = s.steamid WHERE stage = '%d' AND map = '%s' ORDER BY runtime ASC LIMIT 50";


//TABLE BONUS
char sql_createBonus[] = "CREATE TABLE IF NOT EXISTS ck_bonus (steamid VARCHAR(32), name VARCHAR(32), mapname VARCHAR(32), runtime FLOAT NOT NULL DEFAULT '-1.0', zonegroup INT(12) NOT NULL DEFAULT 1, PRIMARY KEY(steamid, mapname, zonegroup));";
char sql_createBonusIndex[] = "CREATE INDEX bonusrank ON ck_bonus (mapname,runtime,zonegroup);";
char sql_insertBonus[] = "INSERT INTO ck_bonus (steamid, name, mapname, runtime, zonegroup) VALUES ('%s', '%s', '%s', '%f', '%i')";
char sql_updateBonus[] = "UPDATE ck_bonus SET runtime = '%f', name = '%s' WHERE steamid = '%s' AND mapname = '%s' AND zonegroup = %i";
char sql_selectBonusCount[] = "SELECT zonegroup, count(1) FROM ck_bonus WHERE mapname = '%s' GROUP BY zonegroup";
char sql_selectPersonalBonusRecords[] = "SELECT runtime, zonegroup FROM ck_bonus WHERE steamid = '%s' AND mapname = '%s' AND runtime > '0.0'";
char sql_selectPlayerRankBonus[] = "SELECT name FROM ck_bonus WHERE runtime <= (SELECT runtime FROM ck_bonus WHERE steamid = '%s' AND mapname= '%s' AND runtime > 0.0 AND zonegroup = %i) AND mapname = '%s' AND zonegroup = %i;";
char sql_selectFastestBonus[] = "SELECT name, MIN(runtime), zonegroup FROM ck_bonus WHERE mapname = '%s' GROUP BY zonegroup;";
char sql_deleteBonus[] = "DELETE FROM ck_bonus WHERE mapname = '%s'";
char sql_selectAllBonusTimesinMap[] = "SELECT zonegroup, runtime from ck_bonus WHERE mapname = '%s';";
char sql_selectTopBonusSurfers[] = "SELECT db2.steamid, db1.name, db2.runtime as overall, db1.steamid, db2.mapname FROM ck_bonus as db2 INNER JOIN ck_playerrank as db1 on db2.steamid = db1.steamid WHERE db2.mapname LIKE '%c%s%c' AND db2.runtime > -1.0 AND zonegroup = %i ORDER BY (CASE WHEN db2.mapname = '%s' THEN 1 WHEN db2.mapname LIKE '%s%c' THEN 2 ELSE 3 END), mapname, overall ASC LIMIT 100;";


//TABLE CK_SPAWNLOCATIONS
char sql_createSpawnLocations[] = "CREATE TABLE IF NOT EXISTS ck_spawnlocations (mapname VARCHAR(54) NOT NULL, pos_x FLOAT NOT NULL, pos_y FLOAT NOT NULL, pos_z FLOAT NOT NULL, ang_x FLOAT NOT NULL, ang_y FLOAT NOT NULL, ang_z FLOAT NOT NULL, zonegroup INT(12) DEFAULT 0, stage INT(12) DEFAULT 0, PRIMARY KEY(mapname, zonegroup));";
char sql_insertSpawnLocations[] = "INSERT INTO ck_spawnlocations (mapname, pos_x, pos_y, pos_z, ang_x, ang_y, ang_z, zonegroup) VALUES ('%s', '%f', '%f', '%f', '%f', '%f', '%f', %i);";
char sql_updateSpawnLocations[] = "UPDATE ck_spawnlocations SET pos_x = '%f', pos_y = '%f', pos_z = '%f', ang_x = '%f', ang_y = '%f', ang_z = '%f' WHERE mapname = '%s' AND zonegroup = %i";
char sql_selectSpawnLocations[] = "SELECT mapname, pos_x, pos_y, pos_z, ang_x, ang_y, ang_z, zonegroup FROM ck_spawnlocations WHERE mapname ='%s';";
char sql_deleteSpawnLocations[] = "DELETE FROM ck_spawnlocations WHERE mapname = '%s' AND zonegroup = %i";


//TABLE PLAYERTITLES
char sql_createPlayerFlags[] = "CREATE TABLE IF NOT EXISTS ck_playertitles (steamid VARCHAR(32), vip INT(12) DEFAULT 0, mapper INT(12) DEFAULT 0, teacher INT(12) DEFAULT 0, custom1 INT(12) DEFAULT 0, custom2 INT(12) DEFAULT 0, custom3 INT(12) DEFAULT 0, custom4 INT(12) DEFAULT 0, custom5 INT(12) DEFAULT 0, custom6 INT(12) DEFAULT 0, custom7 INT(12) DEFAULT 0, custom8 INT(12) DEFAULT 0, custom9 INT(12) DEFAULT 0, custom10 INT(12) DEFAULT 0, custom11 INT(12) DEFAULT 0, custom12 INT(12) DEFAULT 0, custom13 INT(12) DEFAULT 0, custom14 INT(12) DEFAULT 0, custom15 INT(12) DEFAULT 0, custom16 INT(12) DEFAULT 0, custom17 INT(12) DEFAULT 0, custom18 INT(12) DEFAULT 0, custom19 INT(12) DEFAULT 0, custom20 INT(12) DEFAULT 0, inuse INT(12) DEFAULT 0, PRIMARY KEY(steamid));";
char sql_insertPlayerFlags[] = "INSERT INTO ck_playertitles (steamid, vip, mapper, teacher, custom1, custom2, custom3, custom4, custom5, custom6, custom7, custom8, custom9, custom10, custom11, custom12, custom13, custom14, custom15, custom16, custom17, custom18, custom19, custom20, inuse) VALUES ('%s', %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i, %i);";
char sql_updatePlayerFlags[] = "UPDATE ck_playertitles SET vip = %i, mapper = %i, teacher = %i, custom1 = %i, custom2 = %i, custom3 = %i, custom4 = %i, custom5 = %i, custom6 = %i, custom7 = %i, custom8 = %i, custom9 = %i, custom10 = %i, custom11 = %i, custom12 = %i, custom13 = %i, custom14 = %i, custom15 = %i, custom16 = %i, custom17 = %i, custom18 = %i, custom19 = %i, custom20 = %i, inuse = %i WHERE steamid = '%s'";
char sql_updatePlayerFlagsInUse[] = "UPDATE ck_playertitles SET inuse = %i WHERE steamid = '%s'";
char sql_deletePlayerFlags[] = "DELETE FROM ck_playertitles WHERE steamid = '%s'";
char sql_selectPlayerFlags[] = "SELECT vip, mapper, teacher, custom1, custom2, custom3, custom4, custom5, custom6, custom7, custom8, custom9, custom10, custom11, custom12, custom13, custom14, custom15, custom16, custom17, custom18, custom19, custom20, inuse FROM ck_playertitles WHERE steamid = '%s'";

//TABLE CHALLENGE
char sql_createChallenges[] = "CREATE TABLE IF NOT EXISTS ck_challenges (steamid VARCHAR(32), steamid2 VARCHAR(32), bet INT(12), map VARCHAR(32), date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(steamid,steamid2,date));";
char sql_insertChallenges[] = "INSERT INTO ck_challenges (steamid, steamid2, bet, map) VALUES('%s','%s','%i','%s');";
char sql_selectChallenges2[] = "SELECT steamid, steamid2, bet, map, date FROM ck_challenges where steamid = '%s' OR steamid2 ='%s' ORDER BY date DESC";
char sql_selectChallenges[] = "SELECT steamid, steamid2, bet, map FROM ck_challenges where steamid = '%s' OR steamid2 ='%s'";
char sql_selectChallengesCompare[] = "SELECT steamid, steamid2, bet FROM ck_challenges where (steamid = '%s' AND steamid2 ='%s') OR (steamid = '%s' AND steamid2 ='%s')";
char sql_deleteChallenges[] = "DELETE from ck_challenges where steamid = '%s'";

//TABLE ZONES
char sql_createZones[] = "CREATE TABLE IF NOT EXISTS ck_zones (mapname VARCHAR(54) NOT NULL, zoneid INT(12) DEFAULT '-1', zonetype INT(12) DEFAULT '-1', zonetypeid INT(12) DEFAULT '-1', pointa_x FLOAT DEFAULT '-1.0', pointa_y FLOAT DEFAULT '-1.0', pointa_z FLOAT DEFAULT '-1.0', pointb_x FLOAT DEFAULT '-1.0', pointb_y FLOAT DEFAULT '-1.0', pointb_z FLOAT DEFAULT '-1.0', vis INT(12) DEFAULT '0', team INT(12) DEFAULT '0', zonegroup INT(12) DEFAULT 0, zonename VARCHAR(128), PRIMARY KEY(mapname, zoneid));";
char sql_insertZones[] = "INSERT INTO ck_zones (mapname, zoneid, zonetype, zonetypeid, pointa_x, pointa_y, pointa_z, pointb_x, pointb_y, pointb_z, vis, team, zonegroup, zonename) VALUES ('%s', '%i', '%i', '%i', '%f', '%f', '%f', '%f', '%f', '%f', '%i', '%i', '%i','%s')";
char sql_updateZone[] = "UPDATE ck_zones SET zonetype = '%i', zonetypeid = '%i', pointa_x = '%f', pointa_y ='%f', pointa_z = '%f', pointb_x = '%f', pointb_y = '%f', pointb_z = '%f', vis = '%i', team = '%i', zonegroup = '%i' WHERE zoneid = '%i' AND mapname = '%s'";
char sql_selectzoneTypeIds[] = "SELECT zonetypeid FROM ck_zones WHERE mapname='%s' AND zonetype='%i' AND zonegroup = '%i';";
char sql_selectMapZones[] = "SELECT zoneid, zonetype, zonetypeid, pointa_x, pointa_y, pointa_z, pointb_x, pointb_y, pointb_z, vis, team, zonegroup, zonename FROM ck_zones WHERE mapname = '%s' ORDER BY zonetypeid ASC";
char sql_selectTotalBonusCount[] = "SELECT mapname, zoneid, zonetype, zonetypeid, pointa_x, pointa_y, pointa_z, pointb_x, pointb_y, pointb_z, vis, team, zonegroup, zonename FROM ck_zones WHERE zonetype = 3 GROUP BY mapname, zonegroup;";
char sql_selectZoneIds[] = "SELECT mapname, zoneid, zonetype, zonetypeid, pointa_x, pointa_y, pointa_z, pointb_x, pointb_y, pointb_z, vis, team, zonegroup, zonename FROM ck_zones WHERE mapname = '%s' ORDER BY zoneid ASC";
char sql_selectBonusesInMap[] = "SELECT mapname, zonegroup, zonename FROM `ck_zones` WHERE mapname LIKE '%c%s%c' AND zonegroup > 0 GROUP BY zonegroup ORDER BY (CASE WHEN mapname = '%s' THEN 1 WHEN mapname LIKE '%s%c' THEN 2 ELSE 3 END);";
char sql_deleteMapZones[] = "DELETE FROM ck_zones WHERE mapname = '%s'";
char sql_deleteZone[] = "DELETE FROM ck_zones WHERE mapname = '%s' AND zoneid = '%i'";
char sql_deleteAllZones[] = "DELETE FROM ck_zones";
char sql_deleteZonesInGroup[] = "DELETE FROM ck_zones WHERE mapname = '%s' AND zonegroup = '%i'";
char sql_setZoneNames[] = "UPDATE ck_zones SET zonename = '%s' WHERE mapname = '%s' AND zonegroup = '%i';";

//TABLE MAPTIER
char sql_createMapTier[] = "CREATE TABLE IF NOT EXISTS ck_maptier (mapname VARCHAR(54) NOT NULL, tier INT(12), btier1 INT(12), btier2 INT(12), btier3 INT(12), btier4 INT(12), btier5 INT(12), btier6 INT(12), btier7 INT(12), btier8 INT(12), btier9 INT(12), btier10 INT(12), PRIMARY KEY(mapname));";
char sql_selectMapTier[] = "SELECT tier, btier1, btier2, btier3, btier4, btier5, btier6, btier7, btier8, btier9, btier10 FROM ck_maptier WHERE mapname = '%s'";
char sql_deleteAllMapTiers[] = "DELETE FROM ck_maptier";
char sql_insertmaptier[] = "INSERT INTO ck_maptier (mapname, tier) VALUES ('%s', '%i');";
char sql_updatemaptier[] = "UPDATE ck_maptier SET tier = %i WHERE mapname ='%s'";
char sql_updateBonusTier[] = "UPDATE ck_maptier SET btier%i = %i WHERE mapname ='%s'";
char sql_insertBonusTier[] = "INSERT INTO ck_maptier (mapname, btier%i) VALUES ('%s', '%i');";

//TABLE CHECKPOINTS
char sql_createCheckpoints[] = "CREATE TABLE IF NOT EXISTS ck_checkpoints (steamid VARCHAR(32), mapname VARCHAR(32), cp1 FLOAT DEFAULT '0.0', cp2 FLOAT DEFAULT '0.0', cp3 FLOAT DEFAULT '0.0', cp4 FLOAT DEFAULT '0.0', cp5 FLOAT DEFAULT '0.0', cp6 FLOAT DEFAULT '0.0', cp7 FLOAT DEFAULT '0.0', cp8 FLOAT DEFAULT '0.0', cp9 FLOAT DEFAULT '0.0', cp10 FLOAT DEFAULT '0.0', cp11 FLOAT DEFAULT '0.0', cp12 FLOAT DEFAULT '0.0', cp13 FLOAT DEFAULT '0.0', cp14 FLOAT DEFAULT '0.0', cp15 FLOAT DEFAULT '0.0', cp16 FLOAT DEFAULT '0.0', cp17  FLOAT DEFAULT '0.0', cp18 FLOAT DEFAULT '0.0', cp19 FLOAT DEFAULT '0.0', cp20  FLOAT DEFAULT '0.0', cp21 FLOAT DEFAULT '0.0', cp22 FLOAT DEFAULT '0.0', cp23 FLOAT DEFAULT '0.0', cp24 FLOAT DEFAULT '0.0', cp25 FLOAT DEFAULT '0.0', cp26 FLOAT DEFAULT '0.0', cp27 FLOAT DEFAULT '0.0', cp28 FLOAT DEFAULT '0.0', cp29 FLOAT DEFAULT '0.0', cp30 FLOAT DEFAULT '0.0', cp31 FLOAT DEFAULT '0.0', cp32  FLOAT DEFAULT '0.0', cp33 FLOAT DEFAULT '0.0', cp34 FLOAT DEFAULT '0.0', cp35 FLOAT DEFAULT '0.0', zonegroup INT(12) NOT NULL DEFAULT 0, PRIMARY KEY(steamid, mapname, zonegroup));";
char sql_updateCheckpoints[] = "UPDATE ck_checkpoints SET cp1='%f', cp2='%f', cp3='%f', cp4='%f', cp5='%f', cp6='%f', cp7='%f', cp8='%f', cp9='%f', cp10='%f', cp11='%f', cp12='%f', cp13='%f', cp14='%f', cp15='%f', cp16='%f', cp17='%f', cp18='%f', cp19='%f', cp20='%f', cp21='%f', cp22='%f', cp23='%f', cp24='%f', cp25='%f', cp26='%f', cp27='%f', cp28='%f', cp29='%f', cp30='%f', cp31='%f', cp32='%f', cp33='%f', cp34='%f', cp35='%f' WHERE steamid='%s' AND mapname='%s' AND zonegroup='%i'";
char sql_insertCheckpoints[] = "INSERT INTO ck_checkpoints VALUES ('%s', '%s', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%f', '%i')";
char sql_selectCheckpoints[] = "SELECT zonegroup, cp1, cp2, cp3, cp4, cp5, cp6, cp7, cp8, cp9, cp10, cp11, cp12, cp13, cp14, cp15, cp16, cp17, cp18, cp19, cp20, cp21, cp22, cp23, cp24, cp25, cp26, cp27, cp28, cp29, cp30, cp31, cp32, cp33, cp34, cp35 FROM ck_checkpoints WHERE mapname='%s' AND steamid = '%s';";
char sql_selectCheckpointsinZoneGroup[] = "SELECT cp1, cp2, cp3, cp4, cp5, cp6, cp7, cp8, cp9, cp10, cp11, cp12, cp13, cp14, cp15, cp16, cp17, cp18, cp19, cp20, cp21, cp22, cp23, cp24, cp25, cp26, cp27, cp28, cp29, cp30, cp31, cp32, cp33, cp34, cp35 FROM ck_checkpoints WHERE mapname='%s' AND steamid = '%s' AND zonegroup = %i;";
char sql_selectRecordCheckpoints[] = "SELECT zonegroup, cp1, cp2, cp3, cp4, cp5, cp6, cp7, cp8, cp9, cp10, cp11, cp12, cp13, cp14, cp15, cp16, cp17, cp18, cp19, cp20, cp21, cp22, cp23, cp24, cp25, cp26, cp27, cp28, cp29, cp30, cp31, cp32, cp33, cp34, cp35 FROM ck_checkpoints WHERE steamid = '%s' AND mapname='%s' UNION SELECT a.zonegroup, b.cp1, b.cp2, b.cp3, b.cp4, b.cp5, b.cp6, b.cp7, b.cp8, b.cp9, b.cp10, b.cp11, b.cp12, b.cp13, b.cp14, b.cp15, b.cp16, b.cp17, b.cp18, b.cp19, b.cp20, b.cp21, b.cp22, b.cp23, b.cp24, b.cp25, b.cp26, b.cp27, b.cp28, b.cp29, b.cp30, b.cp31, b.cp32, b.cp33, b.cp34, b.cp35 FROM ck_bonus a LEFT JOIN ck_checkpoints b ON a.steamid = b.steamid AND a.zonegroup = b.zonegroup WHERE a.mapname = '%s' GROUP BY a.zonegroup";
char sql_deleteCheckpoints[] = "DELETE FROM ck_checkpoints WHERE mapname = '%s'";

//TABLE LATEST 15 LOCAL RECORDS
char sql_createLatestRecords[] = "CREATE TABLE IF NOT EXISTS ck_latestrecords (steamid VARCHAR(32), name VARCHAR(32), runtime FLOAT NOT NULL DEFAULT '-1.0', map VARCHAR(32), date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, PRIMARY KEY(steamid,map,date));";
char sql_insertLatestRecords[] = "INSERT INTO ck_latestrecords (steamid, name, runtime, map) VALUES('%s','%s','%f','%s');";
char sql_selectLatestRecords[] = "SELECT name, runtime, map, date FROM ck_latestrecords ORDER BY date DESC LIMIT 50";

//TABLE PLAYEROPTIONS
char sql_createPlayerOptions[] = "CREATE TABLE IF NOT EXISTS ck_playeroptions (steamid VARCHAR(32), speedmeter INT(12) DEFAULT '0', quake_sounds INT(12) DEFAULT '1', shownames INT(12) DEFAULT '1', goto INT(12) DEFAULT '1', showtime INT(12) DEFAULT '1', hideplayers INT(12) DEFAULT '0', showspecs INT(12) DEFAULT '1', knife VARCHAR(32) DEFAULT 'weapon_knife', new1 INT(12) DEFAULT '0', new2 INT(12) DEFAULT '0', new3 INT(12) DEFAULT '0', checkpoints INT(12) DEFAULT '1', hidelefthud INT(12) DEFAULT '0', PRIMARY KEY(steamid));";
char sql_insertPlayerOptions[] = "INSERT INTO ck_playeroptions (steamid, speedmeter, quake_sounds, shownames, goto, showtime, hideplayers, showspecs, knife, new1, new2, new3, checkpoints, hidelefthud) VALUES('%s', '%i', '%i', '%i', '%i', '%i', '%i', '%i', '%s', '%i', '%i', '%i', '%i', '%i');";
char sql_selectPlayerOptions[] = "SELECT speedmeter, quake_sounds, shownames, goto, showtime, hideplayers, showspecs, knife, new1, new2, new3, checkpoints, hidelefthud FROM ck_playeroptions where steamid = '%s'";
char sql_updatePlayerOptions[] = "UPDATE ck_playeroptions SET speedmeter ='%i', quake_sounds ='%i', shownames ='%i', goto ='%i', showtime ='%i', hideplayers ='%i', showspecs ='%i', knife ='%s', new1 = '%i', new2 = '%i', new3 = '%i', checkpoints = '%i', hidelefthud = '%i' where steamid = '%s'";

//TABLE PLAYERTEMP
char sql_createPlayertmp[] = "CREATE TABLE IF NOT EXISTS ck_playertemp (steamid VARCHAR(32), mapname VARCHAR(32), cords1 FLOAT NOT NULL DEFAULT '-1.0', cords2 FLOAT NOT NULL DEFAULT '-1.0', cords3 FLOAT NOT NULL DEFAULT '-1.0', angle1 FLOAT NOT NULL DEFAULT '-1.0',angle2 FLOAT NOT NULL DEFAULT '-1.0',angle3 FLOAT NOT NULL DEFAULT '-1.0', EncTickrate INT(12) DEFAULT '-1.0', runtimeTmp FLOAT NOT NULL DEFAULT '-1.0', Stage INT, zonegroup INT NOT NULL DEFAULT 0, PRIMARY KEY(steamid,mapname));";
char sql_insertPlayerTmp[] = "INSERT INTO ck_playertemp (cords1, cords2, cords3, angle1,angle2,angle3,runtimeTmp,steamid,mapname,EncTickrate,Stage,zonegroup) VALUES ('%f','%f','%f','%f','%f','%f','%f','%s', '%s', '%i', %i, %i);";
char sql_updatePlayerTmp[] = "UPDATE ck_playertemp SET cords1 = '%f', cords2 = '%f', cords3 = '%f', angle1 = '%f', angle2 = '%f', angle3 = '%f', runtimeTmp = '%f', mapname ='%s', EncTickrate='%i', Stage = %i, zonegroup = %i WHERE steamid = '%s';";
char sql_deletePlayerTmp[] = "DELETE FROM ck_playertemp where steamid = '%s';";
char sql_selectPlayerTmp[] = "SELECT cords1,cords2,cords3, angle1, angle2, angle3,runtimeTmp, EncTickrate, Stage, zonegroup FROM ck_playertemp WHERE steamid = '%s' AND mapname = '%s';";

// ADMIN
char sqlite_dropChallenges[] = "DROP TABLE ck_challenges; VACCUM";
char sql_dropChallenges[] = "DROP TABLE ck_challenges;";
char sqlite_dropPlayer[] = "DROP TABLE ck_playertimes; VACCUM";
char sql_dropPlayer[] = "DROP TABLE ck_playertimes;";
char sql_dropPlayerRank[] = "DROP TABLE ck_playerrank;";
char sqlite_dropPlayerRank[] = "DROP TABLE ck_playerrank; VACCUM";
char sql_resetRecords[] = "DELETE FROM ck_playertimes WHERE steamid = '%s'";
char sql_resetRecords2[] = "DELETE FROM ck_playertimes WHERE steamid = '%s' AND mapname LIKE '%s';";
char sql_resetRecordPro[] = "UPDATE ck_playertimes SET runtimepro = '-1.0' WHERE steamid = '%s' AND mapname LIKE '%s';";
char sql_resetCheckpoints[] = "DELETE FROM ck_checkpoints WHERE steamid = '%s' AND mapname LIKE '%s';";
char sql_resetMapRecords[] = "DELETE FROM ck_playertimes WHERE mapname = '%s'";
