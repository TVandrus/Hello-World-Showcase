### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# ╔═╡ 2ec300af-39f4-4260-9085-1510d4fdf3cc
using Random, Distributions

# ╔═╡ aad8bbac-a980-4685-9561-3d0fd2989596
md"""# Simulated Causal process 

Goal: design a non-trivial process to generate data suitable for testing methods of recovering the causal effects
"""

# ╔═╡ 9930c5c3-78fb-45b7-8ed0-2c45da32e894
md"""## Plain-language design:

- process modelled around archery marksmanship 
- outcomes are based on external deterministic factors (physics), individual deterministic factors (stats), and some random variation
- disclaimer: I know next to nothing about archery
- disclaimer: physics will be a guide, but simplified and the numbers rounded to make them suit my personal preferences

"""

# ╔═╡ 6c73c7f0-46f8-4199-b279-dd32f5c732d6
md"""### Output values
- distance of actual-landed from exact-target location as a target-variable for regression
- binary label of whether or not the actual-landed location is within a given distance to constitute a 'bull's-eye' as a target-variable for discrete classification
"""

# ╔═╡ ca0f0b7a-fac8-4c00-a77d-2360e71f8089
md"""### Visible/Direct Input factors
- range from archer to target in metres
- ideal draw-weight of bow in Newtons
- draw-strength of archer in Newtons
- mass of arrow in grams
- wind in metres per second
- experience (proxy for baseline random deviation) 
- bull's-eye threshold

### Hidden/Underlying model 
- constant assumed draw length 0.75m
- accuracy threshold:
    - 4cm at 20m
    - 8cm at 40m
    - 12cm 60+m
    -> 2cm accuracy per 10m range for bull's eye

### Derived/Interaction factors
- actual draw = min(archer, bow)
- arrow speed m/s = sqrt(actual_draw N * 0.75m / arrow_mass g *0.001)
- flight time s = range m / arrow_speed m/s
- wind deviation increases for longer flight time, increases w higher wind speed, scaled by aerodynamic constant, reduced with higher arrow mass
- wind deviation m = flight_time s * wind_speed (m/s) * 0.10 * (40 g / arrow_mass g)
- distance deviation = flight_time s * 20 cm
- expected error: Normal(0, deviation * correction cm)
- experience correction factor: 
    - expert: scale corrected deviation by 0.8
    - competent: scale corrected deviation by 1.0
    - beginner: scale corrected deviation by 1.5
"""

# ╔═╡ e6594fab-02dc-4194-a150-d9513f305f20
md"""### Score intuition check
- shooting 50m @100m/s -> deviation to correct = 10cm
- bull's eye accuracy @50m = 10cm
- Normal(0, 10*0.8) will be within 10cm for ~79% of the time for expert

- shooting 30m @85m/s -> 7cm correction
- bull's eye accuracy @30m = 6cm
- Normal(0, 7*1.0) within 6cm ~60% of the time for competent

- shooting 20m @75m/s -> 5cm correction
- bull's eye accuracy @20m = 4cm
- Normal(0, 5*1.5 ) within 4cm ~40% of the time for beginner

### Baseline scenario and ranges: 
- range 30m (20m - 90m)
- bow draw 267N (175N - 350N)
- archer draw 300N (175N - 400N)
- arrow mass 25g (20g - 35g)
- arrow speed 90m/s (75m/s - 110m/s)
- wind 1m/s (0m/s - 5.5m/s)
- experience: competent (beginner-competent-expert)

"""

# ╔═╡ 807937c1-303c-42fe-a5ff-2738f020d917
md"""## Causal graph visualized

```mermaid
---
title: "Graph 1 - the causal graph for the Archer's Marksmanship process"
---
%% TD = Top-Down
graph LR 
    wind --> wind_dev
    wind_dev --> wind_acc
    experience --> dist_acc
    experience --> wind_acc
    wind_acc --> accuracy
    flight_time --> dist_dev
    arrow_speed --> flight_time
    arrow_mass --> arrow_speed
    arrow_mass --> wind_dev
    actual_draw --> arrow_speed
    bow_draw --> actual_draw
    archer_draw --> actual_draw
    flight_time --> wind_dev
    range --> flight_time
    dist_dev --> dist_acc
    dist_acc --> precision
    precision --> hit_or_miss
    range --> prec_threshold
    prec_threshold --> hit_or_miss
    ;
```
"""

