#=
scrape updated interest rate info from web pages
store in tabular format
generate updating graphics
=#
using Gumbo, Cascadia, HTTP, AbstractTrees
using Pluto, Plots 


# configs 
tng_src_url = "https://www.tangerine.ca/en/rates/historical-rates"; 
tng_target_series = [
    "isacad", 
    #"mortgage5yrfixed", 
    #"mortgage5yrvariable", 
    #"ingprimerate", 
    #"gic1yr", 
]

rq = HTTP.get(tng_src_url)
rq_parsed = parsehtml(String(rq.body)).root # :HTML
rq_parsed[2] # :body 
fieldnames(typeof(rq_parsed))
rq_parsed[2].children[7].children[2].children[1].children[1].children[1].children[3].children[2].children[1].children[1].children[1]

for elem in PreOrderDFS(rq_parsed)
    try 
        if tag(elem) == :div && elem.attributes["data-type"] == "mortgage5yrvariable"
            println(elem)
        end
    catch
    end
end

# return first of list (of 1) of divs matching data-type
s1 = h -> eachmatch(sel"div[data-type*=isacad]", h); 
ulist = s1(rq_parsed[2])[1] # returns one :ul

tag(ulist) == :ul && ulist.attributes["class"] == "list--withTextRight__uList"

s2 = h -> eachmatch(sel"li", h)
listitems = s2(ulist)[1] # returns two span
fieldnames(typeof(listitems.children[1]))

print(listitems.children)
print(listitems.children[1])

/html/body/div/section[2]/div/div/div[1]/div[2]/div[1]/ul/li[2]/span[1]
<span class="list--withTextRight__itemContent">July 1, 2022</span>


target = sel"#mainContentSection > div > div > div.viewport--padded > div.body--2.viewport--full > div:nth-child(2) > ul > li:nth-child(1)"
s3 = h -> eachmatch(target, h)
elem = s3(rq_parsed)

println(AbstractTrees.children(listitems)[1])
