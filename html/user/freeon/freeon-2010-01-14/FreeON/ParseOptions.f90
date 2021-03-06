!------------------------------------------------------------------------------
!    This code is part of the MondoSCF suite of programs for linear scaling
!    electronic structure theory and ab initio molecular dynamics.
!
!    Copyright (2004). The Regents of the University of California. This
!    material was produced under U.S. Government contract W-7405-ENG-36
!    for Los Alamos National Laboratory, which is operated by the University
!    of California for the U.S. Department of Energy. The U.S. Government has
!    rights to use, reproduce, and distribute this software.  NEITHER THE
!    GOVERNMENT NOR THE UNIVERSITY MAKES ANY WARRANTY, EXPRESS OR IMPLIED,
!    OR ASSUMES ANY LIABILITY FOR THE USE OF THIS SOFTWARE.
!
!    This program is free software; you can redistribute it and/or modify
!    it under the terms of the GNU General Public License as published by the
!    Free Software Foundation; either version 2 of the License, or (at your
!    option) any later version. Accordingly, this program is distributed in
!    the hope that it will be useful, but WITHOUT ANY WARRANTY; without even
!    the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
!    PURPOSE. See the GNU General Public License at www.gnu.org for details.
!
!    While you may do as you like with this software, the GNU license requires
!    that you clearly mark derivative software.  In addition, you are encouraged
!    to return derivative works to the MondoSCF group for review, and possible
!    disemination in future releases.
!------------------------------------------------------------------------------

#include "MondoConfig.h"

MODULE ParseOptions
  USE InOut
  USE Parse
  USE MemMan
  USE Numerics
  USE Conflicted
  USE OptionKeys
  USE Functionals
  USE DerivedTypes
  USE GlobalScalars
  USE GlobalObjects
  USE ProcessControl
  USE GlobalCharacters
  USE ParsingConstants
  USE ControlStructures
  USE MondoLogger
#ifdef NAG
  USE F90_UNIX
#endif

  IMPLICIT NONE

