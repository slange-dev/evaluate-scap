#!/usr/bin/env bash
########################################################################################
## This script evaluates the SCAP profile rules from the scap-security-guide v0.1.74, ##
## downloaded from github (https://github.com/ComplianceAsCode/content)               ##
## The script generates a "remediation" script and guide for each profile             ##
##                                                                                    ##
## Usage: ./evaluate_scap_0.1.74.sh >> scap_0.1.74.log 2>> scap_0.1.74.log &          ##
########################################################################################

## Scap-security-guide version
VERSION=0.1.74

## OS Version
# Rocky Linux 9 (missed in v0.1.73)
#OS=rl9

# Redhat Linux 9
OS=rhel9

# Create directory
##
TARGETDIR=/root/openscap_data

if [ ! -d "$TARGETDIR" ]; then
  ##
  mkdir -p $TARGETDIR
fi

## Hostname
HOST=$(hostname)

## Date
DATE=$(date +%F)

#######################################
## Download profile from remote site ##
#######################################

## Use content from download
CONTENT=${TARGETDIR}/scap-security-guide-${VERSION}

## Check if wget is installed
if [ -x "$(command -v wget)" ]; then

  ## Download scap-security-guide with wget
  wget https://github.com/ComplianceAsCode/content/releases/download/v${VERSION}/scap-security-guide-${VERSION}.zip -P ${TARGETDIR}

  ## Set
  CURL=0
else

  ## Set
  CURL=1

fi

## Check if cURL is installed
if [ -x "$(command -v curl)" ] && [ $CURL -eq 1 ]; then

  ## Download scap-security-guide with cURL
  curl -o ${TARGETDIR}/scap-security-guide-${VERSION}.zip -L https://github.com/ComplianceAsCode/content/releases/download/v${VERSION}/scap-security-guide-${VERSION}.zip
else

  ##
  sudo dnf install curl -y

  ## Download scap-security-guide with cURL
  curl -o ${TARGETDIR}/scap-security-guide-${VERSION}.zip -L https://github.com/ComplianceAsCode/content/releases/download/v${VERSION}/scap-security-guide-${VERSION}.zip
fi

## Check if unzip is installed
if [ -x "$(command -v unzip)" ]; then

  ## Unzip scap-security-guide
  unzip -o ${TARGETDIR}/scap-security-guide-${VERSION}.zip -d ${TARGETDIR}
else

  ## Install unzip
  sudo dnf install unzip -y

  ## Unzip scap-security-guide
  unzip -o ${TARGETDIR}/scap-security-guide-${VERSION}.zip -d ${TARGETDIR}
fi

## To extract the list of profiles
oscap info --fetch-remote-resources ${CONTENT}/ssg-${OS}-ds.xml | grep profile | sed 's+.*profile_++'

## The following array processes all available profiles, comment out the ones that are not needed
PARRAY=(
  #################
  ## rhel9 / rl9 ##
  #################
  # oscap info "/usr/share/xml/scap/ssg/content/ssg-rl9-ds.xml"
  # oscap info "/usr/share/xml/scap/ssg/content/ssg-rhel9-ds.xml"

  ## Generated: 2024-04-08

  # ANSSI-BP-028 (enhanced)
  #anssi_bp28_enhanced

  # ANSSI-BP-028 (high)
  #anssi_bp28_high

  # ANSSI-BP-028 (intermediary)
  #anssi_bp28_intermediary

  # ANSSI-BP-028 (minimal)
  #anssi_bp28_minimal

  # CCN Red Hat Enterprise Linux 9 - Advanced
  #ccn_advanced

  # CCN Red Hat Enterprise Linux 9 - Basic
  #ccn_basic

  # CCN Red Hat Enterprise Linux 9 - Intermediate
  #ccn_intermediate

  # CIS Red Hat Enterprise Linux 9 Benchmark for Level 2 - Server
  #cis

  # CIS Red Hat Enterprise Linux 9 Benchmark for Level 1 - Server
  #cis_server_l1

  # CIS Red Hat Enterprise Linux 9 Benchmark for Level 1 - Workstation
  #cis_workstation_l1

  # CIS Red Hat Enterprise Linux 9 Benchmark for Level 2 - Workstation
  #cis_workstation_l2

  # DRAFT - Unclassified Information in Non-federal Information Systems and Organizations (NIST 800-171)
  ## Committee on National Security Systems Instruction (CNSSI) No. 1253, Security
  ## Categorization and Control Selection for National Security Systems on security
  ## controls to meet low confidentiality, low integrity, and low assurance.
  #cui

  # Australian Cyber Security Centre (ACSC) Essential Eight
  #e8

  # Health Insurance Portability and Accountability Act (HIPAA)
  #hipaa

  # Australian Cyber Security Centre (ACSC) ISM Official
  #ism_o

  # Protection Profile for General Purpose Operating Systems
  #ospp

  # PCI-DSS v4.0 Control Baseline for Red Hat Enterprise Linux 9
  #pci-dss

  # DISA STIG for Red Hat Enterprise Linux 9
  #stig

  # DISA STIG with GUI for Red Hat Enterprise Linux 9
  stig_gui
)

##
for PROFILE in "${PARRAY[@]}"; do

  ## Display the profile
  printf "\n#### %s ####\n\n" "${PROFILE}"

  ## Evaluate each profile against oval downloaded from RedHat
  oscap xccdf eval --fetch-remote-resources --profile xccdf_org.ssgproject.content_profile_"${PROFILE}" \
    --results "${TARGETDIR}"/"${HOST}"-"${DATE}"-"${PROFILE}".xml \
    --report "${TARGETDIR}"/"${HOST}"-"${DATE}"-"${PROFILE}".html \
    "${CONTENT}"/ssg-"${OS}"-ds.xml

  ## Generate remediation script for each profile
  oscap xccdf generate fix --template urn:xccdf:fix:script:sh \
    --profile xccdf_org.ssgproject.content_profile_"${PROFILE}" \
    --output "${TARGETDIR}"/remediation-"${HOST}"-"${DATE}"-"${PROFILE}".sh \
    "${CONTENT}"/ssg-${OS}-ds.xml

  ## Generate Guide for each profile
  oscap xccdf generate guide --profile xccdf_org.ssgproject.content_profile_"${PROFILE}" \
    --output "${TARGETDIR}"/scap-security-guide-"${VERSION}"-"${HOST}"-"${DATE}"-"${PROFILE}".html \
    "${CONTENT}"/ssg-${OS}-ds.xml
done

## Create tar with all results, scripts, guides, etc.
tar -cvzf "${HOST}"-"${DATE}"-scap_"${VERSION}".tar.gz "${TARGETDIR}"/"${HOST}"/"${HOST}"-"${DATE}"-*.xml "${TARGETDIR}"/"${HOST}"/"${HOST}"-"${DATE}"-*.html "${TARGETDIR}"/"${HOST}"/remediation-"${HOST}"-"${DATE}"-*.sh "${TARGETDIR}"/"${HOST}"/scap-security-guide-"${VERSION}"-"${HOST}"-"${DATE}"-*.html
