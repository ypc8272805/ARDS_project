CREATE TABLE po2oneday AS WITH pvt AS (
         SELECT ie.subject_id,
            ie.hadm_id,
            ie.icustay_id,
                CASE
                    WHEN (le.itemid = 50815) THEN 'O2FLOW'::text
                    WHEN (le.itemid = 50816) THEN 'FIO2'::text
                    WHEN (le.itemid = 50821) THEN 'PO2'::text
                    ELSE NULL::text
                END AS label,
            le.charttime,
            le.value,
                CASE
                    WHEN (le.valuenum <= (0)::double precision) THEN NULL::double precision
                    WHEN ((le.itemid = 50815) AND (le.valuenum > (70)::double precision)) THEN NULL::double precision
                    WHEN ((le.itemid = 50821) AND (le.valuenum > (800)::double precision)) THEN NULL::double precision
                    WHEN ((le.itemid = 50816) AND (le.valuenum > (100)::double precision) AND (le.valuenum < (21)::double precision)) THEN NULL::double precision
                    ELSE le.valuenum
                END AS valuenum
           FROM (mimiciii.icustays ie
             LEFT JOIN mimiciii.labevents le ON (((le.subject_id = ie.subject_id) AND (le.hadm_id = ie.hadm_id) AND ((le.charttime >= (ie.intime - '06:00:00'::interval hour)) AND (le.charttime <= (ie.intime + '1 days'::interval day))) AND (le.itemid = ANY (ARRAY[50815, 50816, 50821])))))
        )
 SELECT pvt.subject_id,
    pvt.hadm_id,
    pvt.icustay_id,
    pvt.charttime,
    max(
        CASE
            WHEN (pvt.label = 'O2FLOW'::text) THEN pvt.valuenum
            ELSE NULL::double precision
        END) AS o2flow,
    max(
        CASE
            WHEN (pvt.label = 'FIO2'::text) THEN pvt.valuenum
            ELSE NULL::double precision
        END) AS fio2,
    max(
        CASE
            WHEN (pvt.label = 'PO2'::text) THEN pvt.valuenum
            ELSE NULL::double precision
        END) AS po2
   FROM pvt
  GROUP BY pvt.subject_id, pvt.hadm_id, pvt.icustay_id, pvt.charttime
  ORDER BY pvt.subject_id, pvt.hadm_id, pvt.icustay_id, pvt.charttime;
