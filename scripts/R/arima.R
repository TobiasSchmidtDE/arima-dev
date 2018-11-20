testdataPath = "C:\\Users\\TobiasSchmidt\\Desktop\\IBM\\PE_4\\SystemML\\dmlscripts\\testdata\\smallerELD_dataset.csv"
testdataPath = "C:\\Users\\TobiasSchmidt\\Desktop\\IBM\\PE_4\\SystemML\\dmlscripts\\pythondump.csv"
testdataPath = "C:\\Users\\TobiasSchmidt\\Desktop\\IBM\\PE_4\\SystemML\\dmlscripts\\simpledata.csv"

testdata = unlist(read.csv(file=testdataPath, header=FALSE, sep=","))
plot(testdata)

model = arima(testdata, order = c(0,0,1), include.mean = FALSE, transform.pars = FALSE, method = c("CSS"))

seasonal_model = arima(testdata, order = c(0,0,0),  seasonal = list(order = c(2, 0, 0), period = 10), include.mean = FALSE, transform.pars = FALSE, method = c("CSS"))

fixedmodel = arima(testdata, fixed = c(1), order = c(0,0,1), seasonal = list(order = c(0, 0, 0), period = 1), include.mean = FALSE, transform.pars = FALSE, method = c("CSS"))
