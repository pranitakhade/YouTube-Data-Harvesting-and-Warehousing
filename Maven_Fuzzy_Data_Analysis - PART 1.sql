SELECT 
	w.utm_content, 
    COUNT(distinct w.website_session_id) as sessions, 
    COUNT(distinct o.order_id) as orders, 
    ROUND(COUNT(distinct o.order_id)/COUNT(distinct w.website_session_id)*100,2) AS session_to_order_conv_rt
FROM 
	website_sessions w
LEFT JOIN 
	orders o
ON 
	w.website_session_id = o.website_session_id
WHERE 
	w.website_session_id BETWEEN 1000 AND 2000
group by 
	w.utm_content
ORDER BY 
	sessions DESC
;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 1st Question
SELECT 
	utm_source, 
    utm_campaign, 
    http_referer, 
    COUNT(distinct website_session_id) AS sessions
FROM 
	website_sessions
WHERE 
	created_at < '2012-04-12'
GROUP BY 
	utm_source, 
    utm_campaign, 
    http_referer
order by
	sessions DESC
;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 2nd Question
SELECT 
	COUNT(DISTINCT w.website_session_id) AS sessions, 
    COUNT(distinct o.order_id) AS orders, 
    ROUND(COUNT(distinct o.order_id)/COUNT(DISTINCT w.website_session_id)*100,2) AS session_to_order_conv_rt
FROM 
	website_sessions w
LEFT JOIN 
	orders o
ON 
	w.website_session_id = o.website_session_id
WHERE 
	w.created_at < '2012-04-14' 
	AND w.utm_source = 'gsearch' 
    AND w.utm_campaign = 'nonbrand'
;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 3rd Question
SELECT 
	primary_product_id, 
    count(distinct case when items_purchased = 1 then order_id ELSE null END) AS count_single_item_orders,
    count(distinct case when items_purchased = 2 then order_id ELSE null END) AS count_two_item_orders
FROM 
	orders
WHERE 
	order_id BETWEEN 31000 AND 32000
group by 
	primary_product_id;
    
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 4th Question

SELECT 
    MIN(date(created_at)) AS week_start_date,
    count(distinct website_session_id) AS sessions
FROM website_sessions 
where created_at < '2012-05-10'
	AND utm_source = 'gsearch' 
    AND utm_campaign = 'nonbrand'
group by 
	year(created_at),
    week(created_at)
;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 5th Question
SELECT 
	w.device_type, 
    COUNT(DISTINCT(w.website_session_id)) AS sessions, 
    COUNT(DISTINCT(o.order_id)) AS orders, 
    ROUND(COUNT(DISTINCT(o.order_id))/COUNT(DISTINCT(w.website_session_id))*100,2) AS session_to_order_conv_rt
FROM 
	website_sessions w
LEFT JOIN 
	orders o
ON 
	w.website_session_id = o.website_session_id
WHERE 
	w.created_at < '2012-05-11'
    AND utm_source = 'gsearch' 
    AND utm_campaign = 'nonbrand'
group by 
	w.device_type;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 6th question
SELECT 
    MIN(DATE(created_at)) AS week_start_date,
    COUNT(DISTINCT CASE WHEN device_type = 'desktop' THEN website_session_id ELSE NULL END) AS desktop_sessions,
    COUNT(DISTINCT CASE WHEN device_type = 'mobile' THEN website_session_id ELSE NULL END) AS mobile_sessions
FROM 
	website_sessions
WHERE 
	created_at BETWEEN '2012-04-15' AND '2012-06-09'
	AND utm_source = 'gsearch' 
    AND utm_campaign = 'nonbrand'
GROUP BY 
	YEAR(created_at),
    WEEK(created_at)
;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 7th Question 
SELECT 
	pageview_url,
	count(distinct website_session_id) AS sessions
FROM 
	website_pageviews
WHERE 
	created_at < '2012-06-09'
GROUP BY 
	pageview_url
ORDER BY 
	sessions DESC
;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 8th Question
CREATE temporary table first_pv_per_session
SELECT website_session_id,
	MIN(website_pageview_id) AS first_pv
FROM 
	website_pageviews
WHERE 
	created_at < '2012-06-12'
GROUP BY 
	website_session_id
;

SELECT 
	w.pageview_url AS landing_page_url, 
	COUNT(DISTINCT f.website_session_id) AS session_hitting_page
FROM 
	first_pv_per_session f
LEFT JOIN 
	website_pageviews w
