#!/bin/bash

set -e 

####Defining pathways
toplvl=/Users/franklinfeingold/Desktop/NKI_script
dcmdir=/Users/franklinfeingold/Desktop/NKI_script/Dicom
dcm2niidir=/Users/franklinfeingold/Desktop/dcm2niix_3-Jan-2018_mac
#Create nifti directory
mkdir ${toplvl}/Nifti
niidir=${toplvl}/Nifti

###Create dataset_description.json
jo -p "Name"="NKI-Rockland Sample - Multiband Imaging Test-Retest Pilot Dataset" "BIDSVersion"="1.0.2" >> ${niidir}/dataset_description.json

####Anatomical Organization####
for subj in 2475376; do
	echo "Processing subject $subj"

###Create structure
mkdir -p ${niidir}/sub-${subj}/ses-1/anat

###Convert dcm to nii
#Only convert the Dicom folder anat
for direcs in anat; do
${dcm2niidir}/dcm2niix -o ${niidir}/sub-${subj} -f ${subj}_%f_%p ${dcmdir}/${subj}/${direcs}
done

#Changing directory into the subject folder
cd ${niidir}/sub-${subj}

###Change filenames
##Rename anat files
#Example filename: 2475376_anat_MPRAGE
#BIDS filename: sub-2475376_ses-1_T1w
#Capture the number of anat files to change
anatfiles=$(ls -1 *MPRAGE* | wc -l)
for ((i=1;i<=${anatfiles};i++)); do
Anat=$(ls *MPRAGE*) #This is to refresh the Anat variable, if this is not in the loop, each iteration a new "No such file or directory error", this is because the filename was changed. 
tempanat=$(ls -1 $Anat | sed '1q;d') #Capture new file to change
tempanatext="${tempanat##*.}"
tempanatfile="${tempanat%.*}"
mv ${tempanatfile}.${tempanatext} sub-${subj}_ses-1_T1w.${tempanatext}
echo "${tempanat} changed to sub-${subj}_ses-1_T1w.${tempanatext}"
done 

###Organize files into folders
for files in $(ls sub*); do 
Orgfile="${files%.*}"
Orgext="${files##*.}"
Modality=$(echo $Orgfile | rev | cut -d '_' -f1 | rev)
if [ $Modality == "T1w" ]; then
	mv ${Orgfile}.${Orgext} ses-1/anat
else
:
fi 
done

####Diffusion Organization####
#Create subject folder 
mkdir -p ${niidir}/sub-${subj}/{ses-1,ses-2}/dwi

###Convert dcm to nii
#Converting the two diffusion Dicom directories 
for direcs in session1 session2; do
${dcm2niidir}/dcm2niix -o ${niidir}/sub-${subj} -f ${subj}_${direcs}_%p ${dcmdir}/${subj}/${direcs}/DTI*
done

#Changing directory into the subject folder
cd ${niidir}/sub-${subj}

#change dwi
#Example filename: 2475376_session2_DIFF_137_AP_RR
#BIDS filename: sub-2475376_ses-2_dwi
#difffiles will capture how many filenames to change
difffiles=$(ls -1 *DIFF* | wc -l)
for ((i=1;i<=${difffiles};i++));
do
	Diff=$(ls *DIFF*) #This is to refresh the diff variable, same as the cases above. 
	tempdiff=$(ls -1 $Diff | sed '1q;d')
	tempdiffext="${tempdiff##*.}"
	tempdifffile="${tempdiff%.*}"
	Sessionnum=$(echo $tempdifffile | cut -d '_' -f2)
	Difflast=$(echo "${Sessionnum: -1}")
	if [ $Difflast == 2 ]; then 
	ses=2
	else
	ses=1
	fi
	mv ${tempdifffile}.${tempdiffext} sub-${subj}_ses-${ses}_dwi.${tempdiffext}
	echo "$tempdiff changed to sub-${subj}_ses-${ses}_dwi.${tempdiffext}"
done 

###Organize files into folders
for files in $(ls sub*); do 
Orgfile="${files%.*}"
Orgext="${files##*.}"
Modality=$(echo $Orgfile | rev | cut -d '_' -f1 | rev)
Sessionnum=$(echo $Orgfile | cut -d '_' -f2)
Difflast=$(echo "${Sessionnum: -1}")
if [[ $Modality == "dwi" && $Difflast == 2 ]]; then
	mv ${Orgfile}.${Orgext} ses-2/dwi
else
if [[ $Modality == "dwi" && $Difflast == 1 ]]; then
	mv ${Orgfile}.${Orgext} ses-1/dwi
fi 
fi
done

####Functional Organization####
#Create subject folder 
mkdir -p ${niidir}/sub-${subj}/{ses-1,ses-2}/func

