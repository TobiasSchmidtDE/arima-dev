timestamp() {
  date +"%Y-%m-%d_%H-%M-%S"
}

nohup python configbuilder.py > nohup/configbuilder_$(timestamp)
