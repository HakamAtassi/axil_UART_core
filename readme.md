
# TODO
* ~Integrate baud bridge~
* ~Integrate fifos~
* Wrap with AXI interface
* AXI bursts?
* Wrap in TileLink
* Write more robust test benches










# Notes (currently for personal reference)

The logic is of data transfers is the following:

1) When valid == 1'b1 && ready == 1'b1, a packet of data is transmitted from the master to the slave. 
2) When valid == 1'b1 && ready == 1'b0, no transfer occurs but the master must hold data until ready is high. 
	2.1) If this is not enforeced, packets will be lost.
3) When valid == 1'b0 && ready == 1'bx, the output can on the masted can change.
	3.1) The only other time this is true is if valid == 1'b1 && ready == 1'b1 (data is being transfered)



https://www.youtube.com/watch?v=okiTzvihHRA&ab_channel=DillonHuff
