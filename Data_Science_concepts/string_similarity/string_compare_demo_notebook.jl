### A Pluto.jl notebook ###
# v0.19.22

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ e9e26fe7-a170-4481-941a-749f3a20bb2a
using PlutoUI;

# ╔═╡ 25fc2f12-8a34-11ed-00af-b19ec1200616
include("string_similarity.jl");

# ╔═╡ 2954b96f-5204-476c-a5ff-acf6d002bfe4
md"
# Interactive Demo of a custom text fuzzy-matching algorithm
"

# ╔═╡ 7b2ba05a-37f9-480f-81df-fe63c521c27d
md"## "

# ╔═╡ ad9160a4-8d0a-4ce8-9994-64b49474ff6a
TableOfContents()

# ╔═╡ 0b728942-74b1-4e3a-bed6-4e69b0407842
# naive equality, after stripping out spaces and standardizing letter-case
function heuristic_isequal(s1, s2)::Float64
	s1 = uppercase(replace(s1, " " => "")) 
	s2 = uppercase(replace(s2, " " => "")) 
	return isequal(s1, s2)
end 

# ╔═╡ 3799d6a3-8e7a-44a7-b8a0-5d25202d52e7
# Jaccard Similarity = |intersection of characters| / |union of characters|
#  debatable whether the pre-processing of text to be standard improves the signal-to-noise, or hinders it for this algorithm
function jaccard_similarity(s1, s2)::Float64 
	s1 = uppercase(replace(s1, " " => "")) 
	s2 = uppercase(replace(s2, " " => "")) 
	return round(length(intersect(Set(s1), Set(s2))) / length(union(Set(s1), Set(s2))), digits=3)
end

# ╔═╡ 97999dd8-6f8d-45fa-8529-9d35163a1950
# intended as a true-positive match, expect high similarity
example_a = ["42 - 123 HelloWorld Ave, Waterloo ON, A2C 4E6", "Unit 42 123 Hello World Avenue Waterloo ON A2C4E6"]

# ╔═╡ 1a0ed19b-c3c2-488a-88bd-98888a4979b1
isequal(example_a[1], example_a[2])

# ╔═╡ 12600847-14df-4f4a-ba88-666427aed4af
heuristic_isequal(example_a[1], example_a[2])

# ╔═╡ 553e7611-96c5-41df-878b-0d61cb6d2933
jaccard_similarity(example_a[1], example_a[2])

# ╔═╡ 4a7e55e6-542e-4a7d-b044-73fdc6edf8a4
string_compare(example_a[1], example_a[2])

# ╔═╡ 12cc9658-62b8-4220-a45d-d876d1db33e5
md"
Here is an illustrative example of the use case for this string-comparison algorithm, and some of the issues that are addressed by the design.

In just about any digital context, the two text strings from example_a are not equal. But, if asked whether or not those strings represent the same thing, or specifically in the case of the problem that motivated this algorithm 'do these two text representations refer to the same mailing address?' most human readers can say there is a high degree of confidence that they would in fact consider them as the same mailing address.

My goal was to create a general-purpose tool that could accelerate an existing manual-review process for duplicate addresses between two systems where the digital representations were often not 'equal' in the trivial sense, but where there was a high incidence of duplicates that were just slightly off

Algorithms such as taking the Jaccard Similarity (used for Power Query fuzzy-joins in Excel) offer a more granular approach to identifying similar text compared to the binary equal/not-equal operators without adding an excess of additional complexity. 

My hypothesis was that a better-performing design (in terms of more closely matching human intuition) existed, if I could make use of additional information/assumptions that were part of the context that the manual reviewers were using.
"

# ╔═╡ 66df1064-241d-47ac-b92a-a25fb777d26f
md"# Demonstration"

# ╔═╡ 2ab6c97d-65af-457a-b1da-06ea2d46b664
# standard/concise format for executing comparative examples
function run_test(triplet, fn=string_compare)
	return string("similar pair: ", fn(triplet[1], triplet[2]), 
		" VS differing pair: ", fn(triplet[1], triplet[3]))
