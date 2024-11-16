# Before runing this script:
# 1. Make sure that you are authenticated in gcloud/ run gcloud init
# 2. Make sure that the correct project is set in config file of gcloud cli
# 3. Make sure that billing is enabled on the project: https://console.cloud.google.com/billing/projects
# 4. make sure that compute.googleapis.com is enabled on the project!
# TODO set the project variable in the config ??
#

echo 'Provide USERNAME'
USERNAME=nazayb
# read USERNAME
 KEY_FILENAME=$USERNAME
 PROJECT_NAME='projectnazay'



# Creating ssh key and coping the public key to the cwd
ssh-keygen -t rsa -f ~/.ssh/$KEY_FILENAME -C $USERNAME -N ""
cat ~/.ssh/$KEY_FILENAME.pub > ./$KEY_FILENAME.pub




# uploading the ssh key to the project
echo Y | gcloud compute os-login ssh-keys add \
   --key-file=./$KEY_FILENAME.pub \
   --project=$PROJECT_NAME \


# Creating the firewall rule for incomin ssh and icmp connection
gcloud compute firewall-rules create incoming \
  --description="Allow incoming traffic on TCP port 80 for ssh and icmp" \
  --allow=tcp:20,icmp \
  --direction=INGRESS \
  --target-tags=cc

# loop thhrought INSTANCES_NAMES List and intanciate the instances
INSTANCES_NAMES=(c3-standard-4 c4-standard-4 n4-standard-4)
for VM_NAME in ${INSTANCES_NAMES[*]}
do
  gcloud compute instances create $VM_NAME \
 --machine-type=$VM_NAME \
  --image=ubuntu-2004-focal-v20241016  \
  --image-project=ubuntu-os-cloud \
  --zone=europe-west1-c	 \
  --tags=cc \
  --enable-nested-virtualization \
  --boot-disk-size=100GB
done

gcloud compute instances list

# VM_NAME=c3-standard-4 \
# gcloud compute instances create $VM_NAME \
#  --machine-type=$VM_NAME \
#   --image=ubuntu-2004-focal-v20241016  \
#   --image-project=ubuntu-os-cloud \
#   --zone=europe-west1-c	 \
#   --tags=cc \
#   --enable-nested-virtualization \
#   --boot-disk-size=100GB


# gcloud compute instances create letsgo \
# --image=ubuntu-2004-focal-v20241016  \
# --image-project=ubuntu-os-cloud \
# --zone=europe-west1-c	 \
# --tags=cc \
# --enable-nested-virtualization \
# --boot-disk-size=100GB


# TODO set the project in the config 
# ret=$(echo Y | gcloud compute os-login ssh-keys add \
#    --key-file=./$KEY_FILENAME.pub \
#    --project=$PROJECT_NAME \
#    --format="json"
#  )
#
#
# echo
# echo $ret | grep $PROJECT_NAME
   
# deletes the project
# echo y | gcloud projects delete $PROJECT_NAME


# pr=$(echo 'shiiiit')
# echo "fuck"
# echo $pr

# if [[ $pr =~ "already in use" ]]; 
# then
#   echo 'Already there'
# else
#   echo 'Created new project'
#   echo $pr
# fi




