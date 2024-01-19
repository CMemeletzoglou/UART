library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_btn is
    generic (
        g_CLKS_PER_BIT : natural := 868
    );
    port (
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_btn : in std_logic;

        o_ser_data : out std_logic
    );
end entity uart_btn;

architecture rtl of uart_btn is
    constant c_MAX_MSG_LEN : integer := 150;
    
    constant c_RST_MSG_LEN : natural := 133;
    constant c_BTN_MSG_LEN : natural := 20;

    type t_CHAR_ARRAY is array (0 to c_MAX_MSG_LEN - 1) of std_logic_vector(7 downto 0);

    -- hold rst for 10 msec (visually delay the rst message)
    constant c_RST_WAIT  : integer                           := 10000000;

    -- the number of clock cycles that the debouncer waits before sampling the button signal
    constant c_DEB_CLK_CYCLES : integer := 1000000;

    constant c_rst_msg : t_CHAR_ARRAY :=
    (
        x"0A", -- LF
        x"0D", -- CR
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"0A", -- LF
        x"0D", -- CR
        x"50", -- P
        x"72", -- r        
        x"65", -- e
        x"73", -- s
        x"73", -- s
        x"20", -- space
        x"42", -- B
        x"54", -- T
        x"4E", -- N
        x"30", -- 0
        x"20", -- space
        x"74", -- t
        x"6F", -- o
        x"20", -- space
        x"64", -- d
        x"69", -- i
        x"73", -- s
        x"70", -- p
        x"6C", -- l
        x"61", -- a
        x"79", -- y
        x"20", -- space
        x"61", -- a
        x"20", -- space
        x"6D", -- m
        x"65", -- e
        x"73", -- s
        x"73", -- s
        x"61", -- a
        x"67", -- g
        x"65", -- e
        x"20", -- space
        x"66", -- f,
        x"72", -- r
        x"6F", -- o,
        x"6D", -- m,
        x"20", -- space
        x"55", -- U
        x"41", -- A
        x"52", -- R,
        x"54", -- T
        x"0A", -- LF
        x"0D", -- CR
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"2A", -- *
        x"0A", -- LF
        x"0D", -- CR      
        x"0A", -- LF
        x"0D", -- CR      
        others => (others => '0')
    );

    -- msg : Hello from UART!!\r\n
    constant c_btn_msg : t_CHAR_ARRAY :=
    (
        x"48", -- H
        x"65", -- e
        x"6C", -- l
        x"6C", -- l
        x"6F", -- o
        x"20", -- space
        x"66", -- f
        x"72", -- r
        x"6F", -- o
        x"6D", -- m
        x"20", -- space
        x"55", -- U
        x"41", -- A
        x"52", -- R
        x"54", -- T
        x"20", -- space
        x"21", -- !
        x"21", -- !
        x"0A", -- LF
        x"0D", -- CR
        others => (others => '0')
    );
    
    type t_BTN_FSM is (s_RST, s_IDLE, s_LOAD_CHAR, s_WAIT_TX_RUNNING, s_SEND_CHAR, s_WAIT_TX_DONE, s_CLEANUP);

    signal w_tx_running : std_logic;
    signal w_tx_done    : std_logic;

    signal w_deb_button : std_logic; -- debounced input button signal
    signal r_curr_btn_state : std_logic := '0'; -- the current registered input button state
    
    -- stores whether a button press was detected (button signal rising edge)
    signal r_btn_pressed : std_logic := '0'; 

    -- r_string contains the current character string to send over UART and
    -- r_string_len corresponds to the number of valid characters in the string.
    signal r_string     : t_CHAR_ARRAY := (others => (others => '0'));
    signal r_string_len : integer      := 0;

    -- r_curr_tx_byte contains the current byte/character that must be sent and
    -- r_curr_tx_byte_index is the byte's index inside the string under transmission.
    signal r_curr_tx_byte       : std_logic_vector(7 downto 0)           := (others => '0');
    signal r_curr_tx_byte_index : integer range 0 to (c_MAX_MSG_LEN - 1) := 0;

    signal r_tx_start : std_logic := '0'; -- UART Tx transmission start signal

    signal r_btn_fsm_state : t_BTN_FSM := s_RST;
    
    signal r_rst_counter : integer range 0 to c_RST_WAIT - 1 := 0;

