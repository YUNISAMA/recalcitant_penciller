functions {
  // get the log-likelihood of y given z, mu, sigma, and y_max
  real lognormal_mix_lpdf(real y, int z, real mu, real sigma, real y_max) {
    if (z == 1)
      return lognormal_lpdf(y | mu, sigma);
    else
      return uniform_lpdf(y | 0, y_max);
  }

  // simulate y given z, mu, sigma, and y_max
  real lognormal_mix_rng(int z, real mu, real sigma, real y_max) {
    if (z == 1)
      return lognormal_rng(mu, sigma);
    else
      return uniform_rng(0, y_max);
  }

  // forward algorithm for calculating log-likelihood of y
  array[,] real forward(vector y, array[] vector theta, vector pi, real mu, real sigma, real y_max) {
    int N = size(y);
    int K = size(pi);
    
    array[K] real acc;       // temporary variable
    array[N, K] real alpha;  // log p(y[1:n], z[n]==k)

    // first observation
    for (k in 1:K)
      alpha[1, k] = log(pi[k]) + lognormal_mix_lpdf(y[1] | k, mu, sigma, y_max);
    
    for (n in 2:N) {
      for (k in 1:K) {
	for (j in 1:K) {
	  // calculate log p(y[1:n], z[n]==k, z[n-1]==j)
	  acc[j] = alpha[n-1, j] + log(theta[j, k]) +
	    lognormal_mix_lpdf(y[n] | k, mu, sigma, y_max);
	}
	
	alpha[n, k] = log_sum_exp(acc);  // marginalize over all previous states j
      }
    }
    
    return alpha;
  }
}

data {
  int<lower=0> N;                         // number of data points
  vector<lower=0>[N] y;                   // data points
}

transformed data {
  int K = 2;                  // number of latent states (1=attentive, 2=guess)
  real y_max = max(y);        // maximum y value
}

parameters {
  array[K] simplex[K] theta;  // transition matrix
    
  real mu;                    // lognormal location
  real<lower=0> sigma;        // lognormal scale
}

transformed parameters {
  simplex[K] pi;              // starting probabilities

  {
    // copy theta to a matrix
    matrix[K, K] t;
    for(j in 1:K){
      for(i in 1:K){
	t[i,j] = theta[i,j];
      }
    }

    // solve for pi (assuming pi = pi * theta)
    pi = to_vector((to_row_vector(rep_vector(1.0, K))/
		    (diag_matrix(rep_vector(1.0, K)) - t + rep_matrix(1, K, K))));
  }

  array[N, K] real alpha = forward(y, theta, pi, mu, sigma, y_max);
}

model {
  for (k in 1:K)
    theta[k] ~ dirichlet([1, 1]');
  
  mu ~ std_normal();
  sigma ~ std_normal();

  target += log_sum_exp(alpha[N]);     // marginalize over all ending states  
}

generated quantities {
  array[N] int<lower=1, upper=K> z_rep;   // simulated latent variables
  vector<lower=0>[N] y_rep;               // simulated data points

  // simulate starting state
  z_rep[1] = categorical_rng(pi);
  y_rep[1] = lognormal_mix_rng(z_rep[1], mu, sigma, y_max);

  // simulate forward
  for (n in 2:N) {
    z_rep[n] = categorical_rng(theta[z_rep[n-1]]);
    y_rep[n] = lognormal_mix_rng(z_rep[n], mu, sigma, y_max);
  }
}


