library ieee;
	use	ieee.std_logic_1164.all;
	use	ieee.numeric_std.all;

library work;
	use work.cnn_types.all;

entity FirstLayer is
  generic(
      PIXEL_SIZE    :   integer :=8;
      IMAGE_WIDTH   :   integer :=254;
      KERNEL_SIZE   :   integer :=3
);

  port(
      clk	        :	in 	std_logic;
      reset_n	    :	in	std_logic;
      enable        :	in	std_logic;

      -- Image IN
      in_data 	    :	in 	std_logic_vector((PIXEL_SIZE-1) downto 0);
      in_dv	        :	in	std_logic;
      in_fv	        :	in	std_logic;
 

      -- Feature Maps OUT
      out_data_1    :	out	std_logic_vector((PIXEL_SIZE-1) downto 0);
      in_dv_1	    :	out	std_logic;
      in_fv_1       :	out	std_logic;

      out_data_2    :	out	std_logic_vector((PIXEL_SIZE-1) downto 0);
      in_dv_2	    :	out	std_logic;
      in_fv_2       :	out	std_logic;

      out_data_3    :	out	std_logic_vector((PIXEL_SIZE-1) downto 0);
      in_dv_3	    :	out	std_logic;
      in_fv_3       :	out	std_logic;
      
  );
end entity;

