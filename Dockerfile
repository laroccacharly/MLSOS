FROM julia:1.8.5


ENV HOME /home/
RUN mkdir /home/MLSOS
WORKDIR /home/MLSOS
# RUN make dirs /src /mount
RUN mkdir /mount && mkdir /src
RUN mkdir -p /usr/share/man/man1 

# Install dependencies
RUN apt-get update 
RUN apt-get -y install hdf5-tools && apt-get -y install gettext && apt-get -y install libpango1.0-0  &&     apt-get -y install wget  &&      apt-get -y install default-jdk &&    apt-get -y install zip

# Set env variables
ENV CPLEX_STUDIO_BINARIES=/opt/ibm/ILOG/CPLEX_Studio1210/cplex/bin/x86-64_linux
ENV JULIA_DEPOT_PATH=/home/julia_depot/

# Install cplex
COPY deps/ .
RUN chmod u+x cplex.bin
RUN ./cplex.bin -f response.properties 
RUN rm cplex.bin 

# Install awscli 
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
  unzip awscliv2.zip && \
  ./aws/install

# COPY Project.toml and Manifest.toml
COPY Project.toml .
COPY Manifest.toml .
RUN julia --project -e 'using Pkg; Pkg.instantiate()'

# Update permissions
RUN chmod -R 645 $JULIA_DEPOT_PATH


