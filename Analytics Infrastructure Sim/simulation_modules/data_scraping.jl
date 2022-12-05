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
    "mortgage5yrfixed", 
    "mortgage5yrvariable", 
    "ingprimerate", 
    "gic1yr", 
]

rq = HTTP.get(tng_src_url)
rq_parsed = parsehtml(String(rq.body)).root
rq_parsed[2]
fieldnames(typeof(rq_parsed))

for elem in PreOrderDFS(rq_parsed)
    try 
        if tag(elem) == :div && elem.attributes["data-type"] == "mortgage5yrvariable"
            println(elem)
        end
    catch
    end
end

# return first of list (of 1) of divs matching data-type
s1 = h -> eachmatch(sel"div[data-type*=mortgage5yr] > ul", h); 
ulist = s1(rq_parsed)[1] # returns one ul

tag(ulist) == :ul && ulist.attributes["class"] == "list--withTextRight__uList"

s2 = h -> eachmatch(sel"li", h)
listitems = s2(ulist)[1] # returns two span
fieldnames(typeof(listitems))

print(listitems.children[1]::HTMLNode)

tag(listitems[1]) == :span && 
println(AbstractTrees.children(listitems)[1])


section[1].attributes
