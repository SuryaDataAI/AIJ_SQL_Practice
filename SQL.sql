CREATE TABLE sales_data (
  ordernumber       integer,
  quantityordered   integer,
  priceeach         numeric(12,2),
  orderlinenumber   integer,
  sales             numeric(14,2),
  orderdate_text    text,               -- import raw, then convert to timestamp
  status            text,
  qtr_id            integer,
  month_id          integer,
  year_id           integer,
  productline       text,
  msrp              numeric(12,0),
  productcode       text,
  customername      text,
  phone             text,
  addressline1      text,
  addressline2      text,
  city              text,
  state             text,
  postalcode        text,
  country           text,
  territory         text,
  contactlastname   text,
  contactfirstname  text,
  dealsize          text
);



SELECT count(*) AS row_count FROM sales_data;


---database and table created now practice

--1.show 10 sample rows

select * from sales_data limit 10;

--2.select ordernumber cutomer name and city

select ordernumber , customername  , city from sales_data;

--3. get order where quantity > 50

select * from sales_data where quantityordered > 50;

--4. find order status when shipped.

select * from sales_data where lower(status) = 'shipped';

--5.show distinct prduct lines

select distinct productline from sales_data order by productline;

--6.count sistinct customers

select count(distinct customername) as unique_customers from sales_data;

--7 . top 20 order by sales.

SELECT ordernumber, customername, sales
FROM sales_data
ORDER BY sales DESC
LIMIT 20;

--8 . ordrrs in the year 2004

select * from sales_data where year_id = 2004;

--9 . orders in march

select * from sales_data where month_id = 3;

--10 . orders where postalcode is null.

select * from sales_data where postalcode is null or trim(postalcode) = '';


---basics done(now aggreagations and groupby)

--11 total sales across all orders

select sum(sales) as total_sales from sales_data;

--12 . total sales in year
select year_id , sum(sales) as sales_per_year
from sales_data
group by year_id
order by year_id;

--13 . average proice per productline

select productline, AVG(priceeach) as avg_price
from sales_data
group by productline
order by avg_price desc;

--14 . total quantity ordered by prodcutcode.

select productcode , sum(quantityordered) as total_qty
from sales_data
group by productcode
order by total_qty desc
limit 20;

--15 . number of orders per status
select status , count(*) as cnt
from sales_data
group by status
order by cnt desc;

--16 . total sales and avg sales per customer
select customername , sum(sales) as total_sales , avg(sales) as avg_sale
from sales_data
group by customername
order by total_sales desc
limit 20;

--17 .total sales by county and productline

select country , productline , sum(sales) as sales_sum
from sales_data
group by country , productline
order by country , sales_sum desc;

--18 . count the orders per month

select month_id  , count(*) as orders
from sales_data
group by month_id
order by month_id;

--19 . top 5 cities by total sales.

select city , sum(sales) as total_sales
from sales_data
group by city
order by total_sales desc
limit 5;

--20 . product lines with avg msrp greather than 1000.

select productline , avg(msrp) as avg_msrp
from sales_data
group by productline
having avg(msrp) > 1000;


---joins and subqueries

--find sutomers where total sales grather than avg sales

with cust_sales AS(select customername , sum(sales) as total_sales
from sales_data
group by customername
)

select cs.customername , cs.total_sales
from cust_sales cs
where cs.total_sales > (select avg(total_sales) from cust_sales)
order by cs.total_sales desc;


--return order where sales > avg sales for that productline.

select s.*
from sales_data s
join(select productline , avg(sales) as avg_sales
from sales_data
group by productline
) pl on s.productline = pl.productline
where s.sales > pl.avg_sales;


--find max sales value and rows

select * from sales_data where sales = (select max(sales) from sales_data);

--show ordered pairs with same customer 

SELECT a.ordernumber AS order_a, b.ordernumber AS order_b, a.customername
FROM sales_data a
JOIN sales_data b ON a.customername = b.customername AND a.ordernumber < b.ordernumber
LIMIT 50;

--find productcode with grates avg quantityordered

select productcode , avg(quantityordered) as avg_qty
from sales_data
group by productcode
order by avg_qty desc
limit 10;

--window functions with adv aggreagations.

--running total sales by orderdate

select ordernumber , sales,
sum(sales) OVER (ORDER BY orderdate ROWS UNBOUNDED PRECEDING) AS running_total
FROM sales_data
order by ordernumber
limit 50;

