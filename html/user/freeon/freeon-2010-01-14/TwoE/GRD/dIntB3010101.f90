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
! ---------------------------------------------------------- 
! COMPUTES THE INTEGRAL CLASS (p s|s s) 
! ---------------------------------------------------------- 
SUBROUTINE dIntB3010101(PrmBufB,LBra,PrmBufK,LKet,ACInfo,BDInfo, &
 OA,LDA,OB,LDB,OC,LDC,OD,LDD,GOA,GOB,GOC,GOD,NINT,PBC,GRADIENTS,STRESS)
       USE DerivedTypes
      USE VScratchB
      USE GlobalScalars
      USE ShellPairStruct
      USE GammaF2
      IMPLICIT REAL(DOUBLE) (W)
      INTEGER        :: LBra,LKet,NINT,CDOffSet
      REAL(DOUBLE)   :: PrmBufB(10,LBra),PrmBufK(10,LKet)
      TYPE(SmallAtomInfo) :: ACInfo,BDInfo
      TYPE(PBCInfo) :: PBC
      REAL(DOUBLE)  :: GRADIENTS(NINT,12)
      REAL(DOUBLE)  :: STRESS(NINT,9)
      REAL(DOUBLE)  :: Ax,Ay,Az,Bx,By,Bz,Cx,Cy,Cz
      REAL(DOUBLE)  :: Dx,Dy,Dz,Qx,Qy,Qz,Px,Py,Pz
      REAL(DOUBLE)  :: PQx,PQy,PQz,FPQx,FPQy,FPQz
      REAL(DOUBLE)  :: Zeta,Eta,Omega,Up,Uq,Upq
      REAL(DOUBLE)  :: T,ET,TwoT,InvT,SqInvT
      REAL(DOUBLE)  :: Alpha,Beta,Gamma
      REAL(DOUBLE), DIMENSION(10) :: HRRTmp 
      REAL(DOUBLE), DIMENSION(4,1,1) :: HRR 
      REAL(DOUBLE), DIMENSION(10,1,1) :: HRRA,HRRB 
      REAL(DOUBLE), DIMENSION(4,4,1) :: HRRC 
      REAL(DOUBLE)  :: VRR(10,4,0:2)
      REAL(DOUBLE)  :: VRRS(4,1,0:1,3)
      REAL(DOUBLE)  :: HRRS(4,1,1,9)
      REAL(DOUBLE)  :: TOm,PQJ(3),FP(9)
      INTEGER       :: OffSet,OA,LDA,GOA,OB,LDB,GOB,OC,LDC,GOC,OD,LDD,GOD,I,J,K,L,IJ
      EXTERNAL InitDbl
      CALL InitDbl(4*1,HRR(1,1,1))
      CALL InitDbl(10*1,HRRA(1,1,1))
      CALL InitDbl(10*1,HRRB(1,1,1))
      CALL InitDbl(4*4,HRRC(1,1,1))
      CALL InitDbl(9*1*4*1,HRRS(1,1,1,1))
      Ax=ACInfo%Atm1X
      Ay=ACInfo%Atm1Y
      Az=ACInfo%Atm1Z
      Bx=ACInfo%Atm2X
      By=ACInfo%Atm2Y
      Bz=ACInfo%Atm2Z
      Cx=BDInfo%Atm1X
      Cy=BDInfo%Atm1Y
      Cz=BDInfo%Atm1Z
      Dx=BDInfo%Atm2X
      Dy=BDInfo%Atm2Y
      Dz=BDInfo%Atm2Z
      ABx=Ax-Bx
      ABy=Ay-By
      ABz=Az-Bz
      CDx=Cx-Dx
      CDy=Cy-Dy
      CDz=Cz-Dz
      !
      !This will feel better above!
      FP(1)=PBC%InvBoxSh%D(1,1)*(Ax-Dx)+PBC%InvBoxSh%D(1,2)*(Ay-Dy)+PBC%InvBoxSh%D(1,3)*(Az-Dz)
      FP(2)=                            PBC%InvBoxSh%D(2,2)*(Ay-Dy)+PBC%InvBoxSh%D(2,3)*(Az-Dz)
      FP(3)=                                                        PBC%InvBoxSh%D(3,3)*(Az-Dz)
      FP(4)=PBC%InvBoxSh%D(1,1)*(Cx-Dx)+PBC%InvBoxSh%D(1,2)*(Cy-Dy)+PBC%InvBoxSh%D(1,3)*(Cz-Dz)
      FP(5)=                            PBC%InvBoxSh%D(2,2)*(Cy-Dy)+PBC%InvBoxSh%D(2,3)*(Cz-Dz)
      FP(6)=                                                        PBC%InvBoxSh%D(3,3)*(Cz-Dz)
      FP(7)=PBC%InvBoxSh%D(1,1)*(Bx-Dx)+PBC%InvBoxSh%D(1,2)*(By-Dy)+PBC%InvBoxSh%D(1,3)*(Bz-Dz)
      FP(8)=                            PBC%InvBoxSh%D(2,2)*(By-Dy)+PBC%InvBoxSh%D(2,3)*(Bz-Dz)
      FP(9)=                                                        PBC%InvBoxSh%D(3,3)*(Bz-Dz)
      !
      DO J=1,LKet ! K^2 VRR |N0) loop 
         Eta=PrmBufK(1,J)
         Qx=PrmBufK(2,J)
         Qy=PrmBufK(3,J)
         Qz=PrmBufK(4,J)
         Uq=PrmBufK(5,J)
         Gamma =PrmBufK(9,J)
         QCx=Qx-Cx
         QCy=Qy-Cy
         QCz=Qz-Cz
         DO K=1,LBra ! K^2 VRR (M0| loop 
            Zeta=PrmBufB(1,K)
            Px=PrmBufB(2,K)
            Py=PrmBufB(3,K)
            Pz=PrmBufB(4,K)
            Up=PrmBufB(5,K)
            Alpha =PrmBufB(9,K)
            Beta  =PrmBufB(10,K)
            r1xZpE=One/(Zeta+Eta)
            Upq=SQRT(r1xZpE)*Up*Uq
            HfxZpE=Half/(Zeta+Eta)
            r1x2E=Half/Eta
            r1x2Z=Half/Zeta
            ExZpE=Eta*r1xZpE
            ZxZpE=Zeta*r1xZpE
            Omega=Eta*Zeta*r1xZpE
            PAx=Px-Ax
            PAy=Py-Ay
            PAz=Pz-Az
            PQx=Px-Qx
            PQy=Py-Qy
            PQz=Pz-Qz
            ! Begin Minimum Image Convention 
            FPQx = PQx*PBC%InvBoxSh%D(1,1)+PQy*PBC%InvBoxSh%D(1,2)+PQz*PBC%InvBoxSh%D(1,3)
            FPQy = PQy*PBC%InvBoxSh%D(2,2)+PQz*PBC%InvBoxSh%D(2,3)
            FPQz = PQz*PBC%InvBoxSh%D(3,3)
            TOm=2.0d0*Omega
            IF(PBC%AutoW%I(1)==1) THEN
              PQJ(1)=ANINT(FPQx-SIGN(1D-15,FPQx));FPQx=FPQx-PQJ(1)
              PQJ(1)=PQJ(1)*TOm
            ELSE
              PQJ(1)=0.0D0
            ENDIF
            IF(PBC%AutoW%I(2)==1) THEN
              PQJ(2)=ANINT(FPQy-SIGN(1D-15,FPQy));FPQy=FPQy-PQJ(2)
              PQJ(2)=PQJ(2)*TOm
            ELSE
              PQJ(2)=0.0D0
            ENDIF
            IF(PBC%AutoW%I(3)==1) THEN
              PQJ(3)=ANINT(FPQz-SIGN(1D-15,FPQz));FPQz=FPQz-PQJ(3)
              PQJ(3)=PQJ(3)*TOm
            ELSE
              PQJ(3)=0.0D0
            ENDIF
            PQx=FPQx*PBC%BoxShape%D(1,1)+FPQy*PBC%BoxShape%D(1,2)+FPQz*PBC%BoxShape%D(1,3)
            PQy=FPQy*PBC%BoxShape%D(2,2)+FPQz*PBC%BoxShape%D(2,3)
            PQz=FPQz*PBC%BoxShape%D(3,3)
            ! End MIC
            WPx = -Eta*PQx*r1xZpE
            WPy = -Eta*PQy*r1xZpE
            WPz = -Eta*PQz*r1xZpE
            WQx = Zeta*PQx*r1xZpE
            WQy = Zeta*PQy*r1xZpE
            WQz = Zeta*PQz*r1xZpE
            T=Omega*(PQx*PQx+PQy*PQy+PQz*PQz)
            IF(T<Gamma_Switch)THEN
              L=AINT(T*Gamma_Grid)
              ET=EXP(-T)
              TwoT=Two*T
              W2=(F2_0(L)+T*(F2_1(L)+T*(F2_2(L)+T*(F2_3(L)+T*F2_4(L)))))
              W1=+3.333333333333333D-01*(TwoT*W2+ET)
              W0=TwoT*W1+ET
              VRR(1,1,0)=Upq*W0
              VRR(1,1,1)=Upq*W1
              VRR(1,1,2)=Upq*W2
            ELSE
              InvT=One/T
              SqInvT=DSQRT(InvT)
              VRR(1,1,0)=+8.862269254527580D-01*Upq*SqInvT
              SqInvT=SqInvT*InvT
              VRR(1,1,1)=+4.431134627263790D-01*Upq*SqInvT
              SqInvT=SqInvT*InvT
              VRR(1,1,2)=+6.646701940895685D-01*Upq*SqInvT
            ENDIF
            ! Generating (p0|s0)^(1)
            VRR(2,1,1)=PAx*VRR(1,1,1)+WPx*VRR(1,1,2) 
            VRR(3,1,1)=PAy*VRR(1,1,1)+WPy*VRR(1,1,2) 
            VRR(4,1,1)=PAz*VRR(1,1,1)+WPz*VRR(1,1,2) 
            ! Generating (p0|s0)^(0)
            VRR(2,1,0)=PAx*VRR(1,1,0)+WPx*VRR(1,1,1) 
            VRR(3,1,0)=PAy*VRR(1,1,0)+WPy*VRR(1,1,1) 
            VRR(4,1,0)=PAz*VRR(1,1,0)+WPz*VRR(1,1,1) 
            ! Generating (d0|s0)^(0)
            VRR(5,1,0)=PAx*VRR(2,1,0)+r1x2Z*(VRR(1,1,0)-ExZpE*VRR(1,1,1))+WPx*VRR(2,1,1)
            VRR(6,1,0)=PAx*VRR(3,1,0)+WPx*VRR(3,1,1)
            VRR(7,1,0)=PAy*VRR(3,1,0)+r1x2Z*(VRR(1,1,0)-ExZpE*VRR(1,1,1))+WPy*VRR(3,1,1)
            VRR(8,1,0)=PAx*VRR(4,1,0)+WPx*VRR(4,1,1)
            VRR(9,1,0)=PAy*VRR(4,1,0)+WPy*VRR(4,1,1)
            VRR(10,1,0)=PAz*VRR(4,1,0)+r1x2Z*(VRR(1,1,0)-ExZpE*VRR(1,1,1))+WPz*VRR(4,1,1)
            ! Generating (s0|p0)^(1)
            VRR(1,2,1)=QCx*VRR(1,1,1)+WQx*VRR(1,1,2)
            VRR(1,3,1)=QCy*VRR(1,1,1)+WQy*VRR(1,1,2)
            VRR(1,4,1)=QCz*VRR(1,1,1)+WQz*VRR(1,1,2)
            ! Generating (s0|p0)^(0)
            VRR(1,2,0)=QCx*VRR(1,1,0)+WQx*VRR(1,1,1)
            VRR(1,3,0)=QCy*VRR(1,1,0)+WQy*VRR(1,1,1)
            VRR(1,4,0)=QCz*VRR(1,1,0)+WQz*VRR(1,1,1)
            ! Generating (p0|p0)^(0)
            VRR(2,2,0)=QCx*VRR(2,1,0)+HfxZpE*VRR(1,1,1)+WQx*VRR(2,1,1) 
            VRR(2,3,0)=QCy*VRR(2,1,0)+WQy*VRR(2,1,1) 
            VRR(2,4,0)=QCz*VRR(2,1,0)+WQz*VRR(2,1,1) 
            VRR(3,2,0)=QCx*VRR(3,1,0)+WQx*VRR(3,1,1) 
            VRR(3,3,0)=QCy*VRR(3,1,0)+HfxZpE*VRR(1,1,1)+WQy*VRR(3,1,1) 
            VRR(3,4,0)=QCz*VRR(3,1,0)+WQz*VRR(3,1,1) 
            VRR(4,2,0)=QCx*VRR(4,1,0)+WQx*VRR(4,1,1) 
            VRR(4,3,0)=QCy*VRR(4,1,0)+WQy*VRR(4,1,1) 
            VRR(4,4,0)=QCz*VRR(4,1,0)+HfxZpE*VRR(1,1,1)+WQz*VRR(4,1,1) 
            !MAY BE BETTER TO PUT WHAT FOLLOWS IN A DO LOOP!
            IF(PBC%AutoW%I(1).EQ.1) THEN
            VRRS(1,1,0,1)=PQx*VRR(1,1,1)
            VRRS(1,1,1,1)=PQx*VRR(1,1,2)
            ! MIC-VRR: Generating [p0|s0]^(0)
            VRRS(2,1,0,1)=PAx*VRRS(1,1,0,1)+WPx*VRRS(1,1,1,1)+r1x2Z*VRR(1,1,1)
            VRRS(3,1,0,1)=PAy*VRRS(1,1,0,1)+WPy*VRRS(1,1,1,1) 
            VRRS(4,1,0,1)=PAz*VRRS(1,1,0,1)+WPz*VRRS(1,1,1,1) 
            ENDIF
            IF(PBC%AutoW%I(2).EQ.1) THEN
            VRRS(1,1,0,2)=PQy*VRR(1,1,1)
            VRRS(1,1,1,2)=PQy*VRR(1,1,2)
            ! MIC-VRR: Generating [p0|s0]^(0)
            VRRS(2,1,0,2)=PAx*VRRS(1,1,0,2)+WPx*VRRS(1,1,1,2)
            VRRS(3,1,0,2)=PAy*VRRS(1,1,0,2)+WPy*VRRS(1,1,1,2)+r1x2Z*VRR(1,1,1)
            VRRS(4,1,0,2)=PAz*VRRS(1,1,0,2)+WPz*VRRS(1,1,1,2)
            ENDIF
            IF(PBC%AutoW%I(3).EQ.1) THEN
            VRRS(1,1,0,3)=PQz*VRR(1,1,1)
            VRRS(1,1,1,3)=PQz*VRR(1,1,2)
            ! MIC-VRR: Generating [p0|s0]^(0)
            VRRS(2,1,0,3)=PAx*VRRS(1,1,0,3)+WPx*VRRS(1,1,1,3)
            VRRS(3,1,0,3)=PAy*VRRS(1,1,0,3)+WPy*VRRS(1,1,1,3)
            VRRS(4,1,0,3)=PAz*VRRS(1,1,0,3)+WPz*VRRS(1,1,1,3)+r1x2Z*VRR(1,1,1)
            ENDIF
            ! Contracting ... 
            CALL CNTRCTG3111(VRR,HRR,Alpha,HRRA,Beta,HRRB,Gamma,HRRC, &
                       VRRS,HRRS(1,1,1,1),PQJ(1),PBC%AutoW%I(1))
         ENDDO ! (M0| loop
      ENDDO ! |N0) loop
      ! Dont need to generate (p,0|s,s)
      ! Dont need to generate (d,0|s,s)^a
      ! Dont need to generate (d,0|s,s)^b
      ! Dont need to generate (p,0|p,s)^c
      ! Stress: No need to generate [p,0|s,s] 
      DO L=1,1
      
         !K = 1
         CDOffSet=(OC+1-1)*LDC+(OD+L-1)*LDD
         ! Generating (p',s|1,L)  and (p,s'|1,L)
         CALL BraHRR31ab(NINT,LDA,LDB,OA,OB,GOA,GOB,CDOffSet,HRR(1,1,L),&
                      HRRA(1,1,L),HRRB(1,1,L),GRADIENTS(1,1),FP(1),&
                      STRESS(1,1))
         ! Generating (p,s|1_x,L)  and (p,s|1,L_x)
         CALL BraHRR31cd(NINT,LDA,LDB,OA,OB,GOA,GOB,GOC,GOD,CDOffSet,0,&
                      HRRC(1,2,L),GRADIENTS(1,1),FP(1),STRESS(1,1))
         ! Generating (p,s|1_y,L)  and (p,s|1,L_y)
         CALL BraHRR31cd(NINT,LDA,LDB,OA,OB,GOA,GOB,GOC,GOD,CDOffSet,1,&
                      HRRC(1,3,L),GRADIENTS(1,1),FP(1),STRESS(1,1))
         ! Generating (p,s|1_z,L)  and (p,s|1,L_z)
         CALL BraHRR31cd(NINT,LDA,LDB,OA,OB,GOA,GOB,GOC,GOD,CDOffSet,2,&
                      HRRC(1,4,L),GRADIENTS(1,1),FP(1),STRESS(1,1))
      ENDDO 
      ! Stress: Generating (p,s|s,s)^(1) 
      DO J=1,3
      DO I=1,3
      IJ=3*(J-1)+I
        DO L=1,1
          DO K=1,1
            CDOffSet=(OC+K-1)*LDC+(OD+L-1)*LDD 
            CALL BraHRR31(OA,OB,LDA,LDB,CDOffSet,HRRS(1,K,L,IJ),STRESS(1,IJ))
          ENDDO 
        ENDDO 
      ENDDO 
      ENDDO 
   END SUBROUTINE dIntB3010101
    SUBROUTINE CNTRCTG3111(VRR,HRR,Alpha,HRRA,Beta,HRRB,Gamma,HRRC,VRRS,HRRS,PQJ,IW)
      USE DerivedTypes
      USE VScratchB
      IMPLICIT NONE
      INTEGER :: K
      REAL(DOUBLE)  :: Alpha,Beta,Gamma
      REAL(DOUBLE), DIMENSION(4,1,1) :: HRR 
      REAL(DOUBLE), DIMENSION(10,1,1) :: HRRA,HRRB 
      REAL(DOUBLE), DIMENSION(4,4,1) :: HRRC 
      REAL(DOUBLE)  :: VRR(10,4,0:2)
      REAL(DOUBLE)  :: VRRS(4,1,0:1,3)
      REAL(DOUBLE)  :: HRRS(4,1,1,9),PQJ(3)
      INTEGER :: IJ,J,I,IW(3)
      HRR(1,1,1)=HRR(1,1,1)+VRR(1,1,0)
      HRRA(1,1,1)=HRRA(1,1,1)+Alpha*VRR(1,1,0)
      HRRB(1,1,1)=HRRB(1,1,1)+Beta*VRR(1,1,0)
      HRRC(1,1,1)=HRRC(1,1,1)+Gamma*VRR(1,1,0)
      HRRC(1,2,1)=HRRC(1,2,1)+Gamma*VRR(1,2,0)
      HRRC(1,3,1)=HRRC(1,3,1)+Gamma*VRR(1,3,0)
      HRRC(1,4,1)=HRRC(1,4,1)+Gamma*VRR(1,4,0)
      HRR(2,1,1)=HRR(2,1,1)+VRR(2,1,0)
      HRRA(2,1,1)=HRRA(2,1,1)+Alpha*VRR(2,1,0)
      HRRB(2,1,1)=HRRB(2,1,1)+Beta*VRR(2,1,0)
      HRRC(2,1,1)=HRRC(2,1,1)+Gamma*VRR(2,1,0)
      HRRC(2,2,1)=HRRC(2,2,1)+Gamma*VRR(2,2,0)
      HRRC(2,3,1)=HRRC(2,3,1)+Gamma*VRR(2,3,0)
      HRRC(2,4,1)=HRRC(2,4,1)+Gamma*VRR(2,4,0)
      HRR(3,1,1)=HRR(3,1,1)+VRR(3,1,0)
      HRRA(3,1,1)=HRRA(3,1,1)+Alpha*VRR(3,1,0)
      HRRB(3,1,1)=HRRB(3,1,1)+Beta*VRR(3,1,0)
      HRRC(3,1,1)=HRRC(3,1,1)+Gamma*VRR(3,1,0)
      HRRC(3,2,1)=HRRC(3,2,1)+Gamma*VRR(3,2,0)
      HRRC(3,3,1)=HRRC(3,3,1)+Gamma*VRR(3,3,0)
      HRRC(3,4,1)=HRRC(3,4,1)+Gamma*VRR(3,4,0)
      HRR(4,1,1)=HRR(4,1,1)+VRR(4,1,0)
      HRRA(4,1,1)=HRRA(4,1,1)+Alpha*VRR(4,1,0)
      HRRB(4,1,1)=HRRB(4,1,1)+Beta*VRR(4,1,0)
      HRRC(4,1,1)=HRRC(4,1,1)+Gamma*VRR(4,1,0)
      HRRC(4,2,1)=HRRC(4,2,1)+Gamma*VRR(4,2,0)
      HRRC(4,3,1)=HRRC(4,3,1)+Gamma*VRR(4,3,0)
      HRRC(4,4,1)=HRRC(4,4,1)+Gamma*VRR(4,4,0)
      HRRA(5,1,1)=HRRA(5,1,1)+Alpha*VRR(5,1,0)
      HRRB(5,1,1)=HRRB(5,1,1)+Beta*VRR(5,1,0)
      HRRA(6,1,1)=HRRA(6,1,1)+Alpha*VRR(6,1,0)
      HRRB(6,1,1)=HRRB(6,1,1)+Beta*VRR(6,1,0)
      HRRA(7,1,1)=HRRA(7,1,1)+Alpha*VRR(7,1,0)
      HRRB(7,1,1)=HRRB(7,1,1)+Beta*VRR(7,1,0)
      HRRA(8,1,1)=HRRA(8,1,1)+Alpha*VRR(8,1,0)
      HRRB(8,1,1)=HRRB(8,1,1)+Beta*VRR(8,1,0)
      HRRA(9,1,1)=HRRA(9,1,1)+Alpha*VRR(9,1,0)
      HRRB(9,1,1)=HRRB(9,1,1)+Beta*VRR(9,1,0)
      HRRA(10,1,1)=HRRA(10,1,1)+Alpha*VRR(10,1,0)
      HRRB(10,1,1)=HRRB(10,1,1)+Beta*VRR(10,1,0)
      IJ=1
      DO J=1,3
      IF(IW(J).EQ.1) THEN
        IF(IW(1).EQ.1) THEN
        HRRS(1,1,1,IJ)=HRRS(1,1,1,IJ)+PQJ(J)*VRRS(1,1,0,1)
        HRRS(2,1,1,IJ)=HRRS(2,1,1,IJ)+PQJ(J)*VRRS(2,1,0,1)
        HRRS(3,1,1,IJ)=HRRS(3,1,1,IJ)+PQJ(J)*VRRS(3,1,0,1)
        HRRS(4,1,1,IJ)=HRRS(4,1,1,IJ)+PQJ(J)*VRRS(4,1,0,1)
        ENDIF
        IJ=IJ+1
        IF(IW(2).EQ.1) THEN
        HRRS(1,1,1,IJ)=HRRS(1,1,1,IJ)+PQJ(J)*VRRS(1,1,0,2)
        HRRS(2,1,1,IJ)=HRRS(2,1,1,IJ)+PQJ(J)*VRRS(2,1,0,2)
        HRRS(3,1,1,IJ)=HRRS(3,1,1,IJ)+PQJ(J)*VRRS(3,1,0,2)
        HRRS(4,1,1,IJ)=HRRS(4,1,1,IJ)+PQJ(J)*VRRS(4,1,0,2)
        ENDIF
        IJ=IJ+1
        IF(IW(3).EQ.1) THEN
        HRRS(1,1,1,IJ)=HRRS(1,1,1,IJ)+PQJ(J)*VRRS(1,1,0,3)
        HRRS(2,1,1,IJ)=HRRS(2,1,1,IJ)+PQJ(J)*VRRS(2,1,0,3)
        HRRS(3,1,1,IJ)=HRRS(3,1,1,IJ)+PQJ(J)*VRRS(3,1,0,3)
        HRRS(4,1,1,IJ)=HRRS(4,1,1,IJ)+PQJ(J)*VRRS(4,1,0,3)
        ENDIF
        IJ=IJ+1
      ELSE
        IJ=IJ+3
      ENDIF
      ENDDO !J
    END SUBROUTINE CNTRCTG3111
