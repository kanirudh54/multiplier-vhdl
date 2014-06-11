--------ADDER---------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
--use IEEE.numeric_std.all;

entity adder is
        port (
                a,b: in STD_LOGIC_VECTOR (7 downto 0);
                adder_result: out STD_LOGIC_VECTOR (7 downto 0)
        );
end adder;

architecture func1 of adder is
begin
   alu_process : process(a,b)

      variable op1 : integer;
      variable op2 : integer;
      variable res : integer;

 function to_integer(X: STD_LOGIC_VECTOR) return INTEGER is
  variable result: INTEGER;
  begin
          result := 0;
          for i in X'range loop
                  result := result * 2;
                  case X(i) is
                          when '0' | 'L' => null;
                          when '1' | 'H' => result := result + 1;
                          when others => null;
                  end case;
          end loop;
          return result;
 end to_integer;

  begin
     op1 := to_integer(a(7 downto 0));
     op2 := to_integer(b(7 downto 0));	  
     res := op1 + op2;
     adder_result <= conv_std_logic_vector(res, 8) after 5 ns;
  end process alu_process;
end func1;

------clock-------------------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity clock is 
 port(value : out std_logic);
end clock;

architecture func2 of clock is

signal clock_value : std_logic := '0';
--variable clock_value : integer := 0;
begin
	Set: value <= clock_value;
	clock_process: Process(clock_value) is
		       begin
				clock_value <= not clock_value after 20 ns;
			end Process clock_process;
end func2;
-------------register----------------------
library IEEE;
use IEEE.std_logic_1164.all;

entity hiloregister is
	port(mcand, HI, LO, addedHI: in STD_LOGIC_VECTOR(7 downto 0);
		testbit: out STD_LOGIC;
		shiftright, reset, load, add, clockval: in STD_LOGIC;
		result: out STD_LOGIC_VECTOR(15 downto 0)
	);
end entity;

architecture func3 of hiloregister is

component adder is
	port (
                a,b: in STD_LOGIC_VECTOR (7 downto 0);
                adder_result: out STD_LOGIC_VECTOR (7 downto 0)
    );
end component;

signal HILO: STD_LOGIC_VECTOR(15 downto 0);

begin

A0:testbit <= HILO(0);
A1:
	process(clockval) is
	begin
		if(clockval='1') then
			if(reset='1') then
				HILO <= "0000000000000000";
			end if;
			if(load='1') then
				HILO(15 downto 8) <= HI;
				HILO(7 downto 0) <= LO;
			end if;
			if(add='1') then
				HILO(15 downto 8) <= addedHI;
			end if;
			if(shiftright='1') then
				HILO(14 downto 0) <= HILO(15 downto 1);
				HILO(15) <= '1';
			end if;
		end if;
	
	result(15 downto 8) <= HILO(15 downto 8);
	result(7 downto 0) <= HILO(7 downto 0);
	testbit <= HILO(0);
	
	end process;
end func3;

-------------------control-----------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;

entity control is
	port( writeflag, shiftflag, addflag, loadflag: out STD_LOGIC;
		clk, LO, reset: in STD_LOGIC
	);
end entity;

architecture func4 of control is

type statetype is (Load, Shift, Continue, EndS);
signal state: statetype;
signal repetitions: INTEGER:= 0;
signal leastBit: STD_LOGIC:= LO;

begin

	process
	variable next_state : statetype := Load;
	
	begin
		leastBit <= LO;
		wait until (clk'event and clk='1');
		if reset = '1' then
			state <= statetype'left;
		else
			loadflag <= '0';
			shiftflag <= '0';
			addflag <= '0';
			case state is
			when Load =>
				loadflag <= '1';
				shiftflag <= '0';
				addflag <= '0';
				next_state := Continue;
			when Continue =>
			if leastBit='0' then
				next_state := Shift;
				loadflag <= '0';
				shiftflag <= '0';
				addflag <= '0';
			else
				next_state := Shift;
				loadflag <= '0';
				shiftflag <= '0';
				addflag <= '1';				
			end if;
			when Shift =>
				next_state := Continue;
				loadflag <= '0';
				shiftflag <= '1';
				addflag <= '0';
			when Ends =>
				loadflag <= '0';
				shiftflag <= '0';
				addflag <= '0';
				null;
			end case;
			repetitions <= repetitions + 1;
			if(repetitions = 20) then
				next_state := EndS;
			end if;
			state <= next_state;
		end if;
	end process; 
end func4;
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.all;


entity multiplier is
	port ( input: in STD_LOGIC_VECTOR (7 downto 0); ---mcand, mplier
	reset: in STD_LOGIC;
	product: out STD_LOGIC_VECTOR (15 downto 0);---See
	store: out std_logic_vector(7 downto 0); 
	condition : in  STD_LOGIC_VECTOR (3 downto 0)
	);
end multiplier;

architecture Behavioral of multiplier is

		component hiloregister is
		port(mcand, HI, LO, addedHI: in STD_LOGIC_VECTOR(7 downto 0);
				testbit: out STD_LOGIC;
				shiftright, reset, load, add, clockval: in STD_LOGIC;
				result: out STD_LOGIC_VECTOR(15 downto 0)
			);
		end component;

		component control is
		port( writeflag, shiftflag, addflag, loadflag: out STD_LOGIC;
				clk, LO, reset: in STD_LOGIC
			);
		end component;

		component clock is
			port(value : out std_logic);
		end component;

		component adder is
				  port (
							 a,b: in STD_LOGIC_VECTOR (7 downto 0);
							 adder_result: out STD_LOGIC_VECTOR (7 downto 0)
				  );
		end component;
		signal productval: STD_LOGIC_VECTOR (15 downto 0);
		signal writeflagsignal, shiftflagsignal, addflagsignal, clocksig, LSB, resetsignal, loadsignal: STD_LOGIC;	
		signal mplier: std_logic_vector(7 downto 0);
		signal mcand: std_logic_vector(7 downto 0);
		signal productHI: STD_LOGIC_VECTOR (7 downto 0);
		signal addHIsignal: STD_LOGIC_VECTOR (7 downto 0);
begin


		CLOCK1 : clock port map(clocksig);
		ADD1 : adder port map(productHI, mcand, mcand);
		M1: control port map (writeflagsignal, shiftflagsignal, addflagsignal, loadsignal, clocksig, LSB, resetsignal);
		M2 : hiloregister port map(mcand, mcand, mplier, mcand, LSB, shiftflagsignal, resetsignal, loadsignal, addflagsignal, clocksig, productval);
		--product <= productval(15 downto 0);
		process(condition)
		begin
		resetsignal <= reset;
		LSB <= productval(0);
		if(condition="0001")then
			mplier<=input;
		elsif(condition="0010")then
			mcand<=input;
			productHI<= mcand;
			--addHIsignal<= mcand;
		elsif(condition="0010")then
			store <= productval(15 downto 8);
		elsif(condition="0010")then
			store <= productval(7 downto 0);
		else
			store<="00000000";	
			--product<="0000000000000000";	
		end if;
	end process;
	

end Behavioral;

