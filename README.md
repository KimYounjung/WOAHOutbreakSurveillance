# **README: WOAH WAHIS Data and Model Fitting**

## **1. Installing Required Software Programs**

### **1.1 Install R**

Download and install R: [https://www.r-project.org/](https://www.r-project.org/).

### **1.2 Install RStan**

Install **RStan**: [https://github.com/stan-dev/rstan/wiki/RStan-Getting-Started](https://github.com/stan-dev/rstan/wiki/RStan-Getting-Started).

**Important Note:**\
Before installing **RStan**, you must configure your R installation to compile C++ code. It is crucial to follow the setup steps detailed on the above RStan website to avoid installation issues.

### **1.3 Install the "bayesplot" Package**

Install the **bayesplot** package in R, which is used for examining MCMC traceplots:

```r
install.packages("bayesplot")
```

---

## **2. WOAH WAHIS Data**

### **2.1 Data Overview**

The file **"data\_sample.csv"** contains a sample of **Highly Pathogenic Avian Influenza (HPAI) outbreak data**. To comply with **WOAH** guidance, country/territory names have been anonymised and randomly shuffled.

### **2.2 Variables in "data\_sample.csv"**

The dataset is ready for model fitting and includes the following variables:

- **outbreak\_ID**: Unique identifier for each outbreak (anonymised).
- **country**: The name of the country/territory where the outbreak was notified (anonymised).
- **epi\_unit**: The epidemiological unit of the premise where the outbreak was notified. The dataset includes two categories:
  - **Commercial**
  - **Backyard/Village**
- **premise\_size**: Number of susceptible animals on the premise. Since premise size is right-skewed, it is log-transformed during model fitting (see `"WOAH_WAHIS.stan"`).
- **no\_death**: Number of dead animals at outbreak notification. The model is fitted to this data using a negative binomial distribution (see `"WOAH_WAHIS.stan"`).
- **zero\_death**: Binary variable indicating whether an outbreak was notified with zero deaths. The model is fitted to this data using a Bernoulli distribution (see `"WOAH_WAHIS.stan"`).
- **season**: The season in which the outbreak occurred.
  - For countries/territories in the Northern Hemisphere:
    - **Spring**: March–May
    - **Summer**: June–August
    - **Autumn**: September–November
    - **Winter**: December–February
  - For countries/territories in the Southern Hemisphere with distinct seasons, different months were assigned accordingly.
- **cluster**: Classification of outbreaks based on spatiotemporal clustering:
  - **1** = within a cluster
  - **0** = outside a cluster
- **income**:
  - **High income**
  - **Upper middle income**
  - **Lower middle income**

### **2.3 Raw Data Source**

The raw outbreak data are publicly available from the **WOAH WAHIS** platform: [https://wahis.woah.org/#/home](https://wahis.woah.org/#/home)

---

## **3. Model Fitting and Diagnostics**

### **3.1 Running the Model**

1. Open **"Run\_WOAH\_WAHIS.R"** in R.
2. Follow the steps described in the script to **run the model fitting**.
3. Model fitting may take long (e.g. a couple of hours), depending on computational power.
4. After a model run, save the MCMC output as **"WOAH\_WAHIS.rds"**.

### **3.2 Performing MCMC Diagnostics**

After model fitting, perform MCMC diagnostics, including:

- **Assessing R-hat values**.
- **Checking effective sample sizes (ESS)**.
- **Examining traceplots**.

### **3.3 Posterior predictive check**

- After running the model, users can expect to see a plot similar to the one below, comparing observed and predicted numbers of dead birds.

![Posterior Predictive Check Plot](https://github.com/KimYounjung/WOAHOutbreakSurveillance/raw/main/Posterior%20predictive%20check%20plot.png)

- The black dots represent observed data, while the blue triangles and error bars show the median and 95th percentile intervals of predicted number of dead birds per each country/territory.
---

## **Final Notes**

- If you encounter installation issues with RStan, refer to the official troubleshooting guide: [https://github.com/stan-dev/rstan](https://github.com/stan-dev/rstan).
- If you encounter any issues in model fitting, please contact **Younjung Kim** [metopeja@gmail.com](metopeja@gmail.com).
---
