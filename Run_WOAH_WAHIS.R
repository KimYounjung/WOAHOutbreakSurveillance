library(rstan)
library(bayesplot)
library(scales)

rstan_options (auto_write = TRUE, threads_per_chain = 1)
options(mc.cores = parallel::detectCores ())

# Import outbreak data with the following information for each outbreak: 
# susceptible animals (unit_size), whether there was no dead animal or not (zero), dead animals (dead_new), 
# country of origin (country), season of outbreak (season), epidemiological unit of a premise (epi_unit), whether an outbreak was within a cluster or not (scan_cluster)
# Then, create an index data for each outbreak. 

data = read.csv(file = "data_sample.csv", header = T)

which(data$zero_death == 1 & data$no_death != 0) # Check if there is any inconsistency between the number of dead animals and an indicator of zero dead animals at notification. 

# Make variables factors to be correctly specified during model fitting. 
data$country = factor(data$country, levels = unique(data$country))
data$epi_unit = factor(data$epi_unit, levels = c("Commercial", "Backyard/Village"))
data$season = factor(data$season, levels = c("Winter", "Spring", "Summer", "Autumn"))
data$cluster = factor(data$cluster, levels = c(0, 1))
data$income = factor(data$income, levels = c("High income", "Upper middle income", "Lower middle income"))

# Check categories are in order for each factor variable. 
table(data$country)
table(data$epi_unit)
table(data$season)
table(data$cluster)
table(data$income)

# Make a variable for the combination of cluster and income. 
data$cluster_by_income = interaction(data$cluster, data$income)

# For each outbreak, 'model.matrix' prepares an index for each category of the variables, ensuring that only the corresponding variables have effects. 
index = model.matrix(~ 0 + country + season + epi_unit + cluster_by_income, data = data)

# Verify whether the index names are correctly ordered according to the categories within each factor variable.
colnames(index)

# Total number of parameters to be estimated will be the sum of the followings.  
# 1) those in logistic regression for each fatality metric: ncol(index)*3
# 2) a parameter for the effect of premise size for the zero-fatality probability: 1
# 3) an overdispersion parameter: 1
no.par = ncol(index)*3 + 1 + 1

# Input data for model fitting 
input_data <- list(N = nrow(data),                 # Total number of outbreaks 
                   V = ncol(index),                # The total number of parameters in the logistic regression for each fatality metric. Note that a parameter for the effect of premise size on the zero-fatality probability is specified separately in the model.
                   unit_size = data$premise_size,  # Premise size of each outbreak
                   dead = data$no_death,           # Number of dead animals at the notification of each outbreak 
                   index = index,                  # Index for each category of the variables 
                   zero = data$zero_death,         # Index indicating whether a given outbreak was reported with no dead animals (No dead animals=1, otherwise 0). 
                   
                   max_overdispersion = 10,        # Upper prior limit of an overdispersion parameter. The lower prior limit is set to 0 directly in the model. 
                   max_threshold = max(data$no_death))  # Upper limit of the fatality threshold. Set to the maximum number of dead animals observed across the outbreaks assessed. 

# Run RStan for model fitting 
mcmc = stan(file = "Stan_WOAH_WAHIS.stan",  # Stan model code
            data = input_data,              # named list of data
            chains = 4,                     # number of Markov chains
            warmup = 2000,                  # number of warm-up iterations per chain
            iter = 4000,                    # total number of iterations per chain
            cores = 4)                      # number of cores (could use one per chain)

# Save MCMC samples 
saveRDS(mcmc, file = "WOAH_WAHIS.rds") 

################################################################################
### MCMC diagnostics ### 
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

################################################################################
### Posterior predictive check ### 

# Import MCMC samples 
post = readRDS(file = "WOAH_WAHIS.rds")              
post = extract(post, permuted = F, inc_warmup = T) 

