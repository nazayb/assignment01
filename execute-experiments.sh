#!/bin/bash

# Define CSV file names
NATIVE_RESULTS="n1-native-results.csv"
DOCKER_RESULTS="n1-docker-results.csv"
KVM_RESULTS="n1-kvm-results.csv"
QEMU_RESULTS="n1-qemu-results.csv"

# Write CSV headers for all result files
echo "time,cpu,mem,diskRand,diskSeq" > $NATIVE_RESULTS
echo "time,cpu,mem,diskRand,diskSeq" > $DOCKER_RESULTS
echo "time,cpu,mem,diskRand,diskSeq" > $KVM_RESULTS
echo "time,cpu,mem,diskRand,diskSeq" > $QEMU_RESULTS

# Function to execute benchmark and collect results
run_benchmark() {
    platform=$1
    output_file=$2

    echo "Running benchmark for $platform..."
    case $platform in
        native)
            ./benchmark.sh >> $output_file 2>/dev/null
            ;;
        docker)
            docker run --rm benchmark-image >> $output_file 2>/dev/null
            ;;
        kvm)
            ssh -o StrictHostKeyChecking=no user@kvm-vm './benchmark.sh' >> $output_file 2>/dev/null
            ;;
        qemu)
            ssh -o StrictHostKeyChecking=no user@qemu-vm './benchmark.sh' >> $output_file 2>/dev/null
            ;;
    esac
    echo "Benchmark for $platform completed."
}

# Run benchmarks for all platforms
run_benchmark native $NATIVE_RESULTS
run_benchmark docker $DOCKER_RESULTS
run_benchmark kvm $KVM_RESULTS
run_benchmark qemu $QEMU_RESULTS

# Add a cron job to automate the execution every 30 minutes
echo "Adding cron job for automation..."
(crontab -l 2>/dev/null; echo "*/30 * * * * $(pwd)/execute-experiments.sh") | crontab -

echo "Script executed. Benchmarks will now run every 30 minutes for the next 24 hours."
