# coding: utf-8

module HWP
    class FileHeader
        attr_reader :signature, :version
        def initialize file
            @signature	= file.read 32
            @version	= file.read(4).reverse.unpack("C*").join(".")
            @property	= file.read(4).unpack("V")[0]
            @reversed	= file.read 216
        end

        def bit?(n)
            if (@property & (1 <<  n)) == 1
                true
            else
                false
            end
        end
        private :bit?

        def compress?;            bit?(0);  end
        def encrypt?;             bit?(1);  end
        def distribute?;          bit?(2);  end
        def script?;              bit?(3);  end
        def drm?;                 bit?(4);  end
        def xml_template?;        bit?(5);  end
        def history?;             bit?(6);  end
        def sign?;                bit?(7);  end
        def certificate_encrypt?; bit?(8);  end
        def sign_spare?;          bit?(9);  end
        def certificate_drm?;     bit?(10); end
        def ccl?;                 bit?(11); end
    end
end
