----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/05/2020 03:43:35 PM
-- Design Name: 
-- Module Name: pulse_gen - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity pulse_gen_10b is
    --Generic ( max_count : integer);
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           max_count : in unsigned (9 downto 0);
           pulse_out : out STD_LOGIC);
end pulse_gen_10b;

architecture Behavioral of pulse_gen_10b is
    signal cntr : unsigned(9 downto 0) := "0000000000";
    signal sync_reset: std_logic;
begin
    process (clk, reset)
    begin
       if (reset = '1') 
       then
           cntr <= (others => '0');
       elsif (rising_edge (clk))
       then
           if (sync_reset = '1')
           then
              cntr <= (others => '0');
           else
              cntr <= cntr +1;
           end if;
        end if;
     end process;
     
     sync_reset <= '1' when (cntr = max_count)
        else '0';
     pulse_out <= sync_reset;


end Behavioral;
