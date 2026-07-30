data {
	int<lower=1> N; # total number of data points == sum(Ts)
	int<lower=1> G; # number of groups
	int Ts[G]; # lengths of each timeseries
	int start_idx[G]; # start index of each timeseries
	vector<lower=0>[N] y; # all data
}

parameters {
  
  real <lower = 0, upper = 1> mu_phi;
  real <lower = 0, upper = 1> unshifted_sigma_phi;
  vector <lower = 0, upper = 1> [G] phi;
  
  real <lower = 0> gamma;
  
  real <lower = 0> mu_sigma;
  real <lower = 0.05, upper = 5> sigma_sigma;
  vector <lower = 0> [G] sigma;
}

transformed parameters {
  real sigma_phi = unshifted_sigma_phi + 1e-2;
}

model {
  
  mu_phi ~ beta(1,5);
  unshifted_sigma_phi ~ beta(1,1);
  phi ~ normal(mu_phi, sigma_phi) T[0,1];
  
  gamma ~ cauchy(50, 10) T[0,];
  
  mu_sigma ~ normal(-6, 40);
  sigma_sigma ~ uniform(0.05, 5);
  sigma ~ lognormal(mu_sigma, sigma_sigma);

  for (g in 1:G){
    int T_g = Ts[g]; # length of timeseries g
    int s = start_idx[g]; # starting point of timeseries g
    for (t in 1:(T_g-1)){
      y[s+t] ~ normal(phi[g] * (y[s+t-1] - gamma) + gamma, sigma[g]) T[0,];
    }
  }
}
