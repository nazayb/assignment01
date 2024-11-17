#!/bin/bash

# File paths for results
NATIVE_RESULTS="n1-native-results.csv"
DOCKER_RESULTS="n1-docker-results.csv"
KVM_RESULTS="n1-kvm-results.csv"
QEMU_RESULTS="n1-qemu-results.csv"

# Ensure CSV files exist and have a header
for file in $NATIVE_RESULTS $DOCKER_RESULTS $KVM_RESULTS $QEMU_RESULTS; do
    if [ ! -f "$file" ]; then
        echo "time,cpu,mem,diskRand,diskSeq" > "$file"
    fi
done

# Function to execute benchmarks
run_benchmark() {
    local platform=$1
    local output_file=$2

    echo "Running benchmark for $platform..."

    case $platform in
        native)
            ./benchmark.sh >> "$output_file" 2>/dev/null
            ;;
        docker)
            docker run --rm benchmark-image >> "$output_file" 2>/dev/null
            ;;
        kvm)
            ssh -o StrictHostKeyChecking=no user@kvm-vm './benchmark.sh' >> "$output_file" 2>/dev/null
            ;;
        qemu)
            ssh -o StrictHostKeyChecking=no user@qemu-vm './benchmark.sh' >> "$output_file" 2>/dev/null
            ;;
    esac

    echo "Benchmark for $platform completed."
}

# Execute benchmarks for all platforms
run_benchmark native $NATIVE_RESULTS
run_benchmark docker $DOCKER_RESULTS
run_benchmark kvm $KVM_RESULTS
run_benchmark qemu $QEMU_RESULTS

# Add the script to cron for periodic execution
if ! crontab -l | grep -q "$(pwd)/execute-experiments.sh"; then
    echo "Adding cron job for periodic execution..."
    (crontab -l 2>/dev/null; echo "*/30 * * * * $(pwd)/execute-experiments.sh") | crontab -
fi

echo "Benchmarks are running. Results will be saved in CSV files."
