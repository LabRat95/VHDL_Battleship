----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/21/2020 08:35:41 PM
-- Design Name: 
-- Module Name: square_draw_logic - Behavioral
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

entity square_draw_logic is
    Port ( squ_pos_x : in STD_LOGIC_VECTOR (4 downto 0); -- position of the square in x space
           squ_pos_y : in STD_LOGIC_VECTOR (4 downto 0); -- position of the square in y space
		   row_cnt : in STD_LOGIC_VECTOR (9 downto 0); -- current row draw cnt of the VGA
           col_cnt : in STD_LOGIC_VECTOR (9 downto 0); -- current col draw cnt of the VGA
           sel_vga : out STD_LOGIC); -- signal out to select the color for the VGA from mux
end square_draw_logic;

architecture Behavioral of square_draw_logic is
	signal row_cnt_reg, col_cnt_reg : unsigned (9 downto 0);
	signal squ_pos_y_reg, squ_pos_x_reg : unsigned (4 downto 0);
	
begin
	-- store all of the vector input in regs for comparison op in comb. logic
	row_cnt_reg <= unsigned(row_cnt);
	col_cnt_reg <= unsigned(col_cnt);
	squ_pos_x_reg <= unsigned(squ_pos_x);
	squ_pos_y_reg <= unsigned(squ_pos_y);
	process (row_cnt_reg, col_cnt_reg) 
	begin
	if ((col_cnt_reg > B"00_0000_0000") and (col_cnt_reg < B"10_1000_0000") and (row_cnt_reg > B"00_0000_0000") and (row_cnt_reg < B"01_1110_0000")) then
		if ((col_cnt_reg(9 downto 5) = squ_pos_x_reg) and (row_cnt_reg(9 downto 5) = squ_pos_y_reg)) then
			sel_vga <= '1';
		else 
			sel_vga <= '0';
		end if;
	else 
		sel_vga <= '0';
	end if;
	end process;

end Behavioral;
