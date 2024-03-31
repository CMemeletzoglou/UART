library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity bin2ssd is
    port (
        i_clk : in std_logic;
        i_bin_num : in std_logic_vector(3 downto 0);
        
        o_seg_A : out std_logic;
        o_seg_B : out std_logic;
        o_seg_C : out std_logic;
        o_seg_D : out std_logic;
        o_seg_E : out std_logic;
        o_seg_F : out std_logic;
        o_seg_G : out std_logic
    );
end bin2ssd;

architecture rtl of bin2ssd is
    signal r_ssd_encoding : std_logic_vector(7 downto 0) := (others => '0');
begin
    process (i_clk)
    begin
        if rising_edge(i_clk) then
            case i_bin_num is
                when b"0000" =>
                    r_ssd_encoding <= x"7E";

                when b"0001" => 
                    r_ssd_encoding <= x"30";
                
                when b"0010" => 
                    r_ssd_encoding <= x"6D";

                when b"0011" => 
                    r_ssd_encoding <= x"79";

                when b"0100" => 
                    r_ssd_encoding <= x"33";

                when b"0101" => 
                    r_ssd_encoding <= x"5B";

                when b"0110" => 
                    r_ssd_encoding <= x"5F";

                when b"0111" => 
                    r_ssd_encoding <= x"70";

                when b"1000" => 
                    r_ssd_encoding <= x"7F";

                when b"1001" => 
                    r_ssd_encoding <= x"73";

                when b"1010" => 
                    r_ssd_encoding <= x"77";

                when b"1011" => 
                    r_ssd_encoding <= x"1F";

                when b"1100" => 
                    r_ssd_encoding <= x"4E";

                when b"1101" => 
                    r_ssd_encoding <= x"3D";

                when b"1110" => 
                    r_ssd_encoding <= x"4F";

                when b"1111" => 
                    r_ssd_encoding <= x"47";                  
            end case;            
        end if;
    end process;

    o_seg_A <= r_ssd_encoding(6);
    o_seg_B <= r_ssd_encoding(5);
    o_seg_C <= r_ssd_encoding(4);
    o_seg_D <= r_ssd_encoding(3);
    o_seg_E <= r_ssd_encoding(2);
    o_seg_F <= r_ssd_encoding(1);
    o_seg_G <= r_ssd_encoding(0);
end architecture;