# ╔═╡ b3d0cb00-5a51-11ee-08e0-a3dcb370ec41
md"""## Implementation to simulate data """

# ╔═╡ dea5b5fc-19d5-4097-8769-a1c86357f019
md"""success\_rate = 1 - cdf(Normal(0, deviation * correction), -acc_threshold) * 2"""

# ╔═╡ c569fd2c-113b-414b-96b4-17b9447635a9
begin
	# implement rules & logic
	
	DRAW_LEN = 0.75; # 0.75m draw length
	AERO_COEF = 0.10 * 40; # deviation of 10% of wind for 40g arrow
	DIST_COEF = 20;
	
	actual_draw(archer, bow) = min(archer, bow);
	arrow_speed(draw, mass) = sqrt(draw * DRAW_LEN * 1000 / mass);
	flight_time(range, speed) = (range / speed);
	wind_deviation(wind, time, mass) = wind * time * AERO_COEF / mass;
	dist_deviation(time) = time * DIST_COEF;
	corrected_deviation(dev, skill_value) = rand(Normal(0, dev * skill_value)); 
	check_bound(range, dev) = dev <= (2 * range/10);
end

# ╔═╡ e85c4758-97c9-4c27-9a3c-3d96b0f5f665
begin
	# set parameters for a simulation
	
	# Archer parameters 
	bow_draw_lim = 175:25:350;
	archer_draw_lim = 175:400;
	experience = Dict(
	    :novice => 1.5, 
	    :intermediate => 1.0, 
	    :expert => 0.8
	);
	
	# Shot parameters
	range_lim = 20:10:90;
	arrow_mass_lim = 20:3:35;
	wind = Exponential(1.5);
end

# ╔═╡ e15d56db-b9c7-4976-bacd-bea13f9cc5b9
begin
	struct Archer
	    exp_level::Symbol
	    strength::Int
	    bow_draw::Int
	end
	
	struct Shot
	    range::Int
	    arrow_mass::Int
	    wind::Number
	end

	gen_archer()::Archer = Archer(
	    rand(keys(experience)), 
	    rand(archer_draw_lim),
	    rand(bow_draw_lim)
	)

	gen_shot()::Shot = Shot(
	    rand(range_lim),
	    rand(arrow_mass_lim), 
	    round(rand(wind), digits=1)
	)
end

# ╔═╡ 006eab5f-8756-40e4-8329-dfea600ac2b9
function shoot(a::Archer, s::Shot) 
    ft = flight_time(s.range, arrow_speed(actual_draw(a.strength, a.bow_draw
		), s.arrow_mass)) 
    d_dev = corrected_deviation(dist_deviation(ft), experience[a.exp_level]) 
    w_dev =corrected_deviation(wind_deviation(s.wind, ft, s.arrow_mass), experience[a.exp_level]) 
    return (
        skill = a.exp_level, 
        strength = a.strength, 
        bow = a.bow_draw, 
        range = s.range, 
        arrow = s.arrow_mass, 
        wind = s.wind, 
        precision = round(sqrt((d_dev ^ 2) + (w_dev ^ 2)), digits=4), 
        score = check_bound(s.range, sqrt((d_dev ^ 2) + (w_dev ^ 2))) 
    )
end

# ╔═╡ ca12076e-0bb7-4ef6-b61a-12f5a2333e93
begin
	using DataFrames, DuckDB 

	n_archers = 100;
	n_shots = 50
	
	archers = [gen_archer() for i in 1:n_archers]
	shots = [gen_shot() for i in 1:n_shots]
	records = []; sizehint!(records, n_archers*10)
	for a in archers
	    for s in rand(shots, 10)
	        push!(records, shoot(a, s))
	    end
	end 
	df = DataFrame(records);
	df.skill = String.(df.skill)
end

