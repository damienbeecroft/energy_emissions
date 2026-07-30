###################################################################################
# The code below shows the region aggregations used in the paper
###################################################################################

# North America ###################################################################
usa_canada_sg = ["USA",
				 "CANADA"] # A bit of this grid goes into Mexico

mexico_sg = ["MEXICO"]

central_america_sg = ["GUATEMALA",
                      "ELSALVADOR",
                      "HONDURAS",
                      "COSTARICA",
                      "PANAMA",
                      "NICARAGUA"]

other_north_america = ["CUBA",
				       "JAMAICA",
				       "HAITI",
				       "DOMINICANR"]

# greenland = ["MGREENLAND"]

# South America ###################################################################
northwestern_south_america_sg = ["VENEZUELA",
				                 "COLOMBIA",
				                 "ECUADOR",
				                 "PERU",
				                 "BOLIVIA"]

southern_south_america_sg = ["CHILE",
				             "ARGENTINA",
				             "PARAGUAY",
				             "URUGUAY"]

brazil_sg = ["BRAZIL"]

# Europe ##########################################################################
continental_europe_sg = ["BOSNIAHERZ",
				         "NORTHMACED",
				         "SERBIA",
				         "SWITLAND",
				         "TURKEY",
				         "AUSTRIA",
				         "BELGIUM",
				         "BULGARIA",
				         "CROATIA",
				         "DENMARK", # Denmark is split between grids
				         "FRANCE", # France includes French Guiana after 2011
				         "GERMANY",
				         "GREECE",
				         "HUNGARY",
				         "ITALY",
				         "LUXEMBOU",
				         "MALTA",
				         "POLAND",
				         "PORTUGAL",
				         "ROMANIA",
				         "SLOVAKIA",
				         "SLOVENIA",
				         "SPAIN",
				         "ALBANIA",
				         "CZECH",
				         "NETHLAND"] # this grid is connected to countries in NW Africa
				 
northern_europe_sg = ["SWEDEN",
				      "NORWAY",
				      "FINLAND"]

eastern_europe_sg = ["ESTONIA",
				     "LATVIA",
				     "LITHUANIA",
				     "MOLDOVA",
				     "UKRAINE"]

british_isles = ["UK",
				 "IRELAND"]

# iceland = ["ICELAND"]

# Africa ##########################################################################
northwest_africa_sg = ["MOROCCO",
				       "ALGERIA",
				       "TUNISIA"] # This is connected to the continental Europe synchronous grid

southern_africa_sg = ["ANGOLA",
				      "BOTSWANA",
				      "CONGOREP",
				      "ESWATINI",
				      "MOZAMBIQUE",
				      "NAMIBIA",
				      "SOUTHAFRIC",
				      "TANZANIA",
				      "ZAMBIA",
				      "ZIMBABWE",
				      "KENYA",
				      "UGANDA"] # Lesotho and Malawi are in this grid, but not separated

northeast_africa_sg = ["LIBYA",
				       "EGYPT"] # This grid also has connections to Jordan, but I separated this grid to keep Asia and Africa separate

other_africa_add = ["AFRICA"]
other_africa_subtract = northwest_africa_sg + southern_africa_sg + northeast_africa_sg

# Asia ############################################################################
# West Asia
middle_east = ["MIDEAST",
			   "ISRAEL",
			   "CYPRUS"]

# North and Central Asia
northern_asia_sg_add = ["MFSU15",
				        "MONGOLIA"]

northern_asia_sg_subtract = ["ESTONIA",
				             "LATVIA",
				             "LITHUANIA",
				             "UKRAINE",
				             "MOLDOVA"]
# South East Asia
southeastern_asia = ["CAMBODIA",
				     "INDONESIA",
				     "LAO",
				     "MALAYSIA",
				     "MYANMAR",
				     "PHILIPPINE",
				     "SINGAPORE",
				     "THAILAND",
				     "VIETNAM"]

# South Asia
india_sg = ["INDIA"]

# East Asia
china_taiwan = ["CHINAREG"]

korea = ["KOREA"]

japan = ["JAPAN"]

other_asia = ["PAKISTAN",
		      "NEPAL",
		      "BANGLADESH",
		      "SRILANKA"]

# taiwan = ["TAIPEI"]

# Oceania #########################################################################
australia = ["AUSTRALI"]

new_zealand = ["NZ"]

