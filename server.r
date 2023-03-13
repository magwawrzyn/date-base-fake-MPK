source("connect.R")
library("DT")
server <- function(input, output){
  observeEvent(input$DODAJPRACID,{
     dodajpr <- paste0("SELECT * FROM zatrudnij_kierowce('",
                       input$ImieID,"','",input$NazwiskoID,"','",input$PESELID,"');")
     dbSendQuery(con, dodajpr)
    })

  observeEvent(input$ZWOLNIJID,{
    dodajpr <- paste0("SELECT * FROM zwolnij_kierowce('",
                      input$zwalnianyID,"');")
    dbSendQuery(con, dodajpr)
  })
  
  output$tpracowID <- DT::renderDataTable({
    dbGetQuery(con, "SELECT * FROM kierowcy;")
  })
  
  observeEvent(input$refreshDT,{
    output$tpracowID <- DT::renderDataTable({
      dbGetQuery(con, "SELECT * FROM kierowcy;")
    })
  })  
#------------------------------------------------------
  observeEvent(input$ZMIENPPID,{
    pp <- paste0("SELECT * FROM zmien_prog(",
                      input$IDK,",",input$progID,");")
    dbSendQuery(con, pp)
  })
  output$progiID <- DT::renderDataTable({
    dbGetQuery(con, "SELECT * FROM kierowcy;")
  
  })
  observeEvent(input$refreshDTw,{
    output$progiID <- DT::renderDataTable({
      dbGetQuery(con, "SELECT * FROM kierowcy;")
    })
  })
#----------------------------------------------------------------
  output$zarobkiID <- DT::renderDataTable({
    dbGetQuery(con, "SELECT * FROM miesieczne_wynagrodzenia;")
  })
  observeEvent(input$refreshDTwid,{
    output$zarobkiID <- DT::renderDataTable({
      dbGetQuery(con, "SELECT * FROM miesieczne_wynagrodzenia;")
    })
  })
#-----------------------------------------------
  observeEvent(input$dodajPojID,{
    poj <- paste0("SELECT * FROM 	dodaj_pojazd(",
                 input$nrpojID,",'",input$markaID,"');")
    dbSendQuery(con, poj)
  })
  output$PojazdyID <- DT::renderDataTable({
    dbGetQuery(con, "SELECT * FROM Pojazdy;")
    
  })
  observeEvent(input$refreshDTp,{
    output$PojazdyID <- DT::renderDataTable({
      dbGetQuery(con, "SELECT * FROM Pojazdy;")
    })
  })
# #-------------------------------------------------------
   observeEvent(input$skasujPojID,{
     poj2 <- paste0("SELECT * FROM 	skasuj_pojazd(",
                   input$nrpojID2,");")
     dbSendQuery(con, poj2)
   })
   output$PojazdyID2 <- DT::renderDataTable({
     dbGetQuery(con, "SELECT * FROM Pojazdy;")
     
   })
   observeEvent(input$refreshDTkas,{
     output$PojazdyID2 <- DT::renderDataTable({
       dbGetQuery(con, "SELECT * FROM Pojazdy;")
     })
   })
#   -----------------------------------------------------------
   output$mcpID <- DT::renderDataTable({
     dbGetQuery(con, "SELECT * FROM miesieczny_czas_pracy;")
   })
   observeEvent(input$refreshDTmcp,{
     output$mcpID <- DT::renderDataTable({
       dbGetQuery(con, "SELECT * FROM miesieczny_czas_pracy;")
     })
   })
#---------------------------------------------------
   observeEvent(input$dodajsluzID,{
     sluz <- paste0("SELECT * FROM 	dodaj_sluzbe(",
                   input$nrbrygadID,",",input$kieID,",",input$wozID,",'",input$dataID,"');")
     dbSendQuery(con, sluz)
   })
   output$sluzbaID <- DT::renderDataTable({
     dbGetQuery(con, "SELECT * FROM  Wykaz_sluzb;")
     
   })
   observeEvent(input$refreshDTsluz,{
     output$sluzbaID <- DT::renderDataTable({
       dbGetQuery(con, "SELECT * FROM  Wykaz_sluzb;")
     })
   })
#---------------------------------------------------------------  
   observeEvent(input$zmiensluzID,{
     zsluz <- paste0("SELECT * FROM 	zmien_sluzbe(",
                     input$skieID,",'",input$sdataID,"',",input$nnrbrygadID,",",input$nwozID,");")
     dbSendQuery(con, zsluz)
   })
   output$zsluzbaID <- DT::renderDataTable({
     dbGetQuery(con, "SELECT * FROM  Wykaz_sluzb;")
     
   })
   observeEvent(input$refreshDTzsluz,{
     output$zsluzbaID <- DT::renderDataTable({
       dbGetQuery(con, "SELECT * FROM  Wykaz_sluzb;")
     })
   })
}