end

# ╔═╡ 1f86bf60-68ba-4646-894f-06ef1c578fb0
md"
**How to read the output from string_compare:**
An output of 0 indicates absolutely no similarity, which is incredibly unlikely in practical cases .

A similarity score in the range (0.0, 0.5) indicates very low similarity, where manual reviewers would almost certainly conclude the text is not meaningfully the same

(0.5, 0.8) is a fairly common level of similarity when comparing two valid addresses of the same format, but where a manual review would expect to find there are meaningful differences and conclude the addresses are not the same

Similarity scores above 0.8 indicates fairly high levels of similarity, and in a scenario where actual matches are expected to be abundant, these would be flagged for review (or simply confirmation) 

Similarity equal to 1.0 means an exact match. Cases where this algorithm claims an exact match but a naive equality check does not is due to the basic pre-processing added to the function implementation for convenience of the intended application
"

# ╔═╡ 8f0cb3a5-3802-4bc7-a77f-11f6a293eb71
md"
**A word on pre-processing:** 
By default, string_compare strips out all spaces and ignores case/capitalization. 

For the purpose of characterising the algorithm performance, all further examples will not focus on pre-processing that could be uniformly applied to any method.  

(Note: choosing assumptions/business rules for preprocessing is an extremely important step, even before comparing or choosing algorithms)
"

# ╔═╡ 4b88d235-7e64-4d88-9e28-7980355795b7
# these are all the same, but the naive equality test fails to indicate that
example_b = ["Test String", "TestString", "test string"]

# ╔═╡ ba291ea9-d5de-4d06-b72a-bb9ff57ba934
run_test(example_b, isequal)

# ╔═╡ 5882a15f-0363-4cec-be4a-43a4a4ca82dd
run_test(example_b, heuristic_isequal)

# ╔═╡ 7d2ba81d-38e2-4d0b-bcae-91e016f126f7
run_test(example_b, jaccard_similarity)

# ╔═╡ 65fdccc2-67d8-4f83-a5b6-81d49272aac8
run_test(example_b, string_compare)

# ╔═╡ 7d7af72c-cca3-4540-a15c-ce73d163cfc9
md"
A series of examples consisting of three text strings, the first two should be rated more similar to each other (positive match), but the first and third should be less similar (negative match). 
"

# ╔═╡ dd35dc9d-693f-4365-ac80-afefb58cf5c3
md"Text (strings) that share most characters should be more similar, even if there is an ommission/addition between the pair"

# ╔═╡ 71515660-04ce-400c-97d8-37e366aa6fc5
example_c = ["Thomas", "Tomas", "Data Science"]

# ╔═╡ 980c5721-c897-42b5-8464-ea839102d923
run_test(example_c, string_compare)

# ╔═╡ cf6fd688-13e0-4c48-984b-01cf9eec91dc
run_test(example_c, jaccard_similarity)

# ╔═╡ 072d1b33-d176-4df2-9c2a-f91b1f0f98cc
md"Implicitly, text addresses of a similar length should end up more similar, even if there is substantial overlap in the set of characters"

# ╔═╡ 6c3e6b66-f1fa-4b5d-943a-384c52fcab60
example_d = ["123 King St South Waterloo", "123 King Street S Waterloo", "123 Insurance Boulevard Kingston"]

# ╔═╡ 4d8f0de7-9c35-46ab-b7c4-ec3ca5e81d5c
run_test(example_d, string_compare)

# ╔═╡ 620be601-5953-4baf-9f8b-74d35fe801d3
run_test(example_d, jaccard_similarity)

# ╔═╡ 4ff0967b-8ceb-453f-b6c3-51fd0cdc22a0
md"A 'bag-of-characters' approach like Jaccard without accounting for order is helpful in overlooking minor typos (false-negative matches). But that alone was not sufficiently sensitive for distinguishing actual differences (true-negative matches)"

