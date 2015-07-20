;
;********************************************************************************************************
;                                                uC/OS-II
;                                          The Real-Time Kernel
;
;
;                              (c) Copyright 2010; Micrium, Inc.; Weston, FL
;                    All rights reserved.  Protected by international copyright laws.
;
;                                           ARM Cortex-M4 Port
;
; File      : OS_CPU_A.ASM
; Version   : V2.92
; By        : JJL
;             BAN
;
; For       : ARMv7 Cortex-M4
; Mode      : Thumb-2 ISA
; Toolchain : RealView Development Suite
;             RealView Microcontroller Development Kit (MDK)
;             ARM Developer Suite (ADS)
;             Keil uVision
;********************************************************************************************************
;

;********************************************************************************************************
;                                          PUBLIC FUNCTIONS
;********************************************************************************************************

    EXTERN  OSRunning                                           ; External references
    EXTERN  OSPrioCur
    EXTERN  OSPrioHighRdy
    EXTERN  OSTCBCur
    EXTERN  OSTCBHighRdy
    EXTERN  OSIntExit
    EXTERN  OSTaskSwHook
    EXTERN  OS_CPU_ExceptStkBase

    EXPORT  OS_CPU_SR_Save                                      ; Functions declared in this file
    EXPORT  OS_CPU_SR_Restore
    EXPORT  OSStartHighRdy
    EXPORT  OSCtxSw
    EXPORT  OSIntCtxSw
    EXPORT  PendSV_Handler

;PAGE
;********************************************************************************************************
;                                               EQUATES
;********************************************************************************************************

NVIC_INT_CTRL   EQU     0xE000ED04                              ; Interrupt control state register.
NVIC_SYSPRI14   EQU     0xE000ED22                              ; System priority register (priority 14).
NVIC_PENDSV_PRI EQU           0xFF                              ; PendSV priority value (lowest).
NVIC_PENDSVSET  EQU     0x10000000                              ; Value to trigger PendSV exception.


;********************************************************************************************************
;                                     CODE GENERATION DIRECTIVES
;********************************************************************************************************

    AREA |.text|, CODE, READONLY, ALIGN=2
    THUMB
    REQUIRE8
    PRESERVE8

;********************************************************************************************************
;                                   CRITICAL SECTION METHOD 3 FUNCTIONS
;
; Description: Disable/Enable interrupts by preserving the state of interrupts.  Generally speaking you
;              would store the state of the interrupt disable flag in the local variable 'cpu_sr' and then
;              disable interrupts.  'cpu_sr' is allocated in all of uC/OS-II's functions that need to
;              disable interrupts.  You would restore the interrupt disable state by copying back 'cpu_sr'
;              into the CPU's status register.
;
; Prototypes :     OS_CPU_SR  OS_CPU_SR_Save(void);
;                  void       OS_CPU_SR_Restore(OS_CPU_SR cpu_sr);
;
;
; Note(s)    : 1) These functions are used in general like this:
;
;                 void Task (void *p_arg)
;                 {
;                 #if OS_CRITICAL_METHOD == 3          /* Allocate storage for CPU status register */
;                     OS_CPU_SR  cpu_sr;
;                 #endif
;
;                          :
;                          :
;                     OS_ENTER_CRITICAL();             /* cpu_sr = OS_CPU_SaveSR();                */
;                          :
;                          :
;                     OS_EXIT_CRITICAL();              /* OS_CPU_RestoreSR(cpu_sr);                */
;                          :
;                          :
;                 }
;********************************************************************************************************

OS_CPU_SR_Save
    MRS     R0, PRIMASK                                         ; Set prio int mask to mask all (except faults)
    CPSID   I
    BX      LR

OS_CPU_SR_Restore
    MSR     PRIMASK, R0
    BX      LR

