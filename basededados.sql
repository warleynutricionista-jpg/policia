-- --------------------------------------------------------
-- Host:                         127.0.0.1
-- Server version:               12.2.2-MariaDB - MariaDB Server
-- Server OS:                    Win64
-- HeidiSQL Version:             12.15.0.7171
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;


-- Dumping database structure for republica
CREATE DATABASE IF NOT EXISTS `republica` /*!40100 DEFAULT CHARACTER SET utf8mb3 COLLATE utf8mb3_general_ci */;
USE `republica`;

-- Dumping structure for table republica.apartments
CREATE TABLE IF NOT EXISTS `apartments` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `type` varchar(255) DEFAULT NULL,
  `label` varchar(255) DEFAULT NULL,
  `citizenid` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`),
  KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.apartments: ~0 rows (approximately)

-- Dumping structure for table republica.bank_accounts
CREATE TABLE IF NOT EXISTS `bank_accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `account_name` varchar(50) NOT NULL,
  `account_balance` int(11) NOT NULL DEFAULT 0,
  `account_type` varchar(20) NOT NULL,
  `users` longtext DEFAULT '[]',
  PRIMARY KEY (`id`),
  KEY `idx_account_name` (`account_name`),
  KEY `idx_account_type` (`account_type`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Dumping data for table republica.bank_accounts: ~9 rows (approximately)
INSERT INTO `bank_accounts` (`id`, `citizenid`, `account_name`, `account_balance`, `account_type`, `users`) VALUES
	(1, NULL, 'cardealer', 0, 'job', '[]'),
	(2, NULL, 'ambulance', 0, 'job', '[]'),
	(3, NULL, 'police', 100, 'job', '[]'),
	(4, NULL, 'mechanic', 0, 'job', '[]'),
	(5, NULL, 'cartel', 0, 'gang', '[]'),
	(6, NULL, 'lostmc', 0, 'gang', '[]'),
	(7, NULL, 'ballas', 0, 'gang', '[]'),
	(8, NULL, 'vagos', 0, 'gang', '[]'),
	(9, NULL, 'families', 0, 'gang', '[]');

-- Dumping structure for table republica.bank_accounts_new
CREATE TABLE IF NOT EXISTS `bank_accounts_new` (
  `id` varchar(50) NOT NULL,
  `amount` int(11) DEFAULT 0,
  `transactions` longtext DEFAULT NULL,
  `auth` longtext DEFAULT NULL,
  `isFrozen` int(11) DEFAULT 0,
  `creator` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.bank_accounts_new: ~11 rows (approximately)
INSERT INTO `bank_accounts_new` (`id`, `amount`, `transactions`, `auth`, `isFrozen`, `creator`) VALUES
	('ambulance', 0, '[]', '[]', 0, NULL),
	('ballas', 0, '[]', '[]', 0, NULL),
	('cardealer', 0, '[]', '[]', 0, NULL),
	('cartel', 0, '[]', '[]', 0, NULL),
	('families', 0, '[]', '[]', 0, NULL),
	('lostmc', 0, '[]', '[]', 0, NULL),
	('mechanic', 0, '[]', '[]', 0, NULL),
	('police', 0, '[]', '[]', 0, NULL),
	('realestate', 0, '[]', '[]', 0, NULL),
	('triads', 0, '[]', '[]', 0, NULL),
	('vagos', 0, '[]', '[]', 0, NULL);

-- Dumping structure for table republica.bans
CREATE TABLE IF NOT EXISTS `bans` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) DEFAULT NULL,
  `license` varchar(50) DEFAULT NULL,
  `discord` varchar(50) DEFAULT NULL,
  `ip` varchar(50) DEFAULT NULL,
  `reason` text DEFAULT NULL,
  `expire` int(11) DEFAULT NULL,
  `bannedby` varchar(255) NOT NULL DEFAULT 'LeBanhammer',
  PRIMARY KEY (`id`),
  KEY `license` (`license`),
  KEY `discord` (`discord`),
  KEY `ip` (`ip`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.bans: ~0 rows (approximately)

-- Dumping structure for table republica.computers_mail_accounts
CREATE TABLE IF NOT EXISTS `computers_mail_accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(40) NOT NULL,
  `username` varchar(16) NOT NULL,
  `password` varchar(32) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_computers_mail_accounts_identifier` (`identifier`),
  KEY `idx_computers_mail_accounts_username` (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- Dumping data for table republica.computers_mail_accounts: ~0 rows (approximately)

-- Dumping structure for table republica.computers_mail_mails
CREATE TABLE IF NOT EXISTS `computers_mail_mails` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `from` varchar(16) NOT NULL,
  `to` varchar(16) NOT NULL,
  `object` varchar(32) DEFAULT NULL,
  `text` varchar(4096) DEFAULT NULL,
  `answer_to` int(11) DEFAULT NULL,
  `timestamp` int(11) DEFAULT unix_timestamp(),
  `read` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_computers_mail_mails_from` (`from`),
  KEY `idx_computers_mail_mails_to` (`to`),
  KEY `idx_computers_mail_mails_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- Dumping data for table republica.computers_mail_mails: ~0 rows (approximately)

-- Dumping structure for table republica.computers_market
CREATE TABLE IF NOT EXISTS `computers_market` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `seller` varchar(40) NOT NULL,
  `title` varchar(16) NOT NULL,
  `description` varchar(512) DEFAULT NULL,
  `timestamp` int(11) DEFAULT unix_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_computers_market_seller` (`seller`),
  KEY `idx_computers_market_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_bin;

-- Dumping data for table republica.computers_market: ~0 rows (approximately)

-- Dumping structure for table republica.dealers
CREATE TABLE IF NOT EXISTS `dealers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL DEFAULT '0',
  `coords` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `time` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `createdby` varchar(50) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.dealers: ~0 rows (approximately)

-- Dumping structure for table republica.dealership_vehicles
CREATE TABLE IF NOT EXISTS `dealership_vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `model` varchar(50) NOT NULL,
  `name` varchar(100) NOT NULL,
  `price` int(11) NOT NULL,
  `category` varchar(50) NOT NULL,
  `stock` int(11) NOT NULL,
  `description` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `model` (`model`)
) ENGINE=InnoDB AUTO_INCREMENT=191 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Dumping data for table republica.dealership_vehicles: ~190 rows (approximately)
INSERT INTO `dealership_vehicles` (`id`, `model`, `name`, `price`, `category`, `stock`, `description`) VALUES
	(1, 'brioso2', 'Brioso 300', 62000, 'compacts', 1000, 'A premium vehicle available at our dealership.'),
	(2, 'brioso', 'Brioso R/A', 58000, 'compacts', 1000, 'A premium vehicle available at our dealership.'),
	(3, 'rhapsody', 'Rhapsody', 55000, 'compacts', 1000, 'A premium vehicle available at our dealership.'),
	(4, 'dilettante', 'Dilettante', 52000, 'compacts', 1000, 'A premium vehicle available at our dealership.'),
	(5, 'prairie', 'Prairie', 48000, 'compacts', 1000, 'A premium vehicle available at our dealership.'),
	(6, 'weevil', 'Weevil', 68000, 'compacts', 1000, 'A premium vehicle available at our dealership.'),
	(7, 'issi2', 'Issi', 45000, 'compacts', 1000, 'A premium vehicle available at our dealership.'),
	(8, 'blista', 'Blista', 42000, 'compacts', 1000, 'A premium vehicle available at our dealership.'),
	(9, 'club', 'Club', 38000, 'compacts', 1000, 'A premium vehicle available at our dealership.'),
	(10, 'asbo', 'Asbo', 35000, 'compacts', 1000, 'A premium vehicle available at our dealership.'),
	(11, 'panto', 'Panto', 28000, 'compacts', 1000, 'A premium vehicle available at our dealership.'),
	(12, 'washington', 'Washington', 48000, 'sedans', 1000, 'A premium vehicle available at our dealership.'),
	(13, 'premier', 'Premier', 45000, 'sedans', 1000, 'A premium vehicle available at our dealership.'),
	(14, 'stratum', 'Stratum', 42000, 'sedans', 1000, 'A premium vehicle available at our dealership.'),
	(15, 'stanier', 'Stanier', 38000, 'sedans', 1000, 'A premium vehicle available at our dealership.'),
	(16, 'warrener', 'Warrener', 32000, 'sedans', 1000, 'A premium vehicle available at our dealership.'),
	(17, 'kanjo', 'Blista Kanjo', 75000, 'compacts', 1000, 'A premium vehicle available at our dealership.'),
	(18, 'tailgater', 'Tailgater', 58000, 'sedans', 1000, 'A premium vehicle available at our dealership.'),
	(19, 'primo', 'Primo', 52000, 'sedans', 1000, 'A premium vehicle available at our dealership.'),
	(20, 'emperor', 'Emperor', 75000, 'sedans', 1000, 'A premium vehicle available at our dealership.'),
	(21, 'sultan', 'Sultan', 68000, 'sedans', 1000, 'A premium vehicle available at our dealership.'),
	(22, 'ingot', 'Ingot', 115000, 'sedans', 1000, 'A premium vehicle available at our dealership.'),
	(23, 'asea', 'Asea', 105000, 'sedans', 1000, 'A premium vehicle available at our dealership.'),
	(24, 'glendale', 'Glendale', 125000, 'sedans', 1000, 'A premium vehicle available at our dealership.'),
	(25, 'sultanrs', 'Sultan RS', 95000, 'sedans', 1000, 'A premium vehicle available at our dealership.'),
	(26, 'intruder', 'Intruder', 145000, 'sedans', 1000, 'A premium vehicle available at our dealership.'),
	(27, 'asterope', 'Asterope', 135000, 'sedans', 1000, 'A premium vehicle available at our dealership.'),
	(28, 'cognoscenti', 'Cognoscenti', 685000, 'sedans', 1000, 'A premium vehicle available at our dealership.'),
	(29, 'superd', 'Super Diamond', 285000, 'sedans', 1000, 'A premium vehicle available at our dealership.'),
	(30, 'cinquemila', 'Cinquemila', 485000, 'sedans', 1000, 'A premium vehicle available at our dealership.'),
	(31, 'deity', 'Deity', 525000, 'sedans', 1000, 'A premium vehicle available at our dealership.'),
	(32, 'fugitive', 'Fugitive', 185000, 'sedans', 1000, 'A premium vehicle available at our dealership.'),
	(33, 'cavalcade2', 'Cavalcade 2', 75000, 'suvs', 1000, 'A premium vehicle available at our dealership.'),
	(34, 'cavalcade', 'Cavalcade', 70000, 'suvs', 1000, 'A premium vehicle available at our dealership.'),
	(35, 'bjxl', 'BeeJay XL', 65000, 'suvs', 1000, 'A premium vehicle available at our dealership.'),
	(36, 'baller2', 'Baller 2', 95000, 'suvs', 1000, 'A premium vehicle available at our dealership.'),
	(37, 'baller', 'Baller', 85000, 'suvs', 1000, 'A premium vehicle available at our dealership.'),
	(38, 'dubsta', 'Dubsta', 80000, 'suvs', 1000, 'A premium vehicle available at our dealership.'),
	(39, 'contender', 'Contender', 125000, 'suvs', 1000, 'A premium vehicle available at our dealership.'),
	(40, 'gresley', 'Gresley', 74000, 'suvs', 1000, 'A premium vehicle available at our dealership.'),
	(41, 'granger', 'Granger', 68000, 'suvs', 1000, 'A premium vehicle available at our dealership.'),
	(42, 'huntley', 'Huntley S', 195000, 'suvs', 1000, 'A premium vehicle available at our dealership.'),
	(43, 'fq2', 'FQ 2', 72000, 'suvs', 1000, 'A premium vehicle available at our dealership.'),
	(44, 'habanero', 'Habanero', 78000, 'suvs', 1000, 'A premium vehicle available at our dealership.'),
	(45, 'landstalker', 'Landstalker', 58000, 'suvs', 1000, 'A premium vehicle available at our dealership.'),
	(46, 'mesa', 'Mesa', 62000, 'suvs', 1000, 'A premium vehicle available at our dealership.'),
	(47, 'patriot', 'Patriot', 135000, 'suvs', 1000, 'A premium vehicle available at our dealership.'),
	(48, 'radi', 'Radius', 76000, 'suvs', 1000, 'A premium vehicle available at our dealership.'),
	(49, 'rocoto', 'Rocoto', 82000, 'suvs', 1000, 'A premium vehicle available at our dealership.'),
	(50, 'seminole', 'Seminole', 64000, 'suvs', 1000, 'A premium vehicle available at our dealership.'),
	(51, 'serrano', 'Serrano', 88000, 'suvs', 1000, 'A premium vehicle available at our dealership.'),
	(52, 'exemplar', 'Exemplar', 205000, 'coupes', 1000, 'A premium vehicle available at our dealership.'),
	(53, 'cogcabrio', 'Cognoscenti Cabrio', 180000, 'coupes', 1000, 'A premium vehicle available at our dealership.'),
	(54, 'xls', 'XLS', 145000, 'suvs', 1000, 'A premium vehicle available at our dealership.'),
	(55, 'felon', 'Felon', 95000, 'coupes', 1000, 'A premium vehicle available at our dealership.'),
	(56, 'f620', 'F620', 135000, 'coupes', 1000, 'A premium vehicle available at our dealership.'),
	(57, 'felon2', 'Felon GT', 105000, 'coupes', 1000, 'A premium vehicle available at our dealership.'),
	(58, 'jackal', 'Jackal', 78000, 'coupes', 1000, 'A premium vehicle available at our dealership.'),
	(59, 'oracle', 'Oracle', 85000, 'coupes', 1000, 'A premium vehicle available at our dealership.'),
	(60, 'oracle2', 'Oracle XS', 92000, 'coupes', 1000, 'A premium vehicle available at our dealership.'),
	(61, 'sentinel', 'Sentinel', 98000, 'coupes', 1000, 'A premium vehicle available at our dealership.'),
	(62, 'sentinel2', 'Sentinel XS', 115000, 'coupes', 1000, 'A premium vehicle available at our dealership.'),
	(63, 'windsor', 'Windsor', 845000, 'coupes', 1000, 'A premium vehicle available at our dealership.'),
	(64, 'windsor2', 'Windsor Drop', 900000, 'coupes', 1000, 'A premium vehicle available at our dealership.'),
	(65, 'zion', 'Zion', 88000, 'coupes', 1000, 'A premium vehicle available at our dealership.'),
	(66, 'zion2', 'Zion Cabrio', 95000, 'coupes', 1000, 'A premium vehicle available at our dealership.'),
	(67, 'blade', 'Blade', 95000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(68, 'buccaneer', 'Buccaneer', 85000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(69, 'buccaneer2', 'Buccaneer Custom', 125000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(70, 'chino', 'Chino', 78000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(71, 'chino2', 'Chino Custom', 115000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(72, 'clique', 'Clique', 365000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(73, 'coquette3', 'Coquette BlackFin', 195000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(74, 'deviant', 'Deviant', 512000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(75, 'dominator', 'Dominator', 95000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(76, 'gauntlet', 'Gauntlet', 105000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(77, 'dukes', 'Dukes', 62000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(78, 'dominator2', 'Pisswasser Dominator', 145000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(79, 'gauntlet2', 'Gauntlet Redwood', 135000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(80, 'hermes', 'Hermes', 535000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(81, 'ratloader', 'Rat-Loader', 38000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(82, 'picador', 'Picador', 68000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(83, 'phoenix', 'Phoenix', 92000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(84, 'nightshade', 'Nightshade', 585000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(85, 'moonbeam2', 'Moonbeam Custom', 115000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(86, 'moonbeam', 'Moonbeam', 85000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(87, 'faction2', 'Faction Custom', 118000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(88, 'faction', 'Faction', 88000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(89, 'hotknife', 'Hotknife', 90000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(90, 'ruiner', 'Ruiner', 98000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(91, 'ratloader2', 'Rat-Truck', 45000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(92, 'vigero', 'Vigero', 105000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(93, 'tampa', 'Tampa', 375000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(94, 'stalion2', 'Burger Shot Stallion', 125000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(95, 'stalion', 'Stallion', 95000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(96, 'slamvan3', 'Slamvan Custom', 118000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(97, 'slamvan2', 'Lost Slamvan', 88000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(98, 'slamvan', 'Slamvan', 78000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(99, 'sabregt', 'Sabre Turbo', 105000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(100, 'voodoo', 'Voodoo', 88000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(101, 'virgo2', 'Virgo Classic Custom', 235000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(102, 'virgo', 'Virgo', 195000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(103, 'casco', 'Casco', 680000, 'sportsclassics', 1000, 'A premium vehicle available at our dealership.'),
	(104, 'yosemite', 'Yosemite', 485000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(105, 'voodoo2', 'Voodoo Custom', 118000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(106, 'coquette2', 'Coquette Classic', 665000, 'sportsclassics', 1000, 'A premium vehicle available at our dealership.'),
	(107, 'stinger', 'Stinger', 850000, 'sportsclassics', 1000, 'A premium vehicle available at our dealership.'),
	(108, 'monroe', 'Monroe', 490000, 'sportsclassics', 1000, 'A premium vehicle available at our dealership.'),
	(109, 'banshee', 'Banshee', 145000, 'sports', 1000, 'A premium vehicle available at our dealership.'),
	(110, 'elegy', 'Elegy RH8', 125000, 'sports', 1000, 'A premium vehicle available at our dealership.'),
	(111, 'z190', 'Z190', 900000, 'sportsclassics', 1000, 'A premium vehicle available at our dealership.'),
	(112, 'rapidgt', 'Rapid GT', 225000, 'sports', 1000, 'A premium vehicle available at our dealership.'),
	(113, 'feltzer2', 'Feltzer', 205000, 'sports', 1000, 'A premium vehicle available at our dealership.'),
	(114, 'ninef', '9F', 185000, 'sports', 999, 'A premium vehicle available at our dealership.'),
	(115, 'surano', 'Surano', 165000, 'sports', 1000, 'A premium vehicle available at our dealership.'),
	(116, 'jester', 'Jester', 325000, 'sports', 1000, 'A premium vehicle available at our dealership.'),
	(117, 'carbonizzare', 'Carbonizzare', 285000, 'sports', 1000, 'A premium vehicle available at our dealership.'),
	(118, 'coquette', 'Coquette', 245000, 'sports', 1000, 'A premium vehicle available at our dealership.'),
	(119, 'turismor', 'Turismo R', 1125000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(120, 'infernus', 'Infernus', 825000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(121, 'vacca', 'Vacca', 685000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(122, 'bullet', 'Bullet', 525000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(123, 'voltic', 'Voltic', 485000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(124, 'italigtb', 'Itali GTB', 3485000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(125, 'pfister811', 'Pfister 811', 3185000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(126, 'adder', 'Adder', 2685000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(127, 'entityxf', 'Entity XF', 2285000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(128, 'zentorno', 'Zentorno', 1985000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(129, 'cheetah', 'Cheetah', 1685000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(130, 'banshee2', 'Banshee 900R', 1385000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(131, 'tempesta', 'Tempesta', 4185000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(132, 'gp1', 'GP1', 3785000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(133, 'nero', 'Nero', 4685000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(134, 'visione', 'Visione', 7385000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(135, 't20', 'T20', 7985000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(136, 'cyclone', 'Cyclone', 6285000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(137, 'osiris', 'Osiris', 6785000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(138, 'reaper', 'Reaper', 5185000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(139, 'tyrus', 'Tyrus', 9485000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(140, 'fmj', 'FMJ', 5685000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(141, 'autarch', 'Autarch', 8685000, 'super', 1000, 'A premium vehicle available at our dealership.'),
	(142, 'pcj', 'PCJ 600', 8500, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(143, 'faggio', 'Faggio', 12000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(144, 'sanchez', 'Sanchez', 18500, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(145, 'hexer', 'Hexer', 16500, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(146, 'nemesis', 'Nemesis', 14500, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(147, 'double', 'Double T', 28000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(148, 'vader', 'Vader', 22000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(149, 'bati', 'Bati 801', 38000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(150, 'sabregt2', 'Sabre Turbo Custom', 135000, 'muscle', 1000, 'A premium vehicle available at our dealership.'),
	(151, 'thrust', 'Thrust', 68000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(152, 'sovereign', 'Sovereign', 105000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(153, 'daemon', 'Daemon', 55000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(154, 'bati2', 'Bati 801RR', 48000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(155, 'bagger', 'Bagger', 42000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(156, 'innovation', 'Innovation', 95000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(157, 'hakuchou', 'Hakuchou', 85000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(158, 'ruffian', 'Ruffian', 9500, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(159, 'akuma', 'Akuma', 115000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(160, 'gargoyle', 'Gargoyle', 125000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(161, 'vortex', 'Vortex', 385000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(162, 'vindicator', 'Vindicator', 485000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(163, 'bf400', 'BF400', 285000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(164, 'zombieb', 'Zombie Chopper', 215000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(165, 'carbonrs', 'Carbon RS', 135000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(166, 'enduro', 'Enduro', 155000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(167, 'cliffhanger', 'Cliffhanger', 585000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(168, 'zombiea', 'Zombie Bobber', 185000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(169, 'lectro', 'Lectro', 685000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(170, 'hakuchou2', 'Hakuchou Drag', 885000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(171, 'defiler', 'Defiler', 1185000, 'motorcycles', 1000, 'A premium vehicle available at our dealership.'),
	(172, 'bifta', 'Bifta', 75000, 'offroad', 1000, 'A premium vehicle available at our dealership.'),
	(173, 'blazer', 'Blazer', 8000, 'offroad', 1000, 'A premium vehicle available at our dealership.'),
	(174, 'blazer4', 'Blazer Aqua', 1755600, 'offroad', 1000, 'A premium vehicle available at our dealership.'),
	(175, 'bodhi2', 'Bodhi', 56000, 'offroad', 1000, 'A premium vehicle available at our dealership.'),
	(176, 'bfinjection', 'BF Injection', 16000, 'offroad', 1000, 'A premium vehicle available at our dealership.'),
	(177, 'brawler', 'Brawler', 715000, 'offroad', 1000, 'A premium vehicle available at our dealership.'),
	(178, 'dloader', 'Duneloader', 135000, 'offroad', 1000, 'A premium vehicle available at our dealership.'),
	(179, 'dubsta3', 'Dubsta 6x6', 249000, 'offroad', 1000, 'A premium vehicle available at our dealership.'),
	(180, 'dune', 'Dune Buggy', 20000, 'offroad', 1000, 'A premium vehicle available at our dealership.'),
	(181, 'kalahari', 'Kalahari', 40000, 'offroad', 1000, 'A premium vehicle available at our dealership.'),
	(182, 'mesa3', 'Mesa (Merryweather)', 87000, 'offroad', 1000, 'A premium vehicle available at our dealership.'),
	(183, 'rancherxl', 'Rancher XL', 59000, 'offroad', 1000, 'A premium vehicle available at our dealership.'),
	(184, 'rebel', 'Rebel', 22000, 'offroad', 1000, 'A premium vehicle available at our dealership.'),
	(185, 'rebel2', 'Rusty Rebel', 18000, 'offroad', 1000, 'A premium vehicle available at our dealership.'),
	(186, 'riata', 'Riata', 380000, 'offroad', 1000, 'A premium vehicle available at our dealership.'),
	(187, 'sandking', 'Sandking XL', 38000, 'offroad', 1000, 'A premium vehicle available at our dealership.'),
	(188, 'sandking2', 'Sandking SWB', 42000, 'offroad', 1000, 'A premium vehicle available at our dealership.'),
	(189, 'trophytruck', 'Trophy Truck', 550000, 'offroad', 1000, 'A premium vehicle available at our dealership.'),
	(190, 'trophytruck2', 'Desert Raid', 695000, 'offroad', 1000, 'A premium vehicle available at our dealership.');

-- Dumping structure for table republica.drug_plants
CREATE TABLE IF NOT EXISTS `drug_plants` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `time` int(255) NOT NULL,
  `health` double NOT NULL DEFAULT 100,
  `growtime` int(11) NOT NULL,
  `fertilizer` double NOT NULL DEFAULT 0,
  `water` double NOT NULL DEFAULT 0,
  `type` varchar(100) NOT NULL,
  `coords` longtext NOT NULL,
  `owner` longtext DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.drug_plants: ~0 rows (approximately)

-- Dumping structure for table republica.drug_processing
CREATE TABLE IF NOT EXISTS `drug_processing` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `coords` longtext NOT NULL,
  `rotation` double NOT NULL,
  `type` varchar(100) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.drug_processing: ~0 rows (approximately)

-- Dumping structure for table republica.export_xp
CREATE TABLE IF NOT EXISTS `export_xp` (
  `cid` varchar(255) NOT NULL,
  `xp` int(11) DEFAULT 0,
  `completed` int(11) DEFAULT 0,
  `failed` int(11) DEFAULT 0,
  PRIMARY KEY (`cid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.export_xp: ~13 rows (approximately)
INSERT INTO `export_xp` (`cid`, `xp`, `completed`, `failed`) VALUES
	('C79HHN67', 0, 0, 0),
	('E33O250L', 0, 0, 0),
	('GBZ4I79C', 0, 0, 0),
	('JTW7MEXP', 0, 0, 0),
	('L112A611', 0, 0, 0),
	('M2R33T1T', 0, 0, 0),
	('M4865C4Y', 0, 0, 0),
	('PE9044F8', 0, 0, 0),
	('PG4943A2', 0, 0, 0),
	('QRCMIT0E', 0, 0, 0),
	('RVA69WB5', 0, 0, 0),
	('VHB6JR43', 0, 0, 0),
	('ZDQ8H6H9', 0, 0, 0);

-- Dumping structure for table republica.fuel_stations
CREATE TABLE IF NOT EXISTS `fuel_stations` (
  `location` int(11) NOT NULL,
  `owned` int(11) DEFAULT NULL,
  `owner` varchar(50) DEFAULT NULL,
  `fuel` int(11) DEFAULT NULL,
  `fuelprice` int(11) DEFAULT NULL,
  `balance` int(255) DEFAULT NULL,
  `label` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`location`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.fuel_stations: ~27 rows (approximately)
INSERT INTO `fuel_stations` (`location`, `owned`, `owner`, `fuel`, `fuelprice`, `balance`, `label`) VALUES
	(1, 0, '0', 100000, 3, 0, 'Davis Avenue Ron'),
	(2, 0, '0', 100000, 3, 0, 'Grove Street LTD'),
	(3, 0, '0', 100000, 3, 0, 'Dutch London Xero'),
	(4, 0, '0', 100000, 3, 0, 'Little Seoul LTD'),
	(5, 0, '0', 100000, 3, 0, 'Strawberry Ave Xero'),
	(6, 0, '0', 100000, 3, 0, 'Popular Street Ron'),
	(7, 0, '0', 100000, 3, 0, 'Capital Blvd Ron'),
	(8, 0, '0', 100000, 3, 0, 'Mirror Park LTD'),
	(9, 0, '0', 100000, 3, 0, 'Clinton Ave Globe Oil'),
	(10, 0, '0', 100000, 3, 0, 'North Rockford Ron'),
	(11, 0, '0', 100000, 3, 0, 'Great Ocean Xero'),
	(12, 0, '0', 100000, 3, 0, 'Paleto Blvd Xero'),
	(13, 0, '0', 100000, 3, 0, 'Paleto Ron'),
	(14, 0, '0', 100000, 3, 0, 'Paleto Globe Oil'),
	(15, 0, '0', 100000, 3, 0, 'Grapeseed LTD'),
	(16, 0, '0', 100000, 3, 0, 'Sandy Shores Xero'),
	(17, 0, '0', 100000, 3, 0, 'Sandy Shores Globe Oil'),
	(18, 0, '0', 100000, 3, 0, 'Senora Freeway Xero'),
	(19, 0, '0', 100000, 3, 0, 'Harmony Globe Oil'),
	(20, 0, '0', 100000, 3, 0, 'Route 68 Globe Oil'),
	(21, 0, '0', 100000, 3, 0, 'Route 68 Workshop Globe O'),
	(22, 0, '0', 100000, 3, 0, 'Route 68 Xero'),
	(23, 0, '0', 100000, 3, 0, 'Route 68 Ron'),
	(24, 0, '0', 100000, 3, 0, 'Rex\'s Diner Globe Oil'),
	(25, 0, '0', 100000, 3, 0, 'Palmino Freeway Ron'),
	(26, 0, '0', 100000, 3, 0, 'North Rockford LTD'),
	(27, 0, '0', 100000, 3, 0, 'Alta Street Globe Oil');

-- Dumping structure for table republica.house_plants
CREATE TABLE IF NOT EXISTS `house_plants` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `building` varchar(30) NOT NULL,
  `stage` varchar(11) NOT NULL DEFAULT 'stage1',
  `sort` varchar(30) NOT NULL,
  `gender` enum('male','female') NOT NULL,
  `food` tinyint(4) NOT NULL DEFAULT 100,
  `health` tinyint(4) NOT NULL DEFAULT 100,
  `progress` tinyint(4) NOT NULL DEFAULT 0,
  `coords` tinytext NOT NULL,
  PRIMARY KEY (`id`),
  KEY `building` (`building`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Dumping data for table republica.house_plants: ~0 rows (approximately)

-- Dumping structure for table republica.houselocations
CREATE TABLE IF NOT EXISTS `houselocations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(255) DEFAULT NULL,
  `label` varchar(255) DEFAULT NULL,
  `coords` text DEFAULT NULL,
  `owned` tinyint(1) DEFAULT NULL,
  `price` int(11) DEFAULT NULL,
  `tier` tinyint(4) DEFAULT NULL,
  `garage` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.houselocations: ~0 rows (approximately)

-- Dumping structure for table republica.lapraces
CREATE TABLE IF NOT EXISTS `lapraces` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) DEFAULT NULL,
  `checkpoints` text DEFAULT NULL,
  `records` text DEFAULT NULL,
  `creator` varchar(50) DEFAULT NULL,
  `distance` int(11) DEFAULT NULL,
  `raceid` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `raceid` (`raceid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.lapraces: ~0 rows (approximately)

-- Dumping structure for table republica.loanshark_loans
CREATE TABLE IF NOT EXISTS `loanshark_loans` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `principal` int(11) NOT NULL DEFAULT 0,
  `due` int(11) NOT NULL DEFAULT 0,
  `created_at` bigint(20) NOT NULL DEFAULT 0,
  `deadline` bigint(20) NOT NULL DEFAULT 0,
  `stage` tinyint(4) NOT NULL DEFAULT 0,
  `reminder_mask` int(11) NOT NULL DEFAULT 0,
  `fees_applied` int(11) NOT NULL DEFAULT 0,
  `last_action` bigint(20) NOT NULL DEFAULT 0,
  `status` varchar(16) NOT NULL DEFAULT 'active',
  `closed_at` bigint(20) NOT NULL DEFAULT 0,
  `paid_amount` int(11) NOT NULL DEFAULT 0,
  `close_reason` varchar(32) NOT NULL DEFAULT '',
  `active_key` tinyint(4) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uniq_one_active` (`citizenid`,`active_key`),
  KEY `idx_cid` (`citizenid`),
  KEY `idx_status` (`status`),
  KEY `idx_loanshark_loans_status` (`status`),
  KEY `idx_loanshark_loans_citizenid` (`citizenid`),
  KEY `idx_loanshark_loans_status_deadline` (`status`,`deadline`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.loanshark_loans: ~2 rows (approximately)
INSERT INTO `loanshark_loans` (`id`, `citizenid`, `principal`, `due`, `created_at`, `deadline`, `stage`, `reminder_mask`, `fees_applied`, `last_action`, `status`, `closed_at`, `paid_amount`, `close_reason`, `active_key`) VALUES
	(1, 'ZDQ8H6H9', 500, 750, 1773674921, 1773678521, 3, 3, 200, 1773796347, 'closed', 1773796514, 750, 'paid', NULL),
	(2, 'JTW7MEXP', 500, 550, 1773706616, 1773710216, 0, 0, 0, 0, 'closed', 1773706638, 550, 'paid', NULL);

-- Dumping structure for table republica.loanshark_payments
CREATE TABLE IF NOT EXISTS `loanshark_payments` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `loan_id` bigint(20) NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `pay_type` varchar(16) NOT NULL DEFAULT '',
  `kind` varchar(16) NOT NULL DEFAULT 'payment',
  `note` varchar(64) NOT NULL DEFAULT '',
  `created_at` bigint(20) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_loan` (`loan_id`),
  KEY `idx_cid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.loanshark_payments: ~2 rows (approximately)
INSERT INTO `loanshark_payments` (`id`, `loan_id`, `citizenid`, `amount`, `pay_type`, `kind`, `note`, `created_at`) VALUES
	(1, 2, 'JTW7MEXP', 550, 'cash', 'payment', 'quitacao', 1773706638),
	(2, 1, 'ZDQ8H6H9', 750, 'bank', 'payment', 'quitacao', 1773796514);

-- Dumping structure for table republica.loanshark_rep
CREATE TABLE IF NOT EXISTS `loanshark_rep` (
  `citizenid` varchar(50) NOT NULL,
  `score` int(11) NOT NULL DEFAULT 0,
  `total_loans` int(11) NOT NULL DEFAULT 0,
  `paid_on_time` int(11) NOT NULL DEFAULT 0,
  `late_count` int(11) NOT NULL DEFAULT 0,
  `updated_at` bigint(20) NOT NULL DEFAULT 0,
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.loanshark_rep: ~2 rows (approximately)
INSERT INTO `loanshark_rep` (`citizenid`, `score`, `total_loans`, `paid_on_time`, `late_count`, `updated_at`) VALUES
	('JTW7MEXP', 7, 1, 1, 0, 1773706638),
	('ZDQ8H6H9', -18, 1, 0, 1, 1773796514);

-- Dumping structure for table republica.management_funds
CREATE TABLE IF NOT EXISTS `management_funds` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL,
  `amount` int(100) NOT NULL,
  `type` enum('boss','gang') NOT NULL DEFAULT 'boss',
  PRIMARY KEY (`id`),
  UNIQUE KEY `job_name` (`job_name`),
  KEY `type` (`type`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.management_funds: ~12 rows (approximately)
INSERT INTO `management_funds` (`id`, `job_name`, `amount`, `type`) VALUES
	(1, 'police', 0, 'boss'),
	(2, 'ambulance', 0, 'boss'),
	(3, 'realestate', 0, 'boss'),
	(4, 'taxi', 0, 'boss'),
	(5, 'cardealer', 0, 'boss'),
	(6, 'mechanic', 0, 'boss'),
	(7, 'lostmc', 0, 'gang'),
	(8, 'ballas', 0, 'gang'),
	(9, 'vagos', 0, 'gang'),
	(10, 'cartel', 0, 'gang'),
	(11, 'families', 0, 'gang'),
	(12, 'triads', 0, 'gang');

-- Dumping structure for table republica.management_outfits
CREATE TABLE IF NOT EXISTS `management_outfits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) NOT NULL,
  `type` varchar(50) NOT NULL,
  `minrank` int(11) NOT NULL DEFAULT 0,
  `name` varchar(50) NOT NULL DEFAULT 'Cool Outfit',
  `gender` varchar(50) NOT NULL DEFAULT 'male',
  `model` varchar(50) DEFAULT NULL,
  `props` text DEFAULT NULL,
  `components` text DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Dumping data for table republica.management_outfits: ~0 rows (approximately)

-- Dumping structure for table republica.management_transactions
CREATE TABLE IF NOT EXISTS `management_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `job_name` varchar(50) DEFAULT NULL,
  `gang_name` varchar(50) DEFAULT NULL,
  `amount` int(11) NOT NULL DEFAULT 0,
  `type` varchar(32) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `citizenid` varchar(50) DEFAULT NULL,
  `note` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_job_name` (`job_name`),
  KEY `idx_gang_name` (`gang_name`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Dumping data for table republica.management_transactions: ~1 rows (approximately)
INSERT INTO `management_transactions` (`id`, `job_name`, `gang_name`, `amount`, `type`, `name`, `citizenid`, `note`, `created_at`) VALUES
	(1, 'police', NULL, 100, 'deposit', 'TiãO Dev', 'ZDQ8H6H9', NULL, '2026-03-18 02:56:22');

-- Dumping structure for table republica.mdt_arrests
CREATE TABLE IF NOT EXISTS `mdt_arrests` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `reportid` int(10) unsigned NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `officer_citizenid` varchar(50) DEFAULT NULL,
  `officer_name` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `reportid` (`reportid`),
  KEY `citizenid` (`citizenid`),
  KEY `idx_mdt_arrests_citizenid` (`citizenid`),
  CONSTRAINT `FK_mdt_arrests_profiles` FOREIGN KEY (`citizenid`) REFERENCES `mdt_profiles` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_mdt_arrests_reports` FOREIGN KEY (`reportid`) REFERENCES `mdt_reports` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_arrests: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_audit_logs
CREATE TABLE IF NOT EXISTS `mdt_audit_logs` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `actor_citizenid` varchar(50) DEFAULT NULL,
  `actor_name` varchar(100) DEFAULT NULL,
  `action` varchar(100) NOT NULL,
  `entity_type` varchar(50) NOT NULL,
  `entity_id` varchar(50) DEFAULT NULL,
  `details` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `entity_type` (`entity_type`),
  KEY `entity_id` (`entity_id`),
  KEY `actor_citizenid` (`actor_citizenid`),
  KEY `action` (`action`),
  KEY `created_at` (`created_at`),
  KEY `idx_entity_lookup` (`entity_type`,`entity_id`,`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=154 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_audit_logs: ~2 rows (approximately)
INSERT INTO `mdt_audit_logs` (`id`, `actor_citizenid`, `actor_name`, `action`, `entity_type`, `entity_id`, `details`, `created_at`) VALUES
	(47, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 01:06:12'),
	(48, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 01:07:41'),
	(49, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 01:36:44'),
	(50, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 01:41:17'),
	(51, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 01:42:03'),
	(52, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 01:47:09'),
	(53, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 02:39:40'),
	(54, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 02:40:31'),
	(55, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 02:40:50'),
	(56, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 02:43:06'),
	(57, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 02:43:15'),
	(58, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 04:36:18'),
	(59, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 04:38:42'),
	(60, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 04:39:13'),
	(61, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'report_updated', 'report', '1', '{"title":"Ocorrencia caixa registradora","type":"Relatório de Prisão"}', '2026-03-23 04:39:51'),
	(62, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 04:40:35'),
	(63, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 04:41:10'),
	(64, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 04:43:10'),
	(65, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 05:18:33'),
	(66, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 16:26:46'),
	(67, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 16:28:52'),
	(68, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 16:44:58'),
	(69, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 17:43:57'),
	(70, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 18:23:07'),
	(71, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 18:23:13'),
	(72, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 18:23:21'),
	(73, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-23 18:25:23'),
	(74, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_login', 'profile', 'JTW7MEXP', '[]', '2026-03-23 23:03:26'),
	(75, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_logout', 'profile', 'JTW7MEXP', '[]', '2026-03-23 23:03:30'),
	(76, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_login', 'profile', 'JTW7MEXP', '[]', '2026-03-23 23:03:32'),
	(77, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_logout', 'profile', 'JTW7MEXP', '[]', '2026-03-23 23:04:24'),
	(78, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_login', 'profile', 'JTW7MEXP', '[]', '2026-03-23 23:05:14'),
	(79, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_logout', 'profile', 'JTW7MEXP', '[]', '2026-03-23 23:06:25'),
	(80, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_login', 'profile', 'JTW7MEXP', '[]', '2026-03-23 23:06:32'),
	(81, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_logout', 'profile', 'JTW7MEXP', '[]', '2026-03-23 23:08:31'),
	(82, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_login', 'profile', 'JTW7MEXP', '[]', '2026-03-24 01:04:30'),
	(83, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_logout', 'profile', 'JTW7MEXP', '[]', '2026-03-24 01:04:33'),
	(84, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_login', 'profile', 'JTW7MEXP', '[]', '2026-03-24 01:04:53'),
	(85, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_logout', 'profile', 'JTW7MEXP', '[]', '2026-03-24 01:05:03'),
	(86, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-24 01:05:13'),
	(87, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_logout', 'profile', 'JTW7MEXP', '[]', '2026-03-24 01:05:21'),
	(88, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_login', 'profile', 'JTW7MEXP', '[]', '2026-03-24 01:05:22'),
	(89, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_logout', 'profile', 'JTW7MEXP', '[]', '2026-03-24 01:05:25'),
	(90, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_login', 'profile', 'JTW7MEXP', '[]', '2026-03-24 01:05:25'),
	(91, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-24 01:05:37'),
	(92, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-24 01:10:15'),
	(93, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-24 01:10:35'),
	(94, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_login', 'profile', 'JTW7MEXP', '[]', '2026-03-24 01:14:23'),
	(95, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_logout', 'profile', 'JTW7MEXP', '[]', '2026-03-24 01:14:25'),
	(96, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_login', 'profile', 'JTW7MEXP', '[]', '2026-03-24 01:23:32'),
	(97, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_logout', 'profile', 'JTW7MEXP', '[]', '2026-03-24 01:23:46'),
	(98, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_login', 'profile', 'JTW7MEXP', '[]', '2026-03-24 01:23:58'),
	(99, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_logout', 'profile', 'JTW7MEXP', '[]', '2026-03-24 01:24:01'),
	(100, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_login', 'profile', 'JTW7MEXP', '[]', '2026-03-24 01:24:11'),
	(101, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-24 01:24:50'),
	(102, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_logout', 'profile', 'JTW7MEXP', '[]', '2026-03-24 01:25:03'),
	(103, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_login', 'profile', 'JTW7MEXP', '[]', '2026-03-24 01:25:13'),
	(104, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-24 01:25:27'),
	(105, 'JTW7MEXP', 'SEM CALLSIGN Maka  Patron', 'mdt_logout', 'profile', 'JTW7MEXP', '[]', '2026-03-24 01:27:48'),
	(106, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-24 02:28:13'),
	(107, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-24 02:28:14'),
	(108, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-24 02:47:21'),
	(109, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-24 02:47:22'),
	(110, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-24 02:49:16'),
	(111, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-24 02:49:17'),
	(112, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-24 03:06:33'),
	(113, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-24 03:07:11'),
	(114, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 05:31:28'),
	(115, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 05:32:32'),
	(116, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 05:32:56'),
	(117, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 05:51:43'),
	(118, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 05:52:15'),
	(119, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 05:54:43'),
	(120, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 05:56:38'),
	(121, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 06:16:17'),
	(122, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 06:31:30'),
	(123, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 12:19:39'),
	(124, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 12:29:30'),
	(125, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 12:29:55'),
	(126, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 12:30:57'),
	(127, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 12:31:05'),
	(128, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 12:31:15'),
	(129, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 12:31:17'),
	(130, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 12:31:18'),
	(131, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 12:31:26'),
	(132, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 12:31:27'),
	(133, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 12:31:30'),
	(134, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 12:31:30'),
	(135, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 12:31:35'),
	(136, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 12:31:44'),
	(137, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 12:32:06'),
	(138, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 12:34:29'),
	(139, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 13:59:10'),
	(140, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 13:59:12'),
	(141, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 13:59:21'),
	(142, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 14:01:13'),
	(143, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 14:01:48'),
	(144, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 14:01:51'),
	(145, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 14:02:14'),
	(146, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 14:02:31'),
	(147, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 14:03:52'),
	(148, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 14:05:25'),
	(149, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 14:06:17'),
	(150, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 14:46:45'),
	(151, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_logout', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 14:47:39'),
	(152, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'mdt_login', 'profile', 'ZDQ8H6H9', '[]', '2026-03-25 14:52:17'),
	(153, 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', 'report_updated', 'report', '2', '{"title":"madato teste","type":"Relatório de Ocorrência"}', '2026-03-25 14:55:12');

-- Dumping structure for table republica.mdt_awards
CREATE TABLE IF NOT EXISTS `mdt_awards` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `description` varchar(255) DEFAULT NULL,
  `icon` varchar(50) NOT NULL DEFAULT 'emoji_events',
  `category` varchar(50) NOT NULL DEFAULT 'general',
  `goal_type` varchar(50) NOT NULL,
  `goal_amount` int(10) unsigned NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_awards: ~25 rows (approximately)
INSERT INTO `mdt_awards` (`id`, `name`, `description`, `icon`, `category`, `goal_type`, `goal_amount`, `created_at`, `updated_at`) VALUES
	(1, 'First Report', 'File your first report in the MDT system', 'description', 'reports', 'reports', 1, '2026-03-22 04:35:17', '2026-03-22 04:35:17'),
	(2, '50 Reports Filed', 'File 50 reports demonstrating consistent documentation', 'description', 'reports', 'reports', 50, '2026-03-22 04:35:17', '2026-03-22 04:35:17'),
	(3, '100 Reports Filed', 'File 100 reports showing dedication to thorough record-keeping', 'description', 'reports', 'reports', 100, '2026-03-22 04:35:17', '2026-03-22 04:35:17'),
	(4, 'First Arrest', 'Make your first arrest and file the arrest report', 'local_police', 'arrests', 'arrests', 1, '2026-03-22 04:35:17', '2026-03-22 04:35:17'),
	(5, '50 Arrests', 'Process 50 arrests as a seasoned officer', 'local_police', 'arrests', 'arrests', 50, '2026-03-22 04:35:17', '2026-03-22 04:35:17'),
	(6, 'Case Worker', 'Work on 25 cases as an investigator', 'work', 'cases', 'cases', 25, '2026-03-22 04:35:17', '2026-03-22 04:35:17'),
	(7, '$100K Fined', 'Issue a total of $100,000 in fines', 'payments', 'financial', 'totalFined', 100000, '2026-03-22 04:35:17', '2026-03-22 04:35:17'),
	(8, '10 Warrants Issued', 'Issue 10 warrants for suspects', 'gavel', 'warrants', 'warrants', 10, '2026-03-22 04:35:17', '2026-03-22 04:35:17'),
	(9, 'First Report', 'File your first report in the MDT system', 'description', 'reports', 'reports', 1, '2026-03-22 04:39:57', '2026-03-22 04:39:57'),
	(10, '50 Reports Filed', 'File 50 reports demonstrating consistent documentation', 'description', 'reports', 'reports', 50, '2026-03-22 04:39:57', '2026-03-22 04:39:57'),
	(11, '100 Reports Filed', 'File 100 reports showing dedication to thorough record-keeping', 'description', 'reports', 'reports', 100, '2026-03-22 04:39:57', '2026-03-22 04:39:57'),
	(12, 'First Arrest', 'Make your first arrest and file the arrest report', 'local_police', 'arrests', 'arrests', 1, '2026-03-22 04:39:57', '2026-03-22 04:39:57'),
	(13, '50 Arrests', 'Process 50 arrests as a seasoned officer', 'local_police', 'arrests', 'arrests', 50, '2026-03-22 04:39:57', '2026-03-22 04:39:57'),
	(14, 'Case Worker', 'Work on 25 cases as an investigator', 'work', 'cases', 'cases', 25, '2026-03-22 04:39:57', '2026-03-22 04:39:57'),
	(15, '$100K Fined', 'Issue a total of $100,000 in fines', 'payments', 'financial', 'totalFined', 100000, '2026-03-22 04:39:57', '2026-03-22 04:39:57'),
	(16, '10 Warrants Issued', 'Issue 10 warrants for suspects', 'gavel', 'warrants', 'warrants', 10, '2026-03-22 04:39:57', '2026-03-22 04:39:57'),
	(17, 'First Report', 'File your first report in the MDT system', 'description', 'reports', 'reports', 1, '2026-03-22 04:40:24', '2026-03-22 04:40:24'),
	(18, '50 Reports Filed', 'File 50 reports demonstrating consistent documentation', 'description', 'reports', 'reports', 50, '2026-03-22 04:40:24', '2026-03-22 04:40:24'),
	(19, '100 Reports Filed', 'File 100 reports showing dedication to thorough record-keeping', 'description', 'reports', 'reports', 100, '2026-03-22 04:40:24', '2026-03-22 04:40:24'),
	(20, 'First Arrest', 'Make your first arrest and file the arrest report', 'local_police', 'arrests', 'arrests', 1, '2026-03-22 04:40:24', '2026-03-22 04:40:24'),
	(21, '50 Arrests', 'Process 50 arrests as a seasoned officer', 'local_police', 'arrests', 'arrests', 50, '2026-03-22 04:40:24', '2026-03-22 04:40:24'),
	(22, 'Case Worker', 'Work on 25 cases as an investigator', 'work', 'cases', 'cases', 25, '2026-03-22 04:40:24', '2026-03-22 04:40:24'),
	(23, '$100K Fined', 'Issue a total of $100,000 in fines', 'payments', 'financial', 'totalFined', 100000, '2026-03-22 04:40:24', '2026-03-22 04:40:24'),
	(24, '10 Warrants Issued', 'Issue 10 warrants for suspects', 'gavel', 'warrants', 'warrants', 10, '2026-03-22 04:40:24', '2026-03-22 04:40:24'),
	(25, 'premiação por ato de heroismo', 'premiação por ato de heroismo', 'description', 'condecoração', 'totalMultado', 10000, '2026-03-23 00:02:50', '2026-03-23 00:02:50');

-- Dumping structure for table republica.mdt_bolos
CREATE TABLE IF NOT EXISTS `mdt_bolos` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `author` varchar(50) DEFAULT NULL,
  `title` varchar(50) DEFAULT NULL,
  `plate` varchar(50) DEFAULT NULL,
  `owner` varchar(50) DEFAULT NULL,
  `individual` varchar(50) DEFAULT NULL,
  `subject_id` varchar(50) DEFAULT NULL,
  `detail` text DEFAULT NULL,
  `tags` text DEFAULT NULL,
  `gallery` text DEFAULT NULL,
  `officersinvolved` text DEFAULT NULL,
  `time` varchar(20) DEFAULT NULL,
  `jobtype` varchar(25) NOT NULL DEFAULT 'police',
  `subject_name` varchar(100) DEFAULT NULL,
  `reportId` int(11) unsigned DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `status` enum('active','inactive','resolved') NOT NULL DEFAULT 'active',
  `type` enum('citizen','vehicle','weapon','property','other') NOT NULL DEFAULT 'citizen',
  PRIMARY KEY (`id`),
  KEY `status` (`status`),
  KEY `reportId` (`reportId`),
  KEY `idx_mdt_bolos_status` (`status`),
  KEY `idx_mdt_bolos_subject_id` (`subject_id`),
  KEY `idx_mdt_bolos_reportId` (`reportId`),
  KEY `type` (`type`),
  KEY `idx_mdt_bolos_type_status_subject` (`type`,`status`,`subject_id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_bolos: ~0 rows (approximately)
INSERT INTO `mdt_bolos` (`id`, `author`, `title`, `plate`, `owner`, `individual`, `subject_id`, `detail`, `tags`, `gallery`, `officersinvolved`, `time`, `jobtype`, `subject_name`, `reportId`, `notes`, `status`, `type`) VALUES
	(1, NULL, NULL, NULL, NULL, NULL, '1', NULL, NULL, NULL, NULL, NULL, 'police', 'Tião', 1, 'Procurado por trafico', 'active', 'citizen');

-- Dumping structure for table republica.mdt_bulletin
CREATE TABLE IF NOT EXISTS `mdt_bulletin` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `title` text NOT NULL,
  `desc` text NOT NULL,
  `author` varchar(50) NOT NULL,
  `time` varchar(20) NOT NULL,
  `jobtype` varchar(25) DEFAULT 'police',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_bulletin: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_bulletins
CREATE TABLE IF NOT EXISTS `mdt_bulletins` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `content` text NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_bulletins: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_cameras
CREATE TABLE IF NOT EXISTS `mdt_cameras` (
  `cam_id` varchar(50) NOT NULL,
  `cam_label` varchar(100) NOT NULL,
  `cam_type` enum('placed','store','bank','jewelry','government','medical','other') NOT NULL DEFAULT 'placed',
  `model` varchar(50) NOT NULL DEFAULT 'security_cam_03',
  `coords` text NOT NULL,
  `rotation` text NOT NULL,
  `image` varchar(255) DEFAULT NULL,
  `can_rotate` tinyint(1) NOT NULL DEFAULT 1,
  `is_online` tinyint(1) NOT NULL DEFAULT 1,
  `spawns_model` tinyint(1) NOT NULL DEFAULT 1 COMMENT 'TRUE = spawns 3D model (player-placed), FALSE = virtual camera (uses existing world model)',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `created_by` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`cam_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_cameras: ~30 rows (approximately)
INSERT INTO `mdt_cameras` (`cam_id`, `cam_label`, `cam_type`, `model`, `coords`, `rotation`, `image`, `can_rotate`, `is_online`, `spawns_model`, `created_at`, `created_by`) VALUES
	('24701', '24/7 - Innocence Boulevard', 'store', 'security_cam_03', '{"x":23.885,"y":-1342.441,"z":31.672}', '{"x":-35.0,"y":0.0,"z":-142.9191}', 'https://files.fivemerr.com/images/ca78a638-f17a-4456-9061-1648b593e394.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('24702', '24/7 - Clinton Avenue', 'store', 'security_cam_03', '{"x":383.402,"y":328.915,"z":105.541}', '{"x":-35.0,"y":0.0,"z":118.585}', 'https://files.fivemerr.com/images/2b19a04e-0f1d-4725-8262-1da93b30391e.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('24703', '24/7 - Ineseno Road', 'store', 'security_cam_03', '{"x":-3046.749,"y":592.491,"z":9.808}', '{"x":-35.0,"y":0.0,"z":-116.673}', 'https://files.fivemerr.com/images/055956f5-6f62-48a7-80d0-c6d94540b6e4.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('24704', '24/7 - Barbareno Road', 'store', 'security_cam_03', '{"x":-3246.489,"y":1010.408,"z":14.705}', '{"x":-35.0,"y":0.0,"z":-135.2151}', 'https://files.fivemerr.com/images/14b9a9ff-4cf0-4373-a784-0723bec9c3b2.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('24705', '24/7 - Route 68', 'store', 'security_cam_03', '{"x":539.773,"y":2664.904,"z":44.056}', '{"x":-35.0,"y":0.0,"z":-42.947}', 'https://files.fivemerr.com/images/4535c506-42dc-4ca9-9f6e-ece7215e1b7f.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('24706', '24/7 - Senora Freeway', 'store', 'security_cam_03', '{"x":2673.579,"y":3281.265,"z":57.541}', '{"x":-35.0,"y":0.0,"z":-80.242}', 'https://files.fivemerr.com/images/cf0b6dc6-3310-441a-ad00-2666fe89c700.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('24707', '24/7 - Alhambra Drive', 'store', 'security_cam_03', '{"x":1966.24,"y":3749.545,"z":34.143}', '{"x":-35.0,"y":0.0,"z":163.065}', 'https://files.fivemerr.com/images/6c3eb8b8-c8a5-4a25-895c-44724ac24a6f.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('24708', '24/7 - Senora Freeway Norte', 'store', 'security_cam_03', '{"x":1729.522,"y":6419.87,"z":37.262}', '{"x":-35.0,"y":0.0,"z":-160.089}', 'https://files.fivemerr.com/images/64918129-eb25-4bd6-abe7-cc6263e36f1d.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('FLB01', 'Banco Fleeca - Legion Square', 'bank', 'security_cam_03', '{"x":144.871,"y":-1043.044,"z":31.017}', '{"x":-35.0,"y":0.0,"z":-143.9796}', 'https://files.fivemerr.com/images/92659204-5c5d-44ab-a14f-68a7f83e01f3.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('FLB02', 'Banco Fleeca - Hawick / Power', 'bank', 'security_cam_03', '{"x":309.341,"y":-281.439,"z":55.88}', '{"x":-35.0,"y":0.0,"z":-146.1595}', 'https://files.fivemerr.com/images/17a41043-bc9d-4a0c-945d-63d03ff4660d.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('FLB03', 'Banco Fleeca - Hawick / San Vitas', 'bank', 'security_cam_03', '{"x":-355.7643,"y":-52.506,"z":50.746}', '{"x":-35.0,"y":0.0,"z":-143.8711}', 'https://files.fivemerr.com/images/ead3415f-bdc5-447f-9d6f-287c77211388.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('FLB04', 'Banco Fleeca - Del Perro Boulevard', 'bank', 'security_cam_03', '{"x":-1214.226,"y":-335.86,"z":39.515}', '{"x":-35.0,"y":0.0,"z":-97.862}', 'https://files.fivemerr.com/images/6d00ce1d-6078-4a69-8cfb-ebed60cbf833.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('FLB05', 'Banco Fleeca - Great Ocean Highway', 'bank', 'security_cam_03', '{"x":-2958.885,"y":478.983,"z":17.406}', '{"x":-35.0,"y":0.0,"z":-34.69595}', 'https://files.fivemerr.com/images/dbb2ec99-8212-47f2-9f79-e0b787608ce2.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('LTD01', 'LTD - Grove Street', 'store', 'security_cam_03', '{"x":-53.14,"y":-1746.71,"z":31.54}', '{"x":-35.0,"y":0.0,"z":-168.9182}', 'https://files.fivemerr.com/images/1ff40a9c-ee6e-4c6f-9273-15bae452375e.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('LTD02', 'LTD - Ginger Street', 'store', 'security_cam_03', '{"x":-718.153,"y":-909.211,"z":21.49}', '{"x":-35.0,"y":0.0,"z":-137.1431}', 'https://files.fivemerr.com/images/ca78a638-f17a-4456-9061-1648b593e394.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('LTD03', 'LTD - West Mirror Drive', 'store', 'security_cam_03', '{"x":1151.93,"y":-320.389,"z":71.33}', '{"x":-35.0,"y":0.0,"z":-119.4468}', 'https://files.fivemerr.com/images/686831ef-ed81-4882-bd23-72c2754e38ab.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('LTD04', 'LTD - Banham Canyon Drive', 'store', 'security_cam_03', '{"x":-1832.057,"y":789.389,"z":140.436}', '{"x":-35.0,"y":0.0,"z":-91.481}', 'https://files.fivemerr.com/images/c6f53e50-75da-4e4c-806c-08be6822e884.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('PCB01', 'Banco Pacific - Saguão', 'bank', 'security_cam_03', '{"x":257.45,"y":210.07,"z":109.08}', '{"x":-25.0,"y":0.0,"z":28.05}', 'https://files.fivemerr.com/images/45bab512-5836-4449-8831-fbe67d7c886f.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('PCB02', 'Banco Pacific - Entrada Interna', 'bank', 'security_cam_03', '{"x":232.86,"y":221.46,"z":107.83}', '{"x":-25.0,"y":0.0,"z":-140.91}', 'https://files.fivemerr.com/images/4a50b347-aa12-4df2-9efc-cf3f38cc1d41.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('PCB03', 'Banco Pacific - Cofre', 'bank', 'security_cam_03', '{"x":252.27,"y":225.52,"z":103.99}', '{"x":-35.0,"y":0.0,"z":-74.87}', 'https://files.fivemerr.com/images/7c1604e9-480b-41d2-9c6b-1899c763fb51.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('PLB01', 'Banco de Paleto', 'bank', 'security_cam_03', '{"x":-102.939,"y":6467.668,"z":33.424}', '{"x":-35.0,"y":0.0,"z":24.66}', 'https://files.fivemerr.com/images/ff06da26-2cd6-4337-a1ca-c738d4267ae5.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('RLQ01', 'Rob\'s Liquor - Prosperity Street', 'store', 'security_cam_03', '{"x":-1482.9,"y":-380.463,"z":42.363}', '{"x":-35.0,"y":0.0,"z":79.53281}', 'https://files.fivemerr.com/images/b5bcfe95-3c3f-4dde-a0b9-2024ea5bfa08.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('RLQ02', 'Rob\'s Liquor - San Andreas Avenue', 'store', 'security_cam_03', '{"x":-1224.874,"y":-911.094,"z":14.401}', '{"x":-35.0,"y":0.0,"z":-6.778894}', 'https://files.fivemerr.com/images/f4aba38b-faa0-4050-ab00-ec55d8a1068d.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('RLQ03', 'Rob\'s Liquor - El Rancho Boulevard', 'store', 'security_cam_03', '{"x":1133.024,"y":-978.712,"z":48.515}', '{"x":-35.0,"y":0.0,"z":-137.302}', 'https://files.fivemerr.com/images/63f7c1dd-c537-44a4-9076-2dd9227dfa97.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('RLQ04', 'Rob\'s Liquor - Great Ocean Highway', 'store', 'security_cam_03', '{"x":-2966.15,"y":387.067,"z":17.393}', '{"x":-35.0,"y":0.0,"z":32.92229}', 'https://files.fivemerr.com/images/f25096f5-5724-4f4b-8a75-b7f968dd67ef.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('RLQ05', 'Rob\'s Liquor - Route 68', 'store', 'security_cam_03', '{"x":1169.855,"y":2711.493,"z":40.432}', '{"x":-35.0,"y":0.0,"z":127.17}', 'https://files.fivemerr.com/images/b8b8e6ff-234a-461f-8636-02c1c9247aeb.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('VGY01', 'Vangelico - Frente Direita', 'jewelry', 'security_cam_03', '{"x":-627.54,"y":-239.74,"z":40.33}', '{"x":-35.0,"y":0.0,"z":5.78}', 'https://files.fivemerr.com/images/348eca1b-17ad-48fc-8f03-1c21bd87dadc.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('VGY02', 'Vangelico - Frente Esquerda', 'jewelry', 'security_cam_03', '{"x":-627.51,"y":-229.51,"z":40.24}', '{"x":-35.0,"y":0.0,"z":-95.78}', 'https://files.fivemerr.com/images/707df30b-440e-4e55-ac93-c1878c381cee.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('VGY03', 'Vangelico - Fundos Esquerda', 'jewelry', 'security_cam_03', '{"x":-620.3,"y":-224.31,"z":40.23}', '{"x":-35.0,"y":0.0,"z":165.78}', 'https://files.fivemerr.com/images/371e5386-c901-451d-a3c4-ce7a371bee86.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM'),
	('VGY04', 'Vangelico - Lateral', 'jewelry', 'security_cam_03', '{"x":-622.57,"y":-236.3,"z":40.31}', '{"x":-35.0,"y":0.0,"z":5.78}', 'https://files.fivemerr.com/images/4c90514e-7a31-4654-a7a9-40864d106028.png', 1, 1, 0, '2026-03-22 04:35:16', 'SYSTEM');

-- Dumping structure for table republica.mdt_case_attachments
CREATE TABLE IF NOT EXISTS `mdt_case_attachments` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `case_id` int(10) unsigned NOT NULL,
  `type` enum('photo','document','other') NOT NULL DEFAULT 'document',
  `url` varchar(255) NOT NULL,
  `label` varchar(100) DEFAULT NULL,
  `uploaded_by` varchar(50) DEFAULT NULL,
  `uploaded_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `case_id` (`case_id`),
  CONSTRAINT `FK_mdt_case_attachments_cases` FOREIGN KEY (`case_id`) REFERENCES `mdt_cases` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_case_attachments: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_case_officers
CREATE TABLE IF NOT EXISTS `mdt_case_officers` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `case_id` int(10) unsigned NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `role` enum('primary','assisting','supervisor') NOT NULL DEFAULT 'assisting',
  `assigned_by` varchar(50) DEFAULT NULL,
  `assigned_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `case_id` (`case_id`),
  KEY `citizenid` (`citizenid`),
  CONSTRAINT `FK_mdt_case_officers_cases` FOREIGN KEY (`case_id`) REFERENCES `mdt_cases` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_mdt_case_officers_profiles` FOREIGN KEY (`citizenid`) REFERENCES `mdt_profiles` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_case_officers: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_case_reports
CREATE TABLE IF NOT EXISTS `mdt_case_reports` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `case_id` int(10) unsigned NOT NULL,
  `report_id` int(10) unsigned NOT NULL,
  `linked_by` varchar(50) DEFAULT NULL,
  `linked_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_case_report` (`case_id`,`report_id`),
  KEY `case_id` (`case_id`),
  KEY `report_id` (`report_id`),
  CONSTRAINT `FK_case_reports_cases` FOREIGN KEY (`case_id`) REFERENCES `mdt_cases` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_case_reports_reports` FOREIGN KEY (`report_id`) REFERENCES `mdt_reports` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_case_reports: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_cases
CREATE TABLE IF NOT EXISTS `mdt_cases` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `case_number` varchar(30) NOT NULL,
  `title` varchar(100) NOT NULL,
  `summary` text DEFAULT NULL,
  `status` enum('open','in_progress','closed') NOT NULL DEFAULT 'open',
  `priority` enum('low','medium','high') NOT NULL DEFAULT 'medium',
  `assigned_department` varchar(50) DEFAULT NULL,
  `created_by` varchar(50) NOT NULL,
  `created_by_name` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `case_number` (`case_number`),
  KEY `status` (`status`),
  KEY `assigned_department` (`assigned_department`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_cases: ~1 rows (approximately)
INSERT INTO `mdt_cases` (`id`, `case_number`, `title`, `summary`, `status`, `priority`, `assigned_department`, `created_by`, `created_by_name`, `created_at`, `updated_at`) VALUES
	(1, 'CASE-2026-00001', 'Caso pitibul', 'abertura de inquerito invetigativo ', 'open', 'medium', 'Dip', 'ZDQ8H6H9', 'SEM CALLSIGN TiãO Dev', '2026-03-22 23:22:52', '2026-03-22 23:22:52');

-- Dumping structure for table republica.mdt_citizen_licenses
CREATE TABLE IF NOT EXISTS `mdt_citizen_licenses` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `license_id` int(10) unsigned NOT NULL,
  `active` tinyint(1) NOT NULL DEFAULT 1,
  `granted_by` varchar(50) DEFAULT NULL,
  `granted_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_citizen_license` (`citizenid`,`license_id`),
  KEY `citizenid` (`citizenid`),
  KEY `license_id` (`license_id`),
  CONSTRAINT `FK_mdt_citizen_licenses_custom` FOREIGN KEY (`license_id`) REFERENCES `mdt_custom_licenses` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_citizen_licenses: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_clocking
CREATE TABLE IF NOT EXISTS `mdt_clocking` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `user_id` varchar(50) NOT NULL DEFAULT '',
  `firstname` varchar(255) NOT NULL DEFAULT '',
  `lastname` varchar(255) NOT NULL DEFAULT '',
  `clock_in_time` varchar(255) NOT NULL DEFAULT '',
  `clock_out_time` varchar(50) DEFAULT NULL,
  `total_time` int(10) NOT NULL DEFAULT 0,
  PRIMARY KEY (`user_id`) USING BTREE,
  KEY `id` (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_clocking: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_convictions
CREATE TABLE IF NOT EXISTS `mdt_convictions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cid` varchar(50) DEFAULT NULL,
  `linkedincident` int(11) NOT NULL DEFAULT 0,
  `warrant` varchar(50) DEFAULT NULL,
  `guilty` varchar(50) DEFAULT NULL,
  `processed` varchar(50) DEFAULT NULL,
  `associated` varchar(50) DEFAULT '0',
  `charges` text DEFAULT NULL,
  `fine` int(11) DEFAULT 0,
  `sentence` int(11) DEFAULT 0,
  `recfine` int(11) DEFAULT 0,
  `recsentence` int(11) DEFAULT 0,
  `time` varchar(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_mdt_convictions_cid` (`cid`),
  KEY `idx_mdt_convictions_linkedincident` (`linkedincident`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_convictions: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_custom_licenses
CREATE TABLE IF NOT EXISTS `mdt_custom_licenses` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `description` varchar(150) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_license_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_custom_licenses: ~3 rows (approximately)
INSERT INTO `mdt_custom_licenses` (`id`, `name`, `description`, `created_at`) VALUES
	(1, 'Licença de caça', 'Permição de caça para areas de reserva', '2026-03-22 04:35:17'),
	(2, 'Licença de embarcação', 'Requerimneto para dirigir embarcaçoes', '2026-03-22 04:35:17'),
	(3, 'Licença de Piloto', 'Requerimento para pilotar avioes e helicopteros', '2026-03-22 04:35:17');

-- Dumping structure for table republica.mdt_data
CREATE TABLE IF NOT EXISTS `mdt_data` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `cid` varchar(20) NOT NULL,
  `information` mediumtext DEFAULT NULL,
  `tags` text NOT NULL,
  `gallery` text NOT NULL,
  `jobtype` varchar(25) DEFAULT 'police',
  `pfp` text DEFAULT NULL,
  `fingerprint` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`cid`),
  KEY `id` (`id`),
  KEY `idx_mdt_data_fingerprint` (`fingerprint`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_data: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_evidence_custody
CREATE TABLE IF NOT EXISTS `mdt_evidence_custody` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `evidence_id` int(10) unsigned NOT NULL,
  `from_citizenid` varchar(50) DEFAULT NULL,
  `to_citizenid` varchar(50) DEFAULT NULL,
  `action` enum('collected','transferred','stored','released','updated','viewed') NOT NULL DEFAULT 'collected',
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `evidence_id` (`evidence_id`),
  CONSTRAINT `FK_mdt_evidence_custody_items` FOREIGN KEY (`evidence_id`) REFERENCES `mdt_evidence_items` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_evidence_custody: ~1 rows (approximately)
INSERT INTO `mdt_evidence_custody` (`id`, `evidence_id`, `from_citizenid`, `to_citizenid`, `action`, `notes`, `created_at`) VALUES
	(1, 1, NULL, 'ZDQ8H6H9', 'collected', 'faca suja de sangue | faca', '2026-03-22 23:28:10');

-- Dumping structure for table republica.mdt_evidence_images
CREATE TABLE IF NOT EXISTS `mdt_evidence_images` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `evidence_id` int(10) unsigned NOT NULL,
  `url` varchar(255) NOT NULL,
  `label` varchar(100) DEFAULT NULL,
  `uploaded_by` varchar(50) DEFAULT NULL,
  `uploaded_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `evidence_id` (`evidence_id`),
  CONSTRAINT `FK_mdt_evidence_images_items` FOREIGN KEY (`evidence_id`) REFERENCES `mdt_evidence_items` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_evidence_images: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_evidence_items
CREATE TABLE IF NOT EXISTS `mdt_evidence_items` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `case_id` int(10) unsigned DEFAULT NULL,
  `report_id` int(10) unsigned DEFAULT NULL,
  `title` varchar(100) NOT NULL,
  `type` varchar(50) NOT NULL,
  `serial` varchar(100) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `location` varchar(100) DEFAULT NULL,
  `stash_id` varchar(100) DEFAULT NULL,
  `stored` tinyint(1) NOT NULL DEFAULT 0,
  `last_holder` varchar(50) DEFAULT NULL,
  `created_by` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `case_id` (`case_id`),
  KEY `report_id` (`report_id`),
  KEY `last_holder` (`last_holder`),
  KEY `idx_mdt_evidence_items_case_created` (`case_id`,`created_at`),
  KEY `idx_mdt_evidence_items_report_created` (`report_id`,`created_at`),
  KEY `idx_mdt_evidence_items_type_stored` (`type`,`stored`),
  CONSTRAINT `FK_mdt_evidence_items_cases` FOREIGN KEY (`case_id`) REFERENCES `mdt_cases` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `FK_mdt_evidence_items_reports` FOREIGN KEY (`report_id`) REFERENCES `mdt_reports` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_evidence_items: ~1 rows (approximately)
INSERT INTO `mdt_evidence_items` (`id`, `case_id`, `report_id`, `title`, `type`, `serial`, `notes`, `location`, `stash_id`, `stored`, `last_holder`, `created_by`, `created_at`, `updated_at`) VALUES
	(1, 1, NULL, 'faca suja de sangue', 'Física', 'EVD-001', 'faca suja de sangue | faca', 'junto do bandido', 'LOCKER-001', 1, 'ZDQ8H6H9', 'ZDQ8H6H9', '2026-03-22 23:28:10', '2026-03-22 23:28:10');

-- Dumping structure for table republica.mdt_impound
CREATE TABLE IF NOT EXISTS `mdt_impound` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `vehicleid` int(11) NOT NULL,
  `linkedreport` int(11) NOT NULL,
  `fee` int(11) DEFAULT NULL,
  `time` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_mdt_impound_vehicleid` (`vehicleid`),
  KEY `idx_mdt_impound_linkedreport` (`linkedreport`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_impound: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_incidents
CREATE TABLE IF NOT EXISTS `mdt_incidents` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `author` varchar(50) NOT NULL DEFAULT '',
  `title` varchar(50) NOT NULL DEFAULT '0',
  `details` longtext NOT NULL,
  `tags` text NOT NULL,
  `officersinvolved` text NOT NULL,
  `civsinvolved` text NOT NULL,
  `evidence` text NOT NULL,
  `time` varchar(20) DEFAULT NULL,
  `jobtype` varchar(25) NOT NULL DEFAULT 'police',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_incidents: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_logs
CREATE TABLE IF NOT EXISTS `mdt_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `text` text NOT NULL,
  `time` varchar(20) DEFAULT NULL,
  `jobtype` varchar(25) DEFAULT 'police',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_logs: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_messages
CREATE TABLE IF NOT EXISTS `mdt_messages` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `sender_citizenid` varchar(50) NOT NULL,
  `sender_name` varchar(100) DEFAULT NULL,
  `receiver_citizenid` varchar(50) NOT NULL,
  `receiver_name` varchar(100) DEFAULT NULL,
  `subject` varchar(120) DEFAULT NULL,
  `body` text NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `read_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `sender_citizenid` (`sender_citizenid`),
  KEY `receiver_citizenid` (`receiver_citizenid`),
  CONSTRAINT `FK_mdt_messages_receiver` FOREIGN KEY (`receiver_citizenid`) REFERENCES `mdt_profiles` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_mdt_messages_sender` FOREIGN KEY (`sender_citizenid`) REFERENCES `mdt_profiles` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_messages: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_penal_codes
CREATE TABLE IF NOT EXISTS `mdt_penal_codes` (
  `code` varchar(20) NOT NULL,
  `label` varchar(100) NOT NULL,
  `charge_class` enum('felony','misdemeanor','infraction') NOT NULL,
  `months` int(10) unsigned NOT NULL DEFAULT 0,
  `fine` int(10) unsigned NOT NULL DEFAULT 0,
  `color` varchar(20) NOT NULL,
  `description` varchar(255) NOT NULL,
  PRIMARY KEY (`code`),
  KEY `label` (`label`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_penal_codes: ~99 rows (approximately)
INSERT INTO `mdt_penal_codes` (`code`, `label`, `charge_class`, `months`, `fine`, `color`, `description`) VALUES
	('P.C. 1001', 'Ameaça', 'misdemeanor', 8, 800, 'orange', 'Ameaçar alguém, por palavra, gesto ou outro meio, de causar mal injusto e grave.'),
	('P.C. 1002', 'Lesão Corporal Leve', 'misdemeanor', 10, 1000, 'orange', 'Ofender a integridade corporal ou a saúde de outra pessoa sem resultado grave.'),
	('P.C. 1003', 'Lesão Corporal Grave', 'felony', 20, 2500, 'red', 'Ofender a integridade corporal de forma grave, causando dano relevante à vítima.'),
	('P.C. 1004', 'Lesão Corporal com Arma', 'felony', 24, 3000, 'red', 'Praticar lesão corporal utilizando arma de fogo, arma branca ou objeto lesivo.'),
	('P.C. 1005', 'Tentativa de Homicídio', 'felony', 60, 10000, 'red', 'Tentar matar alguém por meio idôneo, sem consumação do resultado morte.'),
	('P.C. 1006', 'Homicídio Culposo', 'felony', 40, 7000, 'red', 'Causar a morte de alguém sem intenção, por imprudência, negligência ou imperícia.'),
	('P.C. 1007', 'Homicídio Doloso', 'felony', 90, 15000, 'red', 'Matar alguém com intenção ou assumindo o risco do resultado.'),
	('P.C. 1008', 'Homicídio Qualificado', 'felony', 120, 25000, 'red', 'Matar alguém com agravantes, como emboscada, crueldade ou recurso que dificulte defesa.'),
	('P.C. 1009', 'Sequestro', 'felony', 35, 5000, 'red', 'Privar alguém de sua liberdade mediante violência, ameaça ou fraude.'),
	('P.C. 1010', 'Cárcere Privado', 'felony', 25, 3500, 'red', 'Restringir ilegalmente a liberdade de locomoção de alguém.'),
	('P.C. 1011', 'Tortura', 'felony', 50, 10000, 'red', 'Constranger alguém com violência ou grave ameaça, causando sofrimento físico ou mental.'),
	('P.C. 1012', 'Violência Doméstica', 'felony', 24, 3500, 'red', 'Praticar violência física, psicológica, patrimonial ou moral em contexto doméstico/familiar.'),
	('P.C. 1013', 'Omissão de Socorro', 'misdemeanor', 8, 1200, 'orange', 'Deixar de prestar assistência a pessoa em perigo quando possível fazê-lo sem risco pessoal.'),
	('P.C. 1014', 'Constrangimento Ilegal', 'misdemeanor', 8, 900, 'orange', 'Constranger alguém, mediante violência ou grave ameaça, a fazer o que a lei não manda.'),
	('P.C. 1015', 'Perseguição (Stalking)', 'misdemeanor', 12, 1500, 'orange', 'Perseguir reiteradamente alguém, ameaçando sua integridade física ou psicológica.'),
	('P.C. 2001', 'Furto Simples', 'misdemeanor', 10, 1000, 'orange', 'Subtrair coisa alheia móvel sem violência ou grave ameaça.'),
	('P.C. 2002', 'Furto Qualificado', 'felony', 18, 2500, 'red', 'Furto praticado com agravantes, como rompimento de obstáculo, concurso de pessoas ou fraude.'),
	('P.C. 2003', 'Roubo', 'felony', 24, 3500, 'red', 'Subtrair bem mediante violência ou grave ameaça.'),
	('P.C. 2004', 'Roubo Majorado', 'felony', 32, 5000, 'red', 'Roubo cometido com agravantes, como concurso de agentes, arma ou restrição da liberdade.'),
	('P.C. 2005', 'Latrocínio', 'felony', 120, 30000, 'red', 'Roubo com resultado morte.'),
	('P.C. 2006', 'Receptação', 'misdemeanor', 14, 1800, 'orange', 'Adquirir, ocultar ou transportar bem de origem criminosa.'),
	('P.C. 2007', 'Receptação Qualificada', 'felony', 24, 3500, 'red', 'Receptação em contexto comercial, reiterado ou com maior gravidade.'),
	('P.C. 2008', 'Extorsão', 'felony', 24, 4000, 'red', 'Constranger alguém, mediante violência ou ameaça, para obter vantagem indevida.'),
	('P.C. 2009', 'Estelionato', 'misdemeanor', 16, 2500, 'orange', 'Obter vantagem ilícita induzindo ou mantendo alguém em erro por fraude.'),
	('P.C. 2010', 'Dano ao Patrimônio', 'infraction', 0, 800, 'green', 'Destruir, inutilizar ou deteriorar coisa alheia.'),
	('P.C. 2011', 'Dano ao Patrimônio Público', 'misdemeanor', 14, 2200, 'orange', 'Danificar bem pertencente ao poder público ou serviço essencial.'),
	('P.C. 2012', 'Invasão de Domicílio', 'misdemeanor', 12, 1500, 'orange', 'Entrar ou permanecer em casa alheia sem consentimento legal.'),
	('P.C. 2013', 'Violação de Propriedade', 'infraction', 0, 600, 'green', 'Entrar ou permanecer em área privada ou restrita sem autorização.'),
	('P.C. 2014', 'Apropriação Indébita', 'misdemeanor', 12, 1800, 'orange', 'Apropriar-se de bem móvel de que tem posse ou detenção legítima.'),
	('P.C. 2015', 'Fraude Eletrônica', 'misdemeanor', 18, 3000, 'orange', 'Aplicar golpe por meio digital, eletrônico ou bancário.'),
	('P.C. 2016', 'Roubo de Veículo', 'felony', 22, 3500, 'red', 'Subtrair veículo mediante violência ou grave ameaça.'),
	('P.C. 2017', 'Furto de Veículo', 'felony', 18, 2800, 'red', 'Subtrair veículo sem violência ou grave ameaça.'),
	('P.C. 2018', 'Adulteração de Sinal Identificador de Veículo', 'felony', 20, 3500, 'red', 'Alterar, remover ou adulterar placa, chassi ou identificação de veículo.'),
	('P.C. 3001', 'Desacato', 'misdemeanor', 10, 1200, 'orange', 'Desrespeitar ou ofender funcionário público no exercício da função.'),
	('P.C. 3002', 'Desobediência', 'misdemeanor', 8, 900, 'orange', 'Descumprir ordem legal de funcionário público.'),
	('P.C. 3003', 'Resistência à Prisão', 'misdemeanor', 12, 1500, 'orange', 'Opor-se à execução de ato legal mediante violência ou ameaça.'),
	('P.C. 3004', 'Obstrução da Justiça', 'felony', 18, 2500, 'red', 'Dificultar investigação, diligência policial ou ato judicial.'),
	('P.C. 3005', 'Falso Testemunho', 'felony', 16, 2500, 'red', 'Fazer afirmação falsa ou negar a verdade em procedimento legal.'),
	('P.C. 3006', 'Falsa Comunicação de Crime', 'misdemeanor', 10, 1500, 'orange', 'Provocar ação policial comunicando crime ou ocorrência inexistente.'),
	('P.C. 3007', 'Falsidade Ideológica', 'felony', 18, 2500, 'red', 'Inserir declaração falsa em documento público ou particular.'),
	('P.C. 3008', 'Uso de Documento Falso', 'felony', 18, 2500, 'red', 'Utilizar documento falsificado ou adulterado.'),
	('P.C. 3009', 'Identidade Falsa', 'misdemeanor', 10, 1500, 'orange', 'Atribuir-se falsa identidade para obter vantagem ou ocultar antecedentes.'),
	('P.C. 3010', 'Corrupção Ativa', 'felony', 22, 4000, 'red', 'Oferecer vantagem indevida a funcionário público.'),
	('P.C. 3011', 'Corrupção Passiva', 'felony', 26, 5000, 'red', 'Solicitar ou receber vantagem indevida em razão da função pública.'),
	('P.C. 3012', 'Prevaricação', 'felony', 18, 3000, 'red', 'Retardar ou deixar de praticar ato de ofício para satisfazer interesse pessoal.'),
	('P.C. 3013', 'Peculato', 'felony', 30, 7000, 'red', 'Desviar ou apropriar-se de dinheiro, valor ou bem público em razão do cargo.'),
	('P.C. 3014', 'Favorecimento Pessoal', 'misdemeanor', 12, 1500, 'orange', 'Auxiliar autor de crime a escapar da ação da autoridade.'),
	('P.C. 3015', 'Favorecimento Real', 'misdemeanor', 12, 1500, 'orange', 'Auxiliar na ocultação ou aproveitamento de produto de crime.'),
	('P.C. 3016', 'Fuga do Cárcere', 'felony', 18, 2500, 'red', 'Evadir-se de custódia, cela, penitenciária ou estabelecimento prisional.'),
	('P.C. 3017', 'Auxílio à Fuga', 'felony', 20, 3000, 'red', 'Facilitar ou promover fuga de preso ou detido.'),
	('P.C. 3018', 'Descumprimento de Ordem Judicial', 'misdemeanor', 12, 1800, 'orange', 'Descumprir decisão, medida ou determinação expedida por autoridade competente.'),
	('P.C. 3019', 'Descumprimento de Medida Protetiva', 'felony', 18, 3000, 'red', 'Violar medida protetiva regularmente imposta por autoridade competente.'),
	('P.C. 3020', 'Usurpação de Função Pública', 'felony', 18, 2500, 'red', 'Exercer função pública sem autorização legal.'),
	('P.C. 4001', 'Porte Ilegal de Arma Leve', 'felony', 14, 2000, 'red', 'Portar arma de fogo sem autorização legal.'),
	('P.C. 4002', 'Porte Ilegal de Arma Restrita', 'felony', 24, 4500, 'red', 'Portar arma de uso restrito ou proibido sem autorização legal.'),
	('P.C. 4003', 'Posse Irregular de Arma de Fogo', 'misdemeanor', 10, 1500, 'orange', 'Manter arma de fogo em local não autorizado ou sem regularização.'),
	('P.C. 4004', 'Disparo de Arma de Fogo', 'felony', 18, 3000, 'red', 'Efetuar disparo em via pública ou local habitado sem justificativa legal.'),
	('P.C. 4005', 'Tráfico de Armas', 'felony', 36, 8000, 'red', 'Comercializar, distribuir ou intermediar armas ilegalmente.'),
	('P.C. 4006', 'Comércio Ilegal de Munição', 'felony', 24, 4500, 'red', 'Comercializar ou distribuir munições sem autorização legal.'),
	('P.C. 4007', 'Posse de Explosivos', 'felony', 22, 4000, 'red', 'Possuir explosivos ou artefatos proibidos sem autorização legal.'),
	('P.C. 4008', 'Uso Criminoso de Explosivos', 'felony', 36, 8000, 'red', 'Utilizar explosivos para cometer crime ou causar dano.'),
	('P.C. 4009', 'Arma com Numeração Suprimida', 'felony', 24, 4500, 'red', 'Possuir ou portar arma com identificação raspada ou adulterada.'),
	('P.C. 4010', 'Exibição Ostensiva de Arma', 'misdemeanor', 10, 1200, 'orange', 'Exibir arma de forma intimidatória sem justificativa legal.'),
	('P.C. 5001', 'Posse de Entorpecente para Uso Pessoal', 'misdemeanor', 8, 1000, 'orange', 'Portar pequena quantidade de substância ilícita para consumo próprio.'),
	('P.C. 5002', 'Posse de Entorpecente com Indício de Tráfico', 'felony', 18, 3000, 'red', 'Portar substância ilícita em condições incompatíveis com uso pessoal.'),
	('P.C. 5003', 'Tráfico de Entorpecentes', 'felony', 30, 6000, 'red', 'Vender, fornecer, guardar ou transportar droga para comercialização.'),
	('P.C. 5004', 'Associação para o Tráfico', 'felony', 26, 5000, 'red', 'Associar-se de forma estável para prática do tráfico de drogas.'),
	('P.C. 5005', 'Cultivo Ilegal de Entorpecentes', 'felony', 20, 3500, 'red', 'Cultivar plantas ou matéria-prima destinada à produção de droga ilícita.'),
	('P.C. 5006', 'Produção / Refino de Entorpecentes', 'felony', 28, 5500, 'red', 'Fabricar, preparar ou refinar substância entorpecente ilícita.'),
	('P.C. 5007', 'Tráfico Interestadual / Interestadual Simulado', 'felony', 34, 7000, 'red', 'Transportar grandes quantidades de entorpecentes com finalidade de distribuição.'),
	('P.C. 5008', 'Fornecimento de Entorpecente a Menor', 'felony', 24, 4500, 'red', 'Entregar, vender ou induzir menor ao uso de entorpecente.'),
	('P.C. 6001', 'Conduzir sem Habilitação', 'infraction', 0, 800, 'green', 'Conduzir veículo automotor sem habilitação válida.'),
	('P.C. 6002', 'Direção Perigosa', 'misdemeanor', 10, 1500, 'orange', 'Conduzir veículo de forma a colocar terceiros em risco.'),
	('P.C. 6003', 'Direção sob Influência de Álcool ou Drogas', 'misdemeanor', 12, 2000, 'orange', 'Conduzir veículo sob efeito de álcool ou substância psicoativa.'),
	('P.C. 6004', 'Fuga de Abordagem', 'misdemeanor', 12, 1800, 'orange', 'Evadir-se de abordagem policial ou ordem legal de parada.'),
	('P.C. 6005', 'Fuga com Direção Perigosa', 'felony', 20, 3500, 'red', 'Evadir-se de abordagem policial colocando terceiros em risco.'),
	('P.C. 6006', 'Racha / Corrida Ilegal', 'felony', 20, 3000, 'red', 'Participar de disputa, corrida ou exibição automobilística não autorizada.'),
	('P.C. 6007', 'Omissão de Socorro no Trânsito', 'misdemeanor', 12, 1800, 'orange', 'Deixar de prestar socorro em acidente de trânsito quando possível.'),
	('P.C. 6008', 'Fuga do Local de Acidente', 'misdemeanor', 10, 1500, 'orange', 'Evadir-se do local de acidente para fugir de responsabilidade.'),
	('P.C. 6009', 'Excesso de Velocidade - Leve', 'infraction', 0, 300, 'green', 'Transitar acima do limite em patamar leve.'),
	('P.C. 6010', 'Excesso de Velocidade - Médio', 'infraction', 0, 600, 'green', 'Transitar acima do limite em patamar médio.'),
	('P.C. 6011', 'Excesso de Velocidade - Grave', 'misdemeanor', 6, 1200, 'orange', 'Transitar acima do limite em patamar grave.'),
	('P.C. 6012', 'Avanço de Sinal / Preferencial', 'infraction', 0, 350, 'green', 'Desrespeitar semáforo, parada obrigatória ou preferência legal.'),
	('P.C. 6013', 'Estacionamento Proibido', 'infraction', 0, 250, 'green', 'Estacionar em local proibido, obstruindo fluxo ou área restrita.'),
	('P.C. 6014', 'Veículo Irregular / Adulterado', 'misdemeanor', 10, 1800, 'orange', 'Conduzir veículo sem condições legais, documentação regular ou com adulteração identificadora.'),
	('P.C. 7001', 'Perturbação do Sossego', 'infraction', 0, 500, 'green', 'Perturbar o trabalho ou o descanso alheio com barulho, gritaria ou abuso sonoro.'),
	('P.C. 7002', 'Desordem / Conduta Desordeira', 'infraction', 0, 400, 'green', 'Provocar tumulto, algazarra ou conduta ofensiva em local público.'),
	('P.C. 7003', 'Aglomeração Ilícita', 'misdemeanor', 8, 1000, 'orange', 'Promover ou participar de reunião tumultuária com risco à ordem pública.'),
	('P.C. 7004', 'Incitação à Violência', 'misdemeanor', 12, 1500, 'orange', 'Instigar publicamente a prática de violência ou crime.'),
	('P.C. 7005', 'Vandalismo', 'misdemeanor', 10, 1500, 'orange', 'Depredar patrimônio público ou privado de forma dolosa.'),
	('P.C. 7006', 'Pichação', 'infraction', 0, 600, 'green', 'Pichar ou conspurcar edificação ou monumento sem autorização.'),
	('P.C. 7007', 'Uso Indevido de Equipamento de Emergência', 'misdemeanor', 10, 1500, 'orange', 'Utilizar sirene, luz ou equipamento de emergência sem autorização.'),
	('P.C. 7008', 'Falsa Identidade Funcional', 'felony', 18, 3000, 'red', 'Passar-se por policial, servidor público ou função oficial sem autorização.'),
	('P.C. 7009', 'Lavagem de Dinheiro', 'felony', 30, 7000, 'red', 'Ocultar ou dissimular origem ilícita de valores ou bens.'),
	('P.C. 7010', 'Associação Criminosa', 'felony', 22, 4000, 'red', 'Associar-se com três ou mais pessoas para prática de crimes.'),
	('P.C. 7011', 'Organização Criminosa', 'felony', 36, 9000, 'red', 'Integrar grupo estruturado e estável voltado à prática de crimes graves.'),
	('P.C. 7012', 'Ocultação de Cadáver', 'felony', 24, 5000, 'red', 'Ocultar, destruir ou dificultar localização de cadáver.'),
	('P.C. 7013', 'Profanação de Cadáver', 'felony', 18, 3000, 'red', 'Violar, ultrajar ou desrespeitar cadáver ou local de sepultamento.'),
	('P.C. 7014', 'Suborno', 'felony', 20, 4000, 'red', 'Oferecer vantagem indevida para obter benefício ilícito em procedimento oficial.');

-- Dumping structure for table republica.mdt_permission_roles
CREATE TABLE IF NOT EXISTS `mdt_permission_roles` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `job` varchar(50) NOT NULL,
  `grade` int(10) unsigned NOT NULL,
  `permissions` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`permissions`)),
  `updated_by` varchar(50) DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `job_grade` (`job`,`grade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_permission_roles: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_profile_sessions
CREATE TABLE IF NOT EXISTS `mdt_profile_sessions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `profile_id` int(10) unsigned NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `source` int(11) DEFAULT NULL,
  `login_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `logout_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `profile_id` (`profile_id`),
  KEY `citizenid` (`citizenid`),
  KEY `idx_profile_logout` (`profile_id`,`logout_at`),
  CONSTRAINT `FK_mdt_profile_sessions_profiles` FOREIGN KEY (`profile_id`) REFERENCES `mdt_profiles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=79 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_profile_sessions: ~49 rows (approximately)
INSERT INTO `mdt_profile_sessions` (`id`, `profile_id`, `citizenid`, `source`, `login_at`, `logout_at`) VALUES
	(1, 1, 'ZDQ8H6H9', 1, '2026-03-22 12:52:28', '2026-03-22 12:52:44'),
	(2, 1, 'ZDQ8H6H9', 1, '2026-03-22 12:56:26', '2026-03-22 12:56:48'),
	(3, 1, 'ZDQ8H6H9', 1, '2026-03-22 13:01:13', '2026-03-22 13:01:25'),
	(4, 1, 'ZDQ8H6H9', 1, '2026-03-22 13:33:26', '2026-03-22 13:33:33'),
	(5, 1, 'ZDQ8H6H9', 1, '2026-03-22 13:42:49', '2026-03-22 13:43:54'),
	(6, 1, 'ZDQ8H6H9', 1, '2026-03-22 16:29:20', '2026-03-22 16:29:22'),
	(7, 1, 'ZDQ8H6H9', 1, '2026-03-22 16:29:33', '2026-03-22 16:33:41'),
	(8, 1, 'ZDQ8H6H9', 1, '2026-03-22 17:00:06', '2026-03-22 17:01:36'),
	(9, 1, 'ZDQ8H6H9', 1, '2026-03-22 22:56:44', '2026-03-22 22:59:27'),
	(10, 1, 'ZDQ8H6H9', 1, '2026-03-22 22:59:38', '2026-03-22 23:01:15'),
	(11, 1, 'ZDQ8H6H9', 1, '2026-03-22 23:01:24', '2026-03-22 23:01:56'),
	(12, 1, 'ZDQ8H6H9', 1, '2026-03-22 23:02:39', '2026-03-22 23:05:09'),
	(13, 1, 'ZDQ8H6H9', 1, '2026-03-22 23:05:09', '2026-03-22 23:05:16'),
	(14, 1, 'ZDQ8H6H9', 1, '2026-03-22 23:05:16', '2026-03-22 23:40:45'),
	(15, 1, 'ZDQ8H6H9', 1, '2026-03-22 23:40:51', '2026-03-22 23:45:53'),
	(16, 1, 'ZDQ8H6H9', 1, '2026-03-22 23:46:07', '2026-03-22 23:47:48'),
	(17, 1, 'ZDQ8H6H9', 1, '2026-03-22 23:48:16', '2026-03-22 23:49:11'),
	(18, 1, 'ZDQ8H6H9', 1, '2026-03-22 23:49:34', '2026-03-23 00:03:36'),
	(19, 1, 'ZDQ8H6H9', 1, '2026-03-23 01:06:12', '2026-03-23 01:07:41'),
	(20, 1, 'ZDQ8H6H9', 1, '2026-03-23 01:36:44', '2026-03-23 01:41:17'),
	(21, 1, 'ZDQ8H6H9', 1, '2026-03-23 01:42:02', '2026-03-23 01:47:09'),
	(22, 1, 'ZDQ8H6H9', 1, '2026-03-23 02:39:40', '2026-03-23 02:40:31'),
	(23, 1, 'ZDQ8H6H9', 1, '2026-03-23 02:40:50', '2026-03-23 02:43:06'),
	(24, 1, 'ZDQ8H6H9', 1, '2026-03-23 02:43:15', '2026-03-23 02:53:14'),
	(25, 1, 'ZDQ8H6H9', 1, '2026-03-23 04:36:18', '2026-03-23 04:38:42'),
	(26, 1, 'ZDQ8H6H9', 1, '2026-03-23 04:39:13', '2026-03-23 04:40:35'),
	(27, 1, 'ZDQ8H6H9', 1, '2026-03-23 04:41:10', '2026-03-23 04:43:10'),
	(28, 1, 'ZDQ8H6H9', 1, '2026-03-23 05:18:33', '2026-03-23 05:21:18'),
	(29, 1, 'ZDQ8H6H9', 1, '2026-03-23 16:26:46', '2026-03-23 16:28:52'),
	(30, 1, 'ZDQ8H6H9', 1, '2026-03-23 16:44:58', '2026-03-23 17:01:45'),
	(31, 1, 'ZDQ8H6H9', 1, '2026-03-23 17:43:57', '2026-03-23 17:47:55'),
	(32, 1, 'ZDQ8H6H9', 2, '2026-03-23 18:23:07', '2026-03-23 18:23:13'),
	(33, 1, 'ZDQ8H6H9', 2, '2026-03-23 18:23:20', '2026-03-23 18:25:23'),
	(34, 6, 'JTW7MEXP', 1, '2026-03-23 23:03:26', '2026-03-23 23:03:30'),
	(35, 6, 'JTW7MEXP', 1, '2026-03-23 23:03:32', '2026-03-23 23:04:24'),
	(36, 6, 'JTW7MEXP', 1, '2026-03-23 23:05:13', '2026-03-23 23:06:25'),
	(37, 6, 'JTW7MEXP', 1, '2026-03-23 23:06:32', '2026-03-23 23:08:30'),
	(38, 6, 'JTW7MEXP', 3, '2026-03-24 01:04:30', '2026-03-24 01:04:33'),
	(39, 6, 'JTW7MEXP', 3, '2026-03-24 01:04:53', '2026-03-24 01:05:02'),
	(40, 1, 'ZDQ8H6H9', 2, '2026-03-24 01:05:13', '2026-03-24 01:05:37'),
	(41, 6, 'JTW7MEXP', 3, '2026-03-24 01:05:21', '2026-03-24 01:05:25'),
	(42, 6, 'JTW7MEXP', 3, '2026-03-24 01:05:25', '2026-03-24 01:11:27'),
	(43, 1, 'ZDQ8H6H9', 2, '2026-03-24 01:10:15', '2026-03-24 01:10:35'),
	(44, 6, 'JTW7MEXP', 4, '2026-03-24 01:14:22', '2026-03-24 01:14:25'),
	(45, 6, 'JTW7MEXP', 4, '2026-03-24 01:23:32', '2026-03-24 01:23:46'),
	(46, 6, 'JTW7MEXP', 4, '2026-03-24 01:23:58', '2026-03-24 01:24:01'),
	(47, 6, 'JTW7MEXP', 4, '2026-03-24 01:24:11', '2026-03-24 01:25:03'),
	(48, 1, 'ZDQ8H6H9', 2, '2026-03-24 01:24:50', '2026-03-24 01:25:26'),
	(49, 6, 'JTW7MEXP', 4, '2026-03-24 01:25:13', '2026-03-24 01:27:48'),
	(50, 1, 'ZDQ8H6H9', 5, '2026-03-24 02:28:13', '2026-03-24 02:28:14'),
	(51, 1, 'ZDQ8H6H9', 5, '2026-03-24 02:47:21', '2026-03-24 02:47:22'),
	(52, 1, 'ZDQ8H6H9', 5, '2026-03-24 02:49:16', '2026-03-24 02:49:17'),
	(53, 1, 'ZDQ8H6H9', 5, '2026-03-24 03:06:33', '2026-03-24 03:07:11'),
	(54, 1, 'ZDQ8H6H9', 1, '2026-03-25 05:31:28', '2026-03-25 05:32:32'),
	(55, 1, 'ZDQ8H6H9', 1, '2026-03-25 05:32:32', '2026-03-25 05:32:56'),
	(56, 1, 'ZDQ8H6H9', 1, '2026-03-25 05:32:56', '2026-03-25 05:41:45'),
	(57, 1, 'ZDQ8H6H9', 1, '2026-03-25 05:51:43', '2026-03-25 05:52:15'),
	(58, 1, 'ZDQ8H6H9', 1, '2026-03-25 05:52:15', '2026-03-25 05:54:43'),
	(59, 1, 'ZDQ8H6H9', 1, '2026-03-25 05:54:43', '2026-03-25 05:56:38'),
	(60, 1, 'ZDQ8H6H9', 1, '2026-03-25 05:56:38', '2026-03-25 05:59:40'),
	(61, 1, 'ZDQ8H6H9', 1, '2026-03-25 06:16:17', '2026-03-25 06:17:28'),
	(62, 1, 'ZDQ8H6H9', 1, '2026-03-25 06:31:30', '2026-03-25 06:33:45'),
	(63, 1, 'ZDQ8H6H9', 1, '2026-03-25 12:19:39', '2026-03-25 12:29:30'),
	(64, 1, 'ZDQ8H6H9', 1, '2026-03-25 12:29:55', '2026-03-25 12:30:57'),
	(65, 1, 'ZDQ8H6H9', 1, '2026-03-25 12:31:05', '2026-03-25 12:31:15'),
	(66, 1, 'ZDQ8H6H9', 1, '2026-03-25 12:31:17', '2026-03-25 12:31:18'),
	(67, 1, 'ZDQ8H6H9', 1, '2026-03-25 12:31:26', '2026-03-25 12:31:27'),
	(68, 1, 'ZDQ8H6H9', 1, '2026-03-25 12:31:30', '2026-03-25 12:31:30'),
	(69, 1, 'ZDQ8H6H9', 1, '2026-03-25 12:31:35', '2026-03-25 12:31:43'),
	(70, 1, 'ZDQ8H6H9', 1, '2026-03-25 12:32:06', '2026-03-25 12:34:28'),
	(71, 1, 'ZDQ8H6H9', 1, '2026-03-25 13:59:10', '2026-03-25 13:59:12'),
	(72, 1, 'ZDQ8H6H9', 1, '2026-03-25 13:59:21', '2026-03-25 14:01:13'),
	(73, 1, 'ZDQ8H6H9', 1, '2026-03-25 14:01:48', '2026-03-25 14:01:51'),
	(74, 1, 'ZDQ8H6H9', 1, '2026-03-25 14:02:14', '2026-03-25 14:02:31'),
	(75, 1, 'ZDQ8H6H9', 1, '2026-03-25 14:03:52', '2026-03-25 14:05:25'),
	(76, 1, 'ZDQ8H6H9', 1, '2026-03-25 14:06:17', '2026-03-25 14:10:11'),
	(77, 1, 'ZDQ8H6H9', 1, '2026-03-25 14:46:44', '2026-03-25 14:47:39'),
	(78, 1, 'ZDQ8H6H9', 1, '2026-03-25 14:52:16', NULL);

-- Dumping structure for table republica.mdt_profiles
CREATE TABLE IF NOT EXISTS `mdt_profiles` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) NOT NULL,
  `fullname` varchar(50) NOT NULL,
  `callsign` varchar(50) DEFAULT NULL,
  `badge_number` varchar(20) DEFAULT NULL,
  `rank` varchar(50) DEFAULT NULL,
  `department` varchar(50) DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `profilepicture` varchar(255) DEFAULT NULL,
  `certifications` text DEFAULT NULL,
  `last_login_at` timestamp NULL DEFAULT NULL,
  `last_logout_at` timestamp NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizenid` (`citizenid`),
  UNIQUE KEY `callsign` (`callsign`),
  KEY `badge_number` (`badge_number`),
  KEY `idx_department` (`department`),
  KEY `idx_mdt_profiles_department_rank` (`department`,`rank`),
  KEY `idx_mdt_profiles_citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_profiles: ~4 rows (approximately)
INSERT INTO `mdt_profiles` (`id`, `citizenid`, `fullname`, `callsign`, `badge_number`, `rank`, `department`, `notes`, `profilepicture`, `certifications`, `last_login_at`, `last_logout_at`) VALUES
	(1, 'ZDQ8H6H9', 'TiãO Dev', NULL, 'SEM CALLSIGN', 'CORONEL', 'police', NULL, 'https://r2.fivemanage.com/H1Btzbhf8X3sGIqpq1gEN/suspect_ZDQ8H6H9.png', NULL, '2026-03-25 14:52:16', '2026-03-25 14:47:39'),
	(4, 'E33O250L', 'Will Dgk', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	(5, 'PE9044F8', 'Bruno Pitbull', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
	(6, 'JTW7MEXP', 'Maka  Patron', NULL, NULL, 'CORONEL', 'police', NULL, NULL, NULL, '2026-03-24 01:25:13', '2026-03-24 01:30:25'),
	(7, 'GBZ4I79C', 'Cavalcante Willian', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

-- Dumping structure for table republica.mdt_profiles_clocking
CREATE TABLE IF NOT EXISTS `mdt_profiles_clocking` (
  `profileId` int(10) unsigned NOT NULL,
  `clockindate` timestamp NOT NULL DEFAULT current_timestamp(),
  `clockoutdate` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  KEY `FK_mdt_profiles_clocking_mdt_profiles` (`profileId`),
  CONSTRAINT `FK_mdt_profiles_clocking_mdt_profiles` FOREIGN KEY (`profileId`) REFERENCES `mdt_profiles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_profiles_clocking: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_profiles_gallery
CREATE TABLE IF NOT EXISTS `mdt_profiles_gallery` (
  `profileId` int(10) unsigned NOT NULL,
  `image` varchar(255) NOT NULL,
  `label` varchar(50) DEFAULT NULL,
  `datecreated` timestamp NOT NULL DEFAULT current_timestamp(),
  KEY `FK_mdt_profiles_gallery_mdt_profiles` (`profileId`),
  CONSTRAINT `FK_mdt_profiles_gallery_mdt_profiles` FOREIGN KEY (`profileId`) REFERENCES `mdt_profiles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_profiles_gallery: ~0 rows (approximately)
INSERT INTO `mdt_profiles_gallery` (`profileId`, `image`, `label`, `datecreated`) VALUES
	(1, 'https://r2.fivemanage.com/H1Btzbhf8X3sGIqpq1gEN/suspect_ZDQ8H6H9.png', 'Profile Photo', '2026-03-23 17:44:47');

-- Dumping structure for table republica.mdt_profiles_identifiers
CREATE TABLE IF NOT EXISTS `mdt_profiles_identifiers` (
  `profileId` int(10) unsigned NOT NULL,
  `content` varchar(50) NOT NULL,
  `datecreated` timestamp NOT NULL DEFAULT current_timestamp(),
  KEY `FK_mdt_profiles_identifiers_mdt_profiles` (`profileId`),
  CONSTRAINT `FK_mdt_profiles_identifiers_mdt_profiles` FOREIGN KEY (`profileId`) REFERENCES `mdt_profiles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_profiles_identifiers: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_profiles_tags
CREATE TABLE IF NOT EXISTS `mdt_profiles_tags` (
  `profileId` int(10) unsigned NOT NULL,
  `tag` varchar(15) NOT NULL,
  UNIQUE KEY `unique_profile_tag` (`profileId`,`tag`),
  KEY `FK_mdt_profiles_tags_mdt_profiles` (`profileId`),
  CONSTRAINT `FK_mdt_profiles_tags_mdt_profiles` FOREIGN KEY (`profileId`) REFERENCES `mdt_profiles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_profiles_tags: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_report_templates
CREATE TABLE IF NOT EXISTS `mdt_report_templates` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `type` varchar(50) NOT NULL,
  `content` longtext NOT NULL,
  `job_type` enum('leo','ems','all') NOT NULL DEFAULT 'all',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_mdt_report_templates_job_type` (`job_type`),
  KEY `idx_mdt_report_templates_type_name` (`type`,`name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_report_templates: ~3 rows (approximately)
INSERT INTO `mdt_report_templates` (`id`, `name`, `type`, `content`, `job_type`, `created_at`, `updated_at`) VALUES
	(4, 'Abordagem de Rotina', 'report', '1. DATA E HORA:\n\n2. LOCAL DA ABORDAGEM:\n\n3. GUARNIÇÃO / POLICIAIS ENVOLVIDOS:\n\n4. MOTIVAÇÃO DA ABORDAGEM:\n\n5. IDENTIFICAÇÃO DO(S) ABORDADO(S):\n- Nome:\n- Documento / ID:\n- Telefone, se aplicável:\n\n6. CONDIÇÕES ENCONTRADAS NO LOCAL:\n\n7. BUSCA PESSOAL / VEICULAR:\n\n8. OBJETOS / MATERIAIS ENCONTRADOS:\n\n9. PROVIDÊNCIAS ADOTADAS:\n\n10. OBSERVAÇÕES FINAIS:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(5, 'Atendimento de Denúncia', 'report', '1. DATA E HORA DO ATENDIMENTO:\n\n2. LOCAL INFORMADO:\n\n3. NATUREZA DA DENÚNCIA:\n\n4. FORMA DE RECEBIMENTO DA DENÚNCIA:\n- 190 / central / anônima / popular / outra\n\n5. GUARNIÇÃO RESPONSÁVEL:\n\n6. VERIFICAÇÃO REALIZADA NO LOCAL:\n\n7. PESSOAS ENVOLVIDAS / IDENTIFICADAS:\n\n8. MATERIAIS / OBJETOS ENCONTRADOS:\n\n9. RESULTADO DA DILIGÊNCIA:\n\n10. PROVIDÊNCIAS ADOTADAS:\n\n11. OBSERVAÇÕES COMPLEMENTARES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(6, 'Apoio a Outra Guarnição', 'report', '1. DATA E HORA:\n\n2. GUARNIÇÃO SOLICITANTE:\n\n3. GUARNIÇÃO DE APOIO:\n\n4. LOCAL DA OCORRÊNCIA:\n\n5. MOTIVO DO APOIO:\n\n6. SITUAÇÃO ENCONTRADA:\n\n7. AÇÕES REALIZADAS PELA EQUIPE DE APOIO:\n\n8. PESSOAS ENVOLVIDAS:\n\n9. RESULTADO DA AÇÃO:\n\n10. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(7, 'Furto', 'report', '1. DATA E HORA DO FATO:\n\n2. LOCAL DO FATO:\n\n3. VÍTIMA:\n- Nome:\n- Documento / ID:\n- Contato:\n\n4. BEM SUBTRAÍDO:\n\n5. CIRCUNSTÂNCIAS INFORMADAS:\n\n6. SUSPEITO(S), SE HOUVER:\n\n7. TESTEMUNHAS, SE HOUVER:\n\n8. IMAGENS / CÂMERAS / EVIDÊNCIAS:\n\n9. PROVIDÊNCIAS ADOTADAS:\n\n10. OBSERVAÇÕES COMPLEMENTARES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(8, 'Roubo', 'report', '1. DATA E HORA DO FATO:\n\n2. LOCAL DO FATO:\n\n3. VÍTIMA:\n\n4. BENS SUBTRAÍDOS:\n\n5. EMPREGO DE VIOLÊNCIA OU GRAVE AMEAÇA:\n\n6. USO DE ARMA / TIPO DE ARMA:\n\n7. SUSPEITO(S):\n- Quantidade:\n- Características:\n- Vestimentas:\n- Direção de fuga:\n\n8. VEÍCULO UTILIZADO, SE HOUVER:\n\n9. TESTEMUNHAS / CÂMERAS:\n\n10. PROVIDÊNCIAS ADOTADAS:\n\n11. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(9, 'Tráfico de Entorpecentes', 'report', '1. DATA E HORA:\n\n2. LOCAL DA OCORRÊNCIA:\n\n3. ORIGEM DA INFORMAÇÃO / DENÚNCIA:\n\n4. SUSPEITO(S) ENVOLVIDO(S):\n\n5. DINÂMICA DA ABORDAGEM:\n\n6. MATERIAL APREENDIDO:\n- Tipo de substância:\n- Quantidade:\n- Forma de acondicionamento:\n\n7. VALORES / BALANÇAS / ANOTAÇÕES / APARELHOS:\n\n8. TESTEMUNHAS / APOIO DE OUTRAS EQUIPES:\n\n9. ENCAMINHAMENTO DOS ENVOLVIDOS:\n\n10. PROVIDÊNCIAS ADOTADAS:\n\n11. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(10, 'Apreensão de Entorpecentes', 'report', '1. DATA E HORA:\n\n2. LOCAL:\n\n3. ORIGEM DA APREENSÃO:\n- abordagem / denúncia / flagrante / busca / outra\n\n4. PESSOAS ENVOLVIDAS:\n\n5. TIPO(S) DE ENTORPECENTE(S):\n\n6. QUANTIDADE APREENDIDA:\n\n7. FORMA DE EMBALAGEM / ACONDICIONAMENTO:\n\n8. MATERIAIS CORRELATOS APREENDIDOS:\n\n9. DESTINAÇÃO DO MATERIAL:\n\n10. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(11, 'Porte Ilegal de Arma de Fogo', 'report', '1. DATA E HORA:\n\n2. LOCAL:\n\n3. ENVOLVIDO:\n\n4. CONTEXTO DA ABORDAGEM:\n\n5. ARMA APREENDIDA:\n- Tipo:\n- Marca:\n- Modelo:\n- Calibre:\n- Numeração:\n\n6. MUNIÇÕES APREENDIDAS:\n\n7. DOCUMENTAÇÃO APRESENTADA, SE HOUVER:\n\n8. PROVIDÊNCIAS ADOTADAS:\n\n9. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(12, 'Apreensão de Arma de Fogo', 'report', '1. DATA E HORA:\n\n2. LOCAL DA APREENSÃO:\n\n3. CIRCUNSTÂNCIA DA APREENSÃO:\n\n4. PESSOAS ENVOLVIDAS:\n\n5. DADOS DA ARMA:\n- Tipo:\n- Marca:\n- Modelo:\n- Calibre:\n- Numeração:\n\n6. QUANTIDADE DE MUNIÇÃO:\n\n7. OUTROS MATERIAIS RELACIONADOS:\n\n8. DESTINAÇÃO DO MATERIAL:\n\n9. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(13, 'Homicídio', 'report', '1. DATA E HORA DO ACIONAMENTO:\n\n2. LOCAL DO FATO:\n\n3. VÍTIMA:\n\n4. CONDIÇÃO DA VÍTIMA AO ENCONTRAR:\n\n5. POSSÍVEL DINÂMICA DOS FATOS:\n\n6. SUSPEITO(S), SE HOUVER:\n\n7. TESTEMUNHAS:\n\n8. EVIDÊNCIAS NO LOCAL:\n- cápsulas / arma / sangue / câmeras / objetos\n\n9. ISOLAMENTO E PRESERVAÇÃO DO LOCAL:\n\n10. APOIO ACIONADO:\n\n11. PROVIDÊNCIAS ADOTADAS:\n\n12. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(14, 'Tentativa de Homicídio', 'report', '1. DATA E HORA:\n\n2. LOCAL:\n\n3. VÍTIMA:\n\n4. LESÕES / ESTADO DA VÍTIMA:\n\n5. DINÂMICA NARRADA:\n\n6. SUSPEITO(S):\n\n7. ARMA / MEIO UTILIZADO:\n\n8. TESTEMUNHAS / CÂMERAS:\n\n9. ENCAMINHAMENTO MÉDICO, SE HOUVER:\n\n10. PROVIDÊNCIAS ADOTADAS:\n\n11. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(15, 'Lesão Corporal', 'report', '1. DATA E HORA:\n\n2. LOCAL:\n\n3. VÍTIMA:\n\n4. AUTOR / SUSPEITO:\n\n5. DESCRIÇÃO DA AGRESSÃO:\n\n6. LESÕES APARENTES:\n\n7. OBJETO / MEIO UTILIZADO:\n\n8. TESTEMUNHAS:\n\n9. ENCAMINHAMENTO MÉDICO / IML, SE HOUVER:\n\n10. PROVIDÊNCIAS ADOTADAS:\n\n11. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(16, 'Violência Doméstica', 'report', '1. DATA E HORA:\n\n2. LOCAL:\n\n3. VÍTIMA:\n\n4. AGRESSOR / SUSPEITO:\n\n5. RELAÇÃO ENTRE AS PARTES:\n\n6. DESCRIÇÃO DOS FATOS:\n\n7. HISTÓRICO DE AGRESSÕES, SE INFORMADO:\n\n8. LESÕES / DANOS / AMEAÇAS:\n\n9. MEDIDAS PROTETIVAS EXISTENTES, SE HOUVER:\n\n10. TESTEMUNHAS:\n\n11. PROVIDÊNCIAS ADOTADAS:\n\n12. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(17, 'Sequestro / Cárcere Privado', 'report', '1. DATA E HORA:\n\n2. LOCAL DA OCORRÊNCIA:\n\n3. VÍTIMA / REFÉM:\n\n4. SUSPEITO(S):\n\n5. DINÂMICA INICIAL:\n\n6. EXIGÊNCIAS APRESENTADAS, SE HOUVER:\n\n7. NEGOCIAÇÃO / APOIO EMPREGADO:\n\n8. ARMAS / VEÍCULOS ENVOLVIDOS:\n\n9. DESFECHO DA OCORRÊNCIA:\n\n10. PROVIDÊNCIAS ADOTADAS:\n\n11. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(18, 'Disparo de Arma de Fogo', 'report', '1. DATA E HORA:\n\n2. LOCAL:\n\n3. ORIGEM DA DENÚNCIA / ACIONAMENTO:\n\n4. SITUAÇÃO ENCONTRADA NO LOCAL:\n\n5. PESSOAS ENVOLVIDAS:\n\n6. SUSPEITO(S), SE HOUVER:\n\n7. CÁPSULAS / PROJÉTEIS / DANOS ENCONTRADOS:\n\n8. TESTEMUNHAS / CÂMERAS:\n\n9. PROVIDÊNCIAS ADOTADAS:\n\n10. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(19, 'Direção Perigosa', 'report', '1. DATA E HORA:\n\n2. LOCAL:\n\n3. VEÍCULO ENVOLVIDO:\n- placa:\n- modelo:\n- cor:\n\n4. CONDUTOR:\n\n5. CONDUTA OBSERVADA:\n\n6. RISCO GERADO / DANOS / VÍTIMAS:\n\n7. ACOMPANHAMENTO / CERCO, SE HOUVER:\n\n8. PROVIDÊNCIAS ADOTADAS:\n\n9. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(20, 'Ocorrência de Trânsito', 'report', '1. DATA E HORA:\n\n2. LOCAL DO SINISTRO:\n\n3. VEÍCULOS ENVOLVIDOS:\n\n4. CONDUTORES:\n\n5. PASSAGEIROS / VÍTIMAS:\n\n6. DINÂMICA APARENTE DO FATO:\n\n7. DANOS MATERIAIS:\n\n8. LESÕES / ATENDIMENTO MÉDICO:\n\n9. TESTE / SINAIS DE EMBRIAGUEZ, SE HOUVER:\n\n10. PROVIDÊNCIAS ADOTADAS:\n\n11. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(21, 'Veículo Recuperado', 'report', '1. DATA E HORA:\n\n2. LOCALIZAÇÃO DO VEÍCULO:\n\n3. DADOS DO VEÍCULO:\n- placa:\n- modelo:\n- cor:\n- chassi, se aplicável:\n\n4. SITUAÇÃO EM QUE FOI ENCONTRADO:\n\n5. VÍNCULO COM FURTO / ROUBO / CRIME, SE HOUVER:\n\n6. PROPRIETÁRIO / RESPONSÁVEL:\n\n7. CONDIÇÕES DO VEÍCULO:\n\n8. PROVIDÊNCIAS ADOTADAS:\n\n9. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(22, 'Veículo Abandonado', 'report', '1. DATA E HORA:\n\n2. LOCAL:\n\n3. DADOS DO VEÍCULO:\n\n4. TEMPO APARENTE DE ABANDONO:\n\n5. CONDIÇÕES DO VEÍCULO:\n\n6. CONSULTA DE SITUAÇÃO / PLACA:\n\n7. PROPRIETÁRIO, SE IDENTIFICADO:\n\n8. PROVIDÊNCIAS ADOTADAS:\n\n9. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(23, 'Apreensão de Veículo', 'report', '1. DATA E HORA:\n\n2. LOCAL:\n\n3. VEÍCULO:\n- placa:\n- modelo:\n- cor:\n\n4. MOTIVO DA APREENSÃO:\n\n5. CONDUTOR / RESPONSÁVEL:\n\n6. SITUAÇÃO DOCUMENTAL / CRIMINAL:\n\n7. BENS ENCONTRADOS NO INTERIOR, SE HOUVER:\n\n8. DESTINAÇÃO / PÁTIO:\n\n9. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(24, 'Desacato', 'report', '1. DATA E HORA:\n\n2. LOCAL:\n\n3. ENVOLVIDO:\n\n4. CONTEXTO DA ABORDAGEM / ATENDIMENTO:\n\n5. CONDUTA DESCRITA COMO DESACATO:\n\n6. TESTEMUNHAS / CÂMERAS:\n\n7. PROVIDÊNCIAS ADOTADAS:\n\n8. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(25, 'Desobediência', 'report', '1. DATA E HORA:\n\n2. LOCAL:\n\n3. ENVOLVIDO:\n\n4. ORDEM LEGAL EMANADA:\n\n5. FORMA COMO HOUVE A DESOBEDIÊNCIA:\n\n6. TESTEMUNHAS / EVIDÊNCIAS:\n\n7. PROVIDÊNCIAS ADOTADAS:\n\n8. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(26, 'Resistência à Prisão', 'report', '1. DATA E HORA:\n\n2. LOCAL:\n\n3. ENVOLVIDO:\n\n4. CONTEXTO DA PRISÃO / ABORDAGEM:\n\n5. FORMA DA RESISTÊNCIA:\n\n6. NECESSIDADE DE USO DE FORÇA / INSTRUMENTOS:\n\n7. LESÕES, SE HOUVER:\n\n8. TESTEMUNHAS / CÂMERAS:\n\n9. PROVIDÊNCIAS ADOTADAS:\n\n10. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(27, 'Auto de Prisão em Flagrante', 'report', '1. DATA E HORA:\n\n2. LOCAL:\n\n3. PRESO / CONDUZIDO:\n\n4. FATO GERADOR DO FLAGRANTE:\n\n5. DINÂMICA DA PRISÃO:\n\n6. OBJETOS / MATERIAIS APREENDIDOS:\n\n7. TESTEMUNHAS / VÍTIMAS:\n\n8. ENQUADRAMENTO INICIAL:\n\n9. PROVIDÊNCIAS ADOTADAS:\n\n10. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(28, 'Captura de Foragido', 'report', '1. DATA E HORA:\n\n2. LOCAL DA CAPTURA:\n\n3. FORAGIDO:\n\n4. ORIGEM DA INFORMAÇÃO / MANDADO:\n\n5. DINÂMICA DA CAPTURA:\n\n6. RESISTÊNCIA / FUGA / APOIO, SE HOUVER:\n\n7. MATERIAIS APREENDIDOS:\n\n8. PROVIDÊNCIAS ADOTADAS:\n\n9. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(29, 'Cumprimento de Mandado', 'report', '1. DATA E HORA:\n\n2. TIPO DE MANDADO:\n\n3. NÚMERO / REFERÊNCIA:\n\n4. ALVO / ENDEREÇO:\n\n5. EQUIPE RESPONSÁVEL:\n\n6. DINÂMICA DO CUMPRIMENTO:\n\n7. PESSOAS ENCONTRADAS:\n\n8. MATERIAIS APREENDIDOS:\n\n9. RESULTADO DA DILIGÊNCIA:\n\n10. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(30, 'Ocorrência com Refém', 'report', '1. DATA E HORA:\n\n2. LOCAL:\n\n3. REFÉM / VÍTIMA:\n\n4. SUSPEITO(S):\n\n5. DINÂMICA INICIAL:\n\n6. NEGOCIAÇÃO:\n\n7. APOIO TÁTICO / COMANDO:\n\n8. DESFECHO:\n\n9. PROVIDÊNCIAS ADOTADAS:\n\n10. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(31, 'Ocorrência em Área de Risco', 'report', '1. DATA E HORA:\n\n2. LOCAL / ÁREA:\n\n3. MOTIVO DA INTERVENÇÃO:\n\n4. EFETIVO EMPREGADO:\n\n5. SITUAÇÃO ENCONTRADA:\n\n6. SUSPEITOS / POPULARES ENVOLVIDOS:\n\n7. MATERIAIS APREENDIDOS:\n\n8. RESULTADO DA OPERAÇÃO:\n\n9. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(32, 'Receptação', 'report', '1. DATA E HORA:\n\n2. LOCAL:\n\n3. ENVOLVIDO:\n\n4. BEM LOCALIZADO / APREENDIDO:\n\n5. ORIGEM SUSPEITA DO BEM:\n\n6. CONSULTAS REALIZADAS:\n\n7. PROPRIETÁRIO / VÍTIMA ORIGINAL, SE IDENTIFICADO:\n\n8. PROVIDÊNCIAS ADOTADAS:\n\n9. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(33, 'Estelionato', 'report', '1. DATA E HORA DO FATO:\n\n2. LOCAL / MEIO UTILIZADO:\n\n3. VÍTIMA:\n\n4. AUTOR / SUSPEITO:\n\n5. DESCRIÇÃO DO GOLPE:\n\n6. VALORES / BENS ENVOLVIDOS:\n\n7. COMPROVANTES / MENSAGENS / TRANSFERÊNCIAS:\n\n8. PROVIDÊNCIAS ADOTADAS:\n\n9. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(34, 'Perturbação do Sossego', 'report', '1. DATA E HORA:\n\n2. LOCAL:\n\n3. ORIGEM DA DENÚNCIA:\n\n4. RESPONSÁVEL IDENTIFICADO:\n\n5. SITUAÇÃO ENCONTRADA:\n\n6. ORIENTAÇÕES / ADVERTÊNCIAS REALIZADAS:\n\n7. RESISTÊNCIA / REINCIDÊNCIA, SE HOUVER:\n\n8. PROVIDÊNCIAS ADOTADAS:\n\n9. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(35, 'Mandado de Prisão', 'warrant', '1. TIPO DE MANDADO:\n\n2. FUNDAMENTAÇÃO:\n\n3. ALVO:\n- Nome:\n- Documento / ID:\n- Endereço, se houver:\n\n4. FATOS RELACIONADOS:\n\n5. INDÍCIOS / ELEMENTOS DE CONVICÇÃO:\n\n6. RISCO OFERECIDO PELO ALVO:\n\n7. PEDIDO / REPRESENTAÇÃO:\n\n8. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(36, 'Mandado de Prisão Preventiva', 'warrant', '1. FUNDAMENTAÇÃO DA PREVENTIVA:\n\n2. ALVO:\n\n3. FATOS APURADOS:\n\n4. INDÍCIOS DE AUTORIA E MATERIALIDADE:\n\n5. RISCO À ORDEM PÚBLICA / INSTRUÇÃO / APLICAÇÃO DA LEI:\n\n6. PEDIDO:\n\n7. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(37, 'Mandado de Prisão Temporária', 'warrant', '1. FUNDAMENTAÇÃO DA TEMPORÁRIA:\n\n2. ALVO:\n\n3. FATOS INVESTIGADOS:\n\n4. NECESSIDADE DA MEDIDA:\n\n5. PRAZO PRETENDIDO:\n\n6. PEDIDO:\n\n7. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13'),
	(38, 'Mandado de Busca e Apreensão', 'warrant', '1. OBJETO DA BUSCA:\n\n2. ENDEREÇO / LOCAL A SER DILIGENCIADO:\n\n3. ALVO / RESPONSÁVEL:\n\n4. FUNDAMENTAÇÃO:\n\n5. MATERIAIS / OBJETOS PROCURADOS:\n\n6. INDÍCIOS EXISTENTES:\n\n7. PEDIDO:\n\n8. OBSERVAÇÕES:', 'leo', '2026-03-23 01:59:13', '2026-03-23 01:59:13');

-- Dumping structure for table republica.mdt_report_vehicles
CREATE TABLE IF NOT EXISTS `mdt_report_vehicles` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `reportid` int(10) unsigned NOT NULL,
  `plate` varchar(50) NOT NULL,
  `vehicle_label` varchar(100) DEFAULT NULL,
  `owner_name` varchar(100) DEFAULT NULL,
  `owner_citizenid` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `FK_mdt_report_vehicles_mdt_reports` (`reportid`),
  KEY `idx_report_vehicles_plate` (`plate`),
  CONSTRAINT `FK_mdt_report_vehicles_mdt_reports` FOREIGN KEY (`reportid`) REFERENCES `mdt_reports` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_report_vehicles: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_reports
CREATE TABLE IF NOT EXISTS `mdt_reports` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `author` varchar(50) DEFAULT NULL,
  `title` varchar(255) DEFAULT NULL,
  `type` varchar(50) DEFAULT NULL,
  `report_status` enum('draft','pending_review','approved','archived') NOT NULL DEFAULT 'draft',
  `requires_approval` tinyint(1) NOT NULL DEFAULT 1,
  `contentyjs` longblob DEFAULT NULL,
  `details` longtext DEFAULT NULL,
  `tags` text DEFAULT NULL,
  `officersinvolved` text DEFAULT NULL,
  `civsinvolved` text DEFAULT NULL,
  `gallery` text DEFAULT NULL,
  `time` varchar(20) DEFAULT NULL,
  `jobtype` varchar(25) DEFAULT 'police',
  `contentplaintext` text DEFAULT NULL,
  `authorplaintext` varchar(100) DEFAULT NULL,
  `signed_by` varchar(64) DEFAULT NULL,
  `signed_at` timestamp NULL DEFAULT NULL,
  `signature_hash` varchar(96) DEFAULT NULL,
  `approved_by` varchar(64) DEFAULT NULL,
  `approved_at` timestamp NULL DEFAULT NULL,
  `archived_by` varchar(64) DEFAULT NULL,
  `archived_at` timestamp NULL DEFAULT NULL,
  `unarchived_by` varchar(64) DEFAULT NULL,
  `unarchived_at` timestamp NULL DEFAULT NULL,
  `datecreated` timestamp NOT NULL DEFAULT current_timestamp(),
  `dateupdated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_mdt_reports_datecreated` (`datecreated`),
  KEY `idx_mdt_reports_dateupdated` (`dateupdated`),
  KEY `idx_mdt_reports_author` (`author`),
  KEY `idx_mdt_reports_status` (`report_status`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_reports: ~0 rows (approximately)
INSERT INTO `mdt_reports` (`id`, `author`, `title`, `type`, `report_status`, `requires_approval`, `contentyjs`, `details`, `tags`, `officersinvolved`, `civsinvolved`, `gallery`, `time`, `jobtype`, `contentplaintext`, `authorplaintext`, `signed_by`, `signed_at`, `signature_hash`, `approved_by`, `approved_at`, `archived_by`, `archived_at`, `unarchived_by`, `unarchived_at`, `datecreated`, `dateupdated`) VALUES
	(1, 'ZDQ8H6H9', 'Ocorrencia caixa registradora', 'Relatório de Prisão', 'draft', 1, _binary 0x223c703e466f69207265616c697a6164612061707265656ec3a7c3a36f20646f7320696c696369746f73202e2e2e2e2e2e2e3c2f703e22, NULL, NULL, NULL, NULL, NULL, NULL, 'police', '<p>Foi realizada apreenção dos ilicitos .......</p>', 'TiãO Dev', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-23 04:39:50', '2026-03-23 04:39:50'),
	(2, 'ZDQ8H6H9', 'madato teste', 'Relatório de Ocorrência', 'approved', 0, _binary 0x223c703e7465737465206d616e646164746f3c2f703e22, NULL, NULL, NULL, NULL, NULL, NULL, 'police', '<p>teste mandadto</p>', 'TiãO Dev', NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, '2026-03-25 14:55:12', '2026-03-25 14:55:12');

-- Dumping structure for table republica.mdt_reports_charges
CREATE TABLE IF NOT EXISTS `mdt_reports_charges` (
  `reportid` int(10) unsigned NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `charge` varchar(100) DEFAULT NULL,
  `count` int(10) unsigned NOT NULL DEFAULT 1,
  `time` int(10) unsigned DEFAULT NULL,
  `fine` int(10) unsigned DEFAULT NULL,
  KEY `idx_mdt_reports_charges_reportid` (`reportid`),
  KEY `idx_mdt_reports_charges_charge` (`charge`),
  KEY `idx_mdt_reports_charges_citizenid` (`citizenid`),
  CONSTRAINT `FK_mdt_reports_charges_mdt_reports` FOREIGN KEY (`reportid`) REFERENCES `mdt_reports` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_reports_charges: ~0 rows (approximately)
INSERT INTO `mdt_reports_charges` (`reportid`, `citizenid`, `charge`, `count`, `time`, `fine`) VALUES
	(1, 'PE9044F8', 'Adulteração de Sinal Identificador de Veículo', 1, 20, 3500),
	(1, 'PE9044F8', 'Disparo de Arma de Fogo', 1, 18, 3000);

-- Dumping structure for table republica.mdt_reports_evidence
CREATE TABLE IF NOT EXISTS `mdt_reports_evidence` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `reportid` int(10) unsigned NOT NULL,
  `type` varchar(50) NOT NULL,
  `content` varchar(255) NOT NULL,
  `note` text DEFAULT NULL,
  `stored` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `FK_mdt_reports_evidence_mdt_reports` (`reportid`),
  CONSTRAINT `FK_mdt_reports_evidence_mdt_reports` FOREIGN KEY (`reportid`) REFERENCES `mdt_reports` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_reports_evidence: ~0 rows (approximately)
INSERT INTO `mdt_reports_evidence` (`id`, `reportid`, `type`, `content`, `note`, `stored`) VALUES
	(1, 2, 'Digital', '01', '', 0);

-- Dumping structure for table republica.mdt_reports_involved
CREATE TABLE IF NOT EXISTS `mdt_reports_involved` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `reportid` int(10) unsigned NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `type` varchar(7) NOT NULL,
  `notes` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `FK_mdt_reports_involved_mdt_reports` (`reportid`),
  KEY `idx_involved_citizenid` (`citizenid`),
  KEY `idx_mdt_reports_involved_citizenid` (`citizenid`),
  CONSTRAINT `FK_mdt_reports_involved_mdt_reports` FOREIGN KEY (`reportid`) REFERENCES `mdt_reports` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_reports_involved: ~0 rows (approximately)
INSERT INTO `mdt_reports_involved` (`id`, `reportid`, `citizenid`, `type`, `notes`) VALUES
	(1, 1, 'ZDQ8H6H9', 'suspect', ''),
	(2, 1, 'E33O250L', 'victim', ''),
	(3, 1, 'ZDQ8H6H9', 'officer', ''),
	(4, 2, 'PE9044F8', 'suspect', ''),
	(5, 2, 'GBZ4I79C', 'victim', ''),
	(6, 2, 'ZDQ8H6H9', 'officer', '');

-- Dumping structure for table republica.mdt_reports_restrictions
CREATE TABLE IF NOT EXISTS `mdt_reports_restrictions` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `reportid` int(10) unsigned NOT NULL,
  `type` varchar(7) NOT NULL,
  `identifier` varchar(20) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `FK_mdt_reports_restrictions_mdt_reports` (`reportid`),
  KEY `idx_mdt_reports_restrictions_type_identifier` (`type`,`identifier`),
  CONSTRAINT `FK_mdt_reports_restrictions_mdt_reports` FOREIGN KEY (`reportid`) REFERENCES `mdt_reports` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_reports_restrictions: ~0 rows (approximately)
INSERT INTO `mdt_reports_restrictions` (`id`, `reportid`, `type`, `identifier`) VALUES
	(1, 1, 'jobtype', 'leo'),
	(2, 2, 'jobtype', 'leo');

-- Dumping structure for table republica.mdt_reports_tags
CREATE TABLE IF NOT EXISTS `mdt_reports_tags` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `reportid` int(10) unsigned NOT NULL,
  `tag` varchar(25) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `FK_mdt_reports_tags_mdt_reports` (`reportid`),
  KEY `idx_mdt_reports_tags_tag` (`tag`),
  CONSTRAINT `FK_mdt_reports_tags_mdt_reports` FOREIGN KEY (`reportid`) REFERENCES `mdt_reports` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_reports_tags: ~0 rows (approximately)
INSERT INTO `mdt_reports_tags` (`id`, `reportid`, `tag`) VALUES
	(1, 1, 'LEI MARIA DA PENHA'),
	(2, 2, 'ARMADO');

-- Dumping structure for table republica.mdt_reports_warrants
CREATE TABLE IF NOT EXISTS `mdt_reports_warrants` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `reportid` int(10) unsigned NOT NULL,
  `citizenid` varchar(50) NOT NULL DEFAULT '',
  `felonies` int(10) unsigned NOT NULL DEFAULT 0,
  `misdemeanors` int(10) unsigned NOT NULL DEFAULT 0,
  `infractions` int(10) unsigned NOT NULL DEFAULT 0,
  `expirydate` timestamp NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_warrant` (`reportid`,`citizenid`),
  KEY `FK_mdt_reports_warrants_mdt_reports` (`reportid`),
  KEY `FK_mdt_reports_warrants_mdt_profiles` (`citizenid`),
  KEY `idx_mdt_reports_warrants_citizen_expiry` (`citizenid`,`expirydate`),
  CONSTRAINT `FK_mdt_reports_warrants_mdt_profiles` FOREIGN KEY (`citizenid`) REFERENCES `mdt_profiles` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK_mdt_reports_warrants_mdt_reports` FOREIGN KEY (`reportid`) REFERENCES `mdt_reports` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_reports_warrants: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_settings
CREATE TABLE IF NOT EXISTS `mdt_settings` (
  `key` varchar(100) NOT NULL,
  `value` longtext DEFAULT NULL,
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_settings: ~1 rows (approximately)
INSERT INTO `mdt_settings` (`key`, `value`, `updated_at`) VALUES
	('jail_fines', '{"reductionOffers":[10,25,50],"maxFineAmount":100000}', '2026-03-22 04:23:00');

-- Dumping structure for table republica.mdt_tags
CREATE TABLE IF NOT EXISTS `mdt_tags` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(25) NOT NULL,
  `type` enum('officer','report','both') NOT NULL DEFAULT 'officer',
  `color` varchar(7) NOT NULL DEFAULT '#6b7280',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `job_type` enum('leo','ems','all') NOT NULL DEFAULT 'all',
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_tag_name` (`name`),
  KEY `idx_mdt_tags_job_type` (`job_type`),
  KEY `idx_mdt_tags_type_job_type` (`type`,`job_type`)
) ENGINE=InnoDB AUTO_INCREMENT=61 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_tags: ~39 rows (approximately)
INSERT INTO `mdt_tags` (`id`, `name`, `type`, `color`, `created_at`, `job_type`) VALUES
	(1, 'CHOQUE', 'officer', '#3b82f6', '2026-03-22 04:35:17', 'leo'),
	(2, 'INSTRUTOR', 'officer', '#10b981', '2026-03-22 04:35:17', 'leo'),
	(3, 'INVESTIGADOR', 'officer', '#8b5cf6', '2026-03-22 04:35:17', 'leo'),
	(4, 'EM ESTÁGIO', 'officer', '#f59e0b', '2026-03-22 04:35:17', 'leo'),
	(5, 'COMANDO', 'officer', '#ef4444', '2026-03-22 04:35:17', 'leo'),
	(6, 'CANIL', 'officer', '#06b6d4', '2026-03-22 04:35:17', 'leo'),
	(7, 'AÉREO', 'officer', '#ec4899', '2026-03-22 04:35:17', 'leo'),
	(8, 'ROUBO', 'report', '#ef4444', '2026-03-22 04:35:17', 'leo'),
	(9, 'ARMADO', 'report', '#f97316', '2026-03-22 04:35:17', 'leo'),
	(10, 'PRIORIDADE', 'report', '#f59e0b', '2026-03-22 04:35:17', 'leo'),
	(11, 'EM ANDAMENTO', 'report', '#10b981', '2026-03-22 04:35:17', 'leo'),
	(12, 'BALÍSTICA', 'report', '#8b5cf6', '2026-03-22 04:35:17', 'leo'),
	(13, 'FACÇÃO / ORG. CRIMINOSA', 'report', '#ec4899', '2026-03-22 04:35:17', 'leo'),
	(14, 'ENTORPECENTES', 'report', '#06b6d4', '2026-03-22 04:35:17', 'leo'),
	(15, 'TRÂNSITO', 'report', '#3b82f6', '2026-03-22 04:35:17', 'leo'),
	(16, 'VIOLÊNCIA DOMÉSTICA', 'report', '#6b7280', '2026-03-22 04:35:17', 'leo'),
	(17, 'AGRESSÃO', 'report', '#ef4444', '2026-03-22 04:35:17', 'leo'),
	(18, 'ALTA PRIORIDADE', 'report', '#f59e0b', '2026-03-22 04:35:17', 'leo'),
	(19, 'CONFIDENCIAL', 'report', '#8b5cf6', '2026-03-22 04:35:17', 'leo'),
	(20, 'INVESTIGAÇÃO EM ANDAMENTO', 'report', '#10b981', '2026-03-22 04:35:17', 'leo'),
	(61, 'ROTAM', 'officer', '#1d4ed8', '2026-03-23 01:52:19', 'leo'),
	(62, 'RÁDIO PATRULHA', 'officer', '#2563eb', '2026-03-23 01:52:19', 'leo'),
	(63, 'INTELIGÊNCIA', 'officer', '#7c3aed', '2026-03-23 01:52:19', 'leo'),
	(64, 'PATRULHAMENTO', 'officer', '#059669', '2026-03-23 01:52:19', 'leo'),
	(65, 'OFICIAL DE DIA', 'officer', '#dc2626', '2026-03-23 01:52:19', 'leo'),
	(67, 'FURTO', 'report', '#2563eb', '2026-03-23 01:52:19', 'leo'),
	(68, 'HOMICÍDIO', 'report', '#b91c1c', '2026-03-23 01:52:19', 'leo'),
	(69, 'TENTATIVA DE HOMICÍDIO', 'report', '#dc2626', '2026-03-23 01:52:19', 'leo'),
	(70, 'TRÁFICO DE DROGAS', 'report', '#0891b2', '2026-03-23 01:52:19', 'leo'),
	(71, 'LEI MARIA DA PENHA', 'report', '#db2777', '2026-03-23 01:52:19', 'leo'),
	(72, 'CUMPRIMENTO DE MANDADO', 'report', '#7c3aed', '2026-03-23 01:52:19', 'leo'),
	(73, 'APREENSÃO DE ARMA', 'report', '#ea580c', '2026-03-23 01:52:19', 'leo'),
	(74, 'RECEPTAÇÃO', 'report', '#475569', '2026-03-23 01:52:19', 'leo'),
	(75, 'DESACATO', 'report', '#f59e0b', '2026-03-23 01:52:19', 'leo'),
	(76, 'RESISTÊNCIA', 'report', '#d97706', '2026-03-23 01:52:19', 'leo'),
	(77, 'DIREÇÃO PERIGOSA', 'report', '#0284c7', '2026-03-23 01:52:19', 'leo'),
	(78, 'PERTURBAÇÃO DO SOSSEGO', 'report', '#6b7280', '2026-03-23 01:52:19', 'leo'),
	(79, 'SEQUESTRO / CÁRCERE', 'report', '#7f1d1d', '2026-03-23 01:52:19', 'leo'),
	(80, 'MANDADO DE PRISÃO', 'report', '#991b1b', '2026-03-23 01:52:19', 'leo');

-- Dumping structure for table republica.mdt_vehicleinfo
CREATE TABLE IF NOT EXISTS `mdt_vehicleinfo` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `plate` varchar(50) DEFAULT NULL,
  `information` text NOT NULL DEFAULT '',
  `stolen` tinyint(1) NOT NULL DEFAULT 0,
  `code5` tinyint(1) NOT NULL DEFAULT 0,
  `image` text NOT NULL DEFAULT '',
  `points` int(11) DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `idx_mdt_vehicleinfo_plate` (`plate`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_vehicleinfo: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_weapon_ownership_history
CREATE TABLE IF NOT EXISTS `mdt_weapon_ownership_history` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `serial` varchar(50) NOT NULL,
  `owner` varchar(50) DEFAULT NULL,
  `weapon_model` varchar(50) DEFAULT NULL,
  `weapon_class` varchar(50) DEFAULT NULL,
  `information` text DEFAULT NULL,
  `changed_by` varchar(50) DEFAULT NULL,
  `reason` varchar(100) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_mdt_weapon_history_serial` (`serial`),
  KEY `idx_mdt_weapon_history_owner` (`owner`),
  CONSTRAINT `FK_mdt_weapon_history_weapons` FOREIGN KEY (`serial`) REFERENCES `mdt_weapons` (`serial`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_weapon_ownership_history: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_weaponinfo
CREATE TABLE IF NOT EXISTS `mdt_weaponinfo` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `serial` varchar(50) DEFAULT NULL,
  `owner` varchar(50) DEFAULT NULL,
  `information` text NOT NULL DEFAULT '',
  `weapClass` varchar(50) DEFAULT NULL,
  `weapModel` varchar(50) DEFAULT NULL,
  `image` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `serial` (`serial`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_weaponinfo: ~0 rows (approximately)

-- Dumping structure for table republica.mdt_weapons
CREATE TABLE IF NOT EXISTS `mdt_weapons` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `serial` varchar(50) NOT NULL DEFAULT '',
  `scratched` tinyint(1) NOT NULL DEFAULT 0,
  `owner` varchar(50) DEFAULT NULL,
  `information` text DEFAULT NULL,
  `weaponClass` varchar(50) DEFAULT NULL,
  `weaponModel` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `unique_serial` (`serial`),
  KEY `FK_mdt_weapons_mdt_profiles` (`owner`),
  CONSTRAINT `FK_mdt_weapons_mdt_profiles` FOREIGN KEY (`owner`) REFERENCES `mdt_profiles` (`citizenid`) ON DELETE NO ACTION ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mdt_weapons: ~0 rows (approximately)

-- Dumping structure for table republica.mri_qblips
CREATE TABLE IF NOT EXISTS `mri_qblips` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `data` longtext NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `idx_mri_qblips_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=521 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.mri_qblips: ~40 rows (approximately)
INSERT INTO `mri_qblips` (`id`, `name`, `data`) VALUES
	(11, 'Loja de Pesca', '{"sRange":true,"alpha":255,"items":0,"Sprite":356,"hideb":false,"bflash":false,"colors":0,"scImg":"rgb(254, 254, 254)","ftimer":50000,"coords":{"x":-1492.945068359375,"y":-939.7318725585938,"z":10.205810546875},"outline":false,"scale":7,"SpriteImg":"https://docs.fivem.net/blips/radar_dock.png","tickb":false}'),
	(12, 'Loja de Pesca', '{"sRange":true,"alpha":255,"items":0,"Sprite":356,"hideb":false,"bflash":false,"colors":0,"scImg":"rgb(254, 254, 254)","ftimer":50000,"coords":{"x":-2081.393310546875,"y":2614.31201171875,"z":3.078369140625},"outline":false,"scale":7,"SpriteImg":"https://docs.fivem.net/blips/radar_dock.png","tickb":false}'),
	(51, 'Central de Trabalhos', '{"sRange":true,"alpha":255,"items":0,"Sprite":408,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":-261.0989074707031,"y":-971.8417358398438,"z":31.217529296875},"outline":false,"scale":7,"SpriteImg":"https://docs.fivem.net/blips/radar_capture_the_flag.png","tickb":false}'),
	(101, 'Loja de Conveniência', '{"sRange":true,"alpha":255,"items":0,"Sprite":52,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":25.70000076293945,"y":-1347.300048828125,"z":29.48999977111816},"outline":false,"scale":7,"SpriteImg":"https://docs.fivem.net/blips/radar_crim_holdups.png","tickb":false}'),
	(102, 'Loja de Conveniência', '{"sRange":true,"alpha":255,"items":0,"Sprite":52,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":-3038.7099609375,"y":585.9000244140625,"z":7.90000009536743},"outline":false,"scale":7,"SpriteImg":"https://docs.fivem.net/blips/radar_crim_holdups.png","tickb":false}'),
	(103, 'Loja de Conveniência', '{"sRange":true,"alpha":255,"items":0,"Sprite":52,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":-3241.469970703125,"y":1001.1400146484375,"z":12.82999992370605},"outline":false,"scale":7,"SpriteImg":"https://docs.fivem.net/blips/radar_crim_holdups.png","tickb":false}'),
	(104, 'Loja de Conveniência', '{"sRange":true,"alpha":255,"items":0,"Sprite":52,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":1728.6600341796876,"y":6414.16015625,"z":35.02999877929687},"outline":false,"scale":7,"SpriteImg":"https://docs.fivem.net/blips/radar_crim_holdups.png","tickb":false}'),
	(105, 'Loja de Conveniência', '{"sRange":true,"alpha":255,"items":0,"Sprite":52,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":1697.989990234375,"y":4924.39990234375,"z":42.06000137329101},"outline":false,"scale":7,"SpriteImg":"https://docs.fivem.net/blips/radar_crim_holdups.png","tickb":false}'),
	(106, 'Loja de Conveniência', '{"sRange":true,"alpha":255,"items":0,"Sprite":52,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":1961.47998046875,"y":3739.9599609375,"z":32.34000015258789},"outline":false,"scale":7,"SpriteImg":"https://docs.fivem.net/blips/radar_crim_holdups.png","tickb":false}'),
	(107, 'Loja de Conveniência', '{"sRange":true,"alpha":255,"items":0,"Sprite":52,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":547.7899780273438,"y":2671.7900390625,"z":42.1500015258789},"outline":false,"scale":7,"SpriteImg":"https://docs.fivem.net/blips/radar_crim_holdups.png","tickb":false}'),
	(108, 'Loja de Conveniência', '{"sRange":true,"alpha":255,"items":0,"Sprite":52,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":2679.25,"y":3280.1201171875,"z":55.2400016784668},"outline":false,"scale":7,"SpriteImg":"https://docs.fivem.net/blips/radar_crim_holdups.png","tickb":false}'),
	(109, 'Loja de Conveniência', '{"sRange":true,"alpha":255,"items":0,"Sprite":52,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":2557.93994140625,"y":382.04998779296877,"z":108.62000274658203},"outline":false,"scale":7,"SpriteImg":"https://docs.fivem.net/blips/radar_crim_holdups.png","tickb":false}'),
	(110, 'Loja de Conveniência', '{"sRange":true,"alpha":255,"items":0,"Sprite":52,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":373.54998779296877,"y":325.55999755859377,"z":103.55999755859375},"outline":false,"scale":7,"SpriteImg":"https://docs.fivem.net/blips/radar_crim_holdups.png","tickb":false}'),
	(201, 'Loja de Conveniência', '{"sRange":true,"alpha":255,"items":0,"Sprite":93,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":1135.8079833984376,"y":-982.281005859375,"z":46.41500091552734},"outline":false,"scale":7,"SpriteImg":"https://docs.fivem.net/blips/radar_bar.png","tickb":false}'),
	(202, 'Loja de Conveniência', '{"sRange":true,"alpha":255,"items":0,"Sprite":93,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":-1222.9150390625,"y":-906.9829711914063,"z":12.32600021362304},"outline":false,"scale":7,"SpriteImg":"https://docs.fivem.net/blips/radar_bar.png","tickb":false}'),
	(203, 'Loja de Conveniência', '{"sRange":true,"alpha":255,"items":0,"Sprite":93,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":-1487.552978515625,"y":-379.10699462890627,"z":40.16299819946289},"outline":false,"scale":7,"SpriteImg":"https://docs.fivem.net/blips/radar_bar.png","tickb":false}'),
	(204, 'Loja de Conveniência', '{"sRange":true,"alpha":255,"items":0,"Sprite":93,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":-2968.242919921875,"y":390.9100036621094,"z":15.04300022125244},"outline":false,"scale":7,"SpriteImg":"https://docs.fivem.net/blips/radar_bar.png","tickb":false}'),
	(205, 'Loja de Conveniência', '{"sRange":true,"alpha":255,"items":0,"Sprite":93,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":1166.0240478515626,"y":2708.929931640625,"z":38.15700149536133},"outline":false,"scale":7,"SpriteImg":"https://docs.fivem.net/blips/radar_bar.png","tickb":false}'),
	(206, 'Loja de Conveniência', '{"sRange":true,"alpha":255,"items":0,"Sprite":93,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":1392.56201171875,"y":3604.68408203125,"z":34.97999954223633},"outline":false,"scale":7,"SpriteImg":"https://docs.fivem.net/blips/radar_bar.png","tickb":false}'),
	(207, 'Loja de Conveniência', '{"sRange":true,"alpha":255,"items":0,"Sprite":93,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":-1393.4090576171876,"y":-606.6240234375,"z":30.31900024414062},"outline":false,"scale":7,"SpriteImg":"https://docs.fivem.net/blips/radar_bar.png","tickb":false}'),
	(300, 'Loja de Armas', '{"sRange":true,"alpha":255,"items":0,"Sprite":76,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":-662.1799926757813,"y":-934.9609985351563,"z":21.82900047302246},"outline":false,"scale":6,"SpriteImg":"https://docs.fivem.net/blips/radar_armenian_family.png","tickb":false}'),
	(301, 'Loja de Armas', '{"sRange":true,"alpha":255,"items":0,"Sprite":76,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":810.25,"y":-2157.60009765625,"z":29.6200008392334},"outline":false,"scale":6,"SpriteImg":"https://docs.fivem.net/blips/radar_armenian_family.png","tickb":false}'),
	(302, 'Loja de Armas', '{"sRange":true,"alpha":255,"items":0,"Sprite":76,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":1693.43994140625,"y":3760.159912109375,"z":34.70999908447265},"outline":false,"scale":6,"SpriteImg":"https://docs.fivem.net/blips/radar_armenian_family.png","tickb":false}'),
	(303, 'Loja de Armas', '{"sRange":true,"alpha":255,"items":0,"Sprite":76,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":-330.239990234375,"y":6083.8798828125,"z":31.45000076293945},"outline":false,"scale":6,"SpriteImg":"https://docs.fivem.net/blips/radar_armenian_family.png","tickb":false}'),
	(304, 'Loja de Armas', '{"sRange":true,"alpha":255,"items":0,"Sprite":76,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":252.6300048828125,"y":-50.0,"z":69.94000244140625},"outline":false,"scale":6,"SpriteImg":"https://docs.fivem.net/blips/radar_armenian_family.png","tickb":false}'),
	(305, 'Loja de Armas', '{"sRange":true,"alpha":255,"items":0,"Sprite":76,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":22.55999946594238,"y":-1109.8900146484376,"z":29.79999923706054},"outline":false,"scale":6,"SpriteImg":"https://docs.fivem.net/blips/radar_armenian_family.png","tickb":false}'),
	(306, 'Loja de Armas', '{"sRange":true,"alpha":255,"items":0,"Sprite":76,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":2567.68994140625,"y":294.3800048828125,"z":108.7300033569336},"outline":false,"scale":6,"SpriteImg":"https://docs.fivem.net/blips/radar_armenian_family.png","tickb":false}'),
	(307, 'Loja de Armas', '{"sRange":true,"alpha":255,"items":0,"Sprite":76,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":-1117.5799560546876,"y":2698.610107421875,"z":18.54999923706054},"outline":false,"scale":6,"SpriteImg":"https://docs.fivem.net/blips/radar_armenian_family.png","tickb":false}'),
	(308, 'Loja de Armas', '{"sRange":true,"alpha":255,"items":0,"Sprite":76,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":842.4400024414063,"y":-1033.4200439453126,"z":28.19000053405761},"outline":false,"scale":6,"SpriteImg":"https://docs.fivem.net/blips/radar_armenian_family.png","tickb":false}'),
	(406, 'Centro de Reciclagem', '{"sRange":true,"alpha":255,"items":0,"Sprite":467,"hideb":false,"bflash":false,"colors":0,"scImg":"rgb(113, 203, 113)","ftimer":50000,"sColor":2,"coords":{"x":745.2791137695313,"y":-1401.7318115234376,"z":26.5501708984375},"outline":false,"scale":7,"SpriteImg":"https://docs.fivem.net/blips/radar_pickup_swap.png","tickb":false}'),
	(407, 'Centro de Reciclagem', '{"sRange":false,"alpha":255,"items":0,"Sprite":0,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":59.76263809204101,"y":6474.85693359375,"z":31.4197998046875},"outline":false,"scale":1,"SpriteImg":"","tickb":false}'),
	(408, 'Centro de Reciclagem', '{"sRange":true,"alpha":255,"items":0,"Sprite":467,"hideb":false,"bflash":false,"colors":0,"scImg":"rgb(113, 203, 113)","ftimer":50000,"sColor":2,"coords":{"x":59.76263809204101,"y":6474.85693359375,"z":31.4197998046875},"outline":false,"scale":7,"SpriteImg":"https://docs.fivem.net/blips/radar_pickup_swap.png","tickb":false}'),
	(512, '31º  BATALHÃO DE POLICIA MILITAR', '{"sRange":true,"alpha":255,"items":0,"Sprite":60,"hideb":false,"bflash":false,"colors":0,"scImg":"rgb(93, 182, 229)","ftimer":50000,"sColor":3,"coords":{"x":-2081.103271484375,"y":-520.1670532226563,"z":12.025634765625},"outline":false,"scale":8,"SpriteImg":"https://docs.fivem.net/blips/radar_police_station.png","tickb":false}'),
	(513, '1º  BATALHÃO DE POLICIA MILITAR', '{"sRange":true,"alpha":255,"items":0,"Sprite":60,"hideb":false,"bflash":false,"colors":0,"scImg":"rgb(44, 109, 184)","ftimer":50000,"sColor":38,"coords":{"x":-793.2527465820313,"y":-2660.861572265625,"z":13.9970703125},"outline":false,"scale":8,"SpriteImg":"https://docs.fivem.net/blips/radar_police_station.png","tickb":false}'),
	(514, 'POLICIA CIVIL', '{"sRange":true,"alpha":255,"items":0,"Sprite":60,"hideb":false,"bflash":false,"colors":0,"scImg":"","ftimer":50000,"sColor":0,"coords":{"x":269.5912170410156,"y":-345.032958984375,"z":45.876953125},"outline":false,"scale":8,"SpriteImg":"https://docs.fivem.net/blips/radar_police_station.png","tickb":false}'),
	(515, 'CASSINO REPUBLICANO', '{"sRange":true,"alpha":255,"items":0,"Sprite":590,"hideb":false,"bflash":false,"colors":0,"scImg":"rgb(168, 84, 242)","ftimer":50000,"sColor":83,"coords":{"x":921.4549560546875,"y":48.30329895019531,"z":80.890869140625},"outline":false,"scale":8,"SpriteImg":"https://docs.fivem.net/blips/radar_nhp_base.png","tickb":false}'),
	(517, 'TRIBUNAL DE JUSTIÇA', '{"sRange":true,"alpha":255,"items":0,"Sprite":79,"hideb":false,"bflash":false,"colors":0,"scImg":"rgb(242, 164, 12)","ftimer":50000,"sColor":81,"coords":{"x":243.58682250976563,"y":-1077.112060546875,"z":29.2799072265625},"outline":false,"scale":8,"SpriteImg":"https://docs.fivem.net/blips/radar_trevor_family.png","tickb":false}'),
	(518, 'SECRETARIA DE SEGURANÇA', '{"sRange":true,"alpha":255,"items":0,"Sprite":229,"hideb":false,"bflash":false,"colors":0,"scImg":"rgb(44, 109, 184)","ftimer":50000,"sColor":38,"coords":{"x":1699.8857421875,"y":2601.032958984375,"z":49.4827880859375},"outline":false,"scale":8,"SpriteImg":"https://docs.fivem.net/blips/radar_guncar.png","tickb":false}'),
	(519, 'HOSPITAL CENTRAL', '{"sRange":true,"alpha":255,"items":0,"Sprite":80,"hideb":false,"bflash":false,"colors":0,"scImg":"rgb(12, 123, 86)","ftimer":50000,"sColor":25,"coords":{"x":-1862.5450439453126,"y":-356.05712890625,"z":49.22998046875},"outline":false,"scale":8,"SpriteImg":"https://docs.fivem.net/blips/radar_jewelry_heist.png","tickb":false}'),
	(520, 'BURGER LANCHERIA', '{"sRange":true,"alpha":255,"items":0,"Sprite":106,"hideb":false,"bflash":false,"colors":0,"scImg":"rgb(224, 58, 58)","ftimer":50000,"sColor":49,"coords":{"x":-831.4417724609375,"y":-797.4989013671875,"z":20.6358642578125},"outline":false,"scale":8,"SpriteImg":"https://docs.fivem.net/blips/radar_fbi_officers_strand.png","tickb":false}');

-- Dumping structure for table republica.mri_qelevators
CREATE TABLE IF NOT EXISTS `mri_qelevators` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `label` varchar(64) NOT NULL,
  `x` double NOT NULL,
  `y` double NOT NULL,
  `z` double NOT NULL,
  `size_x` double NOT NULL,
  `size_y` double NOT NULL,
  `size_z` double NOT NULL,
  `rot` double NOT NULL,
  `car` tinyint(1) NOT NULL,
  `job` varchar(64) DEFAULT NULL,
  `gang` varchar(64) DEFAULT NULL,
  `password` varchar(64) DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.mri_qelevators: ~0 rows (approximately)

-- Dumping structure for table republica.mri_qfarm
CREATE TABLE IF NOT EXISTS `mri_qfarm` (
  `farmId` bigint(20) NOT NULL AUTO_INCREMENT,
  `farmName` varchar(100) NOT NULL,
  `farmConfig` longtext DEFAULT NULL,
  `farmGroup` longtext DEFAULT NULL,
  PRIMARY KEY (`farmId`),
  UNIQUE KEY `farmName` (`farmName`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table republica.mri_qfarm: ~0 rows (approximately)

-- Dumping structure for table republica.mri_qjobsystem
CREATE TABLE IF NOT EXISTS `mri_qjobsystem` (
  `jobs` longtext DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table republica.mri_qjobsystem: ~1 rows (approximately)
INSERT INTO `mri_qjobsystem` (`jobs`) VALUES
	('[{"grades":{"5":{"isboss":false,"name":"TENENTE","payment":6000},"6":{"name":"CAPITÃO","payment":7000},"3":{"isboss":true,"payment":4000,"name":"1 SARGENTO","bankAuth":true},"4":{"name":"SUB-TENENTE","payment":5000},"1":{"name":"CABO","payment":2000},"2":{"name":"2 SARGENTO","payment":3000},"0":{"name":"SOLDADO","payment":1000},"9":{"isboss":true,"payment":10000,"name":"CORONEL ","bankAuth":true},"7":{"name":"MAJOR","payment":8000},"8":{"isboss":true,"isrecruiter":true,"name":"TENENTE-CORONEL","payment":9000}},"label":"POLICIA MILITAR","defaultDuty":false,"bossmenu":{"y":-2673.0458984375,"z":15.13656997680664,"x":-789.58203125},"duty":{"y":-2669.55712890625,"z":15.36584281921386,"x":-783.4561767578125},"alarm":{"y":-2656.68017578125,"z":15.42392349243164,"x":-779.521240234375},"stashes":[{"slots":50,"id":"police0_9123","job":true,"weight":500000,"coords":{"y":-972.8811645507813,"z":30.63170433044433,"x":452.0380554199219},"label":"Baú da Polícia"}],"job":"police","craftings":[{"items":[{"itemName":"WEAPON_PISTOL_MK2","itemCount":1,"ingedience":[{"itemName":"money","itemCount":0}]},{"itemName":"armour","itemCount":1,"ingedience":[{"itemName":"money","itemCount":0}]},{"itemName":"WEAPON_BZGAS","itemCount":1,"ingedience":[{"itemName":"money","itemCount":200}]},{"itemName":"handcuffkey","itemCount":1,"ingedience":[{"itemName":"money","itemCount":0}]},{"itemName":"cuffs","itemCount":1,"ingedience":[{"itemName":"money","itemCount":0}]},{"itemName":"WEAPON_NIGHTSTICK","itemCount":1,"ingedience":[{"itemName":"money","itemCount":0}]},{"itemName":"radio","itemCount":1,"ingedience":[{"itemName":"money","itemCount":0}]},{"itemName":"prop_barrier_large","itemCount":1,"ingedience":[{"itemName":"money","itemCount":1000}]},{"itemName":"WEAPON_STUNGUN","itemCount":1,"ingedience":[{"itemName":"money","itemCount":0}]},{"itemName":"ammo-9","itemCount":1,"ingedience":[{"itemName":"money","itemCount":0}]},{"itemName":"WEAPON_TACTICALRIFLE","itemCount":1,"ingedience":[{"itemName":"money","itemCount":1000}]},{"itemName":"ammo-rifle","itemCount":1,"ingedience":[{"itemName":"money","itemCount":1}]},{"itemName":"WEAPON_RADARGUN","itemCount":1,"ingedience":[{"itemName":"money","itemCount":1}]}],"id":"police0_2098","public":false,"coords":{"y":-2685.665283203125,"z":15.49295139312744,"x":-793.5639038085938},"icon":"fa-solid fa-cart-shopping","label":"EQUIPAMENTOS DE POLICIA"}],"type":"job","balance":2001,"coords":{"y":-979.2796020507813,"z":30.68960189819336,"x":447.1144104003906},"jobtype":"leo"},{"grades":{"1":{"name":"Médico","payment":200},"2":{"isboss":true,"payment":300,"name":"Diretor","bankAuth":true},"0":{"name":"Paramédico","payment":100}},"label":"HOSPITAL UPA","defaultDuty":false,"craftings":[],"duty":{"y":-338.0369567871094,"z":49.3585205078125,"x":-1852.2000732421876},"stashes":[],"job":"ambulance","type":"job","typejob":"","coords":{"y":-967.9647827148438,"z":29.46170234680175,"x":413.5118713378906},"jobtype":"ems"},{"grades":{"1":{"name":"Mecânico","payment":200},"2":{"isboss":true,"payment":300,"name":"Gerente","bankAuth":true},"0":{"name":"Aprendiz de Mecãnico","payment":100}},"label":"Los Customs","defaultDuty":true,"craftings":[],"stashes":[],"job":"mechanic","type":"job","jobtype":"mechanic","coords":{"y":-967.9647827148438,"z":29.46170234680175,"x":413.5118713378906},"typejob":""},{"grades":{"1":{"name":"Membro"},"2":{"isboss":true,"name":"Líder","bankAuth":true},"0":{"name":"Recruta"}},"label":"Ballas","craftings":[],"stashes":[],"job":"ballas","type":"gang","typejob":"","coords":{"y":-967.9647827148438,"z":29.46170234680175,"x":413.5118713378906},"jobtype":"mechanic"},{"grades":{"1":{"name":"Membro"},"2":{"isboss":true,"name":"Líder","bankAuth":true},"0":{"name":"Recruta"}},"label":"Vaggos","craftings":[],"stashes":[],"job":"vaggos","type":"gang","typejob":"","coords":{"y":-967.9647827148438,"z":29.46170234680175,"x":413.5118713378906},"jobtype":"mechanic"},{"grades":{"1":{"name":"Gerente","payment":200},"2":{"isboss":true,"payment":300,"name":"Dono","bankAuth":true},"0":{"isboss":true,"payment":100,"name":"Corretor de Imóveis","bankAuth":true}},"label":"Imobiliária","craftings":[],"stashes":[],"job":"realestate","type":"job","typejob":"","coords":{"y":-967.9647827148438,"z":29.46170234680175,"x":413.5118713378906},"jobtype":"realestate"},{"grades":{"5":{"name":"TENENTE","payment":11000},"6":{"name":"CAPITÃO","payment":12000},"3":{"name":"1º SARGENTO","payment":9000},"4":{"name":"SUB-TENENTE","payment":10000},"1":{"name":"CABO","payment":7000},"2":{"name":"3º SARGENTO","payment":8000},"0":{"name":"SOLDADO","payment":6000},"9":{"isboss":true,"payment":15000,"name":"CORONEL","bankAuth":true},"7":{"name":"MAJOR","payment":13000},"8":{"name":"TENENTE-CORONEL","payment":14000}},"label":"FORÇA TATICA PM","craftings":[{"items":[{"itemName":"WEAPON_BULLPUPRIFLE_MK2","ingedience":[{"itemCount":1000,"itemName":"money"}],"itemCount":1},{"itemName":"ammo-rifle","ingedience":[{"itemCount":1,"itemName":"money"}],"itemCount":1},{"itemName":"armour","ingedience":[{"itemCount":0,"itemName":"money"}],"itemCount":1},{"itemName":"WEAPON_STUNGUN","ingedience":[{"itemCount":0,"itemName":"money"}],"itemCount":1},{"itemName":"handcuffkey","ingedience":[{"itemCount":0,"itemName":"money"}],"itemCount":1},{"itemName":"cuffs","ingedience":[{"itemCount":0,"itemName":"money"}],"itemCount":1},{"itemName":"WEAPON_NIGHTSTICK","ingedience":[{"itemCount":0,"itemName":"money"}],"itemCount":1},{"itemName":"WEAPON_BZGAS","ingedience":[{"itemCount":0,"itemName":"money"}],"itemCount":1},{"itemName":"radio","ingedience":[{"itemCount":0,"itemName":"money"}],"itemCount":1}],"id":"ftpolicia0_237","public":false,"icon":"fa-solid fa-cart-shopping","coords":{"y":-527.6156005859375,"z":12.44128131866455,"x":-2105.14208984375},"label":"EQUIPAMENTOS DE POLICIA"}],"duty":{"y":-527.4768676757813,"z":11.75737857818603,"x":-2098.6826171875},"stashes":[],"job":"ftpolicia","type":"job","jobtype":"leo","coords":{"y":-518.6719970703125,"z":12.03853702545166,"x":-2079.480224609375},"typejob":""},{"grades":{"1":{"name":"ESCRIVÃO","payment":6000},"2":{"name":"DELEGADO","payment":15000},"3":{"isboss":true,"payment":7000,"name":"AGSECRETO","bankAuth":true},"0":{"name":"INVESTIGADOR","payment":5000}},"label":"Policia civil","defaultDuty":false,"bossmenu":{"y":-340.5530395507813,"z":49.24231338500976,"x":271.3388977050781},"duty":{"x":267.8782043457031,"y":-339.1048278808594,"z":45.81652069091797},"alarm":{"y":-347.1725769042969,"z":46.19526290893555,"x":275.787841796875},"job":"policiacivil","typejob":"","type":"job","craftings":[],"coords":{"y":-1320.1953125,"z":29.2496109008789,"x":105.14783477783205},"jobtype":"leo"}]');

-- Dumping structure for table republica.mri_qplaylist_songs
CREATE TABLE IF NOT EXISTS `mri_qplaylist_songs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `playlist` int(11) NOT NULL DEFAULT 0,
  `song` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `FK__mri_qplaylists` (`playlist`),
  KEY `FK__mri_qsongs` (`song`),
  CONSTRAINT `FK__mri_qplaylists` FOREIGN KEY (`playlist`) REFERENCES `mri_qplaylists` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `FK__mri_qsongs` FOREIGN KEY (`song`) REFERENCES `mri_qsongs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table republica.mri_qplaylist_songs: ~2 rows (approximately)
INSERT INTO `mri_qplaylist_songs` (`id`, `playlist`, `song`) VALUES
	(1, 1, 1),
	(2, 3, 2);

-- Dumping structure for table republica.mri_qplaylists
CREATE TABLE IF NOT EXISTS `mri_qplaylists` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL DEFAULT '0',
  `owner` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table republica.mri_qplaylists: ~3 rows (approximately)
INSERT INTO `mri_qplaylists` (`id`, `name`, `owner`) VALUES
	(1, 'MAKA', 'license:b3e08103e05d260def1c3fdb26ce015692dc57cf'),
	(2, 'Nova Playlist', 'license:6b4ee3d11fb38d49bef54f80e39e7e24eb9e1e32'),
	(3, 'https://www.youtube.com/watch?v=HupR7mehTog', 'license:6b4ee3d11fb38d49bef54f80e39e7e24eb9e1e32');

-- Dumping structure for table republica.mri_qplaylists_users
CREATE TABLE IF NOT EXISTS `mri_qplaylists_users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `license` varchar(255) NOT NULL DEFAULT '',
  `playlist` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `license` (`license`),
  KEY `FK__mri_qplaylists_users` (`playlist`),
  CONSTRAINT `FK__mri_qplaylists_users` FOREIGN KEY (`playlist`) REFERENCES `mri_qplaylists` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table republica.mri_qplaylists_users: ~3 rows (approximately)
INSERT INTO `mri_qplaylists_users` (`id`, `license`, `playlist`) VALUES
	(1, 'license:b3e08103e05d260def1c3fdb26ce015692dc57cf', 1),
	(2, 'license:6b4ee3d11fb38d49bef54f80e39e7e24eb9e1e32', 2),
	(3, 'license:6b4ee3d11fb38d49bef54f80e39e7e24eb9e1e32', 3);

-- Dumping structure for table republica.mri_qsongs
CREATE TABLE IF NOT EXISTS `mri_qsongs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `url` varchar(50) NOT NULL DEFAULT '0',
  `name` varchar(150) NOT NULL DEFAULT '0',
  `author` varchar(50) NOT NULL DEFAULT '0',
  `maxDuration` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `url` (`url`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table republica.mri_qsongs: ~2 rows (approximately)
INSERT INTO `mri_qsongs` (`id`, `url`, `name`, `author`, `maxDuration`) VALUES
	(1, 'HD2sMiAwpCQ', 'EU ME APAIXONEI - VITINHO IMPERADOR', 'Vitinho Imperador', 206),
	(2, 'HupR7mehTog', 'MC Livinho e MC Pedrinho - Se Prepara 2 (Studio Session) Perera DJ', 'Canal MC Livinho', 153);

-- Dumping structure for table republica.mri_qwhitelist
CREATE TABLE IF NOT EXISTS `mri_qwhitelist` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizen` varchar(50) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizen` (`citizen`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.mri_qwhitelist: ~9 rows (approximately)
INSERT INTO `mri_qwhitelist` (`id`, `citizen`) VALUES
	(1, 'ZDQ8H6H9'),
	(2, 'JTW7MEXP'),
	(3, 'RVA69WB5'),
	(4, 'VHB6JR43'),
	(6, 'PG4943A2'),
	(7, 'L112A611'),
	(8, 'C79HHN67'),
	(9, 'GBZ4I79C'),
	(10, 'E33O250L');

-- Dumping structure for table republica.mri_qwhitelistcfg
CREATE TABLE IF NOT EXISTS `mri_qwhitelistcfg` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `config` longtext NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.mri_qwhitelistcfg: ~1 rows (approximately)
INSERT INTO `mri_qwhitelistcfg` (`id`, `config`) VALUES
	(1, '{"Debug":false,"SuccessHeader":"Você passou no exame de cidadania!","Questions":[{"question":"O que é Meta Gaming?","options":[{"label":"Metagaming é o uso de qualquer informação que seu personagem não aprendeu dentro do roleplay na cidade.","value":true},{"label":"Metagaming é quando você tenta vender pés de galinha para as pessoas e você não tem nenhum pé de galinha.","value":false},{"label":"Eu não sei.","value":false},{"label":"Metagaming é quando você não teme pela sua vida.","value":false}]},{"question":"O que é Power Gaming?","options":[{"label":"Powergaming é o uso de formas de roleplay irreais ou a recusa total de fazer roleplay para se dar uma vantagem injusta.","value":true},{"label":"Powergaming é o uso do cartão de crédito da sua mãe para comprar Fundador Suporte ;)","value":false},{"label":"Powergaming é quando você invade o clube de alguém usando exploits.","value":false},{"label":"Eu não sei.","value":false}]},{"question":"Você pode usar software de trapaça de terceiros?","options":[{"label":"Isso não é permitido sob nenhuma circunstância.","value":true},{"label":"Sim, claro, eu adoro eulen!","value":false},{"label":"Somente se você pedir permissão para sua mãe.","value":false},{"label":"Eu não sei.","value":false}]},{"question":"Qual dos exemplos abaixo é uma Zona Verde?","options":[{"label":"Hospitais.","value":true},{"label":"Bancos de parque.","value":false},{"label":"Em todos os lugares.","value":false},{"label":"Todos os itens acima","value":false}]},{"question":"O que significa quebrar o personagem?","options":[{"label":"Quando você fala fora do personagem dentro da cidade.","value":true},{"label":"Quando você quebra o personagem de outro jogador.","value":false},{"label":"Quando seu tio não vem te buscar na escola.","value":false},{"label":"Eu não sei.","value":false}]},{"question":"Qual destes exemplos é da Regra de Morte Aleatória?","options":[{"label":"Você não pode atacar outro jogador aleatoriamente sem primeiro se envolver em algum tipo de RP verbal.","value":true},{"label":"Você pode matar outros jogadores sem motivo.","value":false},{"label":"Você não pode comprar água a menos que seja um apoiador do servidor.","value":false},{"label":"Eu não sei.","value":false}]}],"escapeNotify":"Você deve completar o exame de cidadania para jogar!","StartExamLabel":"Iniciar o exame de cidadania","StartExamHeader":"Exame de cidadania","SuccessContent":"Bem-vindo ao nosso servidor!","CompletionCoords":{"x":-1042.6800537109376,"y":-2745.969970703125,"z":21.36000061035156,"w":323.70001220703127},"PreExamQuestions":{"label":"Precisamos de algumas informações:","WebHook":"","Enabled":false,"FormatPhone":true,"information":[{"label":"Qual seu nome completo (Vida Real):","min":3,"placeholder":"Seu nome","required":true,"type":"input","max":100,"kind":"name"},{"label":"Qual o seu e-mail?","min":7,"placeholder":"seu@email.com","required":true,"type":"input","max":50,"kind":"email"},{"label":"Qual o seu WhatsApp?","type":"number","kind":"phone","required":true,"placeholder":"9999999999"}]},"ExamCoords":{"x":-68.23999786376953,"y":-814.4000244140625,"z":285.3500061035156},"Interaction":{"TargetRadius":{"x":4.0,"y":4.0,"z":4.0},"MarkerOnFloor":false,"MarkerLabel":"Comece o exame de cidadania","TargetLabel":"Comece o exame de cidadania","MarkerSize":{"x":1.0,"y":1.0,"z":1.0},"Type":"target","TargetDistance":2.0,"TargetIcon":"fas fa-passport","MarkerType":27,"MarkerColor":{"r":26,"b":179,"g":115}},"Percent":70,"NotifyType":"ox_lib","StartExamContent":"Todos os novos cidadãos devem passar no exame antes que possam jogar. Faça no seu tempo, responda com bom senso e não responda aleatoriamente.","loadNotify":"Você deve completar o exame de cidadania para jogar!","citizenZone":{"size":{"x":28.0,"y":22.20000076293945,"z":6.19999980926513},"coords":{"x":-73.33999633789063,"y":-821.1500244140625,"z":285.0},"rotation":340.0},"Enabled":true,"SpawnCoords":{"x":-66.23999786376953,"y":-822.0900268554688,"z":284.6099853515625,"w":78.80000305175781},"PassingScore":4,"FailedHeader":"Você falhou no exame de cidadania!","FailedContent":"Por favor, tente novamente."}');

-- Dumping structure for table republica.multijobs
CREATE TABLE IF NOT EXISTS `multijobs` (
  `citizenid` varchar(100) NOT NULL,
  `jobdata` text DEFAULT NULL,
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_uca1400_ai_ci;

-- Dumping data for table republica.multijobs: ~2 rows (approximately)
INSERT INTO `multijobs` (`citizenid`, `jobdata`) VALUES
	('JTW7MEXP', '{"police":9,"mechanic":2}'),
	('ZDQ8H6H9', '{"police":9,"ftpolicia":9}');

-- Dumping structure for table republica.npwd_calls
CREATE TABLE IF NOT EXISTS `npwd_calls` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(48) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `transmitter` varchar(255) NOT NULL,
  `receiver` varchar(255) NOT NULL,
  `is_accepted` tinyint(4) DEFAULT 0,
  `isAnonymous` tinyint(4) NOT NULL DEFAULT 0,
  `start` varchar(255) DEFAULT NULL,
  `end` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`),
  KEY `idx_npwd_calls_transmitter` (`transmitter`),
  KEY `idx_npwd_calls_receiver` (`receiver`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.npwd_calls: ~0 rows (approximately)

-- Dumping structure for table republica.npwd_darkchat_channel_members
CREATE TABLE IF NOT EXISTS `npwd_darkchat_channel_members` (
  `channel_id` int(11) NOT NULL,
  `user_identifier` varchar(255) NOT NULL,
  `is_owner` tinyint(4) NOT NULL DEFAULT 0,
  KEY `npwd_darkchat_channel_members_npwd_darkchat_channels_id_fk` (`channel_id`) USING BTREE,
  KEY `idx_npwd_dccm_user_identifier` (`user_identifier`),
  KEY `idx_npwd_dccm_channel_user` (`channel_id`,`user_identifier`),
  CONSTRAINT `npwd_darkchat_channel_members_npwd_darkchat_channels_id_fk` FOREIGN KEY (`channel_id`) REFERENCES `npwd_darkchat_channels` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table republica.npwd_darkchat_channel_members: ~0 rows (approximately)

-- Dumping structure for table republica.npwd_darkchat_channels
CREATE TABLE IF NOT EXISTS `npwd_darkchat_channels` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `channel_identifier` varchar(191) NOT NULL,
  `label` varchar(255) DEFAULT '',
  PRIMARY KEY (`id`) USING BTREE,
  UNIQUE KEY `darkchat_channels_channel_identifier_uindex` (`channel_identifier`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=20 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table republica.npwd_darkchat_channels: ~0 rows (approximately)

-- Dumping structure for table republica.npwd_darkchat_messages
CREATE TABLE IF NOT EXISTS `npwd_darkchat_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `channel_id` int(11) NOT NULL,
  `message` varchar(255) NOT NULL,
  `user_identifier` varchar(255) NOT NULL,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `is_image` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `darkchat_messages_darkchat_channels_id_fk` (`channel_id`) USING BTREE,
  KEY `idx_npwd_dcm_channel_createdAt` (`channel_id`,`createdAt`),
  KEY `idx_npwd_dcm_user_identifier` (`user_identifier`),
  CONSTRAINT `darkchat_messages_darkchat_channels_id_fk` FOREIGN KEY (`channel_id`) REFERENCES `npwd_darkchat_channels` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table republica.npwd_darkchat_messages: ~0 rows (approximately)

-- Dumping structure for table republica.npwd_marketplace_listings
CREATE TABLE IF NOT EXISTS `npwd_marketplace_listings` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(48) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `username` varchar(255) DEFAULT NULL,
  `name` varchar(50) DEFAULT NULL,
  `number` varchar(255) NOT NULL,
  `title` varchar(255) DEFAULT NULL,
  `url` varchar(255) DEFAULT NULL,
  `description` varchar(255) NOT NULL,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `reported` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`),
  KEY `idx_npwd_marketplace_number` (`number`),
  KEY `idx_npwd_marketplace_reported_createdAt` (`reported`,`createdAt`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.npwd_marketplace_listings: ~0 rows (approximately)

-- Dumping structure for table republica.npwd_match_profiles
CREATE TABLE IF NOT EXISTS `npwd_match_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(48) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `name` varchar(90) NOT NULL,
  `image` varchar(255) NOT NULL,
  `bio` varchar(512) DEFAULT NULL,
  `location` varchar(45) DEFAULT NULL,
  `job` varchar(45) DEFAULT NULL,
  `tags` varchar(255) NOT NULL DEFAULT '',
  `voiceMessage` varchar(512) DEFAULT NULL,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `identifier_UNIQUE` (`identifier`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.npwd_match_profiles: ~20 rows (approximately)
INSERT INTO `npwd_match_profiles` (`id`, `identifier`, `name`, `image`, `bio`, `location`, `job`, `tags`, `voiceMessage`, `createdAt`, `updatedAt`) VALUES
	(1, 'ZDQ8H6H9', 'TiO Dev', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg', '', '', '', '', NULL, '2026-03-16 06:05:19', '2026-03-16 06:05:19'),
	(2, 'JTW7MEXP', 'Maka Patron', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg', '', '', '', '', NULL, '2026-03-16 19:09:50', '2026-03-16 19:09:50'),
	(3, 'RVA69WB5', 'Makinha Popot', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg', '', '', '', '', NULL, '2026-03-16 20:14:08', '2026-03-16 20:14:08'),
	(4, 'VHB6JR43', 'Will Dgk', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg', '', '', '', '', NULL, '2026-03-18 22:37:39', '2026-03-18 22:37:39'),
	(5, 'PG4943A2', 'Will Dgk', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg', '', '', '', '', NULL, '2026-03-19 00:13:01', '2026-03-19 00:13:01'),
	(6, 'L112A611', 'Cavalcante Willian', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg', '', '', '', '', NULL, '2026-03-19 01:29:13', '2026-03-19 01:29:13'),
	(7, 'T9XU1HYK', 'Teste Teste', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg', '', '', '', '', NULL, '2026-03-19 12:21:10', '2026-03-19 12:21:10'),
	(8, 'OG40R0HG', 'Teste2 Teste2', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg', '', '', '', '', NULL, '2026-03-19 13:18:24', '2026-03-19 13:18:24'),
	(9, 'DPT8137G', 'Teste Ssss', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg', '', '', '', '', NULL, '2026-03-19 13:41:43', '2026-03-19 13:41:43'),
	(10, 'V292Y4ME', 'Teste Teste', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg', '', '', '', '', NULL, '2026-03-19 16:12:09', '2026-03-19 16:12:09'),
	(11, 'UU5H1P92', 'Tiao Teste', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg', '', '', '', '', NULL, '2026-03-19 16:41:00', '2026-03-19 16:41:00'),
	(12, 'YMZ956SW', 'Jana Morte', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg', '', '', '', '', NULL, '2026-03-19 17:03:29', '2026-03-19 17:03:29'),
	(13, 'C26NAK2R', 'Marina Rios', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg', '', '', '', '', NULL, '2026-03-19 17:50:30', '2026-03-19 17:50:30'),
	(14, 'QRCMIT0E', 'Tete Teste', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg', '', '', '', '', NULL, '2026-03-19 18:16:35', '2026-03-19 18:16:35'),
	(15, 'C79HHN67', 'Teste Testw', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg', '', '', '', '', NULL, '2026-03-19 18:34:43', '2026-03-19 18:34:43'),
	(16, 'M2R33T1T', 'Tiao EOPeDeFeijao', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg', '', '', '', '', NULL, '2026-03-19 19:41:36', '2026-03-19 19:41:36'),
	(17, 'GBZ4I79C', 'Cavalcante Willian', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg', '', '', '', '', NULL, '2026-03-19 23:06:49', '2026-03-19 23:06:49'),
	(18, 'E33O250L', 'Will Dgk', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg', '', '', '', '', NULL, '2026-03-19 23:35:20', '2026-03-19 23:35:20'),
	(19, 'M4865C4Y', 'Lobo Walker', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg', '', '', '', '', NULL, '2026-03-19 23:39:27', '2026-03-19 23:39:27'),
	(20, 'PE9044F8', 'Bruno Pitbull', 'https://upload.wikimedia.org/wikipedia/commons/a/ac/No_image_available.svg', '', '', '', '', NULL, '2026-03-20 00:46:15', '2026-03-20 00:46:15');

-- Dumping structure for table republica.npwd_match_views
CREATE TABLE IF NOT EXISTS `npwd_match_views` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(48) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `profile` int(11) NOT NULL,
  `liked` tinyint(4) DEFAULT 0,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `match_profile_idx` (`profile`),
  KEY `identifier` (`identifier`),
  KEY `idx_npwd_match_views_identifier_profile` (`identifier`,`profile`),
  CONSTRAINT `match_profile` FOREIGN KEY (`profile`) REFERENCES `npwd_match_profiles` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.npwd_match_views: ~0 rows (approximately)

-- Dumping structure for table republica.npwd_messages
CREATE TABLE IF NOT EXISTS `npwd_messages` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `message` varchar(512) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `user_identifier` varchar(48) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `conversation_id` varchar(512) NOT NULL,
  `isRead` tinyint(4) NOT NULL DEFAULT 0,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `visible` tinyint(4) NOT NULL DEFAULT 1,
  `author` varchar(255) NOT NULL,
  `is_embed` tinyint(4) NOT NULL DEFAULT 0,
  `embed` varchar(512) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `user_identifier` (`user_identifier`),
  KEY `idx_npwd_messages_conversation_id` (`conversation_id`),
  KEY `idx_npwd_messages_conversation_createdAt` (`conversation_id`,`createdAt`),
  KEY `idx_npwd_messages_user_isRead` (`user_identifier`,`isRead`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.npwd_messages: ~0 rows (approximately)

-- Dumping structure for table republica.npwd_messages_conversations
CREATE TABLE IF NOT EXISTS `npwd_messages_conversations` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `conversation_list` varchar(225) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `label` varchar(60) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '',
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `last_message_id` int(11) DEFAULT NULL,
  `is_group_chat` tinyint(4) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.npwd_messages_conversations: ~0 rows (approximately)

-- Dumping structure for table republica.npwd_messages_participants
CREATE TABLE IF NOT EXISTS `npwd_messages_participants` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `conversation_id` int(11) NOT NULL,
  `participant` varchar(225) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `unread_count` int(11) DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `message_participants_npwd_messages_conversations_id_fk` (`conversation_id`) USING BTREE,
  KEY `idx_npwd_msg_participant` (`participant`),
  KEY `idx_npwd_msg_conversation_participant` (`conversation_id`,`participant`),
  CONSTRAINT `message_participants_npwd_messages_conversations_id_fk` FOREIGN KEY (`conversation_id`) REFERENCES `npwd_messages_conversations` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.npwd_messages_participants: ~0 rows (approximately)

-- Dumping structure for table republica.npwd_notes
CREATE TABLE IF NOT EXISTS `npwd_notes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(48) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `title` varchar(255) NOT NULL,
  `content` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.npwd_notes: ~0 rows (approximately)

-- Dumping structure for table republica.npwd_phone_contacts
CREATE TABLE IF NOT EXISTS `npwd_phone_contacts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(48) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `avatar` varchar(255) DEFAULT NULL,
  `number` varchar(20) DEFAULT NULL,
  `display` varchar(255) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`),
  KEY `idx_npwd_phone_contacts_number` (`number`),
  KEY `idx_npwd_phone_contacts_identifier_number` (`identifier`,`number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.npwd_phone_contacts: ~0 rows (approximately)

-- Dumping structure for table republica.npwd_phone_gallery
CREATE TABLE IF NOT EXISTS `npwd_phone_gallery` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(48) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL,
  `image` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.npwd_phone_gallery: ~0 rows (approximately)

-- Dumping structure for table republica.npwd_twitter_likes
CREATE TABLE IF NOT EXISTS `npwd_twitter_likes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) NOT NULL,
  `tweet_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_combination` (`profile_id`,`tweet_id`),
  KEY `profile_idx` (`profile_id`),
  KEY `tweet_idx` (`tweet_id`),
  CONSTRAINT `profile` FOREIGN KEY (`profile_id`) REFERENCES `npwd_twitter_profiles` (`id`),
  CONSTRAINT `tweet` FOREIGN KEY (`tweet_id`) REFERENCES `npwd_twitter_tweets` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.npwd_twitter_likes: ~0 rows (approximately)

-- Dumping structure for table republica.npwd_twitter_profiles
CREATE TABLE IF NOT EXISTS `npwd_twitter_profiles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_name` varchar(90) NOT NULL,
  `identifier` varchar(48) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `avatar_url` varchar(255) DEFAULT 'https://i.fivemanage.com/images/3ClWwmpwkFhL.png',
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `profile_name_UNIQUE` (`profile_name`),
  KEY `identifier` (`identifier`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.npwd_twitter_profiles: ~16 rows (approximately)
INSERT INTO `npwd_twitter_profiles` (`id`, `profile_name`, `identifier`, `avatar_url`, `createdAt`, `updatedAt`) VALUES
	(1, 'TiO_Dev', 'ZDQ8H6H9', 'https://i.fivemanage.com/images/3ClWwmpwkFhL.png', '2026-03-16 06:05:19', '2026-03-16 06:05:19'),
	(2, 'Maka_Patron', 'JTW7MEXP', 'https://i.fivemanage.com/images/3ClWwmpwkFhL.png', '2026-03-16 19:09:50', '2026-03-16 19:09:50'),
	(3, 'Makinha_Popot', 'RVA69WB5', 'https://i.fivemanage.com/images/3ClWwmpwkFhL.png', '2026-03-16 20:14:08', '2026-03-16 20:14:08'),
	(4, 'Will_Dgk', 'VHB6JR43', 'https://i.fivemanage.com/images/3ClWwmpwkFhL.png', '2026-03-18 22:37:39', '2026-03-18 22:37:39'),
	(7, 'Cavalcante_Willian', 'L112A611', 'https://i.fivemanage.com/images/3ClWwmpwkFhL.png', '2026-03-19 01:29:13', '2026-03-19 01:29:13'),
	(8, 'Teste_Teste', 'T9XU1HYK', 'https://i.fivemanage.com/images/3ClWwmpwkFhL.png', '2026-03-19 12:21:10', '2026-03-19 12:21:10'),
	(9, 'Teste2_Teste2', 'OG40R0HG', 'https://i.fivemanage.com/images/3ClWwmpwkFhL.png', '2026-03-19 13:18:24', '2026-03-19 13:18:24'),
	(10, 'Teste_Ssss', 'DPT8137G', 'https://i.fivemanage.com/images/3ClWwmpwkFhL.png', '2026-03-19 13:41:43', '2026-03-19 13:41:43'),
	(12, 'Tiao_Teste', 'UU5H1P92', 'https://i.fivemanage.com/images/3ClWwmpwkFhL.png', '2026-03-19 16:40:59', '2026-03-19 16:40:59'),
	(13, 'Jana_Morte', 'YMZ956SW', 'https://i.fivemanage.com/images/3ClWwmpwkFhL.png', '2026-03-19 17:03:29', '2026-03-19 17:03:29'),
	(14, 'Marina_Rios', 'C26NAK2R', 'https://i.fivemanage.com/images/3ClWwmpwkFhL.png', '2026-03-19 17:50:30', '2026-03-19 17:50:30'),
	(15, 'Tete_Teste', 'QRCMIT0E', 'https://i.fivemanage.com/images/3ClWwmpwkFhL.png', '2026-03-19 18:16:35', '2026-03-19 18:16:35'),
	(16, 'Teste_Testw', 'C79HHN67', 'https://i.fivemanage.com/images/3ClWwmpwkFhL.png', '2026-03-19 18:34:43', '2026-03-19 18:34:43'),
	(17, 'Tiao_EOPeDeFeijao', 'M2R33T1T', 'https://i.fivemanage.com/images/3ClWwmpwkFhL.png', '2026-03-19 19:41:36', '2026-03-19 19:41:36'),
	(20, 'Lobo_Walker', 'M4865C4Y', 'https://i.fivemanage.com/images/3ClWwmpwkFhL.png', '2026-03-19 23:39:27', '2026-03-19 23:39:27'),
	(21, 'Bruno_Pitbull', 'PE9044F8', 'https://i.fivemanage.com/images/3ClWwmpwkFhL.png', '2026-03-20 00:46:15', '2026-03-20 00:46:15');

-- Dumping structure for table republica.npwd_twitter_reports
CREATE TABLE IF NOT EXISTS `npwd_twitter_reports` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `profile_id` int(11) NOT NULL,
  `tweet_id` int(11) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `unique_combination` (`profile_id`,`tweet_id`),
  KEY `profile_idx` (`profile_id`),
  KEY `tweet_idx` (`tweet_id`),
  CONSTRAINT `report_profile` FOREIGN KEY (`profile_id`) REFERENCES `npwd_twitter_profiles` (`id`),
  CONSTRAINT `report_tweet` FOREIGN KEY (`tweet_id`) REFERENCES `npwd_twitter_tweets` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.npwd_twitter_reports: ~0 rows (approximately)

-- Dumping structure for table republica.npwd_twitter_tweets
CREATE TABLE IF NOT EXISTS `npwd_twitter_tweets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `message` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `createdAt` timestamp NOT NULL DEFAULT current_timestamp(),
  `updatedAt` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `likes` int(11) NOT NULL DEFAULT 0,
  `identifier` varchar(48) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `visible` tinyint(4) NOT NULL DEFAULT 1,
  `images` varchar(1000) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT '',
  `retweet` int(11) DEFAULT NULL,
  `profile_id` int(11) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `npwd_twitter_tweets_npwd_twitter_profiles_id_fk` (`profile_id`) USING BTREE,
  KEY `idx_npwd_twitter_tweets_identifier_createdAt` (`identifier`,`createdAt`),
  KEY `idx_npwd_twitter_tweets_visible_createdAt` (`visible`,`createdAt`),
  CONSTRAINT `npwd_twitter_tweets_npwd_twitter_profiles_id_fk` FOREIGN KEY (`profile_id`) REFERENCES `npwd_twitter_profiles` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.npwd_twitter_tweets: ~0 rows (approximately)

-- Dumping structure for table republica.occasion_vehicles
CREATE TABLE IF NOT EXISTS `occasion_vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `seller` varchar(50) DEFAULT NULL,
  `price` int(11) DEFAULT NULL,
  `description` longtext DEFAULT NULL,
  `plate` varchar(50) DEFAULT NULL,
  `model` varchar(50) DEFAULT NULL,
  `mods` text DEFAULT NULL,
  `occasionid` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `occasionId` (`occasionid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.occasion_vehicles: ~0 rows (approximately)

-- Dumping structure for table republica.officer_data
CREATE TABLE IF NOT EXISTS `officer_data` (
  `citizenid` varchar(50) NOT NULL,
  `callsign` varchar(50) DEFAULT 'NO CALLSIGN',
  `badge` varchar(50) DEFAULT '',
  `custom_image` varchar(255) DEFAULT NULL,
  `category` varchar(50) DEFAULT 'main',
  `channel` varchar(10) DEFAULT '1B',
  PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Dumping data for table republica.officer_data: ~4 rows (approximately)
INSERT INTO `officer_data` (`citizenid`, `callsign`, `badge`, `custom_image`, `category`, `channel`) VALUES
	('E33O250L', 'SEM CALLSIGN', '0', NULL, 'main', '1B'),
	('JTW7MEXP', 'SEM CALLSIGN', '9', NULL, 'main', '1B'),
	('PG4943A2', 'SEM CALLSIGN', '9', NULL, 'main', '1B'),
	('ZDQ8H6H9', 'SEM CALLSIGN', '9', NULL, 'main', '1B');

-- Dumping structure for table republica.officer_data_colors
CREATE TABLE IF NOT EXISTS `officer_data_colors` (
  `setting_name` varchar(50) NOT NULL,
  `setting_value` text DEFAULT NULL,
  PRIMARY KEY (`setting_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Dumping data for table republica.officer_data_colors: ~1 rows (approximately)
INSERT INTO `officer_data_colors` (`setting_name`, `setting_value`) VALUES
	('callsignColors', '[{"min":100,"max":199,"color":"#3498db","name":"Patrulha"},{"min":200,"max":299,"color":"#2ecc71","name":"Trânsito"},{"min":300,"max":399,"color":"#e67e22","name":"Investigação"},{"min":400,"max":499,"color":"#9b59b6","name":"Comando"}]');

-- Dumping structure for table republica.ox_doorlock
CREATE TABLE IF NOT EXISTS `ox_doorlock` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  `data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ox_doorlock_name` (`name`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.ox_doorlock: ~3 rows (approximately)
INSERT INTO `ox_doorlock` (`id`, `name`, `data`) VALUES
	(1, 'vangelico_jewellery', '{"maxDistance":2,"groups":{"police":0},"doors":[{"model":1425919976,"coords":{"x":-631.9553833007813,"y":-236.33326721191407,"z":38.2065315246582},"heading":306},{"model":9467943,"coords":{"x":-630.426513671875,"y":-238.4375457763672,"z":38.2065315246582},"heading":306}],"state":1,"coords":{"x":-631.19091796875,"y":-237.38540649414063,"z":38.2065315246582},"hideUi":true}'),
	(2, 'POLICIA MILITAR 1', '{"autolock":5,"groups":{"police":0},"doors":false,"coords":{"x":-785.967041015625,"y":-2663.494140625,"z":15.36558151245117},"maxDistance":5,"state":1,"model":-1821777087,"heading":60}'),
	(3, 'FORÇA TATICA 1 ARMARIA', '{"autolock":5,"state":1,"model":-1320503032,"heading":320,"maxDistance":5,"coords":{"x":-2098.79443359375,"y":-525.4556884765625,"z":11.94086170196533},"doors":false,"groups":{"ftpolicia":0}}');

-- Dumping structure for table republica.ox_inventory
CREATE TABLE IF NOT EXISTS `ox_inventory` (
  `owner` varchar(60) DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `data` longtext DEFAULT NULL,
  `lastupdated` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  UNIQUE KEY `owner` (`owner`,`name`),
  KEY `idx_ox_inventory_name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.ox_inventory: ~2 rows (approximately)
INSERT INTO `ox_inventory` (`owner`, `name`, `data`, `lastupdated`) VALUES
	('', 'vrs_mechanic_mecanica_central', '[{"name":"money","slot":1,"count":29}]', '2026-03-18 17:50:00'),
	('', 'vrs_mechanic_mecanica_praia', '[{"name":"nitrous_tank","count":1,"slot":1},{"name":"mechanic_tablet","count":1,"slot":2},{"name":"plastic","count":1,"slot":3},{"name":"plastic","count":2,"slot":4},{"name":"repairkit_advanced","count":1,"slot":5},{"name":"suspension_parts","count":1,"slot":6},{"name":"cleaning_kit","count":3,"slot":7},{"name":"engine_parts","count":1,"slot":8},{"name":"spare_tyre","count":1,"slot":9},{"name":"scrap_metal","count":1,"slot":10},{"name":"radiator_parts","count":2,"slot":11},{"name":"engine_upgrade_v8","count":1,"slot":12},{"name":"turbo_kit","count":1,"slot":13},{"name":"ecu_stage_2","count":1,"slot":14},{"name":"coolant","count":2,"slot":15},{"name":"mechanic_toolbox","count":1,"slot":16}]', '2026-03-22 02:25:00');

-- Dumping structure for table republica.pickle_prisons
CREATE TABLE IF NOT EXISTS `pickle_prisons` (
  `identifier` varchar(46) NOT NULL,
  `prison` varchar(50) DEFAULT 'default',
  `time` int(11) NOT NULL DEFAULT 0,
  `inventory` longtext NOT NULL,
  `sentence_date` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci;

-- Dumping data for table republica.pickle_prisons: ~0 rows (approximately)

-- Dumping structure for table republica.player_groups
CREATE TABLE IF NOT EXISTS `player_groups` (
  `citizenid` varchar(50) NOT NULL,
  `group` varchar(50) NOT NULL,
  `type` varchar(50) NOT NULL,
  `grade` tinyint(3) unsigned NOT NULL,
  PRIMARY KEY (`citizenid`,`type`,`group`),
  CONSTRAINT `fk_citizenid` FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.player_groups: ~2 rows (approximately)
INSERT INTO `player_groups` (`citizenid`, `group`, `type`, `grade`) VALUES
	('JTW7MEXP', 'police', 'job', 9),
	('ZDQ8H6H9', 'police', 'job', 9);

-- Dumping structure for table republica.player_houses
CREATE TABLE IF NOT EXISTS `player_houses` (
  `id` int(255) NOT NULL AUTO_INCREMENT,
  `house` varchar(50) NOT NULL,
  `identifier` varchar(50) DEFAULT NULL,
  `citizenid` varchar(50) DEFAULT NULL,
  `keyholders` text DEFAULT NULL,
  `decorations` text DEFAULT NULL,
  `stash` text DEFAULT NULL,
  `outfit` text DEFAULT NULL,
  `logout` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `house` (`house`),
  KEY `citizenid` (`citizenid`),
  KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.player_houses: ~0 rows (approximately)

-- Dumping structure for table republica.player_jobs_activity
CREATE TABLE IF NOT EXISTS `player_jobs_activity` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `job` varchar(255) NOT NULL,
  `last_checkin` int(11) NOT NULL,
  `last_checkout` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `id` (`id` DESC) USING BTREE,
  KEY `last_checkout` (`last_checkout`) USING BTREE,
  KEY `citizenid_job` (`citizenid`,`job`) USING BTREE,
  CONSTRAINT `1` FOREIGN KEY (`citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=29 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table republica.player_jobs_activity: ~25 rows (approximately)
INSERT INTO `player_jobs_activity` (`id`, `citizenid`, `job`, `last_checkin`, `last_checkout`) VALUES
	(1, 'ZDQ8H6H9', 'unemployed', 1773668555, 1773670443),
	(2, 'ZDQ8H6H9', 'unemployed', 1773674250, 1773676171),
	(3, 'ZDQ8H6H9', 'unemployed', 1773686619, 1773689660),
	(4, 'ZDQ8H6H9', 'mechanic', 1773692682, 1773694953),
	(5, 'JTW7MEXP', 'police', 1773754831, 1773756929),
	(6, 'JTW7MEXP', 'police', 1773782891, 1773784965),
	(7, 'ZDQ8H6H9', 'mechanic', 1773794920, 1773798148),
	(8, 'ZDQ8H6H9', 'mechanic', 1773869792, 1773872434),
	(11, 'ZDQ8H6H9', 'mechanic', 1773964131, 1773967593),
	(12, 'ZDQ8H6H9', 'mechanic', 1773967754, 1773970000),
	(13, 'GBZ4I79C', 'unemployed', 1773962184, 1773970254),
	(14, 'E33O250L', 'unemployed', 1773967754, 1773972867),
	(15, 'GBZ4I79C', 'unemployed', 1773970427, 1773975300),
	(16, 'ZDQ8H6H9', 'mechanic', 1773981724, 1773983868),
	(17, 'ZDQ8H6H9', 'mechanic', 1774012946, 1774015585),
	(18, 'ZDQ8H6H9', 'mechanic', 1774029165, 1774032567),
	(19, 'ZDQ8H6H9', 'mechanic', 1774039068, 1774041146),
	(20, 'ZDQ8H6H9', 'mechanic', 1774043155, 1774047033),
	(21, 'JTW7MEXP', 'ftpolicia', 1774049568, 1774053845),
	(22, 'ZDQ8H6H9', 'mechanic', 1774088793, 1774091972),
	(23, 'ZDQ8H6H9', 'mechanic', 1774093861, 1774101882),
	(24, 'ZDQ8H6H9', 'mechanic', 1774141802, 1774146640),
	(25, 'ZDQ8H6H9', 'mechanic', 1774147093, 1774152409),
	(26, 'ZDQ8H6H9', 'police', 1774196966, 1774198905),
	(27, 'ZDQ8H6H9', 'police', 1774220522, 1774224451),
	(28, 'ZDQ8H6H9', 'police', 1774283197, 1774285305);

-- Dumping structure for table republica.player_mails
CREATE TABLE IF NOT EXISTS `player_mails` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `sender` varchar(50) DEFAULT NULL,
  `subject` varchar(50) DEFAULT NULL,
  `message` text DEFAULT NULL,
  `read` tinyint(4) DEFAULT 0,
  `mailid` int(11) DEFAULT NULL,
  `date` timestamp NULL DEFAULT current_timestamp(),
  `button` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`),
  KEY `idx_player_mails_citizenid_read` (`citizenid`,`read`),
  KEY `idx_player_mails_date` (`date`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.player_mails: ~1 rows (approximately)
INSERT INTO `player_mails` (`id`, `citizenid`, `sender`, `subject`, `message`, `read`, `mailid`, `date`, `button`) VALUES
	(1, 'JTW7MEXP', 'O chefe', 'Nova entrega de combustível', 'Estou enviando o local para o seu GPS em seu caminhão.Entregue o combustível ao cliente a tempo!', 0, 892318, '2026-03-21 00:08:16', NULL);

-- Dumping structure for table republica.player_outfit_codes
CREATE TABLE IF NOT EXISTS `player_outfit_codes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `outfitid` int(11) NOT NULL,
  `code` varchar(50) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `FK_player_outfit_codes_player_outfits` (`outfitid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table republica.player_outfit_codes: ~0 rows (approximately)

-- Dumping structure for table republica.player_outfits
CREATE TABLE IF NOT EXISTS `player_outfits` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(50) DEFAULT NULL,
  `outfitname` varchar(50) NOT NULL DEFAULT '0',
  `model` varchar(50) DEFAULT NULL,
  `props` text DEFAULT NULL,
  `components` text DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `citizenid_outfitname_model` (`citizenid`,`outfitname`,`model`),
  KEY `citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Dumping data for table republica.player_outfits: ~0 rows (approximately)

-- Dumping structure for table republica.player_transactions
CREATE TABLE IF NOT EXISTS `player_transactions` (
  `id` varchar(50) NOT NULL,
  `isFrozen` int(11) DEFAULT 0,
  `transactions` longtext DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.player_transactions: ~0 rows (approximately)

-- Dumping structure for table republica.player_vehicles
CREATE TABLE IF NOT EXISTS `player_vehicles` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `license` varchar(50) DEFAULT NULL,
  `citizenid` varchar(50) DEFAULT NULL,
  `vehicle` varchar(50) DEFAULT NULL,
  `vehicle_name` longtext DEFAULT NULL,
  `hash` varchar(50) DEFAULT NULL,
  `mods` longtext DEFAULT NULL,
  `plate` varchar(50) NOT NULL,
  `fakeplate` varchar(50) DEFAULT NULL,
  `garage` varchar(50) DEFAULT NULL,
  `deformation` longtext DEFAULT NULL,
  `fuel` int(11) DEFAULT 100,
  `engine` float DEFAULT 1000,
  `body` float DEFAULT 1000,
  `state` int(11) DEFAULT 1,
  `depotprice` int(11) NOT NULL DEFAULT 0,
  `drivingdistance` int(50) DEFAULT NULL,
  `status` text DEFAULT NULL,
  `paymentsleft` int(11) NOT NULL DEFAULT 0,
  `balance` int(11) NOT NULL DEFAULT 0,
  `glovebox` longtext DEFAULT NULL,
  `trunk` longtext DEFAULT NULL,
  `paymentamount` int(11) NOT NULL DEFAULT 0,
  `financetime` int(11) NOT NULL DEFAULT 0,
  `mileage` float NOT NULL DEFAULT 0,
  `mdt_vehicle_information` text DEFAULT NULL,
  `mdt_vehicle_points` int(11) NOT NULL DEFAULT 0,
  `mdt_vehicle_status` enum('valid','suspended','expired','impounded') NOT NULL DEFAULT 'valid',
  `mdt_vehicle_stolen` tinyint(1) NOT NULL DEFAULT 0,
  `mdt_vehicle_boloactive` tinyint(1) NOT NULL DEFAULT 0,
  `mdt_vehicle_image` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `plate` (`plate`),
  KEY `citizenid` (`citizenid`),
  KEY `license` (`license`),
  KEY `idx_player_vehicles_state` (`state`),
  KEY `idx_player_vehicles_garage` (`garage`),
  KEY `idx_player_vehicles_fakeplate` (`fakeplate`),
  KEY `idx_player_vehicles_citizenid_state` (`citizenid`,`state`),
  KEY `idx_player_vehicles_garage_state` (`garage`,`state`),
  KEY `idx_player_vehicles_citizenid_plate` (`citizenid`,`plate`),
  KEY `idx_player_vehicles_plate` (`plate`)
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.player_vehicles: ~7 rows (approximately)
INSERT INTO `player_vehicles` (`id`, `license`, `citizenid`, `vehicle`, `vehicle_name`, `hash`, `mods`, `plate`, `fakeplate`, `garage`, `deformation`, `fuel`, `engine`, `body`, `state`, `depotprice`, `drivingdistance`, `status`, `paymentsleft`, `balance`, `glovebox`, `trunk`, `paymentamount`, `financetime`, `mileage`, `mdt_vehicle_information`, `mdt_vehicle_points`, `mdt_vehicle_status`, `mdt_vehicle_stolen`, `mdt_vehicle_boloactive`, `mdt_vehicle_image`) VALUES
	(8, 'license2:72b6567475f8452256ac755095e78e87298998a3', 'ZDQ8H6H9', 'osiris', NULL, '1987142870', '{"modLightbar":-1,"modSteeringWheel":-1,"plateIndex":0,"xenonColor":255,"modDial":-1,"tyres":[],"modGrille":-1,"modBrakes":-1,"windows":[4,5,6],"modTrunk":-1,"modHorns":-1,"modSubwoofer":-1,"modHydraulics":false,"modSpoilers":-1,"bulletProofTyres":true,"modWindows":-1,"plate":"03ADA655","pearlescentColor":3,"modStruts":-1,"wheelSize":0.0,"livery":-1,"oilLevel":5,"modRoofLivery":-1,"modFrontWheels":-1,"paintType2":0,"modDoorSpeaker":-1,"doors":[],"modBackWheels":-1,"dirtLevel":4,"modCustomTiresR":false,"modArmor":-1,"color2":1,"modOrnaments":-1,"modSideSkirt":-1,"modExhaust":-1,"bodyHealth":780,"modEngine":-1,"modHydrolic":-1,"neonColor":[255,0,255],"modFrame":-1,"modFender":-1,"dashboardColor":0,"modFrontBumper":-1,"modTransmission":-1,"modSeats":-1,"modSpeakers":-1,"driftTyres":false,"paintType1":0,"modTank":-1,"modVanityPlate":-1,"modSuspension":-1,"wheels":7,"windowTint":-1,"modCustomTiresF":false,"neonEnabled":[false,false,false,false],"modDashboard":-1,"modShifterLeavers":-1,"extras":[],"modAPlate":-1,"modHood":-1,"fuelLevel":87,"tyreSmokeColor":[255,255,255],"modRoof":-1,"modDoorR":-1,"modArchCover":-1,"modRearBumper":-1,"modNitrous":-1,"tankHealth":959,"modRightFender":-1,"modEngineBlock":-1,"wheelColor":0,"wheelWidth":0.0,"modXenon":false,"modAerials":-1,"engineHealth":609,"modPlateHolder":-1,"interiorColor":0,"modTrimA":-1,"modTrimB":-1,"modSmokeEnabled":false,"modLivery":-1,"model":1987142870,"modTurbo":false,"modAirFilter":-1,"color1":99}', '03ADA655', NULL, 'Pillbox Garage Parking', '[{"damage":0.126,"offset":{"x":-1.04999995231628,"y":2.29999995231628,"z":0.0}},{"damage":0.068,"offset":{"x":-1.04999995231628,"y":2.29999995231628,"z":0.61000001430511}},{"damage":0.079,"offset":{"x":0.0,"y":2.29999995231628,"z":0.0}},{"damage":0.019,"offset":{"x":0.0,"y":2.29999995231628,"z":0.61000001430511}},{"damage":0.173,"offset":{"x":1.04999995231628,"y":2.29999995231628,"z":0.0}},{"damage":0.062,"offset":{"x":1.04999995231628,"y":2.29999995231628,"z":0.61000001430511}},{"damage":0.013,"offset":{"x":-1.04999995231628,"y":1.13999998569488,"z":0.0}},{"damage":0.006,"offset":{"x":-1.04999995231628,"y":1.13999998569488,"z":0.61000001430511}},{"damage":0.001,"offset":{"x":0.0,"y":1.13999998569488,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":1.13999998569488,"z":0.61000001430511}},{"damage":0.005,"offset":{"x":1.04999995231628,"y":1.13999998569488,"z":0.0}},{"damage":0.003,"offset":{"x":1.04999995231628,"y":1.13999998569488,"z":0.61000001430511}},{"damage":0.0,"offset":{"x":-1.04999995231628,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":-1.04999995231628,"y":0.0,"z":0.61000001430511}},{"damage":0.0,"offset":{"x":0.0,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":0.0,"z":0.61000001430511}},{"damage":0.0,"offset":{"x":1.04999995231628,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":1.04999995231628,"y":0.0,"z":0.61000001430511}},{"damage":0.013,"offset":{"x":-1.04999995231628,"y":-1.13999998569488,"z":0.0}},{"damage":0.0,"offset":{"x":-1.04999995231628,"y":-1.13999998569488,"z":0.61000001430511}},{"damage":0.013,"offset":{"x":0.0,"y":-1.13999998569488,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":-1.13999998569488,"z":0.61000001430511}},{"damage":0.016,"offset":{"x":1.04999995231628,"y":-1.13999998569488,"z":0.0}},{"damage":0.0,"offset":{"x":1.04999995231628,"y":-1.13999998569488,"z":0.61000001430511}},{"damage":0.0,"offset":{"x":-1.04999995231628,"y":-2.29999995231628,"z":0.0}},{"damage":0.0,"offset":{"x":-1.04999995231628,"y":-2.29999995231628,"z":0.61000001430511}},{"damage":0.027,"offset":{"x":0.0,"y":-2.29999995231628,"z":0.0}},{"damage":0.01,"offset":{"x":0.0,"y":-2.29999995231628,"z":0.61000001430511}},{"damage":0.0,"offset":{"x":1.04999995231628,"y":-2.29999995231628,"z":0.0}},{"damage":0.0,"offset":{"x":1.04999995231628,"y":-2.29999995231628,"z":0.61000001430511}}]', 86, 608, 779, 1, 0, NULL, NULL, 0, 0, NULL, NULL, 0, 0, 0, NULL, 0, 'valid', 0, 0, NULL),
	(9, 'license2:72b6567475f8452256ac755095e78e87298998a3', 'ZDQ8H6H9', 'ninef', NULL, '1032823388', '{"modLivery":-1,"modStruts":-1,"modEngine":-1,"oilLevel":5,"dashboardColor":0,"model":1032823388,"modFrontWheels":-1,"neonColor":[255,0,255],"wheelWidth":0.0,"windows":[4,5],"modSmokeEnabled":false,"modRightFender":-1,"xenonColor":255,"interiorColor":0,"engineHealth":978,"wheelSize":0.0,"modExhaust":-1,"neonEnabled":[false,false,false,false],"modHorns":-1,"modPlateHolder":-1,"modFender":-1,"modNitrous":-1,"modCustomTiresR":false,"wheels":7,"bulletProofTyres":true,"pearlescentColor":7,"modSpoilers":-1,"modTurbo":false,"modTrimA":-1,"modSideSkirt":-1,"paintType2":0,"modSubwoofer":-1,"modTrimB":-1,"modBackWheels":-1,"modAPlate":-1,"fuelLevel":48,"driftTyres":false,"tyreSmokeColor":[255,255,255],"bodyHealth":977,"modFrame":-1,"modArmor":-1,"modTank":-1,"modAerials":-1,"modDoorR":-1,"wheelColor":156,"modEngineBlock":-1,"modGrille":-1,"plateIndex":0,"modSpeakers":-1,"color2":1,"modSteeringWheel":-1,"modTrunk":-1,"dirtLevel":0,"modAirFilter":-1,"modTransmission":-1,"modLightbar":-1,"modOrnaments":-1,"modCustomTiresF":false,"modXenon":false,"tyres":[],"livery":-1,"modRoofLivery":-1,"modDial":-1,"tankHealth":998,"modSuspension":-1,"modHood":-1,"modRearBumper":-1,"extras":{"10":1,"12":0},"doors":[],"modHydrolic":-1,"paintType1":0,"modSeats":-1,"modArchCover":-1,"color1":3,"plate":"2UMVKBQE","modRoof":-1,"modFrontBumper":-1,"modDashboard":-1,"windowTint":-1,"modVanityPlate":-1,"modHydraulics":false,"modShifterLeavers":-1,"modDoorSpeaker":-1,"modWindows":-1,"modBrakes":-1}', '2UMVKBQE', NULL, 'Estacionamento Hospital Pillbox', '[{"damage":0.0,"offset":{"x":-1.02999997138977,"y":2.25,"z":0.0}},{"damage":0.0,"offset":{"x":-1.02999997138977,"y":2.25,"z":0.62999999523162}},{"damage":0.013,"offset":{"x":0.0,"y":2.25,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":2.25,"z":0.62999999523162}},{"damage":0.0,"offset":{"x":1.02999997138977,"y":2.25,"z":0.0}},{"damage":0.0,"offset":{"x":1.02999997138977,"y":2.25,"z":0.62999999523162}},{"damage":0.0,"offset":{"x":-1.02999997138977,"y":1.12000000476837,"z":0.0}},{"damage":0.0,"offset":{"x":-1.02999997138977,"y":1.12000000476837,"z":0.62999999523162}},{"damage":0.0,"offset":{"x":0.0,"y":1.12000000476837,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":1.12000000476837,"z":0.62999999523162}},{"damage":0.0,"offset":{"x":1.02999997138977,"y":1.12000000476837,"z":0.0}},{"damage":0.0,"offset":{"x":1.02999997138977,"y":1.12000000476837,"z":0.62999999523162}},{"damage":0.0,"offset":{"x":-1.02999997138977,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":-1.02999997138977,"y":0.0,"z":0.62999999523162}},{"damage":0.0,"offset":{"x":0.0,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":0.0,"z":0.62999999523162}},{"damage":0.0,"offset":{"x":1.02999997138977,"y":0.0,"z":0.0}},{"damage":0.0,"offset":{"x":1.02999997138977,"y":0.0,"z":0.62999999523162}},{"damage":0.0,"offset":{"x":-1.02999997138977,"y":-1.12000000476837,"z":0.0}},{"damage":0.0,"offset":{"x":-1.02999997138977,"y":-1.12000000476837,"z":0.62999999523162}},{"damage":0.0,"offset":{"x":0.0,"y":-1.12000000476837,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":-1.12000000476837,"z":0.62999999523162}},{"damage":0.0,"offset":{"x":1.02999997138977,"y":-1.12000000476837,"z":0.0}},{"damage":0.0,"offset":{"x":1.02999997138977,"y":-1.12000000476837,"z":0.62999999523162}},{"damage":0.0,"offset":{"x":-1.02999997138977,"y":-2.25,"z":0.0}},{"damage":0.0,"offset":{"x":-1.02999997138977,"y":-2.25,"z":0.62999999523162}},{"damage":0.0,"offset":{"x":0.0,"y":-2.25,"z":0.0}},{"damage":0.0,"offset":{"x":0.0,"y":-2.25,"z":0.62999999523162}},{"damage":0.0,"offset":{"x":1.02999997138977,"y":-2.25,"z":0.0}},{"damage":0.0,"offset":{"x":1.02999997138977,"y":-2.25,"z":0.62999999523162}}]', 47, 977, 976, 2, 0, NULL, NULL, 0, 0, NULL, NULL, 0, 0, 0, NULL, 0, 'valid', 0, 0, NULL),
	(10, 'license2:8d3ceb321079521ddd520a064373aaeff542eb96', 'JTW7MEXP', 'italigtb2', NULL, '-482719877', '{"modStruts":-1,"tireBurstState":{"1":false,"2":false,"3":false,"4":false,"5":false,"6":false,"7":false,"0":false},"modRoof":-1,"modPlateHolder":-1,"modHydrolic":-1,"color2":38,"modCustomTiresF":false,"paintType1":0,"modOrnaments":-1,"modArmor":-1,"bulletProofTyres":true,"wheels":7,"driftTyres":false,"modSuspension":-1,"modDial":-1,"modWindows":-1,"modDoorSpeaker":-1,"paintType2":0,"modTransmission":-1,"modRearBumper":-1,"modTank":-1,"plateIndex":0,"modVanityPlate":-1,"modAerials":-1,"modBackWheels":-1,"modKit47":-1,"wheelColor":156,"engineHealth":1000,"modSpeakers":-1,"doors":[],"modGrille":-1,"tankHealth":1000,"modExhaust":-1,"modDoorR":-1,"interiorColor":38,"modBrakes":-1,"modFrame":-1,"modKit19":-1,"modSpoilers":-1,"modSubwoofer":-1,"modLivery":-1,"livery":-1,"modFrontWheels":-1,"modArchCover":-1,"modHood":-1,"dashboardColor":134,"modRightFender":-1,"neonColor":[255,255,255],"modSideSkirt":-1,"modKit17":-1,"modAPlate":-1,"modFender":-1,"tireBurstCompletely":{"1":false,"2":false,"3":false,"4":false,"5":false,"6":false,"7":false,"0":false},"modXenon":false,"tyreSmokeColor":[255,255,255],"modTrimA":-1,"modAirFilter":-1,"modHydraulics":false,"modKit49":-1,"modCustomTiresR":false,"pearlescentColor":18,"model":-482719877,"bodyHealth":1000,"oilLevel":5,"neonEnabled":[false,false,false,false],"wheelWidth":0.0,"color1":38,"modSeats":-1,"extras":[],"modNitrous":-1,"plate":"67HCH306","headlightColor":255,"wheelSize":0.0,"modLightbar":-1,"modHorns":-1,"modShifterLeavers":-1,"doorStatus":{"1":false,"2":false,"3":false,"4":false,"5":false,"0":false},"windowTint":-1,"tireHealth":{"1":1000.0,"2":1000.0,"3":1000.0,"0":1000.0},"modDashboard":-1,"modFrontBumper":-1,"windows":[4,5],"windowStatus":{"1":true,"2":true,"3":true,"4":false,"5":false,"6":true,"7":true,"0":true},"dirtLevel":1,"modRoofLivery":-1,"modEngineBlock":-1,"modEngine":-1,"tyres":[],"fuelLevel":100,"xenonColor":255,"liveryRoof":-1,"modSteeringWheel":-1,"modTrunk":-1,"modTrimB":-1,"modSmokeEnabled":false,"modTurbo":false,"modKit21":false}', '67HCH306', NULL, NULL, NULL, 100, 1000, 1000, 1, 0, NULL, NULL, 0, 0, NULL, NULL, 0, 0, 0, NULL, 0, 'valid', 0, 0, NULL),
	(11, 'license2:ee41f168f07252b7eaa88f9d3c37d9b23fd61b3c', 'L112A611', 'zentorno', NULL, '-1403128555', '{"tankHealth":1000,"windowTint":-1,"modGrille":-1,"modVanityPlate":-1,"modSpeakers":-1,"driftTyres":false,"modFender":-1,"modTank":-1,"engineHealth":1000,"bulletProofTyres":true,"tireHealth":{"1":1000.0,"2":1000.0,"3":1000.0,"0":1000.0},"wheelSize":0.0,"modHorns":-1,"paintType1":0,"headlightColor":255,"wheelWidth":0.0,"modBrakes":-1,"modLightbar":-1,"modHood":-1,"modSubwoofer":-1,"modCustomTiresR":false,"tyreSmokeColor":[255,255,255],"modTransmission":-1,"neonColor":[255,0,255],"interiorColor":0,"modKit49":-1,"xenonColor":255,"livery":-1,"modLivery":-1,"modKit47":-1,"bodyHealth":1000,"modHydrolic":-1,"modSeats":-1,"doorStatus":{"1":false,"2":false,"3":false,"4":false,"5":false,"0":false},"liveryRoof":-1,"modOrnaments":-1,"oilLevel":5,"wheelColor":156,"modSuspension":-1,"dashboardColor":0,"modHydraulics":false,"modEngine":-1,"modTrimA":-1,"modWindows":-1,"wheels":7,"modAirFilter":-1,"modKit21":false,"modSideSkirt":-1,"modFrontBumper":-1,"modDashboard":-1,"modShifterLeavers":-1,"fuelLevel":100,"modSpoilers":-1,"modKit19":-1,"color1":1,"tireBurstState":{"1":false,"2":false,"3":false,"4":false,"5":false,"6":false,"7":false,"0":false},"modNitrous":-1,"modCustomTiresF":false,"windowStatus":{"1":true,"2":false,"3":false,"4":false,"5":false,"6":true,"7":false,"0":true},"modSmokeEnabled":false,"modDoorSpeaker":-1,"modDial":-1,"modBackWheels":-1,"windows":[2,3,4,5,7],"modRightFender":-1,"modDoorR":-1,"color2":41,"modAerials":-1,"neonEnabled":[false,false,false,false],"dirtLevel":3,"modEngineBlock":-1,"modXenon":false,"modRearBumper":-1,"modRoof":-1,"modPlateHolder":-1,"modAPlate":-1,"modTurbo":false,"model":-1403128555,"modArchCover":-1,"pearlescentColor":7,"modFrame":-1,"modFrontWheels":-1,"modSteeringWheel":-1,"doors":[],"tireBurstCompletely":{"1":false,"2":false,"3":false,"4":false,"5":false,"6":false,"7":false,"0":false},"modTrimB":-1,"modKit17":-1,"plateIndex":0,"tyres":[],"modTrunk":-1,"modArmor":-1,"extras":[],"modStruts":-1,"paintType2":0,"modExhaust":-1,"plate":"83XUV589","modRoofLivery":-1}', '83XUV589', NULL, NULL, NULL, 100, 1000, 1000, 1, 0, NULL, NULL, 0, 0, NULL, NULL, 0, 0, 0, NULL, 0, 'valid', 0, 0, NULL),
	(12, 'license2:72b6567475f8452256ac755095e78e87298998a3', 'ZDQ8H6H9', 'italigtb2', NULL, '-482719877', '{"modBackWheels":-1,"modShifterLeavers":-1,"tireBurstState":{"1":false,"2":false,"3":false,"4":false,"5":false,"6":false,"7":false,"0":false},"modTank":-1,"plate":"48HFF933","modKit47":-1,"modBrakes":-1,"modKit49":-1,"modHood":-1,"windows":[4,5],"plateIndex":0,"modTrimA":-1,"modArchCover":-1,"modRoof":-1,"modRightFender":-1,"modWindows":-1,"engineHealth":1000,"modTrimB":-1,"bulletProofTyres":true,"windowStatus":{"1":true,"2":true,"3":true,"4":false,"5":false,"6":true,"7":true,"0":true},"wheelColor":156,"modAPlate":-1,"modKit17":-1,"driftTyres":false,"modKit19":-1,"livery":-1,"modTrunk":-1,"modOrnaments":-1,"modEngine":-1,"neonEnabled":[false,false,false,false],"liveryRoof":-1,"modCustomTiresR":false,"tireHealth":{"1":1000.0,"2":1000.0,"3":1000.0,"0":1000.0},"modDial":-1,"modPlateHolder":-1,"modAirFilter":-1,"modDashboard":-1,"color1":38,"modRoofLivery":-1,"modHorns":-1,"wheelSize":0.0,"modVanityPlate":-1,"interiorColor":38,"oilLevel":5,"modSpoilers":-1,"modSideSkirt":-1,"modSpeakers":-1,"windowTint":-1,"wheels":7,"modHydrolic":-1,"modNitrous":-1,"modFender":-1,"tankHealth":1000,"modTransmission":-1,"modExhaust":-1,"modLightbar":-1,"modStruts":-1,"doors":[],"modSeats":-1,"wheelWidth":0.0,"modXenon":false,"modFrontBumper":-1,"pearlescentColor":18,"tyres":[],"modDoorSpeaker":-1,"neonColor":[255,0,255],"modFrame":-1,"modKit21":false,"modFrontWheels":-1,"modHydraulics":false,"paintType2":0,"bodyHealth":1000,"fuelLevel":100,"tyreSmokeColor":[255,255,255],"modDoorR":-1,"model":-482719877,"extras":[],"headlightColor":255,"modSmokeEnabled":false,"dirtLevel":0,"modGrille":-1,"tireBurstCompletely":{"1":false,"2":false,"3":false,"4":false,"5":false,"6":false,"7":false,"0":false},"modTurbo":false,"modSuspension":-1,"modSteeringWheel":-1,"modLivery":-1,"modArmor":-1,"dashboardColor":134,"xenonColor":255,"color2":38,"paintType1":0,"doorStatus":{"1":false,"2":false,"3":false,"4":false,"5":false,"0":false},"modEngineBlock":-1,"modAerials":-1,"modRearBumper":-1,"modSubwoofer":-1,"modCustomTiresF":false}', '48HFF933', NULL, NULL, NULL, 100, 1000, 1000, 1, 0, NULL, NULL, 0, 0, NULL, NULL, 0, 0, 0, NULL, 0, 'valid', 0, 0, NULL),
	(13, 'license2:ee41f168f07252b7eaa88f9d3c37d9b23fd61b3c', 'GBZ4I79C', 'reaper', NULL, '234062309', '{"modBackWheels":-1,"modShifterLeavers":-1,"tireBurstState":{"1":false,"2":false,"3":false,"4":false,"5":false,"6":false,"7":false,"0":false},"modTank":-1,"plate":"03DKG765","modKit47":-1,"modBrakes":-1,"modKit49":-1,"wheelWidth":0.0,"windows":[2,3,4,5,7],"plateIndex":0,"modTrimA":-1,"modArchCover":-1,"modRoof":-1,"modRightFender":-1,"modWindows":-1,"engineHealth":1000,"oilLevel":5,"bulletProofTyres":true,"windowStatus":{"1":true,"2":false,"3":false,"4":false,"5":false,"6":true,"7":false,"0":true},"wheelColor":156,"modAPlate":-1,"modKit17":-1,"tyreSmokeColor":[255,255,255],"modKit19":-1,"livery":-1,"modTrunk":-1,"modOrnaments":-1,"modKit21":false,"neonEnabled":[false,false,false,false],"modFrontBumper":-1,"modLightbar":-1,"tireHealth":{"1":1000.0,"2":1000.0,"3":1000.0,"0":1000.0},"modDial":-1,"fuelLevel":100,"modSuspension":-1,"modDashboard":-1,"modPlateHolder":-1,"modRoofLivery":-1,"modHorns":-1,"modAirFilter":-1,"dirtLevel":7,"interiorColor":0,"headlightColor":255,"modGrille":-1,"color1":3,"modSpeakers":-1,"windowTint":-1,"modHood":-1,"modHydrolic":-1,"modNitrous":-1,"modFender":-1,"modTurbo":false,"modTransmission":-1,"modExhaust":-1,"modCustomTiresR":false,"modStruts":-1,"doors":[],"modDoorSpeaker":-1,"liveryRoof":-1,"modXenon":false,"modArmor":-1,"tankHealth":1000,"tyres":[],"bodyHealth":1000,"neonColor":[255,0,255],"modFrame":-1,"modDoorR":-1,"modLivery":-1,"modHydraulics":false,"modVanityPlate":-1,"paintType2":0,"paintType1":0,"modEngineBlock":-1,"modSeats":-1,"model":234062309,"extras":[],"modEngine":-1,"modSmokeEnabled":false,"driftTyres":false,"modSpoilers":-1,"tireBurstCompletely":{"1":false,"2":false,"3":false,"4":false,"5":false,"6":false,"7":false,"0":false},"wheels":7,"modSideSkirt":-1,"modSteeringWheel":-1,"modTrimB":-1,"wheelSize":0.0,"dashboardColor":0,"xenonColor":255,"modFrontWheels":-1,"pearlescentColor":5,"doorStatus":{"1":false,"2":false,"3":false,"4":false,"5":false,"0":false},"modAerials":-1,"color2":3,"modRearBumper":-1,"modSubwoofer":-1,"modCustomTiresF":false}', '03DKG765', NULL, NULL, NULL, 100, 1000, 1000, 1, 0, NULL, NULL, 0, 0, NULL, NULL, 0, 0, 0, NULL, 0, 'valid', 0, 0, NULL),
	(14, 'license2:daf3461f2e2783d50236e55e31784c70edd6a826', 'PE9044F8', 'osiris', NULL, '1987142870', '{"modBackWheels":-1,"modShifterLeavers":-1,"modSuspension":-1,"modDoorSpeaker":-1,"dirtLevel":1,"modKit47":-1,"modBrakes":-1,"modKit49":-1,"wheelWidth":0.0,"fuelLevel":100,"plateIndex":0,"paintType1":0,"modArchCover":-1,"modAerials":-1,"modRightFender":-1,"modWindows":-1,"engineHealth":1000,"oilLevel":5,"bulletProofTyres":true,"windowStatus":{"1":true,"2":true,"3":true,"4":false,"5":false,"6":true,"7":true,"0":true},"wheelColor":0,"modAPlate":-1,"modKit17":-1,"driftTyres":false,"modKit19":-1,"livery":-1,"modTrunk":-1,"modOrnaments":-1,"modEngine":-1,"neonEnabled":[false,false,false,false],"modFrontBumper":-1,"modLightbar":-1,"tireHealth":{"1":1000.0,"2":1000.0,"3":1000.0,"0":1000.0},"modEngineBlock":-1,"tyreSmokeColor":[255,255,255],"plate":"88TOJ439","modDashboard":-1,"modFrontWheels":-1,"modRoofLivery":-1,"modHorns":-1,"wheelSize":0.0,"modAirFilter":-1,"interiorColor":0,"extras":[],"modSpoilers":-1,"modSideSkirt":-1,"modSpeakers":-1,"windowTint":-1,"tireBurstState":{"1":false,"2":false,"3":false,"4":false,"5":false,"6":false,"7":false,"0":false},"modHydrolic":-1,"modNitrous":-1,"modFender":-1,"modDoorR":-1,"modTransmission":-1,"modExhaust":-1,"color1":99,"modStruts":-1,"doors":[],"tireBurstCompletely":{"1":false,"2":false,"3":false,"4":false,"5":false,"6":false,"7":false,"0":false},"liveryRoof":-1,"modXenon":false,"modTrimB":-1,"modTank":-1,"tyres":[],"modTrimA":-1,"tankHealth":1000,"modFrame":-1,"modCustomTiresR":false,"modLivery":-1,"modHydraulics":false,"modDial":-1,"neonColor":[255,0,255],"modSeats":-1,"wheels":7,"windows":[4,5],"model":1987142870,"modArmor":-1,"modKit21":false,"modSmokeEnabled":false,"modPlateHolder":-1,"modVanityPlate":-1,"modTurbo":false,"headlightColor":255,"bodyHealth":1000,"modSteeringWheel":-1,"paintType2":0,"pearlescentColor":3,"dashboardColor":0,"xenonColor":255,"modRoof":-1,"color2":1,"doorStatus":{"1":false,"2":false,"3":false,"4":false,"5":false,"0":false},"modHood":-1,"modGrille":-1,"modRearBumper":-1,"modSubwoofer":-1,"modCustomTiresF":false}', '88TOJ439', NULL, NULL, NULL, 100, 1000, 1000, 1, 0, NULL, NULL, 0, 0, NULL, NULL, 0, 0, 0, NULL, 0, 'valid', 0, 0, NULL);

-- Dumping structure for table republica.player_warns
CREATE TABLE IF NOT EXISTS `player_warns` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `senderIdentifier` varchar(50) DEFAULT NULL,
  `targetIdentifier` varchar(50) DEFAULT NULL,
  `reason` text DEFAULT NULL,
  `warnId` varchar(50) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_player_warns_sender` (`senderIdentifier`),
  KEY `idx_player_warns_target` (`targetIdentifier`),
  KEY `idx_player_warns_warnId` (`warnId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.player_warns: ~0 rows (approximately)

-- Dumping structure for table republica.players
CREATE TABLE IF NOT EXISTS `players` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `userId` int(10) unsigned DEFAULT NULL,
  `citizenid` varchar(50) NOT NULL,
  `cid` int(11) DEFAULT NULL,
  `license` varchar(255) NOT NULL,
  `name` varchar(255) NOT NULL,
  `money` text NOT NULL,
  `charinfo` text DEFAULT NULL,
  `job` text NOT NULL,
  `gang` text DEFAULT NULL,
  `position` text NOT NULL,
  `metadata` text NOT NULL,
  `inventory` longtext DEFAULT NULL,
  `phone_number` varchar(20) DEFAULT NULL,
  `last_updated` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `last_logged_out` timestamp NULL DEFAULT NULL,
  `skills` longtext DEFAULT NULL,
  PRIMARY KEY (`citizenid`),
  KEY `id` (`id`),
  KEY `last_updated` (`last_updated`),
  KEY `license` (`license`),
  KEY `idx_players_userId` (`userId`),
  KEY `idx_players_phone_number` (`phone_number`),
  KEY `idx_players_last_logged_out` (`last_logged_out`),
  KEY `idx_players_citizenid` (`citizenid`)
) ENGINE=InnoDB AUTO_INCREMENT=1417 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.players: ~7 rows (approximately)
INSERT INTO `players` (`id`, `userId`, `citizenid`, `cid`, `license`, `name`, `money`, `charinfo`, `job`, `gang`, `position`, `metadata`, `inventory`, `phone_number`, `last_updated`, `last_logged_out`, `skills`) VALUES
	(434, 3, 'E33O250L', 1, 'license2:0f957b2bed833959dfda9020fc3311dc7a94a69c', 'WILL_DGK', '{"cash":500,"crypto":0,"bank":5180}', '{"cid":1,"backstory":"placeholder backstory","gender":0,"phone":"7145739730","lastname":"Dgk","firstname":"Will","birthdate":"1998-07-08","account":"US09QBX4458172159","nationality":"Brasileiro"}', '{"label":"Civil","onduty":true,"name":"unemployed","isboss":false,"grade":{"level":0,"name":"Freelancer"},"payment":10}', '{"label":"Sem gangue","name":"none","isboss":false,"bankAuth":false,"grade":{"level":0,"name":"Sem cargo"}}', '{"x":-905.3934326171875,"y":-2655.5869140625,"z":53.7120361328125,"w":93.54330444335938}', '{"craftingrep":0,"bloodtype":"A+","dealerrep":0,"jobrep":{"tow":0,"trucker":0,"taxi":0,"hotdog":0},"attachmentcraftingrep":0,"inside":{"apartment":[]},"status":[],"tracker":false,"fingerprint":"008L0EH5545Z0IH","callsign":"SEM CALLSIGN","licences":{"id":true,"weapon":false,"driver":true},"hunger":87.39999999999999,"stress":3,"staff":"group.admin","jailitems":[],"phone":[],"optin":true,"inlaststand":false,"isdead":false,"walletid":"QB-53959618","ishandcuffed":false,"injail":0,"thirst":88.60000000000001,"phonedata":{"SerialNumber":23842712,"InstalledApps":[]},"health":200,"armor":0,"criminalrecord":{"hasRecord":false}}', '[{"metadata":{"durability":99.95,"components":[],"serial":"839311BVT395517","registered":"Will Dgk","ammo":-1},"count":1,"name":"WEAPON_GRENADELAUNCHER","slot":1},{"metadata":{"durability":99.97,"components":[],"serial":"743874CSD307941","registered":"Will Dgk","ammo":-1},"count":1,"name":"WEAPON_CARBINERIFLE_MK2","slot":2},{"metadata":{"durability":100,"components":[],"serial":"935149DVX711374","registered":"Will Dgk","ammo":0},"count":1,"name":"WEAPON_MARKSMANRIFLE_MK2","slot":3},{"metadata":{"durability":99.8,"components":[],"serial":"596572ZCL168062","registered":"Will Dgk","ammo":-1},"count":1,"name":"WEAPON_DOUBLEACTION","slot":4},{"count":500,"name":"money","slot":5},{"count":116,"name":"ammo-rifle2","slot":6},{"count":10,"name":"firework1","slot":7},{"count":1,"name":"phone","slot":8},{"count":2,"name":"lockpick","slot":9},{"count":1,"name":"police_stormram","slot":10},{"metadata":{"badge":"none","lastname":"Dgk","cardtype":"driver_license","firstname":"Will","nationality":"Brasileiro","birthdate":"1998-07-08","citizenid":"E33O250L","sex":"M"},"count":1,"name":"driver_license","slot":11},{"count":1,"name":"speaker","slot":12},{"metadata":{"cardtype":"id_card","citizenid":"E33O250L","badge":"none","lastname":"Dgk","mugShot":"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAAAXNSR0IArs4c6QAAFI9JREFUeF7lW99vHFlWPl3VVV3la3e64myvja0ZmRkSZTUCZbUw2hFCYiS0YsVKaAQS4n/jCfHKyyIkXnjc1SBgBRo2mjBDyChZGxOnOt0u13VVV/XqO+eeW9UdJxMHZR6YK1nVXV0/7vnud37e48HBb+yvnvzqmL6N453DAxp88pMfrz79l1/Qtw0ECP/7P/xQAMDq/+1P//5bRYK//PNPWF4PABgAJnwbBlYeDGAA/uLP/pQZUMwLKhYF/ePPf/b/GoOP//BjOtibehk9AHqmsCX99O/+4Y1AGO+M+b6DgwOaL+b8eZzKufm5fC9swcfZbLb2jslkwt/bZUs72zs03tb7zuQ524aenJwSDUL/7OtO8pM/+RHt7x/S/FzmsMYAs7PFJyaTjI8P/vMLPn7xX1/R/V/ef+Fduzd3+dx0On3lhACACo/r4ySmSSbCbo5ZPqPKVv40QJifCwB+hFH3+86Yjk/Fg82erQOKc3e/d5fu/uY7/Pvd33pfrju3fFQQPAM2AdC3JNvdZO/fv08nj074p6fPnvIxjLoVAQOw8soEZkHTzR0C2aVMACBA4M3PyTBZA4yo5tXXCY8nux27dsZka/e8mzLPo3eP6O7du91Lz9eBUQBwARg1+Mkf/YhtwPSWrGiynVI+y/lzNsnILsse/ETHJyf08MvHDvUFURJQaQtKE+OEGdMs7yi2YxIyW4aKi4KKsqDpjSnZS8t/ySjhe/Qzvp/mJ2SShEyaUFFaWpQiIM9tlJB1DCkv3DuG8tutm7fo9nu3aX9vnV3JMKWzXFi0m+2StSIP5Dg+OabBh/d+sFLhcQQAGAoCEO7Ty15W9PDLJ35SJZVeeDkZymSTmJI0oqYSCkB4jHEyZkFm89kaAJPxhIGYX8iKAQSMupWn4rfysqQ0FqB1mO3Us/HOe3fIbMn7MWBX4jDmzxCen2NLLzy+D44Oj1bT7zh9vrVLDdV8ow4FIM9zyrKMjk+e0uzZQl5wc4esTtAZt0kmxktZEAQNmdTQ6dkpM6GtWlJh9R3KBIASDGEoS5pOMiqspZb5STTZkTnN5mJMk1SACMP2pQDg9+luZ/HPnj2lKIx55TFOjo8FAL7QgRAOe0pLRKXtKMgIXjYeAJlJQElieEK2LMhay6ufz6AWEUEFsPpQAYx0mPLKM50v5dn6Gd8VAJOkzAKoAFY+G2eiKskOJVuG7EXB7yurTt2gBjumM5J+FfsflvIFwmMMiGh1sHfg3U6WCfV05AuZJF6GgVXBiEYRxXFMuNrWAloShVTYisJhTPY8p2AYE40M1bWlqiopjlMyA5ngZMfQbFHwDCaZ8YwpWlxbkTGywnVZ83fYo6quaJzGZCvxFEkc07yUz3Vd89HECS+IjkQ0msdiPqdmEPvFOD09FQDwIyw0+99x7w5e8c4tCeINxaPYA0B14wEoq5bMsKFwGFGzrKldVtTE688LK6x4dCUA1tbUxB0DITgtqQOjFjAw0lHMz6EgZmAUgLBt1gAIw+5588WCaJhQUbjFLIoOAAXBmI4BkxtjBkBXny3vMCEzNrz6mEy7lJVXFgStrARGnBgqqk6FzNaEEve7B3YgBlOHpWZNIBOLB9ER4noIzotTU7Miti0AAYKlw84IggkAgAWH75/PKRwZDwDOeQZ4yjjri+/ZjTGVhRgdPxwA+F5f1lQ1IWUmYgAARNM0vPo66kAmFEUCbLxsKBnFHbMwA+c12MUl4RoAYIDcH/EqmyRiwQFCPi94IfAbBq+sizM8oJs2zD1Pf38BgL6sZttQs1w3ikmSUDYWHcNEKOwQ55ODgJKRIXtZUHlZUBoKVflap/sASxkTDUOKo04IDY7UMLLrS1LCe2FgN0cQBny/qgFWmefGxvjqe/rPGBxMp2wDnpyevvDwzRN4IP72b2VsiHgltmH9u4mVFSw2gh2hbRISrxR0FoavLzwYA4OJyTM7AMQgotli1ll+p0IqTGkFEB1N27AKYCB22cwxXibU1CVEDMDYPWB+UdDM6VvRSxj0IQoAGKA0tEsXCMBlXpRELjJLR4aZkD87ZeEZDOjuoLMXk62Y6lXI1I3iiAHov5fdH6JRt/IQXoeCAAZANaAGeA6uvYopYDMGjvoZ7/IM0AfHjt46kX5ywi9dQYc7PQQASSr6nWwlRHVCtioonwujoALlZeWtdn7RUhoHbC8wwAAMtcxJLPEBU3+U8hEDQGABMFRIAAJ3qQDgGAYh9YFC8qWC83vcwupxcHS4v0J42A94st2pj7QUTaSx1bJid6l2AalrEAh0xUVJZiulFCBwtuXiBQqoXsJ4GUmFg86tRlFK4TCgBhOPIj4it9HcAasajjqG4bku9+mY3ZYcb8D1ynsLBgVs4kVxoMGTwO/r4HwjSWlw9/2jlSC6DkK6JdEdKAvB+eUQZNv4lDUchtRULgBJkfQkrAILFzwBhIgEIdwbDSMqrCQmxkjaDUZB+LooKIhjokasvVp2BYCfLSKxzVG7g1AbAwCATRBU7+XzoaiYMozf7YTHcQ0AfpJzW/gIv28mkieoAKCUMoCPbcuZG8bpWU6252bGSKyWDQuOIcUQy8LHUULFRU5hS5RMMmoQzACEUCitAU84gnr0MsJhQtmugMcgtCVFCbxVzSDYSu5V1YBX0KiSb2oaXnlNtlgF1txFGHVxfVlQE4Ru5cSqg8qgfrKdCBNaoaiqgGZvbrnIDAUcVSFjxILXdUmqAhA8MoZVIA4k8NFVtMsuCMJ9cZiysU23nCfoASDvqTg2wAAQYMAaABXUUedkaTDeNqsdZyH5BS6O3t+Rix6dzWlRLGjH7HhB0rRzQ4GjOF6EIAhpAXy7TAYCNT6I0Zge7kpXqGorSuOU4D73J/t0NhM99c84r7iKxIsHxoVCa7wLx7DtbAoL3TMZJk1p9+aEAzbUPPl3anyBZQEvAC1ExQUg4KgUniDiYhcX0fxCQOAHXFZs7QECrL/m+7WzBWVPBTKwxPl4jdXVXWkEFyNxqu0aANWyodiBCL0uz8UTwOaEccgrq6ts4nDNfoWxLByEx0iGEecumDc/AxWs84IgPI4+EkSlFADgBgx2b8OA7DL0AMyLOaFkxe4OrulmxskKr04rxsi6AoiuIARRSsMy96tNOA+hkiihvMiZCUkgNAYI2XZKhZXnYvXZ6MJouugTLi8ZdsUbmbfMZ7qbsW3CNf2BeUJwLrBu5gJ33z/iig4EVxDAgCf/+4QgvCDaASBII+GQl4CW8Bo6ahhA97XvqzVy4+tcwYPfV1sPAADE/c3SrTyEhwo4twvBIEx10eUq7LKdzYHXAAvGxnDmCjXQhbr/xUM/x7VcAGiOb059aIkVAt36LgTCKgPshaXsRi/3jpCrI093AUuF3E5W0Lu1UGL/teivEN8NddH4QWeY9laQ3bFLHFWg6nK+VlprGmGwV7GwU4eiLGn+fMYsQVaJTPKVyVB/4johAKBuKD/L2e+jMJFGESUOAL2Wo7iBTIbZsmW8qmgCs8ZPzjAbyouCn4l8w/TSW9iLKqj8aopeW8rGUi7L5zNSADwLXaFk8z36/WsB2LyRs8HdjA0g++FlRWX/JY3jaO8NCgBHdo4B+LmfBOE7M20V+OcBgJhadsOIQ3iEYoh9UYYaSuKUbFVSeWlp9vzFjPFlwuP8GwGwf7jPzwQAyYAodwkUl6qcEdJ0FoABANV7zd6gXhquAggNf8NWjAaeKc+7WiAAYHYMUVUyABjHT4/pioz5VfJfH4DJdsKJCQNgSwo2Sl4IiPrZGFwhIjXWSxRPA7iimCM/hNEQTzNBzulxrpf92Y2Njd1bAj4qx/zMUMpzfG5e0Gzj+ldK/yYMAAD7e44B1nLgAaEx4HoWhV3LxuBaNbiKUkOxK4kBAFYDN0NlAzyJAoBjeZ774gaAj4YJnbqNG9wK5qiKYXMX5ffrjGurwNHhvs+w8CKpySGuF6oiEuSJuxXaBACepnVBU1UU1Lg6gE76KgDwW8rFmJQBYMGThCvUhSuSao3yya+6TZvXAeKNANAHQ78BANPPVYVi5PO9cpTZlhAaAwwAABgAgVng0laoAei/CQAtSxYcgzNWVIl7yQxMI1w13CJU4a0CgEhs77t7Pl1l2i6tT5dZMJIa4MRVjRAZct1vGFAUhdQGMaHSWzUV1U0tEV4YEld2HAC+pI4Mb4T7JM2tq4qqugu08H4AamvxRHDF+XOpCr3uuBYDkAHu3thld+VdW9D4VLkPACq/rCIuOQEAGOEopchtcQMARIIQntUHqazbLeI9hVcAgGvBmmYl7hEeg2OHi+rtA9DP1xGIIEDRnD/mWmBX5w+DgCpXNwQICgCERyYIt6cM0CJH7fYZpdLTUF1j5UXQunJlc7Ujqy4bfOsAREnEm4390LgPAIDAvp23EYjB3bYZQNgEgK9bSQ4BEKDLSv+uzGUZAB1F0UoJHGzBeWdT8HtmDJ0+RTS4Xsp/lTpcSwVgZKZZxkkKsrX+0Nq9GjM2erDwI1cbcEaSkylXQRId6Z6C3MIuZXtc9/eQbteVpcjlF7XT73wuPQwokcE2sXoNQ8qf536b7FWC62/XAmBya0JZghS1YsOmQGiJGl4BQveHAoBz8BSvA0B/c1PrDfpMBcC6ajE2OxlHly4jYXrdvQHc90YAaMECx9Y3RMimidYF/G5NW/uaIRcjtzWKlFgBNQBeR1djyGdnfi/S2oKiYH23GjVEW6HDxO0RROna7tU3AoAyAMUOpJa6YQJB4IKQ2npVcFVbNDxg5K66w9dyMtUJj3Opqxmi7QabsuEqYvpDDarachGV73U7RmjQwOp/MwyYTMiYmNqmoiCMKQwjCh0FtcsDBQvePXZlqLHzCNge4x3hXnKjtqC/tQadxsi+I4Bp5oc4H5+LckbxKPHush6g7FZQ06AAGlNTVNfKB66nAg4A1cc4MmzFsZODtheMOI0ZAB2lK0amo8i7R0R0Gt1tGiotaWkRs/8sbuYsXb/hPKdolJICoM/5RgFQBvS7vMzE+IIFJrXLEWFFpStJEarAvS14XNPflWrbLrsDixQIFRAAIFiqL0sGwK4CahBQufHWARj3VhcvbhvXFTZKmAVhGkrfgCtaaHnEN0S8JL9nQ8hFFmL1Ufp7trmuFG63W8wYAL7GdYHpdfZ54btRN9l11fdrq0C2na1vlWH/2w00P6bbGVt31WtEuZHrB8RlCGDGY+kkk9Ht+M7n2CXu1Ief4TYDE5NQahLKc8tuTrNN3hvoVYlRQr9OTeDaAGBnSAfKVKHL6KHT7A1cO5sC0NSWjZYfvaqxnFvf2GgcozShUXwBAMbJqQRKVwHAT7t4i0YQNT2Ewgh5tem5DwAmgNZarRdCCC2LAwQwQTdQtJm6HwqOdwwBgH421yMYC358lnODRB8AnFcW5M/yrn74GjpwLQbgeWiiBAu0SLkJAOryuiWN6/slLQCADhFtY9mcH+xL3d/bwvvcylu3QaqJ7lUAIJe4ThSI918LgMnNCWW9ZAeRWhPGnNtnidvudm1p2smJ1dTtdbwQG6v4rgAicNa9fWyDBStkf5IgmK3Yb3Qg8OH9BpcLKAOrngoZMyZbNnT2bKPD/BVM+FoAIDTG0XtH3DOcDCKC4Ly6DgB8Ro4fBzFR2HAEpwBof4Fur18FAFPY7e83rsSF4kmM9ruWfJcIOkYClMqHMeXnLhnqZYPT6SFRE3Dj9Odffs5z/DowXgrAB799j6bf3ad8drzWLD3ZmrCAM7eLCxvOldkw4goP4n1uqLwoCE0WgWZxy5pXPiQkUeK38R2mDSuvLCAX6gIAjGKJZizpLAcADbbO3T4BM2uIZoux+9tZixsABIo46Az57D8+u5IHVwKgwp/+zzEVRddvz2xwSnhyLPtrUAFlAI68ag4A/r49XusvAAAsmGNRHwDUApplQHEccvmsKCqikUSa6BXm920AYG6IS51O5X+A0Ius/8uA74fvHPL5l4HwAgAf/t6HnMyg6IGbUATh9jWHekOS7h47AEwcU42uC1fcpDgiWxRUunZU3axU+ONAllibF5pBwzu4cRBR1dY+m+yWy1WBXe9w6zowuCMNOcNexjvO+/tSqgfAOlc0aUcjwxuk+JsXBf3zP326xoQ1AG7fvk2HB4e+4sNNRUNpVVfaAgDpCi/4HyViF4RE2PLCRqarBwAEjL1336fZ2RnlZ/IfJukQdcLWA+AIQeFAtr41nYb64e+zf//lWodHHwDuEnHVN/03nKZu/IKh3xC5xcFUWuYBwuMnj+nBgwceBA/A7u4u3bl9x5eTtLFIGcCrhlIU0lffGi8gMNXDkBiEjTj/6M4HlJ+d0cMHYpTAAK4TuhqfVnOY3hsAQBU//ZmsmLISAOjqY4sO22GICzYB0PkubO0B0Hl+/uBzOjsTT8EAqPA8CVdP05Yy3n9zAwCEyABd+zx7AbTCN80aAImjK1gAAB4+eOAZoCrgW1yCgJqVqMVVDCgW5VqXV/FcAGfhHx9z9qwAIPoE/XWXiUFoZeV1KGMVhMFkMlmB9uvxOXT8WELbNKG2aaUJGuC4puf60lIxn7GKaEECR+MSGRgnc2OHbmX79OjRQ/rqkRjNfpDkZ+U+tPAUriPkg3vfp+neHj357/v0NJ/RmdsOg0XIpodkXcMGmjD7TZQ1l9nlgdBOu7DMDi3bzZ/PaXxjTDg+/uoxDT764Ue9Ho1uSgpAv+MKv8IGcUh7aTktRU8waKwdpUmveXr6zsELAMCHrw9tgZGcoFnK7BWAf/vFz73wOJ+ZMU2mB3T80P0r37Dbq+T59QDg7xcdAJt9xqwCLwMA/yOEoQCoajQB2k3EF/YB8Czo9RiDBd/7nR/QO+8e0d/89V/JqqjV8yh0yZC02YvV//iPf8zHTQCOju7S7LS3/zcI1/7HSdsT0LIEJvQB2GTc/xkAPGA+78JOsAAqUDzv+nZ+9w8+5veqGgCA9Rb8zW2shKZ7+/TBvXt0enJCn93/Vz/vj+59n+4/+IL/hyE14v9hkPtqBQAgPLQVZGxQrXIqoAwA/TGgCr8GQ/8wHZlb7fAAAAAASUVORK5CYII=","nationality":"Brasileiro","firstname":"Will","birthdate":"1998-07-08","sex":"M"},"count":1,"name":"id_card","slot":13}]', '7145739730', '2026-03-22 00:57:59', '2026-03-22 04:57:58', '{"mining":0,"hotwiring":0,"crafting":0,"cargo":0,"cooking":0,"hunting":0,"fishing":0,"trucker":0,"taxi":0,"busdriver":0,"garbage":0,"areaexample":0,"cityworker":0,"searching":0,"lockpicking":0}'),
	(429, 4, 'GBZ4I79C', 1, 'license2:ee41f168f07252b7eaa88f9d3c37d9b23fd61b3c', 'willian', '{"crypto":0,"bank":5230,"cash":0}', '{"nationality":"Brasileiro","cid":1,"backstory":"placeholder backstory","gender":0,"lastname":"Willian","birthdate":"1987-11-16","phone":"4722232579","account":"US08QBX4710695699","firstname":"Cavalcante"}', '{"label":"Civil","bankAuth":false,"payment":10,"grade":{"name":"Freelancer","level":0},"isboss":false,"name":"unemployed","onduty":true}', '{"label":"Sem gangue","bankAuth":false,"grade":{"name":"Sem cargo","level":0},"name":"none","isboss":false}', '{"x":3937.490234375,"y":-4692.8173828125,"z":3.3648681640625,"w":11.33858203887939}', '{"licences":{"weapon":false,"id":true,"driver":true},"thirst":100,"hunger":100,"injail":0,"jailitems":[],"status":[],"inlaststand":false,"dealerrep":0,"stress":0,"criminalrecord":{"hasRecord":false},"attachmentcraftingrep":0,"tracker":false,"armor":0,"inside":{"apartment":[]},"craftingrep":0,"jobrep":{"tow":0,"trucker":0,"hotdog":0,"taxi":0},"phonedata":{"InstalledApps":[],"SerialNumber":57885916},"bloodtype":"O+","isdead":false,"optin":true,"health":200,"walletid":"QB-32492353","phone":[],"ishandcuffed":false,"staff":"group.admin","callsign":"SEM CALLSIGN","fingerprint":"877FT39IN3I4V5V"}', '[{"slot":1,"count":1,"metadata":{"components":[],"serial":"427151OJJ598228","durability":99.5,"registered":"TiãO Dev","ammo":-1},"name":"WEAPON_RAILGUN"},{"slot":2,"count":1,"metadata":{"components":[],"ammo":0,"durability":100,"registered":"Cavalcante Willian","serial":"964390JSE982793"},"name":"WEAPON_BATTLERIFLE"}]', '4722232579', '2026-03-20 02:55:00', '2026-03-20 06:55:00', '{"mining":0,"hotwiring":0,"crafting":0,"cargo":0,"cooking":0,"hunting":0,"fishing":0,"trucker":0,"taxi":0,"busdriver":0,"garbage":0,"areaexample":0,"cityworker":0,"searching":0,"lockpicking":0}'),
	(61, 2, 'JTW7MEXP', 2, 'license2:8d3ceb321079521ddd520a064373aaeff542eb96', 'MAKA', '{"crypto":0,"coin":0,"bank":357715,"cash":0}', '{"backstory":"placeholder backstory","firstname":"Maka ","birthdate":"20/03/2026","phone":"5281670555","gender":0,"nationality":"Brasileiro","account":"BRL2MRI3218317121","cid":2,"lastname":"Patron"}', '{"grade":{"name":"CORONEL ","level":9},"type":"leo","name":"police","isboss":true,"onduty":true,"bankAuth":true,"label":"POLICIA MILITAR","payment":10000}', '{"grade":{"name":"Sem cargo","level":0},"name":"none","isboss":false,"bankAuth":false,"label":"Sem gangue"}', '{"x":-786.3956298828125,"y":-2673.441650390625,"z":15.176513671875,"w":184.25196838378907}', '{"licences":{"weapon":false,"driver":true,"id":true},"injail":0,"jailitems":[],"tracker":false,"armor":0,"thirst":24.00000000000004,"staff":"group.admin","status":[],"craftingrep":0,"criminalrecord":{"hasRecord":false},"bloodtype":"O+","stress":0,"inlaststand":false,"inside":{"apartment":[]},"jobrep":{"hotdog":0,"taxi":0,"trucker":0,"tow":0},"callsign":"SEM CALLSIGN","fingerprint":"AIEK125R72DHR07","dealerrep":0,"phone":[],"walletid":"MRI-60319196","attachmentcraftingrep":0,"ishandcuffed":false,"hunger":15.99999999999994,"isdead":false,"health":200,"optin":true,"phonedata":{"InstalledApps":[],"SerialNumber":64878747}}', '[{"slot":1,"name":"rope","count":1}]', '5281670555', '2026-03-24 01:30:25', '2026-03-24 05:30:25', '{"hotwiring":0,"areaexample":0,"trucker":0,"cityworker":0,"crafting":0,"taxi":5,"cargo":0,"lockpicking":0,"busdriver":0,"fishing":10,"cooking":0,"searching":0,"hunting":0,"garbage":0,"mining":0}'),
	(416, 2, 'M2R33T1T', 2, 'license2:8d3ceb321079521ddd520a064373aaeff542eb96', 'MAKA', '{"crypto":0,"bank":5020,"cash":500}', '{"nationality":"Brasileiro","cid":2,"backstory":"placeholder backstory","gender":0,"lastname":"E O Pe De Feijao","birthdate":"2006-12-30","phone":"6419212949","account":"US03QBX3279569018","firstname":"Tiao"}', '{"label":"Civil","bankAuth":false,"payment":10,"grade":{"name":"Freelancer","level":0},"isboss":false,"name":"unemployed","onduty":true}', '{"label":"Sem gangue","bankAuth":false,"grade":{"name":"Sem cargo","level":0},"name":"none","isboss":false}', '{"x":-1028.26806640625,"y":-2723.353759765625,"z":20.079833984375,"w":150.23622131347657}', '{"licences":{"weapon":false,"id":true,"driver":true},"thirst":84.80000000000001,"hunger":83.19999999999999,"injail":0,"callsign":"SEM CALLSIGN","inlaststand":false,"dealerrep":0,"walletid":"QB-21001744","criminalrecord":{"hasRecord":false},"attachmentcraftingrep":0,"tracker":false,"armor":0,"inside":{"apartment":[]},"fingerprint":"JA68J51W7604467","jobrep":{"tow":0,"trucker":0,"hotdog":0,"taxi":0},"phonedata":{"InstalledApps":[],"SerialNumber":87851141},"craftingrep":0,"isdead":false,"health":200,"optin":false,"bloodtype":"B+","phone":[],"ishandcuffed":false,"stress":0,"status":[],"jailitems":[]}', '[{"count":500,"slot":1,"name":"money"},{"count":1,"slot":2,"name":"phone"},{"slot":3,"count":1,"metadata":{"cardtype":"id_card","birthdate":"2006-12-30","badge":"none","citizenid":"M2R33T1T","nationality":"Brasileiro","sex":"M","lastname":"E O Pe De Feijao","firstname":"Tiao"},"name":"id_card"},{"slot":4,"count":1,"metadata":{"cardtype":"driver_license","birthdate":"2006-12-30","badge":"none","citizenid":"M2R33T1T","nationality":"Brasileiro","sex":"M","lastname":"E O Pe De Feijao","firstname":"Tiao"},"name":"driver_license"}]', NULL, '2026-03-19 19:58:52', '2026-03-19 23:58:52', '{"mining":0,"hotwiring":0,"crafting":0,"cargo":0,"cooking":0,"hunting":0,"fishing":0,"trucker":0,"taxi":0,"busdriver":0,"garbage":0,"areaexample":0,"cityworker":0,"searching":0,"lockpicking":0}'),
	(436, 5, 'M4865C4Y', 1, 'license2:1ce6953be549523b546c8051a9024d68c71fb1d8', 'LOBODELEGA', '{"crypto":0,"bank":5010,"cash":400}', '{"nationality":"Brasileiro","cid":1,"backstory":"placeholder backstory","gender":0,"firstname":"Lobo","birthdate":"1979-06-09","phone":"4524823682","account":"US02QBX2936612288","lastname":"Walker"}', '{"label":"Civil","bankAuth":false,"payment":10,"grade":{"name":"Freelancer","level":0},"isboss":false,"name":"unemployed","onduty":true}', '{"label":"Sem gangue","bankAuth":false,"grade":{"name":"Sem cargo","level":0},"name":"none","isboss":false}', '{"x":-69.81098937988281,"y":-827.98681640625,"z":284.99267578125,"w":17.00787353515625}', '{"licences":{"weapon":false,"id":true,"driver":true},"thirst":96.2,"hunger":95.8,"injail":0,"callsign":"SEM CALLSIGN","inlaststand":false,"dealerrep":0,"walletid":"QB-38916920","criminalrecord":{"hasRecord":false},"attachmentcraftingrep":0,"tracker":false,"armor":0,"inside":{"apartment":[]},"fingerprint":"EUS8SOVZ80942T9","jobrep":{"tow":0,"trucker":0,"hotdog":0,"taxi":0},"phonedata":{"InstalledApps":[],"SerialNumber":71897371},"craftingrep":0,"isdead":false,"health":200,"optin":false,"bloodtype":"A+","phone":[],"ishandcuffed":false,"stress":0,"status":[],"jailitems":[]}', '[{"count":400,"slot":1,"name":"money"},{"count":1,"slot":2,"name":"phone"},{"slot":3,"count":1,"metadata":{"cardtype":"id_card","birthdate":"1979-06-09","badge":"none","citizenid":"M4865C4Y","nationality":"Brasileiro","sex":"M","lastname":"Walker","firstname":"Lobo"},"name":"id_card"},{"slot":4,"count":1,"metadata":{"cardtype":"driver_license","birthdate":"1979-06-09","badge":"none","citizenid":"M4865C4Y","nationality":"Brasileiro","sex":"M","lastname":"Walker","firstname":"Lobo"},"name":"driver_license"}]', NULL, '2026-03-19 23:54:37', '2026-03-20 03:54:37', '{"mining":0,"hotwiring":0,"crafting":0,"cargo":0,"cooking":0,"hunting":0,"fishing":0,"trucker":0,"taxi":0,"busdriver":0,"garbage":0,"areaexample":0,"cityworker":0,"searching":0,"lockpicking":0}'),
	(546, 6, 'PE9044F8', 1, 'license2:daf3461f2e2783d50236e55e31784c70edd6a826', 'BUTEÇÃO', '{"crypto":0,"bank":5060,"cash":5400}', '{"nationality":"Brasileiro","cid":1,"backstory":"placeholder backstory","gender":0,"lastname":"Pitbull","birthdate":"1998-12-20","phone":"9097702276","account":"US07QBX4961880460","firstname":"Bruno"}', '{"label":"Civil","bankAuth":false,"payment":10,"grade":{"name":"Freelancer","level":0},"isboss":false,"name":"unemployed","onduty":true}', '{"label":"Sem gangue","bankAuth":false,"grade":{"name":"Sem cargo","level":0},"name":"none","isboss":false}', '{"x":230.39999389648438,"y":-781.6351318359375,"z":30.5098876953125,"w":68.031494140625}', '{"licences":{"weapon":false,"id":true,"driver":true},"thirst":96.2,"hunger":95.8,"injail":0,"callsign":"SEM CALLSIGN","inlaststand":false,"dealerrep":0,"walletid":"QB-22891738","criminalrecord":{"hasRecord":false},"attachmentcraftingrep":0,"tracker":false,"armor":0,"inside":{"apartment":[]},"fingerprint":"IM184PK0769U19Y","jobrep":{"tow":0,"trucker":0,"hotdog":0,"taxi":0},"phonedata":{"InstalledApps":[],"SerialNumber":14486547},"craftingrep":0,"isdead":false,"health":200,"optin":false,"bloodtype":"O-","phone":[],"ishandcuffed":false,"stress":2,"status":[],"jailitems":[]}', '[{"count":5400,"slot":1,"name":"money"},{"count":1,"slot":2,"name":"phone"},{"slot":3,"count":1,"metadata":{"cardtype":"id_card","birthdate":"1998-12-20","badge":"none","citizenid":"PE9044F8","nationality":"Brasileiro","sex":"M","lastname":"Pitbull","firstname":"Bruno"},"name":"id_card"},{"slot":4,"count":1,"metadata":{"cardtype":"driver_license","birthdate":"1998-12-20","badge":"none","citizenid":"PE9044F8","nationality":"Brasileiro","sex":"M","lastname":"Pitbull","firstname":"Bruno"},"name":"driver_license"},{"count":5,"slot":5,"name":"burger"},{"count":5,"slot":6,"name":"sprunk"},{"count":1,"slot":7,"name":"phone"},{"count":5,"slot":8,"name":"lockpick"},{"slot":9,"count":1,"metadata":{"components":[],"ammo":29,"durability":99.97,"serial":"625803NZY573026","registered":"Bruno Pitbull"},"name":"WEAPON_ASSAULTRIFLE_MK2"},{"count":470,"slot":10,"name":"ammo-rifle2"}]', NULL, '2026-03-20 01:47:39', '2026-03-20 05:47:39', '{"mining":0,"hotwiring":0,"crafting":0,"cargo":0,"cooking":0,"hunting":0,"fishing":0,"trucker":0,"taxi":0,"busdriver":0,"garbage":0,"areaexample":0,"cityworker":0,"searching":0,"lockpicking":0}'),
	(1, 1, 'ZDQ8H6H9', 1, 'license2:72b6567475f8452256ac755095e78e87298998a3', 'ShyRabbit8170', '{"crypto":0,"coin":0,"bank":11195870,"cash":4019}', '{"gender":0,"phone":"6522731956","backstory":"placeholder backstory","cid":1,"lastname":"Dev","nationality":"Brasileiro","birthdate":"Invalid Date","account":"BRL3MRI5818593250","firstname":"TiãO"}', '{"label":"POLICIA MILITAR","grade":{"name":"CORONEL ","level":9},"bankAuth":true,"onduty":true,"type":"leo","isboss":true,"name":"police","payment":10000}', '{"label":"Sem gangue","bankAuth":false,"grade":{"name":"Sem cargo","level":0},"name":"none","isboss":false}', '{"x":406.1274719238281,"y":-978.5802001953125,"z":29.2630615234375,"w":17.00787353515625}', '{"bloodtype":"AB+","jailitems":[],"verified_by":"TiãO Dev","attachmentcraftingrep":0,"health":200,"phone":[],"stress":15,"optin":true,"tracker":false,"isdead":false,"inlaststand":false,"inside":{"apartment":[]},"callsign":"SEM CALLSIGN","injail":0,"armor":0,"verified":true,"phonedata":{"InstalledApps":[],"SerialNumber":26596349},"walletid":"MRI-80845816","staff":"group.admin","status":[],"jobrep":{"hotdog":0,"taxi":0,"trucker":0,"tow":0},"craftingrep":0,"licences":{"id":true,"driver":true,"weapon":false},"criminalrecord":{"hasRecord":false},"hunger":87.39999999999999,"ishandcuffed":false,"fingerprint":"3J68B73Y46J7Z8M","thirst":88.60000000000001,"dealerrep":0}', '[{"metadata":{"registered":"TiãO Dev","components":[],"durability":99.9,"serial":"876638FQS652719","ammo":-1},"slot":1,"name":"WEAPON_PUMPSHOTGUN","count":1},{"metadata":{"nationality":"Brasileiro","lastname":"Dev","sex":"M","cardtype":"id_card","firstname":"TiãO","birthdate":"Invalid Date","badge":"none","mugShot":"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAAAXNSR0IArs4c6QAADctJREFUeF7tm99v29YVx78WRfpKtGipihmrdtVozZK5c7qlewjSFgjaPRQoMGDIMKDt6/63YcCADn3ZS4sU2Ioa3bAabdMazVI4de3KUayIpkzrijTl4dwfFKk4XSMpTYDmAAYlSqR4Pvd7zr333OsZAMf4CdvMEwBPFPAkBJ7kgJ9wDsSTJPgoegF3zsbqoquExxMBXt/toHUwfP9jKPNHU8DqYhVvXjwPxth9/Qr6HOExsLG7h41mGxu77YfO4KED0I5rT+KZ3IhTA/HenpVgOnyogHfWv3roEB4agJXTVVx94TwK+ay/fhiPAAgVgII4kgLSxo+AG7f38NXtNm7cnr4ipg6AHCcj58lOAhCE0mlpHLbFEISy5ctzlXsA0ImHBWGqAFaeX8WKHWO5aKNkWcKR6DDtLNBBlHHQyo2ExJH8nOVN+b2Ugtb2PHz0+eaIgiZ7OzUAwvnnV7F852bmidiRfBsahmpvGQJxHGEwCJGDBKXNgvycH0lwsWmhOmui3Y/Q7ocIrAo2v93G5vbOZJ6rq6cCgBy/+oc3sbFxHc53G3BME34kW9KdMRPnhWPKQQIgbABER8O8YCCrGAKQNmPpnHD+2trHjxcAgkBGANJWzjNEqvX1+TgOhQLIIpUUwwQCRyFvoqdCwSrYmfttHdtoLC8JANNQwcQKaCzXcHF1FbutlnjQ54zeUM7MRi5XgGVl+/4w1dUFvKNASCBOTsU+ICAMUt1mzjCwlWOoP13D1ndNfPif9YlVMBGApfoSnj11CouuOxaAiPcQgiMKh4nRlMOCxNIA6OS2OVTEYwHg91euYP2LL5IHPnPsw1AZ3FIKSDtEatAKSAOIIhn7OQWAqdiPUkAMI5cAmJYKJlLAyoUVvPbri/cAIEc0BCPVYmHEYWEYDgTiMA6E42FKBWlgLC+/b6g80mQl8f6xAHDp8itYPeOi+e+15JmdVLybJoPBskksPpIDHmpxctqAgYBLCMLR1LggHgxA3zbzJqy8BdM0EahxQaAGTB/+86OJ8sBECrj6x7eBbz4DvzscolJ7kczJebLYYrBycgwgHYyF41rycThApPp88YVjIDdjIBrIkAgGAwGAjCCEBflaA1j/5FMEwRDgg9IYG8DSch2kgO8DQCDilPMagH5grYBRAPHxcFwQpq5PA9AQrn/+JTzPe1C/k+9PDICvf5D58bQCCEDOtGCp+A3jGLwfJK1PAJhSigyLCPFRnLQ+ndMAyHnxvmDC7kqHW7UGHlkILNXruPTyK4g++1cGQNwPUS45yblKWRc+5Cl+IPt9sk43ADOH4SE+72ULIl0VCnpu0S06CNSY48yrr+L9995Ha1eOQcaxsRVAzhMEAuBHIRzTQsky4XWDBEBlzgFUFqeHa3sd2HnpuDYC0A4CVG1bHCM1AtSfG3k5WdIAdlMVIwLw7t/eRXDwKHJAvY7lZ+pgd7bEAxIAMlJA2qKjbAvH6YRHGd6SALTFaq6g32vpO7Mq+YXDgQEBWFtbw+bN8WeIYyuAHvDqW29jc+0DOJaZAeAd+IlDI4pOzlfmZPfoRzwDID39pc9pHODMSrgEIUgBsF0X733y6TjKT64ZG8C5nzXwu9++hubNDdz675ewSe4A9lLO2/MVeF0Z08FdGft6GFSdl4UPywA6QQ9eoGL//iVDsDkblZwFVmAiV4hjX1730a3mWCAmAnC+0UBpwO8BQI5r0wA0BPKPnD81XxbHzZ1NAUDboCpB+q0WHNdFeCjDg6s4p9llpTq8/3ZHgr3RGq8rHBsA/SgpgO9kCyC91NQ32O8gyhVgV8qwn6qg9fUmyjGE82QEoNNpwjvkCQQCUFpw0b0jMzsBoJbXABiPBQCtAALQDiiMxiunTwSAwuBZK1vkJADkeOPCi+K4s72bAKAwqKUqYmkAWgFtZmLpl6tCAQSBRsaFko1OsyUg1JxKEgK9wx6CHB4NgKrNcH6hAhxJ+ZZtmdT4vpRseV5KeWCwZKhq2zaKhFxZYdZCEPgIojhJbsyRkx1m2+BBgOCgK0PiUP5OZd4Bm7XA+6E4bt3eQ+uQo3W/bDv8uRNfTaSAl87UEgBnXDng4SNS3G0PewTXdQUA3o/AZk0QAEQBgjAWEMiClKAIgFksCOedYgFOgSFWIeb5EjTllGvb4yVAun5iAOXZHLwgAAGoUKv1pcY7+9LxLpceidYnlaikJlrTsdFOTaToXEt9XzdXfDwQjpOVikzMDuk3SAHC+tGjA0BhcGlZrgNQCBAAxuQCh7avd/bES+E82QgAfuAJBWjzDSakT38UBgSAjCAQAE85TxDKji1C4Hp7vB5gYgXQOt+VugRAdrbqIM7LLsqeK6O1uwljxoCpCptRL4Ctu7VZht4sQ6HH0UsXQ2Zi8KMYHlfZMheDmSZ0hYjuvZMaSm/t+2hOsKA6UQjQw7x+bulEAHQyOOiAFR1YRVt0ZwTAiGOwPgc/AUDBMtGLuABAJo7ZkTTaGoz61Y93xp8ITawA3erPVWXmJnPt4UzQnqvAYCxxniAU1CIotT4ZKaBDcldzCR5n5xL8OAaPInC1nBYbw3WCbT/IqCF5iAd4MbECRiHYAxmzbq0hjvEgFi1Pzgsl5E0U+hwd6s/7PfA9WU3iOgzU7I/l1UqSKo5QohX3UwCm4fxUFKBhv3FWOkzGbAfMLqFgOwhjju7tJvzbsqvqqJqg/q7hZBdDaV2Aez5Y2QGrOGA9miKHCI8iceR5mWTHHfuPimMqCqCbngSAzhvMEgDICMIoAI8DVXcIwfJ7wnkBMgWA3hOErkoKjz0ATXqg5v+l0zV5So0Q6WXr1k20221UF+TcQAAbGOCd4eDJzqfqgwrA3mFv7MnPQ1NAbc7GRbXvh0KAB9IJ7nXgnK6BADinF8EWJYjWra/FMebZLE6rZhQCGoIphj5UEZYFkfbRAF/dkROgadjUQsAt2VhdcoFjA8wyRVLjUYiO72P1hRfhnl6UzzsnY7jT3JbvYznW10Y7Qrr7Pnw1kjRSy+fivl3v8QZAVV7tPA1wnPky3NO1BECnO1xD8L7bgZGSuFAMDJTmnQSCBtCLQjnU7npTS4D0e1NTAN3stV80hAK0Uf+uAehzgZeVPAHw1VDWqZbR2qdrVFFk34dt2WKckFx/4E8t/qcOgELAVaUxkmuz4wkAaYva2ZlbL7VULhSgttFpCASA7qNtY4KZ30k5Y6oKoB84d+Ys3JocHreaOzDUup+tqrqR2gVGRY+ND66BzbFkAsV5D1axgDCUc3/LKoDNVxF0h73C9VuyCj0tmzqAMmNwF5cFBALgHIewZy0QgKAfIS6VRa2PKj5kg/02tAoK1PpqHSE4lK2uAQQHPho/fx4dMOx+u4nm9vil8DS8hwZA/0jNok2Qqqbfj+DxUNT8yKjkFR4OW1e0ejE7ndaVIKo6u7VlsOUVce362rWpQJgqgJULF7FydgXX14fLZScB0HCECkY2UlJIkPST76hS2CiAaUGYGoCLL7+GWr0BdtDB5vpwv0ChKOfyNCYg69zNtvjocMYuZneF0aZKRyVWut594SWEgxi2aSKKB3jvnb9MlA4mBkBOLz7TEM43tzbReKqM1q0b4qGCThujAHKiLD6cMhdpD2Bqbc9TBZNAbbNLAyiVHBQaqwiiELZpSRAlB+v/uIbmN+PlhIkALJ05i19dvpK0gAYQeG2IvxQAkdAsE9aMgWoKQI/LjK8h0BI5OUgAtPPkuLZRAP7dNmrPNsaGMDYAcv7Sq6+Dp/pxAuBSE1Pre3LEF3TbYgSXBpDWLI3w0pYGQDLnMwY0AAqFaKEuWp52ndBRAxA5YQwljA1Axzz13VS4NGZyCGn763EMt7WJourG2rGBQFVwqTs0VI+gnR7dD8B5iN7RAIV8DlQUKadqYhGNCernEEYRLNNEHA8AtcnaLhXFLf/+1z8/UE4YC4B2XrRwL7s2H8VhBgDPM9H/awgY2TUaZXaO05xfVpROAkDOEwRynLbMaQBRP4Q5a8GyTMRRjOvrH6O1+8P2Ej8wAEp2BCDpptS0l94bOQP3A0Bjgc07HgZqJOirBVGbWQj4MAxq5eGusjKzoDdb0/29C5el08qo3GZQpUgpjCCQErXzreb2/wXxwADeeOtPGYn5gS9kTzu7LMMEP+KwAw8Ld2RWJgVoIyVQCPgBx06rA8cuII5jAYBA2MwUgtf1QDqOAiD5axvEMZDKQRoAfa4hxL0t7Ox04Ktl+tH4eCAAq795BW69LlpB0KcdXMcQG5vILEYAAPuwjYW7sis8HBgwjZzosylpxRHtCwwRJOXt1N5iy4KtdoURDNM0sGnJdYfKvDzy2ey+wzBM7TE0LNiGHHW2duTvO4b8fK8T4Mate0voPwiA+3Qdbq0OOsYz0nlttPChARh5AxHknh63fQPFXhvRzHDzM0Ho9ZFIniBYqdVl2ghpq8VTK28kAMj58nwV3n4bvgoh2oYb8gAxIhhqg7UxAiDw2zAR41RlCI1AtD35R/a9ABp1F/bCOenQ03VxDI+lBEl+tHt7ZEsPBqp0pVVwEgC6Pol7I7u8PgrAWziXON/Zb8NwhitRdB8NgJw3DDPZgULOkwoIQNo0DAJxXwDkeHleUossObXVANIKEBBS3dSAQiH1b3ECgi+nrxHFKz2wKpgEPfX/AuoBwyiEZVowVRFVKwBnL4uWJ+fpyEplUOuTmczOAKBzOgTo9ebG2j0ANAwN4n9mFylS2li8KQAAAABJRU5ErkJggg==","citizenid":"ZDQ8H6H9"},"slot":2,"name":"id_card","count":1},{"metadata":{"nationality":"Brasileiro","firstname":"TiãO","birthdate":"Invalid Date","badge":"none","sex":"M","cardtype":"id_card","lastname":"Dev","citizenid":"ZDQ8H6H9"},"slot":3,"name":"id_card","count":1},{"slot":4,"name":"money","count":4019},{"slot":5,"name":"lockpick","count":1},{"slot":6,"name":"advancedlockpick","count":2},{"metadata":{"plate":"25ATH606","label":"CHAVE-25ATH606"},"slot":7,"name":"vehiclekey","count":1},{"metadata":{"name":"TiãO Dev","radioId":"ZDQ8H6H96739"},"slot":8,"name":"radio","count":1},{"metadata":{"nationality":"Brasileiro","lastname":"Dev","sex":"M","cardtype":"id_card","firstname":"TiãO","birthdate":"Invalid Date","badge":"none","mugShot":"data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAEAAAABACAYAAACqaXHeAAAAAXNSR0IArs4c6QAADctJREFUeF7tm99v29YVx78WRfpKtGipihmrdtVozZK5c7qlewjSFgjaPRQoMGDIMKDt6/63YcCADn3ZS4sU2Ioa3bAabdMazVI4de3KUayIpkzrijTl4dwfFKk4XSMpTYDmAAYlSqR4Pvd7zr333OsZAMf4CdvMEwBPFPAkBJ7kgJ9wDsSTJPgoegF3zsbqoquExxMBXt/toHUwfP9jKPNHU8DqYhVvXjwPxth9/Qr6HOExsLG7h41mGxu77YfO4KED0I5rT+KZ3IhTA/HenpVgOnyogHfWv3roEB4agJXTVVx94TwK+ay/fhiPAAgVgII4kgLSxo+AG7f38NXtNm7cnr4ipg6AHCcj58lOAhCE0mlpHLbFEISy5ctzlXsA0ImHBWGqAFaeX8WKHWO5aKNkWcKR6DDtLNBBlHHQyo2ExJH8nOVN+b2Ugtb2PHz0+eaIgiZ7OzUAwvnnV7F852bmidiRfBsahmpvGQJxHGEwCJGDBKXNgvycH0lwsWmhOmui3Y/Q7ocIrAo2v93G5vbOZJ6rq6cCgBy/+oc3sbFxHc53G3BME34kW9KdMRPnhWPKQQIgbABER8O8YCCrGAKQNmPpnHD+2trHjxcAgkBGANJWzjNEqvX1+TgOhQLIIpUUwwQCRyFvoqdCwSrYmfttHdtoLC8JANNQwcQKaCzXcHF1FbutlnjQ54zeUM7MRi5XgGVl+/4w1dUFvKNASCBOTsU+ICAMUt1mzjCwlWOoP13D1ndNfPif9YlVMBGApfoSnj11CouuOxaAiPcQgiMKh4nRlMOCxNIA6OS2OVTEYwHg91euYP2LL5IHPnPsw1AZ3FIKSDtEatAKSAOIIhn7OQWAqdiPUkAMI5cAmJYKJlLAyoUVvPbri/cAIEc0BCPVYmHEYWEYDgTiMA6E42FKBWlgLC+/b6g80mQl8f6xAHDp8itYPeOi+e+15JmdVLybJoPBskksPpIDHmpxctqAgYBLCMLR1LggHgxA3zbzJqy8BdM0EahxQaAGTB/+86OJ8sBECrj6x7eBbz4DvzscolJ7kczJebLYYrBycgwgHYyF41rycThApPp88YVjIDdjIBrIkAgGAwGAjCCEBflaA1j/5FMEwRDgg9IYG8DSch2kgO8DQCDilPMagH5grYBRAPHxcFwQpq5PA9AQrn/+JTzPe1C/k+9PDICvf5D58bQCCEDOtGCp+A3jGLwfJK1PAJhSigyLCPFRnLQ+ndMAyHnxvmDC7kqHW7UGHlkILNXruPTyK4g++1cGQNwPUS45yblKWRc+5Cl+IPt9sk43ADOH4SE+72ULIl0VCnpu0S06CNSY48yrr+L9995Ha1eOQcaxsRVAzhMEAuBHIRzTQsky4XWDBEBlzgFUFqeHa3sd2HnpuDYC0A4CVG1bHCM1AtSfG3k5WdIAdlMVIwLw7t/eRXDwKHJAvY7lZ+pgd7bEAxIAMlJA2qKjbAvH6YRHGd6SALTFaq6g32vpO7Mq+YXDgQEBWFtbw+bN8WeIYyuAHvDqW29jc+0DOJaZAeAd+IlDI4pOzlfmZPfoRzwDID39pc9pHODMSrgEIUgBsF0X733y6TjKT64ZG8C5nzXwu9++hubNDdz675ewSe4A9lLO2/MVeF0Z08FdGft6GFSdl4UPywA6QQ9eoGL//iVDsDkblZwFVmAiV4hjX1730a3mWCAmAnC+0UBpwO8BQI5r0wA0BPKPnD81XxbHzZ1NAUDboCpB+q0WHNdFeCjDg6s4p9llpTq8/3ZHgr3RGq8rHBsA/SgpgO9kCyC91NQ32O8gyhVgV8qwn6qg9fUmyjGE82QEoNNpwjvkCQQCUFpw0b0jMzsBoJbXABiPBQCtAALQDiiMxiunTwSAwuBZK1vkJADkeOPCi+K4s72bAKAwqKUqYmkAWgFtZmLpl6tCAQSBRsaFko1OsyUg1JxKEgK9wx6CHB4NgKrNcH6hAhxJ+ZZtmdT4vpRseV5KeWCwZKhq2zaKhFxZYdZCEPgIojhJbsyRkx1m2+BBgOCgK0PiUP5OZd4Bm7XA+6E4bt3eQ+uQo3W/bDv8uRNfTaSAl87UEgBnXDng4SNS3G0PewTXdQUA3o/AZk0QAEQBgjAWEMiClKAIgFksCOedYgFOgSFWIeb5EjTllGvb4yVAun5iAOXZHLwgAAGoUKv1pcY7+9LxLpceidYnlaikJlrTsdFOTaToXEt9XzdXfDwQjpOVikzMDuk3SAHC+tGjA0BhcGlZrgNQCBAAxuQCh7avd/bES+E82QgAfuAJBWjzDSakT38UBgSAjCAQAE85TxDKji1C4Hp7vB5gYgXQOt+VugRAdrbqIM7LLsqeK6O1uwljxoCpCptRL4Ctu7VZht4sQ6HH0UsXQ2Zi8KMYHlfZMheDmSZ0hYjuvZMaSm/t+2hOsKA6UQjQw7x+bulEAHQyOOiAFR1YRVt0ZwTAiGOwPgc/AUDBMtGLuABAJo7ZkTTaGoz61Y93xp8ITawA3erPVWXmJnPt4UzQnqvAYCxxniAU1CIotT4ZKaBDcldzCR5n5xL8OAaPInC1nBYbw3WCbT/IqCF5iAd4MbECRiHYAxmzbq0hjvEgFi1Pzgsl5E0U+hwd6s/7PfA9WU3iOgzU7I/l1UqSKo5QohX3UwCm4fxUFKBhv3FWOkzGbAfMLqFgOwhjju7tJvzbsqvqqJqg/q7hZBdDaV2Aez5Y2QGrOGA9miKHCI8iceR5mWTHHfuPimMqCqCbngSAzhvMEgDICMIoAI8DVXcIwfJ7wnkBMgWA3hOErkoKjz0ATXqg5v+l0zV5So0Q6WXr1k20221UF+TcQAAbGOCd4eDJzqfqgwrA3mFv7MnPQ1NAbc7GRbXvh0KAB9IJ7nXgnK6BADinF8EWJYjWra/FMebZLE6rZhQCGoIphj5UEZYFkfbRAF/dkROgadjUQsAt2VhdcoFjA8wyRVLjUYiO72P1hRfhnl6UzzsnY7jT3JbvYznW10Y7Qrr7Pnw1kjRSy+fivl3v8QZAVV7tPA1wnPky3NO1BECnO1xD8L7bgZGSuFAMDJTmnQSCBtCLQjnU7npTS4D0e1NTAN3stV80hAK0Uf+uAehzgZeVPAHw1VDWqZbR2qdrVFFk34dt2WKckFx/4E8t/qcOgELAVaUxkmuz4wkAaYva2ZlbL7VULhSgttFpCASA7qNtY4KZ30k5Y6oKoB84d+Ys3JocHreaOzDUup+tqrqR2gVGRY+ND66BzbFkAsV5D1axgDCUc3/LKoDNVxF0h73C9VuyCj0tmzqAMmNwF5cFBALgHIewZy0QgKAfIS6VRa2PKj5kg/02tAoK1PpqHSE4lK2uAQQHPho/fx4dMOx+u4nm9vil8DS8hwZA/0jNok2Qqqbfj+DxUNT8yKjkFR4OW1e0ejE7ndaVIKo6u7VlsOUVce362rWpQJgqgJULF7FydgXX14fLZScB0HCECkY2UlJIkPST76hS2CiAaUGYGoCLL7+GWr0BdtDB5vpwv0ChKOfyNCYg69zNtvjocMYuZneF0aZKRyVWut594SWEgxi2aSKKB3jvnb9MlA4mBkBOLz7TEM43tzbReKqM1q0b4qGCThujAHKiLD6cMhdpD2Bqbc9TBZNAbbNLAyiVHBQaqwiiELZpSRAlB+v/uIbmN+PlhIkALJ05i19dvpK0gAYQeG2IvxQAkdAsE9aMgWoKQI/LjK8h0BI5OUgAtPPkuLZRAP7dNmrPNsaGMDYAcv7Sq6+Dp/pxAuBSE1Pre3LEF3TbYgSXBpDWLI3w0pYGQDLnMwY0AAqFaKEuWp52ndBRAxA5YQwljA1Axzz13VS4NGZyCGn763EMt7WJourG2rGBQFVwqTs0VI+gnR7dD8B5iN7RAIV8DlQUKadqYhGNCernEEYRLNNEHA8AtcnaLhXFLf/+1z8/UE4YC4B2XrRwL7s2H8VhBgDPM9H/awgY2TUaZXaO05xfVpROAkDOEwRynLbMaQBRP4Q5a8GyTMRRjOvrH6O1+8P2Ej8wAEp2BCDpptS0l94bOQP3A0Bjgc07HgZqJOirBVGbWQj4MAxq5eGusjKzoDdb0/29C5el08qo3GZQpUgpjCCQErXzreb2/wXxwADeeOtPGYn5gS9kTzu7LMMEP+KwAw8Ld2RWJgVoIyVQCPgBx06rA8cuII5jAYBA2MwUgtf1QDqOAiD5axvEMZDKQRoAfa4hxL0t7Ox04Ktl+tH4eCAAq795BW69LlpB0KcdXMcQG5vILEYAAPuwjYW7sis8HBgwjZzosylpxRHtCwwRJOXt1N5iy4KtdoURDNM0sGnJdYfKvDzy2ey+wzBM7TE0LNiGHHW2duTvO4b8fK8T4Mate0voPwiA+3Qdbq0OOsYz0nlttPChARh5AxHknh63fQPFXhvRzHDzM0Ho9ZFIniBYqdVl2ghpq8VTK28kAMj58nwV3n4bvgoh2oYb8gAxIhhqg7UxAiDw2zAR41RlCI1AtD35R/a9ABp1F/bCOenQ03VxDI+lBEl+tHt7ZEsPBqp0pVVwEgC6Pol7I7u8PgrAWziXON/Zb8NwhitRdB8NgJw3DDPZgULOkwoIQNo0DAJxXwDkeHleUossObXVANIKEBBS3dSAQiH1b3ECgi+nrxHFKz2wKpgEPfX/AuoBwyiEZVowVRFVKwBnL4uWJ+fpyEplUOuTmczOAKBzOgTo9ebG2j0ANAwN4n9mFylS2li8KQAAAABJRU5ErkJggg==","citizenid":"ZDQ8H6H9"},"slot":9,"name":"id_card","count":1},{"metadata":{"image":"casing-ammo-shotgun","label":"Casing from 12 Gauge","weight":4},"slot":10,"name":"casing","count":1},{"slot":11,"name":"engine_upgrade_v8","count":1},{"metadata":{"registered":"TiãO Dev","components":[],"durability":100,"serial":"957009TVM341498","ammo":0},"slot":12,"name":"WEAPON_TACTICALRIFLE","count":1},{"slot":13,"name":"metalscrap","count":1}]', '6522731956', '2026-03-25 15:01:46', '2026-03-25 22:10:11', '{"lockpicking":0,"searching":0,"cityworker":0,"busdriver":0,"cooking":0,"crafting":0,"taxi":5,"trucker":0,"garbage":0,"areaexample":0,"cargo":5,"hunting":0,"hotwiring":0,"mining":0,"fishing":0}');

-- Dumping structure for table republica.playerskins
CREATE TABLE IF NOT EXISTS `playerskins` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` varchar(255) NOT NULL,
  `model` varchar(255) NOT NULL,
  `skin` text NOT NULL,
  `active` tinyint(4) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `citizenid` (`citizenid`),
  KEY `active` (`active`)
) ENGINE=InnoDB AUTO_INCREMENT=14 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.playerskins: ~12 rows (approximately)
INSERT INTO `playerskins` (`id`, `citizenid`, `model`, `skin`, `active`) VALUES
	(1, 'ZDQ8H6H9', 'a_m_m_golfer_01', '{"headOverlays":{"complexion":{"color":0,"style":0,"secondColor":0,"opacity":0},"bodyBlemishes":{"color":0,"style":0,"secondColor":0,"opacity":0},"lipstick":{"color":0,"style":0,"secondColor":0,"opacity":0},"blush":{"color":0,"style":0,"secondColor":0,"opacity":0},"beard":{"color":0,"style":0,"secondColor":0,"opacity":0},"moleAndFreckles":{"color":0,"style":0,"secondColor":0,"opacity":0},"makeUp":{"color":0,"style":0,"secondColor":0,"opacity":0},"chestHair":{"color":0,"style":0,"secondColor":0,"opacity":0},"blemishes":{"color":0,"style":0,"secondColor":0,"opacity":0},"sunDamage":{"color":0,"style":0,"secondColor":0,"opacity":0},"eyebrows":{"color":0,"style":0,"secondColor":0,"opacity":0},"ageing":{"color":0,"style":0,"secondColor":0,"opacity":0}},"hair":{"color":-1,"style":0,"texture":0,"highlight":-1},"components":[{"texture":0,"component_id":0,"drawable":1,"localDrawable":1},{"texture":0,"component_id":1,"drawable":0,"localDrawable":0},{"texture":0,"component_id":2,"drawable":0,"localDrawable":0},{"texture":0,"component_id":3,"drawable":1,"localDrawable":1},{"texture":0,"component_id":4,"drawable":0,"localDrawable":0},{"texture":0,"component_id":5,"drawable":0,"localDrawable":0},{"texture":0,"component_id":6,"drawable":0,"localDrawable":0},{"texture":0,"component_id":7,"drawable":0,"localDrawable":0},{"texture":0,"component_id":8,"drawable":0,"localDrawable":0},{"texture":0,"component_id":9,"drawable":0,"localDrawable":0},{"texture":0,"component_id":10,"drawable":0,"localDrawable":0},{"texture":0,"component_id":11,"drawable":0,"localDrawable":0}],"eyeColor":-1,"tattoos":[],"headBlend":{"shapeSecond":0,"shapeThird":0,"thirdMix":0,"skinFirst":0,"skinSecond":0,"skinThird":0,"skinMix":0,"shapeMix":0,"shapeFirst":0},"model":"a_m_m_golfer_01","props":[{"prop_id":0,"texture":-1,"drawable":-1,"localDrawable":-1},{"prop_id":1,"texture":-1,"drawable":-1,"localDrawable":-1},{"prop_id":2,"texture":-1,"drawable":-1,"localDrawable":-1},{"prop_id":6,"texture":-1,"drawable":-1,"localDrawable":-1},{"prop_id":7,"texture":-1,"drawable":-1,"localDrawable":-1}],"faceFeatures":{"jawBoneBackSize":0,"cheeksBoneHigh":0,"chinBoneLowering":0,"eyesOpening":0,"noseWidth":0,"eyeBrownForward":0,"chinBoneLenght":0,"jawBoneWidth":0,"noseBoneTwist":0,"nosePeakSize":0,"neckThickness":0,"eyeBrownHigh":0,"chinHole":0,"chinBoneSize":0,"noseBoneHigh":0,"cheeksWidth":0,"cheeksBoneWidth":0,"nosePeakHigh":0,"lipsThickness":0,"nosePeakLowering":0}}', 1),
	(3, 'RVA69WB5', 'mp_m_freemode_01', '{"hair":{"highlight":0,"style":0,"texture":0,"color":0},"eyeColor":-1,"props":[{"drawable":-1,"texture":-1,"prop_id":1},{"drawable":-1,"texture":-1,"prop_id":2},{"drawable":-1,"texture":-1,"prop_id":6},{"drawable":-1,"texture":-1,"prop_id":7},{"drawable":23,"texture":0,"prop_id":0}],"headOverlays":{"moleAndFreckles":{"color":0,"secondColor":0,"opacity":0,"style":0},"sunDamage":{"color":0,"secondColor":0,"opacity":0,"style":0},"blush":{"color":0,"secondColor":0,"opacity":0,"style":0},"eyebrows":{"color":0,"secondColor":0,"opacity":0,"style":0},"ageing":{"color":0,"secondColor":0,"opacity":0,"style":0},"complexion":{"color":0,"secondColor":0,"opacity":0,"style":0},"makeUp":{"color":0,"secondColor":0,"opacity":0,"style":0},"bodyBlemishes":{"color":0,"secondColor":0,"opacity":0,"style":0},"lipstick":{"color":0,"secondColor":0,"opacity":0,"style":0},"beard":{"color":0,"secondColor":0,"opacity":0,"style":0},"chestHair":{"color":0,"secondColor":0,"opacity":0,"style":0},"blemishes":{"color":0,"secondColor":0,"opacity":0,"style":0}},"components":[{"component_id":0,"texture":0,"drawable":0},{"component_id":2,"texture":0,"drawable":0},{"component_id":3,"texture":0,"drawable":0},{"component_id":5,"texture":0,"drawable":0},{"component_id":6,"texture":0,"drawable":0},{"component_id":7,"texture":0,"drawable":0},{"component_id":10,"texture":0,"drawable":0},{"component_id":1,"texture":0,"drawable":191},{"component_id":11,"texture":0,"drawable":468},{"component_id":8,"texture":0,"drawable":15},{"component_id":9,"texture":0,"drawable":58},{"component_id":4,"texture":0,"drawable":174}],"tattoos":{"ZONE_LEFT_ARM":[{"hashMale":"MP_MP_ImportExport_Tat_008_M","name":"TAT_IE_008","collection":"mpimportexport_overlays","hashFemale":"MP_MP_ImportExport_Tat_008_F","zone":"ZONE_LEFT_ARM","label":"Scarlett","opacity":0.6}]},"model":"mp_m_freemode_01","faceFeatures":{"cheeksBoneHigh":0,"chinBoneLenght":0,"nosePeakLowering":0,"noseBoneTwist":0,"chinBoneLowering":0,"cheeksWidth":0,"jawBoneBackSize":0,"eyeBrownHigh":0,"neckThickness":0,"lipsThickness":0,"chinBoneSize":0,"eyeBrownForward":0,"nosePeakHigh":0,"nosePeakSize":0,"jawBoneWidth":0,"eyesOpening":0,"cheeksBoneWidth":0,"noseBoneHigh":0,"chinHole":0,"noseWidth":0},"headBlend":{"shapeThird":0,"shapeFirst":0,"shapeSecond":0,"skinMix":0,"skinThird":0,"skinFirst":0,"shapeMix":0,"skinSecond":0,"thirdMix":0}}', 1),
	(4, 'JTW7MEXP', 's_f_y_stripperlite', '{"hair":{"highlight":-1,"color":-1,"style":0,"texture":0},"eyeColor":-1,"props":[{"drawable":-1,"texture":-1,"prop_id":6},{"drawable":-1,"texture":-1,"prop_id":7},{"drawable":-1,"texture":0,"prop_id":0},{"drawable":-1,"texture":0,"prop_id":1},{"drawable":-1,"texture":0,"prop_id":2}],"headOverlays":{"moleAndFreckles":{"secondColor":0,"color":0,"opacity":0,"style":0},"sunDamage":{"secondColor":0,"color":0,"opacity":0,"style":0},"makeUp":{"secondColor":0,"color":0,"opacity":0,"style":0},"lipstick":{"secondColor":0,"color":0,"opacity":0,"style":0},"ageing":{"secondColor":0,"color":0,"opacity":0,"style":0},"blemishes":{"secondColor":0,"color":0,"opacity":0,"style":0},"blush":{"secondColor":0,"color":0,"opacity":0,"style":0},"bodyBlemishes":{"secondColor":0,"color":0,"opacity":0,"style":0},"beard":{"secondColor":0,"color":0,"opacity":0,"style":0},"complexion":{"secondColor":0,"color":0,"opacity":0,"style":0},"chestHair":{"secondColor":0,"color":0,"opacity":0,"style":0},"eyebrows":{"secondColor":0,"color":0,"opacity":0,"style":0}},"tattoos":[],"components":[{"drawable":0,"texture":0,"component_id":2},{"drawable":0,"texture":0,"component_id":3},{"drawable":0,"texture":0,"component_id":5},{"drawable":0,"texture":0,"component_id":11},{"drawable":-1,"texture":0,"component_id":1},{"drawable":0,"texture":0,"component_id":7},{"drawable":1,"texture":0,"component_id":8},{"drawable":0,"texture":0,"component_id":9},{"drawable":0,"texture":0,"component_id":4},{"drawable":0,"texture":0,"component_id":6},{"drawable":0,"texture":0,"component_id":10},{"drawable":0,"texture":0,"component_id":0}],"model":"s_f_y_stripperlite","faceFeatures":{"nosePeakSize":0,"chinBoneLenght":0,"nosePeakLowering":0,"noseBoneTwist":0,"chinBoneLowering":0,"cheeksWidth":0,"noseBoneHigh":0,"eyeBrownHigh":0,"cheeksBoneHigh":0,"lipsThickness":0,"chinBoneSize":0,"eyeBrownForward":0,"chinHole":0,"neckThickness":0,"jawBoneWidth":0,"eyesOpening":0,"cheeksBoneWidth":0,"noseWidth":0,"nosePeakHigh":0,"jawBoneBackSize":0},"headBlend":{"shapeThird":0,"shapeFirst":0,"shapeSecond":0,"skinMix":0,"skinThird":0,"skinFirst":0,"shapeMix":0,"skinSecond":0,"thirdMix":0}}', 1),
	(5, 'YMZ956SW', 'mp_f_freemode_01', '{"components":[{"component_id":0,"texture":0,"drawable":0},{"component_id":1,"texture":0,"drawable":0},{"component_id":2,"texture":0,"drawable":0},{"component_id":3,"texture":0,"drawable":0},{"component_id":4,"texture":0,"drawable":0},{"component_id":5,"texture":0,"drawable":0},{"component_id":6,"texture":0,"drawable":0},{"component_id":7,"texture":0,"drawable":0},{"component_id":8,"texture":0,"drawable":0},{"component_id":9,"texture":0,"drawable":0},{"component_id":10,"texture":0,"drawable":0},{"component_id":11,"texture":0,"drawable":0}],"model":"mp_f_freemode_01","headOverlays":{"bodyBlemishes":{"style":0,"opacity":0,"secondColor":0,"color":0},"moleAndFreckles":{"style":0,"opacity":0,"secondColor":0,"color":0},"makeUp":{"style":16,"opacity":0,"secondColor":24,"color":0},"eyebrows":{"style":0,"opacity":0,"secondColor":0,"color":0},"ageing":{"style":0,"opacity":0,"secondColor":0,"color":0},"blemishes":{"style":0,"opacity":0,"secondColor":0,"color":0},"chestHair":{"style":0,"opacity":0,"secondColor":0,"color":0},"complexion":{"style":0,"opacity":0,"secondColor":0,"color":0},"lipstick":{"style":0,"opacity":0,"secondColor":0,"color":0},"sunDamage":{"style":0,"opacity":0,"secondColor":0,"color":0},"blush":{"style":0,"opacity":0,"secondColor":0,"color":0},"beard":{"style":0,"opacity":0,"secondColor":0,"color":0}},"tattoos":{"ZONE_HAIR":[]},"headBlend":{"skinThird":32,"shapeThird":18,"shapeMix":0.9,"shapeFirst":25,"thirdMix":0,"skinMix":0,"skinSecond":15,"shapeSecond":19,"skinFirst":25},"hair":{"style":31,"highlight":26,"texture":0,"color":37},"props":[{"prop_id":6,"texture":-1,"drawable":-1},{"prop_id":7,"texture":-1,"drawable":-1},{"prop_id":0,"texture":1,"drawable":22},{"prop_id":1,"texture":0,"drawable":4},{"prop_id":2,"texture":0,"drawable":3}],"eyeColor":11,"faceFeatures":{"nosePeakHigh":0,"chinBoneSize":-0.4,"eyeBrownHigh":0,"nosePeakLowering":0,"cheeksBoneWidth":0,"chinBoneLowering":-0.4,"cheeksWidth":0,"chinBoneLenght":-0.4,"noseWidth":0,"neckThickness":-0.7,"noseBoneHigh":0,"jawBoneWidth":0,"noseBoneTwist":0,"chinHole":-0.4,"jawBoneBackSize":0,"nosePeakSize":0,"eyesOpening":0.2,"cheeksBoneHigh":0,"eyeBrownForward":0,"lipsThickness":0}}', 1),
	(6, 'C26NAK2R', 'mp_f_freemode_01', '{"tattoos":{"ZONE_HAIR":[]},"hair":{"texture":0,"style":36,"highlight":0,"color":44},"headOverlays":{"blush":{"secondColor":0,"style":0,"opacity":0,"color":0},"sunDamage":{"secondColor":0,"style":0,"opacity":0,"color":0},"beard":{"secondColor":0,"style":0,"opacity":0,"color":0},"complexion":{"secondColor":0,"style":0,"opacity":0,"color":0},"blemishes":{"secondColor":0,"style":0,"opacity":0,"color":0},"moleAndFreckles":{"secondColor":0,"style":0,"opacity":0,"color":0},"makeUp":{"secondColor":0,"style":0,"opacity":0,"color":0},"bodyBlemishes":{"secondColor":0,"style":0,"opacity":0,"color":0},"lipstick":{"secondColor":0,"style":0,"opacity":0,"color":0},"chestHair":{"secondColor":0,"style":0,"opacity":0,"color":0},"eyebrows":{"secondColor":0,"style":0,"opacity":0,"color":0},"ageing":{"secondColor":0,"style":0,"opacity":0,"color":0}},"headBlend":{"skinThird":0,"skinFirst":20,"shapeMix":0.3,"skinSecond":15,"thirdMix":0,"skinMix":0.1,"shapeThird":0,"shapeSecond":21,"shapeFirst":45},"model":"mp_f_freemode_01","components":[{"drawable":0,"component_id":0,"texture":0},{"drawable":0,"component_id":1,"texture":0},{"drawable":0,"component_id":2,"texture":0},{"drawable":0,"component_id":3,"texture":0},{"drawable":0,"component_id":4,"texture":0},{"drawable":0,"component_id":5,"texture":0},{"drawable":0,"component_id":6,"texture":0},{"drawable":0,"component_id":7,"texture":0},{"drawable":0,"component_id":8,"texture":0},{"drawable":0,"component_id":9,"texture":0},{"drawable":0,"component_id":10,"texture":0},{"drawable":0,"component_id":11,"texture":0}],"props":[{"drawable":-1,"prop_id":0,"texture":-1},{"drawable":-1,"prop_id":1,"texture":-1},{"drawable":-1,"prop_id":2,"texture":-1},{"drawable":-1,"prop_id":6,"texture":-1},{"drawable":-1,"prop_id":7,"texture":-1}],"faceFeatures":{"jawBoneWidth":0,"eyeBrownForward":0,"cheeksBoneHigh":0,"nosePeakLowering":0,"cheeksBoneWidth":0,"nosePeakSize":0,"cheeksWidth":0,"chinBoneLenght":0,"eyeBrownHigh":0,"jawBoneBackSize":0,"neckThickness":0,"chinBoneLowering":0,"chinHole":0,"lipsThickness":0,"nosePeakHigh":0,"eyesOpening":0,"noseBoneTwist":0,"noseWidth":0,"chinBoneSize":0,"noseBoneHigh":0},"eyeColor":-1}', 1),
	(7, 'QRCMIT0E', 'mp_f_freemode_01', '{"model":"mp_f_freemode_01","headOverlays":{"blush":{"secondColor":0,"style":0,"color":0,"opacity":0},"sunDamage":{"secondColor":0,"style":0,"color":0,"opacity":0},"bodyBlemishes":{"secondColor":0,"style":0,"color":0,"opacity":0},"chestHair":{"secondColor":0,"style":0,"color":0,"opacity":0},"ageing":{"secondColor":0,"style":0,"color":0,"opacity":0},"lipstick":{"secondColor":0,"style":0,"color":0,"opacity":0},"moleAndFreckles":{"secondColor":0,"style":0,"color":0,"opacity":0},"eyebrows":{"secondColor":0,"style":0,"color":0,"opacity":0},"blemishes":{"secondColor":0,"style":0,"color":0,"opacity":0},"beard":{"secondColor":0,"style":0,"color":0,"opacity":0},"makeUp":{"secondColor":0,"style":0,"color":0,"opacity":0},"complexion":{"secondColor":0,"style":0,"color":0,"opacity":0}},"props":[{"drawable":-1,"prop_id":0,"texture":-1},{"drawable":-1,"prop_id":1,"texture":-1},{"drawable":-1,"prop_id":2,"texture":-1},{"drawable":-1,"prop_id":6,"texture":-1},{"drawable":-1,"prop_id":7,"texture":-1}],"faceFeatures":{"chinBoneLowering":0,"jawBoneWidth":0,"cheeksBoneWidth":0,"jawBoneBackSize":0,"nosePeakSize":0,"noseWidth":0,"lipsThickness":0,"eyeBrownForward":0,"cheeksWidth":0,"eyeBrownHigh":0,"nosePeakHigh":0,"cheeksBoneHigh":0,"nosePeakLowering":0,"eyesOpening":0,"noseBoneTwist":0,"noseBoneHigh":0,"chinBoneSize":0,"chinBoneLenght":0,"chinHole":0,"neckThickness":0},"components":[{"drawable":0,"component_id":0,"texture":0},{"drawable":0,"component_id":1,"texture":0},{"drawable":0,"component_id":2,"texture":0},{"drawable":0,"component_id":3,"texture":0},{"drawable":0,"component_id":4,"texture":0},{"drawable":0,"component_id":5,"texture":0},{"drawable":0,"component_id":6,"texture":0},{"drawable":0,"component_id":7,"texture":0},{"drawable":0,"component_id":8,"texture":0},{"drawable":0,"component_id":9,"texture":0},{"drawable":0,"component_id":10,"texture":0},{"drawable":0,"component_id":11,"texture":0}],"hair":{"highlight":0,"style":0,"color":0,"texture":0},"headBlend":{"skinMix":0.1,"shapeThird":0,"thirdMix":0,"shapeMix":0.3,"shapeFirst":45,"skinSecond":15,"skinFirst":20,"skinThird":0,"shapeSecond":21},"tattoos":{"ZONE_HAIR":[]},"eyeColor":-1}', 1),
	(8, 'C79HHN67', 'mp_f_freemode_01', '{"eyeColor":-1,"hair":{"texture":0,"color":0,"style":0,"highlight":0},"faceFeatures":{"noseBoneHigh":0,"nosePeakSize":0,"jawBoneBackSize":0,"nosePeakHigh":0,"chinBoneSize":0,"lipsThickness":0,"eyesOpening":0,"nosePeakLowering":0,"jawBoneWidth":0,"noseBoneTwist":0,"chinHole":0,"cheeksBoneHigh":0,"chinBoneLowering":0,"neckThickness":0,"chinBoneLenght":0,"noseWidth":0,"cheeksWidth":0,"eyeBrownHigh":0,"cheeksBoneWidth":0,"eyeBrownForward":0},"props":[{"prop_id":0,"texture":-1,"drawable":-1},{"prop_id":1,"texture":-1,"drawable":-1},{"prop_id":2,"texture":-1,"drawable":-1},{"prop_id":6,"texture":-1,"drawable":-1},{"prop_id":7,"texture":-1,"drawable":-1}],"model":"mp_f_freemode_01","headOverlays":{"blush":{"color":0,"secondColor":0,"style":0,"opacity":0},"eyebrows":{"color":0,"secondColor":0,"style":0,"opacity":0},"beard":{"color":0,"secondColor":0,"style":0,"opacity":0},"complexion":{"color":0,"secondColor":0,"style":0,"opacity":0},"ageing":{"color":0,"secondColor":0,"style":0,"opacity":0},"bodyBlemishes":{"color":0,"secondColor":0,"style":0,"opacity":0},"chestHair":{"color":0,"secondColor":0,"style":0,"opacity":0},"sunDamage":{"color":0,"secondColor":0,"style":0,"opacity":0},"blemishes":{"color":0,"secondColor":0,"style":0,"opacity":0},"makeUp":{"color":0,"secondColor":0,"style":0,"opacity":0},"lipstick":{"color":0,"secondColor":0,"style":0,"opacity":0},"moleAndFreckles":{"color":0,"secondColor":0,"style":0,"opacity":0}},"tattoos":{"ZONE_HAIR":[]},"headBlend":{"skinThird":0,"shapeMix":0.3,"thirdMix":0,"shapeSecond":21,"skinMix":0.1,"shapeThird":0,"skinSecond":15,"skinFirst":20,"shapeFirst":45},"components":[{"texture":0,"component_id":0,"drawable":0},{"texture":0,"component_id":1,"drawable":0},{"texture":0,"component_id":2,"drawable":0},{"texture":0,"component_id":3,"drawable":0},{"texture":0,"component_id":4,"drawable":0},{"texture":0,"component_id":5,"drawable":0},{"texture":0,"component_id":6,"drawable":0},{"texture":0,"component_id":7,"drawable":0},{"texture":0,"component_id":8,"drawable":0},{"texture":0,"component_id":9,"drawable":0},{"texture":0,"component_id":10,"drawable":0},{"texture":0,"component_id":11,"drawable":0}]}', 1),
	(9, 'M2R33T1T', 'mp_m_freemode_01', '{"eyeColor":-1,"props":[{"drawable":-1,"prop_id":0,"texture":-1},{"drawable":-1,"prop_id":1,"texture":-1},{"drawable":-1,"prop_id":2,"texture":-1},{"drawable":-1,"prop_id":6,"texture":-1},{"drawable":-1,"prop_id":7,"texture":-1}],"headOverlays":{"complexion":{"style":0,"secondColor":0,"color":0,"opacity":0},"ageing":{"style":0,"secondColor":0,"color":0,"opacity":0},"makeUp":{"style":0,"secondColor":0,"color":0,"opacity":0},"bodyBlemishes":{"style":0,"secondColor":0,"color":0,"opacity":0},"blush":{"style":0,"secondColor":0,"color":0,"opacity":0},"eyebrows":{"style":0,"secondColor":0,"color":0,"opacity":0},"sunDamage":{"style":0,"secondColor":0,"color":0,"opacity":0},"moleAndFreckles":{"style":0,"secondColor":0,"color":0,"opacity":0},"chestHair":{"style":0,"secondColor":0,"color":0,"opacity":0},"blemishes":{"style":0,"secondColor":0,"color":0,"opacity":0},"beard":{"style":0,"secondColor":0,"color":0,"opacity":0},"lipstick":{"style":0,"secondColor":0,"color":0,"opacity":0}},"headBlend":{"thirdMix":0,"shapeFirst":0,"skinFirst":0,"skinThird":0,"skinSecond":0,"shapeMix":0,"shapeSecond":0,"skinMix":0,"shapeThird":0},"model":"mp_m_freemode_01","tattoos":{"ZONE_HAIR":[]},"faceFeatures":{"noseBoneTwist":0,"nosePeakHigh":0,"noseWidth":0,"chinBoneSize":0,"cheeksBoneHigh":0,"neckThickness":0,"nosePeakSize":0,"cheeksWidth":0,"chinBoneLenght":0,"lipsThickness":0,"eyeBrownForward":0,"jawBoneWidth":0,"jawBoneBackSize":0,"eyesOpening":0,"noseBoneHigh":0,"eyeBrownHigh":0,"cheeksBoneWidth":0,"nosePeakLowering":0,"chinBoneLowering":0,"chinHole":0},"hair":{"style":75,"texture":0,"highlight":0,"color":35},"components":[{"component_id":0,"drawable":0,"texture":0},{"component_id":1,"drawable":0,"texture":0},{"component_id":2,"drawable":0,"texture":0},{"component_id":3,"drawable":0,"texture":0},{"component_id":5,"drawable":0,"texture":0},{"component_id":7,"drawable":0,"texture":0},{"component_id":10,"drawable":0,"texture":0},{"component_id":8,"drawable":15,"texture":0},{"component_id":11,"drawable":514,"texture":0},{"component_id":9,"drawable":11,"texture":0},{"component_id":4,"drawable":19,"texture":0},{"component_id":6,"drawable":17,"texture":0}]}', 1),
	(10, 'GBZ4I79C', 'mp_m_freemode_01', '{"eyeColor":1,"props":[{"drawable":-1,"prop_id":0,"texture":-1},{"drawable":-1,"prop_id":7,"texture":-1},{"drawable":5,"prop_id":1,"texture":0},{"drawable":0,"prop_id":6,"texture":0},{"drawable":17,"prop_id":2,"texture":0}],"headOverlays":{"complexion":{"style":0,"secondColor":0,"opacity":0,"color":0},"moleAndFreckles":{"style":0,"secondColor":0,"opacity":0,"color":0},"makeUp":{"style":0,"secondColor":0,"opacity":0,"color":0},"bodyBlemishes":{"style":0,"secondColor":0,"opacity":0,"color":0},"blush":{"style":0,"secondColor":0,"opacity":0,"color":0},"eyebrows":{"style":6,"secondColor":0,"opacity":0,"color":55},"sunDamage":{"style":0,"secondColor":0,"opacity":0,"color":0},"ageing":{"style":0,"secondColor":0,"opacity":0,"color":0},"chestHair":{"style":0,"secondColor":0,"opacity":0,"color":0},"blemishes":{"style":0,"secondColor":0,"opacity":0,"color":0},"beard":{"style":0,"secondColor":0,"opacity":0,"color":0},"lipstick":{"style":0,"secondColor":0,"opacity":0,"color":0}},"headBlend":{"thirdMix":0,"shapeFirst":19,"skinFirst":0,"shapeThird":0,"skinSecond":0,"shapeMix":0,"shapeSecond":0,"skinMix":0,"skinThird":0},"model":"mp_m_freemode_01","tattoos":{"ZONE_HAIR":[]},"faceFeatures":{"noseBoneTwist":0,"noseBoneHigh":0,"noseWidth":0,"chinBoneSize":0,"cheeksBoneHigh":0,"neckThickness":0,"nosePeakSize":0,"cheeksWidth":0,"chinBoneLenght":0,"lipsThickness":0,"eyeBrownForward":0,"jawBoneWidth":0,"eyeBrownHigh":0,"cheeksBoneWidth":0,"jawBoneBackSize":0,"nosePeakHigh":0,"eyesOpening":0,"nosePeakLowering":0,"chinBoneLowering":0,"chinHole":0},"hair":{"style":11,"highlight":0,"texture":5,"color":55},"components":[{"component_id":0,"drawable":0,"texture":0},{"component_id":2,"drawable":0,"texture":0},{"component_id":5,"drawable":0,"texture":0},{"component_id":1,"drawable":0,"texture":0},{"component_id":6,"drawable":36,"texture":0},{"component_id":4,"drawable":6,"texture":0},{"component_id":7,"drawable":0,"texture":0},{"component_id":11,"drawable":44,"texture":0},{"component_id":9,"drawable":0,"texture":0},{"component_id":10,"drawable":0,"texture":0},{"component_id":8,"drawable":15,"texture":0},{"component_id":3,"drawable":0,"texture":0}]}', 1),
	(11, 'M4865C4Y', 'mp_m_freemode_01', '{"eyeColor":23,"props":[{"drawable":-1,"prop_id":0,"texture":-1},{"drawable":-1,"prop_id":2,"texture":-1},{"drawable":46,"prop_id":1,"texture":0},{"drawable":11,"prop_id":6,"texture":0},{"drawable":3,"prop_id":7,"texture":0}],"headOverlays":{"complexion":{"style":0,"secondColor":0,"color":0,"opacity":0},"ageing":{"style":0,"secondColor":0,"color":0,"opacity":0},"makeUp":{"style":0,"secondColor":0,"color":0,"opacity":0},"bodyBlemishes":{"style":0,"secondColor":0,"color":0,"opacity":0},"blush":{"style":0,"secondColor":0,"color":0,"opacity":0},"eyebrows":{"style":14,"secondColor":0,"color":0,"opacity":0},"sunDamage":{"style":0,"secondColor":0,"color":0,"opacity":0},"blemishes":{"style":0,"secondColor":0,"color":0,"opacity":0},"chestHair":{"style":0,"secondColor":0,"color":0,"opacity":0},"moleAndFreckles":{"style":0,"secondColor":0,"color":0,"opacity":0},"beard":{"style":18,"secondColor":0,"color":0,"opacity":1},"lipstick":{"style":0,"secondColor":0,"color":0,"opacity":0}},"headBlend":{"thirdMix":0,"shapeFirst":0,"skinFirst":0,"shapeThird":0,"skinSecond":0,"shapeMix":0,"shapeSecond":0,"skinMix":0,"skinThird":0},"model":"mp_m_freemode_01","tattoos":{"ZONE_HAIR":[],"ZONE_HEAD":[]},"faceFeatures":{"jawBoneBackSize":0,"nosePeakHigh":0,"noseWidth":0,"chinBoneSize":0,"cheeksBoneHigh":0,"neckThickness":0,"nosePeakSize":0,"cheeksWidth":0,"chinBoneLenght":0,"lipsThickness":0,"eyeBrownForward":0,"jawBoneWidth":0,"noseBoneTwist":0,"noseBoneHigh":0,"cheeksBoneWidth":0,"eyesOpening":0,"eyeBrownHigh":0,"nosePeakLowering":0,"chinBoneLowering":0,"chinHole":0},"hair":{"style":21,"highlight":29,"texture":3,"color":29},"components":[{"component_id":0,"texture":0,"drawable":0},{"component_id":2,"texture":0,"drawable":0},{"component_id":4,"texture":0,"drawable":0},{"component_id":10,"texture":0,"drawable":0},{"component_id":1,"texture":0,"drawable":0},{"component_id":7,"texture":0,"drawable":4},{"component_id":11,"texture":0,"drawable":455},{"component_id":8,"texture":0,"drawable":206},{"component_id":9,"texture":0,"drawable":0},{"component_id":5,"texture":0,"drawable":0},{"component_id":3,"texture":0,"drawable":0},{"component_id":6,"texture":0,"drawable":45}]}', 1),
	(12, 'E33O250L', 'mp_m_freemode_01', '{"eyeColor":-1,"props":[{"texture":-1,"prop_id":0,"drawable":-1},{"texture":-1,"prop_id":1,"drawable":-1},{"texture":-1,"prop_id":2,"drawable":-1},{"texture":-1,"prop_id":6,"drawable":-1},{"texture":-1,"prop_id":7,"drawable":-1}],"headOverlays":{"complexion":{"style":0,"secondColor":0,"color":0,"opacity":0},"ageing":{"style":0,"secondColor":0,"color":0,"opacity":0},"makeUp":{"style":0,"secondColor":0,"color":0,"opacity":0},"bodyBlemishes":{"style":0,"secondColor":0,"color":0,"opacity":0},"blemishes":{"style":0,"secondColor":0,"color":0,"opacity":0},"eyebrows":{"style":18,"secondColor":0,"color":0,"opacity":1},"sunDamage":{"style":0,"secondColor":0,"color":0,"opacity":0},"blush":{"style":0,"secondColor":0,"color":0,"opacity":0},"chestHair":{"style":0,"secondColor":0,"color":0,"opacity":0},"moleAndFreckles":{"style":0,"secondColor":0,"color":0,"opacity":0},"beard":{"style":23,"secondColor":0,"color":0,"opacity":1},"lipstick":{"style":0,"secondColor":0,"color":0,"opacity":0}},"headBlend":{"thirdMix":0,"shapeFirst":0,"skinFirst":0,"skinThird":0,"skinSecond":0,"shapeMix":0,"shapeSecond":0,"skinMix":0,"shapeThird":0},"model":"mp_m_freemode_01","tattoos":{"ZONE_HAIR":[]},"faceFeatures":{"jawBoneBackSize":0,"noseBoneHigh":0,"noseWidth":0,"chinBoneSize":0,"cheeksBoneHigh":0,"neckThickness":0,"nosePeakSize":0,"cheeksWidth":0,"eyesOpening":0,"lipsThickness":0,"eyeBrownForward":0,"jawBoneWidth":0,"eyeBrownHigh":0,"noseBoneTwist":0,"cheeksBoneWidth":0,"nosePeakHigh":0,"chinBoneLenght":0,"nosePeakLowering":0,"chinBoneLowering":0,"chinHole":0},"hair":{"style":12,"highlight":0,"texture":0,"color":0},"components":[{"component_id":0,"drawable":0,"texture":0},{"component_id":2,"drawable":0,"texture":0},{"component_id":5,"drawable":0,"texture":0},{"component_id":7,"drawable":0,"texture":0},{"component_id":10,"drawable":0,"texture":0},{"component_id":11,"drawable":54,"texture":0},{"component_id":9,"drawable":0,"texture":0},{"component_id":3,"drawable":31,"texture":0},{"component_id":8,"drawable":15,"texture":0},{"component_id":4,"drawable":33,"texture":0},{"component_id":6,"drawable":25,"texture":0},{"component_id":1,"drawable":23,"texture":0}]}', 1),
	(13, 'PE9044F8', 'mp_m_freemode_01', '{"eyeColor":7,"hair":{"style":9,"highlight":54,"texture":0,"color":55},"headOverlays":{"complexion":{"style":0,"secondColor":0,"opacity":0,"color":0},"ageing":{"style":0,"secondColor":0,"opacity":0,"color":0},"makeUp":{"style":0,"secondColor":0,"opacity":0,"color":0},"bodyBlemishes":{"style":0,"secondColor":0,"opacity":0,"color":0},"blemishes":{"style":0,"secondColor":0,"opacity":0,"color":0},"eyebrows":{"style":12,"secondColor":0,"opacity":1,"color":0},"sunDamage":{"style":0,"secondColor":0,"opacity":0,"color":0},"blush":{"style":0,"secondColor":0,"opacity":0,"color":0},"chestHair":{"style":0,"secondColor":0,"opacity":0,"color":0},"moleAndFreckles":{"style":0,"secondColor":0,"opacity":0,"color":0},"beard":{"style":3,"secondColor":0,"opacity":1,"color":0},"lipstick":{"style":0,"secondColor":0,"opacity":0,"color":0}},"headBlend":{"thirdMix":0,"shapeFirst":24,"skinFirst":0,"shapeThird":0,"skinSecond":0,"shapeMix":0.5,"shapeSecond":0,"skinMix":0,"skinThird":0},"model":"mp_m_freemode_01","tattoos":{"ZONE_HAIR":[],"ZONE_LEFT_ARM":[{"collection":"mpvinewood_overlays","zone":"ZONE_LEFT_ARM","opacity":1,"name":"TAT_VW_026","hashMale":"MP_Vinewood_Tat_026_M","label":"Banknote Rose","hashFemale":"MP_Vinewood_Tat_026_F"}]},"faceFeatures":{"noseBoneTwist":0,"noseBoneHigh":0,"noseWidth":-1,"chinBoneSize":0.5,"cheeksBoneHigh":0,"neckThickness":0,"nosePeakSize":0.5,"cheeksWidth":0,"chinBoneLenght":0.5,"lipsThickness":-1,"cheeksBoneWidth":0,"jawBoneWidth":0,"eyeBrownForward":0,"nosePeakHigh":-0.6,"eyeBrownHigh":-0.3,"eyesOpening":0,"jawBoneBackSize":-0.5,"nosePeakLowering":-0.2,"chinBoneLowering":1,"chinHole":-1},"props":[{"drawable":-1,"prop_id":1,"texture":-1},{"drawable":143,"prop_id":0,"texture":0},{"drawable":13,"prop_id":2,"texture":1},{"drawable":37,"prop_id":6,"texture":2},{"drawable":0,"prop_id":7,"texture":0}],"components":[{"component_id":0,"drawable":0,"texture":0},{"component_id":2,"drawable":0,"texture":0},{"component_id":5,"drawable":0,"texture":0},{"component_id":9,"drawable":0,"texture":0},{"component_id":4,"drawable":15,"texture":3},{"component_id":6,"drawable":105,"texture":15},{"component_id":10,"drawable":0,"texture":0},{"component_id":1,"drawable":0,"texture":0},{"component_id":7,"drawable":0,"texture":0},{"component_id":8,"drawable":0,"texture":0},{"component_id":3,"drawable":6,"texture":0},{"component_id":11,"drawable":14,"texture":7}]}', 1);

-- Dumping structure for table republica.playlist_songs
CREATE TABLE IF NOT EXISTS `playlist_songs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `playlist` int(11) NOT NULL,
  `position` int(11) NOT NULL DEFAULT 0,
  `link` varchar(255) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Dumping data for table republica.playlist_songs: ~0 rows (approximately)

-- Dumping structure for table republica.playlists
CREATE TABLE IF NOT EXISTS `playlists` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_uca1400_ai_ci;

-- Dumping data for table republica.playlists: ~0 rows (approximately)

-- Dumping structure for table republica.police_impound
CREATE TABLE IF NOT EXISTS `police_impound` (
  `citizenid` varchar(50) NOT NULL,
  `plate` varchar(50) DEFAULT NULL,
  `vehicle` longtext DEFAULT NULL,
  `props` longtext DEFAULT NULL,
  `owner` longtext DEFAULT NULL,
  `officer` longtext DEFAULT NULL,
  `date` longtext NOT NULL,
  `fine` bigint(20) DEFAULT 0,
  `paid` tinyint(4) DEFAULT 0,
  `garage` longtext NOT NULL,
  KEY `idx_police_impound_plate` (`plate`),
  KEY `idx_police_impound_citizenid` (`citizenid`),
  KEY `idx_police_impound_paid` (`paid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.police_impound: ~1 rows (approximately)
INSERT INTO `police_impound` (`citizenid`, `plate`, `vehicle`, `props`, `owner`, `officer`, `date`, `fine`, `paid`, `garage`) VALUES
	('ZDQ8H6H9', '2UMVKBQE', NULL, NULL, NULL, NULL, '18/03/2026', 10000, 0, 'Pátio do Detran');

-- Dumping structure for table republica.properties
CREATE TABLE IF NOT EXISTS `properties` (
  `property_id` int(11) NOT NULL AUTO_INCREMENT,
  `owner_citizenid` varchar(50) DEFAULT NULL,
  `street` varchar(100) DEFAULT NULL,
  `region` varchar(100) DEFAULT NULL,
  `description` longtext DEFAULT NULL,
  `has_access` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT json_array() CHECK (json_valid(`has_access`)),
  `extra_imgs` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT json_array() CHECK (json_valid(`extra_imgs`)),
  `furnitures` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT json_array() CHECK (json_valid(`furnitures`)),
  `for_sale` tinyint(1) NOT NULL DEFAULT 1,
  `price` int(11) NOT NULL DEFAULT 0,
  `shell` varchar(50) NOT NULL,
  `apartment` varchar(50) DEFAULT NULL,
  `door_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`door_data`)),
  `garage_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`garage_data`)),
  `zone_data` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`zone_data`)),
  PRIMARY KEY (`property_id`),
  UNIQUE KEY `UQ_owner_apartment` (`owner_citizenid`,`apartment`),
  CONSTRAINT `FK_owner_citizenid` FOREIGN KEY (`owner_citizenid`) REFERENCES `players` (`citizenid`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.properties: ~0 rows (approximately)

-- Dumping structure for table republica.ps_banking_accounts
CREATE TABLE IF NOT EXISTS `ps_banking_accounts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `balance` bigint(20) NOT NULL,
  `holder` varchar(255) NOT NULL,
  `cardNumber` varchar(255) NOT NULL,
  `users` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`users`)),
  `owner` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL CHECK (json_valid(`owner`)),
  PRIMARY KEY (`id`),
  KEY `idx_ps_banking_accounts_holder` (`holder`),
  KEY `idx_ps_banking_accounts_cardNumber` (`cardNumber`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.ps_banking_accounts: ~4 rows (approximately)
INSERT INTO `ps_banking_accounts` (`id`, `balance`, `holder`, `cardNumber`, `users`, `owner`) VALUES
	(1, 0, 'mechanic', '7279 1683 5816 3785', '[]', '[]'),
	(2, 0, 'police', '8646 0026 1952 5083', '[{"identifier":"ZDQ8H6H9"}]', '{"identifier":"ZDQ8H6H9","name":"TiãO Dev","state":true}'),
	(3, 0, 'ftpolicia', '4747 0552 8139 9838', '[]', '[]'),
	(4, 0, 'ambulance', '8761 6847 7496 7868', '[]', '[]');

-- Dumping structure for table republica.ps_banking_bills
CREATE TABLE IF NOT EXISTS `ps_banking_bills` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL,
  `description` varchar(255) NOT NULL,
  `type` varchar(50) NOT NULL,
  `amount` decimal(20,2) NOT NULL,
  `date` date NOT NULL,
  `isPaid` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_ps_banking_bills_identifier` (`identifier`),
  KEY `idx_ps_banking_bills_identifier_isPaid` (`identifier`,`isPaid`),
  KEY `idx_ps_banking_bills_date` (`date`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.ps_banking_bills: ~0 rows (approximately)

-- Dumping structure for table republica.ps_banking_transactions
CREATE TABLE IF NOT EXISTS `ps_banking_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `identifier` varchar(50) NOT NULL,
  `description` varchar(255) NOT NULL,
  `type` varchar(50) NOT NULL,
  `amount` decimal(20,2) NOT NULL,
  `date` date NOT NULL,
  `isIncome` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.ps_banking_transactions: ~4 rows (approximately)
INSERT INTO `ps_banking_transactions` (`id`, `identifier`, `description`, `type`, `amount`, `date`, `isIncome`) VALUES
	(1, 'JTW7MEXP', 'Transação bancária', 'bank', 1000.00, '2026-03-16', 1),
	(2, 'JTW7MEXP', 'Transação bancária', 'bank', 10000.00, '2026-03-20', 1),
	(3, 'JTW7MEXP', 'Transação bancária', 'bank', 850.00, '2026-03-21', 1),
	(4, 'JTW7MEXP', 'Transação bancária', 'bank', 850.00, '2026-03-21', 1);

-- Dumping structure for table republica.qt-crafting
CREATE TABLE IF NOT EXISTS `qt-crafting` (
  `craft_id` int(11) NOT NULL AUTO_INCREMENT,
  `craft_name` varchar(50) DEFAULT NULL,
  `crafting` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`crafting`)),
  `blipdata` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`blipdata`)),
  `jobs` longtext DEFAULT NULL,
  PRIMARY KEY (`craft_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table republica.qt-crafting: ~0 rows (approximately)

-- Dumping structure for table republica.qt-crafting-items
CREATE TABLE IF NOT EXISTS `qt-crafting-items` (
  `craft_id` int(11) DEFAULT NULL,
  `item` varchar(50) DEFAULT NULL,
  `item_label` varchar(50) DEFAULT NULL,
  `recipe` longtext DEFAULT NULL,
  `time` int(11) DEFAULT NULL,
  `amount` int(11) DEFAULT NULL,
  `model` longtext DEFAULT NULL,
  `anim` longtext DEFAULT NULL,
  `level` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table republica.qt-crafting-items: ~0 rows (approximately)

-- Dumping structure for table republica.race_tracks
CREATE TABLE IF NOT EXISTS `race_tracks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) DEFAULT NULL,
  `checkpoints` text DEFAULT NULL,
  `metadata` text DEFAULT NULL,
  `records` text DEFAULT NULL,
  `creatorid` varchar(50) DEFAULT NULL,
  `creatorname` varchar(50) DEFAULT NULL,
  `distance` int(11) DEFAULT NULL,
  `raceid` varchar(50) DEFAULT NULL,
  `access` text DEFAULT NULL,
  `curated` tinyint(4) DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `raceid` (`raceid`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=41 DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.race_tracks: ~0 rows (approximately)

-- Dumping structure for table republica.racer_names
CREATE TABLE IF NOT EXISTS `racer_names` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `citizenid` text NOT NULL,
  `racername` text NOT NULL,
  `lasttouched` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `races` int(11) NOT NULL DEFAULT 0,
  `wins` int(11) NOT NULL DEFAULT 0,
  `tracks` int(11) NOT NULL DEFAULT 0,
  `auth` varchar(50) DEFAULT 'racer',
  `crew` varchar(50) DEFAULT NULL,
  `createdby` varchar(50) DEFAULT NULL,
  `revoked` tinyint(4) DEFAULT 0,
  `ranking` int(11) DEFAULT 0,
  `active` int(11) NOT NULL DEFAULT 0,
  `crypto` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `id` (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=47 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table republica.racer_names: ~0 rows (approximately)

-- Dumping structure for table republica.racing_crews
CREATE TABLE IF NOT EXISTS `racing_crews` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `crew_name` text DEFAULT NULL,
  `members` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
  `wins` int(11) DEFAULT NULL,
  `races` int(11) DEFAULT NULL,
  `rank` int(11) DEFAULT NULL,
  `founder_name` text DEFAULT NULL,
  `founder_citizenid` text DEFAULT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  CONSTRAINT `members` CHECK (json_valid(`members`))
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table republica.racing_crews: ~0 rows (approximately)

-- Dumping structure for table republica.rnotes
CREATE TABLE IF NOT EXISTS `rnotes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `noteid` varchar(50) NOT NULL DEFAULT '0',
  `citizenid` varchar(100) NOT NULL DEFAULT '0',
  `notes` longtext NOT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_rnotes_citizenid` (`citizenid`),
  KEY `idx_rnotes_noteid` (`noteid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.rnotes: ~0 rows (approximately)

-- Dumping structure for table republica.synced_objects
CREATE TABLE IF NOT EXISTS `synced_objects` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `model` varchar(50) NOT NULL,
  `x` varchar(50) NOT NULL,
  `y` varchar(50) NOT NULL,
  `z` varchar(50) NOT NULL,
  `rx` varchar(50) NOT NULL,
  `ry` varchar(50) NOT NULL,
  `rz` varchar(50) NOT NULL,
  `heading` int(11) NOT NULL,
  `sceneid` int(11) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE,
  KEY `FK_objects_scene` (`sceneid`) USING BTREE,
  CONSTRAINT `FK_objects_scene` FOREIGN KEY (`sceneid`) REFERENCES `synced_objects_scenes` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=23 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table republica.synced_objects: ~21 rows (approximately)
INSERT INTO `synced_objects` (`id`, `model`, `x`, `y`, `z`, `rx`, `ry`, `rz`, `heading`, `sceneid`) VALUES
	(1, 'prop_plas_barier_01a', '-1270.200', '-302.512', '36.005', '0.000', '-0.000', '119.241', 119, 1),
	(2, 'prop_plas_barier_01a', '-1271.028', '-300.848', '36.069', '-0.000', '-0.000', '-62.099', 298, 1),
	(4, 'prop_plas_barier_01a', '-1271.955', '-299.215', '36.165', '-0.000', '-0.000', '-59.559', 300, 1),
	(5, 'prop_plas_barier_01a', '-1272.745', '-297.500', '36.265', '-0.796', '-2.930', '120.582', 121, 1),
	(6, 'prop_plas_barier_01a', '-1273.683', '-295.871', '36.361', '-0.947', '-2.885', '123.545', 124, 1),
	(7, 'prop_plas_barier_01a', '-1274.722', '-294.341', '36.456', '-0.728', '-2.952', '127.329', 127, 1),
	(8, 'prop_plas_barier_01a', '-1275.622', '-292.760', '36.550', '-0.137', '-2.965', '116.073', 116, 1),
	(9, 'prop_plas_barier_01a', '-1276.330', '-291.009', '36.649', '0.000', '-0.000', '118.053', 118, 1),
	(10, 'prop_plas_barier_01a', '-1277.169', '-289.256', '36.749', '0.000', '-0.000', '119.961', 120, 1),
	(11, 'prop_plas_barier_01a', '-1279.436', '-285.294', '36.987', '0.204', '-3.022', '126.777', 127, 1),
	(12, 'prop_plas_barier_01a', '-1280.255', '-283.963', '37.068', '-0.775', '2.928', '-64.184', 296, 1),
	(13, 'prop_fnclink_03c', '-1283.815', '-277.281', '37.469', '-1.615', '3.044', '-63.679', 296, 2),
	(14, 'prop_fnclink_03c', '-1289.192', '-279.464', '37.611', '0.000', '0.000', '32.140', 32, 2),
	(15, 'prop_fnclink_03c', '-1294.534', '-281.939', '37.716', '3.987', '0.683', '29.566', 30, 2),
	(16, 'prop_fnclink_03c', '-1299.784', '-284.605', '37.809', '4.072', '0.875', '27.460', 28, 2),
	(17, 'prop_fnclink_03c', '-1304.508', '-287.514', '37.861', '4.993', '0.733', '28.513', 29, 2),
	(18, 'prop_fnclink_03c', '-1309.964', '-290.392', '37.957', '5.083', '0.355', '36.314', 36, 2),
	(19, 'prop_fnclink_03c', '-1313.044', '-292.344', '37.985', '4.281', '-0.298', '35.299', 35, 2),
	(20, 'prop_fnclink_03c', '-1312.670', '-292.141', '37.983', '-0.182', '4.287', '-61.107', 299, 2),
	(21, 'prop_fnclink_03c', '-1306.893', '-302.227', '37.058', '-0.246', '-4.664', '121.697', 122, 2),
	(22, 'prop_fnclink_03c', '-1304.510', '-306.586', '36.652', '-0.231', '-4.665', '121.509', 122, 2);

-- Dumping structure for table republica.synced_objects_scenes
CREATE TABLE IF NOT EXISTS `synced_objects_scenes` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  PRIMARY KEY (`id`) USING BTREE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table republica.synced_objects_scenes: ~2 rows (approximately)
INSERT INTO `synced_objects_scenes` (`id`, `name`) VALUES
	(1, 'Parede'),
	(2, 'TAxi');

-- Dumping structure for table republica.tcd_starterpack
CREATE TABLE IF NOT EXISTS `tcd_starterpack` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(50) NOT NULL,
  `identifier` varchar(50) NOT NULL,
  `received` tinyint(1) NOT NULL,
  `date_received` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_tcd_starterpack_identifier` (`identifier`),
  KEY `idx_tcd_starterpack_received` (`received`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Dumping data for table republica.tcd_starterpack: ~4 rows (approximately)
INSERT INTO `tcd_starterpack` (`id`, `name`, `identifier`, `received`, `date_received`) VALUES
	(1, 'TiãO Dev', 'license:72b6567475f8452256ac755095e78e87298998a3', 1, '2026-03-19 20:57:03'),
	(2, 'Maka  Patron', 'license:b3e08103e05d260def1c3fdb26ce015692dc57cf', 0, '2026-03-16 16:11:21'),
	(3, 'Cavalcante Willian', 'license:c4dc6917498471cd1fa92f8301057974be6a7794', 1, '2026-03-19 21:00:02'),
	(4, 'Bruno Pitbull', 'license:83e4dc3ef274870e7699fc51711235ac3048a575', 1, '2026-03-19 22:32:52');

-- Dumping structure for table republica.users
CREATE TABLE IF NOT EXISTS `users` (
  `userId` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(255) DEFAULT NULL,
  `license` varchar(50) DEFAULT NULL,
  `license2` varchar(50) DEFAULT NULL,
  `fivem` varchar(20) DEFAULT NULL,
  `discord` varchar(30) DEFAULT NULL,
  PRIMARY KEY (`userId`),
  KEY `idx_users_license` (`license`),
  KEY `idx_users_license2` (`license2`),
  KEY `idx_users_discord` (`discord`),
  KEY `idx_users_fivem` (`fivem`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.users: ~6 rows (approximately)
INSERT INTO `users` (`userId`, `username`, `license`, `license2`, `fivem`, `discord`) VALUES
	(1, 'ShyRabbit8170', 'license:72b6567475f8452256ac755095e78e87298998a3', 'license2:72b6567475f8452256ac755095e78e87298998a3', NULL, 'discord:926961236107730994'),
	(2, 'MAKA', 'license:b3e08103e05d260def1c3fdb26ce015692dc57cf', 'license2:8d3ceb321079521ddd520a064373aaeff542eb96', NULL, 'discord:381450917909757954'),
	(3, 'WILL_DGK', 'license:6b4ee3d11fb38d49bef54f80e39e7e24eb9e1e32', 'license2:0f957b2bed833959dfda9020fc3311dc7a94a69c', NULL, 'discord:789238370466791435'),
	(4, 'willian', 'license:c4dc6917498471cd1fa92f8301057974be6a7794', 'license2:ee41f168f07252b7eaa88f9d3c37d9b23fd61b3c', NULL, 'discord:326175598919811083'),
	(5, 'LOBODELEGA', 'license:1d83d89930a983733c7d2c0fc307f18407ffd0b8', 'license2:1ce6953be549523b546c8051a9024d68c71fb1d8', NULL, 'discord:918388621176881222'),
	(6, 'BUTEÇÃO', 'license:83e4dc3ef274870e7699fc51711235ac3048a575', 'license2:daf3461f2e2783d50236e55e31784c70edd6a826', NULL, 'discord:506273463183605771');

-- Dumping structure for table republica.vehicle_financing
CREATE TABLE IF NOT EXISTS `vehicle_financing` (
  `vehicleId` int(11) NOT NULL,
  `balance` int(11) DEFAULT NULL,
  `paymentamount` int(11) DEFAULT NULL,
  `paymentsleft` tinyint(4) DEFAULT NULL,
  `financetime` int(11) DEFAULT NULL,
  PRIMARY KEY (`vehicleId`),
  KEY `idx_vehicle_financing_balance` (`balance`),
  CONSTRAINT `vehicleId` FOREIGN KEY (`vehicleId`) REFERENCES `player_vehicles` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.vehicle_financing: ~0 rows (approximately)

-- Dumping structure for table republica.vehicles_data
CREATE TABLE IF NOT EXISTS `vehicles_data` (
  `model` varchar(50) NOT NULL,
  `stock` int(11) DEFAULT 0,
  `price` int(11) NOT NULL,
  `name` varchar(100) DEFAULT NULL,
  `brand` varchar(50) DEFAULT NULL,
  `category` varchar(50) DEFAULT NULL,
  `hash` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

-- Dumping data for table republica.vehicles_data: ~901 rows (approximately)
INSERT INTO `vehicles_data` (`model`, `stock`, `price`, `name`, `brand`, `category`, `hash`) VALUES
	('adder', 0, 86065, 'Adder', 'Truffade', 'super', -1216765807),
	('airbus', 0, 42321, 'Airport Bus', '', 'service', 1283517198),
	('airtug', 0, 18786, 'Airtug', 'HVY', 'utility', 1560980623),
	('akula', 0, 6879704, 'Akula', 'Buckingham', 'helicopters', 1181327175),
	('akuma', 0, 25356, 'Akuma', 'Dinka', 'motorcycles', 1672195559),
	('aleutian', 0, 66169, 'Aleutian', 'Vapid', 'suvs', -38879449),
	('alkonost', 0, 1933450, 'RO-86 Alkonost', '', 'planes', -365873403),
	('alpha', 0, 82526, 'Alpha', 'Albany', 'sports', 767087018),
	('alphaz1', 0, 2587839, 'Alpha-Z1', 'Buckingham', 'planes', -1523619738),
	('ambulance', 0, 66002, 'Ambulance', 'Brute', 'emergency', 1171614426),
	('annihilator', 0, 5278061, 'Annihilator', 'Western', 'helicopters', 837858166),
	('annihilator2', 0, 5947464, 'Annihilator Stealth', 'Western', 'helicopters', 295054921),
	('apc', 0, 38410, 'APC', 'HVY', 'military', 562680400),
	('ardent', 0, 79425, 'Ardent', 'Ocelot', 'sportsclassics', 159274291),
	('armytanker', 0, 5748, 'Army Trailer (Tanker)', '', 'utility', -1207431159),
	('armytrailer', 0, 5668, 'Army Trailer', '', 'utility', -1476447243),
	('armytrailer2', 0, 5668, 'Army Trailer (Civilian)', '', 'utility', -1637149482),
	('asbo', 0, 63020, 'Asbo', 'Maxwell', 'compacts', 1118611807),
	('asea', 0, 63374, 'Asea', 'Declasse', 'sedans', -1809822327),
	('asea2', 0, 63374, 'Asea (Snow)', 'Declasse', 'sedans', -1807623979),
	('asterope', 0, 64174, 'Asterope', 'Karin', 'sedans', -1903012613),
	('asterope2', 0, 71306, 'Asterope GZ', 'Karin', 'sedans', -741120335),
	('astron', 0, 81719, 'Astron', 'Pfister', 'suvs', 629969764),
	('autarch', 0, 85798, 'Autarch', 'Överflöd', 'super', -313185164),
	('avarus', 0, 23028, 'Avarus', 'LCC', 'motorcycles', -2115793025),
	('avenger', 0, 1953425, 'Avenger', 'Mammoth', 'planes', -2118308144),
	('avenger2', 0, 1953425, 'Avenger (Prop)', 'Mammoth', 'planes', 408970549),
	('avenger3', 0, 1953425, 'Avenger (Upgraded)', 'Mammoth', 'planes', -426933872),
	('avenger4', 0, 1953425, 'Avenger (Upgraded Prop)', 'Mammoth', 'planes', -69293006),
	('avisa', 0, 804616, 'Avisa', 'Kraken', 'boats', -1706603682),
	('bagger', 0, 19934, 'Bagger', 'Western', 'motorcycles', -2140431165),
	('baletrailer', 0, 5668, 'Baletrailer', '', 'utility', -399841706),
	('baller', 0, 65628, 'Baller', 'Gallivanter', 'suvs', -808831384),
	('baller2', 0, 74432, 'Baller', 'Gallivanter', 'suvs', 142944341),
	('baller3', 0, 74448, 'Baller LE', 'Gallivanter', 'suvs', 1878062887),
	('baller4', 0, 74384, 'Baller LE LWB', 'Gallivanter', 'suvs', 634118882),
	('baller5', 0, 74400, ' Baller LE (Armored)', 'Gallivanter', 'suvs', 470404958),
	('baller6', 0, 74335, 'Baller LE LWB (Armored)', 'Gallivanter', 'suvs', 666166960),
	('baller7', 0, 77229, 'Baller ST', 'Gallivanter', 'suvs', 359875117),
	('baller8', 0, 77694, 'Baller ST-D', 'Gallivanter', 'suvs', -863358884),
	('banshee', 0, 79495, 'Banshee', 'Bravado', 'sports', -1041692462),
	('banshee2', 0, 74887, 'Banshee 900R', 'Bravado', 'super', 633712403),
	('banshee3', 0, 74887, 'Banshee GTS', 'Bravado', 'sports', -660007725),
	('barracks', 0, 53283, 'Barracks', 'HVY', 'military', -823509173),
	('barracks2', 0, 60073, 'Barracks Semi', 'HVY', 'military', 1074326203),
	('barracks3', 0, 53283, 'Barracks', 'HVY', 'military', 630371791),
	('barrage', 0, 66580, 'Barrage', 'HVY', 'military', -212993243),
	('bati', 0, 25838, 'Bati 801', 'Pegassi', 'motorcycles', -114291515),
	('bati2', 0, 25838, 'Bati 801RR', 'Pegassi', 'motorcycles', -891462355),
	('benson', 0, 60635, 'Benson', 'Vapid', 'commercial', 2053223216),
	('benson2', 0, 60635, 'Benson (Cluckin\' Bell)', 'Vapid', 'commercial', 728350375),
	('besra', 0, 2373206, 'Besra', 'Western', 'planes', 1824333165),
	('bestiagts', 0, 79703, 'Bestia GTS', 'Grotti', 'sports', 1274868363),
	('bf400', 0, 23103, 'BF400', 'Nagasaki', 'motorcycles', 86520421),
	('bfinjection', 0, 67551, 'Injection', 'BF', 'offroad', 1126868326),
	('biff', 0, 56668, 'Biff', 'HVY', 'commercial', 850991848),
	('bifta', 0, 74872, 'Bifta', 'BF', 'offroad', -349601129),
	('bison', 0, 62297, 'Bison', 'Bravado', 'vans', -16948145),
	('bison2', 0, 62297, 'Bison (McGill-Olsen)', 'Bravado', 'vans', 2072156101),
	('bison3', 0, 62297, 'Bison (The Mighty Bush)', 'Bravado', 'vans', 1739845664),
	('bjxl', 0, 60692, 'BeeJay XL', 'Karin', 'suvs', 850565707),
	('blade', 0, 70520, 'Blade', 'Vapid', 'muscle', -1205801634),
	('blazer', 0, 21457, 'Blazer', 'Nagasaki', 'offroad', -2128233223),
	('blazer2', 0, 15679, 'Blazer Lifeguard', 'Nagasaki', 'offroad', -48031959),
	('blazer3', 0, 21457, 'Hot Rod Blazer', 'Nagasaki', 'offroad', -1269889662),
	('blazer4', 0, 24453, 'Blazer Sport', 'Nagasaki', 'offroad', -440768424),
	('blazer5', 0, 25680, 'Blazer Aqua', 'Nagasaki', 'offroad', -1590337689),
	('blimp', 0, 1024161, 'Atomic Blimp', '', 'planes', -150975354),
	('blimp2', 0, 1036862, 'Xero Blimp', '', 'planes', -613725916),
	('blimp3', 0, 1024161, 'Blimp', '', 'planes', -307958377),
	('blista', 0, 69371, 'Blista', 'Dinka', 'compacts', -344943009),
	('blista2', 0, 69291, 'Blista Compact', 'Dinka', 'sports', 1039032026),
	('blista3', 0, 69291, 'Blista Go Go Monkey', 'Dinka', 'sports', -591651781),
	('bmx', 0, 2735, 'BMX', 'PED', 'cycles', 1131912276),
	('boattrailer', 0, 5668, 'Boat Trailer', '', 'utility', 524108981),
	('boattrailer2', 0, 5668, 'Boat Trailer (Dinghy)', '', 'utility', 1835260592),
	('boattrailer3', 0, 5668, 'Boat Trailer (Seashark)', '', 'utility', 1539159908),
	('bobcatxl', 0, 58720, 'Bobcat XL Open', 'Vapid', 'vans', 1069929536),
	('bodhi2', 0, 59867, 'Bodhi', 'Canis', 'offroad', -1435919434),
	('bombushka', 0, 788207, 'RM-10 Bombushka', '', 'planes', -32878452),
	('boor', 0, 67237, 'Boor', 'Karin', 'offroad', 996383885),
	('boxville', 0, 47273, 'Boxville (LSDWP)', 'Brute', 'vans', -1987130134),
	('boxville2', 0, 47273, 'Boxville (Go Postal)', 'Brute', 'vans', -233098306),
	('boxville3', 0, 47273, 'Boxville (Humane Labs)', 'Brute', 'vans', 121658888),
	('boxville4', 0, 47273, 'Boxville (Post Op)', 'Brute', 'vans', 444171386),
	('boxville5', 0, 65341, 'Armored Boxville', 'Brute', 'vans', 682434785),
	('boxville6', 0, 47273, 'Boxville (LSDS)', 'Brute', 'vans', -842765535),
	('brawler', 0, 77578, 'Brawler', 'Coil', 'offroad', -1479664699),
	('brickade', 0, 54416, 'Brickade', 'MTL', 'service', -305727417),
	('brickade2', 0, 54416, 'Brickade 6x6', 'MTL', 'service', -1576586413),
	('brigham', 0, 63825, 'Brigham', 'Albany', 'muscle', -654498607),
	('brioso', 0, 69113, 'Brioso R/A', 'Grotti', 'compacts', 1549126457),
	('brioso2', 0, 54291, 'Brioso 300', 'Grotti', 'compacts', 1429622905),
	('brioso3', 0, 61333, 'Brioso 300 Widebody', 'Grotti', 'compacts', 15214558),
	('broadway', 0, 61702, 'Broadway', 'Classique', 'muscle', -1933242328),
	('bruiser', 0, 63687, 'Apocalypse Bruiser', 'Benefactor', 'offroad', 668439077),
	('bruiser2', 0, 63687, 'Future Shock Bruiser', 'Benefactor', 'offroad', -1694081890),
	('bruiser3', 0, 63687, 'Nightmare Bruiser', 'Benefactor', 'offroad', -2042350822),
	('brutus', 0, 70122, 'Apocalypse Brutus', 'Declasse', 'offroad', 2139203625),
	('brutus2', 0, 70122, 'Future Shock Brutus', 'Declasse', 'offroad', -1890996696),
	('brutus3', 0, 70122, 'Nightmare Brutus', 'Declasse', 'offroad', 2038858402),
	('btype', 0, 69018, 'Roosevelt', 'Albany', 'sportsclassics', 117401876),
	('btype2', 0, 74624, 'Franken Stange', 'Albany', 'sportsclassics', -831834716),
	('btype3', 0, 69018, 'Roosevelt Valor', 'Albany', 'sportsclassics', -602287871),
	('buccaneer', 0, 76634, 'Buccaneer', 'Albany', 'muscle', -682211828),
	('buccaneer2', 0, 76634, 'Buccaneer Custom', 'Albany', 'muscle', -1013450936),
	('buffalo', 0, 75156, 'Buffalo', 'Bravado', 'sports', -304802106),
	('buffalo2', 0, 77026, 'Buffalo S', 'Bravado', 'sports', 736902334),
	('buffalo3', 0, 80264, 'Sprunk Buffalo', 'Bravado', 'sports', 237764926),
	('buffalo4', 0, 80516, 'Buffalo STX', 'Bravado', 'muscle', -619930876),
	('buffalo5', 0, 83332, 'Buffalo EVX', 'Bravado', 'muscle', 165968051),
	('bulldozer', 0, 9376, 'Dozer', 'HVY', 'industrial', 1886712733),
	('bullet', 0, 82565, 'Bullet', 'Vapid', 'super', -1696146015),
	('burrito', 0, 61195, 'Burrito (LSDWP)', 'Declasse', 'vans', -1346687836),
	('burrito2', 0, 61195, 'Bugstars Burrito', 'Declasse', 'vans', -907477130),
	('burrito3', 0, 61195, 'Burrito', 'Declasse', 'vans', -1743316013),
	('burrito4', 0, 61195, 'Burrito (McGill-Olsen)', 'Declasse', 'vans', 893081117),
	('burrito5', 0, 61195, 'Burrito (Snow)', 'Declasse', 'vans', 1132262048),
	('bus', 0, 42481, 'Bus', '', 'service', -713569950),
	('buzzard', 0, 6462758, 'Buzzard Attack Chopper', 'Nagasaki', 'helicopters', 788747387),
	('buzzard2', 0, 6462758, 'Buzzard', 'Nagasaki', 'helicopters', 745926877),
	('cablecar', 0, 194680, 'Cable Car', '', 'trains', -960289747),
	('caddy', 0, 36554, 'Caddy (Golf)', 'Nagasaki', 'utility', 1147287684),
	('caddy2', 0, 36554, 'Caddy', 'Nagasaki', 'utility', -537896628),
	('caddy3', 0, 36022, 'Caddy (Bunker)', 'Nagasaki', 'utility', -769147461),
	('calico', 0, 82150, 'Calico GTF', 'Karin', 'sports', -1193912403),
	('camper', 0, 50131, 'Camper', 'Brute', 'vans', 1876516712),
	('caracara', 0, 63685, 'Caracara', 'Vapid', 'offroad', 1254014755),
	('caracara2', 0, 64784, 'Caracara 4x4', 'Vapid', 'offroad', -1349095620),
	('carbonizzare', 0, 80346, 'Carbonizzare', 'Grotti', 'sports', 2072687711),
	('carbonrs', 0, 24649, 'Carbon RS', 'Nagasaki', 'motorcycles', 11251904),
	('cargobob', 0, 5616986, 'Cargobob', 'Western', 'helicopters', -50547061),
	('cargobob2', 0, 5616986, 'Cargobob (Jetsam)', 'Western', 'helicopters', 1621617168),
	('cargobob3', 0, 5616986, 'Cargobob (Trevor Philips Enterprises)', 'Western', 'helicopters', 1394036463),
	('cargobob4', 0, 5616986, 'Cargobob (Drop Zone)', 'Western', 'helicopters', 2025593404),
	('cargobob5', 0, 5616986, 'DH-7 Iron Mule', 'Buckingham', 'helicopters', -352682313),
	('cargoplane', 0, 1537948, 'Cargo Plane', '', 'planes', 368211810),
	('cargoplane2', 0, 1537948, 'Cargo Plane', '', 'planes', -1958189855),
	('casco', 0, 83125, 'Casco', 'Lampadati', 'sportsclassics', 941800958),
	('castigator', 0, 83125, 'Castigator', 'Canis', 'suvs', 1307736079),
	('cavalcade', 0, 63694, 'Cavalcade', 'Albany', 'suvs', 2006918058),
	('cavalcade2', 0, 63694, 'Cavalcade', 'Albany', 'suvs', -789894171),
	('cavalcade3', 0, 67959, 'Cavalcade XL', 'Albany', 'suvs', -1029730482),
	('cerberus', 0, 61154, 'Apocalypse Cerberus', 'MTL', 'commercial', -801550069),
	('cerberus2', 0, 61154, 'Future Shock Cerberus', 'MTL', 'commercial', 679453769),
	('cerberus3', 0, 61154, 'Nightmare Cerberus', 'MTL', 'commercial', 1909700336),
	('champion', 0, 86582, 'Champion', 'Dewbauchee', 'super', -915234475),
	('chavosv6', 0, 86582, 'Chavos V6', 'Dewbauchee', 'sedans', 1992041063),
	('cheburek', 0, 74166, 'Cheburek', 'RUNE', 'sportsclassics', -988501280),
	('cheetah', 0, 82927, 'Cheetah', 'Grotti', 'super', -1311154784),
	('cheetah2', 0, 82724, 'Cheetah Classic', 'Grotti', 'sportsclassics', 223240013),
	('cheetah3', 0, 459381, 'Cheetah 3', 'Grotti', 'sportsclassics', 471399650),
	('chernobog', 0, 37291, 'Chernobog', 'HVY', 'military', -692292317),
	('chimera', 0, 22412, 'Chimera', 'Nagasaki', 'motorcycles', 6774487),
	('chino', 0, 58651, 'Chino', 'Vapid', 'muscle', 349605904),
	('chino2', 0, 60394, 'Chino Custom', 'Vapid', 'muscle', -1361687965),
	('cinquemila', 0, 80476, 'Cinquemila', 'Lampadati', 'sedans', -1527436269),
	('cliffhanger', 0, 25621, 'Cliffhanger', 'Western', 'motorcycles', 390201602),
	('clique', 0, 76525, 'Clique', 'Vapid', 'muscle', -1566607184),
	('clique2', 0, 54902, 'Clique Wagon', 'Vapid', 'muscle', -979292575),
	('club', 0, 69335, 'Club', 'BF', 'compacts', -2098954619),
	('coach', 0, 42321, 'Dashound', '', 'service', -2072933068),
	('cog55', 0, 76441, 'Cognoscenti 55', 'Enus', 'sedans', 906642318),
	('cog552', 0, 75535, 'Cognoscenti 55 (Armored)', 'Enus', 'sedans', 704435172),
	('cogcabrio', 0, 74712, 'Cognoscenti Cabrio', 'Enus', 'coupes', 330661258),
	('cognoscenti', 0, 75535, 'Cognoscenti', 'Enus', 'sedans', -2030171296),
	('cognoscenti2', 0, 74605, 'Cognoscenti (Armored)', 'Enus', 'sedans', -604842630),
	('comet2', 0, 83289, 'Comet', 'Pfister', 'sports', -1045541610),
	('comet3', 0, 83253, 'Comet Retro Custom', 'Pfister', 'sports', -2022483795),
	('comet4', 0, 78289, 'Comet Safari', 'Pfister', 'sports', 1561920505),
	('comet5', 0, 78583, 'Comet SR', 'Pfister', 'sports', 661493923),
	('comet6', 0, 83378, 'Comet S2', 'Pfister', 'sports', -1726022652),
	('comet7', 0, 83759, 'Comet S2 Cabrio', 'Pfister', 'sports', 1141395928),
	('conada', 0, 6931736, 'Conada', 'Buckingham', 'helicopters', -477831899),
	('conada2', 0, 6855740, 'Weaponized Conada', 'Buckingham', 'helicopters', -1659004814),
	('contender', 0, 68578, 'Contender', 'Vapid', 'suvs', 683047626),
	('coquette', 0, 83674, 'Coquette', 'Invetero', 'sports', 108773431),
	('coquette2', 0, 81755, 'Coquette Classic', 'Invetero', 'sportsclassics', 1011753235),
	('coquette3', 0, 74621, 'Coquette BlackFin', 'Invetero', 'muscle', 784565758),
	('coquette4', 0, 80771, 'Coquette D10', 'Invetero', 'sports', -1728685474),
	('coquette5', 0, 80771, 'Coquette D1', 'Invetero', 'sportsclassics', -1958428933),
	('coquette6', 0, 80771, 'Coquette D5', 'Invetero', 'sports', 127317925),
	('corsita', 0, 87616, 'Corsita', 'Lampadati', 'sports', -754687673),
	('coureur', 0, 77754, 'La Coureuse', 'Penaud', 'sports', 610429990),
	('cruiser', 0, 2751, 'Cruiser', 'PED', 'cycles', 448402357),
	('crusader', 0, 59206, 'Crusader', 'Canis', 'military', 321739290),
	('cuban800', 0, 1489140, 'Cuban 800', 'Western', 'planes', -644710429),
	('cutter', 0, 22017, 'Cutter', 'HVY', 'industrial', -1006919392),
	('cyclone', 0, 68875, 'Cyclone', 'Coil', 'super', 1392481335),
	('cypher', 0, 75676, 'Cypher', 'Übermacht', 'sports', 1755697647),
	('daemon', 0, 22321, 'Daemon', 'Western', 'motorcycles', 2006142190),
	('daemon2', 0, 22423, 'Daemon Custom', 'Western', 'motorcycles', -1404136503),
	('deathbike', 0, 25195, 'Apocalypse Deathbike', 'Western', 'motorcycles', -27326686),
	('deathbike2', 0, 25195, 'Future Shock Deathbike', 'Western', 'motorcycles', -1812949672),
	('deathbike3', 0, 25195, 'Nightmare Deathbike', 'Western', 'motorcycles', -1374500452),
	('defiler', 0, 25616, 'Defiler', 'Shitzu', 'motorcycles', 822018448),
	('deity', 0, 73581, 'Deity', 'Enus', 'sedans', 1532171089),
	('deluxo', 0, 70738, 'Deluxo', 'Imponte', 'sportsclassics', 1483171323),
	('deveste', 0, 87916, 'Deveste', 'Principe', 'super', 1591739866),
	('deviant', 0, 70267, 'Deviant', 'Schyster', 'muscle', 1279262537),
	('diablous', 0, 24745, 'Diablous', 'Principe', 'motorcycles', -239841468),
	('diablous2', 0, 24901, 'Diablous Custom', 'Principe', 'motorcycles', 1790834270),
	('dilettante', 0, 40298, 'Dilettante', 'Karin', 'compacts', -1130810103),
	('dilettante2', 0, 40298, 'Dilettante (Security)', 'Karin', 'compacts', 1682114128),
	('dinghy', 0, 446680, 'Dinghy', 'Nagasaki', 'boats', 1033245328),
	('dinghy2', 0, 446680, 'Dinghy', 'Nagasaki', 'boats', 276773164),
	('dinghy3', 0, 446680, 'Dinghy (Heist)', 'Nagasaki', 'boats', 509498602),
	('dinghy4', 0, 446680, 'Dinghy (Yacht)', 'Nagasaki', 'boats', 867467158),
	('dinghy5', 0, 446680, 'Weaponized Dinghy', 'Nagasaki', 'boats', -980573366),
	('dloader', 0, 55231, 'Duneloader', 'Bravado', 'offroad', 1770332643),
	('docktrailer', 0, 5668, 'Dock Trailer', '', 'utility', -2140210194),
	('docktug', 0, 41473, 'Docktug', 'HVY', 'utility', -884690486),
	('dodo', 0, 1321065, 'Dodo', 'Mammoth', 'planes', -901163259),
	('dominator', 0, 80149, 'Dominator', 'Vapid', 'muscle', 80636076),
	('dominator10', 0, 82702, 'Dominator FX', 'Vapid', 'muscle', 1579902654),
	('dominator2', 0, 81440, 'Pisswasser Dominator', 'Vapid', 'muscle', -915704871),
	('dominator3', 0, 77862, 'Dominator GTX', 'Vapid', 'muscle', -986944621),
	('dominator4', 0, 80565, 'Dominator Arena', 'Vapid', 'muscle', -688189648),
	('dominator5', 0, 80565, 'Future Shock Dominator', 'Vapid', 'muscle', -1375060657),
	('dominator6', 0, 80565, 'Nightmare Dominator', 'Vapid', 'muscle', -1293924613),
	('dominator7', 0, 83320, 'Dominator ASP', 'Vapid', 'muscle', 426742808),
	('dominator8', 0, 76296, 'Dominator GTT', 'Vapid', 'muscle', 736672010),
	('dominator9', 0, 82702, 'Dominator GT', 'Vapid', 'muscle', -441209695),
	('dorado', 0, 69578, 'Dorado', 'Bravado', 'suvs', -768044142),
	('double', 0, 25173, 'Double-T', 'Dinka', 'motorcycles', -1670998136),
	('drafter', 0, 79907, '8F Drafter', 'Obey', 'sports', 686471183),
	('draugur', 0, 72622, 'Draugur', 'Declasse', 'offroad', -768236378),
	('driftchavosv6', 0, 86582, 'Drift Chavos V6', 'Dinka', 'sedans', 457814204),
	('driftcheburek', 0, 76163, 'Cheburek (Drift)', 'RUNE', 'sportsclassics', -1466692365),
	('driftcypher', 0, 76163, 'Cypher (Drift)', 'Übermacht', 'sports', 258105345),
	('driftdominator10', 0, 81768, 'Drift Dominator FX', 'Vapid', 'muscle', -939601823),
	('drifteuros', 0, 76163, 'Euros (Drift)', 'Annis', 'sports', 821121576),
	('driftfr36', 0, 75045, 'FR36 (Drift)', 'Fathom', 'coupes', -1479935577),
	('driftfuto', 0, 75037, 'Futo GTX (Drift)', 'Karin', 'sports', -181562642),
	('driftfuto2', 0, 75037, 'Futo (Drift)', 'Karin', 'sports', -1289225626),
	('driftgauntlet4', 0, 81048, 'Drift Gauntlet Hellfire', 'Bravado', 'muscle', -361348193),
	('drifthardy', 0, 22789, 'Drift Hardy', 'Annis', 'sedans', -401558446),
	('driftjester', 0, 74933, 'Jester RR (Drift)', 'Dinka', 'sports', -1763273939),
	('driftjester3', 0, 74933, 'Jester Classic (Drift)', 'Dinka', 'sportsclassics', -362690998),
	('driftl352', 0, 44723, 'Drift Walton L35', 'Declasse', 'offroad', -1982433631),
	('driftnebula', 0, 74933, 'Nebula Turbo (Drift)', 'Vulcar', 'sportsclassics', 1690421418),
	('driftremus', 0, 78305, 'Remus (Drift)', 'Annis', 'sports', -1624083468),
	('driftsentinel', 0, 78305, 'Sentinel Classic Widebody (Drift)', 'Übermacht', 'sports', -986656474),
	('drifttampa', 0, 78299, 'Drift Tampa', 'Declasse', 'sports', -1696319096),
	('driftvorschlag', 0, 70884, 'Vorschlaghammer (Drift)', 'Declasse', 'sedans', -143587026),
	('driftyosemite', 0, 70884, 'Drift Yosemite', 'Declasse', 'muscle', -1681653521),
	('driftzr350', 0, 75060, 'ZR350 (Drift)', 'Annis', 'sports', 1923534526),
	('dubsta', 0, 62617, 'Dubsta', 'Benefactor', 'suvs', 1177543287),
	('dubsta2', 0, 62617, 'Dubsta', 'Benefactor', 'suvs', -394074634),
	('dubsta3', 0, 64556, 'Dubsta 6x6', 'Benefactor', 'offroad', -1237253773),
	('dukes', 0, 79383, 'Dukes', 'Imponte', 'muscle', 723973206),
	('dukes2', 0, 77611, 'Dukes Nightrider', 'Imponte', 'muscle', -326143852),
	('dukes3', 0, 78577, 'Beater Dukes', 'Imponte', 'muscle', 2134119907),
	('dump', 0, 24629, 'Dump', 'HVY', 'industrial', -2130482718),
	('dune', 0, 64617, 'Dune Buggy', 'BF', 'offroad', -1661854193),
	('dune2', 0, 63085, 'Space Docker', 'BF', 'offroad', 534258863),
	('dune3', 0, 64617, 'Dune FAV', 'BF', 'offroad', 1897744184),
	('dune4', 0, 82003, 'Ramp Buggy', 'BF', 'offroad', -827162039),
	('dune5', 0, 81376, 'Ramp Buggy', 'BF', 'offroad', -312295511),
	('duster', 0, 1321065, 'Duster', 'Western', 'planes', 970356638),
	('duster2', 0, 1321065, 'Duster 300-H', 'Western', 'planes', 84351789),
	('dynasty', 0, 58840, 'Dynasty', 'Weeny', 'sportsclassics', 310284501),
	('elegy', 0, 78735, 'Elegy Retro Custom', 'Annis', 'sports', 196747873),
	('elegy2', 0, 80339, 'Elegy RH8', 'Annis', 'sports', -566387422),
	('ellie', 0, 75782, 'Ellie', 'Vapid', 'muscle', -1267543371),
	('emerus', 0, 85112, 'Progen Emerus', 'Progen', 'super', 1323778901),
	('emperor', 0, 56110, 'Emperor', 'Albany', 'sedans', -685276541),
	('emperor2', 0, 56110, 'Emperor (Beater)', 'Albany', 'sedans', -1883002148),
	('emperor3', 0, 56110, 'Emperor (Snow)', 'Albany', 'sedans', -1241712818),
	('enduro', 0, 20848, 'Enduro', 'Dinka', 'motorcycles', 1753414259),
	('entity2', 0, 89286, 'Entity XXR', 'Överflöd', 'super', -2120700196),
	('entity3', 0, 89208, 'Entity MT', 'Överflöd', 'super', 1748565021),
	('entityxf', 0, 84601, 'Entity XF', 'Överflöd', 'super', -1291952903),
	('envisage', 0, 79842, 'Envisage', 'Bollokan', 'sports', 1121330119),
	('esskey', 0, 23138, 'Esskey', 'Pegassi', 'motorcycles', 2035069708),
	('eudora', 0, 66819, 'Eudora', 'Willard', 'muscle', -1249788006),
	('euros', 0, 78840, 'Euros', 'Annis', 'sports', 2038480341),
	('eurosx32', 0, 78840, 'Euros X32', 'Annis', 'sports', -999594302),
	('everon', 0, 68803, 'Everon', 'Karin', 'offroad', -1756021720),
	('everon2', 0, 79842, 'Hotring Everon', 'Karin', 'sports', -131348178),
	('everon3', 0, 79842, 'Everon RS', 'Karin', 'suvs', 554408685),
	('exemplar', 0, 79891, 'Exemplar', 'Dewbauchee', 'coupes', -5153954),
	('f620', 0, 79607, 'F620', 'Ocelot', 'coupes', -591610296),
	('faction', 0, 77450, 'Faction', 'Willard', 'muscle', -2119578145),
	('faction2', 0, 77450, 'Faction Rider', 'Willard', 'muscle', -1790546981),
	('faction3', 0, 58971, 'Faction Custom Donk', 'Willard', 'muscle', -2039755226),
	('fagaloa', 0, 57546, 'Fagaloa', 'Vulcar', 'sportsclassics', 1617472902),
	('faggio', 0, 14728, 'Faggio Sport', 'Pegassi', 'motorcycles', -1842748181),
	('faggio2', 0, 12263, 'Faggio Sport', 'Pegassi', 'motorcycles', 55628203),
	('faggio3', 0, 14291, 'Faggio Mod', 'Pegassi', 'motorcycles', -1289178744),
	('fbi', 0, 76794, 'FIB', 'Bravado', 'emergency', 1127131465),
	('fbi2', 0, 62617, 'FIB', 'Declasse', 'emergency', -1647941228),
	('fcr', 0, 24321, 'FCR 1000', 'Pegassi', 'motorcycles', 627535535),
	('fcr2', 0, 24491, 'FCR 1000 Custom', 'Pegassi', 'motorcycles', -757735410),
	('felon', 0, 76088, 'Felon', 'Lampadati', 'coupes', -391594584),
	('felon2', 0, 72343, 'Felon GT', 'Lampadati', 'coupes', -89291282),
	('feltzer2', 0, 82235, 'Feltzer', 'Benefactor', 'sports', -1995326987),
	('feltzer3', 0, 76445, 'Stirling GT', 'Benefactor', 'sportsclassics', -1566741232),
	('firebolt', 0, 64793, 'Firebolt ASP', 'Vapid', 'emergency', -973016778),
	('firetruk', 0, 64793, 'Fire Truck', 'MTL', 'emergency', 1938952078),
	('fixter', 0, 2835, 'Fixter', '', 'cycles', -836512833),
	('flashgt', 0, 73890, 'Flash GT', 'Vapid', 'sports', -1259134696),
	('flatbed', 0, 46633, 'Flatbed', 'MTL', 'industrial', 1353720154),
	('flatbed2', 0, 46633, 'Flatbed Custom', 'MTL', 'industrial', -1882910943),
	('fmj', 0, 88017, 'FMJ', 'Vapid', 'super', 1426219628),
	('forklift', 0, 17664, 'Forklift', 'HVY', 'utility', 1491375716),
	('formula', 0, 106933, 'PR4', 'Progen', 'openwheel', 340154634),
	('formula2', 0, 106571, 'R88', 'Ocelot', 'openwheel', -1960756985),
	('fq2', 0, 65442, 'FQ2', 'Fathom', 'suvs', -1137532101),
	('fr36', 0, 78667, 'FR36', 'Fathom', 'coupes', -465825307),
	('freecrawler', 0, 60453, 'Freecrawler', 'Canis', 'offroad', -54332285),
	('freight', 0, 194680, 'Freight Train (Locomotive)', '', 'trains', 1030400667),
	('freight2', 0, 194680, 'Freight Train (Chop Shop)', '', 'trains', -442229240),
	('freightcar', 0, 194680, 'Freight Train (Container)', '', 'trains', 184361638),
	('freightcar2', 0, 194680, 'Freight Train (Flatbed Trailer)', '', 'trains', -1108591207),
	('freightcar3', 0, 194680, 'Freight Train (Flatbed Trailer)', '', 'trains', -1874009509),
	('freightcont1', 0, 194680, 'Freight Train (Container)', '', 'trains', 920453016),
	('freightcont2', 0, 194680, 'Freight Train (Lando Container)', '', 'trains', 240201337),
	('freightgrain', 0, 194680, 'Freight Train (Grain Trailer)', '', 'trains', 642617954),
	('freighttrailer', 0, 5668, 'Army Trailer', '', 'utility', -777275802),
	('frogger', 0, 6367865, 'Frogger', 'Maibatsu', 'helicopters', 744705981),
	('frogger2', 0, 6367865, 'Frogger (Trevor Philips Enterprises)', 'Maibatsu', 'helicopters', 1949211328),
	('fugitive', 0, 67317, 'Fugitive', 'Cheval', 'sedans', 1909141499),
	('furia', 0, 83110, 'Furia', 'Grotti', 'super', 960812448),
	('furoregt', 0, 84346, 'Furore GT', 'Lampadati', 'sports', -1089039904),
	('fusilade', 0, 81251, 'Fusilade', 'Schyster', 'sports', 499169875),
	('futo', 0, 74336, 'Futo', 'Karin', 'sports', 2016857647),
	('futo2', 0, 75463, 'Futo GTX', 'Karin', 'sports', -1507230520),
	('gargoyle', 0, 25195, 'Gargoyle', 'Western', 'motorcycles', 741090084),
	('gauntlet', 0, 78237, 'Gauntlet', 'Bravado', 'muscle', -1800170043),
	('gauntlet2', 0, 80506, 'Redwood Gauntlet', 'Bravado', 'muscle', 349315417),
	('gauntlet3', 0, 73572, 'Gauntlet Classic', 'Bravado', 'muscle', 722226637),
	('gauntlet4', 0, 81048, 'Gauntlet Hellfire', 'Bravado', 'muscle', 1934384720),
	('gauntlet5', 0, 80250, 'Gauntlet Classic Custom', 'Bravado', 'muscle', -2122646867),
	('gauntlet6', 0, 81665, 'Hotring Hellfire', 'Bravado', 'sports', 1336514315),
	('gb200', 0, 74534, 'GB 200', 'Vapid', 'sports', 1909189272),
	('gburrito', 0, 61195, 'Gang Burrito (Lost MC)', 'Declasse', 'vans', -1745203402),
	('gburrito2', 0, 66162, 'Burrito Custom', 'Declasse', 'vans', 296357396),
	('glendale', 0, 65948, 'Glendale', 'Benefactor', 'sedans', 75131841),
	('glendale2', 0, 66105, 'Glendale Custom', 'Benefactor', 'sedans', -913589546),
	('gp1', 0, 84220, 'GP1', 'Progen', 'super', 1234311532),
	('graintrailer', 0, 5668, 'Grain Trailer', '', 'utility', 1019737494),
	('granger', 0, 60692, 'Granger', 'Declasse', 'suvs', -1775728740),
	('granger2', 0, 57057, 'Granger 3600LX', 'Declasse', 'suvs', -261346873),
	('greenwood', 0, 78897, 'Greenwood', 'Bravado', 'muscle', 40817712),
	('gresley', 0, 63694, 'Gresley', 'Bravado', 'suvs', -1543762099),
	('growler', 0, 82635, 'Growler', 'Pfister', 'sports', 1304459735),
	('gt500', 0, 76158, 'GT500', 'Grotti', 'sportsclassics', -2079788230),
	('guardian', 0, 65628, 'Guardian', 'Vapid', 'industrial', -2107990196),
	('habanero', 0, 65442, 'Habanero', 'Emperor', 'suvs', 884422927),
	('hakuchou', 0, 25975, 'Hakuchou', 'Shitzu', 'motorcycles', 1265391242),
	('hakuchou2', 0, 27374, 'Hakuchou Drag', 'Shitzu', 'motorcycles', -255678177),
	('halftrack', 0, 34933, 'Half-track', 'Bravado', 'military', -32236122),
	('handler', 0, 14549, 'Dock Handler', 'HVY', 'industrial', 444583674),
	('hardy', 0, 22789, 'Hardy', 'Annis', 'sedans', 1580292663),
	('hauler', 0, 48240, 'Hauler', 'JoBuilt', 'commercial', 1518533038),
	('hauler2', 0, 70102, 'Hauler Custom', 'JoBuilt', 'commercial', 387748548),
	('havok', 0, 6462758, 'Havok', 'Nagasaki', 'helicopters', -1984275979),
	('hellion', 0, 66525, 'Hellion', 'Annis', 'offroad', -362150785),
	('hermes', 0, 68776, 'Hermes', 'Albany', 'muscle', 15219735),
	('hexer', 0, 22521, 'Hexer', 'LCC', 'motorcycles', 301427732),
	('hotknife', 0, 74328, 'Hotknife', 'Vapid', 'muscle', 37348240),
	('hotring', 0, 79724, 'Hotring Sabre', 'Declasse', 'sports', 1115909093),
	('howard', 0, 2587839, 'Howard NX-25', 'Buckingham', 'planes', -1007528109),
	('hunter', 0, 6546934, 'FH-1 Hunter', '', 'helicopters', -42959138),
	('huntley', 0, 74869, 'Huntley S', 'Enus', 'suvs', 486987393),
	('hustler', 0, 72900, 'Hustler', 'Vapid', 'muscle', 600450546),
	('hydra', 0, 2193367, 'Hydra', 'Mammoth', 'planes', 970385471),
	('ignus', 0, 87219, 'Ignus', 'Pegassi', 'super', -1444114309),
	('imorgon', 0, 76854, 'Imorgon', 'Överflöd', 'sports', -1132721664),
	('impaler', 0, 74584, 'Impaler', 'Declasse', 'muscle', -2096690334),
	('impaler2', 0, 84076, 'Apocalypse Impaler', 'Declasse', 'muscle', 1009171724),
	('impaler3', 0, 84076, 'Future Shock Impaler', 'Declasse', 'muscle', -1924800695),
	('impaler4', 0, 84076, 'Nightmare Impaler', 'Declasse', 'muscle', -1744505657),
	('impaler5', 0, 78875, 'Impaler SZ', 'Declasse', 'sedans', -478639183),
	('impaler6', 0, 77917, 'Impaler LX', 'Declasse', 'muscle', -178442374),
	('imperator', 0, 80296, 'Apocalypse Imperator', 'Vapid', 'muscle', 444994115),
	('imperator2', 0, 80296, 'Future Shock Imperator', 'Vapid', 'muscle', 1637620610),
	('imperator3', 0, 80296, 'Nightmare Imperator', 'Vapid', 'muscle', -755532233),
	('inductor', 0, 2607, 'Inductor', 'Coil', 'cycles', -897824023),
	('inductor2', 0, 2607, 'Junk Energy Inductor', 'Coil', 'cycles', -1983622024),
	('infernus', 0, 81077, 'Infernus', 'Pegassi', 'super', 418536135),
	('infernus2', 0, 79349, 'Infernus Classic', 'Pegassi', 'sportsclassics', -1405937764),
	('ingot', 0, 53344, 'Ingot', 'Vulcar', 'sedans', -1289722222),
	('innovation', 0, 23509, 'Innovation', 'LCC', 'motorcycles', -159126838),
	('insurgent', 0, 59045, 'Insurgent Pick-Up', 'HVY', 'offroad', -1860900134),
	('insurgent2', 0, 59045, 'Insurgent', 'HVY', 'offroad', 2071877360),
	('insurgent3', 0, 59045, 'Insurgent Pick-Up Custom', 'HVY', 'offroad', -1924433270),
	('intruder', 0, 65682, 'Intruder', 'Karin', 'sedans', 886934177),
	('issi2', 0, 69371, 'Issi', 'Weeny', 'compacts', -1177863319),
	('issi3', 0, 65593, 'Issi Classic', 'Weeny', 'compacts', 931280609),
	('issi4', 0, 74235, 'Apocalypse Issi', 'Weeny', 'compacts', 628003514),
	('issi5', 0, 74235, 'Future Shock Issi', 'Weeny', 'compacts', 1537277726),
	('issi6', 0, 74235, 'Nightmare Issi', 'Weeny', 'compacts', 1239571361),
	('issi7', 0, 70443, 'Issi Sport', 'Weeny', 'sports', 1854776567),
	('issi8', 0, 79711, 'Issi Rally', 'Weeny', 'suvs', 1550581940),
	('italigtb', 0, 86900, 'Itali GTB', 'Progen', 'super', -2048333973),
	('italigtb2', 0, 87587, 'Itali GTB Custom', 'Progen', 'super', -482719877),
	('italigto', 0, 87475, 'Itali GTO', 'Grotti', 'sports', -331467772),
	('italirsx', 0, 87682, 'Itali RSX', 'Grotti', 'sports', -1149725334),
	('iwagen', 0, 55888, 'I-Wagen', 'Obey', 'suvs', 662793086),
	('jackal', 0, 76324, 'Jackal', 'Ocelot', 'coupes', -624529134),
	('jb700', 0, 82400, 'JB 700', 'Dewbauchee', 'sportsclassics', 1051415893),
	('jb7002', 0, 82400, 'JB 700W', 'Dewbauchee', 'sportsclassics', 394110044),
	('jester', 0, 76685, 'Jester', 'Dinka', 'sports', -1297672541),
	('jester2', 0, 78165, 'Jester (Racecar)', 'Dinka', 'sports', -1106353882),
	('jester3', 0, 80462, 'Jester Classic', 'Dinka', 'sports', -214906006),
	('jester4', 0, 79879, 'Jester RR', 'Dinka', 'sports', -1582061455),
	('jester5', 0, 79879, 'Jester RR Widebody', 'Dinka', 'sports', 1484920335),
	('jet', 0, 1537948, 'Jet', '', 'planes', 1058115860),
	('jetmax', 0, 478680, 'Jetmax', 'Shitzu', 'boats', 861409633),
	('journey', 0, 52886, 'Journey', 'Zirconium', 'vans', -120287622),
	('journey2', 0, 52886, 'Journey II', 'Zirconium', 'vans', -1627077503),
	('jubilee', 0, 71210, 'Jubilee', 'Enus', 'suvs', 461465043),
	('jugular', 0, 81412, 'Jugular', 'Ocelot', 'sports', -208911803),
	('kalahari', 0, 59046, 'Kalahari', 'Canis', 'offroad', 92612664),
	('kamacho', 0, 67315, 'Kamacho', 'Canis', 'offroad', -121446169),
	('kanjo', 0, 73478, 'Blista Kanjo', 'Dinka', 'compacts', 409049982),
	('kanjosj', 0, 73789, 'Kanjo SJ', 'Dinka', 'coupes', -64075878),
	('khamelion', 0, 53292, 'Khamelion', 'Hijak', 'sports', 544021352),
	('khanjali', 0, 30243, 'TM-02 Khanjali', '', 'military', -1435527158),
	('komoda', 0, 83129, 'Komoda', 'Lampadati', 'sports', -834353991),
	('kosatka', 0, 624016, 'Kosatka', 'RUNE', 'boats', 1336872304),
	('krieger', 0, 87715, 'Krieger', 'Benefactor', 'super', -664141241),
	('kuruma', 0, 77445, 'Kuruma', 'Karin', 'sports', -1372848492),
	('kuruma2', 0, 75885, 'Kuruma (Armored)', 'Karin', 'sports', 410882957),
	('l35', 0, 64429, 'Walton L35', 'Declasse', 'offroad', -1763675285),
	('l352', 0, 44723, 'L35 Stock', 'Declasse', 'offroad', 691148275),
	('landstalker', 0, 61393, 'Landstalker', 'Dundreary', 'suvs', 1269098716),
	('landstalker2', 0, 62744, 'Landstalker XL', 'Dundreary', 'suvs', -838099166),
	('lazer', 0, 2374069, 'P-996 LAZER', 'Jobuilt', 'planes', -1281684762),
	('le7b', 0, 84125, 'RE-7B', 'Annis', 'super', -1232836011),
	('lectro', 0, 27225, 'Lectro', 'Principe', 'motorcycles', 640818791),
	('lguard', 0, 62617, 'Lifeguard', 'Declasse', 'emergency', 469291905),
	('limo2', 0, 65584, 'Turreted Limo', 'Benefactor', 'sedans', -114627507),
	('lm87', 0, 84509, 'LM87', 'Benefactor', 'super', -10917683),
	('locust', 0, 81371, 'Locust', 'Ocelot', 'sports', -941272559),
	('longfin', 0, 500680, 'Longfin', 'Shitzu', 'boats', 1861786828),
	('lurcher', 0, 78245, 'Lurcher', 'Albany', 'muscle', 2068293287),
	('luxor', 0, 1818934, 'Luxor', 'Buckingham', 'planes', 621481054),
	('luxor2', 0, 1834048, 'Luxor Deluxe', 'Buckingham', 'planes', -1214293858),
	('lynx', 0, 81739, 'Lynx', 'Ocelot', 'sports', 482197771),
	('mamba', 0, 81429, 'Mamba', 'Declasse', 'sportsclassics', -1660945322),
	('mammatus', 0, 1321065, 'Mammatus', 'JoBuilt', 'planes', -1746576111),
	('manana', 0, 60635, 'Manana', 'Albany', 'sportsclassics', -2124201592),
	('manana2', 0, 71516, 'Manana Custom', 'Albany', 'muscle', 1717532765),
	('manchez', 0, 23138, 'Manchez', 'Maibatsu', 'motorcycles', -1523428744),
	('manchez2', 0, 21545, 'Manchez Scout', 'Maibatsu', 'motorcycles', 1086534307),
	('manchez3', 0, 21632, 'Manchez Scout C', 'Maibatsu', 'motorcycles', 1384502824),
	('marquis', 0, 94680, 'Marquis', 'Dinka', 'boats', -1043459709),
	('marshall', 0, 57276, 'Marshall', 'Cheval', 'offroad', 1233534620),
	('massacro', 0, 83972, 'Massacro', 'Dewbauchee', 'sports', -142942670),
	('massacro2', 0, 83972, 'Massacro Racecar', 'Dewbauchee', 'sports', -631760477),
	('maverick', 0, 6031333, 'Maverick', 'Western', 'helicopters', -1660661558),
	('maverick2', 0, 6031333, 'Maverick', 'Higgins', 'helicopters', 347619240),
	('menacer', 0, 53078, 'Menacer', 'HVY', 'offroad', 2044532910),
	('mesa', 0, 57125, 'Mesa', 'Canis', 'suvs', 914654722),
	('mesa2', 0, 57125, 'Mesa (Snow)', 'Canis', 'suvs', -748008636),
	('mesa3', 0, 57125, 'Mesa (Merryweather)', 'Canis', 'offroad', -2064372143),
	('metrotrain', 0, 194680, 'Freight Train (Tram)', '', 'trains', 868868440),
	('michelli', 0, 74020, 'Michelli GT', 'Lampadati', 'sportsclassics', 1046206681),
	('microlight', 0, 987645, 'Ultralight', 'Nagasaki', 'planes', -1763555241),
	('miljet', 0, 1849116, 'Miljet', 'Buckingham', 'planes', 165154707),
	('minimus', 0, 38763, 'Minimus', 'Annis', 'sedans', -1101107018),
	('minitank', 0, 24911, 'Invade and Persuade Tank', '', 'military', -1254331310),
	('minivan', 0, 58370, 'Minivan', 'Vapid', 'vans', -310465116),
	('minivan2', 0, 58450, 'Minivan Custom', 'Vapid', 'vans', -1126264336),
	('mixer', 0, 53283, 'Mixer', 'HVY', 'industrial', -784816453),
	('mixer2', 0, 53283, 'Mixer', 'HVY', 'industrial', 475220373),
	('mogul', 0, 1489140, 'Mogul', 'Mammoth', 'planes', -749299473),
	('molotok', 0, 2145700, 'V-65 Molotok', '', 'planes', 1565978651),
	('monroe', 0, 82544, 'Monroe', 'Pegassi', 'sportsclassics', -433375717),
	('monster', 0, 57276, 'Liberator', 'Vapid', 'offroad', -845961253),
	('monster3', 0, 64365, 'Apocalypse Sasquatch', 'Bravado', 'offroad', 1721676810),
	('monster4', 0, 64365, 'Future Shock Sasquatch', 'Bravado', 'offroad', 840387324),
	('monster5', 0, 64365, 'Nightmare Sasquatch', 'Bravado', 'offroad', -715746948),
	('monstrociti', 0, 68406, 'MonstroCiti', 'Maibatsu', 'offroad', 802856453),
	('moonbeam', 0, 68586, 'Moonbeam', 'Declasse', 'muscle', 525509695),
	('moonbeam2', 0, 68586, 'Moonbeam Custom', 'Declasse', 'muscle', 1896491931),
	('mower', 0, 12234, 'Lawn Mower', 'Jack Sheepe', 'utility', 1783355638),
	('mule', 0, 47273, 'Mule', 'Maibatsu', 'commercial', 904750859),
	('mule2', 0, 47273, 'Mule (Ramp Door)', 'Maibatsu', 'commercial', -1050465301),
	('mule3', 0, 52599, 'Mule (Heist)', 'Maibatsu', 'commercial', -2052737935),
	('mule4', 0, 47273, 'Mule Custom', 'Maibatsu', 'commercial', 1945374990),
	('mule5', 0, 52599, 'Box Truck Mule', 'Maibatsu', 'commercial', 1343932732),
	('nebula', 0, 62877, 'Nebula Turbo', 'Vulcar', 'sportsclassics', -882629065),
	('nemesis', 0, 23612, 'Nemesis', 'Principe', 'motorcycles', -634879114),
	('neo', 0, 85696, 'Neo', 'Vysser', 'sports', -1620126302),
	('neon', 0, 65765, 'Neon', 'Pfister', 'sports', -1848994066),
	('nero', 0, 87515, 'Nero', 'Truffade', 'super', 1034187331),
	('nero2', 0, 88062, 'Nero Custom', 'Truffade', 'super', 1093792632),
	('nightblade', 0, 24551, 'Nightblade', 'Western', 'motorcycles', -1606187161),
	('nightshade', 0, 67005, 'Nightshade', 'Imponte', 'muscle', -1943285540),
	('nightshark', 0, 61604, 'Nightshark', 'HVY', 'offroad', 433954513),
	('nimbus', 0, 1896246, 'Nimbus', 'Buckingham', 'planes', -1295027632),
	('ninef', 0, 81139, '9F', 'Obey', 'sports', 1032823388),
	('ninef2', 0, 81139, '9F Cabrio', 'Obey', 'sports', -1461482751),
	('niobe', 0, 81139, 'Niobe', 'Übermacht', 'sports', 1881415402),
	('nokota', 0, 2079976, 'P-45 Nokota', '', 'planes', 1036591958),
	('novak', 0, 78077, 'Novak', 'Lampadati', 'suvs', -1829436850),
	('omnis', 0, 73163, 'Omnis', 'Obey', 'sports', -777172681),
	('omnisegt', 0, 80374, 'Omnis e-GT', 'Obey', 'sports', -505223465),
	('openwheel1', 0, 106997, 'BR8', 'Benefactor', 'openwheel', 1492612435),
	('openwheel2', 0, 107315, 'DR1', 'Declasse', 'openwheel', 1181339704),
	('oppressor', 0, 76316, 'Oppressor', 'Pegassi', 'motorcycles', 884483972),
	('oppressor2', 0, 74148, 'Oppressor Mk II', 'Pegassi', 'motorcycles', 2069146067),
	('oracle', 0, 75192, 'Oracle XS', 'Übermacht', 'coupes', 1348744438),
	('oracle2', 0, 76907, 'Oracle', 'Übermacht', 'coupes', -511601230),
	('osiris', 0, 82889, 'Osiris', 'Pegassi', 'super', 1987142870),
	('outlaw', 0, 60938, 'Outlaw', 'Nagasaki', 'offroad', 408825843),
	('packer', 0, 60714, 'Packer', 'MTL', 'commercial', 569305213),
	('panthere', 0, 82311, 'Panthere', 'Toundra', 'sports', 2100457220),
	('panto', 0, 67549, 'Panto', 'Benefactor', 'compacts', -431692672),
	('paradise', 0, 63310, 'Paradise', 'Bravado', 'vans', 1488164764),
	('paragon', 0, 75255, 'Paragon', 'Enus', 'sports', -447711397),
	('paragon2', 0, 74900, 'Paragon R (Armored)', 'Enus', 'sports', 1416466158),
	('paragon3', 0, 74900, 'Paragon S', 'Enus', 'sports', -946047670),
	('pariah', 0, 81207, 'Pariah', 'Ocelot', 'sports', 867799010),
	('patriot', 0, 63246, 'Patriot', 'Mammoth', 'suvs', -808457413),
	('patriot2', 0, 59238, 'Patriot Stretch', 'Mammoth', 'suvs', -420911112),
	('patriot3', 0, 62402, 'Mil-Spec Patriot', 'Mammoth', 'offroad', -670086588),
	('patrolboat', 0, 430680, 'Kurtz 31 Patrol Boat', '', 'boats', -276744698),
	('pbus', 0, 46633, 'Prison Bus', 'Brute', 'emergency', -2007026063),
	('pbus2', 0, 38412, 'Festival Bus', 'Brute', 'service', 345756458),
	('pcj', 0, 20997, 'PCJ-600', 'Shitzu', 'motorcycles', -909201658),
	('penetrator', 0, 81919, 'Penetrator', 'Ocelot', 'super', -1758137366),
	('penumbra', 0, 67839, 'Penumbra', 'Maibatsu', 'sports', -377465520),
	('penumbra2', 0, 74920, 'Penumbra FF', 'Maibatsu', 'sports', -631322662),
	('peyote', 0, 60635, 'Peyote', 'Vapid', 'sportsclassics', 1830407356),
	('peyote2', 0, 77875, 'Peyote Gasser', 'Vapid', 'muscle', -1804415708),
	('peyote3', 0, 70150, 'Peyote Custom', 'Vapid', 'sportsclassics', 1107404867),
	('pfister811', 0, 88499, '811', 'Pfister', 'super', -1829802492),
	('phantom', 0, 56656, 'Phantom', 'JoBuilt', 'commercial', -2137348917),
	('phantom2', 0, 72230, 'Phantom Wedge', 'JoBuilt', 'commercial', -1649536104),
	('phantom3', 0, 69772, 'Phantom Custom', 'JoBuilt', 'commercial', 177270108),
	('phantom4', 0, 56656, 'Phantom (Christmas)', 'JoBuilt', 'commercial', -129283887),
	('phoenix', 0, 78433, 'Phoenix', 'Imponte', 'muscle', -2095439403),
	('picador', 0, 67839, 'Picador', 'Cheval', 'muscle', 1507916787),
	('pigalle', 0, 82282, 'Pigalle', 'Lampadati', 'sportsclassics', 1078682497),
	('pipistrello', 0, 82282, 'Pipistrello', 'Överflöd', 'super', -223461503),
	('pizzaboy', 0, 82282, 'Pizza Boy', 'Pegassi', 'motorcycles', 1968807591),
	('polcaracara', 0, 81768, 'Caracara Pursuit', 'Vapid', 'emergency', -1948949064),
	('polcoquette4', 0, 81768, 'Coquette D10 Pursuit', 'Vapid', 'emergency', 2042703219),
	('poldominator10', 0, 81768, 'Dominator FX Interceptor', 'Vapid', 'emergency', -773802025),
	('poldorado', 0, 81768, 'Dorado Cruiser', 'Bravado', 'emergency', -1628000569),
	('polfaction2', 0, 81768, 'Outreach Faction', 'Willard', 'emergency', -1628000569),
	('polgauntlet', 0, 81768, 'Gauntlet Interceptor', 'Bravado', 'emergency', -1233767450),
	('polgreenwood', 0, 81768, 'Greenwood Cruiser', 'Bravado', 'emergency', 1737348074),
	('police', 0, 71053, 'Police Cruiser', 'Vapid', 'emergency', 2046537925),
	('police2', 0, 76794, 'Police Cruiser', 'Buffalo', 'emergency', -1627000575),
	('police3', 0, 80470, 'Police Cruiser (Interceptor)', 'Vapid', 'emergency', 1912215274),
	('police4', 0, 71053, 'Unmarked Cruiser', 'Vapid', 'emergency', -1973172295),
	('police5', 0, 71053, 'Stanier LE Cruiser', 'Vapid', 'emergency', -1674384553),
	('policeb', 0, 23078, 'Police Bike', 'Western', 'emergency', -34623805),
	('policeb2', 0, 32000, 'Police Bike', 'Western', 'emergency', -1921512137),
	('policeold1', 0, 58720, 'Police Rancher', 'Declasse', 'emergency', -1536924937),
	('policeold2', 0, 71053, 'Police Roadcruiser', 'Albany', 'emergency', -1779120616),
	('policet', 0, 61195, 'Police Transporter', 'Declasse', 'emergency', 456714581),
	('policet3', 0, 61195, 'Burrito (Bail Enforcement)', 'Declasse', 'emergency', -1444856003),
	('polimpaler5', 0, 61195, 'Impaler SZ Cruiser', 'Declasse', 'emergency', 1249425552),
	('polimpaler6', 0, 61195, 'Impaler LX Cruiser', 'Declasse', 'emergency', 1452003510),
	('polmav', 0, 6293144, 'Police Maverick', 'Buckingham', 'helicopters', 353883353),
	('polterminus', 0, 61195, 'Terminus Patrol', 'Canis', 'emergency', -1321131184),
	('pony', 0, 61195, 'Pony', 'Brute', 'vans', -119658072),
	('pony2', 0, 61195, 'Pony (Smoke on the Water)', 'Brute', 'vans', 943752001),
	('postlude', 0, 69683, 'Postlude', 'Dinka', 'coupes', -294678663),
	('pounder', 0, 55550, 'Pounder', 'MTL', 'commercial', 2112052861),
	('pounder2', 0, 60635, 'Pounder Custom', 'MTL', 'commercial', 1653666139),
	('powersurge', 0, 23026, 'Powersurge', 'Western', 'motorcycles', -1386336041),
	('prairie', 0, 67519, 'Prairie', 'Bollokan', 'compacts', -1450650718),
	('pranger', 0, 62617, 'Park Ranger', 'Declasse', 'emergency', 741586030),
	('predator', 0, 412680, 'Police Predator', '', 'boats', -488123221),
	('premier', 0, 63694, 'Premier', 'Declasse', 'sedans', -1883869285),
	('previon', 0, 78200, 'Previon', 'Karin', 'coupes', 1416471345),
	('primo', 0, 64174, 'Primo', 'Albany', 'sedans', -1150599089),
	('primo2', 0, 64174, 'Primo Custom', 'Albany', 'sedans', -2040426790),
	('proptrailer', 0, 5668, 'Prop Trailer', '', 'utility', 356391690),
	('prototipo', 0, 88458, 'X80 Proto', 'Grotti', 'super', 2123327359),
	('pyro', 0, 2140960, 'Pyro', 'Buckingham', 'planes', -1386191424),
	('r300', 0, 79467, '300R', 'Annis', 'sports', 1076201208),
	('radi', 0, 65522, 'Radius', 'Vapid', 'suvs', -1651067813),
	('raiden', 0, 64370, 'Raiden', 'Coil', 'sports', -1529242755),
	('raiju', 0, 2712193, 'F-160 Raiju', 'Mammoth', 'planes', 239897677),
	('raketrailer', 0, 5668, 'Trailer (Rake)', '', 'utility', 390902130),
	('rallytruck', 0, 67837, 'Dune', 'MTL', 'service', -2103821244),
	('rancherxl', 0, 58720, 'Rancher XL', 'Declasse', 'offroad', 1645267888),
	('rancherxl2', 0, 58720, 'Rancher XL (Snow)', 'Declasse', 'offroad', 1933662059),
	('rapidgt', 0, 83599, 'Rapid GT', 'Dewbauchee', 'sports', -1934452204),
	('rapidgt2', 0, 83599, 'Rapid GT Cabrio', 'Dewbauchee', 'sports', 1737773231),
	('rapidgt3', 0, 77766, 'Rapid GT Classic', 'Dewbauchee', 'sportsclassics', 2049897956),
	('rapidgt4', 0, 78543, 'Rapid GT X', 'Dewbauchee', 'sports', 1761301369),
	('raptor', 0, 72091, 'Raptor', 'BF', 'sports', -674927303),
	('ratbike', 0, 19441, 'Rat Bike', 'Western', 'motorcycles', 1873600305),
	('ratel', 0, 72415, 'Ratel', 'Vapid', 'offroad', -536105557),
	('ratloader', 0, 61779, 'Rat-Loader', 'Bravado', 'muscle', -667151410),
	('ratloader2', 0, 65562, 'Rat-Truck', 'Bravado', 'muscle', -589178377),
	('rcbandito', 0, 44530, 'RC Bandito', '', 'offroad', -286046740),
	('reaper', 0, 82990, 'Reaper', 'Pegassi', 'super', 234062309),
	('rebel', 0, 63694, 'Rusty Rebel', 'Karin', 'offroad', -1207771834),
	('rebel2', 0, 63694, 'Rebel', 'Karin', 'offroad', -2045594037),
	('rebla', 0, 77543, 'Rebla GTS', 'Übermacht', 'suvs', 83136452),
	('reever', 0, 26269, 'Reever', 'Western', 'motorcycles', 1993851908),
	('regina', 0, 50997, 'Regina', 'Dundreary', 'sedans', -14495224),
	('remus', 0, 78314, 'Remus', 'Annis', 'sports', 1377217886),
	('rentalbus', 0, 42321, 'Rental Shuttle Bus', 'Brute', 'service', -1098802077),
	('retinue', 0, 70738, 'Retinue', 'Vapid', 'sportsclassics', 1841130506),
	('retinue2', 0, 76099, 'Retinue MKII', 'Vapid', 'sportsclassics', 2031587082),
	('revolter', 0, 74872, 'Revolter', 'Übermacht', 'sports', -410205223),
	('rhapsody', 0, 68425, 'Rhapsody', 'Declasse', 'compacts', 841808271),
	('rhinehart', 0, 78276, 'Rhinehart', 'Übermacht', 'sedans', -1855505138),
	('rhino', 0, 30613, 'Rhino Tank', '', 'military', 782665360),
	('riata', 0, 66525, 'Riata', 'Vapid', 'offroad', -1532697517),
	('riot', 0, 56588, 'Police Riot', 'Brute', 'emergency', -1205689942),
	('riot2', 0, 59094, 'RCV', 'Brute', 'emergency', -1693015116),
	('ripley', 0, 38773, 'Ripley', 'HVY', 'utility', -845979911),
	('rocoto', 0, 67755, 'Rocoto', 'Obey', 'suvs', 2136773105),
	('rogue', 0, 2070400, 'Rogue', 'Western', 'planes', -975345305),
	('romero', 0, 53105, 'Romero Hearse', 'Chariot', 'sedans', 627094268),
	('rrocket', 0, 26257, 'Rampant Rocket', 'Western', 'motorcycles', 916547552),
	('rt3000', 0, 80216, 'RT3000', 'Dinka', 'sports', -452604007),
	('rubble', 0, 54789, 'Rubble', 'JoBuilt', 'industrial', -1705304628),
	('ruffian', 0, 24413, 'Ruffian', 'Pegassi', 'motorcycles', -893578776),
	('ruiner', 0, 80117, 'Ruiner', 'Imponte', 'muscle', -227741703),
	('ruiner2', 0, 186491, 'Ruiner 2000', 'Imponte', 'muscle', 941494461),
	('ruiner3', 0, 80117, 'Ruiner (Wrecked)', 'Imponte', 'muscle', 777714999),
	('ruiner4', 0, 80458, 'Ruiner ZZ-8', 'Imponte', 'muscle', 1706945532),
	('rumpo', 0, 63310, 'Rumpo', 'Bravado', 'vans', 1162065741),
	('rumpo2', 0, 63310, 'Rumpo (Deludamol)', 'Bravado', 'vans', -1776615689),
	('rumpo3', 0, 59206, 'Rumpo Custom', 'Bravado', 'vans', 1475773103),
	('ruston', 0, 78365, 'Ruston', 'Hijak', 'sports', 719660200),
	('s80', 0, 83208, 'S80RR', 'Annis', 'super', -324618589),
	('sabregt', 0, 77450, 'Sabre Turbo', 'Declasse', 'muscle', -1685021548),
	('sabregt2', 0, 77489, 'Sabre GT', 'Declasse', 'muscle', 223258115),
	('sadler', 0, 62297, 'Sadler', 'Vapid', 'utility', -599568815),
	('sadler2', 0, 62297, 'Sadler (Snow)', 'Vapid', 'utility', 734217681),
	('sanchez', 0, 20686, 'Sanchez (livery)', 'Maibatsu', 'motorcycles', 788045382),
	('sanchez2', 0, 20686, 'Sanchez', 'Maibatsu', 'motorcycles', -1453280962),
	('sanctus', 0, 24351, 'Sanctus', 'LCC', 'motorcycles', 1491277511),
	('sandking', 0, 63694, 'Sandking', 'Vapid', 'offroad', -1189015600),
	('sandking2', 0, 63694, 'Sandking SWB', 'Vapid', 'offroad', 989381445),
	('savage', 0, 6962237, 'Savage', '', 'helicopters', -82626025),
	('savestra', 0, 72617, 'Savestra', 'Annis', 'sportsclassics', 903794909),
	('sc1', 0, 79257, 'SC1', 'Übermacht', 'super', 1352136073),
	('scarab', 0, 39724, 'Apocalypse Scarab', 'HVY', 'military', -1146969353),
	('scarab2', 0, 39724, 'Future Shock Scarab', 'HVY', 'military', 1542143200),
	('scarab3', 0, 39724, 'Nightmare Scarab', 'HVY', 'military', -579747861),
	('schafter2', 0, 65682, 'Schafter', 'Benefactor', 'sedans', -1255452397),
	('schafter3', 0, 83088, 'Schafter V12', 'Benefactor', 'sports', -1485523546),
	('schafter4', 0, 65602, 'Schafter LWB', 'Benefactor', 'sports', 1489967196),
	('schafter5', 0, 83008, 'Schafter V12 (Armored)', 'Benefactor', 'sedans', -888242983),
	('schafter6', 0, 62476, 'Schafter LWB (Armored)', 'Benefactor', 'sedans', 1922255844),
	('schlagen', 0, 86368, 'Schlagen GT', 'Benefactor', 'sports', -507495760),
	('schwarzer', 0, 80250, 'Schwartzer', 'Benefactor', 'sports', -746882698),
	('scorcher', 0, 2782, 'Scorcher', 'PED', 'cycles', -186537451),
	('scramjet', 0, 370681, 'Scramjet', 'Declasse', 'super', -638562243),
	('scrap', 0, 52886, 'Scrap Truck', 'Vapid', 'utility', -1700801569),
	('seabreeze', 0, 2211729, 'Seabreeze', 'Western', 'planes', -392675425),
	('seashark', 0, 414680, 'Seashark', 'Speedophile', 'boats', -1030275036),
	('seashark2', 0, 414680, 'Seashark (Lifeguard)', 'Speedophile', 'boats', -616331036),
	('seashark3', 0, 414680, 'Seashark (Yacht)', 'Speedophile', 'boats', -311022263),
	('seasparrow', 0, 6293144, 'Sea Sparrow', '', 'helicopters', -726768679),
	('seasparrow2', 0, 7760028, 'Sparrow', '', 'helicopters', 1229411063),
	('seasparrow3', 0, 7760028, 'Sparrow (Prop)', '', 'helicopters', 1593933419),
	('seminole', 0, 61393, 'Seminole', 'Canis', 'suvs', 1221512915),
	('seminole2', 0, 64904, 'Seminole Frontier', 'Canis', 'suvs', -1810806490),
	('sentinel', 0, 75585, 'Sentinel', 'Übermacht', 'coupes', 1349725314),
	('sentinel2', 0, 75585, ' Sentinel XS', 'Übermacht', 'coupes', 873639469),
	('sentinel3', 0, 74166, 'Sentinel Classic', 'Übermacht', 'sports', 1104234922),
	('sentinel4', 0, 78990, 'Sentinel Classic Widebody', 'Übermacht', 'sports', -1356880839),
	('sentinel5', 0, 120435, 'Sentinel GTS', 'Übermacht', 'sports', -1585673997),
	('serrano', 0, 66517, 'Serrano', 'Benefactor', 'suvs', 1337041428),
	('seven70', 0, 84734, 'Seven-70', 'Dewbauchee', 'sports', -1757836725),
	('shamal', 0, 1818934, 'Shamal', 'Buckingham', 'planes', -1214505995),
	('sheava', 0, 81139, 'ETR1', 'Emperor', 'super', 819197656),
	('sheriff', 0, 71186, 'Sheriff Cruiser', 'Vapid', 'emergency', -1683328900),
	('sheriff2', 0, 62617, 'Sheriff SUV', 'Declasse', 'emergency', 1922257928),
	('shinobi', 0, 27244, 'Shinobi', 'Nagasaki', 'motorcycles', 1353120668),
	('shotaro', 0, 26899, 'Shotaro Concept', 'Nagasaki', 'motorcycles', -405626514),
	('skylift', 0, 5363475, 'Skylift', 'HVY', 'helicopters', 1044954915),
	('slamtruck', 0, 62937, 'Slam Truck', 'Vapid', 'utility', -1045911276),
	('slamvan', 0, 66207, 'Slam Van', 'Vapid', 'muscle', 729783779),
	('slamvan2', 0, 67165, 'Lost Slam Van', 'Vapid', 'muscle', 833469436),
	('slamvan3', 0, 67005, 'Slam Van Custom', 'Vapid', 'muscle', 1119641113),
	('slamvan4', 0, 68476, 'Apocalypse Slamvan', 'Vapid', 'muscle', -2061049099),
	('slamvan5', 0, 68476, 'Future Shock Slamvan', 'Vapid', 'muscle', 373261600),
	('slamvan6', 0, 68476, 'Nightmare Slamvan', 'Vapid', 'muscle', 1742022738),
	('sm722', 0, 80260, 'SM722', 'Benefactor', 'sports', 775514032),
	('sovereign', 0, 23078, 'Sovereign', 'Western', 'motorcycles', 743478836),
	('specter', 0, 81060, 'Specter', 'Dewbauchee', 'sports', 1886268224),
	('specter2', 0, 82332, 'Specter Custom', 'Dewbauchee', 'sports', 1074745671),
	('speeder', 0, 462680, 'Speeder (Yacht)', 'Pegassi', 'boats', 231083307),
	('speeder2', 0, 462680, 'Speeder', 'Pegassi', 'boats', 437538602),
	('speedo', 0, 66002, 'Speedo', 'Vapid', 'vans', -810318068),
	('speedo2', 0, 66002, 'Clown Van', 'Vapid', 'vans', 728614474),
	('speedo4', 0, 70653, 'Speedo Custom (Nightclub)', 'Vapid', 'vans', 219613597),
	('speedo5', 0, 70653, 'Speedo Custom', 'Vapid', 'vans', -44799464),
	('squaddie', 0, 63238, 'Squaddie', 'Mammoth', 'suvs', -102335483),
	('squalo', 0, 362680, 'Squalo', 'Shitzu', 'boats', 400514754),
	('stafford', 0, 62882, 'Stafford', 'Enus', 'sedans', 321186144),
	('stalion', 0, 74781, 'Stallion', 'Declasse', 'muscle', 1923400478),
	('stalion2', 0, 79092, 'Stallion Burgershot', 'Declasse', 'muscle', -401643538),
	('stanier', 0, 71053, 'Stanier', 'Vapid', 'sedans', -1477580979),
	('starling', 0, 5890500, 'LF-22 Starling', '', 'planes', -1700874274),
	('stinger', 0, 74712, 'Stinger', 'Grotti', 'sportsclassics', 1545842587),
	('stingergt', 0, 74712, 'Stinger GT', 'Grotti', 'sportsclassics', -2098947590),
	('stingertt', 0, 87213, 'Itali GTO Stinger TT', 'Grotti', 'sports', 1447690049),
	('stockade', 0, 56588, 'Stockade', 'Brute', 'commercial', 1747439474),
	('stockade3', 0, 56588, 'Stockade (Bobcat Security/Snow)', 'Brute', 'commercial', -214455498),
	('stockade4', 0, 500000, 'Bobcat Security Stockade', 'Brute', 'commercial', 1089816240),
	('stratum', 0, 68894, 'Stratum', 'Zirconium', 'sedans', 1723137093),
	('streamer216', 0, 1574232, 'Streamer216', 'Mammoth', 'planes', 191916658),
	('streiter', 0, 71204, 'Streiter', 'Benefactor', 'sports', 1741861769),
	('stretch', 0, 63950, 'Stretch', 'Dundreary', 'sedans', -1961627517),
	('strikeforce', 0, 1810529, 'B-11 Strikeforce', '', 'planes', 1692272545),
	('stromberg', 0, 76526, 'Stromberg', 'Ocelot', 'sportsclassics', 886810209),
	('stryder', 0, 26711, 'Stryder', 'Nagasaki', 'motorcycles', 301304410),
	('stunt', 0, 1702472, 'Mallard', 'Western Company', 'planes', -2122757008),
	('submersible', 0, 718616, 'Submersible', '', 'boats', 771711535),
	('submersible2', 0, 787416, 'Kraken', 'Kraken', 'boats', -1066334226),
	('sugoi', 0, 75269, 'Sugoi', 'Dinka', 'sports', 987469656),
	('sultan', 0, 74392, 'Sultan', 'Karin', 'sports', 970598228),
	('sultan2', 0, 77184, 'Sultan Custom', 'Karin', 'sports', 872704284),
	('sultan3', 0, 78067, 'Sultan Classic Custom', 'Karin', 'sports', -291021213),
	('sultanrs', 0, 82197, 'Sultan RS', 'Karin', 'super', -295689028),
	('suntrap', 0, 362680, 'Suntrap', 'Shitzu', 'boats', -282946103),
	('superd', 0, 74712, 'Super Diamond', 'Enus', 'sedans', 1123216662),
	('supervolito', 0, 6905749, 'SuperVolito', 'Buckingham', 'helicopters', 710198397),
	('supervolito2', 0, 6905749, 'SuperVolito Carbon', 'Buckingham', 'helicopters', -1671539132),
	('surano', 0, 83971, 'Surano', 'Benefactor', 'sports', 384071873),
	('surfer', 0, 34505, 'Surfer', 'BF', 'vans', 699456151),
	('surfer2', 0, 34505, 'Surfer', 'BF', 'vans', -1311240698),
	('surfer3', 0, 34505, 'Surfer Custom', 'BF', 'vans', -1035489563),
	('surge', 0, 40605, 'Surge', 'Cheval', 'sedans', -1894894188),
	('suzume', 0, 737584, 'Suzume', 'Overflöd', 'super', 687627128),
	('swift', 0, 6504898, 'Swift', 'Buckingham', 'helicopters', -339587598),
	('swift2', 0, 6588870, 'Swift Deluxe', 'Buckingham', 'helicopters', 1075432268),
	('swinger', 0, 81274, 'Swinger', 'Ocelot', 'sportsclassics', 500482303),
	('t20', 0, 83022, 'Progen T20', 'Progen', 'super', 1663218586),
	('taco', 0, 47273, 'Taco Van', 'Brute', 'vans', 1951180813),
	('tahoma', 0, 72249, 'Tahoma Coupe', 'Declasse', 'muscle', -461850249),
	('tailgater', 0, 64174, 'Tailgater', 'Obey', 'sedans', -1008861746),
	('tailgater2', 0, 77411, 'Tailgater S', 'Obey', 'sedans', -1244461404),
	('taipan', 0, 89537, 'Taipan', 'Cheval', 'super', -1134706562),
	('tampa', 0, 70442, 'Tampa', 'Declasse', 'muscle', 972671128),
	('tampa2', 0, 75751, 'Drift Tampa', 'Declasse', 'sports', -1071380347),
	('tampa3', 0, 75751, 'Weaponized Tampa', 'Declasse', 'muscle', -1210451983),
	('tampa4', 0, 48666, 'Tampa GT', 'Declasse', 'muscle', -1508420500),
	('tanker', 0, 5748, 'Tanker Trailer', '', 'utility', -730904777),
	('tanker2', 0, 5748, 'Tanker Trailer', '', 'utility', 1956216962),
	('tankercar', 0, 194680, 'Freight Train (Tanker Trailer)', '', 'trains', 586013744),
	('taxi', 0, 71053, 'Taxi', 'Vapid', 'service', -956048545),
	('technical', 0, 63854, 'Technical', 'Karin', 'offroad', -2096818938),
	('technical2', 0, 65910, 'Technical Aqua', 'Karin', 'offroad', 1180875963),
	('technical3', 0, 63854, 'Technical Custom', 'Karin', 'offroad', 1356124575),
	('tempesta', 0, 81980, 'Tempesta', 'Pegassi', 'super', 272929391),
	('tenf', 0, 82128, '10F', 'Obey', 'sports', -893984159),
	('tenf2', 0, 82729, '10F Widebody', 'Obey', 'sports', 274946574),
	('terbyte', 0, 50669, 'Terrorbyte', 'Benefactor', 'commercial', -1988428699),
	('terminus', 0, 71490, 'Terminus', 'Canis', 'offroad', 167522317),
	('tezeract', 0, 76330, 'Tezeract', 'Pegassi', 'super', 1031562256),
	('thrax', 0, 83929, 'Thrax', 'Truffade', 'super', 1044193113),
	('thrust', 0, 25865, 'Thrust', 'Dinka', 'motorcycles', 1836027715),
	('thruster', 0, 6768641, 'Thruster', 'Mammoth', 'military', 1489874736),
	('tigon', 0, 86363, 'Tigon', 'Lampadati', 'super', -1358197432),
	('tiptruck', 0, 47273, 'Tipper', 'Brute', 'industrial', 48339065),
	('tiptruck2', 0, 47273, 'Tipper', 'Brute', 'industrial', -947761570),
	('titan', 0, 1521752, 'Titan', '', 'planes', 1981688531),
	('titan2', 0, 1521752, 'Titan 250 D', 'Eberhard', 'planes', 858355070),
	('toreador', 0, 235089, 'Toreador', 'Pegassi', 'sportsclassics', 1455990255),
	('torero', 0, 78457, 'Torero', 'Pegassi', 'sportsclassics', 1504306544),
	('torero2', 0, 87548, 'Torero XO', 'Pegassi', 'super', -165394758),
	('tornado', 0, 60635, 'Tornado', 'Declasse', 'sportsclassics', 464687292),
	('tornado2', 0, 60635, 'Tornado Gang', 'Declasse', 'sportsclassics', 1531094468),
	('tornado3', 0, 60635, 'Tornado (Beater)', 'Declasse', 'sportsclassics', 1762279763),
	('tornado4', 0, 60635, 'Tornado (Mariachi)', 'Declasse', 'sportsclassics', -2033222435),
	('tornado5', 0, 60890, 'Tornado Custom', 'Declasse', 'sportsclassics', -1797613329),
	('tornado6', 0, 66096, 'Tornado Rat Rod', 'Declasse', 'sportsclassics', -1558399629),
	('toro', 0, 486680, 'Toro', 'Lampadati', 'boats', 1070967343),
	('toro2', 0, 486680, 'Toro (Yacht)', 'Lampadati', 'boats', 908897389),
	('toros', 0, 81091, 'Toros', 'Pegassi', 'suvs', -1168952148),
	('tourbus', 0, 42321, 'Tour Bus', 'Brute', 'service', 1941029835),
	('towtruck', 0, 57488, 'Tow Truck', 'Vapid', 'utility', -1323100960),
	('towtruck2', 0, 54821, 'Tow Truck (Small)', 'Vapid', 'utility', -442313018),
	('towtruck3', 0, 62901, 'Tow Truck (Beater)', 'Vapid', 'utility', -671564942),
	('towtruck4', 0, 62901, 'Tow Truck', 'Vapid', 'utility', -902029319),
	('tr2', 0, 5748, 'Trailer (Car Carrier)', '', 'utility', 2078290630),
	('tr3', 0, 5748, 'Trailer (Boat)', '', 'utility', 1784254509),
	('tr4', 0, 5748, 'Trailer (Packed Car Carrier)', '', 'utility', 2091594960),
	('tractor', 0, 22677, 'Tractor', '', 'utility', 1641462412),
	('tractor2', 0, 24703, 'Fieldmaster', 'Stanley', 'utility', -2076478498),
	('tractor3', 0, 24703, 'Fieldmaster (Snow)', 'Stanley', 'utility', 1445631933),
	('trailerlarge', 0, 5668, 'Mobile Operations Center', 'Pegasus', 'utility', 1502869817),
	('trailerlogs', 0, 5748, 'Trailer (Logs)', '', 'utility', 2016027501),
	('trailers', 0, 5668, 'Trailer (Container)', '', 'utility', -877478386),
	('trailers2', 0, 5668, 'Trailer (Box)', '', 'utility', -1579533167),
	('trailers3', 0, 5668, 'Trailer (Ramp box)', '', 'utility', -2058878099),
	('trailers4', 0, 5668, 'Trailer (Container)', '', 'utility', -1100548694),
	('trailers5', 0, 5668, 'Trailer (Christmas)', '', 'utility', -1334453816),
	('trailersmall', 0, 5668, 'Trailer (Storage/generator)', '', 'utility', 712162987),
	('trailersmall2', 0, 5668, 'Anti-Aircraft Trailer', 'Vom Feuer', 'military', -1881846085),
	('trash', 0, 59939, 'Trashmaster', 'Jobuilt', 'service', 1917016601),
	('trash2', 0, 59939, 'Trashmaster (Heist)', 'Jobuilt', 'service', -1255698084),
	('trflat', 0, 5668, 'Trailer (Flatbed)', '', 'utility', -1352468814),
	('tribike', 0, 3622, 'Whippet Race Bike', '', 'cycles', 1127861609),
	('tribike2', 0, 3622, 'Endurex Race Bike', '', 'cycles', -1233807380),
	('tribike3', 0, 3622, 'Tri-Cycles Race Bike', '', 'cycles', -400295096),
	('trophytruck', 0, 71559, 'Trophy Truck', 'Vapid', 'offroad', 101905590),
	('trophytruck2', 0, 71559, 'Desert Raid', 'Vapid', 'offroad', -663299102),
	('tropic', 0, 390680, 'Tropic', 'Shitzu', 'boats', 290013743),
	('tropic2', 0, 390680, 'Tropic (Yacht)', 'Shitzu', 'boats', 1448677353),
	('tropos', 0, 71140, 'Tropos Rallye', 'Lampadati', 'sports', 1887331236),
	('tug', 0, 67079, 'Tug', 'Buckingham', 'boats', -2100640717),
	('tula', 0, 1321065, 'Tula', 'Mammoth', 'planes', 1043222410),
	('tulip', 0, 80611, 'Tulip', 'Declasse', 'muscle', 1456744817),
	('tulip2', 0, 74746, 'Tulip M-100', 'Declasse', 'muscle', 268758436),
	('turismo2', 0, 81835, 'Turismo Classic', 'Grotti', 'sportsclassics', -982130927),
	('turismo3', 0, 83545, 'Turismo Omaggio', 'Grotti', 'super', -122993285),
	('turismor', 0, 85403, 'Grotti Turismo R', 'Grotti', 'super', 408192225),
	('tvtrailer', 0, 5668, 'Trailer (Fame or Shame)', '', 'utility', -1770643266),
	('tvtrailer2', 0, 5668, 'Trailer', '', 'utility', 471034616),
	('tyrant', 0, 88321, 'Tyrant', 'Överflöd', 'super', -376434238),
	('tyrus', 0, 84350, 'Tyrus', 'Progen', 'super', 2067820283),
	('uranus', 0, 50131, 'Uranus LozSpeed', 'Vapid', 'sportsclassics', 1534326199),
	('utillitruck', 0, 50131, 'Utility Truck (Cherry Picker)', 'Vapid', 'utility', 516990260),
	('utillitruck2', 0, 50131, 'Utility Truck (Cargo)', 'Vapid', 'utility', 887537515),
	('utillitruck3', 0, 50131, 'Utility Truck (Van)', 'Vapid', 'utility', 2132890591),
	('vacca', 0, 83666, 'Vacca', 'Pegassi', 'super', 338562499),
	('vader', 0, 22163, 'Vader', 'Shitzu', 'motorcycles', -140902153),
	('vagner', 0, 87808, 'Vagner', 'Dewbauchee', 'super', 1939284556),
	('vagrant', 0, 77576, 'Vagrant', 'Maxwell', 'offroad', 740289177),
	('valkyrie', 0, 6116097, 'Valkyrie', 'Buckingham', 'helicopters', -1600252419),
	('valkyrie2', 0, 6116097, 'Valkyrie MOD.0', 'Buckingham', 'helicopters', 1543134283),
	('vamos', 0, 75751, 'Vamos', 'Declasse', 'muscle', -49115651),
	('vectre', 0, 73202, 'Vectre', 'Emperor', 'sports', -1540373595),
	('velum', 0, 1439638, 'Velum', 'JoBuilt', 'planes', -1673356438),
	('velum2', 0, 1439638, 'Velum', 'JoBuilt', 'planes', 1077420264),
	('verlierer2', 0, 83280, 'Verlierer', 'Bravado', 'sports', 1102544804),
	('verus', 0, 16526, 'Verus', 'Dinka', 'offroad', 298565713),
	('vestra', 0, 1982877, 'Vestra', 'Buckingham', 'planes', 1341619767),
	('vetir', 0, 38828, 'Vetir', 'HVY', 'military', 2014313426),
	('veto', 0, 42608, 'Veto Classic', 'Dinka', 'sports', -857356038),
	('veto2', 0, 45282, 'Veto Modern', 'Dinka', 'sports', -1492917079),
	('vigero', 0, 77482, 'Vigero', 'Declasse', 'muscle', -825837129),
	('vigero2', 0, 82143, 'Vigero ZX', 'Declasse', 'muscle', -1758379524),
	('vigero3', 0, 81866, 'Vigero ZX Convertible', 'Declasse', 'muscle', 372621319),
	('vigilante', 0, 261085, 'Vigilante', 'Grotti', 'super', -1242608589),
	('vindicator', 0, 31055, 'Vindicator', 'Dinka', 'motorcycles', -1353081087),
	('virgo', 0, 60554, 'Virgo', 'Albany', 'muscle', -498054846),
	('virgo2', 0, 60758, 'Virgo Custom Classic', 'Dundreary', 'muscle', -899509638),
	('virgo3', 0, 60554, 'Virgo Custom Classic', 'Dundreary', 'muscle', 16646064),
	('virtue', 0, 76383, 'Virtue', 'Ocelot', 'super', 669204833),
	('viseris', 0, 78246, 'Viseris', 'Lampadati', 'sportsclassics', -391595372),
	('visione', 0, 85576, 'Visione', 'Grotti', 'super', -998177792),
	('vivanite', 0, 46334, 'Vivanite', 'Karin', 'suvs', -1372798934),
	('volatol', 0, 1570129, 'Volatol', '', 'planes', 447548909),
	('volatus', 0, 6589212, 'Volatus', 'Buckingham', 'helicopters', -1845487887),
	('voltic', 0, 60326, 'Voltic', 'Coil', 'super', -1622444098),
	('voltic2', 0, 180978, 'Rocket Voltic', 'Coil', 'super', 989294410),
	('voodoo', 0, 66162, 'Voodoo Custom', 'Declasse', 'muscle', 2006667053),
	('voodoo2', 0, 63070, 'Voodoo', 'Declasse', 'muscle', 523724515),
	('vorschlaghammer', 0, 25612, 'Vorschlaghammer', 'Benefactor', 'sedans', -1240172147),
	('vortex', 0, 25612, 'Vortex', 'Pegassi', 'motorcycles', -609625092),
	('vstr', 0, 79649, 'V-STR', 'Albany', 'sports', 1456336509),
	('warrener', 0, 64367, 'Warrener', 'Vulcar', 'sedans', 1373123368),
	('warrener2', 0, 67374, 'Warrener HKR', 'Vulcar', 'sedans', 579912970),
	('washington', 0, 71053, 'Washington', 'Albany', 'sedans', 1777363799),
	('wastelander', 0, 67837, 'Wastelander', 'MTL', 'service', -1912017790),
	('weevil', 0, 53983, 'Weevil', 'BF', 'compacts', 1644055914),
	('weevil2', 0, 83800, 'Weevil Custom', 'BF', 'muscle', -994371320),
	('windsor', 0, 79422, 'Windsor', 'Enus', 'coupes', 1581459400),
	('windsor2', 0, 79252, 'Windsor Drop', 'Enus', 'coupes', -1930048799),
	('winky', 0, 49504, 'Winky', 'Vapid', 'offroad', -210308634),
	('wolfsbane', 0, 19441, 'Wolfsbane', 'Western', 'motorcycles', -618617997),
	('woodlander', 0, 72500, 'Woodlander', 'Karin', 'suvs', 1966698497),
	('xa21', 0, 82892, 'XA-21', 'Ocelot', 'super', 917809321),
	('xls', 0, 72768, 'XLS', 'Benefactor', 'suvs', 1203490606),
	('xls2', 0, 72800, 'XLS (Armored)', 'Benefactor', 'suvs', -432008408),
	('yosemite', 0, 69338, 'Yosemite', 'Declasse', 'muscle', 1871995513),
	('yosemite1500', 0, 66896, 'Yosemite 1500', 'Declasse', 'offroad', -1896488056),
	('yosemite2', 0, 74171, 'Yosemite Drift', 'Declasse', 'muscle', 1693751655),
	('yosemite3', 0, 66896, 'Yosemite Rancher', 'Declasse', 'offroad', 67753863),
	('youga', 0, 55630, 'Youga', 'Bravado', 'vans', 65402552),
	('youga2', 0, 55630, 'Youga Classic', 'Bravado', 'vans', 1026149675),
	('youga3', 0, 63150, 'Youga Classic 4x4', 'Bravado', 'vans', 1802742206),
	('youga4', 0, 60252, 'Youga Custom', 'Vapid', 'vans', 1486521356),
	('youga5', 0, 60252, 'Youga Custom', 'Vapid', 'vans', -2028904199),
	('z190', 0, 73299, '190Z', 'Karin', 'sportsclassics', 838982985),
	('zeno', 0, 89601, 'Zeno', 'Överflöd', 'super', 655665811),
	('zentorno', 0, 82795, 'Zentorno', 'Pegassi', 'super', -1403128555),
	('zhaba', 0, 50950, 'Zhaba', 'RUNE', 'offroad', 1284356689),
	('zion', 0, 77752, 'Zion', 'Übermacht', 'coupes', -1122289213),
	('zion2', 0, 77752, 'Zion Cabrio', 'Übermacht', 'coupes', -1193103848),
	('zion3', 0, 74281, 'Zion Classic', 'Übermacht', 'sportsclassics', 1862507111),
	('zombiea', 0, 23182, 'Zombie Bobber', 'Western', 'motorcycles', -1009268949),
	('zombieb', 0, 23182, 'Zombie Chopper', 'Western', 'motorcycles', -570033273),
	('zorrusso', 0, 85159, 'Pegassi Zorrusso', 'Pegassi', 'super', -682108547),
	('zr350', 0, 79974, 'ZR350', 'Annis', 'sports', -1858654120),
	('zr380', 0, 83632, 'Apocalypse ZR380', 'Annis', 'sports', 540101442),
	('zr3802', 0, 83632, 'Future Shock ZR380', 'Annis', 'sports', -1106120762),
	('zr3803', 0, 83632, 'Nightmare ZR380', 'Annis', 'sports', -1478704292),
	('ztype', 0, 84821, 'Z-Type', 'Truffade', 'sportsclassics', 758895617);

-- Dumping structure for table republica.vrs_mechanic_employees
CREATE TABLE IF NOT EXISTS `vrs_mechanic_employees` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `shop_id` varchar(50) NOT NULL,
  `citizenid` varchar(50) NOT NULL,
  `grade` int(11) NOT NULL DEFAULT 0,
  `hired_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_shop_citizen` (`shop_id`,`citizenid`),
  KEY `idx_shop` (`shop_id`),
  KEY `idx_citizen` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.vrs_mechanic_employees: ~0 rows (approximately)

-- Dumping structure for table republica.vrs_mechanic_price_overrides
CREATE TABLE IF NOT EXISTS `vrs_mechanic_price_overrides` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `shop_id` varchar(50) NOT NULL,
  `service` varchar(50) NOT NULL,
  `price` float NOT NULL DEFAULT 0,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_shop_service` (`shop_id`,`service`),
  KEY `idx_shop` (`shop_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.vrs_mechanic_price_overrides: ~0 rows (approximately)

-- Dumping structure for table republica.vrs_mechanic_service_logs
CREATE TABLE IF NOT EXISTS `vrs_mechanic_service_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `shop_id` varchar(50) NOT NULL DEFAULT 'system',
  `mechanic_citizenid` varchar(50) DEFAULT NULL,
  `mechanic_name` varchar(100) DEFAULT NULL,
  `customer_citizenid` varchar(50) DEFAULT NULL,
  `customer_name` varchar(100) DEFAULT NULL,
  `service_type` varchar(50) NOT NULL DEFAULT 'unknown',
  `amount` float DEFAULT 0,
  `description` text DEFAULT '',
  `work_order_id` int(11) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_shop` (`shop_id`),
  KEY `idx_mechanic` (`mechanic_citizenid`),
  KEY `idx_customer` (`customer_citizenid`),
  KEY `idx_created` (`created_at`),
  KEY `idx_type` (`service_type`)
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.vrs_mechanic_service_logs: ~35 rows (approximately)
INSERT INTO `vrs_mechanic_service_logs` (`id`, `shop_id`, `mechanic_citizenid`, `mechanic_name`, `customer_citizenid`, `customer_name`, `service_type`, `amount`, `description`, `work_order_id`, `created_at`) VALUES
	(1, 'mecanica_central', '2', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'work_order_create', 0, '{"orderId":1,"plate":"22BWG730","action":"work_order_create","source":2,"shopId":"mecanica_central"}', NULL, '2026-03-18 10:43:11'),
	(2, 'mecanica_central', '3', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 210, '{"action":"parts_purchase","shopId":"mecanica_central","source":3,"item":"steel","quantity":1,"amount":210}', NULL, '2026-03-18 14:24:34'),
	(3, 'mecanica_central', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 3200, '{"action":"parts_purchase","source":1,"amount":3200,"shopId":"mecanica_central","quantity":1,"item":"mechanic_tablet"}', NULL, '2026-03-18 14:36:48'),
	(4, 'mecanica_central', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 375, '{"action":"parts_purchase","source":1,"amount":375,"shopId":"mecanica_central","quantity":5,"item":"scrap_metal"}', NULL, '2026-03-18 15:11:23'),
	(5, 'mecanica_central', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 900, '{"action":"parts_purchase","source":1,"amount":900,"shopId":"mecanica_central","quantity":10,"item":"plastic"}', NULL, '2026-03-18 15:11:31'),
	(6, 'mecanica_central', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'repair', 0, '{"action":"repair","source":1,"plate":"02WBU772","part":"body","shopId":"mecanica_central","type":"shop"}', NULL, '2026-03-18 15:12:19'),
	(7, 'mecanica_central', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'repair', 0, '{"source":1,"type":"shop","plate":"06AOX941","action":"repair","part":"body","shopId":"mecanica_central"}', NULL, '2026-03-18 15:59:11'),
	(8, 'mecanica_central', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 12800, '{"source":1,"amount":12800,"action":"parts_purchase","quantity":1,"shopId":"mecanica_central","item":"engine_upgrade_v8"}', NULL, '2026-03-18 15:59:40'),
	(9, 'mecanica_central', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 1650, '{"source":1,"amount":1650,"action":"parts_purchase","quantity":1,"shopId":"mecanica_central","item":"repairkit_advanced"}', NULL, '2026-03-18 16:01:39'),
	(10, 'mecanica_praia', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 2250, '{"source":1,"action":"parts_purchase","shopId":"mecanica_praia","quantity":5,"amount":2250,"item":"cleaning_kit"}', NULL, '2026-03-21 05:46:22'),
	(11, 'mecanica_praia', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'work_order_create', 0, '{"action":"work_order_create","orderId":2,"shopId":"mecanica_praia","source":1,"plate":"69MUJ536"}', NULL, '2026-03-21 06:00:07'),
	(12, 'mecanica_praia', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 1850, '{"source":1,"action":"parts_purchase","quantity":1,"shopId":"mecanica_praia","amount":1850,"item":"engine_parts"}', NULL, '2026-03-21 16:45:05'),
	(13, 'mecanica_praia', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 1320, '{"source":1,"action":"parts_purchase","quantity":1,"shopId":"mecanica_praia","amount":1320,"item":"suspension_parts"}', NULL, '2026-03-21 16:47:38'),
	(14, 'mecanica_praia', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 720, '{"source":1,"action":"parts_purchase","quantity":1,"shopId":"mecanica_praia","amount":720,"item":"spare_tyre"}', NULL, '2026-03-21 16:47:40'),
	(15, 'mecanica_praia', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 6100, '{"source":1,"action":"parts_purchase","quantity":1,"shopId":"mecanica_praia","amount":6100,"item":"ecu_stage_2"}', NULL, '2026-03-21 16:47:58'),
	(16, 'mecanica_praia', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 9700, '{"source":1,"action":"parts_purchase","quantity":1,"shopId":"mecanica_praia","amount":9700,"item":"turbo_kit"}', NULL, '2026-03-21 16:48:04'),
	(17, 'mecanica_praia', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 12800, '{"source":1,"action":"parts_purchase","quantity":1,"shopId":"mecanica_praia","amount":12800,"item":"engine_upgrade_v8"}', NULL, '2026-03-21 16:48:07'),
	(18, 'mecanica_praia', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 2200, '{"source":1,"action":"parts_purchase","quantity":1,"shopId":"mecanica_praia","amount":2200,"item":"mechanic_toolbox"}', NULL, '2026-03-21 16:48:30'),
	(19, 'mecanica_praia', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 1650, '{"source":1,"action":"parts_purchase","quantity":1,"shopId":"mecanica_praia","amount":1650,"item":"repairkit_advanced"}', NULL, '2026-03-21 16:50:27'),
	(20, 'mecanica_praia', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 225, '{"source":1,"action":"parts_purchase","quantity":3,"shopId":"mecanica_praia","amount":225,"item":"scrap_metal"}', NULL, '2026-03-21 16:50:34'),
	(21, 'mecanica_praia', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 3200, '{"source":1,"action":"parts_purchase","quantity":1,"shopId":"mecanica_praia","amount":3200,"item":"mechanic_tablet"}', NULL, '2026-03-21 16:50:38'),
	(22, 'mecanica_praia', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 450, '{"source":1,"action":"parts_purchase","quantity":5,"shopId":"mecanica_praia","amount":450,"item":"plastic"}', NULL, '2026-03-21 16:51:34'),
	(23, 'mecanica_praia', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 3700, '{"source":1,"action":"parts_purchase","quantity":2,"shopId":"mecanica_praia","amount":3700,"item":"engine_parts"}', NULL, '2026-03-21 16:51:43'),
	(24, 'mecanica_praia', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'repair', 0, '{"source":1,"action":"repair","part":"engine","shopId":"mecanica_praia","type":"shop","plate":"45DIA085"}', NULL, '2026-03-21 16:52:12'),
	(25, 'mecanica_praia', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'repair', 0, '{"source":1,"action":"repair","part":"body","shopId":"mecanica_praia","type":"shop","plate":"45DIA085"}', NULL, '2026-03-21 16:52:54'),
	(26, 'mecanica_praia', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 2900, '{"source":1,"action":"parts_purchase","quantity":2,"shopId":"mecanica_praia","amount":2900,"item":"radiator_parts"}', NULL, '2026-03-21 16:53:39'),
	(27, 'mecanica_praia', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 620, '{"source":1,"action":"parts_purchase","quantity":2,"shopId":"mecanica_praia","amount":620,"item":"coolant"}', NULL, '2026-03-21 16:53:53'),
	(28, 'mecanica_praia', 'JTW7MEXP', 'Maka  Patron', 'ZDQ8H6H9', 'TiãO Dev', 'billing', 1000, 'Serviço mecânico', NULL, '2026-03-21 18:18:29'),
	(29, 'mecanica_praia', '1', 'Maka  Patron (JTW7MEXP)', NULL, NULL, 'billing', 1000, '{"target":2,"action":"billing","amount":1000,"source":1,"shopId":"mecanica_praia"}', NULL, '2026-03-21 18:18:29'),
	(30, 'mecanica_praia', 'JTW7MEXP', 'Maka  Patron', 'ZDQ8H6H9', 'TiãO Dev', 'billing', 1000, 'Serviço mecânico', NULL, '2026-03-21 18:18:44'),
	(31, 'mecanica_praia', '1', 'Maka  Patron (JTW7MEXP)', NULL, NULL, 'billing', 1000, '{"target":2,"action":"billing","amount":1000,"source":1,"shopId":"mecanica_praia"}', NULL, '2026-03-21 18:18:44'),
	(32, 'mecanica_praia', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 720, '{"amount":720,"item":"spare_tyre","action":"parts_purchase","source":1,"quantity":1,"shopId":"mecanica_praia"}', NULL, '2026-03-21 20:06:26'),
	(33, 'mecanica_praia', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 12800, '{"item":"engine_upgrade_v8","shopId":"mecanica_praia","quantity":1,"amount":12800,"action":"parts_purchase","source":1}', NULL, '2026-03-21 20:45:28'),
	(34, 'mecanica_praia', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'parts_purchase', 260, '{"item":"oil_can","shopId":"mecanica_praia","quantity":1,"amount":260,"action":"parts_purchase","source":1}', NULL, '2026-03-21 20:56:56'),
	(35, 'mecanica_praia', '1', 'TiãO Dev (ZDQ8H6H9)', NULL, NULL, 'oil_change', 0, '{"action":"oil_change","plate":"41RYN230","shopId":"mecanica_praia","source":1}', NULL, '2026-03-21 20:57:23');

-- Dumping structure for table republica.vrs_mechanic_shops
CREATE TABLE IF NOT EXISTS `vrs_mechanic_shops` (
  `name` varchar(50) NOT NULL,
  `label` varchar(100) NOT NULL,
  `balance` float NOT NULL DEFAULT 0,
  `owner_citizenid` varchar(50) DEFAULT NULL,
  `owner_name` varchar(100) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.vrs_mechanic_shops: ~0 rows (approximately)

-- Dumping structure for table republica.vrs_mechanic_vehicle_status
CREATE TABLE IF NOT EXISTS `vrs_mechanic_vehicle_status` (
  `plate` varchar(20) NOT NULL,
  `status` longtext NOT NULL DEFAULT '{}',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`plate`),
  KEY `idx_updated` (`updated_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.vrs_mechanic_vehicle_status: ~140 rows (approximately)
INSERT INTO `vrs_mechanic_vehicle_status` (`plate`, `status`, `created_at`, `updated_at`) VALUES
	('00JGK851', '{"body":0,"transmission":100.0,"engine":607.6412267684937,"fuel_tank":80.3820613384247,"axle":47.68549690246583,"suspension":34.60687112808225,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":21.52824535369872,"battery":73.84274845123288}', '2026-03-19 19:23:47', '2026-03-19 20:53:53'),
	('00LAU076', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 19:48:49', '2026-03-19 20:53:53'),
	('01OUT216', '{"body":546.9950866699219,"transmission":100.0,"engine":864.0985260009765,"fuel_tank":93.20492630004886,"axle":81.87980346679687,"suspension":77.3497543334961,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":72.81970520019532,"battery":90.93990173339843}', '2026-03-19 19:58:49', '2026-03-19 20:53:53'),
	('01QFB977', '{"transmission":100.0,"radiator":100.0,"suspension":100.0,"fuel_tank":100.0,"body":1000.0,"engine":1000.0,"clutch":100.0,"oil":100.0,"brakes":100.0,"battery":100.0,"axle":100.0}', '2026-03-19 21:11:39', '2026-03-19 21:39:29'),
	('02ANO553', '{"fuel_tank":100.0,"suspension":100.0,"clutch":100.0,"engine":1000.0,"battery":100.0,"body":1000.0,"radiator":100.0,"brakes":100.0,"axle":100.0,"transmission":100.0,"oil":100.0}', '2026-03-20 10:02:07', '2026-03-20 10:33:08'),
	('02WBU772', '{"brakes":99.85780665893556,"engine":809.6044982910157,"clutch":100.0,"suspension":68.26741638183595,"fuel_tank":90.48022491455078,"axle":74.61393310546873,"body":853.5419311523438,"battery":87.30696655273437,"transmission":100.0,"radiator":61.92089965820313,"oil":99.14996661140325}', '2026-03-18 14:39:36', '2026-03-18 15:19:59'),
	('03GHL220', '{"body":640.0,"transmission":100.0,"engine":892.0,"fuel_tank":94.60000000000001,"axle":85.60000000000001,"suspension":82.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":78.39999999999999,"battery":92.8}', '2026-03-19 18:43:46', '2026-03-19 20:53:53'),
	('03HXE991', '{"body":0,"transmission":100.0,"engine":0,"fuel_tank":34.42920013427731,"axle":0,"suspension":0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":0,"battery":12.57226684570311}', '2026-03-19 17:43:44', '2026-03-19 20:53:53'),
	('03WCM561', '{"transmission":100.0,"clutch":99.8688504907608,"oil":99.21226511459348,"engine":1000.0,"body":1000.0,"battery":100.0,"fuel_tank":100.0,"axle":100.0,"radiator":100.0,"suspension":99.89508039260864,"brakes":99.66913588409425}', '2026-03-21 18:40:09', '2026-03-21 19:30:19'),
	('04OUZ806', '{"fuel_tank":99.02665893554688,"suspension":96.75552978515626,"clutch":100.0,"radiator":96.1066357421875,"axle":97.404423828125,"brakes":100.0,"oil":100.0,"battery":98.7022119140625,"transmission":100.0,"body":935.110595703125,"engine":980.5331787109375}', '2026-03-20 15:13:22', '2026-03-21 01:58:37'),
	('06AOX941', '{"brakes":100.0,"radiator":0,"engine":272.54270019531227,"axle":7.80569335937498,"body":23.494384765625,"clutch":100.0,"oil":100.0,"fuel_tank":65.4271350097656,"transmission":100.0,"suspension":0,"battery":53.90284667968749}', '2026-03-18 15:27:12', '2026-03-19 01:59:21'),
	('06NZW165', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 13:12:39', '2026-03-19 20:53:53'),
	('07MYV885', '{"body":558.2174987792969,"transmission":100.0,"engine":867.4652496337891,"fuel_tank":93.37326248168945,"axle":82.32869995117187,"suspension":77.91087493896485,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":73.49304992675782,"battery":91.16434997558594}', '2026-03-19 19:03:47', '2026-03-19 20:53:53'),
	('07NUD310', '{"body":522.188720703125,"transmission":100.0,"engine":856.6566162109375,"fuel_tank":92.83283081054688,"axle":80.88754882812499,"suspension":76.10943603515625,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":71.3313232421875,"battery":90.4437744140625}', '2026-03-19 18:53:46', '2026-03-19 20:53:53'),
	('07WNR678', '{"fuel_tank":100.0,"suspension":100.0,"clutch":100.0,"radiator":100.0,"axle":100.0,"brakes":100.0,"oil":100.0,"battery":100.0,"transmission":100.0,"body":1000.0,"engine":1000.0}', '2026-03-20 16:46:21', '2026-03-21 01:58:37'),
	('08BQU558', '{"body":0,"transmission":100.0,"engine":0,"fuel_tank":41.72804985046387,"axle":0,"suspension":0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":0,"battery":22.30406646728516}', '2026-03-19 19:18:47', '2026-03-19 20:53:53'),
	('08LBT063', '{"axle":51.28469848632811,"clutch":100.0,"brakes":100.0,"transmission":100.0,"suspension":39.10587310791015,"oil":100.0,"radiator":26.92704772949218,"body":0,"battery":75.64234924316406,"engine":630.6352386474609,"fuel_tank":81.73176193237305}', '2026-03-21 17:42:45', '2026-03-21 17:56:45'),
	('08SYO369', '{"fuel_tank":100.0,"axle":100.0,"clutch":100.0,"transmission":100.0,"brakes":100.0,"radiator":100.0,"engine":1000.0,"oil":100.0,"suspension":100.0,"body":1000.0,"battery":100.0}', '2026-03-21 17:10:08', '2026-03-21 17:10:08'),
	('08WJV018', '{"body":353.14959716796877,"transmission":100.0,"engine":805.9448791503907,"fuel_tank":90.29724395751953,"axle":74.12598388671876,"suspension":67.65747985839843,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":61.18897583007813,"battery":87.06299194335938}', '2026-03-19 18:28:43', '2026-03-19 20:53:53'),
	('09CGQ180', '{"radiator":100.0,"transmission":100.0,"suspension":100.0,"battery":100.0,"body":1000.0,"clutch":100.0,"engine":1000.0,"oil":100.0,"axle":100.0,"fuel_tank":100.0,"brakes":100.0}', '2026-03-19 11:19:06', '2026-03-19 11:28:25'),
	('09MED513', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 19:47:07', '2026-03-19 20:53:53'),
	('09WRI000', '{"fuel_tank":100.0,"suspension":100.0,"clutch":100.0,"radiator":100.0,"axle":100.0,"brakes":100.0,"oil":100.0,"battery":100.0,"transmission":100.0,"body":1000.0,"engine":1000.0}', '2026-03-20 16:46:40', '2026-03-21 01:58:37'),
	('20ELJ509', '{"body":938.2603759765625,"transmission":100.0,"engine":981.4781127929687,"fuel_tank":99.07390563964845,"axle":97.53041503906249,"suspension":96.91301879882812,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":96.29562255859375,"battery":98.76520751953126}', '2026-03-19 18:52:59', '2026-03-19 20:53:53'),
	('20NWV006', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 18:53:46', '2026-03-19 20:53:53'),
	('20UQJ847', '{"body":1000.0,"fuel_tank":100.0,"clutch":100.0,"radiator":100.0,"transmission":100.0,"engine":1000.0,"axle":100.0,"brakes":100.0,"battery":100.0,"suspension":100.0,"oil":100.0}', '2026-03-20 11:23:35', '2026-03-20 11:25:49'),
	('20XWX421', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 19:13:47', '2026-03-19 20:53:53'),
	('21IDH857', '{"clutch":100.0,"battery":100.0,"brakes":100.0,"transmission":100.0,"axle":100.0,"oil":100.0,"radiator":100.0,"suspension":100.0,"fuel_tank":100.0,"engine":1000.0,"body":1000.0}', '2026-03-21 07:32:48', '2026-03-21 11:52:54'),
	('21VRE826', '{"body":212.5,"transmission":100.0,"engine":763.75,"fuel_tank":88.1875,"axle":68.5,"suspension":60.625,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":52.75,"battery":84.25}', '2026-03-19 18:07:19', '2026-03-19 20:53:53'),
	('22BWG730', '{"radiator":98.55300537109375,"engine":992.7650268554687,"brakes":100.0,"fuel_tank":99.63825134277345,"clutch":100.0,"axle":99.0353369140625,"transmission":100.0,"body":975.8834228515625,"battery":99.51766845703125,"oil":100.0,"suspension":98.79417114257812}', '2026-03-18 10:42:31', '2026-03-18 13:07:45'),
	('22EIC549', '{"fuel_tank":100.0,"suspension":100.0,"clutch":100.0,"engine":1000.0,"battery":100.0,"body":1000.0,"radiator":100.0,"brakes":100.0,"axle":100.0,"transmission":100.0,"oil":100.0}', '2026-03-20 10:03:46', '2026-03-20 10:28:46'),
	('22NHD158', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 18:57:33', '2026-03-19 20:53:53'),
	('23BZO580', '{"transmission":100.0,"oil":100.0,"radiator":100.0,"fuel_tank":100.0,"battery":100.0,"suspension":100.0,"clutch":100.0,"body":1000.0,"engine":1000.0,"axle":100.0,"brakes":100.0}', '2026-03-21 03:28:11', '2026-03-21 04:19:43'),
	('23HPH546', '{"axle":100.0,"clutch":100.0,"brakes":100.0,"transmission":100.0,"suspension":100.0,"oil":100.0,"radiator":100.0,"body":1000.0,"battery":100.0,"engine":1000.0,"fuel_tank":100.0}', '2026-03-21 17:39:31', '2026-03-21 17:56:45'),
	('23OUV845', '{"body":508.7146301269531,"transmission":100.0,"engine":852.614389038086,"fuel_tank":92.6307194519043,"axle":80.34858520507813,"suspension":75.43573150634765,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":70.52287780761719,"battery":90.17429260253906}', '2026-03-19 18:32:36', '2026-03-19 20:53:53'),
	('25ATH606', '{"fuel_tank":100.0,"body":1000.0,"suspension":100.0,"brakes":100.0,"engine":1000.0,"clutch":100.0,"battery":100.0,"radiator":100.0,"transmission":100.0,"oil":100.0,"axle":100.0}', '2026-03-20 12:28:13', '2026-03-20 12:51:36'),
	('25DPX207', '{"body":0,"transmission":100.0,"engine":694.6082540512085,"fuel_tank":84.73041270256043,"axle":59.28110054016113,"suspension":49.10137567520142,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":38.9216508102417,"battery":79.64055027008057}', '2026-03-19 18:29:42', '2026-03-19 20:53:53'),
	('25PMP860', '{"transmission":100.0,"radiator":100.0,"suspension":100.0,"fuel_tank":100.0,"body":1000.0,"engine":1000.0,"clutch":100.0,"oil":100.0,"brakes":100.0,"battery":100.0,"axle":100.0}', '2026-03-19 21:10:29', '2026-03-19 21:40:57'),
	('26XPV769', '{"body":0,"transmission":100.0,"engine":376.6807229995728,"fuel_tank":68.93403614997865,"axle":17.15742973327637,"suspension":0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":0,"battery":58.57871486663817}', '2026-03-19 19:13:30', '2026-03-19 20:53:53'),
	('27FWP266', '{"fuel_tank":99.66145263671875,"axle":99.09720703125,"clutch":100.0,"transmission":100.0,"brakes":100.0,"radiator":98.645810546875,"engine":993.229052734375,"oil":100.0,"suspension":98.8715087890625,"body":977.43017578125,"battery":99.548603515625}', '2026-03-21 16:38:41', '2026-03-21 17:10:08'),
	('28OMZ455', '{"brakes":100.0,"radiator":100.0,"fuel_tank":100.0,"axle":100.0,"body":1000.0,"clutch":100.0,"oil":100.0,"battery":100.0,"suspension":100.0,"transmission":100.0,"engine":1000.0}', '2026-03-18 19:44:12', '2026-03-19 01:59:21'),
	('29DUB915', '{"clutch":100.0,"battery":100.0,"brakes":100.0,"transmission":100.0,"axle":100.0,"oil":100.0,"radiator":100.0,"suspension":100.0,"fuel_tank":100.0,"engine":1000.0,"body":1000.0}', '2026-03-21 07:32:48', '2026-03-21 11:52:54'),
	('29UBH786', '{"fuel_tank":100.0,"suspension":100.0,"clutch":100.0,"radiator":100.0,"axle":100.0,"brakes":100.0,"oil":100.0,"battery":100.0,"transmission":100.0,"body":1000.0,"engine":1000.0}', '2026-03-20 16:48:23', '2026-03-21 01:58:37'),
	('40AID731', '{"body":0,"transmission":100.0,"engine":698.8395048618316,"fuel_tank":84.94197524309158,"axle":59.84526731491088,"suspension":49.80658414363861,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":39.76790097236633,"battery":79.92263365745544}', '2026-03-19 19:08:47', '2026-03-19 20:53:53'),
	('40KVI207', '{"body":755.59619140625,"oil":100.0,"engine":926.678857421875,"brakes":100.0,"radiator":85.335771484375,"transmission":100.0,"fuel_tank":96.33394287109376,"suspension":87.7798095703125,"battery":95.111923828125,"clutch":100.0,"axle":90.22384765625}', '2026-03-21 18:11:12', '2026-03-21 19:11:38'),
	('40MBD252', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 18:18:45', '2026-03-19 20:53:53'),
	('40MUK152', '{"transmission":100.0,"engine":1000.0,"clutch":100.0,"brakes":100.0,"fuel_tank":100.0,"suspension":100.0,"body":1000.0,"radiator":100.0,"axle":100.0,"oil":100.0,"battery":100.0}', '2026-03-20 06:41:13', '2026-03-20 07:32:25'),
	('40NCA547', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 19:23:47', '2026-03-19 20:53:53'),
	('40ZZP763', '{"brakes":100.0,"radiator":80.26465454101563,"fuel_tank":95.0661636352539,"axle":86.84310302734376,"body":671.0775756835938,"clutch":100.0,"oil":100.0,"battery":93.42155151367189,"suspension":83.55387878417968,"transmission":100.0,"engine":901.3232727050781}', '2026-03-18 19:59:12', '2026-03-19 01:59:21'),
	('41BRF845', '{"radiator":53.27621124267578,"body":221.2701873779297,"oil":100.0,"transmission":100.0,"engine":766.3810562133789,"suspension":61.06350936889648,"axle":68.8508074951172,"fuel_tank":88.31905281066895,"clutch":100.0,"brakes":100.0,"battery":84.4254037475586}', '2026-03-21 20:21:50', '2026-03-21 21:21:20'),
	('41NUF999', '{"transmission":100.0,"engine":1000.0,"clutch":100.0,"brakes":100.0,"fuel_tank":100.0,"suspension":100.0,"body":1000.0,"radiator":100.0,"axle":100.0,"oil":100.0,"battery":100.0}', '2026-03-20 06:20:23', '2026-03-20 07:32:25'),
	('41RYN230', '{"radiator":100.0,"body":1000.0,"oil":100.0,"transmission":100.0,"engine":1000.0,"suspension":100.0,"brakes":100.0,"axle":100.0,"fuel_tank":100.0,"clutch":100.0,"battery":100.0}', '2026-03-21 20:39:51', '2026-03-21 21:21:20'),
	('41RZF128', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 18:17:27', '2026-03-19 20:53:53'),
	('41SKB101', '{"suspension":98.85588073730469,"transmission":100.0,"brakes":100.0,"oil":100.0,"engine":993.1352844238281,"body":977.1176147460938,"radiator":98.62705688476562,"clutch":100.0,"axle":99.08470458984375,"battery":99.54235229492187,"fuel_tank":99.65676422119141}', '2026-03-20 12:01:27', '2026-03-20 12:17:30'),
	('42FDB127', '{"radiator":100.0,"body":1000.0,"oil":100.0,"transmission":100.0,"engine":1000.0,"suspension":100.0,"brakes":100.0,"axle":100.0,"fuel_tank":100.0,"clutch":100.0,"battery":100.0}', '2026-03-21 21:06:12', '2026-03-21 21:21:20'),
	('42JID117', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 16:33:49', '2026-03-19 20:53:53'),
	('42NQM643', '{"clutch":100.0,"battery":100.0,"brakes":100.0,"transmission":100.0,"axle":100.0,"oil":100.0,"radiator":100.0,"suspension":100.0,"fuel_tank":100.0,"engine":1000.0,"body":1000.0}', '2026-03-21 07:32:48', '2026-03-21 11:52:54'),
	('42QLH924', '{"body":0.0,"transmission":100.0,"engine":700.0,"fuel_tank":85.0,"axle":60.0,"suspension":50.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":40.0,"battery":80.0}', '2026-03-19 18:18:45', '2026-03-19 20:53:53'),
	('42UFC618', '{"axle":100.0,"radiator":100.0,"transmission":100.0,"battery":100.0,"engine":1000.0,"body":1000.0,"brakes":100.0,"fuel_tank":100.0,"suspension":100.0,"clutch":100.0,"oil":100.0}', '2026-03-18 14:20:37', '2026-03-18 14:20:37'),
	('43EHU103', '{"radiator":100.0,"body":1000.0,"oil":100.0,"transmission":100.0,"engine":1000.0,"suspension":100.0,"brakes":100.0,"axle":100.0,"fuel_tank":100.0,"clutch":100.0,"battery":100.0}', '2026-03-21 21:17:23', '2026-03-21 21:21:20'),
	('43FTA368', '{"transmission":100.0,"engine":1000.0,"clutch":100.0,"brakes":100.0,"fuel_tank":100.0,"suspension":100.0,"body":1000.0,"radiator":100.0,"axle":100.0,"oil":100.0,"battery":100.0}', '2026-03-20 06:22:24', '2026-03-20 07:32:25'),
	('43XVQ625', '{"fuel_tank":100.0,"suspension":100.0,"clutch":100.0,"engine":1000.0,"battery":100.0,"body":1000.0,"radiator":100.0,"brakes":100.0,"axle":100.0,"transmission":100.0,"oil":100.0}', '2026-03-20 10:03:46', '2026-03-20 10:28:46'),
	('44CHH831', '{"engine":589.6083618164064,"transmission":100.0,"body":0,"axle":49.0144482421875,"battery":74.50722412109374,"radiator":23.52167236328125,"clutch":100.0,"fuel_tank":80.88041809082032,"brakes":100.0,"suspension":36.26806030273438,"oil":100.0}', '2026-03-23 19:37:59', '2026-03-24 02:00:42'),
	('44PRB844', '{"radiator":100.0,"transmission":100.0,"suspension":100.0,"battery":100.0,"body":1000.0,"clutch":100.0,"engine":1000.0,"oil":100.0,"axle":100.0,"fuel_tank":100.0,"brakes":100.0}', '2026-03-19 11:18:24', '2026-03-19 11:28:25'),
	('44UQF516', '{"axle":100.0,"radiator":100.0,"transmission":100.0,"battery":100.0,"engine":1000.0,"body":1000.0,"brakes":100.0,"fuel_tank":100.0,"suspension":100.0,"clutch":100.0,"oil":100.0}', '2026-03-18 14:10:37', '2026-03-18 14:20:37'),
	('45DIA085', '{"fuel_tank":74.97699249267579,"axle":33.27197998046876,"clutch":100.0,"transmission":100.0,"brakes":99.85416574096679,"radiator":0,"engine":976.0,"oil":99.55213242497445,"suspension":16.58997497558593,"body":1000.0,"battery":66.63598999023435}', '2026-03-21 16:35:07', '2026-03-21 17:10:08'),
	('45DPA602', '{"fuel_tank":100.0,"suspension":100.0,"radiator":100.0,"oil":100.0,"transmission":100.0,"axle":100.0,"body":1000.0,"engine":1000.0,"clutch":100.0,"brakes":100.0,"battery":100.0}', '2026-03-20 11:07:43', '2026-03-20 11:13:35'),
	('45FRP121', '{"axle":96.28923095703125,"clutch":100.0,"brakes":100.0,"transmission":100.0,"suspension":95.36153869628906,"oil":100.0,"radiator":94.43384643554687,"body":907.2307739257813,"battery":98.14461547851562,"engine":972.1692321777343,"fuel_tank":98.60846160888672}', '2026-03-21 17:40:00', '2026-03-21 17:56:45'),
	('45MCA163', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 18:48:46', '2026-03-19 20:53:53'),
	('45NEX921', '{"engine":992.8725830078124,"radiator":98.5745166015625,"oil":100.0,"suspension":98.81209716796876,"clutch":100.0,"fuel_tank":99.64362915039064,"transmission":100.0,"brakes":100.0,"battery":99.5248388671875,"axle":99.049677734375,"body":976.241943359375}', '2026-03-21 04:59:06', '2026-03-21 05:27:26'),
	('45UWG475', '{"fuel_tank":100.0,"suspension":100.0,"clutch":100.0,"radiator":100.0,"axle":100.0,"brakes":100.0,"oil":100.0,"battery":100.0,"transmission":100.0,"body":1000.0,"engine":1000.0}', '2026-03-20 16:51:51', '2026-03-21 01:58:37'),
	('46MSE479', '{"brakes":100.0,"radiator":100.0,"fuel_tank":100.0,"axle":100.0,"body":1000.0,"clutch":100.0,"oil":100.0,"battery":100.0,"suspension":100.0,"transmission":100.0,"engine":1000.0}', '2026-03-18 18:53:50', '2026-03-19 01:59:21'),
	('47KIY536', '{"radiator":100.0,"body":1000.0,"oil":100.0,"transmission":100.0,"engine":1000.0,"suspension":100.0,"brakes":100.0,"axle":100.0,"fuel_tank":100.0,"clutch":100.0,"battery":100.0}', '2026-03-21 20:41:49', '2026-03-21 21:21:20'),
	('47KQB243', '{"body":687.6588134765625,"transmission":100.0,"engine":906.2976440429687,"fuel_tank":95.31488220214844,"axle":87.5063525390625,"suspension":84.38294067382812,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":81.25952880859376,"battery":93.75317626953125}', '2026-03-19 18:27:58', '2026-03-19 20:53:53'),
	('47NRT444', '{"body":0,"transmission":100.0,"engine":672.1348747253419,"fuel_tank":83.60674373626708,"axle":56.28464996337891,"suspension":45.35581245422364,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":34.42697494506836,"battery":78.14232498168946}', '2026-03-19 18:18:45', '2026-03-19 20:53:53'),
	('47UDC692', '{"body":1000.0,"oil":100.0,"engine":1000.0,"brakes":100.0,"radiator":100.0,"transmission":100.0,"fuel_tank":100.0,"suspension":100.0,"battery":100.0,"clutch":100.0,"axle":100.0}', '2026-03-21 18:38:04', '2026-03-21 19:14:24'),
	('48FGS586', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 18:09:12', '2026-03-19 20:53:53'),
	('48FIY857', '{"axle":100.0,"radiator":100.0,"transmission":100.0,"battery":100.0,"engine":1000.0,"body":1000.0,"brakes":100.0,"fuel_tank":100.0,"suspension":100.0,"clutch":100.0,"oil":100.0}', '2026-03-18 13:21:30', '2026-03-18 14:21:40'),
	('48HJW651', '{"brakes":100.0,"radiator":26.44173858642577,"fuel_tank":81.61043464660648,"axle":50.96115905761718,"body":0,"clutch":100.0,"oil":100.0,"battery":75.4805795288086,"suspension":38.70144882202147,"transmission":100.0,"engine":632.2086929321287}', '2026-03-18 19:04:11', '2026-03-19 01:59:21'),
	('48MYO793', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 18:46:44', '2026-03-19 20:53:53'),
	('48OBN195', '{"body":979.8933715820313,"transmission":100.0,"engine":993.9680114746094,"fuel_tank":99.69840057373047,"axle":99.19573486328125,"suspension":98.99466857910156,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":98.79360229492187,"battery":99.59786743164062}', '2026-03-19 17:10:18', '2026-03-19 20:53:53'),
	('60FFS465', '{"brakes":100.0,"radiator":100.0,"fuel_tank":100.0,"axle":100.0,"body":1000.0,"clutch":100.0,"oil":100.0,"battery":100.0,"suspension":100.0,"transmission":100.0,"engine":1000.0}', '2026-03-18 18:50:42', '2026-03-19 01:59:21'),
	('60FNN530', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 18:44:01', '2026-03-19 20:53:53'),
	('60NVG622', '{"body":962.3001098632813,"transmission":100.0,"engine":988.6900329589844,"fuel_tank":99.43450164794922,"axle":98.49200439453125,"suspension":98.11500549316406,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":97.73800659179688,"battery":99.24600219726563}', '2026-03-19 19:11:55', '2026-03-19 20:53:53'),
	('61BUL978', '{"body":0,"transmission":100.0,"engine":695.4615163803101,"fuel_tank":84.7730758190155,"axle":59.39486885070801,"suspension":49.24358606338502,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":39.09230327606202,"battery":79.697434425354}', '2026-03-19 19:01:43', '2026-03-19 20:53:53'),
	('61FGI913', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 16:38:43', '2026-03-19 20:53:53'),
	('61QXY154', '{"fuel_tank":100.0,"suspension":100.0,"clutch":100.0,"radiator":100.0,"axle":100.0,"brakes":100.0,"oil":100.0,"battery":100.0,"transmission":100.0,"body":1000.0,"engine":1000.0}', '2026-03-20 16:52:48', '2026-03-21 01:58:37'),
	('61UYB054', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 18:51:32', '2026-03-19 20:53:53'),
	('61VAP304', '{"body":0,"transmission":100.0,"engine":556.9716732025146,"fuel_tank":77.84858366012574,"axle":40.92955642700197,"suspension":26.16194553375242,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":11.39433464050293,"battery":70.46477821350098}', '2026-03-19 19:03:47', '2026-03-19 20:53:53'),
	('62IET174', '{"engine":918.3386779785157,"transmission":100.0,"body":727.7955932617188,"axle":89.11182373046874,"battery":94.55591186523438,"radiator":83.66773559570314,"clutch":100.0,"fuel_tank":95.91693389892578,"brakes":100.0,"suspension":86.38977966308593,"oil":100.0}', '2026-03-23 18:32:23', '2026-03-24 02:00:41'),
	('62TGO464', '{"engine":1000.0,"transmission":100.0,"body":1000.0,"axle":100.0,"battery":100.0,"radiator":100.0,"clutch":100.0,"fuel_tank":100.0,"brakes":100.0,"suspension":100.0,"oil":100.0}', '2026-03-23 17:10:31', '2026-03-24 02:00:41'),
	('63VOD500', '{"body":63.29038619995117,"transmission":100.0,"engine":718.9871158599854,"fuel_tank":85.94935579299927,"axle":62.53161544799805,"suspension":53.16451930999756,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":43.79742317199707,"battery":81.26580772399902}', '2026-03-19 18:30:36', '2026-03-19 20:53:53'),
	('64JJA687', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 18:48:46', '2026-03-19 20:53:53'),
	('64QPC117', '{"body":358.10443115234377,"transmission":100.0,"engine":807.4313293457032,"fuel_tank":90.37156646728515,"axle":74.32417724609374,"suspension":67.9052215576172,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":61.48626586914063,"battery":87.16208862304689}', '2026-03-19 18:50:31', '2026-03-19 20:53:53'),
	('64WQU193', '{"oil":100.0,"engine":1000.0,"clutch":100.0,"axle":100.0,"transmission":100.0,"battery":100.0,"suspension":100.0,"brakes":100.0,"body":1000.0,"fuel_tank":100.0,"radiator":100.0}', '2026-03-20 11:23:35', '2026-03-20 11:44:42'),
	('65XGT110', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 16:37:36', '2026-03-19 20:53:53'),
	('66MFN686', '{"fuel_tank":100.0,"suspension":100.0,"clutch":100.0,"engine":1000.0,"battery":100.0,"body":1000.0,"radiator":100.0,"brakes":100.0,"axle":100.0,"transmission":100.0,"oil":100.0}', '2026-03-20 10:05:39', '2026-03-20 10:28:46'),
	('66NDK674', '{"brakes":100.0,"radiator":100.0,"fuel_tank":100.0,"axle":100.0,"body":1000.0,"clutch":100.0,"oil":100.0,"battery":100.0,"suspension":100.0,"transmission":100.0,"engine":1000.0}', '2026-03-18 19:34:12', '2026-03-19 01:59:21'),
	('67ACH778', '{"axle":100.0,"clutch":100.0,"brakes":100.0,"transmission":100.0,"suspension":100.0,"oil":100.0,"radiator":100.0,"body":1000.0,"battery":100.0,"engine":1000.0,"fuel_tank":100.0}', '2026-03-21 17:35:15', '2026-03-21 17:56:45'),
	('67ERO204', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 17:11:13', '2026-03-19 20:53:53'),
	('67ONI389', '{"body":964.9130859375,"transmission":100.0,"engine":989.47392578125,"fuel_tank":99.4736962890625,"axle":98.5965234375,"suspension":98.245654296875,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":97.89478515625,"battery":99.29826171875}', '2026-03-19 19:16:48', '2026-03-19 20:53:53'),
	('68CFJ455', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 18:16:56', '2026-03-19 20:53:53'),
	('68HNB092', '{"brakes":100.0,"radiator":81.09862670898439,"fuel_tank":95.2746566772461,"axle":87.39908447265624,"body":684.9771118164063,"clutch":100.0,"oil":100.0,"battery":93.69954223632814,"suspension":84.2488555908203,"transmission":100.0,"engine":905.493133544922}', '2026-03-18 16:57:49', '2026-03-19 01:59:21'),
	('68JAJ541', '{"body":928.0,"transmission":100.0,"engine":978.4,"fuel_tank":98.92,"axle":97.12,"suspension":96.4,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":95.68,"battery":98.56}', '2026-03-19 17:11:31', '2026-03-19 20:53:53'),
	('68LSX713', '{"body":956.2496337890625,"oil":100.0,"engine":986.8748901367187,"brakes":100.0,"radiator":97.37497802734375,"transmission":100.0,"fuel_tank":99.34374450683593,"suspension":97.81248168945312,"battery":99.12499267578125,"clutch":100.0,"axle":98.2499853515625}', '2026-03-21 18:04:43', '2026-03-21 19:11:38'),
	('68UIP755', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 18:05:54', '2026-03-19 20:53:53'),
	('69HNS053', '{"radiator":100.0,"engine":1000.0,"brakes":100.0,"fuel_tank":100.0,"clutch":100.0,"axle":100.0,"transmission":100.0,"body":1000.0,"battery":100.0,"oil":100.0,"suspension":100.0}', '2026-03-18 10:31:06', '2026-03-18 13:07:45'),
	('69MTQ712', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 16:21:03', '2026-03-19 20:53:53'),
	('69MUJ536', '{"clutch":100.0,"body":1000.0,"brakes":100.0,"transmission":100.0,"axle":100.0,"suspension":100.0,"radiator":100.0,"oil":100.0,"fuel_tank":100.0,"engine":1000.0,"battery":100.0}', '2026-03-19 21:46:53', '2026-03-21 11:52:54'),
	('69TXR277', '{"fuel_tank":100.0,"suspension":100.0,"clutch":100.0,"radiator":100.0,"axle":100.0,"brakes":100.0,"oil":100.0,"battery":100.0,"transmission":100.0,"body":1000.0,"engine":1000.0}', '2026-03-20 16:48:23', '2026-03-21 01:58:37'),
	('80GTV218', '{"body":761.463623046875,"transmission":100.0,"engine":928.4390869140625,"fuel_tank":96.42195434570313,"axle":90.45854492187499,"suspension":88.07318115234375,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":85.68781738281251,"battery":95.22927246093751}', '2026-03-19 19:52:15', '2026-03-19 20:53:53'),
	('80KUI329', '{"radiator":100.0,"transmission":100.0,"suspension":100.0,"battery":100.0,"body":1000.0,"clutch":100.0,"engine":1000.0,"oil":100.0,"axle":100.0,"fuel_tank":100.0,"brakes":100.0}', '2026-03-19 11:19:41', '2026-03-19 11:28:25'),
	('80OSS100', '{"body":1000.0,"oil":100.0,"engine":1000.0,"brakes":100.0,"radiator":100.0,"transmission":100.0,"fuel_tank":100.0,"suspension":100.0,"battery":100.0,"clutch":100.0,"axle":100.0}', '2026-03-21 18:25:02', '2026-03-21 19:11:38'),
	('80YCZ571', '{"fuel_tank":96.3855126953125,"suspension":87.951708984375,"clutch":100.0,"radiator":85.54205078125,"axle":90.3613671875,"brakes":100.0,"oil":100.0,"battery":95.18068359375,"transmission":100.0,"body":759.0341796875,"engine":927.71025390625}', '2026-03-20 15:09:48', '2026-03-21 01:58:37'),
	('81FBF081', '{"body":787.5260009765625,"transmission":100.0,"engine":936.2578002929686,"fuel_tank":96.81289001464843,"axle":91.5010400390625,"suspension":89.37630004882813,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":87.25156005859374,"battery":95.75052001953124}', '2026-03-19 19:14:23', '2026-03-19 20:53:53'),
	('81IOX099', '{"axle":100.0,"clutch":100.0,"brakes":100.0,"transmission":100.0,"suspension":100.0,"oil":100.0,"radiator":100.0,"body":1000.0,"battery":100.0,"engine":1000.0,"fuel_tank":100.0}', '2026-03-21 17:41:30', '2026-03-21 17:56:45'),
	('81YPA238', '{"body":1000.0,"oil":100.0,"engine":1000.0,"brakes":100.0,"radiator":100.0,"transmission":100.0,"fuel_tank":100.0,"suspension":100.0,"battery":100.0,"clutch":100.0,"axle":100.0}', '2026-03-21 18:06:37', '2026-03-21 19:11:38'),
	('82CTA701', '{"body":223.23182678222657,"transmission":100.0,"engine":766.9695480346679,"fuel_tank":88.34847740173339,"axle":68.92927307128906,"suspension":61.16159133911131,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":53.39390960693358,"battery":84.4646365356445}', '2026-03-19 19:00:18', '2026-03-19 20:53:53'),
	('82ECS804', '{"clutch":100.0,"battery":98.32383056640625,"brakes":100.0,"transmission":100.0,"axle":96.6476611328125,"oil":100.0,"radiator":94.97149169921875,"suspension":95.80957641601562,"fuel_tank":98.74287292480469,"engine":974.8574584960937,"body":916.1915283203125}', '2026-03-21 07:16:50', '2026-03-21 11:52:54'),
	('82LIA644', '{"brakes":100.0,"radiator":100.0,"fuel_tank":100.0,"axle":100.0,"body":1000.0,"clutch":100.0,"oil":100.0,"battery":100.0,"suspension":100.0,"transmission":100.0,"engine":1000.0}', '2026-03-18 16:59:09', '2026-03-19 01:59:21'),
	('82WEZ945', '{"body":1000.0,"suspension":100.0,"fuel_tank":100.0,"transmission":100.0,"oil":100.0,"battery":100.0,"engine":1000.0,"radiator":100.0,"clutch":100.0,"axle":100.0,"brakes":100.0}', '2026-03-21 19:39:33', '2026-03-21 20:19:28'),
	('82WIM168', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 19:10:19', '2026-03-19 20:53:53'),
	('82WMK428', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 16:39:05', '2026-03-19 20:53:53'),
	('82XET274', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 18:18:45', '2026-03-19 20:53:53'),
	('83CJW934', '{"body":915.630615234375,"transmission":100.0,"engine":974.6891845703125,"fuel_tank":98.73445922851562,"axle":96.625224609375,"suspension":95.78153076171876,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":94.9378369140625,"battery":98.3126123046875}', '2026-03-19 19:11:16', '2026-03-19 20:53:53'),
	('83LUE605', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 18:46:08', '2026-03-19 20:53:53'),
	('83QOQ538', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 19:18:47', '2026-03-19 20:53:53'),
	('83XUV589', '{"brakes":100.0,"radiator":100.0,"fuel_tank":100.0,"axle":100.0,"body":1000.0,"clutch":100.0,"oil":100.0,"battery":100.0,"suspension":100.0,"transmission":100.0,"engine":1000.0}', '2026-03-18 18:38:43', '2026-03-19 01:59:21'),
	('84JOP052', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 16:25:30', '2026-03-19 20:53:53'),
	('84KEQ469', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 19:13:29', '2026-03-19 20:53:53'),
	('84XBV328', '{"body":233.51123046875,"transmission":100.0,"engine":770.053369140625,"fuel_tank":88.50266845703125,"axle":69.34044921875,"suspension":61.67556152343749,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":54.01067382812501,"battery":84.67022460937503}', '2026-03-19 18:03:45', '2026-03-19 20:53:53'),
	('85ZZN009', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 19:13:47', '2026-03-19 20:53:53'),
	('86BBA336', '{"brakes":100.0,"radiator":100.0,"fuel_tank":100.0,"axle":100.0,"body":1000.0,"clutch":100.0,"oil":100.0,"battery":100.0,"suspension":100.0,"transmission":100.0,"engine":1000.0}', '2026-03-18 17:24:10', '2026-03-19 01:59:21'),
	('86UYH203', '{"body":0,"transmission":100.0,"engine":161.25449981689449,"fuel_tank":58.56272499084473,"axle":0,"suspension":0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":0,"battery":44.75029998779299}', '2026-03-19 16:55:00', '2026-03-19 20:53:53'),
	('86VME156', '{"body":0,"transmission":100.0,"engine":578.2597106933592,"fuel_tank":79.51298553466798,"axle":45.36796142578124,"suspension":31.70995178222654,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":18.05194213867188,"battery":72.68398071289065}', '2026-03-19 17:33:44', '2026-03-19 20:53:53'),
	('86ZXC413', '{"brakes":100.0,"radiator":100.0,"fuel_tank":100.0,"axle":100.0,"body":1000.0,"clutch":100.0,"oil":100.0,"battery":100.0,"suspension":100.0,"transmission":100.0,"engine":1000.0}', '2026-03-18 18:36:46', '2026-03-19 01:59:21'),
	('87FSQ904', '{"engine":1000.0,"transmission":100.0,"body":1000.0,"axle":100.0,"battery":100.0,"radiator":100.0,"clutch":100.0,"fuel_tank":100.0,"brakes":100.0,"suspension":100.0,"oil":100.0}', '2026-03-23 18:31:40', '2026-03-24 02:00:42'),
	('88LJE994', '{"body":1000.0,"transmission":100.0,"engine":1000.0,"fuel_tank":100.0,"axle":100.0,"suspension":100.0,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":100.0,"battery":100.0}', '2026-03-19 13:03:39', '2026-03-19 20:53:53'),
	('88TOJ439', '{"body":47.15252685546875,"transmission":100.0,"engine":714.1457580566405,"fuel_tank":85.70728790283205,"axle":61.88610107421878,"suspension":52.35762634277348,"oil":100.0,"clutch":100.0,"brakes":100.0,"radiator":42.82915161132815,"battery":80.9430505371094}', '2026-03-19 18:33:45', '2026-03-19 20:53:53'),
	('89UKX494', '{"fuel_tank":100.0,"suspension":100.0,"clutch":100.0,"radiator":100.0,"axle":100.0,"brakes":100.0,"oil":100.0,"battery":100.0,"transmission":100.0,"body":1000.0,"engine":1000.0}', '2026-03-20 16:47:36', '2026-03-21 01:58:37'),
	('CARG8193', '{"oil":98.98799495124817,"body":275.94029235839846,"fuel_tank":89.13910438537596,"transmission":100.0,"radiator":56.55641754150392,"brakes":99.54093529663085,"clutch":99.8683490386963,"axle":71.03761169433594,"battery":85.51880584716798,"suspension":63.69169384887693,"engine":782.7820877075197}', '2026-03-22 06:08:07', '2026-03-22 06:23:07'),
	('PREVIEW', '{"fuel_tank":100.0,"suspension":100.0,"clutch":100.0,"radiator":100.0,"axle":100.0,"brakes":100.0,"oil":100.0,"battery":100.0,"transmission":100.0,"body":1000.0,"engine":1000.0}', '2026-03-20 16:58:23', '2026-03-21 01:58:37'),
	('TEST437', '{"fuel_tank":100.0,"suspension":100.0,"clutch":100.0,"radiator":100.0,"axle":100.0,"brakes":100.0,"oil":100.0,"battery":100.0,"transmission":100.0,"body":1000.0,"engine":1000.0}', '2026-03-20 16:58:23', '2026-03-21 01:58:37'),
	('TEST722', '{"fuel_tank":100.0,"suspension":100.0,"clutch":100.0,"radiator":100.0,"axle":100.0,"brakes":100.0,"oil":100.0,"battery":100.0,"transmission":100.0,"body":1000.0,"engine":1000.0}', '2026-03-20 16:58:23', '2026-03-21 01:58:37'),
	('TRUCK563', '{"fuel_tank":81.98188537597655,"suspension":39.93961791992186,"clutch":100.0,"radiator":27.92754150390626,"axle":51.95169433593747,"brakes":100.0,"oil":100.0,"battery":75.97584716796875,"transmission":100.0,"body":0,"engine":639.6377075195312}', '2026-03-20 17:07:36', '2026-03-21 01:58:37');

-- Dumping structure for table republica.vrs_mechanic_work_orders
CREATE TABLE IF NOT EXISTS `vrs_mechanic_work_orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `shop_id` varchar(50) NOT NULL,
  `plate` varchar(20) NOT NULL,
  `model` varchar(50) DEFAULT '',
  `owner_name` varchar(100) DEFAULT 'Desconhecido',
  `mechanic_name` varchar(100) NOT NULL,
  `mechanic_citizenid` varchar(50) NOT NULL,
  `problems` longtext DEFAULT '[]',
  `materials` longtext DEFAULT '[]',
  `budget` float DEFAULT 0,
  `notes` text DEFAULT '',
  `status` varchar(20) NOT NULL DEFAULT 'open',
  `created_at` datetime NOT NULL DEFAULT current_timestamp(),
  `updated_at` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_shop` (`shop_id`),
  KEY `idx_plate` (`plate`),
  KEY `idx_status` (`status`),
  KEY `idx_mechanic` (`mechanic_citizenid`),
  KEY `idx_created` (`created_at`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Dumping data for table republica.vrs_mechanic_work_orders: ~2 rows (approximately)
INSERT INTO `vrs_mechanic_work_orders` (`id`, `shop_id`, `plate`, `model`, `owner_name`, `mechanic_name`, `mechanic_citizenid`, `problems`, `materials`, `budget`, `notes`, `status`, `created_at`, `updated_at`) VALUES
	(1, 'mecanica_central', '22BWG730', 'TENF', 'tião', 'TiãO Dev', 'ZDQ8H6H9', '[]', '[]', 0, '', 'open', '2026-03-18 10:43:11', '2026-03-18 10:43:11'),
	(2, 'mecanica_praia', '69MUJ536', 'gtr r33', 'João', 'TiãO Dev', 'ZDQ8H6H9', '[]', '[]', 0, 'orçamento', 'open', '2026-03-21 06:00:07', '2026-03-21 06:00:07');

-- Dumping structure for trigger republica.mdt_reports_charges_after_delete
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `mdt_reports_charges_after_delete` AFTER UPDATE ON `mdt_reports_charges` FOR EACH ROW BEGIN
    UPDATE mdt_reports_warrants
    SET
        felonies = (
            SELECT SUM(CASE WHEN mc.charge_class = 'felony' THEN 1 ELSE 0 END)
        FROM mdt_reports_charges AS mrc
                     INNER JOIN mdt_penal_codes AS mc
                                ON mrc.charge = mc.label
            WHERE mrc.reportid = OLD.reportid
        ),
        misdemeanors = (
            SELECT SUM(CASE WHEN mc.charge_class = 'misdemeanor' THEN 1 ELSE 0 END)
        FROM mdt_reports_charges AS mrc
                     INNER JOIN mdt_penal_codes AS mc
                                ON mrc.charge = mc.label
            WHERE mrc.reportid = OLD.reportid
        ),
        infractions = (
            SELECT SUM(CASE WHEN mc.charge_class = 'infraction' THEN 1 ELSE 0 END)
        FROM mdt_reports_charges AS mrc
                     INNER JOIN mdt_penal_codes AS mc
                                ON mrc.charge = mc.label
            WHERE mrc.reportid = OLD.reportid
        )
    WHERE reportid = OLD.reportid;
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger republica.mdt_reports_charges_after_insert
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER `mdt_reports_charges_after_insert` AFTER INSERT ON `mdt_reports_charges` FOR EACH ROW BEGIN
    UPDATE mdt_reports_warrants
    SET
        felonies = (
            SELECT SUM(CASE WHEN mc.charge_class = 'felony' THEN 1 ELSE 0 END)
        FROM mdt_reports_charges AS mrc
                     INNER JOIN mdt_penal_codes AS mc
                                ON mrc.charge = mc.label
            WHERE mrc.reportid = NEW.reportid
        ),
        misdemeanors = (
            SELECT SUM(CASE WHEN mc.charge_class = 'misdemeanor' THEN 1 ELSE 0 END)
        FROM mdt_reports_charges AS mrc
                     INNER JOIN mdt_penal_codes AS mc
                                ON mrc.charge = mc.label
            WHERE mrc.reportid = NEW.reportid
        ),
        infractions = (
            SELECT SUM(CASE WHEN mc.charge_class = 'infraction' THEN 1 ELSE 0 END)
        FROM mdt_reports_charges AS mrc
                     INNER JOIN mdt_penal_codes AS mc
                                ON mrc.charge = mc.label
            WHERE mrc.reportid = NEW.reportid
        )
    WHERE reportid = NEW.reportid;
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger republica.rhd_garage_delete_from_impound
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='IGNORE_SPACE,STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER rhd_garage_delete_from_impound
AFTER DELETE ON player_vehicles
FOR EACH ROW
BEGIN
    DELETE FROM police_impound
    WHERE plate = OLD.plate;
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger republica.rhd_garage_state_update
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='IGNORE_SPACE,STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER rhd_garage_state_update
AFTER UPDATE ON player_vehicles
FOR EACH ROW
BEGIN
    IF NEW.state <> 2 THEN
        DELETE FROM police_impound
        WHERE plate = OLD.plate;
    END IF;
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

-- Dumping structure for trigger republica.rhd_garage_update_impound_plate
SET @OLDTMP_SQL_MODE=@@SQL_MODE, SQL_MODE='IGNORE_SPACE,STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION';
DELIMITER //
CREATE TRIGGER rhd_garage_update_impound_plate
AFTER UPDATE ON player_vehicles
FOR EACH ROW
BEGIN
    UPDATE police_impound
    SET plate = NEW.plate
    WHERE plate = OLD.plate;
END//
DELIMITER ;
SET SQL_MODE=@OLDTMP_SQL_MODE;

/*!40103 SET TIME_ZONE=IFNULL(@OLD_TIME_ZONE, 'system') */;
/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