###Convert dcm to nii
for direcs in TfMRI_breathHold_1400 TfMRI_eyeMovementCalibration_1400 TfMRI_eyeMovementCalibration_645 TfMRI_visualCheckerboard_1400 TfMRI_visualCheckerboard_645 session1 session2; do
if [[ $direcs == "session1" || $direcs == "session2" ]]; then
for rest in RfMRI_mx_645 RfMRI_mx_1400 RfMRI_std_2500; do 
${dcm2niidir}/dcm2niix -o ${niidir}/sub-${subj} -f ${subj}_${direcs}_%p ${dcmdir}/${subj}/${direcs}/${rest}
done
else
${dcm2niidir}/dcm2niix -o ${niidir}/sub-${subj} -f ${subj}_${direcs}_%p ${dcmdir}/${subj}/${direcs}
fi
done

#Changing directory into the subject folder
cd ${niidir}/sub-${subj}

##Rename func files
#Break the func down into each task
#Checkerboard task
#Example filename: 2475376_TfMRI_visualCheckerboard_645_CHECKERBOARD_645_RR
#BIDS filename: sub-2475376_ses-1_task-Checkerboard_acq-TR645_bold
#Capture the number of checkerboard files to change
checkerfiles=$(ls -1 *CHECKERBOARD* | wc -l)
for ((i=1;i<=${checkerfiles};i++)); do
Checker=$(ls *CHECKERBOARD*) #This is to refresh the Checker variable, same as the Anat case
tempcheck=$(ls -1 $Checker | sed '1q;d') #Capture new file to change
tempcheckext="${tempcheck##*.}"
tempcheckfile="${tempcheck%.*}"
TR=$(echo $tempcheck | cut -d '_' -f4) #f4 is the third field delineated by _ to capture the acquisition TR from the filename
mv ${tempcheckfile}.${tempcheckext} sub-${subj}_ses-1_task-Checkerboard_acq-TR${TR}_bold.${tempcheckext}
echo "${tempcheckfile}.${tempcheckext} changed to sub-${subj}_ses-1_task-Checkerboard_acq-TR${TR}_bold.${tempcheckext}"
done

#Eye Movement
#Example filename: 2475376_TfMRI_eyeMovementCalibration_645_EYE_MOVEMENT_645_RR
#BIDS filename: sub-2475376_ses-1_task-eyemovement_acq-TR645_bold
#Capture the number of eyemovement files to change
eyefiles=$(ls -1 *EYE* | wc -l)
for ((i=1;i<=${eyefiles};i++)); do
Eye=$(ls *EYE*)
tempeye=$(ls -1 $Eye | sed '1q;d')
tempeyeext="${tempeye##*.}"
tempeyefile="${tempeye%.*}"
TR=$(echo $tempeye | cut -d '_' -f4) #f4 is the fourth field delineated by _ to capture the acquisition TR from the filename
mv ${tempeyefile}.${tempeyeext} sub-${subj}_ses-1_task-eyemovement_acq-TR${TR}_bold.${tempeyeext}
echo "${tempeyefile}.${tempeyeext} changed to sub-${subj}_ses-1_task-eyemovement_acq-TR${TR}_bold.${tempeyeext}"
done

#Breath Hold
#Example filename: 2475376_TfMRI_breathHold_1400_BREATH_HOLD_1400_RR
#BIDS filename: sub-2475376_ses-1_task-breathhold_acq-TR1400_bold
#Capture the number of breath hold files to change
breathfiles=$(ls -1 *BREATH* | wc -l)
for ((i=1;i<=${breathfiles};i++)); do
Breath=$(ls *BREATH*)
tempbreath=$(ls -1 $Breath | sed '1q;d')
tempbreathext="${tempbreath##*.}"
tempbreathfile="${tempbreath%.*}"
TR=$(echo $tempbreath | cut -d '_' -f4) #f4 is the fourth field delineated by _ to capture the acquisition TR from the filename
mv ${tempbreathfile}.${tempbreathext} sub-${subj}_ses-1_task-breathhold_acq-TR${TR}_bold.${tempbreathext}
echo "${tempbreathfile}.${tempbreathext} changed to sub-${subj}_ses-1_task-breathhold_acq-TR${TR}_bold.${tempbreathext}"
done

#Rest
#Example filename: 2475376_session1_REST_645_RR
#BIDS filename: sub-2475376_ses-1_task-rest_acq-TR645_bold
#Breakdown rest scans into each TR
for TR in 645 1400 CAP; do 
for corrun in $(ls *REST_${TR}*); do
corrunfile="${corrun%.*}"
corrunfileext="${corrun##*.}"
Sessionnum=$(echo $corrunfile | cut -d '_' -f2)
sesnum=$(echo "${Sessionnum: -1}") 
if [ $sesnum == 2 ]; then 
ses=2
else
	ses=1
