-- 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

-- Budu pracovat s daty o meziročním růstu cen a mezd, 
-- takže využiju podklady již vytvořené při zodpovídání předchozích otázek (otázky 1 a 3).
-- Navážu na sebe tabulky o mzdách a o cenách pomocí JOINu tak, aby se shodovaly porovnávané roky.
-- U cen i mezd budu muset počítat s procentuálním rozdílem, nikoli pouze s meziročním rozdílem hodnot.
-- Poté budu porovnávat meziroční percentuální růsty cen a meziroční percentuální růsty mezd.


-- Hodnoty prům. mezd a jejich meziroční růst:
-- Oproti původnímu VIEWu mezirocni_porovnani_mezd_cr z otázky 1 zde nechci zohledňovat obor.
-- Použiju tedy pouze sloupce roků a sloupce průměrů průměrných mezd
-- (musím mzdy znovu průměrovat, protože původní průměrné mzdy se týkaly jednotlivých odvětví).
SELECT 
	rok_a,
	AVG(průměr_hodnot_za_rok_a) AS prum_mzda_rok_a,
	rok_b,
	AVG(průměr_hodnot_za_rok_b) AS prum_mzda_rok_b
FROM mezirocni_porovnani_mezd_cr
GROUP BY rok_a;

-- Přidám sloupec s meziročním percentuálním růstem průměrné mzdy.
SELECT 
	rok_a,
	AVG(průměr_hodnot_za_rok_a) AS prum_mzda_rok_a,
	rok_b,
	AVG(průměr_hodnot_za_rok_b) AS prum_mzda_rok_b,
	(AVG(průměr_hodnot_za_rok_a) - AVG(průměr_hodnot_za_rok_b)) *100 / AVG(průměr_hodnot_za_rok_b) AS procentni_rust_prum_mzdy
FROM mezirocni_porovnani_mezd_cr
GROUP BY rok_a;


-- Hodnoty prům. cen a jejich meziroční růst:
-- Z tabulky k otázce 3 si vytvořím VIEW, aby se mi s daty lépe pracovalo.
CREATE VIEW mezirocni_srovnani_prum_cen
AS
	(SELECT 
		rok_a.category_code,
		rok_a.nazev,
		rok_a.rok AS rok_a,
		rok_a.prumerna_cena AS prum_cena_v_roce_a,
		rok_b.rok AS rok_b,
		rok_b.prumerna_cena AS prum_cena_v_roce_b,
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
	)
;

-- Narozdíl od mezd, kde jsem odstraňovala závislost na odvětví, u cen potravin chci počítat s jejich kategorií.
-- Průměruju tedy rovnou percentuální meziroční růst cen potravin.
-- Použiju sloupce roků a sloupec pro meziroční percentuální porovnání cen.
-- Nebudu zobrazovat hodnoty průměrných cen za rok, protože by byly zavádějící
-- (prům. cena za jednu potravinu za rok je příliš abstraktní).

SELECT
	rok_a,
	rok_b,
	AVG(rozdil_cen_v_procentech) AS prum_procentni_rust_cen
FROM mezirocni_srovnani_prum_cen
GROUP BY rok_a;


-- Připravené tabulky spojím JOINem na základě shodných roků.

SELECT 
	prum_mzdy.*,
	prum_ceny.prum_procentni_rust_cen
FROM 
	(SELECT 
		rok_a,
		AVG(průměr_hodnot_za_rok_a) AS prum_mzda_rok_a,
		rok_b,
		AVG(průměr_hodnot_za_rok_b) AS prum_mzda_rok_b,
		(AVG(průměr_hodnot_za_rok_a) - AVG(průměr_hodnot_za_rok_b)) *100 / AVG(průměr_hodnot_za_rok_b) AS procentni_rust_prum_mzdy
	FROM mezirocni_porovnani_mezd_cr
	GROUP BY rok_a
	)
	AS prum_mzdy
JOIN
	(SELECT
		rok_a,
		rok_b,
		AVG(rozdil_cen_v_procentech) AS prum_procentni_rust_cen
	FROM mezirocni_srovnani_prum_cen
	GROUP BY rok_a
	)
	AS prum_ceny
ON prum_mzdy.rok_a = prum_ceny.rok_a
;

-- Budu porovnávat meziroční percentuální růsty cen a meziroční percentuální růsty mezd, 
-- proto prvně vyfiltruju pomocí WHERE pouze kladné hodnoty percentuálních rozdílů.
-- Poté přidám sloupec porovnávající rozdíl růstu u cen a mezd (ceny_vs_mzdy_rozdil)
-- a sloupec CASE (ceny_vs_mzdy_rozdil_vyssi_nez_10) pro ověření, zda byl v některém roce rozdíl 
-- meziročního percentuálního nárůstu cen potravin a meziročního percentuálního růstu mezd vyšší než 10 %.
-- Pro větší přehlednost hodnoty v tabulce vhodně zaokrouhlím a tabulku uspořádám (ORDER BY)
-- podle sledovaného rozdílu cen a mezd sestupně.
SELECT 
	prum_mzdy.rok_a,
	ROUND(prum_mzdy.prum_mzda_rok_a) AS prum_mzda_rok_a,
	prum_mzdy.rok_b,
	ROUND(prum_mzdy.prum_mzda_rok_b) AS prum_mzda_rok_b,
	ROUND(prum_mzdy.procentni_rust_prum_mzdy, 2) AS procentni_rust_prum_mzdy,
	ROUND(prum_ceny.prum_procentni_rust_cen, 2) AS prum_procentni_rust_cen,
	ROUND(prum_ceny.prum_procentni_rust_cen - prum_mzdy.procentni_rust_prum_mzdy, 2) AS ceny_vs_mzdy_rozdil,
	CASE 
		WHEN prum_ceny.prum_procentni_rust_cen - prum_mzdy.procentni_rust_prum_mzdy > 10 THEN 1
		ELSE 0
	END AS ceny_vs_mzdy_rozdil_vyssi_nez_10
FROM 
	(SELECT 
		rok_a,
		AVG(průměr_hodnot_za_rok_a) AS prum_mzda_rok_a,
		rok_b,
		AVG(průměr_hodnot_za_rok_b) AS prum_mzda_rok_b,
		(AVG(průměr_hodnot_za_rok_a) - AVG(průměr_hodnot_za_rok_b)) *100 / AVG(průměr_hodnot_za_rok_b) AS procentni_rust_prum_mzdy
	FROM mezirocni_porovnani_mezd_cr
	GROUP BY rok_a
	)
	AS prum_mzdy
JOIN
	(SELECT
		rok_a,
		rok_b,
		AVG(rozdil_cen_v_procentech) AS prum_procentni_rust_cen
	FROM mezirocni_srovnani_prum_cen
	GROUP BY rok_a
	)
	AS prum_ceny
ON prum_mzdy.rok_a = prum_ceny.rok_a
WHERE 
	prum_mzdy.procentni_rust_prum_mzdy > 0
	AND prum_ceny.prum_procentni_rust_cen > 0
ORDER BY (prum_ceny.prum_procentni_rust_cen - prum_mzdy.procentni_rust_prum_mzdy) DESC
;

-- ODPOVĚĎ NA VÝZKUMNOU OTÁZKU
-- 4. Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

/*
Takový rok neexistuje. 
Nejvyšší hodnota rozdílu meziročního nárůstu cen potravin a meziročního percentuálního růstu mezd
je 4,54 % (mezi lety 2011 a 2012).
*/