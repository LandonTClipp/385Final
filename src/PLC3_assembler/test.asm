ANDi R0,R0,0
BRnzp 3
0x0009		 	; master address
0x0014		 	; kernel address
0x0010		 	; pointer to the array to increment
BR_CPUID 0,3 		; skip master CPU to line 9
LD R0,-4	 	; if a slave, load beginning of kernel
LD R6,-4	 	; load array pointer to R6
JMP R0		 	; branch to beginning of kernel
SYNC 1111	 	; 		MASTER: beginning of master program
CPU_SEL 1111 		; instruct the slaves to begin
BRnzp 0
CPU_SEL 0000 		; Remove the "run" signal to prevent immediate continuation
SYNC 1111	 	; wait until the slaves are done
READY		 	; send ready signal to top-level
WAIT		 	; program is done
0x0000			; array[0]
0x0000			; array[1]
0x0000			; array[2]
0x0000			; array[3]
READY			; 		KERNEL: set ready signal to 1
WAIT			; wait until master gives the go-ahead
ANDi R1,R1,0		; clear R1 for all slaves
ADDi R1,R1,15		; store 15 in all slaves (number of times to increment)
BR_CPUID 1,3
BR_CPUID 2,4
BR_CPUID 3,5
BR_CPUID 4,6
LDR R0,R6,0		; Load the value to increment into R0 (CPU1)
BRnzp 5
LDR R0,R6,1		; Load the value to increment into R0 (CPU2)
BRnzp 3
LDR R0,R6,2		; Load the value to increment into R0 (CPU3)
BRnzp 1
LDR R0,R6,3		; Load the value to increment into R0 (CPU4)
ADDi R0,R0,1		; Increment the value
BR_CPUID 1,3
BR_CPUID 2,4
BR_CPUID 3,5
BR_CPUID 4,6
STR R0,R6,0 		; store value back to array (CPU1)
BRnzp 5 
STR R0,R6,1 		; store value back to array (CPU2)
BRnzp 3
STR R0,R6,2 		; store value back to array (CPU3)
BRnzp 1
STR R0,R6,3 		; store value back to array (CPU4)
NOT R0,R0		; Do 2's compliment
ADDi R0,R0,1		; 2's compliment
ADD R0,R0,R1		; see if we are done incrementing
BRp -27		; If we're not done, continue on
READY
WAIT