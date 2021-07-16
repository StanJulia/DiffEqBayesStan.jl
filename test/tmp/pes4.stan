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
}