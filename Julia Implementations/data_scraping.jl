#=
scrape updated interest rate info from web pages
store in tabular format
generate updating graphics
=#
using Gumbo, Cascadia, HTTP, AbstractTrees
using Pluto, Plots 


mcu_src_url = "https://www.meridiancu.ca/personal/rates-and-fees";

mcu_targets = [
    "mortgages"=>"/html/body/main/section[1]/div/div[2]/div[2]",
    "gics"=>"/html/body/main/section[1]/div/div[3]/div[2]"
]
rq = HTTP.get(mcu_src_url);
rq_parsed = parsehtml(String(rq.body)).root; # :HTML
node = rq_parsed[2]; # :body 
node = node[2][3][1] # main/section/div

dataset = [];

# fixed mortgages
table = node[3][2][1][2][1][1][2].children
for row in table
    content = (product=row[3][1].text, posted=row[1][1].text, special=row[2][1].text)
    push!(dataset, content);
end

# variable 
table = node[3][2][4][2][1][1][2].children
for row in table
    content = (product=row[2][1].text, posted=row[1][1].text)
    push!(dataset, content);
end

#GICs 
table = node[4][2].children
row = table[2]
record = row[2][1][2][2][1].children
record[2][1].text
for row in table[[1,2,8,11]]
    record = row[2][1][2][2][1].children
    content = (product=record[2][1].text, posted=record[1][1].text)
    push!(dataset, content);
end

dataset


tng_src_url = "https://www.tangerine.ca/en/rates/mortgage-rates"; 

#prime rate 
#/html/body/div/section/section/div[2]/div[1]/div/div/h3/span

rq = HTTP.get(tng_src_url);
rq_parsed = parsehtml(String(rq.body)).root[2] # :body 

for ele in PreOrderDFS(rq_parsed)
    try
        if tag(ele) == :span 
            println(ele)
            if attr(ele)["data-toggle"] == "rate"
                println("!!!!!")
            end
        end
    catch
    end
end


#prime
primerate = rq_parsed[7][1][1][2]
node = primerate[1][1][1][1][2].attributes
nodevalue(node)

<span data-toggle="rate" data-type="mortgage5yrvarlatest">6.65%</span>
<span data-toggle="rate" data-type="mortgage5yrvarlatest">6.65%</span>
#\35 yearvarblock > div.rate > span
document.querySelector("#\\35 yearvarblock > div.rate > span")
//*[@id="5yearvarblock"]/div[2]/span
/html/body/div/section/section/div[3]/div[1]/div[2]/div[1]/div[2]/span

nodelist = rq_parsed.children
nodelist[7][1][1][2][1][1][1][1][2]