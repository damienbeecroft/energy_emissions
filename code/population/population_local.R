# The following code is modified from the work of Hana Sevcikova, hanas@uw.edu
# Web links to the original code are given below.

# Load Packages and Declare Global Variables -----------------------------------
# source("C:/Users/damie/OneDrive/UW/research/dargan/projects/iea_analysis_ratio/code/helper_functions.R")

library(bayesPop)
# using bayesTFR version 7.4-4
library(bayesTFR)
library(data.table)
# using bayesLife version 5.3-0
library(bayesLife)
# using bayesMig version 0.4-7
library(bayesMig)

# Pre-requisites
# Install the wpp2024 package from GitHub
if(! "wpp2024" %in% installed.packages()) {
  library(devtools)
  options(timeout = 600) # allow the installation to take longer than 1 minute
  devtools::install_github("PPgp/wpp2024")
}

work.path <- "C:/Users/damie/OneDrive/UW/research/dargan/projects/iea_analysis_ratio/forecasts_n_validation/traces/population/"
# work.path <- "/mmfs1/gscratch/amath/dob1998/population/sim/"

# download the UN's raw TFR file to assess the uncertainty around estimates
# download.file("https://bayespop.csss.washington.edu/data/bayesTFR/rawTFR2024pub.csv", "rawTFR2024pub.csv")

# determine VR unbiased countries based on the proportion of births
## registered in vital statistics ("VR_completeness")
## since 1950 (or available years) using 0.98 or higher as cutoff for full coverage (i.e, 98%)
raw.tfr <- fread("rawTFR2024pub.csv")
vr.unbiased <- raw.tfr[DataProcess == "VR", .(is_good_vr = all(VR_completeness >= 0.98)),
                       by = "country_code"][is_good_vr == TRUE, country_code]

# Total Fertility Rate variables
# tfr.iter <- 10000
# tfr.burnin <- 1000
# tfr.thin <- 3
# tfr.nr.chains <- 3
# tfr.nr.traj <- 1000

tfr.iter <- 110
tfr.burnin <- 10
tfr.thin <- 1
tfr.nr.chains <- 3
tfr.nr.traj <- 100

# Life Expectancy variables
# e0.iter <- 21000
# e0.burnin <- 1000
# e0.thin <- 5
# e0.nr.chains <- 3
# e0.nr.traj <- 1000

e0.iter <- 110
e0.burnin <- 10
e0.thin <- 1
e0.nr.chains <- 3
e0.nr.traj <- 100

# # Migration variables
# mig.iter <- 11000
# mig.burnin <- 1000
# mig.thin <- 1
# mig.nr.chains <- 3
# mig.nr.traj <- 1000

# Migration variables
mig.iter <- 110
mig.burnin <- 10
mig.thin <- 1
mig.nr.chains <- 3
mig.nr.traj <- 100

# Population variables
pop.nr.traj <- 1000

seed <- 20241101
last.data.year <- 2022
lags <- c(0,10,20)

