-- 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

-- Pozn. Měla bych si data pročistit od hodnot branch IS NULL 
-- (protože chci porovnávat mzdy právě podle uvedených oborů).
-- NULL obory se ale nějak samy vytratily v průběhu práce.

-- Vytvořím si sloupce se součtem values a průměrem values (values = průměrné mzdy),
-- seskupím podle roku & odvětví.
-- Součet hodnot později zahodím, je jen pro kotrolu.
SELECT 	
	payroll_year,
	industry_branch_code AS branch,
	SUM(value) AS součet_hodnot_za_rok,
	SUM(value)/COUNT(payroll_quarter) AS průměr_hodnot_za_rok
FROM czechia_payroll 
WHERE calculation_code = 200
	AND value_type_code = 5958
GROUP BY payroll_year, industry_branch_code;

-- Potřebuju přidat sloupec na výpočet meziročního rozdílu.
-- Nejspíš to půjde JOINem tabulky na sebe samu.
-- Co chci do JOINu? Data z předcházejícího roku.
-- Na základě čehož potom vytvořím sloupec porovnávající hodnoty z jednotlivých let.
SELECT 	
	rok_a.industry_branch_code AS branch,
	rok_a.payroll_year AS rok_a,
	SUM(rok_a.value) AS součet_hodnot_za_rok_a,
	SUM(rok_a.value)/COUNT(payroll_quarter) AS průměr_hodnot_za_rok_a,
	rok_b.payroll_year AS rok_b,
	rok_b.součet_hodnot_za_rok AS součet_hodnot_za_rok_b,
	rok_b.průměr_hodnot_za_rok AS průměr_hodnot_za_rok_b
FROM czechia_payroll AS rok_a
JOIN 
	(SELECT 	
	payroll_year,
	industry_branch_code AS branch,
	SUM(value) AS součet_hodnot_za_rok,
	SUM(value)/COUNT(payroll_quarter) AS průměr_hodnot_za_rok
	FROM czechia_payroll
	WHERE calculation_code = 200
		AND value_type_code = 5958
	GROUP BY payroll_year, industry_branch_code)
	AS rok_b
ON rok_a.payroll_year = rok_b.payroll_year + 1
	AND rok_a.industry_branch_code = rok_b.branch
WHERE calculation_code = 200
	AND value_type_code = 5958
GROUP BY industry_branch_code, rok_a.payroll_year;

-- Pro přehlednost si už vymažu kontrolní sloupce se součty.
-- Vytvořím sloupec porovnávající hodnoty z jednotlivých let.
-- Na základě tohoto sloupce vytvořím CASE sloupec, který určí, 
-- zda je meziroční rozdíl pozitivní, nebo negativní/0.
SELECT 	
	rok_a.industry_branch_code AS branch,
	rok_a.payroll_year AS rok_a,
	SUM(rok_a.value)/COUNT(payroll_quarter) AS průměr_hodnot_za_rok_a,
	rok_b.payroll_year AS rok_b,
	rok_b.průměr_hodnot_za_rok AS průměr_hodnot_za_rok_b,
	SUM(rok_a.value)/COUNT(payroll_quarter) - rok_b.průměr_hodnot_za_rok AS meziroční_rozdíl,
	CASE
		WHEN SUM(rok_a.value)/COUNT(payroll_quarter) - rok_b.průměr_hodnot_za_rok > 0 THEN 1
		WHEN SUM(rok_a.value)/COUNT(payroll_quarter) - rok_b.průměr_hodnot_za_rok <= 0 THEN 0
	END AS růst
FROM czechia_payroll AS rok_a
JOIN 
	(SELECT 	
	payroll_year,
	industry_branch_code AS branch,
	SUM(value) AS součet_hodnot_za_rok,
	SUM(value)/COUNT(payroll_quarter) AS průměr_hodnot_za_rok
	FROM czechia_payroll
	WHERE calculation_code = 200
		AND value_type_code = 5958
	GROUP BY payroll_year, industry_branch_code)
	AS rok_b
ON rok_a.payroll_year = rok_b.payroll_year + 1
	AND rok_a.industry_branch_code = rok_b.branch
WHERE calculation_code = 200
	AND value_type_code = 5958
GROUP BY industry_branch_code, rok_a.payroll_year;