# ╔═╡ 277f9397-30d1-4ae3-841f-aee4905a9ac6
example_e = ["Katherine", "Kahterine", "Katerinah"]

# ╔═╡ c2503166-68f4-4606-b306-b96a6f1cc9e6
run_test(example_e, string_compare)

# ╔═╡ da2ccc49-9e72-40f3-ac06-a1b1cbc33f50
run_test(example_e, jaccard_similarity)

# ╔═╡ f9c96933-42d7-4a2e-bd06-5f5f5f2c83ff
md"Some concept of order/localized matching must be implemented to better match the perspective of human readers of English. 

As later discussed in more depth, while the motivation included comparing addresses between systems that did not have the same delineation/standardization/formatting of fields, it was valid to assume the parts of the addresses between systems were going to be in the same/similar order within the strings supplied to the function (ie unit, street, city, postal code)
"

# ╔═╡ 0704eb6d-d798-40f6-8ad1-bf4f9eff65f6
example_f = ["the sun life insurance company of canada", "sun the life insurance company of canada", "the life insurance company of canada sun"]

# ╔═╡ 2012d0d7-b376-4c5e-95bd-f62d22849ecf
run_test(example_f, string_compare)

# ╔═╡ 4d32eebb-4e3f-430e-a1e9-d117284c4ccf
run_test(example_f, jaccard_similarity)

# ╔═╡ fa4d9739-f11b-4952-bf2b-38c1b882c5b6
md"
The final implementation included a method for acknowledging matching characters within similar/localized sections between strings, but also penalizing transpositions based on how many characters were out of order, and even disregarding matching characters if they were outside that localized section

This turned out to be highly informative to the manual reviewers, and justified the effort to implement the changes to their workflow. And because there was nothing else available to offer these attributes in the format required, that justified my efforts to implement it (prototyped in Julia when it was a hobby-project, but the real-life application required VBA for use within Excel)
"

# ╔═╡ dd163732-edf5-4e51-8784-a82e50b66d18
md"## Try it!"

# ╔═╡ ffca7ed5-a50e-466a-9c66-b7f35fc1e62d
md"
The expectation is that a better-performing algorithm will rate more-similar pairs higher, and less-similar pairs lower. Further, a well-behaved similarity function will impose less of a penalty as 'less meaningful' changes are added between the compared texts, but changes that substantially change how the text address is interpreted should drastically lower the similarity score.

See if string_compare demonstrates this, based on texts that you consider to be more or less similar.
" 

# ╔═╡ 74dc476d-0e9b-42fa-aaeb-de4b8a6ce750
@bind text_1 TextField(default="Put your example text here")

# ╔═╡ 2e68f87c-dbda-4fe2-9735-35c2cf987ef7
@bind text_2 TextField(default="Put your sample text here.")

# ╔═╡ 65406e88-01ea-4d62-852f-5d41a8e88109
@bind text_3 TextField(default="Enter something else here")

# ╔═╡ 9373b74a-1df5-46fd-9d0d-005996c42a89
interactive_example = [text_1, text_2, text_3]

# ╔═╡ a84817be-5c80-4bd9-9e3c-248693713a69
run_test(interactive_example, string_compare)

# ╔═╡ a0e12250-8941-4bad-9b54-23d752597f0f
run_test(interactive_example, jaccard_similarity)

# ╔═╡ 5ed5ff29-667d-490c-9f8c-9913dddbae56
run_test(interactive_example, heuristic_isequal)

# ╔═╡ 3889985e-df9c-4b28-a059-9ea57993a575
run_test(interactive_example, isequal)

# ╔═╡ c0303bcb-e1b3-4fc1-b912-4b00ebd47cea
md"Modify below code cell to customize string_compare parameters applied to the above example"

# ╔═╡ 15e559aa-c5a7-4f15-8de8-5cbcea6ffbdc
# modify this code to see the influence of different parameters on your examples
run_test(interactive_example,
	(t1, t2) -> string_compare(
		t1, t2, 
		strip=[" ", "-", ",", "."], 
		keep_case=true, 
		ignore_short=2 
	)
)

