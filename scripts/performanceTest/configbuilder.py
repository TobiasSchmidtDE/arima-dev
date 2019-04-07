import pandas as pd

base = pd.DataFrame(columns=["X_src", "weigths_src", "residuals_out", "solver", "p", "d", "q", "P", "D", "Q", "s"])

tsfolder = "in/timeseries/"
tsprefix = "ts_"
weightsfolder = "in/weights/"
weightsprefix = "model_"
matrixsuffix = ".mtx"
initstep = 0
endstep = 1000
stepsize = 50
sizes = {"":1, "K":1E3, "M":1E6, "G":1E9}

def configObject (tssize, solver, p, d, q, P, D, Q, s, i, ):
    print("Size= " + tssize + ", solver= " + solver + ", i= " +str(i) + "confg="+ str(p) + "_" + str(d) + "_" + str(q) + "_" + str(P) + "_" + str(D) + "_" + str(Q) + "_" + str(s))
    nargs = str(p+q+P+Q)
    ncond = p+P*s+d+D*s
    if ncond < i*sizes[tssize]:
        allargs = solver + "_" + str(p) + "_" + str(d) + "_" + str(q) + "_" + str(P) + "_" + str(D) + "_" + str(Q) + "_" + str(s)
        tsfile = tsfolder + tsprefix + str(i) + tssize + matrixsuffix
        weightsfile = weightsfolder + weightsprefix + nargs + matrixsuffix
        weightsfilesmall = weightsfolder + weightsprefix + nargs + "_small" + matrixsuffix
        resout = "residuals_" + str(i) + tssize + allargs + matrixsuffix
        return sarimaObj(tsfile, weightsfile, resout, solver, p, d, q, P, D, Q, s, i*sizes[tssize])
    else:
        return base

def seasonalARIMA(tssize, solver, p, d, q, P, D, Q, s):
    sarima = base.copy()
    if tssize =="G":
        sarima = sarima.append(configObject(tssize, solver, p, d, q, P, D, Q, s, 1), ignore_index=True)
        for i in range(0, 51, 10):
            if i == 0:
                continue
            sarima = sarima.append(configObject(tssize, solver, p, d, q, P, D, Q, s, i), ignore_index=True)
    else:
        sarima = sarima.append(configObject(tssize, solver, p, d, q, P, D, Q, s, 1), ignore_index=True)
        for i in range(initstep, endstep, stepsize):
            if i == 0:
                continue
            sarima = sarima.append(configObject(tssize, solver, p, d, q, P, D, Q, s, i), ignore_index=True)
    return sarima

def arima(tssize, solver, p, d, q):
    return seasonalARIMA(tssize, solver, p, d, q, 0, 0, 0, 0)

def arma(tssize, solver, p, q):
    return arima(tssize, solver, p, 0, q)

def ar(tssize, solver, p):
    return arma(tssize, solver, p, 0)

def ma(tssize, solver, q):
    return arma(tssize, solver, 0, q)

def sar(tssize, solver, p, P, s):
    return seasonalARIMA(tssize, solver, p, 0, 0, P, 0, 0, s)

def sma(tssize, solver, q, Q, s):
    return seasonalARIMA(tssize, solver, 0, 0, q, 0, 0, Q, s)


def allConfigsForSize(solver, tssize):
    print("All configurations for " + tssize + " and " + solver + " solver")
    ar3 = ar(tssize, solver, 3)
    ar6 = ar(tssize, solver, 6)
    ma3 = ma(tssize, solver, 3)
    ma6 = ma(tssize, solver, 6)
    arima2 = arima(tssize, solver, 2, 1, 2)
    arima4 = arima(tssize, solver, 4, 1, 4)
    #sar3 = sar(tssize, solver, 3, 3, 3)
    #sar6 = sar(tssize, solver, 6, 6, 18)
    #sma3 = sma(tssize, solver, 3, 3, 3)
    #sma6 = sma(tssize, solver, 6, 6, 18)
    # sarima2 = seasonalARIMA(tssize, solver, 2, 1, 2, 2, 1, 2, 6)
    # sarima4 = seasonalARIMA(tssize, solver, 4, 1, 4, 4, 1, 4, 12)

    return pd.concat([ar3, ar6, ma3, ma6, arima2, arima4], ignore_index=True)


def allConfigsForSolver(solver):
    all = allConfigsForSize(solver, "")
    allK = allConfigsForSize(solver, "K")
    allM = allConfigsForSize(solver, "M")
    someG = allConfigsForSize(solver, "G")
    #return pd.concat([all], ignore_index=True)
    return pd.concat([all, allK, allM, someG], ignore_index=True)



def sarimaObj(X_src, weigths_src, residuals_out, solver, p, d, q, P, D, Q, s, Xsize):
    return {"X_src":X_src,"weigths_src": weigths_src, "residuals_out": residuals_out, "solver": solver, "p":p, "d":d, "q":q, "P":P, "D":D, "Q":Q, "s":s, "Xsize":Xsize}


jacobiTestConf= allConfigsForSolver("jacobi")
jacobiTestConf.to_csv("jacobiTestConf.csv", index = False)


forwardsubTestConf= allConfigsForSolver("forwardsub")
forwardsubTestConf.to_csv("forwardsubTestConf.csv", index = False)


inverseTestConf= allConfigsForSolver("inverse")
inverseTestConf.to_csv("inverseTestConf.csv", index = False)
