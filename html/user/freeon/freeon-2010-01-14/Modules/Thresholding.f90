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
!    COMPUTE AND SET THRESHOLDS AND INTERMEDIATE VALUES USED IN THRESHOLDING
!    Author: Matt Challacombe and C.J. Tymczak
!------------------------------------------------------------------------------
MODULE Thresholding
  USE DerivedTypes
  USE GlobalScalars
  USE GlobalCharacters
  USE GlobalObjects
  USE InOut
  USE SpecFun
  USE Parse
  USE McMurchie
#ifdef MMech
  USE Mechanics
#endif
!-------------------------------------------------
!  Primary thresholds
   TYPE(TOLS), SAVE :: Thresholds
!-------------------------------------------------------------------------
! Intermediate thresholds
  REAL(DOUBLE), SAVE                   :: MinZab,MinXab
  REAL(DOUBLE), SAVE                   :: AtomPairDistanceThreshold  ! Atom pairs
  REAL(DOUBLE), SAVE                   :: PrimPairDistanceThreshold  ! Prim pairs
  REAL(DOUBLE),PARAMETER               :: GFactor=0.90D0
  REAL(DOUBLE),DIMENSION(0:HGEll),SAVE :: AACoef
  CONTAINS
!====================================================================================================
!    Set and load global threholding parameters
!====================================================================================================
     SUBROUTINE SetThresholds(Base)
         INTEGER          :: NExpt,Lndx
         TYPE(DBL_VECT)   :: Expts
         CHARACTER(LEN=*) :: Base
!        Get the primary thresholds
         CALL Get(Thresholds,Tag_O=Base)
#ifdef MMech
         IF(HasQM())THEN
#endif
!        Get distribution exponents
         CALL Get(NExpt,'nexpt',Tag_O=Base)
         CALL Get(Lndx ,'lndex',Tag_O=Base)
         CALL New(Expts,NExpt)
         CALL Get(Expts,'dexpt',Tag_O=Base)
!        MinZab=MinZa+MinZb, MinZa=MinZb
         MinZab=Expts%D(1)
!        MinXab=MinZa*MinZb/(MinZa+MinZb)=MinZab/4
         MinXab=MinZab/Four
!        Delete Exponents
         CALL Delete(Expts)
!        Set Atom-Atom thresholds
         CALL SetAtomPairThresh(Thresholds%Dist)
!        Set Prim-Prim thresholds
         CALL SetPrimPairThresh(Thresholds%Dist)
#ifdef MMech
         ENDIF
#endif
     END SUBROUTINE SetThresholds
!====================================================================================================
!    Preliminary worst case thresholding at level of atom pairs
!    Using Exp[-MinXab*|A-B|^2] = Tau
!====================================================================================================
     SUBROUTINE SetAtomPairThresh(Tau)
        REAL(DOUBLE),INTENT(IN) :: Tau
        AtomPairDistanceThreshold=-LOG(Tau)/MinXab
     END SUBROUTINE SetAtomPairThresh
!
     FUNCTION TestAtomPair(Pair,Box_O)
        LOGICAL                   :: TestAtomPair
        TYPE(AtomPair)            :: Pair
        TYPE(BBox),OPTIONAL       :: Box_O
        IF(Pair%AB2>AtomPairDistanceThreshold) THEN
           TestAtomPair = .FALSE.
        ELSE
           TestAtomPair = .TRUE.
           IF(PRESENT(Box_O)) &
              TestAtomPair=BoxPairOverlap(Pair,Box_O)
        ENDIF
     END FUNCTION TestAtomPair
     !==================================================================================================
     ! Modified Miguel Gomez' Ray-AABB test (Gamasutra '99) to work for Cylinder-AABB
     ! for Ray=Point, uses A Simple Method for Box-Sphere Intersection Testing, Graphics Gems, pp. 247-250
     !==================================================================================================
     FUNCTION BoxPairOverlap(Pair,Box)
       LOGICAL                   :: BoxPairOverlap
       INTEGER                   :: I
       TYPE(AtomPair)            :: Pair
       TYPE(BBox),OPTIONAL       :: Box
       REAL(DOUBLE)              :: Ext,R,TMag,LMag,HL,d,s
       REAL(DOUBLE),DIMENSION(3) :: RayAB,LHat,T,THat
       !----------------------------------------------------------------
       BoxPairOverlap=.FALSE.
       IF(Pair%AB2>1.D-20)THEN ! This is the Cylinder-Box test
          ! Solve  Exp[-MinXab*|A-B|^2]*Exp[-MinZab*Ext^2]<Tau
          Ext=SQRT(MAX(Zero,(PrimPairDistanceThreshold-MinXab*Pair%AB2)/MinZab))
          ! Ray from A to B
          RayAB=Pair%A-Pair%B
          ! Length of RayAB
          LMag=SQRT(RayAB(1)**2+RayAB(2)**2+RayAB(3)**2)
          ! AB unit vector
          LHat=RayAB/LMag
          ! Half length
          HL=Half*LMag
          ! Distance from Box center to RayAB midpoint
          T=Box%Center-(Pair%A+Pair%B)*Half
          TMag=SQRT(T(1)**2+T(2)**2+T(3)**2)
          !
          IF(TMag==Zero)THEN
             BoxPairOverlap=.TRUE.
             RETURN
          ENDIF
          ! Unit vector in direction T
          THat=T/TMag
          ! Recompute T to change test from Ray-Box to Cylinder-Box
          T=THat*MAX(Zero,TMag-Ext)
          ! Seperating axis tests
          DO I=1,3
             IF(ABS(T(I))>Box%Half(I)+HL*ABS(LHat(I)))RETURN
          ENDDO
          ! Cross product tests
          r=Box%Half(2)*ABS(LHat(3))+Box%Half(3)*ABS(LHat(2))
          IF(ABS(T(2)*LHat(3)-T(3)*LHat(2))>r)RETURN
          r=Box%Half(1)*ABS(LHat(3))+Box%Half(3)*ABS(LHat(1))
          IF(ABS(T(3)*LHat(1)-T(1)*LHat(3))>r)RETURN
          r=Box%Half(1)*ABS(LHat(2))+Box%Half(2)*ABS(LHat(1))
          IF(ABS(T(1)*LHat(2)-T(2)*LHat(1))>r)RETURN
       ELSE ! Sphere-AABB from Graphics Gems
          d=Zero
          DO I=1,3
             IF(Pair%A(I)<Box%BndBox(I,1))d=d+(Pair%A(I)-Box%BndBox(I,1))**2
             IF(Pair%A(I)>Box%BndBox(I,2))d=d+(Pair%A(I)-Box%BndBox(I,2))**2
          ENDDO
          ! PrimPairDistanceThreshold is the squared radius of the sphere
          IF(d>PrimPairDistanceThreshold)RETURN
       ENDIF
       BoxPairOverlap=.TRUE.
     END FUNCTION BoxPairOverlap
!====================================================================================================
!    Secondary thresholding of primitive pairs using current
!    value of Xab and Exp[-Xab |A-B|^2] = Tau
!====================================================================================================
     SUBROUTINE SetPrimPairThresh(Tau)
        REAL(DOUBLE),INTENT(IN) :: Tau
        PrimPairDistanceThreshold=-LOG(Tau)
     END SUBROUTINE SetPrimPairThresh
!
     FUNCTION TestPrimPair(Xi,Dist)
        LOGICAL                :: TestPrimPair
        TYPE(AtomPair)         :: Pair
        REAL(DOUBLE)           :: Xi,Dist
        IF(Xi*Dist>PrimPairDistanceThreshold) THEN
           TestPrimPair = .FALSE.
        ELSE
           TestPrimPair = .TRUE.
        ENDIF
     END FUNCTION TestPrimPair




!===================================================================================================
!     Simple expressions to determine largest extent R for a distribution rho_LMN(R)
!     Using a new Tighter Gramers like bound
!===================================================================================================
      FUNCTION Extent2(Ell,Zeta,HGTF,Tau_O,ExtraEll_O,Potential_O) RESULT (R)
       INTEGER                         :: Ell,L,M,N,LMN
       REAL(DOUBLE)                    :: Zeta , TmpExt
       REAL(DOUBLE),DIMENSION(:)       :: HGTF
       REAL(DOUBLE),OPTIONAL           :: Tau_O
       INTEGER,OPTIONAL                :: ExtraEll_O
       LOGICAL,OPTIONAL                :: Potential_O
       LOGICAL                         :: Potential
       INTEGER                         :: ExtraEll,TotEll
       REAL(DOUBLE)                    :: R,Tau,Coef,ZetaFac,MinMax,ScaledTau,DelR,SqrtW,Fun,dFun

!      Quick turn around for nuclei
       IF(Zeta==NuclearExpnt)THEN
          R=1.D-10
          RETURN
       ENDIF
!      Misc options.
       IF(PRESENT(ExtraEll_O))THEN
          ExtraEll=ExtraEll_O
       ELSE
          ExtraEll=0
       ENDIF
       IF(PRESENT(Tau_O)) THEN
          Tau=Tau_O
       ELSE
          Tau=Thresholds%Dist
       ENDIF
       IF(PRESENT(Potential_O)) THEN
          Potential=Potential_O
       ELSE
          Potential=.FALSE.
       ENDIF
       TotEll = Ell+ExtraEll
!
       IF(Potential) THEN
          Coef      = NodeWeight(Ell,Zeta,HGTF)
          R         = Zero
          SqrtW     = SQRT(Zeta)
          DelR      = SqrtW
          ScaledTau = Tau/(Coef+SMALL_DBL)
          DO L=1,50
             Fun = EXP(RErfc(SqrtW*R,TotEll))
             IF(Fun > ScaledTau*(R**(TotEll+1))) THEN
                R = R+DelR
             ELSE
                DelR = DelR*Half
                R = R-DelR
             ENDIF
          ENDDO
