----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 04/26/2020 05:58:43 PM
-- Design Name: 
-- Module Name: bship_fsm - Behavioral
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

entity bship_fsm is
GENERIC ( y_max : integer := 14;
		  x_max : integer := 19);
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
		   start_signal: in STD_LOGIC;
		   timer_done_flag : in STD_LOGIC;
           latch_done_flag_p : in STD_LOGIC;
           latch_done_flag_o : in STD_LOGIC;
           --err_flag_p : in STD_LOGIC;
           --err_flag_o : in STD_LOGIC;
           hit_flag_p : in STD_LOGIC;
           hit_flag_o : in STD_LOGIC;
		   miss_flag_p : in STD_LOGIC;
		   miss_flag_o : in STD_LOGIC;
           lut_wr_en_p : out STD_LOGIC;
           lut_rd_en_p : out STD_LOGIC;
           lut_wr_en_o : out STD_LOGIC;
           lut_rd_en_o : out STD_LOGIC;
           bship_width_out : out STD_LOGIC_VECTOR (2 downto 0);
		   win_flag_out : out STD_LOGIC;
		   loss_flag_out : out STD_LOGIC;
		  -- cpu_latch_out : out STD_LOGIC;
		  -- cpu_x_pos_out : out STD_LOGIC_VECTOR (4 downto 0);
		  -- cpu_y_pos_out : out STD_LOGIC_VECTOR (4 downto 0);
		   timer_start_flag : out STD_LOGIC;
		   timer_max : out STD_LOGIC_VECTOR (31 downto 0)
		   );
end bship_fsm;

architecture Behavioral of bship_fsm is
	signal timer_en : std_logic; 									-- Enable FSM timer
	signal timer_start : std_logic:= '0';							-- Start the FSM timer
	signal timer_stop : std_logic:= '0';							-- Stop the FSM timer
	signal timer_max_set : unsigned (31 downto 0):= X"0000_0000";     -- Set the max count for the timer
	
	signal latch_done_flag_o_q, latch_done_flag_p_q : std_logic;
	-- game states
	type fsm_state is (
		INIT,
		PLACE_CARRIER,
		PLACE_BATTLESHIP,
		PLACE_DESTROYER,
		PLACE_SUBMARINE,
		PLACE_PT_BOAT,
		CPU_PLACE_CARRIER,
		CPU_PLACE_BATTLESHIP,
		CPU_PLACE_DESTROYER,
		CPU_PLACE_SUBMARINE,
		CPU_PLACE_PT_BOAT,
		PLAYER_MOVE,
		CPU_MOVE,
		CHK_HIT_CNT,
		WIN_STATE,
		LOSS_STATE);
	signal current_state : fsm_state;
	signal next_state : fsm_state;
	
	--CPU place ships vars
	-- type ship_sizes is array (0 to 4) of std_logic_vector (2 downto 0);
	-- signal cpu_ships : ship_sizes;
	-- signal cpu_x_pos, cpu_y_pos : unsigned (4 downto 0) := "00000";
	-- signal cpu_place_latch_d, cpu_place_latch_q, cpu_shoot_latch_d, cpu_shoot_latch_q : std_logic;
	-- signal cpu_place_finish : std_logic;
	
	-- Hit trackers
	signal player_hits : unsigned (4 downto 0) := "00000";
	signal cpu_hits : unsigned (4 downto 0) := "00000";
	
begin

-- -- Declare the sizes of the CPUs ships
-- cpu_ships(0) <= "101";
-- cpu_ships(1) <= "100";
-- cpu_ships(2) <= "011";
-- cpu_ships(3) <= "011";
-- cpu_ships(4) <= "010";
timer_start_flag <= std_logic (timer_start);
timer_max <= std_logic_vector(timer_max_set);
STATE_UPDATE : process (clk, reset)
begin
	if(reset = '1') then
		current_state <= INIT;
		latch_done_flag_o_q <= '0';
		latch_done_flag_p_q <= '0';
	elsif(rising_edge(clk)) then
		current_state <= next_state;
		latch_done_flag_o_q <= latch_done_flag_o;
		latch_done_flag_p_q <= latch_done_flag_p;
	end if;
end process;