# ╔═╡ 2eabe02b-1f34-4789-a38d-b4162b47eb84
md"# Algorithm Design In-Depth"

# ╔═╡ 56cb357a-c691-4219-a28c-3b906b514446
md""

# ╔═╡ c040bca6-0c4d-4e35-9647-391576c03ff4
example_a

# ╔═╡ 1c34e642-12a2-4676-b013-82c3cf4a59a1
string_compare(example_a[1], example_a[2], 
	verbose=true, 
	strip=[" ", "-", ",", "Unit"],
	keep_case=false,
	ignore_short=5
)

# ╔═╡ a4c430be-8abb-46b2-87cc-d8e0f5792278
@bind text_1v TextField(default="Try a verbose example")

# ╔═╡ e19b32c0-2850-47d8-b2cd-50dce11fb054
@bind text_2v TextField(default="Try a non-concise example")

# ╔═╡ 57839a61-dcba-48d0-af26-f21b438488cd
@bind text_3v TextField(default="Or not")

# ╔═╡ e7fef134-455f-44ba-b19a-d81ea9a04f23
begin
	interactive_example_v = [text_1v, text_2v, text_3v]
	run_test(interactive_example_v, string_compare)
end

# ╔═╡ 7dbe3461-dbc8-429b-9a57-884af4dfbf18
string_compare(text_1v, text_2v, 
	verbose=true, 
	strip=[" "],
	keep_case=false,
	ignore_short=4
)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"

[compat]
PlutoUI = "~0.7.49"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.5"
manifest_format = "2.0"
project_hash = "08cc58b1fbde73292d848136b97991797e6c5429"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.1+0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MIMEs]]
git-tree-sha1 = "65f28ad4b594aebe22157d6fac869786a255b7eb"
uuid = "6c6e2e6c-3030-632d-7369-2d6c69616d65"
version = "0.1.4"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.2.1"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[deps.Parsers]]
deps = ["Dates", "SnoopPrecompile"]
git-tree-sha1 = "6466e524967496866901a78fca3f2e9ea445a559"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.5.2"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "FixedPointNumbers", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "MIMEs", "Markdown", "Random", "Reexport", "URIs", "UUIDs"]
git-tree-sha1 = "eadad7b14cf046de6eb41f13c9275e5aa2711ab6"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.49"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SnoopPrecompile]]
git-tree-sha1 = "f604441450a3c0569830946e5b33b78c928e1a85"
uuid = "66db9d55-30c0-4569-8b51-7e840670fc0c"
version = "1.0.1"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.Tricks]]
git-tree-sha1 = "6bac775f2d42a611cdfcd1fb217ee719630c4175"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.6"

