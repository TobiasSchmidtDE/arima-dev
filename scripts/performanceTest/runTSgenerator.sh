timestamp() {
  date +"%Y-%m-%d_%H-%M-%S"
}

nohup spark-submit --driver-memory 256G --executor-memory 256G systemml.jar -f tsgenerator.dml > nohup/data_generator_$(timestamp)
