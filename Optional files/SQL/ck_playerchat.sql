CREATE TABLE `surf_timer`.`ck_playerchat` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `steamid` VARCHAR(45) NOT NULL,
  `tag` VARCHAR(64) NULL,
  `name` VARCHAR(64) NULL,
  PRIMARY KEY (`id`),
  UNIQUE INDEX `id_UNIQUE` (`id` ASC),
  UNIQUE INDEX `steamid_UNIQUE` (`steamid` ASC));
