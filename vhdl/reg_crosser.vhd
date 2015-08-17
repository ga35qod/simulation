----------------------------------------------------------------------------------
-- Company: Physics Department E18, TU Muenchen
-- Engineer: Dmytro Levit
-- 
-- Create Date: 11-05-2015
-- Design Name: 
-- File Name: reg_crosser.vhd
-- Module Name: reg_crosser
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


ENTITY reg_crosser IS
	PORT(
		rst_i : in std_logic;
		clk_in : in std_logic;
		clk_out : in std_logic;
		wren_i : in std_logic;
		valid_o : out std_logic;
		register_in : in std_logic_vector(31 downto 0);
		register_out : out std_logic_vector(31 downto 0)
	);
END reg_crosser;

ARCHITECTURE implementation OF reg_crosser IS

	type FSM_TYPE is (idle_st, wait_ack_st);
	signal write_fsm : FSM_TYPE := idle_st;
	signal read_fsm : FSM_TYPE := idle_st;
	signal active : std_logic := '0';
	signal ack : std_logic := '0';
	signal reg_write : std_logic_vector(register_in'range);
	signal reg_read : std_logic_vector(register_in'range);

BEGIN

	register_out <= reg_read;

	write_proc : PROCESS(clk_in)
	BEGIN
		if rising_edge(clk_in) then
			case write_fsm is
				when idle_st =>
					if wren_i = '1' then
						reg_write <= register_in;
						active <= '1';
						write_fsm <= wait_ack_st;
					end if;
				when wait_ack_st =>
					if ack = '1' then
						active <= '0';
						write_fsm <= idle_st;
					end if;
				when others => null;
			end case;

			if rst_i = '1' then
				write_fsm <= idle_st;
				active <= '0';
			end if;
		end if;
	END PROCESS;

	read_proc : PROCESS(clk_out)
	BEGIN
		if rising_edge(clk_out) then
			valid_o <= '0';

			case read_fsm is
				when idle_st =>
					if active = '1' then
						reg_read <= reg_write;
						ack <= '1';
						read_fsm <= wait_ack_st;
					end if;
				when wait_ack_st =>
					if active = '0' then
						valid_o <= '1';
						ack <= '0';
						read_fsm <= idle_st;
					end if;
				when others => null;
			end case;

			if rst_i = '1' then
				read_fsm <= idle_st;
				ack <= '0';
			end if;
		end if;
	END PROCESS;

END implementation;
