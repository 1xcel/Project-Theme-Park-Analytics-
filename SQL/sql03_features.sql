--sql/03_features.sql 

--Stay_minutes: From Entry time - to Exit time 

SELECT
fv.entry_time , fv.exit_time, fv.guest_id, fv.visit_date,
cast((strftime('%s', fv.exit_time) - strftime('%s', fv.entry_time))/60 as INTEGER) as stay_minutes 
from fact_visits fv
order by 
	fv.guest_id DESC

--wait bucket : case on wait_minutes (0-15 ,16-30 , 31- 60 , 61> ) 

SELECT fe.wait_minutes, fe.attraction_id,da.attraction_name,			
Case
	when wait_minutes between 0 and 15 then 'Quick_wait_time'
	when wait_minutes between 16 and 30  then 'Long_wait_time'
	when wait_minutes between 31 and 60 then 'Extreme_wait_time'
	when wait_minutes >= 60 then 'Bad_for_business_wait_time'
	else ' No_ record'
end as wait_bucket
from fact_ride_events fe
inner join dim_attraction da on fe.attraction_id = da.attraction_id
order by  wait_bucket desc 

-- populatarity within each attraction on customers ?

SELECT
da.attraction_name , round(avg(fe.satisfaction_rating ),1) as average_rating, count(fv.guest_id)as amount_of_people_rating
from 
fact_ride_events fe 																			-- The popularity on the attraction for the guest that attended
inner join 																							-- can help ake clear descions on how well an attraction is doing can can cause insights 
	fact_visits fv on fv.visit_id=fe.visit_id									-- such as which rides to keep , which rides to promote , a rankiing on which rides are 
inner join																							-- well and which rides aren't. As well as a closer look at customer satifaction with the filtering of the rides. 
	dim_attraction da on fe.attraction_id = da.attraction_id
group by
	da.attraction_name 

-- populatarity between merch or food items and how much of each made , and was bought. 

Select 
fp.item_name , count(*) as amount_bought , sum(fp. amount_cents_clean)/100.0 as revenue , fp.category
from 
	fact_purchases fp
left join
	fact_visits fv on fp.visit_id = fv.visit_id			-- This feature is added in order to prove insights on the products that 
group by 																		-- the theme park is selling contribute to the parks revenue as well .
	fp.item_name,fp.category
order by 																		-- This helps the business problem because it provides more awareness 
	 category ASC , revenue DESC							-- and insight on why customers might not come back or if the popularity of items 
																						-- can help increaase reveune or be devaluing the entire guest expereince. 
				
				

--(make sure to answer THINKING PROMOTES) .

/*For each feature, add a short comment answering:
“Why would a stakeholder want this?” or “How does this help the business
problem?*/

