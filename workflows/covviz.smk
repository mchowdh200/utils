import os
configfile: 'conf/covviz.yaml'

index_urls = [f.rstrip() for f in open(config['bam_index_list']).readlines()]

# list of urls keyed by the destination file
index_files = {f'{config["outdir"]}/os.path.basename(url)': url
               for url in index_urls}

rule GetIndex:
    output:
        index = temp('{index}')
    run:
        url = index_files[output.index]
        shell(f'aws s3 cp {url} {{output.index}}')

rule GetFai:
    output:
        f'{config["outdir"]}/ref.fa.fai'
    shell:
        f'aws s3 cp {config["ref_index"]} {{output}}'

rule RunCovviz:
    input:
        indices = expand('{index}', index=index_files.keys()),
        fai = rules.GetFai.output
    output:
        f'{config["outdir"]}/covviz_report.html'
    conda:
        'envs/covviz.yaml'
    shell:
        f"""
        covviz --indexes '{config["outdir"]}/*.{config["index_extension"]} \\
               --fai {config["ref_index"]} \\
               --output {{output}}'
        """
