----------------------------------------------------------------------------------
-- Company: Physics Department E18, TU Muenchen
-- Engineer: Dmytro Levit
-- 
-- Create Date: 10-02-2014
-- Design Name: 
-- File Name: trigger_top.vhd
-- Module Name: trigger_top
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
USE work.data_path_pkg.ALL;

LIBRARY UNISIM;
USE UNISIM.vcomponents.all;


ENTITY trigger_top IS
	GENERIC(
		HYBRID6_SETUP : boolean := FALSE;
		DHP_CLK_PERIOD_PS : integer;
		TRG_SRC : string := "TLU"
	);
	PORT(
		OSC_GCK_CLK_P : in std_logic;
		OSC_GCK_CLK_N : in std_logic;

		PRE_GCK_P : out std_logic;
		PRE_GCK_N : out std_logic;
		
		refclk127_bufg_o : out std_logic;
		refclk127_o : out std_logic;

		belle_trg_p : in  std_logic;
		belle_trg_n : in  std_logic;
		belle_clk_p : in  std_logic;
		belle_clk_n : in  std_logic;
		belle_ack_p : out std_logic;
		belle_ack_n : out std_logic;
		belle_rsv_p : out std_logic;
		belle_rsv_n : out std_logic;

		TRGTX_TXP : out std_logic;
		TRGTX_TXN : out std_logic;
		TRGTX_RXP : in std_logic;
		TRGTX_RXN : in std_logic;

		TRGRX_TXP : out std_logic;
		TRGRX_TXN : out std_logic;
		TRGRX_RXP : in std_logic;
		TRGRX_RXN : in std_logic;

		USER_CLK_i : in std_logic;
		timer_strobe_i : in std_logic;
		trigger_rst_i : in std_logic;
		tlu_rst_i : in std_logic;

		runrst_o : out std_logic;
		feerst_o : out std_logic;

		tlu_conf_reg_i : in std_logic_vector(31 downto 0);
		tlu_timeout_factor_i : in std_logic_vector(31 downto 0);
		trg_nr_ipbus_i : in std_logic_vector(31 downto 0);
		trg_ipbus_i : in std_logic;

		trg_en_i : in std_logic;
		invert_trg_i : in std_logic;
		invert_trg_dcdjtag_i : in std_logic;
		trg_len_i : in unsigned(14 downto 0);
		fck_len_i : in unsigned(14 downto 0);
		fck_strobe_len_i : in unsigned(5 downto 0);
		trg_dly_i : in unsigned(14 downto 0);

		stat_trg_en_i : in std_logic;
		stat_trgmiss_en_i : in std_logic;
		trigger_cnt_o : out std_logic_vector(31 downto 0);
		trigger_rate_o : out std_logic_vector(31 downto 0);
		trigger_missing_cnt_o : out std_logic_vector(31 downto 0);
		trigger_missing_rate_o : out std_logic_vector(31 downto 0);

		veto_i : in std_logic;

		-- signals are used to generate trigger for raw data
		dhp_rx_d : in DATA_ARRAY_TYPE;
		dhp_sof_n : in FLAG_TYPE;
		dhp_eof_n : in FLAG_TYPE;
		dhp_src_rdy_n : in FLAG_TYPE;
		dhp_channel_up : in FLAG_TYPE;

		timestamp_o : out TIMESTAMP_TYPE;
		trg_nr_out_o : out TRIGGER_TYPE;
		trg_nr_en_o : out std_logic;
		bram_sync_o : out std_logic;
		sync_o : out std_logic;
		next_sync_o : out std_logic;
		ack_out_o : out std_logic;
		trg_strobe_raw_o : out std_logic;
		trg_strobe_o : out std_logic;
		trg_strobe_missing_o : out std_logic;
		trigger_position_o : out std_logic_vector(14 downto 0);
		actual_frame_o : out std_logic_vector(15 downto 0);
		trg21_o : out std_logic;
		trg_out_o : out std_logic;
		-- from lemo unit to dhpt_cmd
		veto_out_o : out std_logic;

		tlu_busy_ext_i : in std_logic;
		tlu_clk_ext_i : in std_logic;
		tlu_trg_ext_o : out std_logic;
		tlu_rst_ext_o : out std_logic;
		
		-- signals from lemo
		trg_lemo_i : in std_logic;
		veto_lemo_i : in std_logic;
		-- signals from memory block
		trg_bram_i : in std_logic;
		
		dbg_o : out std_logic_vector(31 downto 0)
	);
END trigger_top;

