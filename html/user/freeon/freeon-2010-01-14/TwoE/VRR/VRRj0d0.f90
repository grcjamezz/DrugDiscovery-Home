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
   SUBROUTINE VRRj0d0(LB,LK,VRR0,VRR1) 
      USE DerivedTypes
      USE VScratchB
      USE GlobalScalars
      IMPLICIT REAL(DOUBLE) (W)
      INTEGER :: LB,LK
      REAL(DOUBLE), DIMENSION(1:LB,1:LK) :: VRR0,VRR1
      V(1)=r1x2Z*VRR0(38,5)
      V(2)=ExZpE*r1x2Z*VRR1(38,5)
      V(3)=r1x2Z*VRR0(38,6)
      V(4)=ExZpE*r1x2Z*VRR1(38,6)
      V(5)=r1x2Z*VRR0(38,7)
      V(6)=ExZpE*r1x2Z*VRR1(38,7)
      V(7)=r1x2Z*VRR0(38,8)
      V(8)=ExZpE*r1x2Z*VRR1(38,8)
      V(9)=r1x2Z*VRR0(38,9)
      V(10)=ExZpE*r1x2Z*VRR1(38,9)
      V(11)=r1x2Z*VRR0(38,10)
      V(12)=ExZpE*r1x2Z*VRR1(38,10)
      V(13)=r1x2Z*VRR0(39,5)
      V(14)=ExZpE*r1x2Z*VRR1(39,5)
      V(15)=HfxZpE*VRR1(60,2)
      V(16)=r1x2Z*VRR0(39,6)
      V(17)=ExZpE*r1x2Z*VRR1(39,6)
      V(18)=HfxZpE*VRR1(60,3)
      V(19)=r1x2Z*VRR0(39,7)
      V(20)=ExZpE*r1x2Z*VRR1(39,7)
      V(21)=r1x2Z*VRR0(39,8)
      V(22)=ExZpE*r1x2Z*VRR1(39,8)
      V(23)=HfxZpE*VRR1(60,4)
      V(24)=r1x2Z*VRR0(39,9)
      V(25)=ExZpE*r1x2Z*VRR1(39,9)
      V(26)=r1x2Z*VRR0(39,10)
      V(27)=ExZpE*r1x2Z*VRR1(39,10)
      V(28)=r1x2Z*VRR0(44,5)
      V(29)=3.D0*V(28)
      V(30)=ExZpE*r1x2Z*VRR1(44,5)
      V(31)=-3.D0*V(30)
      V(32)=r1x2Z*VRR0(44,6)
      V(33)=3.D0*V(32)
      V(34)=ExZpE*r1x2Z*VRR1(44,6)
      V(35)=-3.D0*V(34)
      V(36)=r1x2Z*VRR0(44,7)
      V(37)=3.D0*V(36)
      V(38)=ExZpE*r1x2Z*VRR1(44,7)
      V(39)=-3.D0*V(38)
      V(40)=r1x2Z*VRR0(44,8)
      V(41)=3.D0*V(40)
      V(42)=ExZpE*r1x2Z*VRR1(44,8)
      V(43)=-3.D0*V(42)
      V(44)=r1x2Z*VRR0(44,9)
      V(45)=3.D0*V(44)
      V(46)=ExZpE*r1x2Z*VRR1(44,9)
      V(47)=-3.D0*V(46)
      V(48)=r1x2Z*VRR0(44,10)
      V(49)=3.D0*V(48)
      V(50)=ExZpE*r1x2Z*VRR1(44,10)
      V(51)=-3.D0*V(50)
      V(52)=r1x2Z*VRR0(45,5)
      V(53)=ExZpE*r1x2Z*VRR1(45,5)
      V(54)=HfxZpE*VRR1(67,2)
      V(55)=r1x2Z*VRR0(45,6)
      V(56)=ExZpE*r1x2Z*VRR1(45,6)
      V(57)=HfxZpE*VRR1(67,3)
      V(58)=r1x2Z*VRR0(45,7)
      V(59)=ExZpE*r1x2Z*VRR1(45,7)
      V(60)=r1x2Z*VRR0(45,8)
      V(61)=ExZpE*r1x2Z*VRR1(45,8)
      V(62)=HfxZpE*VRR1(67,4)
      V(63)=r1x2Z*VRR0(45,9)
      V(64)=ExZpE*r1x2Z*VRR1(45,9)
      V(65)=r1x2Z*VRR0(45,10)
      V(66)=ExZpE*r1x2Z*VRR1(45,10)
      V(67)=r1x2Z*VRR0(47,5)
      V(68)=ExZpE*r1x2Z*VRR1(47,5)
      V(69)=r1x2Z*VRR0(47,6)
      V(70)=ExZpE*r1x2Z*VRR1(47,6)
      V(71)=r1x2Z*VRR0(47,7)
      V(72)=ExZpE*r1x2Z*VRR1(47,7)
      V(73)=r1x2Z*VRR0(47,8)
      V(74)=ExZpE*r1x2Z*VRR1(47,8)
      V(75)=r1x2Z*VRR0(47,9)
      V(76)=ExZpE*r1x2Z*VRR1(47,9)
      V(77)=r1x2Z*VRR0(47,10)
      V(78)=ExZpE*r1x2Z*VRR1(47,10)
      V(79)=r1x2Z*VRR0(48,5)
      V(80)=3.D0*V(79)
      V(81)=ExZpE*r1x2Z*VRR1(48,5)
      V(82)=-3.D0*V(81)
      V(83)=r1x2Z*VRR0(48,6)
      V(84)=3.D0*V(83)
      V(85)=ExZpE*r1x2Z*VRR1(48,6)
      V(86)=-3.D0*V(85)
      V(87)=r1x2Z*VRR0(48,7)
      V(88)=3.D0*V(87)
      V(89)=ExZpE*r1x2Z*VRR1(48,7)
      V(90)=-3.D0*V(89)
      V(91)=r1x2Z*VRR0(48,8)
      V(92)=3.D0*V(91)
      V(93)=ExZpE*r1x2Z*VRR1(48,8)
      V(94)=-3.D0*V(93)
      V(95)=r1x2Z*VRR0(48,9)
      V(96)=3.D0*V(95)
      V(97)=ExZpE*r1x2Z*VRR1(48,9)
      V(98)=-3.D0*V(97)
      V(99)=r1x2Z*VRR0(48,10)
      V(100)=3.D0*V(99)
      V(101)=ExZpE*r1x2Z*VRR1(48,10)
      V(102)=-3.D0*V(101)
      V(103)=r1x2Z*VRR0(49,5)
      V(104)=ExZpE*r1x2Z*VRR1(49,5)
      V(105)=HfxZpE*VRR1(72,2)
      V(106)=r1x2Z*VRR0(49,6)
      V(107)=ExZpE*r1x2Z*VRR1(49,6)
      V(108)=HfxZpE*VRR1(72,3)
      V(109)=r1x2Z*VRR0(49,7)
      V(110)=ExZpE*r1x2Z*VRR1(49,7)
      V(111)=r1x2Z*VRR0(49,8)
      V(112)=ExZpE*r1x2Z*VRR1(49,8)
      V(113)=HfxZpE*VRR1(72,4)
      V(114)=r1x2Z*VRR0(49,9)
      V(115)=ExZpE*r1x2Z*VRR1(49,9)
      V(116)=r1x2Z*VRR0(49,10)
      V(117)=ExZpE*r1x2Z*VRR1(49,10)
      V(118)=3.D0*V(103)
      V(119)=-3.D0*V(104)
      V(120)=3.D0*V(106)
      V(121)=-3.D0*V(107)
      V(122)=3.D0*V(109)
      V(123)=-3.D0*V(110)
      V(124)=3.D0*V(111)
      V(125)=-3.D0*V(112)
      V(126)=3.D0*V(114)
      V(127)=-3.D0*V(115)
      V(128)=3.D0*V(116)
      V(129)=-3.D0*V(117)
      V(130)=r1x2Z*VRR0(50,5)
      V(131)=ExZpE*r1x2Z*VRR1(50,5)
      V(132)=r1x2Z*VRR0(50,6)
      V(133)=ExZpE*r1x2Z*VRR1(50,6)
      V(134)=r1x2Z*VRR0(50,7)
      V(135)=ExZpE*r1x2Z*VRR1(50,7)
      V(136)=r1x2Z*VRR0(50,8)
      V(137)=ExZpE*r1x2Z*VRR1(50,8)
      V(138)=r1x2Z*VRR0(50,9)
      V(139)=ExZpE*r1x2Z*VRR1(50,9)
      V(140)=r1x2Z*VRR0(50,10)
      V(141)=ExZpE*r1x2Z*VRR1(50,10)
      V(142)=r1x2Z*VRR0(51,5)
      V(143)=ExZpE*r1x2Z*VRR1(51,5)
      V(144)=HfxZpE*VRR1(75,2)
      V(145)=r1x2Z*VRR0(51,6)
      V(146)=ExZpE*r1x2Z*VRR1(51,6)
      V(147)=HfxZpE*VRR1(75,3)
      V(148)=r1x2Z*VRR0(51,7)
      V(149)=ExZpE*r1x2Z*VRR1(51,7)
      V(150)=r1x2Z*VRR0(51,8)
      V(151)=ExZpE*r1x2Z*VRR1(51,8)
      V(152)=HfxZpE*VRR1(75,4)
      V(153)=r1x2Z*VRR0(51,9)
      V(154)=ExZpE*r1x2Z*VRR1(51,9)
      V(155)=r1x2Z*VRR0(51,10)
      V(156)=ExZpE*r1x2Z*VRR1(51,10)
      V(157)=r1x2Z*VRR0(52,5)
      V(158)=2.D0*V(157)
      V(159)=ExZpE*r1x2Z*VRR1(52,5)
      V(160)=-2.D0*V(159)
      V(161)=HfxZpE*VRR1(76,2)
      V(162)=r1x2Z*VRR0(52,6)
      V(163)=2.D0*V(162)
      V(164)=ExZpE*r1x2Z*VRR1(52,6)
      V(165)=-2.D0*V(164)
      V(166)=HfxZpE*VRR1(76,3)
      V(167)=r1x2Z*VRR0(52,7)
      V(168)=2.D0*V(167)
      V(169)=ExZpE*r1x2Z*VRR1(52,7)
      V(170)=-2.D0*V(169)
      V(171)=r1x2Z*VRR0(52,8)
      V(172)=2.D0*V(171)
      V(173)=ExZpE*r1x2Z*VRR1(52,8)
      V(174)=-2.D0*V(173)
      V(175)=HfxZpE*VRR1(76,4)
      V(176)=r1x2Z*VRR0(52,9)
      V(177)=2.D0*V(176)
      V(178)=ExZpE*r1x2Z*VRR1(52,9)
      V(179)=-2.D0*V(178)
      V(180)=r1x2Z*VRR0(52,10)
      V(181)=2.D0*V(180)
      V(182)=ExZpE*r1x2Z*VRR1(52,10)
      V(183)=-2.D0*V(182)
      V(184)=HfxZpE*VRR1(77,2)
      V(185)=HfxZpE*VRR1(77,3)
      V(186)=HfxZpE*VRR1(77,4)
      V(187)=r1x2Z*VRR0(53,5)
      V(188)=ExZpE*r1x2Z*VRR1(53,5)
      V(189)=r1x2Z*VRR0(53,6)
      V(190)=ExZpE*r1x2Z*VRR1(53,6)
      V(191)=HfxZpE*VRR1(78,2)
      V(192)=r1x2Z*VRR0(53,7)
      V(193)=ExZpE*r1x2Z*VRR1(53,7)
      V(194)=HfxZpE*VRR1(78,3)
      V(195)=r1x2Z*VRR0(53,8)
      V(196)=ExZpE*r1x2Z*VRR1(53,8)
      V(197)=r1x2Z*VRR0(53,9)
      V(198)=ExZpE*r1x2Z*VRR1(53,9)
      V(199)=HfxZpE*VRR1(78,4)
      V(200)=r1x2Z*VRR0(53,10)
      V(201)=ExZpE*r1x2Z*VRR1(53,10)
      VRR0(85,5)=6.D0*r1x2Z*VRR0(36,5)+PAx*VRR0(57,5)-6.D0*ExZpE*r1x2Z*VRR1(36,5)+2.D0*HfxZpE*VRR1(57,2)+WPx*VRR1(57,5)
      VRR0(85,6)=6.D0*r1x2Z*VRR0(36,6)+PAx*VRR0(57,6)-6.D0*ExZpE*r1x2Z*VRR1(36,6)+HfxZpE*VRR1(57,3)+WPx*VRR1(57,6)
      VRR0(85,7)=6.D0*r1x2Z*VRR0(36,7)+PAx*VRR0(57,7)-6.D0*ExZpE*r1x2Z*VRR1(36,7)+WPx*VRR1(57,7)
      VRR0(85,8)=6.D0*r1x2Z*VRR0(36,8)+PAx*VRR0(57,8)-6.D0*ExZpE*r1x2Z*VRR1(36,8)+HfxZpE*VRR1(57,4)+WPx*VRR1(57,8)
      VRR0(85,9)=6.D0*r1x2Z*VRR0(36,9)+PAx*VRR0(57,9)-6.D0*ExZpE*r1x2Z*VRR1(36,9)+WPx*VRR1(57,9)
      VRR0(85,10)=6.D0*r1x2Z*VRR0(36,10)+PAx*VRR0(57,10)-6.D0*ExZpE*r1x2Z*VRR1(36,10)+WPx*VRR1(57,10)
      VRR0(86,5)=5.D0*r1x2Z*VRR0(37,5)+PAx*VRR0(58,5)-5.D0*ExZpE*r1x2Z*VRR1(37,5)+2.D0*HfxZpE*VRR1(58,2)+WPx*VRR1(58,5)
      VRR0(86,6)=5.D0*r1x2Z*VRR0(37,6)+PAx*VRR0(58,6)-5.D0*ExZpE*r1x2Z*VRR1(37,6)+HfxZpE*VRR1(58,3)+WPx*VRR1(58,6)
      VRR0(86,7)=5.D0*r1x2Z*VRR0(37,7)+PAx*VRR0(58,7)-5.D0*ExZpE*r1x2Z*VRR1(37,7)+WPx*VRR1(58,7)
      VRR0(86,8)=5.D0*r1x2Z*VRR0(37,8)+PAx*VRR0(58,8)-5.D0*ExZpE*r1x2Z*VRR1(37,8)+HfxZpE*VRR1(58,4)+WPx*VRR1(58,8)
      VRR0(86,9)=5.D0*r1x2Z*VRR0(37,9)+PAx*VRR0(58,9)-5.D0*ExZpE*r1x2Z*VRR1(37,9)+WPx*VRR1(58,9)
      VRR0(86,10)=5.D0*r1x2Z*VRR0(37,10)+PAx*VRR0(58,10)-5.D0*ExZpE*r1x2Z*VRR1(37,10)+WPx*VRR1(58,10)
      VRR0(87,5)=4.D0*V(1)-4.D0*V(2)+PAx*VRR0(59,5)+2.D0*HfxZpE*VRR1(59,2)+WPx*VRR1(59,5)
      VRR0(87,6)=4.D0*V(3)-4.D0*V(4)+PAx*VRR0(59,6)+HfxZpE*VRR1(59,3)+WPx*VRR1(59,6)
      VRR0(87,7)=4.D0*V(5)-4.D0*V(6)+PAx*VRR0(59,7)+WPx*VRR1(59,7)
      VRR0(87,8)=4.D0*V(7)-4.D0*V(8)+PAx*VRR0(59,8)+HfxZpE*VRR1(59,4)+WPx*VRR1(59,8)
      VRR0(87,9)=4.D0*V(9)-4.D0*V(10)+PAx*VRR0(59,9)+WPx*VRR1(59,9)
      VRR0(87,10)=4.D0*V(11)-4.D0*V(12)+PAx*VRR0(59,10)+WPx*VRR1(59,10)
      VRR0(88,5)=3.D0*V(13)-3.D0*V(14)+2.D0*V(15)+PAx*VRR0(60,5)+WPx*VRR1(60,5)
      VRR0(88,6)=3.D0*V(16)-3.D0*V(17)+V(18)+PAx*VRR0(60,6)+WPx*VRR1(60,6)
      VRR0(88,7)=3.D0*V(19)-3.D0*V(20)+PAx*VRR0(60,7)+WPx*VRR1(60,7)
      VRR0(88,8)=3.D0*V(21)-3.D0*V(22)+V(23)+PAx*VRR0(60,8)+WPx*VRR1(60,8)
      VRR0(88,9)=3.D0*V(24)-3.D0*V(25)+PAx*VRR0(60,9)+WPx*VRR1(60,9)
      VRR0(88,10)=3.D0*V(26)-3.D0*V(27)+PAx*VRR0(60,10)+WPx*VRR1(60,10)
      VRR0(89,5)=3.D0*V(1)-3.D0*V(2)+PAy*VRR0(60,5)+WPy*VRR1(60,5)
      VRR0(89,6)=3.D0*V(3)-3.D0*V(4)+V(15)+PAy*VRR0(60,6)+WPy*VRR1(60,6)
      VRR0(89,7)=3.D0*V(5)-3.D0*V(6)+2.D0*V(18)+PAy*VRR0(60,7)+WPy*VRR1(60,7)
      VRR0(89,8)=3.D0*V(7)-3.D0*V(8)+PAy*VRR0(60,8)+WPy*VRR1(60,8)
      VRR0(89,9)=3.D0*V(9)-3.D0*V(10)+V(23)+PAy*VRR0(60,9)+WPy*VRR1(60,9)
      VRR0(89,10)=3.D0*V(11)-3.D0*V(12)+PAy*VRR0(60,10)+WPy*VRR1(60,10)
      VRR0(90,5)=4.D0*V(13)-4.D0*V(14)+PAy*VRR0(61,5)+WPy*VRR1(61,5)
      VRR0(90,6)=4.D0*V(16)-4.D0*V(17)+PAy*VRR0(61,6)+HfxZpE*VRR1(61,2)+WPy*VRR1(61,6)
      VRR0(90,7)=4.D0*V(19)-4.D0*V(20)+PAy*VRR0(61,7)+2.D0*HfxZpE*VRR1(61,3)+WPy*VRR1(61,7)
      VRR0(90,8)=4.D0*V(21)-4.D0*V(22)+PAy*VRR0(61,8)+WPy*VRR1(61,8)
      VRR0(90,9)=4.D0*V(24)-4.D0*V(25)+PAy*VRR0(61,9)+HfxZpE*VRR1(61,4)+WPy*VRR1(61,9)
      VRR0(90,10)=4.D0*V(26)-4.D0*V(27)+PAy*VRR0(61,10)+WPy*VRR1(61,10)
      VRR0(91,5)=5.D0*r1x2Z*VRR0(40,5)+PAy*VRR0(62,5)-5.D0*ExZpE*r1x2Z*VRR1(40,5)+WPy*VRR1(62,5)
      VRR0(91,6)=5.D0*r1x2Z*VRR0(40,6)+PAy*VRR0(62,6)-5.D0*ExZpE*r1x2Z*VRR1(40,6)+HfxZpE*VRR1(62,2)+WPy*VRR1(62,6)
      VRR0(91,7)=5.D0*r1x2Z*VRR0(40,7)+PAy*VRR0(62,7)-5.D0*ExZpE*r1x2Z*VRR1(40,7)+2.D0*HfxZpE*VRR1(62,3)+WPy*VRR1(62,7)
      VRR0(91,8)=5.D0*r1x2Z*VRR0(40,8)+PAy*VRR0(62,8)-5.D0*ExZpE*r1x2Z*VRR1(40,8)+WPy*VRR1(62,8)
      VRR0(91,9)=5.D0*r1x2Z*VRR0(40,9)+PAy*VRR0(62,9)-5.D0*ExZpE*r1x2Z*VRR1(40,9)+HfxZpE*VRR1(62,4)+WPy*VRR1(62,9)
      VRR0(91,10)=5.D0*r1x2Z*VRR0(40,10)+PAy*VRR0(62,10)-5.D0*ExZpE*r1x2Z*VRR1(40,10)+WPy*VRR1(62,10)
      VRR0(92,5)=6.D0*r1x2Z*VRR0(41,5)+PAy*VRR0(63,5)-6.D0*ExZpE*r1x2Z*VRR1(41,5)+WPy*VRR1(63,5)
      VRR0(92,6)=6.D0*r1x2Z*VRR0(41,6)+PAy*VRR0(63,6)-6.D0*ExZpE*r1x2Z*VRR1(41,6)+HfxZpE*VRR1(63,2)+WPy*VRR1(63,6)
      VRR0(92,7)=6.D0*r1x2Z*VRR0(41,7)+PAy*VRR0(63,7)-6.D0*ExZpE*r1x2Z*VRR1(41,7)+2.D0*HfxZpE*VRR1(63,3)+WPy*VRR1(63,7)
      VRR0(92,8)=6.D0*r1x2Z*VRR0(41,8)+PAy*VRR0(63,8)-6.D0*ExZpE*r1x2Z*VRR1(41,8)+WPy*VRR1(63,8)
      VRR0(92,9)=6.D0*r1x2Z*VRR0(41,9)+PAy*VRR0(63,9)-6.D0*ExZpE*r1x2Z*VRR1(41,9)+HfxZpE*VRR1(63,4)+WPy*VRR1(63,9)
      VRR0(92,10)=6.D0*r1x2Z*VRR0(41,10)+PAy*VRR0(63,10)-6.D0*ExZpE*r1x2Z*VRR1(41,10)+WPy*VRR1(63,10)
      VRR0(93,5)=5.D0*r1x2Z*VRR0(42,5)+PAx*VRR0(64,5)-5.D0*ExZpE*r1x2Z*VRR1(42,5)+2.D0*HfxZpE*VRR1(64,2)+WPx*VRR1(64,5)
      VRR0(93,6)=5.D0*r1x2Z*VRR0(42,6)+PAx*VRR0(64,6)-5.D0*ExZpE*r1x2Z*VRR1(42,6)+HfxZpE*VRR1(64,3)+WPx*VRR1(64,6)
      VRR0(93,7)=5.D0*r1x2Z*VRR0(42,7)+PAx*VRR0(64,7)-5.D0*ExZpE*r1x2Z*VRR1(42,7)+WPx*VRR1(64,7)
      VRR0(93,8)=5.D0*r1x2Z*VRR0(42,8)+PAx*VRR0(64,8)-5.D0*ExZpE*r1x2Z*VRR1(42,8)+HfxZpE*VRR1(64,4)+WPx*VRR1(64,8)
      VRR0(93,9)=5.D0*r1x2Z*VRR0(42,9)+PAx*VRR0(64,9)-5.D0*ExZpE*r1x2Z*VRR1(42,9)+WPx*VRR1(64,9)
      VRR0(93,10)=5.D0*r1x2Z*VRR0(42,10)+PAx*VRR0(64,10)-5.D0*ExZpE*r1x2Z*VRR1(42,10)+WPx*VRR1(64,10)
      VRR0(94,5)=4.D0*r1x2Z*VRR0(43,5)+PAx*VRR0(65,5)-4.D0*ExZpE*r1x2Z*VRR1(43,5)+2.D0*HfxZpE*VRR1(65,2)+WPx*VRR1(65,5)
      VRR0(94,6)=4.D0*r1x2Z*VRR0(43,6)+PAx*VRR0(65,6)-4.D0*ExZpE*r1x2Z*VRR1(43,6)+HfxZpE*VRR1(65,3)+WPx*VRR1(65,6)
      VRR0(94,7)=4.D0*r1x2Z*VRR0(43,7)+PAx*VRR0(65,7)-4.D0*ExZpE*r1x2Z*VRR1(43,7)+WPx*VRR1(65,7)
      VRR0(94,8)=4.D0*r1x2Z*VRR0(43,8)+PAx*VRR0(65,8)-4.D0*ExZpE*r1x2Z*VRR1(43,8)+HfxZpE*VRR1(65,4)+WPx*VRR1(65,8)
      VRR0(94,9)=4.D0*r1x2Z*VRR0(43,9)+PAx*VRR0(65,9)-4.D0*ExZpE*r1x2Z*VRR1(43,9)+WPx*VRR1(65,9)
      VRR0(94,10)=4.D0*r1x2Z*VRR0(43,10)+PAx*VRR0(65,10)-4.D0*ExZpE*r1x2Z*VRR1(43,10)+WPx*VRR1(65,10)
      VRR0(95,5)=V(29)+V(31)+PAx*VRR0(66,5)+2.D0*HfxZpE*VRR1(66,2)+WPx*VRR1(66,5)
      VRR0(95,6)=V(33)+V(35)+PAx*VRR0(66,6)+HfxZpE*VRR1(66,3)+WPx*VRR1(66,6)
      VRR0(95,7)=V(37)+V(39)+PAx*VRR0(66,7)+WPx*VRR1(66,7)
      VRR0(95,8)=V(41)+V(43)+PAx*VRR0(66,8)+HfxZpE*VRR1(66,4)+WPx*VRR1(66,8)
      VRR0(95,9)=V(45)+V(47)+PAx*VRR0(66,9)+WPx*VRR1(66,9)
      VRR0(95,10)=V(49)+V(51)+PAx*VRR0(66,10)+WPx*VRR1(66,10)
      VRR0(96,5)=2.D0*V(52)-2.D0*V(53)+2.D0*V(54)+PAx*VRR0(67,5)+WPx*VRR1(67,5)
      VRR0(96,6)=2.D0*V(55)-2.D0*V(56)+V(57)+PAx*VRR0(67,6)+WPx*VRR1(67,6)
      VRR0(96,7)=2.D0*V(58)-2.D0*V(59)+PAx*VRR0(67,7)+WPx*VRR1(67,7)
      VRR0(96,8)=2.D0*V(60)-2.D0*V(61)+V(62)+PAx*VRR0(67,8)+WPx*VRR1(67,8)
      VRR0(96,9)=2.D0*V(63)-2.D0*V(64)+PAx*VRR0(67,9)+WPx*VRR1(67,9)
      VRR0(96,10)=2.D0*V(65)-2.D0*V(66)+PAx*VRR0(67,10)+WPx*VRR1(67,10)
      VRR0(97,5)=V(29)+V(31)+PAy*VRR0(67,5)+WPy*VRR1(67,5)
      VRR0(97,6)=V(33)+V(35)+V(54)+PAy*VRR0(67,6)+WPy*VRR1(67,6)
      VRR0(97,7)=V(37)+V(39)+2.D0*V(57)+PAy*VRR0(67,7)+WPy*VRR1(67,7)
      VRR0(97,8)=V(41)+V(43)+PAy*VRR0(67,8)+WPy*VRR1(67,8)
      VRR0(97,9)=V(45)+V(47)+V(62)+PAy*VRR0(67,9)+WPy*VRR1(67,9)
      VRR0(97,10)=V(49)+V(51)+PAy*VRR0(67,10)+WPy*VRR1(67,10)
      VRR0(98,5)=4.D0*V(52)-4.D0*V(53)+PAy*VRR0(68,5)+WPy*VRR1(68,5)
      VRR0(98,6)=4.D0*V(55)-4.D0*V(56)+PAy*VRR0(68,6)+HfxZpE*VRR1(68,2)+WPy*VRR1(68,6)
      VRR0(98,7)=4.D0*V(58)-4.D0*V(59)+PAy*VRR0(68,7)+2.D0*HfxZpE*VRR1(68,3)+WPy*VRR1(68,7)
      VRR0(98,8)=4.D0*V(60)-4.D0*V(61)+PAy*VRR0(68,8)+WPy*VRR1(68,8)
      VRR0(98,9)=4.D0*V(63)-4.D0*V(64)+PAy*VRR0(68,9)+HfxZpE*VRR1(68,4)+WPy*VRR1(68,9)
      VRR0(98,10)=4.D0*V(65)-4.D0*V(66)+PAy*VRR0(68,10)+WPy*VRR1(68,10)
      VRR0(99,5)=5.D0*r1x2Z*VRR0(46,5)+PAy*VRR0(69,5)-5.D0*ExZpE*r1x2Z*VRR1(46,5)+WPy*VRR1(69,5)
      VRR0(99,6)=5.D0*r1x2Z*VRR0(46,6)+PAy*VRR0(69,6)-5.D0*ExZpE*r1x2Z*VRR1(46,6)+HfxZpE*VRR1(69,2)+WPy*VRR1(69,6)
      VRR0(99,7)=5.D0*r1x2Z*VRR0(46,7)+PAy*VRR0(69,7)-5.D0*ExZpE*r1x2Z*VRR1(46,7)+2.D0*HfxZpE*VRR1(69,3)+WPy*VRR1(69,7)
      VRR0(99,8)=5.D0*r1x2Z*VRR0(46,8)+PAy*VRR0(69,8)-5.D0*ExZpE*r1x2Z*VRR1(46,8)+WPy*VRR1(69,8)
      VRR0(99,9)=5.D0*r1x2Z*VRR0(46,9)+PAy*VRR0(69,9)-5.D0*ExZpE*r1x2Z*VRR1(46,9)+HfxZpE*VRR1(69,4)+WPy*VRR1(69,9)
      VRR0(99,10)=5.D0*r1x2Z*VRR0(46,10)+PAy*VRR0(69,10)-5.D0*ExZpE*r1x2Z*VRR1(46,10)+WPy*VRR1(69,10)
      VRR0(100,5)=4.D0*V(67)-4.D0*V(68)+PAx*VRR0(70,5)+2.D0*HfxZpE*VRR1(70,2)+WPx*VRR1(70,5)
      VRR0(100,6)=4.D0*V(69)-4.D0*V(70)+PAx*VRR0(70,6)+HfxZpE*VRR1(70,3)+WPx*VRR1(70,6)
      VRR0(100,7)=4.D0*V(71)-4.D0*V(72)+PAx*VRR0(70,7)+WPx*VRR1(70,7)
      VRR0(100,8)=4.D0*V(73)-4.D0*V(74)+PAx*VRR0(70,8)+HfxZpE*VRR1(70,4)+WPx*VRR1(70,8)
      VRR0(100,9)=4.D0*V(75)-4.D0*V(76)+PAx*VRR0(70,9)+WPx*VRR1(70,9)
      VRR0(100,10)=4.D0*V(77)-4.D0*V(78)+PAx*VRR0(70,10)+WPx*VRR1(70,10)
      VRR0(101,5)=V(80)+V(82)+PAx*VRR0(71,5)+2.D0*HfxZpE*VRR1(71,2)+WPx*VRR1(71,5)
      VRR0(101,6)=V(84)+V(86)+PAx*VRR0(71,6)+HfxZpE*VRR1(71,3)+WPx*VRR1(71,6)
      VRR0(101,7)=V(88)+V(90)+PAx*VRR0(71,7)+WPx*VRR1(71,7)
      VRR0(101,8)=V(92)+V(94)+PAx*VRR0(71,8)+HfxZpE*VRR1(71,4)+WPx*VRR1(71,8)
      VRR0(101,9)=V(96)+V(98)+PAx*VRR0(71,9)+WPx*VRR1(71,9)
      VRR0(101,10)=V(100)+V(102)+PAx*VRR0(71,10)+WPx*VRR1(71,10)
      VRR0(102,5)=2.D0*V(103)-2.D0*V(104)+2.D0*V(105)+PAx*VRR0(72,5)+WPx*VRR1(72,5)
      VRR0(102,6)=2.D0*V(106)-2.D0*V(107)+V(108)+PAx*VRR0(72,6)+WPx*VRR1(72,6)
      VRR0(102,7)=2.D0*V(109)-2.D0*V(110)+PAx*VRR0(72,7)+WPx*VRR1(72,7)
      VRR0(102,8)=2.D0*V(111)-2.D0*V(112)+V(113)+PAx*VRR0(72,8)+WPx*VRR1(72,8)
      VRR0(102,9)=2.D0*V(114)-2.D0*V(115)+PAx*VRR0(72,9)+WPx*VRR1(72,9)
      VRR0(102,10)=2.D0*V(116)-2.D0*V(117)+PAx*VRR0(72,10)+WPx*VRR1(72,10)
      VRR0(103,5)=2.D0*V(79)-2.D0*V(81)+PAy*VRR0(72,5)+WPy*VRR1(72,5)
      VRR0(103,6)=2.D0*V(83)-2.D0*V(85)+V(105)+PAy*VRR0(72,6)+WPy*VRR1(72,6)
      VRR0(103,7)=2.D0*V(87)-2.D0*V(89)+2.D0*V(108)+PAy*VRR0(72,7)+WPy*VRR1(72,7)
      VRR0(103,8)=2.D0*V(91)-2.D0*V(93)+PAy*VRR0(72,8)+WPy*VRR1(72,8)
      VRR0(103,9)=2.D0*V(95)-2.D0*V(97)+V(113)+PAy*VRR0(72,9)+WPy*VRR1(72,9)
      VRR0(103,10)=2.D0*V(99)-2.D0*V(101)+PAy*VRR0(72,10)+WPy*VRR1(72,10)
      VRR0(104,5)=V(118)+V(119)+PAy*VRR0(73,5)+WPy*VRR1(73,5)
      VRR0(104,6)=V(120)+V(121)+PAy*VRR0(73,6)+HfxZpE*VRR1(73,2)+WPy*VRR1(73,6)
      VRR0(104,7)=V(122)+V(123)+PAy*VRR0(73,7)+2.D0*HfxZpE*VRR1(73,3)+WPy*VRR1(73,7)
      VRR0(104,8)=V(124)+V(125)+PAy*VRR0(73,8)+WPy*VRR1(73,8)
      VRR0(104,9)=V(126)+V(127)+PAy*VRR0(73,9)+HfxZpE*VRR1(73,4)+WPy*VRR1(73,9)
      VRR0(104,10)=V(128)+V(129)+PAy*VRR0(73,10)+WPy*VRR1(73,10)
      VRR0(105,5)=4.D0*V(130)-4.D0*V(131)+PAy*VRR0(74,5)+WPy*VRR1(74,5)
      VRR0(105,6)=4.D0*V(132)-4.D0*V(133)+PAy*VRR0(74,6)+HfxZpE*VRR1(74,2)+WPy*VRR1(74,6)
      VRR0(105,7)=4.D0*V(134)-4.D0*V(135)+PAy*VRR0(74,7)+2.D0*HfxZpE*VRR1(74,3)+WPy*VRR1(74,7)
      VRR0(105,8)=4.D0*V(136)-4.D0*V(137)+PAy*VRR0(74,8)+WPy*VRR1(74,8)
      VRR0(105,9)=4.D0*V(138)-4.D0*V(139)+PAy*VRR0(74,9)+HfxZpE*VRR1(74,4)+WPy*VRR1(74,9)
      VRR0(105,10)=4.D0*V(140)-4.D0*V(141)+PAy*VRR0(74,10)+WPy*VRR1(74,10)
      VRR0(106,5)=3.D0*V(142)-3.D0*V(143)+2.D0*V(144)+PAx*VRR0(75,5)+WPx*VRR1(75,5)
      VRR0(106,6)=3.D0*V(145)-3.D0*V(146)+V(147)+PAx*VRR0(75,6)+WPx*VRR1(75,6)
      VRR0(106,7)=3.D0*V(148)-3.D0*V(149)+PAx*VRR0(75,7)+WPx*VRR1(75,7)
      VRR0(106,8)=3.D0*V(150)-3.D0*V(151)+V(152)+PAx*VRR0(75,8)+WPx*VRR1(75,8)
      VRR0(106,9)=3.D0*V(153)-3.D0*V(154)+PAx*VRR0(75,9)+WPx*VRR1(75,9)
      VRR0(106,10)=3.D0*V(155)-3.D0*V(156)+PAx*VRR0(75,10)+WPx*VRR1(75,10)
      VRR0(107,5)=V(158)+V(160)+2.D0*V(161)+PAx*VRR0(76,5)+WPx*VRR1(76,5)
      VRR0(107,6)=V(163)+V(165)+V(166)+PAx*VRR0(76,6)+WPx*VRR1(76,6)
      VRR0(107,7)=V(168)+V(170)+PAx*VRR0(76,7)+WPx*VRR1(76,7)
      VRR0(107,8)=V(172)+V(174)+V(175)+PAx*VRR0(76,8)+WPx*VRR1(76,8)
      VRR0(107,9)=V(177)+V(179)+PAx*VRR0(76,9)+WPx*VRR1(76,9)
      VRR0(107,10)=V(181)+V(183)+PAx*VRR0(76,10)+WPx*VRR1(76,10)
      VRR0(108,5)=2.D0*V(28)-2.D0*V(30)+PAz*VRR0(72,5)+WPz*VRR1(72,5)
      VRR0(108,6)=2.D0*V(32)-2.D0*V(34)+PAz*VRR0(72,6)+WPz*VRR1(72,6)
      VRR0(108,7)=2.D0*V(36)-2.D0*V(38)+PAz*VRR0(72,7)+WPz*VRR1(72,7)
      VRR0(108,8)=2.D0*V(40)-2.D0*V(42)+V(105)+PAz*VRR0(72,8)+WPz*VRR1(72,8)
      VRR0(108,9)=2.D0*V(44)-2.D0*V(46)+V(108)+PAz*VRR0(72,9)+WPz*VRR1(72,9)
      VRR0(108,10)=2.D0*V(48)-2.D0*V(50)+2.D0*V(113)+PAz*VRR0(72,10)+WPz*VRR1(72,10)
      VRR0(109,5)=V(158)+V(160)+PAy*VRR0(77,5)+WPy*VRR1(77,5)
      VRR0(109,6)=V(163)+V(165)+V(184)+PAy*VRR0(77,6)+WPy*VRR1(77,6)
      VRR0(109,7)=V(168)+V(170)+2.D0*V(185)+PAy*VRR0(77,7)+WPy*VRR1(77,7)
      VRR0(109,8)=V(172)+V(174)+PAy*VRR0(77,8)+WPy*VRR1(77,8)
      VRR0(109,9)=V(177)+V(179)+V(186)+PAy*VRR0(77,9)+WPy*VRR1(77,9)
      VRR0(109,10)=V(181)+V(183)+PAy*VRR0(77,10)+WPy*VRR1(77,10)
      VRR0(110,5)=3.D0*V(187)-3.D0*V(188)+PAy*VRR0(78,5)+WPy*VRR1(78,5)
      VRR0(110,6)=3.D0*V(189)-3.D0*V(190)+V(191)+PAy*VRR0(78,6)+WPy*VRR1(78,6)
      VRR0(110,7)=3.D0*V(192)-3.D0*V(193)+2.D0*V(194)+PAy*VRR0(78,7)+WPy*VRR1(78,7)
      VRR0(110,8)=3.D0*V(195)-3.D0*V(196)+PAy*VRR0(78,8)+WPy*VRR1(78,8)
      VRR0(110,9)=3.D0*V(197)-3.D0*V(198)+V(199)+PAy*VRR0(78,9)+WPy*VRR1(78,9)
      VRR0(110,10)=3.D0*V(200)-3.D0*V(201)+PAy*VRR0(78,10)+WPy*VRR1(78,10)
      VRR0(111,5)=3.D0*V(67)-3.D0*V(68)+PAz*VRR0(75,5)+WPz*VRR1(75,5)
      VRR0(111,6)=3.D0*V(69)-3.D0*V(70)+PAz*VRR0(75,6)+WPz*VRR1(75,6)
      VRR0(111,7)=3.D0*V(71)-3.D0*V(72)+PAz*VRR0(75,7)+WPz*VRR1(75,7)
      VRR0(111,8)=3.D0*V(73)-3.D0*V(74)+V(144)+PAz*VRR0(75,8)+WPz*VRR1(75,8)
      VRR0(111,9)=3.D0*V(75)-3.D0*V(76)+V(147)+PAz*VRR0(75,9)+WPz*VRR1(75,9)
      VRR0(111,10)=3.D0*V(77)-3.D0*V(78)+2.D0*V(152)+PAz*VRR0(75,10)+WPz*VRR1(75,10)
      VRR0(112,5)=V(80)+V(82)+PAz*VRR0(76,5)+WPz*VRR1(76,5)
      VRR0(112,6)=V(84)+V(86)+PAz*VRR0(76,6)+WPz*VRR1(76,6)
      VRR0(112,7)=V(88)+V(90)+PAz*VRR0(76,7)+WPz*VRR1(76,7)
      VRR0(112,8)=V(92)+V(94)+V(161)+PAz*VRR0(76,8)+WPz*VRR1(76,8)
      VRR0(112,9)=V(96)+V(98)+V(166)+PAz*VRR0(76,9)+WPz*VRR1(76,9)
      VRR0(112,10)=V(100)+V(102)+2.D0*V(175)+PAz*VRR0(76,10)+WPz*VRR1(76,10)
      VRR0(113,5)=V(118)+V(119)+PAz*VRR0(77,5)+WPz*VRR1(77,5)
      VRR0(113,6)=V(120)+V(121)+PAz*VRR0(77,6)+WPz*VRR1(77,6)
      VRR0(113,7)=V(122)+V(123)+PAz*VRR0(77,7)+WPz*VRR1(77,7)
      VRR0(113,8)=V(124)+V(125)+V(184)+PAz*VRR0(77,8)+WPz*VRR1(77,8)
      VRR0(113,9)=V(126)+V(127)+V(185)+PAz*VRR0(77,9)+WPz*VRR1(77,9)
      VRR0(113,10)=V(128)+V(129)+2.D0*V(186)+PAz*VRR0(77,10)+WPz*VRR1(77,10)
      VRR0(114,5)=3.D0*V(130)-3.D0*V(131)+PAz*VRR0(78,5)+WPz*VRR1(78,5)
      VRR0(114,6)=3.D0*V(132)-3.D0*V(133)+PAz*VRR0(78,6)+WPz*VRR1(78,6)
      VRR0(114,7)=3.D0*V(134)-3.D0*V(135)+PAz*VRR0(78,7)+WPz*VRR1(78,7)
      VRR0(114,8)=3.D0*V(136)-3.D0*V(137)+V(191)+PAz*VRR0(78,8)+WPz*VRR1(78,8)
      VRR0(114,9)=3.D0*V(138)-3.D0*V(139)+V(194)+PAz*VRR0(78,9)+WPz*VRR1(78,9)
      VRR0(114,10)=3.D0*V(140)-3.D0*V(141)+2.D0*V(199)+PAz*VRR0(78,10)+WPz*VRR1(78,10)
      VRR0(115,5)=4.D0*V(142)-4.D0*V(143)+PAz*VRR0(79,5)+WPz*VRR1(79,5)
      VRR0(115,6)=4.D0*V(145)-4.D0*V(146)+PAz*VRR0(79,6)+WPz*VRR1(79,6)
      VRR0(115,7)=4.D0*V(148)-4.D0*V(149)+PAz*VRR0(79,7)+WPz*VRR1(79,7)
      VRR0(115,8)=4.D0*V(150)-4.D0*V(151)+PAz*VRR0(79,8)+HfxZpE*VRR1(79,2)+WPz*VRR1(79,8)
      VRR0(115,9)=4.D0*V(153)-4.D0*V(154)+PAz*VRR0(79,9)+HfxZpE*VRR1(79,3)+WPz*VRR1(79,9)
      VRR0(115,10)=4.D0*V(155)-4.D0*V(156)+PAz*VRR0(79,10)+2.D0*HfxZpE*VRR1(79,4)+WPz*VRR1(79,10)
      VRR0(116,5)=4.D0*V(157)-4.D0*V(159)+PAz*VRR0(80,5)+WPz*VRR1(80,5)
      VRR0(116,6)=4.D0*V(162)-4.D0*V(164)+PAz*VRR0(80,6)+WPz*VRR1(80,6)
      VRR0(116,7)=4.D0*V(167)-4.D0*V(169)+PAz*VRR0(80,7)+WPz*VRR1(80,7)
      VRR0(116,8)=4.D0*V(171)-4.D0*V(173)+PAz*VRR0(80,8)+HfxZpE*VRR1(80,2)+WPz*VRR1(80,8)
      VRR0(116,9)=4.D0*V(176)-4.D0*V(178)+PAz*VRR0(80,9)+HfxZpE*VRR1(80,3)+WPz*VRR1(80,9)
      VRR0(116,10)=4.D0*V(180)-4.D0*V(182)+PAz*VRR0(80,10)+2.D0*HfxZpE*VRR1(80,4)+WPz*VRR1(80,10)
      VRR0(117,5)=4.D0*V(187)-4.D0*V(188)+PAz*VRR0(81,5)+WPz*VRR1(81,5)
      VRR0(117,6)=4.D0*V(189)-4.D0*V(190)+PAz*VRR0(81,6)+WPz*VRR1(81,6)
      VRR0(117,7)=4.D0*V(192)-4.D0*V(193)+PAz*VRR0(81,7)+WPz*VRR1(81,7)
      VRR0(117,8)=4.D0*V(195)-4.D0*V(196)+PAz*VRR0(81,8)+HfxZpE*VRR1(81,2)+WPz*VRR1(81,8)
      VRR0(117,9)=4.D0*V(197)-4.D0*V(198)+PAz*VRR0(81,9)+HfxZpE*VRR1(81,3)+WPz*VRR1(81,9)
      VRR0(117,10)=4.D0*V(200)-4.D0*V(201)+PAz*VRR0(81,10)+2.D0*HfxZpE*VRR1(81,4)+WPz*VRR1(81,10)
      VRR0(118,5)=5.D0*r1x2Z*VRR0(54,5)+PAz*VRR0(82,5)-5.D0*ExZpE*r1x2Z*VRR1(54,5)+WPz*VRR1(82,5)
      VRR0(118,6)=5.D0*r1x2Z*VRR0(54,6)+PAz*VRR0(82,6)-5.D0*ExZpE*r1x2Z*VRR1(54,6)+WPz*VRR1(82,6)
      VRR0(118,7)=5.D0*r1x2Z*VRR0(54,7)+PAz*VRR0(82,7)-5.D0*ExZpE*r1x2Z*VRR1(54,7)+WPz*VRR1(82,7)
      VRR0(118,8)=5.D0*r1x2Z*VRR0(54,8)+PAz*VRR0(82,8)-5.D0*ExZpE*r1x2Z*VRR1(54,8)+HfxZpE*VRR1(82,2)+WPz*VRR1(82,8)
      VRR0(118,9)=5.D0*r1x2Z*VRR0(54,9)+PAz*VRR0(82,9)-5.D0*ExZpE*r1x2Z*VRR1(54,9)+HfxZpE*VRR1(82,3)+WPz*VRR1(82,9)
      VRR0(118,10)=5.D0*r1x2Z*VRR0(54,10)+PAz*VRR0(82,10)-5.D0*ExZpE*r1x2Z*VRR1(54,10)+2.D0*HfxZpE*VRR1(82,4)+WPz*VRR1(82,10)
      VRR0(119,5)=5.D0*r1x2Z*VRR0(55,5)+PAz*VRR0(83,5)-5.D0*ExZpE*r1x2Z*VRR1(55,5)+WPz*VRR1(83,5)
      VRR0(119,6)=5.D0*r1x2Z*VRR0(55,6)+PAz*VRR0(83,6)-5.D0*ExZpE*r1x2Z*VRR1(55,6)+WPz*VRR1(83,6)
      VRR0(119,7)=5.D0*r1x2Z*VRR0(55,7)+PAz*VRR0(83,7)-5.D0*ExZpE*r1x2Z*VRR1(55,7)+WPz*VRR1(83,7)
      VRR0(119,8)=5.D0*r1x2Z*VRR0(55,8)+PAz*VRR0(83,8)-5.D0*ExZpE*r1x2Z*VRR1(55,8)+HfxZpE*VRR1(83,2)+WPz*VRR1(83,8)
      VRR0(119,9)=5.D0*r1x2Z*VRR0(55,9)+PAz*VRR0(83,9)-5.D0*ExZpE*r1x2Z*VRR1(55,9)+HfxZpE*VRR1(83,3)+WPz*VRR1(83,9)
      VRR0(119,10)=5.D0*r1x2Z*VRR0(55,10)+PAz*VRR0(83,10)-5.D0*ExZpE*r1x2Z*VRR1(55,10)+2.D0*HfxZpE*VRR1(83,4)+WPz*VRR1(83,10)
      VRR0(120,5)=6.D0*r1x2Z*VRR0(56,5)+PAz*VRR0(84,5)-6.D0*ExZpE*r1x2Z*VRR1(56,5)+WPz*VRR1(84,5)
      VRR0(120,6)=6.D0*r1x2Z*VRR0(56,6)+PAz*VRR0(84,6)-6.D0*ExZpE*r1x2Z*VRR1(56,6)+WPz*VRR1(84,6)
      VRR0(120,7)=6.D0*r1x2Z*VRR0(56,7)+PAz*VRR0(84,7)-6.D0*ExZpE*r1x2Z*VRR1(56,7)+WPz*VRR1(84,7)
      VRR0(120,8)=6.D0*r1x2Z*VRR0(56,8)+PAz*VRR0(84,8)-6.D0*ExZpE*r1x2Z*VRR1(56,8)+HfxZpE*VRR1(84,2)+WPz*VRR1(84,8)
      VRR0(120,9)=6.D0*r1x2Z*VRR0(56,9)+PAz*VRR0(84,9)-6.D0*ExZpE*r1x2Z*VRR1(56,9)+HfxZpE*VRR1(84,3)+WPz*VRR1(84,9)
      VRR0(120,10)=6.D0*r1x2Z*VRR0(56,10)+PAz*VRR0(84,10)-6.D0*ExZpE*r1x2Z*VRR1(56,10)+2.D0*HfxZpE*VRR1(84,4)+WPz*VRR1(84,10)
END SUBROUTINE VRRj0d0