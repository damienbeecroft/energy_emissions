data {
	real<lower=0> CAUCHY_SD;
	real MIN_POW;
	real MAX_POW;
	real<lower=0> MIN_SIGMA;
	real<lower=1> MIN_NU;
	real<lower=1> MAX_NU;
	int<lower=1> N; # total number of data points == sum(Ts)
	int<lower=1> G; # number of groups
	int Ts[G]; # lengths of each timeseries
	int start_idx[G]; # start index of each timeseries
	vector<lower=0>[N] y; # all data
}

parameters {
	real <lower=MIN_NU,upper=MAX_NU> nu;
	vector <lower=0,upper=1> [G] alpha;
	vector <lower=0,upper=1> [G] beta;
	vector <lower=0,upper=1> [G] lam;
	vector <lower = MIN_SIGMA> [G] sigma;
	vector <lower=0, upper=1> [G] rho_unshifted;
	vector [G] gamma;
}

transformed parameters {
	vector <lower=MIN_POW,upper=MAX_POW> [G] rho;
	rho = (MAX_POW-MIN_POW)*rho_unshifted + MIN_POW;
}

model {
  alpha ~ uniform(0,1);
  beta ~ uniform(0,1);
  lam ~ uniform(0,1);
  rho_unshifted ~ uniform(0,1);
	sigma ~ cauchy(MIN_SIGMA,CAUCHY_SD) T[MIN_SIGMA,];
	gamma ~ cauchy(0,CAUCHY_SD);

  vector[N] l;
  vector[N] b;

  for (g in 1:G){
    int T_g = Ts[g]; # length of timeseries g
    int s = start_idx[g]; # starting point of timeseries g

    l[s] = y[s];
    b[s] = 0;

    for (t in 2:T_g) {
      l[s + t - 1] = alpha[g] * y[s + t - 1] + (1 - alpha[g]) * l[s + t - 2];
      b[s + t - 1] = beta[g] * (l[s + t - 1] - l[s + t - 2]) + (1 - beta[g]) * b[s + t - 2];
    }
  	
  	for (t in 2:T_g) {
  		y[s + t - 1] ~ student_t(nu, l[s + t - 2] + gamma[g]*fabs(l[s + t - 2])^rho[g] + lam[g]*b[s + t - 2],
  				sigma[g]);
  	}
  }
}