# ╔═╡ dc0af8a9-e344-41f8-a559-3db98fce2a81
begin
	arch = gen_archer()
	shot = gen_shot() 
	record = shoot(arch, shot)
end

# ╔═╡ be0eeeca-6f9a-4095-bcb9-7003bdeb67d0
begin
	db = DuckDB.open("__local_artifacts__/portable.duckdb")
	#db = DuckDB.open(":memory:")
	con = DuckDB.connect(db)
	DuckDB.execute(con, "create schema if not exists sim;")
	DuckDB.execute(con, "drop table if exists sim.archery;")
	DuckDB.register_data_frame(con, df, "df_view")
	DuckDB.execute(con, "create table sim.archery as select * from df_view;")
	DuckDB.disconnect(con)
	DuckDB.close(db)
end

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
DataFrames = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
DuckDB = "d2f5444f-75bc-4fdf-ac35-56f514c445e1"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[compat]
DataFrames = "~1.6.1"
Distributions = "~0.25.100"
DuckDB = "~0.8.1"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.9.3"
manifest_format = "2.0"
project_hash = "85cc09dacd8bfae38c088235f290e3800f21f202"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[deps.Compat]]
deps = ["UUIDs"]
git-tree-sha1 = "e460f044ca8b99be31d35fe54fc33a5c33dd8ed7"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.9.0"
weakdeps = ["Dates", "LinearAlgebra"]

    [deps.Compat.extensions]
    CompatLinearAlgebraExt = "LinearAlgebra"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "1.0.5+0"

[[deps.Crayons]]
git-tree-sha1 = "249fe38abf76d48563e2f4556bebd215aa317e15"
uuid = "a8cc5b0e-0ffa-5ad4-8c14-923d3ee1735f"
version = "4.1.1"

[[deps.DBInterface]]
git-tree-sha1 = "9b0dc525a052b9269ccc5f7f04d5b3639c65bca5"
uuid = "a10d1c49-ce27-4219-8d33-6db1a4562965"
version = "2.5.0"

[[deps.DataAPI]]
git-tree-sha1 = "8da84edb865b0b5b0100c0666a9bc9a0b71c553c"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.15.0"

[[deps.DataFrames]]
deps = ["Compat", "DataAPI", "DataStructures", "Future", "InlineStrings", "InvertedIndices", "IteratorInterfaceExtensions", "LinearAlgebra", "Markdown", "Missings", "PooledArrays", "PrecompileTools", "PrettyTables", "Printf", "REPL", "Random", "Reexport", "SentinelArrays", "SortingAlgorithms", "Statistics", "TableTraits", "Tables", "Unicode"]
git-tree-sha1 = "04c738083f29f86e62c8afc341f0967d8717bdb8"
uuid = "a93c6f00-e57d-5684-b7b6-d8193f3e46c0"
version = "1.6.1"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "3dbd312d370723b6bb43ba9d02fc36abade4518d"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.15"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.Distributions]]
deps = ["FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SpecialFunctions", "Statistics", "StatsAPI", "StatsBase", "StatsFuns", "Test"]
git-tree-sha1 = "938fe2981db009f531b6332e31c58e9584a2f9bd"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.100"

    [deps.Distributions.extensions]
    DistributionsChainRulesCoreExt = "ChainRulesCore"
    DistributionsDensityInterfaceExt = "DensityInterface"

    [deps.Distributions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    DensityInterface = "b429d917-457f-4dbc-8f4c-0cc954292b1d"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "2fb1e02f2b635d0845df5d7c167fec4dd739b00d"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.3"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.DualNumbers]]
deps = ["Calculus", "NaNMath", "SpecialFunctions"]
git-tree-sha1 = "5837a837389fccf076445fce071c8ddaea35a566"
uuid = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74"
version = "0.6.8"

[[deps.DuckDB]]
deps = ["DBInterface", "DataFrames", "Dates", "DuckDB_jll", "FixedPointDecimals", "Tables", "UUIDs", "WeakRefStrings"]
git-tree-sha1 = "88cd745f64a570e7f865c49c17f59822f7f7e47b"
uuid = "d2f5444f-75bc-4fdf-ac35-56f514c445e1"
version = "0.8.1"

[[deps.DuckDB_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl"]
git-tree-sha1 = "f23f3781c620a97a9d0f7e4e057e94f9c9ef70e1"
uuid = "2cbbab25-fc8b-58cf-88d4-687a02676033"
version = "0.8.1+0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra", "Random"]
git-tree-sha1 = "a20eaa3ad64254c61eeb5f230d9306e937405434"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "1.6.1"
weakdeps = ["SparseArrays", "Statistics"]

    [deps.FillArrays.extensions]
    FillArraysSparseArraysExt = "SparseArrays"
    FillArraysStatisticsExt = "Statistics"

[[deps.FixedPointDecimals]]
deps = ["Parsers"]
git-tree-sha1 = "d58aa8e85901dee0915262c1c2697c4037281982"
uuid = "fb4d412d-6eee-574d-9565-ede6634db7b0"
version = "0.4.3"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.HypergeometricFunctions]]
deps = ["DualNumbers", "LinearAlgebra", "OpenLibm_jll", "SpecialFunctions"]
git-tree-sha1 = "f218fe3736ddf977e0e772bc9a586b2383da2685"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.23"

