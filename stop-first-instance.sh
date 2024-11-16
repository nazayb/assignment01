
gcloud compute instances list
# loop thhrought INSTANCES_NAMES List and stop the instances
INSTANCES_NAMES=(c3-standard-4)
for VM_NAME in ${INSTANCES_NAMES[*]}
do
  gcloud compute instances stop $VM_NAME 
done

gcloud compute instances list
