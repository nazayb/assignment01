#!/bin/bash

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
            ./benchmark.sh >> "$output_file" 2>/dev/null
            ;;
        docker)
            docker run --rm benchmark >> "$output_file" 2>/dev/null
            ;;
        kvm)
            ssh kvm-vm './benchmark.sh' >> "$output_file" 2>/dev/null
            ;;
        qemu)
            ssh qemu-vm './benchmark.sh' >> "$output_file" 2>/dev/null
            ;;
    esac
}

# Run benchmarks for all platforms
run_all_benchmarks() {
    run_benchmark "native"
    run_benchmark "docker"
    run_benchmark "kvm"
    run_benchmark "qemu"
}

# Set up cron job
setup_cron() {
    (crontab -l 2>/dev/null; echo "*/30 * * * * $(pwd)/execute-experiments.sh run") | crontab -
}

# Main execution
case $1 in
    run)
        run_all_benchmarks
        ;;
    setup)
        setup_cron
        ;;
    *)
        echo "Usage: $0 {run|setup}"
        exit 1
        ;;
esac
