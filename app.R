library(leaflet)
library(shiny)
library(htmltools)
library(sf)
library(units)
library(dplyr)
library(ggmap)
library(leaflegend)

# geocode base location data using Google API 
# register API key permanently with: register_google(key = "[your key]", write = TRUE)
# for more information on geocoding: https://www.shanelynn.ie/massive-geocoding-with-r-and-google-maps/
#sbux <- read.csv("starbucks_locations.csv", check.names = FALSE)
#sbux_geo <- mutate_geocode(sbux, location = Address)
#write.csv(sbux_geo, "sbux.csv")
#mob <- read.csv("mobility_locations.csv", check.names = FALSE)
#mob_geo <- mutate_geocode(mob, location = Name)
#write.csv(mob_geo, "mob.csv")

sbux <- read.csv("sbux.csv", check.names = FALSE)
mob <- read.csv("mob.csv", check.names = FALSE)
vzw <- read.csv("vzw_locations.csv", check.names = FALSE)
vzw <- vzw %>% 
  mutate(location = paste0(address, ", ", city, ", ", state))

# convert points into sf object, then join with st_is_within_distance to find proximity locations
close_mob <- st_as_sf(mob, coords = c("lon", "lat"))
close_sbux <- st_as_sf(sbux, coords = c("lon", "lat"))
distance <- set_units(.1) # specify maximum distance between Mobility and Starbucks locations
combined_mob <- st_join(close_mob, close_sbux, join=st_is_within_distance, dist = distance, left=FALSE)
combined_mob_df <- distinct(combined_mob, Name, .keep_all= TRUE)
mob_df <- left_join(combined_mob_df, mob, by=c("Name" = "Name"))

close_vzw <- st_as_sf(vzw, coords = c("lon", "lat"))
combined_vzw <- st_join(close_vzw, close_sbux, join=st_is_within_distance, dist = distance, left=FALSE)
combined_vzw_df <- distinct(combined_vzw, store_name, .keep_all= TRUE)
vzw_df <- left_join(combined_vzw_df, vzw, by=c("store_name" = "store_name"))

# create icon set for legend
iconSet <- awesomeIconList(
  Starbucks = makeAwesomeIcon(
    icon = 'coffee',
    library = 'fa',
    iconColor = 'green',
    markerColor = 'green'
  ),
  ATT = makeAwesomeIcon(
    icon = 'circle',
    library = 'fa',
    iconColor = 'blue',
    markerColor = 'blue'
  ),
  VZW = makeAwesomeIcon(
    icon = 'circle',
    library = 'fa',
    iconColor = 'red',
    markerColor = 'red'
  )
)
# 

# specify coffee icon design for Sbux location markers
icons <- awesomeIcons(
  icon = 'coffee',
  iconColor = 'white',
  library = 'fa',
  markerColor = 'green')

# create popup info for Sbux locations
popup <- paste("<b>Address: </b>", 
               sbux$Address,
               "<br><b>Status: </b>", 
               sbux$Status,
               "<br><b>Date Filed: </b>", 
               sbux$"Date Filed",
               "<br><b>Tally Date: </b>", 
               sbux$"Tally Date",
               "<br><b>Ballot Type: </b>",
               sbux$"Ballot Type",
               "<br><b>Votes For Union: </b>",
               sbux$"Votes For Union",
               "<br><b>Votes Against: </b>",
               sbux$"Votes Against",
               "<br><b>Total Eligible Voters: </b>",
               sbux$"Num Eligible Voters"
               ) %>% 
  lapply(htmltools::HTML)

# create popup info for ATT locations
popup2 <- paste("<b>Name: </b>", 
                mob_df$Name,
                "<br><b>District: </b>", 
                mob_df$District.x,
                "<br><b>Local: </b>",
                mob_df$Local.x,
                "<br><b>Contract: </b>",
                mob_df$Contract.x,
                "<br><b># of Workers: </b>",
                mob_df$Workers.x) %>% 
  lapply(htmltools::HTML)

# create popup info for VZW locations
popup3 <- paste("<b>Name: </b>", 
                vzw_df$store_name,
                "<br><b>Address: </b>", 
                vzw_df$location.x
                #,
                #"<br><b>Website: </b>",
                #'<a href="', vzw_df$website_address.x, '">Link</a>'
                ) %>% 
  lapply(htmltools::HTML)

# design overall dashboard user interface
ui <- fluidPage(
  HTML("<h3>CWA Wireless + Starbucks Union Locations</h3>"),
  mainPanel(
    leafletOutput("mymap", width="100%", height=1000)
  ))

# create Shiny dashboard server
server <- function(input, output, session) {
  
  fillPage(
    tags$style(type = "text/css",
               ".half-fill { width: 50%; height: 100%; }",
               "#one { float: left; background-color: #ddddff; }",
               "#two { float: right; background-color: #ccffcc; }"
    ),
    div(id = "one", class = "half-fill",
        "Left half"
    ),
    div(id = "two", class = "half-fill",
        "Right half"
    ),
    padding = 10
  )
  
  output$mymap <- renderLeaflet({
    leaflet() %>%
      setView(-104.96, 39.71, 4) %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      addLayersControl(
        overlayGroups = c("Starbucks", "AT&T", "VZW"),
        options = layersControlOptions(collapsed = FALSE)
      ) %>%
      addLegendAwesomeIcon(iconSet = iconSet, # uses the icon set we designated earlier
                           orientation = 'vertical',
                           marker = FALSE,
                           title = htmltools::tags$div(
                             style = 'font-size: 18px;',
                             'Legend'),
                           labelStyle = 'font-size: 16px;',
                           position = 'topright',
                           group = 'Legend')
  })
  
  # add markers for locations
  observe({    
    leafletProxy("mymap", data=mob_df) %>%
      addCircleMarkers(~lon, ~lat, popup = popup2, group = "AT&T", color = 'blue', fillColor = 'blue', opacity = 0.5, radius = 5, fillOpacity = 0.5)
  })
  
  observe({    
    leafletProxy("mymap", data=vzw_df) %>%
      addCircleMarkers(~lon, ~lat, popup = popup3, group = "VZW", color = 'red', fillColor = 'red', opacity = 0.5, radius = 5, fillOpacity = 0.5)
  })
  
  observe({    
    leafletProxy("mymap", data=sbux) %>%
      addAwesomeMarkers(~lon, ~lat, popup = popup, icon = icons, group = "Starbucks")
  })
  
  
}

# run your app!
shinyApp(ui, server)
