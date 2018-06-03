#' Shiny App for editing the metadata biblio table
#'
#' @param filepath the filepath to the dataspice biblio.csv file. Defaults to current
#'   <project_root>/data/metadata/biblio.csv.
#'
#' @import shiny
#' @import rhandsontable
#' @import ggplot2
#' @export
#'
#' @examples
#' \dontrun{
#' editTable()
#'
#'}

edit_biblio <- function(filepath = here::here("data", "metadata", "biblio.csv")){
  ui <- shinyUI(fluidPage(

    titlePanel("Populate the Biblio Metadata Table"),
    helpText("Shiny app to read in the", code("dataspice"), "metadata templates and populate with user supplied metadata"),

    sidebarLayout(
      sidebarPanel(
        wellPanel(
          h3("Save table"),
          div(class='row',
              div(class="col-sm-6",
                  actionButton("save", "Save Changes"))
          )
        ),
        h4("Bibliographic metadata"),
        h6('title = text: Title of the dataset(s) described.'),
        h6("description = text: Description of the dataset(s) described"),
        h6('datePublished = text: The date published in ISO 8601 format (YYYY-MM-DD)'),
        h6("citation = text: citation for the dataset(s) described"),
        h6("keywords = text: keywords, separated by commas, associated with the dataset(s) described"),
        h6("license = text: license under which data are published"),
        h6("funder = text: Name of funders associated with the work through which data where generated"),

        br(),
        h4("Spatial Coverage metadata"),
        h6('geographicDescription = text: Description of the area of study'),
        h6("northBoundCoord = numeric or text: southern latitudinal boundary of the data coverage area. For example 37.42242 (WGS 84)"),
        h6("eastBoundCoord = numeric or text: eastern longitudinal boundary of the data coverage area. For example -122.08585 (WGS 84)"),
        h6("southBoundCoord = numeric or text: northern latitudinal boundary of the data coverage area."),
        h6("westBoundCoord = numeric or text: western longitudinal boundary of the data coverage area."),
        helpText("To provide a single point to describe the spatial aspect of the dataset, provide the same coordinates for east-west and north-south boundary definition"),
        br(),
        h4("Temporal Coverage metadata"),
        h6("wktString = text: ??"),
        h6('startDate = text: The start date of the data temporal coverage in ISO 8601 format (YYYY-MM-DD)'),
        h6("endDate = text: The end date of the data temporal coverage in ISO 8601 format (YYYY-MM-DD)"),

        plotOutput("bbmap")

      ),

      mainPanel(
        wellPanel(
          uiOutput("message", inline=TRUE)
        ),
        rHandsontableOutput("hot"),
        br()

      )
    )
  ))

  server <- shinyServer(function(input, output) {

    values <- reactiveValues()

    dat <- readr::read_csv(file = filepath,
                    col_types = "ccccccccccccccc")
    output$hot <- rhandsontable::renderRHandsontable({
      rows_to_add <- as.data.frame(matrix(nrow=1,
                                          ncol=ncol(dat)))

      colnames(rows_to_add) <- colnames(dat)
      DF <- dplyr::bind_rows(dat, rows_to_add)

      rhandsontable::rhandsontable(DF,
                    useTypes = TRUE,
                    stretchH = "all")
    })

    ## Save
    observeEvent(input$save, {
      finalDF <- hot_to_r(input$hot)
      readr::write_csv(finalDF, path = filepath)
    })


    ## bounding box map

    output$bbmap <- renderPlot({
      world <- ggplot2::map_data("world")
      ggplot2::ggplot() +
        ggplot2::geom_map(data=world, map=world,
                          aes(x=long, y=lat, map_id=region),
                          color="black",fill="#7f7f7f")
    })


    ## Message
    output$message <- renderUI({
      if(input$save==0){
        helpText(sprintf("This table will be saved at path \'%s\' once you press the Save button.", filepath))
      }else{
        outfile <- "biblio.csv"
        fun <- 'readr::read_csv'
        list(helpText(sprintf("File saved at path: \'%s\'.",
                              filepath)),
             helpText(sprintf("Use %s(\'%s\') to read it.",
                              fun, filepath)))
      }
    })

  })

  ## run app
  runApp(list(ui=ui, server=server))
  return(invisible())
}