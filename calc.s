
section	.rodata
operand:
	DB	"%s",  0	; Format string

	operand2:
	DB	"%s", 10, 0	; Format string

printNumWithZero:
	DB	"%02x",0	; Format string
printNum:
	DB	"%x",0	; Format string
newLine:
	DB  10,0


callCalc: 
		DB 		"calc: ",0
printerror1:
		DB    "Error: Insufficient Number of Arguments on Stack",0
printerror2:
		DB    "Error: stack overflow",0
printerror3:
		DB	  "Error: illegal input, please enter number or valid operator"

section .bss
	buffer : RESB 80 ; store the input
    lastLink : RESb 4	
	newLink : RESb 4
	list_head : RESb 4
	stack : RESb 5 ; the program stack
	

section	.data
stkp	dd 		stack
printCounter	dd 		0
operand_counter dd 		0
bitLink 		dd 		0
carry			dd		0
bitLink2		dd 		0
dbug			dd 		0



section .text
     align 16
     global main
     extern printf
     extern fprintf
     extern malloc
     extern free
     extern fgets
     extern stderr
     extern stdin
     extern stdout

main:
	 push	ebp
	 mov	ebp, esp

     cmp byte[ebp+8],1               ;check if argc is larger then 1 if not jump to start      
     jbe start  				     
     mov ecx, dword [ebp+12]                             
     mov ecx, dword[ecx+4]                      
	 cmp byte[ecx],45                ;check if first char is "-"
	 jne start
	 cmp byte[ecx+1],100			 ;check if second char is "d"
	 jne start
	 cmp byte[ecx+2],0				 ;check if we finish string
	 jne start
	 mov byte[dbug],1               ;if we get "-d" dfleg gets value 1

start:

	call calc

	push eax
	push printNum
	call printf
	add esp,8
	push newLine
	push operand
	call printf
	add esp , 8
	
     mov     eax,1                       ;system call number (sys_exit)
     int     0x80                        ;call kerne
     
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;macro for debug mode
    %macro debug_mode 0



    mov edx,dword [stkp]
	sub edx,4    			; update stack pointer
	mov  ebx, dword [edx]

	
%%loop2:							;this lable scaning the last num on the stack and prepare to print
	mov edx,0
	mov dl, byte [ebx] 			; move the current-link data to edx
	push edx
	mov ebx, dword [ebx+1] 		; move to the next link
	add dword [printCounter], 1 ; count the numbers to print later
	cmp ebx,0					; check if the first number is zero 
		jz %%delete_zero
	jmp %%loop2

%%delete_zero:					; delete the leading zeroes
	cmp dword [printCounter],0  ; if we have to print only zero
	je %%print_zero
	mov edx , 0
	pop edx
	cmp edx, 0
	jg %%print_first				; after remove all the "first" zeros
	sub dword [printCounter], 1
	jmp %%delete_zero

%%print_zero:
	push 0
	push printNum
	call printf
	add esp, 8
	jmp %%end_of_print

%%print_first:				; print without leading zeros

	cmp dword [printCounter], 0
		je %%end_of_print
	push edx
	push printNum
	call printf
	add esp, 8
	sub dword [printCounter], 1

%%print:
	cmp dword [printCounter], 0 ; check if we finish the printing
		je %%end_of_print
	
	push printNumWithZero
	call printf
	add esp, 8
	sub dword [printCounter], 1
	jmp print

%%end_of_print: 			
	push newLine
	push operand
	call printf
	add esp,8
	%endmacro
;;;;;;;;;;;;;;;;;;;;;;;;;
calc:
    push  ebp            ;push ebp register
    mov   ebp, esp       ;set the base pointer to point at the bottom of the stack


func_calc:
	mov [buffer],dword 0
	mov ecx,0
	mov ebx,0
	mov edx,0
	mov eax,0
	push callCalc
	call printf
	add esp ,4
	push dword [stdin]              ;fgets need 3 param
	push dword 80                   ;max lenght
	push dword buffer               ;input buffer
	call fgets
	add esp,12	

	cmp byte [buffer], 43 ; case operator "+"
	je add

	cmp byte[buffer], 112 ; case operator "p"
	je pop_and_print

	cmp byte[buffer], 113 ; case operator "q"
	je quit

	cmp byte [buffer], 100 ; case operator "d"
	je duplicate

	cmp byte [buffer], 38 ; case operator "&"
	je bitwise_and

	cmp byte [buffer], 47 
		jg check2 ; case number entered
		jle error ; invalid input

