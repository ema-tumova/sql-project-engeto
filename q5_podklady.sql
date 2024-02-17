-- 5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, 
-- projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?
-- (Percentuální odchylky jednotlivých růstů a snížení HDP (průměrných mezd, cen) v rámci let.)

-- Budu vycházet z výsledné tabulky ze 4. otázky.
-- Vytvořím si z ní pro jednoduchost VIEW, které vhodně upravím.

-- Zruším filtr, který omezoval data pouze na kladné hodnoty růstu. 
-- Vymažu sloupce porovnávající mezi sebou růst cen a mezd. 
-- Seřadím podle let vzestupně.

-- Pro lepší přehled nebudu porovnávat pouze roky, pro něž jsou dostupná data jak pro ceny, tak pro platy, 
-- ale zobrazím všechny roky, pro které mám informace z jedné nebo druhé kategorie. 
-- Ceny mám dostupné pro roky 2006-2018, mzdy pro roky 2000-2021.
-- Zvolím tedy prum_mzdy LEFT JOIN prum_ceny, spárované na základě porovnávaných let.

CREATE OR REPLACE VIEW odchylky_ceny_a_mzdy
	AS
	(SELECT 
		prum_mzdy.rok_a,
		ROUND(prum_mzdy.prum_mzda_rok_a) AS prum_mzda_rok_a,
		prum_mzdy.rok_b,
		ROUND(prum_mzdy.prum_mzda_rok_b) AS prum_mzda_rok_b,
		ROUND(prum_mzdy.procentni_rust_prum_mzdy, 2) AS procentni_rust_prum_mzdy,
		ROUND(prum_ceny.prum_procentni_rust_cen, 2) AS prum_procentni_rust_cen
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
	LEFT JOIN
		(SELECT
			rok_a,
			rok_b,
			AVG(rozdil_cen_v_procentech) AS prum_procentni_rust_cen
		FROM mezirocni_srovnani_prum_cen
		GROUP BY rok_a
		)
		AS prum_ceny
	ON prum_mzdy.rok_a = prum_ceny.rok_a
	ORDER BY rok_a
)
;

-- Zjistím, pro jaké roky jsou dostupné informace o HDP v ČR v tabulce economies:
SELECT country, GDP, year
FROM economies
WHERE country = 'Czech Republic' AND GDP IS NOT NULL
ORDER BY year;
-- 1990 - 2020
-- Roky 1990-1999 nebudu do výsledného srovnání zahrnovat, 
-- protože je není s čím porovnávat (chybí data pro mzdy a ceny).

-- Vytvořím si tabulku pro procentuální růst HDP v ČR pro roky 2000-2020, 
-- kterou poté napojím k právě vytvořenému VIEW s procentuálními rozdíly cen a mezd.

-- Tabulku s HDP prvně JOINuju samu na sebe pro meziroční porovnání HDP (na základě rozdílu let + 1).
-- Poté přidám sloupec s meziroční percentuální odchylkou.

-- Z hotové tabulky pro HDP vytvořím VIEW odchylky_hdp,
-- které jednodušeji napojím na připravené VIEW s daty o cenách a mzdách.

CREATE OR REPLACE VIEW odchylky_hdp AS
	(SELECT 
		ROUND(rok_a.gdp) AS HDP_rok_a,
		rok_a.rok AS rok_a,
		ROUND(rok_b.gdp) AS HDP_rok_b,
		rok_b.rok AS rok_b,
		ROUND(((rok_a.gdp-rok_b.gdp)*100) / rok_b.gdp, 2) AS percent_rozdil_HDP
	FROM 
		(SELECT
			country, 
			GDP, 
			year AS rok
		FROM economies
		WHERE
			country = 'Czech Republic'
			AND year BETWEEN 2000 AND 2020)
		AS rok_a
		JOIN
		(SELECT
			country, 
			GDP, 
			year AS rok
		FROM economies
		WHERE
			country = 'Czech Republic'
			AND year BETWEEN 2000 AND 2020)
		AS rok_b
	ON rok_a.rok = rok_b.rok + 1
	ORDER BY rok_a.rok ASC)
