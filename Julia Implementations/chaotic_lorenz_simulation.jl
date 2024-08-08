### A Pluto.jl notebook ###
# v0.19.9

using Markdown
using InteractiveUtils

# ╔═╡ b5e41461-b495-4675-83ac-e21a0a98f5ca
# imports
using Unitful, DataFrames, Logging, Plots
# units for calculations
# dataframes to represent state
# plots for visualizing state 
# duckdb to record/playback a sequence

# ╔═╡ c5887070-3fd2-11ef-2ca5-e187879f3427
md"Simulation of complex systems that exhibit chaotic behaviours, making simulations entertaining to watch"

# ╔═╡ aa475e33-0ed3-422a-ae0a-1e97d657df77
md"# Lorenz Waterwheel"

# ╔═╡ cdb95efa-1e5a-421e-98cf-1933ee7842ae
md"
[https://www.collimator.ai/tutorials/surrogate-model-of-a-chaotic-lorenz-waterwheel](https://www.collimator.ai/tutorials/surrogate-model-of-a-chaotic-lorenz-waterwheel)

https://en.wikipedia.org/wiki/Torque

https://en.wikipedia.org/wiki/Malkus_waterwheel

https://en.wikipedia.org/wiki/Lorenz_system#Julia_simulation
"

# ╔═╡ 3e9f3839-40ea-4f88-a81b-f2c87218b1a5
md"## System Mechanics"

# ╔═╡ 31b046cf-a232-48be-aa25-e27f4c85ad71
struct State
	𝑡
	θ
	ω
	buckets
end

# ╔═╡ 7d2fcbe4-ac26-45d9-b13a-a6d207bc3998
function step_wheel(state, sys) ::State
	# calculate observable state
	B = state.buckets 
	B.pos_x = (sin.(B.pos_θ) * sys.wheel_radius)
	B.pos_y = (cos.(B.pos_θ) * sys.wheel_radius)

	# check if buckets satisfy the fill position
	fill_position = (-0.1u"m" .< B.pos_x .< 0.5u"m") .&& (B.pos_y .> 0u"m")

	# update bucket mass
	B′ = DataFrame()
	B′.id = B.id
	
	B′.mass = min.(sys.max_fill, max.(+0u"kg" ,
		B.mass 
		# if a bucket is in a position to be filled, increase its mass for one step
		.+ (sys.inflow_rate*sys.𝑡_step) * fill_position
		# every bucket that has a filled mass loses some for one step
		# basic implementation: all buckets constant drain rate
		.- (sys.outflow_rate*sys.𝑡_step) 
		# realistic: each bucket drains at a rate according to its filled mass and shape of water for one step
	))
	#@debug B′.mass

	#@debug state.𝑡, state.θ, state.ω
	# update resultant dynamics
	𝑡′ = state.𝑡 + sys.𝑡_step 
	θ′ = mod(state.θ + state.ω * sys.𝑡_step, 2*π*u"rad")
	B′.τ = B′.mass .* sin.(B.pos_θ) .* sys.wheel_radius * sys.g⃗
	#@debug B′.τ
	ω′ = state.ω + (sum(B′.τ) - sign(state.ω)*sys.ν) / sys.wheel_inertia *u"rad"

	#@debug 𝑡′, θ′, ω′
	
	B′.pos_θ = mod.(θ′ .+ (B′.id ./ sys.n_buckets .* (2*π*u"rad")), 2*π*u"rad")
	B′.pos_x = sin.(B′.pos_θ) * sys.wheel_radius
	B′.pos_y = cos.(B′.pos_θ) * sys.wheel_radius
	#@debug B′
	
	return State(
		𝑡′, 
		θ′, 
		ω′, 
		B′
	)
end

# ╔═╡ f949dc42-bc2e-406d-8247-714f0b3c561b
md"# Initialize System Properties"

# ╔═╡ bda19153-039d-4541-a06e-116688abe810

sim_system = (
	𝑡_step = 0.02u"s", # temporal resolution of the simulation
	
	g⃗ = 9.8u"m/s^2", 
	inflow_rate = 0.300u"kg/s", 
	max_fill = 1u"kg", 
	outflow_rate = 0.050u"kg/s", 
	
	n_buckets = 11, 
	wheel_radius = 1u"m", 
	wheel_inertia = 5u"kg*m^2/s", 
	ν = 0.1u"N*m*rad", # braking torque
)

# ╔═╡ c821788a-ea86-47c8-bf55-e086d5ebfb95
function initialize(sys)
	positions = ((1:sys.n_buckets)/sys.n_buckets) .* 2*π *u"rad"
	return State(
		0u"s",
		π*0.1u"rad",
		π*0.2u"rad/s",
		DataFrame(
			:id=>(1:sys.n_buckets), 
			:mass=>zeros(sys.n_buckets)u"kg", 
			:pos_θ=>positions, 
			:pos_x=>(sin.(positions) * sys.wheel_radius),
			:pos_y=>(cos.(positions) * sys.wheel_radius),
		)
	)
end

# ╔═╡ beb0e29b-1325-4873-baa6-a19e245d8669
#test_state = step_wheel(initialize(sim_system), sim_system);

# ╔═╡ e983bcc2-53dd-45f9-aef4-0b21ab459087
function play_simulation(time_limit=30u"s")
	start_state = initialize(sim_system)
	frames = []
	push!(frames, start_state)
	#while frames[i].𝑡 < time_limit
	for i in 1:1000
		if i%20 == 1
			@debug "iter $(i-1), rotation: $(round(u"rad/s", frames[i].ω)) at $(round(u"ms",frames[i].𝑡))\n"
			@debug frames[i].buckets
		end
		push!(frames, step_wheel(frames[i], sim_system))
	end
	return frames
end

# ╔═╡ c31909fc-a2b7-44a3-a44c-bf9ec8512fde
sim = play_simulation();

# ╔═╡ b5d79250-4d4d-48bb-bfc6-66f402abec29
# display

# ╔═╡ 2c749b81-013b-4561-a206-bf074ac774f9
wheel_bucket = Shape([(0,0.2),(0.4,0.2),(0.4, 0),(0,0),])

# ╔═╡ 690ec340-d9aa-4328-b214-a4b9aaabaa8f
	# render frames
	seq = @animate for i in 1:length(sim)
		push!(plt, 
			ustrip.(sim[i].buckets.pos_x[1:5]), 
			ustrip.(sim[i].buckets.pos_y[1:5]), 
			seriestype=:scatter,
			line_z=1:5,
		)
	end

# ╔═╡ 96c92fb8-2aa2-4b20-8ef2-45e1a8e237f4
	# save to file
	gif(seq, "waterwheel_test.gif", fps=50)

# ╔═╡ 0067187c-c857-4614-a424-2b6d007625b6
# define the Lorenz attractor
Base.@kwdef mutable struct Lorenz
    dt::Float64 = 0.02
    σ::Float64 = 10
    ρ::Float64 = 28
    β::Float64 = 8/3
    x::Float64 = 1
    y::Float64 = 1
    z::Float64 = 1
end

# ╔═╡ 7cdbe6a1-599d-40eb-920e-8f773dd31d3f
function step!(l::Lorenz)
    dx = l.σ * (l.y - l.x)
    dy = l.x * (l.ρ - l.z) - l.y
    dz = l.x * l.y - l.β * l.z
    l.x += l.dt * dx
    l.y += l.dt * dy
    l.z += l.dt * dz
end

# ╔═╡ f81354a0-db19-47f0-b038-39127af73ed5
attractor = Lorenz()

# ╔═╡ 982df5ea-692f-4a6e-8536-19fb3561330b
# ╠═╡ disabled = true
#=╠═╡
# build an animated gif by pushing new points to the plot, saving every 10th frame
@gif for i=1:1500
    step!(attractor)
    push!(plt, attractor.x, attractor.y, attractor.z)
end every 10
  ╠═╡ =#

# ╔═╡ 421b946a-7cca-4afe-b24a-fef86fd1e6a6


# ╔═╡ 744346af-a29f-4d60-aca1-0827afd2671f
#=╠═╡

	# initialize a 2D plot with 1 empty series
	plt = plot(
	    1,
	    xlim = (-1.5, 1.5),
	    ylim = (-1.5, 1.5),
	    title = "Lorenz Waterwheel",
	    legend = false,
	    marker = 2,
		#size=(500, 500),
	)
  ╠═╡ =#

# ╔═╡ e0477e69-21af-412a-9c01-a5c829c3b865
# ╠═╡ disabled = true
#=╠═╡
# initialize a 3D plot with 1 empty series
plt = plot3d(
    1,
    xlim = (-30, 30),
    ylim = (-30, 30),
    zlim = (0, 60),
    title = "Lorenz Attractor",
    legend = false,
    marker = 2,
);
  ╠═╡ =#

# ╔═╡ Cell order:
# ╟─c5887070-3fd2-11ef-2ca5-e187879f3427
# ╟─aa475e33-0ed3-422a-ae0a-1e97d657df77
# ╠═cdb95efa-1e5a-421e-98cf-1933ee7842ae
# ╠═b5e41461-b495-4675-83ac-e21a0a98f5ca
# ╟─3e9f3839-40ea-4f88-a81b-f2c87218b1a5
# ╠═31b046cf-a232-48be-aa25-e27f4c85ad71
# ╠═7d2fcbe4-ac26-45d9-b13a-a6d207bc3998
# ╟─f949dc42-bc2e-406d-8247-714f0b3c561b
# ╠═bda19153-039d-4541-a06e-116688abe810
# ╠═c821788a-ea86-47c8-bf55-e086d5ebfb95
# ╠═beb0e29b-1325-4873-baa6-a19e245d8669
# ╠═e983bcc2-53dd-45f9-aef4-0b21ab459087
# ╠═c31909fc-a2b7-44a3-a44c-bf9ec8512fde
# ╠═b5d79250-4d4d-48bb-bfc6-66f402abec29
# ╠═2c749b81-013b-4561-a206-bf074ac774f9
# ╠═744346af-a29f-4d60-aca1-0827afd2671f
# ╠═690ec340-d9aa-4328-b214-a4b9aaabaa8f
# ╠═96c92fb8-2aa2-4b20-8ef2-45e1a8e237f4
# ╠═0067187c-c857-4614-a424-2b6d007625b6
# ╠═7cdbe6a1-599d-40eb-920e-8f773dd31d3f
# ╠═f81354a0-db19-47f0-b038-39127af73ed5
# ╠═e0477e69-21af-412a-9c01-a5c829c3b865
# ╠═982df5ea-692f-4a6e-8536-19fb3561330b
# ╠═421b946a-7cca-4afe-b24a-fef86fd1e6a6
