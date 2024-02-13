-- 3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
-- (Pozor, existují i negativní hodnoty.)

-- PŘEDBĚŽNÝ PLÁN:
-- Budu používat tabulku czechia_price.
-- Potřebuji zjistit meziroční růst průměrných cen potravin podle kategorií potravin.
-- Tento rozdíl musím poté ještě přepočíat na meziroční procentní rozdíl.
-- Poté vyfiltruju přes WHERE pouze hodnoty rozdílu větší než 0 (chci pouze růst, ne pokles).
-- Nakonec data seřadím vzestupně podle hodnot meziročního procentního růstu
-- a omezím (LIMIT) pouze na první (a tedy nejnižší) záznam.
-- Kategorie potravin u tohoto záznamu bude odpovědí na výzkumnou otázku.

-- Použiju tabulku průměrných ročních cen potravin z řešení otázky 2.
-- Pro zachování přesnosti zatím nebudu prům. cenu zaokrouhlovat.
-- Tuto tabulku budu JOINovat samu na sebe tak, abych měla v jednom záznamu
-- hodnoty pro dva po sobě následující roky. 
-- Tabulky na sebe tedy navazuji tak, že se od sebe roky liší o jeden rok a kategorie jsou shodné.
-- Poté už můžu jednoduše vypočítat meziroční rozdíl průměrných cen v novém sloupci mezirocni_rozdil_cen.
-- Tento sloupec musím ještě přepočítat na percentuální meziroční rozdíl (sloupec rozdil_cen_v_procentech).
SELECT 
	rok_a.category_code,
	rok_a.nazev,
	rok_a.rok AS rok_a,
	rok_a.prumerna_cena AS prumerna_cena_v_roce_a,
	rok_b.rok AS rok_b,
	rok_b.prumerna_cena AS prumerna_cena_v_roce_b,
	rok_a.prumerna_cena - rok_b.prumerna_cena AS mezirocni_rozdil_cen,
	(rok_a.prumerna_cena - rok_b.prumerna_cena)*100/rok_b.prumerna_cena AS rozdil_cen_v_procentech
FROM 
	(SELECT 
		cp.category_code AS category_code,
		cpc.name AS nazev,
		YEAR(cp.date_from) AS rok,
		AVG(cp.value) AS prumerna_cena
	FROM czechia_price cp
	JOIN czechia_price_category cpc
		ON cp.category_code = cpc.code
	GROUP BY category_code, YEAR(date_from)
	)
	AS rok_a
JOIN 
	(SELECT 
		cp.category_code AS category_code,
		cpc.name AS nazev,
		YEAR(cp.date_from) AS rok,
		AVG(cp.value) AS prumerna_cena
	FROM czechia_price cp
	JOIN czechia_price_category cpc
		ON cp.category_code = cpc.code
	GROUP BY category_code, YEAR(date_from)
	)
	AS rok_b
ON rok_a.rok = rok_b.rok + 1
	AND rok_a.category_code = rok_b.category_code
;

-- Vyfiltruju přes WHERE pouze hodnoty růstu větší než 0 (chci pouze růst, ne pokles).
-- Nakonec data seřadím vzestupně podle hodnot meziročního růstu
-- a omezím (LIMIT) pouze na první (a tedy nejnižší) záznam.
-- Kategorie potravin u tohoto záznamu bude odpovědí na výzkumnou otázku.
SELECT 
	rok_a.category_code,
	rok_a.nazev,
	rok_a.rok AS rok_a,
	rok_a.prumerna_cena AS prumerna_cena_v_roce_a,
	rok_b.rok AS rok_b,
	rok_b.prumerna_cena AS prumerna_cena_v_roce_b,
	rok_a.prumerna_cena - rok_b.prumerna_cena AS mezirocni_rozdil_cen,
	(rok_a.prumerna_cena - rok_b.prumerna_cena)*100/rok_b.prumerna_cena AS rozdil_cen_v_procentech
FROM 
	(SELECT 
		cp.category_code AS category_code,
		cpc.name AS nazev,
		YEAR(cp.date_from) AS rok,
		AVG(cp.value) AS prumerna_cena
	FROM czechia_price cp
	JOIN czechia_price_category cpc
		ON cp.category_code = cpc.code
	GROUP BY category_code, YEAR(date_from)
	)
	AS rok_a
JOIN 
	(SELECT 
		cp.category_code AS category_code,
		cpc.name AS nazev,
		YEAR(cp.date_from) AS rok,
		AVG(cp.value) AS prumerna_cena
	FROM czechia_price cp
	JOIN czechia_price_category cpc
		ON cp.category_code = cpc.code
	GROUP BY category_code, YEAR(date_from)
	)
	AS rok_b
ON rok_a.rok = rok_b.rok + 1
	AND rok_a.category_code = rok_b.category_code
WHERE (rok_a.prumerna_cena - rok_b.prumerna_cena)*100/rok_b.prumerna_cena > 0
ORDER BY (rok_a.prumerna_cena - rok_b.prumerna_cena)*100/rok_b.prumerna_cena
LIMIT 1
;

-- ODPOVĚĎ NA VÝZKUMNOU OTÁZKU
-- 3. Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?

/*
Nejpomalejší meziroční percentuální zdražení pozorujeme u rostlinného roztíratelného tuku,
a to mezi lety 2008 a 2009, 
kdy se jeho cena zvýšila z 84,3963 Kč na 84,4096 Kč (za 1 kg), tedy o pouhých 0.0157 %.
*/