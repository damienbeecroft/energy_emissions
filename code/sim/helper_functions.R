library(tidyverse)
library(stringr)
library(purrr)
library(rstan)
library(truncnorm)
library(strucchange)
library(crch)
library(data.table)
library(bayesMig)
library(bayesPop)
library(bayesTFR)
library(bayesLife)
library(tidyr)
library(writexl)
library(abind)
library(scales)
library(bayesplot)
# GLOBAL VARIABLES -------------------------------------------------------------
data("UNlocations")
POP_SAVE_PATH <- "C:/Users/damie/population/" # path where population data is stored (change if running yourself)
WORK_PATH <- "C:/Users/damie/OneDrive/UW/research/dargan/projects/energy_emissions/" # work directory (change if running yourself)
TFDIR <- paste0(POP_SAVE_PATH,"sim/TFR/") # total fertility rate directory
E0DIR <- paste0(POP_SAVE_PATH,"sim/E0/") # mortality rate directory
LOAD_PATH <- paste0(WORK_PATH,"data/processed/") # path to load the data from
SAVE_PATH <- paste0(WORK_PATH,"projections_n_validation/") # path where plots and posteriors are saved
STAN_PATH <- paste0(WORK_PATH,"code/stan/") # path for stan files
TRACE_PATH <- paste0(SAVE_PATH,"traces/") # path to save the posterior samples (also called the traces)
PLOT_PATH <- paste0(SAVE_PATH,"plots/") # path to save the plots
# Full Run ##########################################################
CHAINS <- 4 # chains to run for MCMC
WARMUP <- 2000 # warm-up iterations for MCMC
ITER <- 10000 + WARMUP # total number of iterations per MCMC chain
# Test Run ##########################################################
# CHAINS <- 1 # chains to run for MCMC
# WARMUP <- 2000 # warm-up iterations for MCMC
# ITER <- 5000 # total number of iterations per MCMC chain
#####################################################################
CORES <- 4 # number of cores (should be the same as the number of chains)
REFRESH <- 1000 # how often to show MCMC progress
HORIZON <- 28 # forecast horizon
DRAWS <- CHAINS * (ITER - WARMUP) # number of posterior draws to use
REGIONS = 25 # number of global regions
LAGS = c(0, 10, 20) # amount of data to chop off during validation (include 0 to do a forecast into the future as well)
SOVIET_END = 1989 # all data on and before this year is removed from all countries in the former Soviet Union
YEAR = 2022 # last available year of data

# GENERAL PURPOSE FUNCTIONS ----------------------------------------------------

inv_scaled_logistic <- function(x){
  0.5 * log((0.5 * x + 0.5)/(1 - (0.5 * x + 0.5))) 
}

scaled_logistic <- function(x){
  ((exp(-2 * x) + 1)^-1 - 0.5)/0.5
}

aggregate_timeseries <- function(all_data,
                                 lag,
                                 draws=DRAWS,
                                 regions=REGIONS,
                                 horizon=HORIZON,
                                 year=YEAR,
                                 sample_size=10000){
  
  #' Collect simulations for all individual components into all_data
  #'
  #' @param all_data A container for all of the individual simulations
  #' @param lag The number of years chopped before simulation. lag=0 is for
  #'            forecasting and lag>0 is for validation
  #' @param draws The number of posterior draws to use
  #' @param regions The number of global regions
  #' @param horizon The number of years to project forwards if lag=0
  #' @param year The last available year of data
  #' @param sample_size Number of samples to take from posterior distribution
  #' @returns Simulations for all time series components
  #' @export
  
  if(lag == 0){ # forecast mode
    forecast_range <- year + c(1:horizon)
    forecast_length <- length(forecast_range)
  }
  else{ # validation mode
    forecast_range <- year + c((-lag+1):0)
    forecast_length <- length(forecast_range)
  }
  
  # create and store simulations for the relevant variable
  for (name in names(all_data)){ 
    print(name)
    if(name=="population"){
      files <- list.files(paste0(POP_SAVE_PATH,"sim/POP/POP_lag_",toString(lag),"/aggregations_energy_regions"))
      files <- files[files != "prediction.rda"]
      load((paste0(POP_SAVE_PATH,"sim/POP/POP_lag_",toString(lag),"/aggregations_energy_regions/",files[1])))
      dim_totp <- dim(t(totp))
      bootstrap <- array(0, c(dim_totp[1], files%>%length, dim_totp[2] - 1)) # initialize array of zeros
      
      idx <- 1
      for (file in files){
        load((paste0(POP_SAVE_PATH,"sim/POP/POP_lag_",toString(lag),"/aggregations_energy_regions/",file)))
        totp <- t(totp)
        ncols <- dim(totp)[2]
        bootstrap[,idx,] <- (totp[,-c(1)] + totp[,-c(ncols)])/2
        idx <- idx + 1
      }
      
      mask <- colnames(all_data[[name]][["data"]]) != "year"
      dimnames(bootstrap) <- list(NULL,colnames(all_data[[name]][["data"]][mask]), forecast_range)
      bootstrap <- 1e3 * bootstrap # forecasts are in thousands, bring down to individuals
      dim1 <- dim(bootstrap)[1]
      row_samples <- sample(1:dim1, sample_size, replace=TRUE)
      all_data[[name]][["forecast"]] <- bootstrap[row_samples,,]
    }
    else if(name=="gdp_per_capita"){
      fit <- readRDS(all_data[[name]][["directory"]])
      make_forecast <- get_make_forecast(all_data[[name]][["method"]])
      
      data <- all_data[[name]][["data"]]
      data <- data[data$year < (YEAR-lag+1),]
      data <- data[colnames(data) != "year"]
      data[-c(1)] <- data[-c(1)] / data[,1] # compute ratios
      
      bootstrap <- make_forecast(draws, regions, forecast_length, fit, data, return_bootstrap=TRUE)

      dimnames(bootstrap) <- list(NULL,colnames(data), forecast_range)
      dim1 <- dim(bootstrap)[1]
      row_samples <- sample(1:dim1, sample_size, replace=TRUE)
      all_data[[name]][["forecast"]] <- bootstrap[row_samples,,]
    }
    else if(name=="energy_per_gdp"){
      fit <- readRDS(all_data[[name]][["directory"]])
      make_forecast <- get_make_forecast(all_data[[name]][["method"]])
      
      data <- all_data[[name]][["data"]]
      data <- data[data$year < (YEAR-lag+1),]
      data <- data[colnames(data) != "year"]
      data <- log(data, base=10)
      
      bootstrap <- make_forecast(draws, regions, forecast_length, fit, data, return_bootstrap=TRUE)
      bootstrap <- 10^bootstrap
      
      dimnames(bootstrap) <- list(NULL, colnames(data), forecast_range)
      dim1 <- dim(bootstrap)[1]
      row_samples <- sample(1:dim1, sample_size, replace=TRUE)
      all_data[[name]][["forecast"]] <- bootstrap[row_samples,,]
    }
    else if(name=="fraction_elec_n_heat"){
      fit <- readRDS(all_data[[name]][["directory"]])
      make_forecast <- get_make_forecast(all_data[[name]][["method"]])
      
      data <- all_data[[name]][["data"]]
      data <- data[data$year < (YEAR-lag+1),]
      data <- data[colnames(data) != "year"]
      data <- inv_scaled_logistic(data)
      
      bootstrap <- make_forecast(draws, regions, forecast_length, fit, data, return_bootstrap=TRUE)
      bootstrap <- scaled_logistic(bootstrap)
      
      dimnames(bootstrap) <- list(NULL, colnames(data), forecast_range)
      dim1 <- dim(bootstrap)[1]
      row_samples <- sample(1:dim1, sample_size, replace=TRUE)
      all_data[[name]][["forecast"]] <- bootstrap[row_samples,,]
    }
    else{
      fit <- readRDS(all_data[[name]][["directory"]])
      make_forecast <- get_make_forecast(all_data[[name]][["method"]])
      
      data <- all_data[[name]][["data"]]
      data <- data[data$year < (YEAR-lag+1),]
      data <- data[colnames(data) != "year"]
                                         
      bootstrap <- make_forecast(draws, regions, forecast_length, fit, data, return_bootstrap=TRUE)
      
      dimnames(bootstrap) <- list(NULL,colnames(data), forecast_range)
      dim1 <- dim(bootstrap)[1]
      row_samples <- sample(1:dim1, sample_size, replace=TRUE)
      all_data[[name]][["forecast"]] <- bootstrap[row_samples,,]
    }
  }
  all_data
}

