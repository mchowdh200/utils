import os
configfile: 'conf/covviz.yaml'

# load the list of alignment indices (s3 uris)
index_urls = [f.rstrip() for f in open(config['bam_index_list']).readlines()]
url_dict = {os.path.basename(url): url for url in index_urls}
indices = list(url_dict.keys())

outdir = config['outdir']

rule All:
    input:
       f'{outdir}/covviz_report.html'

rule GetIndex:
    output:
        temp(f'{outdir}/{{index}}')
    params:
        url = lambda w: url_dict[w.index]
    shell:
        """
        aws s3 cp {params.url} {output}
        """

rule GetFai:
    output:
        temp(f'{outdir}/ref.fa.fai')
    params:
        url = config['ref_index']
    shell:
        'aws s3 cp {params.url} {output}'

rule GoleftIndexcov:
    input:
        crai = expand(f'{outdir}/{{index}}', index=indices),
        fai = f'{outdir}/ref.fa.fai'
    output:
        f'{outdir}/goleft/goleft-indexcov.bed.gz'
    conda:
        'envs/covviz.yaml'
    shell:
        f"""
        goleft indexcov --extranormalize \\
               --directory {outdir}/goleft \\
               --fai {{input.fai}} \\
               {{input.crai}}
        """

rule Covviz:
    input:
        f'{outdir}/goleft/goleft-indexcov.bed.gz'
    output:
        f'{outdir}/covviz_report.html'
    conda:
        'envs/covviz.yaml'
    shell:
        f"""
        covviz --output {{output}} {{input}}
        """

