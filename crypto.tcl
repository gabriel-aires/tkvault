#safe cryptographic operations using blowfish CBC mode
oo::class create Crypto {
	variable Key InitVector Secret DataSize Cache
	
	constructor {master_password max_size} {
		my Next_vector
		set Secret [binary format A8 $master_password]
		set DataSize $max_size
		set Key [::blowfish::Init cbc $Secret $InitVector]
		set Cache {}
	}

	method random_string {length} {
		binary scan " " c initial
		binary scan "~" c final
		set range [- $final $initial]
		set str {}
	
		for {set i 0} {$i < $length} {incr i} {
			set char [+ $initial [round [* [rand] $range]]]
			append str [binary format c $char]
		}
		
		return $str
	}

	method get_vector {} {
		return $InitVector
	}
	
	method import_vector {used_vector} {
		set InitVector $used_vector
		my Reset_key
	}
	
	method Next_vector {} {
		set InitVector [my random_string 8]
	}
	
	method Reset_key {} {
		::blowfish::Reset $Key $InitVector
	}
		
	method Update_state {} {
		my Next_vector
		my Reset_key
	}
	
	method query_cache {index item} {
		try {
			set data [dict get $Cache $index $item]
			return [list true $data]
		} on error {} {
			return [list false {}]
		}
	}
	
	method set_cache {index item data} {
		dict set Cache $index $item $data
	}
	
	method Update_cache {index plaintext ciphertext} {
		if {$index != ""} {
			set encrypt_data [list $ciphertext $InitVector]
			set decrypt_data [list $plaintext $InitVector]
			my set_cache $index $plaintext $encrypt_data
			my set_cache $index $ciphertext $decrypt_data
		}
	}	
	
	method encrypt {index plaintext} {
		set ciphertext [::blowfish::Encrypt $Key [binary format A$DataSize $plaintext]]
		set encrypt_data [list $ciphertext $InitVector]
		my Update_cache $index $plaintext $ciphertext
		my Update_state
		return $encrypt_data
	}
	
	method decrypt {index ciphertext} {
		set plaintext [::blowfish::Decrypt $Key $ciphertext]
		set decrypt_data [list $plaintext $InitVector]
		my Update_cache $index $plaintext $ciphertext
		my Update_state
		return $decrypt_data
	}
	
	destructor {
		::blowfish::Final $Key
	}
}