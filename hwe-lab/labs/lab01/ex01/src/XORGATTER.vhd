entity XORGATTER is
	port (X,Y: in bit;
			Z:out bit);
end entity;
		architecture Data of XORGATTER is
			begin
				Z <= X xor Y;
		end architecture;