check2:
	cmp byte [buffer], 58
		jl number ; case number entered
		jge error ; invalid input



number:
	mov edx, stack 			;check if stack is full
	add edx,20
	cmp dword [stkp], edx 
	je stack_overflow

	mov ecx, 0	;Get argument (pointer to string)
	mov ebx, -1			;counter for length

check_length:						; checking the leangth of the new num
	cmp byte [buffer+ecx], 0		;if end of string
		jz check_odd
	inc ebx
	inc ecx
	jmp check_length	

check_odd: 						;if the leangth is odd we need to prepare one link with one digit 
	mov ecx, 0
	and ebx, 1					;check if odd
	jz even					;jump if even
	
odd: 					;makw link with only one digit
	push ecx
	push 5
	call malloc 		; allocate memory for new link
	add esp,4
	mov [lastLink], eax 
	pop ecx
	mov eax, [lastLink]
	mov edx,0
	mov dl, [buffer+ecx]		; move the next num from the buffer
	sub dl,48					; convert to decimal num
	mov [eax], dl 				; put the current-link data in the new link
	mov [eax+1] ,dword 0
	inc ecx
	jmp loop

even:					; makes the first link of the new number 
	push ecx
	push 5
	call malloc			; allocate memory for new link
	add esp,4
	mov [lastLink], eax
	pop ecx
	mov eax, [lastLink]
	mov edx,0
	mov ebx,0
	mov dl, [buffer+ecx]
	inc ecx
	mov bl, [buffer+ecx]
	sub bl,48					; convert to decimal num
	sub dl,48					; convert to decimal num
	shl dl, 4					; multiply al * 4
	or bl,dl
	mov [eax], bl
	mov[eax+1],dword 0
	inc ecx

loop:								; make the list
	cmp byte [buffer+ecx], 10		;if end of string
		jz update_stack
	
	push ecx
	push 5
	call malloc
	add esp,4
	mov [newLink], eax
	pop ecx
	mov eax, [newLink]
	mov edx,0
	mov dl, [buffer+ecx]
	inc ecx
	mov bl, [buffer+ecx]
	sub dl,48					; convert to decimal num
	shl dl, 4					;multiply al * 4
	sub bl, 48
	or bl,dl
	mov [eax], bl
	mov edx, dword [lastLink]
	mov[eax+1], edx
	mov [lastLink],eax
	inc ecx
	jmp loop
		
update_stack:
	mov edx,dword [lastLink]  ; 
	mov ebx,dword [stkp]	; 	
	mov dword[ebx],edx 
	add dword [stkp],4 	; update the stack pointer (our  stack) to next empty place
	
	mov ebx,0
	cmp dword [dbug],1
	jne no_debug
    debug_mode 

    no_debug:
	jmp func_calc



pop_and_print:						
	add dword [operand_counter], 1  
	cmp dword [stkp], stack  		; check if there is at least one element in the stack 
		je error_empty_stack
	mov edx,dword [stkp]
	sub edx,4    			; update stack pointer
	mov dword [stkp], edx
	mov  ebx, dword [edx]

	
loop2:							;this lable scaning the last num on the stack and prepare to print
	mov edx,0
	mov dl, byte [ebx] 			; move the current-link data to edx
	push edx
	mov ebx, dword [ebx+1] 		; move to the next link
	add dword [printCounter], 1 ; count the numbers to print later
	cmp ebx,0					; check if the first number is zero 
		jz delete_zero
	jmp loop2

delete_zero:					; delete the leading zeroes
	cmp dword [printCounter],0  ; if we have to print only zero
	je print_zero
	mov edx , 0
	pop edx
	cmp edx, 0
	jg print_first				; after remove all the "first" zeros
	sub dword [printCounter], 1
	jmp delete_zero

print_zero: 					; if the number we need to print is 0
	push 0
	push printNum
	call printf
	add esp, 8
	jmp end_of_print

