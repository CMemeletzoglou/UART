library ieee;
use ieee.std_logic_1164.all;

-- assume baud rate = 115.200, 1 start bit, 8 data bits, 1 stop bit, no parity and no flow control (8N1 convension)
-- Internal UART Receiver clock frequency = 100 MHz -> 100000000/115200 = 868 internal clocks per transmitted bit
entity uart_rx is
    generic (
        g_CLKS_PER_BIT : natural
   );
    port (
        i_clk      : in std_logic;
        i_rst      : in std_logic;
        i_ser_data : in std_logic;
        o_done     : out std_logic;
        o_par_data : out std_logic_vector(7 downto 0)
   );
end entity uart_rx;

architecture fsm of uart_rx is
    constant c_BIT_DURATION : integer := g_CLKS_PER_BIT - 1;
    type t_RX_STATE is (s_IDLE, s_START_BIT, s_RX_DATA, s_STOP_BIT, s_DONE);

    -- current RX state
    signal r_rx_state : t_RX_STATE;

    -- wait counter
    signal r_wait_counter : integer range 0 to c_BIT_DURATION := 0;

    signal r_received_data : std_logic_vector(7 downto 0) := (others => '0');

    -- received bit index
    signal r_curr_bit_index : integer range 0 to 7 := 0;

    signal r_done : std_logic := '0';
begin
    uart_rx_fsm_proc : process (i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_rst = '1') then
                r_rx_state       <= s_IDLE;
                r_wait_counter   <= 0;
                r_received_data  <= (others => '0');
                r_curr_bit_index <= 0;
                r_done           <= '0';
            else
                case r_rx_state is
                    when s_IDLE =>
                        if i_ser_data = '0' then -- START bit detected
                            r_rx_state <= s_START_BIT;
                        else
                            r_rx_state       <= s_IDLE;
                            r_wait_counter   <= 0;
                            r_curr_bit_index <= 0;
                        end if;

                    when s_START_BIT =>
                        -- wait for half of the bit period and then sample the input again
                        -- to make sure that it was a valid start bit and not just a spurious change
                        if (r_wait_counter < c_BIT_DURATION / 2) then
                            r_wait_counter <= r_wait_counter + 1;
                            r_rx_state     <= s_START_BIT;
                        else
                            -- check value
                            if (i_ser_data = '0') then --valid START bit
                                r_rx_state <= s_RX_DATA; -- goto read data state

                                r_wait_counter <= 0;
                            else
                                r_rx_state <= s_IDLE; -- go back to the IDLE state
                            end if;
                        end if;

                    when s_RX_DATA =>
                        -- Since at the s_START_BIT state we waited for half of the bit's duration,
                        -- by waiting a complete bit duration in sebsequent states, we are effectively
                        -- sampling the incoming bits at the middle of their duration. 
                        -- This way we sample valid data bits, by allowing the transmission line time to "settle"
                        if (r_wait_counter < c_BIT_DURATION) then
                            r_wait_counter <= r_wait_counter + 1;
                            r_rx_state     <= s_RX_DATA;
                        else
                            -- sample data in
                            r_received_data(r_curr_bit_index) <= i_ser_data;

                            -- reset counter for next bit
                            r_wait_counter <= 0;

                            -- check if we have read all the bits
                            if (r_curr_bit_index < 7) then
                                -- increment bit index
                                r_curr_bit_index <= r_curr_bit_index + 1;

                                r_rx_state <= s_RX_DATA;
                            else -- all bits read
                                r_curr_bit_index <= 0;
                                r_rx_state       <= s_STOP_BIT;
                            end if;
                        end if;

                    when s_STOP_BIT =>
                        if (r_wait_counter < c_BIT_DURATION) then
                            r_wait_counter <= r_wait_counter + 1;
                            r_rx_state     <= s_STOP_BIT;
                        else
                            -- check for at least one transition of the UART line to logic HIGH
                            if (i_ser_data = '1') then
                                -- goto DONE state
                                r_rx_state     <= s_DONE;
                                r_done         <= '1';
                                r_wait_counter <= 0;
                            else
                                r_rx_state <= s_STOP_BIT;
                            end if;
                        end if;

                    when s_DONE =>
                        -- stay here for one clock cycle, deassert done, then go back to IDLE
                        r_done     <= '0';
                        r_rx_state <= s_IDLE;

                    when others =>
                        r_rx_state <= s_IDLE;
                end case;
            end if;
        end if;
    end process uart_rx_fsm_proc;

    o_done <= r_done;
    o_par_data <= r_received_data;
end architecture;