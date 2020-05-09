----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/27/2020 07:58:35 PM
-- Design Name: 
-- Module Name: fsm_timer - Behavioral
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
--	 Modeled after the pb_debouncer from Lab 3
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

entity fsm_timer is
    Port ( -- Inputs
		   clk : in STD_LOGIC;								-- Global Clk
		   reset : in STD_LOGIC;							-- Async reset
           timer_start_flag : in STD_LOGIC;					-- Input that starts the timer
           timer_max : in STD_LOGIC_VECTOR (31 downto 0);	-- Input that the timer counts up to
           -- Outputs
		   timer_done_flag : out STD_LOGIC);				-- Output pulse lasting one clk period when timer finishes
end fsm_timer;

architecture Behavioral of fsm_timer is
	signal timer_clear: std_logic;
	signal timer_en : std_logic;
	signal timer_set: std_logic := '0';
	signal timer_finish : std_logic;
	signal timer_stop : std_logic := '0';
	--signal timer_max_q : unsigned (23 downto 0);
	signal timer_count : unsigned (31 downto 0);
begin

s_counter : process (clk, reset)
begin
	--timer_set <= '0';
	--timer_stop <= '0';
	if(reset = '1') then -- asynchronous clear
		timer_count <= (others => '0');
	elsif (rising_edge(clk)) then
		if (timer_clear = '1') then -- synchronous clear
			timer_count <= (others => '0');
		elsif (timer_en = '1') then -- If FSM enables start flag and the count is less than the max 
			timer_count <= timer_count + 1;
			timer_stop <= '0';
		elsif (timer_finish = '1') then
			timer_stop <= '1';
		end if;
	end if;
end process;		

c_counter : process (timer_count, timer_max, timer_start_flag)
begin
	timer_finish <= '0';
	timer_clear <= '0';
	timer_en <= '0';
	if (timer_start_flag = '1') then -- If FSM raises start flag
		--timer_max_q <= unsigned (timer_max);-- Latch the input max count into a register
		-- Need to see if I need to insert a small delay from the point at which the max val gets latched to where I can start comparing it
		if(timer_count < unsigned(timer_max)) then 
			timer_en <= '1';
		else
			timer_finish <= '1';
		end if;
	else
		timer_clear <= '1';
	end if;
end process;

timer_done_flag <= timer_start_flag  and  timer_finish and (not timer_stop);
end Behavioral;
