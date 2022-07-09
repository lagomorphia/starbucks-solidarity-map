# starbucks-solidarity-map

![image](https://user-images.githubusercontent.com/53026628/178120026-991be686-6979-43b5-a4a2-2ca75b1606b4.png)

Map to visualize proximity of CWA union members (AT&T Mobility) to unionizing Starbucks locations for the purpose of solidarity mobilizing. Demo map is available at https://lodgepolepines.shinyapps.io/starbucks-solidarity-map/

Uses R packages `sf` to calculate proximity, `shiny` and `leaflet` for mapping, and `rsconnect` to deploy to **shinyapps**. For purposes of demo all CWA data is fake.

More information available here: [link](https://docs.google.com/presentation/d/1FN4ok-iPdDFvUFGlbDQari5CbZ15lxX_p4kvZ0sVY-w/edit#slide=id.ge9090756a_1_58)

## To use:

Clone this repository, install the necessary R packages such as `shiny`, `leaflet`, and `sf`, replace the repo csv location data with your own data, and run app.R. To deploy to **shinyapps** follow [these instructions](https://shiny.rstudio.com/articles/shinyapps.html). For more information on geocoding data with the Google Maps Geocoding API, [see here](https://www.shanelynn.ie/massive-geocoding-with-r-and-google-maps/).
