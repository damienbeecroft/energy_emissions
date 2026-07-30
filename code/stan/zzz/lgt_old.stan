// GLOBAL NU AND NO HIERARCHICAL STRUCTURE OTHERWISE --------------
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
	// int<lower=1, upper=G> group[N]; # group index
	vector<lower=0>[N] y; # all data
}

parameters {
	real <lower=MIN_NU,upper=MAX_NU> nu;
	vector <lower=0,upper=1> [G] levSm;
	vector <lower=0,upper=1> [G] bSm;
	vector <lower=-1,upper=1> [G] locTrendFract;
	vector <lower=MIN_SIGMA> [G] offsetSigma;
	vector <lower=0,upper=1> [G] powTrendBeta;
	vector [G] coefTrend;
}

transformed parameters {
	vector <lower=MIN_POW,upper=MAX_POW> [G] powTrend;
	powTrend = (MAX_POW-MIN_POW)*powTrendBeta+MIN_POW;
}

model {
	offsetSigma ~ cauchy(MIN_SIGMA,CAUCHY_SD) T[MIN_SIGMA,];
	coefTrend ~ cauchy(0,CAUCHY_SD);

  vector[N] l;
  vector[N] b;

  for (g in 1:G){
    int T_g = Ts[g]; # length of timeseries g
    int s = start_idx[g]; # starting point of timeseries g

    l[s] = y[s];
    b[s] = 0;

    for (t in 2:T_g) {
      l[s + t - 1] = levSm[g] * y[s + t - 1] + (1 - levSm[g]) * l[s + t - 2];
      b[s + t - 1] = bSm[g] * (l[s + t - 1] - l[s + t - 2]) + (1 - bSm[g]) * b[s + t - 2];
    }

  	for (t in 2:T_g) {
  		y[s + t - 1] ~ student_t(nu, l[s + t - 2] + coefTrend[g]*fabs(l[s + t - 2])^powTrend[g] + locTrendFract[g]*b[s + t - 2],
  				offsetSigma[g]);
  	}
  }
}

// model {
// 	offsetSigma ~ cauchy(MIN_SIGMA,CAUCHY_SD) T[MIN_SIGMA,];
// 	coefTrend ~ cauchy(0,CAUCHY_SD);
// 
//   vector[N] l;
//   vector[N] b;
// 
//   for (g in 1:G){
//     int T_g = Ts[g]; # length of timeseries g
//     int s = start_idx[g]; # starting point of timeseries g
// 
//     l[s] = y[s];
//     b[s] = 0;
// 
//     for (t in 2:T_g) {
//       l[s + t - 1] = levSm[group[s + t - 1]] * y[s + t - 1] + (1 - levSm[group[s + t - 1]]) * l[s + t - 2];
//       b[s + t - 1] = bSm[group[s + t - 1]] * (l[s + t - 1] - l[s + t - 2]) + (1 - bSm[group[s + t - 1]]) * b[s + t - 2];
//     }
// 
//   	for (t in 2:T_g) {
//   		y[s + t - 1] ~ student_t(nu, l[s + t - 2] + coefTrend[group[s + t - 1]]*fabs(l[s + t - 2])^powTrend[group[s + t - 1]] + locTrendFract[group[s + t - 1]]*b[s + t - 2],
//   				offsetSigma[group[s + t - 1]]);
//   	}
//   }
// }
