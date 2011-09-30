/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
 * Copyright by The HDF Group.                                               *
 * Copyright by the Board of Trustees of the University of Illinois.         *
 * All rights reserved.                                                      *
 *                                                                           *
 * This file is part of HDF5.  The full HDF5 copyright notice, including     *
 * terms governing use, modification, and redistribution, is contained in    *
 * the files COPYING and Copyright.html.  COPYING can be found at the root   *
 * of the source code distribution tree; Copyright.html can be found at the  *
 * root level of an installed copy of the electronic HDF5 document set and   *
 * is linked from the top-level documents page.  It can also be found at     *
 * http://hdfgroup.org/HDF5/doc/Copyright.html.  If you do not have          *
 * access to either file, you may request a copy from help@hdfgroup.org.     *
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

/* C Program to match C types to Fortran types
 * Creates the files H5f90i_gen.h for the C code and H5fortran_types.f90
 * for the Fortran.
 */

#include <stdio.h>
#include <assert.h>

#include "H5public.h"
/* Include H5Ipublic.h for hid_t type */
#include "H5Ipublic.h"

/* Definitions of which fortran type sizes exist */
#include "H5fort_type_defines.h"

/* File pointers for files */
FILE * c_header;
FILE * fort_header;

#define CFILE "H5f90i_gen.h"
#define FFILE "H5fortran_types.f90"

static void
initCfile(void)
{
  fprintf(c_header,
    "/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *\n\
 * Copyright by the Board of Trustees of the University of Illinois.         *\n\
 * All rights reserved.                                                      *\n\
 *                                                                           *\n\
 * This file is part of HDF5.  The full HDF5 copyright notice, including     *\n\
 * terms governing use, modification, and redistribution, is contained in    *\n\
 * the files COPYING and Copyright.html.  COPYING can be found at the root   *\n\
 * of the source code distribution tree; Copyright.html can be found at the  *\n\
 * root level of an installed copy of the electronic HDF5 document set and   *\n\
 * is linked from the top-level documents page.  It can also be found at     *\n\
 * http://hdf.ncsa.uiuc.edu/HDF5/doc/Copyright.html.  If you do not have     *\n\
 * access to either file, you may request a copy from hdfhelp@ncsa.uiuc.edu. *\n\
 * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */\n\
\n\n\
#ifndef _H5f90i_gen_H\n\
#define _H5f90i_gen_H\n\
\n\
/* This file is automatically generated by H5match_types.c at build time. */\n\
\n\
#include \"H5public.h\"\n\n");
}

static void
initFfile(void)
{
  fprintf(fort_header,
    "! * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * \n\
!   Copyright by the Board of Trustees of the University of Illinois.         *\n\
!   All rights reserved.                                                      *\n\
!                                                                             *\n\
!   This file is part of HDF5.  The full HDF5 copyright notice, including     *\n\
!   terms governing use, modification, and redistribution, is contained in    *\n\
!   the files COPYING and Copyright.html.  COPYING can be found at the root   *\n\
!   of the source code distribution tree; Copyright.html can be found at the  *\n\
!   root level of an installed copy of the electronic HDF5 document set and   *\n\
!   is linked from the top-level documents page.  It can also be found at     *\n\
!   http://hdf.ncsa.uiuc.edu/HDF5/doc/Copyright.html.  If you do not have     *\n\
!   access to either file, you may request a copy from hdfhelp@ncsa.uiuc.edu. *\n\
! * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *\n\
!\n!\n\
! This file is automatically generated and contains HDF5 Fortran90 type definitions.\n!\n\
       MODULE H5FORTRAN_TYPES\n\
         !\n\
         !  HDF5 integers\n\
         !\n");

}

static void
endCfile(void)
{
  fprintf(c_header, "\n#endif /* _H5f90i_gen_H */\n");
}
static void
endFfile(void)
{
  fprintf(fort_header, "\n        INTEGER(SIZE_T), PARAMETER :: OBJECT_NAMELEN_DEFAULT_F = -1\n\n");
  fprintf(fort_header, "        END MODULE H5FORTRAN_TYPES\n");
}

