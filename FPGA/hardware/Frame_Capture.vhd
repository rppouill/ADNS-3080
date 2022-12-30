LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_ARITH.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;



ENTITY FRAME_CAPTURE IS
GENERIC (
	CLK_FREQ	: INTEGER RANGE 500 TO 2000 := 1000		-- Main frequency (kHz)
);
PORT(
	SCLK_I		:	IN 	STD_LOGIC;
	RST_I			:	IN 	STD_LOGIC;
	
	MISO			:	IN 	STD_LOGIC;
	NCS_CMD		:	IN 	STD_LOGIC;
	NEW_PXL		:	IN		STD_LOGIC;
	
	SCLK_O		:	OUT	STD_LOGIC;
	MOSI			: 	OUT 	STD_LOGIC;
	NCS			: 	OUT 	STD_LOGIC;
	RST_O			: 	OUT 	STD_LOGIC;

	DATA		 	: 	BUFFER 	STD_LOGIC_VECTOR(7 DOWNTO 0);
	DATA_EN		:	OUT		STD_LOGIC
	);
END FRAME_CAPTURE;




ARCHITECTURE SPI OF FRAME_CAPTURE IS  


-- COMPONENT DECLARATION --


--CONSTANT DECLARATION--
CONSTANT DATA_FRAME_CAPTURE	:	STD_LOGIC_VECTOR(15 DOWNTO 0) := "1001001110000011";
CONSTANT DATA_PIXEL_BURST		:	STD_LOGIC_VECTOR( 7 DOWNTO 0) := "01000000";

CONSTANT BYTE				:	INTEGER RANGE 0 TO  8 :=  8;
CONSTANT BYTES_2			:	INTEGER RANGE 0 TO 16 := 16;


	-- CONSTANT FOR THE DELAY --
CONSTANT CYCLE	:	INTEGER	:= 2;

CONSTANT DELAY_FRAM_CAPTURE_US			:	INTEGER RANGE 0 TO 50 										:= 			 					   50;
CONSTANT DELAY_FRAME_CAPTURE_CYCLE		:	INTEGER RANGE 0 TO CYCLE * DELAY_FRAM_CAPTURE_US	:= CYCLE * DELAY_FRAM_CAPTURE_US;

CONSTANT T_SRAD_US							:	INTEGER RANGE 0 TO 50 										:= 								   50;
CONSTANT T_SRAD_CYCLE						:	INTEGER RANGE 0 TO CYCLE * T_SRAD_US					:= CYCLE * 				  T_SRAD_US;

CONSTANT T_LOAD_US							:	INTEGER RANGE 0 TO 10										:=									   10;
CONSTANT T_LOAD_CYCLE						:	INTEGER RANGE 0 TO CYCLE * T_LOAD_US - BYTE			:= CYCLE *      T_LOAD_US - BYTE;

CONSTANT T_BEXIT_US							:	INTEGER RANGE 0 TO 14										:=										 14;
CONSTANT T_BEXIT_CYCLE						:	INTEGER RANGE 0 TO CYCLE * T_BEXIT_US					:=	CYCLE * 				 T_BEXIT_US;


--TYPE DECLARATION--	
TYPE STATE_TYPE IS (
	IDLE,
	FRAME_CAPTURE,
	DELAY_FRAME_CAPTURE,
	PIXEL_BURST,
	DELAY_BURST,
	FIRST_PIXEL,
	PIXEL,
	DELAY,
	EXIT_BURST_MODE
);


--SIGNAL DECLARATION--
SIGNAL STATE_MACHINE	:	STATE_TYPE							:=	IDLE;
SIGNAL NX_STATE		:	STATE_TYPE							:=	FIRST_PIXEL;
SIGNAL CLK_EN			:	STD_LOGIC							:=	 '0';

BEGIN

--PROCESS--
PROCESS(SCLK_I,RST_I)
--VARIABLE PROCESS
VARIABLE COUNTER				:	INTEGER	:= 0;
VARIABLE PIXEL_COUNTER		:	INTEGER	:=	0;
BEGIN
	IF RST_I = '0' THEN
		RST_O		<= '1';
		MOSI		<= '1';
		NCS		<= '1';
		CLK_EN 	<= '0';
		
		DATA		<= (others => '0');
		DATA_EN	<= '0';
				
		PIXEL_COUNTER := 1;
		      COUNTER := 0;
				
		STATE_MACHINE 	<= IDLE;
		NX_STATE			<= FIRST_PIXEL;
		
	
	ELSIF FALLING_EDGE(SCLK_I) THEN
		CASE STATE_MACHINE IS
			-- IDLE STATE --
			WHEN IDLE	=>
				RST_O	<= '0';
				DATA			<= (others => '0');
				DATA_EN		<= '0';
				IF NCS_CMD = '0' THEN
					STATE_MACHINE	<=	FRAME_CAPTURE;
					PIXEL_COUNTER	:=	 0 ;
				END IF;
				
				CLK_EN	<= '0';
				NCS		<= '1';
				