;PAGE
;********************************************************************************************************
;                                         START MULTITASKING
;                                      void OSStartHighRdy(void)
;
; Note(s) : 1) This function triggers a PendSV exception (essentially, causes a context switch) to cause
;              the first task to start.
;
;           2) OSStartHighRdy() MUST:
;              a) Setup PendSV exception priority to lowest;
;              b) Set initial PSP to 0, to tell context switcher this is first run;
;              c) Set the main stack to OS_CPU_ExceptStkBase
;              d) Set OSRunning to TRUE;
;              e) Trigger PendSV exception;
;              f) Enable interrupts (tasks will run with interrupts enabled).
;********************************************************************************************************

OSStartHighRdy
    LDR     R0, =NVIC_SYSPRI14                                  ; Set the PendSV exception priority
    LDR     R1, =NVIC_PENDSV_PRI
    STRB    R1, [R0]
	
	;设置进程栈的PSP为0，指示是第一次进行任务切换
    MOVS    R0, #0                                              ; Set the PSP to 0 for initial context switch call
    MSR     PSP, R0
	
	;带“=”的LDR是伪指令，获取的是OS_CPU_ExceptStkBase的地址
	;汇编器把OS_CPU_ExceptStkBase的地址放在一个文字池中，
	;再用LDR或者MOV指令把文字池中的内容(OS_CPU_ExceptStkBase的地址)读取R0
    LDR     R0, =OS_CPU_ExceptStkBase                           ; Initialize the MSP to the OS_CPU_ExceptStkBase
	;获取OS_CPU_ExceptStkBase的值，即MSP使用的栈的栈顶地址
    LDR     R1, [R0]
	;MSP = OS_CPU_ExceptStkBase
    MSR     MSP, R1    
	
	;伪指令。R0 = &OSRunning
    LDR     R0, =OSRunning                                      ; OSRunning = TRUE
    MOVS    R1, #1
	;*R0 = R1。即OSRunning = 1
    STRB    R1, [R0]
	
	;触发PendSV异常。
	;使用伪指令LDR。
	;把NVIC_INT_CTRL的值放入文字池，再把文字池中的值用指令LDR到R0
    LDR     R0, =NVIC_INT_CTRL                                  ; Trigger the PendSV exception (causes context switch)
    LDR     R1, =NVIC_PENDSVSET
	;*NVIC_INT_CTRL = NVIC_PENDSVSET
    STR     R1, [R0]
	
	;开总中断
    CPSIE   I                                                   ; Enable interrupts at processor level

OSStartHang
    B       OSStartHang                                         ; Should never get here


;PAGE
;********************************************************************************************************
;                       PERFORM A CONTEXT SWITCH (From task level) - OSCtxSw()
;
; Note(s) : 1) OSCtxSw() is called when OS wants to perform a task context switch.  This function
;              triggers the PendSV exception which is where the real work is done.
;********************************************************************************************************

OSCtxSw
	;*NVIC_INT_CTRL = NVIC_PENDSVSET，触发PendSV异常
    LDR     R0, =NVIC_INT_CTRL                                  ; Trigger the PendSV exception (causes context switch)
    LDR     R1, =NVIC_PENDSVSET
    STR     R1, [R0]
    BX      LR


;PAGE
;********************************************************************************************************
;                   PERFORM A CONTEXT SWITCH (From interrupt level) - OSIntCtxSw()
;
; Note(s) : 1) OSIntCtxSw() is called by OSIntExit() when it determines a context switch is needed as
;              the result of an interrupt.  This function simply triggers a PendSV exception which will
;              be handled when there are no more interrupts active and interrupts are enabled.
;********************************************************************************************************

OSIntCtxSw
	;*NVIC_INT_CTRL = NVIC_PENDSVSET，触发PendSV异常
    LDR     R0, =NVIC_INT_CTRL                                  ; Trigger the PendSV exception (causes context switch)
    LDR     R1, =NVIC_PENDSVSET
    STR     R1, [R0]
    BX      LR


