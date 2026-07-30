data {
	int<lower=1> N; # total number of data points == sum(Ts)
	int<lower=1> G; # number of groups
	int Ts[G]; # lengths of each timeseries
	int start_idx[G]; # start index of each timeseries
	vector<lower=0>[N] y; # all data
}

parameters {
  real <lower = 0> tau;
  real <lower = 0> sigma_frontier;
  
  real <lower = 0, upper = 1> mu_phi;
  real <lower = 0, upper = 1> unshifted_sigma_phi;
  vector <lower = 0, upper = 1> [G-1] phi;
  
  vector <lower = 0> [G-1] sigma;
  real <lower = 0.05, upper = 5> sigma_sigma;
  real mu_sigma;
}

transformed parameters {
  real sigma_phi = unshifted_sigma_phi + 1e-2;
}

model {
  tau ~ cauchy(600, 100) T[0,];
  sigma_frontier ~ lognormal(2.5, 10);
  
  mu_phi ~ beta(10,1);
  unshifted_sigma_phi ~ beta(2,20);
  phi ~ normal(mu_phi, sigma_phi) T[0,1];
  
  mu_sigma ~ normal(-6, 40);
  sigma_sigma ~ uniform(0.05, 5);
  sigma ~ lognormal(mu_sigma, sigma_sigma);
  
  int Tg;
  int T = Ts[1]; # make sure frontier is at index 1!
  int s = start_idx[1];
  vector [T] F = y[s:(s+T-1)]; # data is passed in on a log scale. We undo this for the frontier
  
  F[2:T] ~ normal(F[1:(T-1)] + tau, sigma_frontier);
  
  for (g in 2:G){
    Tg = Ts[g]; # length of timeseries g
    s = start_idx[g]; # starting point of timeseries g
    y[(s+1):(s+Tg-1)] ~ normal(1 - phi[g-1] * (1 - y[s:(s+Tg-2)]), sigma[g-1]) T[0,];
  }
}
