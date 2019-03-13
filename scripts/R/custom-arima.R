args = commandArgs(trailingOnly=TRUE)

# '1st': X (one column time series - there has to be an .mtd file associated to the src file!) 
# '2nd': p (non-seasonal AR order) (default 0)
# '3rd': d (non-seasonal differencing order) (default 0)
# '4th': q (non-seasonal MA order) (default 0)
# '5th': P (seasonal AR order) (default 0)
# '6th': D (seasonal differencing order)(default 0)
# '7th': Q (seasonal MA order)(default 0)
# '8th': s (period in terms of number of time-steps) (default 1)
# 'dest': file name to store learnt parameters (default "arima-result.csv")
# 'result_format': the format of the destination file (default "csv") 

#input col of time series data
X = read($X)
solver = ifdef($solver, "jacobi")	
optim_method = ifdef($optim_method, "bfgs")
max_func_invoc = ifdef($max_func_invoc, 1000)
dest = ifdef($dest, "arima-results.csv")
result_format = ifdef($result_format, "csv")

#non-seasonal order
p =	ifdef($p, 0)
d = ifdef($d, 0)
q = ifdef($q, 0)

#seasonal order
P = ifdef($P, 0)
D = ifdef($D, 0)
Q = ifdef($Q, 0)

#length of the season
s = ifdef($s, 1)	

debug ("p= " + p)
debug ("d= " + d)
debug ("q= " + q)
debug ("P= " + P)
debug ("D= " + D)
debug ("Q= " + Q)
debug ("s= " + s)
debug ("solver= " + solver)
debug ("optim_method= " + optim_method)
debug ("source= " + $X)
debug ("dest= " + dest)
debug ("result_format= " + result_format)


#TODO: check max_func_invoc < totparamcols --> print warning (stop here ??)

num_rows = nrow(X)
debug("nrows of X: " + num_rows)

if(num_rows <= d){
  warning("non-seasonal differencing order should be smaller than length of the time-series")
}
if(num_rows <= s*D){
  warning("seasonal differencing order should be smaller than number of observations divided by length of season")
}

X = difference (X, d, D, s)

Z = constructPredictorMatrix(X, p, P, q, Q, s)

debug("Z Matrix of size "+nrow(Z)+"x"+ncol(Z)+":\n" + toString( cbind (seq(1,nrow(Z)), Z)))

#R does not use the first rows of Z where the values in columns for p or P are zero, so we cut of all those first rows
max_ar_lag = max(p, P*s, p+(P*s))

arima_model = eval(optim_method + "_optimizer", X[max_ar_lag+1:nrow(X)], Z[max_ar_lag+1:nrow(Z)], max_func_invoc, p, P, q, Q, s, solver)


#TODO: Add RMSE to output

colNames = as.frame("")
for (i in seq(1, p, 1)){
  colNames = rbind(colNames, as.frame("ar"+i))
}
for (i in seq(1, P, 1)){
  colNames = rbind(colNames, as.frame("sar"+i))
}
for (i in seq(1, q, 1)){
  colNames = rbind(colNames, as.frame("ma"+i))
}
for (i in seq(1, Q, 1)){
  colNames = rbind(colNames, as.frame("sma"+i))
}
print("Coefficients for SARIMA("+p+", "+d+", "+q+")("+P+", "+D+", "+Q+") with seasonality s="+s+":\n" + toString(cbind(colNames[2:p+P+q+Q+1, ], as.frame(arima_model)), decimal=15))
write(arima_model, dest, format=result_format)
