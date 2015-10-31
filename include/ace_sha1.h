/*
 * Copyright (c) 2009 Samsung Electronics Co., Ltd.
 *              http://www.samsung.com/
 *
 * Header file for SHA1 F/W Code
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */
 
#ifndef __ACE_FW_SHA1_H__
#define __ACE_FW_SHA1_H__

#ifdef __cplusplus
extern "C" {
#endif

#include "ace_sfr.h"

	
/*****************************************************************
	Functions
*****************************************************************/
int SHA1_digest (
	unsigned char*	pOut,
	unsigned char*	pBufAddr,
	unsigned int		bufLen
);


#ifdef __cplusplus
}
#endif

#endif 