ON 
	f.first_pv = w.website_pageview_id
GROUP BY 
	w.pageview_url
;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- BUSINESS CONTEXT : We want to see landing page performance for a certain time period

-- STEP 1: Find the first website_pageview_id for relevant sessions
-- STEP 2: Identify the landing page for each session
-- STEP 3: Counting pageviews for each session, to identify "bounces".
-- STEP 4: Summarizing total sessions and bounced sessions, by LP. 

CREATE temporary table first_pageview_demo
SELECT 
	wp.website_session_id,
    MIN(wp.website_pageview_id) AS min_pageview_id
FROM 
	website_pageviews wp
INNER JOIN 
	website_sessions ws
ON 
	wp.website_session_id = ws.website_session_id
	AND ws.created_at between '2014-01-01' AND '2014-02-01'
GROUP BY 
	wp.website_session_id
;

CREATE temporary table sessions_w_landing_page_demo
SELECT 
	fd.website_session_id,
	wp.pageview_url as landing_page
FROM 
	first_pageview_demo fd
LEFT JOIN 
	website_pageviews wp
ON 
	fd.min_pageview_id = wp.website_pageview_id
;

create temporary table bounced_sessions_only
SELECT 
	sd.website_session_id, 
    sd.landing_page, 
    COUNT(wp.website_pageview_id) AS count_of_pages_viewed
FROM 
	sessions_w_landing_page_demo sd
LEFT JOIN 
	website_pageviews wp
ON 
	sd.website_session_id = wp.website_session_id
GROUP BY 
	sd.website_session_id, sd.landing_page
HAVING
	COUNT(wp.website_pageview_id) = 1
;


SELECT 
	sd.landing_page, 
	sd.website_session_id, 
    bo.website_session_id AS bounced_website_session_id
FROM 
	sessions_w_landing_page_demo sd
LEFT JOIN 
	bounced_sessions_only bo
ON 
	sd.website_session_id = bo.website_session_id
ORDER BY 
	sd.website_session_id
;

SELECT 
	sd.landing_page, 
	COUNT(DISTINCT sd.website_session_id) AS sessions,
    COUNT(DISTINCT bo.website_session_id) AS bounced_sessions,
    ROUND(COUNT(DISTINCT bo.website_session_id)/COUNT(DISTINCT sd.website_session_id)*100,2) AS bounced_session_rate
FROM 
	sessions_w_landing_page_demo sd
LEFT JOIN 
	bounced_sessions_only bo
ON 
	sd.website_session_id = bo.website_session_id
GROUP BY
	sd.landing_page
;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 9th Question 

CREATE temporary table first_pageviews
SELECT 
	website_session_id,
	MIN(website_pageview_id) AS min_pageview_id
FROM 
	website_pageviews
WHERE 
	created_at < '2012-06-12'
GROUP BY 
	website_session_id
;

CREATE temporary table sessions_w_home_landing_page
SELECT 
	fp.website_session_id,
    wp.pageview_url AS landing_page
FROM 
	first_pageviews fp
LEFT JOIN 
	website_pageviews wp
ON 
	fp.min_pageview_id = wp.website_pageview_id 
WHERE 
	wp.pageview_url = '/home'
;
	
create temporary table bounced_sessions
SELECT 
	sd.website_session_id, 
	sd.landing_page, 
    COUNT(wp.website_pageview_id) AS count_of_page_view
FROM 
	sessions_w_home_landing_page sd
LEFT JOIN 
	website_pageviews wp
ON 
	sd.website_session_id = wp.website_session_id
group by 
	sd.website_session_id, 
	sd.landing_page
HAVING 
	COUNT(wp.website_pageview_id) = 1
;

SELECT 
	sd.website_session_id,
	bo.website_session_id
FROM 
	sessions_w_home_landing_page sd
LEFT JOIN 
	bounced_sessions bo
ON 
	sd.website_session_id = bo.website_session_id
;

SELECT 
	COUNT(DISTINCT sd.website_session_id) AS sessions,
	COUNT(DISTINCT bo.website_session_id) AS bounced_sessions,
    ROUND(COUNT(DISTINCT bo.website_session_id)/COUNT(DISTINCT sd.website_session_id)*100,2) AS bounced_session_rate
FROM 
	sessions_w_home_landing_page sd
LEFT JOIN 
	bounced_sessions bo
ON 
	sd.website_session_id = bo.website_session_id
;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 10th Question

SELECT 
	MIN(created_at) AS first_created_at, 
    min(website_pageview_id) AS first_pageview_id
