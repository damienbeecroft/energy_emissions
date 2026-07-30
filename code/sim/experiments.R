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


## EXPERIMENT 1 ----------------------------------------------------------------
lags <- c(0)
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
                              method="global_frontier_ratio_experiment",
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
  
  # browser()
  
  # Total Energy Emissions
  make_aggregate_plots(all_data,
                       lag,
                       "total_energy_emissions",
                       cols,
                       "C:/Users/damie/OneDrive/UW/research/dargan/projects/energy_emissions/experiments/1/",
                       "",
                       expression("Gigatons of CO2"),
                       log_scale=FALSE,
                       scale=1e-15,
                       global=TRUE)
}


## EXPERIMENT 2 ----------------------------------------------------------------

lags <- c(0)
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
  
  # browser()
  
  all_data[["population"]][["forecast"]][,"Other.Africa",] <- population["2022", "Other.Africa"]
  all_data[["population"]][["forecast"]][,"S.Africa",] <- population["2022", "S.Africa"]
  
  # Total Energy Emissions
  make_aggregate_plots(all_data,
                       lag,
                       "total_energy_emissions",
                       cols,
                       "C:/Users/damie/OneDrive/UW/research/dargan/projects/energy_emissions/experiments/2/",
                       "",
                       expression("Gigatons of CO2"),
                       log_scale=FALSE,
                       scale=1e-15,
                       global=TRUE)
  # Population
  make_aggregate_plots(all_data,
                       lag,
                       "population",
                       cols,
                       "C:/Users/damie/OneDrive/UW/research/dargan/projects/energy_emissions/experiments/2/",
                       "",
                       "Number of Individuals",
                       log_scale=FALSE,
                       global=TRUE)
}

## BOX PLOT --------------------------------------------------------------------

eh.emissions.data <- read.csv(paste0(SAVE_PATH,"plots/aggregates/total_electricity_emissions/total_electricity_emissions_0/data.csv"))
df.emissions.data <- read.csv(paste0(SAVE_PATH,"plots/aggregates/total_nonelectricity_emissions/total_nonelectricity_emissions_0/data.csv"))
population.data  <- read.csv(paste0(SAVE_PATH,"plots/aggregates/population/population_0/data.csv"))

groupings <- list(
                  "Oceania" = c("Australia", "New.Zealand"),
                  "North.America" = c("USA.and.Canada", "Mexico", "Central.America", "Other.North.America"),
                  "North.Asia" = c("N.Asia"),
                  "East.Asia" = c("China.and.Taiwan", "Japan", "Korea"),
                  "Middle.East" = c("Middle.East"),
                  "Europe" = c("E.Europe", "N.Europe", "British.Isles", "Continental.Europe"),
                  "Southeast.Asia" = c("SE.Asia"),
                  "South.America" = c("Brazil", "NW.South.America", "S.South.America"),
                  "South.Asia" = c("India", "Other.Asia"),
                  "Africa" = c("S.Africa", "Other.Africa", "NW.Africa", "NE.Africa")
)

eh.emissions.data <- as.data.frame(
  lapply(groupings, function(cols) rowSums(eh.emissions.data[, cols, drop = FALSE]))
)
df.emissions.data <- as.data.frame(
  lapply(groupings, function(cols) rowSums(df.emissions.data[, cols, drop = FALSE]))
)
population.data <- as.data.frame(
  lapply(groupings, function(cols) rowSums(population.data[, cols, drop = FALSE]))
)

r <- dim(eh.emissions.data)[1]
population <- as.numeric(population.data[r,])
eh <- 1e9 * as.numeric(eh.emissions.data[r,])/population
df <- 1e9 * as.numeric(df.emissions.data[r,])/population

n <- length(population)
width <- rep(population, 2)
value <- c(eh, df)
group <- rep(colnames(eh.emissions.data), 2)
category <- c(rep("E&H", n), rep("DF", n))
xmin <- cumsum(c(0,population[-c(n)]))
xmin <- c(xmin, xmin)

df <- data.frame(
  group = group,
  category = category,
  value = value,
  xmin = xmin,
  width = width
)

df <- df %>%
  group_by(group) %>%
  mutate(
    ymin = cumsum(value) - value,
    ymax = cumsum(value),
    xmax = xmin + width,
    xcenter = xmin + (width/2)
  )

myplot <- ggplot(df) +
  geom_rect(
    aes(
      xmin = xmin,
      xmax = xmax,
      ymin = ymin,
      ymax = ymax,
      fill = category
    ),
    color = "white"
  ) +
  scale_fill_manual(
    values = c(
      "DF" = "sienna",
      "E&H" = "gold2"
    )
  ) +
