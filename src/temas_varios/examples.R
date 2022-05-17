require("data.table")
require(parallel)
install.packages("readODS")
require("readODS")

cores <- detectCores()
cores


setwd("/Users/manuelvargas/Documents/ITBA-Maestria- Especialización en Ciencia de Datos/clases/Mineria de Datos/DATOS")   #Establezco el Working Directory
#cargo los datos
dataset  <- read_ods("./datasets/DiccionarioDatos.ods")

str(dataset)
colnames(dataset)         #[1] "#"           "campo"       "unidad"      "Significado"
str(dataset$Significado)
head(dataset)