fi
if [ $TR == "CAP" ]; then
	TR=2500
else
	:
fi
mv ${corrunfile}.${corrunfileext} sub-${subj}_ses-${ses}_task-rest_acq-TR${TR}_bold.${corrunfileext}
echo "${corrun} changed to sub-${subj}_ses-${ses}_task-rest_acq-TR${TR}_bold.${corrunfileext}"
done
done

###Organize files into folders
for files in $(ls sub*); do 
Orgfile="${files%.*}"
Orgext="${files##*.}"
Modality=$(echo $Orgfile | rev | cut -d '_' -f1 | rev)
Sessionnum=$(echo $Orgfile | cut -d '_' -f2)
Difflast=$(echo "${Sessionnum: -1}")
if [[ $Modality == "bold" && $Difflast == 2 ]]; then
	mv ${Orgfile}.${Orgext} ses-2/func
else
if [[ $Modality == "bold" && $Difflast == 1 ]]; then
	mv ${Orgfile}.${Orgext} ses-1/func
fi 
fi
done

###Create events tsv files
##Create Checkerboard event file
#Checkerboard acq-TR645
#Generate Checkerboard acq-TR645 event tsv if it doesn't exist
if [ -e ${niidir}/task-Checkerboard_acq-TR645_events.tsv ]; then
	:
else
#Create events file with headers
echo -e onset'\t'duration'\t'trial_type > ${niidir}/task-Checkerboard_acq-TR645_events.tsv
#This file will be placed at the level where dataset_description file and subject folders are.
#The reason for this file location is because the event design is consistent across subjects.
#If the event design is consistent across subjects, we can put it at this level. This is because of the Inheritance principle.

#Create onset column
echo -e 0'\n'20'\n'40'\n'60'\n'80'\n'100 > ${niidir}/temponset.txt 

#Create duration column
echo -e 20'\n'20'\n'20'\n'20'\n'20'\n'20 > ${niidir}/tempdur.txt

#Create trial_type column
echo -e Fixation'\n'Checkerboard'\n'Fixation'\n'Checkerboard'\n'Fixation'\n'Checkerboard > ${niidir}/temptrial.txt

#Paste onset and duration into events file
paste -d '\t' ${niidir}/temponset.txt ${niidir}/tempdur.txt ${niidir}/temptrial.txt >> ${niidir}/task-Checkerboard_acq-TR645_events.tsv

#remove temp files
rm ${niidir}/tempdur.txt ${niidir}/temponset.txt ${niidir}/temptrial.txt
fi

##Checkerboard acq-TR1400
#Generate Checkerboard acq-TR1400 event tsv if it doesn't exist
if [ -e ${niidir}/task-Checkerboard_acq-TR1400_events.tsv ]; then
	:
else
#Because the checkerboard design is consistent across the different TRs
#We can copy the above event file and change the name 
cp ${niidir}/task-Checkerboard_acq-TR645_events.tsv ${niidir}/task-Checkerboard_acq-TR1400_events.tsv
fi

##Eye movement acq-TR645
#Generate eye movement acq-TR645 event tsv if it doesn't exist
if [ -e ${niidir}/task-eyemovement_acq-TR645_events.tsv ]; then
	:
else
#Create events file with headers
echo -e onset'\t'duration > ${niidir}/task-eyemovement_acq-TR645_events.tsv

#Creating duration first to help generate the onset file
#Create temponset file
onlength=$(cat /Users/franklinfeingold/Desktop/EyemovementCalibParadigm.txt | wc -l)
for ((i=2;i<=$((onlength-1));i++));
do
ontime=$(cat /Users/franklinfeingold/Desktop/EyemovementCalibParadigm.txt | sed "${i}q;d" | cut -d ',' -f1)
echo -e ${ontime} >> ${niidir}/temponset.txt
done
cp ${niidir}/temponset.txt ${niidir}/temponset2.txt
echo 108 >> ${niidir}/temponset2.txt #Eye calibration length is 108 seconds

#Generate tempdur file
durlength=$(cat ${niidir}/temponset2.txt | wc -l)
for ((i=1;i<=$((durlength-1));i++));
do
durtime=$(cat ${niidir}/temponset2.txt | sed $((i+1))"q;d")
onsettime=$(cat ${niidir}/temponset2.txt | sed "${i}q;d")
newdur=$(echo "$durtime - $onsettime"|bc)
echo "${newdur}" >> ${niidir}/tempdur.txt
done

#Paste onset and duration into events file
paste -d '\t' ${niidir}/temponset.txt ${niidir}/tempdur.txt >> ${niidir}/task-eyemovement_acq-TR645_events.tsv

#rm temp files
rm ${niidir}/tempdur.txt ${niidir}/temponset.txt ${niidir}/temponset2.txt 
fi

