# FOR MAC
# brew update 
# brew install sysbench
#####

## FOR linux (check if to install sysbench)
#if ! command -v sysbench &> /dev/null; then
#    echo "Installing sysbench..."
#    sudo apt update && sudo apt install -y sysbench
#fi

## FOR Linux (no check)
# sudo apt update && sudo apt install -y sysbench

#TODO read time

TIME=$(date +%s)

# Benchmark CPU
# sysbench cpu run --time=$TIME
CPU=$(sysbench cpu run --time=60 | grep "events (avg/stddev):" | awk '{print $3}')
echo $CPU

# Benchmark Memory
MEMORY=$(sysbench memory run --time=60 --memory-block-size=4KB --memory-total-size=100TB | grep "MiB transferred" | awk '{print $4}')
echo $memory

# Random Access Disk Benchmark
#Preparing files
sysbench fileio --file-num=1 --file-total-size=1GB --file-test-mode=rndrd  prepare
# Runing FILEIO speed test greeping read/s printing second argument
FILEIORND=$(sysbench fileio --file-num=1 --file-total-size=1GB --file-test-mode=rndrd --time=60 run  | grep "reads/s:" | awk '{print $2}')
echo $FILEIORND


# Sequential Disk Benchmark
#Preparing files
sysbench fileio --file-num=1 --file-total-size=1GB --file-test-mode=seqrd  prepare
# Runing FILEIO speed test greeping read/s printing second argument
FILEIOSEQ=$(sysbench fileio --file-num=1 --file-total-size=1GB --file-test-mode=seqrd --time=60 run  | grep "reads/s:" | awk '{print $2}')
echo $FILEIOSEQ




echo "TIME, CPU, MEMORY, FILEIORND, FILEIOSEQ"
echo "$TIME, $CPU, $MEMORY, $FILEIORND, $FILEIOSEQ"


sysbench fileio --file-block-size=1 --file-total-size=1GB --file-test-mode=rndrd --time=60 cleanup
sysbench fileio --file-block-size=1 --file-total-size=1GB --file-test-mode=seqrd --time=60 cleanup

