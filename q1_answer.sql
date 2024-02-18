-- Q1: Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

CREATE VIEW IF NOT EXISTS mezirocni_rust_mzdy
AS
	(SELECT
		pf1.kod_podkategorie,
		pf1.nazev_podkategorie,
		pf1.rok AS rok_a,
		pf1.prum_hodnota AS prum_hodnota_a,
		pf2.rok AS rok_b,
		pf2.prum_hodnota AS prum_hodnota_b,
		pf2.prum_hodnota - pf1.prum_hodnota AS rozdil_hodnot,
		CASE 
			WHEN pf2.prum_hodnota - pf1.prum_hodnota > 0 THEN 1
			WHEN pf2.prum_hodnota - pf1.prum_hodnota < 0 THEN 0
		END AS rust
	FROM t_ema_tumova_project_sql_primary_final pf1
	JOIN 
		(SELECT *
		FROM t_ema_tumova_project_sql_primary_final
		) 
		AS pf2
		ON pf1.rok = pf2.rok - 1
			AND pf1.kategorie = 'mzda'
			AND pf1.kod_podkategorie = pf2.kod_podkategorie)
;

SELECT
	nazev_podkategorie,
	CASE
		WHEN COUNT(rust) - SUM(rust) = 0 THEN CONCAT('Prům. mzda vždy meziročně rostla.')
		WHEN COUNT(rust) - SUM(rust) > 0 THEN CONCAT('Prům. mzda ', COUNT(rust) - SUM(rust) ,'x meziročně klesla.')
	END AS mezirocni_klesani_prum_mzdy
FROM mezirocni_rust_mzdy
	GROUP BY kod_podkategorie
	ORDER BY COUNT(rust) - SUM(rust) DESC;

/*
ODPOVĚĎ NA VÝZKUMNOU OTÁZKU:

Průměrná mzda v letech 2000-2021 meziročně vždy rostla pouze ve čtyřech z devatenácti porovnávaných odvětví:
Administrativní a podpůrné činnosti, Zdravotní a sociální péče, Doprava a skladování a Ostatní činnosti.

Nejvíce meziročních poklesů průměrné mzdy (4) ve zkoumaném období zaregistrovalo odvětví Těžba a dobývání.

Průměrná mzda 3x meziročně poklesla v odvětvích:
Kulturní, zábavní a rekreační činnosti, 
Ubytování, stravování a pohostinství
a Veřejná správa a obrana; povinné sociální zabezpečení.

ZÁVĚR:

Mzdy ve všech odvětvích zpravidla meziročně rostou.
Neustálý meziroční růst byl však zjištěn pouze ve 4 z 19 zkoumaných odvětví.
U ostatních oborů mzdy alespoň jednou (maximálně 4x) meziročně klesly.
*/