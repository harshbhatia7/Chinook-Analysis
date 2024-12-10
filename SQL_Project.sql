use chinook;
-- Objective Questions

-- Question 1. Does any table have missing values or duplicates? If yes how would you handle it?

-- there are no duplicates in the data but there are missing values which can be filled with default values to avoid errors during analysis

update customer 
set fax= 'Not Available'
where fax is null;

update customer 
set postal_code= 'N/A'
where postal_code is null;

update customer 
set company = 'Not Available'
where company is null;

update customer 
set state = 'N/A'
where state is null;

update track 
set composer = 'Not Available'
where composer is null;


-- Question 2. Find the top-selling tracks and top artist in the USA and identify their most famous genres.

-- Top 10 tracks in USA

select t.name as Track_Name,a.name as artist_name, 
g.name as Genre_name ,sum(il.quantity) as Total_sales 
from invoice_line il 
inner join invoice i 
on il.invoice_id = i.invoice_id
inner join track t  
on il.track_id = t.track_id 
inner join customer c
on i.customer_id = c.customer_id
inner join album al
on t.album_id = al.album_id
inner join artist a on al.artist_id = a.artist_id
inner join genre g on t.genre_id = g.genre_id
where country= 'USA'
group by t.name, a.name, g.name
order by Total_sales desc 
limit 10;

-- Top 10 genres in USA

select g.name as Top_Genres
from track t
left join invoice_line il on il.track_id = t.track_id
left join invoice i on i.invoice_id = il.invoice_id
left join genre g on t.genre_id = g.genre_id
where i.billing_country = 'USA'
group by g.name
order by sum(il.quantity) desc
limit 10;

-- Question 3. What is the customer demographic breakdown (age, gender, location) of Chinook's customer base?

select * from customer;

select distinct(country)
from customer;

select count(distinct(country)) as country_count
from customer;

select country, count(*) as customer_count
from customer
group by country
order by customer_count desc
limit 10;

-- Question 4. Calculate the total revenue and number of invoices for each country, state, and city.

select * from invoice;

select billing_country as country, billing_city as city, billing_state as state, 
count(invoice_id) as invoice_count, sum(total) as total_revenue 
from invoice
group by billing_country, billing_city, billing_state 
order by count(invoice_id) desc, sum(total) desc;

-- Question 5. Find the top 5 customers by total revenue in each country.

select * from customer;

with cte as
(select customer_id, sum(total) as total_revenue
from invoice
group by customer_id),

ranked_customers as 
(select c.first_name, c.last_name, cte.total_revenue,
dense_rank() over(partition by c.country order by cte.total_revenue desc) as ranking
from cte
left join customer c 
on cte.customer_id = c.customer_id)

select first_name, last_name, total_revenue, ranking
from ranked_customers 
where ranking <=5
order by ranking asc;

-- Question 6. Identify the top-selling track for each customer

select * from customer;

with cte as 
(select c.customer_id, c.first_name, c.last_name, t.name as track_name, sum(i.total) as total_revenue
from customer c
inner join invoice i
on c.customer_id = i.customer_id
inner join invoice_line il 
on i.invoice_id = il.invoice_id
inner join track t 
on il.track_id = t.track_id
group by c.customer_id, c.first_name, c.last_name, t.name),

ranked_customer as 
(select customer_id, first_name, last_name, track_name, total_revenue,
row_number() over(partition by customer_id order by total_revenue desc) as ranking
from cte 
order by total_revenue desc)

select customer_id, first_name, last_name, track_name as top_track
from ranked_customer
where ranking = 1
order by customer_id asc;

-- Question 7. Are there any patterns or trends in customer purchasing behavior (e.g., frequency of purchases, preferred payment methods, average order value)?

select * from invoice;

select count(invoice_id) as invoice_count, 
date_format(invoice_date,'%Y-%m') as date, 
avg(total) as monthly_avg_order_value
from invoice
group by date_format(invoice_date,'%Y-%m')
order by date_format(invoice_date,'%Y-%m');

-- Question 8. What is the customer churn rate?

select * from invoice;

with last_purchase as 
(select c.customer_id, max(i.invoice_date) as last_purchase_date
from customer c
inner join invoice i 
on c.customer_id = i.customer_id
group by c.customer_id
),

