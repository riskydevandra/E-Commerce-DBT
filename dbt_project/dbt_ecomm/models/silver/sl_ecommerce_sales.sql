{{ config(materialized = 'table')}}


with cleaned as (
    select 
        transaction_id,
        cast(order_date as date) as order_date,
        customer_id,
        customer_name,
        CASE
        WHEN country IN ('US', 'UK', 'IN', 'DE', 'FR', 'CA', 'AU') THEN country
                ELSE 'Unknown'
            END AS country,
            product_id,
            product_category,
            CASE
                WHEN quantity > 0 THEN quantity
                ELSE 1
            END AS quantity,
            CASE
                WHEN price > 0 THEN price
                ELSE 0
            END AS price,
            order_status
        FROM {{ ref('br_ecommerce_sales') }}
        WHERE customer_id IS NOT NULL
            AND CAST(order_date AS DATE) <= CURRENT_DATE
),

deduplicated as (
    select *,
        row_number() over (partition by transaction_id order by order_date desc) as rn
    from cleaned
)

select *
from deduplicated
where rn = 1