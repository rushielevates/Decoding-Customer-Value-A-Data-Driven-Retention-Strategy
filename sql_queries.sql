CREATE DATABASE customer_loyalty_db;
USE customer_loyalty_db;
SELECT COUNT(*) FROM customer;
SHOW COLUMNS FROM customer;

-- ques1-- 
SELECT 
    CASE 
        WHEN `Discount Applied` = 'No' AND `Loyalty_Tier_Corrected` = 'High Loyalty' 
            THEN 'Genuinely Loyal (No Discounts Needed)'
        WHEN `Discount Applied` = 'Yes' AND `Loyalty_Tier_Corrected` = 'High Loyalty' 
            THEN 'Valuable but Promo-Driven'
        WHEN `Discount Applied` = 'No' AND `Loyalty_Tier_Corrected` = 'Medium Loyalty' 
            THEN 'Growing Organically'
        WHEN `Discount Applied` = 'Yes' AND `Loyalty_Tier_Corrected` = 'Medium Loyalty' 
            THEN 'Mixed Behavior'
        WHEN `Discount Applied` = 'Yes' AND `Loyalty_Tier_Corrected` = 'Low Loyalty' 
            THEN 'Discount-Only (Only Buy on Sale)'
        WHEN `Discount Applied` = 'No' AND `Loyalty_Tier_Corrected` = 'Low Loyalty' 
            THEN 'At Risk (Low Value, No Discounts)'
    END AS Customer_Segment,

    COUNT(*) AS customer_count,

    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_customers,

    ROUND(AVG(`Purchase Amount (USD)`), 2) AS avg_spend,

    ROUND(SUM(`Purchase Amount (USD)`), 2) AS total_revenue,

    ROUND(SUM(`Purchase Amount (USD)`) * 100.0 / SUM(SUM(`Purchase Amount (USD)`)) OVER (), 1) 
        AS pct_of_total_revenue,

    ROUND(AVG(`Previous Purchases`), 1) AS avg_previous_purchases,

    ROUND(AVG(`Review Rating`), 2) AS avg_satisfaction,

    ROUND(AVG(`Loyalty_Score_Final`), 1) AS avg_loyalty_score

FROM customer
GROUP BY Customer_Segment
ORDER BY avg_spend DESC;

-- ques 2_A
SELECT 
    `Loyalty_Tier_Corrected`,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 1) AS pct_of_total_customers,

    -- Revenue signals
    ROUND(AVG(`Purchase Amount (USD)`), 2) AS avg_spend,
    ROUND(SUM(`Purchase Amount (USD)`), 2) AS total_revenue,
    ROUND(SUM(`Purchase Amount (USD)`) * 100.0 / SUM(SUM(`Purchase Amount (USD)`)) OVER (), 1) 
        AS pct_of_total_revenue,

    -- Purchase history (tenure proxy)
    ROUND(AVG(`Previous Purchases`), 1) AS avg_previous_purchases,

    -- Subscription behaviour
    ROUND(AVG(CASE WHEN `Subscription Status` = 'Yes' THEN 1 ELSE 0 END) * 100, 1) 
        AS pct_subscribed,

    -- Purchase frequency breakdown (all values covered)
    ROUND(AVG(CASE WHEN `Frequency of Purchases` = 'Weekly' THEN 1 ELSE 0 END) * 100, 1) 
        AS pct_weekly,
    ROUND(AVG(CASE WHEN `Frequency of Purchases` = 'Bi-Weekly' THEN 1 ELSE 0 END) * 100, 1) 
        AS pct_biweekly,
    ROUND(AVG(CASE WHEN `Frequency of Purchases` = 'Fortnightly' THEN 1 ELSE 0 END) * 100, 1) 
        AS pct_fortnightly,
    ROUND(AVG(CASE WHEN `Frequency of Purchases` = 'Monthly' THEN 1 ELSE 0 END) * 100, 1) 
        AS pct_monthly,
    ROUND(AVG(CASE WHEN `Frequency of Purchases` IN ('Quarterly','Every 3 Months','Annually') 
        THEN 1 ELSE 0 END) * 100, 1) AS pct_low_frequency,

    -- Discount & promo independence
    ROUND(AVG(CASE WHEN `Discount Applied` = 'No' THEN 1 ELSE 0 END) * 100, 1) 
        AS pct_buys_without_discount,
    ROUND(AVG(CASE WHEN `Promo Code Used` = 'No' THEN 1 ELSE 0 END) * 100, 1) 
        AS pct_buys_without_promo,

    -- Payment method preferences
    ROUND(AVG(CASE WHEN `Payment Method` = 'Credit Card' THEN 1 ELSE 0 END) * 100, 1) 
        AS pct_credit_card,
    ROUND(AVG(CASE WHEN `Payment Method` = 'Debit Card' THEN 1 ELSE 0 END) * 100, 1) 
        AS pct_debit_card,
    ROUND(AVG(CASE WHEN `Payment Method` = 'PayPal' THEN 1 ELSE 0 END) * 100, 1) 
        AS pct_paypal,
    ROUND(AVG(CASE WHEN `Payment Method` = 'Bank Transfer' THEN 1 ELSE 0 END) * 100, 1) 
        AS pct_bank_transfer,
    ROUND(AVG(CASE WHEN `Payment Method` IN ('Cash','Venmo') THEN 1 ELSE 0 END) * 100, 1) 
        AS pct_cash_venmo,

    -- Shipping preference (premium vs free)
    ROUND(AVG(CASE WHEN `Shipping Type` IN ('Express','Next Day Air','2-Day Shipping') 
        THEN 1 ELSE 0 END) * 100, 1) AS pct_premium_shipping,
    ROUND(AVG(CASE WHEN `Shipping Type` = 'Free Shipping' 
        THEN 1 ELSE 0 END) * 100, 1) AS pct_free_shipping,

    -- Satisfaction
    ROUND(AVG(`Review Rating`), 2) AS avg_review_rating,
    ROUND(AVG(`Loyalty_Score_Final`), 1) AS avg_loyalty_score

