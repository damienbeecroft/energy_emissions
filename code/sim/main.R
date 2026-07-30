source("C:/Users/damie/OneDrive/UW/research/dargan/projects/energy_emissions/code/sim/helper_functions.R") # look here for global variables and function definitions
set.seed(42)

# LOAD AND CLEAN DATA ----------------------------------------------------------
## POPULATION-------------------------------------------------------------------
population <- read.csv(paste0(LOAD_PATH, "population_grouped.csv"),
                       header = TRUE,
                       skip=1)
population <- population[-c(1)]
rownames(population) <- c(1960:YEAR)
population[,"year"] <- c(1960:YEAR)
population_global <- population["Global"]
population <- subset(population,
                     select=-c(Global))

## GDP PER CAPITA --------------------------------------------------------------
gdp_per_capita <- read.csv(paste0(LOAD_PATH, "gdp_per_capita.csv"),
                           header = TRUE,
                           skip = 1)
gdp_per_capita <- gdp_per_capita[-c(1)]
idx <- which(colnames(gdp_per_capita)=="USA.and.Canada")
gdp_per_capita <- cbind(gdp_per_capita[idx],
                        gdp_per_capita[-c(idx)]) # make USA Canada SG the first column (order is important for this one)
rownames(gdp_per_capita) <- c(1960:YEAR)
gdp_per_capita[,"year"] <- c(1960:YEAR)
gdp_per_capita_global <- gdp_per_capita["Global"]
gdp_per_capita <- subset(gdp_per_capita,
                         select=-c(Global))
gdp_per_capita_unchopped <- gdp_per_capita
gdp_per_capita[as.character(c(1960:SOVIET_END)),"E.Europe"] = NA
gdp_per_capita[as.character(c(1960:SOVIET_END)),"N.Asia"] = NA

## ENERGY PER GDP --------------------------------------------------------------
energy_per_gdp <- read.csv(paste0(LOAD_PATH, "energy_per_gdp.csv"),
                           header = TRUE,
                           skip = 1)
energy_per_gdp<- energy_per_gdp[-c(1)]
rownames(energy_per_gdp) <- c(1960:YEAR)
energy_per_gdp[,"year"] <- c(1960:YEAR)
energy_per_gdp_global <- energy_per_gdp["Global"]
energy_per_gdp <- subset(energy_per_gdp,
                         select=-c(Global))
energy_per_gdp_unchopped <- energy_per_gdp
energy_per_gdp[as.character(c(1960:SOVIET_END)),"E.Europe"] = NA
energy_per_gdp[as.character(c(1960:SOVIET_END)),"N.Asia"] = NA

## ELECTRIFICATION -------------------------------------------------------------
fraction_elec_n_heat <- read.csv(paste0(LOAD_PATH, "fraction_elec_n_heat.csv"),
                                 header = TRUE,
                                 skip = 1)
fraction_elec_n_heat <- fraction_elec_n_heat[-c(1)]
rownames(fraction_elec_n_heat) <- c(1960:YEAR)
fraction_elec_n_heat[,"year"] <- c(1960:YEAR)
fraction_elec_n_heat_global <- fraction_elec_n_heat["Global"]
fraction_elec_n_heat <- subset(fraction_elec_n_heat,
                               select=-c(Global))
fraction_elec_n_heat_unchopped <- fraction_elec_n_heat
fraction_elec_n_heat[as.character(c(1960:SOVIET_END)),"E.Europe"] = NA
fraction_elec_n_heat[as.character(c(1960:SOVIET_END)),"N.Asia"] = NA

## EMISSIONS PER UNIT OF ENERGY FROM ELECTRICITY AND HEAT ----------------------
emissions_per_elec_n_heat <- read.csv(paste0(LOAD_PATH, "emissions_per_elec_n_heat.csv"),
                                      header = TRUE,
                                      skip = 1)
emissions_per_elec_n_heat <- emissions_per_elec_n_heat[-c(1)]
rownames(emissions_per_elec_n_heat) <- c(1971:YEAR)
emissions_per_elec_n_heat[,"year"] <- c(1971:YEAR)
emissions_per_elec_n_heat_global <- emissions_per_elec_n_heat["Global"]
emissions_per_elec_n_heat <- subset(emissions_per_elec_n_heat,
                                    select=-c(Global))