print_first:				; printthe first 2 digits without leading zeros

	cmp dword [printCounter], 0
		je end_of_print
	push edx
	push printNum
	call printf
	add esp, 8
	sub dword [printCounter], 1

print: 							;print the num
	cmp dword [printCounter], 0 ; check if we finish the printing
		je end_of_print
	
	push printNumWithZero
	call printf
	add esp, 8
	sub dword [printCounter], 1
	jmp print

error_empty_stack:				; dealing with error empty stack
	push printerror1
	push operand2
	call printf
	add esp,8
	jmp func_calc


end_of_print: 					
	push newLine
	push operand
	call printf
	add esp,8
	jmp func_calc


duplicate:
	mov edx, stack 			; check if we have enough space in our stack 
	add edx,20
	cmp dword [stkp], edx 
	je stack_overflow

	add dword [operand_counter], 1
	cmp dword [stkp], stack
		je error_empty_stack
	mov edx,dword [stkp]
	sub edx,4
	mov  ebx, dword [edx]
	mov ecx,0
	mov edx,0
	mov dl, byte [ebx] 		;save data of link
	pushad
	push 5
	call malloc				; allocate space for the first new link
	add esp,4
	mov [list_head], eax
	popad
	mov eax, dword [list_head]	; 
	mov dword [newLink], eax
	mov dword[lastLink], eax 	
	mov dword [eax], edx 		; set eax to contain new link
	mov ebx, dword [ebx+1]

middle_loop: 					;dealing with the rest of the list
		cmp ebx,0 				;check if we finish the list we duplicate
		je end_dup
		mov edx,0
		mov dl, byte [ebx]
		pushad
		push 5
		call malloc 					; creating space in memory for the new link
		add esp,4
		mov [newLink], eax
		popad
		mov eax, dword [newLink] 		
		mov dword [eax], edx 			; save the data on the new link
		mov ecx, dword [lastLink]		; linking the new link with the older
		mov dword [ecx+1], eax 			
		mov dword [lastLink], eax
		mov ebx, dword [ebx+1]
		cmp ebx,0
		je end_dup
		jmp middle_loop

end_dup:
		mov ecx, dword [newLink]  
		mov dword [ecx+1], 0  			; set the last link as "last" point on null
		mov edx,dword [list_head]
		mov ebx,dword [stkp] 			; set the new link at the begining of the stack 
		mov dword[ebx],edx
		add dword [stkp],4  			; update the stack pointer 

		cmp dword [dbug],1 				;checking debug flag
		jne no_debug2
   		debug_mode 

   		no_debug2:
		jmp func_calc

bitwise_and: 							;;;;;bitwise and
		mov ecx, dword [stkp]  			; if there is at least two elements on the stack
		sub ecx , 8
		cmp ecx, stack
		jl error_empty_stack ; 

		add dword [operand_counter], 1
		mov edx, dword [stkp]
		sub edx, 4 						; set the first number
		mov edx, dword [edx]
		mov ebx , dword [stkp]
		sub ebx, 8 						; set the second number
		mov ebx, dword [ebx]
		mov ecx, 0
		mov eax, 0

bitwise_loop:								;doing and between the 2 last lists on the stack
		mov cl, byte [ebx]					
		mov al , byte [edx]
		and cl, al 			
		mov byte [ebx], cl 		
		mov dword [bitLink], ebx 			; save the last link for the end
		mov edx, dword [edx+1] 				; move to next link 
		mov ebx, dword [ebx+1]				; move to next link 
		cmp edx, 0 							; the first element is shorter
		je edx_small
		cmp ebx , 0  						; the second element is shorter
		je end_of_bitwise
		jmp bitwise_loop

edx_small:									; when the last number in the stack is shorter than the lower 
		cmp ebx, 0
		je end_of_bitwise
		mov ecx, dword [bitLink] 			; set the last link we handle in the lower number to be the last one
		mov dword [ecx+1],0

loopi:							; free all the links after the link that have to be the last one
		cmp dword [ebx+1], 0  ; we got the end of link
		je end_of_bitwise
		mov eax, dword [ebx+1]
		pushad
		push ebx
		call free 			; free the un-needed links
		add esp,4
		popad
		mov ebx, eax
		jmp loopi

