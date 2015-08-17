--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   16:31:53 08/04/2015
-- Design Name:   
-- Module Name:   D:/B_ise/BelleII/simulation/vhdl/tlu_tb.vhd
-- Project Name:  simulation
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: tlu_control
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tlu_tb IS
END tlu_tb;
 
ARCHITECTURE behavior OF tlu_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT tlu_control
    PORT(
         clk : IN  std_logic;
         rst : IN  std_logic;
         clk_slow_down_factor : IN  std_logic_vector(5 downto 0);
         timeout_factor : IN  std_logic_vector(31 downto 0);
         tn2a_default : IN  std_logic_vector(31 downto 0);
         trg_cnt_default : IN  std_logic_vector(31 downto 0);
         tlu_reset : IN  std_logic;
         tlu_trigger : IN  std_logic;
         tlu_trigger_clk : OUT  std_logic;
         tlu_busy : OUT  std_logic;
         ts_2tu : OUT  std_logic;
         ts_2a : OUT  std_logic;
         tn2a : OUT  std_logic_vector(31 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal clk_slow_down_factor : std_logic_vector(5 downto 0) := b"000000";
   signal timeout_factor : std_logic_vector(31 downto 0) := x"0000_0014";
   signal tn2a_default : std_logic_vector(31 downto 0) := x"0000_A000";
   signal trg_cnt_default : std_logic_vector(31 downto 0) := x"0000_00A0";
   signal tlu_reset : std_logic := '0';
   signal tlu_trigger : std_logic := '0';

 	--Outputs
   signal tlu_trigger_clk : std_logic;
   signal tlu_busy : std_logic;
   signal ts_2tu : std_logic;
   signal ts_2a : std_logic;
   signal tn2a : std_logic_vector(31 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
   constant clk_slow_down_factor_period : time := 10 ns;
   constant tlu_trigger_clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: tlu_control PORT MAP (
          clk => clk,
          rst => rst,
          clk_slow_down_factor => clk_slow_down_factor,
          timeout_factor => timeout_factor,
          tn2a_default => tn2a_default,
          trg_cnt_default => trg_cnt_default,
          tlu_reset => tlu_reset,
          tlu_trigger => tlu_trigger,
          tlu_trigger_clk => tlu_trigger_clk,
          tlu_busy => tlu_busy,
          ts_2tu => ts_2tu,
          ts_2a => ts_2a,
          tn2a => tn2a
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
--   clk_slow_down_factor_process :process
--   begin
--		clk_slow_down_factor <= '0';
--		wait for clk_slow_down_factor_period/2;
--		clk_slow_down_factor <= '1';
--		wait for clk_slow_down_factor_period/2;
--   end process;
-- 
--   tlu_trigger_clk_process :process
--   begin
--		tlu_trigger_clk <= '0';
--		wait for tlu_trigger_clk_period/2;
--		tlu_trigger_clk <= '1';
--		wait for tlu_trigger_clk_period/2;
--   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		rst <= '1';
      wait for 1000 ns;	
		rst <= '0';
      wait;
   end process;

   trigger_stim_proc: process
   begin		
      -- hold reset state for 100 ns.
		tlu_trigger <= '0';
      wait for 2100 ns;	
		tlu_trigger <= '1';
      wait for 350 ns;
		tlu_trigger <= '0';
		wait for 2 us;
		tlu_trigger <= '0';
		tlu_reset <= '1';
		wait for  1 us;
		tlu_trigger <= '0';
		tlu_reset <= '0';
		wait for 10 us;
		tlu_trigger <= '1';
		wait for 500 ns;
		tlu_trigger <= '0';
		wait;
   end process;
END;