total_customer_count as 
(select count(distinct customer_id) AS total_customers
from customer
),

ChurnedCustomers as 
(select count(distinct customer_id) as churned_customers
from last_purchase
where last_purchase_date < date_sub('2020-12-31', interval 6 month)
)
select t.total_customers, c.churned_customers,
round((c.churned_customers / t.total_customers) * 100,2) as churned_percentage
from total_customer_count t, ChurnedCustomers c;

-- Question 9. Calculate the percentage of total sales contributed by each genre in the USA and identify the best-selling genres and artists.
select * from invoice_line;
-- percentage of total sales contributed by each genre

select g.name as Genre, sum(il.quantity) as total_sales,
round((sum(il.quantity) * 100.0 / (select sum(il2.quantity)
from invoice_line il2
inner join invoice i2 
on il2.invoice_id = i2.invoice_id
where i2.billing_country = 'USA')),2) as PercentageOfTotalSales
from invoice_line il
inner join track t 
on il.track_id = t.track_id
inner join genre g 
on t.genre_id = g.genre_id
inner join invoice i 
on il.invoice_id = i.invoice_id
where i.billing_country = 'USA'
group by g.name
order by total_sales desc;

-- best-selling artists and genre in USA:
with cte as 
(select g.name as Genre, ar.name as Artist, 
sum(il.quantity) as total_sales
from invoice_line il 
inner join track t 
on il.track_id = t.track_id 
inner join genre g 
on t.genre_id = g.genre_id 
inner join album al 
on t.album_id = al.album_id 
inner join artist ar 
on al.artist_id = ar.artist_id 
inner join invoice i 
on il.invoice_id = i.invoice_id 
where i.billing_country = 'USA' 
group by g.name, ar.name)

SELECT Artist, Genre, total_sales 
FROM cte 
ORDER BY total_sales DESC;

-- Question 10. Find customers who have purchased tracks from at least 3 different genres.

select * from invoice;

select c.customer_id, c.first_name, c.last_name, 
count(distinct g.genre_id) as genre_count
FROM customer c
inner join invoice i 
on c.customer_id = i.customer_id
inner join invoice_line il 
on i.invoice_id = il.invoice_id
inner join track t 
on il.track_id = t.track_id
inner join genre g 
on t.genre_id = g.genre_id
group by c.customer_id
having genre_count >= 3
order by c.customer_id asc;

-- Question 11. Rank genres based on their sales performance in the USA.

select * from invoice_line;

select g.name as Genre, sum(il.quantity) as total_sales,
rank() over (ORDER BY sum(il.quantity) DESC) as Ranking
from invoice_line il
inner join track t on il.track_id = t.track_id
inner join genre g on t.genre_id = g.genre_id
inner join invoice i on il.invoice_id = i.invoice_id
where i.billing_country = 'USA'
group by g.name
order by Ranking;

-- Question 12. Identify customers who have not made a purchase in the last 3 months.
select * from invoice;

select c.first_name, c.last_name
from customer c
inner join invoice i 
on c.customer_id = i.customer_id
group by c.first_name, c.last_name
having max(i.invoice_date) < DATE_SUB('2020-12-31', interval 3 month); 

-----------------------------------------------------------------------
-----------------------------------------------------------------------

-- Subjective Questions:

-- Question 1. Recommend the three albums from the new record label that should be prioritised.

select * from genre;

with cte as 
(select a.album_id, a.title as album_title,
SUM(i.total) as total_revenue
from album a
inner join track t 
on t.album_id = a.album_id
inner join invoice_line il 
on il.track_id = t.track_id
inner join invoice i 
on i.invoice_id = il.invoice_id
where t.genre_id = 1 
GROUP BY a.album_id
ORDER BY total_revenue DESC)
select album_id,album_title
from cte
limit 3;

-- Question 2. Determine the top-selling genres in countries other than the USA and identify any commonalities or differences.

with cte as 
(select g.name as Genre
from track t
inner join invoice_line il 
on il.track_id = t.track_id
inner join invoice i 
on i.invoice_id = il.invoice_id
inner join genre g 
on t.genre_id = g.genre_id
where i.billing_country != 'USA'
group by g.name
order by sum(il.quantity) desc
limit 10)