;

-- Vytvořená VIEWs na sebe napojím pomocí JOINu, 
-- tedy tak, abych porovnávala pouze roky, které jsou v obou VIEWs.
-- Vytvořím tak nové VIEW mzdy_ceny_hdp, které budu dále rozpracovávat.
CREATE OR REPLACE VIEW mzdy_ceny_hdp 
AS
	(SELECT 
		ocm.rok_a AS rok_a,
		ocm.rok_b AS rok_b,
		ocm.prum_mzda_rok_a AS prum_mzda_a,
		ocm.prum_mzda_rok_b AS prum_mzda_b,
		ocm.procentni_rust_prum_mzdy AS procent_rozdil_mzdy,
		ocm.prum_procentni_rust_cen AS procent_rozdil_ceny,
		oh.HDP_rok_a AS HDP_a,
		oh.HDP_rok_b AS HDP_b,
		oh.percent_rozdil_HDP AS procent_rozdil_HDP
	FROM odchylky_ceny_a_mzdy AS ocm
	JOIN odchylky_hdp AS oh
	ON ocm.rok_a = oh.rok_a)
;

-- Chci zjistit, zda meziroční percentuální změny HDP korelují s meziročními percentuálními změnami mezd a cen.
-- To provedu odečtením těchto hodnot (zjištěním absolutní hodnoty jejich rozdílu).
-- Čím menší odchylka, tím podobnější byl vývoj v porovnávaných kategoriích.
SELECT *,
	ABS(procent_rozdil_HDP - procent_rozdil_ceny) AS HDP_vs_ceny,
	ABS(procent_rozdil_HDP - procent_rozdil_mzdy) AS HDP_vs_mzdy
FROM mzdy_ceny_hdp;

-- Porovnání ale nechceme jen pro stejné roky.
-- Chci zjistit, jestli se změny v HDP neprojeví také v následujícím roce v cenách a mzdách. 
-- Budu tedy znovu potřebovat JOINovat tabulku samu na sebe přes roční rozdíl.
-- Vytvořím dva sloupce pro porovnání růstu HDP v jednom roce a cen/mezd v roce následujícím.
SELECT prvni_rok.*,
	druhy_rok.rok_a AS rok_c,
	ABS(prvni_rok.procent_rozdil_HDP - druhy_rok.procent_rozdil_ceny) AS HDP_vs_ceny_rok_c,
	ABS(prvni_rok.procent_rozdil_HDP - druhy_rok.procent_rozdil_mzdy) AS HDP_vs_mzdy_rok_c
FROM 
	(SELECT *,
		ABS(procent_rozdil_HDP - procent_rozdil_ceny) AS HDP_vs_ceny,
		ABS(procent_rozdil_HDP - procent_rozdil_mzdy) AS HDP_vs_mzdy
	FROM mzdy_ceny_hdp)
	AS prvni_rok
	JOIN
	(SELECT *,
		ABS(procent_rozdil_HDP - procent_rozdil_ceny) AS HDP_vs_ceny,
		ABS(procent_rozdil_HDP - procent_rozdil_mzdy) AS HDP_vs_mzdy
	FROM mzdy_ceny_hdp)
	AS druhy_rok
ON druhy_rok.rok_a = prvni_rok.rok_a + 1
ORDER BY prvni_rok.rok_a
;