# Region aggregations #############################################################
region_aggregations = {
    "North America": {"USA and Canada": usa_canada_sg,
					  "Mexico": mexico_sg,
					  "Central America": central_america_sg,
					  "Other North America": other_north_america},
    
    "South America": {"NW South America": northwestern_south_america_sg,
					  "Brazil": brazil_sg,
					  "S South America": southern_south_america_sg},
    
	"Asia": {"Middle East": middle_east,
		     "N Asia Add": northern_asia_sg_add,
		     "N Asia Subtract": northern_asia_sg_subtract,
		     "India": india_sg,
		     "SE Asia": southeastern_asia,
		     "China and Taiwan": china_taiwan,
		     "Korea": korea,
		     "Japan": japan,
		     "Other Asia": other_asia},
    
    "Europe": {"Continental Europe": continental_europe_sg,
			   "N Europe": northern_europe_sg,
			   "E Europe": eastern_europe_sg,
			   "British Isles": british_isles},
    
    "Africa": {"Other Africa Subtract": other_africa_subtract,
			   "Other Africa Add": other_africa_add,
			   "NW Africa": northwest_africa_sg,
			   "NE Africa": northeast_africa_sg,
			   "S Africa": southern_africa_sg},
    
    "Oceania": {"Australia": australia,
				"New Zealand": new_zealand}
	}

###################################################################################
# Different datasets have different naming conventions. These dictionaries
# translate the naming conventions into those used in the IEA World Energy 
# Balances
###################################################################################

# translator used for population dataset
population_translator = {
    # North America #################
	"USA": ["USA"],
	"CANADA": ["CAN"],
	"MEXICO": ["MEX"],
	"GUATEMALA": ["GTM"],
	"ELSALVADOR": ["SLV"],
	"HONDURAS": ["HND"],
	"COSTARICA": ["CRI"],
	"PANAMA": ["PAN"],
	"NICARAGUA": ["NIC"],
	"CUBA": ["CUB"],
	"JAMAICA": ["JAM"],
	"HAITI": ["HTI"],
	"DOMINICANR": ["DOM"],
    "MGREENLAND": ["GRL"],
    # South America #################
	"VENEZUELA": ["VEN"],
	"COLOMBIA": ["COL"],
	"ECUADOR": ["ECU"],
	"PERU": ["PER"],
	"CHILE": ["CHL"],
	"ARGENTINA": ["ARG"],
	"PARAGUAY": ["PRY"],
	"URUGUAY": ["URY"],
	"GUYANA": ["GUY"],
	"SURINAME": ["SUR"],
	"BOLIVIA": ["BOL"],
	"BRAZIL": ["BRA"],
	# Europe ########################
	"BOSNIAHERZ": ["BIH"],
	"NORTHMACED": ["MKD"],
	# "KOSOVO": ["XKX"], 
	"SERBIA": ["SRB"], 
	"SWITLAND": ["CHE"], 
	"TURKEY": ["TUR"], 
	"MOLDOVA": ["MDA"], 
	"AUSTRIA": ["AUT"], 
	"BELGIUM": ["BEL"], 
	"BULGARIA": ["BGR"], 
	"CROATIA": ["HRV"], 
	"DENMARK": ["DNK"], 
	"FRANCE": ["FRA"], 
	"GERMANY": ["DEU"], 
	"GREECE": ["GRC"], 
	"HUNGARY": ["HUN"], 
	"ITALY": ["ITA"], 
	"LUXEMBOU": ["LUX"], 
	"MALTA": ["MLT"], 
	"POLAND": ["POL"], 
	"PORTUGAL": ["PRT"], 
	"ROMANIA": ["ROU"], 
	"SLOVAKIA": ["SVK"], 
	"SLOVENIA": ["SVN"], 
	"SPAIN": ["ESP"], 
	"UKRAINE": ["UKR"], 
	"ALBANIA": ["ALB"], 
	"CZECH": ["CZE"], 
	"NETHLAND": ["NLD"],
	"SWEDEN": ["SWE"], 
	"NORWAY": ["NOR"], 
	"FINLAND": ["FIN"],
	"ESTONIA": ["EST"], 
	"LATVIA": ["LVA"], 
	"LITHUANIA": ["LTU"],
	"UK": ["GBR"], 
	"IRELAND": ["IRL"],
	"ICELAND": ["ISL"],
    # Africa ########################
	"MOROCCO": ["MAR"], 
	"ALGERIA": ["DZA"], 
	"TUNISIA": ["TUN"], 
	"ANGOLA": ["AGO"],
	"BOTSWANA": ["BWA"], 
	"CONGOREP": ["COD"], 
	"ESWATINI": ["SWZ"], 
	"MOZAMBIQUE": ["MOZ"], 
	"NAMIBIA": ["NAM"],
	"SOUTHAFRIC": ["ZAF"], 
	"TANZANIA": ["TZA"], 
	"ZAMBIA": ["ZMB"], 
	"ZIMBABWE": ["ZWE"], 
	"LIBYA": ["LBY"], 
	"EGYPT": ["EGY"], 
	"SUDAN": ["SDN"],
    "UGANDA": ["UGA"],
    "KENYA": ["KEN"],
	"AFRICA": ["Africa"],
    # Asia ##########################
	"INDIA": ["IND"],
	"TAIPEI": ["TWN"],
	"KOREA": ["KOR"],
	"JAPAN": ["JPN"],
	"ISRAEL": ["ISR"],
	"MONGOLIA": ["MNG"],
	"PAKISTAN": ["PAK"],
	"NEPAL": ["NPL"],
	"BANGLADESH": ["BGD"],
    "SRILANKA": ["LKA"],
	"CHINAREG": ["CHN", # China proper
				 "HKG", # Hong Kong 
                 "TWN"], # Taiwan
    "CYPRUS": ["CYP"],
	"MIDEAST": ["BHR", # Bahrain
				"IRN", # Iran
				"IRQ", # Iraq
				"JOR", # Jordan
				"KWT", # Kuwait
				"LBN", # Lebanon
				"OMN", # Oman
				"QAT", # Qatar
				"SAU", # Saudi Arabia
				"SYR", # Syria
				"ARE", # United Arab Emirates
				"YEM"], # Yemen
	"MFSU15":  ["MDA", # Moldova
				"UKR", # Ukraine
				"EST", # Estonia
				"LVA", # Latvia
				"LTU", # Lithuania
				"RUS", # Russia
				"KAZ", # Kazakhstan
				"UZB", # Uzbekistan
				"TKM", # Turkmenistan
                "TJK", # Tajikistan
				"KGZ", # Kyrgyzstan
				"GEO", # Georgia
				"AZE", # Azerbaijan
				"ARM", # Armenia
				"BLR"], # Belarus
    "CAMBODIA": ["KHM"],
    "INDONESIA": ["IDN"],
    "LAO": ["LAO"],
    "MALAYSIA": ["MYS"],
    "MYANMAR": ["MMR"],
    "PHILIPPINE": ["PHL"],
    "SINGAPORE": ["SGP"],
    "THAILAND": ["THA"],
    "VIETNAM": ["VNM"],
	# Oceania #######################
    "AUSTRALI": ["AUS"],
    "NZ": ["NZL"]
}