!          WRITE(*,*) 'R    = ',R,Coef*EXP(RErfc(SqrtW*R,TotEll))/(R**(TotEll+1))
!          IF(Ell==0) STOP
       ELSE
          IF(Ell==0) THEN
             Coef      = ABS(HGTF(1))*AACoef(ExtraEll)
             ScaledTau = Tau/(Coef+SMALL_DBL)
             R         = SQRT(MAX(SMALL_DBL,-LOG(ScaledTau)/Zeta))
          ELSE
             Coef = Zero
             DO L=0,Ell
                DO M=0,Ell-L
                   DO N=0,Ell-L-M
                      LMN=LMNDex(L,M,N)
                      ZetaFac = SQRT(Zeta**DBLE(L+M+N))
                      MinMax  = AACoef(L+ExtraEll)*AACoef(M)*AACoef(N)
                      MinMax  = MAX(MinMax,AACoef(L)*AACoef(M+ExtraEll)*AACoef(N))
                      MinMax  = MAX(MinMax,AACoef(L)*AACoef(M)*AACoef(N+ExtraEll))
                      Coef    = Coef + ZetaFac*ABS(HGTF(LMN))*MinMax
                   ENDDO
                ENDDO
             ENDDO
             ScaledTau = Tau/(Coef+SMALL_DBL)
             R         = SQRT(MAX(SMALL_DBL,-LOG(Tau/Coef)/(GFactor*Zeta)))
          ENDIF
       ENDIF

!!$
!!$       IF( R > 1D1 * TmpExt .OR. TmpExt > 1D1 * R ) THEN
!!$
!!$          WRITE(*,*)'--------------------------------------------'
!!$          WRITE(*,*)' Ell  = ',ell
!!$          WRITE(*,*)' Zeta = ',Zeta
!!$
!!$
!!$          WRITE(*,*)' HGTF = ',Coef
!!$          WRITE(*,*)' R = ',R
!!$          WRITE(*,*)' T = ',TmpExt
!!$
!!$          TmpExt=Extent3(Ell,Zeta,HGTF,Tau_O,ExtraEll_O,Potential_O)
!!$          WRITE(*,*)' T3= ',TmpExt
!!$
!!$          WRITE(*,*)' ScaledTau = ',ScaledTau
!!$          WRITE(*,*)' -LOG(Tau/Coef)/(GFactor*Zeta)) ',-LOG(Tau/Coef)/(GFactor*Zeta)
!!$
!!$!          STOP
!!$
!!$
!!$       ENDIF
!
     END FUNCTION Extent2
!===================================================================================================
!     Simple expressions to determine largest extent R for a distribution rho_LMN(R)
!     outside of which its value at a point is less than Tau (default) or outside
!     of which the error made using the classical potential is less than Tau (Potential option)
!===================================================================================================
     FUNCTION Extent(Ell,Zeta,HGTF,Tau_O,ExtraEll_O,Potential_O) RESULT (R)
       INTEGER                         :: Ell
       REAL(DOUBLE)                    :: Zeta
       REAL(DOUBLE),DIMENSION(:)       :: HGTF
       REAL(DOUBLE),OPTIONAL           :: Tau_O
       INTEGER,OPTIONAL                :: ExtraEll_O
       LOGICAL,OPTIONAL                :: Potential_O
       INTEGER                         :: L,M,N,Lp,Mp,Np,LMN,ExtraEll
       LOGICAL                         :: Potential
       REAL(DOUBLE)                    :: Tau,T,R,CramCo,MixMax,ScaledTau,ZetaHalf,HGInEq,TMP
       REAL(DOUBLE),PARAMETER          :: K3=1.09D0**3
       REAL(DOUBLE),DIMENSION(0:12),PARAMETER :: Fact=(/1D0,1D0,2D0,6D0,24D0,120D0,      &
                                                        720D0,5040D0,40320D0,362880D0,   &
                                                        3628800D0,39916800D0,479001600D0/)
!------------------------------------------------------------------------------------------------------------------
       ! Quick turn around for nuclei
       IF(Zeta>=(NuclearExpnt-1D1))THEN
          R=1.D-10
          RETURN
       ENDIF
       ! Misc options....
       IF(PRESENT(ExtraEll_O))THEN
          ExtraEll=ExtraEll_O
       ELSE
          ExtraEll=0
       ENDIF
       IF(PRESENT(Tau_O)) THEN
          Tau=Tau_O
       ELSE
          Tau=Thresholds%Dist
       ENDIF
       IF(PRESENT(Potential_O)) THEN
          Potential=Potential_O
       ELSE
          Potential=.FALSE.
       ENDIF
       ! Spherical symmetry check
       IF(Ell+ExtraEll==0)THEN
          ! For S functions we can use tighter bounds (no halving of exponents)
          ScaledTau=Tau/(ABS(HGTF(1))+SMALL_DBL)
          IF(Potential)THEN
             ! R is the boundary of the quantum/classical potential approximation
             ! HGTF(1)*Int dr [(Pi/Zeta)^3/2 delta(r)-Exp(-Zeta r^2)]/|r-R| < Tau
             R=PFunk(Zeta,ScaledTau)
          ELSE
             ! Gaussian solution gives HGTF(1)*Exp[-Zeta*R^2] <= Tau
             R=SQRT(MAX(SMALL_DBL,-LOG(ScaledTau)/Zeta))
          ENDIF
       ELSE
          ! Universal prefactor based on Cramers inequality:
          ! H_n(t) < K 2^(n/2) SQRT(n!) EXP(t^2/2), with K=1.09
          CramCo=-BIG_DBL
          DO L=0,Ell
             DO M=0,Ell-L
                DO N=0,Ell-L-M
                   LMN=LMNDex(L,M,N)
                   MixMax=Fact(L+ExtraEll)*Fact(M)*Fact(N)
                   MixMax=MAX(MixMax,Fact(L)*Fact(M+ExtraEll)*Fact(N))
                   MixMax=MAX(MixMax,Fact(L)*Fact(M)*Fact(N+ExtraEll))
                   HGInEq=SQRT(MixMax*(Two*Zeta)**(L+M+N+ExtraEll))*HGTF(LMN)
                   CramCo=MAX(CramCo,ABS(HGInEq))
                ENDDO
             ENDDO
          ENDDO
          ! Now we just use expresions based on spherical symmetry but with half the exponent ...
          ZetaHalf=Half*Zeta
          ! and the threshold rescaled by the Cramer coefficient:
          ScaledTau=Tau/CramCo
          IF(Potential)THEN
             ! R is the boundary of the quantum/classical potential approximation
             ! CCo*Int dr [(2 Pi/Zeta)^3/2 delta(r)-Exp(-Zeta/2 r^2)]/|r-R| < Tau
             R=PFunk(ZetaHalf,ScaledTau)
          ELSE
             ! Gaussian solution gives CCo*Exp[-Zeta*R^2/2] <= Tau
             R=SQRT(MAX(SMALL_DBL,-LOG(ScaledTau)/ZetaHalf))
          ENDIF
       ENDIF
     END FUNCTION Extent
!===================================================================================================
!     Simple expressions to determine largest extent R for a distribution rho_LMN(R)
!     outside of which its value at a point is less than Tau (default) or outside
!     of which the error made using the classical potential is less than Tau (Potential option)
!===================================================================================================
     FUNCTION Extent3(Ell,Zeta,HGTF,Tau_O,ExtraEll_O,Potential_O) RESULT (R)
       INTEGER                         :: Ell
       REAL(DOUBLE)                    :: Zeta
       REAL(DOUBLE),DIMENSION(:)       :: HGTF
       REAL(DOUBLE),OPTIONAL           :: Tau_O
       INTEGER,OPTIONAL                :: ExtraEll_O
       LOGICAL,OPTIONAL                :: Potential_O
       INTEGER                         :: L,M,N,Lp,Mp,Np,LMN,ExtraEll
       LOGICAL                         :: Potential
       REAL(DOUBLE)                    :: Tau,T,R,CramCo,MixMax,ScaledTau,ZetaHalf,HGInEq,TMP
       REAL(DOUBLE),PARAMETER          :: K3=1.09D0**3
       REAL(DOUBLE),DIMENSION(0:12),PARAMETER :: Fact=(/1D0,1D0,2D0,6D0,24D0,120D0,      &
                                                        720D0,5040D0,40320D0,362880D0,   &
                                                        3628800D0,39916800D0,479001600D0/)
