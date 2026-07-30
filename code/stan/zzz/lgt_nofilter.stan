data {
	int<lower=1> N; # total number of data points == sum(Ts)
	int<lower=1> G; # number of groups
	int Ts[G]; # lengths of each timeseries
	int start_idx[G]; # start index of each timeseries
	vector<lower=0>[N] y; # all data
}

parameters {
	// real mu_gamma;
	// // real <lower = 0.01, upper = 1> sigma_gamma;
	// real <lower = 0, upper = 1> sigma_gamma;
	vector [G] gamma;
	
	// real <lower = 5> alpha;
	// real <lower = 5> beta;
	vector <lower=0, upper=1> [G] unscaled_rho;
	// real <lower=-1, upper=1> mu_rho;
	// real <lower = 0.01, upper = 1> sigma_rho;
	// vector <lower=-1, upper=1> [G] unscaled_rho;
	// vector <lower=-1, upper=1> [G] rho;

  real mu_sigma;
  real <lower = 0.05, upper = 5> sigma_sigma;
  vector <lower = 0> [G] sigma;
}

transformed parameters {
  vector [G] rho = 2 * unscaled_rho - 1;
}

model {
  int Tg;
  int s;


  gamma ~ normal(0, 0.1);
  // mu_gamma ~ cauchy(0, 0.1);
  // // sigma_gamma ~ uniform(0.001, 1);
  // sigma_gamma ~ beta(2, 60);
  // gamma ~ normal(mu_gamma, sigma_gamma);
  
  unscaled_rho ~ beta(2, 2);
  
  // alpha ~ cauchy(100, 100) T[5,];
  // beta ~ cauchy(100, 100) T[5,];
  // unscaled_rho ~ beta(alpha, beta);

  // mu_rho ~ cauchy(0, 0.5) T[-1, 1];
  // sigma_rho ~ uniform(0.01, 1);
  // rho ~ normal(mu_rho, sigma_rho) T[-1, 1];
  
  mu_sigma ~ normal(-6, 40);
  sigma_sigma ~ uniform(0.05, 5);
  sigma ~ lognormal(mu_sigma, sigma_sigma);

  for (g in 1:G){
    Tg = Ts[g]; # length of timeseries g
    s = start_idx[g]; # starting point of timeseries g
    
    y[(s+1):(s+Tg-1)] ~ normal(y[s:(s+Tg-2)] + gamma[g] * y[s:(s+Tg-2)]^rho[g], sigma[g]) T[0,];
    
    // for (t in 1:(T_g-1)){
    //   y[s+t] ~ normal(y[s+t-1] + gamma[g] * y[s+t-1]^rho[g], sigma[g]) T[0,];
    // }
  }
}
