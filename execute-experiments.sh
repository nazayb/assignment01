#!/bin/bash

# Add this at the beginning of the run_all_benchmarks function
echo "$(date): Starting benchmarks for $1" >> /tmp/benchmark_log.txt

# Function to run benchmark and append results to CSV
run_benchmark() {
    local platform=$1
    local output_file="${platform}-results.csv"
    
    # Create CSV header if file doesn't exist
    if [ ! -f "$output_file" ]; then
        echo "time,cpu,mem,diskRand,diskSeq" > "$output_file"
    fi
    
    # Run benchmark and append results
    case $platform in
        native)
            ./benchmark.sh >> "$output_file"
            ;;
        docker)
            docker run --rm benchmark >> "$output_file"
            ;;
        kvm)
            ssh -o StrictHostKeyChecking=no kvm-vm './benchmark.sh' >> "$output_file"
            ;;
        qemu)
            ssh -o StrictHostKeyChecking=no qemu-vm './benchmark.sh' >> "$output_file"
            ;;
    esac
}

# Run benchmarks for all platforms
run_all_benchmarks() {
    local vm_type=$1
    run_benchmark "${vm_type}-native"
    run_benchmark "${vm_type}-docker"
    run_benchmark "${vm_type}-kvm"
    run_benchmark "${vm_type}-qemu"
}

# Set up cron job
setup_cron() {
    (crontab -l 2>/dev/null; echo "*/30 * * * * $(pwd)/execute-experiments.sh run") | crontab -
}

# Main execution
case $1 in
    run)
        # Determine VM type based on hostname or instance metadata
        vm_type=$(curl -s "http://metadata.google.internal/computeMetadata/v1/instance/machine-type" -H "Metadata-Flavor: Google" | awk -F/ '{print $NF}')
        case $vm_type in
            c3-standard-4) vm_prefix="c3" ;;
            c4-standard-4) vm_prefix="c4" ;;
            n4-standard-4) vm_prefix="n4" ;;
            *) echo "Unknown VM type"; exit 1 ;;
        esac
        run_all_benchmarks $vm_prefix
        ;;
    setup)
        setup_cron
        ;;
    *)
        echo "Usage: $0 {run|setup}"
        exit 1
        ;;
esac
