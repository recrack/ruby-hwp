# coding: utf-8
# 한글과컴퓨터의 글 문서 파일(.hwp) 공개 문서를 참고하여 개발하였습니다.

module DataType
# 사용예
#	class Model
#		include DataType
#		byte :bytes, 30
#		word :title, 40

#		def get_bytes
#			@bytes.pack("C*")
#		end
#	end

#	model = Model.new stream
#	model.bytes
#	model.get_bytes
#	model.title

#    C         | Integer | 8-bit unsigned integer (unsigned char)
#    c         | Integer | 8-bit signed integer (char)

#    v         | Integer | 16-bit unsigned integer, VAX (little-endian) byte order
#    s         | Integer | 16-bit signed integer, native endian (int16_t)

#    V         | Integer | 32-bit unsigned integer, VAX (little-endian) byte order
#    l         | Integer | 32-bit signed integer, native endian (int32_t)

# TODO 몇몇의 자료형은 unpack 할 필요가 없다.
	TYPE = {
		# common
		:byte		=> {:size => 1, :pack => "C"},
		:word		=> {:size => 2, :pack => "v"},
		:dword		=> {:size => 4, :pack => "V"},
		# hwp 5.0
		:wchar		=> {:size => 2, :pack => "v"},
		:hwpunit	=> {:size => 4, :pack => "V"},
		:shwpunit	=> {:size => 4, :pack => "l"}, # signed
		:uint8		=> {:size => 1, :pack => "C"},
		:uint16		=> {:size => 2, :pack => "v"},
		:uint32		=> {:size => 4, :pack => "V"},
		:int8		=> {:size => 1, :pack => "c"}, # signed
		:int16		=> {:size => 2, :pack => "s"}, # signed
		:int32		=> {:size => 4, :pack => "l"}, # signed
		:hwpunit16	=> {:size => 2, :pack => "s"}, # signed
		:colorref	=> {:size => 4, :pack => "V"}, # 0x00bbggrr
		# hwp 3.0
		:sbyte		=> {:size => 1, :pack => "c"}, # signed
		:sword		=> {:size => 2, :pack => "s"}, # signed
		:sdword		=> {:size => 4, :pack => "l"}, # signed
		:hchar		=> {:size => 2, :pack => "v"},
		:echar		=> {:size => 1, :pack => "C"},
		:kchar		=> {:size => 1, :pack => "C"},
		:hunit		=> {:size => 2, :pack => "v"},
		:shunit		=> {:size => 2, :pack => "s"}, # signed
		:hunit32	=> {:size => 4, :pack => "V"},
		:shunit32	=> {:size => 4, :pack => "l"}  # signed
	}

	def self.included(base)
		base.class_eval do
			def initialize stream
				@stream = stream
				# FIXME 몇몇의 자료형은 unpack 할 필요가 없다.
				self.class.instance_variable_get(:@fields).each do |type, var, array|
					if array == 1
						instance_variable_set(var,
							@stream.read(array * TYPE[type][:size]).unpack(TYPE[type][:pack]).pop)
					else
						instance_variable_set(var,
							@stream.read(array * TYPE[type][:size]).unpack(TYPE[type][:pack] * array))
					end
				end
			end
		end

		# class method
		class << base
			TYPE.keys.each do |type|
				define_method type do |var, array=1|
					@fields ||= []
					@fields << [type, "@#{var.to_s}".to_sym, array]

					define_method var do
						instance_variable_get("@#{var.to_s}".to_sym)
					end
				end
			end
		end
	end
end
