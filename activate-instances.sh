
gcloud compute instances list
# loop thhrought INSTANCES_NAMES List and stop the instances
INSTANCES_NAMES=(c3-standard-4 c4-standard-4 n4-standard-4 e2-standard-4)
for VM_NAME in ${INSTANCES_NAMES[*]}
do
  gcloud compute instances start $VM_NAME 
done

gcloud compute instances list
