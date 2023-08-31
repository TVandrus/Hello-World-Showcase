
select 
    e.prod_id
    , e.prod_name as product 
    , YEAR(b.cont_date) as r_year 
    , MONTH(b.cont_date) as r_month 
    , count(b.cont_id) as total_contracts
    , sum(b.cont_amt) as total_amt
from {{ source('src_seed', 'b_contract') }} as b 
    join {{ source('src_seed', 'e_product') }} as e 
        on e.prod_id = b.cont_prod_id 
group by 
    e.prod_id 
    , e.prod_name 
    , YEAR(b.cont_date) 
    , MONTH(b.cont_date) 
order by r_year, r_month, product 
