SELECT
	utm_source,
    utm_campaign,
	utm_content,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    ROUND(COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id)*100,2) AS session_to_orders_conv_rt
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at BETWEEN '2014-01-01' AND '2014-02-01'
GROUP BY 
	website_sessions.utm_source,
    website_sessions.utm_campaign,
    website_sessions.utm_content
ORDER BY 
	session_to_orders_conv_rt DESC;
    
------------------------------------------------------------------------------------------------------------------

SELECT 
    MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_session_id ELSE NULL END) AS gsearch_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_session_id ELSE NULL END) AS bsearch_sessions
FROM website_sessions
WHERE created_at BETWEEN '2012-08-22' AND '2012-11-29'
	AND utm_campaign = 'nonbrand'
GROUP BY
	YEAR(created_at),
    WEEK(created_at);
    
------------------------------------------------------------------------------------------------------------------

SELECT 
	utm_source,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions,
    ROUND(COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id)*100,2) AS pct_mobile
FROM website_sessions
WHERE created_at BETWEEN '2012-08-22' AND '2012-11-30'
	AND utm_campaign = 'nonbrand'
    AND utm_source IN ('gsearch', 'bsearch')
GROUP BY 
	utm_source;
    
------------------------------------------------------------------------------------------------------------------

SELECT 
	website_sessions.device_type,
    website_sessions.utm_source,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    ROUND(COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id)*100,2) AS conv_rate
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at BETWEEN '2012-08-22' AND '2012-09-18'
	AND website_sessions.utm_campaign = 'nonbrand'
    AND website_sessions.utm_source IN ('gsearch', 'bsearch')
GROUP BY
	website_sessions.device_type,
    website_sessions.utm_source
;

------------------------------------------------------------------------------------------------------------------

SELECT 
	MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) AS g_dtop_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END) AS b_dtop_sessions,
    ROUND(COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'desktop' THEN website_session_id ELSE NULL END)*100,2) AS b_pct_of_g_dtop,
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) AS g_mob_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END) AS b_mob_sessions,
    ROUND(COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND device_type = 'mobile' THEN website_session_id ELSE NULL END)*100,2) AS b_pct_of_g_mob
FROM website_sessions
WHERE created_at BETWEEN '2012-11-04' AND '2012-12-22'
	AND utm_campaign = 'nonbrand'
GROUP BY 
	yearweek(created_at);
    
------------------------------------------------------------------------------------------------------------------

SELECT
    CASE 
		WHEN http_referer IS NULL THEN 'direct_type_in'
		WHEN http_referer = 'https://www.gsearch.com' AND utm_source IS NULL THEN 'gsearch_organic'
        WHEN http_referer = 'https://www.bsearch.com' AND utm_source IS NULL THEN 'bsearch_organic'
		ELSE 'other'
	END AS link,
    COUNT(distinct website_session_id) AS sessions
FROM 
	website_sessions
WHERE website_session_id between 100000 AND 115000
GROUP BY 1
ORDER BY 2 DESC;

------------------------------------------------------------------------------------------------------------------

SELECT 
	YEAR(created_at) AS yr,
    MONTH(created_at) AS mn,
    COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END) AS 'nonbrand',
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_session_id ELSE NULL END) AS 'brand',
    ROUND(COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END)*100,2) AS brand_pct_of_nonbrand,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_session_id ELSE NULL END) AS direct,
    ROUND(COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END)*100,2) AS direct_pct_of_nonbrand,
    COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_session_id ELSE NULL END) AS organic,
    ROUND(COUNT(CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN utm_campaign = 'nonbrand' THEN website_session_id ELSE NULL END)*100,2) AS organic_pct_of_nonbrand
FROM website_sessions
WHERE created_at < '2012-12-23'
GROUP BY
	YEAR(created_at),
    MONTH(created_at);
    

------------------------------------------------------------------------------------------------------------------

SELECT 
	YEAR(website_sessions.created_at) AS yr,
    MONTH(website_sessions.created_at) AS mo,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE year(website_sessions.created_at) = '2012'
GROUP BY
	YEAR(website_sessions.created_at),
    MONTH(website_sessions.created_at);
    
------------------------------------------------------------------------------------------------------------------


