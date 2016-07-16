/*=====================================================================*
 *                                                                     *
 *   Software Name : HEC-MW Library for PC-cluster                     *
 *         Version : 2.8                                               *
 *                                                                     *
 *     Last Update : 2006/06/01                                        *
 *        Category : I/O and Utility                                   *
 *                                                                     *
 *            Written by Kazuaki Sakane (RIST)                         *
 *                                                                     *
 *     Contact address :  IIS,The University of Tokyo RSS21 project    *
 *                                                                     *
 *     "Structural Analysis System for General-purpose Coupling        *
 *      Simulations Using High End Computing Middleware (HEC-MW)"      *
 *                                                                     *
 *=====================================================================*/



#ifndef HECMW_HECLEX_INCLUDED
#define HECMW_HECLEX_INCLUDED

#include <stdio.h>


enum {
	HECMW_HECLEX_NL	= 1000,
	HECMW_HECLEX_INT,
	HECMW_HECLEX_DOUBLE,
	HECMW_HECLEX_NAME,
	HECMW_HECLEX_FILENAME,
	HECMW_HECLEX_HEADER,

	HECMW_HECLEX_H_AMPLITUDE = 2000,
	HECMW_HECLEX_H_CONNECTIVITY,
	HECMW_HECLEX_H_CONTACT_PAIR,
	HECMW_HECLEX_H_ECOPY,
	HECMW_HECLEX_H_EGEN,
	HECMW_HECLEX_H_EGROUP,
	HECMW_HECLEX_H_ELEMENT,
	HECMW_HECLEX_H_END,
	HECMW_HECLEX_H_EQUATION,
	HECMW_HECLEX_H_HEADER,
	HECMW_HECLEX_H_INCLUDE,
	HECMW_HECLEX_H_INITIAL,
	HECMW_HECLEX_H_ITEM,
	HECMW_HECLEX_H_MATERIAL,
	HECMW_HECLEX_H_NCOPY,
	HECMW_HECLEX_H_NFILL,
	HECMW_HECLEX_H_NGEN,
	HECMW_HECLEX_H_NGROUP,
	HECMW_HECLEX_H_NODE,
	HECMW_HECLEX_H_SECTION,
	HECMW_HECLEX_H_SGROUP,
	HECMW_HECLEX_H_SYSTEM,
	HECMW_HECLEX_H_ZERO,

	HECMW_HECLEX_K_ABAQUS = 3000,
	HECMW_HECLEX_K_ABSOLUTE,
	HECMW_HECLEX_K_BEAM,
	HECMW_HECLEX_K_COMPOSITE,
	HECMW_HECLEX_K_DEFINITION,
	HECMW_HECLEX_K_EGRP,
	HECMW_HECLEX_K_GENERATE,
	HECMW_HECLEX_K_HECMW,
	HECMW_HECLEX_K_INPUT,
	HECMW_HECLEX_K_INTERFACE,
	HECMW_HECLEX_K_ITEM,
	HECMW_HECLEX_K_MATERIAL,
	HECMW_HECLEX_K_MATITEM,
	HECMW_HECLEX_K_NAME,
	HECMW_HECLEX_K_NASTRAN,
	HECMW_HECLEX_K_NGRP,
	HECMW_HECLEX_K_NODE_SURF,
	HECMW_HECLEX_K_RELATIVE,
	HECMW_HECLEX_K_SECOPT,
	HECMW_HECLEX_K_SECTION,
	HECMW_HECLEX_K_SGRP,
	HECMW_HECLEX_K_SHELL,
	HECMW_HECLEX_K_SOLID,
	HECMW_HECLEX_K_STEP_TIME,
	HECMW_HECLEX_K_SUBITEM,
	HECMW_HECLEX_K_SURF_SURF,
	HECMW_HECLEX_K_SYSTEM,
	HECMW_HECLEX_K_TABLE,
	HECMW_HECLEX_K_TABULAR,
	HECMW_HECLEX_K_TEMPERATURE,
	HECMW_HECLEX_K_TIME,
	HECMW_HECLEX_K_TYPE,
	HECMW_HECLEX_K_VALUE,
	HECMW_HECLEX_K_TIMEVALUE,
	HECMW_HECLEX_K_VALUETIME
};


extern double HECMW_heclex_get_number(void);


extern char *HECMW_heclex_get_text(void);


extern int HECMW_heclex_get_lineno(void);


extern int HECMW_heclex_next_token(void);


extern int HECMW_heclex_next_token_skip(int skip_token);


extern int HECMW_heclex_set_input(FILE *fp);


extern int HECMW_heclex_skip_line(void);


extern int HECMW_heclex_switch_to_include(const char *filename);


extern int HECMW_heclex_unput_token(void);


extern int HECMW_heclex_is_including(void);

#endif