[[deps.URIs]]
git-tree-sha1 = "ac00576f90d8a259f2c9d823e91d1de3fd44d348"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.4.1"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+3"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.1+0"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"
"""

# ╔═╡ Cell order:
# ╟─2954b96f-5204-476c-a5ff-acf6d002bfe4
# ╠═7b2ba05a-37f9-480f-81df-fe63c521c27d
# ╠═e9e26fe7-a170-4481-941a-749f3a20bb2a
# ╠═25fc2f12-8a34-11ed-00af-b19ec1200616
# ╠═ad9160a4-8d0a-4ce8-9994-64b49474ff6a
# ╠═0b728942-74b1-4e3a-bed6-4e69b0407842
# ╠═3799d6a3-8e7a-44a7-b8a0-5d25202d52e7
# ╟─97999dd8-6f8d-45fa-8529-9d35163a1950
# ╠═1a0ed19b-c3c2-488a-88bd-98888a4979b1
# ╠═12600847-14df-4f4a-ba88-666427aed4af
# ╠═553e7611-96c5-41df-878b-0d61cb6d2933
# ╠═4a7e55e6-542e-4a7d-b044-73fdc6edf8a4
# ╟─12cc9658-62b8-4220-a45d-d876d1db33e5
# ╟─66df1064-241d-47ac-b92a-a25fb777d26f
# ╠═2ab6c97d-65af-457a-b1da-06ea2d46b664
# ╟─1f86bf60-68ba-4646-894f-06ef1c578fb0
# ╟─8f0cb3a5-3802-4bc7-a77f-11f6a293eb71
# ╠═4b88d235-7e64-4d88-9e28-7980355795b7
# ╠═ba291ea9-d5de-4d06-b72a-bb9ff57ba934
# ╠═5882a15f-0363-4cec-be4a-43a4a4ca82dd
# ╠═7d2ba81d-38e2-4d0b-bcae-91e016f126f7
# ╠═65fdccc2-67d8-4f83-a5b6-81d49272aac8
# ╟─7d7af72c-cca3-4540-a15c-ce73d163cfc9
# ╟─dd35dc9d-693f-4365-ac80-afefb58cf5c3
# ╠═71515660-04ce-400c-97d8-37e366aa6fc5
# ╠═980c5721-c897-42b5-8464-ea839102d923
# ╠═cf6fd688-13e0-4c48-984b-01cf9eec91dc
# ╟─072d1b33-d176-4df2-9c2a-f91b1f0f98cc
# ╠═6c3e6b66-f1fa-4b5d-943a-384c52fcab60
# ╠═4d8f0de7-9c35-46ab-b7c4-ec3ca5e81d5c
# ╠═620be601-5953-4baf-9f8b-74d35fe801d3
# ╟─4ff0967b-8ceb-453f-b6c3-51fd0cdc22a0
# ╠═277f9397-30d1-4ae3-841f-aee4905a9ac6
# ╠═c2503166-68f4-4606-b306-b96a6f1cc9e6
# ╠═da2ccc49-9e72-40f3-ac06-a1b1cbc33f50
# ╟─f9c96933-42d7-4a2e-bd06-5f5f5f2c83ff
# ╠═0704eb6d-d798-40f6-8ad1-bf4f9eff65f6
# ╠═2012d0d7-b376-4c5e-95bd-f62d22849ecf
# ╠═4d32eebb-4e3f-430e-a1e9-d117284c4ccf
# ╟─fa4d9739-f11b-4952-bf2b-38c1b882c5b6
# ╟─dd163732-edf5-4e51-8784-a82e50b66d18
# ╟─ffca7ed5-a50e-466a-9c66-b7f35fc1e62d
# ╟─74dc476d-0e9b-42fa-aaeb-de4b8a6ce750
# ╟─2e68f87c-dbda-4fe2-9735-35c2cf987ef7
# ╟─65406e88-01ea-4d62-852f-5d41a8e88109
# ╟─9373b74a-1df5-46fd-9d0d-005996c42a89
# ╠═a84817be-5c80-4bd9-9e3c-248693713a69
# ╠═a0e12250-8941-4bad-9b54-23d752597f0f
# ╠═5ed5ff29-667d-490c-9f8c-9913dddbae56
# ╠═3889985e-df9c-4b28-a059-9ea57993a575
# ╟─c0303bcb-e1b3-4fc1-b912-4b00ebd47cea
# ╠═15e559aa-c5a7-4f15-8de8-5cbcea6ffbdc
# ╟─2eabe02b-1f34-4789-a38d-b4162b47eb84
# ╟─56cb357a-c691-4219-a28c-3b906b514446
# ╟─c040bca6-0c4d-4e35-9647-391576c03ff4
# ╠═1c34e642-12a2-4676-b013-82c3cf4a59a1
# ╟─a4c430be-8abb-46b2-87cc-d8e0f5792278
# ╟─e19b32c0-2850-47d8-b2cd-50dce11fb054
# ╟─57839a61-dcba-48d0-af26-f21b438488cd
# ╟─e7fef134-455f-44ba-b19a-d81ea9a04f23
# ╠═7dbe3461-dbc8-429b-9a57-884af4dfbf18
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
