----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/29/2020 08:30:38 PM
-- Design Name: 
-- Module Name: battleship_top_level - Behavioral
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

entity battleship_top_level is
Port ( CLK100MHZ : in STD_LOGIC;
	   BTNU : in STD_LOGIC;
	   BTND : in STD_LOGIC;
	   BTNL : in STD_LOGIC;
	   BTNR : in STD_LOGIC;
	   BTNC : in STD_LOGIC;
	   SW : in STD_LOGIC_VECTOR (15 downto 0);
	   SEG7_CATH : out STD_LOGIC_VECTOR (7 downto 0);
	   AN : out STD_LOGIC_VECTOR (7 downto 0);
	   VGA_HS : out STD_LOGIC;
	   VGA_VS : out STD_LOGIC;
	   VGA_R : out STD_LOGIC_VECTOR (3 downto 0);
	   VGA_B : out STD_LOGIC_VECTOR (3 downto 0);
	   VGA_G : out STD_LOGIC_VECTOR (3 downto 0);
	   LED : out STD_LOGIC_VECTOR (15 downto 0)
	   );
end battleship_top_level;

architecture Behavioral of battleship_top_level is
	constant pb_hold_max : unsigned (31 downto 0) := X"004C4B40"; --  5,000,000 clks  - 20 Hz (5ms) sample rate
	constant x_count_max : unsigned (4 downto 0) := "10100";
	constant y_count_max : unsigned (4 downto 0) := "01111";
	
	-- Object Color Map
	constant bship_cursor_color : std_logic_vector(11 downto 0) := "111111110000"; -- LIGHT GREY?
	constant bship_color : std_logic_vector(11 downto 0) := "000011110000"; --blue
	constant miss_color : std_logic_vector(11 downto 0) := "111111111111";  --Green
	constant hit_color : std_logic_vector(11 downto 0) := "111100000000"; --Red
	constant t_cursor_color : std_logic_vector(11 downto 0):= "111100001111"; -- Yellow
	constant ocean_color : std_logic_vector(11 downto 0):= "000000000000"; -- Black
	
	-- Routing signals for game logic
	signal BTNU_db, BTND_db, BTNL_db, BTNR_db, BTNC_db : std_logic; -- debounced PBs
	signal squ_x_pos_out, squ_y_pos_out : std_logic_vector (4 downto 0);
	signal x_digit_0, x_digit_1, y_digit_0, y_digit_1 : std_logic_vector (3 downto 0);
	signal latch_in_top, miss_in_top, hit_in_top : std_logic;
	signal err_flag_top : std_logic;
	signal bship_width_bus_top : std_logic_vector (2 downto 0); 
	signal bship_wr_en_top, bship_rd_en_top : std_logic;
	signal win_indicator, loss_indicator : std_logic;
	
	-- VGA ctrl logic signal 
	signal vga_out_mux : std_logic_vector (11 downto 0); -- vga_out_chk comes from checkerboard, vga_out_mux from mux
	signal h_count_active: std_logic_vector (9 downto 0); -- active display pixel count
	signal v_count_active : std_logic_vector (9 downto 0); -- active display line count
	signal reset_graphics : std_logic;
	-- VGA color selection lines
	signal bship_cursor_sel_test, bship_sel_test, hit_sel_test, miss_sel_test, t_cursor_sel_test, back_sel_test : std_logic;
	
	-- Win/Loss counter logic
	signal win_cnt, loss_cnt : unsigned (7 downto 0):= "00000000";
	signal win_v0, win_v1, loss_v0, loss_v1 : std_logic_vector(3 downto 0); 
begin
-- Square Cursor Logic Begin
--Define the debounce circuits
BTNU_DEB : entity work.pb_debounce port map (
	clk => CLK100MHZ,
	reset => SW(0),
	pb_in => BTNU,
	hold_cnt_max => pb_hold_max,
	pbd_out => BTNU_db
);
BTND_DEB : entity work.pb_debounce port map (
	clk => CLK100MHZ,
	reset => SW(0),
	pb_in => BTND,
	hold_cnt_max => pb_hold_max,
	pbd_out => BTND_db
);
BTNL_DEB : entity work.pb_debounce port map (
	clk => CLK100MHZ,
	reset => SW(0),
	pb_in => BTNL,
	hold_cnt_max => pb_hold_max,
	pbd_out => BTNL_db
);
BTNR_DEB : entity work.pb_debounce port map (
	clk => CLK100MHZ,
	reset => SW(0),
	pb_in => BTNR,
	hold_cnt_max => pb_hold_max,
	pbd_out => BTNR_db
);
BTNC_DEB : entity work.pb_debounce port map (
	clk => CLK100MHZ,
	reset => SW(0),
	pb_in => BTNC,
	hold_cnt_max => pb_hold_max,
	pbd_out => BTNC_db
);

-- two d pos cntr
SQU_POS_REG : entity work.two_d_square_pos_reg port map (
	clk => CLK100MHZ,
	reset => SW(0),
	x_inc => BTNR_db,
	x_dec => BTNL_db,
	y_inc => BTND_db,
	y_dec => BTNU_db,
	x_max => x_count_max,
	y_max => y_count_max,
	squ_x_pos => squ_x_pos_out,
	squ_y_pos => squ_y_pos_out
);

