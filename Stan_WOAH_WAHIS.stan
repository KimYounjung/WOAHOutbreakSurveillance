data {
  int N;
  int V;

  vector[N] unit_size;
  int dead[N];
  int zero[N];
  matrix[N, V] index;

  real max_threshold;
  real max_overdispersion;
}

parameters {
  vector[V] early;
  real early_size;
  vector[V] slope;
  vector[V] threshold;
  real<lower=0, upper=max_overdispersion> overdispersion;
}

model {
  early ~ normal(0, 2);
  early_size ~ normal(0, 2);
  slope ~ normal(0, 2);
  threshold ~ normal(0, 2);
  overdispersion ~ uniform(0, max_overdispersion);

  vector[N] prob_zero = inv_logit(index * early + log10(unit_size) * early_size);
  vector[N] scaled_slope = inv_logit(index * slope);
  vector[N] scaled_threshold = max_threshold * inv_logit(index * threshold);

  zero ~ bernoulli(prob_zero);
  
  vector[N] mu = (unit_size .* scaled_slope) ./ (1 + (unit_size .* scaled_slope) ./ scaled_threshold);
  vector[N] prob = overdispersion ./ (overdispersion + (1 - to_vector(zero)) .* mu) - 1e-10 * to_vector(zero);

  dead ~ neg_binomial_2(overdispersion .* (1 - prob) ./ prob, overdispersion);
}

generated quantities {
  vector[N] log_lik;
  vector[N] gen_prob_zero = inv_logit(index * early + log10(unit_size) * early_size);
  vector[N] gen_scaled_slope = inv_logit(index * slope);
  vector[N] gen_scaled_threshold = max_threshold * inv_logit(index * threshold);

  vector[N] gen_mu = (unit_size .* gen_scaled_slope) ./ (1 + (unit_size .* gen_scaled_slope) ./ gen_scaled_threshold);
  vector[N] gen_prob = overdispersion ./ (overdispersion + (1 - to_vector(zero)) .* gen_mu) - 1e-10 * to_vector(zero);

  for (i in 1:N) {
    log_lik[i] = bernoulli_lpmf(zero[i] | gen_prob_zero[i]) + 
                 neg_binomial_2_lpmf(dead[i] | overdispersion * (1 - gen_prob[i]) / gen_prob[i], overdispersion);
  }
}