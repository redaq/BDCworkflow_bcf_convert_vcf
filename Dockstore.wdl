version 1.0

workflow BCFConvertVCF{
	meta {
	author: "Dandi Qiao"
	email: "redaq@channing.harvard.edu"
	description: "Convert bcf files to blocked vcf.gz files required by HAIL."
	}

	input {
		Array[File] bcf_list
		String  vcf_output
		#File  subj_list
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
			vcf_output_in = vcf_output,
			#subj_list_in = subj_list,
			cores_in = cores,
			disk_in = disk,
			mem_gb_in = mem_gb,
			filterPass_in = filterPass,
			min_mac_in = min_mac
			
		}
		File vcf_out = convert.convert_vcf
	}	

	output {
		Array[File] vcf_outs = vcf_out 
	}
}


task convert {
	input {
		File bcf_list_in
		String vcf_output_in
		#File subj_list_in
		Boolean filterPass_in
		Int min_mac_in
		Int cores_in
		Int disk_in
		Int mem_gb_in
	}
	command { 
	set -eux -o pipefail

	## prepare
	if [ ~{filterPass_in} == true ]; then
		bcftools view -O z -f .,PASS -o ~{vcf_output_in}_tmp.vcf.gz ~{bcf_list_in} 
	else
		bcftools view -O z -o ~{vcf_output_in}_tmp.vcf.gz ~{bcf_list_in}
	fi

	if [~{min_mac_in} == 0 ]; then		
		plink2 --vcf ~{vcf_output_in}_tmp.vcf.gz --export vcf bgz id-paste=iid --out ~{vcf_output_in} 
	else
		plink2 --vcf ~{vcf_output_in}_tmp.vcf.gz --mac ~{min_mac_in} --export vcf bgz id-paste=iid --out ~{vcf_output_in}
	fi
	}
	output {
		File convert_vcf = "${vcf_output_in}.vcf.gz"

	}
	runtime {
		docker: "try/bcf_convert_vcf"
		memory: mem_gb_in + " GB"
		cpu: cores_in
		disks: "local-disk " + disk_in + " SSD"
	}
}


