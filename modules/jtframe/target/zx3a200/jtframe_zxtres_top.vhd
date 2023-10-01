library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.demistify_config_pkg.all;

-------------------------------------------------------------------------

entity jtframe_zxtres_top is
	port (
		CLK_50     : in std_logic;
--		SW2        : in std_logic;
		LED5       : out std_logic := '1';
		LED6       : out std_logic := '1';
		-- SDRAM
		DRAM_CLK   : out std_logic;
		DRAM_CKE   : out std_logic;
		DRAM_ADDR  : out std_logic_vector(12 downto 0);
		DRAM_BA    : out std_logic_vector(1 downto 0);
		DRAM_DQ    : inout std_logic_vector(15 downto 0);
		DRAM_LDQM  : out std_logic;
		DRAM_UDQM  : out std_logic;
		DRAM_CS_N  : out std_logic;
		DRAM_WE_N  : out std_logic;
		DRAM_CAS_N : out std_logic;
		DRAM_RAS_N : out std_logic;
		-- SRAM
		SRAM_A      : out   std_logic_vector(19 downto 0);
		SRAM_Q      : inout std_logic_vector(15 downto 0);
		SRAM_WE     : out   std_logic                       := '1';
		SRAM_OE     : out   std_logic                       := '1';
		SRAM_UB     : out   std_logic                       := '1';
		SRAM_LB     : out   std_logic                       := '1';
		-- VGA
		VGA_HS : out std_logic;
		VGA_VS : out std_logic;
		VGA_R  : out std_logic_vector(7 downto 0);
		VGA_G  : out std_logic_vector(7 downto 0);
		VGA_B  : out std_logic_vector(7 downto 0);
		-- EAR
		-- EAR 			 : in std_logic;
		-- PS2
		PS2_KEYBOARD_CLK : inout std_logic := '1';
		PS2_KEYBOARD_DAT : inout std_logic := '1';
		PS2_MOUSE_CLK    : inout std_logic;
		PS2_MOUSE_DAT    : inout std_logic;
		-- UART
		-- PMOD4_D4 : in std_logic;		--UART_RXD
		-- PMOD4_D5 : out std_logic;		--UART_TXD
		-- PMOD4_D6 : in std_logic;		--UART_CTS
		-- PMOD4_D7 : out std_logic;		--UART_RTS		
		-- JOYSTICK
        joy_clk : out std_logic;
        joy_load_n : out std_logic;
        joy_data : in std_logic;
        joy_sel : out std_logic := '1';
		-- SD Card
		SD_CS_N_O   : out std_logic := '1';
		SD_SCLK_O   : out std_logic := '0';
		SD_MOSI_O   : out std_logic := '0';
		SD_MISO_I   : in std_logic;
		-- I2S audio		
		I2S_BCLK   : out std_logic := '0';
		I2S_LRCLK  : out std_logic := '0';
		I2S_DATA   : out std_logic := '0';
		-- PWM AUDIO
		PWM_AUDIO_L 	: out std_logic;
		PWM_AUDIO_R 	: out std_logic
	);
END entity;

architecture RTL of jtframe_zxtres_top is

	-- System clocks
	signal locked  : std_logic;
	signal reset_n : std_logic;

	-- SPI signals
	signal sd_clk  : std_logic;
	signal sd_cs   : std_logic;
	signal sd_mosi : std_logic;
	signal sd_miso : std_logic;

	-- internal SPI signals