FROM 
	website_pageviews
WHERE 
	created_at IS NOT NULL
	AND pageview_url = '/lander-1'
;


CREATE temporary table first_test_pageview
SELECT 
	website_pageviews.website_session_id,
    MIN(website_pageviews.website_pageview_id) AS first_pageview
FROM 
	website_pageviews
INNER JOIN 
	website_sessions
ON 
	website_pageviews.website_session_id = website_sessions.website_session_id
    AND website_sessions.created_at < '2017-07-28'
    AND website_pageviews.website_pageview_id > 23504
    AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
GROUP BY 
	website_pageviews.website_session_id
;


CREATE temporary table nonbrand_test_session_w_landing_page
SELECT 
	fpt.website_session_id, 
	wp.pageview_url AS landing_page
FROM 
	first_test_pageview fpt
LEFT JOIN 
	website_pageviews wp
ON 
	fpt.first_pageview = wp.website_pageview_id
WHERE 
	wp.pageview_url IN ('/lander-1', '/home')
;

CREATE temporary table nonbrand_test_bounced_session
SELECT 
	sw.website_session_id, sw.landing_page, 
    COUNT(DISTINCT wp.website_pageview_id) AS count_of_pages_viewed
FROM 
	nonbrand_test_session_w_landing_page sw
LEFT JOIN 
	website_pageviews wp
ON 
	sw.website_session_id = wp.website_session_id
GROUP BY 
	sw.website_session_id, sw.landing_page
HAVING 
	COUNT(DISTINCT wp.website_pageview_id) = 1
;


SELECT 
	nonbrand_test_session_w_landing_page.landing_page, 
	count(DISTINCT nonbrand_test_session_w_landing_page.website_session_id) AS total_sessions,
    COUNT(DISTINCT nonbrand_test_bounced_session.website_session_id) AS bounced_session,
    ROUND(COUNT(DISTINCT nonbrand_test_bounced_session.website_session_id)/count(DISTINCT nonbrand_test_session_w_landing_page.website_session_id)*100,2) AS bounce_rate
FROM 
	nonbrand_test_session_w_landing_page
LEFT JOIN 
	nonbrand_test_bounced_session
ON 
	nonbrand_test_session_w_landing_page.website_session_id = nonbrand_test_bounced_session.website_session_id
GROUP BY 
	nonbrand_test_session_w_landing_page.landing_page
;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- 11th Question
CREATE temporary table sessions_w_min_pv_id_and_view_count
SELECT
	ws.website_session_id,
    min(wp.website_pageview_id) AS first_pageview_id,
    count(wp.website_pageview_id) AS count_pageviews
FROM 
	website_sessions ws
LEFT JOIN 
	website_pageviews wp
ON 
	ws.website_session_id = wp.website_session_id
WHERE 
	ws.created_at between '2012-06-01' AND '2012-08-31'
	AND ws.utm_source = 'gsearch'
	AND ws.utm_campaign = 'nonbrand' 
GROUP BY 
	ws.website_session_id
;

CREATE temporary table sessions_counts_lander_and_created_at
SELECT 
	sw.*, 
	wp.pageview_url AS landing_page, 
    wp.created_at AS session_created_at
FROM 
	sessions_w_min_pv_id_and_view_count sw
LEFT JOIN 
	website_pageviews wp
ON 
	sw.website_session_id = wp.website_session_id
;

SELECT 
	-- yearweek(session_created_at) AS year_week,
    MIN(DATE(session_created_at)) AS week_start_date,
    -- COUNT(DISTINCT website_session_id) AS total_sessions,
    -- COUNT(distinct CASE WHEN count_pageviews = 1 THEN website_session_id ELSE NULL END) AS bounced_sessions,
    ROUND(COUNT(distinct CASE WHEN count_pageviews = 1 THEN website_session_id ELSE NULL END)/COUNT(DISTINCT website_session_id)*100,2) AS boounce_rate,
    COUNT(distinct CASE WHEN landing_page = '/home' THEN website_session_id ELSE NULL END) AS home_sessions,
    COUNT(distinct CASE WHEN landing_page = '/lander-1' THEN website_session_id ELSE NULL END) AS lander_session
FROM 
	sessions_counts_lander_and_created_at
GROUP BY
	yearweek(session_created_at)
;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- BUSINESS CONTEXT
	-- We want to build a mini conversion funnel, from /lander-2 to /cart
    -- We want to know how many people reach each step, and also fropoff rates