emissions_per_elec_n_heat_unchopped <- emissions_per_elec_n_heat
emissions_per_elec_n_heat[as.character(c(1971:SOVIET_END)),"E.Europe"] = NA
emissions_per_elec_n_heat[as.character(c(1971:SOVIET_END)),"N.Asia"] = NA

## EMISSIONS PER UNIT OF ENERGY FROM DIRECT FUEL USE ---------------------------
emissions_per_direct <- read.csv(paste0(LOAD_PATH, "emissions_per_direct.csv"),
                                 header = TRUE,
                                 skip = 1)
emissions_per_direct <- emissions_per_direct[-c(1)]
rownames(emissions_per_direct) <- c(1971:YEAR)
emissions_per_direct[,"year"] <- c(1971:YEAR)
emissions_per_direct_global <- emissions_per_direct["Global"]
emissions_per_direct <- subset(emissions_per_direct,
                               select=-c(Global))
emissions_per_direct_unchopped <- emissions_per_direct
emissions_per_direct[as.character(c(1971:SOVIET_END)),"E.Europe"] = NA
emissions_per_direct[as.character(c(1971:SOVIET_END)),"N.Asia"] = NA

# FIT THE MODELS ---------------------------------------------------------------
## POPULATION ------------------------------------------------------------------

# create agg_df.txt for the region aggregations
world_codes <- get_codes(UNlocations)
my_regions <- UNlocations[c("country_code",
                            "reg_code",
                            "name",
                            "location_type")]
my_regions <- my_regions[my_regions$location_type == 4,]
region_names <- lapply(world_codes, names) %>% unlist %>% unname

new_regions <- data.frame(country_code=1000 + c(1:(region_names %>% length)),
                          reg_code=-1,
                          name=region_names,
                          location_type=1000 + c(1:(region_names %>% length)))
agg_df <- rbind(new_regions, my_regions)
code_idx <- 1000
for (continent_name in names(world_codes)){
  for (region_name in names(world_codes[[continent_name]])){
    code_idx <- code_idx + 1
    mask <- agg_df$country_code %in% world_codes[[continent_name]][[region_name]]
    colname <- paste0("agcode_",
                      toString(code_idx))
    agg_df[,colname] <- -1
    agg_df[mask,colname] <- code_idx
  }
}
write.table(agg_df, paste0(POP_SAVE_PATH,"aggregation_files/agg_df.txt"), sep="\t",row.names = FALSE)

lags <- c(0, 10, 20)

for(lag in lags){
  pop.pred <- get.pop.prediction(paste0(POP_SAVE_PATH,"sim/POP/POP_lag_",toString(lag))) # fetch population predictions
  my.location.file <- paste0(POP_SAVE_PATH,"aggregation_files/agg_df.txt")
  
  # run the aggregation
  pop.aggregate(
    pop.pred=pop.pred,
    regions=1000 + c(1:REGIONS),
    input.type="country",
    name="energy_regions",
    my.location.file=my.location.file
  )
}

## GDP PER CAPITA --------------------------------------------------------------

validation(gdp_per_capita,
           c(0,10,20),
           "gdp_per_capita",
           "global_frontier_ratio",
           plot_title = "GDP per Capita" ,
           plot_ylabel = "2026 US Dollars per Capita",
           run_simulation = FALSE,
           apply_ratio_frontier = TRUE,
           apply_cusum = TRUE)


# # For comparison with Raftery
# validation(gdp_per_capita,
#            c(20),
#            "gdp_per_capita",
#            "global_frontier_log_difference",
#            plot_title = "GDP per Capita" ,
#            plot_ylabel = "2026 US Dollars per Capita",
#            run_simulation = FALSE,
#            log_scale = TRUE)