/* Define a c_int_x type in the C header */
void writeTypedef(const char* c_type, unsigned int size)
{
  fprintf(c_header, "#define c_int_%d %s\n", size, c_type);
}

/* Define a c_float_x type in the C header */
void writeFloatTypedef(const char* c_type, unsigned int size)
{
  fprintf(c_header, "#define c_float_%d %s\n", size, c_type);
}

/* Call this function if there is no matching C type for sizes > 1 */
void writeTypedefDefault(unsigned int size)
{
  assert(size %2 == 0);

  fprintf(c_header, "typedef struct {c_int_%d a; c_int_%d b;} c_int_%d\n", size / 2, size / 2, size);
}

/* Create matching Fortran and C types by writing to both files */
void writeToFiles(const char* fortran_type, const char* c_type, unsigned int size)
{
  fprintf(fort_header, "        INTEGER, PARAMETER :: %s = %d\n", fortran_type, size);
  fprintf(c_header, "typedef c_int_%d %s;\n", size, c_type);
}

/* Create matching Fortran and C floating types by writing to both files */
void writeFloatToFiles(const char* fortran_type, const char* c_type, unsigned int size)
{
  fprintf(fort_header, "        INTEGER, PARAMETER :: %s = %d\n", fortran_type, size);

  fprintf(c_header, "typedef c_float_%d %s;\n", size, c_type);
}