# Combine MCMC chains into one data frame, discarding burn-in samples 
nchains = 4
post_chain = list()
for(i in 1:nchains) {
  post_chain[[i]] = post[2001:4000, i, 1:no.par]  }
post = do.call("rbind", post_chain)

# Predict the number of dead birds at initial outbreak notification based on MCMC samples
nSim = 1000    # No. of predictions  
set.seed(0513) # a random seed 
s = sample(1:nrow(post), nSim, replace = F) # Indices for joint posterior estimates 
 
country_list = unique(data$country) # Country indices
pred = list()

# Prediction will be conducted for each outbreak within each country to allow the computation of the total number of dead birds by country. 
for(k in 1:length(country_list)) {
  
  sub_data = data[which(data$country == country_list[k]),] 
  sub_index = index[which(data$country == country_list[k]),]
  pred[[k]] = matrix(NA, nrow = nSim, ncol = nrow(sub_data))
  
  for(i in 1:nSim) {
    
    for(j in 1:nrow(sub_data)) {
      
      prob_zero = plogis(sum(sub_index[j,] * post[s[i], 1:35]) + log10(sub_data$premise_size[j]) * post[s[i], 36])
      
      zero = rbinom(1,1,p=prob_zero)
      
      if(zero == 1) pred[[k]][i,j] = 0
      if(zero == 0) {
        scaled_slope = plogis(sum(sub_index[j,] * post[s[i], 37:71]))
        scaled_threshold = max(data$no_death) * plogis(sum(sub_index[j,] * post[s[i], 72:106]))
        mu = (sub_data$premise_size[j] * scaled_slope / (1 + (sub_data$premise_size[j] * scaled_slope) / scaled_threshold))
        pred[[k]][i,j] = rnbinom(1, mu = mu, size=post[s[i], 107])
      }}}
  
  print(k)
}

total = matrix(NA, nrow = length(country_list), ncol = nSim)
for(i in 1:length(country_list)) {
  total[i,] = rowSums(pred[[i]]) # Compute the total no. of dead birds per country per prediction
  }

total = as.data.frame(cbind(as.character(country_list), total))

# Compute the median and 95th percentile intervals across predictions per country  
for(i in 1:nrow(total)) {
  total$median[i] = median(as.numeric(total[i,2:1001]))
  total$lower[i] = quantile(as.numeric(total[i,2:1001]), 0.025)
  total$upper[i] = quantile(as.numeric(total[i,2:1001]), 0.975)
}

data$country = as.character(data$country)
colnames(total)[1] = "country_list"

# Attach the observed no. of dead birds reported per country 
for(i in 1:nrow(total)) {
  total$obs[i] = sum(data$no_death[which(data$country == total$country_list[i])])
}

# Check if there are countries whose 95th percentile intervals does not include the observed data 
total$country_list[which(total$obs < total$lower | total$obs > total$upper)] 

# Finally, plot the predicted and observed data. 
total$xaxis = 1:nrow(total)
plot(NA, 
     ylim = c(0, nrow(total)), 
     xlim = c(0, max(total$upper, total$obs)),
     xaxt = 'n', yaxt = 'n',
     xlab = NA, ylab = NA)
axis(side = 1, at = seq(0, 1800000, 300000), labels = seq(0, 1800000, 300000))
axis(side = 2, at = total$xaxis, labels = total$country_list, cex.axis = 0.9)
points(y=total$xaxis+0.2, x=total$obs, pch = 16, col = "black")
points(y=total$xaxis-0.2, x=total$median, pch = 17, col = "steelblue")     
arrows(total$lower, total$xaxis-0.2, 
       total$upper, total$xaxis-0.2,  
       length = 0, angle = 90, code = 3, lwd = 1, col = "steelblue")
mtext("Country ID", side = 2, line = 2.5, cex = 1.2)
mtext("No. of birds", side = 1, line = 2.5, cex = 1.2)
mtext("Predicted or observed no. of dead birds reported at initial notification per country", side = 3, line = 0.5, cex = 1.2)