SELECT 
    MIN(DATE(website_sessions.created_at)) AS week_start_date,
    COUNT(DISTINCT website_sessions.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE year(website_sessions.created_at) = '2012'
GROUP BY
	YEAR(website_sessions.created_at),
    WEEK(website_sessions.created_at);


------------------------------------------------------------------------------------------------------------------

SELECT 
	hr AS "Hour", 
    ROUND(AVG(CASE WHEN week_day = 0 THEN sessions ELSE NULL END),1) AS Monday,
    ROUND(AVG(CASE WHEN week_day = 1 THEN sessions ELSE NULL END),1) AS Tuesday,
    ROUND(AVG(CASE WHEN week_day = 2 THEN sessions ELSE NULL END),1) AS Wednesday,
    ROUND(AVG(CASE WHEN week_day = 3 THEN sessions ELSE NULL END),1) AS Thursday,
    ROUND(AVG(CASE WHEN week_day = 4 THEN sessions ELSE NULL END),1) AS Friday,
    ROUND(AVG(CASE WHEN week_day = 5 THEN sessions ELSE NULL END),1) AS Saturday,
    ROUND(AVG(CASE WHEN week_day = 6 THEN sessions ELSE NULL END),1) AS Sunday
FROM (    
	SELECT
		DATE(created_at),
		WEEKDAY(created_at) AS week_day,
		HOUR(created_at) AS hr,
		COUNT(DISTINCT website_session_id) AS sessions
	FROM website_sessions
	WHERE created_at BETWEEN '2012-09-15' AND '2012-11-15'
	GROUP BY 
		DATE(created_at),
		WEEKDAY(created_at),
		hour(created_at)
) AS daily_hourly_sessions
GROUP BY 1;

------------------------------------------------------------------------------------------------------------------

SELECT 
	YEAR(created_at) AS yr,
    MONTH(created_at) AS mo,
    COUNT(DISTINCT order_id) AS number_of_sales,
    SUM(price_usd) AS total_revenue,
    SUM(price_usd - cogs_usd) AS total_margin
FROM orders
WHERE created_at < '2013-01-04'
GROUP BY 1,2;

------------------------------------------------------------------------------------------------------------------

SELECT 
	YEAR(website_sessions.created_at) AS yr, 
    MONTH(website_sessions.created_at) AS mo,
    COUNT(DISTINCT orders.order_id) AS orders,
    ROUND(COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_sessions.website_session_id)*100,2) AS conv_rate,
    ROUND(SUM(orders.price_usd)/COUNT(DISTINCT website_sessions.website_session_id)*100,2) AS revenue_per_session,
    COUNT(DISTINCT CASE WHEN primary_product_id = 1 THEN orders.order_id ELSE NULL END) AS product_one_orders,
    COUNT(DISTINCT CASE WHEN primary_product_id = 2 THEN orders.order_id ELSE NULL END) AS product_two_orders
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at BETWEEN '2012-04-01' AND '2013-04-05'
GROUP BY
	YEAR(website_sessions.created_at), 
    MONTH(website_sessions.created_at);
    
    
------------------------------------------------------------------------------------------------------------------

SELECT 
	website_pageviews.pageview_url,
    COUNT(DISTINCT website_pageviews.website_session_id) AS sessions,
    COUNT(DISTINCT orders.order_id) AS orders,
    ROUND(COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT website_pageviews.website_session_id)*100,2) AS view_product_to_order_rate
FROM website_pageviews
LEFT JOIN orders
ON website_pageviews.website_session_id = orders.website_session_id
WHERE website_pageviews.created_at BETWEEN '2013-02-01' AND '2013-03-01'
	AND website_pageviews.pageview_url IN ('/the-original-mr-fuzzy', '/the-forever-love-bear')
GROUP BY
	website_pageviews.pageview_url;
    
------------------------------------------------------------------------------------------------------------------


/* Assignment_product_pathing_analysis

STEP 1: Find the relevant/ products pageviews with website_session_id
STEP 2: Find the next pageview id that occurs AFTER the product pageview
STEP 3: Find the pageview_url associated with any applicable next pageview id
STEP 4: Summarize the data and analyze the pre vs post periods

*/
CREATE temporary table products_pageviews
SELECT 
	website_session_id,
    website_pageview_id,
    created_at,
    CASE
		WHEN created_at < '2013-01-06' THEN 'A. Pre_Product_2'
        WHEN created_at >= '2013-01-06' THEN 'B. Post_Product_2'
        ELSE 'uh oh... check logic'
	END AS time_period