end_of_bitwise:					; update stck and check debug mode
		mov ecx, dword [stkp]	 ; move the stack pointer to the new current-link
		sub ecx , 4
		mov dword [stkp], ecx

		cmp dword [dbug],1
		jne no_debug3
   		debug_mode 

   		no_debug3:
		jmp func_calc		
		

error:							;dealing with illeagal input 	
		push printerror3 ; print "illegal input"
		push operand2
		call printf
		add esp,8
		jmp func_calc

stack_overflow:					;dealing with stack over flow 
		push printerror2  ; print "stack-overflow"
		push operand2
		call printf
		add esp,8
		jmp func_calc

add:							;;;;addition 
		mov ecx, dword [stkp]
		sub ecx , 8
		cmp ecx, stack 				; check for enough numbers on stack 
		jl error_empty_stack

		mov byte [carry], 0 		; cleaning carry 
		add dword [operand_counter], 1
		mov edx, dword [stkp]
		sub edx, 4
		mov edx, dword [edx]
		mov ebx , dword [stkp]
		sub ebx, 8 					;saving the two top numbers on stack in registers
		mov ebx, dword [ebx]
		mov ecx, 0
		mov eax, 0
		mov dword [bitLink],0
		mov dword [bitLink2],0

loop_add: 								; addition of thw last 2 list on stack
		mov cl, byte [ebx]
		mov al , byte [edx]
		add al, byte [carry] 			;add carry to al
		add al, cl 						; adding the current two  digits from the lists
		daa 
		setc byte [carry] 				;update carry 
		mov byte [ebx], al
		mov dword [bitLink], edx
		mov dword [bitLink2], ebx
		mov edx, dword [edx+1]
		mov ebx, dword [ebx+1] 			; moving to the next two digits 
		cmp edx, 0
		je edx_small_add 				; if the higher num on stack is the smaller
		cmp ebx , 0
		je ebx_small_add 				;if the lower num is smaller
		jmp loop_add

edx_small_add: 							;we need to move on the lower num in the stack and add the carry to his links untill carryFlag =0
		mov eax,0
		cmp ebx, 0 						;if we finish dealing with the lower num 
		je end_of_add
		mov al, byte [ebx]
		add al, byte [carry]
		daa
		setc byte [carry] 	; save the carry result from daa
		mov byte [ebx], al
		mov dword [bitLink2], ebx  ; save the last link for later :)
		mov ebx, dword [ebx+1]
		jmp edx_small_add

ebx_small_add: 							;the lower num is shorter- we need to connect betwwen his last link to the rest of the higher num
		cmp edx, 0
		je end_of_add
		mov ecx, dword [bitLink2]
		mov dword [ecx+1], edx
		mov ebx, edx

add_carry: 								; add the carry (if carryFlag != 0) to the rest of the list 
		cmp byte [carry],0
			je end_of_add
		mov eax,0
		mov al, byte [ebx]
		add al, byte [carry] 			;add carry to the current link 
		daa
		setc byte [carry]
		mov byte [ebx], al
		mov dword [bitLink2], ebx
		mov ebx, dword [ebx+1]
		cmp ebx,0  						;finish scaning lower number 
			je end_of_add
		jmp add_carry

end_of_add: 
		cmp byte [carry],0 			; if carry=0 we finish, else we need to malloc new link to the result list
		jg add_link
		mov ecx, dword [stkp]
		sub ecx , 4 				; update stack pointer 
		mov dword [stkp], ecx

		cmp dword [dbug],1 			;check debug mode 
		jne no_debug5
    	debug_mode 

    	no_debug5:
		jmp func_calc

add_link: 				; add new link to the result (for carry)
		pushad
		push 5
		call malloc 
		add esp,4
		mov [newLink], eax
		popad
		mov eax, [newLink]
		mov byte [eax], 1
		mov ebx, dword [bitLink2]
		mov dword [eax+1],0 
		mov dword [ebx+1], eax
		mov ecx, dword [stkp] 			;update stack 
		sub ecx , 4
		mov dword [stkp], ecx

		cmp dword [dbug],1
		jne no_debug4
    	debug_mode 

    	no_debug4:
		jmp func_calc

quit:
	mov eax,dword [operand_counter];           ;return operand counter value to main
    mov esp,ebp
    pop ebp
    ret
