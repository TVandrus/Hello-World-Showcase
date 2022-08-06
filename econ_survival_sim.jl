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
    outcomes = [-cost, -0.5*cost, 0, cost, cost]
    if assets < cost
        return 0
    else
        return rand(outcomes)
    end
end

# simulate_run
function simulate_run(init_spec)
    n_p = get(init_spec, :n_periods, 52)
    b = init_spec[:cash_init]
    h = [(t=0, c=b)]
    sizehint!(h, n_p)
    s = true
    # iterate process until insufficient assets, or specified periods elapsed
    for p = range(1, n_p, step=1)
        if p % init_spec[:income_freq] == 0
            b += init_spec[:income_amt]
        end
        if p % init_spec[:obligation_freq] == 0
            b -= init_spec[:obligation_amt]
        end
        if p % init_spec[:invest_freq] == 0
            b += invest_risky(b, init_spec[:invest_cost])
        end
        
        push!(h, (t=p, c=b))
        if (b <= 0) 
            s = false
            break
        end
    end
    return (success=s, elapsed=length(h)-1, balance=b, history=h)
end

# simulate_all_runs
function simulate_all_runs(init_spec, n_runs=1000)
    results = []
    sizehint!(results, n_runs)
    records = []
    sizehint!(records, n_runs)
    @threads for i in range(1, n_runs, step=1)
        trial = simulate_run(init_spec)
        push!(results, (id=i, success=trial[:success], elapsed=trial[:elapsed]))
        push!(records, trial[:history])
    end
    return (results, collect(Iterators.flatten(records)))
end


# specify initial state
init_A = (
    n_periods = 52, 
    cash_init = 100, 
    income_amt = 10, 
    income_freq = 1, 
    obligation_amt = 40, 
    obligation_freq = 4,
    invest_freq = 2, 
    invest_cost = 20, 
    invest_fn = invest_risky
)
 
init_B = (
    n_periods = 52, 
    cash_init = 50, 
    income_amt = 10, 
    income_freq = 1, 
    obligation_amt = 40, 
    obligation_freq = 4,
    invest_freq = 2, 
    invest_cost = 20, 
    invest_fn = invest_risky
)
init_C = (
    n_periods = 52, 
    cash_init = 50, 
    income_amt = 10, 
    income_freq = 1, 
    obligation_amt = 40, 
    obligation_freq = 4,
    invest_freq = 3, 
    invest_cost = 20, 
    invest_fn = invest_risky
)


# analyse results
sim = Dict()

let run = simulate_all_runs(init_A); 
    sim[:A] = (
        outcomes = run[1],  
        details = run[2])
end ;
let run = simulate_all_runs(init_B); 
    sim[:B] = (
        outcomes = run[1],  
        details = run[2])
end ;
let run = simulate_all_runs(init_C); 
    sim[:C] = (
        outcomes = run[1],  
        details = run[2])
end ;

# n trials
length(sim[:A].outcomes)

# investment characteristics for the trials
returns = [invest_risky(100, 100) for _ in 1:1_000_000]; 
mean(returns)
std(returns)
quantile(returns, (0 : 0.1 : 1))

# rate of survival to end of trial
mean([o.success for o in sim[:A].outcomes]) # start w 100, invest every 2nd week
mean([o.success for o in sim[:B].outcomes]) # start w 50, invest every 2nd week
mean([o.success for o in sim[:C].outcomes]) # start w 50, invest every 3rd week


# avg ending assets of survivors

# avg time to fail 


