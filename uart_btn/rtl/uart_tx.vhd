library ieee;
use ieee.std_logic_1164.all;

entity uart_tx is
    generic (
        g_CLKS_PER_BIT : natural
    );
    port (
        i_clk      : in std_logic;
        i_rst      : in std_logic;
        i_start    : in std_logic;
        i_par_data : in std_logic_vector(7 downto 0);

        o_running  : out std_logic;
        o_done     : out std_logic;
        o_ser_data : out std_logic
    );
end entity uart_tx;

architecture fsm of uart_tx is
    constant c_BIT_DURATION : integer := g_CLKS_PER_BIT - 1;

    type t_TX_STATE is (s_IDLE, s_START_BIT, s_TX_DATA, s_STOP_BIT, s_DONE);

    signal r_wait_counter : integer := c_BIT_DURATION;

    signal s_tx_state : t_TX_STATE;
    signal r_running  : std_logic := '0';
    signal r_done     : std_logic := '0';

    signal r_curr_bit_index : integer range 0 to 7 := 0;

    signal r_tx_data : std_logic_vector(7 downto 0) := (others => '0');
begin
    uart_tx_fsm_proc : process (i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_rst = '1') then
                s_tx_state       <= s_IDLE;
                r_wait_counter   <= 0;
                r_running        <= '0';
                r_done           <= '0';
                r_curr_bit_index <= 0;
                r_tx_data        <= (others => '0');
            else
                case s_tx_state is
                    when s_IDLE =>
                        r_running        <= '0';
                        r_done           <= '0';
                        r_wait_counter   <= 0;
                        r_curr_bit_index <= 0;

                        o_ser_data <= '1'; -- keep line HIGH -> IDLE

                        -- if start asserted
                        if (i_start = '1') then
                            r_tx_data  <= i_par_data;
                            s_tx_state <= s_START_BIT;
                        else
                            s_tx_state <= s_IDLE;
                        end if;

                    when s_START_BIT =>
                        -- start bit -> drive line to LOW
                        o_ser_data <= '0';
                        r_running  <= '1';

                        -- wait for start bit to finish
                        if (r_wait_counter < c_BIT_DURATION) then
                            r_wait_counter <= r_wait_counter + 1;
                            s_tx_state     <= s_START_BIT;
                        else
                            r_wait_counter <= 0;
                            s_tx_state     <= s_TX_DATA;
                        end if;

                    when s_TX_DATA =>
                        o_ser_data <= r_tx_data(r_curr_bit_index);

                        -- wait for the bit to finish
                        if (r_wait_counter < c_BIT_DURATION) then
                            r_wait_counter <= r_wait_counter + 1;
                            s_tx_state     <= s_TX_DATA;
                        else
                            r_wait_counter <= 0;

                            -- check where we are
                            if (r_curr_bit_index < 7) then
                                r_curr_bit_index <= r_curr_bit_index + 1;
                                s_tx_state       <= s_TX_DATA;
                            else
                                s_tx_state       <= s_STOP_BIT;
                                r_curr_bit_index <= 0;
                            end if;
                        end if;

                    when s_STOP_BIT =>
                        -- STOP BIT = '1'
                        o_ser_data <= '1';

                        -- wait for the stop bit to finish
                        if (r_wait_counter < c_BIT_DURATION) then
                            r_wait_counter <= r_wait_counter + 1;
                            s_tx_state     <= s_STOP_BIT;
                        else
                            r_wait_counter <= 0;
                            r_done         <= '1';
                            s_tx_state     <= s_DONE;
                        end if;

                    when s_DONE =>
                        r_done     <= '0';
                        r_running  <= '0';
                        s_tx_state <= s_IDLE;

                    when others =>
                        s_tx_state <= s_IDLE;
                end case;
            end if;
        end if;
    end process uart_tx_fsm_proc;
    
    o_running <= r_running;
    o_done    <= r_done;
end architecture;