# econ_survival_sim.jl

"""
simulate survival distribution wrt liquidity/solvency risks
where available assets available to cover obligations are affected by deterministic and stochastic changes
"""

using Statistics
using Base.Iterators, Base.Threads


function invest_safe(assets, cost=0, ror=0.02)::Integer
    if assets < cost
        return 0
    else
        return floor(assets * ror)
    end
end

function invest_risky(assets, cost)::Integer
    # favourable, but uncertain returns
    outcomes = [-cost, cost, cost]
    if assets < cost
        return 0
    else
        return rand(outcomes)
    end
end


# specify initial state
init_A = (
    n_periods = 52, 
    cash_init = 100, 
    income_amt = 10, 
    income_freq = 1, 
    obligation_amt = 40, 
    obligation_freq = 4,
    invest_freq = 1, 
    invest_cost = 20, 
    invest_fn = invest_risky
)
 

# simulate_run
function simulate_run(init_spec)
    n_p = get(init_spec, :n_periods, 52)
    b = init_spec[:cash_init]
    h = [(t=0, c=b)]
    sizehint!(h, n_p)
    s = true
    # iterate process until insufficient assets, or specified periods elapsed
    for p = range(1, n_p)
        if p % init_spec[:income_freq] == 0
            b += init_spec[:income_amt]
        end
        if p % init_spec[:obligation_freq] == 0
            b -= init_spec[:obligation_amt]
        end
        if p % init_spec[:invest_freq] == 0
            b += invest_risky(assets=b, cost=20)
        end
        
        push!(h, (t=p, c=b))
        if (b <= 0) 
            success = false
            break
        end
    end
    return (success=success, elapsed=length(history)-1, balance=b, history=h)
end

# simulate_all_runs
function simulate_all_runs(init_spec, n_runs=1000)
    results = []
    sizehint!(results, n_runs)
    records = []
    sizehint!(records, n_runs)
    @threads for i in range(1, n_runs)
        trial = simulate_run(init_spec)
        push!(results, (id=i, success=trial[:success], elapsed=trial[:elapsed]))
        push!(records, trial[:history])
    end
    return (results, collect(Iterators.flatten(records)))
end

# analyse results

sim_A = simulate_all_runs(init_A)
outcomes_A = sim_A[1]
details_A = sim_A[2]


# n trials
length(outcomes_A)

# rate of survival to end of trial
mean(outcomes_A.[:success])

# avg ending assets of survivors
# avg time to fail 