-- STEP 1: Select all pageviews for relevant sessions
-- STEP 2: Identify each relevant pageview as the specific funnel step
-- STEP 3: Create the session-level conversion funnel view
-- STEP 4: Aggregate the data to access funnel performance


SELECT 
	website_sessions.website_session_id,
    website_sessions.created_at,
    website_pageviews.pageview_url,
    CASE WHEN website_pageviews.pageview_url = '/products' THEN 1 ELSE 0 END AS product_page,
    CASE WHEN website_pageviews.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
    CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page
FROM website_sessions
LEFT JOIN website_pageviews
ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.created_at between '2014-01-01' AND '2014-02-01'
	AND website_pageviews.pageview_url IN ('/lander-2', '/products','/cart','/the-original-mr-fuzzy')
ORDER BY 
	website_sessions.website_session_id,
    website_sessions.created_at
;
create temporary table session_level_made_it_flag_demo
SELECT
	website_session_id,
    MAX(product_page) AS products_made_it,
    MAX(mrfuzzy_page) AS mrfuzzy_made_it,
    MAX(cart_page) AS cart_made_it
FROM (
	SELECT 
		website_sessions.website_session_id,
		website_sessions.created_at,
		website_pageviews.pageview_url,
		CASE WHEN website_pageviews.pageview_url = '/products' THEN 1 ELSE 0 END AS product_page,
		CASE WHEN website_pageviews.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
		CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page
	FROM website_sessions
	LEFT JOIN website_pageviews
	ON website_sessions.website_session_id = website_pageviews.website_session_id
	WHERE website_sessions.created_at between '2014-01-01' AND '2014-02-01'
		AND website_pageviews.pageview_url IN ('/lander-2', '/products','/cart','/the-original-mr-fuzzy')
	ORDER BY 
		website_sessions.website_session_id,
		website_sessions.created_at
) AS pageview_level
GROUP BY website_session_id
;

SELECT 
	COUNT(distinct website_session_id) AS sessions,
    COUNT(distinct CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END) AS to_products,
    COUNT(distinct CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END) AS to_mrfuzzy,
    COUNT(distinct CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END) AS to_cart
FROM 
	session_level_made_it_flag_demo;
    

