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

/*
 * Programmer:  Robb Matzke <matzke@llnl.gov>
 *              Tuesday, August 10, 1999
 *
 * Purpose:	A driver which stores the HDF5 data in main memory  using
 *		only the HDF5 public API. This driver is useful for fast
 *		access to small, temporary hdf5 files.
 */

/* Interface initialization */
#define H5_INTERFACE_INIT_FUNC	H5FD_core_init_interface


#include "H5private.h"		/* Generic Functions			*/
#include "H5Eprivate.h"		/* Error handling		  	*/
#include "H5Fprivate.h"		/* File access				*/
#include "H5FDprivate.h"	/* File drivers				*/
#include "H5FDcore.h"           /* Core file driver			*/
#include "H5Iprivate.h"		/* IDs			  		*/
#include "H5MMprivate.h"	/* Memory management			*/
#include "H5Pprivate.h"		/* Property lists			*/

/* The driver identification number, initialized at runtime */
static hid_t H5FD_CORE_g = 0;

/*
 * The description of a file belonging to this driver. The `eoa' and `eof'
 * determine the amount of hdf5 address space in use and the high-water mark
 * of the file (the current size of the underlying memory).
 */
typedef struct H5FD_core_t {
    H5FD_t	pub;			/*public stuff, must be first	*/
    char	*name;			/*for equivalence testing	*/
    unsigned char *mem;			/*the underlying memory		*/
    haddr_t	eoa;			/*end of allocated region	*/
    haddr_t	eof;			/*current allocated size	*/
    size_t	increment;		/*multiples for mem allocation	*/
    hbool_t	backing_store;		/*write to file name on flush	*/
    int		fd;			/*backing store file descriptor	*/
    hbool_t	dirty;			/*changes not saved?		*/
} H5FD_core_t;

/* Driver-specific file access properties */
typedef struct H5FD_core_fapl_t {
    size_t	increment;		/*how much to grow memory	*/
    hbool_t	backing_store;		/*write to file name on flush	*/
} H5FD_core_fapl_t;

/* Allocate memory in multiples of this size by default */
#define H5FD_CORE_INCREMENT		8192

/*
 * These macros check for overflow of various quantities.  These macros
 * assume that file_offset_t is signed and haddr_t and size_t are unsigned.
 *
 * ADDR_OVERFLOW:	Checks whether a file address of type `haddr_t'
 *			is too large to be represented by the second argument
 *			of the file seek function.
 *
 * SIZE_OVERFLOW:	Checks whether a buffer size of type `hsize_t' is too
 *			large to be represented by the `size_t' type.
 *
 * REGION_OVERFLOW:	Checks whether an address and size pair describe data
 *			which can be addressed entirely in memory.
 */
#define MAXADDR 		((haddr_t)((~(size_t)0)-1))
#define ADDR_OVERFLOW(A)	(HADDR_UNDEF==(A) || (A) > (haddr_t)MAXADDR)
#define SIZE_OVERFLOW(Z)	((Z) > (hsize_t)MAXADDR)
#define REGION_OVERFLOW(A,Z)	(ADDR_OVERFLOW(A) || SIZE_OVERFLOW(Z) ||      \
                                 HADDR_UNDEF==(A)+(Z) ||		      \
				 (size_t)((A)+(Z))<(size_t)(A))

/* Prototypes */
static void *H5FD_core_fapl_get(H5FD_t *_file);
static H5FD_t *H5FD_core_open(const char *name, unsigned flags, hid_t fapl_id,
			      haddr_t maxaddr);
static herr_t H5FD_core_close(H5FD_t *_file);
static int H5FD_core_cmp(const H5FD_t *_f1, const H5FD_t *_f2);
static haddr_t H5FD_core_get_eoa(const H5FD_t *_file, H5FD_mem_t type);
static herr_t H5FD_core_set_eoa(H5FD_t *_file, H5FD_mem_t type, haddr_t addr);
static haddr_t H5FD_core_get_eof(const H5FD_t *_file);
static herr_t  H5FD_core_get_handle(H5FD_t *_file, hid_t fapl, void** file_handle);
static herr_t H5FD_core_read(H5FD_t *_file, H5FD_mem_t type, hid_t fapl_id, haddr_t addr,
			     size_t size, void *buf);