##Eye movement acq-TR1400
#Generate eye movement acq-TR1400 event tsv if it doesn't exist
if [ -e ${niidir}/task-eyemovement_acq-TR1400_events.tsv ]; then
	:
else
#Because the eye movement calibration is consistent across the different TRs
#We can copy the above event file and change the name
cp ${niidir}/task-eyemovement_acq-TR645_events.tsv ${niidir}/task-eyemovement_acq-TR1400_events.tsv
fi

##Breath hold acq-TR1400
#Generate breath hold acq-TR1400 event tsv if it doesn't exist
if [ -e ${niidir}/task-breathhold_acq-TR1400_events.tsv ]; then
	:
else
#Create events file with headers
echo -e onset'\t'duration > ${niidir}/task-breathhold_acq-TR1400_events.tsv

#Create duration column
#Creating duration first to help generate the onset file
dur1=10
dur2=2
dur3=3

#Create tempdur file
for ((i=1;i<=7;i++));
do
echo -e ${dur1}'\n'${dur2}'\n'${dur2}'\n'${dur2}'\n'${dur2}'\n'${dur3}'\n'${dur3}'\n'${dur3}'\n'${dur3}'\n'${dur3}'\n'${dur3} >> ${niidir}/tempdur.txt
done

#Create onset column
#Initialize temponset file
echo -e 0 > ${niidir}/temponset.txt

#Generate temponset file
durlength=$(cat ${niidir}/tempdur.txt | wc -l)
for ((i=1;i<=$((durlength-1));i++));
do
durtime=$(cat ${niidir}/tempdur.txt | sed "${i}q;d")
onsettime=$(cat ${niidir}/temponset.txt | sed "${i}q;d")
newonset=$((durtime+onsettime))
echo ${newonset} >> ${niidir}/temponset.txt
done

#Paste onset and duration into events file
paste -d '\t' ${niidir}/temponset.txt ${niidir}/tempdur.txt >> ${niidir}/task-breathhold_acq-TR1400_events.tsv

#rm temp files
rm ${niidir}/tempdur.txt ${niidir}/temponset.txt 
fi

###Check func json for required fields
#Required fields for func: 'RepetitionTime','VolumeTiming' or 'SliceTiming', and 'TaskName'
#capture all jsons to test
for sessnum in ses-1 ses-2; do
cd ${niidir}/sub-${subj}/${sessnum}/func #Go into the func folder
for funcjson in $(ls *.json); do 

#Repeition Time exist?
repeatexist=$(cat ${funcjson} | jq '.RepetitionTime')
if [[ ${repeatexist} == "null" ]]; then    
	echo "${funcjson} doesn't have RepetitionTime defined"
else
echo "${funcjson} has RepetitionTime defined"
fi

#VolumeTiming or SliceTiming exist?
#Constraint SliceTiming can't be great than TR
volexist=$(cat ${funcjson} | jq '.VolumeTiming')
sliceexist=$(cat ${funcjson} | jq '.SliceTiming')
if [[ ${volexist} == "null" && ${sliceexist} == "null" ]]; then
echo "${funcjson} doesn't have VolumeTiming or SliceTiming defined"
else
if [[ ${volexist} == "null" ]]; then
echo "${funcjson} has SliceTiming defined"
#Check SliceTiming is less than TR
sliceTR=$(cat ${funcjson} | jq '.SliceTiming[] | select(.>="$repeatexist")')
if [ -z ${sliceTR} ]; then
echo "All SliceTiming is less than TR" #The slice timing was corrected in the newer dcm2niix version called through command line
else
echo "SliceTiming error"
fi
else
echo "${funcjson} has VolumeTiming defined"
fi
fi

#Does TaskName exist?
taskexist=$(cat ${funcjson} | jq '.TaskName')
if [ "$taskexist" == "null" ]; then
jsonname="${funcjson%.*}"
taskfield=$(echo $jsonname | cut -d '_' -f2 | cut -d '-' -f2)
jq '. |= . + {"TaskName":"'${taskfield}'"}' ${funcjson} > tasknameadd.json
rm ${funcjson}
mv tasknameadd.json ${funcjson}
echo "TaskName was added to ${jsonname} and matches the tasklabel in the filename"
else
Taskquotevalue=$(jq '.TaskName' ${funcjson})
Taskvalue=$(echo $Taskquotevalue | cut -d '"' -f2)	
jsonname="${funcjson%.*}"
taskfield=$(echo $jsonname | cut -d '_' -f2 | cut -d '-' -f2)
if [ $Taskvalue == $taskfield ]; then
echo "TaskName is present and matches the tasklabel in the filename"
else
echo "TaskName and tasklabel do not match"
fi
fi

done
done

echo "${subj} complete!"

done


