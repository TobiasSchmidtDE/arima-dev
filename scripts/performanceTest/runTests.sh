timestamp() {
  date +"%Y-%m-%d_%H-%M-%S"
}

nohup bash performanceTest.sh driver-memory=256G executor-memory=256G config=forwardsubTestConf.csv systemml=systemml.jar s_folder=scripts/ -usehdfs > nohup/testrun_forwardsub_$(timestamp)

nohup bash performanceTest.sh driver-memory=256G executor-memory=256G config=jacobiTestConf.csv systemml=systemml.jar s_folder=scripts/ -usehdfs > nohup/testrun_jacobi_$(timestamp)

nohup bash performanceTest.sh driver-memory=256G executor-memory=256G config=inverseTestConf.csv systemml=systemml.jar s_folder=scripts/ -usehdfs > nohup/testrun_inverse_$(timestamp)
