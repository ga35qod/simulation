--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   12:07:05 08/05/2015
-- Design Name:   
-- Module Name:   D:/B_ise/BelleII/simulation/vhdl/lemo_trg_cntr_tb.vhd
-- Project Name:  simulation
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: lemo_trg_cntr
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
 
ENTITY lemo_trg_cntr_tb IS
END lemo_trg_cntr_tb;
 
ARCHITECTURE behavior OF lemo_trg_cntr_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT lemo_trg_cntr
    PORT(
         clk_i : IN  std_logic;
         rst_i : IN  std_logic;
         veto_i : IN  std_logic;
         trg_i : IN  std_logic;
         veto_o : OUT  std_logic;
         trg_o : OUT  std_logic;
         trg_nmb_o : OUT  std_logic_vector(31 downto 0);
         trigger_nr_lemo_en_o : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk_i : std_logic := '0';
   signal rst_i : std_logic := '0';
   signal veto_i : std_logic := '0';
   signal trg_i : std_logic := '0';

 	--Outputs
   signal veto_o : std_logic;
   signal trg_o : std_logic;
   signal trg_nmb_o : std_logic_vector(31 downto 0);
   signal trigger_nr_lemo_en_o : std_logic;

   -- Clock period definitions
   constant clk_i_period : time := 10 ns;
   constant trg_i_period : time := 10 us;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: lemo_trg_cntr PORT MAP (
          clk_i => clk_i,
          rst_i => rst_i,
          veto_i => veto_i,
          trg_i => trg_i,
          veto_o => veto_o,
          trg_o => trg_o,
          trg_nmb_o => trg_nmb_o,
          trigger_nr_lemo_en_o => trigger_nr_lemo_en_o
        );

   -- Clock process definitions
   clk_i_process :process
   begin
		clk_i <= '0';
		wait for clk_i_period/2;
		clk_i <= '1';
		wait for clk_i_period/2;
   end process;
 

   -- Stimulus process
   rst_stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      rst_i <= '0';
		wait for 100 ns;
		rst_i <= '1';
		wait for 10 us;
		rst_i <= '0';
      wait;
   end process;

   trg_stim_proc: process
   begin		
      -- hold reset state for 100 ns.
--      trg_i <= '0';
--		wait for 1 us;
--		trg_i <= '1';
--		wait for 10 us;
--		trg_i <= '0';
--      wait;
		trg_i <= '0';
		wait for (19*trg_i_period/20);
		trg_i <= '1';
		wait for (trg_i_period/20) + 9 ns;
   end process;

END;