FROM customer
GROUP BY `Loyalty_Tier_Corrected`
ORDER BY 
    CASE `Loyalty_Tier_Corrected`
        WHEN 'High Loyalty' THEN 1
        WHEN 'Medium Loyalty' THEN 2
        WHEN 'Low Loyalty' THEN 3
    END;


-- ques2-B
SELECT 
    f.`Loyalty_Tier_Corrected`,
    f.`Frequency of Purchases`  AS dominant_frequency,
    f.freq_count,
    c.Category                  AS dominant_category,
    c.cat_count,
    s.Season                    AS dominant_season,
    s.season_count

FROM (
    SELECT `Loyalty_Tier_Corrected`, `Frequency of Purchases`,
        COUNT(*) AS freq_count,
        ROW_NUMBER() OVER (PARTITION BY `Loyalty_Tier_Corrected` 
                           ORDER BY COUNT(*) DESC) AS rn
    FROM customer
    GROUP BY `Loyalty_Tier_Corrected`, `Frequency of Purchases`
) f

JOIN (
    SELECT `Loyalty_Tier_Corrected`, Category,
        COUNT(*) AS cat_count,
        ROW_NUMBER() OVER (PARTITION BY `Loyalty_Tier_Corrected` 
                           ORDER BY COUNT(*) DESC) AS rn
    FROM customer
    GROUP BY `Loyalty_Tier_Corrected`, Category
) c 
    ON f.`Loyalty_Tier_Corrected` = c.`Loyalty_Tier_Corrected` AND c.rn = 1

JOIN (
    SELECT `Loyalty_Tier_Corrected`, Season,
        COUNT(*) AS season_count,
        ROW_NUMBER() OVER (PARTITION BY `Loyalty_Tier_Corrected` 
                           ORDER BY COUNT(*) DESC) AS rn
    FROM customer
    GROUP BY `Loyalty_Tier_Corrected`, Season
) s 
    ON f.`Loyalty_Tier_Corrected` = s.`Loyalty_Tier_Corrected` AND s.rn = 1

WHERE f.rn = 1
ORDER BY 
    CASE f.`Loyalty_Tier_Corrected`
        WHEN 'High Loyalty' THEN 1
        WHEN 'Medium Loyalty' THEN 2
        WHEN 'Low Loyalty' THEN 3
    END; 
    