# translator used for GDP dataset
gdp_translator = {
    # North America #################
	"USA": ["USA"],
	"CANADA": ["CAN"],
	"MEXICO": ["MEX"],
	"GUATEMALA": ["GTM"],
	"ELSALVADOR": ["SLV"],
	"HONDURAS": ["HND"],
	"COSTARICA": ["CRI"],
	"PANAMA": ["PAN"],
	"NICARAGUA": ["NIC"],
	"CUBA": ["CUB"],
	"JAMAICA": ["JAM"],
	"HAITI": ["HTI"],
	"DOMINICANR": ["DOM"],
    "MGREENLAND": ["GRL"],
    # South America #################
	"VENEZUELA": ["VEN"],
	"COLOMBIA": ["COL"],
	"ECUADOR": ["ECU"],
	"PERU": ["PER"],
	"CHILE": ["CHL"],
	"ARGENTINA": ["ARG"],
	"PARAGUAY": ["PRY"],
	"URUGUAY": ["URY"],
	"GUYANA": ["GUY"],
	"SURINAME": ["SUR"],
	"BOLIVIA": ["BOL"],
	"BRAZIL": ["BRA"],
	# Europe ########################
	"BOSNIAHERZ": ["BIH"], 
	"NORTHMACED": ["MKD"], 
	# "KOSOVO": ["XKX"], 
	"SERBIA": ["SRB"], 
	"SWITLAND": ["CHE"], 
	"TURKEY": ["TUR"], 
	"MOLDOVA": ["MDA"], 
	"AUSTRIA": ["AUT"], 
	"BELGIUM": ["BEL"], 
	"BULGARIA": ["BGR"], 
	"CROATIA": ["HRV"], 
	"DENMARK": ["DNK"], 
	"FRANCE": ["FRA"], 
	"GERMANY": ["DEU"], 
	"GREECE": ["GRC"], 
	"HUNGARY": ["HUN"], 
	"ITALY": ["ITA"], 
	"LUXEMBOU": ["LUX"], 
	"MALTA": ["MLT"], 
	"POLAND": ["POL"], 
	"PORTUGAL": ["PRT"], 
	"ROMANIA": ["ROU"], 
	"SLOVAKIA": ["SVK"], 
	"SLOVENIA": ["SVN"], 
	"SPAIN": ["ESP"], 
	"UKRAINE": ["UKR"], 
	"ALBANIA": ["ALB"], 
	"CZECH": ["CZE"], 
	"NETHLAND": ["NLD"],
	"SWEDEN": ["SWE"], 
	"NORWAY": ["NOR"], 
	"FINLAND": ["FIN"],
	"ESTONIA": ["EST"], 
	"LATVIA": ["LVA"], 
	"LITHUANIA": ["LTU"],
	"UK": ["GBR"], 
	"IRELAND": ["IRL"],
	"ICELAND": ["ISL"],
    # Africa ########################
	"MOROCCO": ["MAR"], 
	"ALGERIA": ["DZA"], 
	"TUNISIA": ["TUN"], 
	"ANGOLA": ["AGO"],
	"BOTSWANA": ["BWA"], 
	"CONGOREP": ["COD"], 
	"ESWATINI": ["SWZ"], 
	"MOZAMBIQUE": ["MOZ"], 
	"NAMIBIA": ["NAM"],
	"SOUTHAFRIC": ["ZAF"], 
	"TANZANIA": ["TZA"], 
	"ZAMBIA": ["ZMB"], 
	"ZIMBABWE": ["ZWE"], 
	"LIBYA": ["LBY"], 
	"EGYPT": ["EGY"], 
	"SUDAN": ["SDN"],
    "UGANDA": ["UGA"],
    "KENYA": ["KEN"],
	"AFRICA": ["DZA", # Algeria
			   "AGO", # Angola
			   "BEN", # Benin
			   "BWA", # Botswana
			   "BFA", # Burkina Faso
			   "BDI", # Burundi
			   "CMR", # Cameroon
			   "CPV", # Cape Verde
			   "CAF", # Central African Republic
			   "TCD", # Chad
			   "COM", # Comoros
			   "COG", # Congo
			   "COD", # Demoratic Republic of the Congo
			   # "CIV", # Cote d'Irvoire
			   "DJI", # Djibouti
			   "EGY", # Egypt
			   "GNQ", # Equatorial Guinea
			   # "ERI", # Eritrea
			   "ETH", # Ethiopia
			   "GAB", # Gabon
			   "GMB", # Gambia
			   "GHA", # Ghana
			   "GIN", # Guinea
			   "GNB", # Guinea-Bissau
			   "KEN", # Kenya
			   "LSO", # Lesotho
			   "LBR", # Liberia
			   "LBY", # Libya
			   "MDG", # Madagascar
			   "MLI", # Mali
			   "MWI", # Malawi
			   "MRT", # Mauritania
			   "MUS", # Mauritius
			   # "MYT", # Mayotte
			   "MAR", # Morocco
			   "MOZ", # Mozambique
			   "NAM", # Namibia
			   "NER", # Niger
			   "NGA", # Nigeria
			   # "REU", # Reunion
			   "RWA", # Rwanda
			   "STP", # Sao Tome and Principe
			   "SEN", # Senegal
			   "SYC", # Seychelles
			   "SLE", # Sierra Leone
			   # "SOM", # Somalia
			   "ZAF", # South Africa
			   # "SSD", # South Sudan
			   "SDN", # Sudan
			   "SWZ", # Swaziland
			   "TZA", # Tanzania
			   "TGO", # Togo
			   "TUN", # Tunisia
			   "UGA", # Uganda
			   # "ESH", # West Sahara
			   "ZMB", # Zambia
			   "ZWE"], # Zimbabwe
    # Asia ##########################
	"INDIA": ["IND"],
	"TAIPEI": ["TWN"],
	"KOREA": ["KOR"],
	"JAPAN": ["JPN"],
	"ISRAEL": ["ISR"],
	"MONGOLIA": ["MNG"],
	"PAKISTAN": ["PAK"],
	"NEPAL": ["NPL"],
	"BANGLADESH": ["BGD"],
    "SRILANKA": ["LKA"],
	"CHINAREG": ["CHN", # China proper
				 "HKG", # Hong Kong 
                 "TWN"], # Taiwan
	"CYPRUS": ["CYP"],
	"MIDEAST": ["BHR", # Bahrain
				"IRN", # Iran
				"IRQ", # Iraq
				"JOR", # Jordan
				"KWT", # Kuwait
				"LBN", # Lebanon
				"OMN", # Oman
				"QAT", # Qatar
				"SAU", # Saudi Arabia
				"SYR", # Syria
				"ARE", # United Arab Emirates
				"YEM"], # Yemen
	"MFSU15":  ["MDA", # Moldova
				"UKR", # Ukraine
				"EST", # Estonia
				"LVA", # Latvia
				"LTU", # Lithuania
				"RUS", # Russia
				"KAZ", # Kazakhstan
				"UZB", # Uzbekistan
				"TKM", # Turkmenistan
				"TJK", # Tajikistan
				"KGZ", # Kyrgyzstan
				"GEO", # Georgia
				"AZE", # Azerbaijan
				"ARM", # Armenia
				"BLR"], # Belarus
    "CAMBODIA": ["KHM"],
    "INDONESIA": ["IDN"],
    "LAO": ["LAO"],
    "MALAYSIA": ["MYS"],
    "MYANMAR": ["MMR"],
    "PHILIPPINE": ["PHL"],
    "SINGAPORE": ["SGP"],
    "THAILAND": ["THA"],
    "VIETNAM": ["VNM"],
	# Oceania #######################
    "AUSTRALI": ["AUS"],
    "NZ": ["NZL"]
}