FROM website_pageviews
WHERE created_at BETWEEN '2012-10-06' AND '2013-04-06'
	AND pageview_url = '/products';
    
    
create temporary table sessions_w_next_pageview_id
SELECT 
	products_pageviews.time_period,
	products_pageviews.website_session_id, 
    MIN(website_pageviews.website_pageview_id) AS next_pageview_url
FROM products_pageviews
LEFT JOIN website_pageviews
ON products_pageviews.website_session_id = website_pageviews.website_session_id
	AND products_pageviews.website_pageview_id < website_pageviews.website_pageview_id
GROUP BY 
	products_pageviews.time_period,
	products_pageviews.website_session_id;
    
CREATE temporary table sessions_w_next_pageurl
SELECT 
	sessions_w_next_pageview_id.time_period,
    sessions_w_next_pageview_id.website_session_id,
    website_pageviews.pageview_url AS next_pageview_url
FROM sessions_w_next_pageview_id
LEFT JOIN website_pageviews
ON sessions_w_next_pageview_id.website_session_id = website_pageviews.website_session_id;

SELECT 
	time_period,
    COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END) AS w_next_pg,
    COUNT(DISTINCT CASE WHEN next_pageview_url IS NOT NULL THEN website_session_id ELSE NULL END)/COUNT(distinct website_session_id) AS pct_w_next_pg,
    COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-original-mr-fuzzy' THEN website_session_id ELSE NULL END)/COUNT(distinct website_session_id) AS pct_to_mrfuzzy,
    COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END) AS to_lovebear,
    COUNT(DISTINCT CASE WHEN next_pageview_url = '/the-forever-love-bear' THEN website_session_id ELSE NULL END)/COUNT(distinct website_session_id) AS pct_to_lovebear
FROM sessions_w_next_pageurl
GROUP BY time_period;


------------------------------------------------------------------------------------------------------------------


CREATE temporary table session_seen_product_pages
SELECT 
	website_session_id,
    website_pageview_id,
	pageview_url AS product_page_seen
FROM website_pageviews
WHERE created_at BETWEEN '2014-01-06' AND '2014-04-10'
AND pageview_url IN ('/the-original-mr-fuzzy','/the-forever-love-bear');


SELECT 
	DISTINCT website_pageviews.pageview_url
FROM session_seen_product_pages
LEFT JOIN website_pageviews
ON session_seen_product_pages.website_session_id = website_pageviews.website_session_id
AND website_pageviews.website_pageview_id > session_seen_product_pages.website_pageview_id;


SELECT 
	session_seen_product_pages.website_session_id,
    session_seen_product_pages.product_page_seen,
    CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN website_pageviews.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN website_pageviews.pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN website_pageviews.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM session_seen_product_pages
LEFT JOIN website_pageviews
ON session_seen_product_pages.website_session_id = website_pageviews.website_session_id
	AND website_pageviews.website_pageview_id > session_seen_product_pages.website_pageview_id
ORDER BY
	session_seen_product_pages.website_session_id,
    website_pageviews.created_at;
    
    
CREATE temporary table session_product_level_made_it_flags
SELECT 
	website_session_id, 
    CASE
		WHEN product_page_seen = '/the-original-mr-fuzzy' THEN 'mrfuzzy'
        WHEN product_page_seen = '/the-forever-love-bear' THEN 'lovebear'
        ELSE 'uh oh... check logic'
	END AS product_seen,
    MAX(cart_page) AS cart_made_it,
    MAX(shipping_page) AS shipping_made_it,
    MAX(billing_page) AS billing_made_it,
    MAX(thankyou_page) AS thankyou_made_it
FROM (
	SELECT 
		session_seen_product_pages.website_session_id,
		session_seen_product_pages.product_page_seen,
		CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
		CASE WHEN website_pageviews.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
		CASE WHEN website_pageviews.pageview_url = '/billing-2' THEN 1 ELSE 0 END AS billing_page,
		CASE WHEN website_pageviews.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
	FROM session_seen_product_pages
	LEFT JOIN website_pageviews
	ON session_seen_product_pages.website_session_id = website_pageviews.website_session_id
		AND website_pageviews.website_pageview_id > session_seen_product_pages.website_pageview_id
	ORDER BY
		session_seen_product_pages.website_session_id,
		website_pageviews.created_at
) AS pageview_level
GROUP BY
	1,2;
    
    
