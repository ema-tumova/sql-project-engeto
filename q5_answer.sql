-- Q5: Má výška HDP vliv na změny ve mzdách a cenách potravin?
-- Neboli, pokud HDP vzroste výrazněji v jednom roce,
-- projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?

-- Porovnávám percentuální meziroční rozdíl pro ceny, mzdy a HDP.

-- Pro data o mzdách a cenách použiju výsledné zobrazení dat z předchozí otázky,
-- ale zobrazím pouze potřebné minimum.
SELECT
	mzdy.rok_a,
	mzdy.rok_b,
	mzdy.mezirocni_percent_rozdil_prum_mzdy,
	ceny.prum_mezirocni_percent_rozdil_cen
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
	rozdily_mzdy AS mzdy
ON
	ceny.rok_a = mzdy.rok_a
;

-- Pro data o HDP použiju sekundární tabulku. Vyberu sloupce rok a HDP pro ČR.
-- Pro meziroční srovnání HDP JOINuju tabulku samu na sebe a přidám sloupec s meziročním rozdílem HDP.
-- Vytvořím VIEW pro jednodušší následnou manipulaci s daty.
CREATE VIEW IF NOT EXISTS rozdily_HDP
AS
	(SELECT
		rok_a.rok AS rok_a,
		rok_a.HDP AS HDP_a,
		rok_b.rok AS rok_b,
		rok_b.HDP as HDP_b,
		ROUND(((rok_b.HDP - rok_a.HDP)*100)/rok_a.HDP, 3) AS mezirocni_percent_rozdil_HDP
	FROM 
		(SELECT
			rok,
			HDP
		FROM t_ema_tumova_project_sql_secondary_final
		WHERE
			zeme = 'Czech Republic')
		AS rok_a
	JOIN 
		(SELECT
			rok,
			HDP
		FROM t_ema_tumova_project_sql_secondary_final
		WHERE
			zeme = 'Czech Republic')
		AS rok_b 
	ON
		rok_a.rok = rok_b.rok - 1)
;

-- Spojím data o cenách a mzdách s daty o HDP.
-- Data budu potřebovat napojit samy na sebe, abych získala ještě další srovnání ob rok,
-- vytvořím si tedy nové VIEW pro jednodušší spojení.
CREATE VIEW IF NOT EXISTS ceny_mzdy_hdp
AS
	(SELECT
		mzdy.rok_a,
		mzdy.rok_b,
		mzdy.mezirocni_percent_rozdil_prum_mzdy AS rozdil_mzdy,
		ceny.prum_mezirocni_percent_rozdil_cen AS rozdil_ceny,
		hdp.mezirocni_percent_rozdil_HDP AS rozdil_hdp
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
		rozdily_mzdy AS mzdy
		ON ceny.rok_a = mzdy.rok_a
	JOIN
		rozdily_HDP AS hdp
		ON ceny.rok_a = hdp.rok_a)
;

-- Napojím data samy na sebe pro srovnání ob rok.
-- Vytvořím 4 sloupce:
-- meziroční rozdíl HDP vs. meziroční rozdíl cen/mezd ve stejném a v následujícím roce.
-- Počítám absolutní hodnotu rozdílu, protože nechci, aby záleželo na pořadí porovnávaných položek.
-- Chci dostat absolutní 'vzdálenost' rozdílů.
-- Vytvořím VIEW, abych mohla jednoduše filtrovat data a přitom neztratila ta, co se mohou ještě hodit.
CREATE VIEW IF NOT EXISTS ceny_mzdy_hdp_korelace
AS 
	(SELECT
		roky_ab.rok_a,
		roky_ab.rok_b,
		rok_c.rok_b AS rok_c,
		roky_ab.rozdil_mzdy AS rozdil_mzdy_ab,
		roky_ab.rozdil_ceny AS rozdil_ceny_ab,
		roky_ab.rozdil_hdp AS rozdil_hdp_ab,
		rok_c.rozdil_mzdy AS rozdil_mzdy_bc,
		rok_c.rozdil_ceny AS rozdil_ceny_bc,
		rok_c.rozdil_hdp AS rozdil_hdp_bc,
		ABS(roky_ab.rozdil_hdp - roky_ab.rozdil_ceny) AS hdp_ab_vs_ceny_ab,
		ABS(roky_ab.rozdil_hdp - roky_ab.rozdil_mzdy) AS hdp_ab_vs_mzdy_ab,
		ABS(roky_ab.rozdil_hdp - rok_c.rozdil_ceny) AS hdp_ab_vs_ceny_bc,
		ABS(roky_ab.rozdil_hdp - rok_c.rozdil_mzdy) AS hdp_ab_vs_mzdy_bc
	FROM 
		(SELECT * 
		FROM ceny_mzdy_hdp)
		AS roky_ab
	JOIN
		(SELECT * 
		FROM ceny_mzdy_hdp)
		AS rok_c
	ON 
		roky_ab.rok_b = rok_c.rok_a)
