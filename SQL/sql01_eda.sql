--sql/01_eda.sql 

--Q1. Date range of visit_date; number of distinct dates; visits per date (use GROUP BY + ORDER BY).

SELECT
count(fv. visit_date) as amount_visited , max(fv.visit_date) as end_date, min(fv.visit_date) as start_date, count(DISTINCT dd.date_iso) as distinct_dates
from 
	fact_visits fv
inner join 
	dim_date dd on dd.date_id = fv.date_id
Group by 
	dd.date_iso
Order by 
end_date , start_date 

/*The columns that are selected are used in order to correctly categorize and structure the data that is being 
	extracted in order to view the data ranges of visits. */
	




--Q2. Visits by ticket_type_name (join to dim_ticket), ordered by most to least.

SELECT
count(fv.guest_id)as total_visits, fv.ticket_type_id,dt.ticket_type_name
From
	fact_visits fv
INNER JOIN
	dim_ticket dt on fv.ticket_type_id =dt.ticket_type_id
Group by 
	dt.ticket_type_name , fv.ticket_type_id
order by 
	total_visits DESC

-- 

--Q3. Distribution of wait_minutes (include NULL count separately).

SELECT 
count(fe.wait_minutes) as total_counts ,avg(fe.wait_minutes) as average_wait , sum(fe.wait_minutes is null) as not_answered,
max(fe.wait_minutes) as maximum_wait, min(fe.wait_minutes) as minimum_wait , fe.attraction_id, da.attraction_name
From 
	fact_ride_events fe
Inner join 
	dim_attraction da on fe.attraction_id = da.attraction_id
group by 
	fe.attraction_id , da.attraction_name
	
/*when it comes to the word "Distribution" , think of every way possible . i used the function such as avg (), sum(), max(), min()and count()
to help me verify the differences wihtin wait_minutes through out each of the attractioon rides */
-- we inner join in order to also include the sum amounts of null counts within findig the distributition of wait_mintues .
-- we are then grouping by the attraction id , and attraction name to conncise the information that is being given for just the rides .
	
--Q4. Average satisfaction_rating by attraction_name and by category.

SELECT
round(avg(fe.satisfaction_rating),1) as Average_satified_rating, fe.attraction_id , da.attraction_name , da.category
from 
	fact_ride_events fe
inner join 
	dim_attraction da on fe.attraction_id = da.attraction_id
Group by 
	da.attraction_name , da.category,fe.attraction_id
order by 
	fe.attraction_id 
-- we will order this by the attraction id , attraction name , and the category the attraction falls under.
/*we are looking for information within different tables so we will join on just one of the similar column that they share 
which will lead to the information being selected to be the output. */


--Q5. Duplicates check: exact duplicate fact_ride_events rows (match on all columns) with counts.

SELECT * , count(*) as duplicates 
from 
	fact_ride_events fe
Group by 
	fe.visit_id , fe.attraction_id, fe.photo_purchase,fe.satisfaction_rating,fe.ride_time,fe.wait_minutes
Having 
	count(*)>1 
	
--In order to view all duplicates within the entire fact_ride_events table ,(*) is used .
/* you will group by all the columns within the table EXCEPT for the unique column within the table.( similar to rowID) 
	including this unique column would confuse the machine into having no output due to the fact that their can not be any duplicates 
	within a unique column*/
--i then did >1, in order to give the condion that if there are an rows that are similar (> more then 1) this will be counted as duplicates. 

--6. Null audit for key columns you care about (report counts).

SELECT 'fact_ride_events.wait_minutes' as table_column_name , sum(case when wait_minutes is null then 1 else 0 end ) as Null_audit FROM fact_ride_events
UNION ALL 
SELECT 'fact_visits.promotion_code', sum(case when promotion_code is null then 1 else 0 end ) FROM fact_visits											
UNION ALL
SELECT 'fact_visits.spend_cents_clean',  sum ( case when spend_cents_clean is null then 1 else 0 end ) FROM fact_visits
UNION ALL 
SELECT 'fact_purchases.amount_cents_clean', sum(case when amount_cents_clean is null then 1 else 0 end ) FROM fact_purchases
	
	--  i am selecting the column within the table , within the ' ' .
	--	i am then using the sum function over  the case in order to give me the total amount of nulls within the column stated 
/*	the case function is able to return a specfic output based on the condiotions that are being given . For instance within the column 
		the machine looks through each row and detects if there is a value or not. if yes then the machine reads it as 0 , if their is no value 
		the machine reads it as 1 and is then added to the next empty/null value , through the help of the sum function. sum(case 'conditions' ) . */
	
--Q7. Average party_size by day of week (dim_date.day_name).

SELECT
	round(avg(fv.party_size),0)as party_size , dd.day_name , dd.date_iso 
from 
	fact_visits fv 
INNER JOIN
	dim_date dd on fv.visit_date = dd.date_iso
Group by 
	dd.day_name
Order by 
	party_size DESC
	
/*you will need to join the tables together based on the column that is shared within the tables . Even if they have 
	different column names as long as they are structured similary , this will work*/
/*you will then group by the day name and order it by the party size, this will help display the informaiton in 
	a much readable format. */
--i add the function Round() to the nearest 0 (whole number) , in order for it to be more comprehensiable for the party_size. 