!------------------------------------------------------------------------------------------------------------------
       ! Quick turn around for nuclei
       IF(Zeta>=(NuclearExpnt-1D1))THEN
          R=1.D-10
          RETURN
       ENDIF
       ! Misc options....
       IF(PRESENT(ExtraEll_O))THEN
          ExtraEll=ExtraEll_O
       ELSE
          ExtraEll=0
       ENDIF
       IF(PRESENT(Tau_O)) THEN
          Tau=Tau_O
       ELSE
          Tau=Thresholds%Dist
       ENDIF
       IF(PRESENT(Potential_O)) THEN
          Potential=Potential_O
       ELSE
          Potential=.FALSE.
       ENDIF
       ! Spherical symmetry check
       IF(Ell+ExtraEll==0)THEN
          ! For S functions we can use tighter bounds (no halving of exponents)
          ScaledTau=Tau/(ABS(HGTF(1))+SMALL_DBL)
          IF(Potential)THEN
             ! R is the boundary of the quantum/classical potential approximation
             ! HGTF(1)*Int dr [(Pi/Zeta)^3/2 delta(r)-Exp(-Zeta r^2)]/|r-R| < Tau
             R=PFunk(Zeta,ScaledTau)
          ELSE
             ! Gaussian solution gives HGTF(1)*Exp[-Zeta*R^2] <= Tau
             R=SQRT(MAX(SMALL_DBL,-LOG(ScaledTau)/Zeta))
          ENDIF
       ELSE
          ! Universal prefactor based on Cramers inequality:
          ! H_n(t) < K 2^(n/2) SQRT(n!) EXP(t^2/2), with K=1.09
          CramCo=-BIG_DBL
          DO L=0,Ell
             DO M=0,Ell-L
                DO N=0,Ell-L-M
                   LMN=LMNDex(L,M,N)
                   MixMax=Fact(L+ExtraEll)*Fact(M)*Fact(N)
                   MixMax=MAX(MixMax,Fact(L)*Fact(M+ExtraEll)*Fact(N))
                   MixMax=MAX(MixMax,Fact(L)*Fact(M)*Fact(N+ExtraEll))
                   HGInEq=SQRT(MixMax*(Two*Zeta)**(L+M+N+ExtraEll))*HGTF(LMN)
                   CramCo=MAX(CramCo,ABS(HGInEq))
                ENDDO
             ENDDO
          ENDDO
          ! Now we just use expresions based on spherical symmetry but with half the exponent ...
          ZetaHalf=Half*Zeta
          ! and the threshold rescaled by the Cramer coefficient:
          ScaledTau=Tau/CramCo
          IF(Potential)THEN
             ! R is the boundary of the quantum/classical potential approximation
             ! CCo*Int dr [(2 Pi/Zeta)^3/2 delta(r)-Exp(-Zeta/2 r^2)]/|r-R| < Tau
             R=PFunk(ZetaHalf,ScaledTau)
          ELSE
             ! Gaussian solution gives CCo*Exp[-Zeta*R^2/2] <= Tau
             WRITE(*,*)' 3 Tau    = ',Tau
             WRITE(*,*)' 3 CramCo = ',CramCo
             WRITE(*,*)' 3 ScaledTau= ',ScaledTau
             WRITE(*,*)' 3 ZetaHalf = ',ZetaHalf
             WRITE(*,*)' 3 LOGLOG   = ',-LOG(ScaledTau)/ZetaHalf

             R=SQRT(MAX(SMALL_DBL,-LOG(ScaledTau)/ZetaHalf))
          ENDIF
       ENDIF
     END FUNCTION Extent3

!====================================================================================================
!    COMPUTE THE R THAT SATISFIES (Pi/z)^(3/2) Erfc[Sqrt[z]*R]/R < Tau
!    Note: Funk is its own reward; so make my funk the p-funk.
!====================================================================================================
     FUNCTION PFunk(Zeta,Tau) RESULT(R)
        REAL(DOUBLE)  :: Tau,Zeta,SqZ,NewTau,Val,Ec,R,BisR,DelR,X,CTest
        INTEGER       :: J,K
        LOGICAL :: pp
