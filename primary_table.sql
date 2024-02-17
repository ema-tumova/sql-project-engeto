/*
Primární tabulka pro data mezd a cen potravin za ČR sjednocených na totožné porovnatelné období – společné roky.
Na základě pěti výzkumných otázek vytvořím primární tabulku
t_ema_tumova_project_SQL_primary_final,
ze které je možné získat data pro zodpovězení všech otázek o ČR.

Analyzuji, co budu potřebovat vyčíst z primární tabulky:

- q1: meziroční růst/pokles průměrných mezd podle odvětví 
	-> tabulka czechia_payroll
- q2: průměrná mzda a průměrná cena mléka a chleba 
	-> tabulka czechia_payroll, czechia_price, czechia_price_category
- q3: percentuální meziroční rozdíl cen potravin podle jejich kategorií
	-> tabulka czechia_price, czechia_price_category
- q4: percentuální meziroční rozdíl cen potravin a mezd
	-> tabulka czechia_payroll, czechia_price, czechia_price_category
- q5: percentuální meziroční rozdíl cen potravin, mezd a HDP
	-> tabulka czechia_payroll, czechia_price, czechia_price_category, economies
	-> HDP vyčtu ze sekundární tabulky, nebudu ho řadit do primární tabulky

Co by měla tabulka obsahovat:

	ROK,
		-> date_from a date_to (v tabulce czechia_price) jsou vždy ve shodném roce,
		   pro získání roku mi tedy stačí pouze jeden z těchto údajů
	ODVĚTVÍ pro zobrazenou průměrnou mzdu,
	PRŮMĚRNÁ MZDA v daném roce:
		-> vypočítám ji sečtením hodnot seskupených podle roku, 
		   vydělených počtem čtvtletí (uvedených záznamů pro stejný rok)
		-> filtr: calculation_code = 100 (plné i částečné úvazky)
		-> filtr: value_type_code = 5958 (mzdy),
	KATEGORIE potraviny pro zobrazenou průměrnou cenu,
	PRŮMĚRNÁ CENA potraviny v daném roce
*/

-- Jak tabulku zrealizovat?

-- Kdybych vytvořila sloupce tak, jak jsou uvedné výše,
-- byly by v jenom řádku záznamy, které spolu nesouvisejí (odvětví pro mzdy a kategorie potravin pro ceny):
SELECT
	cp.rok,
	cp.odvetvi,
	cp.prum_mzda,
	cpr.kod_kategorie,
	cpr.nazev_kategorie,
	cpr.prum_cena
FROM 
	(SELECT
		cp.payroll_year AS rok,
		cpib.name AS odvetvi,
		SUM(cp.value)/COUNT(cp.payroll_quarter) AS prum_mzda
	FROM czechia_payroll cp
	JOIN czechia_payroll_industry_branch cpib
		ON cp.industry_branch_code = cpib.code
	WHERE 
		cp.calculation_code = 100
		AND cp.value_type_code = 5958
	GROUP BY 
		cp.payroll_year,
		cp.industry_branch_code
	ORDER BY 
		cp.payroll_year,
		cp.industry_branch_code)
	AS cp
JOIN 
	(SELECT
		YEAR(cpr.date_from) AS rok,
		cpr.category_code AS kod_kategorie,
		cpc.name AS nazev_kategorie,
		AVG(cpr.value) AS prum_cena
	FROM czechia_price cpr
	JOIN czechia_price_category cpc
		ON cpr.category_code = cpc.code
	GROUP BY
		YEAR(cpr.date_from),
		cpr.category_code
	) 
	AS cpr
	ON cp.rok = cpr.rok
;

/*
Tomu se chci určitě vyhnout.
Proto pro vytvoření primární tabulky použiju UNION,
čímž pod sebe seřadím zvlášť data o cenách a zvlášť data o mzdách.

Sloupce budou:
	ROK,
	KATEGORIE ('cena' / 'mzda'),
	KÓD PODKATEGORIE (kód kategorie pro potraviny / kód odvětví pro mzdy),
	NÁZEV PODKATEGORIE (název kategorie pro potraviny / název odvětví pro mzdy),
	HODNOTA (průměrná hodnota za rok: cena pro potraviny / mzda pro mzdy)
*/

CREATE TABLE IF NOT EXISTS t_ema_tumova_project_SQL_primary_final 
AS
	(SELECT 	
		cp.payroll_year AS rok,
		CONCAT('mzda') AS kategorie,
		cp.industry_branch_code AS kod_podkategorie,
		cpib.name AS nazev_podkategorie,
		SUM(cp.value)/COUNT(cp.payroll_quarter) AS prum_hodnota
	FROM czechia_payroll cp
	JOIN czechia_payroll_industry_branch cpib
		ON cp.industry_branch_code = cpib.code
	WHERE
		cp.calculation_code = 100
		AND cp.value_type_code = 5958
	GROUP BY
		cp.payroll_year,
		cp.industry_branch_code
	ORDER BY 
		cp.payroll_year,
		cp.industry_branch_code)
UNION
	(SELECT
		YEAR(cpr.date_from) AS rok,
		CONCAT('cena') AS kategorie,
		cpr.category_code AS kod_podkategorie,
		cpc.name AS nazev_podkategorie,
		AVG(cpr.value) AS prum_hodnota
	FROM czechia_price cpr
	JOIN czechia_price_category cpc
		ON cpr.category_code = cpc.code
	GROUP BY
		YEAR(cpr.date_from),
		cpr.category_code)
;

-- Data o mzdách máme pro roky 2000 až 2021, o cenách pro roky 2006 až 2018.
-- Data mají být sjednocená na totožné porovnatelné období – společné roky.
-- Když tedy budu porovnávat mzdy a ceny, budu navíc filtrovat záznamy o mzdách:
-- zobrazím pak záznamy pouze pro roky 2006 až 2018.