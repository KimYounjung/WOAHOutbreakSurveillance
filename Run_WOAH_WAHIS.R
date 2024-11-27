library(rstan)
library(gridExtra)
rstan_options (auto_write = TRUE, threads_per_chain = 1)
options(mc.cores = parallel::detectCores ())

# Import outbreak data with the following information for each outbreak: 
# susceptible animals (unit_size), whether there was no dead animal or not (zero), dead animals (dead_new), 
# country of origin (country), season of outbreak (season), epidemiological unit of a premise (epi_unit), whether an outbreak was within a cluster or not (scan_cluster)
# Then, create an index data for each outbreak. 
index = model.matrix(~ 0 + country + season + epi_unit + scan_cluster, data = data)

# specify input data for model fitting 
input_data <- list(N = nrow(data),
                   V = ncol(index),

                   unit_size = data$unit_size, 
                   dead = data$dead_new,
                   index = index,
                   zero = data$zero,
                   
                   max_overdispersion = 10,
                   max_threshold = max(data$dead_new))

# Run RStan for model fitting 
mcmc = stan(file = "WOAH_WAHIS.stan",  # Stan program
            data = input_data,         # named list of data
            chains = 4,                # number of Markov chains
            warmup = 1000,             # number of warm-up iterations per chain
            iter = 2000,               # total number of iterations per chain
            cores = 4)                 # number of cores (could use one per chain)

saveRDS(mcmc, file = "WOAH_WAHIS.rds")