static herr_t H5FD_core_write(H5FD_t *_file, H5FD_mem_t type, hid_t fapl_id, haddr_t addr,
			      size_t size, const void *buf);
static herr_t H5FD_core_flush(H5FD_t *_file, hid_t dxpl_id, unsigned closing);

static const H5FD_class_t H5FD_core_g = {
    "core",					/*name			*/
    MAXADDR,					/*maxaddr		*/
    H5F_CLOSE_WEAK,				/*fc_degree		*/
    NULL,					/*sb_size		*/
    NULL,					/*sb_encode		*/
    NULL,					/*sb_decode		*/
    sizeof(H5FD_core_fapl_t),			/*fapl_size		*/
    H5FD_core_fapl_get,				/*fapl_get		*/
    NULL,					/*fapl_copy		*/
    NULL, 					/*fapl_free		*/
    0,						/*dxpl_size		*/
    NULL,					/*dxpl_copy		*/
    NULL,					/*dxpl_free		*/
    H5FD_core_open,				/*open			*/
    H5FD_core_close,				/*close			*/
    H5FD_core_cmp,				/*cmp			*/
    NULL,				        /*query			*/
    NULL,					/*alloc			*/
    NULL,					/*free			*/
    H5FD_core_get_eoa,				/*get_eoa		*/
    H5FD_core_set_eoa, 				/*set_eoa		*/
    H5FD_core_get_eof,				/*get_eof		*/
    H5FD_core_get_handle,                       /*get_handle            */
    H5FD_core_read,				/*read			*/
    H5FD_core_write,				/*write			*/
    H5FD_core_flush,				/*flush			*/
    NULL,                                       /*lock                  */
    NULL,                                       /*unlock                */
    H5FD_FLMAP_SINGLE 				/*fl_map		*/
};


/*--------------------------------------------------------------------------
NAME
   H5FD_core_init_interface -- Initialize interface-specific information
USAGE
    herr_t H5FD_core_init_interface()

RETURNS
    Non-negative on success/Negative on failure
DESCRIPTION
    Initializes any interface-specific data or routines.  (Just calls
    H5FD_core_init currently).

--------------------------------------------------------------------------*/
static herr_t
H5FD_core_init_interface(void)
{
    FUNC_ENTER_NOAPI_NOINIT_NOFUNC(H5FD_core_init_interface)

    FUNC_LEAVE_NOAPI(H5FD_core_init())
} /* H5FD_core_init_interface() */


/*-------------------------------------------------------------------------
 * Function:	H5FD_core_init
 *
 * Purpose:	Initialize this driver by registering the driver with the
 *		library.
 *
 * Return:	Success:	The driver ID for the core driver.
 *
 *		Failure:	Negative.
 *
 * Programmer:	Robb Matzke
 *              Thursday, July 29, 1999
 *
 * Modifications:
 *
 *-------------------------------------------------------------------------
 */
hid_t
H5FD_core_init(void)
{
    hid_t ret_value=H5FD_CORE_g;   /* Return value */

    FUNC_ENTER_NOAPI(H5FD_core_init, FAIL)

    if (H5I_VFL!=H5Iget_type(H5FD_CORE_g))
        H5FD_CORE_g = H5FD_register(&H5FD_core_g,sizeof(H5FD_class_t));

    /* Set return value */
    ret_value=H5FD_CORE_g;

done:
    FUNC_LEAVE_NOAPI(ret_value)
}


/*---------------------------------------------------------------------------
 * Function:	H5FD_core_term
 *
 * Purpose:	Shut down the VFD
 *
 * Return:	<none>
 *
 * Programmer:  Quincey Koziol
 *              Friday, Jan 30, 2004
 *
 * Modification:
 *
 *---------------------------------------------------------------------------
 */
