#esqueleto de grid search
#se espera que los alumnos completen lo que falta para recorrer TODOS cuatro los hiperparametros 

rm( list=ls() )  #Borro todos los objetos
gc()   #Garbage Collection

require("data.table")
require("rpart")
require("parallel")
#100169,100183,100189,100193,100207,100213
#ksemillas  <- c(102191,200177,410551,552581,892237) #reemplazar por las propias semillas
ksemillas  <-  c(100183,100189,100193,100207,100169)
#------------------------------------------------------------------------------
#particionar agrega una columna llamada fold a un dataset que consiste en una particion estratificada segun agrupa
# particionar( data=dataset, division=c(70,30), agrupa=clase_ternaria, seed=semilla)   crea una particion 70, 30 

particionar  <- function( data,  division, agrupa="",  campo="fold", start=1, seed=NA )
{
  if( !is.na(seed) )   set.seed( seed )

  bloque  <- unlist( mapply(  function(x,y) { rep( y, x )} ,   division,  seq( from=start, length.out=length(division) )  ) )  

  data[ , (campo) :=  sample( rep( bloque, ceiling(.N/length(bloque))) )[1:.N],
          by= agrupa ]
}
#------------------------------------------------------------------------------

ArbolEstimarGanancia  <- function( semilla, param_basicos )
{
  #particiono estratificadamente el dataset
  particionar( dataset, division=c(70,30), agrupa="clase_ternaria", seed= semilla )  #Cambiar por la primer semilla de cada uno !

  #genero el modelo
  modelo  <- rpart("clase_ternaria ~ .",     #quiero predecir clase_ternaria a partir del resto
                   data= dataset[ fold==1],  #fold==1  es training,  el 70% de los datos
                   xval= 0,
                   control= param_basicos )  #aqui van los parametros del arbol

  #aplico el modelo a los datos de testing
  prediccion  <- predict( modelo,   #el modelo que genere recien
                          dataset[ fold==2],  #fold==2  es testing, el 30% de los datos
                          type= "prob") #type= "prob"  es que devuelva la probabilidad

  #prediccion es una matriz con TRES columnas, llamadas "BAJA+1", "BAJA+2"  y "CONTINUA"
  #cada columna es el vector de probabilidades 


  #calculo la ganancia en testing  qu es fold==2
  ganancia_test  <- dataset[ fold==2, 
                             sum( ifelse( prediccion[, "BAJA+2"]  >  1/60,
                                         ifelse( clase_ternaria=="BAJA+2", 59000, -1000 ),
                                         0 ) )]

  #escalo la ganancia como si fuera todo el dataset
  ganancia_test_normalizada  <-  ganancia_test / 0.3

  return( ganancia_test_normalizada )
}
#------------------------------------------------------------------------------

ArbolesMontecarlo  <- function( semillas, param_basicos )
{
  #la funcion mcmapply  llama a la funcion ArbolEstimarGanancia  tantas veces como valores tenga el vector  ksemillas
  ganancias  <- mcmapply( ArbolEstimarGanancia, 
                          semillas,   #paso el vector de semillas, que debe ser el primer parametro de la funcion ArbolEstimarGanancia
                          MoreArgs= list( param_basicos),  #aqui paso el segundo parametro
                          SIMPLIFY= FALSE,
                          mc.cores= 12 )  #se puede subir a 5 si posee Linux o Mac OS

  ganancia_promedio  <- mean( unlist(ganancias) )

  return( ganancia_promedio )
}
#------------------------------------------------------------------------------

#Aqui se debe poner la carpeta de la computadora local
# "/Users/manuelvargas/Documents/ITBA-Maestria- Especialización en Ciencia de Datos/clases/Mineria de Datos/DATOS"
#setwd("D:\\gdrive\\ITBA2022A\\")   #Establezco el Working Directory
setwd("/Users/manuelvargas/Documents/ITBA-Maestria- Especialización en Ciencia de Datos/clases/Mineria de Datos/DATOS")   #Establezco el Working Directory
#cargo los datos
dataset  <- fread("./datasets/paquete_premium_202011.csv")


#genero el archivo para Kaggle
#creo la carpeta donde va el experimento
# HT  representa  Hiperparameter Tuning
dir.create( "./labo/exp/",  showWarnings = FALSE ) 
dir.create( "./labo/exp/HT2020/", showWarnings = FALSE )
archivo_salida  <- "./labo/exp/HT2020/gridsearch5.txt"

#Escribo los titulos al archivo donde van a quedar los resultados
#atencion que si ya existe el archivo, esta instruccion LO SOBREESCRIBE, y lo que estaba antes se pierde
#la forma que no suceda lo anterior es con append=TRUE
cat( file=archivo_salida,
     sep= "",
     "max_depth", "\t",
     "min_split", "\t",
     "min_bucket", "\t",
     "ganancia_promedio", "\n")


#itero por los loops anidados para cada hiperparametro
for( minbucket  in  c( 4,5, 6)  )
{
  for( vmax_depth  in  c( 6,7, 8)  )
  {
    for( vmin_split  in  c( 1000, 950, 900, 850,800 )  )
    {
    
      #notar como se agrega
      param_basicos  <- list( "cp"=         -0.5,       #complejidad minima
                              "minsplit"=  vmin_split,  #minima cantidad de registros en un nodo para hacer el split
                              "minbucket"=  minbucket,          #minima cantidad de registros en una hoja
                              "maxdepth"=  vmax_depth ) #profundidad máxima del arbol
      print(vmin_split, minbucket, vmax_depth)
      #Un solo llamado, con la semilla 17
      ganancia_promedio  <- ArbolesMontecarlo( ksemillas,  param_basicos )
    
      #escribo los resultados al archivo de salida
      cat(  file=archivo_salida,
            append= TRUE,
            sep= "",
            vmax_depth, "\t",
            vmin_split, "\t",
            minbucket, "\t",
            ganancia_promedio, "\n"  )
    }
  }
}