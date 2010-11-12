require 'stringio'

module Datatype
# unpack, pack
# C     |  Unsigned char # 1 byte
# I     |  Unsigned integer # 4 bytes
# L     |  Unsigned long
# S     |  Unsigned short # 2 bytes

# c     |  char # 1 byte
# i     |  integer # 4 bytes
# l     |  long
# s     |  short # 2 bytes

# unpack, pack
# C     |  UINT8  # 1 byte
# I     |  UINT32 # 4 bytes
# L     |  Unsigned long
# S     |  UINT16 # 2 bytes

# c     |  char # 1 byte
# i     |  integer # 4 bytes
# l     |  long
# s     |  short # 2 bytes

# typedef unsigned char  UINT8;		1 byte
# typedef unsigned short UINT16;	2 bytes
# typedef unsigned int   UINT32;	4 bytes
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
	class UInt16 < TwoBytes;PACK = "S";	end
	class Word < TwoBytes;	PACK = "S";	end

	class FourBytes < Type;		SIZE_OF = 4;end
	class Int32 < FourBytes;	PACK = "i";	end
	class UInt32 < FourBytes;	PACK = "I";	end
	class ColorRef < FourBytes;	PACK = "I";	end

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
