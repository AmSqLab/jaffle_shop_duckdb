-- Test to verify that there are no negative order amounts
-- This test should return 0 rows if all orders have non-negative amounts
-- If any orders have negative amounts, this test will fail
# sq
select 
    order_id,
    customer_id,
    amount
from {{ ref('orders') }} 
where amount < 0
