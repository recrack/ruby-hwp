module HWP
    module Utils
        def hierarchy_check(level1, level2, line_num)
            if level1 != level2 - 1
                p [level1, level2]
                raise "hierarchy error at line #{line_num}"
            end
        end
    end # Utils
end # HWP

class String
    def to_formatted_hex
        self.bytes.to_a.map{|c| sprintf("%02x", c)}.join(" ")
    end
end
