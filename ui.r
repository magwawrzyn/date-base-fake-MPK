ui <- fluidPage(
  tabsetPanel(
    tabPanel("B - zatrudnij i zwolnij", 
             column(5,textInput(inputId = "ImieID", label = "Podaj imie nowego pracownika"),
                    textInput(inputId = "NazwiskoID", label = "Podaj nazwisko nowego pracownika"),
                    textInput(inputId = "PESELID", label = "Podaj PESEL nowego pracownika"),
                    actionButton(inputId = "DODAJPRACID", label = "Zatrudnij")),
             column(4,numericInput(inputId = "zwalnianyID",label = "Podaj ID zwalnianego pracownika", value = 1),
                    actionButton(inputId = "ZWOLNIJID", label = "Zwolnij")),
             column(3,actionButton(inputId = "refreshDT", label = "Odswiez")),
             DT::dataTableOutput(outputId = "tpracowID")
    ),
    tabPanel("B - zmien prog placowy",
             numericInput(inputId = "IDK",label = "Podaj ID kierowcy, ktorego prog placowy jest do zmiany", value = 1),
             selectInput(inputId = "progID",label = "Podaj nowy prog", choice =c(1,2,3,4)),
             actionButton(inputId = "ZMIENPPID", label = "Zmien"),
             actionButton(inputId = "refreshDTw", label = "Odswiez"),
             DT::dataTableOutput(outputId = "progiID")
    ),
    tabPanel("B - zarobki",
             actionButton(inputId = "refreshDTwid", label = "Odswiez"),
             DT::dataTableOutput(outputId = "zarobkiID")
    ),
    
    tabPanel("B - dodaj nowy pojazd",
             numericInput(inputId = "nrpojID",label = "Podaj nr dodawanego pojazdu", value = 7001),
             textInput(inputId = "markaID", label = "Podaj marke dodawanego pojazdu"),
             actionButton(inputId = "dodajPojID", label = "Dodaj"),
             actionButton(inputId = "refreshDTp", label = "Odswiez"),
             DT::dataTableOutput(outputId = "PojazdyID")
             
    ),
     tabPanel("B - skasuj pojazd",
              numericInput(inputId = "nrpojID2",label = "Podaj nr pojazdu do kasacji", value = 7001),
              actionButton(inputId = "skasujPojID", label = "Skasuj"),
              actionButton(inputId = "refreshDTkas", label = "Odswiez"),
              DT::dataTableOutput(outputId = "PojazdyID2")
     ),
    tabPanel("D - miesieczny czas pracy",
             actionButton(inputId = "refreshDTmcp", label = "Odswiez"),
             DT::dataTableOutput(outputId = "mcpID")
    ),
    tabPanel("D - dodaj sluzbe",
             numericInput(inputId = "nrbrygadID",label = "Podaj nr brygady", value = 10601),
             numericInput(inputId = "kieID",label = "Podaj ID kierowcy", value = 1),
             numericInput(inputId = "wozID", label = "Podaj nr pojazdu", value = 7001),
             dateInput(inputId = "dataID", label = "Podaj dzien sluzby", value = "2020-01-16"),
             actionButton(inputId = "dodajsluzID", label = "Dodaj"),
             actionButton(inputId = "refreshDTsluz", label = "Odswiez"),
             DT::dataTableOutput(outputId = "sluzbaID")
    ),
    tabPanel("D - zmien sluzbe",
             numericInput(inputId = "nnrbrygadID",label = "Podaj nr nowej brygady", value = 10601),
             numericInput(inputId = "skieID",label = "Podaj ID kierowcy", value = 1),
             numericInput(inputId = "nwozID", label = "Podaj nr nowego pojazdu", value = 7001),
             dateInput(inputId = "sdataID", label = "Podaj dzien sluzby", value = "2020-01-16"),
             actionButton(inputId = "zmiensluzID", label = "Zmien"),
             actionButton(inputId = "refreshDTzsluz", label = "Odswiez"),
             DT::dataTableOutput(outputId = "zsluzbaID")
             
    )
  )
)