ARCHITECTURE implementation OF trigger_top IS

	-- b2tt
	constant VERSION  : integer := 20131013;
	constant DEFADDR  : std_logic_vector (19 downto 0) := x"00001";
	constant FLIPCLK  : std_logic := '0';
	constant FLIPTRG  : std_logic := '0';
	constant FLIPACK  : std_logic := '0';
	constant USEFIFO  : std_logic := '0';
	constant CLKDIV1  : integer range 1 to 72 := 3;
	constant CLKDIV2  : integer range 1 to 72 := 4;
	constant USEPLL   : std_logic := '0';
	constant USEICTRL : std_logic := '0';
	constant NBITTIM  : integer range 1 to 32 := 32;
	constant NBITTAG  : integer range 4 to 32 := 32;
	constant NBITID   : integer range 4 to 32 := 16;
	constant B2LRATE  : integer := 4;   -- 127 Mbyte / s

	signal dhhid_b2tt : std_logic_vector (NBITID-1 downto 0) := std_logic_vector(to_unsigned(1, NBITID));

	signal trg_nr_in : std_logic_vector(31 downto 0) := (others => '0');
	signal trg21 : std_logic := '0';
	signal clk_raw : std_logic := '0';
	signal clk127 : std_logic := '0';
	signal refclk127_bufg : std_logic := '0';
	signal refclk127 : std_logic := '0';
	signal busy_status : std_logic := '0';

	-- link status
	signal b2clkup  : std_logic;
	signal b2ttup   : std_logic;

	-- system clock and time
	signal utime    : std_logic_vector (NBITTIM-1 downto 0);
	signal ctime    : std_logic_vector (26 downto 0);

	-- divided clock
	signal divclk1  : std_logic_vector (1 downto 0);
	signal divclk2  : std_logic_vector (1 downto 0);

	-- exp- / run-number
	signal exprun   : std_logic_vector (31 downto 0);
	
	-- run reset
	signal runreset : std_logic;
	signal feereset : std_logic;
	signal gtpreset : std_logic;
	signal use_trg_nr_in : std_logic := '0';
	signal runreset_uc : std_logic := '0';
	signal feereset_uc : std_logic := '0';
	signal gtpreset_uc : std_logic := '0';
	signal trgtag_uc : std_logic_vector(31 downto 0);
	signal trgtag_in_uc : std_logic_vector(31 downto 0);
	signal trgtag_in : std_logic_vector(31 downto 0);
	signal wren_trgcrs : std_logic := '0';
	signal TRG_IN_UC : std_logic := '0';
	
	-- trigger
	signal trgout   : std_logic;
	signal trgtyp   : std_logic_vector (3  downto 0);
	signal trgtag   : std_logic_vector (31 downto 0);

	-- revolution
	signal revo     : std_logic;
	signal revo9    : std_logic;
	signal revoclk  : std_logic_vector (10 downto 0);
	signal revogap  : std_logic;                       -- TBI
	signal injveto  : std_logic_vector (1 downto 0);   -- TBI
	
	-- busy and status return
	signal busy_b2tt     : std_logic := '0'; -- to suspend the trigger
	signal err_b2tt      : std_logic := '0'; -- to stop the run

	-- Belle2link status
	signal b2plllk  : std_logic := '1';
	signal b2linkup : std_logic := '1';
	signal b2linkwe : std_logic := '0';
	signal b2lclk   : std_logic := '0';

	-- SEU status (from virtex5_seu_controller)
	signal seuinit  : std_logic := '0';  -- initialising
	signal seubusy  : std_logic := '0';  -- busy
	signal seuactiv : std_logic := '0';  -- acm_active
	signal seuscan  : std_logic := '0';  -- end_of_scan
	signal seudet   : std_logic := '0';  -- seu_detect
	signal seucrc   : std_logic := '0';  -- crc_error
	signal seumbe   : std_logic := '0';  -- mbe
	
	-- data for Belle2link header
	signal fifordy  : std_logic := '0';
	signal fifodata : std_logic_vector (95 downto 0);
	signal fifonext : std_logic := '0';

	-- b2tt-link status
	signal regdbg   : std_logic_vector (7 downto 0);
	signal octet    : std_logic_vector (7 downto 0);  -- decode
	signal isk      : std_logic;                      -- decode
	signal cntbit2  : std_logic_vector (2 downto 0);  -- decode
	signal sigbit2  : std_logic_vector (1 downto 0);  -- decode
	signal bitddr   : std_logic;                      -- encode
	signal sta_octet : std_logic;

	signal belle_trg_ready : std_logic;
	signal clk_iodel : std_logic;
	signal rst_iodel : std_logic;
	signal CNTVALUEIN : std_logic_vector(4 downto 0);
	signal cnt_invalid_o : std_logic_vector (11 downto 0);
	signal incdelay_o : std_logic;

	signal sig_o : std_logic;

	-- GTX trg tx signals
	signal GTXTX_BACKCHANNEL_ERROR_OUT : std_logic;
	signal GTXTX_RXSYNCDONE_OUT : std_logic;
	signal GTX_TX_SYNC_DONE : std_logic;
	signal GTX_TXUSRCLK2 : std_logic;
	signal GTX0_RXPLLLKDET_OUT : std_logic;
	signal GTX0_GTXTEST_DONE : std_logic;
	signal GTX0_RXUSRCLK2_O : std_logic;
	signal GTX0_RXDATA_O : std_logic_vector(15 downto 0);
	signal refclk_out : std_logic;
	-- trg tx signals
	signal RESET_IN : std_logic := '0'; -- power up reset
	signal RUNRESET_IN : std_logic := '0';
	signal FEERESET_IN : std_logic := '0';
	signal GTPRESET_IN : std_logic := '0';
	--
	signal REVO_IN : std_logic := '0';
	signal REVO9_IN : std_logic := '0';
	signal INJVETO_IN : std_logic_vector(1 downto 0) := (others => '0');
	signal REVOGAP_IN : std_logic := '0';
	--
	signal TRG_IN : std_logic := '0'; -- synchronous with CLK_IN
	signal TRG_TYPE_IN : std_logic_vector(3 downto 0) := (others => '0');
	signal CTIME_IN : std_logic_vector(26 downto 0) := (others => '0');

	-- GTX trg rx signals
	signal GTX1_RXCHARISCOMMA_OUT : std_logic_vector(1 downto 0);
	signal GTX1_RXCHARISK_OUT : std_logic_vector(1 downto 0);
	signal GTX1_RXDISPERR_OUT : std_logic_vector(1 downto 0);
	signal GTX1_RXNOTINTABLE_OUT : std_logic_vector(1 downto 0);
	signal GTX1_RXDATA_OUT : std_logic_vector(15 downto 0);
	signal GTX1_RXPLLLKDET_OUT : std_logic;
	signal rxgtxreset : std_logic;
	signal state_flag : std_logic_vector(2 downto 0);

	signal RX_USRCLK2_OUT : std_logic;
	signal GTX_RX_SYNC_DONE : std_logic;

	signal ERROR_OUT : std_logic;
	signal RUNRESET_OUT : std_logic;
	signal FEERESET_OUT : std_logic;
	signal GTPRESET_OUT : std_logic;
	--
	signal REVO_OUT : std_logic;
	signal REVO9_OUT : std_logic;
	signal INJVETO_OUT : std_logic_vector(1 downto 0);
	signal REVOGAP_OUT : std_logic;
	--
	signal TRG_OUT : std_logic; 
	signal TRG_NR_OUT : std_logic_vector(15 downto 0); 
	signal TRG_TYPE_OUT : std_logic_vector(3 downto 0);
	signal CTIME_OUT : std_logic_vector(26 downto 0);

	signal trigger_nr_en : std_logic := '0';
	signal trg_strobe_raw : std_logic := '0';
	signal trg_strobe_missing : std_logic := '0';
	signal trg21_temp : std_logic := '0';

	signal actual_row_o : std_logic_vector(9 downto 0) := (others => '0');
