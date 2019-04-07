timestamp() {
  date +"%Y-%m-%d_%H-%M-%S"
}

for ARG in "$@"
do
  KEY=$(echo $ARG | cut -f1 -d=)
  VALUE=$(echo $ARG | cut -f2 -d=)
  case $KEY in
    "config") config=$VALUE;;
    "out") testOut=$VALUE;;
    "r_file") r_file=$VALUE;;
    "r_path") dml_path=$VALUE;;
    "dml_file") dml_file=$VALUE;;
    "s_folder") scripts_folder=$VALUE;;
    "dml_path") dml_path=$VALUE;;
    "systemml") systemml_jar=$VALUE;;
    "driver-memory") driver_memory=$VALUE;;
    "executor-memory") executor_memory=$VALUE;;
    "exec_mode") exec_mode=$VALUE;;
    "-usehdfs") usehdfs=TRUE;;
  esac
done

if [ -z "$usehdfs" ]
then
  usehdfs=FALSE
fi

if [ -z "$driver_memory" ]
then
  driver_memory=4G
fi

if [ -z "$executor_memory" ]
then
  executor_memory=4G
fi


if [ -z "$dml_file" ]
then
  dml_file="arima_css.dml"
fi

if [ -z "$r_file" ]
then
  r_file="arima_css.R"
fi

if [ -z "$scripts_folder" ]
then
  scripts_folder="/Users/tobiasschmidt/Desktop/DHBW/Studienarbeit/systemml/src/test/scripts/applications/arima_box-jenkins/"
fi

if [ -z "$systemml_jar" ]
then
  systemml_jar=~/Desktop/DHBW/Studienarbeit/systemml/target/systemml-1.3.0-SNAPSHOT.jar
fi

if [ -z "$dml_path" ]
then
  dml_path=$scripts_folder$dml_file
fi

if [ -z "$r_path" ]
then
  r_path=$scripts_folder$r_file
fi

if [ -z "$testOut" ]
then
  testOut="out/results_"$(timestamp)"_"$config
fi

if [ -z "$exec_mode" ]
then
  exec_mode="singlenode"
fi


dml_out=out/dml/
r_out=out/r/
error_out=out/error/

mkdir -p $dml_out
mkdir -p $r_out
mkdir -p $error_out

if test $usehdfs = TRUE
then
  hdfs dfs -mkdir -p $dml_out
  hdfs dfs -mkdir -p $r_out
  hdfs dfs -mkdir -p $error_out
fi

echo "X_src,weigths_src,residuals_out,solver,p,d,q,P,D,Q,s,Xsize,r_exec_time,r_run_time,r_result,dml_elapsed_time,dml_compilation_time,dml_execution_time,dml_result,heavy_hitter_instruction_1,heavy_hitter_instruction_2,heavy_hitter_instruction_3,heavy_hitter_instruction_4,heavy_hitter_instruction_5,heavy_hitter_instruction_6,heavy_hitter_instruction_7,heavy_hitter_instruction_8,heavy_hitter_instruction_9,heavy_hitter_instruction_10,heavy_hitter_time_1,heavy_hitter_time_2,heavy_hitter_time_3,heavy_hitter_time_4,heavy_hitter_time_5,heavy_hitter_time_6,heavy_hitter_time_7,heavy_hitter_time_8,heavy_hitter_time_9,heavy_hitter_time_10,heavy_hitter_count_1, heavy_hitter_count_2, heavy_hitter_count_3, heavy_hitter_count_4, heavy_hitter_count_5, heavy_hitter_count_6, heavy_hitter_count_7, heavy_hitter_count_8, heavy_hitter_count_9, heavy_hitter_count_10, errormsg," > "$testOut"