SELECT 
	product_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart,
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS to_shipping,
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS to_billing,
    COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END) AS to_thankyou
FROM session_product_level_made_it_flags
GROUP BY product_seen;


SELECT 
	product_seen,
    COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id) AS product_page_click_rt,
    COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS cart_click_rt,
    COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN shipping_made_it = 1 THEN website_session_id ELSE NULL END) AS shipping_click_rt,
    COUNT(DISTINCT CASE WHEN thankyou_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT CASE WHEN billing_made_it = 1 THEN website_session_id ELSE NULL END) AS billing_click_rt
FROM session_product_level_made_it_flags
GROUP BY product_seen;


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

SELECT 
    orders.primary_product_id,
    COUNT(DISTINCT orders.order_id) AS orders,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN orders.order_id ELSE NULL END) AS x_sell_prod1,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN orders.order_id ELSE NULL END) AS x_sell_prod2,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN orders.order_id ELSE NULL END) AS x_sell_prod3,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 1 THEN orders.order_id ELSE NULL END)/COUNT(DISTINCT orders.order_id) AS x_sell_prod1_rt,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN orders.order_id ELSE NULL END)/COUNT(DISTINCT orders.order_id) AS x_sell_prod2_rt,
    COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN orders.order_id ELSE NULL END)/COUNT(DISTINCT orders.order_id) AS x_sell_prod3_rt
FROM orders
LEFT JOIN order_items
ON orders.order_id = order_items.order_id
AND order_items.is_primary_item = 0
WHERE orders.order_id BETWEEN 10000 AND 11000
group by 1;


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Assignment Cross Sell Analysis

-- STEP 1: Identify the relevant /cart page views amnd their sessions
-- STEP 2: See which of those /cart sessions clicked through to the shipping page
-- STEP 3: Find the orders associated with the /cart sessions. Analyse products purchased, AOV
-- STEP 4: Aggregate and analyze a summary of our findings

CREATE temporary table sessions_seeing_cart
SELECT 
	CASE
		WHEN created_at < '2013-09-25' THEN 'A. Pre_Cross_Sell'
        WHEN created_at >= '2013-09-25' THEN 'B. Post_Cross_Sell'
        ELSE 'uh oh... check logic'
	END AS time_period,
website_session_id AS cart_session_id,
website_pageview_id AS cart_pageview_id
FROM website_pageviews 
WHERE created_at BETWEEN '2013-08-25' AND '2013-10-25'
	AND pageview_url = '/cart';
    
    
CREATE temporary table cart_session_seeing_another_page
SELECT 
	sessions_seeing_cart.time_period,
    sessions_seeing_cart.cart_session_id,
    MIN(website_pageviews.website_pageview_id) AS pv_id_after_cart
FROM sessions_seeing_cart
LEFT JOIN website_pageviews
ON website_pageviews.website_session_id = sessions_seeing_cart.cart_session_id
	AND website_pageviews.website_pageview_id > sessions_seeing_cart.cart_pageview_id
group by 
	sessions_seeing_cart.time_period,
    sessions_seeing_cart.cart_session_id
HAVING 
	MIN(website_pageviews.website_pageview_id) IS NOT NULL;

create temporary table pre_post_session_orders
SELECT 
	time_period,
    cart_session_id,
    order_id,
    items_purchased,
    price_usd
FROM sessions_seeing_cart
INNER JOIN orders
ON sessions_seeing_cart.cart_session_id = orders.website_session_id;


SELECT 
	sessions_seeing_cart.time_period,
    sessions_seeing_cart.cart_session_id,
    CASE WHEN cart_session_seeing_another_page.cart_session_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
    CASE WHEN pre_post_session_orders.order_id IS NULL THEN 0 ELSE 1 END AS placed_order,
    pre_post_session_orders.items_purchased,
    pre_post_session_orders.price_usd
FROM sessions_seeing_cart
LEFT JOIN cart_session_seeing_another_page
ON sessions_seeing_cart.cart_session_id = cart_session_seeing_another_page.cart_session_id
LEFT JOIN pre_post_session_orders
ON sessions_seeing_cart.cart_session_id = pre_post_session_orders.cart_session_id;

