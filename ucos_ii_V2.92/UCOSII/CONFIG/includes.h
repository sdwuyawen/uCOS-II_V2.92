/*
*********************************************************************************************************
*                                              EXAMPLE CODE
*
*                             (c) Copyright 2013; Micrium, Inc.; Weston, FL
*
*                   All rights reserved.  Protected by international copyright laws.
*                   Knowledge of the source code may not be used to write a similar
*                   product.  This file may only be used in accordance with a license
*                   and should not be redistributed in any way.
*********************************************************************************************************
*/

/*
*********************************************************************************************************
*
*                                           MASTER INCLUDES
*
*                                     ST Microelectronics STM32
*                                              with the
*
*                                           STM3240G-EVAL
*                                         Evaluation Board
*
* Filename      : includes.h
* Version       : V1.00
* Programmer(s) : EHS
*                 DC
*********************************************************************************************************
*/

#ifndef  INCLUDES_PRESENT
#define  INCLUDES_PRESENT

/*********************************************************************************************************
*                                            LOCAL DEFINES
*********************************************************************************************************
*/

//#define DEVELOPER_MODE //测试模式宏定义，当选择正常工作模式时请将此宏定义注释掉 

/*
*********************************************************************************************************
*                                         STANDARD LIBRARIES
*********************************************************************************************************
*/

#include  <stdarg.h>
#include  <stdio.h>
#include  <stdlib.h>
#include  <math.h>



/*
*********************************************************************************************************
*                                              LIBRARIES
*********************************************************************************************************
*/

//#include  <cpu.h>
// #include  <lib_def.h>
// #include  <lib_ascii.h>
// #include  <lib_math.h>
// #include  <lib_mem.h>
// #include  <lib_str.h>
#include  <stm32f4xx_conf.h>
#include  <stm32f4xx.h>

#include  <stm32f4xx_can.h>
#include  <stm32f4xx_dma.h>
#include  <stm32f4xx_exti.h>
#include  <stm32f4xx_fsmc.h>
#include  <stm32f4xx_gpio.h>
#include  <stm32f4xx_iwdg.h>
#include  <stm32f4xx_rcc.h>
#include  <stm32f4xx_spi.h>
#include  <stm32f4xx_syscfg.h>
#include  <stm32f4xx_tim.h>
#include  <misc.h>

/*
*********************************************************************************************************
*                                                 OS
*********************************************************************************************************
*/

#include  <ucos_ii.h>

/* 定义一个邮箱，    这只是一个邮箱指针，  OSMboxCreate函数会创建邮箱必需的资源 */
extern OS_EVENT *AppPRESSMbox;
extern OS_EVENT *app_mbox_sdcard;
/*
*********************************************************************************************************
*                                              APP / BSP
*********************************************************************************************************
*/

#include  <bsp.h>
#include  "cpap_config.h"

#include "cpap_INC_PID.h"
#include "bsp_PCF2129.h"
#include "bsp_STM32_ADC.h"
//#include "bsp_LCD160160.h"
#include "bsp_KEY1.h"
#include "bsp_AT93C66.h"
//#include "bsp_Humidifier.h"
#include "bsp_STM32_SDP510.h"
#include "bsp_STM32_NPA700.h" 
#include "bsp_BELL.h"
#include "bsp_Motor.h"
#include "bsp_STM32_I2C.h"
#include "bsp_STM32_I2C1.h"
#include "bsp_encoder.h"

/*
*********************************************************************************************************
*                                               SERIAL
*********************************************************************************************************
*/

// #if (APP_CFG_SERIAL_EN == DEF_ENABLED)
// #include  <app_serial.h>
// #endif
/*
*********************************************************************************************************
*                                              CPAP/APP
*********************************************************************************************************
*/
#include  "uip.h"
#include  "uip_arp.h"
#include  "timer.h"

#include  "stm32f4x7_eth.h"
#include  "stm32f4x7_eth_bsp.h"
#include  "stm32f4xx_it.h"

#include  "cpap_STM32_NET.h"
#include  "cpap_STM32_FSMC.h"
#include  "cpap_STM32_ADC.h"

#include  "cpap_AT93C66.h"
#include  "cpap_CRC.h"
#include  "cpap_Humidifier.h"
#include  "cpap_KEY.h"
#include  "cpap_LCD160160.h"
#include  "cpap_PCF2129.h"
#include  "cpap_NPA700.h" 
#include  "cpap_SDP510.h"
#include  "cpap_SDCard.h"
/*
*********************************************************************************************************
*                                            INCLUDES END
*********************************************************************************************************
*/


#endif

