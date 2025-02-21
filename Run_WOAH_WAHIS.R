library(rstan)
library(bayesplot)

rstan_options (auto_write = TRUE, threads_per_chain = 1)
options(mc.cores = parallel::detectCores ())

# Import outbreak data with the following information for each outbreak: 
# susceptible animals (unit_size), whether there was no dead animal or not (zero), dead animals (dead_new), 
# country of origin (country), season of outbreak (season), epidemiological unit of a premise (epi_unit), whether an outbreak was within a cluster or not (scan_cluster)
# Then, create an index data for each outbreak. 

data = read.csv(file = "data_sample.csv", header = T)

# Make variables factors to be correctly specified during model fitting. 
data$country = factor(data$country, levels = unique(data$country))
data$epi_unit = factor(data$epi_unit, levels = c("Commercial", "Backyard/Village"))
data$season = factor(data$season, levels = c("Winter", "Spring", "Summer", "Autumn"))
data$cluster = factor(data$cluster, levels = c("0.High income", "1.High income", "0.Upper middle income", "1.Upper middle income", "0.Lower middle income", "1.Lower middle income"))

# Check categories are in order for each factor variable. 
table(data$country)
table(data$epi_unit)
table(data$season)
table(data$cluster)

# For each outbreak, 'model.matrix' prepares an index for each category of the variables, ensuring that only the corresponding variables have effects. 
index = model.matrix(~ 0 + country + season + epi_unit + cluster, data = data)

# Verify whether the index names are correctly ordered according to the categories within each factor variable.
colnames(index)

# Total number of parameters to be estimated will be the sum of the followings.  
# 1) those in logistic regression for each fatality metric: ncol(index)*3
# 2) a parameter for the effect of premise size for the zero-fatality probability: 1
# 3) an overdispersion parameter: 1
no.par = ncol(index)*3 + 1 + 1

# Input data for model fitting 
input_data <- list(N = nrow(data),              # Total number of outbreaks 
                   V = ncol(index),             # The total number of parameters in the logistic regression for each fatality metric. Note that a parameter for the effect of premise size on the zero-fatality probability is specified separately in the model.
                   unit_size = data$premise_size,  # Premise size of each outbreak
                   dead = data$no_death,        # Number of dead animals at the notification of each outbreak 
                   index = index,               # Index for each category of the variables 
                   zero = data$zero_death,      # Index indicating whether a given outbreak was reported with no dead animals (No dead animals=1, otherwise 0). 
                   
                   max_overdispersion = 10,     # Upper prior limit of an overdispersion parameter. The lower prior limit is set to 0 directly in the model. 
                   max_threshold = max(data$no_death))  # Upper limit of the fatality threshold. Set to the maximum number of dead animals observed across the outbreaks assessed. 

# Run RStan for model fitting 
mcmc = stan(file = "Stan_WOAH_WAHIS.stan",  # Stan model code
            data = input_data,              # named list of data
            chains = 4,                     # number of Markov chains
            warmup = 2000,                  # number of warm-up iterations per chain
            iter = 4000,                    # total number of iterations per chain
            cores = 4)                      # number of cores (could use one per chain)

saveRDS(mcmc, file = "WOAH_WAHIS.rds") 

### Diagnostics of MCMC samples ### 
fit_summary = summary(mcmc)$summary

# Effective sample sizes
ESS_values = fit_summary[1:no.par, "n_eff"]
print(ESS_values)    

# Rhat values 
Rhat_values = fit_summary[1:no.par, "Rhat"]
print(Rhat_values)   

# Visually inspect trace plots
mcmc_trace(mcmc, pars = rownames(fit_summary)[1:(ncol(index)+1)]) # Parameters related to zero-fatality probability 
mcmc_trace(mcmc, pars = rownames(fit_summary)[(ncol(index)+2):(ncol(index)*2+1)]) # Parameters related to fatality slope
mcmc_trace(mcmc, pars = rownames(fit_summary)[(ncol(index)*2+2):(ncol(index)*3+1)]) # Parameters related to fatality threshold
mcmc_trace(mcmc, pars = rownames(fit_summary)[(ncol(index)*3+2)]) # Overdispersion parameter 

