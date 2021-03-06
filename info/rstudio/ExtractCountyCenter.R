# package installment
for (package in c('sf','readr','tidyverse')) {
  if (!require(package,character.only = TRUE)) {
    install.packages(package)
    library(package)
  }
}
# working directory, make sure it is in accordance with the actual directory where data is located in your local machine
setwd("/Users/eloncha/Documents/GitHub/community/info/rstudio")
# read state abbreviation csv (for future table join)
abbr = read_csv('data/stats.csv')
colnames(abbr)[2] = 'ABBR'

# read shp
county = st_read('data/tl_2019_us_county/tl_2019_us_county.shp') # all counties in the US  

# compute geometry (area)
county_area = st_area(county) 
units(county_area) = 'mi2'

# add population attributes
totalpop = read_csv('data/county-totalpop.csv')
totalpop = totalpop %>% 
  separate(.,col = 'GEO_ID', into = c('suffix','GEOID'), sep = 'US') %>%
  separate(.,col = 'NAME', into = c('NAME','STATE'), sep = ',') %>%
  select(2,5)
            
# final table
county_attr = st_drop_geometry(county) # attribute only
county_attr = county_attr %>% 
  mutate(longitude = as.numeric(as.character(INTPTLON)), latitude = as.numeric(as.character(INTPTLAT)), FIPS = as.numeric(as.character(STATEFP))) %>% 
  select(1:2,4:6,18:20) %>% 
  left_join(.,abbr, by = 'FIPS') %>% 
  select(1:4,6:7, 9:10) %>% 
  mutate(sq_miles = county_area) %>% 
  left_join(., totalpop, by = 'GEOID') %>%
  na.omit()# data cleaning

stateList = unique(county_attr$`ABBR`) # get state name list 

setwd("/Users/eloncha/Documents/GitHub/community/info/rstudio/output")
for (s in stateList) {
  state_table = county_attr %>% filter(ABBR == s)
  fileName = paste0(s, 'counties.csv')
  dir.create(s)
  pathName = paste0(s,paste0('/',fileName))
  write_csv(state_table,path = pathName)
} # write table for each state

#### zcta, to be updated, do not run
#### zcta, to be updated, do not run
zcta = st_read('data/tl_2016_us_zcta510/tl_2016_us_zcta510.shp')
zcta2 = st_drop_geometry(zcta)
zcta_text = read_csv('data/zcta_crosswalk') %>% filter(STATE ==13)

GAzcta = left_join(zcta_text,zcta2, by = c('ZCTA5' = 'GEOID10')) %>% 
  mutate(lat = as.numeric(as.character(INTPTLAT10)), lon = as.numeric(as.character(INTPTLON10))) %>%
  left_join(., county_text, by = c('COUNTY' = 'COUNTYFP10'))
write.csv(GAzcta,'GApostalcodes.csv')
#### zcta, to be updated, do not run
#### zcta, to be updated, do not run


#### topoJSON
countyTOPO = topojson_read('counties-10m.json') #TopoJSON to sf, compatible to Leaflet
countytopo = rgdal::readOGR('counties-10m.json') # TopoJSON to LSPD, compatible to Leaflet

# take a look
library(leaflet)
leaflet(countyTOPO) %>%
  addTiles() %>%
  addPolygons(stroke = 0.3)


