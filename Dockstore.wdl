version 1.0

workflow BCFConvertVCF{
	meta {
	author: "Dandi Qiao"
	email: "redaq@channing.harvard.edu"
	description: "Convert bcf files to blocked vcf.gz files required by HAIL."
	}

	input {
		Array[File] bcf_list
		File? subj_list
		Boolean filterPass = true ### whether to filter down to variants with PASS status
		Int min_mac = 0 ### Whether to filter out variants with mac < min_mac_in, 0 means no filter.
		Int mem_gb = 5 
		Int cores = 1
		Int disk = 10
	}
	scatter (bcf_file in bcf_list){
		call convert {
			input:
			bcf_list_in = bcf_file,
			subj_list_in = subj_list,
			cores_in = cores,
			disk_in = disk,
			mem_gb_in = mem_gb,
			filterPass_in = filterPass,
			min_mac_in = min_mac
			
		}
	}	

	output {
		Array[File] vcf_outs = convert.convert_vcf
	}
}


task convert {
	input {
		File bcf_list_in
		File? subj_list_in
		Boolean filterPass_in
		Int min_mac_in
		Int cores_in
		Int disk_in
		Int mem_gb_in
	}
	command { 
	# Set the exit code of a pipeline to that of the rightmost command
	# to exit with a non-zero status, or zero if all commands of the pipeline exit
	set -eux -o pipefail

	vcf_output_in=$(basename "${bcf_list_in}" .bcf)
	echo $vcf_output_in

	## prepare
	if [ ${default="NONE" subj_list_in} == "NONE" ]; then
		if [ ~{filterPass_in} == true ]; then
			bcftools view -O z -f .,PASS -o $vcf_output_in.vcf.gz.tmp ~{bcf_list_in} 
		else
			bcftools view -O z -o $vcf_output_in.tmp.vcf.gz.tmp ~{bcf_list_in}
		fi
	else
		if [ ~{filterPass_in} == true ]; then
			bcftools view -O z -S ~{subj_list_in} -f .,PASS -o $vcf_output_in.vcf.gz.tmp ~{bcf_list_in}
		else
			bcftools view -O z -S ~{subj_list_in} -o $vcf_output_in.tmp.vcf.gz.tmp ~{bcf_list_in}
		fi
	fi

	if [ ~{min_mac_in} == 0 ]; then
		plink2 --vcf $vcf_output_in.vcf.gz.tmp --export vcf bgz id-paste=iid --out $vcf_output_in 
	else
		plink2 --vcf $vcf_output_in.vcf.gz.tmp --mac ~{min_mac_in} --export vcf bgz id-paste=iid --out $vcf_output_in
	fi
	}
	runtime {
		docker: "quay.io/redaq/bcf-convert-vcf"
		memory: mem_gb_in + " GB"
		cpu: cores_in
		disks: "local-disk " + disk_in + " SSD"
	}
	output {
		File convert_vcf = glob("*.vcf.gz")[0]

	}
}