ignoreHeader=TRUE
while IFS=',' read -r X weights_src residuals_out solver p d q P D Q s Xsize
do
  if test $ignoreHeader = TRUE
  then
    ignoreHeader=false
  else
    dest_dml=$dml_out$residuals_out
    dest_r=$r_out$residuals_out
    dash=_
    txt=.txt
    error_file=error_$(timestamp)_$solver$p$d$q$P$D$Q$s$dash$Xsize$txt
    error=false
    errormsg=NA
    dml_execution_time=NA
    r_exec_time=NA
    dml_elapsed_time=NA
    r_run_time=NA
    dml_result=NA
    r_result=NA


    echo
    echo
    echo "RUN TEST FOR ARIMA("$p", "$d", "$q")("$P", "$D", "$Q") s="$s" with X="$X" weights_src="$weights_src "solver="$solver" and dest="$dest_dml
    echo

    dml_output=$(spark-submit --driver-memory $driver_memory --executor-memory $executor_memory $systemml_jar -f $dml_path -nvargs X=$X weights_src=$weights_src p=$p d=$d q=$q P=$P D=$D Q=$Q s=$s solver=$solver residuals_out=$dest_dml -exec $exec_mode -stats)

    echo

    readheavyhitter=false
    nHeavyhitter=0
    heavyhitter_instruction=()
    heavyhitter_time=()
    heavyhitter_count=()
    while read -r f1 f2 f3 f4 f5 f6
    do
      #echo "1-$f1--2-$f2--3-$f3--4-$f4--5-$f5--6-$f6"
      if [[ $f3 == "org.apache.sysml.runtime.DMLRuntimeException:" ]]
      then
        error=TRUE
        errormsg="DMLRuntimeException: $f4"
      fi
      if [[ $f1 == "ERROR:" ]]
      then
        error=TRUE
        errormsg=$f4
      fi
      if [[ $f2 == "elapsed" && $f3 == "time:" ]];
      then
        dml_elapsed_time=$f4
      fi
      if [[ $f2 == "compilation" && $f3 == "time:" ]]
      then
        dml_compilation_time=$f4
      fi
      if [[ $f2 == "execution" && $f3 == "time:" ]]
      then
        dml_execution_time=$f4
      fi
      if [[ $f1 == "arima_css" ]]
      then
        dml_result=$f3
      fi

      if test $readheavyhitter = TRUE
      then
        if [[ $nHeavyhitter -gt 0 && $nHeavyhitter -lt 11 ]]
        then
          heavyhitter_instruction[$nHeavyhitter]=$f2
          heavyhitter_time[$nHeavyhitter]=$f3
          heavyhitter_count[$nHeavyhitter]=$f4
        fi
        nHeavyhitter=$((nHeavyhitter+1))
      fi

      if [[ $f1 == "Heavy" && $f2 == "hitter" && $f3 == "instructions:" ]]
      then
        readheavyhitter=TRUE
      fi


    done <<< "$dml_output"
    echo "DML finished"

    # echo $readheavyhitter $nHeavyhitter
    # echo $dml_elapsed_time
    # echo $dml_compilation_time
    # echo $dml_execution_time
    printf "%s," ${heavyhitter_instruction[@]}
    echo
    printf "%s," ${heavyhitter_time[@]}
    echo
    printf "%s," ${heavyhitter_count[@]}
    echo

    if test $dml_result = NA
    then
      error=TRUE
      errormsg="UNKNOWN ERROR: Error logs in $error_out$error_file"
    fi

    if test $error = TRUE
    then
      echo "AN ERROR HAS OCCURED IN THE DML SCRIPT:"
      echo $errormsg
      printf "%s\n" "$dml_output" >> "$error_out$error_file"
      if test $usehdfs = TRUE
      then
        hdfs dfs -copyFromLocal -f $error_out$error_file $error_out$error_file
      fi
    fi

    # Rscript does *not* load the "methods" package by default
		# to save on start time. The "Matrix" package used in the
		# tests requires the "methods" package and should still
		# load and attach it, but in R 3.2 with the latest version
		# of the "Matrix" package, "methods" is loaded *but not
		# attached* when run with Rscript. Therefore, we need to
		# explicitly load it with Rscript.
    r_output=$(Rscript --verbose --default-packages=methods,datasets,graphics,grDevices,stats,utils $r_path $X $weights_src "" $p $d $q $P $D $Q $s $dest_r $usehdfs)

    echo
    while read -r f1 f2 f3 f4
    do
      #echo "1-$f1--2-$f2--3-$f3--4-$f4"
      if [[ $f2 == '"execution_time:' ]]
      then
        r_exec_time="$(cut -d'"' -f1 <<<$f3)" #cutting of double qoutes
      fi

      if [[ $f2 == '"run_time:' ]]
      then
        r_run_time="$(cut -d'"' -f1 <<<$f3)" #cutting of double qoutes
      fi

      if [[ $f2 == '"arima_css=' ]]
      then
        r_result="$(cut -d'"' -f1 <<<$f3)" #cutting of double qoutes
      fi
    done <<< "$r_output"
    echo "R finished"

    echo "DML's execution time: $dml_execution_time"
    echo "R's execution time: $r_exec_time"
    echo
    echo "DML's run time: $dml_elapsed_time"
    echo "R's run time: $r_run_time"
    echo
    echo "DML's result: $dml_result"
    echo "R's result: $r_result"

    testsummary=$(printf "%s," "${X}" "${weights_src}" "${residuals_out}" "${solver}" "${p}" "${d}" "${q}" "${P}" "${D}" "${Q}" "${s}" "${Xsize}" "${r_exec_time}" "${r_run_time}" "${r_result}" "${dml_elapsed_time}" "${dml_compilation_time}" "${dml_execution_time}" "${dml_result}" "${heavyhitter_instruction[@]}" "${heavyhitter_time[@]}" "${heavyhitter_count[@]}" "${errormsg}")
    testsummary=$(printf "%s\n" "${testsummary}")

    echo
    echo $testsummary
    echo $testsummary >> "$testOut"

  fi
done < "$config"

if test $usehdfs = TRUE
then
  hdfs dfs -copyFromLocal -f $testOut $testOut
fi