;PAGE
;********************************************************************************************************
;                                       HANDLE PendSV EXCEPTION
;                                   void OS_CPU_PendSVHandler(void)
;
; Note(s) : 1) PendSV is used to cause a context switch.  This is a recommended method for performing
;              context switches with Cortex-M3.  This is because the Cortex-M3 auto-saves half of the
;              processor context on any exception, and restores same on return from exception.  So only
;              saving of R4-R11 is required and fixing up the stack pointers.  Using the PendSV exception
;              this way means that context saving and restoring is identical whether it is initiated from
;              a thread or occurs due to an interrupt or exception.
;
;           2) Pseudo-code is:
;              a) Get the process SP, if 0 then skip (goto d) the saving part (first context switch);
;              b) Save remaining regs r4-r11 on process stack;
;              c) Save the process SP in its TCB, OSTCBCur->OSTCBStkPtr = SP;
;              d) Call OSTaskSwHook();
;              e) Get current high priority, OSPrioCur = OSPrioHighRdy;
;              f) Get current ready thread TCB, OSTCBCur = OSTCBHighRdy;
;              g) Get new process SP from TCB, SP = OSTCBHighRdy->OSTCBStkPtr;
;              h) Restore R4-R11 from new process stack;
;              i) Perform exception return which will restore remaining context.
;
;           3) On entry into PendSV handler:
;              a) The following have been saved on the process stack (by processor):
;                 xPSR, PC, LR, R12, R0-R3
;              b) Processor mode is switched to Handler mode (from Thread mode)
;              c) Stack is Main stack (switched from Process stack)
;              d) OSTCBCur      points to the OS_TCB of the task to suspend
;                 OSTCBHighRdy  points to the OS_TCB of the task to resume
;
;           4) Since PendSV is set to lowest priority in the system (by OSStartHighRdy() above), we
;              know that it will only be run when no other exception or interrupt is active, and
;              therefore safe to assume that context being switched out was using the process stack (PSP).
;********************************************************************************************************

PendSV_Handler
	;关总中断
    CPSID   I                                                   ; Prevent interruption during context switch
	;R0 = PSP(R13)。获取任务栈的指针
    MRS     R0, PSP 
	; PSP is process stack pointer
	;任务栈指针为0，说明是从OSStartHighRdy()触发的本中断
	;是系统第一次进行任务调度，不必保存任务上下文
    CBZ     R0, OS_CPU_PendSVHandler_nosave                     ; Skip register save the first time
    
    SUBS    R0, R0, #0x20                                       ; Save remaining regs r4-11 on process stack
    STM     R0, {R4-R11}
;--------------------------------------------------------------------------------------------------------------------------	
    ;USE_FPU
	;Is the task using the FPU context? If so, push high vfp registers.
	;tst r14, #0x10
	;it eq
	;vstmdbeq r0!, {s16-s31}
    
	;若R14的bit4为0，表示使用过FPU，把S16到S31手动压入任务栈
	TST		R14, #0x10
;	IT 		EQ
	VSTMDBEQ	R0!, {S16-S31}
	SUBS    R0, R0, #0x04
	;把R14(LR)的值压入R0指向的任务栈
	STM		R0, {R14}
	
    ;SUBS    R0, R0, #0x40                                       ; Save remaining regs r4-11 on process stack
    ;VSTMDBEQ R0!, {S16-S31}                                     ; PUSH address from RO to (R0 + 0x40), RO remains
;--------------------------------------------------------------------------------------------------------------------------	
	;R1 = &OSTCBCur 
    LDR     R1, =OSTCBCur                                       ; OSTCBCur->OSTCBStkPtr = SP;
	;R1 = OSTCBCur的值
    LDR     R1, [R1]
	;*OSTCBCur = R0。即把任务栈的指针存入OSTCBCur指向的地址。
	;struct os_tcb的第一个元素是OSTCBStkPtr。即OSTCBCur->OSTCBStkPtr = 当前任务栈的SP
    STR     R0, [R1]                                            ; R0 is SP of process being switched out

                                                                ; At this point, entire context of process has been saved
