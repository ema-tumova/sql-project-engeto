-- Q2: Kolik je možné si koupit litrů mléka a kilogramů chleba za první a poslední srovnatelné období
-- v dostupných datech cen a mezd?

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