-- ques 3------------------------------------------------------------------------------------------------------------------------------------------------
-- Part A — Full Geographic Intelligence
WITH location_metrics AS (
    SELECT 
        Location,
        COUNT(*) AS customer_count,

        ROUND(AVG(`Purchase Amount (USD)`), 2) AS avg_spend,
        ROUND(SUM(`Purchase Amount (USD)`), 2) AS total_revenue,
        ROUND(SUM(`Purchase Amount (USD)`) * 100.0 / 
            SUM(SUM(`Purchase Amount (USD)`)) OVER (), 1) AS pct_of_total_revenue,

        ROUND(AVG(`Previous Purchases`), 1) AS avg_previous_purchases,

        ROUND(AVG(CASE WHEN `Discount Applied` = 'No' THEN 1 ELSE 0 END) * 100, 1) 
            AS pct_no_discount,

        ROUND(AVG(CASE WHEN `Promo Code Used` = 'No' THEN 1 ELSE 0 END) * 100, 1) 
            AS pct_no_promo,

        ROUND(AVG(CASE WHEN `Loyalty_Tier_Corrected` = 'High Loyalty' THEN 1 ELSE 0 END) * 100, 1) 
            AS pct_high_loyalty,

        ROUND(AVG(CASE WHEN `Loyalty_Tier_Corrected` = 'Low Loyalty' THEN 1 ELSE 0 END) * 100, 1) 
            AS pct_low_loyalty,

        ROUND(AVG(CASE WHEN `Subscription Status` = 'Yes' THEN 1 ELSE 0 END) * 100, 1) 
            AS pct_subscribed,

        ROUND(AVG(`Review Rating`), 2) AS avg_rating,

        ROUND(AVG(`Loyalty_Score_Final`), 1) AS avg_loyalty_score

    FROM customer
    GROUP BY Location
    HAVING COUNT(*) >= 15
),

scored AS (
    SELECT *,
        -- Opportunity Score: high spend (35%) + low discount dependency (25%) 
        --                  + high loyalty (25%) + subscription rate (15%)
        ROUND((
            (avg_spend         / (SELECT MAX(avg_spend)         FROM location_metrics)) * 0.35 +
            (pct_no_discount   / (SELECT MAX(pct_no_discount)   FROM location_metrics)) * 0.25 +
            (pct_high_loyalty  / (SELECT MAX(pct_high_loyalty)  FROM location_metrics)) * 0.25 +
            (pct_subscribed    / (SELECT MAX(pct_subscribed)    FROM location_metrics)) * 0.15
        ) * 100, 1) AS opportunity_score

    FROM location_metrics
)

SELECT 
    Location,
    customer_count,
    avg_spend,
    total_revenue,
    pct_of_total_revenue,
    avg_previous_purchases,
    pct_no_discount,
    pct_no_promo,
    pct_high_loyalty,
    pct_low_loyalty,
    pct_subscribed,
    avg_rating,
    avg_loyalty_score,
    opportunity_score,

    -- Classification label for Power BI and playbook
    CASE 
        WHEN opportunity_score >= 75 AND pct_of_total_revenue < 5 
            THEN 'High Opportunity — Underlevered'
        WHEN opportunity_score >= 75 AND pct_of_total_revenue >= 5 
            THEN 'Star Market — Already Strong'
        WHEN opportunity_score BETWEEN 50 AND 74 AND pct_no_discount >= 60 
            THEN 'Organic Growth — Nurture'
        WHEN pct_no_discount < 40 AND pct_high_loyalty < 25 
            THEN 'Discount Dependent — Risky'
        ELSE 'Average Market'
    END AS market_classification

FROM scored
ORDER BY opportunity_score DESC; 


-- Part B — Demographic Profile Per Geography (Top 10 States)
WITH top_locations AS (
    SELECT Location
    FROM customer
    GROUP BY Location
    HAVING COUNT(*) >= 15
    ORDER BY AVG(`Purchase Amount (USD)`) DESC
    LIMIT 10
),

demo_profile AS (
    SELECT 
        c.Location,

        -- Age segmentation
        ROUND(AVG(c.Age), 1) AS avg_age,
        ROUND(AVG(CASE WHEN c.Age BETWEEN 18 AND 30 THEN 1 ELSE 0 END) * 100, 1) 
            AS pct_age_18_30,
        ROUND(AVG(CASE WHEN c.Age BETWEEN 31 AND 45 THEN 1 ELSE 0 END) * 100, 1) 
            AS pct_age_31_45,
        ROUND(AVG(CASE WHEN c.Age BETWEEN 46 AND 60 THEN 1 ELSE 0 END) * 100, 1) 
            AS pct_age_46_60,
        ROUND(AVG(CASE WHEN c.Age > 60 THEN 1 ELSE 0 END) * 100, 1) 
            AS pct_age_60_plus,

        -- Gender split
        ROUND(AVG(CASE WHEN c.Gender = 'Male' THEN 1 ELSE 0 END) * 100, 1) 
            AS pct_male,
        ROUND(AVG(CASE WHEN c.Gender = 'Female' THEN 1 ELSE 0 END) * 100, 1) 
            AS pct_female,

        -- Top category in that location
        (
            SELECT Category FROM customer c2
            WHERE c2.Location = c.Location
            GROUP BY Category
            ORDER BY COUNT(*) DESC
            LIMIT 1
        ) AS dominant_category,

        -- Top season in that location
        (
            SELECT Season FROM customer c3
            WHERE c3.Location = c.Location
            GROUP BY Season
            ORDER BY COUNT(*) DESC
            LIMIT 1
        ) AS dominant_season,

        ROUND(AVG(c.`Purchase Amount (USD)`), 2) AS avg_spend,
        ROUND(AVG(c.`Loyalty_Score_Final`), 1) AS avg_loyalty_score

    FROM customer c
    WHERE c.Location IN (SELECT Location FROM top_locations)
    GROUP BY c.Location
)