make_aggregate_plots <- function(all_data,
                                 lag,
                                 forecast_type,
                                 cols,
                                 path,
                                 title,
                                 ylabel,
                                 horizon=HORIZON,
                                 regions=REGIONS,
                                 year=YEAR,
                                 scale=1,
                                 log_scale=FALSE,
                                 global=FALSE,
                                 test=FALSE){
  
  #' Create aggregate plots
  #'
  #' @param all_data A container for all of the individual simulations
  #' @param lag The number of years chopped before simulation. lag=0 is for
  #'            forecasting and lag>0 is for validation
  #' @param forecast_type Name of the forecast component: total_energy_emissions,
  #'                      energy_per_capita, emissions_per_energy, 
  #'                      electricity_per_capita, total_electricity_emissions,
  #'                      total_nonelectricity_emissions, gdp_per_capita, 
  #'                      energy_per_gdp, electrification, 
  #'                      emissions_per_elec, emissions_per_fuel
  #' @param cols The list of countries to be plotted
  #' @param path The path for the plot to be saved to
  #' @param title Plot title
  #' @param ylabel Plot y axis label
  #' @param scale Scales the data to implement coordinate change
  #' @param log_scale If true the y axis is log scale, otherwise the scale is linear
  #' @param horizon The number of years to project forwards if lag=0
  #' @param regions The number of global regions
  #' @param year The last available year of data
  #' @param global If true, produce a global plot
  #' @param test If true, save plots in a separate test directory
  #' @returns Simulations for all time series components
  #' @export
  
  
  print_str <- paste0("Plotting ",
                      forecast_type,
                      " for lag ",
                      lag)
  print(print_str)

  population_d <- all_data[["population"]][["data"]][,cols,]
  gdp_per_capita_d <- all_data[["gdp_per_capita"]][["data"]][,cols,]
  energy_per_gdp_d <- all_data[["energy_per_gdp"]][["data"]][,cols,]
  electrification_d <- all_data[["fraction_elec_n_heat"]][["data"]][,cols,]
  emissions_per_elec_d <- all_data[["emissions_per_elec_n_heat"]][["data"]][,cols,]
  emissions_per_fuel_d <- all_data[["emissions_per_direct"]][["data"]][,cols,]
  
  population_f <- all_data[["population"]][["forecast"]][,cols,]
  gdp_per_capita_f <- all_data[["gdp_per_capita"]][["forecast"]][,cols,]
  energy_per_gdp_f <- all_data[["energy_per_gdp"]][["forecast"]][,cols,]
  electrification_f <- all_data[["fraction_elec_n_heat"]][["forecast"]][,cols,]
  emissions_per_elec_f <- all_data[["emissions_per_elec_n_heat"]][["forecast"]][,cols,]
  emissions_per_fuel_f <- all_data[["emissions_per_direct"]][["forecast"]][,cols,]
  
  population_g <- all_data[["population"]][["global"]]
  gdp_per_capita_g <- all_data[["gdp_per_capita"]][["global"]]
  energy_per_gdp_g <- all_data[["energy_per_gdp"]][["global"]]
  electrification_g <- all_data[["fraction_elec_n_heat"]][["global"]]
  emissions_per_elec_g <- all_data[["emissions_per_elec_n_heat"]][["global"]]
  emissions_per_fuel_g <- all_data[["emissions_per_direct"]][["global"]]
  
  get_global_ratio_d <- function(numerator,
                                 denominator){

    numerator[is.na(numerator)] <- 0
    denominator[is.na(denominator)] <- 0
    
    numerator <- rowSums(numerator[cols])
    denominator <- rowSums(denominator[cols])
    
    ratio <- numerator/denominator
    
    return(ratio)
  }
  
  get_global_ratio_f <- function(numerator,
                                 denominator){
    numerator <- apply(numerator, c(1,3), sum)
    denominator <- apply(denominator, c(1,3), sum)
    
    ratio <- numerator/denominator
    
    return(ratio)
  }
  
  if(lag == 0){ # forecast mode
    forecast_range <- year + c(1:horizon)
    forecast_length <- length(forecast_range)
  }
  else{ # validation mode
    forecast_range <- year + c((-lag+1):0)
    forecast_length <- length(forecast_range)
  }
  
  if(forecast_type == "total_energy_emissions"){
    data <- (emissions_per_fuel_d * (1 - electrification_d) + 
             emissions_per_elec_d * electrification_d) * 
             energy_per_gdp_d * gdp_per_capita_d * population_d
    forecast_bootstrap <- (emissions_per_fuel_f * (1 - electrification_f) + 
                           emissions_per_elec_f * electrification_f) * 
                           energy_per_gdp_f * gdp_per_capita_f * population_f
  }
  else if(forecast_type == "energy_per_capita"){
    data <- energy_per_gdp_d * gdp_per_capita_d
    forecast_bootstrap <- energy_per_gdp_f * gdp_per_capita_f
  }
  else if(forecast_type == "emissions_per_energy"){
    data <- (emissions_per_fuel_d * (1 - electrification_d) + 
            emissions_per_elec_d * electrification_d)
    forecast_bootstrap <- (emissions_per_fuel_f * (1 - electrification_f) + 
                          emissions_per_elec_f * electrification_f)
  }
  else if(forecast_type == "electricity_per_capita"){
    data <- electrification_d * energy_per_gdp_d * gdp_per_capita_d
    forecast_bootstrap <- electrification_f * energy_per_gdp_f * gdp_per_capita_f
  }
  else if(forecast_type == "total_electricity_emissions"){
    data <- emissions_per_elec_d * electrification_d * energy_per_gdp_d * gdp_per_capita_d * population_d
    forecast_bootstrap <- emissions_per_elec_f * electrification_f * energy_per_gdp_f * gdp_per_capita_f * population_f
  }
  else if(forecast_type == "total_nonelectricity_emissions"){
    data <- emissions_per_fuel_d * (1 - electrification_d) * energy_per_gdp_d * gdp_per_capita_d * population_d
    forecast_bootstrap <- emissions_per_fuel_f * (1 - electrification_f) * energy_per_gdp_f * gdp_per_capita_f * population_f
  }
  else if(forecast_type == "total_electricity"){
    data <- electrification_d * energy_per_gdp_d * gdp_per_capita_d * population_d
    forecast_bootstrap <- electrification_f * energy_per_gdp_f * gdp_per_capita_f * population_f
  }
  else if(forecast_type == "total_nonelectricity"){
    data <- (1 - electrification_d) * energy_per_gdp_d * gdp_per_capita_d * population_d
    forecast_bootstrap <- (1 - electrification_f) * energy_per_gdp_f * gdp_per_capita_f * population_f
  }
  else if(forecast_type == "population"){
    data <- population_d
    forecast_bootstrap <- population_f
  }
  else if(forecast_type == "gdp_per_capita"){
    data <- gdp_per_capita_d
    forecast_bootstrap <- gdp_per_capita_f
  }
  else if(forecast_type == "energy_per_gdp"){
    data <- energy_per_gdp_d
    forecast_bootstrap <-energy_per_gdp_f
  }
  else if(forecast_type == "fraction_elec_n_heat"){
    data <- electrification_d
    forecast_bootstrap <- electrification_f
  }
  else if(forecast_type == "emissions_per_elec_n_heat"){
    data <- emissions_per_elec_d
    forecast_bootstrap <-emissions_per_elec_f
  }
  else if(forecast_type == "emissions_per_direct"){
    data <- emissions_per_fuel_d
    forecast_bootstrap <-emissions_per_fuel_f
  }
  
  if(global){ # add global simulation
    global_name <- "Global"
    regions <- regions + 1
    if(forecast_type == "total_energy_emissions"){
      
      data[global_name] <- (emissions_per_fuel_g * (1 - electrification_g) + 
                            emissions_per_elec_g * electrification_g) * 
                           energy_per_gdp_g * gdp_per_capita_g * population_g
      global_forecast_bootstrap <- apply(forecast_bootstrap,
                                         c(1,3),
                                         sum)
      
    }
    else if(forecast_type == "energy_per_capita"){
      
      numerator_g <- energy_per_gdp_g * gdp_per_capita_g * population_g
      denominator_g <- population_g
      numerator_f <- energy_per_gdp_f * gdp_per_capita_f * population_f
      denominator_f <- population_f
      
      data[global_name] <- numerator_g/denominator_g
      global_forecast_bootstrap <- get_global_ratio_f(numerator_f,
                                                      denominator_f)
    }
    else if(forecast_type == "emissions_per_energy"){
      
      numerator_g <- (emissions_per_fuel_g * (1 - electrification_g) + emissions_per_elec_g * electrification_g) * energy_per_gdp_g * gdp_per_capita_g * population_g
      denominator_g <- energy_per_gdp_g * gdp_per_capita_g * population_g
      numerator_f <- (emissions_per_fuel_f * (1 - electrification_f) + emissions_per_elec_f * electrification_f) * energy_per_gdp_f * gdp_per_capita_f * population_f
      denominator_f <- energy_per_gdp_f * gdp_per_capita_f * population_f
      
      data[global_name] <- numerator_g/denominator_g
      global_forecast_bootstrap <- get_global_ratio_f(numerator_f,
                                                      denominator_f)
    }
    else if(forecast_type == "electricity_per_capita"){
      
      numerator_g <- electrification_g * energy_per_gdp_g * gdp_per_capita_g * population_g
      denominator_g <- population_g
      numerator_f <- electrification_f * energy_per_gdp_f * gdp_per_capita_f * population_f
      denominator_f <- population_f
      
      data[global_name] <- numerator_g/denominator_g
      global_forecast_bootstrap <- get_global_ratio_f(numerator_f,
                                                      denominator_f)
    }
    else if(forecast_type == "total_electricity_emissions"){
      data[global_name] <- emissions_per_elec_g * electrification_g * 
                           energy_per_gdp_g * gdp_per_capita_g * population_g
      global_forecast_bootstrap <- apply(forecast_bootstrap,
                                         c(1,3),
                                         sum)
    }
    else if(forecast_type == "total_nonelectricity_emissions"){
      data[global_name] <- emissions_per_fuel_g * (1 - electrification_g) * 
                           energy_per_gdp_g * gdp_per_capita_g * population_g
      global_forecast_bootstrap <- apply(forecast_bootstrap,
                                         c(1,3),
                                         sum)
    }
    else if(forecast_type == "total_electricity"){
      data[global_name] <- electrification_g * energy_per_gdp_g * 
                           gdp_per_capita_g * population_g
      global_forecast_bootstrap <- apply(forecast_bootstrap,
                                         c(1,3),
                                         sum)
    }
    else if(forecast_type == "total_nonelectricity"){
      data[global_name] <- (1 - electrification_g) * energy_per_gdp_g * 
                           gdp_per_capita_g * population_g
      global_forecast_bootstrap <- apply(forecast_bootstrap,
                                         c(1,3),
                                         sum)
    }
    else if(forecast_type == "population"){

      data[global_name] <- population_g
      global_forecast_bootstrap <- apply(forecast_bootstrap,
                                         c(1,3),
                                         sum)
    }
    else if(forecast_type == "gdp_per_capita"){

      numerator_f <- gdp_per_capita_f * population_f
      denominator_f <- population_f
      
      data[global_name] <- gdp_per_capita_g
      global_forecast_bootstrap <- get_global_ratio_f(numerator_f,
                                                      denominator_f)
    }
    else if(forecast_type == "energy_per_gdp"){
      
      numerator_f <- energy_per_gdp_f * gdp_per_capita_f * population_f
      denominator_f <- gdp_per_capita_f * population_f
      
      data[global_name] <- energy_per_gdp_g
      global_forecast_bootstrap <- get_global_ratio_f(numerator_f,
                                                      denominator_f)
    }
    else if(forecast_type == "fraction_elec_n_heat"){
      
      numerator_f <- electrification_f * energy_per_gdp_f * gdp_per_capita_f * population_f
      denominator_f <- energy_per_gdp_f * gdp_per_capita_f * population_f
      
      data[global_name] <- electrification_g
      global_forecast_bootstrap <- get_global_ratio_f(numerator_f,
                                                      denominator_f)
    }
    else if(forecast_type == "emissions_per_elec_n_heat"){
      
      numerator_f <- emissions_per_elec_f * electrification_f * energy_per_gdp_f * gdp_per_capita_f * population_f
      denominator_f <- electrification_f * energy_per_gdp_f * gdp_per_capita_f * population_f
      
      data[global_name] <- emissions_per_elec_g
      global_forecast_bootstrap <- get_global_ratio_f(numerator_f,
                                                      denominator_f)
    }
    else if(forecast_type == "emissions_per_direct"){
      
      numerator_f <- emissions_per_fuel_f * (1 - electrification_f) * energy_per_gdp_f * gdp_per_capita_f * population_f
      denominator_f <- (1 - electrification_f) * energy_per_gdp_f * gdp_per_capita_f * population_f
      
      data[global_name] <- emissions_per_fuel_g
      global_forecast_bootstrap <- get_global_ratio_f(numerator_f,
                                                      denominator_f)
    }
    else{
      print("This global version is not implemented :(")
      stop()
    }
    
    forecast_bootstrap <- abind(forecast_bootstrap,
                                global_forecast_bootstrap,
                                along=2)
    dimnames(forecast_bootstrap)[[2]][regions] <- global_name
    
    cols <- c(cols, global_name)
  }
    
  data[,"year"] <- c(1971:year)
  forecast <- compute_quantiles(forecast_bootstrap,
                                cols,
                                regions=regions)
  forecast[,"year"] <- forecast_range
  if(test){
    plot.dir <- paste0(path,
                       "plots/aggregates/test/",
                       forecast_type,
                       "/",
                       forecast_type,
                       "_",
                       toString(lag),
                       "/")
  }else{
    plot.dir <- paste0(path, 
                       "plots/aggregates/", 
                       forecast_type, 
                       "/", 
                       forecast_type, 
                       "_", 
                       toString(lag), 
                       "/")
  }
  if(!dir.exists(plot.dir)){
    dir.create(plot.dir, recursive=TRUE)
  }
  
  data[,names(data) != "year"] <- scale * data[,names(data) != "year"]
  forecast[,names(forecast) != "year"] <- scale * forecast[,names(forecast) != "year"]
  make_plot(data,
            forecast,
            cols,
            regions,
            plot.dir,
            title,
            ylabel,
            log_scale=log_scale)
  
  
}

