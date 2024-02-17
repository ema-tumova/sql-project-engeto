-- Q2: Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období
-- v dostupných datech cen a mezd?

-- Z primární tabulky filtruji pouze první a poslední srovnatelné období = roky 2006 a 2018.
-- (Data o mzdách máme pro roky 2000 až 2021, o cenách pro roky 2006 až 2018.)

-- Nejdříve zvlášť upravím data o mzdách a o cenách.

-- MZDY:
-- Seskupím data podle roku, zprůměruji mzdy ze všech odvětví v daném roce, zaokrouhlím.
SELECT
	rok,
	ROUND(AVG(prum_hodnota)) AS prum_mzda
FROM t_ema_tumova_project_SQL_primary_final
WHERE 
	rok IN (2006, 2018)
	AND kategorie = 'mzda'
GROUP BY rok
;

-- CENY:
-- Vyfiltruji pouze mléko a chleba (nazev_podkategorie).

SELECT 
	rok,
	nazev_podkategorie,
	prum_hodnota AS prum_cena
FROM t_ema_tumova_project_SQL_primary_final
WHERE 
	rok IN (2006, 2018)
	AND kategorie = 'cena'
	AND nazev_podkategorie IN ('Chléb konzumní kmínový', 'Mléko polotučné pasterované')
;

-- Ověřím, že je cena uvedena za litry a kilogramy:
SELECT *
FROM czechia_price_category
WHERE 
	name IN ('Chléb konzumní kmínový', 'Mléko polotučné pasterované');
-- Ano, cena je za 1 kg chleba a 1 l mléka.

-- Spojím data o cenách a mzdách.
-- Prům. cenu zaokrouhlím -> vizuálně příjemnější.
-- Přidám CASE sloupec s počtem litrů mléka / kg chleba,
-- které bylo možné pořídit za průměrnou mzdu a průměrnou cenu v daném roce.
-- Množství zaokrouhlím na nejbližší nižší celé číslo.
SELECT 
	ceny.rok AS rok,
	ceny.nazev_podkategorie AS potravina,
	ROUND(ceny.prum_cena, 2) AS prum_cena,
	mzdy.prum_mzda,
	CASE 
		WHEN ceny.nazev_podkategorie LIKE 'Chléb%' THEN 
			CONCAT('V roce ', ceny.rok, ' bylo možné si za průměrnou mzdu koupit ', FLOOR(mzdy.prum_mzda/ceny.prum_cena), ' kg chleba.')	
		WHEN ceny.nazev_podkategorie LIKE 'Mléko%' THEN
			CONCAT('V roce ', ceny.rok, ' bylo možné si za průměrnou mzdu koupit ', FLOOR(mzdy.prum_mzda/ceny.prum_cena), ' l mléka.')
	END AS mnozstvi_potravin_za_prum_mzdu
FROM 
	(SELECT
		rok,
		ROUND(AVG(prum_hodnota)) AS prum_mzda
	FROM t_ema_tumova_project_SQL_primary_final
	WHERE 
		rok IN (2006, 2018)
		AND kategorie = 'mzda'
	GROUP BY rok)
	AS mzdy
JOIN 
	(SELECT 
		rok,
		nazev_podkategorie,
		prum_hodnota AS prum_cena
	FROM t_ema_tumova_project_SQL_primary_final
	WHERE 
		rok IN (2006, 2018)
		AND kategorie = 'cena'
		AND nazev_podkategorie IN ('Chléb konzumní kmínový', 'Mléko polotučné pasterované'))
	AS ceny
ON mzdy.rok = ceny.rok
;

/*
ODPOVĚĎ NA VÝZKUMNOU OTÁZKU:

Pracujeme-li s průměrnými hodnotami mezd a cen potravin za rok, potom platí:

V roce 2006 (v prvním srovnatelném období) bylo možné si za průměrnou mzdu koupit
1261 kg chleba nebo 1408 l mléka.

V roce 2018 (v posledním srovnatelném období) bylo možné si za průměrnou mzdu koupit
1319 kg chleba nebo 1613 l mléka.

Vycházíme-li pouze z těchto výsledků, zdá se, že ačkoli ceny chleba a mléka s časem stouply,
mzdy mezitím vzrostly tak, že si lidé mohli
v roce 2018 za průměrnou mzdu pořídit více chleba a mléka než v roce 2006.
*/