SELECT * FROM demo_profile
ORDER BY avg_spend DESC;   

-- ques 4---------------------------------------------------------------------------------------------------------------------------------------------------------
SELECT 
    `Loyalty_Tier_Corrected`,
    COUNT(*) AS customer_count,

    -- Spend comparison
    ROUND(AVG(CASE WHEN `Discount Applied` = 'Yes' 
        THEN `Purchase Amount (USD)` END), 2) AS avg_spend_with_discount,
    ROUND(AVG(CASE WHEN `Discount Applied` = 'No'  
        THEN `Purchase Amount (USD)` END), 2) AS avg_spend_without_discount,

    -- Discount lift: how much more (or less) they spend when discount applied
    ROUND((
        AVG(CASE WHEN `Discount Applied` = 'Yes' THEN `Purchase Amount (USD)` END) /
        NULLIF(AVG(CASE WHEN `Discount Applied` = 'No' 
            THEN `Purchase Amount (USD)` END), 0) - 1
    ) * 100, 1) AS discount_lift_pct,

    -- Promo dependency
    ROUND(AVG(CASE WHEN `Discount Applied` = 'Yes' THEN 1 ELSE 0 END) * 100, 1) 
        AS promo_dependency_pct,
    ROUND(AVG(CASE WHEN `Promo Code Used` = 'Yes' THEN 1 ELSE 0 END) * 100, 1) 
        AS promo_code_usage_pct,

    -- Frequency behavior of discount users vs non-discount users
    ROUND(AVG(CASE WHEN `Discount Applied` = 'Yes' AND 
        `Frequency of Purchases` IN ('Weekly','Bi-Weekly','Fortnightly') 
        THEN 1 ELSE 0 END) * 100, 1) AS pct_discount_users_high_freq,
    ROUND(AVG(CASE WHEN `Discount Applied` = 'No' AND 
        `Frequency of Purchases` IN ('Weekly','Bi-Weekly','Fortnightly') 
        THEN 1 ELSE 0 END) * 100, 1) AS pct_nondiscount_users_high_freq,

    -- Tenure & satisfaction
    ROUND(AVG(`Previous Purchases`), 1) AS avg_previous_purchases,
    ROUND(AVG(`Review Rating`), 2) AS avg_review_rating,
    ROUND(AVG(`Loyalty_Score_Final`), 1) AS avg_loyalty_score,

    -- Subscription rate
    ROUND(AVG(CASE WHEN `Subscription Status` = 'Yes' THEN 1 ELSE 0 END) * 100, 1) 
        AS pct_subscribed,

    -- Revenue breakdown
    ROUND(SUM(CASE WHEN `Discount Applied` = 'Yes' 
        THEN `Purchase Amount (USD)` ELSE 0 END), 2) AS revenue_from_discount_users,
    ROUND(SUM(CASE WHEN `Discount Applied` = 'No'  
        THEN `Purchase Amount (USD)` ELSE 0 END), 2) AS revenue_from_nondiscount_users,
    ROUND(SUM(`Purchase Amount (USD)`), 2) AS total_tier_revenue,

    -- Revenue share of discount users within tier
    ROUND(
        SUM(CASE WHEN `Discount Applied` = 'Yes' THEN `Purchase Amount (USD)` ELSE 0 END) * 100.0 /
        NULLIF(SUM(`Purchase Amount (USD)`), 0)
    , 1) AS pct_revenue_from_discount_users,

    -- Margin risk: revenue at risk if discounts removed from this tier
    ROUND(
        SUM(CASE WHEN `Discount Applied` = 'Yes' THEN `Purchase Amount (USD)` ELSE 0 END) * 100.0 /
        SUM(SUM(`Purchase Amount (USD)`)) OVER ()
    , 1) AS pct_of_total_revenue_at_risk,

    -- Strategic action recommendation
    CASE `Loyalty_Tier_Corrected`
        WHEN 'High Loyalty' THEN 
            'Gradually sunset discounts — replace with loyalty rewards & early access'
        WHEN 'Medium Loyalty' THEN 
            'Selective discounts — use only to trigger upgrade behavior, not habitually'
        WHEN 'Low Loyalty' THEN 
            'Test removing discounts — low tenure means low switching cost anyway'
    END AS recommended_action