void
H5FD_core_term(void)
{
    FUNC_ENTER_NOAPI_NOINIT_NOFUNC(H5FD_core_term)

    /* Reset VFL ID */
    H5FD_CORE_g=0;

    FUNC_LEAVE_NOAPI_VOID
} /* end H5FD_core_term() */


/*-------------------------------------------------------------------------
 * Function:	H5Pset_fapl_core
 *
 * Purpose:	Modify the file access property list to use the H5FD_CORE
 *		driver defined in this source file.  The INCREMENT specifies
 *		how much to grow the memory each time we need more.
 *
 * Return:	Non-negative on success/Negative on failure
 *
 * Programmer:	Robb Matzke
 *		Thursday, February 19, 1998
 *
 * Modifications:
 * 		Robb Matzke, 1999-10-19
 *		Added the BACKING_STORE argument. If set then the entire file
 *		contents are flushed to a file with the same name as this
 *		core file.
 *
 *		Raymond Lu, 2001-10-25
 *		Changed the file access list to the new generic list.
 *
 *-------------------------------------------------------------------------
 */
herr_t
H5Pset_fapl_core(hid_t fapl_id, size_t increment, hbool_t backing_store)
{
    H5FD_core_fapl_t	fa;
    H5P_genplist_t *plist;      /* Property list pointer */
    herr_t ret_value;

    FUNC_ENTER_API(H5Pset_fapl_core, FAIL)
    H5TRACE3("e", "izb", fapl_id, increment, backing_store);

    /* Check argument */
    if(NULL == (plist = H5P_object_verify(fapl_id,H5P_FILE_ACCESS)))
        HGOTO_ERROR(H5E_ARGS, H5E_BADTYPE, FAIL, "not a file access property list")

    fa.increment = increment;
    fa.backing_store = backing_store;

    ret_value= H5P_set_driver(plist, H5FD_CORE, &fa);

done:
    FUNC_LEAVE_API(ret_value)
}


/*-------------------------------------------------------------------------
 * Function:	H5Pget_fapl_core
 *
 * Purpose:	Queries properties set by the H5Pset_fapl_core() function.
 *
 * Return:	Success:	Non-negative
 *
 *		Failure:	Negative
 *
 * Programmer:	Robb Matzke
 *              Tuesday, August 10, 1999
 *
 * Modifications:
 *		Robb Matzke, 1999-10-19
 *		Added the BACKING_STORE argument.
 *
 *		Raymond Lu
 *		2001-10-25
 *		Changed file access list to the new generic property list.
 *
 *-------------------------------------------------------------------------
 */
herr_t
H5Pget_fapl_core(hid_t fapl_id, size_t *increment/*out*/,
		 hbool_t *backing_store/*out*/)
{
    H5FD_core_fapl_t	*fa;
    H5P_genplist_t *plist;      /* Property list pointer */
    herr_t      ret_value=SUCCEED;       /* Return value */

    FUNC_ENTER_API(H5Pget_fapl_core, FAIL)
    H5TRACE3("e", "ixx", fapl_id, increment, backing_store);

    if(NULL == (plist = H5P_object_verify(fapl_id,H5P_FILE_ACCESS)))
        HGOTO_ERROR(H5E_ARGS, H5E_BADTYPE, FAIL, "not a file access property list")
    if (H5FD_CORE!=H5P_get_driver(plist))
        HGOTO_ERROR(H5E_PLIST, H5E_BADVALUE, FAIL, "incorrect VFL driver")
    if (NULL==(fa=H5P_get_driver_info(plist)))
        HGOTO_ERROR(H5E_PLIST, H5E_BADVALUE, FAIL, "bad VFL driver info")

    if (increment)
        *increment = fa->increment;
    if (backing_store)
        *backing_store = fa->backing_store;

done:
    FUNC_LEAVE_API(ret_value)
}


