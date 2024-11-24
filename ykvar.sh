#!/bin/bash

has_v_option=false
has_n_option=false
fifty_chance=$(($RANDOM % 2))
is_as_root=$(($UID == 0))
HELPER="\nAvailable options for the ykvar script. \n\n  -h           Lists all available options \n\n  -v           Displays more on what the script is doing \n\n  -n           Installs yq command line tool, required if not installed! Needs Elevated Privileges \n\n----------------------------------------- \n\nUsage: \n\n Run 'chmod +x ykvar.sh' to make executable \n\n ykvar script takes variables: \n  WNODENAME        worker node name, \n  DATASTORAGE      '###Gi' allocation (in GB), \n  DATAPATH         /mnt/path/for/data, \n  MEDIASTORAGE     '###Gi' allocation (in GB), \n  MEDIAPATH        /mnt/path/for/media \n\n ykvar.sh [OPTIONS(-h, -v, -n)] \n"

# Sets up the ability for options/flags
while getopts :hvnt flag; do
    case $flag in 
        h) echo -e "$HELPER"; exit ;;
        v) has_v_option=true ;;
        n) has_n_option=true ;;
       \?) echo -e "\nUnknown option -$OPTARG"; echo -e "$HELPER"; exit 1;;
    esac
done

# Disposes/Clears any previous options
shift $(( OPTIND - 1 ))

### This script installs the yq YAML processor tool and swaps all of the variable values with the values of the environmental variables set
if $has_n_option && [ $is_as_root -eq 1 ] ; then
  wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq
elif $has_n_option && [ $is_as_root -eq 0 ] ; then
  echo -e "Required Elevated Privileges \n" && sudo wget -q https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/bin/yq && chmod +x /usr/bin/yq
fi

if $has_v_option ; then
    echo -e "\nSTATUS MESSAGE              ENV                    VALUE \n"
elif [ $fifty_chance -eq 1 ] && !$has_v_option ; then
    echo -e "Tip: Use the "-v" option to see verbose output"
fi

### Changes the nodeSelector value for the deployment file
if [ -z "$WNODENAME" ] && $has_v_option ; then
  echo -e "node name missing!          WNODENAME:             $WNODENAME- \n..."
elif yq -i ".spec.template.spec.nodeSelector.[\"kubernetes.io/hostname\"] = strenv(WNODENAME)" ./k8s/deployments/jellyfindeploy.yaml && $has_v_option ; then
  echo -e "nodeSelector set!           WNODENAME:             $WNODENAME \n..."
elif $has_v_option ; then
  echo -e "__in nodeSelector.          WNODENAME:             $WNODENAME \n..."
fi

### Changes the pv and pvc configs for the DATA volume
if [ -z "$DATASTORAGE" ] && $has_v_option ; then
  echo -e "data storage missing!       DATASTORAGE:           $DATASTORAGE- \n..."
elif yq -i ".spec.resources.requests.storage = strenv(DATASTORAGE)" ./k8s/pvclaims/pvc-data.yaml && yq -i ".spec.capacity.storage = strenv(DATASTORAGE)" ./k8s/pvolumes/pv-data.yaml && $has_v_option ; then
  echo -e "data storage set!           DATASTORAGE:           $DATASTORAGE \n..."
elif $has_v_option ; then
  echo -e "__in data storage           DATASTORAGE:           $DATASTORAGE \n..."
fi

if [ -z "$DATAPATH" ] && $has_v_option ; then
  echo -e "data path missing!          DATAPATH:              $DATAPATH- \n..."
elif yq -i ".spec.hostPath.path = strenv(DATAPATH)" ./k8s/pvolumes/pv-data.yaml && $has_v_option ; then
  echo -e "data path set!              DATAPATH:              $DATAPATH \n..."
elif $has_v_option ; then
  echo -e "__in data path.             DATAPATH:              $DATAPATH \n..."
fi

### Changes the pv and pvc configs for the MEDIA volume
if [ -z "$MEDIASTORAGE" ] && $has_v_option ; then
  echo -e "media storage missing!      MEDIASTORAGE:          $MEDIASTORAGE- \n..."
elif yq -i ".spec.resources.requests.storage = strenv(MEDIASTORAGE)" ./k8s/pvclaims/pvc-media.yaml && yq -i ".spec.capacity.storage = strenv(MEDIASTORAGE)" ./k8s/pvolumes/pv-media.yaml && $has_v_option ; then
  echo -e "media storage set!          MEDIASTORAGE:          $MEDIASTORAGE \n..."
elif $has_v_option ; then
  echo -e "__in media storage.         MEDIASTORAGE:          $MEDIASTORAGE \n..."
fi

if [ -z "$MEDIAPATH" ] && $has_v_option ; then
  echo -e "media path missing!         MEDIAPATH:             $MEDIAPATH- \n..."
elif yq -i ".spec.hostPath.path = strenv(MEDIAPATH)" ./k8s/pvolumes/pv-media.yaml && $has_v_option ; then
  echo -e "media path set!             MEDIAPATH:             $MEDIAPATH \n..."
elif $has_v_option ; then
  echo -e "__in media path.            MEDIAPATH:             $MEDIAPATH \n..."
fi

echo -e "Done \n"