FROM customer
GROUP BY `Loyalty_Tier_Corrected`
ORDER BY 
    CASE `Loyalty_Tier_Corrected`
        WHEN 'High Loyalty' THEN 1
        WHEN 'Medium Loyalty' THEN 2
        WHEN 'Low Loyalty' THEN 3
    END;

-- ques 5------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Q5: Ideal Customer Profile (High Loyalty tier)
-- Part 1: Core demographic and behavioral profile of ideal customers
SELECT 
    'Ideal Customer (High Loyalty)' AS profile_type,
    COUNT(*) AS customer_count,
    
    -- Demographics
    ROUND(AVG(Age), 1) AS avg_age,
    MIN(Age) AS min_age,
    MAX(Age) AS max_age,
    (SELECT Gender FROM customer WHERE Loyalty_Tier_Corrected = 'High Loyalty' GROUP BY Gender ORDER BY COUNT(*) DESC LIMIT 1) AS primary_gender,
    
    -- Geographic
    (SELECT Location FROM customer WHERE Loyalty_Tier_Corrected = 'High Loyalty' GROUP BY Location ORDER BY COUNT(*) DESC LIMIT 1) AS top_location,
    
    -- Product preferences
    (SELECT Category FROM customer WHERE Loyalty_Tier_Corrected = 'High Loyalty' GROUP BY Category ORDER BY COUNT(*) DESC LIMIT 1) AS top_category,
    (SELECT `Item Purchased` FROM customer WHERE Loyalty_Tier_Corrected = 'High Loyalty' GROUP BY `Item Purchased` ORDER BY COUNT(*) DESC LIMIT 1) AS top_item,
    (SELECT Color FROM customer WHERE Loyalty_Tier_Corrected = 'High Loyalty' GROUP BY Color ORDER BY COUNT(*) DESC LIMIT 1) AS preferred_color,
    (SELECT Season FROM customer WHERE Loyalty_Tier_Corrected = 'High Loyalty' GROUP BY Season ORDER BY COUNT(*) DESC LIMIT 1) AS preferred_season,
    
    -- Payment & shipping
    (SELECT `Payment Method` FROM customer WHERE Loyalty_Tier_Corrected = 'High Loyalty' GROUP BY `Payment Method` ORDER BY COUNT(*) DESC LIMIT 1) AS preferred_payment,
    (SELECT `Shipping Type` FROM customer WHERE Loyalty_Tier_Corrected = 'High Loyalty' GROUP BY `Shipping Type` ORDER BY COUNT(*) DESC LIMIT 1) AS preferred_shipping,
    
    -- Behavioral
    ROUND(AVG(`Purchase Amount (USD)`), 0) AS avg_spend,
    ROUND(AVG(`Previous Purchases`), 1) AS avg_previous_purchases,
    ROUND(AVG(`Review Rating`), 2) AS avg_review_rating,
    ROUND(AVG(CASE WHEN `Subscription Status` = 'Yes' THEN 1 ELSE 0 END) * 100, 1) AS pct_subscribed,
    ROUND(AVG(CASE WHEN `Frequency of Purchases` = 'Weekly' THEN 1 ELSE 0 END) * 100, 1) AS pct_weekly_buyers,
    ROUND(AVG(CASE WHEN `Discount Applied` = 'No' THEN 1 ELSE 0 END) * 100, 1) AS pct_no_discount_needed

FROM customer
WHERE Loyalty_Tier_Corrected = 'High Loyalty'

UNION ALL

