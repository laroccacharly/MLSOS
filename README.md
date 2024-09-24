# MLSOS
The goal of the project is to accelerate the discovery of solutions for MIPs with SOS1 constraints. The methodology called Probe and Freeze (PNF) uses a data-driven tools to predict the solution in a one-shot fashion. For an overview, see the jopt2023.pdf in the docs folder. 

Link to published paper: https://link.springer.com/article/10.1007/s43069-024-00336-6

Note: The code for the locomotive assignment problem was removed for confidentiality reasons. This codebase only supports MIPLIB instances. 


# Installation 
The project runs inside Docker. The image is built using the Dockerfile file. The main dependencies are Julia, MIPLIB and CPLEX. First, download the CPLEX binaries (linux-x86-64.bin) from IBM and place them in the deps folder.

```
mkdir deps
cp $CPLEX_PATH/cplex_studio1210.linux-x86-64.bin deps/cplex.bin
```
Build the image: 
```
export IMAGE_PREFIX="local" # or your dockerhub username
export IMAGE_NAME=$IMAGE_PREFIX/mlsos:1.0 
docker build -f Dockerfile -t $IMAGE_NAME . 
```
Build the container: 
```
export CONTAINER_NAME=mlsos
export SRC_PATH=$PWD
export FOLDER_NAME=MLSOS
export LOCAL_MIPLIB_PATH=path/to/miplib # Download from https://miplib.zib.de/downloads/collection.zip. Unzip and place in the LOCAL_MIPLIB_PATH. 
export CONTAINER_MIPLIB_PATH=/home/$FOLDER_NAME/raw_data/miplib_data
docker run -d --name $CONTAINER_NAME -it -v $SRC_PATH:/home/$FOLDER_NAME/ -v $LOCAL_MIPLIB_PATH:$CONTAINER_MIPLIB_PATH $IMAGE_NAME bash 
```
Attach to the container and run julia: 
```
docker exec -it $CONTAINER_NAME julia --project
include("test_run.jl") # run the test script
include("array.jl") # run a set of scenarios for a given array of tasks ids 
include("metrics.jl") # merge the results into a single file that will be saved at processed_data/experiments/miplib_all/metrics.json
```
Note: The codebase is not designed to run locally. It is recommended to run the experiments on a slurm cluster. 