architecture rtl of FirstLayer is
    --------------------------------------------------------------------------------
    -- COMPONENTS
    --------------------------------------------------------------------------------
    component neighExtractor
    generic(
		PIXEL_SIZE      :   integer;
		IMAGE_WIDTH     :   integer;
		KERNEL_SIZE     :   integer
	);

    port(
		clk	            :	in 	std_logic;
        reset_n	        :	in	std_logic;
        enable	        :	in	std_logic;
        in_data         :	in 	std_logic_vector((PIXEL_SIZE-1) downto 0);
        in_dv	        :	in	std_logic;
        in_fv	        :	in	std_logic;
        out_data        :	out	pixel_array (0 to (KERNEL_SIZE * KERNEL_SIZE)- 1);
        out_dv			:	out std_logic;
        out_fv			:	out std_logic;
    );
    end component;

    --------------------------------------------------------------------------------
    component convElement

    generic(
        KERNEL_SIZE :    integer;
        PIXEL_SIZE  :    integer
    );

    port(
        clk         :   in  std_logic;
        reset_n     :   in  std_logic;
        enable      :   in  std_logic;
        in_data     :   in  pixel_array (0 to KERNEL_SIZE * KERNEL_SIZE - 1);
        in_dv    	:   in  std_logic;
        in_fv    	:   in  std_logic;
        in_kernel   :   in  pixel_array (0 to KERNEL_SIZE * KERNEL_SIZE - 1);
        in_norm     :   in  std_logic_vector(PIXEL_SIZE-1 downto 0);
        out_data    :   out std_logic_vector(PIXEL_SIZE-1 downto 0)
        out_dv    	:   out std_logic;
        out_fv    	:   out std_logic;

    );
    end component;



    --------------------------------------------------------------------------------
    -- SIGNALS
    --------------------------------------------------------------------------------

    signal s_neigh_data  :   pixel_array (0 to (KERNEL_SIZE * KERNEL_SIZE)- 1);
    signal s_neigh_dv    :   std_logic;
    signal s_neigh_fv    :   std_logic;

    --------------------------------------------------------------------------------
    -- WEIGHTS
    --------------------------------------------------------------------------------
    -- Kernel 1
    constant W11(0)     :   std_logic_vector (7 downto 0):= "10000001";
    constant W11(1)     :   std_logic_vector (7 downto 0):= "00000000";
    constant W11(2)     :   std_logic_vector (7 downto 0):= "00000001";
    constant W11(3)     :   std_logic_vector (7 downto 0):= "10000010";
    constant W11(4)     :   std_logic_vector (7 downto 0):= "00000000";
    constant W11(5)     :   std_logic_vector (7 downto 0):= "00000010";
    constant W11(6)     :   std_logic_vector (7 downto 0):= "10000001";
    constant W11(7)     :   std_logic_vector (7 downto 0):= "00000000";
    constant W11(8)     :   std_logic_vector (7 downto 0):= "00000001";

    -- Kernel 2
    constant W12(0)     :   std_logic_vector (7 downto 0):= "10000001";
    constant W12(1)     :   std_logic_vector (7 downto 0):= "10000010";
    constant W12(2)     :   std_logic_vector (7 downto 0):= "10000001";
    constant W12(3)     :   std_logic_vector (7 downto 0):= "00000000";
    constant W12(4)     :   std_logic_vector (7 downto 0):= "00000000";
    constant W12(5)     :   std_logic_vector (7 downto 0):= "00000000";
    constant W12(6)     :   std_logic_vector (7 downto 0):= "00000001";
    constant W12(7)     :   std_logic_vector (7 downto 0):= "00000010";
    constant W12(8)     :   std_logic_vector (7 downto 0):= "00000001";

    -- Kernel 3
    constant W13(0)     :   std_logic_vector (7 downto 0):= "00000001";
    constant W13(1)     :   std_logic_vector (7 downto 0):= "00000001";
    constant W13(2)     :   std_logic_vector (7 downto 0):= "00000001";
    constant W13(3)     :   std_logic_vector (7 downto 0):= "00000001";
    constant W13(4)     :   std_logic_vector (7 downto 0):= "00000110";
    constant W13(5)     :   std_logic_vector (7 downto 0):= "00000001";
    constant W13(6)     :   std_logic_vector (7 downto 0):= "00000001";
    constant W13(7)     :   std_logic_vector (7 downto 0):= "00000001";
    constant W13(8)     :   std_logic_vector (7 downto 0):= "00000001";

     -- NORMS : devide == shift
    constant N11        :   std_logic_vector (7 downto 0):= "00000000";
    constant N12        :   std_logic_vector (7 downto 0):= "00000000";
    constant N13        :   std_logic_vector (7 downto 0):= "00001000";
    

    --------------------------------------------------------------------------------
    -- BEGIN STRUCTURAL DESCRIPTION
    --------------------------------------------------------------------------------

    begin
        --Neighborhood Extractor
        inst_NE : neighExtractor
        generic map(
            PIXEL_SIZE	=> PIXEL_SIZE,
            IMAGE_WIDTH => IMAGE_WIDTH,
            KERNEL_SIZE	=> KERNEL_SIZE
        )
        port map(
            clk	        => clk,
            reset_n	    => reset_n,
            enable	    => enable,
            in_data     => in_data,
            in_dv	    => in_dv,
            in_fv	    => in_fv,
            out_data    => s_neigh_data,
            out_dv	    => s_neigh_dv,
            out_fv	    => s_neigh_fv
        );
        
        
        -- CE11
        inst_CE_11 : convElement
        generic map(
            KERNEL_SIZE => KERNEL_SIZE,
            PIXEL_SIZE  => PIXEL_SIZE
        )
        port map(
            clk         => clk,
            reset_n     => reset_n, 
            enable      => enable,
            in_data     => s_neigh_data,
            in_dv    	=> s_neigh_dv,
            in_fv    	=> s_neigh_fv,
            in_kernel   => W11,
            in_norm     => N11,  
            out_data    => out_data_1,
            out_dv    	=> out_dv_1,
            out_fv    	=> out_fv_1              
        );

        -- CE12
        inst_CE_12 : convElement
        generic map(
            KERNEL_SIZE => KERNEL_SIZE,
            PIXEL_SIZE  => PIXEL_SIZE
        )
        port map(
            clk         => clk,
            reset_n     => reset_n, 
            enable      => enable,
            in_data     => s_neigh_data,
            in_dv    	=> s_neigh_dv,
            in_fv    	=> s_neigh_fv,
            in_kernel   => W12,
            in_norm     => N12,  
            out_data    => out_data_2,
            out_dv    	=> out_dv_2,
            out_fv    	=> out_fv_2    
        );

        --CE13
        inst_CE_13 : convElement
        generic map(
            KERNEL_SIZE => KERNEL_SIZE,
            PIXEL_SIZE  => PIXEL_SIZE
        )
        port map(
            clk         => clk,
            reset_n     => reset_n, 
            enable      => enable,
            in_data     => s_neigh_data,
            in_dv    	=> s_neigh_dv,
            in_fv    	=> s_neigh_fv,
            in_kernel   => W13,
            in_norm     => N13,  
            out_data    => out_data_3
            out_dv    	=> out_dv_3
            out_fv    	=> out_fv_3    
        );

end architecture;
