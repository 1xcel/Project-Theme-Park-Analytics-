--sql/02_cleaning.sql

-- If you haven't added these yet, run them ONCE (comment out if they already exist)( They exist already)

ALTER TABLE fact_visits ADD COLUMN spend_cents_clean INTEGER;
ALTER TABLE fact_purchases ADD COLUMN amount_cents_clean INTEGER;

-- Visits: compute cleaned once, join by rowid, update when cleaned is non-empty

WITH c AS (
SELECT 
rowid AS rid,

REPLACE(REPLACE(REPLACE(REPLACE(UPPER(COALESCE(total_spend_cents,'')),
'USD',''), '$',''), ',', ''), ' ', '') AS cleaned
FROM fact_visits
)

UPDATE fact_visits
SET spend_cents_clean = CAST((SELECT cleaned FROM c WHERE c.rid = fact_visits.rowid)
AS INTEGER)
WHERE LENGTH((SELECT cleaned FROM c WHERE c.rid = fact_visits.rowid)) > 0;

SELECT CAST( total_spend_cents as decimal(10,2))/100.0 as dollar_spend,             --   convert these columns to dollars
CAST( spend_cents_clean as decimal(10,2))/100.0 as dollar_cents_clean 
from fact_visits
	

-- Purchases: same pattern (WRITE THE SAME CODE ABOVE for the fact_purchases table)

WITH c AS (
SELECT 
rowid AS rid,

REPLACE(REPLACE(REPLACE(REPLACE(UPPER(COALESCE(amount_cents,'')),
'USD',''), '$',''), ',', ''), ' ', '') AS cleaned
FROM fact_purchases
)

UPDATE fact_purchases
SET amount_cents_clean = CAST((SELECT cleaned FROM c WHERE c.rid = fact_purchases.rowid)
AS INTEGER)
WHERE LENGTH((SELECT cleaned FROM c WHERE c.rid = fact_purchases.rowid)) > 0;

SELECT CAST( amount_cents as decimal(10,2))/100.0 as dollar_amount_cents,
CAST( amount_cents_clean as decimal(10,2))/100.0 as dollar_amount_cents_cleaned 	  --   convert these columns to dollars
from fact_purchases


-- B . Exact duplicates: every column in a row matches across rows. Detect with GROUP BY all_columns HAVING COUNT(*)>1.

SELECT * , count(*) as duplicates 
from 
	fact_ride_events fe
Group by 
	fe.visit_id , fe.attraction_id, fe.photo_purchase,fe.satisfaction_rating,fe.ride_time,fe.wait_minutes
Having 
	count(*)>1 
--	
	SELECT * , count(*) as duplicates 
from 
	fact_visits fv
Group by 
	fv.guest_id, fv.ticket_type_id ,fv.visit_date,fv.party_size,fv.spend_cents_clean,fv.promotion_code
Having 
	count(*)>1 
--
SELECT * , count(*) as duplicates 
from 																																						-- when this is runned the duplicates that are being shown aree based on each individual column 
	fact_purchases  fp																														-- for instance the first colum shows 2 duplicates due to their being a silmalier amount cents clean , 
Group by 																																				-- payment_method and product_ category. Even if the purchasse id and visit_id are different. 
	fp.visit_id,fp.category,fp.item_name,fp.payment_method,fp.amount_cents_clean
Having 
	count(*)>1


--C) Validate keys (what it means + an example) “Validate keys” = ensure foreign keys have a matching parent (no orphans). 

--Check orphans like this (do this for all PK/FK combinations across tables):


SELECT  v.guest_id, v.visit_id				--Foreign Key 
FROM fact_visits v
LEFT JOIN dim_guest g ON g.guest_id = v.guest_id
WHERE g.guest_id IS NULL;

Select  fe.visit_id,fe.attraction_id			---Foreign key 
from fact_ride_events fe
left join dim_attraction da on fe.attraction_id=da.attraction_id
where da.attraction_id is NULL

SELECT count(*) as null_amounts  	--- Primary Key
from fact_purchases fp
where fp.purchase_id is null 

SELECT count(*) as null_amounts  	--- Primary Key
from dim_date dd
where dd.date_iso is null 

SELECT count(*) as null_amounts  	--- Primary Key
from dim_guest dg
where dg.email is null 

SELECT count(*) as null_amounts  	--- Primary Key
from dim_attraction da
where da.attraction_id is null

--D) Handling missing values

--● If a field is essential for aggregation (e.g., spend), you might set unusable values to NULL and exclude them in metrics.

select nullif(total_spend_cents , 'n/a') as total_spend_cents 
from fact_visits 

select nullif(spend_cents_clean,  0 ) as total_spend_cents 
from fact_visits 


--● For text normalization (e.g., promotion_code, home_state), TRIM + consistent casing (e.g., UPPER) is enough—don’t guess content.

SELECT DISTINCT  home_state 
from dim_guest

update dim_guest
set home_state = upper(trim(home_state))
where home_state is not null 

SELECT DISTINCT promotion_code
from fact_visits

update fact_visits
set promotion_code = upper(trim(promotion_code))
where promotion_code is not null 

--● For analysis, report how many values were dropped/cleaned before proceeding.

/* the entity of the columns fact_purchases and fact_visits have been standardized with upper and trim text , for easy readability .
That is about 40 - 60 rows . This is also applied to the columns promotion_code and home_state about 10 - 50 columns cleaned for easier readability.
Nothing was dropped due to the size of the database that is being worked on. Values within the fact_visits table that showed n/a  or 0 have been 
changes to NULL specifically spend_cents_clean and total_spend_cents*/