# translator used for emissions dataset
emissions_translator = {
    # North America #################
	"USA": ["USA"],
	"CANADA": ["CAN"],
	"MEXICO": ["MEX"],
	"GUATEMALA": ["GTM"],
	"ELSALVADOR": ["SLV"],
	"HONDURAS": ["HND"],
	"COSTARICA": ["CRI"],
	"PANAMA": ["PAN"],
	"NICARAGUA": ["NIC"],
	"CUBA": ["CUB"],
	"JAMAICA": ["JAM"],
	"HAITI": ["HTI"],
	"DOMINICANR": ["DOM"],
    "MGREENLAND": ["GRL"],
    # South America #################
	"VENEZUELA": ["VEN"],
	"COLOMBIA": ["COL"],
	"ECUADOR": ["ECU"],
	"PERU": ["PER"],
	"CHILE": ["CHL"],
	"ARGENTINA": ["ARG"],
	"PARAGUAY": ["PRY"],
	"URUGUAY": ["URY"],
	"GUYANA": ["GUY"],
	"SURINAME": ["SUR"],
	"BOLIVIA": ["BOL"],
	"BRAZIL": ["BRA"],
	# Europe ########################
	"BOSNIAHERZ": ["BIH"], 
	"NORTHMACED": ["MKD"], 
	# "KOSOVO": ["XKX"], 
	"SERBIA": ["SCG"], # Serbia and Montenegro OR
	# "SERBIA": ["SRB"], # Serbia
	# "SERBIA": ["SCG"], # Montenegro
	"SWITLAND": ["CHE"], 
	"TURKEY": ["TUR"], 
	"MOLDOVA": ["MDA"], 
	"AUSTRIA": ["AUT"], 
	"BELGIUM": ["BEL"], 
	"BULGARIA": ["BGR"], 
	"CROATIA": ["HRV"], 
	"DENMARK": ["DNK"], 
	"FRANCE": ["FRA"], 
	"GERMANY": ["DEU"], 
	"GREECE": ["GRC"], 
	"HUNGARY": ["HUN"], 
	"ITALY": ["ITA"], 
	"LUXEMBOU": ["LUX"], 
	"MALTA": ["MLT"], 
	"POLAND": ["POL"], 
	"PORTUGAL": ["PRT"], 
	"ROMANIA": ["ROU"], 
	"SLOVAKIA": ["SVK"], 
	"SLOVENIA": ["SVN"], 
	"SPAIN": ["ESP"], 
	"UKRAINE": ["UKR"], 
	"ALBANIA": ["ALB"], 
	"CZECH": ["CZE"], 
	"NETHLAND": ["NLD"],
	"SWEDEN": ["SWE"], 
	"NORWAY": ["NOR"], 
	"FINLAND": ["FIN"],
	"ESTONIA": ["EST"], 
	"LATVIA": ["LVA"], 
	"LITHUANIA": ["LTU"],
	"UK": ["GBR"], 
	"IRELAND": ["IRL"],
	"ICELAND": ["ISL"],
    # Africa ########################
	"MOROCCO": ["MAR"], 
	"ALGERIA": ["DZA"], 
	"TUNISIA": ["TUN"], 
	"ANGOLA": ["AGO"],
	"BOTSWANA": ["BWA"], 
	"CONGOREP": ["COD"], 
	"ESWATINI": ["SWZ"], 
	"MOZAMBIQUE": ["MOZ"], 
	"NAMIBIA": ["NAM"],
	"SOUTHAFRIC": ["ZAF"], 
	"TANZANIA": ["TZA"], 
	"ZAMBIA": ["ZMB"], 
	"ZIMBABWE": ["ZWE"], 
	"LIBYA": ["LBY"], 
	"EGYPT": ["EGY"], 
	"SUDAN": ["SDN"],
    "UGANDA": ["UGA"],
    "KENYA": ["KEN"],
	"AFRICA": ["DZA", # Algeria
		       "AGO", # Angola
		       "BEN", # Benin
		       "BWA", # Botswana
		       "BFA", # Burkina Faso
		       "BDI", # Burundi
		       "CMR", # Cameroon
		       "CPV", # Cape Verde
		       "CAF", # Central African Republic
		       "TCD", # Chad
		       "COM", # Comoros
		       "COG", # Congo
		       "COD", # Demoratic Republic of the Congo
		       "CIV", # Cote d'Irvoire
		       "DJI", # Djibouti
		       "EGY", # Egypt
		       "GNQ", # Equatorial Guinea
		       "ERI", # Eritrea
		       "ETH", # Ethiopia
		       "GAB", # Gabon
		       "GMB", # Gambia
		       "GHA", # Ghana
		       "GIN", # Guinea
		       "GNB", # Guinea-Bissau
		       "KEN", # Kenya
		       "LSO", # Lesotho
		       "LBR", # Liberia
		       "LBY", # Libya
		       "MDG", # Madagascar
		       "MLI", # Mali
		       "MWI", # Malawi
		       "MRT", # Mauritania
		       "MUS", # Mauritius
		       # "MYT", # Mayotte
		       "MAR", # Morocco
		       "MOZ", # Mozambique
		       "NAM", # Namibia
		       "NER", # Niger
		       "NGA", # Nigeria
		       "REU", # Reunion
		       "RWA", # Rwanda
		       "STP", # Sao Tome and Principe
		       "SEN", # Senegal
		       "SYC", # Seychelles
		       "SLE", # Sierra Leone
		       "SOM", # Somalia
		       "ZAF", # South Africa
		       # "SSD", # South Sudan
		       "SDN", # Sudan
		       "SWZ", # Swaziland
		       "TZA", # Tanzania
		       "TGO", # Togo
		       "TUN", # Tunisia
		       "UGA", # Uganda
		       "ESH", # West Sahara
		       "ZMB", # Zambia
		       "ZWE"], # Zimbabwe
    # Asia ##########################
	"INDIA": ["IND"],
	"TAIPEI": ["TWN"],
	"KOREA": ["KOR"],
	"JAPAN": ["JPN"],
	"ISRAEL": ["ISR"],
	"MONGOLIA": ["MNG"],
	"PAKISTAN": ["PAK"],
	"NEPAL": ["NPL"],
	"BANGLADESH": ["BGD"],
    "SRILANKA": ["LKA"],
	"CHINAREG": ["CHN", # China proper
				 "HKG", # Hong Kong 
                 "TWN"], # Taiwan
	"CYPRUS": ["CYP"],
	"MIDEAST": ["BHR", # Bahrain
				"IRN", # Iran
				"IRQ", # Iraq
				"JOR", # Jordan
				"KWT", # Kuwait
				"LBN", # Lebanon
				"OMN", # Oman
				"QAT", # Qatar
				"SAU", # Saudi Arabia
				"SYR", # Syria
				"ARE", # United Arab Emirates
				"YEM"], # Yemen
	"MFSU15":  ["MDA", # Moldova
				"UKR", # Ukraine
				"EST", # Estonia
				"LVA", # Latvia
				"LTU", # Lithuania
				"RUS", # Russia
				"KAZ", # Kazakhstan
				"UZB", # Uzbekistan
				"TKM", # Turkmenistan
				"TJK", # Tajikistan
				"KGZ", # Kyrgyzstan
				"GEO", # Georgia
				"AZE", # Azerbaijan
				"ARM", # Armenia
				"BLR"], # Belarus
    "CAMBODIA": ["KHM"],
    "INDONESIA": ["IDN"],
    "LAO": ["LAO"],
    "MALAYSIA": ["MYS"],
    "MYANMAR": ["MMR"],
    "PHILIPPINE": ["PHL"],
    "SINGAPORE": ["SGP"],
    "THAILAND": ["THA"],
    "VIETNAM": ["VNM"],
	# Oceania #######################
    "AUSTRALI": ["AUS"],
    "NZ": ["NZL"]
}

