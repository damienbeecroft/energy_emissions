data {
	int <lower=1> N; # total number of data points == sum(Ts)
	int <lower=1> G; # number of groups
	int <lower=1> NUM_YEARS;
	vector [NUM_YEARS] t;
	int Ts[G]; # lengths of each timeseries
	int start_idx[G]; # start index of each timeseries
	vector <lower=0>[N] y; # all data
}

parameters {
  real <upper = 0> beta;
  real <lower = 0> mu_alpha;
  real <lower = 0> sigma_alpha;
  vector <lower = 0> [G] alpha;
  
  real <lower = 0, upper = 1> mu_phi;
  real <lower = 0, upper = 1> unshifted_sigma_phi;
  vector <lower = 0, upper = 1> [G] phi;
  
  real mu_sigma;
  real <lower = 0.05, upper = 5> sigma_sigma;
  vector <lower = 0> [G] sigma;
}

transformed parameters {
  real sigma_phi = unshifted_sigma_phi + 1e-2;
}

model {
  int Tg;
  int s;
  
  beta ~ normal(0, 1e-2) T[,0];
  mu_alpha ~ normal(1, 0.5) T[0,];
  sigma_alpha ~ inv_gamma(5, 1);
  alpha ~ normal(mu_alpha, sigma_alpha) T[0,];
  
  // mu_phi ~ beta(1,5);
  mu_phi ~ beta(10, 1);
  unshifted_sigma_phi ~ beta(2, 20);
  phi ~ normal(mu_phi, sigma_phi) T[0,1];
  
  mu_sigma ~ normal(-6, 40);
  sigma_sigma ~ uniform(0.05, 5);
  sigma ~ lognormal(mu_sigma, sigma_sigma);
  
  for (g in 1:G){
    Tg = Ts[g]; # length of timeseries g
    s = start_idx[g]; # starting point of timeseries g
    y[(s+1):(s+Tg-1)] ~ normal(alpha[g] + beta * t[(NUM_YEARS - Tg + 2):] + phi[g] * (y[s:(s+Tg-2)] - (alpha[g] + beta * t[(NUM_YEARS - Tg + 1):(NUM_YEARS - 1)])), sigma[g]);
  }
}
