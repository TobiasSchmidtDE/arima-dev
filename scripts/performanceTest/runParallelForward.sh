timestamp() {
  date +"%Y-%m-%d_%H-%M-%S"
}

nohup bash performanceTest.sh exec_mode="hybrid" driver-memory=256G executor-memory=256G config=forwardsubTestConf.csv systemml=systemml.jar s_folder=scripts/ -usehdfs > nohup/paralleltestrun_forwardsub_$(timestamp)
