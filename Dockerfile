# Use Ubuntu 22.04 as the base image
FROM ubuntu:22.04

# Update package lists and install sysbench
RUN apt-get update && apt-get install -y sysbench

# Copy the benchmark script into the container
COPY benchmark.sh /benchmark.sh

# Make the benchmark script executable
RUN chmod +x /benchmark.sh

# Set the benchmark script as the default command to run when the container starts
CMD ["/benchmark.sh"]
