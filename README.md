# WOAHOutbreakSurveillance


1. Install R (https://www.r-project.org/) and RStan (RStan: https://mc-stan.org/users/interfaces/rstan) following the instructions on their respective websites. Both are open-source software.
2. Place "Run_WOAH_WAHIS.R", "Stan_WOAH_WAHIS.stan", "data_sample.csv" into the working folder.
3. The file "data_sample.csv" contains a sample of outbreak data where country/territory names are anonymised and randomly shuffled (raw data are publicly available from WOAH WAHIS at: https://wahis.woah.org/#/home).
4. Open "Run_WOAH_WAHIS.R" in R and run the model fitting following the steps as described (model fitting may take several hours depending on computer power).
5. The MCMC output will be saved as "WOAH_WAHIS.rds", allowing the analysis of posterior parameter estimates.   