SELECT
	time_period,
    COUNT(DISTINCT cart_session_id) AS cart_sessions,
    SUM(clicked_to_another_page) AS clickthroughs,
    SUM(clicked_to_another_page)/COUNT(DISTINCT cart_session_id) AS cart_ctr,
    SUM(placed_order) AS orders_placed,
    SUM(items_purchased) AS products_purchased,
    SUM(items_purchased)/SUM(placed_order) AS products_per_order,
    SUM(price_usd) AS revenue,
    SUM(price_usd)/SUM(placed_order) AS AOV,
    SUM(price_usd)/COUNT(DISTINCT cart_session_id) AS rev_per_cart_session
FROM (
	SELECT 
		sessions_seeing_cart.time_period,
		sessions_seeing_cart.cart_session_id,
		CASE WHEN cart_session_seeing_another_page.cart_session_id IS NULL THEN 0 ELSE 1 END AS clicked_to_another_page,
		CASE WHEN pre_post_session_orders.order_id IS NULL THEN 0 ELSE 1 END AS placed_order,
		pre_post_session_orders.items_purchased,
		pre_post_session_orders.price_usd
	FROM sessions_seeing_cart
	LEFT JOIN cart_session_seeing_another_page
	ON sessions_seeing_cart.cart_session_id = cart_session_seeing_another_page.cart_session_id
	LEFT JOIN pre_post_session_orders
	ON sessions_seeing_cart.cart_session_id = pre_post_session_orders.cart_session_id
) AS full_data
GROUP BY
	time_period;
    

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


SELECT
	CASE
		WHEN website_sessions.created_at < '2013-12-12' THEN 'A.Pre_Birthday_Bear'
        WHEN website_sessions.created_at >= '2013-12-12' THEN 'B.Post_Birthday_Bear'
        ELSE 'uh oh... check logiv'
	END AS time_period,
    COUNT(distinct website_sessions.website_session_id) AS sessions,
    COUNT(distinct orders.order_id) AS orders,
    ROUND(COUNT(distinct orders.order_id)/COUNT(distinct website_sessions.website_session_id)*100,2) AS conv_rate,
    SUM(price_usd)/COUNT(distinct orders.order_id) AS aov,
    SUM(items_purchased)/COUNT(distinct orders.order_id) AS products_per_order,
    SUM(price_usd)/COUNT(distinct website_sessions.website_session_id) AS revenue_per_session
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at BETWEEN DATE_SUB('2013-12-12', INTERVAL 1 MONTH) AND DATE_ADD('2013-12-12', INTERVAL 1 MONTH)
GROUP BY 1;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


SELECT
	YEAR(order_items.created_at) AS yr,
    month(order_items.created_at) AS mo,
    COUNT(distinct CASE WHEN order_items.product_id = 1 THEN order_items.order_id ELSE NULL END) AS 'p1.orders',
    ROUND(SUM(CASE WHEN order_items.product_id = 1 THEN order_item_refunds.refund_amount_usd ELSE NULL END) / SUM(CASE WHEN order_items.product_id = 1 THEN order_items.price_usd ELSE NULL END)*100,2) AS 'p1_refund_rt',
    COUNT(DISTINCT CASE WHEN order_items.product_id = 2 THEN order_items.order_id ELSE NULL END) AS 'p2.orders',
    ROUND(SUM(CASE WHEN order_items.product_id = 2 THEN order_item_refunds.refund_amount_usd ELSE NULL END) / SUM(CASE WHEN order_items.product_id = 2 THEN order_items.price_usd ELSE NULL END)*100,2) AS 'p2_refund_rt',
    COUNT(DISTINCT CASE WHEN order_items.product_id = 3 THEN order_items.order_id ELSE NULL END) AS 'p3.orders',
    ROUND(SUM(CASE WHEN order_items.product_id = 3 THEN order_item_refunds.refund_amount_usd ELSE NULL END) / SUM(CASE WHEN order_items.product_id = 3 THEN order_items.price_usd ELSE NULL END)*100,2) AS 'p3_refund_rt'
FROM order_items
LEFT JOIN order_item_refunds
ON order_items.order_id = order_item_refunds.order_id
WHERE order_items.created_at < '2014-10-15'
GROUP BY
	YEAR(order_items.created_at),
    month(order_items.created_at);
    
    
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


