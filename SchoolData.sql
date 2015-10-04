-- Save the join as a view

CREATE VIEW scoreview AS
SELECT sc13.CCBASIC, scTarget.INSTNM, scTarget.CONTROL, scTarget.Year, 
        scTarget.TUITFTE, scTarget.COSTT4_A, scTarget.TUITIONFEE_IN,
	scTarget.INC_PCT_LO, scTarget.INC_PCT_M1, scTarget.INC_PCT_M2, 
	scTarget.INC_PCT_H1, scTarget.INC_PCT_H2, scTarget.PCTFLOAN,
	scTarget.DEBT_MDN, scTarget.FEMALE_DEBT_MDN, scTarget.MALE_DEBT_MDN,
	scTarget.C150_4, scTarget.mn_earn_wne_p10, scTarget.gt_25k_p10
FROM Scorecard scTarget INNER JOIN Scorecard sc13 ON scTarget.UNITID = sc13.UNITID
-- set target year
WHERE scTarget.Year = 2009
	AND sc13.Year = 2013
	AND scTarget.mn_earn_wne_p10 IS NOT NULL
	AND scTarget.mn_earn_wne_p10 != 'PrivacySuppressed'
	AND sc13.CCBASIC NOT LIKE '%Special%';


-- Community college vs 4-yr college vs master's univ vs doctoral/research univ
-- This can only be done following the join above to grab CCBASIC

.print Community college
SELECT cast(AVG(sc.mn_earn_wne_p10) as integer) as MeanEarning10YrsAfterMatriculation FROM scoreview sc WHERE sc.CCBASIC LIKE '%Associate%';

.print 4-yr college
SELECT cast(AVG(sc.mn_earn_wne_p10) as integer) as MeanEarning10YrsAfterMatriculation FROM scoreview sc WHERE sc.CCBASIC LIKE '%Baccalaureate%';

.print Master's degree granting university
SELECT cast(AVG(sc.mn_earn_wne_p10) as integer) as MeanEarning10YrsAfterMatriculation FROM scoreview sc WHERE sc.CCBASIC LIKE '%Master% Colleges and Universities%';

.print Research Universities
SELECT cast(AVG(sc.mn_earn_wne_p10) as integer) as MeanEarning10YrsAfterMatriculation FROM scoreview sc WHERE sc.CCBASIC LIKE '%Research Universities%';

-- GROUP BY sc.CCBASIC; -- no, this results in too much fragmentation


-- Earnings as a function of school type; this can be grouped by year

.print Private vs public school
SELECT Year, CONTROL as school_type, cast(AVG(mn_earn_wne_p10) as integer) as MeanEarning10YrsAfterMatriculation
FROM Scorecard
WHERE mn_earn_wne_p10 != 'PrivacySuppressed' AND mn_earn_wne_p10 IS NOT NULL
GROUP BY Year, CONTROL
ORDER BY Year, CONTROL; 


-- Quantitative categories: change category by commenting/uncommenting relevant lines below; change binsize as appropriate
-- can do this only for years for which data is available

.print Mean earning vs quantitative categories
-- SELECT min(sc.DEBT_MDN), max(sc.DEBT_MDN) FROM scoreview sc WHERE sc.DEBT_MDN != 'PrivacySuppressed';

SELECT Year, bin*binsize as CostOfAttendancePerYear, 
	-- round(AVG(gt_25k_p10), 2)
	cast(AVG(mn_earn_wne_p10) as integer) as MeanEarning10YrsAfterMatriculation
FROM(
    SELECT *, quant/binsize as bin
    FROM(	 
        SELECT *, 5000 as binsize,
	       	-- TUITFTE as quant -- net tuition revenue of school per full-time student
	       	COSTT4_A as quant -- total cost of attendance/yr for Title IV aid students
	       	-- TUITIONFEE_IN as quant -- tuition/yr, in-state
	       	-- TUITIONFEE_OUT as quant -- tuition/yr, out-of-state
		-- cast(MALE_DEBT_MDN as integer) as quant -- median debt for male students
		-- cast(FEMALE_DEBT_MDN as integer) as quant -- median debt for female students
		-- cast(DEBT_MDN as integer) as quant -- median debt for all students
	 FROM Scorecard
	 WHERE mn_earn_wne_p10 != 'PrivacySuppressed' AND mn_earn_wne_p10 IS NOT NULL
    )   
)
GROUP BY Year, bin
ORDER BY Year, bin asc;


-- mean earning vs fraction of aided students whose family income is in range $0-30000, for schools with 
-- at least 50% such students
-- SELECT sc.INC_PCT_LO, sc.INC_PCT_M1, sc.INC_PCT_M2, sc.INC_PCT_H1, sc.INC_PCT_H2, sc.mn_earn_wne_p10
/*SELECT sc.INC_PCT_LO, AVG(sc.mn_earn_wne_p10)
FROM Scorecard sc
WHERE sc.INC_PCT_LO > 0.5 AND sc.INC_PCT_LO != 'PrivacySuppressed';*/
