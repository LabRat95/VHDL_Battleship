----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/06/2020 09:08:44 AM
-- Design Name: 
-- Module Name: seg7_controller - Behavioral
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
use work.all;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity seg7_controller is
    Port ( clk_seg7_ctrl : in STD_LOGIC;
           reset_seg7_ctrl : in STD_LOGIC;
           digit_0 : in STD_LOGIC_VECTOR (3 downto 0);
           digit_1 : in STD_LOGIC_VECTOR (3 downto 0);
           digit_2 : in STD_LOGIC_VECTOR (3 downto 0);
           digit_3 : in STD_LOGIC_VECTOR (3 downto 0);
           digit_4 : in STD_LOGIC_VECTOR (3 downto 0);
           digit_5 : in STD_LOGIC_VECTOR (3 downto 0);
           digit_6 : in STD_LOGIC_VECTOR (3 downto 0);
           digit_7 : in STD_LOGIC_VECTOR (3 downto 0);
           cath_out_seg7_ctrl : out STD_LOGIC_VECTOR (7 downto 0);
           an_out_seg7_ctrl : out STD_LOGIC_VECTOR (7 downto 0));
end seg7_controller;

architecture Behavioral of seg7_controller is
    signal max_cntr_val : unsigned (31 downto 0) := X"000186A0";

    signal pulse_line : std_logic;
    signal select_bus : std_logic_vector (2 downto 0);
    signal digit_bus : std_logic_vector (3 downto 0);
begin
    one_khz_pls_gen: entity work.pulse_gen port map (
        clk => clk_seg7_ctrl,
        reset => reset_seg7_ctrl,
        max_count => max_cntr_val,
        pulse_out => pulse_line);
    seg7_arr_counter: entity work.seg7_scan port map (
        clk => clk_seg7_ctrl,
        reset => reset_seg7_ctrl,
        pulse_in => pulse_line,
        select_out => select_bus);
    seg7_anode_logic: entity work.seg7_scan_an_drive port map (
        reset => reset_seg7_ctrl,
        select_in => select_bus,
        an_out => an_out_seg7_ctrl);
    -- Four-bit wide 8to1 mux driven by select_bus
    with select_bus select digit_bus <=
        digit_0 when "000",
        digit_1 when "001",
        digit_2 when "010",
        digit_3 when "011",
        digit_4 when "100",
        digit_5 when "101",
        digit_6 when "110",
        digit_7 when others;
    seg7_cath_logic: entity work.seg7_hex port map (
        digit => digit_bus,
        seg7 => cath_out_seg7_ctrl);

end Behavioral;