--======================================================================================--
---------------------------------- FRAME CAPTURE STATE -----------------------------------
--======================================================================================--			
				WHEN	FRAME_CAPTURE => 
					COUNTER 	:= COUNTER + 1;
					IF COUNTER >= BYTES_2 THEN
						COUNTER			:= 0;
						STATE_MACHINE	<= DELAY_FRAME_CAPTURE;
					ELSE
						MOSI				<= DATA_FRAME_CAPTURE(BYTES_2 - COUNTER);
					END IF;
					
					CLK_EN			<= '1';
					NCS				<= '0';
					
					
				WHEN DELAY_FRAME_CAPTURE => 
					COUNTER := COUNTER + 1;
					IF COUNTER >= DELAY_FRAME_CAPTURE_CYCLE THEN
						COUNTER 			:= 0;
						STATE_MACHINE	<= PIXEL_BURST;
					END IF;
					
					NCS				<=   		  '1';
					CLK_EN			<= 		  '0';
--======================================================================================--
------------------------------------ PIXLE BURST STATE -----------------------------------
--======================================================================================-- 
			WHEN PIXEL_BURST	=>
				COUNTER := COUNTER + 1;
				IF COUNTER	>= BYTE THEN
					STATE_MACHINE	<= DELAY_BURST;
					MOSI	<= '1';
				ELSE
					MOSI	<= DATA_PIXEL_BURST(BYTE - COUNTER);
				END IF;
				
				CLK_EN			<= 		  '1';
				NCS				<= 		  '0';
				
--======================================================================================--
------------------------------------ DELAY BURST MODE ------------------------------------
--======================================================================================-- 
			WHEN DELAY_BURST	=> 
				COUNTER := COUNTER + 1;
				IF COUNTER >= T_SRAD_CYCLE	THEN
					COUNTER := 0;
					STATE_MACHINE	<= FIRST_PIXEL;
				END IF;
				NCS	<= '0';
				CLK_EN <= '0';
	
--======================================================================================--
--------------------------------------- GET PIXEL ----------------------------------------
--======================================================================================-- 
	
			WHEN FIRST_PIXEL =>
				COUNTER := COUNTER + 1;
				IF COUNTER >= BYTE THEN
					STATE_MACHINE	<= DELAY;
					COUNTER := 0;
					
					IF DATA(6 DOWNTO 5) = "11" THEN
						DATA_EN	<= '1';
						NX_STATE <= PIXEL;
					ELSE
						NX_STATE <= FIRST_PIXEL;
					END IF;
				ELSE
					DATA(BYTE - COUNTER) <= MISO;
				

				END IF;
				
				NCS		<= '0';
				CLK_EN	<= '1';

				
			WHEN DELAY		=>
				COUNTER	:=	COUNTER + 1;
				IF COUNTER	>=  T_LOAD_CYCLE AND NEW_PXL = '1' THEN
					COUNTER := 0;
					STATE_MACHINE	<= NX_STATE;
					DATA_EN	<= '0';
					
				END IF;
				CLK_EN	<= '0';
				NCS		<= '0';
				
			WHEN PIXEL		=>
				COUNTER := COUNTER + 1;
				IF COUNTER >= BYTE THEN
					COUNTER := 0;
					STATE_MACHINE <= DELAY;
					PIXEL_COUNTER := PIXEL_COUNTER + 1;
					DATA_EN	<= '1';
				ELSE
					DATA(BYTE - COUNTER) <= MISO;
					
				IF PIXEL_COUNTER = 899 THEN
						NX_STATE	<= EXIT_BURST_MODE;
					END IF;
				END IF;
				
				CLK_EN	<=	'1';
				NCS		<= '0';
				
			WHEN EXIT_BURST_MODE =>
				COUNTER := COUNTER + 1;
				IF COUNTER >= T_BEXIT_CYCLE THEN
					STATE_MACHINE	<= IDLE;
					COUNTER	:= 0;
					PIXEL_COUNTER	:= 0;
					NX_STATE			<= FIRST_PIXEL;
				END IF;
				CLK_EN	<= '0';
				NCS		<= '1';
			
				
		END CASE;
	END IF;
END PROCESS;
	--NCS	<= NCS_CMD;
	--RST_O		<= not(RST_I);
	SCLK_O	<= 	SCLK_I when CLK_EN = '1' else '1';

	
END ARCHITECTURE SPI;