plotting_translator = {
    # North America #################
	"USA": ["USA"],
	"CANADA": ["CAN"],
	"MEXICO": ["MEX"],
	"GUATEMALA": ["GTM"],
	"ELSALVADOR": ["SLV"],
	"HONDURAS": ["HND"],
	"COSTARICA": ["CRI"],
	"PANAMA": ["PAN"],
	"NICARAGUA": ["NIC"],
	"CUBA": ["CUB"],
	"JAMAICA": ["JAM"],
	"HAITI": ["HTI"],
	"DOMINICANR": ["DOM"],
    "MGREENLAND": ["GRL"],
    # South America #################
	"VENEZUELA": ["VEN"],
	"COLOMBIA": ["COL"],
	"ECUADOR": ["ECU"],
	"PERU": ["PER"],
	"CHILE": ["CHL"],
	"ARGENTINA": ["ARG"],
	"PARAGUAY": ["PRY"],
	"URUGUAY": ["URY"],
	"GUYANA": ["GUY"],
	"SURINAME": ["SUR"],
	"BOLIVIA": ["BOL"],
	"BRAZIL": ["BRA"],
	# Europe ########################
	"BOSNIAHERZ": ["BIH"], 
	"NORTHMACED": ["MKD"], 
	# "KOSOVO": ["XKX"], 
	"SERBIA": ["SRB"], 
	"SWITLAND": ["CHE"], 
	"TURKEY": ["TUR"], 
	"MOLDOVA": ["MDA"], 
	"AUSTRIA": ["AUT"], 
	"BELGIUM": ["BEL"], 
	"BULGARIA": ["BGR"], 
	"CROATIA": ["HRV"], 
	"DENMARK": ["DNK"], 
	"FRANCE": ["FRA"], 
	"GERMANY": ["DEU"], 
	"GREECE": ["GRC"], 
	"HUNGARY": ["HUN"], 
	"ITALY": ["ITA"], 
	"LUXEMBOU": ["LUX"], 
	"MALTA": ["MLT"], 
	"POLAND": ["POL"], 
	"PORTUGAL": ["PRT"], 
	"ROMANIA": ["ROU"], 
	"SLOVAKIA": ["SVK"], 
	"SLOVENIA": ["SVN"], 
	"SPAIN": ["ESP"], 
	"UKRAINE": ["UKR"], 
	"ALBANIA": ["ALB"], 
	"CZECH": ["CZE"], 
	"NETHLAND": ["NLD"],
	"SWEDEN": ["SWE"], 
	"NORWAY": ["NOR"], 
	"FINLAND": ["FIN"],
	"ESTONIA": ["EST"], 
	"LATVIA": ["LVA"], 
	"LITHUANIA": ["LTU"],
	"UK": ["GBR"], 
	"IRELAND": ["IRL"],
	"ICELAND": ["ISL"],
    # Africa ########################
	"MOROCCO": ["MAR"], 
	"ALGERIA": ["DZA"], 
	"TUNISIA": ["TUN"], 
	"ANGOLA": ["AGO"],
	"BOTSWANA": ["BWA"], 
	"CONGOREP": ["COD"], 
	"ESWATINI": ["SWZ"], 
	"MOZAMBIQUE": ["MOZ"], 
	"NAMIBIA": ["NAM"],
	"SOUTHAFRIC": ["ZAF"], 
	"TANZANIA": ["TZA"], 
	"ZAMBIA": ["ZMB"], 
	"ZIMBABWE": ["ZWE"], 
	"LIBYA": ["LBY"], 
	"EGYPT": ["EGY"], 
	"SUDAN": ["SDN"],
    "UGANDA": ["UGA"],
    "KENYA": ["KEN"],
	"AFRICA": ["DZA", # Algeria
		       "AGO", # Angola
		       "BEN", # Benin
		       "BWA", # Botswana
		       "BFA", # Burkina Faso
		       "BDI", # Burundi
		       "CMR", # Cameroon
		       "CPV", # Cape Verde
		       "CAF", # Central African Republic
		       "TCD", # Chad
		       "COM", # Comoros
		       "COG", # Congo
		       "COD", # Demoratic Republic of the Congo
		       "CIV", # Cote d'Irvoire
		       "DJI", # Djibouti
		       "EGY", # Egypt
		       "GNQ", # Equatorial Guinea
		       "ERI", # Eritrea
		       "ETH", # Ethiopia
		       "GAB", # Gabon
		       "GMB", # Gambia
		       "GHA", # Ghana
		       "GIN", # Guinea
		       "GNB", # Guinea-Bissau
		       "KEN", # Kenya
		       "LSO", # Lesotho
		       "LBR", # Liberia
		       "LBY", # libya
		       "MDG", # Madagascar
		       "MLI", # Mali
		       "MWI", # Malawi
		       "MRT", # Mauritania
		       "MUS", # Mauritius
		       "MYT", # Mayotte
		       "MAR", # Morocco
		       "MOZ", # Mozambique
		       "NAM", # Namibia
		       "NER", # Niger
		       "NGA", # Nigeria
		       "REU", # Reunion
		       "RWA", # Rwanda
		       "STP", # Sao Tome and Principe
		       "SEN", # Senegal
		       "SYC", # Seychelles
		       "SLE", # Sierra Leone
		       "SOM", # Somalia
		       "ZAF", # South Africa
		       "SSD", # South Sudan
		       "SDN", # Sudan
		       "SWZ", # Swaziland
		       "TZA", # Tanzania
		       "TGO", # Togo
		       "TUN", # Tunisia
		       "UGA", # Uganda
		       "ESH", # West Sahara
		       "ZMB", # Zambia
		       "ZWE"], # Zimbabwe
    # Asia ##########################
	"INDIA": ["IND"],
	"TAIPEI": ["TWN"],
	"KOREA": ["KOR"],
	"JAPAN": ["JPN"],
	"ISRAEL": ["ISR"],
	"MONGOLIA": ["MNG"],
	"PAKISTAN": ["PAK"],
	"NEPAL": ["NPL"],
	"BANGLADESH": ["BGD"],
    "SRILANKA": ["LKA"],
	"CHINAREG": ["CHN", # China proper
				 "HKG",
                 "TWN"],# Hong Kong 
    "CYPRUS": ["CYP"],
	"MIDEAST": ["BHR", # Bahrain
				"IRN", # Iran
				"IRQ", # Iraq
				"JOR", # Jordan
				"KWT", # Kuwait
				"LBN", # Lebanon
				"OMN", # Oman
				"QAT", # Qatar
				"SAU", # Saudi Arabia
				"SYR", # Syria
				"ARE", # United Arab Emirates
				"YEM"], # Yemen
	"MFSU15":  ["MDA", # Moldova
				"UKR", # Ukraine
				"EST", # Estonia
				"LVA", # Latvia
				"LTU", # Lithuania
				"RUS", # Russia
				"KAZ", # Kazakhstan
				"UZB", # Uzbekistan
				"TKM", # Turkmenistan
				"TJK", # Tajikistan
				"KGZ", # Kyrgyzstan
				"GEO", # Georgia
				"AZE", # Azerbaijan
				"ARM", # Armenia
				"BLR"], # Belarus
    "CAMBODIA": ["KHM"],
    "INDONESIA": ["IDN"],
    "LAO": ["LAO"],
    "MALAYSIA": ["MYS"],
    "MYANMAR": ["MMR"],
    "PHILIPPINE": ["PHL"],
    "SINGAPORE": ["SGP"],
    "THAILAND": ["THA"],
    "VIETNAM": ["VNM"],
	# Oceania #######################
    "AUSTRALI": ["AUS"],
    "NZ": ["NZL"]
}
