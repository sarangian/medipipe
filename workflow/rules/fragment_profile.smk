#############################################################################
## Fragment profiles measured by short/long fragments in 1bm and 5bm regions
rule fragment_profile:
    input:
        get_dedup_bam
    output:
        "fragment_profile/{sample}_10_Granges.bed",
        "fragment_profile/{sample}_50_Granges.bed",
        "fragment_profile/{sample}_10_100kb_fragment_profile_GC_corrected_Ratio.txt",
        "fragment_profile/{sample}_50_100kb_fragment_profile_GC_corrected_Ratio.txt"
    resources:
        mem_mb=60000
    params:
        bsgenome = config["bsgenome"],
        scr_dir = config["pipe_dir"],   ## filter regions enclosed in assets folder are needed
    log:
        "logs/{sample}_fragment_profile.log"
    shell:
        "(Rscript --vanilla {params.scr_dir}/workflow/scripts/fragment_profile.R "
        "{wildcards.sample} {input} {params.bsgenome} {params.scr_dir}) 2> {log}"
