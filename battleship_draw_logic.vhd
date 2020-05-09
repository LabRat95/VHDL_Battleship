----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/20/2020 07:41:33 PM
-- Design Name: 
-- Module Name: battleship_draw_logic - Behavioral
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

entity battleship_draw_logic is
GENERIC ( y_max : integer := 14;
		  x_max : integer := 19);
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
		   -- state machine variables
           bship_width_in : in STD_LOGIC_VECTOR (2 downto 0);
           bship_wr_en_in : in STD_LOGIC;
		   bship_rd_en_in : in STD_LOGIC;
		   -- player control signals
		   pos_x_in : in STD_LOGIC_VECTOR (4 downto 0);
           pos_y_in : in STD_LOGIC_VECTOR (4 downto 0);
           transpose_in : in STD_LOGIC;
		   -- signals ported from the position lut
           latch_in : in STD_LOGIC; -- latch_done_flag from pos rom
		   err_in : in STD_LOGIC;
		   miss_wr_in : in STD_LOGIC; -- miss flag from pos rom
		   hit_wr_in : in STD_LOGIC; -- hit flag from pos rom 
		   -- VGA counts 
           row_cnt : in STD_LOGIC_VECTOR (9 downto 0);
           col_cnt : in STD_LOGIC_VECTOR (9 downto 0);
		   -- Graphics overlay flags
		   --bship_place_finish : out STD_LOGIC;
		   bship_cursor_sel : out STD_LOGIC;
           bship_sel : out STD_LOGIC;
           hit_sel : out STD_LOGIC;
           miss_sel : out STD_LOGIC;
           t_cursor_sel : out STD_LOGIC;
		   back_sel : out STD_LOGIC);
end battleship_draw_logic;

architecture Behavioral of battleship_draw_logic is
	type two_d_lut is array (0 to y_max) of std_logic_vector (x_max downto 0); -- define the 2D grid the game is played on
	signal battleship_cursor : two_d_lut := (others => X"0_0000"); -- grid that contains the location of the player's ship before it's placed
	signal battleship_pos : two_d_lut := (others => X"0_0000"); -- grid that contains the location of the player's ships
	signal battleship_hit_grid_p : two_d_lut := (others => X"0_0000"); -- grid that contains the history of the opponent's hits
	signal battleship_miss_grid_p : two_d_lut := (others => X"0_0000"); -- grid that contains the history of the opponent's misses
	signal battleship_hit_grid_o : two_d_lut := (others => X"0_0000"); -- grid that contains the history of the player's hits
	signal battleship_miss_grid_o : two_d_lut := (others => X"0_0000"); -- grid that contains the history of the player's misses
	signal target_cursor : two_d_lut := (others => X"0_0000"); -- grid that contains the location of the player's ship before it's placed
	signal player_placement_en : std_logic;
	signal cpu_strike_en : std_logic;
	signal player_strike_en : std_logic;
	--flip-flops for position and bship width
	signal pos_x_in_q, pos_y_in_q : unsigned (4 downto 0) := (others => '0');
	--signal bship_width_in_d, bship_width_in_q : unsigned (2 downto 0) := (others => '0');
	signal clr_cursor : std_logic := '0'; -- active-high blanking of the display cursor
	signal latch_in_q : std_logic := '0';
	signal transpose_in_q : std_logic := '0';
	constant row_cnt_max : std_logic_vector := B"01_1101_1111";
begin

player_placement_en <= bship_wr_en_in and not bship_rd_en_in;
cpu_strike_en <= bship_wr_en_in and bship_rd_en_in;
player_strike_en <= not bship_wr_en_in and bship_rd_en_in;