select Genre from cte;

-- Question 3. Customer Purchasing Behavior Analysis: How do the purchasing habits (frequency, basket size, spending amount) of long-term customers differ from those of new customers? What insights can these patterns provide about customer loyalty and retention strategies?
 
select * from invoice;

with cte as
(select i.customer_id, max(invoice_date) as last_purchase_date, 
min(invoice_date) as first_purchase_date,
sum(total) as total_spent, 
sum(quantity) as items_bought, 
count(i.customer_id) as frequency,
abs(timestampdiff(day, max(invoice_date), min(invoice_date))) as customer_since_days
from invoice i
left join invoice_line il on il.invoice_id = i.invoice_id
left join customer c on c.customer_id = i.customer_id
group by i.customer_id),

avg_days AS 
(select avg(customer_since_days) as average_days 
from cte),

tenure as
(SELECT total_spent, items_bought, frequency,
case
when customer_since_days> (SELECT average_days FROM avg_days)
then 'Long-Term Customer'
else 'Short-Term Customer' 
end Customer_Type
from cte)

select Customer_Type, sum(total_spent) as Total_money_spent,
sum(items_bought) as Total_items_bought,
count(frequency) as Customer_count 
from tenure 
group by Customer_Type;

-- Question 4. Product Affinity Analysis: Which music genres, artists, or albums are frequently purchased together by customers? How can this information guide product recommendations and cross-selling initiatives?

with cte as 
(select il.invoice_id, il.track_id, t.album_id, t.genre_id, a.title as album_title,
g.name as genre_name, ar.name as artist_name, i.customer_id
from invoice_line il
inner join track t on il.track_id = t.track_id
inner join album a on t.album_id = a.album_id
inner join genre g on t.genre_id = g.genre_id
inner join artist ar on a.artist_id = ar.artist_id
inner join invoice i on il.invoice_id = i.invoice_id)

select c.genre_name as Genre1, c.artist_name as Artist1,
c.album_title as Album1,ct.genre_name as Genre2,
ct.artist_name as Artist2, ct.album_title as Album2, COUNT(*) as Frequency
from cte c
inner join cte ct
on c.customer_id = ct.customer_id 
and c.track_id < ct.track_id
and (c.genre_name != ct.genre_name or c.artist_name != ct.artist_name or c.album_title != ct.album_title)
group by c.genre_name, c.artist_name, c.album_title, ct.genre_name, ct.artist_name, ct.album_title
order by frequency desc
limit 10;

-- Question 5. Regional Market Analysis: Do customer purchasing behaviors and churn rates vary across different geographic regions or store locations? How might these correlate with local demographic or economic factors?

with cte as 
(select c.customer_id, c.country, 
min(i.invoice_date) as first_purchase_date, 
max(i.invoice_date) as last_purchase_date, 
datediff(max(i.invoice_date), min(i.invoice_date)) as tenure, 
datediff('2020-12-31', max(i.invoice_date)) as days_since_last_purchase 
from customer c 
inner join invoice i 
ON c.customer_id = i.customer_id 
group by c.customer_id, c.country), 

customer_classification as 
(select customer_id, country, tenure, days_since_last_purchase, 
case  
when year(first_purchase_date) = 2020 
then 'New Customer' else 'Long-term Customer' 
end as customer_type, 
case 
when last_purchase_date < DATE_SUB('2020-12-31', interval 6 month) then 'Churned Customer' 
else 'Active Customer' 
end as customer_status 
from cte)
 
select c.country as Country, 
count(distinct c.customer_id) as Customer_count, 
sum(i.total) as TotalSales, 
round(avg(i.total),2) as Average_order_value, 
count(distinct case when cc.customer_type = 'Long-term Customer' then c.customer_id end) as Existing_term_customers, 
count(distinct case when cc.customer_type = 'New Customer' then c.customer_id end) as New_customers, 
count(distinct case when cc.customer_status = 'Churned Customer' then c.customer_id end) as Churned_customers 
from customer c 
inner join invoice i 
on c.customer_id = i.customer_id 
inner join customer_classification cc 
on c.customer_id = cc.customer_id 
group by c.country 
order by TotalSales desc;

