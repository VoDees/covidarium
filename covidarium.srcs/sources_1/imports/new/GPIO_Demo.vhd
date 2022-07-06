----------------------------------------------------------------------------
-- Authors: David Vodak, Daniel kondys
-- Usage:   top for Digilent Basys3 board
-- This file is edited version of former Digilent demo:
-- https://github.com/Digilent/Basys-3-GPIO/blob/v2018.2-3/src/hdl/GPIO_Demo.vhd
----------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

--The IEEE.std_logic_unsigned contains definitions that allow
--std_logic_vector types to be used with the + operator to instantiate a
--counter.
use IEEE.std_logic_unsigned.all;

entity GPIO_demo is
    Port (
        SW           : in    STD_LOGIC_VECTOR (15 downto 0);
        BTN          : in    STD_LOGIC_VECTOR (4 downto 0);
        CLK          : in    STD_LOGIC;
        LED          : out   STD_LOGIC_VECTOR (15 downto 0);
        SSEG_CA      : out   STD_LOGIC_VECTOR (7 downto 0);
        SSEG_AN      : out   STD_LOGIC_VECTOR (3 downto 0);
        UART_TXD     : out   STD_LOGIC;
        VGA_RED      : out   STD_LOGIC_VECTOR (3 downto 0);
        VGA_BLUE     : out   STD_LOGIC_VECTOR (3 downto 0);
        VGA_GREEN    : out   STD_LOGIC_VECTOR (3 downto 0);
        VGA_VS       : out   STD_LOGIC;
        VGA_HS       : out   STD_LOGIC;
        PS2_CLK      : inout STD_LOGIC;
        PS2_DATA     : inout STD_LOGIC
    );
end GPIO_demo;

architecture Behavioral of GPIO_demo is

    component debouncer

    Generic(
        DEBNC_CLOCKS : integer;
        PORT_WIDTH   : integer
    );

    Port(
        SIGNAL_I : in  std_logic_vector(4 downto 0);
        CLK_I    : in  std_logic;
        SIGNAL_O : out std_logic_vector(4 downto 0)
    );

    end component;

    component vga_ctrl

    Port ( CLK_I       : in STD_LOGIC;
           VGA_HS_O    : out STD_LOGIC;
           VGA_VS_O    : out STD_LOGIC;
           VGA_RED_O   : out STD_LOGIC_VECTOR (3 downto 0);
           VGA_BLUE_O  : out STD_LOGIC_VECTOR (3 downto 0);
           VGA_GREEN_O : out STD_LOGIC_VECTOR (3 downto 0);

           VGA_RED_I   : in STD_LOGIC_VECTOR (3 downto 0);
           VGA_GREEN_I : in STD_LOGIC_VECTOR (3 downto 0);
           VGA_BLUE_I  : in STD_LOGIC_VECTOR (3 downto 0);

           H_CNT_O     : out STD_LOGIC_VECTOR (11 downto 0);
           V_CNT_O     : out STD_LOGIC_VECTOR (11 downto 0)
           );
    end component;

    --Used to determine when a button press has occured
    signal btnReg      : std_logic_vector (3 downto 0) := "0000";
    signal btnDetect   : std_logic;

    --Debounced btn signals used to prevent single button presses
    --from being interpreted as multiple button presses.
    signal btnDeBnc    : std_logic_vector(4 downto 0);

    signal h_cnt       : std_logic_vector (11 downto 0);
    signal v_cnt       : std_logic_vector (11 downto 0);

    signal draw_bit    : std_logic := '0';

    signal vga_red_s   : std_logic_vector (3 downto 0);
    signal vga_green_s : std_logic_vector (3 downto 0);
    signal vga_blue_s  : std_logic_vector (3 downto 0);

begin
    ----------------------------------------------------------
    ------              Button Control                 -------
    ----------------------------------------------------------
    --Buttons are debounced and their rising edges are detected
    --to trigger UART messages

    --Debounces btn signals
    Inst_btn_debounce: debouncer
    generic map(
        DEBNC_CLOCKS => (2**16),
        PORT_WIDTH   => 5
    )
    port map(
        SIGNAL_I => BTN,
        CLK_I    => CLK,
        SIGNAL_O => btnDeBnc
    );

    --Registers the debounced button signals, for edge detection.
    btn_reg_process : process (CLK)
    begin
        if (rising_edge(CLK)) then
            btnReg <= btnDeBnc(3 downto 0);
        end if;
    end process;

    --btnDetect goes high for a single clock cycle when a btn press is
    --detected. This triggers a UART message to begin being sent.
    btnDetect <= '1' when ((btnReg(0)='0' and btnDeBnc(0)='1') or
                           (btnReg(1)='0' and btnDeBnc(1)='1') or
                           (btnReg(2)='0' and btnDeBnc(2)='1') or
                           (btnReg(3)='0' and btnDeBnc(3)='1'))
                     else
                 '0';

    ----------------------------------------------------------
    ------              VGA Control                    -------
    ----------------------------------------------------------

    draw_bit <= '0' when h_cnt <= 100 and v_cnt <= 500 else '1';

    vga_red_s   <= "0010" when draw_bit = '0' else "1000";
    vga_green_s <= "1000" when draw_bit = '0' else "0010";
    vga_blue_s  <= "0010" when draw_bit = '0' else "0010";

    Inst_vga_ctrl: vga_ctrl port map(
        CLK_I       => CLK,
        VGA_HS_O    => VGA_HS,
        VGA_VS_O    => VGA_VS,
        VGA_RED_O   => VGA_RED,
        VGA_BLUE_O  => VGA_BLUE,
        VGA_GREEN_O => VGA_GREEN,

        H_CNT_O     => h_cnt,
        V_CNT_O     => v_cnt,

        VGA_RED_I   => vga_red_s,
        VGA_GREEN_I => vga_green_s,
        VGA_BLUE_I  => vga_blue_s
    );

end Behavioral;
