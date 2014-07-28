#!/bin/bash
#***************************************************************************************
# SHA1 table generation model:
#      This model is part of Cisco openh264 project for encoder binary comparison test.
#      The output of this test are those SHA1 tables for all test bit stream, and will
#      be used in openh264/test/encoder_binary_comparison/SHA1Table.
#
#      1.Test case configure file: ./CaseConfigure/case.cfg.
#
#      2.Test bit stream files: ./BitStreamForTest/*.264
#
#      3.Test result: ./FinalResult  and ./SHA1Table
#
#      4 For more detail, please refer to READE.md
#
# brief:
#       --Test all cases for one sequence to check that the target codec is the same as benchmark codec
#       --output info can be found  in ../AllTestData/${TestSetIndex}/result/
#            pass case number, unpass case number total case number
#            ${TestSetIndex}_${TestYUVName}_AllCaseOutput.csv
#            ${AllCaseConsoleLogFile}
#            ${CaseSummaryFile}
#
#date:  10/06/2014 Created
#***************************************************************************************
runGlobalVariableInitial()
{
	CurrentDir=`pwd`
	#test data space
	FinalResultPath="result"
	IssueDataPath="issue"
	TempDataPath="TempData"
	mkdir -p ${FinalResultPath}
	mkdir -p ${IssueDataPath}
	mkdir -p ${TempDataPath}
	#test cfg file and test info output file
	ConfigureFile=welsenc.cfg
	AllCasePassStatusFile="${FinalResultPath}/${TestYUVName}_AllCaseOutput.csv"
	AllCaseSHATableFile="${FinalResultPath}/${TestYUVName}_AllCase_SHA1_Table.csv"
	AllCaseConsoleLogFile="${FinalResultPath}/${TestYUVName}.TestLog"
	CaseSummaryFile="${FinalResultPath}/${TestYUVName}.Summary"
	echo  "EncoderFlag,DecoderFlag,SHA-1, MD5, BitStreamSize, YUVSize,\
			-scrsig,  -frms,  -numl,  -numtl, -sw, -sh,\
			-dw 0, -dh 0, -dw 1, -dh 1,-dw 2, -dh 2, -dw 3, -dh 3,\
			-frout 0,  -frout 1, -frout 2, -frout 3,\
			-lqp 0, -lqp 1, -lqp 2, -lqp 3,\
			-rc,-tarb, -ltarb 0, -ltarb 1, -ltarb 2, -ltarb 3,\
			-slcmd 0, -slcnum 0, -slcmd 1, -slcnum 1,\
			-slcmd 2, -slcnum 2, -slcmd 3, -slcnum 3,\
			-nalsize, -iper, -thread, -ltr, -db, -denois,\
			-scene    -bgd    -aq ">${AllCasePassStatusFile}
	echo  "SHA-1 Value, MD5String, BitStreamSize, YUVSize, \
			-scrsig,  -frms,  -numl,  -numtl, -sw, -sh,\
			-dw 0, -dh 0, -dw 1, -dh 1,-dw 2, -dh 2, -dw 3, -dh 3,\
			-frout 0,  -frout 1, -frout 2, -frout 3,\
			-lqp 0, -lqp 1, -lqp 2, -lqp 3,\
			-rc,-tarb, -ltarb 0, -ltarb 1, -ltarb 2, -ltarb 3,\
			-slcmd 0, -slcnum 0, -slcmd 1, -slcnum 1,\
			-slcmd 2, -slcnum 2, -slcmd 3, -slcnum 3,\
			-nalsize, -iper, -thread, -ltr, -db, -denois,\
			-scene    -bgd    -aq ">${AllCaseSHATableFile}
	
	let "YUVSizeLayer0=0"
	let "YUVSizeLayer1=0"
	let "YUVSizeLayer2=0"
	let "YUVSizeLayer3=0"
	
	YUVFileLayer0=""
	YUVFileLayer1=""
	YUVFileLayer2=""
	YUVFileLayer3=""
		
	#encoder parameters  change based on the case info
	let "EncoderPassedNum=0"
	let "EncoderUnPassedNum=0"
	let "DecoderPassedNum=0"
	let "DecoderUpPassedNum=0"
	let "DecoderUnCheckNum=0"
}
runPrepareMultiLayerInfo()
{
	local PrepareLog="MultiLayerInputYUVPrepare.log"
	declare -a aYUVInfo
	
	aYUVInfo=(`./run_ParseYUVInfo.sh  ${TestYUVName}`)
	PicW=${aYUVInfo[0]}
	PicH=${aYUVInfo[1]}
	#generate input YUV file for each layer
	MaxSpatialLayerNum=`./run_GetSpatialLayerNum.sh ${PicW} ${PicH}`
	./run_PrepareMultiLayerInputYUV.sh ${InputYUV} ${MaxSpatialLayerNum} ${PrepareLog}
	
	if [ ! $? -eq 0 ]
	then
		echo ""
		echo -e "\033[31m multilayer input YUV preparation failed! \033[0m"
		echo ""
		exit 1	
	fi
	
	#parse multilayer YUV's name and size info	
	while read line
	do
		if [[  $line =~ ^LayerName_0  ]]
		then
			YUVFileLayer0=`echo $line | awk 'BEGIN {FS="[:\r]"} {print $2}'`
		elif [[ $line =~ ^LayerSize_0 ]]
		then
			YUVSizeLayer0=`echo $line | awk 'BEGIN {FS="[:\r]"} {print $2}'`
		elif  [[  $line =~ ^LayerName_1  ]]
		then
			YUVFileLayer1=`echo $line | awk 'BEGIN {FS="[:\r]"} {print $2}'`
		elif [[ $line =~ ^LayerSize_1 ]]
		then
			YUVSizeLayer1=`echo $line | awk 'BEGIN {FS="[:\r]"} {print $2}'`
		elif  [[  $line =~ ^LayerName_2  ]]
		then
			YUVFileLayer2=`echo $line | awk 'BEGIN {FS="[:\r]"} {print $2}'`
		elif [[ $line =~ ^LayerSize_2 ]]
		then
			YUVSizeLayer2=`echo $line | awk 'BEGIN {FS="[:\r]"} {print $2}'`
		elif  [[  $line =~ ^LayerName_3  ]]
		then
			YUVFileLayer3=`echo $line | awk 'BEGIN {FS="[:\r]"} {print $2}'`
		elif [[ $line =~ ^LayerSize_3 ]]
		then
			YUVSizeLayer3=`echo $line | awk 'BEGIN {FS="[:\r]"} {print $2}'`
		fi	
	done <${PrepareLog}
	echo "YUVFileLayer3:  ${YUVFileLayer3}"
	echo "YUVSizeLayer3:  ${YUVSizeLayer3}"
	echo "YUVFileLayer2:  ${YUVFileLayer2}"
	echo "YUVSizeLayer2:  ${YUVSizeLayer2}"
	echo "YUVFileLayer1:  ${YUVFileLayer1}"
	echo "YUVSizeLayer1:  ${YUVSizeLayer1}"
	echo "YUVFileLayer0:  ${YUVFileLayer0}"
	echo "YUVSizeLayer0:  ${YUVSizeLayer0}"	
}
#usae: runParseCaseCheckLog ${CheckLog}
runParseCaseCheckLog()
{
	if [ ! $# -eq 1 ]
	then
		echo "usae: runParseCaseCheckLog ${CheckLog}"
		return 1
	fi
	
	local CheckLog=$1
	local Flag="0"
	
	if [  ! -e ${CheckLog} ]
	then
		echo "check log file does not exist!"
		return 1
	fi
	
	while read line
	do
		if [[  "$line" =~ ^EncoderPassedNum  ]]
		then
			Flag=`echo $line | awk 'BEGIN {FS="[:\r]"} {print $2}'`
			echo $Flag
			let "EncoderPassedNum +=${Flag}"
		elif [[ "$line" =~ ^EncoderUnPassedNum ]]
		then
			Flag=`echo $line | awk 'BEGIN {FS="[:\r]"} {print $2}'`
			echo $Flag
			let "EncoderUnPassedNum +=${Flag}"
		elif [[ "$line" =~ ^DecoderPassedNum ]]
		then
			Flag=`echo $line | awk 'BEGIN {FS="[:\r]"} {print $2}'`
			echo $Flag
			let "DecoderPassedNum +=${Flag}"
		elif [[ "$line" =~ ^DecoderUpPassedNum ]]
		then
			Flag=`echo $line | awk 'BEGIN {FS="[:\r]"} {print $2}'`
			echo $Flag
			let "DecoderUpPassedNum +=${Flag}"
		elif [[ "$line" =~ ^DecoderUnCheckNum ]]
		then
			Flag=`echo $line | awk 'BEGIN {FS="[:\r]"} {print $2}'`
			echo $Flag
			let "DecoderUnCheckNum +=${Flag}"
		fi
	done <${CheckLog}
}
# run all test case based on XXXcase.csv file
#usage  runAllCaseTest
runAllCaseTest()
{
	local CheckLogFile="CaseCheck.log"
	local EncoderLog="encoder.log"
	
	while read CaseData
	do
		if [[ $CaseData =~ ^[-0-9]  ]]
		then
			echo ""
			echo ""
			echo ""
			echo "********************case index is ${TotalCaseNum}**************************************"
			export IssueDataPath
			export TempDataPath
			export TestYUVName
			export InputYUV
			export AllCasePassStatusFile
			export AllCaseSHATableFile
			export EncoderLog
			export CheckLogFile
			export YUVSizeLayer0
			export YUVSizeLayer1
			export YUVSizeLayer2
			export YUVSizeLayer3
			export YUVFileLayer0
			export YUVFileLayer1
			export YUVFileLayer2
			export YUVFileLayer3
			
			./run_TestOneCase.sh  ${CaseData}
			runParseCaseCheckLog ${CheckLogFile}
			
			cat ${EncoderLog}
            cat ${CheckLogFile}
			let "TotalCaseNum++"
		fi
	done <$AllCaseFile
}
#usage runOutputPassNum
runOutputPassNum()
{
	# output file locate in ../result
	TestFolder=`echo $CurrentDir | awk 'BEGIN {FS="/"} { i=NF; print $i}'`
	echo ""
	echo  -e "\033[32m *********************************************************** \033[0m"
	echo  -e "\033[32m total case  Num     is : ${TotalCaseNum}\033[0m"
	echo  -e "\033[32m EncoderPassedNum    is : ${EncoderPassedNum}\033[0m"
	echo  -e "\033[31m EncoderUnPassedNum  is : ${EncoderUnPassedNum} \033[0m"
	echo  -e "\033[32m DecoderPassedNum    is : ${DecoderPassedNum}\033[0m"
	echo  -e "\033[31m DecoderUpPassedNum  is : ${DecoderUpPassedNum}\033[0m"
	echo  -e "\033[31m DecoderUnCheckNum   is : ${DecoderUnCheckNum}\033[0m"
	echo "issue bitstream can be found in .../AllTestData/${TestFolder}/issue"
	echo "detail result  can be found in .../AllTestData/${TestFolder}/result"
	echo  -e "\033[32m *********************************************************** \033[0m"
	echo ""
	echo "${TestSetIndex}_${TestYUVName}">${CaseSummaryFile}
	echo "total case  Num     , ${TotalCaseNum}" >>${CaseSummaryFile}
	echo "EncoderPassedNum    , ${EncoderPassedNum}" >>${CaseSummaryFile}
	echo "EncoderUnPassedNum  , ${EncoderUnPassedNum} " >>${CaseSummaryFile}
	echo "DecoderPassedNum    , ${DecoderPassedNum}" >>${CaseSummaryFile}
	echo "DecoderUpPassedNum  , ${DecoderUpPassedNum}" >>${CaseSummaryFile}
	echo "DecoderUnCheckNum   , ${DecoderUnCheckNum}" >>${CaseSummaryFile}
	echo "  detail file located in ../AllTestData/${TestSetIndex}/result" >>${CaseSummaryFile}
	echo  -e "\033[32m *********************************************************** \033[0m"
	
	if [  ! ${EncoderUnPassedNum} -eq 0  ]
	then
		FlagFile="./result/${TestSetIndex}_${TestYUVName}.unpassFlag"
	else
		FlagFile="./result/${TestSetIndex}_${TestYUVName}.passFlag"
	fi
	touch ${FlagFile}
}
#***********************************************************
# usage: runMain $TestYUV  $InputYUV $AllCaseFile
runMain()
{
	if [ ! $# -eq 3  ]
	then
		echo "usage: run_TestAllCase.sh \$TestYUVName \$InputYUV  \$AllCaseFile"
	return 1
	fi
	
	TestYUVName=$1
	InputYUV=$2
	AllCaseFile=$3
	runGlobalVariableInitial
	runPrepareMultiLayerInfo
	
	runAllCaseTest #>${AllCaseConsoleLogFile}
	runOutputPassNum
}
TestYUVName=$1
InputYUV=$2
AllCaseFile=$3
runMain  ${TestYUVName}  ${InputYUV}  ${AllCaseFile}

