using DiffEqBayesStan
using OrdinaryDiffEq
using ParameterizedFunctions
using RecursiveArrayTools
using StatsPlots, Statistics
using StanSample

ProjDir = @__DIR__

println("Four parameter case (using StanLanguage)")

f1 = @ode_def begin
  dx = a*x - b*x*y
  dy = -c*y + d*x*y
end a b c d
u0 = [1.0,1.0]
tspan = (0.0,10.0)
p = [1.5,1.0,3.0,1.0]
prob1 = ODEProblem(f1,u0,tspan,p)
sol = solve(prob1,Tsit5())
t = collect(range(1,stop=10,length=50))
randomized = VectorOfArray([(sol(t[i]) + .3randn(2)) for i in 1:length(t)])
data_array = convert(Array, randomized)'

stan_pes = "
functions {
  vector sho(real t,vector internal_var___u, 
    real internal_var___p_1, real internal_var___p_2, 
    real internal_var___p_3, real internal_var___p_4) {
    
    vector[2] internal_var___du;
    internal_var___du[1] = internal_var___p_1 * internal_var___u[1] - 
      internal_var___p_2 * internal_var___u[1] * internal_var___u[2];
    internal_var___du[2] = internal_var___u[2] * -internal_var___p_3 +
      internal_var___p_4 * internal_var___u[1] * internal_var___u[2];

    return internal_var___du;
  }
}
data {
  vector[2] u0;
  int<lower=1> T;
  real internal_var___u[T,2];
  real t0;
  real ts[T];
}
parameters {
  row_vector<lower=0>[2] sigma1;
  real<lower=0.5,upper=2.0> theta_1;real<lower=0.5,upper=1.5> theta_2;real<lower=0.5,upper=4.0> theta_3;real<lower=0.5,upper=2.0> theta_4;
}
model{
  vector[2] u_hat[T];
  sigma1 ~ inv_gamma(4.0, 1.0);
  theta_1 ~ normal(1.1, 0.5) T[0.5,2.0];
  theta_2 ~ normal(1.5, 0.5) T[0.5,1.5];
  theta_3 ~ normal(2.0, 0.5) T[0.5,4.0];
  theta_4 ~ normal(1.5, 0.5) T[0.5,2.0];
  u_hat = ode_rk45_tol(sho, u0, t0, ts, 0.001, 1.0e-6, 100000, 
    theta_1,theta_2,theta_3,theta_4);
  for (t in 1:T){
    internal_var___u[t,:] ~ normal(u_hat[t,1:2],sigma1);
    }
}";

pes4 = SampleModel("pes4", stan_pes, joinpath(ProjDir, "tmp"))
data = (u0=u0, T=size(t, 1), internal_var___u=data_array, t0=0.0, ts=t)
rc = stan_sample(pes4; data)

if success(rc)
  df = read_samples(pes4, :dataframe)
  
  println("\ntheta means:\n",
    [mean(df.theta_1), mean(df.theta_2), mean(df.theta_3), mean(df.theta_4)])
  println("\ntheta vars:\n",
    [var(df.theta_1), var(df.theta_2), var(df.theta_3), var(df.theta_4)])
  println()

  dfs = read_samples(pes4, :dataframes)
  for j in 1:4
    for i in 1:4
      if i == 1
        plot(dfs[i][:, "theta_$j"], lab="chain[$j]")
      else
        plot!(dfs[i][:, "theta_$j"], lab="chain[$j]")
      end
    end
    savefig(joinpath(ProjDir, "tmp", "theta_$j.png"))
  end

end

