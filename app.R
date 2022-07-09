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
#sbux <- sbux %>% 
#mutate(location = paste0(Address, ", ", City, ", ", State))
#sbux_geo <- mutate_geocode(sbux, location = location)
#write.csv(sbux_geo, "sbux.csv")
#mob <- read.csv("mobility_locations.csv", check.names = FALSE)
#mob_geo <- mutate_geocode(mob, location = Name)
#write.csv(mob_geo, "mob.csv")

sbux <- read.csv("sbux.csv", check.names = FALSE)
mob <- read.csv("mob.csv", check.names = FALSE)

# convert points into sf object, then join with st_is_within_distance to find proximity locations
close_mob <- st_as_sf(mob, coords = c("lon", "lat"))
close_sbux <- st_as_sf(sbux, coords = c("lon", "lat"))
distance <- set_units(.1) # specify maximum distance between Mobility and Starbucks locations
combined<- st_join(close_mob, close_sbux, join=st_is_within_distance, dist = distance, left=FALSE)
df <- distinct(combined, Name, .keep_all= TRUE)
mob_df <- left_join(df, mob, by=c("Name" = "Name"))

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
  )
)
# 

# specify coffee icon design for Sbux locations
icons <- awesomeIcons(
  icon = 'coffee',
  iconColor = 'white',
  library = 'fa',
  markerColor = 'green')

# create popup info for AT&T locations
popup <- paste("<b>Title: </b>", 
               sbux$Title,
               "<br><b>Address: </b>", 
               sbux$Address,
               "<br><b>City: </b>", 
               sbux$City,
               "<br><b>State: </b>", 
               sbux$State,
               "<br><b>Status: </b>", 
               sbux$Status) %>% 
  lapply(htmltools::HTML)

# create popup info for Sbux locations
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

# design overall dashboard user interface
ui <- fluidPage(
  HTML("<h3>CWA AT&T Mobility Locations + Starbucks Union Locations</h3>"),
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
        overlayGroups = c("Starbucks", "AT&T"),
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
    leafletProxy("mymap", data=sbux) %>%
      addAwesomeMarkers(~lon, ~lat, popup = popup, icon = icons, group = "Starbucks")
  })
  
  
}

# run your app!
shinyApp(ui, server)
