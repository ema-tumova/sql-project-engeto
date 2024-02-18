/*
Primární tabulka pro data mezd a cen potravin za ČR sjednocených na totožné porovnatelné období – společné roky.
Pro data mezd započítávám plné i částečné úvazky.

Struktura dat (sloupce tabulky):
	rok,
	kategorie:
		'cena'
		'mzda'
	kod_podkategorie:
		kód kategorie pro potraviny
		kód odvětví pro mzdy
	nazev_podkategorie:
		název kategorie pro potraviny
		název odvětví pro mzdy
	prum_hodnota:
		průměrná cena pro potraviny
		průměrná mzda pro mzdy
*/

CREATE TABLE IF NOT EXISTS t_ema_tumova_project_SQL_primary_final 
AS
	(SELECT 	
		cp.payroll_year AS rok,
		CONCAT('mzda') AS kategorie,
		cp.industry_branch_code AS kod_podkategorie,
		cpib.name AS nazev_podkategorie,
		SUM(cp.value)/COUNT(cp.payroll_quarter) AS prum_hodnota
	FROM czechia_payroll cp
	JOIN czechia_payroll_industry_branch cpib
		ON cp.industry_branch_code = cpib.code
	WHERE
		cp.calculation_code = 100
		AND cp.value_type_code = 5958
	GROUP BY
		cp.payroll_year,
		cp.industry_branch_code
	ORDER BY 
		cp.payroll_year,
		cp.industry_branch_code)
UNION
	(SELECT
		YEAR(cpr.date_from) AS rok,
		CONCAT('cena') AS kategorie,
		cpr.category_code AS kod_podkategorie,
		cpc.name AS nazev_podkategorie,
		AVG(cpr.value) AS prum_hodnota
	FROM czechia_price cpr
	JOIN czechia_price_category cpc
		ON cpr.category_code = cpc.code
	GROUP BY
		YEAR(cpr.date_from),
		cpr.category_code)
;