LUT : process (reset, clk) 
--variable Xds, Xqs, Yds, Yqs : signed (5 downto 0); 
--variable pos_x_delta, pos_y_delta : signed (5 downto 0);
variable pos_x_in_int, pos_y_in_int : integer;
variable i_iter, j_iter, bship_width_in_q : unsigned(2 downto 0):= (others => '0');
--variable latch_in_q : std_logic:= '0';
begin
	if (reset = '1') then
		battleship_pos <= (others => X"0_0000");
		battleship_hit_grid_p <= (others => X"0_0000");
		battleship_miss_grid_p <= (others => X"0_0000");
		battleship_hit_grid_o <= (others => X"0_0000");
		battleship_miss_grid_o <= (others => X"0_0000");
		battleship_cursor <= (others => X"0_0000");
		target_cursor <= (others => X"0_0000");
		pos_x_in_q <= (others => '0');
		pos_y_in_q <= (others => '0');
		bship_width_in_q := (others => '0');
	elsif (rising_edge(clk)) then
		-- if (row_cnt = row_cnt_max) then
			-- clr_cursor <= not clr_cursor;
		-- end if;
		pos_x_in_int := to_integer(unsigned(pos_x_in));
		pos_y_in_int := to_integer(unsigned(pos_y_in));
		bship_width_in_q := unsigned(bship_width_in);
		pos_x_in_q <= unsigned(pos_x_in);
		pos_y_in_q <= unsigned(pos_y_in);
		transpose_in_q <= transpose_in;
		if ((pos_x_in_q /= unsigned(pos_x_in)) or (pos_y_in_q /= unsigned(pos_y_in)) or (transpose_in_q /= transpose_in)) then
			clr_cursor <= '1';
		else 
			clr_cursor <= '0';
		end if;
		if (player_placement_en = '1') then -- If we're in the state where the player is moving the ship  
			-- Logic for writing ship permanent position
			if (latch_in = '1') then
				latch_in_q <= '1';
			elsif (latch_in_q = '1' and err_in = '0') then -- and (battleship_pos(pos_y_in_int)(pos_x_in_int) /= '1')) then
				if (transpose_in = '1') then 
					if (j_iter < (bship_width_in_q)) then
						battleship_pos (pos_y_in_int)(pos_x_in_int + to_integer(j_iter)) <= '1';
						j_iter := j_iter + 1;
					else
						j_iter := "000";
						latch_in_q <= '0';
					end if;
				elsif (transpose_in = '0') then
					if (j_iter < (bship_width_in_q)) then
						battleship_pos (pos_y_in_int + to_integer(j_iter))(pos_x_in_int) <= '1';
						j_iter := j_iter + 1;
					else 
						j_iter := "000";
						latch_in_q <= '0';
					end if;
				end if;
			end if;
			-- Logic for writing ship temp position
			if (clr_cursor = '0') then -- if not blanking interval
				-- Check if we're near a board edge
				if (((pos_x_in_q + to_integer(bship_width_in_q)) > (x_max + 1)) and transpose_in = '1') then
					if (i_iter < to_unsigned(x_max - pos_x_in_int, 3)) then
						battleship_cursor (pos_y_in_int)(pos_x_in_int + to_integer(i_iter)) <= '1';
						i_iter := i_iter + 1;
					else 
						i_iter := "000";
					end if;
				elsif (((pos_y_in_q + to_integer(bship_width_in_q)) > (y_max + 1)) and transpose_in = '0') then -- conditional to deal with ships placed near the y max bound
					if (i_iter < to_unsigned(y_max - pos_y_in_int, 3)) then
						battleship_cursor (pos_y_in_int + to_integer(i_iter))(pos_x_in_int) <= '1';
						i_iter := i_iter + 1;
					else 
						i_iter := "000";
					end if;
				else
					if (transpose_in = '1') then 
						if (i_iter < (bship_width_in_q)) then
							battleship_cursor (pos_y_in_int)(pos_x_in_int + to_integer(i_iter)) <= '1';
							i_iter := i_iter + 1;
						else 
							i_iter := "000";
						end if;
					elsif (transpose_in = '0') then
						if (i_iter < (bship_width_in_q)) then
							battleship_cursor (pos_y_in_int + to_integer(i_iter))(pos_x_in_int) <= '1';
							i_iter := i_iter + 1;
						else 
							i_iter := "000";
						end if;
					end if;
				end if;
			elsif (clr_cursor = '1') then -- If blanking interval
				battleship_cursor <= (others => X"0_0000");
			end if;
		elsif (cpu_strike_en = '1') then -- the part where the CPU is trying to hit the player
			if (hit_wr_in = '1') then
				battleship_hit_grid_p(pos_y_in_int)(pos_x_in_int) <= '1';
			elsif (miss_wr_in = '1') then 
				battleship_miss_grid_p(pos_y_in_int)(pos_x_in_int) <= '1';
			end if;
		elsif (player_strike_en = '1') then -- the part where the player is trying to hit the CPU
			if (hit_wr_in = '1') then
				battleship_hit_grid_o(pos_y_in_int)(pos_x_in_int) <= '1';
			end if;
			if (miss_wr_in = '1') then 
				battleship_miss_grid_o(pos_y_in_int)(pos_x_in_int) <= '1';
			end if;
			if (clr_cursor = '0') then -- if not blanking interval
				--clr_cursor <= '1';
				target_cursor (pos_y_in_int)(pos_x_in_int) <= '1';
			elsif (clr_cursor = '1') then 
				target_cursor <= (others => X"0_0000");
				--clr_cursor <= '0';
			end if;
		else
			--...
		end if;	
	end if;
