-- Q4: Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?

CREATE VIEW IF NOT EXISTS rozdily_mzdy
AS
	(SELECT
		rok_a.rok AS rok_a,
		rok_a.prum_mzda AS prum_mzda_a,
		rok_b.rok AS rok_b,
		rok_b.prum_mzda AS prum_mzda_b,
		ROUND(((rok_b.prum_mzda - rok_a.prum_mzda)*100)/rok_a.prum_mzda, 3) AS mezirocni_percent_rozdil_prum_mzdy
	FROM
		(SELECT
			rok,
			ROUND(AVG(prum_hodnota), 2) AS prum_mzda
		FROM t_ema_tumova_project_sql_primary_final
		WHERE 
			kategorie = 'mzda'
		GROUP BY
			rok)
		AS rok_a
	JOIN
		(SELECT
			rok,
			ROUND(AVG(prum_hodnota), 2) AS prum_mzda
		FROM t_ema_tumova_project_sql_primary_final
		WHERE 
			kategorie = 'mzda'
		GROUP BY
			rok)
		AS rok_b
	ON 
		rok_a.rok = rok_b.rok - 1)
;

CREATE VIEW IF NOT EXISTS rozdily_ceny 
AS
	(SELECT 
		rok_a.nazev_podkategorie,	
		rok_a.rok AS rok_a,
		ROUND(rok_a.prum_hodnota, 3) AS prum_cena_a,
		rok_b.rok AS rok_b,
		ROUND(rok_b.prum_hodnota, 3) AS prum_cena_b,
		ROUND(((rok_b.prum_hodnota - rok_a.prum_hodnota)*100)/rok_a.prum_hodnota, 3) AS mezirocni_percent_rozdil
	FROM
		(SELECT
			rok,
			kod_podkategorie,
			nazev_podkategorie,
			prum_hodnota
		FROM t_ema_tumova_project_sql_primary_final
		WHERE
			kategorie = 'cena')
		AS rok_a	
	JOIN
		(SELECT
			rok,
			kod_podkategorie,
			nazev_podkategorie,
			prum_hodnota
		FROM t_ema_tumova_project_sql_primary_final
		WHERE
			kategorie = 'cena')
		AS rok_b	
	ON
		rok_a.rok = rok_b.rok - 1
		AND rok_a.kod_podkategorie = rok_b.kod_podkategorie)
;

SELECT
	mzdy.rok_a,
	mzdy.rok_b,
	mzdy.prum_mzda_a,
	mzdy.prum_mzda_b,
	mzdy.mezirocni_percent_rozdil_prum_mzdy,
	ceny.prum_mezirocni_percent_rozdil_cen,
	(ceny.prum_mezirocni_percent_rozdil_cen - mzdy.mezirocni_percent_rozdil_prum_mzdy) AS rozdil_ceny_minus_mzdy,
	CASE 
		WHEN ceny.prum_mezirocni_percent_rozdil_cen - mzdy.mezirocni_percent_rozdil_prum_mzdy > 10 THEN 1
		ELSE 0
	END AS rust_ceny_vyraznejsi_nez_mzdy
FROM
	(SELECT
		rok_a,
		rok_b,
		ROUND(AVG(mezirocni_percent_rozdil), 4) AS prum_mezirocni_percent_rozdil_cen
	FROM rozdily_ceny
	GROUP BY 
		rok_a)
	AS ceny
JOIN
	(SELECT * 
	FROM rozdily_mzdy)
	AS mzdy
ON ceny.rok_a = mzdy.rok_a
ORDER BY
	rozdil_ceny_minus_mzdy DESC
;

/*
ODPOVĚĎ NA VÝZKUMNOU OTÁZKU:

V letech 2006-2018 nevzrostly průměrné ceny meziročně nikdy výrazně více (o více než 10 %) než průměrné mzdy.

Nejvyšší rozdíl růstu cen oproti mzdám (7,6 %) je z let 2012-2013,
kdy ceny meziročně vzrostly o 6 % a mzdy meziročně poklesly o 1,6 %.
*/