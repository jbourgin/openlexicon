# shiny R code for generate pseudowords <www.lexique.org>
# Authors: Boris New, C. Pallier & J. Bourgin
# Time-stamp: <2020-10-21 17:08:14 jessica.bourgin@univ-smb.fr>

#### Functions ####
rm(list = ls())
source('www/functions/loadPackages.R')
source('www/functions/qTips.R')

# Loading datasets and UI
source('../../datasets-info/fetch_datasets.R')
source('www/data/loadingDatasets.R')

source('www/data/uiElements.R')

#### Script begins ####
ui <- fluidPage(
    # Qtips
    tags$link(rel = "stylesheet", type = "text/css", href = "functions/jquery.qtip.css"),
    tags$script(type = "text/javascript", src = "functions/jquery.qtip.js"),

  useShinyjs(),
  useShinyalert(),

  titlePanel(tags$a(href="http://chrplr.github.io/openlexicon/", "Infra")),
  title = "Infra",

  sidebarLayout(
    sidebarPanel(
      uiOutput("helper_alert"),
      br(),
      helper_alert,
      br(),
      div(textAreaInput("mots",
                  label = tags$b(paste_words),
                  rows = 10, resize = "none")),
      div(style="text-align:center;",actionButton("go", go_btn)),
      width=4
    ),
  mainPanel(
      fluidRow(tags$style(HTML("
                      thead:first-child > tr:first-child > th {
                          border-top: 0;
                          font-size: normal;
                          font-weight: bold;
                      }
                  ")),
                 br(),
                 DTOutput(outputId="infra") %>% withSpinner(type=3,
                            color.background="#ffffff",
                            hide.element.when.recalculating = FALSE,
                            proxy.height = 0),
        uiOutput("outdownload"),
        br(),
        htmlOutput("notokpseudowords")
      ))
    )
)

server <- function(input, output, session) {
  v <- reactiveValues(
    button_helperalert = btn_hide_helper,
    notokpseudowords = c())

    #### Toggle helper_alert ####

    output$helper_alert <- renderUI({
      actionButton("btn", v$button_helperalert)
    })

    observeEvent(input$btn, {
      shinyjs::toggle("helper_box", anim = TRUE, animType = "slide")

      if (v$button_helperalert == btn_show_helper){
        v$button_helperalert = btn_hide_helper
      }else{
        v$button_helperalert = btn_show_helper
      }
    })

    #### Generate word list ####

    words_list <- eventReactive(input$go,
    {
        words <- strsplit(input$mots,"[ \n\t]")[[1]]
        wordsok <- unique(words[!grepl("[[:punct:][:space:]]", words)]) # remove words with punctuation or space, and duplicates
        })

    #### Table ####

    retable <- reactive({
        words_list <- words_list()
        if (!is.null(words_list)){
            notokpseudowords <- c()
            types_list <- c("let", "bigr", "trigr")
            subtypes_list <- c("Ty", "To")
            final_dt <- data.frame()
            # Get whole databases
            dt_info <- list()
            dt_info[[types_list[[1]]]] <- dictionary_databases[['Lexique-Infra-lettres']][['dstable']]
            dt_info[[types_list[[2]]]] <- dictionary_databases[['Lexique-Infra-bigrammes']][['dstable']]
            dt_info[[types_list[[3]]]] <- dictionary_databases[['Lexique-Infra-trigrammes']][['dstable']]
            whole_dt <- dictionary_databases[['Lexique-Infra-word_frequency']][['dstable']]
            # Add TypItem column in second position
            whole_dt[[type_column]] <- NA
            whole_dt<-whole_dt[,c(1,ncol(whole_dt), 3:ncol(whole_dt)-1)]

            # Get words
            for (word in words_list){
                word <- tolower(word)
                # If elt is word, we get it in the word_frequency dt
                if (is.element(word,unlist(whole_dt[[join_column]]))){
                    new_line <- subset(whole_dt, Word == word)
                    new_line[[type_column]] <- "Word"
                    is_word <- TRUE
                # else we calculate its values
                }else{
                    is_word <- FALSE
                    ok_pseudoword <- TRUE
                    dic_info <- list()
                    # Dic values
                    for (type in types_list){
                        dic_info[[type]] <- list()
                        for (subtype in subtypes_list){
                            dic_info[[type]][[subtype]] <- list()
                            dic_info[[type]][[subtype]][["sum"]] <- 0.0
                            dic_info[[type]][[subtype]][["decomp"]] <- ""
                        }
                    }

                    count <- 0
                    for (type in types_list){
                        # While the pseudoword is ok (we find info for it)
                        if (ok_pseudoword == TRUE){
                            for (num_elt in 1:(nchar(word) -count)){
                                current_line <- subset(dt_info[[type]], Word == substring(word, num_elt, num_elt+count))
                                # If part of the pseudoword is not found in the table, we decide it's not a valid pseudoword
                                if (NROW(current_line) == 0){
                                    ok_pseudoword <- FALSE
                                }
                                # Initial, middle or final position
                                if (num_elt == 1){
                                    spec = "I"
                                    separator = ""
                                }else if(num_elt==(nchar(word)-count)){
                                    spec="F"
                                    separator = "-"
                                }else{
                                    spec="M"
                                    separator = "-"
                                }
                                # Get info in dictionary
                                for (subtype in subtypes_list){
                                    dic_info[[type]][[subtype]][["sum"]] <- dic_info[[type]][[subtype]][["sum"]] + as.double(current_line[[paste(type,subtype,spec,sep="")]])

                                    dic_info[[type]][[subtype]][["decomp"]] <- paste(dic_info[[type]][[subtype]][["decomp"]], as.character(current_line[[paste(type,subtype,spec,sep="")]]), sep=separator)
                                }
                            }
                        }
                        count = count+1
                    }
                    # Line creation
                    if (ok_pseudoword == TRUE){
                        new_line <- data.frame()
                        new_line[1,1] <- word
                        new_line[1,2] <- "Pseudoword"
                        for (i in 3:6){
                            new_line[1,i] <- ""
                        }
                        count <- 0
                        count_col <- 7
                        for (type in types_list){
                            for (subtype in subtypes_list){
                                new_line[1,count_col] <- dic_info[[type]][[subtype]][["decomp"]]
                                new_line[1,count_col+1] <-dic_info[[type]][[subtype]][["sum"]]/(nchar(word)-count)
                                count_col <- count_col +2
                            }
                            count <- count +1
                        }
                        for (i in 19:34){
                            new_line[1,i] <- ""
                        }
                        colnames(new_line) <- colnames(whole_dt)
                    }
                }
                # If the item is ok, we add it in the table
                if (is_word == TRUE || ok_pseudoword == TRUE){
                    final_dt <- rbind(final_dt, new_line)
                }
                # Else we show it in the text output
                else if (ok_pseudoword == FALSE){
                    notokpseudowords <- append(notokpseudowords, word)
                }
            }

            # Rename word column
            if (nrow(final_dt) > 0){
                colnames(final_dt)[colnames(final_dt) == join_column] <- "Item"
            }

            # Update not ok items list
            v$notokpseudowords <- notokpseudowords

            # return datatable
            final_dt
        }
        })

    output$infra = renderDT({
        if (!is.null(words_list()) & nrow(retable() > 0)){
            retable()

            # for tooltips
            headerCallback <- c(
              "function(thead, data, start, end, display){",
              qTips(dictionary_databases[['Lexique-Infra-word_frequency']][['colnames_dataset']]),
              "  for(var i = 1; i <= tooltips.length; i++){",
              "if(tooltips[i-1]['content']['text'].length > 0){",
              "      $('th:eq('+i+')',thead).qtip(tooltips[i-1]);",
              "    }",
              "  }",
              "}"
            )

            datatable(retable(),
                      escape = FALSE, selection = 'none',
                      filter=list(position = 'top', clear = FALSE),
                      rownames= FALSE, #extensions = 'Buttons',
                      width = 200,
                      options=list(headerCallback = JS(headerCallback),
                                   pageLength=20,
                                   columnDefs = list(list(className = 'dt-center', targets = "_all")),
                                   sDom  = '<"top">lrt<"bottom">ip',

                                   lengthMenu = c(20,100, 500, 1000),
                                   search=list(searching = TRUE,
                                               regex=TRUE,
                                               caseInsensitive = FALSE)
                       ))}
    }, server = TRUE)

    #### Render not ok pseudowords ####

    output$notokpseudowords <- renderUI({
        if (length(v$notokpseudowords) > 0){
            # final_list <- tags$ul(paste(v$notokpseudowords, collapse = ', '))
            tags$div(id = "notok",
                     class="alert alert-danger",
                     tags$p("Sorry, we did not find information for the following pseudowords:"),
                     tags$br(),
                     tags$ul(tagList(
                         lapply(seq_along(v$notokpseudowords), function(s) {
                            tags$li(v$notokpseudowords[s])
                          })
                     )
                      )
        )}
    })

    #### Download options ####

    output$outdownload <- renderUI({
        if (!is.null(words_list()) & nrow(retable() > 0)){
            downloadButton('download.xlsx', label="Download infra query")
        }
    })

    output$download.xlsx <- downloadHandler(
      filename = function() {
        paste("Infra-query-",
              format(Sys.time(), "%Y-%m-%d"), ' ',
              paste(hour(Sys.time()), minute(Sys.time()), second(Sys.time()), sep = "-"),
              ".xlsx", sep="")
      },
      content = function(fname) {
        dt = retable()[input[["infra_rows_all"]], ]
        write_xlsx(dt, fname)
      })
}

shinyApp(ui, server)
