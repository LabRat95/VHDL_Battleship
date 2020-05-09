----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/17/2020 10:43:52 AM
-- Design Name: 
-- Module Name: vga_timing_ctrl - Behavioral
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

entity vga_timing_ctrl is
    Port ( clk_vga_timing : in STD_LOGIC;
           reset_vga_timing : in STD_LOGIC;
           h_sync : out STD_LOGIC;
           v_sync : out STD_LOGIC;
		   pixel_sync : out STD_LOGIC; -- 25MHz pulse out
		   disp_sync : out STD_LOGIC; -- rollover signal put out when the screen refreshes
           h_count : out STD_LOGIC_VECTOR (9 downto 0); -- display active line count
           v_count : out STD_LOGIC_VECTOR (9 downto 0)); -- display active pixel count 
end vga_timing_ctrl;

architecture Behavioral of vga_timing_ctrl is
	--constants
	constant max_count_25M : unsigned (9 downto 0) := B"00_0000_0011"; -- 3 dec
	constant max_col_cnt : unsigned (9 downto 0) := B"11_0001_1111"; -- 799 dec
	constant h_fr_p_cnt_max : unsigned (9 downto 0) := B"00_0000_1111"; -- 15 dec
	constant h_sync_cnt_max : unsigned (9 downto 0) := B"00_0110_1111"; -- 112 dec
	constant h_bk_p_cnt_max : unsigned (9 downto 0) := B"00_1001_1111"; -- 158 dec
	constant h_disp_cnt_max : unsigned (9 downto 0) := B"11_0001_1111"; -- 799 dec
	constant max_row_cnt : unsigned (9 downto 0) := B"10_0000_1100"; -- 524 dec
	constant v_fr_p_cnt_max : unsigned (9 downto 0) := B"00_0000_1001"; -- 9 dec
	constant v_sync_cnt_max : unsigned (9 downto 0) := B"00_0000_1100"; -- 12 dec
	constant v_bk_p_cnt_max : unsigned (9 downto 0) := B"00_0010_1100"; -- 45 dec
	constant v_disp_cnt_max : unsigned (9 downto 0) := B"10_0000_1100"; -- 524 dec
	--signals
	signal pls_out_25M : std_logic;
	-- signal pls_sync : std_logic;
	signal v_inc_pls : std_logic;
	signal col_count_out : std_logic_vector (9 downto 0);
	signal row_count_out : std_logic_vector (9 downto 0);
begin
	-- 25MHz pulse gen for column pixel counter
	pls_gen_25M : entity work.pulse_gen_10b port map (
		clk => clk_vga_timing,
		reset => reset_vga_timing,
		max_count => max_count_25M,
		pulse_out => pls_out_25M
	);
	pixel_sync <= pls_out_25M;
	-- Row/Col Counter
	row_col_cntr : entity work.two_d_counter_10b port map (
		clk => clk_vga_timing,
		reset => reset_vga_timing,
		pls_in => pls_out_25M,
		h_max => max_col_cnt,
		v_max => max_row_cnt,
		v_pls_out => v_inc_pls,
		reset_pls_out => disp_sync,
		h_count => col_count_out,
		v_count => row_count_out
	);

	-- VGA HSYNC Logic
	hsync_logic : entity work.vga_sync_ctrl port map (
		clk => clk_vga_timing,
		reset => reset_vga_timing,
		pls_in => pls_out_25M,
		pixel_cnt => col_count_out,
		-- params
		fr_p_cnt_max => h_fr_p_cnt_max,
		sync_cnt_max => h_sync_cnt_max,
		bk_p_cnt_max => h_bk_p_cnt_max,
		disp_cnt_max => h_disp_cnt_max,
		sync => h_sync,
		disp_cnt => h_count
	);

	-- VGA VSYNC Logic
	vsync_logic : entity work.vga_sync_ctrl port map (
		clk => clk_vga_timing,
		reset => reset_vga_timing,
		pls_in => v_inc_pls,
		pixel_cnt => row_count_out,
		-- params
		fr_p_cnt_max => v_fr_p_cnt_max,
		sync_cnt_max => v_sync_cnt_max,
		bk_p_cnt_max => v_bk_p_cnt_max,
		disp_cnt_max => v_disp_cnt_max,
		sync => v_sync,
		disp_cnt => v_count
	);
end Behavioral;
