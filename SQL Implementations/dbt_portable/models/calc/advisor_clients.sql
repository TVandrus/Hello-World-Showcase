
select 
    a.adv_id 
    , a.adv_name 
    , c.clt_id 
    , c.clt_name 
    , b.cont_id 
    , b.cont_date
from {{ source('src_seed', 'a_advisor') }} as a 
    join {{ source('src_seed', 'b_contract') }} as b 
        on b.cont_adv_id = a.adv_id 
    join {{ source('src_seed', 'c_client') }} as c 
        on c.clt_id = b.cont_own_id 