--	signal actual_frame_o : std_logic_vector(15 downto 0) := (others => '0');
	signal tlu_rst : std_logic := '0';
	signal trg_dhp : std_logic := '0';

	signal tlu_clk_p : std_logic := '0';
	signal tlu_clk_n : std_logic := '1';
	signal tlu_trg_p : std_logic := '0';
	signal tlu_trg_n : std_logic := '1';
	signal tlu_rst_p : std_logic := '0';
	signal tlu_rst_n : std_logic := '1';
	signal tlu_busy_p : std_logic := '0';
	signal tlu_busy_n : std_logic := '1';
	
--	lemo
	signal trg_lemo_int : std_logic := '0';
	signal trigger_nr_lemo			: std_logic_vector(31 downto 0);
	signal trigger_nr_lemo_en		: std_logic := '0';

	signal dummy : std_logic_vector(31 downto 0);

	signal dbg_tlu : std_logic_vector(31 downto 0);

BEGIN

--	dbg_o(15 downto 0) <= actual_frame_o;
--	dbg_o(25 downto 16) <= actual_row_o;
--	dbg_o <= dbg_tlu;

	trg_stat_inst : ENTITY work.statistics_block
		GENERIC map(
			CLK_PERIOD_PS => DHP_CLK_PERIOD_PS
		)
		PORT map(
			clk => USER_CLK_i,
			timer_strobe_i => timer_strobe_i,
--			clk => RX_USRCLK2_OUT,
			-- this flag also resets counters
			en => stat_trg_en_i,
			single_pulse_i => '1',
			-- after this period elapses, rate counter is restarted
			sample_period_sec => std_logic_vector(to_unsigned(1, 3)),
			-- used for count cnt and rate
			valid => trg21_temp,
			-- used for frame_cnt
			sof => '0',
			eof => '0',

			cnt => trigger_cnt_o,
			rate => trigger_rate_o,
			frame_cnt => open
		);

	trg_missing_inst : ENTITY work.statistics_block
		GENERIC map(
			CLK_PERIOD_PS => DHP_CLK_PERIOD_PS
		)
		PORT map(
			clk => USER_CLK_i,
			timer_strobe_i => timer_strobe_i,
			-- this flag also resets counters
			en => stat_trgmiss_en_i,
			single_pulse_i => '1',
			-- after this period elapses, rate counter is restarted
			sample_period_sec => std_logic_vector(to_unsigned(1, 3)),
			-- used for count cnt and rate
			valid => trg_strobe_missing,
			-- used for frame_cnt
			sof => '0',
			eof => '0',

			cnt => trigger_missing_cnt_o,
			rate => trigger_missing_rate_o,
			frame_cnt => open
		);

	trg_strobe_missing_o <= trg_strobe_missing;
	trg_strobe_raw_o <= trg_strobe_raw;
	trg21_temp <= (trg21 or trigger_nr_lemo_en or trg_bram_i) when trg_en_i = '1' else trg_strobe_raw; 
	trg21_o <= trg21_temp;

	trg_gen_inst : ENTITY work.trigger_unit_multichannel
		PORT map(
			clk => USER_CLK_i,
			rst => '0', -- trigger_rst_i,

			trg_en => trg_en_i,
			invert_trg_out => invert_trg_i,
			invert_trg_dcdjtag_i => invert_trg_dcdjtag_i,
			use_trg_nr_in => use_trg_nr_in, -- otherwise internal counter is used
			trg_len => trg_len_i,
			fck_len => fck_len_i,
			trg_dly => trg_dly_i,
			fck_strobe_len => fck_strobe_len_i,

			-- signals are used to generate trigger for raw data
			dhp_rx_d => dhp_rx_d,
			dhp_sof_n => dhp_sof_n,
			dhp_eof_n => dhp_sof_n,
			dhp_src_rdy_n => dhp_src_rdy_n,
			dhp_channel_up => dhp_channel_up,

			use_ipbus_i => tlu_conf_reg_i(30),
			trg_ipbus_i => trg_ipbus_i,
			trg_nr_ipbus_i => trg_nr_ipbus_i,

			timestamp => timestamp_o,
			trg_nr_out => trg_nr_out_o,
			trg_nr_en => trg_nr_en_o,
			trg_nr_in => trg_nr_in or trigger_nr_lemo,
			trg_nr_en_i => trg21 or trigger_nr_lemo_en or trg_bram_i,

			dbg_o => dbg_o,

			bram_sync => bram_sync_o,
			sync => sync_o,
			next_sync => next_sync_o,
			ack_out => ack_out_o,
			trg_strobe_raw_o => trg_strobe_raw,
			trg_strobe => trg_strobe_o,
			trg_strobe_missing => trg_strobe_missing,
			trigger_position => trigger_position_o,
			trg_in => trg_dhp or trg_lemo_int or trg_bram_i,
			veto => veto_i,
			actual_row_o => actual_row_o,
			actual_frame_o => actual_frame_o,
			trg_out => trg_out_o
		);

	refclk127_ibufds : IBUFDS_GTXE1   
		port map (        
			O => refclk127,        
			ODIV2 => open,        
			CEB => '0',        
			I => OSC_GCK_CLK_P,     
			IB => OSC_GCK_CLK_N
		); 

	BUFG_inst : BUFG
		port map (
			O => refclk127_bufg, 
			I => refclk127  
		);

	refclk127_o <= refclk127;