cusum_function_gdp_per_capita <- function(data,
                                          cols,
                                          breakpoints,
                                          alpha,
                                          lag){
  
  #' Find breakpoints in the GDP per capita time series with OLS-CUSUM
  #'
  #' @param data Historical time series for regions of interest
  #' @param cols The list of countries
  #' @param breakpoints List of current breakpoints
  #' @param alpha The false positive rate of two sided CUSUM test. Half this
  #'              is the false positive rate for our one-sided test.
  #' @param lag The number of years chopped before simulation. lag=0 is for
  #'            forecasting and lag>0 is for validation
  #' @returns Truncated data and breakpoint
  #' @export

  for (col in cols){
    num_nan <- sum(is.na(data[col]))
    x <- data[[col]]
    x_na <- !is.na(x)
    x <- x[x_na] # remove NaNs
    z <- diff(log(1 - x))
    lenx <- length(x)
    mask_lag <- -c((lenx-lag+1):lenx) 
    z <- z[mask_lag] # lag truncation
    bp <- 1
    cusum_result <- efp(z ~ 1, type="OLS-CUSUM")
    check_for_significance <- (cusum_result$process > boundary(cusum_result, alpha=alpha))
    if (any(check_for_significance)){
      bp <- which.max(cusum_result$process)
      if(bp < length(x) - 10 - lag){
        data[num_nan + c(1:bp) - 1, col] <- NA
        idx <- which(colnames(data) == col)
        breakpoints[idx] <- num_nan + bp
      }
    }
  }
  return(list(data=data, breakpoints=breakpoints))
}

