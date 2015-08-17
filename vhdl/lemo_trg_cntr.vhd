----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    14:07:00 07/29/2015 
-- Design Name: 
-- Module Name:    lemo_trg_cntr - implementation 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
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
use IEEE.STD_LOGIC_UNSIGNED.ALL;
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity lemo_trg_cntr is
	port(
		clk_i					: in std_logic;
		rst_i					: in std_logic;
		--
		veto_i				: in std_logic;
		trg_i					: in std_logic;
		-- reclocked lemo trigger
		veto_o					: out std_logic;
		trg_o					: out std_logic;
		trg_nmb_o				: out std_logic_vector(31 downto 0);
		trigger_nr_lemo_en_o					: out std_logic);
end lemo_trg_cntr;

architecture implementation of lemo_trg_cntr is

--	signal veto_o_int			: std_logic := '0';
	signal trg_edge			: std_logic := '0';
	signal trg_i_delay0			: std_logic := '0';
	signal trg_i_delay1			: std_logic := '0';
	signal trg_o_int			: std_logic := '0';
	signal trg_nmb_o_int			: std_logic_vector(31 downto 0) := (others => '0');
	signal trigger_nr_lemo_en_o_int			: std_logic := '0';

begin

	veto_o <= veto_i; --directly forward to "dhpt_cmd_encoder"
	trg_o <= trg_o_int; -- trg_o has a maximum 2clk delay to the trg_i falling edge
	trg_nmb_o <= trg_nmb_o_int;
	trigger_nr_lemo_en_o <= trigger_nr_lemo_en_o_int;
	
	--input trigger edge
	trg_edge <= trg_i_delay0 xor trg_i_delay1; -- two clock delay ensure pulse width

	trg_proc : process(clk_i)
		begin
			if rst_i = '1' then
--				veto_o_int	<=	'0';
				trg_o_int	<=	'0';
				trg_i_delay0 <= '0';
				trg_i_delay1 <= '0';
				trg_nmb_o_int <= (others => '0');
				trigger_nr_lemo_en_o_int <= '0';
			elsif rising_edge(clk_i) then
				trg_i_delay0 <= trg_i;
				trg_i_delay1 <= trg_i_delay0;
				if trg_edge = '1' and trg_i = '0' then -- falling trigger edge
					trg_nmb_o_int <= trg_nmb_o_int + 1;
					trg_o_int <= '1';
					trigger_nr_lemo_en_o_int <= '1';
				else
					trigger_nr_lemo_en_o_int <= '0';
					trg_o_int <= '0';
				end if;
			end if;
		end process;

end implementation;