lemo_gen: if TRG_SRC = "LEMO" generate

	PRE_GCK_OBUFDS_inst : OBUFDS
		generic map (
			IOSTANDARD => "DEFAULT")
		port map (
			O => PRE_GCK_P,    
			OB => PRE_GCK_N,   
			I => refclk127_bufg       
		);

	refclk127_bufg_o <= refclk127_bufg;
	clk127 <= refclk127_bufg;
	
	lemo_trg_cntr_inst: entity work.lemo_trg_cntr
    port map (
      clk_i                => USER_CLK_i,
      rst_i                => '0', --trigger_rst_i,
      --
      veto_i                => veto_lemo_i,
      trg_i                => trg_lemo_i,
      -- reclocked lemo trigger
      veto_o                => veto_out_o,
      trg_o                => trg_lemo_int,
      trg_nmb_o            => trigger_nr_lemo,
      trigger_nr_lemo_en_o => trigger_nr_lemo_en
      );		

	use_trg_nr_in <= '0';
	
end generate lemo_gen;

b2tt_gen : if TRG_SRC = "B2TT" generate

--	trg_crosser_inst : ENTITY work.crosser32 
--		PORT map(
--			clk_in => clk127,
--			clk_out => USER_CLK,
--			register_in(0) => trgout,
--			register_in(31 downto 1) => (others => '0'),
--			register_out(0) => trg21,
--			register_out(31 downto 1) => open
--		);

--	trigger_nr_en <= trg21;
	trg_nr_in <= trgtag;
--	timestamp <= utime;