for(lag in lags){
  
  tfr.dir <- paste0(work.path, "TFR/TFR_lag_", toString(lag), "_small")
  if(!dir.exists(tfr.dir)){
    dir.create(tfr.dir, recursive = TRUE)
  }
  
  e0.dir <- paste0(work.path, "E0/E0_lag_", toString(lag), "_small")
  if(!dir.exists(e0.dir)){
    dir.create(e0.dir, recursive = TRUE)
  }
  
  mig.dir <- paste0(work.path, "MIG/MIG_lag_", toString(lag), "_small")
  if(!dir.exists(mig.dir)){
    dir.create(mig.dir, recursive = TRUE)
  }
  
  pop.dir <- paste0(work.path, "POP/POP_lag_", toString(lag), "_small")
  if(!dir.exists(pop.dir)){
    dir.create(pop.dir, recursive = TRUE)
  }
  
  forecast.year <- last.data.year - lag
  
  if(lag==0){
    end.year <- 2050
  }else{
    end.year <- last.data.year
  }
  
  # Total Fertility Rate ---------------------------------------------------------
  print("Running TFR\n")
  # Modified from https://bayespop.csss.washington.edu/data/bayesTFR/TFRsimWPP2024/TFR1unc/README.r

  t1 <- Sys.time()

  # Phase II MCMC & III MCMC (big and small countries)
  tfr.m <- run.tfr.mcmc(iter = tfr.iter, thin = tfr.thin,
                        nr.chains = tfr.nr.chains, output.dir = tfr.dir, replace.output = TRUE,
                        start.year = 1950, present.year = forecast.year, wpp.year = 2024,
                        annual = TRUE, uncertainty = TRUE, ar.phase2 = TRUE,
                        my.tfr.raw.file = "rawTFR2024pub.csv",
                        ## categorical and continuous covariates to take into account when estimating uncertainty about the estimates
                        covariates=c("DataProcess", "DataTypeGroupName2", "EducationLevel"),
                        cont_covariates=c("RecallLag", "VR_completeness", "EnrolmentRate", "prop_Dx_Crises"),
                        source.col.name = "DataProcess", # which column is the data source
                        iso.unbiased = vr.unbiased,
                        seed = seed, buffer.size = 100,
                        parallel = TRUE # if set to TRUE, run it from a command line and NOT from RStudio
  )

  # # center around WPP estimates
  # m <- tfr.shift.estimation.to.wpp(tfdir, burnin = burnin)

  t2 <- Sys.time()
  cat("\nTFR Estimation time: ", t2-t1)

  # Projections
  print("Trial")
  tfr.pred <- tfr.predict(sim.dir = tfr.dir, end.year = end.year, uncertainty = TRUE, replace.output = TRUE,
                          burnin = tfr.burnin, burnin3 = tfr.burnin, nr.traj = tfr.nr.traj,
                          seed = seed, use.correlation = TRUE)

  t3 <- Sys.time()
  cat("\nTFR Projection time: ", t3-t2)
  cat("\nTFR Total time: ", t3-t1)
  
  # Life Expectancy --------------------------------------------------------------
  # Modified from https://bayespop.csss.washington.edu/data/bayesLife/WPP2024/e01/README.r

  print("Running Life Expectancy")
  t1 <- Sys.time()

  # simulate MCMC using female data
  e0.m <- run.e0.mcmc(iter = e0.iter, thin = e0.thin,
                      nr.chains = e0.nr.chains, output.dir = e0.dir, replace.output = TRUE,
                      start.year = 1873, present.year = forecast.year, wpp.year = 2024,
                      annual = TRUE, seed = seed,
                      parallel = TRUE # if set to TRUE, run it from a command line and NOT from RStudio
  )

  print("Running Extra Countries")
  # generate MCMCs and projections for HIV/AIDS countries
  # (MCMCs for small countries were already generated within the previous step)
  data(include_2024, package = "bayesLife")
  countries <- subset(include_2024, include_code == 3)$country_code
  e0.m.aids <- run.e0.mcmc.extra(sim.dir = e0.dir, countries = countries,
                                 parallel = TRUE)


  t2 <- Sys.time()

  cat("\nEstimation time: ", t2-t1)

  # generate predictions for all countries (female and male)
  e0.pred <- e0.predict(sim.dir = e0.dir, end.year = end.year, replace.output = TRUE,
                        burnin = e0.burnin, nr.traj = e0.nr.traj, seed = seed)

  # # align medians with to WPP 2024 middle series
  # e0.shift.prediction.to.wpp(e0dir, stat = "mean") # female
  # e0.shift.prediction.to.wpp(e0dir, stat = "mean", joint.male = TRUE) # male

  # to remove the adjustment, run
  # e0.median.reset(e0dir) # female
  # e0.median.reset(e0dir, joint.male = TRUE) # female

  t3 <- Sys.time()
  cat("\nProjection time: ", t3-t2)
  cat("\nTotal time: ", t3-t1)
  
  # Migration --------------------------------------------------------------------
  # Modified from https://bayespop.csss.washington.edu/data/bayesMig/mig1traj/README.r
  print("Running Migration")
  
  # extract small countries that will be excluded from influencing the world parameters
  data(include_2024, package = "bayesTFR")
  small.countries <- subset(include_2024, include_code == 1)$country_code
  
  t1 <- Sys.time()
  
  # Estimate the migration model
  mig.mcmc <- run.mig.mcmc(nr.chains = mig.nr.chains,
                           wpp.year = 2024,
                           thin = mig.thin,
                           iter = mig.iter,
                           verbose.iter = 1000,
                           present.year = forecast.year,
                           output.dir = mig.dir,
                           annual = TRUE,
                           exclude.from.world = small.countries,
                           parallel = TRUE,
                           replace.output = FALSE)
  
  t2 <- Sys.time()
  cat("\nEstimation time: ", t2-t1, "\n")
  
  # Project migration rates
  mig.pred <- mig.predict(sim.dir = mig.dir,
                          nr.traj = mig.nr.traj,
                          burnin = mig.burnin,
                          replace.output = TRUE,
                          end.year = end.year,
                          use.cummulative.threshold = TRUE)
  
  t3 <- Sys.time()
  cat("\nProjection time: ", t3-t2, "\n")

  # remove adjustment
  mig.median.reset(mig.dir)

  # convert trajectories for all countries into an ASCII file
  convert.mig.trajectories(sim.dir = mig.dir,
                           n = mig.nr.traj,
                           output.dir = mig.dir,
                           verbose = TRUE)

  # The above function generated a file {mig.dir}/ascii_trajectories.csv which is included
  # in this directory and can be used as input into population projections.

  t4 <- Sys.time()
  cat("\nTotal time: ", t4-t1, "\n")

  # Population -----------------------------------------------------------------
  pop.predict(annual=TRUE,
              end.year=end.year,
              start.year=1950,
              present.year=forecast.year,
              wpp.year=2024,
              output.dir=pop.dir,
              nr.traj=1000,
              replace.output=TRUE,
              mig.is.rate = c(FALSE, TRUE),
              inputs=list(tfr.sim.dir=tfr.dir,
                          e0F.sim.dir=e0.dir,
                          e0M.sim.dir="joint_",
                          migtraj = paste0(mig.dir,"/ascii_trajectories.csv")))
}