end process;	

DRAW : process (row_cnt, col_cnt, bship_wr_en_in, bship_rd_en_in) 
begin
	if ((col_cnt > B"00_0000_0000") and (col_cnt < B"10_1000_0000") and (row_cnt> B"00_0000_0000") and (row_cnt< B"01_1110_0000")) then
		if (bship_wr_en_in = '1' and bship_rd_en_in = '0') then  -- Phase of the game where the player is placing the ship 
			t_cursor_sel <= '0';
			hit_sel <= '0';
			miss_sel <= '0';
			if (battleship_cursor(to_integer(unsigned(row_cnt(9 downto 5))))(to_integer(unsigned(col_cnt(9 downto 5))))  = '1') then
				bship_cursor_sel <= '1';
				bship_sel <= '0';
				back_sel <= '0';
			elsif (battleship_pos(to_integer(unsigned(row_cnt(9 downto 5))))(to_integer(unsigned(col_cnt(9 downto 5)))) = '1') then
				bship_cursor_sel <= '0';
				bship_sel <= '1';
				back_sel <= '0';
			else 
				bship_cursor_sel <= '0';
				bship_sel <= '0';
				back_sel <= '1';
			end if;
		elsif (bship_wr_en_in = '1' and bship_rd_en_in = '1') then -- Phase of the game where the CPU is selecting where to hit the player
			t_cursor_sel <= '0';
			bship_cursor_sel <= '0';
			if (battleship_hit_grid_p(to_integer(unsigned(row_cnt(9 downto 5))))(to_integer(unsigned(col_cnt(9 downto 5)))) = '1') then 
				bship_sel <= '0';
				hit_sel <= '1';
				miss_sel <= '0';
				back_sel <= '0';
			elsif (battleship_miss_grid_p(to_integer(unsigned(row_cnt(9 downto 5))))(to_integer(unsigned(col_cnt(9 downto 5)))) = '1') then 
				bship_sel <= '0';
				hit_sel <= '0';
				miss_sel <= '1';
				back_sel <= '0';
			elsif (battleship_pos(to_integer(unsigned(row_cnt(9 downto 5))))(to_integer(unsigned(col_cnt(9 downto 5)))) = '1') then
				bship_sel <= '1';
				hit_sel <= '0';
				miss_sel <= '0';
				back_sel <= '0';
			else 
				bship_sel <= '0';
				hit_sel <= '0';
				miss_sel <= '0';
				back_sel <= '1';
			end if;
		elsif (bship_wr_en_in = '0' and bship_rd_en_in = '1') then -- Phase where the player is selecting where to hit the CPU's ship
			bship_cursor_sel <= '0';
			bship_sel <= '0';
			if (target_cursor(to_integer(unsigned(row_cnt(9 downto 5))))(to_integer(unsigned(col_cnt(9 downto 5)))) = '1') then
				t_cursor_sel <= '1';
				hit_sel <= '0';
				miss_sel <= '0';
				back_sel <= '0';
			elsif (battleship_hit_grid_o(to_integer(unsigned(row_cnt(9 downto 5))))(to_integer(unsigned(col_cnt(9 downto 5)))) = '1') then 
				t_cursor_sel <= '0';
				hit_sel <= '1';
				miss_sel <= '0';
				back_sel <= '0';
			elsif (battleship_miss_grid_o(to_integer(unsigned(row_cnt(9 downto 5))))(to_integer(unsigned(col_cnt(9 downto 5)))) = '1') then 
				t_cursor_sel <= '0';
				hit_sel <= '0';
				miss_sel <= '1';
				back_sel <= '0';
			else 
				t_cursor_sel <= '0';
				hit_sel <= '0';
				miss_sel <= '0';
				back_sel <= '1';
			end if;
		else 
			t_cursor_sel <= '0';
			hit_sel <= '0';
			miss_sel <= '0';
			bship_cursor_sel <= '0';
			bship_sel <= '0';
			back_sel <= '1';
		end if;
	else 
		t_cursor_sel <= '0';
		hit_sel <= '0';
		miss_sel <= '0';
		bship_cursor_sel <= '0';
		bship_sel <= '0';
		back_sel <= '0';
	end if;
end process;
end Behavioral;

