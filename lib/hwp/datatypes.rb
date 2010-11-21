require 'stringio'

module Datatype
	class Type
		attr_reader :a_size
		def initialize a_size
			@a_size = a_size
		end
	end

	class OneByte < Type;	SIZE_OF = 1;end
	class Int8 < OneByte;	PACK = "c";	end
	class UInt8 < OneByte;	PACK = "C";	end

	class TwoBytes < Type;	SIZE_OF = 2;end
	class UInt16 < TwoBytes;PACK = "v";	end
	class Word < TwoBytes;	PACK = "v";	end

	class FourBytes < Type;		SIZE_OF = 4;end
	class Int32 < FourBytes;	PACK = "i";	end
	class UInt32 < FourBytes;	PACK = "V";	end
	class ColorRef < FourBytes;	PACK = "V";	end

	def int8 a_size=1;		return Int8.new a_size;		end
	def int32 a_size=1;		return Int32.new a_size;	end
	def uint8 a_size=1;		return UInt8.new a_size;	end
	def uint16 a_size=1;	return UInt16.new a_size;	end
	def uint32 a_size=1;	return UInt32.new a_size;	end
	def word a_size=1;		return Word.new a_size;		end
	def colorref a_size=1;	return ColorRef.new a_size;	end

	def decode data, fields
		@io = StringIO.new data
		fields.each_pair do |type, var|
			name = "@"+var.to_s
			raw = @io.read(type.class::SIZE_OF*type.a_size)
			val = raw.unpack(type.class::PACK*type.a_size)
			instance_variable_set(name, val)
		end
		@io.close
	end
end
