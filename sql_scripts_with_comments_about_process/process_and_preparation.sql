/*
Postup tvorby projektu:

Nejdříve jsem si důkladně prošla zadání. 
Založila jsem první soubory projektu, aby měl základní strukturu.

Začala jsem určením zdrojových dat, která budou podkladem pro zodpovězení výzkumných otázek, a analýzou těchto dat.
Potřebná zdrojová data jsem seskupila do primární tabulky (data o cenách potravin a mzdách v ČR) a do sekundární tabulky (data o HDP a dalších ukazatelích v evropských zemích).

Poté jsem už mohla přistoupit k hledání odpovědí na jednotlivé výzkumné otázky.
V oddělených SQL souborech jsem vyřešila otázky jednu po druhé. 
U každé otázky jsem postupně vhodně filtrovala a upravovala zobrazovaná data z primární (popř. také sekundární) tabulky.
Každý SQL soubor obsahuje výsledný SQL příkaz, který zobrazí data, na jejichž základě jsem poté otázku zodpověděla.

Proces tvorby a vylaďování SQL dotazů jsem v SQL souborech průběžně komentovala.
Okomentované SQL soubory jsem přesunula do složky 'sql_scripts_with_comments_about_process'. 

Jako základní výstup projektu odevzdávám SQL soubory s minimem komentářů, 
obsahující pouze to nejdůležitější pro zodpovězení výzkumných otázek a také odpovědi samotné.
*/

/*
Datové sady pro získání datového podkladu:

Primární tabulky:
1.	czechia_payroll – Informace o mzdách v různých odvětvích za několikaleté období. Datová sada pochází z Portálu otevřených dat ČR.
2.	czechia_payroll_calculation – Číselník kalkulací v tabulce mezd.
3.	czechia_payroll_industry_branch – Číselník odvětví v tabulce mezd.
4.	czechia_payroll_unit – Číselník jednotek hodnot v tabulce mezd.
5.	czechia_payroll_value_type – Číselník typů hodnot v tabulce mezd.
6.	czechia_price – Informace o cenách vybraných potravin za několikaleté období. Datová sada pochází z Portálu otevřených dat ČR.
7.	czechia_price_category – Číselník kategorií potravin, které se vyskytují v našem přehledu.
*/

DESCRIBE czechia_payroll;
-- id -> 741371788 - 906098840
-- value -> NULL or 19 - 66089
-- value_type_code -> 316, 5958
-- unit_code -> 200, 80403
-- calculation_code -> 100, 200
-- industry_branch_code -> NULL or A-S
-- payroll_year -> 2000(4Q) - 2021(2Q)
-- payroll_quarter -> 4 čtvrtletí pro každý rok (1-4)

DESCRIBE czechia_payroll_value_type;
-- code: 316 = name: Průměrný počet zaměstnaných osob
-- code: 5958 = name: Průměrná hrubá mzda na zaměstnance
DESCRIBE czechia_payroll_unit;
-- code: 200 = name: Kč
-- code: 80403 = name: tis. osob (tis. os.)
DESCRIBE czechia_payroll_calculation;
-- code: 100 = name: fyzický = vč. částečných úvazků
-- code: 200 = name: přepočtený = pouze plné úvazky
DESCRIBE czechia_payroll_industry_branch;
-- code: A-S = name: <vypsaný obor>

DESCRIBE czechia_price;
-- id: 770138308 - 801137046
-- value
-- category_code -> 27 distinct kódů
-- date_from: 2006-01-02 - 2018-12-10
-- date_to: 2006-01-08 - 2018-12-16
--		(vždy se shoduje rok, někdy různý měsíc)
-- region_code: NULL, CZ010 - CZ080 
 
DESCRIBE czechia_price_category;
-- code -> 111101 - 213201 & 2000001
-- name -> <vypsaná potravina>
-- price_value -> 0.5, 0.75, 1, 10, 150
-- price_unit -> kg, l, ks, g

/*
Číselníky sdílených informací o ČR:
1.	czechia_region – Číselník krajů České republiky dle normy CZ-NUTS 2.
2.	czechia_district – Číselník okresů České republiky dle normy LAU.

Dodatečné tabulky:
1.	countries - Všemožné informace o zemích na světě, například hlavní město, měna, národní jídlo nebo průměrná výška populace.
2.	economies - HDP, GINI, daňová zátěž, atd. pro daný stát a rok.
*/

DESCRIBE economies;
-- country
-- year
-- GDP

/*
Výstup: 

Připravte robustní datové podklady, ve kterých bude možné vidět porovnání dostupnosti potravin 
na základě průměrných příjmů za určité časové období.

2 dvě tabulky, ze kterých se požadovaná data dají získat.

Primární: přehled pro ČR.
t_{jmeno}_{prijmeni}_project_SQL_primary_final 
(pro data mezd a cen potravin za ČR sjednocených na totožné porovnatelné období – společné roky)

Sekundární: tabulka s HDP, GINI koeficientem a populací dalších evropských států ve stejném období.
t_{jmeno}_{prijmeni}_project_SQL_secondary_final 
(pro dodatečná data o dalších evropských státech)

+ sady SQL, které z těchto tabulek získají datový podklad k odpovědím na výzkumné otázky. 
Vaše výstupy mohou hypotézy podporovat i vyvracet! Záleží na tom, co říkají data.
*/

/*
Výzkumné otázky:

1.	Rostou v průběhu let mzdy ve všech odvětvích, nebo v některých klesají?
2.	Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období 
	v dostupných datech cen a mezd?
	- Neřešit převedení hrubé mzdy na čistou.
3.	Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroční nárůst)?
	- Pozor, existují i negativní hodnoty.
4.	Existuje rok, ve kterém byl meziroční nárůst cen potravin výrazně vyšší než růst mezd (větší než 10 %)?
5.	Má výška HDP vliv na změny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výrazněji v jednom roce, 
	projeví se to na cenách potravin či mzdách ve stejném nebo následujícím roce výraznějším růstem?
	- Percentuální odchylky jednotlivých růstů a snížení HDP (průměrných mezd, cen) v rámci let.
*/