compute_quantiles <- function(forecast_bootstrap,
                              cols,
                              regions = REGIONS){
  
  #' Compute quantiles from simulations
  #'
  #' @param forecast_bootstrap Collection of simulations 
  #' @param cols The list of countries
  #' @param regions The number of regions simulated
  #' @returns Simulation quantiles
  #' @export

  intervals <- c("lower2.5", "lower10", "median", "upper90", "upper97.5")
  for (g in 1:regions){
    colnames_g <- map_chr(intervals, function(x) paste(cols[g], x, sep = "."))
    
    forecast_g <- apply(forecast_bootstrap[, g, ], 2, function(x){
      c(lower5 = quantile(x, 0.025), lower25 = quantile(x, 0.1), median = median(x),
        upper75 = quantile(x, 0.9), upper95 = quantile(x, 0.975))}) %>%
      t() %>%
      as_tibble() %>%
      set_names(colnames_g)
    
    if(g == 1){
      forecast <- forecast_g
    }
    else{
      forecast <- cbind(forecast, forecast_g)
    }
  }
  forecast
}

make_data_stack <- function(data){
  
  #' Stack the input data so that it can be passd to STAN
  #'
  #' @param data Historical time series for regions of interest 
  #' @returns Data stack for STAN
  #' @export

  data_stack <- tibble()
  group_idx <- 1
  group_lengths <- c()
  cols <- colnames(data)[colnames(data) != "year"]
  
  for (col in cols){ # stack the data and organize groups
    data_col <- data[col] 
    data_col <- data_col[!is.na(data_col)]
    data_group <- tibble(group_idx = group_idx, y = data_col)
    data_stack <- rbind(data_stack, data_group)
    
    group_lengths <- c(group_lengths, length(data_col)) # collect group lengths
    group_idx <- group_idx + 1 # increment group index
  }
  
  start_idx <- c(0, cumsum(head(group_lengths, -1))) + 1 # gives the increment in data_stack where each new time series begins
  list(data_stack = data_stack, start_idx = start_idx, group_lengths = group_lengths)
}

make_plot <- function(data,
                      forecast,
                      cols,
                      regions,
                      path,
                      title,
                      ylabel,
                      log_scale=FALSE,
                      breakpoints=NULL){ # takes data and forecasts to produce plots
  
  #' Create plots of the time series simulations
  #'
  #' @param data Historical time series data
  #' @param forecast The time series simulations
  #' @param cols The list of countries
  #' @param regions The number of global regions
  #' @param path Directory for figure storage
  #' @param title Plot title
  #' @param ylabel Plot y axis label
  #' @param breakpoints List of breakpoints
  #' @param log_scale The y axis is log scale if this is true, otherwise the
  #'                  log scale is linear
  #' @returns Simulation plots for time series
  #' @export

  for (g in 1:regions){
    forecast_cols <- colnames(forecast)[5*(g-1) + c(1:5)]
    
    myplot <- ggplot() +
      geom_line(data = data,
                aes(x = year,
                    y = .data[[cols[g]]]),
                    na.rm = TRUE) +
      geom_line(data = forecast, # add median
                aes(x = year,
                    y = .data[[forecast_cols[3]]]),
                    col = "red") +
      geom_ribbon(data = forecast, # add quantiles
                  aes(x = year,
                      ymin=.data[[forecast_cols[2]]],
                      ymax=.data[[forecast_cols[4]]]),
                      fill = "red",
                      alpha=0.2) +
      geom_ribbon(data = forecast, # add more quantiles
                  aes(x = year,
                      ymin=.data[[forecast_cols[1]]],
                      ymax=.data[[forecast_cols[5]]]),
                      fill = "red",
                      alpha=0.2)
    
    if (title == ""){
      plt_title <- ""
    }
    else{
      plt_title <- paste0(title,
                          ", ",
                          gsub(".",
                               " ",
                               cols[g],
                               fixed=TRUE))
    }
    myplot <- myplot + 
              labs(title=plt_title,
                   y=ylabel,
                   x="Year") +
              theme(plot.title=element_text(size = 30,
                                            hjust = 0.5),
                    axis.title = element_text(size = 28),
                    axis.text = element_text(size = 25),
                    axis.title.y = element_text(margin = margin(r = 20))) 
    
    
    if(log_scale){ # make the plot log scale
      myplot <- myplot + scale_y_log10()
    }
    
    if(!is.null(breakpoints)){ # add break point markers
      if(!is.na(breakpoints[g])){
        myplot <- myplot + 
                  geom_point(data = data[breakpoints[g],],
                             aes(x = year,
                                 y = .data[[cols[g]]]),
                                 shape = 18,
                                 color = "blue")
      }
    }

    ggsave(
      paste0(path, cols[g], ".png"),
      plot = myplot,
      width = 10,
      height = 8,
      create.dir = TRUE
    )
    
    write.csv(forecast,
              paste0(path, "forecast.csv"),
              row.names = FALSE)
    write.csv(data,
              paste0(path, "data.csv"),
              row.names = FALSE)
  }
}

get_stan_input <- function(data, 
                           cols, 
                           method_name, 
                           regions = REGIONS){

  #' Different methods structural time series methods require different input
  #' formats. This function handles these cases
  #'
  #' @param data Historical time series data
  #' @param cols The list of countries
  #' @param method_name The name of the structural time series method
  #' @param regions The number of global regions
  #' @returns STAN input list
  #' @export
  
  out <- make_data_stack(data[,cols])
  data_stack <- out$data_stack
  if(method_name == "global_frontier_log_difference"){
    stan_input <- list(
        N = length(data_stack$y), # total length
        G = regions, # number of groups
        Ts = out$group_lengths, # the lengths of the time series
        start_idx = out$start_idx, # the location where each new time series begins
        y = data_stack$y
    )
  } 
  if(method_name == "global_frontier_ratio"){
    stan_input <- list(
      N = length(data_stack$y), # total length
      G = regions, # number of groups
      Ts = out$group_lengths, # the lengths of the time series
      start_idx = out$start_idx, # the location where each new time series begins
      y = data_stack$y
    )
  } 
  else if(method_name == "trend_stationary_convergence"){
    stan_input <- list(
      N = length(data_stack$y),
      G = regions,
      NUM_YEARS = length(data$year),
      t = (data$year - 1960),
      Ts = out$group_lengths,
      start_idx = out$start_idx,
      y = data_stack$y
    )
  }
  else if(method_name == "lgt_hierarchical"){
    stan_input <- list(
      CAUCHY_SD = 1/150, # CAUCHY_SD = max(data_stack$y)/150,
      MIN_POW = -0.5,
      MAX_POW = 1,
      MIN_SIGMA = 1e-3,
      MIN_NU = 1.5,
      MAX_NU = 20,
      N = length(data_stack$y),
      G = regions,
      Ts = out$group_lengths,
      start_idx = out$start_idx,
      y = data_stack$y
    )
  }
  else if(method_name == "exp_decay"){
    y_maxes <- unname(sapply(data, max, na.rm = TRUE))
    y_maxes <- y_maxes[-length(y_maxes)] # remove year
    stan_input <- list(
      N = length(data_stack$y),
      G = regions, # number of groups
      Ts = out$group_lengths, # vector containing the lengths of each group
      start_idx = out$start_idx,
      y_maxes = y_maxes,
      y = data_stack$y
    )
  }
  else if(method_name == "constant_convergence") {
    stan_input <- list(
      N = length(data_stack$y), # total length
      G = regions, # number of groups
      Ts = out$group_lengths, # the lengths of the time series
      start_idx = out$start_idx, # the location where each new time series begins
      y = data_stack$y
    )
  }
  stan_input
}