--	trgtag_crosser_inst : ENTITY work.crosser32 
--		PORT map(
--			clk_in => clk127,
--			clk_out => USER_CLK,
--			register_in => trgtag,
--			register_out => trg_nr_in
--		);

	-- Use only the clock directly from FTSW
	-- in FPGA synthesized clock has way too large jitter
	PRE_GCK_OBUFDS_inst : OBUFDS
		generic map (
			IOSTANDARD => "DEFAULT")
		port map (
			O => PRE_GCK_P,   
			OB => PRE_GCK_N,  
			I => clk_raw    
		);

	b2tt_inst : entity work.b2tt
		generic map (
			 VERSION =>  VERSION,
			 DEFADDR =>  DEFADDR,
			 FLIPCLK =>  FLIPCLK,
			 FLIPTRG =>  FLIPTRG,
			 FLIPACK =>  FLIPACK,
			 USEFIFO =>  USEFIFO,
			 CLKDIV1 =>  CLKDIV1,
			 CLKDIV2 =>  CLKDIV2,
			 USEPLL =>  USEPLL,
			 USEICTRL =>  USEICTRL,
			 NBITTIM =>  NBITTIM,
			 NBITTAG =>  NBITTAG,
			 NBITID =>  NBITID,
			 B2LRATE =>  B2LRATE
		)
		port map (
			-- RJ-45
			 clkp =>  belle_clk_p,
			 clkn =>  belle_clk_n,
			 trgp =>  belle_trg_p,
			 trgn =>  belle_trg_n,
			 rsvp =>  belle_rsv_p,
			 rsvn =>  belle_rsv_n,
			 ackp =>  belle_ack_p,
			 ackn =>  belle_ack_n,

			-- board id
			 id =>  dhhid_b2tt,

			-- link status
			 b2clkup =>  b2clkup,
			 b2ttup =>  b2ttup,

			-- system clock and time
			 sysclk =>  clk127,
			 rawclk =>  clk_raw,
			 utime =>  utime,
			 ctime =>  ctime,

			-- divided clock
			 divclk1 =>  divclk1,
			 divclk2 =>  divclk2,

			-- exp- / run-number
			 exprun =>  exprun,

			-- run reset
			 runreset => runreset,
			 feereset => feereset,
			 gtpreset => gtpreset,

			-- trigger
			 trgout => trgout,
			 trgtyp => trgtyp,
			 trgtag => trgtag,

			-- revolution
			 revo =>  revo,
			 revo9 =>  revo9,
			 revoclk =>  revoclk,
			 revogap =>  revogap,
			 injveto =>  injveto,

			-- busy and status return
			 busy => busy_b2tt,
			 err => err_b2tt,

			-- Belle2link status
			 b2plllk =>  b2plllk,
			 b2linkup =>  b2linkup,
			 b2linkwe =>  b2linkwe,
			 b2lclk =>  b2lclk,

			-- SEU status (from virtex5_seu_controller)
			 seuinit => seuinit,
			 seubusy => seubusy,
			 seuactiv => seuactiv,
			 seuscan => seuscan,
			 seudet => seudet,
			 seucrc => seucrc,
			 seumbe => seumbe,

			-- data for Belle2link header
			 fifordy =>  fifordy,
			 fifodata =>  fifodata,
			 fifonext =>  fifonext,

			-- b2tt-link status
			 regdbg =>  regdbg,
			 octet =>  octet,
--			 sta_octet => sta_octet,
			 isk =>  isk,
			 cntbit2 =>  cntbit2,
			 sigbit2 =>  sigbit2,
			 bitddr =>  bitddr,
--			cnt_invalid_o => cnt_invalid_o,
--			incdelay_o => incdelay_o,
			 dbg => open,
			 dbg2 => open
		);

	trg_crosser_inst : ENTITY work.crosser32 
		PORT map(
			rst_i => '0',
			clk_in => clk127,
			clk_out => refclk_out,
			wren_i => '0',
			register_out(0) => RUNRESET_IN,
			register_out(1) => FEERESET_IN,
			register_out(2) => REVO_IN,
			register_out(3) => REVO9_IN,
			register_out(4) => TRG_IN,
			register_out(31 downto 5) => CTIME_IN,
			register_in(0) => runreset,
			register_in(1) => feereset,
			register_in(2) => revo,
			register_in(3) => revo9,
			register_in(4) => trgout,
			register_in(31 downto 5) => ctime
		);

end generate b2tt_gen;


