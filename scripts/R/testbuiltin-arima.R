start_time <- Sys.time()

args = commandArgs(trailingOnly=TRUE)

print(args)
if (length(args)!= 8) {
  stop("At least one argument must be supplied (input file).n", call.=FALSE)
} 


filePath = args[1]
nonseasonalparam = as.numeric(strsplit(args[2],",")[[1]])
seasonalparam = as.numeric(strsplit(args[3],",")[[1]])
seasonality = as.numeric(strsplit(args[4],",")[[1]])
data = unlist(read.csv(file=filePath , header=FALSE, sep=","))
seasonal_model = arima(data , order = nonseasonalparam ,  seasonal = list(order = seasonalparam , period = seasonality ), include.mean = FALSE, transform.pars = FALSE, method = c("CSS"))

end_time <- Sys.time()
sprintf("R ARIMA's execution time: %f", (end_time - start_time))