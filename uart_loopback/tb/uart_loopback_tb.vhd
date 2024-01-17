library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_loopback_tb is
end;

architecture bench of uart_loopback_tb is

  component uart_loopback
    generic (
      g_CLKS_PER_BIT : natural
    );
      port (
      i_clk : in std_logic;
      i_rst : in std_logic;
      i_ser_data : in std_logic;
      o_ser_data : out std_logic
    );
  end component;

  -- Clock period
  constant clk_period : time := 50 ns;
  -- Generics
  constant g_CLKS_PER_BIT : natural := 174;

  constant c_BIT_PERIOD : time := 8650 ns;

  -- Ports
  signal i_clk : std_logic;
  signal i_rst : std_logic;
  signal i_ser_data : std_logic;
  signal o_ser_data : std_logic;

  procedure UART_WRITE_BYTE(
    i_data_in : in std_logic_vector(7 downto 0);
    signal o_ser_data : out std_logic
  ) is
  begin
    -- send START BIT
    o_ser_data <= '0';
    wait for c_BIT_PERIOD;

    for i in 0 to 7 loop
        o_ser_data <= i_data_in(i);
        wait for c_BIT_PERIOD;
    end loop;

    -- send STOP  bit
    o_ser_data <= '1';
    wait for c_BIT_PERIOD;
    
  end procedure;

begin

    uart_loopback_inst : uart_loopback
    generic map (
        g_CLKS_PER_BIT => g_CLKS_PER_BIT
    )
    port map (
        i_clk => i_clk,
        i_rst => i_rst,
        i_ser_data => i_ser_data,
        o_ser_data => o_ser_data
    );

    clk_process : process
    begin
        i_clk <= '1';
        wait for clk_period/2;
        i_clk <= '0';
        wait for clk_period/2;
    end process clk_process;

    stimuli_proc : process begin
        i_rst <= '1', '0' after 2 * clk_period;

        wait until rising_edge(i_clk);
        UART_WRITE_BYTE(x"3B", i_ser_data);

        wait until rising_edge(i_clk);

        if (o_ser_data = x"3B") then
            report "Test Pass - Correct Byte loopbacked" severity note;
        else
            report "Test FAIL - Incorrect Byte loopbacked" severity note;
        end if;

        assert false report "ALL test passed" severity failure;

    end process stimuli_proc;



end;
