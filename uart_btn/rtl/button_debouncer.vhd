library ieee;
use ieee.std_logic_1164.all;

entity button_debouncer is
    port (
        i_clk        : in std_logic;
        i_button     : in std_logic;
        o_deb_button : out std_logic
    );
end entity button_debouncer;

architecture rtl of button_debouncer is
    constant c_WAIT_LIMIT : integer                         := 1000000;
    signal r_wait_counter : integer range 0 to c_WAIT_LIMIT := 0;
    signal r_button_state : std_logic                       := '0'; -- initially open button

begin
    btn_deb_proc : process (i_clk)
    begin
        if rising_edge(i_clk) then
            if (r_wait_counter < c_WAIT_LIMIT and r_button_state /= i_button) then
                r_wait_counter <= r_wait_counter + 1;
            elsif (r_wait_counter = c_WAIT_LIMIT) then
                r_button_state <= i_button;
                r_wait_counter <= 0;
            else
                r_wait_counter <= 0;
            end if;
        end if;
    end process btn_deb_proc;

    o_deb_button <= r_button_state;
end architecture;