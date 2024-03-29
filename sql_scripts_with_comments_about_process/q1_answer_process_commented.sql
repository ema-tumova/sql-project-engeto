-- Q1: Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

-- Filtruju data z primární tabulky pouze na data o mzdách (kategorie = 'mzda').
-- Tabulku napojím samu na sebe JOINem pro získání meziročního porovnání (pf1.rok = pf2.rok - 1).
-- Zobrazím pouze sloupce, které jsou důležité a vhodně je pojmenuju.
-- Vytvořím sloupec pro výpočet meziročního rozdílu hodnot.
-- Vytvořím CASE sloupec 'rust' pro ověření, zda hodnota meziročně vzrostla (1) nebo klesla (0).
-- Nejdříve ale ověřím, že neexistuje záznam s nulovým meziročním rozdílem (ani pokles, ani růst).
-- Zjistím to pomocí WHERE klauzule (WHERE pf2.prum_hodnota - pf1.prum_hodnota = 0).
-- Žádný takový záznam nebyl nalezen, pokračuji tedy přidáním CASE sloupce 'rust'.
-- Vytvořím si VIEW, které bude podkladem pro finální zobrazení dat a odpověď.

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

-- Data z view 'mezirocni_rust_mzdy' seskupím podle odvětví.
-- V novém CASE sloupci uvedu, kolikrát mzda meziročně poklesla.
-- Data seřadím podle počtu let s poklesem prům. mzdy.

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