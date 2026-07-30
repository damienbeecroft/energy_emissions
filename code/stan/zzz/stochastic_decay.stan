# This model
data {
	int<lower=1> N; # total number of data points == sum(Ts)
	int<lower=1> G; # number of groups
	int Ts[G]; # lengths of each timeseries
	int start_idx[G]; # start index of each timeseries
	vector<lower=0>[N] y; # all data
}

parameters {
  real <lower = 1e-1> alpha;
  real <lower = 1e-1, upper = 3> beta;
  vector <lower = 0, upper = 1> [G] rho;
  // vector <lower = 0> [G] sigma;

  real <lower = 0.05, upper = 5> global_sigma_sigma;
  real global_mu_sigma;
  vector <lower = 0> [G] global_sigma;
}

model {
  alpha ~ cauchy(120, 30) T[1e-1,];
  beta ~ uniform(1e-1,3);
  rho ~ beta(alpha, beta);
  // sigma ~ cauchy(0, 1) T[0,];

  global_sigma_sigma ~ uniform(0.05, 5);
  global_mu_sigma ~ normal(0, 10);
  global_sigma ~ lognormal(global_mu_sigma, global_sigma_sigma);

  for (g in 1:G){
    int T_g = Ts[g]; # length of timeseries g
    int s = start_idx[g]; # starting point of timeseries g
    for (t in 1:(T_g-1)){
      // y[s+t] ~ normal(rho[g] * y[s+t-1], global_sigma[g] * sqrt(y[s+t-1]) + sigma[g]) T[0,];
      y[s+t] ~ normal(rho[g] * y[s+t-1], global_sigma[g] * log(1 + y[s+t-1])) T[0,];
    }
  }
}