/*-------------------------------------------------------------------------
 * Function:	H5FD_core_fapl_get
 *
 * Purpose:	Returns a copy of the file access properties.
 *
 * Return:	Success:	Ptr to new file access properties.
 *
 *		Failure:	NULL
 *
 * Programmer:	Robb Matzke
 *              Friday, August 13, 1999
 *
 * Modifications:
 *
 *-------------------------------------------------------------------------
 */
static void *
H5FD_core_fapl_get(H5FD_t *_file)
{
    H5FD_core_t		*file = (H5FD_core_t*)_file;
    H5FD_core_fapl_t	*fa = NULL;
    void      *ret_value;       /* Return value */

    FUNC_ENTER_NOAPI(H5FD_core_fapl_get, NULL)

    if (NULL==(fa=H5MM_calloc(sizeof(H5FD_core_fapl_t))))
        HGOTO_ERROR(H5E_RESOURCE, H5E_NOSPACE, NULL, "memory allocation failed")

    fa->increment = file->increment;
    fa->backing_store = (file->fd>=0);

    /* Set return value */
    ret_value=fa;

done:
    FUNC_LEAVE_NOAPI(ret_value)
}


/*-------------------------------------------------------------------------
 * Function:	H5FD_core_open
 *
 * Purpose:	Create memory as an HDF5 file.
 *
 * Return:	Success:	A pointer to a new file data structure. The
 *				public fields will be initialized by the
 *				caller, which is always H5FD_open().
 *
 *		Failure:	NULL
 *
 * Programmer:	Robb Matzke
 *              Thursday, July 29, 1999
 *
 * Modifications:
 *		Robb Matzke, 1999-10-19
 *		The backing store file is created and opened if specified.
 *              
 *              Raymond Lu, 2006-11-30
 *              Enabled the driver to read an existing file depending on 
 *              the setting of the backing_store and file open flags.
 *-------------------------------------------------------------------------
 */
static H5FD_t *
H5FD_core_open(const char *name, unsigned flags, hid_t fapl_id,
	       haddr_t maxaddr)
{
    int			o_flags;
    H5FD_core_t		*file=NULL;
    H5FD_core_fapl_t	*fa=NULL;
    H5P_genplist_t *plist;      /* Property list pointer */
    h5_stat_t		sb;
    int			fd=-1;
    H5FD_t		*ret_value;

    FUNC_ENTER_NOAPI(H5FD_core_open, NULL)

    /* Check arguments */
    if (!name || !*name)
        HGOTO_ERROR(H5E_ARGS, H5E_BADVALUE, NULL, "invalid file name")
    if (0==maxaddr || HADDR_UNDEF==maxaddr)
        HGOTO_ERROR(H5E_ARGS, H5E_BADRANGE, NULL, "bogus maxaddr")
    if (ADDR_OVERFLOW(maxaddr))
        HGOTO_ERROR(H5E_ARGS, H5E_OVERFLOW, NULL, "maxaddr overflow")
    if (H5P_DEFAULT!=fapl_id) {
        if(NULL == (plist = H5I_object(fapl_id)))
            HGOTO_ERROR(H5E_ARGS, H5E_BADTYPE, NULL, "not a file access property list")
        fa = H5P_get_driver_info(plist);
    } /* end if */

    /* Build the open flags */
    o_flags = (H5F_ACC_RDWR & flags) ? O_RDWR : O_RDONLY;
    if (H5F_ACC_TRUNC & flags) o_flags |= O_TRUNC;
    if (H5F_ACC_CREAT & flags) o_flags |= O_CREAT;
    if (H5F_ACC_EXCL & flags) o_flags |= O_EXCL;

    /* Open backing store.  The only case that backing store is off is when
     * the backing_store flag is off and H5F_ACC_CREAT is on. */
    if(fa->backing_store || !(H5F_ACC_CREAT & flags)) {
        if (fa && (fd=HDopen(name, o_flags, 0666))<0)
            HGOTO_ERROR(H5E_FILE, H5E_CANTOPENFILE, NULL, "unable to open file")
    }

    /* Create the new file struct */
    if (NULL==(file=H5MM_calloc(sizeof(H5FD_core_t))))
        HGOTO_ERROR(H5E_RESOURCE, H5E_NOSPACE, NULL, "unable to allocate file struct")
    file->fd = fd;
    if (name && *name)
        file->name = H5MM_xstrdup(name);

    /*
     * The increment comes from either the file access property list or the
     * default value. But if the file access property list was zero then use
     * the default value instead.
     */
    file->increment = (fa && fa->increment>0) ?  fa->increment : H5FD_CORE_INCREMENT;

    /* If save data in backing store. */
    file->backing_store = fa->backing_store;

    /* If an existing file is opened, load the whole file into memory. */
    if(!(H5F_ACC_CREAT & flags)) {
        unsigned char *x=NULL;
        size_t size;

        if (HDfstat(file->fd, &sb)<0)
            HSYS_GOTO_ERROR(H5E_FILE, H5E_BADFILE, NULL, "unable to fstat file")

	size = (size_t)sb.st_size;

        if(size) {
            if (NULL==file->mem)
                x = (unsigned char*)H5MM_malloc(size);

            if (!x)
                HGOTO_ERROR(H5E_RESOURCE, H5E_NOSPACE, NULL, "unable to allocate memory block")

            file->mem = x;
            file->eof = size;

            if(HDread(file->fd, file->mem, size)<0)
                HGOTO_ERROR(H5E_FILE, H5E_CANTOPENFILE, NULL, "unable to read file")
        }
    }

    /* Set return value */
    ret_value=(H5FD_t *)file;

done:
    FUNC_LEAVE_NOAPI(ret_value)
}