tlu_gen : if TRG_SRC = "TLU" generate

	-- Use only the clock directly from FTSW
	-- in FPGA synthesized clock has way too large jitter
	PRE_GCK_OBUFDS_inst : OBUFDS
		generic map (
			IOSTANDARD => "DEFAULT")
		port map (
			O => PRE_GCK_P,    
			OB => PRE_GCK_N,   
			I => refclk127_bufg       
		);

	refclk127_bufg_o <= refclk127_bufg;

	clk127 <= refclk127_bufg;

	hybrid6_gen : if HYBRID6_SETUP = TRUE generate
		tlu_trg_p <= belle_clk_p;
		tlu_trg_n <= belle_clk_n;
		tlu_rst_p <= belle_trg_p;
		tlu_rst_n <= belle_trg_n;
		belle_ack_p <= tlu_clk_p; 
		belle_ack_n <= tlu_clk_n; 
		belle_rsv_p <= tlu_busy_p; 
		belle_rsv_n <= tlu_busy_n; 
	end generate hybrid6_gen;

	nothybrid6_gen : if HYBRID6_SETUP = FALSE generate
		tlu_trg_p <= belle_trg_p;
		tlu_trg_n <= belle_trg_n;
		tlu_rst_p <= belle_clk_p;
		tlu_rst_n <= belle_clk_n;
		belle_ack_p <= tlu_busy_p; 
		belle_ack_n <= tlu_busy_n; 
		belle_rsv_p <= tlu_clk_p; 
		belle_rsv_n <= tlu_clk_n; 
	end generate nothybrid6_gen;

	tlu_inst : ENTITY work.tlu
		generic map(
			HYBRID6_SETUP => HYBRID6_SETUP,
			EXTERNAL_CONTROL => false
		)
		PORT map(
			clk => USER_CLK_i,
			rst => tlu_rst_i,

			tlu_trg_p => tlu_trg_p,
			tlu_trg_n => tlu_trg_n,
			tlu_rst_p => tlu_rst_p,
			tlu_rst_n => tlu_rst_n,
			tlu_clk_p => tlu_clk_p,
			tlu_clk_n => tlu_clk_n,
			tlu_busy_p => tlu_busy_p,
			tlu_busy_n => tlu_busy_n,

		-- Use this pins for the Tabuk setup (hardwired on the carrier board)
--			tlu_trg_p => belle_trg_p,
--			tlu_trg_n => belle_trg_n,
--			tlu_rst_p => belle_clk_p,
--			tlu_rst_n => belle_clk_n,
--			tlu_clk_p => belle_rsv_p,
--			tlu_clk_n => belle_rsv_n,
--			tlu_busy_p => belle_ack_p,
--			tlu_busy_n => belle_ack_n,

		-- Florian's setup in Bonn
--			tlu_trg_p => belle_clk_p,
--			tlu_trg_n => belle_clk_n,
--			tlu_rst_p => belle_trg_p,
--			tlu_rst_n => belle_trg_n,
--			tlu_clk_p => belle_ack_p,
--			tlu_clk_n => belle_ack_n,
--			tlu_busy_p => belle_rsv_p,
--			tlu_busy_n => belle_rsv_n,
--
			dbg => dbg_tlu,
			tlu_busy_ext => tlu_busy_ext_i,
			tlu_clk_ext => tlu_clk_ext_i,
			tlu_trg_ext => tlu_trg_ext_o,
			tlu_rst_ext => tlu_rst_ext_o,

			trg_ipbus => trg_ipbus_i,
			trg_nr_ipbus => trg_nr_ipbus_i,
		
			tlu_busy_ext_en => tlu_conf_reg_i(31),
			busy_status => busy_status,

			tlu_rst_o => tlu_rst,
			trg => trg_dhp,
--			trg => trg_out_o,
--			trigger_nr_en => trigger_nr_en,
			trigger_nr_en => trg21,
			-- vector is loaded on the falling edge of trigger_nr_en
			trigger_nr => trg_nr_in,
--			trigger_nr => open,

			max_bits => tlu_conf_reg_i(7 downto 0),
			-- delay trg signal wrt tlu_clk.
			-- trigger signal is produced on the falling edge of the clock
			-- and stays high for the tlu_clk period
			use_ipbus_trg => tlu_conf_reg_i(30),
			ts_2tu_del => tlu_conf_reg_i(23 downto 8),
			tn2a_default => (others => '0'),
			timeout_factor => tlu_timeout_factor_i,
			clk_slow_down_factor => tlu_conf_reg_i(29 downto 24)
		);

	runrst_o <= tlu_rst;
	use_trg_nr_in <= '1';

end generate tlu_gen;

