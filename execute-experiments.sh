#Create four CSV files, each with a header:
#time,cpu,mem,diskRand,diskSeq

echo "time,cpu,mem,diskRand,diskSeq" > n1-native-results.csv
echo "time,cpu,mem,diskRand,diskSeq" > n1-docker-results.csv
# Repeat for other platforms and instances.

#1- Run the benchmark script natively on the GCP VM:
#Run the benchmark script natively on the GCP VM
./benchmark.sh >> n1-native-results.csv

#2-Run the benchmark in a Docker container:
#Start the Docker container with the benchmark script:
docker run --rm your-docker-image >> n1-docker-results.csv

#3-Run the benchmark on Qemu + KVM:
#SSH into the Qemu + KVM VM and execute the benchmark script:
ssh user@qemu-kvm-vm 'bash -s' < ./benchmark.sh >> n1-kvm-results.csv

#4-Run the benchmark on Qemu with dynamic binary translation:
#ssh user@qemu-vm 'bash -s' < ./benchmark.sh >> n1-qemu-results.csv
ssh user@qemu-vm 'bash -s' < ./benchmark.sh >> n1-qemu-results.csv

crontab -e
*/30 * * * * /path/to/execute-experiments.sh
chmod +x execute-experiments.sh

python3 plot.py




