import requests as rq 
import bs4 as bsoup 



##################################################
# configs


tng_src_url = "https://www.tangerine.ca/en/rates/historical-rates"
tng_target_class = "list--withTextRight margin__t--fix2 is-hidden"
tng_target_series = [
    "mortgage5yrfixed", 
    "mortgage5yrvariable", 
    "ingprimerate", 
    "gic1yr", 
]


##################################################
# core logic

tng_page = rq.get(tng_src_url)
bs_obj = bsoup.BeautifulSoup(tng_page.content, "html.parser") 
tng_content = bs_obj.find(id="mainContentSection") 
tng_targets = {ts: 
    tng_content.find('div', 
        attrs={
            'data-toggle': 'historical-rate', 
            'data-type': ts
        }) 
    for ts in tng_target_series}

lines = [] 
for k in tng_targets.keys(): 
    lli = tng_targets[k].findAll('li', attr={'class': "list--withTextRight__listItem"})
    for li in lli: 
        tng_line = (
            k, 
            li.find('span', attr={'class': 'list--withTextRight__itemContent'}), 
            li.find('span', attr={'class': 'list--withTextRight__value'})
        ) 
        print(tng_line)
        lines += [tng_line]

lines


tng_targets['ingprimerate'].prettify()

.find('ul', attr={'class': "list--withTextRight__uList"})

.find('li', attr={'class': "list--withTextRight__listItem"})