!----------------------------------------------------------------------
        SqZ=SQRT(Zeta)
        NewTau=Tau*(Zeta/Pi)**(1.5D0)
        ! Quick check for max resolution of Erfc approx
        IF(1D-13*SqZ/Erf_Switch>NewTau)THEN
           R=Erf_Switch/SqZ
           RETURN
        ELSEIF(NewTau>1D20)THEN
           R=Zero
           RETURN
        ENDIF
        ! Ok, within resolution--do root finding...
        DelR=Erf_Switch/SqZ
        BisR=Zero
        DO K=1,100
           ! New midpoint
           R=BisR+DelR
           X=SqZ*R
           ! Compute Erfc[Sqrt(Zeta)*R]https://www.blogger.com/comment.g?blogID=18675105&postID=3471233482324285043
           IF(X>=Erf_Switch)THEN
              Ec=Zero
           ELSE
              J=AINT(X*Erf_Grid)
              Ec=One-(Erf_0(J)+X*(Erf_1(J)+X*(Erf_2(J)+X*(Erf_3(J)+X*Erf_4(J)))))
           ENDIF
           Val=Ec/R
           CTest=(Val-NewTau)/Tau
           ! Go for relative error to get smoothness, but bail if
           ! absolute accuracy of erf interpolation is exceeded
           IF(ABS(CTest)<1D-4.OR.Tau*ABS(CTest)<1.D-12)THEN
              ! Converged
              RETURN
           ELSEIF(DelR<1D-40)THEN
              ! This is unacceptable
              EXIT
           ENDIF
           ! If still to the left, increment bisection point
           IF(CTest>Zero)BisR=R
           DelR=Half*DelR
        ENDDO
        CALL Halt(' Failed to converge in P-Funk: '//Rtrn &
                   //'Tau = '//TRIM(DblToShrtChar(NewTau))//Rtrn &
                   //' CTest = '//TRIM(DblToShrtChar(CTest))//Rtrn &
                   //' Zeta = '//TRIM(DblToShrtChar(Zeta))//Rtrn &
                   //' R = '//TRIM(DblToShrtChar(R))//Rtrn &
                   //' Ec = '//TRIM(DblToShrtChar(Ec))//Rtrn &
                   //' dR = '//TRIM(DblToShrtChar(DelR))//Rtrn &
                   //' SqZ*R = '//TRIM(DblToMedmChar(X)))
     END FUNCTION PFunk



!===================================================================================================
!    Used to set up our new Cramer's like bound
!===================================================================================================
     SUBROUTINE SetAACoef()
       REAL(DOUBLE)  :: X1,X2,X3,F1,F2,F3
       INTEGER       :: L,I
!       Solve for AACoef
       AACoef(0)= 1.D0
       DO L=1,HGEll
          X1 = SQRT(0.499D0*DBLE(L)/(1.D0-GFactor))
          X2 = 2.D0*X1
          F1 = Hermite(X1,L+1)+2.D0*GFactor*X1*Hermite(X1,L)
          F2 = Hermite(X2,L+1)+2.D0*GFactor*X2*Hermite(X2,L)
          IF(SIGN(1.D0,F1)==SIGN(1.D0,F2)) THEN
             CALL Halt('Failed to Find Root in  SetLocalCoefs')
          ENDIF
          DO I=1,100
             X3 = 0.5D0*(X1+X2)
             F3 = Hermite(X3,L+1)+2.D0*GFactor*X3*Hermite(X3,L)
             IF(SIGN(1.D0,F3)==SIGN(1.D0,F1)) THEN
                X1 = X3
             ELSE
                X2 = X3
             ENDIF
          ENDDO
          AACoef(L) = ABS(Hermite(X3,L))*EXP(-(One-GFactor)*X3*X3)
!          WRITE(*,*) 'L=',L,' X3 = ',X3,' F3 = ',F3
!          WRITE(*,*) 'AACoef = ',AACoef(L)
       ENDDO
     END SUBROUTINE SetAACoef
!=================================================================================================
!
!=================================================================================================
      FUNCTION Hermite(x,L)
        INTEGER                         :: L,I,J
        REAL(DOUBLE)                    :: Hermite,x
        REAL(DOUBLE),DIMENSION(0:8,0:8) :: CC
!
        CC(0:8,0) = (/ 1.000D0, 0.000D0, 0.0000D0, 0.000D0, 0.0000D0, 0.000D0, 0.000D0, 0.00D0, 0.00D0/)
        CC(0:8,1) = (/ 0.000D0,-2.000D0, 0.0000D0, 0.000D0, 0.0000D0, 0.000D0, 0.000D0, 0.00D0, 0.00D0/)
        CC(0:8,2) = (/-2.000D0, 0.000D0, 4.0000D0, 0.000D0, 0.0000D0, 0.000D0, 0.000D0, 0.00D0, 0.00D0/)
        CC(0:8,3) = (/ 0.000D0, 12.00D0, 0.0000D0,-8.000D0, 0.0000D0, 0.000D0, 0.000D0, 0.00D0, 0.00D0/)
        CC(0:8,4) = (/ 12.00D0, 0.000D0,-48.000D0, 0.000D0, 16.000D0, 0.000D0, 0.000D0, 0.00D0, 0.00D0/)
        CC(0:8,5) = (/ 0.000D0,-120.0D0, 0.0000D0, 160.0D0, 0.0000D0,-32.00D0, 0.000D0, 0.00D0, 0.00D0/)
        CC(0:8,6) = (/-120.0D0, 0.000D0, 720.00D0, 0.000D0,-480.00D0, 0.000D0, 64.00D0, 0.00D0, 0.00D0/)
        CC(0:8,7) = (/ 0.000D0, 1680.D0, 0.0000D0,-3360.D0, 0.0000D0, 1344.D0, 0.000D0,-128.D0, 0.00D0/)
        CC(0:8,8) = (/ 1680.D0, 0.000D0,-13440.D0, 0.000D0, 13440.D0, 0.000D0,-3584.D0, 0.00D0, 256.D0/)
!
        IF(L>8) CALL Halt("FUNCTION Hermite: L>8")
        Hermite = CC(L,L)
        DO I=0,L-1
           J = L-1-I
           Hermite = Hermite*x+CC(J,L)
        ENDDO
      END FUNCTION Hermite


!!$!===================================================================================================
!!$!    Used to set up our new Cramer's like bound
!!$!===================================================================================================
!!$     SUBROUTINE SetAACoef()
!!$       REAL(DOUBLE)  :: X1,X2,X3,F1,F2,F3
!!$       INTEGER       :: L,I
!!$!       Solve for AACoef
!!$       AACoef(0)= 1.D0
!!$       DO L=1,HGEll
!!$          X1 = SQRT(0.499D0*DBLE(L)/(1.D0-GFactor))
!!$          X2 = 2.D0*X1
!!$          F1 = Hermite(X1,L+1)+2.D0*GFactor*X1*Hermite(X1,L)
!!$          F2 = Hermite(X2,L+1)+2.D0*GFactor*X2*Hermite(X2,L)
!!$          IF(SIGN(1.D0,F1)==SIGN(1.D0,F2)) THEN
!!$             CALL Halt('Failed to Find Root in  SetLocalCoefs')
!!$          ENDIF
!!$          DO I=1,100
!!$             X3 = 0.5D0*(X1+X2)
!!$             F3 = Hermite(X3,L+1)+2.D0*GFactor*X3*Hermite(X3,L)
!!$             IF(SIGN(1.D0,F3)==SIGN(1.D0,F1)) THEN
!!$                X1 = X3
!!$             ELSE
!!$                X2 = X3
!!$             ENDIF
!!$          ENDDO
!!$          AACoef(L) = ABS(Hermite(X3,L))*EXP(-(One-GFactor)*X3*X3)
!!$!          WRITE(*,*) 'L=',L,' X3 = ',X3,' F3 = ',F3
!!$!          WRITE(*,*) 'AACoef = ',AACoef(L)
!!$       ENDDO
!!$     END SUBROUTINE SetAACoef
!!$!=================================================================================================
!!$!
!!$!=================================================================================================
!!$      FUNCTION Hermite(x,L)
!!$        INTEGER                         :: L,I,J
!!$        REAL(DOUBLE)                    :: Hermite,x
!!$        REAL(DOUBLE),DIMENSION(0:8,0:8) :: CC
!!$!
!!$        CC(0:8,0) = (/ 1.000D0, 0.000D0, 0.0000D0, 0.000D0, 0.0000D0, 0.000D0, 0.000D0, 0.00D0, 0.00D0/)
!!$        CC(0:8,1) = (/ 0.000D0,-2.000D0, 0.0000D0, 0.000D0, 0.0000D0, 0.000D0, 0.000D0, 0.00D0, 0.00D0/)
!!$        CC(0:8,2) = (/-2.000D0, 0.000D0, 4.0000D0, 0.000D0, 0.0000D0, 0.000D0, 0.000D0, 0.00D0, 0.00D0/)
!!$        CC(0:8,3) = (/ 0.000D0, 12.00D0, 0.0000D0,-8.000D0, 0.0000D0, 0.000D0, 0.000D0, 0.00D0, 0.00D0/)
!!$        CC(0:8,4) = (/ 12.00D0, 0.000D0,-48.000D0, 0.000D0, 16.000D0, 0.000D0, 0.000D0, 0.00D0, 0.00D0/)
!!$        CC(0:8,5) = (/ 0.000D0,-120.0D0, 0.0000D0, 160.0D0, 0.0000D0,-32.00D0, 0.000D0, 0.00D0, 0.00D0/)
!!$        CC(0:8,6) = (/-120.0D0, 0.000D0, 720.00D0, 0.000D0,-480.00D0, 0.000D0, 64.00D0, 0.00D0, 0.00D0/)
!!$        CC(0:8,7) = (/ 0.000D0, 1680.D0, 0.0000D0,-3360.D0, 0.0000D0, 1344.D0, 0.000D0,-128.D0, 0.00D0/)
!!$        CC(0:8,8) = (/ 1680.D0, 0.000D0,-13440.D0, 0.000D0, 13440.D0, 0.000D0,-3584.D0, 0.00D0, 256.D0/)
!!$
!!$!
!!$        IF(L>8) CALL Halt("FUNCTION Hermite: L>8")
!!$        Hermite = CC(L,L)
!!$        DO I=0,L-1
!!$           J = L-1-I
!!$           Hermite = Hermite*x+CC(J,L)
!!$        ENDDO
!!$      END FUNCTION Hermite
!======================================================================================
!
!======================================================================================
      FUNCTION NodeWeight(Ell,Zeta,HGCo)
        INTEGER                          :: Ell,L,M,N,LMN
        REAL(DOUBLE)                     :: NodeWeight,Zeta,PiZ
        REAL(DOUBLE), DIMENSION(1:)      :: HGCo
!
        PiZ        = (Pi/Zeta)**(ThreeHalves)
        NodeWeight = Zero
        DO L=0,Ell
           DO M=0,Ell-L
              DO N=0,Ell-L-M
                 LMN = LMNDex(L,M,N)
                 NodeWeight = NodeWeight+ABS(HGCo(LMN))*PiZ
              ENDDO
           ENDDO
        ENDDO
!
      END FUNCTION NodeWeight
!======================================================================================
!
!======================================================================================
      FUNCTION RErfc(R,L)
        INTEGER                    :: L
        REAL(DOUBLE)               :: RErfc
        REAL(DOUBLE)               :: R
!
        IF(R < Zero) THEN
           RErfc = One
           RETURN
        ENDIF
        SELECT CASE(L)
        CASE(0)
           RErfc=RErfc0(R)
        CASE(1)
           RErfc=RErfc1(R)
        CASE(2)
           RErfc=RErfc2(R)
        CASE(3)
           RErfc=RErfc3(R)
        CASE(4)
           RErfc=RErfc4(R)
        CASE(5)
           RErfc=RErfc5(R)
        CASE(6)
           RErfc=RErfc6(R)
        CASE(7)
           RErfc=RErfc7(R)
        CASE(8)
           RErfc=RErfc8(R)
        CASE(9)
           RErfc=RErfc9(R)
        CASE(10)
           RErfc=RErfc10(R)
        CASE(11)
           RErfc=RErfc11(R)
        CASE(12)
           RErfc=RErfc12(R)
        CASE DEFAULT
           CALL Halt('RErfc: L > 12')
        END SELECT
!
      END FUNCTION RErfc
!======================================================================================
!
!======================================================================================
      FUNCTION RErfc0(R)
        REAL(DOUBLE)                    :: RErfc0,R,DR,XX,YY
        INTEGER                         :: IG
        INTEGER,PARAMETER               :: NGrid     = 99
        REAL(DOUBLE),PARAMETER          :: DeltaR    = 0.05931686960054D0
        REAL(DOUBLE),PARAMETER          :: OneOverDR = One/DeltaR
        REAL(DOUBLE),PARAMETER          :: MaxR      = 99D0*DeltaR
        REAL(DOUBLE),DIMENSION(0:NGrid) :: RErfData  = (/0.00000000000000, &
        -0.069193073224990,-0.142991408326928,-0.221515189900601, &
        -0.304878985039043,-0.393191833185381,-0.486557367758120, &
        -0.585073963362215,-0.688834902998355,-0.797928560302294, &
        -0.912438592460752,-1.032444140042566,-1.158020030540609, &
        -1.289236982933699,-1.426161811043475,-1.568857623877557, &
        -1.717384021517407,-1.871797285429200,-2.032150562351496, &
        -2.198494041148113,-2.370875122212302,-2.549338579172856, &
        -2.733926712788254,-2.924679497024897,-3.121634717403466, &
        -3.324828101766578,-3.534293443674045,-3.750062718671778, &
        -3.972166193708843,-4.200632529996424,-4.435488879614120, &
        -4.676760976174494,-4.924473219857437,-5.178648757122674, &
        -5.439309555402449,-5.706476473067985,-5.980169324953073, &
        -6.260406943706823,-6.547207237235464,-6.840587242480499, &
        -7.140563175767735,-7.447150479948944,-7.760363868545313, &
        -8.080217367089518,-8.406724351851343,-8.739897586120252, &
        -9.079749254207362,-9.426290993318746,-9.779533923442075, &
        -10.13948867537919,-10.50616541704832,-10.87957387817126, &
        -11.25972337345318,-11.64662282435497,-12.04028077955169, &
        -12.44070543416383,-12.84790464784229,-13.26188596178228, &
        -13.68265661473638,-14.11022355809175,-14.54459347007234, &
        -14.98577276912252,-15.43376762652473,-15.88858397830016, &
        -16.35022753643799,-16.81870379949573,-17.29401806261018, &
        -17.77617542695583,-18.26518080868519,-18.76103894738293, &
        -19.26375441406382,-19.77333161874226,-20.28977481759945, &
        -20.81308811977241,-21.34327549378756,-21.88034077366007, &
        -22.42428766467859,-22.97511974889410,-23.53284049032989, &
        -24.09745323992905,-24.66896124025451,-25.24736762995584, &
        -25.83267544801594,-26.42488763779025,-27.02400705084999, &
        -27.63003645064032,-28.24297851596384,-28.86283584429873, &
        -29.48961095496092,-30.12330629211845,-30.76392422766607, &
        -31.41146706396770,-32.06593703647349,-32.72733631621836, &
        -33.39566701220809,-34.07093117369880,-34.75313079237544, &
        -35.44226780443437,-36.13834409257494,-36.84136148790473  /)
!
        IF(R .GE. MaxR) THEN
           RErfc0  = RErfData(99)
        ELSE
           DR      = R*OneOverDR
           IG      = INT(DR)
           YY      = DBLE(IG+1)-DR
           RErfc0  = YY*RErfData(IG)+(One-YY)*RErfData(IG+1)
        ENDIF
!
      END FUNCTION RErfc0
!======================================================================================
      FUNCTION RErfc1(R)
        REAL(DOUBLE)                    :: RErfc1,R,DR,XX,YY
        INTEGER                         :: IG
        INTEGER,PARAMETER               :: NGrid     = 99
        REAL(DOUBLE),PARAMETER          :: DeltaR    = 0.06292211887801D0
        REAL(DOUBLE),PARAMETER          :: OneOverDR = One/DeltaR
        REAL(DOUBLE),PARAMETER          :: MaxR      = 99D0*DeltaR
        REAL(DOUBLE),DIMENSION(0:NGrid) :: RErfData = (/0.00000000000000, &
        -0.000186974756964,-0.001486152993383,-0.004965342495878, &
        -0.011615198762045,-0.022329451188646,-0.037896063626369, &
        -0.058996660762918,-0.086211592623261,-0.120028398070176, &
        -0.160851945232677,-0.209015033912026,-0.264788673480549, &
        -0.328391578175315,-0.399998655017707,-0.479748414396392, &
        -0.567749328786172,-0.664085218490682,-0.768819768614690, &
        -0.882000289032170,-1.003660826175044,-1.133824726879128, &
        -1.272506743392976,-1.419714756870860,-1.575451185310542, &
        -1.739714131515644,-1.912498317494334,-2.093795843793505, &
        -2.283596805548458,-2.481889791388417,-2.688662286644674, &
        -2.903900998426183,-3.127592116931218,-3.359721524740706, &
        -3.600274963691111,-3.849238167168902,-4.106596964234527, &
        -4.372337360813076,-4.646445602233191,-4.928908220615716, &
        -5.219712069976476,-5.518844351387177,-5.826292630112860, &
        -6.142044846296310,-6.466089320474866,-6.798414754981612, &
        -7.139010232091591,-7.487865209616626,-7.844969514523482, &
        -8.210313335044181,-8.583887211660339,-8.965682027271787, &
        -9.355688996800997,-9.753899656436403,-10.16030585267795, &
        -10.57489973131550,-10.99767372644386,-11.42862054959609, &
        -11.86773317905864,-12.31500484941721,-12.77042904136974, &
        -13.23399947183347,-13.70571008436457,-14.18555503990271, &
        -14.67352870784722,-15.16962565746772,-15.67384064964845, &
        -16.18616862896284,-16.70660471607307,-17.23514420044744, &
        -17.77178253338728,-18.31651532135442,-18.86933831958934, &
        -19.43024742600977,-19.99923867537953,-20.57630823373690, &
        -21.16145239307215,-21.75466756624373,-22.35595028212303, &
        -22.96529718095755,-23.58270500994284,-24.20817061899368, &
        -24.84169095670549,-25.48326306649696,-26.13288408292562, &
        -26.79055122816809,-27.45626180865726,-28.13001321186889, &
        -28.81180290325062,-29.50162842328640,-30.19948738468997, &
        -30.90537746972125,-31.61929642761955,-32.34124207214819, &
        -33.07121227924511,-33.80920498477436,-34.55521818237374, &
        -35.30924992139395,-36.07129830492483,-36.84136148790473  /)
!

        IF(R .GE. MaxR) THEN
           RErfc1  = RErfData(99)
        ELSE
           DR      = R*OneOverDR
           IG      = INT(DR)
           YY      = DBLE(IG+1)-DR
           IF(IG.GT.98)THEN
              WRITE(*,*)myid,' IG = ',IG,' DR = ',DR
           ENDIF
           RErfc1  = YY*RErfData(IG)+(One-YY)*RErfData(IG+1)
        ENDIF
!
      END FUNCTION RErfc1
!======================================================================================
      FUNCTION RErfc2(R)
        REAL(DOUBLE)                    :: RErfc2,R,DR,XX,YY
        INTEGER                         :: IG
        INTEGER,PARAMETER               :: NGrid     = 99
        REAL(DOUBLE),PARAMETER          :: DeltaR    = 0.06650073239004D0
        REAL(DOUBLE),PARAMETER          :: OneOverDR = One/DeltaR
        REAL(DOUBLE),PARAMETER          :: MaxR      = 99D0*DeltaR
        REAL(DOUBLE),DIMENSION(0:NGrid) :: RErfData = (/1.09861228866811, &
         1.098611898560562, 1.098599922810268, 1.098519850529684, &
         1.098231189148427, 1.097481253396448, 1.095891043053229, &
         1.092956146155825, 1.088061218847890, 1.080504682183971, &
         1.069529238851472, 1.054353756589920, 1.034202809377015, &
         1.008331360983343, 0.976043349629266, 0.936704014576070, &
         0.889746561079973, 0.834674175410980, 0.771058537462595, &
         0.698535924009143, 0.616801836077347, 0.525604884640897, &
         0.424740472290347, 0.314044637344209, 0.193388289721380, &
         0.062671964929394,-0.078178850474941,-0.229217817439951, &
        -0.390481293005311,-0.561991372254674,-0.743758475182828, &
        -0.935783532255666,-1.138059820956087,-1.350574501994271, &
        -1.573309899185180,-1.806244561951503,-2.049354144423236, &
        -2.302612130421020,-2.565990429354655,-2.839459864289333, &
        -3.122990570131541,-3.416552317038580,-3.720114771720514, &
        -4.033647707235601,-4.357121170133754,-4.690505612333299, &
        -5.033771993884073,-5.386891861738907,-5.749837408794295, &
        -6.122581516742676,-6.505097785679913,-6.897360552912827, &
        -7.299344902996300,-7.711026670683754,-8.132382438187024, &
        -8.563389527902092,-9.004025991557733,-9.454270596578135, &
        -9.914102810312302,-10.38350278266801,-10.86245132759224, &
        -11.35092990376029,-11.84892059476921,-12.35640608907627, &
        -12.87336965987678,-13.39979514507772,-13.93566692749175, &
        -14.48096991534977,-15.03568952320859,-15.59981165331189, &
        -16.17332267744812,-16.75620941933639,-17.34845913756144, &
        -17.95005950907069,-18.56099861323924,-19.18126491650391, &
        -19.81084725756220,-20.44973483312946,-21.09791718424411, &
        -21.75538418310897,-22.42212602045517,-23.09813319341371, &
        -23.78339649387900,-24.47790699734828,-25.18165605222019, &
        -25.89463526953593,-26.61683651314627,-27.34825189028785, &
        -28.08887374255254,-28.83869463723381,-29.59770735903457, &
        -30.36590490212118,-31.14328046250907,-31.92982743076558, &
        -32.72553938501631,-33.53041008424174,-34.34443346185134, &
        -35.16760361952294,-35.99991482129561,-36.84136148790473  /)
!
        IF(R .GE. MaxR) THEN
           RErfc2  = RErfData(99)
        ELSE
           DR      = R*OneOverDR
           IG      = INT(DR)
           YY      = DBLE(IG+1)-DR
           RErfc2  = YY*RErfData(IG)+(One-YY)*RErfData(IG+1)
        ENDIF
!
      END FUNCTION RErfc2
!======================================================================================
      FUNCTION RErfc3(R)
        REAL(DOUBLE)                    :: RErfc3,R,DR,XX,YY
        INTEGER                         :: IG
        INTEGER,PARAMETER               :: NGrid     = 99
        REAL(DOUBLE),PARAMETER          :: DeltaR    = 0.070042173079986D0
        REAL(DOUBLE),PARAMETER          :: OneOverDR = One/DeltaR
        REAL(DOUBLE),PARAMETER          :: MaxR      = 99D0*DeltaR
        REAL(DOUBLE),DIMENSION(0:NGrid) :: RErfData = (/2.564949357461537, &
         2.564989006596002, 2.565263625653670, 2.565992802603680, &
         2.567362349194489, 2.569501375799620, 2.572455274337426, &
         2.576157159860651, 2.580402023380362, 2.584828524976382, &
         2.588912662484419, 2.591975596861863, 2.593205267685739, &
         2.591688902030936, 2.586451829453514, 2.576497524413260, &
         2.560844423100085, 2.538556404517671, 2.508765389438766, &
         2.470685893005966, 2.423622348402277, 2.366970556941687, &
         2.300214785775659, 2.222921946659951, 2.134734064044039, &
         2.035359967473269, 1.924566878894906, 1.802172339323368, &
         1.668036741562407, 1.522056605013354, 1.364158638220666, &
         1.194294576177962, 1.012436744324360, 0.818574282638383, &
         0.612709955824941, 0.394857475240685, 0.165039262043416, &
        -0.076715412873998,-0.330371969575571,-0.595891790626697, &
        -0.873233266850037,-1.162352654350417,-1.463204774242147, &
        -1.775743581588198,-2.099922625809633,-2.435695421191560, &
        -2.783015743032326,-3.141837862387034,-3.512116730178176, &
        -3.893808119624240,-4.286868734417033,-4.691256288812390, &
        -5.106929564745866,-5.533848450209878,-5.971973962401831, &
        -6.421268258549297,-6.881694636817219,-7.353217529286199, &
        -7.835802488645572,-8.329416169958229,-8.834026308616013, &
        -9.349601695406685,-9.876112149449189,-10.41352848961737, &
        -10.96182250495898,-11.52096692452251,-12.09093538692622, &
        -12.67170240993884,-13.26324336028737,-13.86553442386302, &
        -14.47855257645904,-15.10227555514383,-15.73668183034752, &
        -16.38175057871904,-17.03746165679417,-17.70379557550059, &
        -18.38073347551483,-19.06825710347665,-19.76634878905889, &
        -20.47499142288505,-21.19416843528175,-21.92386377585001, &
        -22.66406189383600,-23.41474771927998,-24.17590664492068, &
        -24.94752450883107,-25.72958757776088,-26.52208253116099, &
        -27.32499644586458,-28.13831678139993,-28.96203136591040, &
        -29.79612838265713,-30.64059635708082,-31.49542414439931, &
        -32.36060091771853,-33.23611615663498,-34.12195963630871, &
        -35.01812141698625,-35.92459183395427,-36.84136148790473  /)
!
        IF(R .GE. MaxR) THEN
           RErfc3  = RErfData(99)
        ELSE
           DR      = R*OneOverDR
           IG      = INT(DR)
           YY      = DBLE(IG+1)-DR
           RErfc3  = YY*RErfData(IG)+(One-YY)*RErfData(IG+1)
        ENDIF
!
      END FUNCTION RErfc3
!======================================================================================
      FUNCTION RErfc4(R)
        REAL(DOUBLE)                    :: RErfc4,R,DR,XX,YY
        INTEGER                         :: IG
        INTEGER,PARAMETER               :: NGrid     = 99
        REAL(DOUBLE),PARAMETER          :: DeltaR    = 0.07353933182164D0
        REAL(DOUBLE),PARAMETER          :: OneOverDR = One/DeltaR
        REAL(DOUBLE),PARAMETER          :: MaxR      = 99D0*DeltaR
        REAL(DOUBLE),DIMENSION(0:NGrid) :: RErfData = (/4.31748811353631, &
         4.317512175896137, 4.317683623966438, 4.318164127293550, &
         4.319140372982487, 4.320827794009712, 4.323464056836887, &
         4.327289854793929, 4.332516232536889, 4.339280301196572, &
         4.347594409460488, 4.357296734921312, 4.368012702667446, &
         4.379135703591913, 4.389832144701020, 4.399070830898690, &
         4.405671686727401, 4.408365472876023, 4.405855264024864, &
         4.396871839282875, 4.380217876363918, 4.354798847322964, &
         4.319640979226662, 4.273898209536944, 4.216850753226575, &
         4.147897931370660, 4.066547560830147, 3.972403697632445, &
         3.865154011832016, 3.744557627277397, 3.610433913785588, &
         3.462652470318325, 3.301124370798844, 3.125794640228349, &
         2.936635869946806, 2.733642852628586, 2.516828108888931, &
         2.286218180366933, 2.041850573539846, 1.783771250879338, &
         1.512032579167286, 1.226691657620370, 0.927808960280979, &
         0.615447237630823, 0.289670631504055,-0.049456034828375, &
        -0.401867822946879,-0.767500127972495,-1.146289031095237, &
        -1.538171573575461,-1.943085966710299,-2.360971749668170, &
        -2.791769904964123,-3.235422939597830,-3.691874938437616, &
        -4.161071595252469,-4.642960225823636,-5.137489766770208, &
        -5.644610763067975,-6.164275346702261,-6.696437208452392, &
        -7.241051564440955,-7.798075118780859,-8.367466023406095, &
        -8.949183835968431,-9.543189476514596,-10.14944518352021, &
        -10.76791446974285,-11.39856207826294,-12.04135393900370, &
        -12.69625712595819,-13.36323981529909,-14.04227124450406, &
        -14.73332167259470,-15.43636234155808,-16.15136543899705, &
        -16.87830406203610,-17.61715218249468,-18.36788461332744, &
        -19.13047697632112,-19.90490567103020,-20.69114784492749, &
        -21.48918136474094,-22.29898478894504,-23.12053734137223, &
        -23.95381888590821,-24.79880990223418,-25.65549146257799, &
        -26.52384520943658,-27.40385333423184,-28.29549855686274, &
        -29.19876410611710,-30.11363370090723,-31.04009153229460, &
        -31.97812224626968,-32.92771092725435,-33.88884308229508, &
        -34.86150462591662,-35.84568186560679,-36.84136148790429  /)
!
        IF(R .GE. MaxR) THEN
           RErfc4  = RErfData(99)
        ELSE
           DR      = R*OneOverDR
           IG      = INT(DR)
           YY      = DBLE(IG+1)-DR
           RErfc4  = YY*RErfData(IG)+(One-YY)*RErfData(IG+1)
        ENDIF
!
      END FUNCTION RErfc4
!======================================================================================
      FUNCTION RErfc5(R)
        REAL(DOUBLE)                    :: RErfc5,R,DR,XX,YY
        INTEGER                         :: IG
        INTEGER,PARAMETER               :: NGrid     = 99
        REAL(DOUBLE),PARAMETER          :: DeltaR    = 0.076987652162559D0
        REAL(DOUBLE),PARAMETER          :: OneOverDR = One/DeltaR
        REAL(DOUBLE),PARAMETER          :: MaxR      = 99D0*DeltaR
        REAL(DOUBLE),DIMENSION(0:NGrid) :: RErfData = (/ 6.293419278846481, &
         6.293428265819673, 6.293493693088801, 6.293684825294408, &
         6.294097480722633, 6.294868768085997, 6.296191436978435, &
         6.298324559305090, 6.301595469240838, 6.306386896861673, &
         6.313103857987721, 6.322117801478111, 6.333690876598580, &
         6.347889995738276, 6.364506404181953, 6.382998863032870, &
         6.402475264230870, 6.421718851294309, 6.439254240568298, &
         6.453439390802683, 6.462565703379193, 6.464950063244258, &
         6.459007992616580, 6.443303455963686, 6.416576085487549, &
         6.377749759222207, 6.325927650652646, 6.260378681155761, &
         6.180519411586974, 6.085894310516414, 5.976156325380410, &
         5.851048881436368, 5.710389860321647, 5.554057733779277, &
         5.381979801623467, 5.194122361061197, 4.990482580557620, &
         4.771081838857976, 4.535960300383642, 4.285172520311048, &
         4.018783899096409, 3.736867832950762, 3.439503431662079, &
         3.126773697248394, 2.798764075935197, 2.455561311979858, &
         2.097252545193015, 1.723924604978496, 1.335663462683267, &
         0.932553811347163, 0.514678747860966, 0.082119537331311, &
        -0.365044556677445,-0.826736389226794,-1.302881009089328, &
        -1.793405700471006,-2.298239998355976,-2.817315683124955, &
        -3.350566759017813,-3.897929420135558,-4.459342006966959, &
        -5.034744955848791,-5.624080743300500,-6.227293826793563, &
        -6.844330583206216,-7.475139245962356,-8.119669841648340, &
        -8.777874126734537,-9.449705524892659,-10.13511906528941, &
        -10.83407132214725,-11.54652035579019,-12.27242565533362, &
        -13.01174808312917,-13.76444982103778,-14.53049431857250, &
        -15.30984624292880,-16.10247143089987,-16.90833684265962, &
        -17.72741051738381,-18.55966153067059,-19.40505995371506, &
        -20.26357681418708,-21.13518405875834,-22.01985451722200, &
        -22.91756186814730,-23.82828060601040,-24.75198600974339, &
        -25.68865411264334,-26.63826167358464,-27.60078614947883, &
        -28.57620566892770,-29.56449900701696,-30.56564556119960, &
        -31.57962532821967,-32.60641888202935,-33.64600735265372, &
        -34.69837240595972,-35.76349622428757,-36.84136148790473  /)
!
        IF(R .GE. MaxR) THEN
           RErfc5  = RErfData(99)
        ELSE
           DR      = R*OneOverDR
           IG      = INT(DR)
           YY      = DBLE(IG+1)-DR
           RErfc5  = YY*RErfData(IG)+(One-YY)*RErfData(IG+1)
        ENDIF
!
      END FUNCTION RErfc5
!======================================================================================
      FUNCTION RErfc6(R)
        REAL(DOUBLE)                    :: RErfc6,R,DR,XX,YY
        INTEGER                         :: IG
        INTEGER,PARAMETER               :: NGrid     = 99
        REAL(DOUBLE),PARAMETER          :: DeltaR    = 0.08038444969254D0
        REAL(DOUBLE),PARAMETER          :: OneOverDR = One/DeltaR
        REAL(DOUBLE),PARAMETER          :: MaxR      = 99D0*DeltaR
        REAL(DOUBLE),DIMENSION(0:NGrid) :: RErfData = (/8.45169420918354, &
         8.451696731464077, 8.451714888931130, 8.451767285120825, &
         8.451880596117433, 8.452098828437182, 8.452498313444538, &
         8.453208957843854, 8.454440297748572, 8.456507961859357, &
         8.459852596569360, 8.465040097440987, 8.472730740677765, &
         8.483607536248120, 8.498262414270261, 8.517052340799022, &
         8.539952349806729, 8.566441803163055, 8.595457129229599, &
         8.625427356204093, 8.654384475228830, 8.680120241622958, &
         8.700353016766163, 8.712873605545914, 8.715652157851680, &
         8.706901896938425, 8.685105064270344, 8.649010910852891, &
         8.597615994368103, 8.530135293222203, 8.445970214034995, &
         8.344677310862902, 8.225939795721121, 8.089542736587266, &
         7.935352112890379, 7.763297499914760, 7.573357968050040, &
         7.365550724834147, 7.139922039492823, 6.896540034991680, &
         6.635488990291770, 6.356864854015652, 6.060771724448421, &
         5.747319097464568, 5.416619723165008, 5.068787944213050, &
         4.703938414936417, 4.322185121174293, 3.923640637508130, &
         3.508415571731583, 3.076618156873394, 2.628353959351936, &
         2.163725678368683, 1.682833016805942, 1.185772607972306, &
         0.672637985766722, 0.143519588389567,-0.401495212241652, &
        -0.962322061601805,-1.538879559139565,-2.131089184254946, &
        -2.738875214781334,-3.362164640428643,-4.000887073123153, &
        -4.654974655762534,-5.324361970570697,-6.008985947969708, &
        -6.708785776671868,-7.423702815523707,-8.153680507496597, &
        -8.898664296109308,-9.658601544480679,-10.43344145714136, &
        -11.22313500467889,-12.02763485124716,-12.84689528493792, &
        -13.68087215098553,-14.52952278775660,-15.39280596546090, &
        -16.27068182750891,-17.16311183443352,-18.07005871028809, &
        -18.99148639142966,-19.92735997759444,-20.87764568517237, &
        -21.84231080258775,-22.82132364769479,-23.81465352709815, &
        -24.82227069731149,-25.84414632766920,-26.88025246490968, &
        -27.93056199935137,-28.99504863258574,-30.07368684661494, &
        -31.16645187436438,-32.27331967150422,-33.39426688951615, &
        -34.52927084994538,-35.67830951978023,-36.84136148790473  /)
!
        IF(R .GE. MaxR) THEN
           RErfc6  = RErfData(99)
        ELSE
           DR      = R*OneOverDR
           IG      = INT(DR)
           YY      = DBLE(IG+1)-DR
           RErfc6  = YY*RErfData(IG)+(One-YY)*RErfData(IG+1)
        ENDIF
!
      END FUNCTION RErfc6
!======================================================================================
      FUNCTION RErfc7(R)
        REAL(DOUBLE)                    :: RErfc7,R,DR,XX,YY
        INTEGER                         :: IG
        INTEGER,PARAMETER               :: NGrid     = 99
        REAL(DOUBLE),PARAMETER          :: DeltaR    = 0.08372839514058D0
        REAL(DOUBLE),PARAMETER          :: OneOverDR = One/DeltaR
        REAL(DOUBLE),PARAMETER          :: MaxR      = 99D0*DeltaR
        REAL(DOUBLE),DIMENSION(0:NGrid) :: RErfData = (/10.76411757198485, &
         10.76411813202136, 10.76412161068957, 10.76412884865863, &
         10.76413725129333, 10.76414135516990, 10.76413734281293, &
         10.76413437044705, 10.76417591591818, 10.76437352645060, &
         10.76495267261681, 10.76630547905418, 10.76903811904830, &
         10.77399296615340, 10.78222018951453, 10.79487516270565, &
         10.81303208815989, 10.83743234625641, 10.86822088203630, &
         10.90474737057441, 10.94550134099710, 10.98820796622151, &
         11.03005430026045, 11.06797589104793, 11.09892898774297, &
         11.12009776570572, 11.12901920253527, 11.12363378411671, &
         11.10228235216457, 11.06367070923063, 11.00681929024963, &
         10.93100947122898, 10.83573311168280, 10.72064840114283, &
         10.58554290609700, 10.43030353717445, 10.25489262068989, &
         10.05932909285404, 9.843673860563882, 9.608018483047434, &
         9.352476465192646, 9.077176586924835, 8.782257810944393, &
         8.467865409735382, 8.134148032505685, 7.781255495899864, &
         7.409337131719821, 7.018540563180395, 6.609010810760577, &
         6.180889651424727, 5.734315172435320, 5.269421474379441, &
         4.786338488331491, 4.285191880002061, 3.766103019834477, &
         3.229189002731290, 2.674562704746890, 2.102332866916499, &
         1.512604198594619, 0.905477494391382, 0.281049760133554, &
        -0.360585655677304,-1.019338927618791,-1.695123618382168, &
        -2.387856544653565,-3.097457645014350,-3.823849850724589, &
        -4.566958960011978,-5.326713516299833,-6.103044690660536, &
        -6.895886168666482,-7.705174041722214,-8.530846702893573, &
        -9.372844747198082,-10.23111087628201,-11.10558980738087, &
        -11.99622818643962,-12.90297450525411,-13.82577902248646, &
        -14.76459368840081,-15.71937207316397,-16.69006929855462, &
        -17.67664197292666,-18.67904812927494,-19.69724716625527, &
        -20.73119979201542,-21.78086797069849,-22.84621487148561, &
        -23.92720482005027,-25.02380325230213,-26.13597667030399, &
        -27.26369260025078,-28.40691955240504,-29.56562698288869, &
        -30.73978525723578,-31.92936561561601,-33.13434013964345, &
        -34.35468172068938,-35.59036402962264,-36.84136148790473  /)
!
        IF(R .GE. MaxR) THEN
           RErfc7  = RErfData(99)
        ELSE
           DR      = R*OneOverDR
           IG      = INT(DR)
           YY      = DBLE(IG+1)-DR
           RErfc7  = YY*RErfData(IG)+(One-YY)*RErfData(IG+1)
        ENDIF
!
      END FUNCTION RErfc7
!======================================================================================
      FUNCTION RErfc8(R)
        REAL(DOUBLE)                    :: RErfc8,R,DR,XX,YY
        INTEGER                         :: IG
        INTEGER,PARAMETER               :: NGrid     = 99
        REAL(DOUBLE),PARAMETER          :: DeltaR    = 0.08701912793799076D0
        REAL(DOUBLE),PARAMETER          :: OneOverDR = One/DeltaR
        REAL(DOUBLE),PARAMETER          :: MaxR      = 99D0*DeltaR
        REAL(DOUBLE),DIMENSION(0:NGrid) :: RErfData = (/13.21007201125389, &
         13.21007210579564, 13.21007227927197, 13.21007005067418, &
         13.21005732941711, 13.21001669824980, 13.20991758420083, &
         13.20971415312302, 13.20934856302267, 13.20876515815047, &
         13.20794243688575, 13.20694890611345, 13.20602477824935, &
         13.20568264806853, 13.20680646838516, 13.21071103344163, &
         13.21910950621756, 13.23393599716151, 13.25699950601481, &
         13.28951239379937, 13.33162045239924, 13.38210762511775, &
         13.43840348111898, 13.49689512904119, 13.55341867250709, &
         13.60375956235860, 13.64403532477755, 13.67091530295996, &
         13.68169617117483, 13.67427964785485, 13.64709850937911, &
         13.59902443940239, 13.52927747625324, 13.43734643536429, &
         13.32292328707192, 13.18585112774050, 13.02608395599955, &
         12.84365608467509, 12.63865913336727, 12.41122485076809, &
         12.16151235707816, 11.88969870867806, 11.59597194712053, &
         11.28052600069436, 10.94355696568463, 10.58526041473942, &
         10.20582946986403, 9.805453444665598, 9.384316910289244, &
         8.942599076439862, 8.480473406307775, 7.998107404598747, &
         7.495662533049846, 6.973294219148203, 6.431151932257200, &
         5.869379307727688, 5.288114304370591, 4.687489384290343, &
         4.067631706820725, 3.428663330384575, 2.770701417679387, &
         2.093858440793407, 1.398242383772753, 0.683956940857744, &
        -0.048898290862246,-0.800227625222303,-1.569939107724557, &
        -2.357944343559354,-3.164158333040834,-3.988499314463468, &
        -4.830888614290837,-5.691250504518998,-6.569512067007911, &
        -7.465603064541049,-8.379455818351749,-9.311005091842319, &
        -10.26018798021615,-11.22694380574245,-12.21121401837633, &
        -13.21294210146295,-14.23207348226218,-15.26855544703957, &
        -16.32233706047955,-17.39336908918729,-18.48160392905668, &
        -19.58699553629281,-20.70949936188802,-21.84907228936145, &
        -23.00567257558201,-24.17925979450482,-25.36979478366071, &
        -26.57723959324732,-27.80155743767910,-29.04271264946192, &
        -30.30067063526530,-31.57539783407339,-32.86686167730197, &
        -34.17503055077605,-35.49987375846828,-36.84136148790455  /)
!
        IF(R .GE. MaxR) THEN
           RErfc8  = RErfData(99)
        ELSE
           DR      = R*OneOverDR
           IG      = INT(DR)
           YY      = DBLE(IG+1)-DR
           RErfc8  = YY*RErfData(IG)+(One-YY)*RErfData(IG+1)
        ENDIF
!
      END FUNCTION RErfc8
!======================================================================================
      FUNCTION RErfc9(R)
        REAL(DOUBLE)                    :: RErfc9,R,DR,XX,YY
        INTEGER                         :: IG
        INTEGER,PARAMETER               :: NGrid     = 99
        REAL(DOUBLE),PARAMETER          :: DeltaR    = 0.09025697036060773D0
        REAL(DOUBLE),PARAMETER          :: OneOverDR = One/DeltaR
        REAL(DOUBLE),PARAMETER          :: MaxR      = 99D0*DeltaR
        REAL(DOUBLE),DIMENSION(0:NGrid) :: RErfData = (/15.77380950510918, &
        15.77380951365833,15.77380929105443,15.77380705640535, &
        15.77379726100260,15.77376694867352,15.77368993018243, &
        15.77351839022051,15.77317275755632,15.77253309166093, &
        15.77143888735956,15.76970835205055,15.76719119027290, &
        15.76386821265520,15.76000370220934,15.75633949409789, &
        15.75429105493971,15.75606690239350,15.76459560132631, &
        15.78314209477066,15.81457693971122,15.86044798761322, &
        15.92020601245947,15.99096426746836,16.06792636161863, &
        16.14526340526118,16.21704609416605,16.27792994765047, &
        16.32350161106595,16.35034923711048,16.35597014810275, &
        16.33861163689883,16.29710381293223,16.23071231645819, &
        16.13901960250412,16.02183403377646,15.87912239651312, &
        15.71096075865471,15.51749911517102,15.29893615132185, &
        15.05550132802297,14.78744222456747,14.49501564096529, &
        14.17848138424863,13.83809797007609,13.47411969133663, &
        13.08679466256243,12.67636356064059,12.24305886167692, &
        11.78710443033980,11.30871535829746,10.80809797718976, &
        10.28544999227477,9.740960697808344,9.174811246003233, &
        8.587174949243091,7.978217600925064,7.348097804462778, &
        6.696967303022009,6.024971304787452,5.332248800189479, &
        4.618932868713368,3.885150973785423,3.131025244865089, &
        2.356672746331497,1.562205733082297,0.7477318929959050, &
        -0.08664542342965993,-0.9408269858388962,-1.814717478688967, &
        -2.708225307293120,-3.621262414681635,-4.553744108718695, &
        -5.505588898918507,-6.476718342416520,-7.467056898569270, &
        -8.476531791677459,-9.505072881350006,-10.55261254005101, &
        -11.61908553739616,-12.70442893078958,-13.80858196201593, &
        -14.93148595942599,-16.07308424537587,-17.23332204860155, &
        -18.41214642123034,-19.60950616015008,-20.82535173247459, &
        -22.05963520486113,-23.31231017645090,-24.58333171521896, &
        -25.87265629753336,-27.18024175073635,-28.50604719857273, &
        -29.85003300930142,-31.21216074633698,-32.59239312127749, &
        -33.99069394918448,-35.40702810598882,-36.84136148790473  /)
!
        IF(R .GE. MaxR) THEN
           RErfc9  =RErfData(99)
        ELSE
           DR      = R*OneOverDR
           IG      = INT(DR)
           YY      = DBLE(IG+1)-DR
           RErfc9  = YY*RErfData(IG)+(One-YY)*RErfData(IG+1)
        ENDIF
!
      END FUNCTION RErfc9
!======================================================================================
      FUNCTION RErfc10(R)
        REAL(DOUBLE)                    :: RErfc10,R,DR,XX,YY
        INTEGER                         :: IG
        INTEGER,PARAMETER               :: NGrid     = 99
        REAL(DOUBLE),PARAMETER          :: DeltaR    = 0.09344271762133112D0
        REAL(DOUBLE),PARAMETER          :: OneOverDR = One/DeltaR
        REAL(DOUBLE),PARAMETER          :: MaxR      = 99D0*DeltaR
        REAL(DOUBLE),DIMENSION(0:NGrid) :: RErfData = (/18.44290751886233, &
        18.44290751715104,18.44290738561470,18.44290633426016, &
        18.44290191135521,18.44288809157196,18.44285144576142, &
        18.44276384957866,18.44256991067949,18.44216796195571, &
        18.44138601742552,18.43995928546354,18.43752355245647, &
        18.43364725316707,18.42793081867475,18.42020018749843, &
        18.41080666564634,18.40101058378327,18.39336218633989, &
        18.39189625832506,18.40185977816341,18.42871019249799, &
        18.47642720152296,18.54575654796465,18.63336814027105, &
        18.73248567289395,18.83457542922275,18.93112845126090, &
        19.01483637317953,19.08004011253013,19.12267946416737, &
        19.14001628862671,19.13031204206564,19.09254376285118, &
        19.02618288578449,18.93103387703396,18.80712080010139, &
        18.65460928731298,18.47375356086243,18.26486076341270, &
        18.02826709971954,17.76432198705671,17.47337762196832, &
        17.15578220729846,16.81187565249188,16.44198694434276, &
        16.04643264408822,15.62551614107524,15.17952741099559, &
        14.70874310652440,14.21342686255465,13.69382973538573, &
        13.15019072074321,12.58273731309496,11.99168608088877, &
        11.37724324076322,10.73960521963028,10.07895919758375, &
        9.395483627395066,8.689348728292951,7.960716953047244, &
        7.209743428270990,6.436576368447969,5.641357464573960, &
        4.824222248533324,3.985300434462731,3.124716238412923, &
        2.242588677629978,1.339031850755577,0.4141552002027328, &
        -0.5319362420927141,-1.499141624408141,-2.487364059388215, &
        -3.496510421615460,-4.526491157662858,-5.577220107758864, &
        -6.648614338257216,-7.740593984162511,-8.853082101017608, &
        -9.986004525510348,-11.13928974420498,-12.31286876984806, &
        -13.50667502473978,-14.72064423069947,-15.95471430518946, &
        -17.20882526319321,-18.48291912447406,-19.77693982586788, &
        -21.09083313828830,-22.42454658814666,-23.77802938290990, &
        -25.15123234053965,-26.54410782257378,-27.95660967062847, &
        -29.38869314611444,-30.84031487297506,-32.31143278326736, &
        -33.80200606541906,-35.31199511500598,-36.84136148790473  /)
!
        IF(R .GE. MaxR) THEN
           RErfc10 = RErfData(99)
        ELSE
           DR      = R*OneOverDR
           IG      = INT(DR)
           YY      = DBLE(IG+1)-DR
           RErfc10 = YY*RErfData(IG)+(One-YY)*RErfData(IG+1)
        ENDIF
!
      END FUNCTION RErfc10
!======================================================================================
      FUNCTION RErfc11(R)
        REAL(DOUBLE)                    :: RErfc11,R,DR,XX,YY
        INTEGER                         :: IG
        INTEGER,PARAMETER               :: NGrid     = 99
        REAL(DOUBLE),PARAMETER          :: DeltaR    = 0.09657748457523069D0
        REAL(DOUBLE),PARAMETER          :: OneOverDR = One/DeltaR
        REAL(DOUBLE),PARAMETER          :: MaxR      = 99D0*DeltaR
        REAL(DOUBLE),DIMENSION(0:NGrid) :: RErfData = (/21.20731571229542, &
        21.20731571107156,21.20731566285921,21.20731531957955, &
        21.20731399323669,21.20731010902021,21.20730002148488, &
        21.20727483835995,21.20721284007656,21.20706376334364, &
        21.20672063743336,21.20597669782455,21.20447118459797, &
        21.20163973421013,21.19670127569658,21.18872922870755, &
        21.17686359916332,21.16071527403658,21.14098515965502, &
        21.12024684897591,21.10367756867960,21.09923619551078, &
        21.11652185197993,21.16383456556883,21.24433885940325, &
        21.35379278566555,21.48169003395478,21.61485505981057, &
        21.74091663147353,21.85013186681244,21.93568310940778, &
        21.99320103007327,22.02010124563232,22.01500388764749, &
        21.97730438787966,21.90688092087268,21.80390340866076, &
        21.66871176818656,21.50173939503212,21.30346557428190, &
        21.07438620082099,20.81499603696140,20.52577822610399, &
        20.20719836254006,19.85970141326331,19.48371041359732, &
        19.07962625266803,18.64782811400600,18.18867429490573, &
        17.70250322924271,17.18963460324505,16.65037049539474, &
        16.08499649849051,15.49378279920821,14.87698520160866, &
        14.23484608813347,13.56759531609543,12.87545105042393, &
        12.15862053506421,11.41730080634207,10.65167935205289, &
        9.861934720183251,9.048237081139358,8.210748747210850, &
        7.349624652791463,6.465012798639260,5.557054663210042, &
        4.625885583849919,3.671635110394842,2.694427333500284, &
        1.694381189815447,0.6716107459240641,-0.3737745372019551, &
        -1.441669557649851,-2.531973342473271,-3.644588832749788, &
        -4.779422682597701,-5.936385071068279,-7.115389525926298, &
        -8.316352758418961,-9.539194508212005,-10.78383739774288, &
        -12.05020679530513,-13.33823068623601,-14.64783955163221, &
        -15.97896625406570,-17.33154592981514,-18.70551588716730, &
        -20.10081551037858,-21.51738616891874,-22.95517113164875, &
        -24.41411548561122,-25.89416605913635,-27.39527134898872, &
        -28.91738145130069,-30.46044799605671,-32.02442408491001, &
        -33.60926423212901,-35.21492430848480,-36.84136148790473  /)
!
        IF(R .GE. MaxR) THEN
           RErfc11 = RErfData(99)
        ELSE
           DR      = R*OneOverDR
           IG      = INT(DR)
           YY      = DBLE(IG+1)-DR
           RErfc11 = YY*RErfData(IG)+(One-YY)*RErfData(IG+1)
        ENDIF
!
      END FUNCTION RErfc11
!======================================================================================
      FUNCTION RErfc12(R)
        REAL(DOUBLE)                    :: RErfc12,R,DR,XX,YY
        INTEGER                         :: IG
        INTEGER,PARAMETER               :: NGrid     = 99
        REAL(DOUBLE),PARAMETER          :: DeltaR    = 0.09966259428603357D0
        REAL(DOUBLE),PARAMETER          :: OneOverDR = One/DeltaR
        REAL(DOUBLE),PARAMETER          :: MaxR      = 99D0*DeltaR
        REAL(DOUBLE),DIMENSION(0:NGrid) :: RErfData = (/24.05873528266423, &
        24.05873528223582,24.05873526921308,24.05873519907667, &
        24.05873505179937,24.05873506479703,24.05873615062081, &
        24.05874015212194,24.05874862547055,24.05875691314462, &
        24.05873735871244,24.05860260794256,24.05813965925027, &
        24.05691176376220,24.05414211238127,24.04862029126469, &
        24.03870317596971,24.02250583583366,23.99838833893557, &
        23.96583980586502,23.92682198681755,23.88745903327613, &
        23.85940811687748,23.85918546483326,23.90321258065273, &
        23.99922955414769,24.14048482883780,24.30867003132285, &
        24.48243381741757,24.64400492074749,24.78125260891334, &
        24.88693020618666,24.95717591871165,24.99022619951323, &
        24.98553727547292,24.94324219048330,24.86383119277638, &
        24.74796849354406,24.59638910806416,24.40984190379312, &
        24.18905909585404,23.93474080401092,23.64754813078842, &
        23.32810100109457,22.97697859915366,22.59472115730405, &
        22.18183238291467,21.73878211880764,21.26600901284704, &
        20.76392307749518,20.23290808119616,19.67332374851817, &
        19.08550776569738,18.46977759886651,17.82643213755937, &
        17.15575317829413,16.45800676348983,15.73344439045991, &
        14.98230410422821,14.20481148670477,13.40118055349980, &
        12.57161456843300,11.71630678465671,10.83544112027539, &
        9.929192775415586,8.997728796877427,8.041208595773329, &
        7.059784422923065,6.053601806217522,5.022799953676525, &
        3.967512125500828,2.887865978046627,1.783983882325962, &
        0.6559832193517721,-0.4960233456030412,-1.671927607982189, &
        -2.871625586500435,-4.095017301787792,-5.342006569785119, &
        -6.612500808685152,-7.906410858330366,-9.223650811083153, &
        -10.56413785327646,-11.92779211643553,-13.31453653753513, &
        -14.72429672762243,-16.15700084819488,-17.61257949477537, &
        -19.09096558717454,-20.59209426597321,-22.11590279479652, &
        -23.66233046798624,-25.23131852330974,-26.82281005937242, &
        -28.43674995742671,-30.07308480729448,-31.73176283714101, &
        -33.41273384685862,-35.11594914483587,-36.84136148790473  /)
!
        IF(R .GE. MaxR) THEN
           RErfc12 = RErfData(99)
        ELSE
           DR      = R*OneOverDR
           IG      = INT(DR)
           YY      = DBLE(IG+1)-DR
           RErfc12 = YY*RErfData(IG)+(One-YY)*RErfData(IG+1)
        ENDIF
!
      END FUNCTION RErfc12

END MODULE Thresholding