-- map the digits from the counter to appropriate width signal for the seg7 ctrlr
x_digit_0 <= squ_x_pos_out(3 downto 0);
x_digit_1 <= '0' & '0' & '0' & squ_x_pos_out(4);
y_digit_0 <= squ_y_pos_out(3 downto 0);
y_digit_1 <= '0' & '0' & '0' & squ_y_pos_out(4); 

WIN_LOSS_CNTR: process (CLK100MHZ) 
begin
	if (rising_edge(CLK100MHZ)) then
		if (win_indicator = '1') then
			win_cnt <= win_cnt + 1;
		elsif (loss_indicator = '1') then 
			loss_cnt <= loss_cnt + 1;
		end if;
	end if;
end process;
win_v1 <= std_logic_vector(win_cnt(7 downto 4));
win_v0 <= std_logic_vector(win_cnt(3 downto 0));
loss_v1 <= std_logic_vector(loss_cnt(7 downto 4));

-- seg7 display controller
SEG7_DISP : entity work.seg7_controller port map (
	clk_seg7_ctrl => CLK100MHZ,
	reset_seg7_ctrl => SW(0),
	digit_0 => y_digit_0,
	digit_1 => y_digit_1,
	digit_2 => x_digit_0,
	digit_3 => x_digit_1,
	digit_4 => loss_v1(0) & loss_v0(3 downto 1),
	digit_5 => '0' & loss_v1(3 downto 1),
	digit_6 => win_v1(0) & win_v0(3 downto 1),
	digit_7 => '0' & win_v1(3 downto 1),
	cath_out_seg7_ctrl => SEG7_CATH,
	an_out_seg7_ctrl => AN
);

-- VGA Logic Begin
vga_timing_logic : entity work.vga_timing_ctrl port map (
	clk_vga_timing => CLK100MHZ,
	reset_vga_timing => '0',
	h_sync => VGA_HS,
	v_sync => VGA_VS,
	disp_sync => open,
	h_count => h_count_active,
	v_count => v_count_active
);
reset_graphics <= SW(0) or win_indicator or loss_indicator; -- will reset graphics registers when game finishes or there is a manual reset
-- VGA_logic End 
BSHIP_VGA_LOGIC : entity work.battleship_draw_logic port map (
	clk => CLK100MHZ,
	reset => reset_graphics,
	bship_width_in => bship_width_bus_top,
	bship_wr_en_in => bship_wr_en_top,
	bship_rd_en_in => bship_rd_en_top,
	pos_x_in => squ_x_pos_out,
	pos_y_in => squ_y_pos_out,
	transpose_in => SW(1),
	latch_in => BTNC_db,
	err_in => err_flag_top,
	miss_wr_in => miss_in_top,
	hit_wr_in => hit_in_top,
	row_cnt => v_count_active,
	col_cnt => h_count_active,
	bship_cursor_sel => bship_cursor_sel_test,
	bship_sel => bship_sel_test,
	hit_sel => hit_sel_test,
	miss_sel => miss_sel_test,
	t_cursor_sel => t_cursor_sel_test,
	back_sel => back_sel_test
);
-- Game logic
BSHIP_GAME_LOGIC : entity work.battleship_game_logic port map (
	clk_logic => CLK100MHZ,
	reset_logic => SW(0),
	start_signal_logic => BTNC_db,
	latch_in_logic => BTNC_db,
	transpose_logic_in => SW(1),
	x_pos_cnt_logic_in => squ_x_pos_out,
	y_pos_cnt_logic_in => squ_y_pos_out,
   -- Outputs
   win_flag_logic_out => win_indicator,
   loss_flag_logic_out => loss_indicator, 
   hit_flag_logic_out => hit_in_top,
   miss_flag_logic_out => miss_in_top,
   latch_flag_logic_out => open,
   err_flag_logic_out => err_flag_top,
   bship_width_logic_out => bship_width_bus_top,
   bship_draw_wr_en_logic_out => bship_wr_en_top,
   bship_draw_rd_en_logic_out => bship_rd_en_top
);
-- Decoder logic for bship width indicator
process (bship_width_bus_top)
begin
	case (bship_width_bus_top) is
		when "000" => LED(4 downto 0) <= "00000";
		when "001" => LED(4 downto 0) <= "00001";
		when "010" => LED(4 downto 0) <= "00011";
		when "011" => LED(4 downto 0) <= "00111";
		when "100" => LED(4 downto 0) <= "01111";
		when "101" => LED(4 downto 0) <= "11111";
		when others => LED(4 downto 0) <= "00000";
	end case;
end process;

vga_out_mux <= t_cursor_color when (t_cursor_sel_test = '1')
	--else back_mux;
	else bship_cursor_color when (bship_cursor_sel_test = '1')
	else bship_color when (bship_sel_test = '1')
	else miss_color when (miss_sel_test = '1')
	else hit_color when (hit_sel_test = '1')
	else ocean_color;
	
	
VGA_R <= vga_out_mux (11 downto 8);
VGA_B <= vga_out_mux (7 downto 4);
VGA_G <= vga_out_mux (3 downto 0);
end Behavioral;