-- Part 2: Comparison with Low Loyalty customers (to highlight contrast)
SELECT 
    'Low Loyalty (For Contrast)' AS profile_type,
    COUNT(*) AS customer_count,
    ROUND(AVG(Age), 1) AS avg_age,
    MIN(Age) AS min_age,
    MAX(Age) AS max_age,
    (SELECT Gender FROM customer WHERE Loyalty_Tier_Corrected = 'Low Loyalty' GROUP BY Gender ORDER BY COUNT(*) DESC LIMIT 1) AS primary_gender,
    (SELECT Location FROM customer WHERE Loyalty_Tier_Corrected = 'Low Loyalty' GROUP BY Location ORDER BY COUNT(*) DESC LIMIT 1) AS top_location,
    (SELECT Category FROM customer WHERE Loyalty_Tier_Corrected = 'Low Loyalty' GROUP BY Category ORDER BY COUNT(*) DESC LIMIT 1) AS top_category,
    (SELECT `Item Purchased` FROM customer WHERE Loyalty_Tier_Corrected = 'Low Loyalty' GROUP BY `Item Purchased` ORDER BY COUNT(*) DESC LIMIT 1) AS top_item,
    (SELECT Color FROM customer WHERE Loyalty_Tier_Corrected = 'Low Loyalty' GROUP BY Color ORDER BY COUNT(*) DESC LIMIT 1) AS preferred_color,
    (SELECT Season FROM customer WHERE Loyalty_Tier_Corrected = 'Low Loyalty' GROUP BY Season ORDER BY COUNT(*) DESC LIMIT 1) AS preferred_season,
    (SELECT `Payment Method` FROM customer WHERE Loyalty_Tier_Corrected = 'Low Loyalty' GROUP BY `Payment Method` ORDER BY COUNT(*) DESC LIMIT 1) AS preferred_payment,
    (SELECT `Shipping Type` FROM customer WHERE Loyalty_Tier_Corrected = 'Low Loyalty' GROUP BY `Shipping Type` ORDER BY COUNT(*) DESC LIMIT 1) AS preferred_shipping,
    ROUND(AVG(`Purchase Amount (USD)`), 0) AS avg_spend,
    ROUND(AVG(`Previous Purchases`), 1) AS avg_previous_purchases,
    ROUND(AVG(`Review Rating`), 2) AS avg_review_rating,
    ROUND(AVG(CASE WHEN `Subscription Status` = 'Yes' THEN 1 ELSE 0 END) * 100, 1) AS pct_subscribed,
    ROUND(AVG(CASE WHEN `Frequency of Purchases` = 'Weekly' THEN 1 ELSE 0 END) * 100, 1) AS pct_weekly_buyers,
    ROUND(AVG(CASE WHEN `Discount Applied` = 'No' THEN 1 ELSE 0 END) * 100, 1) AS pct_no_discount_needed

FROM customer
WHERE Loyalty_Tier_Corrected = 'Low Loyalty'; 


-- Q5: Ideal Customer Profile — All 3 tiers for full contrast
-- High Loyalty (Ideal Customer)
SELECT 
    'Ideal Customer (High Loyalty)' AS profile_type,
    COUNT(*) AS customer_count,

    -- Demographics
    ROUND(AVG(Age), 1) AS avg_age,
    MIN(Age) AS min_age,
    MAX(Age) AS max_age,

    (SELECT Gender FROM customer 
     WHERE `Loyalty_Tier_Corrected` = 'High Loyalty' 
     GROUP BY Gender ORDER BY COUNT(*) DESC LIMIT 1) AS primary_gender,

    -- Geographic
    (SELECT Location FROM customer 
     WHERE `Loyalty_Tier_Corrected` = 'High Loyalty' 
     GROUP BY Location ORDER BY COUNT(*) DESC LIMIT 1) AS top_location,

    -- Product preferences
    (SELECT Category FROM customer 
     WHERE `Loyalty_Tier_Corrected` = 'High Loyalty' 
     GROUP BY Category ORDER BY COUNT(*) DESC LIMIT 1) AS top_category,

    (SELECT `Item Purchased` FROM customer 
     WHERE `Loyalty_Tier_Corrected` = 'High Loyalty' 
     GROUP BY `Item Purchased` ORDER BY COUNT(*) DESC LIMIT 1) AS top_item,

    (SELECT Size FROM customer 
     WHERE `Loyalty_Tier_Corrected` = 'High Loyalty' 
     GROUP BY Size ORDER BY COUNT(*) DESC LIMIT 1) AS dominant_size,

    (SELECT Color FROM customer 
     WHERE `Loyalty_Tier_Corrected` = 'High Loyalty' 
     GROUP BY Color ORDER BY COUNT(*) DESC LIMIT 1) AS preferred_color,

    (SELECT Season FROM customer 
     WHERE `Loyalty_Tier_Corrected` = 'High Loyalty' 
     GROUP BY Season ORDER BY COUNT(*) DESC LIMIT 1) AS preferred_season,

    -- Payment & shipping
    (SELECT `Payment Method` FROM customer 
     WHERE `Loyalty_Tier_Corrected` = 'High Loyalty' 
     GROUP BY `Payment Method` ORDER BY COUNT(*) DESC LIMIT 1) AS preferred_payment,

    (SELECT `Shipping Type` FROM customer 
     WHERE `Loyalty_Tier_Corrected` = 'High Loyalty' 
     GROUP BY `Shipping Type` ORDER BY COUNT(*) DESC LIMIT 1) AS preferred_shipping,

    -- Dominant purchase frequency
    (SELECT `Frequency of Purchases` FROM customer 
     WHERE `Loyalty_Tier_Corrected` = 'High Loyalty' 
     GROUP BY `Frequency of Purchases` ORDER BY COUNT(*) DESC LIMIT 1) AS dominant_frequency,

    -- Dominant buyer type (from engineered column)
    (SELECT `Buyer_Type` FROM customer 
     WHERE `Loyalty_Tier_Corrected` = 'High Loyalty' 
     GROUP BY `Buyer_Type` ORDER BY COUNT(*) DESC LIMIT 1) AS dominant_buyer_type,

    -- Behavioral metrics
    ROUND(AVG(`Purchase Amount (USD)`), 0) AS avg_spend,
    ROUND(AVG(`Previous Purchases`), 1) AS avg_previous_purchases,
    ROUND(AVG(`Review Rating`), 2) AS avg_review_rating,
    ROUND(AVG(`Loyalty_Score_Final`), 1) AS avg_loyalty_score,

    ROUND(AVG(CASE WHEN `Subscription Status` = 'Yes' THEN 1 ELSE 0 END) * 100, 1) 
        AS pct_subscribed,
    ROUND(AVG(CASE WHEN `Frequency of Purchases` = 'Weekly' THEN 1 ELSE 0 END) * 100, 1) 
        AS pct_weekly_buyers,
    ROUND(AVG(CASE WHEN `Discount Applied` = 'No' THEN 1 ELSE 0 END) * 100, 1) 
        AS pct_no_discount_needed,
    ROUND(AVG(CASE WHEN `Promo Code Used` = 'No' THEN 1 ELSE 0 END) * 100, 1) 
        AS pct_no_promo_needed

