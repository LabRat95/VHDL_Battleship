----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/20/2020 08:03:38 PM
-- Design Name: 
-- Module Name: pb_debounce - Behavioral
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

entity pb_debounce is
    Port ( clk : in STD_LOGIC;
           reset : in STD_LOGIC;
           pb_in : in STD_LOGIC;
           hold_cnt_max : in unsigned (31 downto 0);
           pbd_out : out STD_LOGIC);
end pb_debounce;

architecture Behavioral of pb_debounce is
	--constant pb_count_max : unsigned (3 downto 0) := "0100";
	--signal pb_count : unsigned (3 downto 0) := "0000";
	signal pb_set : STD_LOGIC := '0';
	signal pb_hold : STD_LOGIC := '0';
	--signal pbd_out_reg : STD_LOGIC := '0';
	--signal pb_wait : std_logic := '0';
	signal pb_en : STD_LOGIC := '0';
    signal sync_reset : STD_LOGIC;
	signal hold_cntr : unsigned (31 downto 0) := (others => '0');
begin
	s_count : process (clk, reset) 
	begin
		--pb_hold <= '0';
		if (reset = '1') then
			hold_cntr <= (others => '0');
		elsif(rising_edge(clk)) then 
			if (sync_reset = '1') then
				hold_cntr <= (others => '0');
			elsif (pb_en = '1') then -- pushbutton detected
				hold_cntr <= hold_cntr + 1;
				pb_hold <= '0';
			elsif (pb_set = '1') then -- pushbutton debounce complete
				pb_hold <= '1';
			end if;
		end if;
	end process;
	
	c_compare : process (pb_in, hold_cntr)
	begin
		--pbd_out <= '0';
		pb_en <= '0';
		pb_set <= '0';
		sync_reset <= '0';
		if (pb_in = '1') then 
			if (hold_cntr < hold_cnt_max) then
				pb_en <= '1';
				-- pb_hold <= '0';
			elsif (hold_cntr < hold_cnt_max) then
				pb_en <= '0';
			else -- at max hold cnt 
				pb_set <= '1';
			end if;
		else 
			sync_reset <= '1';
			--pbd_out_reg <= '0';
		end if;
	end process;

	-- s_pb_count_out: process (clk, pb_in, pb_set)
	-- begin
		-- --pbd_out_reg <= '0';
		-- --pb_count <= "0000";
		-- --pbd_hold <= '0';
		-- if(rising_edge(clk)) then
			-- if (pb_set = '1') then
				-- if (pb_count < pb_count_max) then 
					-- pb_count <= pb_count + 1;
					
				-- else 
					-- pbd_out_reg <= '1';
					-- pb_count <= (others => '0');
					-- --pb_set <= '0';
				-- end if;
				-- --pb_hold <= '1';
				-- --pb_set <= '0';
			-- end if;
		-- end if;
	-- end process; 
	
	pbd_out <= pb_in and pb_set and (not pb_hold) ;
end Behavioral;
