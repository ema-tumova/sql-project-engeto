-- 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období 
-- v dostupných datech cen a mezd?

-- Budu pracovat s tabulkou mezd (czechia_payroll) i potravin (czechia_price).

-- Nejdříve určím první a poslední srovnatelné období: 
-- V tabulce mezd mám čtvrtletí a roky, v tabulce potravin týdny (date_from, date_to).
-- Budu tedy porovnávat roky.

SELECT DISTINCT date_from
FROM czechia_price
ORDER BY date_from
LIMIT 1;
-- první date_from = 2006-01-02

SELECT DISTINCT date_to
FROM czechia_price
ORDER BY date_to DESC
LIMIT 1;
-- poslední date_to = 2018-12-16

SELECT DISTINCT payroll_year, payroll_quarter
FROM czechia_payroll
ORDER BY payroll_year, payroll_quarter
LIMIT 1;
-- první payroll_year & payroll_quarter = 2000/1

SELECT DISTINCT payroll_year, payroll_quarter
FROM czechia_payroll
ORDER BY payroll_year DESC, payroll_quarter DESC
LIMIT 1;
-- poslední payroll_year & payroll_quarter = 2021/2

-- V tabulce czechia_price jsou data z let 2006-2018, v tabulce czechia_payroll z let 2000-2021.
-- Průnik zkoumaných let jsou tedy roky 2006-2018. 
-- První srovnatelné období je rok 2006, poslední je rok 2018.

-- Seskupím si data z tabulky czechia_price podle let tak, 
-- aby obsahovala průměrnou value spočítanou ze všech období v daném roce.
-- Sloupce date_to a date_from v jednom záznamu jsou vždy v rámci stejného roku, 
-- proto můžu použít pouze jeden z těchto sloupců, z něhož zobrazím pouze rok.
-- Data seskupím podle kategorie potravin a podle let. 
-- Rozdíly cen potravin mezi regiony nejsou v této otázce relevantní.
-- Průměrnou value vypočítám zprůměrováním všech values za všechna období jednotlivých let.
-- Pro přehlednost připojím název kategorie potravin přes JOIN s tabulkou czechia_price_category.

SELECT 
	cp.category_code,
	cpc.name AS nazev,
	YEAR(cp.date_from) AS rok,
	ROUND(AVG(cp.value), 2) AS prumerna_cena
FROM czechia_price cp
JOIN czechia_price_category cpc
	ON cp.category_code = cpc.code
GROUP BY category_code, YEAR(date_from);

-- Otázka se ptá pouze na mléko a chleba, zjistím jejich kód:
SELECT 
	DISTINCT code,
	name AS nazev
FROM czechia_price_category
WHERE name LIKE 'ch%' OR name LIKE 'm%';
-- category_code chleba a mléka: 111301 a 114201.

-- Potřebuji zobrazovat data pouze pro mléko a chleba,
-- pouze za první a poslední srovnatelné období (roky 2006 a 2018):
SELECT 
	cp.category_code,
	cpc.name AS nazev,
	YEAR(cp.date_from) AS rok,
	ROUND(AVG(cp.value), 2) AS prumerna_cena
FROM czechia_price cp
JOIN czechia_price_category cpc
	ON cp.category_code = cpc.code
WHERE 
	cp.category_code IN (111301, 114201)
	AND YEAR(date_from) IN (2006, 2018)
GROUP BY 
	category_code, 
	YEAR(date_from);

-- Ověřím, že průměrná cena je uvedena pro litry a kilogramy:
SELECT *
FROM czechia_price_category
WHERE code IN (111301, 114201);
-- Ano, cena je za 1 kg chleba a 1 l mléka.

-- Zobrazím průměrnou mzdu pro roky 2006 a 2018 z tabulky použité v řešení otázky 1 (bez filtru na odvětví):
SELECT 	
	payroll_year,
	SUM(value)/COUNT(payroll_quarter) AS prumerna_mzda
FROM czechia_payroll 
WHERE calculation_code = 200
	AND value_type_code = 5958
	AND payroll_year IN (2006, 2018)
GROUP BY payroll_year;

-- Vyfiltrovaná data z obou tabulek spojím pomocí JOINu přes shodné roky.
-- Průměrnou mzdu a průměrnou cenu nezaokrouhluji, aby byl následný výpočet co nepřesnější.
-- V novém sloupci vypočítám, kolik litrů mléka nebo kg chleba 
-- by bylo možné si pořídit z průměrné mzdy v daný rok podle průměrné ceny potravin za daný rok.
-- Vydělím tedy průměrnou mzdu průměrnou cenou dané potraviny a zaokrouhlím na nejbližší nižší celé číslo.
SELECT
	ceny_potravin.*, 
	prumezne_mzdy.prumerna_mzda,
	FLOOR(prumezne_mzdy.prumerna_mzda/ceny_potravin.prumerna_cena) AS pocet_jednotek_potraviny_za_mzdu
FROM 
	(SELECT 
		cp.category_code,
		cpc.name AS nazev,
		YEAR(cp.date_from) AS rok,
		AVG(cp.value) AS prumerna_cena
	FROM czechia_price cp
	JOIN czechia_price_category cpc
		ON cp.category_code = cpc.code
	WHERE 
		cp.category_code IN (111301, 114201)
		AND YEAR(date_from) IN (2006, 2018)
	GROUP BY 
		category_code, 
		YEAR(date_from)
	)
	AS ceny_potravin
JOIN
	(SELECT 	
		payroll_year,
		SUM(value)/COUNT(payroll_quarter) AS prumerna_mzda
	FROM czechia_payroll 
	WHERE calculation_code = 200
		AND value_type_code = 5958
		AND payroll_year IN (2006, 2018)
	GROUP BY payroll_year
	)
	AS prumezne_mzdy
ON ceny_potravin.rok = prumezne_mzdy.payroll_year;


-- ODPOVĚĎ NA VÝZKUMNOU OTÁZKU
-- 2. Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období 
-- v dostupných datech cen a mezd?

/*
Pracujeme-li s průměrnými ročními hodnotami mezd a cen potravin v ČR, potom platí:
V roce 2006 (v prvním srovnatelném období) bylo možné si za průměrnou mzdu 
koupit 1460 litrů mléka nebo 1307 kg chleba.
V roce 2018 (v posledním srovnatelném období) bylo možné si za průměrnou mzdu 
koupit 1667 litrů mléka nebo 1363 kg chleba.

Vycházíme-li pouze z těchto výsledků, zdá se, že ačkoli byly průměrné ceny potravin 
v roce 2018 vyšší než v roce 2006, mzdy rostly tak, že si lidé mohli v roce 2018 pořídit 
více potravin za průměrnou mzdu než v roce 2006.
*/