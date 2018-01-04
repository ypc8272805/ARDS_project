CREATE TABLE pf_new AS
 WITH stg_fio2 AS (
         SELECT chartevents.subject_id,
            chartevents.hadm_id,
            chartevents.icustay_id,
            chartevents.charttime,
            max(
                CASE
                    WHEN (chartevents.itemid = 223835) THEN
                    CASE
                        WHEN ((chartevents.valuenum > (0)::double precision) AND (chartevents.valuenum <= (1)::double precision)) THEN (chartevents.valuenum * (100)::double precision)
                        WHEN ((chartevents.valuenum > (1)::double precision) AND (chartevents.valuenum < (21)::double precision)) THEN NULL::double precision
                        WHEN ((chartevents.valuenum >= (21)::double precision) AND (chartevents.valuenum <= (100)::double precision)) THEN chartevents.valuenum
                        ELSE NULL::double precision
                    END
                    WHEN (chartevents.itemid = ANY (ARRAY[3420, 3422])) THEN chartevents.valuenum
                    WHEN ((chartevents.itemid = 190) AND (chartevents.valuenum > (0.20)::double precision) AND (chartevents.valuenum < (1)::double precision)) THEN (chartevents.valuenum * (100)::double precision)
                    ELSE NULL::double precision
                END) AS fio2_chartevents
           FROM mimiciii.chartevents
          WHERE ((chartevents.itemid = ANY (ARRAY[3420, 190, 223835, 3422])) AND (chartevents.error IS DISTINCT FROM 1))
          GROUP BY chartevents.subject_id, chartevents.hadm_id, chartevents.icustay_id, chartevents.charttime
        ), stg1 AS (
         SELECT po2.subject_id,
            po2.hadm_id,
            po2.icustay_id,
            po2.charttime,
            po2.o2flow,
            po2.fio2,
            po2.po2,
            fio2.fio2_chartevents,
            row_number() OVER (PARTITION BY po2.icustay_id, po2.charttime ORDER BY fio2.charttime DESC) AS lastrowfio2
           FROM (mimiciii.po2oneday po2
             LEFT JOIN stg_fio2 fio2 ON (((po2.icustay_id = fio2.icustay_id) AND ((fio2.charttime >= (po2.charttime - '04:00:00'::interval hour)) AND (fio2.charttime <= po2.charttime)))))
        ), stg2 AS (
         SELECT stg1.subject_id,
            stg1.hadm_id,
            stg1.icustay_id,
            stg1.charttime,
            stg1.o2flow,
            stg1.fio2,
            stg1.po2,
            stg1.fio2_chartevents,
            stg1.lastrowfio2,
                CASE
                    WHEN ((stg1.po2 IS NOT NULL) AND (COALESCE(stg1.fio2, stg1.fio2_chartevents) IS NOT NULL)) THEN (((100)::double precision * stg1.po2) / COALESCE(stg1.fio2, stg1.fio2_chartevents))
                    ELSE NULL::double precision
                END AS pf
           FROM stg1
          WHERE (stg1.lastrowfio2 = 1)
          ORDER BY stg1.icustay_id, stg1.charttime
        ), stg3 AS (
         SELECT stg2.subject_id,
            stg2.hadm_id,
            stg2.icustay_id,
            avg(stg2.pf) AS avgpf
           FROM stg2
          GROUP BY stg2.subject_id, stg2.hadm_id, stg2.icustay_id
        )
 SELECT stg3.subject_id,
    stg3.hadm_id,
    stg3.icustay_id,
    stg3.avgpf,
        CASE
            WHEN ((stg3.avgpf > (300)::double precision) OR (stg3.avgpf IS NULL)) THEN 1
            ELSE 0
        END AS exclusion_pf
   FROM stg3;