get_make_forecast <- function(method_name){

  #' Return the simulation function that corresponds to the method name
  #'
  #' @param method_name The name of the structural time series method
  #' @returns Simulation function
  #' @export

  if(method_name == "global_frontier_log_difference"){
    make_forecast <- make_forecast_global_frontier_log_difference
  }
  else if(method_name == "global_frontier_ratio"){
    make_forecast <- make_forecast_global_frontier_ratio
  }
  else if(method_name == "global_frontier_ratio_experiment"){
    make_forecast <- make_forecast_global_frontier_ratio_experiment
  }
  else if(method_name == "trend_stationary_convergence"){
    make_forecast <- make_forecast_trend_stationary_convergence
  } 
  else if(method_name == "lgt_hierarchical"){
    make_forecast <- make_forecast_lgt_hierarchical
  }
  else if(method_name == "exp_decay"){
    make_forecast <- make_forecast_exp_decay
  }
  else if(method_name == "constant_convergence"){
    make_forecast <- make_forecast_constant_convergence
  }
  else{
    print("Invalid Method")
  }
  make_forecast
}

validation <- function(all_data,
                       lags,
                       timeseries_type,
                       method_name,
                       plot_title = "Generic Title",
                       plot_ylabel = "Generic Axis Label",
                       run_simulation = FALSE,
                       log_scale = FALSE,
                       logistic_scale = FALSE,
                       apply_ratio_frontier = FALSE,
                       apply_cusum = FALSE, 
                       chop_emissions_per_elec_n_heat = FALSE,
                       alpha = 0.1,
                       draws = DRAWS,
                       regions = REGIONS,
                       horizon = HORIZON, 
                       year = YEAR){

  #' The master function that calls the necessary simulation 
  #' method and then calls plotting functions to show the results
  #'
  #' @param all_data Historical time series data
  #' @param lags A list of the years chopped before each simulation. 
  #'            lag=0 is for forecasting and lag>0 is for validation
  #' @param timeseries_type The component that is being simulated
  #' @param method_name The algorithm that is being used for simulation
  #' @param plot_title The plot title
  #' @param plot_ylabel The y axis label
  #' @param run_simulation If this is true then run a new simulation, otherwise
  #'                       use an existing simulation for plotting
  #' @param log_scale If true then transform the data through a log transform
  #'                  before simulating
  #' @param logistic_scale If true use a scaled logistic function before 
  #'                       simulating
  #' @param apply_ratio_frontier Apply the ratio transform for GDP per capita
  #' @param apply_cusum Apply OLS-CUSUM to GDP per capita to find break points
  #' @param chop_emissions_per_elec_n_heat Chop the emissions per electricity
  #'                                       component to after 1997
  #' @param alpha The two sided false positive rate for OLS-CUSUM
  #' @param draws The number of posterior draws to use
  #' @param regions The number of global regions
  #' @param horizon The number of years to project forwards if lag=0
  #' @param year The last available year of data
  #' @returns Simulations and plots of the time series of interest
  #' @export
  
  cols <- colnames(all_data)[colnames(all_data) != "year"]
  num_years <- dim(all_data)[1]
  
  
  complete_trace_path <- paste0(TRACE_PATH,
                                timeseries_type,
                                "/",
                                method_name,
                                "/") # path for traces

  if (!dir.exists(complete_trace_path)){
    dir.create(complete_trace_path, recursive = TRUE)
  }

  make_forecast <- get_make_forecast(method_name) # select forecasting function
  
  for (lag in lags){
    breakpoints <- rep(NA, REGIONS)
    print(paste("Lag", toString(lag)))
    
    data <- all_data

  
    complete_plot_path <- paste0(PLOT_PATH,
                                 timeseries_type,
                                 "/",
                                 method_name,
                                 "/",
                                 method_name,
                                 "_",
                                 toString(lag),
                                 "/") # path for plots

    if (!dir.exists(complete_plot_path)){
      dir.create(complete_plot_path, recursive = TRUE)
    }
    
    if(log_scale){ # transform data to log scale...
      data[cols] <- log(all_data[cols], base = 10)
    } 
    else if(logistic_scale){ # or logistic scale...
      data[cols] <- inv_scaled_logistic(all_data[cols])
    }
    else if(apply_ratio_frontier){
      cols_no_frontier <- cols[-c(1)] # put frontier in the first column
      data[cols_no_frontier] <- all_data[cols_no_frontier] / all_data[,1]
    }
    
    if(apply_cusum){ # or apply_cusum to find structural breaks
      if(timeseries_type == "gdp_per_capita"){
        gdp_per_capita_cols <- c("China.and.Taiwan",
                                 "India",
                                 "SE.Asia",
                                 "Brazil",
                                 "Mexico") # regions with primarily newly industrialized countries
        
        output <- cusum_function_gdp_per_capita(data,
                                                gdp_per_capita_cols, 
                                                breakpoints, 
                                                alpha, 
                                                lag)
        data <- output$data
        breakpoints <- output$breakpoints
      }
      else{
        print("Unsupported CUSUM class")
      }
    }
    
    if(chop_emissions_per_elec_n_heat){
      data[as.character(c(1970:1997)),] = NA
      breakpoints <- rep(1998 - 1970, REGIONS)
    }
    
    data <- data[c(1:(num_years-lag)),]
    
    if(run_simulation){ # determine whether to run the simulation...
      
      stan_input <- get_stan_input(data,
                                   cols,
                                   method_name) # select STAN data
      file <- paste0(STAN_PATH,
                     timeseries_type,
                     "/",
                     method_name,
                     ".stan")
      data_fit <- stan(file = file,
                       data = stan_input,
                       chains = CHAINS,
                       warmup = WARMUP,
                       iter = ITER,
                       cores = CORES,
                       refresh = REFRESH
      )
      
      if (!dir.exists(complete_trace_path)){ # make trace path if it does not exist
        dir.create(complete_trace_path)
      }
      saveRDS(data_fit, 
              paste0(complete_trace_path, 
                     method_name,
                     "_",
                     toString(lag),
                     ".rds")) # save the trace data
    } 
    else{ # or load a previous run
      data_fit <- readRDS(paste0(complete_trace_path, 
                                 method_name, 
                                 "_", 
                                 toString(lag), 
                                 ".rds")) # read the trace data
    }
    
    if(lag == 0){ # determine whether you are plotting a forecast...
      data_forecast <- make_forecast(draws, 
                                     regions, 
                                     horizon, 
                                     data_fit, 
                                     data)
      forecast_years <- c((year + 1):(year + horizon))
    } 
    else{ # or a validation
      data_forecast <- make_forecast(draws,
                                     regions,
                                     lag,
                                     data_fit,
                                     data)
      forecast_years <- c((year - lag + 1):year)
    }
    
    if(log_scale){ # revert back to original scale from log...
      data_forecast <- 10^data_forecast
    }
    else if(logistic_scale){ # or logistic scale
      data_forecast <- scaled_logistic(data_forecast)
    }
    
    if(method_name=="global_frontier_log_difference"){
      log_scale <- FALSE # plot this on normal scale for comparison
    }
    
    data_forecast[,"year"] <- forecast_years
    make_plot(all_data,
              data_forecast, 
              cols, 
              regions, 
              complete_plot_path, 
              title = plot_title, 
              ylabel = plot_ylabel, 
              log_scale = log_scale, 
              breakpoints = breakpoints) # save the plots

  }
}