/*-------------------------------------------------------------------------
 * Function:	H5FD_core_close
 *
 * Purpose:	Closes the file.
 *
 * Return:	Success:	0
 *
 *		Failure:	-1
 *
 * Programmer:	Robb Matzke
 *              Thursday, July 29, 1999
 *
 * Modifications:
 * 		Robb Matzke, 1999-10-19
 *		The contents of memory are written to the backing store if
 *		one is open.
 *-------------------------------------------------------------------------
 */
static herr_t
H5FD_core_close(H5FD_t *_file)
{
    H5FD_core_t	*file = (H5FD_core_t*)_file;
    herr_t      ret_value=SUCCEED;       /* Return value */

    FUNC_ENTER_NOAPI(H5FD_core_close, FAIL)

    /* Release resources */
    if (file->fd>=0)
        HDclose(file->fd);
    if (file->name)
        H5MM_xfree(file->name);
    if (file->mem)
        H5MM_xfree(file->mem);
    HDmemset(file, 0, sizeof(H5FD_core_t));
    H5MM_xfree(file);

done:
    FUNC_LEAVE_NOAPI(ret_value)
}


/*-------------------------------------------------------------------------
 * Function:	H5FD_core_cmp
 *
 * Purpose:	Compares two files belonging to this driver by name. If one
 *		file doesn't have a name then it is less than the other file.
 *		If neither file has a name then the comparison is by file
 *		address.
 *
 * Return:	Success:	A value like strcmp()
 *
 *		Failure:	never fails (arguments were checked by the
 *				caller).
 *
 * Programmer:	Robb Matzke
 *              Thursday, July 29, 1999
 *
 * Modifications:
 *
 *-------------------------------------------------------------------------
 */
static int
H5FD_core_cmp(const H5FD_t *_f1, const H5FD_t *_f2)
{
    const H5FD_core_t	*f1 = (const H5FD_core_t*)_f1;
    const H5FD_core_t	*f2 = (const H5FD_core_t*)_f2;
    int			ret_value;

    FUNC_ENTER_NOAPI(H5FD_core_cmp, FAIL)

    if (NULL==f1->name && NULL==f2->name) {
        if (f1<f2)
            HGOTO_DONE(-1)
        if (f1>f2)
            HGOTO_DONE(1)
        HGOTO_DONE(0)
    }

    if (NULL==f1->name)
        HGOTO_DONE(-1)
    if (NULL==f2->name)
        HGOTO_DONE(1)

    ret_value = HDstrcmp(f1->name, f2->name);

done:
    FUNC_LEAVE_NOAPI(ret_value)
}


