# =====================================================================
# E. COLI VARIANT CALLING PIPELINE (SRR2584863)
# =====================================================================

# Ensure we start from the main project root directory
cd ~/Bioinfo_project

# ---------------------------------------------------------------------
# Step 1: Directory Setup & Data Extraction
# ---------------------------------------------------------------------
echo "Initializing project directory structures..."
mkdir -p Raw_data qc_result trimmed_data Reference alignment Result
cd Raw_data
prefetch SRR2584863

cd SRR2584863
fastq-dump --split-files -O Raw_data/ SRR2584863

# ---------------------------------------------------------------------
# Step 2: Run Quality Control with FastQC
# ---------------------------------------------------------------------
echo "Running FastQC analysis..."
fastqc -o qc_result/ Raw_data/SRR2584863_1.fastq Raw_data/SRR2584863_2.fastq

# ---------------------------------------------------------------------
# Step 3: Quality Trimming with Trimmomatic
# ---------------------------------------------------------------------
echo "Running Trimmomatic adapter and quality trimming..."
trimmomatic PE \
  Raw_data/SRR2584863_1.fastq Raw_data/SRR2584863_2.fastq \
  trimmed_data/SRR2584863_1_paired.fastq trimmed_data/SRR2584863_1_unpaired.fastq \
  trimmed_data/SRR2584863_2_paired.fastq trimmed_data/SRR2584863_2_unpaired.fastq \
  LEADING:3 TRAILING:3 SLIDINGWINDOW:4:15 MINLEN:36

# ---------------------------------------------------------------------
# Step 4: Reference Genome Preparation & Indexing
# ---------------------------------------------------------------------
wget -O Reference/Reference.fasta.gz https://ftp.ncbi.nlm.nih.gov/genomes/refseq/bacteria/Escherichia_coli/reference/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz
gunzip Reference/Reference.fasta.gz
bwa index Reference/Reference.fasta
# ---------------------------------------------------------------------
# Step 5: Alignment using BWA MEM
# ---------------------------------------------------------------------
echo "Aligning clean reads to reference genome..."
bwa mem Reference/Reference.fasta \
  trimmed_data/SRR2584863_1_paired.fastq \
  trimmed_data/SRR2584863_2_paired.fastq > alignment/alignment.sam

# ---------------------------------------------------------------------
# Step 6: Convert, Sort, and Index Alignment Data
# ---------------------------------------------------------------------
echo "Converting SAM to sorted BAM and indexing..."
samtools sort -o alignment/alignment_sorted.bam alignment/alignment.sam
samtools index alignment/alignment_sorted.bam

# ---------------------------------------------------------------------
# Step 7: Variant Calling using BCFTools
# ---------------------------------------------------------------------
echo "Starting variant calling pipeline..."
bcftools mpileup -f Reference/Reference.fasta alignment/alignment_sorted.bam | \
  bcftools call -mv -Ob -o Result/variants.bcf

# Convert to human-readable VCF layout
echo "Converting binary BCF to human-readable VCF format..."
bcftools view Result/variants.bcf > Result/variants.vcf

echo "======================================================="
echo "PIPELINE COMPLETE! Final variants saved to Result/variants.vcf"
echo "======================================================="
