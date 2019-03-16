NVARGS=""
for ARG in "$@"
do
  KEY=$(echo $ARG | cut -f1 -d=)
  VALUE=$(echo $ARG | cut -f2 -d=)
  case $KEY in
    "q"|"d"|"p"|"P"|"D"|"Q"|"s"|"solver"|"maxit"|"dest"|"result_format") NVARGS="$NVARGS$ARG ";;
    "weights") weights="$VALUE";;
    "weights_src") weights_src=$ARG;;
    "X") X=$ARG;;
    "dml_file") dml_file=$VALUE;;
    "dml_folder") dml_folder=$VALUE;;
    "-debug") debug=$ARG;;
  esac
done

if [ -z "$X" ]
then
  X="X=/Users/tobiasschmidt/Desktop/DHBW/Studienarbeit/data/MT_225-ResampledW-NoTimestamp-householddata.csv"
fi

if [ -z "$weights_src" ]
then
  weights_src="weights_src=/Users/tobiasschmidt/Desktop/DHBW/Studienarbeit/scripts/arima-results.csv"
fi

if [ -z "$dml_file" ]
then
  dml_file="arima_css.dml"
fi

if [ -z "$dml_folder" ]
then
  dml_folder="/Users/tobiasschmidt/Desktop/DHBW/Studienarbeit/systemml/src/test/scripts/applications/arima_box-jenkins/"
fi

NVARGS="$NVARGS$X $weights_src"
SYSTEMLJAR=~/Desktop/DHBW/Studienarbeit/systemml/target/systemml-1.3.0-SNAPSHOT.jar
echo
echo
echo "RUN ARIMA with $NVARGS"
echo
echo

if [ -z "$weights" ]
then
spark-submit $SYSTEMLJAR -f $dml_folder$dml_file -nvargs $NVARGS $debug -exec "singlenode"
else
spark-submit $SYSTEMLJAR -f $dml_folder$dml_file -nvargs $NVARGS weights="$weights" $debug -exec "singlenode"
fi