OS_CPU_PendSVHandler_nosave
	;调用任务切换钩子函数
    PUSH    {R14}                                               ; Save LR exc_return value
    LDR     R0, =OSTaskSwHook                                   ; OSTaskSwHook();
    BLX     R0
    POP     {R14}
	
	;获取最高优先级就绪任务的优先级
	;R0 = &OSPrioCur
    LDR     R0, =OSPrioCur                                      ; OSPrioCur = OSPrioHighRdy;
	;R1 = &OSPrioHighRdy
    LDR     R1, =OSPrioHighRdy
	;R2 = OSPrioHighRdy的值
    LDRB    R2, [R1]
	;OSPrioCur的值 = OSPrioHighRdy的值
    STRB    R2, [R0]
	
	;获取最高优先级就绪任务的TCB
	;R0 = &OSTCBCur
    LDR     R0, =OSTCBCur                                       ; OSTCBCur  = OSTCBHighRdy;
	;R1 = &OSTCBHighRdy
    LDR     R1, =OSTCBHighRdy
	;R2 = OSTCBHighRdy的值
    LDR     R2, [R1]
	;OSTCBCur的值 = OSTCBHighRdy的值
    STR     R2, [R0]

    ;USE_FPU
	;Is the task using the FPU context? If so, pop the high vfp registers too.
	;tst r14, #0x10
	;it eq
	;vldmiaeq r0!, {s16-s31}
    
	;R0 = OSTCBCur指向的地址的值。即R0 = OSTCBCur->OSTCBStkPtr
	;把最高优先级就绪任务被换出前保存的栈SP(R13)，写入R0
    LDR     R0, [R2]                                            ; R0 is new process SP; SP = OSTCBHighRdy->OSTCBStkPtr;
;--------------------------------------------------------------------------------------------------------------------------	
    ;VLDMIAEQ R0!, {S16-S31}                                     ; POP address from RO to (RO + 0x40), RO remains
    ;ADDS    R0, R0, #0x40
	
	;恢复待运行任务的(R14)LR
	;R14(LR) = *R0 = *(OSTCBCur->OSTCBStkPtr)，即栈顶的元素(最后压栈的R14)
	LDM		R0,{R14}
	ADDS    R0, R0, #0x04
	;判断是否待运行任务被换出前，是否手动压栈了S16-S31。LR的bit4是0表示该任务之前使用过FPU
	;任务被换出前应该手动压栈了S16-S31
	TST		R14, #0x10
;	IT 		EQ
	;如果待运行任务被换出前，手动压栈了S16-S31，则出栈S16-S31
	VLDMIAEQ  R0!, {S16-S31}
;--------------------------------------------------------------------------------------------------------------------------	
	;出栈手动压栈的R4-R11
    LDM     R0, {R4-R11}                                        ; Restore r4-11 from new process stack
    ADDS    R0, R0, #0x20
    
	;PSP = R0
	;恢复待运行任务的PSP
    MSR     PSP, R0                                             ; Load PSP with new process SP
	;保证中断返回时使用PSP出栈
    ORR     LR, LR, #0x04                                       ; Ensure exception return uses process stack
	;允许全局中断
    CPSIE   I
	;中断返回，使用待运行任务的PSP出栈
	;如果LR的值不是0xffffxxxx类型的，则PC跳至LR[31:1]，而根据LR[0:0]则决定跳转后处理器进入的状态。
	;如果LR[0:0]=1，则进入Thumb状态，否则进入ARM状态。 
	;在CM3中不支持ARM状态，所以LR[0:0]必须是1——也就是LR必须是奇数 
	;在CM3中，如果以0xffff开头则有特殊的含义
	;命名为EXC_RETURN，它指示正在从异常返回，并决定返回的方式，在《Cortex-M3权威指南》中有重点介绍
    BX      LR                                                  ; Exception return will restore remaining context

    END
