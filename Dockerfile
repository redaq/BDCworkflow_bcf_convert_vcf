############################################################################
## Dockerfile to build a container for converting bcf files to blocked vcf.gz files
## blocked vcf.gz files can be loaded using HAIL
######################################################


# Set the base image to Ubuntu
FROM ubuntu:14.04

# File Author / Maintainer
MAINTAINER Dandi Qiao <redaq@channing.harvard.edu>

# Setup packages
USER root
RUN apt-get -m update && apt-get install -y wget unzip zip git gcc make curl zlib1g-dev libperl-dev libbz2-dev liblzma-dev libcurl4-openssl-dev autoconf

RUN wget -q https://s3.amazonaws.com/plink2-assets/alpha2/plink2_linux_x86_64.zip 
RUN unzip plink2_linux_x86_64.zip && \
    rm plink2_linux_x86_64.zip && \
    mv plink2 /usr/local/bin/
RUN chmod a+x /usr/local/bin/plink2

RUN git clone --recurse-submodules git://github.com/samtools/htslib.git
RUN git clone git://github.com/samtools/bcftools.git
RUN cd /bcftools &&\
    make &&\
    mv bcftools /usr/local/bin/
RUN chmod a+x /usr/local/bin/bcftools


## switch back
RUN groupadd -r -g 1000 ubuntu && useradd -r -g ubuntu -u 1000 ubuntu
USER ubuntu

# by default /bin/bash is executed
CMD ["/bin/bash"]




