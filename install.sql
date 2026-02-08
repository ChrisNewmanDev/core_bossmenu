-- Boss Menu Locations Table
-- Run this SQL query in your database to create the table

CREATE TABLE IF NOT EXISTS `core_bossmenu_locations` (
  `id` INT(11) NOT NULL AUTO_INCREMENT,
  `job` VARCHAR(50) NOT NULL,
  `coords` TEXT NOT NULL,
  PRIMARY KEY (`id`),
  KEY `job` (`job`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