begin
    button_debouncer : entity work.button_debouncer
        generic map(
            g_DEB_CLK_CYCLES => c_DEB_CLK_CYCLES
        )
        port map(
            i_clk        => i_clk,
            i_button     => i_btn,
            o_deb_button => w_deb_button
        );

    -- detect an input button press based on the last stored state of the inputs button's signal
    -- and the debounced button signal.
    -- If the latter is at '1' and the former is at '0', a button rising edge can be detected.
    button_press_detection_proc : process (i_clk)
    begin
        if rising_edge(i_clk) then
            r_curr_btn_state <= w_deb_button;
            r_btn_pressed      <= '0';

            if (r_curr_btn_state = '0' and w_deb_button = '1') then -- rising edge -> button press
                r_btn_pressed <= '1';
            end if;
        end if;
    end process button_press_detection_proc;

    btn_ctrl_fsm : process (i_clk)
    begin
        if rising_edge(i_clk) then
            if (i_rst = '1') then
                r_btn_fsm_state <= s_RST;
            else
                case r_btn_fsm_state is
                    when s_RST =>
                        r_curr_tx_byte       <= (others => '0');
                        r_curr_tx_byte_index <= 0;
                        r_tx_start           <= '0';
                        r_rst_counter        <= 0;

                        r_string     <= c_rst_msg;
                        r_string_len <= c_RST_MSG_LEN;

                        if (r_rst_counter < c_RST_WAIT - 1) then
                            r_rst_counter   <= r_rst_counter + 1;
                            r_btn_fsm_state <= s_RST;
                        else
                            r_btn_fsm_state <= s_LOAD_CHAR;
                        end if;


                    when s_IDLE =>
                        r_curr_tx_byte       <= (others => '0');
                        r_curr_tx_byte_index <= 0;
                        r_tx_start           <= '0';

                        r_string     <= c_btn_msg;
                        r_string_len <= c_BTN_MSG_LEN;

                        if (r_btn_pressed = '1') then -- button pressed -> load the first char                       
                            r_btn_fsm_state <= s_LOAD_CHAR;
                        else
                            r_btn_fsm_state <= s_IDLE;
                        end if;


                    when s_LOAD_CHAR =>
                        r_curr_tx_byte  <= r_string(r_curr_tx_byte_index);
                        r_btn_fsm_state <= s_WAIT_TX_RUNNING;


                    when s_WAIT_TX_RUNNING =>
                        r_btn_fsm_state <= s_WAIT_TX_RUNNING;
                        if (w_tx_running = '0') then -- TX not running -> we can send the next char
                            r_btn_fsm_state <= s_SEND_CHAR;
                        end if;


                    when s_SEND_CHAR =>
                        r_tx_start      <= '1'; -- activate the Tx
                        r_btn_fsm_state <= s_WAIT_TX_DONE;


                    when s_WAIT_TX_DONE =>
                        r_tx_start      <= '0';
                        r_btn_fsm_state <= s_WAIT_TX_DONE;
                        -- check if DONE
                        if (w_tx_done = '1') then
                            -- check if we can increment the byte index (i.e. if we have more bytes to send out)                            
                            if (r_curr_tx_byte_index < r_string_len - 1) then
                                r_curr_tx_byte_index <= r_curr_tx_byte_index + 1;
                                r_btn_fsm_state      <= s_LOAD_CHAR;
                            else -- all bytes sent out -> transmission done
                                r_btn_fsm_state <= s_CLEANUP;
                                r_rst_counter   <= 0;
                            end if;
                        end if;


                    when s_CLEANUP =>
                        r_curr_tx_byte_index <= 0;
                        r_btn_fsm_state      <= s_IDLE;


                    -- catch-all, should never get here
                    when others =>
                        r_btn_fsm_state <= s_IDLE;
                end case;
            end if;
        end if;
    end process btn_ctrl_fsm;

    uart_tx : entity work.uart_tx
        generic map(
            g_CLKS_PER_BIT => g_CLKS_PER_BIT
        )
        port map(
            i_clk      => i_clk,
            i_rst      => i_rst,
            i_start    => r_tx_start,
            i_par_data => r_curr_tx_byte,

            o_running  => w_tx_running,
            o_done     => w_tx_done,
            o_ser_data => o_ser_data
        );
end architecture;