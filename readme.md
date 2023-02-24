
# AXI Handshaking


The process of performing a handshake is essentially a way of encapsulating when a valid
data transfer takes place between a master and slave and/or series of masters and series of slaves


The handshaking process depends on a valid signal that is controlled by a master and a ready signal
that is controlled by a slave. 

The logic is of data transfers is the following:

1) When valid == 1'b1 && ready == 1'b1, a packet of data is transmitted from the master to the slave. 
2) When valid == 1'b1 && ready == 1'b0, no transfer occurs but the master must hold data until ready is high. 
	2.1) If this is not enforeced, packets will be lost.
3) When valid == 1'b0 && ready == 1'bx, the output can on the masted can change.
	3.1) The only other time this is true is if valid == 1'b1 && ready == 1'b1 (data is being transfered)



https://www.youtube.com/watch?v=okiTzvihHRA&ab_channel=DillonHuff
