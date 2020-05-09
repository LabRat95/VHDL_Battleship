----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/18/2020 05:49:08 PM
-- Design Name: 
-- Module Name: battleship_pos_lut - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 	LUT containing position of battleships set by player to be read by opponent.
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

entity battleship_pos_lut is
	GENERIC ( y_max : integer := 14;
			  x_max : integer := 19);
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
		   --Inputs
		   lut_wr_en_in : in STD_LOGIC; -- Write enable to the LUT
		   lut_rd_en_in : in STD_LOGIC; -- Read enable to the LUT
		   bship_width_in : in unsigned (2 downto 0); -- size of the battle ship to be entered into the LUT
           pos_x_in : in STD_LOGIC_VECTOR (4 downto 0); -- counter value for x axis
           pos_y_in : in STD_LOGIC_VECTOR (4 downto 0); -- counter value for y axis
		   transpose_in : in STD_LOGIC; -- input determines whether to place ship w/ vertical or horizontal alignment
		   latch_in : in STD_LOGIC; -- input for writing ship position data to memory space, should be one clk wide strobe 
		   
		   --Outputs
		   latch_done_flag : out STD_LOGIC; -- indicates that write to memory space was successful
		   err_latch_flag : out STD_LOGIC; -- indicates there was existing data in the memory space and the write was denied
		   pos_hit_flag : out STD_LOGIC; -- indicates that a read of memory space yielded a ship 
		   pos_miss_flag : out STD_LOGIC -- indicates that a read of memory space did not yield a ship
		   );
end battleship_pos_lut;

architecture Behavioral of battleship_pos_lut is
	type two_d_lut is array (0 to y_max) of std_logic_vector (x_max downto 0); -- define the 2D grid the game is played on
	signal battleship_pos : two_d_lut := (others => X"0_0000"); -- grid that contains the location of the player's ships
	signal battleship_shot_grid : two_d_lut := (others => X"0_0000"); -- grid that contains the history of the opponent's hits
	signal latch_done_flag_d, err_latch_flag_d, pos_hit_flag_d, pos_miss_flag_d : std_logic := '0'; -- flags for FSM logic inputs
	signal latch_done_flag_q, err_latch_flag_q, pos_hit_flag_q, pos_miss_flag_q : std_logic := '0'; -- flags for FSM logic outputs
	signal latch_in_q : std_logic;
