WITH churn_monthly AS (
WITH approval_cohort AS 
(SELECT
     DISTINCT
     created_date::date as approval_cohort,
     revenue.user_id as user_id
FROM revenue 
     left join rev_table on rev_table.user_id = revenue.user_id
WHERE
created_date >= '2021-01-01')
(SELECT current_month as cohort,
(churn_rate) 
FROM
     (SELECT
          date_trunc('month',current_month) as current_month,
          count(CASE WHEN cust_type='churn' THEN 1  ELSE NULL END)/count(user_id)::float8 AS churn_rate 
     FROM
          (SELECT
               past_month.approval_cohort + interval '1 month' AS current_month,
               past_month.user_id, 
               CASE WHEN this_month.user_id IS NULL THEN 'churn'  ELSE 'retained' 
               END AS cust_type 
          FROM
               approval_cohort past_month 
  	       LEFT JOIN approval_cohort this_month ON
                    this_month.user_id = past_month.user_id
                    AND this_month.approval_cohort=past_month.approval_cohort + interval '1 month'
          )da
     GROUP BY 1)dff 
)
),
arpu as (
SELECT
     Avg(revenue) AS ARPU,
     date_trunc('month',cohort_date) as cohort
     --EXTRACT('YEAR' FROM visit_month)||'-' ||LPAD(EXTRACT('MONTH' FROM visit_month)::text,2, '0') as cohort
FROM
     (SELECT
          rev_table.user_id,
            created_date::date as cohort_date,
          SUM(late_fee/100 + interest/100 + write_off_interest/100 ) AS revenue 
     FROM   rev_table 
     WHERE  created_date >= '2021-01-01' and cardinal = 1
     GROUP BY 1,2) d group by cohort order by cohort asc

)
SELECT churn_monthly.*,arpu.arpu, (arpu.arpu)/churn_rate as LTV FROM churn_monthly
left join arpu on arpu.cohort = churn_monthly.cohort