# TIMESERIES SPECIFIC FUNCTIONS ------------------------------------------------
## POPULATION ------------------------------------------------------------------
get_codes <- function(UNlocations){
  #' Fetch codes for population region aggregation
  #'
  #' @param UNlocations Dataframe containing region codes
  #' @returns Region aggregation codes
  #' @export
  # North America
  usa_canada_sg <- c("United States of America",
                     "Canada")
  mexico_sg <- c("Mexico")
  central_america_sg <- c("Guatemala",
                          "El Salvador",
                          "Honduras",
                          "Costa Rica",
                          "Panama",
                          "Nicaragua")
  carribean <- c("Cuba",
                 "Jamaica",
                 "Haiti",
                 "Dominican Republic")
  
  # South America
  northwestern_south_america_sg = c("Venezuela (Bolivarian Republic of)",
                                    "Colombia",
                                    "Ecuador",
                                    "Peru", 
                                    "Bolivia (Plurinational State of)")
  southern_south_america_sg <- c("Chile", 
                                 "Argentina", 
                                 "Paraguay", 
                                 "Uruguay")
  brazil_sg <- c("Brazil")
  
  # Europe
  continental_europe_sg <- c("Bosnia and Herzegovina",
                             "TFYR Macedonia", 
                             "Serbia", 
                             "Switzerland", 
                             "Turkey", 
                             "Austria", 
                             "Belgium", 
                             "Bulgaria", 
                             "Croatia", 
                             "Denmark", 
                             "France", 
                             "Germany", 
                             "Greece", 
                             "Hungary", 
                             "Italy", 
                             "Luxembourg", 
                             "Malta", 
                             "Poland", 
                             "Portugal", 
                             "Romania", 
                             "Slovakia", 
                             "Slovenia", 
                             "Spain", 
                             "Albania", 
                             "Czechia", 
                             "Netherlands")
  northern_europe_sg <- c("Sweden", 
                          "Norway", 
                          "Finland")
  eastern_europe_sg <- c("Estonia", 
                         "Latvia", 
                         "Lithuania", 
                         "Republic of Moldova", 
                         "Ukraine")
  british_isles <- c("United Kingdom", 
                     "Ireland")
  # iceland <- c("Iceland", "Greenland")
  
  # Africa
  northwest_africa_sg <- c("Morocco", 
                           "Algeria", 
                           "Tunisia")
  southern_africa_sg <- c("Angola", 
                          "Botswana", 
                          "Democratic Republic of the Congo", 
                          "Swaziland", 
                          "Mozambique", 
                          "Namibia", 
                          "South Africa", 
                          "United Republic of Tanzania", 
                          "Zambia", 
                          "Zimbabwe", 
                          "Kenya", 
                          "Uganda")
  northeast_africa_sg <- c("Libya",
                           "Egypt")
  africa <- c("Algeria", 
              "Angola", 
              "Benin", 
              "Botswana", 
              "Burkina Faso", 
              "Burundi", 
              "Cameroon", 
              "Cabo Verde", 
              "Central African Republic", 
              "Chad", 
              "Comoros", 
              "Congo", 
              "Democratic Republic of the Congo", 
              "Cote d'Ivoire", 
              "Djibouti", 
              "Egypt", 
              "Equatorial Guinea", 
              "Eritrea", 
              "Ethiopia", 
              "Gabon", 
              "Gambia", 
              "Ghana", 
              "Guinea", 
              "Guinea-Bissau", 
              "Kenya", 
              "Lesotho", 
              "Liberia", 
              "Libya", 
              "Madagascar", 
              "Mali", 
              "Malawi", 
              "Mauritania", 
              "Mauritius", 
              "Mayotte", 
              "Morocco", 
              "Mozambique", 
              "Namibia", 
              "Niger", 
              "Nigeria", 
              "Reunion", 
              "Rwanda", 
              "Sao Tome and Principe", 
              "Senegal", 
              "Seychelles", 
              "Sierra Leone", 
              "Somalia", 
              "South Africa", 
              "South Sudan", 
              "Sudan", 
              "Swaziland", 
              "United Republic of Tanzania", 
              "Togo", 
              "Tunisia", 
              "Uganda", 
              "Western Sahara", 
              "Zambia", 
              "Zimbabwe")
  central_africa <- setdiff(africa, c(northwest_africa_sg, northeast_africa_sg, southern_africa_sg))
  
  # Asia
  middle_east <- c("Bahrain",
                   "Iran (Islamic Republic of)", 
                   "Iraq", 
                   "Jordan", 
                   "Kuwait", 
                   "Lebanon", 
                   "Oman", 
                   "Qatar", 
                   "Saudi Arabia", 
                   "Syrian Arab Republic", 
                   "United Arab Emirates", 
                   "Yemen", 
                   "Israel", 
                   "Cyprus")
  northern_asia_sg <- c("Russian Federation", 
                        "Tajikistan", 
                        "Kazakhstan", 
                        "Uzbekistan", 
                        "Turkmenistan", 
                        "Kyrgyzstan", 
                        "Georgia", 
                        "Azerbaijan", 
                        "Armenia", 
                        "Belarus", 
                        "Mongolia")
  southeastern_asia <- c("Cambodia", 
                         "Indonesia", 
                         "Lao People's Democratic Republic", 
                         "Malaysia", 
                         "Myanmar", 
                         "Philippines", 
                         "Singapore", 
                         "Thailand", 
                         "Viet Nam")
  india_sg <- c("India")
  china <- c("China", 
             "China, Hong Kong SAR", 
             "China, Macao SAR", 
             "China, Taiwan Province of China")
  korea <- c("Republic of Korea")
  japan <- c("Japan")
  other_asia <- c("Pakistan", 
                  "Nepal", 
                  "Bangladesh", 
                  "Sri Lanka")
  
  # Oceania
  australia <- c("Australia")
  new_zealand <- c("New Zealand")
  
  world_names <- list(
    "North America"=list("USA and Canada"=usa_canada_sg,
                         "Mexico"=mexico_sg,
                         "Central America"=central_america_sg,
                         "Other North America"=carribean),
    "South America"=list("NW South America"=northwestern_south_america_sg,
                         "Brazil"=brazil_sg,
                         "S South America"=southern_south_america_sg),
    "Asia"=list("Middle East"=middle_east,
                "N Asia"=northern_asia_sg,
                "India"=india_sg,
                "SE Asia"=southeastern_asia,
                "China and Taiwan"=china,
                "Korea"=korea,
                "Japan"=japan,
                "Other Asia"=other_asia),
    "Europe"=list("Continental Europe"=continental_europe_sg,
                  "N Europe"=northern_europe_sg,
                  "E Europe"=eastern_europe_sg,
                  "British Isles"=british_isles),
    "Africa"=list("Other Africa"=central_africa,
                  "NW Africa"=northwest_africa_sg,
                  "NE Africa"=northeast_africa_sg,
                  "S Africa"=southern_africa_sg),
    "Oceania"=list("Australia"=australia,
                   "New Zealand"=new_zealand)
  )
  
  world_codes <- world_names
  for (continent_name in names(world_names)){
    for (region_name in names(world_names[[continent_name]])){
      country_mask <- UNlocations$name %in% world_names[[continent_name]][[region_name]]
      df <- UNlocations[country_mask,]
      world_codes[[continent_name]][[region_name]] <- df$country_code
      if (length(world_codes[[continent_name]][[region_name]]) == 
          length(world_names[[continent_name]][[region_name]])){
        cat(paste(region_name, "good!","\n\n"))
      }
      else{
        browser()
        print(paste(region_name, "bad!", "Missing Countries:"))
        mask <- !(world_names[[continent_name]][[region_name]] %in% df$name)
        print(world_names[[continent_name]][[region_name]][mask])
        cat("\n")
        stop()
      }
    }
  }
  
  temp <- unname(unlist(world_names))
  mask <- UNlocations$name %in% temp
  df <- UNlocations[!mask,]
  
  world_codes
}