begin
	LUT_WR_RD : process (clk, reset) -- Process guides Write and Read of the LUT
	variable j_iter : unsigned (2 downto 0):= "000";
	begin
		if (reset = '1') then -- Async Reset logic
			battleship_pos <= (others => X"0_0000");
			battleship_shot_grid <= (others => X"0_0000");
			latch_done_flag_d <= '0';
			err_latch_flag_d <= '0';
			pos_hit_flag_d <= '0';
			pos_miss_flag_d <= '0';
		elsif (rising_edge(clk)) then -- Sync Logic
		    latch_done_flag_q <= latch_done_flag_d; --Latch output of flag flip-flops with the inputs 
			err_latch_flag_q <= err_latch_flag_d;
			pos_hit_flag_q <= pos_hit_flag_d;
			pos_miss_flag_q <= pos_miss_flag_d;
			if (lut_wr_en_in = '1') then -- If the write enable is high (during the ship placement state) and the user presses the "execute" button
				if ( latch_in = '1') then
					latch_in_q <= '1';
				end if;
				if ((to_integer(unsigned(pos_x_in)) + to_integer(bship_width_in)) >= x_max) then -- check to make sure the array x accessor is  w/i bounds
					err_latch_flag_d <= '1';
				elsif (((to_integer(unsigned(pos_y_in)) + to_integer(bship_width_in)) >= y_max)) then -- check to make sure the array y accessor is  w/i bounds
					err_latch_flag_d <= '1'; 
				elsif ( latch_in_q = '1' ) then 
					-- if (battleship_pos(to_integer(unsigned(pos_y_in)))(to_integer(unsigned(pos_x_in))) = '1') then -- check to make sure a ship is not already there
						-- err_latch_flag_d <= '1';
						-- latch_in_q <= '0'
					-- if none of the error conditions are met, latch the position of the new ship
					if (transpose_in = '1') then -- determine whether the ship is being placed horizontal or vertical
						if (j_iter < bship_width_in) then
							battleship_pos (to_integer(unsigned(pos_y_in)))(to_integer(unsigned(pos_x_in) + j_iter)) <= '1';
							j_iter := j_iter + 1;
							latch_done_flag_d <= '0'; 
						else
							j_iter := "000";
							latch_in_q <= '0';
							latch_done_flag_d <= '1'; -- raise the flag that the write executed successfully
						end if;
						-- for i in 0 to (to_integer(bship_width_in) - 1) loop
							-- battleship_pos (to_integer(unsigned(pos_y_in)))(to_integer(unsigned(pos_x_in)) + i) <= '1';
						-- end loop;
					else
						if (j_iter < bship_width_in) then
							battleship_pos (to_integer(unsigned(pos_y_in) + j_iter))(to_integer(unsigned(pos_x_in))) <= '1';
							j_iter := j_iter + 1;
							latch_done_flag_d <= '0'; 
						else
							j_iter := "000";
							latch_in_q <= '0';
							latch_done_flag_d <= '1'; -- raise the flag that the write executed successfully
						end if;
						-- for i in 0 to (to_integer(bship_width_in) - 1) loop
							-- battleship_pos (to_integer(unsigned(pos_y_in)) + i)(to_integer(unsigned(pos_x_in))) <= '1';
						-- end loop;
					--end if;
					end if;
				end if;
			elsif (lut_rd_en_in = '1' and latch_in = '1') then
				latch_in_q <= '0';
				if (to_integer(unsigned(pos_x_in)) >= x_max) then -- check to make sure the array x accessor is  w/i bounds
					err_latch_flag_d <= '1';
				elsif (to_integer(unsigned(pos_y_in)) >= y_max) then -- check to make sure the array y accessor is  w/i bounds
					err_latch_flag_d <= '1'; 
				else
					if (battleship_shot_grid(to_integer(unsigned(pos_y_in)))(to_integer(unsigned(pos_x_in))) = '1') then
						err_latch_flag_d <= '1';
					else
						battleship_shot_grid(to_integer(unsigned(pos_y_in)))(to_integer(unsigned(pos_x_in))) <= '1';
						if (battleship_pos(to_integer(unsigned(pos_y_in)))(to_integer(unsigned(pos_x_in))) = '1') then
							pos_hit_flag_d <= '1';
						else 
							pos_miss_flag_d <= '1';
						end if;
					end if; 
				end if;
			else 
				latch_done_flag_d <= '0';
				err_latch_flag_d <= '0';
				pos_hit_flag_d <= '0';
				pos_miss_flag_d <= '0';
			end if;
		end if;
	end process;
	-- process (clk, reset)
	-- begin
		-- if (reset = '1') then
			-- latch_done_flag_q <= '0';
			-- err_latch_flag_q <= '0';
			-- pos_hit_flag_q <= '0';
			-- pos_miss_flag_q <= '0';
		-- elsif (rising_edge(clk)) then
			-- latch_done_flag_q <= latch_done_flag_d;
			-- err_latch_flag_q <= err_latch_flag_d;
			-- pos_hit_flag_q <= pos_hit_flag_d;
			-- pos_miss_flag_q <= pos_miss_flag_d;
		-- end if;
	-- end process;
	latch_done_flag <= not latch_done_flag_q and latch_done_flag_d ;
	err_latch_flag <= not err_latch_flag_q and err_latch_flag_d;
	pos_hit_flag <= not pos_hit_flag_q and pos_hit_flag_d;
	pos_miss_flag <= not  pos_miss_flag_q and pos_miss_flag_d;
end Behavioral;

