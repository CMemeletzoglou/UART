library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx_tb is
end;

architecture bench of uart_rx_tb is
  component uart_rx    
      port (
      i_clk : in std_logic;
      i_rst : in std_logic;
      i_ser_data : in std_logic;
      o_done : out std_logic;
      o_par_data : out std_logic_vector(7 downto 0)
    );
  end component;

  -- Clock period
  constant clk_period : time := 50 ns;
  -- Generics
  constant g_CLKS_PER_BIT : natural := 174;

  constant c_BIT_PERIOD : time := 8680 ns;

  -- Ports
  signal i_clk : std_logic;
  signal i_rst : std_logic;
  signal i_ser_data : std_logic;
  signal o_done : std_logic;
  signal o_par_data : std_logic_vector(7 downto 0);

  -- UART Byte write
    procedure UART_WRITE_BYTE (
        i_data_in : in std_logic_vector(7 downto 0);
        signal o_serial : out std_logic) is    
    begin
        -- send START bit
        o_serial <= '0';
        wait for c_BIT_PERIOD;

        -- send data byte
        for i in 0 to 7 loop
            o_serial <= i_data_in(i);
            wait for c_BIT_PERIOD;            
        end loop;

        -- send STOP bit
        o_serial <= '1';
        wait for c_BIT_PERIOD;
    
    end procedure UART_WRITE_BYTE;

begin

    uart_rx_inst : uart_rx    
    port map (
        i_clk => i_clk,
        i_rst => i_rst,
        i_ser_data => i_ser_data,
        o_done => o_done,
        o_par_data => o_par_data
    );

    clk_process : process
    begin
    i_clk <= '1';
    wait for clk_period/2;
    i_clk <= '0';
    wait for clk_period/2;
    end process clk_process;

    

    stimuli_proc : process begin
        i_rst <= '1', '0' after clk_period;

        wait until rising_edge(i_clk);
        UART_WRITE_BYTE(x"37", i_ser_data);

        wait until rising_edge(i_clk);

        if (o_par_data = x"37") then
            report "Test1 Passed - Correct Byte received" severity note;
        else
            report "Test FAILED - Incorrect Byte received" severity note;
        end if;
        
        wait until rising_edge(i_clk);
        UART_WRITE_BYTE(x"a4", i_ser_data);
        wait until rising_edge(i_clk);
        
        if (o_par_data = x"A4") then
            report "Test2 Passed - Correct Byte received" severity note;
        else
            report "Test2 FAILED - Incorrect Byte received" severity note;
        end if;        

        assert false report "Tests Complete" severity failure;



    end process stimuli_proc;

end;
