--sql/04_ctes_windows.sql

/*1. Daily performance: Build a daily CTE (join fact_visits→dim_date) with
daily_visits and daily_spend. Add a running total window.(maybe : partition by or sum / over clause )  Identify top 3 peak
days. (Interpret for Ops staffing.)*/

with daily_performance as ( 
SELECT dd.date_iso, dd.day_name, 									      --We are finding the daily spending and visits
count(DISTINCT fv. visit_id) as daily_visits, 					      -- putting them together and calling it the daily_performance
sum(fp.amount_cents_clean)/100.0 as daily_spending 
from 
fact_visits fv
inner join 																							-- Here we are joining the tables that are being used 
dim_date dd on dd.date_id=fv.date_id
left join 
fact_purchases fp on fv.visit_id = fp.visit_id
group by 
dd.day_name , dd.date_iso), 

 running_total_window as (																					-- what is running_total_window? it helping us keep track
SELECT  date_iso, daily_visits, daily_spending, 												-- of the daily_visits and daily_spending by taking into 
sum(daily_visits) over (order by date_iso) as running_visits,					-- the row above in order to provide a more consise sum on daily summarizes 
sum(daily_spending) over (order by date_iso) as running_spending,
day_name
FROM  
daily_performance ) 

select * 
from running_total_window
order by daily_visits  DESC
LIMIT 3

/*2. RFM & CLV: Define CLV_revenue_proxy = SUM(spend_cents_clean) per guest.
Compute RFM and rank guests by CLV within home_state using a window function.
(Interpret which segments to target.)*/

with CLV_revenue_proxy as (
select fv.guest_id , dg.home_state, sum(fv.spend_cents_clean)       		-- We are looking for the total spend per guest. SUM(spend_cents_clean) per guest
from fact_visits fv																							
inner join dim_guest dg on fv.guest_id =dg.guest_id 
group by fv.guest_id ,dg.home_state),

rfm as (
SELECT fv.guest_id,  dg.home_state,SUM(fv.spend_cents_clean) as monetary, COUNT(fv.visit_date) as frequency,MAX(fv.visit_date) as recency
FROM fact_visits fv
inner join dim_guest dg on fv.guest_id = dg.guest_id						---- finding the RFM ( Recency , Monetary, Frequency) 
group by  fv.guest_id, dg.home_state
)

SELECT guest_id,home_state,monetary,frequency, recency,
 RANK() over (PARTITION BY home_state 
order by monetary, frequency , recency ) 						-- we are ranking each of the guest by each of the RFM columns ( reveune , frequency , recency) 
as rank_guest																				-- revolving around how much they spend  and the home state they are from. 
from rfm
ORDER BY home_state, rank_guest;



/*3. Behavior change: Using LAG(spend_cents_clean) per guest (ordered by visit
date), compute delta vs. prior visit. What share increased?(<-- find the percentage of visits that increased)  (Interpret what factors
correlate with increases—ticket type, day, party size.)*/

with priorvisits as (
Select fv.guest_id ,fv.visit_date , fv.spend_cents_clean ,
lag(fv.spend_cents_clean, 1 ) over ( 												-- The Lag function is being wrapped around the column 'spend_cents_clean' in order to 
PARTITION by guest_id																		-- to print out the time line of all the previous payments
order by fv.visit_date) as previous_payments 
from fact_visits fv ),

computedelta as (
SELECT fv.guest_id,fv.visit_date,
fv.spend_cents_clean - lag(fv.spend_cents_clean,1) over (
PARTITION by guest_id																		-- this shows the very current payments that are being added to the guest history. 
order by fv.visit_date) as current_payment_differences 		-- we would use the previous dates adn subject from what ever is being spent on not to view
from fact_visits fv ) 																			-- how much guests make within the park .

/*flag*/ 

increase as ( 
Select fv.guest_id, fv.visit_date,fv.spend_cents_clean,
Case 
	when fv.spend_cents_clean > lag (fv.spend_cents_clean, 1 ,0) over 
	(PARTITION by fv.guest_id 
	order by fv.visit_date)						--- this shows us the current status of spending that the guest has done . 
	then 1 else 0											--- If they spend more then 1 and if they spend less,  it sates 0
end as increase_flag 
from fact_visits fv )
	select *
	from fact_visits
	

/*4. Ticket switching: Using FIRST_VALUE(ticket_type_name) per guest, flag if they
later switched. (Interpret implications for pricing/packaging.)*/

with ticket_switching as (SELECT fv.guest_id,dt.ticket_type_name,
first_value(dt.ticket_type_name)over (
PARTITION by fv.guest_id												-- if we run this subsquary sepeartly starting from select to the inner join without the parathese it 
order by fv.visit_date)														-- shows the tickets that have been switched (name of ticket) 
 as ticket_switching 
 from fact_visits fv
 inner join dim_ticket dt on fv.ticket_type_id=dt.ticket_type_id )
 
 
 SELECT 
 guest_id,
 CASE when count ( DISTINCT ticket_type_name )> 1 then 1 else 0				-- 1 represents the fact that the guest has switched there tickets , 0 means that the guest 
 end as switching_flag 																										-- stayed with the same ticket 
 from ticket_switching
 group by guest_id
 


-- ( Make sure to answer in AWES form the questions provided )