MOORE_FSM : process (current_state, start_signal, latch_done_flag_p, latch_done_flag_o, miss_flag_o, miss_flag_p, timer_done_flag)
begin
	-- default states 
	timer_en <= '0';
	timer_max_set <= (others => '0');
	next_state <= current_state;
	lut_wr_en_p <= '0';
	lut_wr_en_o <= '0';
	lut_rd_en_p <= '0';
	lut_rd_en_o <= '0';
	bship_width_out <= "000";
	win_flag_out <= '0';
	loss_flag_out <= '0';
	case (current_state) is 
		when INIT =>
			if (start_signal = '1') then
				next_state <= PLACE_CARRIER;
			else
				next_state <= INIT;
			end if;
		when PLACE_CARRIER =>
			lut_wr_en_p <= '1';
			bship_width_out <= "101";
			if (latch_done_flag_p_q = '1') then
				next_state <= PLACE_BATTLESHIP;
			else
				next_state <= PLACE_CARRIER;
			end if;
		when PLACE_BATTLESHIP =>
			lut_wr_en_p <= '1';
			bship_width_out <= "100";
			if (latch_done_flag_p_q = '1') then 
				next_state <= PLACE_DESTROYER;
			else 
				next_state <= PLACE_BATTLESHIP;
			end if;
		when PLACE_DESTROYER =>
			lut_wr_en_p <= '1';
			bship_width_out <= "011";
			if (latch_done_flag_p_q = '1') then 
				next_state <= PLACE_SUBMARINE;
			else 
				next_state <= PLACE_DESTROYER;
			end if;
		when PLACE_SUBMARINE =>
			lut_wr_en_p <= '1';
			bship_width_out <= "011";
			if (latch_done_flag_p_q = '1') then
				next_state <= PLACE_PT_BOAT;
			else
				next_state <= PLACE_SUBMARINE;
			end if;
		when PLACE_PT_BOAT =>
			lut_wr_en_p <= '1';
			bship_width_out <= "010";
			if (latch_done_flag_p_q = '1') then
				next_state <= CPU_PLACE_CARRIER;
			else
				next_state <= PLACE_PT_BOAT;
			end if;
		when CPU_PLACE_CARRIER =>
			lut_wr_en_o <= '1';
			bship_width_out <= "101";
			if (latch_done_flag_o_q = '1') then
				next_state <= CPU_PLACE_BATTLESHIP;
			else
				next_state <= CPU_PLACE_CARRIER;
			end if;
		when CPU_PLACE_BATTLESHIP =>
			lut_wr_en_o <= '1';
			bship_width_out <= "100";
			if (latch_done_flag_o_q = '1') then
				next_state <= CPU_PLACE_DESTROYER;
			else
				next_state <= CPU_PLACE_BATTLESHIP;
			end if;
		when CPU_PLACE_DESTROYER =>
			lut_wr_en_o <= '1';
			bship_width_out <= "011";
			if (latch_done_flag_o_q = '1') then
				next_state <= CPU_PLACE_SUBMARINE;
			else
				next_state <= CPU_PLACE_DESTROYER;
			end if;
		when CPU_PLACE_SUBMARINE =>
			lut_wr_en_o <= '1';
			bship_width_out <= "011";
			if (latch_done_flag_o_q = '1') then
				next_state <= CPU_PLACE_PT_BOAT;
			else
				next_state <= CPU_PLACE_SUBMARINE;
			end if;
		when CPU_PLACE_PT_BOAT =>
			lut_wr_en_o <= '1';
			bship_width_out <= "010";
			if (latch_done_flag_o_q = '1') then
				next_state <= PLAYER_MOVE;
			else
				next_state <= CPU_PLACE_PT_BOAT;
			end if;
		when PLAYER_MOVE =>
			lut_rd_en_o <= '1'; -- read the opponent's LUT
			if (miss_flag_o = '1') then
				next_state <= CPU_MOVE;
			else
				next_state <= PLAYER_MOVE;
			end if;
		when CPU_MOVE =>
			lut_rd_en_p <= '1'; -- read the player's lut
			if (miss_flag_p = '1') then
				next_state <= CHK_HIT_CNT;
			else
				next_state <= CPU_MOVE;
			end if;
		when CHK_HIT_CNT =>
			if (cpu_hits = "10001") then 
				next_state <= WIN_STATE;
			elsif (player_hits = "10001") then
				next_state <= LOSS_STATE;
			else
				next_state <= PLAYER_MOVE;
			end if;
		when WIN_STATE =>
			timer_en <= '1';
			--timer_max_set <= X"59682F00" -- 15 seconds
			timer_max_set <= X"00000100"; -- for debug
			-- ??? Some indication of victory ???
			win_flag_out <= '1';
			if (timer_done_flag = '1') then 
				next_state <= INIT;
			else
				next_state <= WIN_STATE;
			end if;
		when LOSS_STATE =>
			timer_en <= '1';
			---timer_max_set <= X"59682F00" -- 15 seconds
			timer_max_set <= X"00000100"; -- for debug
			-- ??? Some indication of loss ???
			loss_flag_out <= '1';
			if (timer_done_flag = '1') then
				next_state <= INIT;
			else
				next_state <= LOSS_STATE;
			end if;
	end case;