-- Question 6.Customer Risk Profiling: Based on customer profiles (age, gender, location, purchase history), which customer segments are more likely to churn or pose a higher risk of reduced spending? What factors contribute to this risk?

select c.customer_id, first_name, c.last_name, country,
count(i.invoice_id) as Purchase_count,
sum(i.total) as Total_money_spent,
datediff('2020-12-31',max(i.invoice_date)) as Day_count_since_last_purchase,
case 
when DATEDIFF('2020-12-31', MAX(i.invoice_date)) > 180 then 'High'
when DATEDIFF('2020-12-31', MAX(i.invoice_date)) between 90 and 180 then 'Medium'
else 'Low'
end AS Risk_level
from customer c
inner join invoice i
ON c.customer_id = i.customer_id
group by c.customer_id, c.first_name, c.last_name, c.country
order by Total_money_spent desc;

-- Question 7.Customer Lifetime Value Modelling: How can you leverage customer data (tenure, purchase history, engagement) to predict the lifetime value of different customer segments? This could inform targeted marketing and loyalty program strategies. Can you observe any common characteristics or purchase patterns among customers who have stopped purchasing?

with cte as ( 
select c.customer_id, c.first_name, c.last_name, 
min(i.invoice_date) as first_purchase_date, 
count(distinct i.invoice_id) as num_orders, 
sum(il.unit_price * il.quantity) as total_spending, 
datediff('2020-12-31', min(i.invoice_date)) as customer_tenure_days,
max(i.invoice_date) as last_purchase_date
from customer c 
left join invoice i on c.customer_id = i.customer_id 
left join invoice_line il on i.invoice_id = il.invoice_id 
group by c.customer_id 
),
customer_status as 
(select customer_id,
case 
when max(i.invoice_date) < date_sub('2020-12-31', interval 6 month) then 'Churned Customer'
else 'Active Customer'
end as purchase_status
from invoice i
group by customer_id
),
clv_status AS 
(select c.customer_id, c.first_name, c.last_name, c.first_purchase_date, c.num_orders, 
c.total_spending, c.customer_tenure_days, c.last_purchase_date, cs.purchase_status
from cte c
left join customer_status cs 
ON c.customer_id = cs.customer_id
)
select 
CASE 
when customer_tenure_days < 365 then 'New Customer' 
when customer_tenure_days >= 365 and customer_tenure_days < 1095 then 'Existing Customer' 
else 'High-Value Customer' 
END AS Customer_Type, 
count(*) as Customer_count, 
round(avg(total_spending), 2) AS Avg_money_spent, 
round(avg(num_orders), 2) AS avg_orders,
sum(case when purchase_status = 'Churned Customer' then 1 else 0 end) as Churned_customers,
round(avg(case when purchase_status = 'Churned Customer' then total_spending else null end), 2) as avg_spending_churned_customers
from clv_status
GROUP BY Customer_Type
ORDER BY Avg_money_spent DESC;

-- Question 8. If data on promotional campaigns (discounts, events, email marketing) is available, how could you measure their impact on customer acquisition, retention, and overall sales?
-- word document

-- Question 9.	How would you approach this problem, if the objective and subjective questions weren't given? 
-- word document

-- Question 10. How can you alter the "Albums" table to add a new column named "ReleaseYear" of type INTEGER to store the release year of each album?

alter table Album add ReleaseYear int;
select * from Album;

-- Question 11. Chinook is interested in understanding the purchasing behavior of customers based on their geographical location. They want to know the average total amount spent by customers from each country, along with the number of customers and the average number of tracks purchased per customer. Write an SQL query to provide this information.

with cte as
(select invoice_id, count(track_id) as track_count
from invoice_line
group by invoice_id)

select c.country as Country, 
count(distinct c.customer_id) as Customer_count, 
sum(i.total) as Total_amount_spent, 
round(avg(i.total),2) as Avg_amount_spent,
round(avg(cte.track_count),0) as Avg_tracks_purchased
from customer c
inner join invoice i 
on c.customer_id = i.customer_id
inner join cte 
on cte.invoice_id = i.invoice_id
GROUP BY c.country
order by total_amount_spent desc;