scale_x_continuous(
  breaks = unlist(df[1:n,"xcenter"]),
  minor_breaks = seq(0, 1e10, by = 1e9),
  labels = gsub(".", " ", names(groupings), fixed = TRUE)
) +
  labs(x = NULL, y = "Mg CO2 per Capita per Year") +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 0.5, size = 15),
    axis.text.y = element_text(size = 15),
    legend.text = element_text(size = 15),
    axis.title.y = element_text(size = 20),
    legend.title = element_blank(),
    panel.grid.minor.x = element_line(),
    panel.grid.major.x = element_blank()
  )

ggsave(
  paste0("C:/Users/damie/OneDrive/UW/research/dargan/projects/energy_emissions/experiments/box_plots/box_plot2022.png"),
  plot = myplot,
  width = 10,
  height = 8,
  create.dir = TRUE
)

eh.emissions.forecast <- read.csv(paste0(SAVE_PATH,"plots/aggregates/total_electricity_emissions/total_electricity_emissions_0/forecast.csv"))
df.emissions.forecast <- read.csv(paste0(SAVE_PATH,"plots/aggregates/total_nonelectricity_emissions/total_nonelectricity_emissions_0/forecast.csv"))
population.forecast <- read.csv(paste0(SAVE_PATH,"plots/aggregates/population/population_0/forecast.csv"))

c <- dim(eh.emissions.forecast)[2]

eh.emissions.forecast <- eh.emissions.forecast[, seq(3, c, by = 5)]
df.emissions.forecast <- df.emissions.forecast[, seq(3, c, by = 5)]
population.forecast <- population.forecast[, seq(3, c, by = 5)]

groupings <- list(
  "Oceania" = c("Australia.median", "New.Zealand.median"),
  "North.America" = c("USA.and.Canada.median", "Mexico.median", "Central.America.median", "Other.North.America.median"),
  "North.Asia" = c("N.Asia.median"),
  "East.Asia" = c("China.and.Taiwan.median", "Japan.median", "Korea.median"),
  "Middle.East" = c("Middle.East.median"),
  "Europe" = c("E.Europe.median", "N.Europe.median", "British.Isles.median", "Continental.Europe.median"),
  "Southeast.Asia" = c("SE.Asia.median"),
  "South.America" = c("Brazil.median", "NW.South.America.median", "S.South.America.median"),
  "South.Asia" = c("India.median", "Other.Asia.median"),
  "Africa" = c("S.Africa.median", "Other.Africa.median", "NW.Africa.median", "NE.Africa.median")
)

eh.emissions.forecast <- as.data.frame(
  lapply(groupings, function(cols) rowSums(eh.emissions.forecast[, cols, drop = FALSE]))
)
df.emissions.forecast <- as.data.frame(
  lapply(groupings, function(cols) rowSums(df.emissions.forecast[, cols, drop = FALSE]))
)
population.forecast <- as.data.frame(
  lapply(groupings, function(cols) rowSums(population.forecast[, cols, drop = FALSE]))
)

r <- dim(eh.emissions.forecast)[1]
population <- as.numeric(population.forecast[r,])
eh <- 1e9 * as.numeric(eh.emissions.forecast[r,])/population
df <- 1e9 * as.numeric(df.emissions.forecast[r,])/population

n <- length(population)
width <- rep(population, 2)
value <- c(eh, df)
group <- rep(colnames(eh.emissions.forecast), 2)
category <- c(rep("E&H", n), rep("DF", n))
xmin <- cumsum(c(0,population[-c(n)]))
xmin <- c(xmin, xmin)

df <- data.frame(
  group = group,
  category = category,
  value = value,
  xmin = xmin,
  width = width
)

df <- df %>%
  group_by(group) %>%
  mutate(
    ymin = cumsum(value) - value,
    ymax = cumsum(value),
    xmax = xmin + width,
    xcenter = xmin + (width/2)
  )

myplot <- ggplot(df) +
  geom_rect(
    aes(
      xmin = xmin,
      xmax = xmax,
      ymin = ymin,
      ymax = ymax,
      fill = category
    ),
    color = "white"
  ) +
  scale_fill_manual(
    values = c(
      "DF" = "sienna",
      "E&H" = "gold2"
    )
  ) +
  scale_x_continuous(
    breaks = unlist(df[1:n,"xcenter"]),
    minor_breaks = seq(0, 1e10, by = 1e9),
    labels = gsub(".", " ", names(groupings), fixed = TRUE)
  ) +
  labs(x = NULL, y = "Mg CO2 per Capita per Year") +
  theme(
    axis.text.x = element_text(angle = 90, vjust = 0.5, hjust = 0.5, size = 15),
    axis.text.y = element_text(size = 15),
    legend.text = element_text(size = 15),
    axis.title.y = element_text(size = 20),
    legend.title = element_blank(),
    panel.grid.minor.x = element_line(),
    panel.grid.major.x = element_blank()
  )

ggsave(
  paste0("C:/Users/damie/OneDrive/UW/research/dargan/projects/energy_emissions/experiments/box_plots/box_plot2050.png"),
  plot = myplot,
  width = 10,
  height = 8,
  create.dir = TRUE
)