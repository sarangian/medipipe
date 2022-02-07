## read in sample list
import pandas as pd

## read in sample and corresponding fq files talbe
SAMPLES = (
    pd.read_csv(config["samples"], sep="\t")
    .set_index("sample", drop=False)
    .sort_index()
)

## read in refrence files' info
REF = pd.read_csv(config["ref_files"], sep="\t", header = None, index_col = 0)

## working directory
wd = config["workdir"]
pipe_dir = config["pipeline_dir"]
umi_list = config["umi_list"]

#############################################
## get taget outputs based on the config file
#############################################

def get_rule_all_input():

    #map_out = expand("sorted_reads/{sample}_sorted.bam.bai", sample = SAMPLES["sample"]),
    dedup_out = expand("dedup_bam/{sample}_dedup.bam.bai", sample = SAMPLES["sample"]),
    medips_out = expand("methyQuant/{sample}_qc_report.txt", sample = SAMPLES["sample"]),
    medestrand_out = expand("methyQuant/{sample}_abs_methy.RDS", sample = SAMPLES["sample"]),


    if config["paired-end"]:
        ## FASQC out for raw and trimmed paired-end fqs
        fastqc_raw_pe = expand("fastqc/pe/{sample}_{mate}_fastqc.html",
                                sample = SAMPLES["sample"],
                                mate = ["R1", "R2"]),
        fastqc_trimmed_r1 = expand("fastqc/pe/{sample}_R1_val_1_fastqc.html",
                                   sample = SAMPLES["sample"]),
        fastqc_trimmed_r2 = expand("fastqc/pe/{sample}_R2_val_2_fastqc.html",
                                   sample = SAMPLES["sample"]),
        fastqc_pe_out = fastqc_raw_pe + fastqc_trimmed_r1 + fastqc_trimmed_r2

        ## inferred insert size
        inferred_insert_size = expand("dedup_bam/{sample}_insert_size_histogram.pdf",
                                      sample = SAMPLES["sample"]),

        return fastqc_pe_out + dedup_out + inferred_insert_size + medips_out + medestrand_out


    else:
        ## FASQC out for raw and trimmed single-end fq
        fastqc_raw_se = expand("fastqc/se/{sample}_fastqc.html",
                                sample = SAMPLES["sample"]),
        fastqc_trimmed_se = expand("fastqc/se/{sample}_trimmed_fastqc.html",
                                    sample = SAMPLES["sample"]),
        fastqc_se_out = fastqc_raw_se + fastqc_trimmed_se

        return fastqc_se_out + dedup_out + dedup_out + medips_out + medestrand_out


###############################
##  get corresponding bwa_index
def get_bwa_index():
    if config["spike_in"]:
        return REF.loc["bwa_idx_spikein"][1]
    else:
        return REF.loc["bwa_idx"][1]


#######################################################
##  get raw fastq files for FASTQC and extract barcodes
def get_raw_fastq(wildcards):
    if config["paired-end"]:
        R1 = SAMPLES.loc[wildcards.sample]["R1"],
        R2 = SAMPLES.loc[wildcards.sample]["R2"],
        return R1 + R2
    else:
        return SAMPLES.loc[wildcards.sample]["R1"]


################################################
## get fastq for TRIM GALORE
## UMI extracted for paired-end reads, if exist
def get_fastq_4trim(wildcards):
    if config["paired-end"] == False:
        return SAMPLES.loc[wildcards.sample]["R1"]
    elif config["add_umi"]:
        R1 = "barcoded_fq/{}_R1.fastq.gz".format(wildcards.sample),
        R2 = "barcoded_fq/{}_R2.fastq.gz".format(wildcards.sample),
        return R1 + R2
    else:
        R1 = SAMPLES.loc[wildcards.sample]["R1"],
        R2 = SAMPLES.loc[wildcards.sample]["R2"],
        return R1 + R2


##################################
## get trimmed fastq files for BWA
def get_trimmed_fastq(wildcards):
    if config["paired-end"]:
        R1 = "trimmed_fq/{}_R1_val_1.fq.gz".format(wildcards.sample),
        R2 = "trimmed_fq/{}_R2_val_2.fq.gz".format(wildcards.sample),
        return R1 + R2
    else:
        return "trimmed_fq/{}_trimmed.fq.gz".format(wildcards.sample)