FROM customer
WHERE `Loyalty_Tier_Corrected` = 'High Loyalty'

UNION ALL

-- Medium Loyalty (Growth Target)
SELECT 
    'Growth Target (Medium Loyalty)' AS profile_type,
    COUNT(*),
    ROUND(AVG(Age), 1), MIN(Age), MAX(Age),
    (SELECT Gender FROM customer WHERE `Loyalty_Tier_Corrected` = 'Medium Loyalty' 
     GROUP BY Gender ORDER BY COUNT(*) DESC LIMIT 1),
    (SELECT Location FROM customer WHERE `Loyalty_Tier_Corrected` = 'Medium Loyalty' 
     GROUP BY Location ORDER BY COUNT(*) DESC LIMIT 1),
    (SELECT Category FROM customer WHERE `Loyalty_Tier_Corrected` = 'Medium Loyalty' 
     GROUP BY Category ORDER BY COUNT(*) DESC LIMIT 1),
    (SELECT `Item Purchased` FROM customer WHERE `Loyalty_Tier_Corrected` = 'Medium Loyalty' 
     GROUP BY `Item Purchased` ORDER BY COUNT(*) DESC LIMIT 1),
    (SELECT Size FROM customer WHERE `Loyalty_Tier_Corrected` = 'Medium Loyalty' 
     GROUP BY Size ORDER BY COUNT(*) DESC LIMIT 1),
    (SELECT Color FROM customer WHERE `Loyalty_Tier_Corrected` = 'Medium Loyalty' 
     GROUP BY Color ORDER BY COUNT(*) DESC LIMIT 1),
    (SELECT Season FROM customer WHERE `Loyalty_Tier_Corrected` = 'Medium Loyalty' 
     GROUP BY Season ORDER BY COUNT(*) DESC LIMIT 1),
    (SELECT `Payment Method` FROM customer WHERE `Loyalty_Tier_Corrected` = 'Medium Loyalty' 
     GROUP BY `Payment Method` ORDER BY COUNT(*) DESC LIMIT 1),
    (SELECT `Shipping Type` FROM customer WHERE `Loyalty_Tier_Corrected` = 'Medium Loyalty' 
     GROUP BY `Shipping Type` ORDER BY COUNT(*) DESC LIMIT 1),
    (SELECT `Frequency of Purchases` FROM customer WHERE `Loyalty_Tier_Corrected` = 'Medium Loyalty' 
     GROUP BY `Frequency of Purchases` ORDER BY COUNT(*) DESC LIMIT 1),
    (SELECT `Buyer_Type` FROM customer WHERE `Loyalty_Tier_Corrected` = 'Medium Loyalty' 
     GROUP BY `Buyer_Type` ORDER BY COUNT(*) DESC LIMIT 1),
    ROUND(AVG(`Purchase Amount (USD)`), 0),
    ROUND(AVG(`Previous Purchases`), 1),
    ROUND(AVG(`Review Rating`), 2),
    ROUND(AVG(`Loyalty_Score_Final`), 1),
    ROUND(AVG(CASE WHEN `Subscription Status` = 'Yes' THEN 1 ELSE 0 END) * 100, 1),
    ROUND(AVG(CASE WHEN `Frequency of Purchases` = 'Weekly' THEN 1 ELSE 0 END) * 100, 1),
    ROUND(AVG(CASE WHEN `Discount Applied` = 'No' THEN 1 ELSE 0 END) * 100, 1),
    ROUND(AVG(CASE WHEN `Promo Code Used` = 'No' THEN 1 ELSE 0 END) * 100, 1)