--	signal spi_do 		 : std_logic;
	signal spi_toguest   : std_logic;
	signal spi_fromguest : std_logic;
	signal spi_ss2       : std_logic;
	signal spi_ss3       : std_logic;
	signal spi_ss4       : std_logic;
	signal conf_data0    : std_logic;
	signal spi_clk_int   : std_logic;

	-- PS/2 Keyboard socket - used for second mouse
	signal ps2_keyboard_clk_in  : std_logic;
	signal ps2_keyboard_dat_in  : std_logic;
	signal ps2_keyboard_clk_out : std_logic;
	signal ps2_keyboard_dat_out : std_logic;

	-- PS/2 Mouse
	signal ps2_mouse_clk_in  : std_logic;
	signal ps2_mouse_dat_in  : std_logic;
	signal ps2_mouse_clk_out : std_logic;
	signal ps2_mouse_dat_out : std_logic;

	signal intercept : std_logic;

	-- Video
	signal vga_red   : std_logic_vector(7 downto 0);
	signal vga_green : std_logic_vector(7 downto 0);
	signal vga_blue  : std_logic_vector(7 downto 0);
	signal vga_hsync : std_logic;
	signal vga_vsync : std_logic;

	-- RS232 serial
	signal rs232_rxd : std_logic;
	signal rs232_txd : std_logic;

	-- JOYSTICK
	signal joya : std_logic_vector(7 downto 0);
	signal joyb : std_logic_vector(7 downto 0);

	signal joy1 : std_logic_vector(5 downto 0);
	signal joy2 : std_logic_vector(5 downto 0);
	signal intercept_joy : std_logic_vector(5 downto 0);
	signal joy_select_o  : std_logic;

	signal joy1up      : std_logic := '1';
	signal joy1down    : std_logic := '1';
	signal joy1left    : std_logic := '1';
	signal joy1right   : std_logic := '1';
	signal joy1fire1   : std_logic := '1';
	signal joy1fire2   : std_logic := '1';
	signal joy2up      : std_logic := '1';
	signal joy2down    : std_logic := '1';
	signal joy2left    : std_logic := '1';
	signal joy2right   : std_logic := '1';
	signal joy2fire1   : std_logic := '1';
	signal joy2fire2   : std_logic := '1';

	component joydecoder_neptuno is
		port (
			clk_i         : in std_logic;
			joy_data_i    : in std_logic;
			joy_clk_o     : out std_logic;
			joy_load_o    : out std_logic;
			joy1_up_o     : out std_logic;
			joy1_down_o   : out std_logic;
			joy1_left_o   : out std_logic;
			joy1_right_o  : out std_logic;
			joy1_fire1_o  : out std_logic;
			joy1_fire2_o  : out std_logic;
			joy2_up_o     : out std_logic;
			joy2_down_o   : out std_logic;
			joy2_left_o   : out std_logic;
			joy2_right_o  : out std_logic;
			joy2_fire1_o  : out std_logic;
			joy2_fire2_o  : out std_logic
		);
	end component;	
	

	-- DAC AUDIO
	signal dac_l : signed(15 downto 0);
	signal dac_r : signed(15 downto 0);
	
	-- I2S 
	signal i2s_mclk : std_logic;

	component audio_top is
		port (
			clk_50MHz : in std_logic;  -- system clock
			dac_MCLK  : out std_logic; -- outputs to I2S DAC
			dac_LRCK  : out std_logic;
			dac_SCLK  : out std_logic;
			dac_SDIN  : out std_logic;
			L_data    : in std_logic_vector(15 downto 0); -- LEFT data (15-bit signed)
			R_data    : in std_logic_vector(15 downto 0)  -- RIGHT data (15-bit signed) 
		);
	end component;

	signal act_led : std_logic;

	signal osd_en   : std_logic;
	signal sram_we_x : std_logic;
	signal lf_sram : std_logic;

	signal CLK_50_buf : std_logic;
	
	alias clock_input 	: std_logic is CLK_50;
	alias sigma_l : std_logic is PWM_AUDIO_L;
	alias sigma_r : std_logic is PWM_AUDIO_R;


	signal PMOD4_D5 : std_logic;
	signal PMOD4_D4 : std_logic;

begin


