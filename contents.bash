#!/bin/bash

GITHUBRELEASEROOT=RELEASE/github

ACCOUNT=riscv-verification
NAME=RVVI

RELEASEDIR=${GITHUBRELEASEROOT}/${ACCOUNT}/${NAME}

# List of the source files
SRCFILES="
    githubSource/RVVI/README.md 
    githubSource/RVVI/RVVI-API/README.md 
    githubSource/RVVI/RVVI-TRACE/README.md 
    githubSource/RVVI/RVVI-VVP/README.md 
    githubSource/RVVI/diagrams/TestbenchForAdvancedRISC-VDesignVerification.png
    githubSource/RVVI/diagrams/InstructionRetirement.png
    githubSource/RVVI/diagrams/EnvironmentCallException.png
    githubSource/RVVI/diagrams/LoadAddressMisalignedTrap.png
    githubSource/RVVI/diagrams/MachineExternalInterruptTrap.png
    githubSource/RVVI/diagrams/MachineExternalInterrupt.png
    githubSource/RVVI/diagrams/InjectDebugModeEbreak.png
    githubSource/RVVI/diagrams/InjectDebugModeHaltreq.png
    githubSource/RVVI/diagrams/WFIMie1.png
    githubSource/RVVI/diagrams/WFIMie0.png
    ImpPublic/include/host/rvvi/rvviApi.h 
    ImpPublic/source/host/rvvi/rvvi.f 
    ImpPublic/source/host/rvvi/rvviTrace.sv 
    ImpPublic/source/host/rvvi/rvviApiPkg.sv" 

for s in ${SRCFILES}; do
    dst=$(echo $s | sed -e "s|ImpPublic/||" -e "s|ImpProprietary/||" -e "s|githubSource/${NAME}/||")
    echo "# $s -> ${RELEASEDIR}/${dst}"
    mkdir -p $(dirname ${RELEASEDIR}/${dst})
    cp $s ${RELEASEDIR}/${dst}
done

updateVersionForREADME() {
    file=$1
    ref=$2
    if [ "$file" != "" ]; then
        MAJOR=$(grep "parameter RVVI_${ref}_VERSION_MAJOR" ${file} | sed -e "s|.*RVVI_${ref}_VERSION_MAJOR.*=.\([0-9]*\);|\1|";grep "define RVVI_${ref}_VERSION_MAJOR"    ${file} | sed -e "s|.*RVVI_${ref}_VERSION_MAJOR \([0-9]*\)|\1|")
        MINOR=$(grep "parameter RVVI_${ref}_VERSION_MINOR" ${file} | sed -e "s|.*RVVI_${ref}_VERSION_MINOR.*=.\([0-9]*\);|\1|";grep "define RVVI_${ref}_VERSION_MINOR"    ${file} | sed -e "s|.*RVVI_${ref}_VERSION_MINOR \([0-9]*\)|\1|")
    else
        MAJOR=0
        MINOR=0
    fi
    echo "# Update RVVI-${ref}/README.md for version ${MAJOR}.${MINOR}"
    sed -i -e "s|__VERSIONMAJOR__|${MAJOR}|" -e "s|__VERSIONMINOR__|${MINOR}|" ${RELEASEDIR}/RVVI-${ref}/README.md 

    # also update top level README
    echo "# Update README.md for RVVI-${ref} version ${MAJOR}.${MINOR}"
    sed -i -e "s|__${ref}VERSIONMAJOR__|${MAJOR}|" -e "s|__${ref}VERSIONMINOR__|${MINOR}|" ${RELEASEDIR}/README.md 
}

# fixup Versions
updateVersionForREADME ImpPublic/source/host/rvvi/rvviApiPkg.sv API
updateVersionForREADME ImpPublic/source/host/rvvi/rvviTrace.sv  TRACE
updateVersionForREADME ""                                       VVP