# # GDP per Capita CUSUM Filtering Visualization
# gdp_per_capita_ratio <- gdp_per_capita
# # gdp_per_capita_cols <- colnames(gdp_per_capita)[-c(1,REGIONS + 1)]
# # gdp_per_capita_cols <- colnames(gdp_per_capita)[c(-26)] # remove the year column
# gdp_per_capita_cols <- c("China", "India", "SE.Asia", "Brazil", "Mexico.SG", "NW.South.America.SG", "S.South.America.SG", "NE.Africa.SG", "NW.Africa.SG", "Other.Africa", "S.Africa.SG")
# gdp_per_capita_ratio <- gdp_per_capita[gdp_per_capita_cols] / gdp_per_capita[,1]
# gdp_per_capita_filtered <- gdp_per_capita
# alpha = 0.02
# lag <- 0
# for (col in gdp_per_capita_cols){ # Apply CUSUM to find structural breaks
#   num_nan <- sum(is.na(gdp_per_capita_ratio[col]))
#   x <- gdp_per_capita_ratio[[col]]
#   x_na <- !is.na(x)
#   x <- x[x_na]
#   log_x <- log(1 - x)
#   z <- diff(log_x)
#   lenx <- length(x)
#   mask_lag <- -c((lenx-lag+1):lenx)
#   z <- z[mask_lag]
#   bp = 1
#   cusum_result <- efp(z ~ 1, type = "OLS-CUSUM")
#   check_for_significance <- cusum_result$process > boundary(cusum_result, alpha = alpha)
#   if (any(check_for_significance)){
#     bp <- which.max(cusum_result$process)
#     if(bp < lenx - 10 - lag){
#       gdp_per_capita_filtered[num_nan + c(1:bp) - 1, col] = NA
#     }
#   }
#   par(mfrow = c(2,1))  # 1 row, 2 columns
#   plot(x[mask_lag], main = col)
#   lines(x[mask_lag])
#   points(bp, x[bp], col = "red")
#   plot(cusum_result, alpha = alpha)
# }

## ENERGY PER GDP --------------------------------------------------------------

validation(energy_per_gdp,
           c(0,10,20),
           "energy_per_gdp",
           "trend_stationary_convergence",
           plot_title = "Quantity of Energy Consumed per \nUnit of GDP",
           plot_ylabel = "Megajoules per 2026 US Dollar",
           run_simulation = FALSE,
           log_scale = TRUE)

## FRACTION OF ENERGY FROM ELECTRICITY AND HEAT --------------------------------
validation(fraction_elec_n_heat,
           c(0,10,20),
           "fraction_elec_n_heat",
           "lgt_hierarchical",
           plot_title = "Fraction of Total Energy Consumption \nfrom Electricity and Heat",
           plot_ylabel = "Fraction of Total Energy",
           run_simulation = FALSE,
           logistic_scale = TRUE)

## EMISSIONS PER UNIT OF ENERGY FROM ELECTRICITY AND HEAT ----------------------

validation(emissions_per_elec_n_heat,
           c(0,10,20),
           "emissions_per_elec_n_heat",
           "exp_decay",
           plot_title = "CO2 Emissions per Unit of Energy from \nElectricity and Heat Consumption",
           plot_ylabel = "Grams per Megajoule",
           run_simulation = FALSE,
           chop_emissions_per_elec_n_heat = TRUE)

## EMISSIONS PER UNIT OF ENERGY FROM DIRECT FUEL USE ---------------------------
validation(emissions_per_direct,
           c(0,10,20),
           "emissions_per_direct",
           "constant_convergence",
           plot_title = "CO2 Emissions per Unit of Energy from \nDirect Fuel Use",
           plot_ylabel = "Grams per Megajoule",
           run_simulation = FALSE)


# AGGREGATIONS AND ERRORS ------------------------------------------------------
## PLOT AGGREGATE QUANTITIES ---------------------------------------------------
lags <- c(0, 10, 20)
agg_df <- read.table(paste0(POP_SAVE_PATH, "aggregation_files/agg_df.txt"),
                     header=TRUE,
                     sep="\t")
names <- agg_df[agg_df$country_code>1000,
                "name"]
pop_cols <- gsub(" ",
                 ".",
                 names)
