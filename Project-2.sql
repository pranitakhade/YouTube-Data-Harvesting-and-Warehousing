/*
1. First, I'd like to show our volume growth. Can you pull overall session and order volume, 
trended by quarter for the life of the business? Since the most recent quarter is incomplete,
you can decide how to handle it.
*/

SELECT 
	YEAR(website_sessions.created_at) AS yr,
    quarter(website_sessions.created_at) AS qr,
	COUNT(distinct website_sessions.website_session_id) AS overall_sessions,
    COUNT(distinct orders.order_id) AS orders
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 1,2
order by 1,2;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*
2. Next, let's showcase all of our efficiency improvements. I would love to show quarterly figures
since we launched, for session-to-order conversion rate, revenue per order, and revenue per session
*/

SELECT 
	YEAR(website_sessions.created_at) AS yr,
    quarter(website_sessions.created_at) AS qr,
	-- COUNT(distinct website_sessions.website_session_id) AS overall_sessions,
    ROUND(COUNT(distinct orders.order_id)/COUNT(distinct website_sessions.website_session_id)*100,2) AS session_to_order,
    ROUND(SUM(orders.price_usd)/COUNT(distinct orders.order_id)*100,2) AS revenue_per_order,
    ROUND(SUM(orders.price_usd)/COUNT(distinct website_sessions.website_session_id)*100,2) AS revenue_per_session
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 1,2
order by 1,2;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*
3. I'd like to show how we've grown specific channels. Could you pull a quarterly view of orders
from Gsearch nonbrand, Bsearch nonbrand, brand search overall, organic search and direct type-in?
*/

SELECT 
	YEAR(website_sessions.created_at) AS yr,
    quarter(website_sessions.created_at) AS qr,
	COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) AS "gsearch_nonbrand",
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END) AS "bsearch_nonbrand",
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN orders.order_id ELSE NULL END) AS "brand",
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN orders.order_id ELSE NULL END) AS "organic_search",
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN orders.order_id ELSE NULL END) AS "direct_type_in"
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 
	YEAR(website_sessions.created_at),
    quarter(website_sessions.created_at);
    
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/* 
4. Next, let's show the overall session-to-order conversion rate trends for those same channels,
by quarter. Please also make a note of any periods where we made major improvements or optimizations.
*/

SELECT 
	YEAR(website_sessions.created_at) AS yr,
    quarter(website_sessions.created_at) AS qr,
	COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' AND utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END) AS "gsearch_nonbrand_conv_rt",
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN orders.order_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' AND utm_campaign = 'nonbrand' THEN website_sessions.website_session_id ELSE NULL END)AS "bsearch_nonbrand_conv_rt",
    COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN orders.order_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN utm_campaign = 'brand' THEN website_sessions.website_session_id ELSE NULL END) AS "brand_conv_rt",
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN orders.order_id ELSE NULL END) 
		/COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS "organic_conv_rt",
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN orders.order_id ELSE NULL END)
		/COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS "direct_type_in_conv_rt"
FROM website_sessions
LEFT JOIN orders
ON website_sessions.website_session_id = orders.website_session_id
GROUP BY 
	YEAR(website_sessions.created_at),
    quarter(website_sessions.created_at);
    
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    
/*
5. We've come a long way since the days of selling a single product. Let's pull monthly trending for revenue
and margin by product, along with total sales and revenue. Note anything you notice about seasonality.
*/

SELECT 
	YEAR(created_at) AS yr,
    MONTH(created_at) AS mo,
    SUM(CASE WHEN product_id = 1 THEN price_usd ELSE NULL END) AS mrfuzzy_rev,
    SUM(CASE WHEN product_id = 1 THEN price_usd - cogs_usd ELSE NULL END) AS mrfuzzy_marg,
    SUM(CASE WHEN product_id = 2 THEN price_usd ELSE NULL END) AS lovebear_rev,
    SUM(CASE WHEN product_id = 2 THEN price_usd - cogs_usd ELSE NULL END) AS lovebear_marg,
    SUM(CASE WHEN product_id = 3 THEN price_usd ELSE NULL END) AS birthdaybear_rev,
    SUM(CASE WHEN product_id = 3 THEN price_usd - cogs_usd ELSE NULL END) AS birthdaybear_marg,
    SUM(CASE WHEN product_id = 4 THEN price_usd ELSE NULL END) AS minibear_rev,
    SUM(CASE WHEN product_id = 4 THEN price_usd - cogs_usd ELSE NULL END) AS minibear_marg
FROM order_items
GROUP BY 1,2
ORDER BY 1,2;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/*
6. Let's dive deeper into the impact of introducing new products. Please pull monthly sessions to
the /products page, and show how the % of those sessions clicking through another page has changed
over time, along with a view of how conversion from /products to placing an order has improved.
*/

Create temporary table sessions_w_products_to_orders
SELECT 
	product_page.website_session_id,
    product_page.website_pageview_id AS product_pageview_id,
    product_page.created_at AS created,
    MIN(website_pageviews.website_pageview_id) AS next_pageview_id
FROM (
	SELECT 
		website_session_id, website_pageview_id, created_at
	FROM website_pageviews
	WHERE pageview_url = '/products'
) AS product_page
LEFT JOIN website_pageviews
ON product_page.website_session_id = website_pageviews.website_session_id
	AND website_pageviews.website_pageview_id > product_page.website_pageview_id
GROUP BY 1,2,3;


SELECT 
	YEAR(created) AS yr,
    MONTH(created) AS mo,
    COUNT(DISTINCT sessions_w_products_to_orders.website_session_id) AS product_sessions,
    ROUND(COUNT(DISTINCT sessions_w_products_to_orders.next_pageview_id)
		/COUNT(DISTINCT sessions_w_products_to_orders.website_session_id)*100,2) AS next_sessions_conv_rt,
	ROUND(COUNT(DISTINCT orders.order_id)/COUNT(DISTINCT sessions_w_products_to_orders.website_session_id)*100,2) AS session_to_order_conv_rt
FROM sessions_w_products_to_orders
LEFT JOIN orders
ON sessions_w_products_to_orders.website_session_id = orders.website_session_id
GROUP BY 1,2;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

/* 
7. We made our 4th product available as a primary product on December 02, 2014 (it was previously only a cross-sell item).
Could you please pull sales data since then, and show how well each product cross-sells from one another?
*/

create temporary table primary_products
SELECT 
	order_id, 
    primary_product_id,
    created_at AS ordered_at
FROM orders
WHERE created_at > '2014-12-02'
;


SELECT 
	primary_product_id,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 1 THEN order_id ELSE NULL END) AS _xsold_p1,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 2 THEN order_id ELSE NULL END) AS _xsold_p2,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 3 THEN order_id ELSE NULL END) AS _xsold_p3,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 4 THEN order_id ELSE NULL END) AS _xsold_p4,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 1 THEN order_id ELSE NULL END)/ COUNT(DISTINCT order_id) AS p1_xsell_rt,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 2 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p2_xsell_rt,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 3 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p3_xsell_rt,
    COUNT(DISTINCT CASE WHEN cross_sell_product_id = 4 THEN order_id ELSE NULL END)/COUNT(DISTINCT order_id) AS p4_xsell_rt
FROM (
	SELECT 
		primary_products.*,
		order_items.product_id AS cross_sell_product_id
	FROM primary_products
	LEFT JOIN order_items
	ON primary_products.order_id = order_items.order_id
		AND order_items.is_primary_item = 0
) AS primary_w_cross_sell
GROUP BY 1;