-- Sloupec určující, zde se jedná o růst, teď musím využít pro porovnání růstů mezi jednotlivými odvětvými.
-- Protože už je SQL zápis delší a komplikovaný, vytvořím si VIEW (mezirocni_porovnani_mezd_cr), 
-- abych si ze záznamů jednoduše a rychle vytáhla jen informace o růstu podle odvětví.
CREATE VIEW mezirocni_porovnani_mezd_cr AS
(SELECT 	
	rok_a.industry_branch_code AS branch,
	rok_a.payroll_year AS rok_a,
	SUM(rok_a.value)/COUNT(payroll_quarter) AS průměr_hodnot_za_rok_a,
	rok_b.payroll_year AS rok_b,
	rok_b.průměr_hodnot_za_rok AS průměr_hodnot_za_rok_b,
	SUM(rok_a.value)/COUNT(payroll_quarter) - rok_b.průměr_hodnot_za_rok AS meziroční_rozdíl,
	CASE
		WHEN SUM(rok_a.value)/COUNT(payroll_quarter) - rok_b.průměr_hodnot_za_rok > 0 THEN 1
		WHEN SUM(rok_a.value)/COUNT(payroll_quarter) - rok_b.průměr_hodnot_za_rok <= 0 THEN 0
	END AS růst
FROM czechia_payroll AS rok_a
JOIN 
	(SELECT 	
	payroll_year,
	industry_branch_code AS branch,
	SUM(value) AS součet_hodnot_za_rok,
	SUM(value)/COUNT(payroll_quarter) AS průměr_hodnot_za_rok
	FROM czechia_payroll
	WHERE calculation_code = 200
		AND value_type_code = 5958
	GROUP BY payroll_year, industry_branch_code)
	AS rok_b
ON rok_a.payroll_year = rok_b.payroll_year + 1
	AND rok_a.industry_branch_code = rok_b.branch
WHERE calculation_code = 200
	AND value_type_code = 5958
GROUP BY industry_branch_code, rok_a.payroll_year);

-- Porovnám hromadně růst/pokles mezd mezi jednotlivými odvětvými.

-- Zajímá mě klesání mzdy, nejen nerůst.
-- Zkontroluji tedy, že ve sloupci meziroční_rozdíl není hodnota 0.
SELECT 
	branch,
	meziroční_rozdíl
FROM mezirocni_porovnani_mezd_cr
WHERE meziroční_rozdíl = 0;
-- Žádný záznam o nulovém meziročním rozdílu v datech nemáme, 
-- pracuji tedy s nerůstem jakožto s poklesem.

-- Ve VIEW si zobrazím sloupec s počtem let, 
-- kdy mzda v daném odvětví meziročně klesala.
-- Sloupce pocet_zkoumanych_let & pocet_let_rustu slouží jen pro kontrolu, později je smažu.
-- Přidám přes JOIN názvy odvětví, abych mohla uvést konkrétní obory v odpovědi na výzkumnou otázku.
SELECT mpm.branch,
	cpib.name,
	COUNT(mpm.růst) pocet_zkoumanych_let,
	SUM(mpm.růst) pocet_let_rustu,
	CASE 
		WHEN SUM(mpm.růst) = COUNT(mpm.růst) THEN 0
		WHEN SUM(mpm.růst) = COUNT(mpm.růst) - 1 THEN 1
		WHEN SUM(mpm.růst) = COUNT(mpm.růst) - 2 THEN 2
		WHEN SUM(mpm.růst) = COUNT(mpm.růst) - 3 THEN 3
		WHEN SUM(mpm.růst) = COUNT(mpm.růst) - 4 THEN 4
		WHEN SUM(mpm.růst) < COUNT(mpm.růst) - 4 THEN 'více než 4'
	END AS pocet_let_poklesu
FROM mezirocni_porovnani_mezd_cr mpm
JOIN czechia_payroll_industry_branch cpib 
	ON mpm.branch = cpib.code
GROUP BY branch
ORDER BY pocet_let_poklesu DESC;

-- ODPOVĚĎ NA VÝZKUMNOU OTÁZKU
-- 1. Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?

/*
Ve zkoumaném období (20,5 let) mzdy meziročně vždy rostly pouze ve třech oborech: 
Zpracovatelský průmysl, Zdravotní a sociální péče a Ostatní činnosti.

Nejvíce meziročních poklesů mzdy (4) ve zkoumaném období zaregistroval obor Těžba a dobývání.

Mzdy klesaly 3 roky z celkového počtu zkoumaných let v oborech:
Výroba a rozvod elektřiny, plynu, tepla a klimatiz. vzduchu,
Veřejná správa a obrana; povinné sociální zabezpečení, 
Činnosti v oblasti nemovitostí,
Ubytování, stravování a pohostinství.

ZÁVĚR:
Mzdy zpravidla meziročně rostou.
Neustálý růst byl zjištěn ve 3 uvedených oborech.
U ostatních oborů mzdy meziročně klesly maximálně 4krát z 21 zkoumaných časových úseků (20,5 let).
*/