;

-- Je otázka, co můžeme považovat za výrazný vliv.
-- Zde budu za korelující považovat hodnoty lišící se maximálně o 3 %.
-- Vytvořím 4 podmínkové sloupce pro 4 dříve vytvořené sloupce.
-- Budou značit, zda je absolutní rozdíl hodnot nižší než 3 % (1) nebo vyšší (0).
-- Vytvořím 2 další podmínkové sloupce, abych zjistila,
-- zda hodnoty korelují více ve stejném roce (1) nebo ob rok (0).
SELECT 
	rok_a,
	rok_b,
	rok_c,
	hdp_ab_vs_ceny_ab,
	IF (hdp_ab_vs_ceny_ab < 3, 1, 0) AS hdp_ab_vs_ceny_ab_mene_nez_3,
	hdp_ab_vs_mzdy_ab,
	IF (hdp_ab_vs_mzdy_ab < 3, 1, 0) AS hdp_ab_vs_mzdy_ab_mene_nez_3,
	hdp_ab_vs_ceny_bc,
	IF (hdp_ab_vs_ceny_bc < 3, 1, 0) AS hdp_ab_vs_ceny_bc_mene_nez_3,
	hdp_ab_vs_mzdy_bc,
	IF (hdp_ab_vs_mzdy_bc < 3, 1, 0) AS hdp_ab_vs_mzdy_bc_mene_nez_3,
	IF (hdp_ab_vs_ceny_ab < hdp_ab_vs_ceny_bc, 1, 0) AS hdp_vs_ceny_korel_vice_stejny_rok,
	IF (hdp_ab_vs_mzdy_ab < hdp_ab_vs_mzdy_bc, 1, 0) AS hdp_vs_mzdy_korel_vice_stejny_rok
FROM
	ceny_mzdy_hdp_korelace;


-- Data zprůměruju, abych získala celkový přehled.
SELECT 
	AVG(hdp_ab_vs_ceny_ab) AS avg_hdp_ab_vs_ceny_ab,
	AVG(IF (hdp_ab_vs_ceny_ab < 3, 1, 0)) AS avg_hdp_ab_vs_ceny_ab_mene_nez_3,
	AVG(hdp_ab_vs_ceny_bc) AS avg_hdp_ab_vs_ceny_bc,
	AVG(IF (hdp_ab_vs_ceny_bc < 3, 1, 0)) AS avg_hdp_ab_vs_ceny_bc_mene_nez_3,
	AVG(IF (hdp_ab_vs_ceny_ab < hdp_ab_vs_ceny_bc, 1, 0)) AS avg_hdp_vs_ceny_korel_vice_stejny_rok,
	AVG(hdp_ab_vs_mzdy_ab) AS avg_hdp_ab_vs_mzdy_ab,
	AVG(IF (hdp_ab_vs_mzdy_ab < 3, 1, 0)) AS avg_hdp_ab_vs_mzdy_ab_mene_nez_3,
	AVG(hdp_ab_vs_mzdy_bc) AS avg_hdp_ab_vs_mzdy_bc,
	AVG(IF (hdp_ab_vs_mzdy_bc < 3, 1, 0)) AS avg_hdp_ab_vs_mzdy_bc_mene_nez_3,
	AVG(IF (hdp_ab_vs_mzdy_ab < hdp_ab_vs_mzdy_bc, 1, 0)) AS avg_hdp_vs_mzdy_korel_vice_stejny_rok
FROM
	ceny_mzdy_hdp_korelace;

/*
ODPOVĚĎ NA VÝZKUMNOU OTÁZKU:

Změny v HDP korelují více se změnami ve mzdách než se změnami cen.

U mezd pozorujeme výraznější korelaci s ročním odstupem,
tzn. změna HDP v jednom roce koreluje výrazněji se změnou mezd v následujícím roce (průměrná odchylka 2,07 %)
než ve shodném roce (průměrná odchylka 2,41 %).

Korelace změn HDP a změn cen je nižší.
Ve stejném roce je tato korelace o něco vyšší (průměrná odchylka 4,09 %),
než když porovnáváme meziroční rozdíl HDP v jednom roce s meziročním rozdílem cen v následujícícm roce
(průměrná odchylka 4,66 %).

Zvolme maximální odchylku např. 3 % (od hranice 3 % a výše už nepovažujeme hodnoty za korelaci):

V tom případě korelují meziroční rozdíly cen a HDP pouze ve 36 %
(bez ohledu na to, zda porovnáváme hodnoty ze stejného roku nebo změnu cen s ročním odstupem od změny HDP).
Korelace mezi meziročními rozdíly mezd a HDP je výrazně vyšší:
73 % hodnot koreluje při porovnání ve stejném roce
a dokonce 82 % hodnot koreluje při porovnání změny mezd s meziročním odstupem od změny HDP.
*/