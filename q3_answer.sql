-- Q3: Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?

-- Primární tabulku spojím samu na sebe s jednoletým rozdílem.
-- Vyfiltruji jen kateogorii 'cena', zobrazím jen relevantní sloupce, cenu zaokrouhlím.
-- Přidám sloupec se zaokrouhleným meziročním percentuálním rozdílem.
-- Pomocí WHERE zobrazím pouze kladné meziroční rozdíly (otázka se ptá na nárůst).
-- Pomocí ORDER BY seřadím podle rozdílů vzestupně.
-- Pomocí LIMIT můžu výsledky omezit na první nejnižší meziroční percentiuální nárůst.
SELECT
	rok_a.nazev_podkategorie,
	rok_a.rok AS rok_a,
	ROUND(rok_a.prum_hodnota, 4) AS prum_cena_a,
	rok_b.rok AS rok_b,
	ROUND(rok_b.prum_hodnota, 4) AS prum_cena_b,
	ROUND(((rok_b.prum_hodnota - rok_a.prum_hodnota)*100)/rok_a.prum_hodnota, 4) AS mezirocni_percentualni_rozdil
FROM
	(SELECT *
	FROM t_ema_tumova_project_sql_primary_final
	)
	AS rok_a
JOIN 
	(SELECT *
	FROM t_ema_tumova_project_sql_primary_final
	)
	AS rok_b
ON
	rok_a.kategorie = 'cena'
	AND rok_a.rok = rok_b.rok - 1
	AND rok_a.kod_podkategorie = rok_b.kod_podkategorie
WHERE
	((rok_b.prum_hodnota - rok_a.prum_hodnota)*100)/rok_a.prum_hodnota > 0
ORDER BY
	((rok_b.prum_hodnota - rok_a.prum_hodnota)*100)/rok_a.prum_hodnota
LIMIT 1;

-- Jako odpověď vychází 'Rostlinný roztíratelný tuk'.
-- Ověřím, že je cena uvedena za kg:
SELECT *
FROM czechia_price_category
WHERE 
	name = 'Rostlinný roztíratelný tuk';
-- Ano, cena je za 1 kg.

-- Když navíc vyfiltrujeme meziroční růst např. na 0-5 %, můžeme zjistit,
-- které kategorie potravin zdražovaly takto pomalu nejčastěji.
SELECT
	rok_a.nazev_podkategorie,
	COUNT(rok_a.nazev_podkategorie) AS cetnost_rustu_pod_5_procent
FROM
	(SELECT *
	FROM t_ema_tumova_project_sql_primary_final
	)
	AS rok_a
JOIN 
	(SELECT *
	FROM t_ema_tumova_project_sql_primary_final
	)
	AS rok_b
ON
	rok_a.kategorie = 'cena'
	AND rok_a.rok = rok_b.rok - 1
	AND rok_a.kod_podkategorie = rok_b.kod_podkategorie
WHERE
	((rok_b.prum_hodnota - rok_a.prum_hodnota)*100)/rok_a.prum_hodnota BETWEEN 0 AND 5
GROUP BY
	nazev_podkategorie
ORDER BY
	COUNT(rok_a.nazev_podkategorie) DESC;

/*
ODPOVĚĎ NA VÝZKUMNOU OTÁZKU:
Nejpomalejší meziroční percentuální zdražení v období 2006-2018
proběhlo mezi lety 2008 a 2009 u rostlinného roztíratelného tuku,
kdy jeho průměrná cena stoupla z 84,3963 Kč na 84,4096 Kč (za 1 kg), tedy o pouhých 0.0157 %.

Navíc:
Nejčastější meziroční percentuální růst ceny mezi 0 a 5 %
zaznamenalo pivo, následované těstovinami, kaprem a hovězím.
*/