end process;

-- For the purposes of demonstration, this will be a very *simple* placement algorithm
-- TODO: figure out pseudo-random seeding technique for ship placement 
-- cpu_latch_out <= (not cpu_place_latch_q and cpu_place_latch_d) or (not cpu_shoot_latch_q and cpu_shoot_latch_d); -- should issue a single pulse on each write to the LUT
-- CPU_PLACE_LOGIC : process (clk, reset, lut_wr_en_o, lut_rd_en_o, latch_done_flag_o)
-- variable j_iter : unsigned (2 downto 0) := "000";
-- begin
	-- if (reset = '1') then
		-- j_iter := "000";
		-- cpu_x_pos <= "00000";
		-- cpu_y_pos <= "00000";
		-- cpu_place_finish <= '0';
	-- elsif (rising_edge(clk)) then
		-- cpu_place_latch_q <= cpu_place_latch_d;
		-- if (lut_wr_en_o = '1' and lut_rd_en_o = '0') then
			-- if (cpu_place_latch_d = '1') then -- should reset the latch every other clk cycle
				-- cpu_place_latch_d <= '0';
			-- else
				-- if (j_iter < "101") then 
					-- bship_width_out <= cpu_ships (j_iter);
					-- cpu_place_latch_d <= '1';
					-- j_iter <= j_iter + 1;
					-- cpu_x_pos <= cpu_x_pos + 2; -- Shouldn't cause issues with overrun, max x and y are 10
					-- cpu_y_pos <= cpu_y_pos + 2;
				-- else
					-- cpu_place_finish <= '1';
					-- j_iter <= "000";
				-- end if;
			-- end if;
		-- else
			-- cpu_place_finish <= '0';
	-- end if;	
-- end process;
-- CPU_MOVE_LOGIC : process (clk, lut_rd_en_p)
-- begin
	-- if (rising_edge(clk)) then
		-- cpu_shoot_latch_q <= cpu_shoot_latch_d;	
		-- if (lut_rd_en_p = '1') then
			-- if (cpu_shoot_latch_d = '1'
			-- if (cpu_x_pos >= to_unsigned(x_max, 5) and cpu_y_pos <= to_unsigned(y_max)) then
				-- cpu_x_pos <= "00000";
				-- cpu_y_pos <= cpu_y_pos + 1;
			-- elsif cpu_x_pos >= to_unsigned(x_max, 5) and cpu_y_pos >= to_unsigned(y_max)
				-- cpu_x_pos <= "00000";
				-- cpu_y_pos <= "00000";
			-- else
				-- cpu_x_pos <= cpu_x_pos + 1;
			
-- end process; 
HIT_COUNTER : process (clk, reset, hit_flag_p, hit_flag_o)
begin
	if (reset = '1') then
		cpu_hits <= "00000";
		player_hits <= "00000";
	elsif (rising_edge(clk)) then
		if (hit_flag_p = '1') then
			player_hits <= player_hits + 1;
		elsif (hit_flag_o = '1') then 
			cpu_hits <= cpu_hits + 1;
		end if;
	end if;
end process;	

s_timer_ctrl : process(clk, reset) 
begin
	if (reset = '1') then
		timer_start <= '0';															-- Don't start the timer
		timer_stop <= '0';																-- Don't signal the timer is finished
	elsif (rising_edge(clk)) then
		if (timer_en = '1') then 														-- If I'm using the timer in this state,
			if(timer_done_flag = '1') then 													-- Wait for the timer to finish, 
				timer_stop <= '1';														-- And set a flag when it does.
			elsif (timer_stop = '1' and timer_done_flag = '0' and timer_start = '1') then 	-- Wait one clk cycle after the timer finishes...
				timer_start<= '0'; 													-- ... to disable the timer.
			else																		-- Otherwise, if the the timer is not finished and we don't have a flag set...
				timer_start <= '1';													-- ... assume the timer is not enabled and enable it now.
				timer_stop <= '0';														-- And make sure the stop flag is disabled.
			end if;
		else
			timer_start <= '0';														-- Don't start the timer
			timer_stop <= '0';															-- Don't signal the timer is finished
		end if;	
	end if;
end process;


end Behavioral;