gtxtrgtest_gen : if TRG_SRC = "TEST" generate

	-- Use only the clock directly from FTSW
	-- in FPGA synthesized clock has way too large jitter
	PRE_GCK_OBUFDS_inst : OBUFDS
		generic map (
			IOSTANDARD => "DEFAULT")
		port map (
			O => PRE_GCK_P,    
			OB => PRE_GCK_N,   
			I => refclk127_bufg       
		);

	refclk127_bufg_o <= refclk127_bufg;
	clk127 <= refclk127_bufg;

	belle_rsv_n <= RX_USRCLK2_OUT;
	belle_rsv_p <= GTX_TXUSRCLK2;

	trg_gen_proc : PROCESS(USER_CLK_i)
	BEGIN
		if rising_edge(USER_CLK_i) then
			CTIME_IN <= CTIME_IN + 1;
			TRG_IN_UC <= '0';

			if CTIME_IN(19) = '1' then
				TRG_IN_UC <= '1';
				CTIME_IN <= (others => '0');
				trgtag_in_uc <= trgtag_in_uc + 1;
			end if;
		end if;
	END PROCESS;

	gtx_rx_top_inst : entity work.gtx_rx_top
		port map(
			GTX0_MGTREFCLKRX_IN => refclk127,
			GTX0_TXP_OUT => TRGRX_TXP,
			GTX0_TXN_OUT => TRGRX_TXN,
			GTX0_RXP_IN => TRGRX_RXP,
			GTX0_RXN_IN => TRGRX_RXN,

			GTX0_RXCHARISCOMMA_OUT => GTX1_RXCHARISCOMMA_OUT,
			GTX0_RXCHARISK_OUT => GTX1_RXCHARISK_OUT,
			GTX0_RXDISPERR_OUT => GTX1_RXDISPERR_OUT,
			GTX0_RXNOTINTABLE_OUT => GTX1_RXNOTINTABLE_OUT,
			GTX0_RXDATA_OUT => GTX1_RXDATA_OUT,
			GTX0_RXPLLLKDET_OUT => GTX1_RXPLLLKDET_OUT,
			GTX0_GTXRXRESET_IN => rxgtxreset,
			state_flag => state_flag,

			ERROR_OUT => ERROR_OUT,
			RUNRESET_OUT => RUNRESET_OUT,
			FEERESET_OUT => FEERESET_OUT,
			GTPRESET_OUT => GTPRESET_OUT,
			--
			REVO_OUT => REVO_OUT,
			REVO9_OUT => REVO9_OUT,
			INJVETO_OUT => INJVETO_OUT,
			REVOGAP_OUT => REVOGAP_OUT,
			--
			TRG_OUT => TRG_OUT,
			TRG_NR_OUT => trgtag(15 downto 0),
			TRG_TYPE_OUT => TRG_TYPE_OUT,
			CTIME_OUT => CTIME_OUT,

			RX_USRCLK2_OUT => RX_USRCLK2_OUT,
			SYNC_DONE_OUT => GTX_RX_SYNC_DONE
		);

	gtx_tx_top_inst : entity work.gtx_tx_top
		port map(
			GTX0_MGTREFCLKRX_IN => refclk127,
			GTX0_TXP_OUT => TRGTX_TXP,
			GTX0_TXN_OUT => TRGTX_TXN,
			GTX0_RXP_IN => TRGTX_RXP,
			GTX0_RXN_IN => TRGTX_RXN,

			refclk_out => refclk_out,
			GTX0_GTXTEST_DONE => GTX0_GTXTEST_DONE,
			GTX0_RXPLLLKDET_OUT => GTX0_RXPLLLKDET_OUT,
			GTX0_RXUSRCLK2_O => GTX0_RXUSRCLK2_O,
			GTX0_RXDATA_O => GTX0_RXDATA_O,
			SYNC_DONE => GTX_TX_SYNC_DONE,
			GTX0_TXUSRCLK2_o => GTX_TXUSRCLK2,

			ERROR_OUT => GTXTX_BACKCHANNEL_ERROR_OUT,
			RXSYNCDONE_OUT => GTXTX_RXSYNCDONE_OUT,

			RESET_IN => RESET_IN,
			RUNRESET_IN => RUNRESET_IN,
			FEERESET_IN => FEERESET_IN,
			GTPRESET_IN => GTPRESET_IN,
			--
			REVO_IN => REVO_IN,
			REVO9_IN => REVO9_IN,
			INJVETO_IN => INJVETO_IN,
			REVOGAP_IN => REVOGAP_IN,
			--
			TRG_IN => TRG_IN,
			TRG_NR_IN => trgtag_in(15 downto 0),
			TRG_TYPE_IN => TRG_TYPE_IN,
			CTIME_IN => CTIME_IN
		);

	trgin_crosser_inst : ENTITY work.crosser32 
		generic map(
			USE_WREN => TRUE
		)
		PORT map(
			rst_i => '0',
			clk_out => GTX_TXUSRCLK2,
			clk_in => USER_CLK_i,
			wren_i => TRG_IN_UC,
			register_in(0) => TRG_IN_UC,
			register_in(31 downto 1) => trgtag_in_uc(30 downto 0),
			register_out(0) => TRG_IN,
			register_out(31 downto 1) => trgtag_in(30 downto 0)
		);

	trgout_crosser_inst : ENTITY work.crosser32 
		generic map(
			USE_WREN => TRUE
		)
		PORT map(
			rst_i => '0',
			clk_out =>USER_CLK_i,
			clk_in => RX_USRCLK2_OUT,
			wren_i => TRG_OUT,
			register_in(0) => TRG_OUT,
			register_in(31 downto 1) => trgtag(30 downto 0),
			register_out(0) => trg21,
			register_out(31 downto 1) => trgtag_uc(30 downto 0)
		);

	use_trg_nr_in <= '0';

