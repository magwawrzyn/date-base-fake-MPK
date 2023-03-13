##install.packages("RPostgreSQL")
library("RPostgreSQL")

drv <- dbDriver("PostgreSQL")

pw <- {"haslo"}

con <- dbConnect(drv, dbname = "projekt-MPK", host = "localhost", port = 5432, 
                 user = "postgres", password = pw)
rm(pw)


##konczenia pracy z baza danych:
# dbDisconnect(con)
# dbUnloadDriver(drv)