SELECT 
	COUNT(distinct website_session_id) AS sessions,
    ROUND(COUNT(distinct CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(distinct website_session_id)*100,2) AS lander_clickthrough_rate,
    ROUND(COUNT(distinct CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(distinct CASE WHEN products_made_it = 1 THEN website_session_id ELSE NULL END)*100,2) AS products_clickthrough_rate,
    ROUND(COUNT(distinct CASE WHEN cart_made_it = 1 THEN website_session_id ELSE NULL END)/COUNT(distinct CASE WHEN mrfuzzy_made_it = 1 THEN website_session_id ELSE NULL END)*100,2) AS mrfuzzy_clickthrough_rate
FROM 
	session_level_made_it_flag_demo;
    
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
-- 12th Question
SELECT 
	website_sessions.website_session_id, 
	website_sessions.created_at, 
	website_pageviews.pageview_url,
    CASE WHEN website_pageviews.pageview_url = '/products' THEN 1 ELSE 0 END AS product_page,
    CASE WHEN website_pageviews.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
    CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
    CASE WHEN website_pageviews.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
    CASE WHEN website_pageviews.pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
    CASE WHEN website_pageviews.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
FROM website_sessions
LEFT JOIN website_pageviews
ON website_sessions.website_session_id = website_pageviews.website_session_id
WHERE website_sessions.created_at BETWEEN '2012-08-05' AND '2012-09-05'
	AND website_sessions.utm_source = 'gsearch'
    AND website_sessions.utm_campaign = 'nonbrand'
    AND website_pageviews.pageview_url IN ('/lander-1','/products','/the-original-mr-fuzzy','/cart','/shipping','/billing','/thank-you-for-your-order')
ORDER BY website_sessions.website_session_id, website_sessions.created_at;



create temporary table session_level_made_it_to_thankyou_page
SELECT 
	website_session_id, 
    MAX(product_page) AS to_products,
    MAX(mrfuzzy_page) AS to_mrfuzzy,
    MAX(cart_page) AS to_cart,
    MAX(shipping_page) AS to_shipping,
    MAX(billing_page) AS to_billing,
    MAX(thankyou_page) AS to_thankyou
FROM (
	SELECT 
		website_sessions.website_session_id, 
		website_sessions.created_at, 
		website_pageviews.pageview_url,
		CASE WHEN website_pageviews.pageview_url = '/products' THEN 1 ELSE 0 END AS product_page,
		CASE WHEN website_pageviews.pageview_url = '/the-original-mr-fuzzy' THEN 1 ELSE 0 END AS mrfuzzy_page,
		CASE WHEN website_pageviews.pageview_url = '/cart' THEN 1 ELSE 0 END AS cart_page,
		CASE WHEN website_pageviews.pageview_url = '/shipping' THEN 1 ELSE 0 END AS shipping_page,
		CASE WHEN website_pageviews.pageview_url = '/billing' THEN 1 ELSE 0 END AS billing_page,
		CASE WHEN website_pageviews.pageview_url = '/thank-you-for-your-order' THEN 1 ELSE 0 END AS thankyou_page
	FROM website_sessions
	LEFT JOIN website_pageviews
	ON website_sessions.website_session_id = website_pageviews.website_session_id
	WHERE website_sessions.created_at BETWEEN '2012-08-05' AND '2012-09-05'
		AND website_sessions.utm_source = 'gsearch'
		AND website_sessions.utm_campaign = 'nonbrand'
		AND website_pageviews.pageview_url IN ('/lander-1','/products','/the-original-mr-fuzzy','/cart','/shipping','/billing','/thank-you-for-your-order')
	ORDER BY website_sessions.website_session_id, website_sessions.created_at
) AS pageview_demo
GROUP BY website_session_id;

SELECT 
	COUNT(distinct website_session_id) AS sessions,
    SUM(to_products) AS to_products,
    SUM(to_mrfuzzy) AS to_mrfuzzy,
    SUM(to_cart) AS to_cart,
    SUM(to_shipping) AS to_shipping,
    SUM(to_billing) AS to_billing,
    SUM(to_thankyou) AS to_thankyou
FROM
	session_level_made_it_to_thankyou_page;
    
    
    
SELECT 
	COUNT(distinct website_session_id) AS lander_click_rt,
    ROUND(SUM(to_products)/COUNT(distinct website_session_id)*100,2) AS products_click_rt,
    ROUND(SUM(to_mrfuzzy)/SUM(to_products)*100,2) AS mrfuzzy_click_rt,
    ROUND(SUM(to_cart)/SUM(to_mrfuzzy)*100,2) AS cart_click_rt,
    ROUND(SUM(to_shipping)/SUM(to_cart)*100,2) AS shipping_click_rt,
    ROUND(SUM(to_billing)/SUM(to_shipping)*100,2) AS billing_click_rt,
    ROUND(SUM(to_thankyou)/SUM(to_billing)*100,2) AS thankyou_click_rt
FROM
	session_level_made_it_to_thankyou_page;
    
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
-- 13th Question
SELECT 
	MIN(DATE(created_at)) AS first_created_at,
    MIN(website_pageview_id) AS first_pv_id
FROM website_pageviews
WHERE pageview_url = '/billing-2'
GROUP BY pageview_url;

SELECT 
	website_pageviews.website_session_id,
    website_pageviews.pageview_url AS billing_version_seen,
    orders.order_id
FROM website_pageviews
LEFT JOIN orders
ON website_pageviews.website_session_id = orders.website_session_id
WHERE website_pageviews.created_at between '2012-09-10' AND '2012-11-10'
	AND website_pageviews.website_pageview_id >= 53550
	AND website_pageviews.pageview_url IN ('/billing', '/billing-2')
order by 
	website_pageviews.website_session_id,
    website_pageviews.created_at;


SELECT 
	billing_version_seen,
	COUNT(DISTINCT website_session_id) AS sessions,
    COUNT(DISTINCT order_id) AS orders,
    ROUND(COUNT(DISTINCT order_id)/COUNT(DISTINCT website_session_id)*100,2) AS billing_to_order_rt
FROM (
	SELECT 
		website_pageviews.website_session_id,
		website_pageviews.pageview_url AS billing_version_seen,
		orders.order_id
	FROM website_pageviews
	LEFT JOIN orders
	ON website_pageviews.website_session_id = orders.website_session_id
	WHERE website_pageviews.created_at between '2012-09-10' AND '2012-11-10'
		AND website_pageviews.website_pageview_id >= 53550
		AND website_pageviews.pageview_url IN ('/billing', '/billing-2')
	order by 
		website_pageviews.website_session_id,
		website_pageviews.created_at
) AS pageview_demo
group by billing_version_seen;