/*-------------------------------------------------------------------------
 * Function:	H5FD_core_get_eoa
 *
 * Purpose:	Gets the end-of-address marker for the file. The EOA marker
 *		is the first address past the last byte allocated in the
 *		format address space.
 *
 * Return:	Success:	The end-of-address marker.
 *
 *		Failure:	HADDR_UNDEF
 *
 * Programmer:	Robb Matzke
 *              Monday, August  2, 1999
 *
 * Modifications:
 *              Raymond Lu
 *              21 Dec. 2006
 *              Added the parameter TYPE.  It's only used for MULTI driver.
 *
 *-------------------------------------------------------------------------
 */
static haddr_t
H5FD_core_get_eoa(const H5FD_t *_file, H5FD_mem_t UNUSED type)
{
    haddr_t ret_value;   /* Return value */

    const H5FD_core_t	*file = (const H5FD_core_t*)_file;

    FUNC_ENTER_NOAPI(H5FD_core_get_eoa, HADDR_UNDEF)

    /* Set return value */
    ret_value=file->eoa;

done:
    FUNC_LEAVE_NOAPI(ret_value)
}


/*-------------------------------------------------------------------------
 * Function:	H5FD_core_set_eoa
 *
 * Purpose:	Set the end-of-address marker for the file. This function is
 *		called shortly after an existing HDF5 file is opened in order
 *		to tell the driver where the end of the HDF5 data is located.
 *
 * Return:	Success:	0
 *
 *		Failure:	-1
 *
 * Programmer:	Robb Matzke
 *              Thursday, July 29, 1999
 *
 * Modifications:
 *              Raymond Lu
 *              21 Dec. 2006
 *              Added the parameter TYPE.  It's only used for MULTI driver.
 *
 *-------------------------------------------------------------------------
 */
static herr_t
H5FD_core_set_eoa(H5FD_t *_file, H5FD_mem_t UNUSED type, haddr_t addr)
{
    H5FD_core_t	*file = (H5FD_core_t*)_file;
    herr_t      ret_value=SUCCEED;       /* Return value */

    FUNC_ENTER_NOAPI(H5FD_core_set_eoa, FAIL)

    if (ADDR_OVERFLOW(addr))
        HGOTO_ERROR(H5E_ARGS, H5E_OVERFLOW, FAIL, "address overflow")

    file->eoa = addr;

done:
    FUNC_LEAVE_NOAPI(ret_value)
}


/*-------------------------------------------------------------------------
 * Function:	H5FD_core_get_eof
 *
 * Purpose:	Returns the end-of-file marker, which is the greater of
 *		either the size of the underlying memory or the HDF5
 *		end-of-address markers.
 *
 * Return:	Success:	End of file address, the first address past
 *				the end of the "file", either the memory
 *				or the HDF5 file.
 *
 *		Failure:	HADDR_UNDEF
 *
 * Programmer:	Robb Matzke
 *              Thursday, July 29, 1999
 *
 * Modifications:
 *
 *-------------------------------------------------------------------------
 */
static haddr_t
H5FD_core_get_eof(const H5FD_t *_file)
{
    haddr_t ret_value;   /* Return value */

    const H5FD_core_t	*file = (const H5FD_core_t*)_file;

    FUNC_ENTER_NOAPI(H5FD_core_get_eof, HADDR_UNDEF)

    /* Set return value */
    ret_value=MAX(file->eof, file->eoa);

done:
    FUNC_LEAVE_NOAPI(ret_value)
}