FROM customer
WHERE `Loyalty_Tier_Corrected` = 'Medium Loyalty'

UNION ALL

-- Low Loyalty (For Contrast)
SELECT 
    'Low Loyalty (Contrast)' AS profile_type,
    COUNT(*),
    ROUND(AVG(Age), 1), MIN(Age), MAX(Age),
    (SELECT Gender FROM customer WHERE `Loyalty_Tier_Corrected` = 'Low Loyalty' 
     GROUP BY Gender ORDER BY COUNT(*) DESC LIMIT 1),
    (SELECT Location FROM customer WHERE `Loyalty_Tier_Corrected` = 'Low Loyalty' 
     GROUP BY Location ORDER BY COUNT(*) DESC LIMIT 1),
    (SELECT Category FROM customer WHERE `Loyalty_Tier_Corrected` = 'Low Loyalty' 
     GROUP BY Category ORDER BY COUNT(*) DESC LIMIT 1),
    (SELECT `Item Purchased` FROM customer WHERE `Loyalty_Tier_Corrected` = 'Low Loyalty' 
     GROUP BY `Item Purchased` ORDER BY COUNT(*) DESC LIMIT 1),
    (SELECT Size FROM customer WHERE `Loyalty_Tier_Corrected` = 'Low Loyalty' 
     GROUP BY Size ORDER BY COUNT(*) DESC LIMIT 1),
    (SELECT Color FROM customer WHERE `Loyalty_Tier_Corrected` = 'Low Loyalty' 
     GROUP BY Color ORDER BY COUNT(*) DESC LIMIT 1),
    (SELECT Season FROM customer WHERE `Loyalty_Tier_Corrected` = 'Low Loyalty' 
     GROUP BY Season ORDER BY COUNT(*) DESC LIMIT 1),
    (SELECT `Payment Method` FROM customer WHERE `Loyalty_Tier_Corrected` = 'Low Loyalty' 
     GROUP BY `Payment Method` ORDER BY COUNT(*) DESC LIMIT 1),
    (SELECT `Shipping Type` FROM customer WHERE `Loyalty_Tier_Corrected` = 'Low Loyalty' 
     GROUP BY `Shipping Type` ORDER BY COUNT(*) DESC LIMIT 1),
    (SELECT `Frequency of Purchases` FROM customer WHERE `Loyalty_Tier_Corrected` = 'Low Loyalty' 
     GROUP BY `Frequency of Purchases` ORDER BY COUNT(*) DESC LIMIT 1),
    (SELECT `Buyer_Type` FROM customer WHERE `Loyalty_Tier_Corrected` = 'Low Loyalty' 
     GROUP BY `Buyer_Type` ORDER BY COUNT(*) DESC LIMIT 1),
    ROUND(AVG(`Purchase Amount (USD)`), 0),
    ROUND(AVG(`Previous Purchases`), 1),
    ROUND(AVG(`Review Rating`), 2),
    ROUND(AVG(`Loyalty_Score_Final`), 1),
    ROUND(AVG(CASE WHEN `Subscription Status` = 'Yes' THEN 1 ELSE 0 END) * 100, 1),
    ROUND(AVG(CASE WHEN `Frequency of Purchases` = 'Weekly' THEN 1 ELSE 0 END) * 100, 1),
    ROUND(AVG(CASE WHEN `Discount Applied` = 'No' THEN 1 ELSE 0 END) * 100, 1),
    ROUND(AVG(CASE WHEN `Promo Code Used` = 'No' THEN 1 ELSE 0 END) * 100, 1)

FROM customer
WHERE `Loyalty_Tier_Corrected` = 'Low Loyalty';