## GDP PER CAPITA --------------------------------------------------------------
make_forecast_global_frontier_ratio <- function(draws,
                                                regions,
                                                horizon,
                                                fit,
                                                data,
                                                return_bootstrap=FALSE){ 

  #' Use posterior samples to simulate time series
  #'
  #' @param draws The number of posterior draws to use
  #' @param regions The number of global regions
  #' @param horizon The number of years to project forwards if lag=0
  #' @param fit Samples from posterior distribution
  #' @param data Historical time series data
  #' @param return_bootstrap If true return all the simulations, otherwise only
  #'                         return the quantiles
  #' @returns Time series simulation
  #' @export
  
  
  posterior <- rstan::extract(fit) # extract posterior samples from the fit
  forecast_bootstrap <- array(NA, dim = c(draws, regions, horizon+1))
  
  cols <- colnames(data)[colnames(data) != "year"] # make sure the frontier is in column 1!
  tau <- posterior$tau
  sigma_frontier <- posterior$sigma_frontier
  forecast_bootstrap[,1,1] <- tail(data[[cols[1]]], n=1)
  for (h in 2:(horizon+1)){
    forecast_bootstrap[,1,h] <- rnorm(n = draws, 
                                      mean = forecast_bootstrap[,1,h-1] + tau, 
                                      sd = sigma_frontier)
  }
  
  for (g in 1:(regions-1)){
    phi <- posterior$phi[,g]
    sigma <- posterior$sigma[,g]
    forecast_bootstrap[,g+1,1] <- tail(data[[cols[g+1]]], n=1)
    
    for (h in 2:(horizon+1)){
      mu <- 1 - phi * (1 - forecast_bootstrap[,g+1,h-1])
    
      forecast_bootstrap[,g+1,h] <- rtruncnorm(n = draws,
                                               a = 0,
                                               mean = mu,
                                               sd = sigma)
    }
    forecast_bootstrap[,g+1,] <- forecast_bootstrap[,g+1,] * forecast_bootstrap[,1,] # multiply the current region with the frontier
  }
  forecast_bootstrap <- forecast_bootstrap[,,-c(1)] # take off the last true data point from the forecast 
  
  if(return_bootstrap){
    ret_val <- forecast_bootstrap
  }
  else{
    ret_val <- compute_quantiles(forecast_bootstrap, cols)
  }
  ret_val
}

make_forecast_global_frontier_log_difference <- function(draws,
                                                         regions,
                                                         horizon,
                                                         fit,
                                                         data,
                                                         return_bootstrap=FALSE){

  #' Use posterior samples to simulate time series
  #'
  #' @param draws The number of posterior draws to use
  #' @param regions The number of global regions
  #' @param horizon The number of years to project forwards if lag=0
  #' @param fit Samples from posterior distribution
  #' @param data Historical time series data
  #' @param return_bootstrap If true return all the simulations, otherwise only
  #'                         return the quantiles
  #' @returns Time series simulation
  #' @export

  posterior <- rstan::extract(fit) # extract posterior samples from the fit
  forecast_bootstrap <- array(NA, dim = c(draws, regions, horizon+1))
  
  cols <- colnames(data)[colnames(data) != "year"] # make sure the frontier is in column 1!
  tau <- posterior$tau
  sigma_frontier <- posterior$sigma_frontier
  
  forecast_bootstrap[,1,1] <- tail(data[[cols[1]]], 
                                   n=1)
  for (h in 2:(horizon+1)){
    forecast_bootstrap[,1,h] <- rnorm(n=draws,
                                      mean=forecast_bootstrap[,1,h-1] + tau,
                                      sd=sigma_frontier)
  }
  
  for (g in 1:(regions-1)){
    phi <- posterior$phi[,g]
    sigma <- posterior$sigma[,g]
  
    forecast_bootstrap[,g+1,1] <- tail(data[[cols[g+1]]], n=1)
    
    for (h in 2:(horizon+1)){
      mean <- forecast_bootstrap[,1,h] - phi * (forecast_bootstrap[,1,h-1] - forecast_bootstrap[,g+1,h-1])
      forecast_bootstrap[,g+1,h] <- rnorm(n=draws,
                                          mean=mean,
                                          sd=sigma)
    }
  }
  forecast_bootstrap <- forecast_bootstrap[,,-c(1)]
  
  if(return_bootstrap){
    ret_val <- forecast_bootstrap
  }
  else{
    ret_val <- compute_quantiles(forecast_bootstrap, cols)
  }
  ret_val
}

make_forecast_global_frontier_ratio_experiment <- function(draws,
                                                           regions,
                                                           horizon,
                                                           fit,
                                                           data,
                                                           return_bootstrap=FALSE){ 
  
  #' Run experiments where frontier stays constant
  #'
  #' @param draws The number of posterior draws to use
  #' @param regions The number of global regions
  #' @param horizon The number of years to project forwards if lag=0
  #' @param fit Samples from posterior distribution
  #' @param data Historical time series data
  #' @param return_bootstrap If true return all the simulations, otherwise only
  #'                         return the quantiles
  #' @returns Time series simulation
  #' @export
  
  
  posterior <- rstan::extract(fit) # extract posterior samples from the fit
  forecast_bootstrap <- array(NA, dim = c(draws, regions, horizon+1))
  forecast_bootstrap_ratio <- array(NA, dim = c(draws, regions, horizon+1))
  
  cols <- colnames(data)[colnames(data) != "year"] # make sure the frontier is in column 1!
  tau <- posterior$tau
  sigma_frontier <- posterior$sigma_frontier
  forecast_bootstrap[,1,1] <- tail(data[[cols[1]]], n=1)
  for (h in 2:(horizon+1)){
    forecast_bootstrap[,1,h] <- forecast_bootstrap[,1,h-1]
  }
  
  for (g in 1:(regions-1)){
    phi <- posterior$phi[,g]
    sigma <- posterior$sigma[,g]
    forecast_bootstrap[,g+1,1] <- tail(data[[cols[g+1]]], n=1)
    
    for (h in 2:(horizon+1)){
      mu <- 1 - phi * (1 - forecast_bootstrap[,g+1,h-1])
      
      forecast_bootstrap[,g+1,h] <- rtruncnorm(n = draws,
                                               a = 0,
                                               mean = 1 - mu,
                                               sd = sigma)
    }
    forecast_bootstrap[,g+1,] <- forecast_bootstrap[,g+1,] * forecast_bootstrap[,1,] # multiply the current region with the frontier
  }
  forecast_bootstrap <- forecast_bootstrap[,,-c(1)] # take off the last true data point from the forecast 
  
  if(return_bootstrap){
    ret_val <- forecast_bootstrap
  }
  else{
    ret_val <- compute_quantiles(forecast_bootstrap, cols)
  }
  ret_val
}

