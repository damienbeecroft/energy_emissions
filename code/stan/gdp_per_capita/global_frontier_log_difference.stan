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
  
  // vector <lower = 0, upper = 1> [G-1] phi;
  // real <lower = 1e-1> alpha;
  // real <lower = 1e-1> beta;
  
  vector <lower = 0, upper = 1> [G-1] phi;
  real <lower = 0, upper = 1> mu_phi;
  real <lower = 1e-4, upper = 1> sigma_phi;
  
  vector <lower = 0> [G-1] sigma;
  real mu_sigma;
  real <lower = 0.05, upper = 5> sigma_sigma;
}

model {
  // tau ~ normal(0,1) T[0,];
  // sigma_frontier ~ lognormal(-3, 20);
  tau ~ cauchy(600, 100) T[0,];
  sigma_frontier ~ lognormal(2.5, 10);

  // beta ~ normal(0,10) T[1e-1,];
  // alpha ~ normal(50,30) T[1e-1,];
  // phi ~ beta(alpha, beta);

  mu_phi ~ uniform(0,1);
  sigma_phi ~ uniform(1e-4,1);
  phi ~ normal(mu_phi, sigma_phi) T[0,1];

  mu_sigma ~ normal(-6, 40);
  sigma_sigma ~ uniform(0.05, 5);
  sigma ~ lognormal(mu_sigma, sigma_sigma);
  
  int Tg;
  int T = Ts[1]; # make sure frontier is at index 1!
  int s = start_idx[1]; # offset for 1973 breakpoint
  int offset = 12;
  
  // F[2:T] ~ normal(F[1:(T-1)] + tau, sigma_frontier);
  y[(s+offset+1):(s+T-1)] ~ normal(y[(s+offset):(s+T-2)] + tau, sigma_frontier);
  
  for (g in 2:G){
    Tg = Ts[g]; # length of timeseries g
    s = start_idx[g]; # starting point of timeseries g
    y[(s+1):(s+Tg-1)] ~ normal(y[(T-Tg+2):T] - phi[g-1] * (y[(T-Tg+1):(T-1)] - y[s:(s+Tg-2)]), sigma[g-1]);
  }
}
