FROM mambaorg/micromamba:2.6.2 AS micromamba

FROM ubuntu:24.04

# version pinning
# snakemake-executor-plugin-cluster-generic works with python 3.11-12
ARG SNAKEMAKE_VERSION=9.22.0 \
    SNAKEMAKE_PLUGIN_VERSION=1.0.9

ENV DEBIAN_FRONTEND=noninteractive \
    LC_ALL=C

# apt:
# - tools
# - libraries
# - languages
#   - R 4.3.3
# - applications
#   - bedtools 2.31.1
#   - bcftools 1.19
#   - vcftools 0.1.16
# - snape-pooled dependency

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential ca-certificates git parallel \
        libbz2-dev liblzma-dev libopenblas-dev zlib1g-dev \
        r-base \
        bedtools bcftools vcftools libhts-dev samtools tabix \
        ocaml-nox \
    && rm -rf /var/lib/apt/lists/*

# Python packages
COPY --from=micromamba /bin/micromamba /bin/micromamba
RUN micromamba install --yes --name base -c conda-forge -c bioconda \
        python=3.11 \
        snakemake=$SNAKEMAKE_VERSION \
        snakemake-executor-plugin-cluster-generic=$SNAKEMAKE_PLUGIN_VERSION \
    && micromamba clean --all --yes
ENV PATH=/root/.local/share/mamba/bin:$PATH

# R packages
RUN R -e "install.packages(c('data.table'), repos='https://cran.r-project.org')"

# snape-pooled
#   deprecated in ocaml:
#   - Array.create -> Array.make
#   - String.uppercase -> String.uppercase_ascii

WORKDIR /opt
RUN git clone https://github.com/DEST-bio/snape-pooled.git && \
    cd snape-pooled && \
    sed -i -e 's/Array.create/Array.make/g' \
           -e 's/String.uppercase/String.uppercase_ascii/g' \
        pooled.ml && \
    make snape-pooled

ENV PATH="/opt/snape-pooled:${PATH}"

# DEST-bio
RUN git clone https://github.com/rsdmse/DESTv3.git && \
    cd DESTv3 && \
    git checkout kathryn
