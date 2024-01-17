library ieee;
use ieee.std_logic_1164.all;

entity uart_loopback is
    generic (
        g_CLKS_PER_BIT : natural := 868
    );
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;        
        i_ser_data : in std_logic;
        
        o_ser_data : out std_logic
    );
end entity uart_loopback;

architecture rtl of uart_loopback is
    signal w_rx_done : std_logic;
    signal w_rx_data_out : std_logic_vector(7 downto 0);

    signal  w_tx_running,
            w_tx_done : std_logic;
begin
    uart_rx : entity work.uart_rx
        generic map (
            g_CLKS_PER_BIT => 868
        )
        port map(
            i_clk => i_clk,
            i_rst => i_rst,
            i_ser_data => i_ser_data,
            o_done => w_rx_done,
            o_par_data => w_rx_data_out
        );

    uart_tx : entity work.uart_tx
        generic map (
            g_CLKS_PER_BIT => 868
        )
        port map (
            i_clk => i_clk,
            i_rst => i_rst,
            i_start => w_rx_done,
            i_par_data => w_rx_data_out,

            o_running => w_tx_running,
            o_done => w_tx_done,
            o_ser_data => o_ser_data
        );
end architecture;