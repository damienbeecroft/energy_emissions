# This model
data {
	int<lower=1> N; # total number of data points == sum(Ts)
	int<lower=1> G; # number of groups
	int Ts[G]; # lengths of each timeseries
	int start_idx[G]; # start index of each timeseries
	real y_maxes[G];
	vector<lower=0>[N] y; # all data
}

parameters {
  real <lower = 0, upper = 1> mu_rho;
  real <lower = 0, upper = 1> unshifted_sigma_rho;
  vector <lower = 0, upper = 1> [G] rho;
  
  real <lower = 0.05, upper = 5> global_sigma_sigma;
  real global_mu_sigma;
  vector <lower = 0> [G] global_sigma;
}


transformed parameters {
  real sigma_rho = unshifted_sigma_rho + 1e-2;
}

model {
  
  mu_rho ~ beta(10,1);
  sigma_rho ~ beta(2, 20);
  rho ~ normal(mu_rho, sigma_rho) T[0,1];
  
  global_sigma_sigma ~ uniform(0.05, 5);
  global_mu_sigma ~ normal(0, 10);
  global_sigma ~ lognormal(global_mu_sigma, global_sigma_sigma);

  for (g in 1:G){
    int T_g = Ts[g]; # length of timeseries g
    int s = start_idx[g]; # starting point of timeseries g
    real y_max = y_maxes[g];
    real upper_bound = 2 * y_max;
    for (t in 1:(T_g-1)){
      y[s+t] ~ normal(rho[g] * y[s+t-1], (rho[g] * y[s+t-1])^2 * global_sigma[g]) T[0, upper_bound];
    }
  }
}
