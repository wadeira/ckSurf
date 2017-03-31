ALTER TABLE `ck_playeroptions` 
DROP COLUMN `new1`,
DROP COLUMN `knife`,
DROP COLUMN `showtime`,
DROP COLUMN `goto`,
DROP COLUMN `shownames`,
DROP COLUMN `speedmeter`,
CHANGE COLUMN `new2` `hidechat` INT(12) NULL DEFAULT '0' ,
CHANGE COLUMN `new3` `viewmodel` INT(12) NULL DEFAULT '0' ;