## ENERGY PER GDP --------------------------------------------------------------
make_forecast_trend_stationary_convergence <- function(draws,
                                                       regions,
                                                       horizon,
                                                       fit,
                                                       data,
                                                       return_bootstrap=FALSE){
  
  #' Use posterior samples to simulate time series
  #'
  #' @param draws The number of posterior draws to use
  #' @param regions The number of global regions
  #' @param horizon The number of years to project forwards if lag=0
  #' @param fit Samples from posterior distribution
  #' @param data Historical time series data
  #' @param return_bootstrap If true return all the simulations, otherwise only
  #'                         return the quantiles
  #' @returns Time series simulation
  #' @export

  posterior <- rstan::extract(fit) # extract posterior samples from the fit
  forecast_bootstrap <- array(NA, dim=c(draws, regions, horizon + 1))
  
  cols <- colnames(data)[colnames(data) != "year"]
  num_years <- length(rownames(data))
  beta <- posterior$beta
  # nu <- posterior$nu
  for (g in 1:regions){
    phi <- posterior$phi[,g]
    alpha <- posterior$alpha[,g]
    sigma <- posterior$sigma[,g]
    
    forecast_bootstrap[,g,1] <- tail(data[[cols[g]]], n=1)
    
    for (h in 2:(horizon+1)){
      t <- num_years + h - 1
      mean <- alpha + beta * t + phi * (forecast_bootstrap[,g,h-1] - (alpha + beta * (t - 1)))
      forecast_bootstrap[,g,h] <- rnorm(n = draws,
                                        mean = mean,
                                        sd = sigma)
      # forecast_bootstrap[,g,h] <- rtt(draws,
      #                                 location = mean,
      #                                 scale = sigma,
      #                                 nu)
    }
  }
  
  forecast_bootstrap <- forecast_bootstrap[,,-c(1)]
  
  if(return_bootstrap){
    ret_val <- forecast_bootstrap
  }
  else{
    ret_val <- compute_quantiles(forecast_bootstrap, cols)
  }
  ret_val
}
## ELECTRIFICATION -------------------------------------------------------------
make_forecast_lgt_hierarchical <- function(draws,
                                           regions,
                                           horizon,
                                           fit,
                                           data,
                                           return_bootstrap=FALSE){

  #' Use posterior samples to simulate time series
  #'
  #' @param draws The number of posterior draws to use
  #' @param regions The number of global regions
  #' @param horizon The number of years to project forwards if lag=0
  #' @param fit Samples from posterior distribution
  #' @param data Historical time series data
  #' @param return_bootstrap If true return all the simulations, otherwise only
  #'                         return the quantiles
  #' @returns Time series simulation
  #' @export

  posterior <- rstan::extract(fit) # extract posterior samples from the fit
  forecast_bootstrap <- array(NA, dim = c(draws, regions, horizon))

  cols <- colnames(data)[colnames(data) != "year"]
  for (g in 1:regions){
    alpha <- posterior$alpha[,g]
    beta <- posterior$beta[,g]
    gamma <- posterior$gamma[,g]
    rho <- posterior$rho[,g]
    lam <- posterior$lam[,g]
    sigma <- posterior$sigma[,g]
    nu <- posterior$nu
  
    data_col <- data[cols[g]]
    data_col <- data_col[!is.na(data_col)]
    l <- data_col[1]
    b <- 0
    for (y in data_col[-c(1)]){
      l_new <- alpha * y + (1 - alpha) * l
      b <- beta * (l_new - l) + (1 - beta) * b
      l <- l_new
    }
    for (h in 1:horizon){
      trend <- gamma * abs(l)^rho + lam * b
      mu <- l + trend

      forecast_bootstrap[,g,h] <- rtt(draws,
                                      location = mu,
                                      scale = sigma,
                                      nu,
                                      left = 0)

      l_new <- alpha * forecast_bootstrap[,g,h]  + (1 - alpha) * l
      b <- beta * (l_new - l) + (1 - beta) * b
      l <- l_new
    }
  }

  if(return_bootstrap){
    ret_val <- forecast_bootstrap
  }
  else{
    ret_val <- compute_quantiles(forecast_bootstrap, cols)
  }
  ret_val
}

## EMISSIONS PER ELECTRICITY ---------------------------------------------------
make_forecast_exp_decay <- function(draws, 
                                    regions, 
                                    horizon, 
                                    fit, 
                                    data, 
                                    return_bootstrap=FALSE){

  #' Use posterior samples to simulate time series
  #'
  #' @param draws The number of posterior draws to use
  #' @param regions The number of global regions
  #' @param horizon The number of years to project forwards if lag=0
  #' @param fit Samples from posterior distribution
  #' @param data Historical time series data
  #' @param return_bootstrap If true return all the simulations, otherwise only
  #'                         return the quantiles
  #' @returns Time series simulation
  #' @export

  posterior <- rstan::extract(fit) # extract posterior samples from the fit
  forecast_bootstrap <- array(NA, dim = c(draws, regions, horizon + 1))
  cols <- colnames(data)[colnames(data) != "year"]
  y_maxes <- unname(sapply(data, max, na.rm = TRUE))

  for (g in 1:regions){
    global_sigma <- posterior$global_sigma[,g]
    rho <- posterior$rho[,g]
    
    forecast_bootstrap[,g,1] <- tail(data[[cols[g]]], n=1)
    y_max <- y_maxes[g]
    for (h in 2:(horizon+1)){

      forecast_bootstrap[,g,h] <- rtruncnorm(n = draws,
                                             a = 0,
                                             b = 2 * y_max,
                                             mean = rho * forecast_bootstrap[,g,h-1],
                                             sd = (rho * forecast_bootstrap[,g,h-1])^2 * global_sigma)

    }
  }
  forecast_bootstrap <- forecast_bootstrap[,,-c(1)]
  if(return_bootstrap){
    ret_val <- forecast_bootstrap
  }
  else{
    ret_val <- compute_quantiles(forecast_bootstrap, cols)
  }
  ret_val
}
## EMISSIONS PER FUEL ----------------------------------------------------------
make_forecast_constant_convergence <- function(draws,
                                               regions,
                                               horizon,
                                               fit,
                                               data,
                                               return_bootstrap=FALSE){
  
  #' Use posterior samples to simulate time series
  #'
  #' @param draws The number of posterior draws to use
  #' @param regions The number of global regions
  #' @param horizon The number of years to project forwards if lag=0
  #' @param fit Samples from posterior distribution
  #' @param data Historical time series data
  #' @param return_bootstrap If true return all the simulations, otherwise only
  #'                         return the quantiles
  #' @returns Time series simulation
  #' @export
  
  posterior <- rstan::extract(fit) # extract posterior samples from the fit
  forecast_bootstrap <- array(NA, dim = c(draws, regions, horizon + 1))
  
  cols <- colnames(data)[colnames(data) != "year"]
  
  for (g in 1:regions){
    phi <- posterior$phi[,g]
    gamma <- posterior$gamma[,g]
    sigma <- posterior$sigma[,g]
    
    forecast_bootstrap[,g,1] <- tail(data[[cols[g]]], n=1)
    
    for (h in 2:(horizon+1)){
      forecast_bootstrap[,g,h] <- rnorm(n = draws, mean = phi * (forecast_bootstrap[,g,h-1] - gamma) + gamma, sd = sigma)
    }
  }
  forecast_bootstrap <- forecast_bootstrap[,,-c(1)]
  
  if(return_bootstrap){
    ret_val <- forecast_bootstrap
  }
  else{
    ret_val <- compute_quantiles(forecast_bootstrap, cols)
  }
  ret_val
}
