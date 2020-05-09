----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/16/2020 12:30:54 PM
-- Design Name: 
-- Module Name: vga_sync_ctrl - Behavioral
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

entity vga_sync_ctrl is
    Port ( -- Inputs
		   clk : in STD_LOGIC;
           reset : in STD_LOGIC;
		   pls_in : in STD_LOGIC;
           pixel_cnt : in STD_LOGIC_VECTOR (9 downto 0);
		   -- Counts for transitions between states
		   fr_p_cnt_max : in unsigned (9 downto 0);
		   sync_cnt_max : in unsigned (9 downto 0);
		   bk_p_cnt_max : in unsigned (9 downto 0);
		   disp_cnt_max : in unsigned (9 downto 0);
		   -- Outputs
           sync : out STD_LOGIC;
           disp_cnt : out STD_LOGIC_VECTOR (9 downto 0));
end vga_sync_ctrl;

architecture Behavioral of vga_sync_ctrl is
	-- signal state_reg: unsigned (1 downto 0):= "00"; -- reg for tracking state
	signal pixel_cnt_reg : unsigned (9 downto 0) := B"00_0000_0000";
	signal disp_cnt_reg : unsigned (9 downto 0):= B"00_0000_0000"; -- reg for output 
begin
	pixel_cnt_reg <= unsigned(pixel_cnt);
	sequential : process (clk, reset)
	begin
		if (reset = '1') then
			disp_cnt_reg <= (others => '0');
			sync <= '1';
		elsif (rising_edge(clk)) then
			if ((pixel_cnt_reg < fr_p_cnt_max) and (pixel_cnt_reg < sync_cnt_max) and (pixel_cnt_reg < bk_p_cnt_max) and (pixel_cnt_reg < disp_cnt_max)) then
				sync <= '1';
				disp_cnt_reg <= (others => '0');
			elsif ((pixel_cnt_reg > fr_p_cnt_max) and (pixel_cnt_reg < sync_cnt_max) and (pixel_cnt_reg < bk_p_cnt_max) and (pixel_cnt_reg < disp_cnt_max)) then
				sync <= '0';
				disp_cnt_reg <= (others => '0');
			elsif ((pixel_cnt_reg > fr_p_cnt_max) and (pixel_cnt_reg > sync_cnt_max) and (pixel_cnt_reg < bk_p_cnt_max) and (pixel_cnt_reg < disp_cnt_max)) then
				sync <= '1';
				disp_cnt_reg <= (others => '0');
			elsif ((pixel_cnt_reg > fr_p_cnt_max) and (pixel_cnt_reg > sync_cnt_max) and (pixel_cnt_reg > bk_p_cnt_max) and (pixel_cnt_reg < disp_cnt_max)) then
				sync <= '1';
				if (pls_in = '1') then
					disp_cnt_reg <= disp_cnt_reg + 1;
				end if;
			elsif (pixel_cnt_reg = disp_cnt_max) then
				sync <= '1';
				if (pls_in = '1') then
					disp_cnt_reg <= (others => '0');
				end if;
			else
				sync <= '1';
				disp_cnt_reg <= (others => '0');
			end if;
		end if;
	end process;
	-- state_machine : process (clk, reset)
	-- begin
		-- if (reset = '1') then
			-- state_reg <= "00"; -- reset the state machine
			-- disp_cnt_reg <= (others => '0');
			-- sync <= '1';
		-- elsif (rising_edge(clk)) then
			-- -- State 0: Front Porch
			-- if (state_reg = "00") then
				-- sync <= '1';
				-- disp_cnt_reg <= B"00_0000_0000";
				-- if (pixel_cnt = STD_LOGIC_VECTOR(fr_p_cnt_max)) then
					-- state_reg <= state_reg + 1;
				-- -- else
				-- --	state_reg <= "00";
				-- end if;
			-- -- State 1: Sync active
			-- elsif (state_reg = "01") then
				-- sync <= '0';
				-- disp_cnt_reg <= B"00_0000_0000";
				-- if (pixel_cnt = STD_LOGIC_VECTOR(sync_cnt_max)) then
					-- state_reg <= state_reg + 1;
				-- -- else 
				-- --	state_reg <= "01";
				-- end if;
		    -- -- State 2: Back Porch
			-- elsif (state_reg = "10") then
				-- sync <= '1';
				-- if (pixel_cnt = STD_LOGIC_VECTOR(bk_p_cnt_max)) then
					-- disp_cnt_reg <= B"00_0000_0000";
					-- state_reg <= state_reg + 1;
				-- -- else
				-- --	state_reg <= "10";
				-- end if; 
			-- -- State 3: Display Active
			-- elsif (state_reg = "11") then 
				-- sync <= '1';
				-- if (pixel_cnt = STD_LOGIC_VECTOR(disp_cnt_max)) then 
					-- -- if (pls_in = '1') then 
					-- state_reg <= B"00";
					-- -- else
					-- --	disp_cnt_reg <= disp_cnt_reg;
					-- disp_cnt_reg <= B"00_0000_0000";
				-- elsif (pls_in = '1') then 
						-- disp_cnt_reg <= disp_cnt_reg + 1; -- disp count will factor into the active display count
				-- end if;
				-- -- else
				-- --	state_reg <= "11";
				-- -- end if;
			-- end if;
		-- end if;
	-- end process;
	
	-- assignments
	disp_cnt <= STD_LOGIC_VECTOR (disp_cnt_reg);
		
end Behavioral;