/*-------------------------------------------------------------------------
 * Function:       H5FD_core_get_handle
 *
 * Purpose:        Returns the file handle of CORE file driver.
 *
 * Returns:        Non-negative if succeed or negative if fails.
 *
 * Programmer:     Raymond Lu
 *                 Sept. 16, 2002
 *
 * Modifications:
 *
 *-------------------------------------------------------------------------
 */
/* ARGSUSED */
static herr_t
H5FD_core_get_handle(H5FD_t *_file, hid_t UNUSED fapl, void** file_handle)
{
    H5FD_core_t         *file = (H5FD_core_t *)_file;
    herr_t              ret_value = SUCCEED;

    FUNC_ENTER_NOAPI(H5FD_core_get_handle, FAIL)

    if(!file_handle)
         HGOTO_ERROR(H5E_ARGS, H5E_BADVALUE, FAIL, "file handle not valid")

    *file_handle = &(file->mem);

done:
    FUNC_LEAVE_NOAPI(ret_value)
}


/*-------------------------------------------------------------------------
 * Function:	H5FD_core_read
 *
 * Purpose:	Reads SIZE bytes of data from FILE beginning at address ADDR
 *		into buffer BUF according to data transfer properties in
 *		DXPL_ID.
 *
 * Return:	Success:	Zero. Result is stored in caller-supplied
 *				buffer BUF.
 *
 *		Failure:	-1, Contents of buffer BUF are undefined.
 *
 * Programmer:	Robb Matzke
 *              Thursday, July 29, 1999
 *
 * Modifications:
 *
 *-------------------------------------------------------------------------
 */
/* ARGSUSED */
static herr_t
H5FD_core_read(H5FD_t *_file, H5FD_mem_t UNUSED type, hid_t UNUSED dxpl_id, haddr_t addr,
	       size_t size, void *buf/*out*/)
{
    H5FD_core_t	*file = (H5FD_core_t*)_file;
    herr_t      ret_value=SUCCEED;       /* Return value */

    FUNC_ENTER_NOAPI(H5FD_core_read, FAIL)

    assert(file && file->pub.cls);
    assert(buf);

    /* Check for overflow conditions */
    if (HADDR_UNDEF == addr)
        HGOTO_ERROR(H5E_IO, H5E_OVERFLOW, FAIL, "file address overflowed")
    if (REGION_OVERFLOW(addr, size))
        HGOTO_ERROR(H5E_IO, H5E_OVERFLOW, FAIL, "file address overflowed")
    if (addr + size > file->eoa)
        HGOTO_ERROR(H5E_IO, H5E_OVERFLOW, FAIL, "file address overflowed")

    /* Read the part which is before the EOF marker */
    if (addr < file->eof) {
        size_t nbytes;
#ifndef NDEBUG
        hsize_t temp_nbytes;

        temp_nbytes = file->eof-addr;
        H5_CHECK_OVERFLOW(temp_nbytes,hsize_t,size_t);
        nbytes = MIN(size,(size_t)temp_nbytes);
#else /* NDEBUG */
        nbytes = MIN(size,(size_t)(file->eof-addr));
#endif /* NDEBUG */

        HDmemcpy(buf, file->mem + addr, nbytes);
        size -= nbytes;
        addr += nbytes;
        buf = (char *)buf + nbytes;
    }

    /* Read zeros for the part which is after the EOF markers */
    if (size > 0)
        HDmemset(buf, 0, size);

done:
    FUNC_LEAVE_NOAPI(ret_value)
}


/*-------------------------------------------------------------------------
 * Function:	H5FD_core_write
 *
 * Purpose:	Writes SIZE bytes of data to FILE beginning at address ADDR
 *		from buffer BUF according to data transfer properties in
 *		DXPL_ID.
 *
 * Return:	Success:	Zero
 *
 *		Failure:	-1
 *
 * Programmer:	Robb Matzke
 *              Thursday, July 29, 1999
 *
 * Modifications:
 *
 *-------------------------------------------------------------------------
 */