-- Z předchozí tabulky si vytvořím VIEW celkove_srovnani.
CREATE OR REPLACE VIEW celkove_srovnani 
AS
(SELECT prvni_rok.*,
	druhy_rok.rok_a AS rok_c,
	ABS(prvni_rok.procent_rozdil_HDP - druhy_rok.procent_rozdil_ceny) AS HDP_vs_ceny_rok_c,
	ABS(prvni_rok.procent_rozdil_HDP - druhy_rok.procent_rozdil_mzdy) AS HDP_vs_mzdy_rok_c
FROM 
	(SELECT *,
		ABS(procent_rozdil_HDP - procent_rozdil_ceny) AS HDP_vs_ceny,
		ABS(procent_rozdil_HDP - procent_rozdil_mzdy) AS HDP_vs_mzdy
	FROM mzdy_ceny_hdp)
	AS prvni_rok
	JOIN
	(SELECT *,
		ABS(procent_rozdil_HDP - procent_rozdil_ceny) AS HDP_vs_ceny,
		ABS(procent_rozdil_HDP - procent_rozdil_mzdy) AS HDP_vs_mzdy
	FROM mzdy_ceny_hdp)
	AS druhy_rok
ON druhy_rok.rok_a = prvni_rok.rok_a + 1
ORDER BY prvni_rok.rok_a)
;

-- Je otázkou, jak malou odchylku už budeme vnímat jako 'vliv'. 
-- Zvolím tuto odchylku jako rozdíl o maximálně 3 procenta.
-- Přidám CASE sloupce pro porovnání rozdílů v odchylkách cen/mezd a HDP
-- (1 nebo 0 podle toho, zda odchylka <= 3 nebo >3).
CREATE OR REPLACE VIEW celkove_srovnani_avg_vliv
AS
	(SELECT *,
		CASE 
			WHEN HDP_vs_ceny IS NULL THEN NULL 
			WHEN HDP_vs_ceny <= 3 THEN 1 
			ELSE 0
		END AS vliv_HDP_vs_ceny,
		CASE 
			WHEN HDP_vs_mzdy IS NULL THEN NULL 
			WHEN HDP_vs_mzdy <= 3 THEN 1 
			ELSE 0
		END AS vliv_HDP_vs_mzdy,
		CASE 
			WHEN HDP_vs_ceny_rok_c IS NULL THEN NULL 
			WHEN HDP_vs_ceny_rok_c <= 3 THEN 1 
			ELSE 0
		END AS vliv_HDP_vs_ceny_rok_c,
		CASE 
			WHEN HDP_vs_mzdy_rok_c IS NULL THEN NULL 
			WHEN HDP_vs_mzdy_rok_c <= 3 THEN 1 
			ELSE 0
		END AS vliv_HDP_vs_mzdy_rok_c
	FROM celkove_srovnani)
;

SELECT 
	AVG(vliv_HDP_vs_ceny) AS avg_vliv_HDP_vs_ceny,
	AVG(vliv_HDP_vs_mzdy) AS avg_vliv_HDP_vs_mzdy,
	AVG(vliv_HDP_vs_ceny_rok_c) AS avg_vliv_HDP_vs_ceny_rok_c,
	AVG(vliv_HDP_vs_mzdy_rok_c) AS avg_vliv_HDP_vs_mzdy_rok_c
FROM celkove_srovnani_avg_vliv;

-- ODPOVĚĎ NA VÝZKUMNOU OTÁZKU
-- 5. Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, 
-- projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?

/*
Zvolíme-li dostatečně nízkou odchylku (rozdíl o maximálně 3 procenta), pozorujeme, že změny v HDP
korelují více se změnami ve mzdách než se změnami cen. 
U mezd pozorujeme výraznější korelaci s ročním odstupem,
tzn. změna HDP v jednom roce koreluje výrazněji se změnou mezd v následujícím roce než ve shodném roce.
Výrazná korelace změn v HDP a změn v cenách se neprokázala, a to ani ve shodném roce, 
ani když porovnáváme rozdíl HDP z jednoho roku s rozdílem cen z následujícícho roku.
Může to být způsobeno příliž nízko zvolenou odchylkou (rozdíl o maximálně 3 procenta), 
ale také opravdu nižší korelací mezi porovnávanými hodnotami.
*/