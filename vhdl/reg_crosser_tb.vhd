----------------------------------------------------------------------------------
-- Company: Physics Department E18, TU Muenchen
-- Engineer: Dmytro Levit
-- 
-- Create Date: 18-01-2014
-- Design Name: 
-- File Name: crosser32_tb.vhd
-- Module Name: crosser32_tb
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Last Modified: 
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_unsigned.all;

LIBRARY UNISIM;
USE UNISIM.vcomponents.all;


ENTITY reg_crosser_tb IS
END reg_crosser_tb;

ARCHITECTURE implementation OF reg_crosser_tb IS

	constant USE_WREN : boolean := TRUE;
	signal clk_in : std_logic := '0';
	signal clk_out : std_logic := '0';
	signal wren_i : std_logic := '0';
	signal valid_o : std_logic := '0';
	signal register_in : std_logic_vector(31 downto 0) := (others => '0');
	signal register_out : std_logic_vector(31 downto 0) := (others => '0');

	constant clk_period_in : time := 5 ns;
	constant clk_period_out : time := 7.34 ns;

BEGIN

	clkin_proc : PROCESS
	BEGIN
		clk_in <= not clk_in;
		wait for clk_period_in/2;
	END PROCESS;

	clkout_proc : PROCESS
	BEGIN
		clk_out <= not clk_out;
		wait for clk_period_out/2;
	END PROCESS;

	crosser32_inst : entity work.reg_crosser
		port map(
			rst_i => '0',
			clk_in => clk_in,
			clk_out => clk_out,
			wren_i => wren_i,
			valid_o => valid_o,
			register_in => register_in,
			register_out => register_out
		);

	sim_proc : PROCESS
	BEGIN
		wait for 352 ns;
		register_in <= X"ABCDEF01";
		wait for 352 ns;
		wait until clk_in = '1';
		wren_i <= '1';
		register_in <= X"CAFEBABE";
		wait until clk_in = '1';
		wren_i <= '0';
		wait for 352 ns;
		wren_i <= '1';
		register_in <= X"ABCDEF01";
		wait until clk_in = '1';
		wren_i <= '0';
		wait for 352 ns;
		wait until clk_in = '1';
		wren_i <= '1';
		register_in <= X"CAFEBABE";
		wait until clk_in = '1';
		wren_i <= '0';
		wait;
	END PROCESS;

END implementation;
