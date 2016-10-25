library ieee;
	use	ieee.std_logic_1164.all;
	use	ieee.numeric_std.all;

library work;
	use work.cnn_types.all;

entity fcElement is

    generic(
        NB_IN_FLOWS :    integer;
        PIXEL_SIZE  :    integer
    );

    port(
        clk         :   in  std_logic;
        reset_n     :   in  std_logic;
        enable      :   in  std_logic;
        in_data     :   in  pixel_array (0 to NB_IN_FLOWS - 1);
        in_dv    	:   in  std_logic;
        in_fv    	:   in  std_logic;
        in_kernel   :   in  pixel_array (0 to NB_IN_FLOWS - 1);
        out_data    :   out std_logic_vector (3*PIXEL_SIZE downto 0);
        out_dv    	:   out std_logic;
        out_fv    	:   out std_logic

    );
end fcElement;

architecture bhv of fcElement is

    -- Signals
    type	pixel_array_s1 is array (0 to NB_IN_FLOWS - 1) of signed (PIXEL_SIZE downto 0);
	type	pixel_array_s2 is array (0 to NB_IN_FLOWS - 1) of signed (2 * PIXEL_SIZE + 1 downto 0);
	signal	data_s	    :	pixel_array_s1 ;
	signal	kernel_s	:	pixel_array_s1 ;
	signal	sums		:	signed (3 * PIXEL_SIZE downto 0);
    signal  all_valid   :   std_logic;

    begin
		-- All valid : Logic and
		all_valid    <=    in_dv and in_fv and enable;

        SIGNED_CAST     :   for i in 0 to ( NB_IN_FLOWS - 1 ) generate
            data_s(i)      <=  signed('0' & in_data(i));
            kernel_s(i)    <=  signed(in_kernel(i)(in_kernel(i)'LEFT) & (in_kernel(i)));
        end generate;

    process(clk)
        variable mul    :   pixel_array_s2;
        variable sum    :   signed (3 * PIXEL_SIZE downto 0):= (others=>'0');

        begin

            if (reset_n ='0') then
                sum := (others=>'0');
            elsif (RISING_EDGE(clk)) then
                if (all_valid='1') then

                    -- Product
                    Product : for i in 0 to ( NB_IN_FLOWS - 1 ) loop
                        mul(i) := data_s(i) * kernel_s(i);
                    end loop;
                    sum     := (others=>'0');

                    -- Summation
                    Summation : for i in 0 to ( NB_IN_FLOWS - 1 ) loop
                        sum := sum + mul(i);
                    end loop;
                    sums <=	sum;

                    end if;
            end if;
    end process;



    out_data    <=  std_logic_vector (sums);
	out_dv      <=  in_dv;
	out_fv      <=  in_fv;