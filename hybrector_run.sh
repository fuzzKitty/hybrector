#!/bin/bash

# SETTING UP THE ENVIRONMENT
# Reference colours table
# Black        0;30     Dark Gray     1;30
# Red          0;31     Light Red     1;31
# Green        0;32     Light Green   1;32
# Brown/Orange 0;33     Yellow        1;33
# Blue         0;34     Light Blue    1;34
# Purple       0;35     Light Purple  1;35
# Cyan         0;36     Light Cyan    1;36
# Light Gray   0;37     White         1;37

# Colour coding rough guidelines:
# CYAN for messages
# PURPLE for operations
# WHITE for runtime criticals
# GREEN for good
# YELLOW for neutral
# RED for bad

RED='\033[1;31m' #RED colour
PURPLE='\033[1;35m' #PURPLE colour
CYAN='\033[1;36m' #CYAN colour
YELLOW='\033[1;33m' #YELLOW colour
GREEN='\033[1;32m' #GREEN colour
NC='\033[0m' #NO colour

# CHECK IF ARG PASSED
if [ -z $1 ]; then
	echo -e ""
	echo -e "${CYAN}WELCOME${NC} to ${GREEN}hybrector${NC}!!!"
	echo -e "To run hybrector, pass an APK or IPA file as argument"
	echo -e "e.g.: ${YELLOW}./hybrector.sh foo.apk${NC} ...or... ${PURPLE}./hybrector.sh bar.ipa${NC}"
	echo -e ""
	exit 1
 fi

name="$(echo $1)"
unpacked_dir=./unpacked/
ls_logs_file=ls_logs.txt

rm -rf $unpacked_dir
rm -rf $ls_logs_file
mkdir $unpacked_dir

echo -e ""
echo -e "[${PURPLE}***${NC}] Analysing $name ..."
#echo -e ""


#DETECTING PLATFORM
file_type="null"
platform="null"

if [[ $name = *apk* ]]; then
	file_type="apk"
	platform="Android"
	echo -e "[${YELLOW}***${NC}] $platform detected"
	echo -e ""

elif [[ $name = *ipa* ]]; then
	file_type="ipa"
	platform="iOS"
	echo -e "[${YELLOW}***${NC}] $platform detected"
	echo -e ""

else
	echo -e "[${WHITE}***${NC}] ${RED}INVALID file type! Terminating...${NC}"
	echo -e ""
	exit 1

fi


# UNPACKING
if [[ $file_type = "apk" ]]; then
	echo -e "[${PURPLE}***${NC}] Unpacking ..."
	apktool d $name -f --output $unpacked_dir
	echo -e ""

elif [[ $file_type = "ipa" ]]; then
	echo -e "[${PURPLE}***${NC}] Unpacking ..."
	unzip -q $name -d $unpacked_dir
	echo -e ""

fi


#LOGGING DIRS TREE
echo -e "[${PURPLE}***${NC}] Logging directories tree ..."
ls -R $unpacked_dir > $ls_logs_file
echo -e "[${CYAN}***${NC}] ls_logs.txt created"
echo -e ""


#FW DETECTION
#DIRS TREE BASED DETECTION
fw_detected_flag=false
detected_fw="null"

if grep -q -i "cordova" $ls_logs_file; then
	fw_detected_flag=true
	detected_fw="cordova"
	echo -e "[${YELLOW}***${NC}] FW detection -> $detected_fw signs found"
	echo -e ""
fi

if grep -q -i "ionic" $ls_logs_file || grep -q -i -E "\d+\.js" $ls_logs_file; then
	fw_detected_flag=true
	detected_fw="ionic"
	echo -e "[${YELLOW}***${NC}] FW detection -> $detected_fw signs found"
	echo -e ""
fi

if grep -q -i "index.android.bundle" $ls_logs_file || grep -q -i "index.ios.bundle" $ls_logs_file; then
	fw_detected_flag=true
	detected_fw="react_native"
	echo -e "[${YELLOW}***${NC}] FW detection -> $detected_fw signs found"
	echo -e ""
fi

if grep -q -i "flutter" $ls_logs_file; then
	fw_detected_flag=true
	detected_fw="flutter"
	echo -e "[${YELLOW}***${NC}] FW detection -> $detected_fw signs found"
	echo -e ""
fi

if [ $fw_detected_flag = false ]; then
	echo -e "[${YELLOW}***${NC}] FW detection -> NO hybrid framework detected"
	echo -e "[${YELLOW}***${NC}] FW detection -> Unknown framework or Native app"
	echo -e ""
fi


#===APK SPECIFIC HANDLING===
if [[ $file_type = "apk" ]]; then

	echo -e "[${CYAN}***${NC}] Proceeding with $platform specific analysis ..."

	#MANIFEST ANALYSIS
	manifest_path=$(find . -iname AndroidManifest.xml)
	echo -e "[${CYAN}***${NC}] Manifest path -> $manifest_path"
	echo -e "[${PURPLE}***${NC}] Analysing Android manifest file"

	#android:debuggable
	if grep -q -io 'android:debuggable="true"' $manifest_path; then
		echo -e "[${RED}***${NC}] {${RED}BAD${NC}} Manifest analysis -> android:debuggable set to ${RED}TRUE${NC}"
	elif grep -q -io 'android:debuggable="false"' $manifest_path; then
		echo -e "[${GREEN}***${NC}] {${GREEN}GOOD${NC}} Manifest analysis -> android:debuggable set to FALSE"
	else
		echo -e "[${GREEN}***${NC}] {${GREEN}GOOD${NC}} Manifest analysis -> android:debuggable NOT SET; default is FALSE"
	fi

	#android:allowBackup
	if grep -q -io 'android:allowBackup="true"' $manifest_path; then
		echo -e "[${RED}***${NC}] {${RED}BAD${NC}} Manifest analysis -> android:allowBackup set to ${RED}TRUE${NC}"
	elif grep -q -io 'android:allowBackup="false"' $manifest_path; then
		echo -e "[${GREEN}***${NC}] {${GREEN}GOOD${NC}} Manifest analysis -> android:allowBackup set to FALSE"
	else
		echo -e "[${RED}***${NC}] {${RED}BAD${NC}} Manifest analysis -> android:allowBackup ${RED}NOT SET${NC}; default is ${RED}TRUE${NC}"
	fi

	#android:protectionLevel
	if grep -q -io 'android:protectionLevel="signature"' $manifest_path; then
		echo -e "[${RED}***${NC}] {${RED}BAD${NC}} Manifest analysis -> android:protectionLevel set as ${RED}signature${NC}"
	elif grep -q -io 'android:protectionLevel="signatureOrSystem"' $manifest_path; then
		echo -e "[${RED}***${NC}] {${RED}BAD${NC}} Manifest analysis -> android:protectionLevel set as ${RED}signatureOrSystem${NC}"
	else
		echo -e "[${GREEN}***${NC}] {${GREEN}GOOD${NC}} Manifest analysis -> no excessive android:protectionLevel detected"
	fi

	echo -e ""

fi


#===IPA SPECIDIC HANDLING===
if [[ $file_type = "ipa" ]]; then

	echo -e "[${PURPLE}***${NC}] Proceeding with $platform specific analysis ..."
	echo -e "iOS WIP"
	echo -e ""

	#OTOOL CHECKS
	otool -Vh $name
	otool -I -v $name | grep stack_chk_guard)
	otool -I -v $name | grep _objc_release)

fi
