# shiny R code for lexique.org
# Time-stamp: <2019-11-23 10:33:15 christophe@pallier.org>

library(shiny)
library(DT)
library(writexl)

source("https://raw.githubusercontent.com/chrplr/openlexicon/master/datasets-info/fetch_datasets.R")
lexique <- get_lexique383_rds()

helper_alert =
    tags$div(class="alert alert-info",

             tags$p(tags$img(src="bouton_aide.png"),
                    "Watch an ",
                    tags$a(class="alert-link",
                           href="http://www.lexique.org/_media/aide-interface-lexique3.mp4",
                           "intro video"),
                    "or access ",
                    tags$a(class="alert-link",
                           href="http://www.lexique.org/?page_id=166",
                           "documentation.")
                    )
             )

                                        #   tags$hr(""),
    #   tags$p("Crash course:"),
    #   tags$ul(
    #     tags$li("Select desired columns on the sidebar on the left"),
    #     tags$li("For each column you can:"),
    #     tags$ul(
    #       tags$li("sort (ascending or descending)"),
    #       tags$li("Filter using ", tags$a(href="http://regextutorials.com/index.html", "regexes"), ".")
    #     ),
    #     tags$li("Download the result of your manipulations")
    # )
    #)

ui <- fluidPage(
    title = "Lexique",
    sidebarLayout(
        sidebarPanel(
            checkboxGroupInput("show_vars", "Columns to display",
                               names(lexique),
                               selected = c('ortho', 'nblettres', 'cgramortho', 'islem',
                                            'cgram', 'nblettres', 'nbsyll','lemme',
                                            'freqlemfilms2', 'freqfilms2', 'phon')
                               ),
            width=2
        ),
        mainPanel(
            helper_alert,  
            # uiOutput("help"),

            h3(textOutput("caption", container = span)),
            fluidRow(DTOutput(outputId="table")),
            downloadButton(outputId='download', label="Download filtered data")
        )
    )
)


server <- function(input, output) {
    datasetInput <- reactive({lexique})

    output$caption <- renderText({
        "Lexique3"
    })

    output$table <- renderDT(datasetInput()[,input$show_vars, drop=FALSE],
                             server=TRUE, escape = TRUE, selection = 'none',
                             filter=list(position = 'top', clear = FALSE),
                             rownames= FALSE,
                             options=list(pageLength=25,
                                          sDom  = '<"top">lrt<"bottom">ip',
                                          lengthMenu = c(10, 25, 100, 500, 1000),
                                          search=list(searching = TRUE,
                                                      regex=TRUE,
                                                      caseInsensitive = FALSE)
                                          )
                             )

    output$download <- downloadHandler(
        filename = function() {
            paste("Lexique-query-", Sys.time(), ".xlsx", sep="")
        },
        content = function(fname){
            dt = datasetInput()[input[["table_rows_all"]], ]
            write_xlsx(dt, fname)
        })

    url  <- a("Aide", href="http://www.lexique.org/?page_id=166")
    # output$help = renderUI({ tagList(tags$h4("Aide pour les recherches :", url)) })
    output$help = renderUI({ tagList(tags$a(tags$img(src="bouton_aide.png"), href="http://www.lexique.org/?page_id=166") )
      })
}


shinyApp(ui, server)
