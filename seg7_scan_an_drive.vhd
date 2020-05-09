----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/06/2020 08:13:56 AM
-- Design Name: 
-- Module Name: seg7_scan_an_drive - Behavioral
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity seg7_scan_an_drive is
    Port ( reset : in STD_LOGIC;
           select_in : in STD_LOGIC_VECTOR (2 downto 0);
           an_out : out STD_LOGIC_VECTOR (7 downto 0));
end seg7_scan_an_drive;
    
architecture Behavioral of seg7_scan_an_drive is
    signal an_set : std_logic_vector (7 downto 0);
   
begin
    with select_in select an_set <=
        X"01" when "000",
        X"02" when "001",
        X"04" when "010",
        X"08" when "011",
        X"10" when "100",
        X"20" when "101",
        X"40" when "110",
        X"80" when others;
    an_out <= X"00" when reset = '1'
        else not an_set;
end Behavioral;
