#!/bin/bash

# Function to check if a command was successful
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: $1 failed"
        exit 1
    fi
}

# Prepare result files with CSV headers
for platform in native docker kvm qemu; do
    echo "time,cpu,mem,diskRand,diskSeq" > "$(hostname)-${platform}-results.csv"
done

# Function to run benchmark and append results
run_benchmark() {
    local platform=$1
    local command=$2
    
    echo "Running benchmark on $platform"
    result=$(eval $command)
    check_command "Benchmark on $platform"
    
    echo "$result" >> "$(hostname)-${platform}-results.csv"
}

# Run benchmarks
for i in {1..48}; do
    timestamp=$(date +%s)
    
    # Native benchmark
    run_benchmark "native" "./benchmark.sh"
    
    # Docker benchmark
    run_benchmark "docker" "sudo docker run --rm benchmark"
    
    # KVM benchmark
    run_benchmark "kvm" "ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no ubuntu@kvm-instance './benchmark.sh'"
    
    # QEMU benchmark
    run_benchmark "qemu" "ssh -i ~/.ssh/id_rsa -o StrictHostKeyChecking=no -p 2222 ubuntu@localhost './benchmark.sh'"
    
    # Wait for 30 minutes before next iteration
    if [ $i -lt 48 ]; then
        sleep 1800
    fi
done

echo "All benchmarks completed."
