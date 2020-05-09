----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/05/2020 07:55:16 PM
-- Design Name: 
-- Module Name: seg7_scan - Behavioral
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
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity seg7_scan is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           pulse_in : in STD_LOGIC;
           select_out : out STD_LOGIC_VECTOR (2 downto 0));
end seg7_scan;

architecture Behavioral of seg7_scan is
    signal cntr : unsigned (2 downto 0) := "000";
    --signal sync_reset : std_logic;
begin
    process (clk, reset)
    begin
        if (reset = '1') 
        then 
            cntr <= (others => '0');
        elsif (rising_edge(clk))
        then 
--            if (sync_reset = '1')
--            then
--                cntr <= "000";
            if (pulse_in = '1')
            then
                cntr <= cntr +1;
            end if;
        end if;
    end process;
    -- cast the unsigned count as a std_logic_vector
    select_out <= std_logic_vector(cntr);
--    with cntr select select_out <=
--        "000" when "000",
--        "001" when "001",
--        "010" when "010",
--        "011" when "011",
--        "100" when "100",
--        "101" when "101", 
--        "110" when "110",
--        "111" when others;
        
end Behavioral;