/* ARGSUSED */
static herr_t
H5FD_core_write(H5FD_t *_file, H5FD_mem_t UNUSED type, hid_t UNUSED dxpl_id, haddr_t addr,
		size_t size, const void *buf)
{
    H5FD_core_t		*file = (H5FD_core_t*)_file;
    herr_t      ret_value=SUCCEED;       /* Return value */

    FUNC_ENTER_NOAPI(H5FD_core_write, FAIL)

    assert(file && file->pub.cls);
    assert(buf);

    /* Check for overflow conditions */
    if (REGION_OVERFLOW(addr, size))
        HGOTO_ERROR(H5E_IO, H5E_OVERFLOW, FAIL, "file address overflowed")
    if (addr+size>file->eoa)
        HGOTO_ERROR(H5E_IO, H5E_OVERFLOW, FAIL, "file address overflowed")

    /*
     * Allocate more memory if necessary, careful of overflow. Also, if the
     * allocation fails then the file should remain in a usable state.  Be
     * careful of non-Posix realloc() that doesn't understand what to do when
     * the first argument is null.
     */
    if (addr+size>file->eof) {
        unsigned char *x;
        size_t new_eof;

        H5_ASSIGN_OVERFLOW(new_eof,file->increment*((addr+size)/file->increment),hsize_t,size_t);

        if ((addr+size) % file->increment)
            new_eof += file->increment;
        if (NULL==file->mem)
            x = H5MM_malloc(new_eof);
        else
            x = H5MM_realloc(file->mem, new_eof);
#ifdef H5_CLEAR_MEMORY
HDmemset(x + file->eof, 0, (size_t)(new_eof - file->eof));
#endif /* H5_CLEAR_MEMORY */
        if (!x)
            HGOTO_ERROR(H5E_RESOURCE, H5E_NOSPACE, FAIL, "unable to allocate memory block")
        file->mem = x;
        file->eof = new_eof;
    }

    /* Write from BUF to memory */
    HDmemcpy(file->mem+addr, buf, size);
    file->dirty = TRUE;

done:
    FUNC_LEAVE_NOAPI(ret_value)
}


/*-------------------------------------------------------------------------
 * Function:	H5FD_core_flush
 *
 * Purpose:	Flushes the file to backing store if there is any and if the
 *		dirty flag is set.
 *
 * Return:	Success:	0
 *
 *		Failure:	-1
 *
 * Programmer:	Robb Matzke
 *              Friday, October 15, 1999
 *
 * Modifications:
 *              Raymond Lu, 2006-11-30
 *              Added a condition check for backing store flag, for an
 *              existing file can be opened for read and write now. 
 *-------------------------------------------------------------------------
 */
/* ARGSUSED */
static herr_t
H5FD_core_flush(H5FD_t *_file, hid_t UNUSED dxpl_id, unsigned UNUSED closing)
{
    H5FD_core_t	*file = (H5FD_core_t*)_file;
    herr_t      ret_value=SUCCEED;       /* Return value */

    FUNC_ENTER_NOAPI(H5FD_core_flush, FAIL)

    /* Write to backing store */
    if (file->dirty && file->fd>=0 && file->backing_store) {
        haddr_t size = file->eof;
        unsigned char *ptr = file->mem;

        if (0!=HDlseek(file->fd, (off_t)0, SEEK_SET))
            HGOTO_ERROR(H5E_IO, H5E_SEEKERROR, FAIL, "error seeking in backing store")

        while (size) {
            ssize_t n;

            H5_CHECK_OVERFLOW(size,hsize_t,size_t);
            n = HDwrite(file->fd, ptr, (size_t)size);
            if (n<0 && EINTR==errno)
                continue;
            if (n<0)
                HGOTO_ERROR(H5E_IO, H5E_WRITEERROR, FAIL, "error writing backing store")
            ptr += (size_t)n;
            size -= (size_t)n;
        }
        file->dirty = FALSE;
    }

done:
    FUNC_LEAVE_NOAPI(ret_value)
}