--rank customer by total_sales

select customername , total_sales , dense_rank() over (order by total_sales desc) as sales_rank
from(select customername , sum(sales) as total_sales
from sales_data
group by customername)t;


--show each orders sales and avg sales per productline

select ordernumber , productline , sales , avg(sales) over(partition by productline) as avg_sales_productline
from sales_data;

--orderline partiton via ordersales
select ordernumber , customername , orderdate , row_number() over (partiton by customername order by orderdate) as rn
from sales_data;

--difference between each row sales adn previous year sales

SELECT ordernumber, orderdate, sales,
       sales - LAG(sales) OVER (ORDER BY orderdate) AS diff_from_prev
FROM sales_data;

--date and time functions

ALTER TABLE sales_data ADD COLUMN orderdate timestamptz;
UPDATE sales_data
SET orderdate = to_timestamp(orderdate_text, 'MM/DD/YYYY HH24:MI');

--orders per year
SELECT EXTRACT(YEAR FROM orderdate)::int AS yr, COUNT(*) AS cnt
FROM sales_data
GROUP BY yr
ORDER BY yr;

--total sales per quater

select qtr_id  , sum(sales) as qtr_sales
from sales_data
group by qtr_id
order by qtr_id;

--find orders in last 30 days

select * from sales_data
where orderdate >= (current_date - interval '30 days');

--find weekday distribution of orders

select to_char(orderdate , 'Day') as weekday , count(*) as cnt
from sales_data
group by weekday
order by cnt desc;

---strings functions and pattern matching

--find cusotmers with A
select * from sales_data where customername ILIKE 'A%';

--cecking ph number of cusotmer for diect contact

SELECT phone, regexp_replace(phone, '^\D*([0-9]{3}).*$', '\1') AS area_code
FROM sales_data
WHERE phone IS NOT NULL LIMIT 50;

--find productcodes that contain substring

select distinct productcode from sales_data where productcode like '%S10%';

--create a full contact name

select contactfirstname || ' '|| contactlastname as contact_fullname , *
from sales_data limit 20;

--ormalize country anme

select upper(country) as country_uc , count(*) as cnt
from sales_data
group by country_uc
order by cnt desc;

--update and delete indexes

--add an index to speed queires
create index idx_sales_productcode on sales_data(productcode);

--set null postcal code

update sales_dataset postalcode = 'UNKNOWN' where postalcode is null;

--delete rows with zeros or negative sales

delete from sales_data where sales <= 0;

--create a view for high valu cusotmers

CREATE OR REPLACE VIEW high_value_customers AS
SELECT customername, SUM(sales) AS total_sales
FROM sales_data
GROUP BY customername
HAVING SUM(sales) > 10000;

--createa materlized view for reporting

CREATE MATERIALIZED VIEW mv_monthly_sales AS
SELECT year_id, month_id, SUM(sales) AS month_sales
FROM sales_data
GROUP BY year_id, month_id;
-- REFRESH MATERIALIZED VIEW mv_monthly_sales;


select * from sales_data;

--checking over month-month overall sales growth

WITH monthly AS (
  SELECT year_id,
         month_id,
         SUM(sales) AS month_sales,
         (year_id * 100 + month_id) AS yearmonth
  FROM sales_data
  GROUP BY year_id, month_id
)
SELECT 
  year_id,
  month_id,
  month_sales,
  LAG(month_sales) OVER (ORDER BY yearmonth) AS prev_month,
  month_sales - LAG(month_sales) OVER (ORDER BY yearmonth) AS diff,
  ROUND(
      100.0 * (month_sales - LAG(month_sales) OVER (ORDER BY yearmonth)) /
      NULLIF(LAG(month_sales) OVER (ORDER BY yearmonth), 0),
      2
  ) AS pct_growth
FROM monthly
ORDER BY yearmonth;


--checking the top selling prodcut code per year

SELECT year_id, productcode, total_sales
FROM (
    SELECT 
        year_id,
        productcode,
        SUM(sales) AS total_sales,
        ROW_NUMBER() OVER (
            PARTITION BY year_id
            ORDER BY SUM(sales) DESC
        ) AS rn
    FROM sales_data
    GROUP BY year_id, productcode
) t
WHERE rn = 1
ORDER BY year_id;

select * from sales_data;


---each and every time we can use this to revise regarding SQL