[[deps.InlineStrings]]
deps = ["Parsers"]
git-tree-sha1 = "9cc2baf75c6d09f9da536ddf58eb2f29dedaf461"
uuid = "842dd82b-1e85-43dc-bf29-5d0ee9dffc48"
version = "1.4.0"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.InvertedIndices]]
git-tree-sha1 = "0dc7b50b8d436461be01300fd8cd45aa0274b038"
uuid = "41ab1584-1d38-5bbf-9106-f11c6c58b48f"
version = "1.3.0"

[[deps.IrrationalConstants]]
git-tree-sha1 = "630b497eafcc20001bba38a4651b327dcfc491d2"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.2.2"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLLWrappers]]
deps = ["Artifacts", "Preferences"]
git-tree-sha1 = "7e5d6779a1e09a36db2a7b6cff50942a0a7d0fca"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.5.0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

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
deps = ["Libdl", "OpenBLAS_jll", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LogExpFunctions]]
deps = ["DocStringExtensions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "7d6dd4e9212aebaeed356de34ccf262a3cd415aa"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.26"

    [deps.LogExpFunctions.extensions]
    LogExpFunctionsChainRulesCoreExt = "ChainRulesCore"
    LogExpFunctionsChangesOfVariablesExt = "ChangesOfVariables"
    LogExpFunctionsInverseFunctionsExt = "InverseFunctions"

    [deps.LogExpFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    ChangesOfVariables = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.2+0"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "f66bdc5de519e8f8ae43bdc598782d35a25b1272"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.1.0"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.10.11"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "0877504529a3e5c3343c6f8b4c0381e57e4387e4"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.2"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.21+4"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "2e73fe17cac3c62ad1aebe70d44c963c3cfdc3e3"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.6.2"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "67eae2738d63117a196f497d7db789821bce61d1"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.17"

[[deps.Parsers]]
deps = ["Dates", "PrecompileTools", "UUIDs"]
git-tree-sha1 = "716e24b21538abc91f6205fd1d8363f39b442851"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.7.2"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "FileWatching", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.9.2"

[[deps.PooledArrays]]
deps = ["DataAPI", "Future"]
git-tree-sha1 = "a6062fe4063cdafe78f4a0a81cfffb89721b30e7"
uuid = "2dfb63ee-cc39-5dd5-95bd-886bf059d720"
version = "1.4.2"

[[deps.PrecompileTools]]
deps = ["Preferences"]
git-tree-sha1 = "03b4c25b43cb84cee5c90aa9b5ea0a78fd848d2f"
uuid = "aea7be01-6a6a-4083-8856-8a6e6704d82a"
version = "1.2.0"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "7eb1686b4f04b82f96ed7a4ea5890a4f0c7a09f1"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.4.0"

[[deps.PrettyTables]]
deps = ["Crayons", "LaTeXStrings", "Markdown", "Printf", "Reexport", "StringManipulation", "Tables"]
git-tree-sha1 = "ee094908d720185ddbdc58dbe0c1cbe35453ec7a"
uuid = "08abe8d2-0d0c-5749-adfa-8a2ac140af0d"
version = "2.2.7"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "6ec7ac8412e83d57e313393220879ede1740f9ee"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.8.2"

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

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "f65dcb5fa46aee0cf9ed6274ccbd597adc49aa7b"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.1"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6ed52fdd3382cf21947b15e8870ac0ddbff736da"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.4.0+0"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.SentinelArrays]]
deps = ["Dates", "Random"]
git-tree-sha1 = "04bdff0b09c65ff3e06a05e3eb7b120223da3d39"
uuid = "91c51154-3ec4-41a3-a24f-3f23e20d615c"
version = "1.4.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "c60ec5c62180f27efea3ba2908480f8055e17cee"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.1.1"

[[deps.SparseArrays]]
deps = ["Libdl", "LinearAlgebra", "Random", "Serialization", "SuiteSparse_jll"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "e2cfc4012a19088254b3950b85c3c1d8882d864d"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.3.1"

    [deps.SpecialFunctions.extensions]
    SpecialFunctionsChainRulesCoreExt = "ChainRulesCore"

    [deps.SpecialFunctions.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
version = "1.9.0"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "45a7769a04a3cf80da1c1c7c60caf932e6f4c9f7"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.6.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "75ebe04c5bed70b91614d684259b661c9e6274a4"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.34.0"

[[deps.StatsFuns]]
deps = ["HypergeometricFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "f625d686d5a88bcd2b15cd81f18f98186fdc0c9a"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.3.0"

    [deps.StatsFuns.extensions]
    StatsFunsChainRulesCoreExt = "ChainRulesCore"
    StatsFunsInverseFunctionsExt = "InverseFunctions"

    [deps.StatsFuns.weakdeps]
    ChainRulesCore = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
    InverseFunctions = "3587e190-3f89-42d0-90ee-14403ec27112"

[[deps.StringManipulation]]
git-tree-sha1 = "46da2434b41f41ac3594ee9816ce5541c6096123"
uuid = "892a3eda-7b42-436c-8928-eab12a02cf0e"
version = "0.3.0"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.SuiteSparse_jll]]
deps = ["Artifacts", "Libdl", "Pkg", "libblastrampoline_jll"]
uuid = "bea87d4a-7f5b-5778-9afe-8cc45184846c"
version = "5.10.1+6"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.3"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "1544b926975372da01227b382066ab70e574a3ec"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.10.1"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.WeakRefStrings]]
deps = ["DataAPI", "InlineStrings", "Parsers"]
git-tree-sha1 = "b1be2855ed9ed8eac54e5caff2afcdb442d52c23"
uuid = "ea10d353-3f73-51f8-a26c-33c1cb351aa5"
version = "1.4.2"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.13+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.8.0+0"

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
# ╟─aad8bbac-a980-4685-9561-3d0fd2989596
# ╟─9930c5c3-78fb-45b7-8ed0-2c45da32e894
# ╟─6c73c7f0-46f8-4199-b279-dd32f5c732d6
# ╟─ca0f0b7a-fac8-4c00-a77d-2360e71f8089
# ╟─e6594fab-02dc-4194-a150-d9513f305f20
# ╟─807937c1-303c-42fe-a5ff-2738f020d917
# ╟─b3d0cb00-5a51-11ee-08e0-a3dcb370ec41
# ╟─2ec300af-39f4-4260-9085-1510d4fdf3cc
# ╟─dea5b5fc-19d5-4097-8769-a1c86357f019
# ╟─c569fd2c-113b-414b-96b4-17b9447635a9
# ╟─e85c4758-97c9-4c27-9a3c-3d96b0f5f665
# ╟─e15d56db-b9c7-4976-bacd-bea13f9cc5b9
# ╠═006eab5f-8756-40e4-8329-dfea600ac2b9
# ╟─dc0af8a9-e344-41f8-a559-3db98fce2a81
# ╟─ca12076e-0bb7-4ef6-b61a-12f5a2333e93
# ╠═be0eeeca-6f9a-4095-bcb9-7003bdeb67d0
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
