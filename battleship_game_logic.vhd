----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/28/2020 06:22:06 PM
-- Design Name: 
-- Module Name: battleship_game_logic - Behavioral
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

entity battleship_game_logic is
    Port ( -- Inputs
		   clk_logic : in STD_LOGIC;
           reset_logic : in STD_LOGIC;
		   start_signal_logic : in STD_LOGIC;
		   latch_in_logic : in STD_LOGIC;
		   transpose_logic_in : in STD_LOGIC;
           x_pos_cnt_logic_in : in STD_LOGIC_VECTOR (4 downto 0);
           y_pos_cnt_logic_in : in STD_LOGIC_VECTOR (4 downto 0);
		   -- Outputs
           win_flag_logic_out : out STD_LOGIC;
           loss_flag_logic_out : out STD_LOGIC;
           hit_flag_logic_out : out STD_LOGIC;
           miss_flag_logic_out : out STD_LOGIC;
		   latch_flag_logic_out : out STD_LOGIC;
		   err_flag_logic_out : out STD_LOGIC;
		   bship_width_logic_out : out STD_LOGIC_VECTOR (2 downto 0);
		   bship_draw_wr_en_logic_out : out STD_LOGIC;
		   bship_draw_rd_en_logic_out : out STD_LOGIC
		   );
end battleship_game_logic;

architecture Behavioral of battleship_game_logic is
	signal bship_width_bus : std_logic_vector (2 downto 0);
	
	-- timer ctrl signals
	signal timer_start_flag_log, timer_finish_flag_log : std_logic;
	signal timer_count_bus : std_logic_vector (31 downto 0);
	
	-- LUT ctrl signals
	signal lut_wr_en_o_logic, lut_rd_en_o_logic, lut_wr_en_p_logic, lut_rd_en_p_logic : std_logic; 
	signal latch_done_flag_o_log, latch_done_flag_p_log, hit_flag_p_log, hit_flag_o_log, miss_flag_p_log, miss_flag_o_log : std_logic;
	signal err_flag_p, err_flag_o : std_logic;
begin

-- Game Logic to Draw Truth table
-- lut_wr_p		lut_rd_p	lut_wr_o	lut_rd_o  /  draw_wr	draw_rd
--		  0			   0		   0		   0           0          0
--		  0 		   0           0           1		   0          1 -- Player trying to hit CPU ships
--        0            0           1           0           0          0
--        0            0           1           1           0          1 
--		  0			   1           0		   0           1		  1 


bship_draw_wr_en_logic_out <= '1' when (lut_wr_en_p_logic = '1' or (lut_rd_en_p_logic = '1' and lut_rd_en_o_logic = '0')) else '0';
bship_draw_rd_en_logic_out <= '1' when (lut_rd_en_p_logic = '1' or lut_rd_en_o_logic = '1') else '0';
bship_width_logic_out <= bship_width_bus;
hit_flag_logic_out <= hit_flag_p_log or hit_flag_o_log;
miss_flag_logic_out <= miss_flag_p_log or miss_flag_o_log;
latch_flag_logic_out <= latch_done_flag_p_log or latch_done_flag_o_log;

GAME_FSM : entity work.bship_fsm port map (
	clk => clk_logic,
	reset => reset_logic,
	start_signal => start_signal_logic,
	timer_done_flag => timer_finish_flag_log,
	latch_done_flag_p => latch_done_flag_p_log,
	latch_done_flag_o => latch_done_flag_o_log,
	hit_flag_p => hit_flag_p_log,
	hit_flag_o => hit_flag_o_log,
	miss_flag_p => miss_flag_p_log,
	miss_flag_o => miss_flag_o_log,
	lut_wr_en_p => lut_wr_en_p_logic,
	lut_rd_en_p => lut_rd_en_p_logic,
	lut_wr_en_o => lut_wr_en_o_logic,
	lut_rd_en_o => lut_rd_en_o_logic,
	bship_width_out => bship_width_bus,
	win_flag_out => win_flag_logic_out,
	loss_flag_out => loss_flag_logic_out,
	timer_start_flag => timer_start_flag_log,
	timer_max => timer_count_bus
);

FSM_TIMER : entity work.fsm_timer port map (
	clk => clk_logic,
	reset => reset_logic,
	timer_start_flag => timer_start_flag_log,
	timer_max => timer_count_bus,
	timer_done_flag => timer_finish_flag_log
);

err_flag_logic_out <= err_flag_p or err_flag_o;

PLAYER_POS_LUT : entity work.battleship_pos_lut port map ( 
	clk => clk_logic,
	reset => reset_logic,
	lut_wr_en_in => lut_wr_en_p_logic,
	lut_rd_en_in => lut_rd_en_p_logic,
	bship_width_in => unsigned(bship_width_bus),
	pos_x_in => x_pos_cnt_logic_in,
	pos_y_in => y_pos_cnt_logic_in,
	transpose_in => transpose_logic_in,
	latch_in => latch_in_logic,
	latch_done_flag => latch_done_flag_p_log,
	err_latch_flag => err_flag_p, -- not using error flag
	pos_hit_flag => hit_flag_p_log,
	pos_miss_flag => miss_flag_p_log
);

CPU_POS_LUT : entity work.battleship_pos_lut port map (
	clk => clk_logic,
	reset => reset_logic,
	lut_wr_en_in => lut_wr_en_o_logic,
	lut_rd_en_in => lut_rd_en_o_logic,
	bship_width_in => unsigned(bship_width_bus),
	pos_x_in => x_pos_cnt_logic_in,
	pos_y_in => y_pos_cnt_logic_in,
	transpose_in => transpose_logic_in,
	latch_in => latch_in_logic,
	latch_done_flag => latch_done_flag_o_log,
	err_latch_flag => err_flag_o, -- not using error flag
	pos_hit_flag => hit_flag_o_log,
	pos_miss_flag => miss_flag_o_log
);

end Behavioral;
