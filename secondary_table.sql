/*
Sekundární tabulka s HDP, Giniho koeficientem a populací evropských států ve stejném období.
t_ema_tumova_project_SQL_secondary_final

Sloupce budou:
	ZEMĚ,
	ROK,
	HDP,
	Giniho koeficient,
	POPULACE
*/

-- Vypíšu si evropské státy (ne zámořská území atd.) z tabulky,
-- abych poté zobrazila pouze data o nich.
SELECT 
	DISTINCT country 
FROM economies;

/*
Evropské státy: 
Albania, Andorra, Austria, Belarus, Belgium, Bosnia and Herzegovina, Bulgaria, Croatia, Cyprus, Czech Republic,
Denmark, Estonia, Finland, France, Germany, Greece, Hungary, Iceland, Ireland, Italy, Kosovo, Latvia,
Liechtenstein, Lithuania, Luxembourg, Malta, Moldova, Monaco, Montenegro, Netherlands, North Macedonia,
Norway, Poland, Portugal, Romania, San Marino, Serbia, Slovakia, Slovenia, Spain, Sweden, Switzerland,
Ukraine, United Kingdom 
*/

-- Nejširší období s dostupnými daty, která budu primárně zkoumat (mzdy a ceny), jsou roky 2000 až 2021 (mzdy).
-- Omezím tedy data v sekundární tabulce právě na roky 2000 až 2021.
-- HDP pro přeheldnost zaokrouhlím na jednotky.

CREATE TABLE IF NOT EXISTS t_ema_tumova_project_SQL_secondary_final
AS
	(SELECT
		country AS zeme,
		year AS rok,
		ROUND(GDP) AS HDP,
		gini,
		population AS pocet_obyvatel	
	FROM economies
	WHERE 
		country IN
			('Albania', 'Andorra', 'Austria', 'Belarus', 'Belgium', 'Bosnia and Herzegovina',
			'Bulgaria', 'Croatia', 'Cyprus', 'Czech Republic', 'Denmark', 'Estonia', 'Finland',
			'France', 'Germany', 'Greece', 'Hungary', 'Iceland', 'Ireland', 'Italy', 'Kosovo', 'Latvia',
			'Liechtenstein', 'Lithuania', 'Luxembourg', 'Malta', 'Moldova', 'Monaco', 'Montenegro',
			'Netherlands', 'North Macedonia', 'Norway', 'Poland', 'Portugal', 'Romania', 'San Marino', 
			'Serbia', 'Slovakia', 'Slovenia', 'Spain', 'Sweden', 'Switzerland', 'Ukraine', 'United Kingdom')
		AND `year` BETWEEN 2000 AND 2021
	ORDER BY
		country,
		year)
;