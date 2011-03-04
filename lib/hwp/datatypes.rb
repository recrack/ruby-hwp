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
	TYPES = {
		:byte		=> {:size => 1, :pack => "C"},
		:sbyte		=> {:size => 1, :pack => "c"},
		:word		=> {:size => 2, :pack => "v"},
		:sword		=> {:size => 2, :pack => "s"},
		:dword		=> {:size => 4, :pack => "V"},
		:sdword		=> {:size => 4, :pack => "l"},
		:hchar		=> {:size => 2, :pack => "v"},
		:echar		=> {:size => 1, :pack => "C"},
		:kchar		=> {:size => 1, :pack => "C"},
		:hunit		=> {:size => 2, :pack => "v"},
		:shunit		=> {:size => 2, :pack => "v"},
		:hunit32	=> {:size => 4, :pack => "V"},
		:shunit32	=> {:size => 4, :pack => "V"}
	}

	def self.included(base)
		base.class_eval do
			def initialize stream
				@stream = stream
				# FIXME 몇몇의 자료형은 unpack 할 필요가 없다.
				self.class.instance_variable_get(:@fields).each do |type, var, array|
					if array == 1
						instance_variable_set(var,
							@stream.read(array * TYPES[type][:size]).unpack(TYPES[type][:pack]).pop)
					else
						instance_variable_set(var,
							@stream.read(array * TYPES[type][:size]).unpack(TYPES[type][:pack] * array))
					end
				end
			end
		end

		# class method
		class << base
			TYPES.keys.each do |type|
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
