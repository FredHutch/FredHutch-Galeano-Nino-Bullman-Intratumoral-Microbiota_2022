# The preprocessing pipeline for 10X Visium data, input of this pipeline is the output of spaceranger count
ml GATK/4.1.3.0-GCCcore-8.3.0-Java-1.8
ml Python
ml Pysam

`raw_data_folder` # the folder containing Spaceranger output folders 
`root` # working directory
`pathseqdb` # Pathseq database

cd ${root}
cd ${raw_data_folder}

# PathSeq pipeline
outpath=${root}/pathseq
mkdir ${outpath}
# PathSeq process # Please adjust "-Xmx750g" based on the memory you want to use. Adjust --min-score-identity and --min-clipped-read-length based on your samples
# 
for folder in *
do
folder_name=${folder##*/}
file=${folder}/outs/possorted_genome_bam.bam
samplename=${folder_name}
echo ${samplename}
gatk --java-options "-Xmx750g" PathSeqPipelineSpark \
    --input ${file} \
    --filter-bwa-image ${pathseqdb}/pathseq_host.fa.img \
    --kmer-file ${pathseqdb}/pathseq_host.bfi \
    --min-clipped-read-length 60 \
    --microbe-fasta ${pathseqdb}/pathseq_microbe.fa \
    --microbe-bwa-image ${pathseqdb}/pathseq_microbe.fa.img \
    --taxonomy-file ${pathseqdb}/pathseq_taxonomy.db \
    --output ${outpath}/${samplename}.pathseq.complete.bam \
    --scores-output ${outpath}/${samplename}.pathseq.complete.csv \
    --is-host-aligned false \
    --filter-duplicates false \
    --min-score-identity .7
done

# Python script to generate bacteria matrix
bam_path=${raw_data_folder}
pathseq_path=${root}/pathseq
out_path=${root}/python
mkdir ${out_path}
cd ${bam_path}

for each_sample in *
do
echo ${each_sample}
python UMI_annotator.py \
${bam_path}/${each_sample}/outs/possorted_genome_bam.bam \
'' \
${bam_path}/${each_sample}/outs/raw_feature_bc_matrix/barcodes.tsv.gz \
${pathseq_path}/${each_sample}.pathseq.complete.bam \
${pathseq_path}/${each_sample}.pathseq.complete.csv \
${out_path}/${each_sample}.visium.raw_matrix.readname \
${out_path}/${each_sample}.visium.raw_matrix.unmap_cbub.bam \
${out_path}/${each_sample}.visium.raw_matrix.unmap_cbub.fasta \
${out_path}/${each_sample}.visium.raw_matrix.list \
${out_path}/${each_sample}.visium.raw.raw_matrix.readnamepath \
${out_path}/${each_sample}.visium.raw_matrix.genus.cell \
${out_path}/${each_sample}.visium.raw_matrix.genus.csv \
${out_path}/${each_sample}.visium.raw_matrix.validate.csv
done