create temporary table sessions_w_repeat
SELECT 
	new_sessions.user_id,
    new_sessions.website_session_id AS new_session_id,
    website_sessions.website_session_id AS repeat_session_id
FROM (
	SELECT 
		user_id,
		website_session_id
	FROM website_sessions
	WHERE created_at between '2014-01-01' AND '2014-11-01'
		AND is_repeat_session = 0
) As new_sessions
LEFT JOIN website_sessions
ON new_sessions.user_id = website_sessions.user_id
	AND website_sessions.is_repeat_session = 1
    AND website_sessions.website_session_id > new_sessions.website_session_id
    AND website_sessions.created_at between '2014-01-01' AND '2014-11-01'
;

SELECT
	repeat_sessions,
    COUNT(DISTINCT user_id) AS users
FROM (
	SELECT 
		user_id,
		COUNT(distinct new_session_id) AS new_sessions,
		count(distinct repeat_session_id) AS repeat_sessions
	FROM sessions_w_repeat
	group by 1
	ORDER BY 3 DESC
) AS user_level
group by 1;


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


CREATE temporary table sessions_w_repeat_for_time_diff
SELECT 
	first_sessions.user_id,
    first_sessions.website_session_id AS new_session_id,
    first_sessions.created_at AS new_session_date,
    website_sessions.website_session_id AS repeat_session_id,
    website_sessions.created_at AS repeat_session_date
FROM (
	SELECT 
		user_id, 
		website_session_id,
        created_at
	FROM website_sessions
	WHERE created_at BETWEEN '2014-01-01' AND '2014-11-03'
		AND is_repeat_session = 0
) AS first_sessions
LEFT JOIN website_sessions
ON first_sessions.user_id = website_sessions.user_id
	AND website_sessions.is_repeat_session = 1
    AND website_sessions.website_session_id > first_sessions.website_session_id
    AND website_sessions.created_at BETWEEN '2014-01-01' AND '2014-11-03';
    
    
    
CREATE temporary table users_first_to_second
SELECT 
	user_id,
    datediff(second_session_date, new_session_date) AS difference
FROM (
	SELECT 
		user_id,
		new_session_id,
		new_session_date,
		MIN(repeat_session_id) AS second_session_id,
		MIN(repeat_session_date) AS second_session_date
	FROM sessions_w_repeat_for_time_diff
	GROUP BY 1,2,3
) AS first_second;


SELECT 
	AVG(difference) AS avg_days_first_to_second,
    MIN(difference) AS min_days_first_to_second,
    MAX(difference) AS MAX_days_first_to_second
FROM users_first_to_second;


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


SELECT 
	CASE 
		WHEN utm_source IS NULL AND http_referer IS NULL THEN 'direct_type_in'
		WHEN utm_campaign = "nonbrand" THEN "paid_nonbrand"
        WHEN utm_campaign = 'brand' THEN 'paid_brand'
        WHEN utm_source = 'socialbook' THEN 'paid_social'
        WHEN utm_campaign IS NULL AND http_referer IS NOT NULL THEN 'organic_search'
	END AS channel_group,
	-- utm_content, 
    -- utm_campaign,
    -- http_referer,
    COUNT(distinct CASE WHEN is_repeat_session = 0 THEN website_session_id ELSE NULL END) AS new_session,
    COUNT(distinct CASE WHEN is_repeat_session = 1 THEN website_session_id ELSE NULL END) AS repeat_session
FROM website_sessions
WHERE created_at BETWEEN '2014-01-01' AND '2014-11-05'
GROUP BY 1;


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


SELECT *
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at BETWEEN '2014-01-01' AND '2014-11-08';



SELECT 
	website_sessions.is_repeat_session,
    COUNT(distinct website_sessions.website_session_id) AS sessions, 
    COUNT(DISTINCT orders.order_id) AS orders,
    ROUND(COUNT(DISTINCT orders.order_id)/COUNT(distinct website_sessions.website_session_id)*100,2) AS conv_rate,
    ROUND(SUM(price_usd) / COUNT(distinct website_sessions.website_session_id)*100,2) AS rev_per_session
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
WHERE website_sessions.created_at BETWEEN '2014-01-01' AND '2014-11-08'
GROUP BY 1;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