population_reordered <- population[,c(pop_cols,"year")] # reorder columns to be in line with bayesPop forecasts
common_years <- as.character(c(1971:YEAR)) # the years that all the time series have in common
cols <- colnames(population[colnames(population) != "year"])

for (lag in lags){
  population_path <- paste0(POP_SAVE_PATH,
                            "sim/POP/POP_lag_",
                            toString(lag),
                            "aggregations_energy_regions/aggregations_energy_regions",
                            "_",
                            toString(lag),
                            ".rds")
  gdp_per_capita_path <- paste0(TRACE_PATH,
                                "gdp_per_capita/global_frontier_ratio/global_frontier_ratio",
                                "_",
                                toString(lag),
                                ".rds")
  energy_per_gdp_path <- paste0(TRACE_PATH,
                                "energy_per_gdp/trend_stationary_convergence/trend_stationary_convergence",
                                "_",
                                toString(lag),
                                ".rds")
  fraction_elec_n_heat_path <- paste0(TRACE_PATH,
                                      "fraction_elec_n_heat/lgt_hierarchical/lgt_hierarchical",
                                      "_",
                                      toString(lag),
                                      ".rds")
  emissions_per_elec_n_heat_path <- paste0(TRACE_PATH,
                                           "emissions_per_elec_n_heat/exp_decay/exp_decay",
                                           "_",
                                           toString(lag),
                                           ".rds")
  emissions_per_direct_path <- paste0(TRACE_PATH,
                                     "emissions_per_direct/constant_convergence/constant_convergence",
                                     "_",
                                     toString(lag),
                                     ".rds")
  
  population_list <- list(data=population_reordered[common_years,], 
                          directory=population_path,
                          global=population_global[common_years,])
  gdp_per_capita_list <- list(data=gdp_per_capita_unchopped[common_years,], 
                              method="global_frontier_ratio",
                              directory=gdp_per_capita_path,
                              global=gdp_per_capita_global[common_years,])
  energy_per_gdp_list <- list(data=energy_per_gdp_unchopped[common_years,], 
                              method="trend_stationary_convergence",
                              directory=energy_per_gdp_path,
                              global=energy_per_gdp_global[common_years,])
  fraction_elec_n_heat_list <- list(data=fraction_elec_n_heat_unchopped[common_years,], 
                                    method="lgt_hierarchical", 
                                    directory=fraction_elec_n_heat_path,
                                    global=fraction_elec_n_heat_global[common_years,])
  emissions_per_elec_n_heat_list <- list(data=emissions_per_elec_n_heat_unchopped[common_years,], 
                                         method="exp_decay",
                                         directory=emissions_per_elec_n_heat_path,
                                         global=emissions_per_elec_n_heat_global[common_years,])
  emissions_per_direct_list <- list(data=emissions_per_direct_unchopped[common_years,], 
                                    method="constant_convergence",
                                    directory=emissions_per_direct_path,
                                    global=emissions_per_direct_global[common_years,])

  all_data <- list(population=population_list,
                   gdp_per_capita=gdp_per_capita_list,
                   energy_per_gdp=energy_per_gdp_list,
                   fraction_elec_n_heat=fraction_elec_n_heat_list,
                   emissions_per_elec_n_heat=emissions_per_elec_n_heat_list,
                   emissions_per_direct=emissions_per_direct_list)
  all_data <- aggregate_timeseries(all_data, lag)
  
  
  # Population
  make_aggregate_plots(all_data,
                       lag,
                       "population",
                       cols,
                       SAVE_PATH,
                       "Population",
                       "Number of Individuals",
                       log_scale=FALSE,
                       global=TRUE)
  
  # GDP per Capita
  make_aggregate_plots(all_data,
                       lag,
                       "gdp_per_capita",
                       cols,
                       SAVE_PATH,
                       "GDP per Capita",
                       "2026 US Dollars per Capita",
                       log_scale=FALSE,
                       global=TRUE)

  # Energy per Unit of GDP
  make_aggregate_plots(all_data,
                       lag,
                       "energy_per_gdp",
                       cols,
                       SAVE_PATH,
                       "Quantity of Energy Consumed \nper Unit of GDP",
                       "Megajoules per 2026 US Dollar",
                       log_scale=TRUE,
                       global=TRUE)

  # Fraction of Energy from Electricity and Heat
  make_aggregate_plots(all_data,
                      lag,
                      "fraction_elec_n_heat",
                      cols,
                      SAVE_PATH,
                      "Fraction of Total Energy Consumption \nfrom Electricity and Heat",
                      "Fraction of Total Energy",
                      log_scale=FALSE,
                      global=TRUE)

  # Emissions per Electricity and Heat
  make_aggregate_plots(all_data,
                       lag,
                       "emissions_per_elec_n_heat",
                       cols,
                       SAVE_PATH,
                       "CO2 Emissions per Unit of Energy from \nElectricity and Heat Consumption",
                       "Grams per Megajoule",
                       log_scale=FALSE,
                       global=TRUE)

  # Emissions per Direct Fuel
  make_aggregate_plots(all_data,
                       lag,
                       "emissions_per_direct",
                       cols,
                       SAVE_PATH,
                       "CO2 Emissions per Unit of Energy from \nDirect Fuel Use",
                       "Grams per Megajoule",
                       log_scale=FALSE,
                       global=TRUE)
  # Total Energy Emissions
  make_aggregate_plots(all_data,
                       lag,
                       "total_energy_emissions",
                       cols,
                       SAVE_PATH,
                       "",
                       expression("Gigatons of CO2"),
                       log_scale=FALSE,
                       scale=1e-15,
                       global=TRUE)
  
  # Energy per Capita
  make_aggregate_plots(all_data,
                       lag,
                       "energy_per_capita",
                       cols,
                       SAVE_PATH,
                       "Energy per Capita",
                       "Megajoules per Person",
                       log_scale=FALSE,
                       global=TRUE)

  # Emissions per Energy
  make_aggregate_plots(all_data,
                       lag,
                       "emissions_per_energy",
                       cols,
                       SAVE_PATH,
                       "Emissions per Unit of Energy",
                       expression("Grams of CO2 per Megajoule"),
                       log_scale=FALSE,
                       global=TRUE)

  # Electricity per Capita
  make_aggregate_plots(all_data,
                       lag,
                       "electricity_per_capita",
                       cols,
                       SAVE_PATH,
                       "Electricity per Capita",
                       "Megajoules per Person",
                       log_scale=FALSE,
                       global=TRUE)

  # Total Electricity Emissions
  make_aggregate_plots(all_data,
                       lag,
                       "total_electricity_emissions",
                       cols,
                       SAVE_PATH,
                       "Total Electricity and Heat Plant\n Emissions",
                       "Gigatons of CO2",
                       scale=1e-15,
                       log_scale=FALSE,
                       global=TRUE)


  # Total Non-Electricity Emissions
  make_aggregate_plots(all_data,
                       lag,
                       "total_nonelectricity_emissions",
                       cols,
                       SAVE_PATH,
                       "Total Direct Fuel Use\n Emissions",
                       "Gigatons of CO2",
                       scale=1e-15,
                       log_scale=FALSE,
                       global=TRUE)

  # Total Electricity Energy
  make_aggregate_plots(all_data,
                       lag,
                       "total_electricity",
                       cols,
                       SAVE_PATH,
                       "Total Electricity and Heat Plant\n Energy",
                       "Exajoules",
                       scale=1e-12,
                       log_scale=FALSE,
                       global=TRUE)

  # Total Non-Electricity Energy
  make_aggregate_plots(all_data,
                       lag,
                       "total_nonelectricity",
                       cols,
                       SAVE_PATH,
                       "Total Direct Fuel Use\n Energy",
                       "Exajoules",
                       scale=1e-12,
                       log_scale=FALSE,
                       global=TRUE)
  
  # Total Non-Electricity Energy
  make_aggregate_plots(all_data,
                       lag,
                       "total_nonelectricity",
                       cols,
                       SAVE_PATH,
                       "Total Direct Fuel Use\n Energy",
                       "Exajoules",
                       scale=1e-12,
                       log_scale=FALSE,
                       global=TRUE)
}