int main()
{
  int FoundIntSize[4];
  int FoundRealSize[4];
  int i,j,flag;
  char chrA[20],chrB[20];
  int H5_C_HAS_REAL_NATIVE_16;
  int H5_C_HAS_REAL_NATIVE_12;

  /* Open target files */
  c_header = fopen(CFILE, "w");
  fort_header = fopen(FFILE, "w");


/* Default is C has 16 byte float */
  H5_C_HAS_REAL_NATIVE_16 = 1; 
/* Default is C has 12 byte float */
  H5_C_HAS_REAL_NATIVE_12 = 1; 

  /* Write copyright, boilerplate to both files */
  initCfile();
  initFfile();

  /* First, define c_int_x */

#if defined H5_FORTRAN_HAS_INTEGER_1
  if(sizeof(long long) == 1)
    writeTypedef("long long", 1);
  else if(sizeof(long) == 1)
    writeTypedef("long", 1);
  else if(sizeof(int) == 1)
    writeTypedef("int", 1);
  else if(sizeof(short) == 1)
    writeTypedef("short", 1);
  else
    writeTypedef("char", 1);
  /* Actually, char is not necessarily one byte.
   * But if char isn't, then nothing is, so this
   * is as close as we can get. */
#endif /*H5_FORTRAN_HAS_INTEGER_1 */

#if defined H5_FORTRAN_HAS_INTEGER_2
  if(sizeof(long long) == 2)
    writeTypedef("long long", 2);
  else if(sizeof(long) == 2)
    writeTypedef("long", 2);
  else if(sizeof(int) == 2)
    writeTypedef("int", 2);
  else if(sizeof(short) == 2)
    writeTypedef("short", 2);
  else
    writeTypedefDefault(2);
#endif /*H5_FORTRAN_HAS_INTEGER_2 */

#if defined H5_FORTRAN_HAS_INTEGER_4
  if(sizeof(long long) == 4)
    writeTypedef("long long", 4);
  else if(sizeof(long) == 4)
    writeTypedef("long", 4);
  else if(sizeof(int) == 4)
    writeTypedef("int", 4);
  else if(sizeof(short) == 4)
    writeTypedef("short", 4);
  else
    writeTypedefDefault(4);
#endif /*H5_FORTRAN_HAS_INTEGER_4 */

#if defined H5_FORTRAN_HAS_INTEGER_8
  if(sizeof(long long) == 8)
    writeTypedef("long long", 8);
  else if(sizeof(long) == 8)
    writeTypedef("long", 8);
  else if(sizeof(int) == 8)
    writeTypedef("int", 8);
  else if(sizeof(short) == 8)
    writeTypedef("short", 8);
  else
    writeTypedefDefault(8);
#endif /*H5_FORTRAN_HAS_INTEGER_8 */

  /* Define c_float_x */

#if defined H5_FORTRAN_HAS_REAL_NATIVE_4 || defined H5_FORTRAN_HAS_REAL_4
  if(sizeof(long double) == 4)
    writeFloatTypedef("long double", 4);
  else if(sizeof(double) == 4)
   writeFloatTypedef("double", 4);
  else if(sizeof(float) == 4)
   writeFloatTypedef("float", 4);
  else
   { printf("Fortran REAL is 4 bytes, no corresponding C floating type\n");
     printf("Quitting....\n");
     return -1;
   }
#endif /*H5_FORTRAN_HAS_REAL_NATIVE_4*/

#if defined H5_FORTRAN_HAS_REAL_NATIVE_8 || defined H5_FORTRAN_HAS_REAL_8
  if(sizeof(long double) == 8)
    writeFloatTypedef("long double", 8);
  else if(sizeof(double) == 8)
   writeFloatTypedef("double", 8);
  else if(sizeof(float) == 8)
   writeFloatTypedef("float", 8);
  else
   { printf("Fortran REAL is 16 bytes, no corresponding C floating type\n");
     printf("Quitting....\n");
     return -1;
   }
#endif /*H5_FORTRAN_HAS_REAL_NATIVE_8*/

#if defined H5_FORTRAN_HAS_REAL_NATIVE_12 || defined H5_FORTRAN_HAS_REAL_12
  if(sizeof(long double) == 12)
    writeFloatTypedef("long double", 12);
  else if(sizeof(double) == 12)
   writeFloatTypedef("double", 12);
  else if(sizeof(float) == 12)
   writeFloatTypedef("float", 12);
  else /*C has no 12 byte float so disable it in Fortran*/ 
   { printf("warning: Fortran REAL is 12 bytes, no corresponding C floating type\n");
     printf("         Disabling Fortran 12 byte REALs\n");
     H5_C_HAS_REAL_NATIVE_12 = 0;
   }
#endif /*H5_FORTRAN_HAS_REAL_NATIVE_8*/

#if defined H5_FORTRAN_HAS_REAL_NATIVE_16 || defined H5_FORTRAN_HAS_REAL_16
  if(sizeof(long double) == 16)
    writeFloatTypedef("long double", 16);
  else if(sizeof(double) == 16)
   writeFloatTypedef("double", 16);
  else if(sizeof(float) == 16)
   writeFloatTypedef("float", 16);
  else /*C has no 16 byte float so disable it in Fortran*/ 
   { printf("warning: Fortran REAL is 16 bytes, no corresponding C floating type\n");
     printf("         Disabling Fortran 16 byte REALs\n");
     H5_C_HAS_REAL_NATIVE_16 = 0;
   }
#endif /*H5_FORTRAN_HAS_REAL_NATIVE_16*/

  /* Now begin defining fortran types. */
  fprintf(c_header, "\n");
  /* haddr_t */
#if defined H5_FORTRAN_HAS_INTEGER_8 && H5_SIZEOF_HADDR_T >= 8
  writeToFiles("HADDR_T", "haddr_t_f", 8);
#elif defined H5_FORTRAN_HAS_INTEGER_4 && H5_SIZEOF_HADDR_T >= 4
  writeToFiles("HADDR_T", "haddr_t_f", 4);
#elif defined H5_FORTRAN_HAS_INTEGER_2 && H5_SIZEOF_HADDR_T >= 2
  writeToFiles("HADDR_T", "haddr_t_f", 2);
#elif defined H5_FORTRAN_HAS_INTEGER_1 && H5_SIZEOF_HADDR_T >= 1
  writeToFiles("HADDR_T", "haddr_t_f", 1);
#else
    /* Error: couldn't find a size for haddr_t */
    return -1;
#endif

  /* hsize_t */
#if defined H5_FORTRAN_HAS_INTEGER_8 && H5_SIZEOF_HSIZE_T >= 8
      writeToFiles("HSIZE_T", "hsize_t_f", 8);
#elif defined H5_FORTRAN_HAS_INTEGER_4 && H5_SIZEOF_HSIZE_T >= 4
      writeToFiles("HSIZE_T", "hsize_t_f", 4);
#elif defined H5_FORTRAN_HAS_INTEGER_2 && H5_SIZEOF_HSIZE_T >= 2
      writeToFiles("HSIZE_T", "hsize_t_f", 2);
#elif defined H5_FORTRAN_HAS_INTEGER_1 && H5_SIZEOF_HSIZE_T >= 1
      writeToFiles("HSIZE_T", "hsize_t_f", 1);
#else
    /* Error: couldn't find a size for hsize_t */
    return -1;
#endif

  /* hssize_t */
#if defined H5_FORTRAN_HAS_INTEGER_8 && H5_SIZEOF_HSSIZE_T >= 8
      writeToFiles("HSSIZE_T", "hssize_t_f", 8);
#elif defined H5_FORTRAN_HAS_INTEGER_4 && H5_SIZEOF_HSSIZE_T >= 4
      writeToFiles("HSSIZE_T", "hssize_t_f", 4);
#elif defined H5_FORTRAN_HAS_INTEGER_2 && H5_SIZEOF_HSSIZE_T >= 2
      writeToFiles("HSSIZE_T", "hssize_t_f", 2);
#elif defined H5_FORTRAN_HAS_INTEGER_1 && H5_SIZEOF_HSSIZE_T >= 1
      writeToFiles("HSSIZE_T", "hssize_t_f", 1);
#else
    /* Error: couldn't find a size for hssize_t */
    return -1;
#endif


  /* size_t */
#if defined H5_FORTRAN_HAS_INTEGER_8 && H5_SIZEOF_SIZE_T >= 8
      writeToFiles("SIZE_T", "size_t_f", 8);
#elif defined H5_FORTRAN_HAS_INTEGER_4 && H5_SIZEOF_SIZE_T >= 4
      writeToFiles("SIZE_T", "size_t_f", 4);
#elif defined H5_FORTRAN_HAS_INTEGER_2 && H5_SIZEOF_SIZE_T >= 2
      writeToFiles("SIZE_T", "size_t_f", 2);
#elif defined H5_FORTRAN_HAS_INTEGER_1 && H5_SIZEOF_SIZE_T >= 1
      writeToFiles("SIZE_T", "size_t_f", 1);
#else
    /* Error: couldn't find a size for size_t */
    return -1;
#endif

  /* int */
#if defined H5_FORTRAN_HAS_NATIVE_8
      writeToFiles("Fortran_INTEGER", "int_f", 8);
#elif defined H5_FORTRAN_HAS_NATIVE_4
      writeToFiles("Fortran_INTEGER", "int_f", 4);
#elif defined H5_FORTRAN_HAS_NATIVE_2
      writeToFiles("Fortran_INTEGER", "int_f", 2);
#elif defined H5_FORTRAN_HAS_NATIVE_1
      writeToFiles("Fortran_INTEGER", "int_f", 1);
#else
    /* Error: couldn't find a size for int */
    return -1;
#endif


  /* int_1, int_2, int_4, int_8 */

/* Defined different KINDs of integers:                       */
/* if the integer kind is not available then we assign        */
/* it a value of the next larger one, but if the next         */
/* higher one is not available we assigned it the next lowest */

    FoundIntSize[0] = -1;
    FoundIntSize[1] = -2;
    FoundIntSize[2] = -4;
    FoundIntSize[3] = -8;

#if defined H5_FORTRAN_HAS_INTEGER_1
    FoundIntSize[0] = 1;
#endif
#if defined H5_FORTRAN_HAS_INTEGER_2
    FoundIntSize[1] = 2;
#endif
#if defined H5_FORTRAN_HAS_INTEGER_4
    FoundIntSize[2] = 4;
#endif
#if defined H5_FORTRAN_HAS_INTEGER_8
    FoundIntSize[3] = 8;
#endif

    for(i=0;i<4;i++) {
      if( FoundIntSize[i] > 0) /* Found the integer type */
	{
	  sprintf(chrA, "Fortran_INTEGER_%d", FoundIntSize[i]);
	  sprintf(chrB, "int_%d_f", FoundIntSize[i]);
	  writeToFiles(chrA, chrB, FoundIntSize[i]);
	}
      else  /* Did not find the integer type */
	{
	  flag = 0; /* flag indicating if found the next highest */
	  for(j=i+1;j<4;j++)  /* search for next highest */
	    {
	      if( FoundIntSize[j] > 0) /* Found the next highest */
		{
		  sprintf(chrA, "Fortran_INTEGER_%d", (-1)*FoundIntSize[i]);
		  sprintf(chrB, "int_%d_f", (-1)*FoundIntSize[i]);
		  writeToFiles(chrA, chrB, FoundIntSize[j]);
		  flag = 1;
		  break;
		}
	    }
	  if(flag == 0) /* No higher one found, so find next lowest */
	    {
	      for(j=2;j>-1;j--)  /* Search for next lowest */
		{
		  if( FoundIntSize[j] > 0) /* Found the next lowest */
		    {
		      sprintf(chrA, "Fortran_INTEGER_%d", (-1)*FoundIntSize[i]);
		      sprintf(chrB, "int_%d_f", (-1)*FoundIntSize[i]);
		      writeToFiles(chrA, chrB, FoundIntSize[j]);
		      flag = 1;
		      break;
		    }
		}
	    }
	  if(flag == 0) /* No higher or lower one found, indicating an error */
	    {
	     return -1; 
	    }
	}
    }

  /* real_4, real_8, real_12, real_16 */

/* Defined different KINDs of reals:                          */
/* if the REAL kind is not available then we assign           */
/* it a value of the next larger one, but if the next         */
/* higher one is not available we assigned it the next lowest */

    FoundRealSize[0] = -4;
    FoundRealSize[1] = -8;
    FoundRealSize[2] = -12;
    FoundRealSize[3] = -16;

#if defined H5_FORTRAN_HAS_REAL_4
    FoundRealSize[0] = 4;
#endif
#if defined H5_FORTRAN_HAS_REAL_8
    FoundRealSize[1] = 8;
#endif
#if defined H5_FORTRAN_HAS_REAL_12
    if(H5_C_HAS_REAL_NATIVE_12 != 0) {
      FoundRealSize[2] = 12;
    }
#endif
#if defined H5_FORTRAN_HAS_REAL_16
    if(H5_C_HAS_REAL_NATIVE_16 != 0) {
      FoundRealSize[3] = 16;
    }
#endif

    for(i=0;i<4;i++) {
      if( FoundRealSize[i] > 0) /* Found the real type */
	{
	  sprintf(chrA, "Fortran_REAL_%d", FoundRealSize[i]);
	  sprintf(chrB, "real_%d_f", FoundRealSize[i]);
	  writeFloatToFiles(chrA, chrB, FoundRealSize[i]);
	}
      else  /* Did not find the real type */
	{
	  flag = 0; /* flag indicating if found the next highest */
	  for(j=i+1;j<4;j++)  /* search for next highest */
	    {
	      if( FoundRealSize[j] > 0) /* Found the next highest */
		{
		  sprintf(chrA, "Fortran_REAL_%d", (-1)*FoundRealSize[i]);
		  sprintf(chrB, "real_%d_f", (-1)*FoundRealSize[i]);
		  if(FoundRealSize[j]>4) {
		    writeFloatToFiles(chrA, chrB, FoundRealSize[j]);
		    flag = 1;
		  }
		/*   else { */
/* 		    writeFloatToFiles(chrA, chrB, FoundRealSize[j]); */
/* 		  } */
		  flag = 1;
		  break;
		}
	    }
	  if(flag == 0) /* No higher one found, so find next lowest */
	    {
	      for(j=2;j>-1;j--)  /* Search for next lowest */
		{
		  if( FoundRealSize[j] > 0) /* Found the next lowest */
		    {
		      sprintf(chrA, "Fortran_REAL_%d", (-1)*FoundRealSize[i]);
		      sprintf(chrB, "real_%d_f", (-1)*FoundRealSize[i]);
		      if(FoundRealSize[j]>4) {
			writeFloatToFiles(chrA, chrB, FoundRealSize[j]);
		      }
		     /*  else { */
/* 			writeFloatToFiles(chrA, chrB, FoundRealSize[j]); */
/* 		      } */
		      flag = 1;
		      break;
		    }
		}
	    }
	  if(flag == 0) /* No higher or lower one found, indicating an error */
	    {
	     return -1; 
	    }
	}
    }

  /* hid_t */
#if defined H5_FORTRAN_HAS_INTEGER_8 && H5_SIZEOF_HID_T >= 8
      writeToFiles("HID_T", "hid_t_f", 8);
#elif defined H5_FORTRAN_HAS_INTEGER_4 && H5_SIZEOF_HID_T >= 4
      writeToFiles("HID_T", "hid_t_f", 4);
#elif defined H5_FORTRAN_HAS_INTEGER_2 && H5_SIZEOF_HID_T >= 2
      writeToFiles("HID_T", "hid_t_f", 2);
#elif defined H5_FORTRAN_HAS_INTEGER_1 && H5_SIZEOF_HID_T >= 1
      writeToFiles("HID_T", "hid_t_f", 1);
#elif defined H5_FORTRAN_HAS_INTEGER_8 && H5_SIZEOF_HID_T >= 4
      writeToFiles("HID_T", "hid_t_f", 8);
#else
    /* Error: couldn't find a size for hid_t */
    return -1;
#endif

  /* real_f */
#if defined H5_FORTRAN_HAS_REAL_NATIVE_16
    if(H5_C_HAS_REAL_NATIVE_16 != 0) {
      writeFloatToFiles("Fortran_REAL", "real_f", 16);
    }
#elif defined H5_FORTRAN_HAS_REAL_NATIVE_12
    if(H5_C_HAS_REAL_NATIVE_12 != 0) {
      writeFloatToFiles("Fortran_REAL", "real_f", 12);
    }
#elif defined H5_FORTRAN_HAS_REAL_NATIVE_8
      writeFloatToFiles("Fortran_REAL", "real_f", 8);
#elif defined H5_FORTRAN_HAS_REAL_NATIVE_4
      writeFloatToFiles("Fortran_REAL", "real_f", 4);
#else
    /* Error: couldn't find a size for real_f */
    return -1;
#endif

  /* double_f */
#if defined H5_FORTRAN_HAS_DOUBLE_NATIVE_16
      writeFloatToFiles("Fortran_DOUBLE", "double_f", 16);
#elif defined H5_FORTRAN_HAS_DOUBLE_NATIVE_8
      writeFloatToFiles("Fortran_DOUBLE", "double_f", 8);
#else
    /* Error: couldn't find a size for real_f */
    return -1;
#endif

  /* Close files */
  endCfile();
  endFfile();
  fclose(c_header);
  fclose(fort_header);
  return 0;
}