CONTAINS

  !============================================================================
  !  LOAD THE OPTIONS OBJECT
  !============================================================================
  SUBROUTINE LoadOptions(N,O)
    TYPE(FileNames) :: N
    TYPE(Options)   :: O
    INTEGER         :: HDFFileID

    CALL OpenASCII(N%IFile,Inp)
    ! Check for restart, and extract the current state from the restart HDF file
    CALL ParseRestart(N%M_PWD,N%NewFileID,O%Guess,N%RFile,O%RestartState)
    ! Parse print output options, load global object PrintFlags and N%GFile
    CALL ParsePrintFlags(O%PFlags,N,O%GeomPrint)
    ! Parse for accuracy levels and set thresholds
    CALL ParseThresholds(O%NThrsh,O%AccuracyLevels,O%Thresholds)
    ! Parse for SCF methods to use in solution of SCF equations and put to HDF
    CALL ParseSCFMethods(O%NMthds,O%Methods)
    ! Parse for Convergence Algorithms
    CALL ParseConvergence(O%NConvergence,O%Convergence)
    ! Parse for model chemistries
    CALL ParseModelChems(O%NModls,O%Models)
    ! Parse for spin model.
    CALL ParseSpinModels(O%NModls, O%NSpinModels, O%NSMat)
    ! Parse for gradient options.
    CALL ParseGradients(O%NSteps, O%Coordinates, O%Grad, O%DoGDIIS, &
                        O%SteepStep, O%CartesianOptimizerMethod)
    IF(O%Grad == GRAD_TS_SEARCH_NEB) THEN
      ! Parse for NEB options.
      CALL ParseNEB(O%NEBSteepAlpha, O%NEBSteepMaxMove, O%NEBSpring, &
                    O%NEBClimb, O%NEBDoubleNudge, O%EndPts, N%ReactantsFile, &
                    N%ProductsFile, O%NEBReactantEnergy, O%NEBProductEnergy)
    ENDIF
    ! Parse Optimizer options.
    CALL ParseOptimizer(O%ConjugateGradientMaxMove, O%ConjugateGradientAlpha)
    ! Parse SCF convergence overides and DMPOrder
    CALL ParseSCF(O%MinSCF,O%MaxSCF)
    ! Parse RQI guess and max iteration count
    CALL ParseRQI(O%RQIGuess,O%MaxRQI)
    ! Parse Misc
    CALL ParseMISC(O%Pressure, O%UseLennardJones, O%LennardJonesR0, O%LennardJonesEpsilon)
    ! close
    CLOSE(UNIT=Inp,STATUS='KEEP')
  END SUBROUTINE LoadOptions

  !============================================================================
  !  PARSE THE METHODS TO USE IN SOLUTION OF THE SCF EQUATIONS
  !============================================================================
  SUBROUTINE ParseModelChems(NModls,Models)
    INTEGER                       :: NModls,I
    INTEGER,   DIMENSION(MaxSets) :: Models

    NModls=0
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_Hartree,MaxSets,NLoc,Location))THEN
       NModls=NModls+NLoc
       DO I=1,NLoc
          Models(Location(I))=NO_EXCHANGE
       ENDDO
    ENDIF
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_ExactX,MaxSets,NLoc,Location))THEN
      NModls=NModls+NLoc
      DO I=1,NLoc
        Models(Location(I))=EXACT_EXCHANGE
      ENDDO
    ENDIF
    ! Slater-Dirac exchage
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_SD,MaxSets,NLoc,Location))THEN
      NModls=NModls+NLoc
      DO I=1,NLoc
        Models(Location(I))=SD_EXCHANGE
      ENDDO
    ENDIF
    ! X-alpha exchage
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_XA,MaxSets,NLoc,Location))THEN
      NModls=NModls+NLoc
      DO I=1,NLoc
        Models(Location(I))=XA_EXCHANGE
      ENDDO
    ENDIF
    ! PW91 exchange
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_PW91x,MaxSets,NLoc,Location))THEN
      NModls=NModls+NLoc
      DO I=1,NLoc
        Models(Location(I))=PW91_EXCHANGE
      ENDDO
    ENDIF
    ! PBE exchange
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_PBEx,MaxSets,NLoc,Location))THEN
      NModls=NModls+NLoc
      DO I=1,NLoc
        Models(Location(I))=PBE_EXCHANGE
      ENDDO
    ENDIF
    ! B88 exchange
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_B88x,MaxSets,NLoc,Location))THEN
      NModls=NModls+NLoc
      DO I=1,NLoc
        Models(Location(I))=B88_EXCHANGE
      ENDDO
    ENDIF
    ! Pure Slater exchange with VWN3 LSDA correlation
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_VWN3,MaxSets,NLoc,Location))THEN
      NModls=NModls+NLoc
      DO I=1,NLoc
        Models(Location(I))=PURE_VWN3_LSD
      ENDDO
    ENDIF
    ! Pure Slater exchange with VWN5 LSDA correlation
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_VWN5,MaxSets,NLoc,Location))THEN
      NModls=NModls+NLoc
      DO I=1,NLoc
        Models(Location(I))=PURE_VWN5_LSD
      ENDDO
    ENDIF
    ! Pure PW91 exchange and correlation
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_PW91PW91,MaxSets,NLoc,Location))THEN
      NModls=NModls+NLoc
      DO I=1,NLoc
        Models(Location(I))=PURE_PW91_PW91
      ENDDO
    ENDIF
    ! Pure PW91 exchange with LYP correlation
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_PW91LYP,MaxSets,NLoc,Location))THEN
      NModls=NModls+NLoc
      DO I=1,NLoc
        Models(Location(I))=PURE_PW91_LYP
      ENDDO
    ENDIF
    ! Pure PBE GGA exchange-correlation
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_PBEPBE,MaxSets,NLoc,Location))THEN
      NModls=NModls+NLoc
      DO I=1,NLoc
        Models(Location(I))=PURE_PBE_PBE
      ENDDO
    ENDIF
    ! Pure BLYP GGA exchange-correlation
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_BLYP,MaxSets,NLoc,Location))THEN
      NModls=NModls+NLoc
      DO I=1,NLoc
        Models(Location(I))=PURE_B88_LYP
      ENDDO
    ENDIF
    ! Pure BPW91 GGA exchange-correlation
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_BPW91,MaxSets,NLoc,Location))THEN
      NModls=NModls+NLoc
      DO I=1,NLoc
        Models(Location(I))=PURE_B88_PW91
      ENDDO
    ENDIF
    ! Pure HCTH93 GGA exchange-correlation
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_HCTH93,MaxSets,NLoc,Location))THEN
      NModls=NModls+NLoc
      DO I=1,NLoc
        Models(Location(I))=PURE_HCTH93
      ENDDO
    ENDIF
    ! Pure HCTH120 GGA exchange-correlation
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_HCTH120,MaxSets,NLoc,Location))THEN
      NModls=NModls+NLoc
      DO I=1,NLoc
        Models(Location(I))=PURE_HCTH120
      ENDDO
    ENDIF
    ! Pure HCTH147 GGA exchange-correlation
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_HCTH147,MaxSets,NLoc,Location))THEN
      NModls=NModls+NLoc
      DO I=1,NLoc
        Models(Location(I))=PURE_HCTH147
      ENDDO
    ENDIF
    ! Pure HCTH407 GGA exchange-correlation
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_HCTH407,MaxSets,NLoc,Location))THEN
      NModls=NModls+NLoc
      DO I=1,NLoc
        Models(Location(I))=PURE_HCTH407
      ENDDO
    ENDIF
    ! Pure XLYP exchange-correlation
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_XLYP,MaxSets,NLoc,Location))THEN
      NModls=NModls+NLoc
      DO I=1,NLoc
        Models(Location(I))=PURE_XLYP
      ENDDO
    ENDIF
    ! Hybrid B3LYP/VWN3 exchange-correlation
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_B3LYP_VWN3,MaxSets,NLoc,Location))THEN
      NModls=NModls+NLoc
      DO I=1,NLoc
        Models(Location(I))=HYBRID_B3LYP_VWN3
      ENDDO
    ENDIF
    ! Hybrid B3LYP/VWN5 exchange-correlation
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_B3LYP_VWN5,MaxSets,NLoc,Location))THEN
      NModls=NModls+NLoc
      DO I=1,NLoc
        Models(Location(I))=HYBRID_B3LYP_VWN5
      ENDDO
    ENDIF
    ! Hybrid B3LYP/PW91 exchange-correlation
    !    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_B3LYP_PW91,MaxSets,NLoc,Location))THEN
    !       NModls=NModls+NLoc
    !       DO I=1,NLoc
    !          Models(Location(I))=HYBRID_B3LYP_PW91
    !       ENDDO
    !    ENDIF
    ! Hybrid PBE0 exchange-correlation
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_PBE0,MaxSets,NLoc,Location))THEN
      NModls=NModls+NLoc
      DO I=1,NLoc
        Models(Location(I))=HYBRID_PBE0
      ENDDO
    ENDIF
    ! Hybrid X3LYP exchange-correlation
    IF(OptKeyLocQ(Inp,MODEL_OPTION,MODEL_X3LYP,MaxSets,NLoc,Location))THEN
      NModls=NModls+NLoc
      DO I=1,NLoc
        Models(Location(I))=HYBRID_X3LYP
      ENDDO
    ENDIF
  END SUBROUTINE ParseModelChems

  SUBROUTINE ParseSpinModels(NModls, NSpinModels, NSMat)
    INTEGER, INTENT(IN)                         :: NModls
    INTEGER, INTENT(INOUT)                      :: NSpinModels
    INTEGER, DIMENSION(MaxSets), INTENT(INOUT)  :: NSMat
    INTEGER                                     :: i

    NSpinModels = 0

    ! Reset spin models.
    DO i = 1, NModls
      NSMat(i) = 0
    ENDDO

    IF(OptKeyLocQ(Inp, SPIN_MODEL_OPTION, SPIN_MODEL_RESTRICTED, MaxSets, NLoc, Location)) THEN
      NSpinModels = NSpinModels + NLoc
      DO i = 1, NLoc
        NSMat(Location(i)) = SPIN_MODEL_RESTRICTED_VALUE
      ENDDO
    ENDIF

    IF(OptKeyLocQ(Inp, SPIN_MODEL_OPTION, SPIN_MODEL_UNRESTRICTED, MaxSets, NLoc, Location)) THEN
      NSpinModels = NSpinModels + NLoc
      DO i = 1, NLoc
        NSMat(Location(i)) = SPIN_MODEL_UNRESTRICTED_VALUE
      ENDDO
    ENDIF

    IF(OptKeyLocQ(Inp, SPIN_MODEL_OPTION, SPIN_MODEL_GENERALIZED, MaxSets, NLoc, Location)) THEN
      NSpinModels = NSpinModels + NLoc
      DO i = 1, NLoc
        NSMat(Location(i)) = SPIN_MODEL_GENERALIZED_VALUE
      ENDDO
    ENDIF

  END SUBROUTINE ParseSpinModels

  !============================================================================
  !  PARSE THE METHODS TO USE IN SOLUTION OF THE SCF EQUATIONS
  !============================================================================
  SUBROUTINE ParseSCFMethods(NMthds,Methods)
    INTEGER                       :: NMthds,NLoc,I
    INTEGER,   DIMENSION(MaxSets) :: Methods
    !----------------------------------------------------------------------------
    NMthds=0
    IF(OptKeyLocQ(Inp,SCF_OPTION,SCF_SDMM,MaxSets,NLoc,Location))THEN
      NMthds=NMthds+NLoc
      DO I=1,NLoc
        Methods(Location(I))=SDMM_R_SCF
      ENDDO
    ENDIF
    IF(OptKeyLocQ(Inp,SCF_OPTION,SCF_PM,MaxSets,NLoc,Location))THEN
      NMthds=NMthds+NLoc
      DO I=1,NLoc
        Methods(Location(I))=PM_R_SCF
      ENDDO
    ENDIF
    IF(OptKeyLocQ(Inp,SCF_OPTION,SCF_SP2,MaxSets,NLoc,Location))THEN
      NMthds=NMthds+NLoc
      DO I=1,NLoc
        Methods(Location(I))=SP2_R_SCF
      ENDDO
    ENDIF
    IF(OptKeyLocQ(Inp,SCF_OPTION,SCF_SP4,MaxSets,NLoc,Location))THEN
      NMthds=NMthds+NLoc
      DO I=1,NLoc
        Methods(Location(I))=SP4_R_SCF
      ENDDO
    ENDIF
    IF(OptKeyLocQ(Inp,SCF_OPTION,SCF_TS4,MaxSets,NLoc,Location))THEN
      NMthds=NMthds+NLoc
      DO I=1,NLoc
        Methods(Location(I))=TS4_R_SCF
      ENDDO
    ENDIF
    IF(OptKeyLocQ(Inp,SCF_OPTION,SCF_RHHF,MaxSets,NLoc,Location))THEN
      NMthds=NMthds+NLoc
      DO I=1,NLoc
        Methods(Location(I))=RH_R_SCF
      ENDDO
    ENDIF
    IF(NMthds==0) &
         CALL MondoHalt(PRSE_ERROR,'Option '//SCF_OPTION//' not set in input.'//RTRN   &
         //'Options include '//SCF_SDMM//', '//SCF_PM//', '//SCF_SP2//', '//SCF_TS4//', and '//SCF_RHHF)
  END SUBROUTINE ParseSCFMethods

  !============================================================================
  !  PARSE CONVERGENCE ALGORITHMS
  !============================================================================
  SUBROUTINE ParseConvergence(NConvergence,Convergence)
    INTEGER                       :: NConvergence,NLoc,I
    INTEGER,   DIMENSION(MaxSets) :: Convergence
    !----------------------------------------------------------------------------
    NConvergence=0
    ! ODA -> DIIS convergence is the default
    Convergence(:) = ODMIX_CNVRGNC
    !
    IF(OptKeyLocQ(Inp,CNVRGNC_OPTION,CNVRGNC_DIIS,MaxSets,NLoc,Location))THEN
      NConvergence=NConvergence+NLoc
      DO I=1,NLoc
        Convergence(Location(I))=DIIS_CNVRGNC
      ENDDO
    ENDIF
    IF(OptKeyLocQ(Inp,CNVRGNC_OPTION,CNVRGNC_ODA,MaxSets,NLoc,Location))THEN
      NConvergence=NConvergence+NLoc
      DO I=1,NLoc
        Convergence(Location(I))=ODA_CNVRGNC
      ENDDO
    ENDIF
    IF(OptKeyLocQ(Inp,CNVRGNC_OPTION,CNVRGNC_ODMIX,MaxSets,NLoc,Location))THEN
      NConvergence=NConvergence+NLoc
      DO I=1,NLoc
        Convergence(Location(I))=ODMIX_CNVRGNC
      ENDDO
    ENDIF
    IF(OptKeyLocQ(Inp,CNVRGNC_OPTION,CNVRGNC_DOMIX,MaxSets,NLoc,Location))THEN
      NConvergence=NConvergence+NLoc
      DO I=1,NLoc
        Convergence(Location(I))=DOMIX_CNVRGNC
      ENDDO
    ENDIF
    IF(OptKeyLocQ(Inp,CNVRGNC_OPTION,CNVRGNC_SMIX,MaxSets,NLoc,Location))THEN
      NConvergence=NConvergence+NLoc
      DO I=1,NLoc
        Convergence(Location(I))=SMIX_CNVRGNC
      ENDDO
    ENDIF
    !
    IF(OptKeyLocQ(Inp,CNVRGNC_OPTION,CNVRGNC_INCF,MaxSets,NLoc,Location))THEN
      NConvergence=NConvergence+NLoc
      DO I=1,NLoc
        Convergence(Location(I))=INCF_CNVRGNC
      ENDDO
    ENDIF
    !
  END SUBROUTINE ParseConvergence
  !===============================================================================================
  ! PARSE FOR ACCURACY LEVELS AND SET THRESHOLDS
  !===============================================================================================
  SUBROUTINE ParseThresholds(NThrsh,AccuracyLevels,Thresholds)
    INTEGER                       :: NThrsh,I
    INTEGER,   DIMENSION(MaxSets) :: AccuracyLevels
    TYPE(TOLS),DIMENSION(MaxSets) :: Thresholds
    !-----------------------------------------------------------------------------------------------
    NThrsh=0
    IF(OptKeyLocQ(Inp,ACCURACY_OPTION,ACCURACY_CHEEZY,MaxSets,NLoc,Location))THEN
      NThrsh=NThrsh+NLoc
      DO I=1,NLoc
        AccuracyLevels(Location(I))=1
      ENDDO
    ENDIF
    IF(OptKeyLocQ(Inp,ACCURACY_OPTION,ACCURACY_GOOD,MaxSets,NLoc,Location))THEN
      NThrsh=NThrsh+NLoc
      DO I=1,NLoc
        AccuracyLevels(Location(I))=2
      ENDDO
    ENDIF
    IF(OptKeyLocQ(Inp,ACCURACY_OPTION,ACCURACY_TIGHT,MaxSets,NLoc,Location))THEN
      NThrsh=NThrsh+NLoc
      DO I=1,NLoc
        AccuracyLevels(Location(I))=3
      ENDDO
    ENDIF
    IF(OptKeyLocQ(Inp,ACCURACY_OPTION,ACCURACY_RETENTIVE,MaxSets,NLoc,Location))THEN
      NThrsh=NThrsh+NLoc
      DO I=1,NLoc
        AccuracyLevels(Location(I))=4
      ENDDO
    ENDIF
    IF(NThrsh==0) &
         CALL MondoHalt(PRSE_ERROR,'Option '//ACCURACY_OPTION//' not set in input.'//RTRN   &
         //'Options include '//ACCURACY_CHEEZY//', '//ACCURACY_GOOD//', '   &
         //ACCURACY_TIGHT//', and '//ACCURACY_RETENTIVE)
    ! Set thresholds
    DO I=1,NThrsh
      Thresholds(I)%Cube=CubeNeglect(AccuracyLevels(I))
      Thresholds(I)%Trix=TrixNeglect(AccuracyLevels(I))
      Thresholds(I)%Dist=DistNeglect(AccuracyLevels(I))
      Thresholds(I)%TwoE=TwoENeglect(AccuracyLevels(I))
      Thresholds(I)%ETol=ETol(AccuracyLevels(I))
      Thresholds(I)%DTol=DTol(AccuracyLevels(I))
    ENDDO
  END SUBROUTINE ParseThresholds
  !===============================================================================================
  ! PARSE THE INPUT FILE FOR GUESS OPTIONS, GET PREVIOUS CURRENT SCF STATE IF RESTART
  !===============================================================================================
  SUBROUTINE ParseRestart(M_PWD,NewFileID,Guess,RestartHDF,RestartState)
    CHARACTER(LEN=*)                 :: M_PWD
    CHARACTER(LEN=DCL)               :: RestartHDF,CTmp
    TYPE(INT_VECT)                   :: RestartState
    INTEGER                          :: Guess,NewFileID,L1,L2,L3
    !-----------------------------------------------------------------------------------------------
    IF(OptKeyQ(Inp,GUESS_OPTION,GUESS_RESTART))THEN
      Guess=GUESS_EQ_RESTART
    ELSEIF(OptKeyQ(Inp,GUESS_OPTION,GUESS_NUGUESS))THEN
      Guess=GUESS_EQ_NUGUESS
    ELSEIF(OptKeyQ(Inp,GUESS_OPTION,GUESS_NEWGEOM))THEN
      Guess=GUESS_EQ_NEWGEOM
    ENDIF
    IF(Guess==GUESS_EQ_RESTART.OR. &
       Guess==GUESS_EQ_NUGUESS.OR. &
       Guess==GUESS_EQ_NEWGEOM )THEN

      ! Make sure we have the necessary information to restart.
      IF(.NOT.OptCharQ(Inp,RESTART_INFO,RestartHDF)) THEN
        CALL MondoHalt(PRSE_ERROR,'Restart requested, but no HDF file specified.')
      ENDIF

      ! Print something.
      CALL MondoLog(DEBUG_NONE, "ParseRestart", "restarting from hdf "//TRIM(RestartHDF))

      ! Check for relative path for HDF, and if relative, expand ...
      IF(SCAN(RestartHDF,'$') /= 0)THEN
        CALL MondoLog(DEBUG_NONE, "ParseRestart", "found variable name in path, expanding...")
        L1=INDEX(RestartHDF,'$')
        L2=INDEX(RestartHDF,'/')
        L3=LEN(RestartHDF)
        ! get the relative env name
        CALL GETENV(RestartHDF(L1+1:L2-1),CTmp)
        RestartHDF=RestartHDF(1:L1-1)//TRIM(CTmp)//RestartHDF(L2:L3)
        CALL MondoLog(DEBUG_NONE, "ParseRestart", "to "//TRIM(RestartHDF))
      ENDIF

      ! Check for absolute path
      IF(RestartHDF(1:1)/='/') THEN
        CALL MondoHalt(PRSE_ERROR,'Please use absolute path to the restart HDF file')
      ENDIF
      CALL New(RestartState,3)

      ! Open the old restart HDF file
      CALL MondoLog(DEBUG_NONE, "ParseRestart", "opening hdf file")
      HDF_CurrentID=OpenHDF(RestartHDF)
      CALL MondoLog(DEBUG_NONE, "ParseRestart", "done opening hdf file")

      ! Get the current state to restart from
      CALL Get(RestartState,'current_state')

      ! Now close the old file...
      CALL CloseHDF(HDF_CurrentID)
    ELSEIF(OptKeyQ(Inp,GUESS_OPTION,GUESS_CORE))THEN
      !CALL MondoHalt(PRSE_ERROR,'Core guess may crash the code for some simple systems.')
      Guess=GUESS_EQ_CORE
    ELSEIF(OptKeyQ(Inp,GUESS_OPTION,GUESS_SUPER))THEN
      Guess=GUESS_EQ_SUPR
    ELSE
      CALL MondoHalt(PRSE_ERROR,'No guess specified in input file')
    ENDIF
  END SUBROUTINE ParseRestart
  !===============================================================================================
  ! PARSE THE PRINT OUT OPTIONS AND LOAD THE GLOBAL PRINT FLAGS OBJECT.
  !===============================================================================================
  SUBROUTINE ParsePrintFlags(PFlags,Names,GeomPrint)
    TYPE(DEBG)         :: PFlags
    TYPE(FileNames)    :: Names
    CHARACTER(LEN=3)   :: GeomPrint
    !-----------------------------------------------------------------------------------------------
    IF(OptKeyQ(Inp,GLOBAL_DEBUG,DBG_NONE) )THEN
      PFlags%Key=DEBUG_NONE
    ELSEIF(OptKeyQ(Inp,GLOBAL_DEBUG,DBG_MEDIUM) )THEN
      PFlags%Key=DEBUG_MEDIUM
    ELSEIF(OptKeyQ(Inp,GLOBAL_DEBUG,DBG_MAXIMUM) )THEN
      PFlags%Key=DEBUG_MAXIMUM
    ELSE
      PFlags%Key=DEBUG_MINIMUM
    ENDIF
    ! And, by the way, set the global key for front end (FreeON)
    PrintFlags%Key=PFlags%Key
    !
    IF(OptKeyQ(Inp,GLOBAL_DEBUG,DBG_MATRICES) )THEN
      PFlags%Mat=DEBUG_MATRICES
    ELSEIF(OptKeyQ(Inp,GLOBAL_DEBUG,PLT_MATRICES) )THEN
      PFlags%Mat=PLOT_MATRICES
    ELSE
      PFlags%Mat=DEBUG_NONE
    ENDIF
    IF(OptKeyQ(Inp,GLOBAL_DEBUG,DBG_CHKSUMS))THEN
      PFlags%Chk=DEBUG_CHKSUMS
    ELSE
      PFlags%Chk=DEBUG_NONE
    ENDIF
    !
    IF(OptKeyQ(Inp,GLOBAL_DEBUG,DBG_MMA_STYLE) )THEN
      PFlags%Fmt=DEBUG_MMASTYLE
    ELSEIF(OptKeyQ(Inp,GLOBAL_DEBUG,DBG_FLT_STYLE) )THEN
      PFlags%Fmt=DEBUG_FLTSTYLE
    ELSE
      PFlags%Fmt=DEBUG_DBLSTYLE
    ENDIF

    IF(OptKeyQ(Inp,GLOBAL_DEBUG,DBG_PRT_INTS))THEN
      PFlags%Int=DEBUG_INTEGRAL
    ELSE
      PFlags%Int=DEBUG_NONE
    ENDIF

    IF(OptKeyQ(Inp,GLOBAL_DEBUG,DBG_PRT_SETS))THEN
      PFlags%Set=DEBUG_BASISSET
    ELSE
      PFlags%Set=DEBUG_NONE
    ENDIF

    IF(OptKeyQ(Inp,GLOBAL_DEBUG,DBG_GEOP_MIN))THEN
      PFlags%GeOp=DEBUG_GEOP_MIN
    ELSE IF(OptKeyQ(Inp,GLOBAL_DEBUG,DBG_GEOP_MAX))THEN
      PFlags%GeOp=DEBUG_GEOP_MAX
    ELSE
      PFlags%GeOp=DEBUG_NONE
    ENDIF

    IF(OptKeyQ(Inp,GLOBAL_DEBUG,DBG_PRT_MM))THEN
      PFlags%MM=DEBUG_MM
    ELSEIF(OptKeyQ(Inp,GLOBAL_DEBUG,DBG_PRT_FRC))THEN
      PFlags%MM=DEBUG_FRC
    ELSE
      PFlags%MM=DEBUG_NONE
    ENDIF

    IF(OptKeyQ(Inp,OUTPUT_OPTION,OUTPUT_PDB)) THEN
      GeomPrint='PDB'
      IF(INDEX(Names%GFile,'.')==0) &
           Names%GFile=TRIM(Names%GFile)//'.pdb'
    ELSE IF (OptKeyQ(Inp,OUTPUT_OPTION,OUTPUT_XYZ)) THEN
      GeomPrint='XYZ'
      IF(INDEX(Names%GFile,'.')==0) &
           Names%GFile=TRIM(Names%GFile)//'.xyz'
    ELSE IF (OptKeyQ(Inp,OUTPUT_OPTION,OUTPUT_XCD)) THEN
      GeomPrint='XSF'
      IF(INDEX(Names%GFile,'.')==0) &
           Names%GFile=TRIM(Names%GFile)//'.xsf'
    ELSE IF (OptKeyQ(Inp,OUTPUT_OPTION,OUTPUT_CIF)) THEN
      GeomPrint='CIF'
      IF(INDEX(Names%GFile,'.')==0) &
           Names%GFile=TRIM(Names%GFile)//'.cif'
    ELSE
      ! Default is xyz
      GeomPrint='XYZ'
      IF(INDEX(Names%GFile,'.')==0) &
           Names%GFile=TRIM(Names%GFile)//'.xyz'
    ENDIF

  END SUBROUTINE ParsePrintFlags

  SUBROUTINE ParseGradients(NSteps, Coordinates, Grad, DoGDIIS, SteepStep, CartesianOptimizerMethod)
    INTEGER :: NSteps, Coordinates, Grad, CartesianOptimizerMethod
    LOGICAL :: OneBase, DoGDIIS, SteepStep

    ! Default max geometry steps is 100
    IF(.NOT.OptIntQ(Inp,OPT_NSTEPS,NSteps))THEN
      CALL MondoLog(DEBUG_MAXIMUM, "ParseGradients", "using default NSteps")
      NSteps=100
    ENDIF

    ! Macro gradient options
    IF(OptKeyQ(Inp,GRADIENTS,GRAD_FORCE))THEN
      Grad=GRAD_ONE_FORCE
      NSteps=1
    ELSEIF(OptKeyQ(Inp,GRADIENTS,GRAD_DYNAMICS))THEN
      ! Do molecular dynamics
      Grad=GRAD_DO_DYNAMICS
      NSteps=1
    ELSEIF(OptKeyQ(Inp,GRADIENTS,GRAD_HYBRIDMC))THEN
      ! Do hybrid montecarlos / molecular dynamics
      Grad=GRAD_DO_HYBRIDMC
      NSteps=1
    ELSEIF(OptKeyQ(Inp,GRADIENTS,GRAD_OPTIMIZE))THEN
      ! Go downhill in energy
      Grad=GRAD_GO_DOWNHILL
    ELSEIF(OptKeyQ(Inp,GRADIENTS,GRAD_TS_SEARCH))THEN
      ! Transition state search
      Grad=GRAD_TS_SEARCH_NEB
    ELSEIF(OptKeyQ(Inp,GRADIENTS,GRAD_NHESSIAN))THEN
      ! Do numerical hessian, frequencies and thermostatistic
      Grad=GRAD_DO_NHESSIAN
    ELSE
      ! Single point energy only
      Grad=GRAD_NO_GRAD
      NSTeps=1
    ENDIF

    CALL MondoLog(DEBUG_MAXIMUM, "ParseGradients", "NSteps = "//TRIM(IntToChar(NSteps)))

    ! Use internal or Cartesian coordinates ?
    IF(OptKeyQ(Inp,GRADIENTS,GRAD_INTERNALS)) THEN
      ! Yes, use internals where available
      Coordinates=GRAD_INTS_OPT
    ELSE
      ! Default is Cartesians
      Coordinates=GRAD_CART_OPT
    ENDIF

    ! Use GDIIS in optimization ?
    IF(OptKeyQ(Inp,GRADIENTS,GRAD_GDIIS))THEN
      ! Yep
      DoGDIIS=.TRUE.
    ELSE
      ! Nope
      DoGDIIS=.FALSE.
    ENDIF

    ! Use approximate second order methods in optimization
    IF(OptKeyQ(Inp,GRADIENTS,GRAD_APPRX_HESS))THEN
      ! Yeah, but only if using internal coordinates
      SteepStep=.FALSE.
    ELSE
      ! No, gradients only
      SteepStep=.TRUE.
    ENDIF

    ! In case of cartesian optimizer, which method to use?
    IF(OptKeyQ(Inp, GRADIENTS, GRAD_OPTIMIZE_SD)) THEN
      CALL MondoLog(DEBUG_NONE, "ParseGradients", "cartesian optimizer method = "//TRIM(GRAD_OPTIMIZE_SD))
      CartesianOptimizerMethod = GRAD_OPTIMIZE_SD_VALUE
    ELSEIF(OptKeyQ(Inp, GRADIENTS, GRAD_OPTIMIZE_CG)) THEN
      CALL MondoLog(DEBUG_NONE, "ParseGradients", "cartesian optimizer method = "//TRIM(GRAD_OPTIMIZE_CG))
      CartesianOptimizerMethod = GRAD_OPTIMIZE_CG_VALUE
    ELSEIF(OptKeyQ(Inp, GRADIENTS, GRAD_OPTIMIZE_GLOBAL_CG)) THEN
      CALL MondoLog(DEBUG_NONE, "ParseGradients", "cartesian optimizer method = "//TRIM(GRAD_OPTIMIZE_GLOBAL_CG))
      CartesianOptimizerMethod = GRAD_OPTIMIZE_GLOBAL_CG_VALUE
    ELSEIF(OptKeyQ(Inp, GRADIENTS, GRAD_OPTIMIZE_LBFGS)) THEN
      CALL MondoLog(DEBUG_NONE, "ParseGradients", "cartesian optimizer method = "//TRIM(GRAD_OPTIMIZE_LBFGS))
      CartesianOptimizerMethod = GRAD_OPTIMIZE_LBFGS_VALUE
    ELSEIF(OptKeyQ(Inp, GRADIENTS, GRAD_OPTIMIZE_GLOBAL_LBFGS)) THEN
      CALL MondoLog(DEBUG_NONE, "ParseGradients", "cartesian optimizer method = "//TRIM(GRAD_OPTIMIZE_GLOBAL_LBFGS))
      CartesianOptimizerMethod = GRAD_OPTIMIZE_GLOBAL_LBFGS_VALUE
    ELSE
      CALL MondoLog(DEBUG_NONE, "ParseGradients", "cartesian optimizer method = "//TRIM(GRAD_OPTIMIZE_SD))
      CartesianOptimizerMethod = GRAD_OPTIMIZE_SD_VALUE
    ENDIF

  END SUBROUTINE ParseGradients

  SUBROUTINE ParseNEB(NEBSteepAlpha, NEBSteepMaxMove, NEBSpring, NEBClimb, &
                      DoubleNudge, EndPts, ReactantsFile, ProductsFile, &
                      NEBReactantEnergy, NEBProductEnergy)

    REAL(DOUBLE)       :: NEBSpring, NEBSteepAlpha, NEBSteepMaxMove, &
                          NEBReactantEnergy, NEBProductEnergy
    Logical            :: NEBClimb, DoubleNudge
    INTEGER            :: EndPts
    CHARACTER(Len=DCL) :: ReactantsFile, ProductsFile

    IF(.NOT. OptDblQ(Inp, NEB_STEEP_ALPHA, NEBSteepAlpha)) THEN
      NEBSteepAlpha = 1.0D-2
    ENDIF
    NEBSteepAlpha = NEBSteepAlpha*AngstromsToAU*AngstromsToAU/eV2au
    CALL MondoLog(DEBUG_NONE, "ParseNEB", "using NEBSteepAlpha = "//TRIM(DblToChar(NEBSteepAlpha*AUToAngstroms*AUToAngstroms/au2eV))//" A^2/eV")

    IF(.NOT. OptDblQ(Inp, NEB_STEEP_MAX_MOVE, NEBSteepMaxMove)) THEN
      NEBSteepMaxMove = 2.0D-1
    ENDIF
    NEBSteepMaxMove = NEBSteepMaxMove*AngstromsToAU
    CALL MondoLog(DEBUG_NONE, "ParseNEB", "using NEBSteepMaxMove = "//TRIM(DblToChar(NEBSteepMaxMove*AUToAngstroms))//" A")

    ! Set the spring constant between NEB images
    IF(.NOT.OptDblQ(Inp,NEB_SPRING,NEBSpring))THEN
      NEBSpring = 2.0D-3
    ENDIF
    NEBSpring = NEBSpring*eV2au/AngstromsToAU/AngstromsToAU
    CALL MondoLog(DEBUG_NONE, "ParseNEB", "using NEBSpring = "//TRIM(DblToChar(NEBSpring*au2eV/AUToAngstroms/AUToAngstroms))//" eV/A^2")

    ! Parse energies of reactant and product configurations.
    IF(.NOT.OptDblQ(Inp, NEB_REACTANT_ENERGY, NEBReactantEnergy)) THEN
      CALL Halt("Missing NEBReactantEnergy option. I need the energy of the reactant")
    ELSE
      NEBReactantEnergy = NEBReactantEnergy*eV2au
      CALL MondoLog(DEBUG_NONE, "ParseNEB", "reactant energy = "//TRIM(DblToChar(NEBReactantEnergy*au2eV))//" eV")
    ENDIF

    IF(.NOT.OptDblQ(Inp, NEB_PRODUCT_ENERGY, NEBProductEnergy)) THEN
      CALL Halt("Missing NEBProductEnergy option. I need the energy of the product")
    ELSE
      NEBProductEnergy = NEBProductEnergy*eV2au
      CALL MondoLog(DEBUG_NONE, "ParseNEB", "product energy = "//TRIM(DblToChar(NEBProductEnergy*au2eV))//" eV")
    ENDIF

    ! Use the climbing image?
    IF(OptKeyQ(Inp,NEB_OPTION,NEB_CLIMB))THEN
      CALL MondoLog(DEBUG_NONE, "ParseNEB", "using climbing image")
      NEBClimb=.TRUE.
    ELSE
      NEBClimb=.FALSE.
    ENDIF

    IF(OptKeyQ(Inp, NEB_OPTION, NEB_DOUBLE_NUDGE)) THEN
      CALL MondoLog(DEBUG_NONE, "ParseNEB", "double nudging")
      DoubleNudge = .TRUE.
    ELSE
      DoubleNudge = .FALSE.
    ENDIF

    IF(OptKeyQ(Inp,NEB_OPTION,NEB_READ_HDF))THEN
      EndPts=ENDPOINTS_FROM_HDF
      ! Read in the reactants file name
      IF(.NOT.OptCharQ(Inp,NEB_REACTANTS_HDF,ReactantsFile)) THEN
        CALL MondoHalt(PRSE_ERROR,' NEB reactants file missing from input ')
      ENDIF

      ! Read in the products file name
      IF(.NOT.OptCharQ(Inp,NEB_PRODUCTS_HDF,ProductsFile)) THEN
        CALL MondoHalt(PRSE_ERROR,' NEB products file missing from input ')
      ENDIF
    ELSE
      EndPts=ENDPOINTS_FROM_INP
    ENDIF
  END SUBROUTINE ParseNEB

  SUBROUTINE ParseOptimizer(ConjugateGradientMaxMove, ConjugateGradientAlpha)
    REAL(DOUBLE) :: ConjugateGradientMaxMove, ConjugateGradientAlpha

    IF(.NOT. OptDblQ(Inp, CG_MAX_MOVE, ConjugateGradientMaxMove)) THEN
      ConjugateGradientMaxMove = 0.2D0
    ENDIF
    ConjugateGradientMaxMove = ConjugateGradientMaxMove*AngstromsToAU
    CALL MondoLog(DEBUG_NONE, "ParseOptimizer", "using ConjugateGradientMaxMove = "//TRIM(DblToChar(ConjugateGradientMaxMove*AUToAngstroms))//" A")

    IF(.NOT. OptDblQ(Inp, CG_STEPSIZE, ConjugateGradientAlpha)) THEN
      ! This default depends on the chosen accuracy, i.e. how many digits we
      ! expect to have in the force.
      ConjugateGradientAlpha = 1.0D-4
    ENDIF
    CALL MondoLog(DEBUG_NONE, "ParseOptimizer", "using ConjugateGradientAlpha = "//TRIM(DblToChar(ConjugateGradientAlpha)))

  END SUBROUTINE ParseOptimizer

  SUBROUTINE ParseSCF(MinSCF,MaxSCF)
    INTEGER :: MinSCF,MaxSCF

    ! Parse for Min and Max SCF
    IF(.NOT. OptIntQ(Inp,Op_MinSCF,MinSCF)) THEN
      MinSCF = 0
    ENDIF
    IF(.NOT. OptIntQ(Inp,Op_MaxSCF,MaxSCF)) THEN
      MaxSCF = HAVE_MAX_SCF
    ENDIF
  END SUBROUTINE ParseSCF

  SUBROUTINE ParseRQI(RQIGuess,MaxRQI)
    INTEGER           :: MaxRQI
    CHARACTER(Len=DCL) :: GuessDCL
    CHARACTER(LEN=*) :: RQIGuess
    IF(.NOT.OptIntQ(Inp,RQICycles,MaxRQI)) THEN
      MaxRQI=30
    ENDIF
    IF(.NOT.OptCharQ(Inp,'RQIGuess',GuessDCL)) THEN
       GuessDCL='Koopmans'
    ENDIF
    RQIGuess=ADJUSTL(GuessDCL)
    CALL MondoLog(DEBUG_NONE, "ParseRQI", "Guess = "//TRIM(RQIGuess))

  END SUBROUTINE ParseRQI
  !===============================================================================================
  !
  !===============================================================================================
  SUBROUTINE ParseMISC(Pressure, UseLennardJones, LennardJonesR0, LennardJonesEpsilon)
    REAL(DOUBLE), INTENT(INOUT) :: Pressure
    LOGICAL, INTENT(INOUT)      :: UseLennardJones
    REAL(DOUBLE), INTENT(INOUT) :: LennardJonesR0
    REAL(DOUBLE), INTENT(INOUT) :: LennardJonesEpsilon

    ! Parse the Pressure, used in Optimizer, MD and MC routines
    IF(.NOT. OptDblQ(Inp,Op_Pressure, Pressure)) THEN
      Pressure = 0.0D0
    ENDIF

    ! Convert to Atomic Units
    Pressure = Pressure*GPaToAU

    IF(Pressure .NE. Zero) THEN
      CALL MondoLog(DEBUG_NONE, "ParseMISC", "Pressure = " &
        //TRIM(FltToChar(Pressure))//", AU")
      CALL MondoLog(DEBUG_NONE, "ParseMISC", "Pressure = " &
        //TRIM(FltToChar(Pressure/GPaToAU))//" GPa")
    ENDIF

    IF(.NOT.OptIntQ(Inp, RECYCLE_HDF_OPTION, RecycleHDF)) THEN
      RecycleHDF = 20
    ENDIF

    IF(.NOT.OptLogicalQ(Inp, CLEAN_SCRATCH_OPTION, doCleanScratch)) THEN
      doCleanScratch = .TRUE.
    ENDIF

    IF(doCleanScratch) THEN
      CALL MondoLog(DEBUG_NONE, "ParseMISC", "cleaning out scratch")
    ELSE
      CALL MondoLog(DEBUG_NONE, "ParseMISC", "I will not clean out scratch")
    ENDIF

    IF(.NOT.OptLogicalQ(Inp, USE_LENNARD_JONES, UseLennardJones)) THEN
      UseLennardJones = .FALSE.
    ENDIF

    IF(UseLennardJones) THEN
      ! J. Chem. Phys. 89, 4535 (1988)
      LennardJonesR0 = 3.761*AngstromsToAU
      LennardJonesEpsilon = 99.2*inverseCM2au

      ! For debugging.
      !LennardJonesR0 = 4*AngstromsToAU
      !LennardJonesEpsilon = AUToAngstroms**2

      CALL MondoLog(DEBUG_NONE, "ParseMISC", "using Lennard-Jones potential with")
      CALL MondoLog(DEBUG_NONE, "ParseMISC", "  epsilon = "//TRIM(FltToChar(LennardJonesEpsilon*au2eV))//" eV")
      CALL MondoLog(DEBUG_NONE, "ParseMISC", "  R0      = "//TRIM(FltToChar(LennardJonesR0*AUToAngstroms))//" A")
    ENDIF

  END SUBROUTINE ParseMISC
END MODULE ParseOptions