-- process(CLK_50_buf)
-- begin
-- 	if (lf_sram = '1') then		--`ifdef JTFRAME_LF_BUFFER
		SRAM_OE <= '0';
		SRAM_WE <= sram_we_x;
		--SRAM_OE <= not sram_we_x;
		SRAM_UB <= '0';
		SRAM_LB <= '0';
-- 	else
-- 		--no SRAM for this core
-- 		SRAM_A <=  (others => '0');
-- 		SRAM_Q <=  (others => 'Z');
-- 		SRAM_WE <= '1';
-- 		SRAM_OE <= '1';
-- 		SRAM_UB <= '1';
-- 		SRAM_LB <= '1';
-- 	end if;
-- end process;


-- SPI
SD_CS_N_O <= sd_cs;
SD_MOSI_O <= sd_mosi;
sd_miso   <= SD_MISO_I;
SD_SCLK_O <= sd_clk;

-- External devices tied to GPIOs
ps2_mouse_dat_in <= PS2_MOUSE_DAT;
PS2_MOUSE_DAT    <= '0' when ps2_mouse_dat_out = '0' else 'Z';
ps2_mouse_clk_in <= PS2_MOUSE_CLK;
PS2_MOUSE_CLK    <= '0' when ps2_mouse_clk_out = '0' else 'Z';

ps2_keyboard_dat_in <= PS2_KEYBOARD_DAT;
PS2_KEYBOARD_DAT    <= '0' when ps2_keyboard_dat_out = '0' else 'Z';
ps2_keyboard_clk_in <= PS2_KEYBOARD_CLK;
PS2_KEYBOARD_CLK    <= '0' when ps2_keyboard_clk_out = '0' else 'Z';

VGA_R       <= vga_red(7 downto 2)  &vga_red(7 downto 6);
VGA_G       <= vga_green(7 downto 2)&vga_green(7 downto 6);
VGA_B       <= vga_blue(7 downto 2) &vga_blue(7 downto 6);
VGA_HS      <= vga_hsync;
VGA_VS      <= vga_vsync;

-- JOYSTICKS
joy : component joydecoder_neptuno
	port map(
		clk_i         => CLK_50_buf,
		joy_data_i    => joy_data,
		joy_clk_o     => joy_clk,
		joy_load_o    => joy_load_n,
		joy1_up_o     => joy1up,
		joy1_down_o   => joy1down,
		joy1_left_o   => joy1left,
		joy1_right_o  => joy1right,
		joy1_fire1_o  => joy1fire1,
		joy1_fire2_o  => joy1fire2,
		joy2_up_o     => joy2up,
		joy2_down_o   => joy2down,
		joy2_left_o   => joy2left,
		joy2_right_o  => joy2right,
		joy2_fire1_o  => joy2fire1,
		joy2_fire2_o  => joy2fire2
	);
	
joya        <= "11" & joy1fire2 & joy1fire1 & joy1right & joy1left & joy1down & joy1up;
joyb        <= "11" & joy2fire2 & joy2fire1 & joy2right & joy2left & joy2down & joy2up;

-- Core direct joystick
joy1                <= joy1fire2 & joy1fire1 & joy1up & joy1down & joy1left & joy1right;
joy2                <= joy2fire2 & joy2fire1 & joy2up & joy2down & joy2left & joy2right;

--  Joystick intercept signal
process(CLK_50_buf)
begin
	if (intercept = '1') then
		intercept_joy <= "111111";
		joy_sel    <= '1';
	else
		intercept_joy <= "000000";
		joy_sel    <= joy_select_o;
	end if;
end process;


-- I2S audio
audio_i2s : entity work.audio_top
	port map (
		clk_50MHz => CLK_50_buf,
		dac_MCLK  => i2s_mclk,
		dac_SCLK  => I2S_BCLK,
		dac_SDIN  => I2S_DATA,
		dac_LRCK  => I2S_LRCLK,
		L_data    => std_logic_vector(dac_l),
		R_data    => std_logic_vector(dac_r)
	);



	guest : component mist_top
		port map
		(
			CLOCK_27 	=> clock_input&clock_input,
			CLOCK_27_buff => CLK_50_buf,
			LED 		=> act_led,

			--SDRAM
			SDRAM_DQ   => DRAM_DQ,
			SDRAM_A    => DRAM_ADDR,
			SDRAM_DQML => DRAM_LDQM,
			SDRAM_DQMH => DRAM_UDQM,
			SDRAM_nWE  => DRAM_WE_N,
			SDRAM_nCAS => DRAM_CAS_N,
			SDRAM_nRAS => DRAM_RAS_N,
			SDRAM_nCS  => DRAM_CS_N,
			SDRAM_BA   => DRAM_BA,
			SDRAM_CLK  => DRAM_CLK,
			SDRAM_CKE  => DRAM_CKE,

			--SRAM
			SRAM_A		=> SRAM_A,
			SRAM_Q		=> SRAM_Q,
			SRAM_WE		=> sram_we_x,
			LF_SRAM		=> lf_sram,

			--UART
			UART_TX    => PMOD4_D5,
			UART_RX    => PMOD4_D4,

			--SPI
		--	SPI_DO     => spi_do,
			SPI_DO     => spi_fromguest,
			SPI_DO_IN  => sd_miso,
			SPI_DI     => spi_toguest,
			SPI_SCK    => spi_clk_int,
			SPI_SS2    => spi_ss2,
			SPI_SS3    => spi_ss3,
			SPI_SS4    => spi_ss4,
			CONF_DATA0 => conf_data0,

			--VGA
			VGA_HS    => vga_hsync,
			VGA_VS    => vga_vsync,
			VGA_R      => vga_red(7 downto 2),
			VGA_G      => vga_green(7 downto 2),
			VGA_B      => vga_blue(7 downto 2),

			--HDMI
			--RED_x      => vga_x_r,
			--GREEN_x    => vga_x_g,
			--BLUE_x     => vga_x_b,
			--HS_x       => vga_x_hs,
			--VS_x       => vga_x_vs,
			--VGA_DE     => vga_de,
			--VGA_CLK    => vga_clk,

			--JOYSTICKS
			JOY1 	   => joy1 or intercept_joy,   -- Block joystick when OSD is active
			JOY2 	   => joy2 or intercept_joy,   -- Block joystick when OSD is active
			JOY_SELECT => joy_select_o,

			--AUDIO
			DAC_L      => dac_l,
			DAC_R      => dac_r,
			AUDIO_L    => sigma_l,
			AUDIO_R    => sigma_r,

			OSD_EN	   => osd_en

		);


	-- Pass internal signals to external SPI interface
	sd_clk <= spi_clk_int;
	-- spi_do <= sd_miso when spi_ss4='0' else 'Z'; -- to guest
	-- spi_fromguest <= spi_do;  -- to control CPU

	controller : entity work.substitute_mcu
		generic map(
			sysclk_frequency => 500,
	--		SPI_FASTBIT=>3,
	--		SPI_INTERNALBIT=>2,		--needed if OSD hungs
	--		SPI_FASTBIT => 0, 		-- Reducing this will make SPI comms faster, for cores which are clocked fast enough.
	--		SPI_INTERNALBIT => 0, 	-- This will make SPI comms faster, for cores which are clocked fast enough.
			debug     => false,
			jtag_uart => false
		)
		port map(
			clk       => CLK_50_buf,					--50 MHz
			reset_in  => '1',							--reset_in  when 0
			reset_out => reset_n,						--reset_out when 0

			-- SPI signals
			spi_miso      => sd_miso,
			spi_mosi      => sd_mosi,
			spi_clk       => spi_clk_int,
			spi_cs        => sd_cs,
			spi_fromguest => spi_fromguest,
			spi_toguest   => spi_toguest,
			spi_ss2       => spi_ss2,
			spi_ss3       => spi_ss3,
			spi_ss4       => spi_ss4,
			conf_data0    => conf_data0,

			-- PS/2 signals
			ps2k_clk_in  => ps2_keyboard_clk_in,
			ps2k_dat_in  => ps2_keyboard_dat_in,
			ps2k_clk_out => ps2_keyboard_clk_out,
			ps2k_dat_out => ps2_keyboard_dat_out,
			ps2m_clk_in  => ps2_mouse_clk_in,
			ps2m_dat_in  => ps2_mouse_dat_in,
			ps2m_clk_out => ps2_mouse_clk_out,
			ps2m_dat_out => ps2_mouse_dat_out,

			-- Buttons
			buttons => (others => '1'),	-- 0 = opens OSD

			-- Joysticks
			joy1 => joya,
			joy2 => joyb,

			-- UART
			rxd  => rs232_rxd,
			txd  => rs232_txd,
			--
			intercept => intercept
		);

	LED5 <= not act_led;

end rtl;
