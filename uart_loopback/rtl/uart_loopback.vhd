library ieee;
use ieee.std_logic_1164.all;

entity uart_loopback is
    generic (
        g_CLKS_PER_BIT : natural := 868;
        -- set to 1 if a digilent PMOD Seven Segment Display is connected to the top row of PMOD connectors JA and JB
        g_DIGILENT_SSD : natural := 1
    );
    port (
        i_clk      : in std_logic;
        i_rst      : in std_logic;
        i_ser_data : in std_logic;

        o_ser_data : out std_logic;

        o_ssd_digit_sel : out std_logic;

        o_ssd_seg_A : out std_logic;
        o_ssd_seg_B : out std_logic;
        o_ssd_seg_C : out std_logic;
        o_ssd_seg_D : out std_logic;
        o_ssd_seg_E : out std_logic;
        o_ssd_seg_F : out std_logic;
        o_ssd_seg_G : out std_logic
    );
end entity uart_loopback;

architecture rtl of uart_loopback is
    signal  w_rx_done     : std_logic;
    signal  w_rx_data_out : std_logic_vector(7 downto 0);

    signal  w_tx_running,
            w_tx_done : std_logic;

    signal  w_ssd_0_seg_A,
            w_ssd_0_seg_B, 
            w_ssd_0_seg_C, 
            w_ssd_0_seg_D, 
            w_ssd_0_seg_E, 
            w_ssd_0_seg_F, 
            w_ssd_0_seg_G : std_logic;

    signal  w_ssd_1_seg_A,
            w_ssd_1_seg_B, 
            w_ssd_1_seg_C, 
            w_ssd_1_seg_D, 
            w_ssd_1_seg_E, 
            w_ssd_1_seg_F, 
            w_ssd_1_seg_G : std_logic;    
    

    constant c_WAIT_LIMIT : integer := 1000000;

    signal r_wait_counter : integer range 0 to c_WAIT_LIMIT := 0;    

    signal r_ssd_digit_sel : std_logic := '0';
begin
    uart_rx : entity work.uart_rx
        generic map(
            g_CLKS_PER_BIT => g_CLKS_PER_BIT
        )
        port map(
            i_clk      => i_clk,
            i_rst      => i_rst,
            i_ser_data => i_ser_data,
            o_done     => w_rx_done,
            o_par_data => w_rx_data_out
        );

    uart_tx : entity work.uart_tx
        generic map(
            g_CLKS_PER_BIT => g_CLKS_PER_BIT
        )
        port map(
            i_clk      => i_clk,
            i_rst      => i_rst,
            i_start    => w_rx_done,
            i_par_data => w_rx_data_out,

            o_running  => w_tx_running,
            o_done     => w_tx_done,
            o_ser_data => o_ser_data
        );

    digilent_ssd : if (g_DIGILENT_SSD = 1) generate
        -- connect the two digit seven segment display
        -- one bin2ssd instance for each nibble
        ssd_0_bin_conv : entity work.bin2ssd
            port map(
                i_clk => i_clk,
                i_bin_num => w_rx_data_out(3 downto 0),
                o_seg_A => w_ssd_0_seg_A,
                o_seg_B => w_ssd_0_seg_B,
                o_seg_C => w_ssd_0_seg_C,
                o_seg_D => w_ssd_0_seg_D,
                o_seg_E => w_ssd_0_seg_E,
                o_seg_F => w_ssd_0_seg_F,
                o_seg_G => w_ssd_0_seg_G
            );

        ssd_1_bin_conv : entity work.bin2ssd
            port map(
                i_clk => i_clk,
                i_bin_num => w_rx_data_out(7 downto 4),
                o_seg_A => w_ssd_1_seg_A,
                o_seg_B => w_ssd_1_seg_B,
                o_seg_C => w_ssd_1_seg_C,
                o_seg_D => w_ssd_1_seg_D,
                o_seg_E => w_ssd_1_seg_E,
                o_seg_F => w_ssd_1_seg_F,
                o_seg_G => w_ssd_1_seg_G
            );
            
        -- According to Digilent's PMOD SSD reference manual, only
        -- one of the SSD's digits can be lit at a particular time.
        -- Therefore, in order to light both of them, we first light Digit_0
        -- and then wait 10 msecs before lighting Digit_1
        ssd_digit_sel_proc : process (i_clk)
        begin
            if rising_edge(i_clk) then
                if (i_rst = '1') then
                    r_ssd_digit_sel <= '0';
                else
                    -- wait for 10 msecs (c_WAIT_LIMIT) then enable digit 1
                    if (r_wait_counter < c_WAIT_LIMIT) then
                        r_wait_counter <= r_wait_counter + 1;
                        r_ssd_digit_sel <= r_ssd_digit_sel;
                    else
                        r_wait_counter <= 0;
                        r_ssd_digit_sel <= NOT r_ssd_digit_sel;
                    end if;
                end if;            
            end if;
        end process;
    
        o_ssd_digit_sel <= '0' when r_ssd_digit_sel = '0' else '1';    

        o_ssd_seg_A <= w_ssd_0_seg_A when r_ssd_digit_sel = '0' else w_ssd_1_seg_A;
        o_ssd_seg_B <= w_ssd_0_seg_B when r_ssd_digit_sel = '0' else w_ssd_1_seg_B;
        o_ssd_seg_C <= w_ssd_0_seg_C when r_ssd_digit_sel = '0' else w_ssd_1_seg_C;
        o_ssd_seg_D <= w_ssd_0_seg_D when r_ssd_digit_sel = '0' else w_ssd_1_seg_D;
        o_ssd_seg_E <= w_ssd_0_seg_E when r_ssd_digit_sel = '0' else w_ssd_1_seg_E;
        o_ssd_seg_F <= w_ssd_0_seg_F when r_ssd_digit_sel = '0' else w_ssd_1_seg_F;
        o_ssd_seg_G <= w_ssd_0_seg_G when r_ssd_digit_sel = '0' else w_ssd_1_seg_G;

    else generate        
        o_ssd_digit_sel <= '0';
        o_ssd_seg_A <= '0';
        o_ssd_seg_B <= '0';
        o_ssd_seg_C <= '0';
        o_ssd_seg_D <= '0';
        o_ssd_seg_E <= '0';
        o_ssd_seg_F <= '0';
        o_ssd_seg_G <= '0';
    end generate;   

end architecture;