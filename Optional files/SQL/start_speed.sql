ALTER TABLE `ck_playertimes` ADD COLUMN `startspeed` FLOAT NOT NULL DEFAULT -1.0 AFTER `runtimepro`;
ALTER TABLE `ck_stages` ADD COLUMN `startspeed` FLOAT NOT NULL DEFAULT -1 AFTER `date`;
ALTER TABLE `ck_bonus` ADD COLUMN `startspeed` FLOAT NOT NULL DEFAULT -1 AFTER `zonegroup`;