end generate gtxtrgtest_gen;

dhhc_rx_gen : if TRG_SRC = "DHHC_RX" generate

	PRE_GCK_OBUFDS_inst : OBUFDS
		generic map (
			IOSTANDARD => "DEFAULT")
		port map (
			O => PRE_GCK_P,
			OB => PRE_GCK_N,
			I => RX_USRCLK2_OUT       
		);

	refclk127_bufg_o <= RX_USRCLK2_OUT;

	gtx_rx_top_inst : entity work.gtx_rx_top
		port map(
			GTX0_MGTREFCLKRX_IN => refclk127,
			GTX0_TXP_OUT => TRGRX_TXP,
			GTX0_TXN_OUT => TRGRX_TXN,
			GTX0_RXP_IN => TRGRX_RXP,
			GTX0_RXN_IN => TRGRX_RXN,

			GTX0_RXCHARISCOMMA_OUT => GTX1_RXCHARISCOMMA_OUT,
			GTX0_RXCHARISK_OUT => GTX1_RXCHARISK_OUT,
			GTX0_RXDISPERR_OUT => GTX1_RXDISPERR_OUT,
			GTX0_RXNOTINTABLE_OUT => GTX1_RXNOTINTABLE_OUT,
			GTX0_RXDATA_OUT => GTX1_RXDATA_OUT,
			GTX0_RXPLLLKDET_OUT => GTX1_RXPLLLKDET_OUT,
			GTX0_GTXRXRESET_IN => rxgtxreset,
			state_flag => state_flag,

			ERROR_OUT => ERROR_OUT,
			RUNRESET_OUT => RUNRESET_OUT,
			FEERESET_OUT => FEERESET_OUT,
			GTPRESET_OUT => GTPRESET_OUT,
			--
			REVO_OUT => REVO_OUT,
			REVO9_OUT => REVO9_OUT,
			INJVETO_OUT => INJVETO_OUT,
			REVOGAP_OUT => REVOGAP_OUT,
			--
			TRG_OUT => TRG_OUT,
			TRG_NR_OUT => TRG_NR_OUT,
			TRG_TYPE_OUT => TRG_TYPE_OUT,
			CTIME_OUT => CTIME_OUT,

			RX_USRCLK2_OUT => RX_USRCLK2_OUT,
			SYNC_DONE_OUT => GTX_RX_SYNC_DONE
		);

		revo <= REVO_OUT;
		revo9 <= REVO9_OUT;
		injveto <= INJVETO_OUT;
		revogap <= REVOGAP_OUT;
		runreset <= RUNRESET_OUT;
		feereset <= FEERESET_OUT;
		gtpreset <= GTPRESET_OUT;
		trgout <= TRG_OUT;
		trgtyp <= TRG_TYPE_OUT;
		ctime <= CTIME_OUT;
		trgtag(15 downto 0) <= TRG_NR_OUT;

--	trg_crosser_inst : ENTITY work.crosser32 
--		generic map(
--			USE_WREN => TRUE
--		)
--		PORT map(
--			clk_in => RX_USRCLK2_OUT,
--			clk_out => USER_CLK_i,
--			wren_i => wren_trgcrs,
--			register_in(0) => trgout,
--			register_in(1) => runreset,
--			register_in(2) => feereset,
--			register_in(15 downto 3) => (others => '0'),
--			register_in(31 downto 16) => trgtag(15 downto 0),
--			register_out(0) => trg21,
--			register_out(1) => runreset_uc,
--			register_out(2) => feereset_uc,
--			register_out(15 downto 3) => open,
--			register_out(31 downto 16) => trgtag_uc(15 downto 0)
--		);

	trg_crosser_inst : ENTITY work.sync_trg_fifo 
		PORT map(
			reset_in => trigger_rst_i,
			clk_in => RX_USRCLK2_OUT,
			clk_out => USER_CLK_i,
			wren_in => wren_trgcrs,
			register_in(0) => trgout,
			register_in(1) => runreset,
			register_in(2) => feereset,
			register_in(15 downto 3) => (others => '0'),
			register_in(31 downto 16) => trgtag(15 downto 0),
			register_out(0) => trg21,
			register_out(1) => runreset_uc,
			register_out(2) => feereset_uc,
			register_out(15 downto 3) => dummy(15 downto 3),
			register_out(31 downto 16) => trgtag_uc(15 downto 0)
		);

	wren_trgcrs <= trgout or runreset or feereset;

	use_trg_nr_in <= '1';
--	trigger_nr_en <= trg21;
	trg_nr_in <= trgtag_uc;
--	trigger_rst <= runreset_uc;
	runrst_o <= runreset_uc;
	feerst_o <= feereset_uc;
	
end generate dhhc_rx_gen; 


END implementation;
