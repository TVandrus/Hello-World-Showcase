
select 
    a.adv_id 
    , a.adv_name 
    , b.cont_id 
    , b.cont_date
    , b.cont_amt 
    , b.cont_prod_id 
from {{ source('src_seed', 'a_advisor') }} as a 
    join {{ source('src_seed', 'b_contract') }} as b 
        on b.cont_adv_id = a.adv_id 
