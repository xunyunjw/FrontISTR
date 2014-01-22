module hecmw_solver_misc_33

      contains

!C
!C***
!C*** hecmw_matvec_33
!C***
!C
      subroutine hecmw_matvec_33 (hecMESH, hecMAT, X, Y, COMMtime)
      use hecmw_util
      use m_hecmw_comm_f
      use hecmw_matrix_contact
      use hecmw_matrix_misc
      use jad_type
      !$ use omp_lib

      implicit none
      type (hecmwST_local_mesh), intent(in) :: hecMESH
      type (hecmwST_matrix), intent(in), target :: hecMAT
      real(kind=kreal), intent(in) :: X(:)
      real(kind=kreal), intent(out) :: Y(:)
      real(kind=kreal), intent(inout), optional :: COMMtime

      real(kind=kreal) :: START_TIME, END_TIME
      integer(kind=kint) :: i, j, jS, jE, in
      real(kind=kreal) :: YV1, YV2, YV3, X1, X2, X3

      integer(kind=kint) :: N, NP
      integer(kind=kint), pointer :: indexL(:), itemL(:), indexU(:), itemU(:)
      real(kind=kreal), pointer :: AL(:), AU(:), D(:)

      ! added for turning >>>
      integer, parameter :: numOfBlockPerThread = 100
      logical, save :: isFirst = .true.
      integer, save :: numOfThread = 1
      integer, save, allocatable :: startPos(:), endPos(:)
      integer(kind=kint), save :: sectorCacheSize0, sectorCacheSize1
      integer(kind=kint) :: threadNum, blockNum, numOfBlock
      integer(kind=kint) :: numOfElement, elementCount, blockIndex
      real(kind=kreal) :: numOfElementPerBlock
      ! <<< added for turning

      IF (hecmw_mat_get_usejad(hecMAT).ne.0) THEN
        call JAD_MATVEC(hecMESH, hecMAT, X, Y, COMMtime)
      ELSE

      N = hecMAT%N
      NP = hecMAT%NP
      indexL => hecMAT%indexL
      indexU => hecMAT%indexU
      itemL => hecMAT%itemL
      itemU => hecMAT%itemU
      AL => hecMAT%AL
      AU => hecMAT%AU
      D => hecMAT%D

      ! added for turning >>>
      if (isFirst .eqv. .true.) then
        !$ numOfThread = omp_get_max_threads()
        numOfBlock = numOfThread * numOfBlockPerThread
        allocate (startPos(0 : numOfBlock - 1), endPos(0 : numOfBlock - 1))
        numOfElement = N + indexL(N) + indexU(N)
        numOfElementPerBlock = dble(numOfElement) / numOfBlock
        blockNum = 0
        elementCount = 0
        startPos(blockNum) = 1
        do i= 1, N
          elementCount = elementCount + 1
          elementCount = elementCount + (indexL(i) - indexL(i-1))
          elementCount = elementCount + (indexU(i) - indexU(i-1))
          if (elementCount > (blockNum + 1) * numOfElementPerBlock) then
            endPos(blockNum) = i
            write(9000+hecMESH%my_rank,*) mod(blockNum, numOfThread), &
                 startPos(blockNum), endPos(blockNum)
            blockNum = blockNum + 1
            startPos(blockNum) = i + 1
            if (blockNum == (numOfBlock - 1)) exit
          endif
        enddo
        endPos(blockNum) = N
        write(9000+hecMESH%my_rank,*) mod(blockNum, numOfThread), &
             startPos(blockNum), endPos(blockNum)

        ! calculate sector cache size
        sectorCacheSize1 = int((dble(NP) * 3 * kreal / (4096 * 128)) + 0.999)
        if (sectorCacheSize1 > 6 ) sectorCacheSize1 = 6
        sectorCacheSize0 = 12 - sectorCacheSize1
        write(*,*) 'X size =', N * 3 * kreal, '[byte]  ', &
                   'sectorCache0 =', sectorCacheSize0, '[way]  ', &
                   'sectorCache1 =', sectorCacheSize1, '[way]'

        isFirst = .false.
      endif
      ! <<< added for turning

      START_TIME= HECMW_WTIME()
      call hecmw_update_3_R (hecMESH, X, NP)
      END_TIME= HECMW_WTIME()
      if (present(COMMtime)) COMMtime = COMMtime + END_TIME - START_TIME

!call fapp_start("loopInMatvec33", 1, 0)
!call start_collection("loopInMatvec33")

!xx!OCL CACHE_SECTOR_SIZE(sectorCacheSize0,sectorCacheSize1)
!xx!OCL CACHE_SUBSECTOR_ASSIGN(X)

!$OMP PARALLEL DEFAULT(NONE) &
!$OMP&PRIVATE(i,X1,X2,X3,YV1,YV2,YV3,jS,jE,j,in,threadNum,blockNum,blockIndex) &
!$OMP&SHARED(D,AL,AU,indexL,itemL,indexU,itemU,X,Y,startPos,endPos,numOfThread)
      threadNum = 0
      !$ threadNum = omp_get_thread_num()
      do blockNum = 0 , numOfBlockPerThread - 1
        blockIndex = blockNum * numOfThread  + threadNum
        do i = startPos(blockIndex), endPos(blockIndex)
          X1= X(3*i-2)
          X2= X(3*i-1)
          X3= X(3*i  )
          YV1= D(9*i-8)*X1 + D(9*i-7)*X2 + D(9*i-6)*X3
          YV2= D(9*i-5)*X1 + D(9*i-4)*X2 + D(9*i-3)*X3
          YV3= D(9*i-2)*X1 + D(9*i-1)*X2 + D(9*i  )*X3

          jS= indexL(i-1) + 1
          jE= indexL(i  )
          do j= jS, jE
            in  = itemL(j)
            X1= X(3*in-2)
            X2= X(3*in-1)
            X3= X(3*in  )
            YV1= YV1 + AL(9*j-8)*X1 + AL(9*j-7)*X2 + AL(9*j-6)*X3
            YV2= YV2 + AL(9*j-5)*X1 + AL(9*j-4)*X2 + AL(9*j-3)*X3
            YV3= YV3 + AL(9*j-2)*X1 + AL(9*j-1)*X2 + AL(9*j  )*X3
          enddo
          jS= indexU(i-1) + 1
          jE= indexU(i  )
          do j= jS, jE
            in  = itemU(j)
            X1= X(3*in-2)
            X2= X(3*in-1)
            X3= X(3*in  )
            YV1= YV1 + AU(9*j-8)*X1 + AU(9*j-7)*X2 + AU(9*j-6)*X3
            YV2= YV2 + AU(9*j-5)*X1 + AU(9*j-4)*X2 + AU(9*j-3)*X3
            YV3= YV3 + AU(9*j-2)*X1 + AU(9*j-1)*X2 + AU(9*j  )*X3
          enddo
          Y(3*i-2)= YV1
          Y(3*i-1)= YV2
          Y(3*i  )= YV3
        enddo
      enddo
!$OMP END PARALLEL

!xx!OCL END_CACHE_SUBSECTOR
!xx!OCL END_CACHE_SECTOR_SIZE

!call stop_collection("loopInMatvec33")
!call fapp_stop("loopInMatvec33", 1, 0)

      ENDIF

      call hecmw_cmat_multvec_add( hecMAT%cmat, X, Y, NP * hecMAT%NDOF )

      end subroutine hecmw_matvec_33

!C
!C***
!C*** hecmw_matresid_33
!C***
!C
      subroutine hecmw_matresid_33 (hecMESH, hecMAT, X, B, R, COMMtime)
      use hecmw_util
      implicit none
      type (hecmwST_local_mesh), intent(in) :: hecMESH
      type (hecmwST_matrix), intent(in)     :: hecMAT
      real(kind=kreal), intent(in) :: X(:), B(:)
      real(kind=kreal), intent(out) :: R(:)
      real(kind=kreal), intent(inout), optional :: COMMtime

      integer(kind=kint) :: i
      real(kind=kreal) :: Tcomm = 0.d0

      call hecmw_matvec_33 (hecMESH, hecMAT, X, R, Tcomm)
      if (present(COMMtime)) COMMtime = COMMtime + Tcomm
      do i = 1, hecMAT%N * 3
        R(i) = B(i) - R(i)
      enddo

      end subroutine hecmw_matresid_33

!C
!C***
!C*** hecmw_rel_resid_L2_33
!C***
!C
      function hecmw_rel_resid_L2_33 (hecMESH, hecMAT, COMMtime)
      use hecmw_util
      use hecmw_solver_misc
      implicit none
      real(kind=kreal) :: hecmw_rel_resid_L2_33
      type ( hecmwST_local_mesh ), intent(in) :: hecMESH
      type ( hecmwST_matrix     ), intent(in) :: hecMAT
      real(kind=kreal), intent(inout), optional :: COMMtime

      real(kind=kreal), allocatable :: r(:)
      real(kind=kreal) :: bnorm2, rnorm2
      real(kind=kreal) :: Tcomm=0.d0

      allocate(r(hecMAT%NDOF*hecMAT%NP))

      call hecmw_InnerProduct_R(hecMESH, hecMAT%NDOF, &
           hecMAT%B, hecMAT%B, bnorm2, Tcomm)
      call hecmw_matresid_33(hecMESH, hecMAT, hecMAT%X, hecMAT%B, r, Tcomm)
      call hecmw_InnerProduct_R(hecMESH, hecMAT%NDOF, r, r, rnorm2, Tcomm)
      hecmw_rel_resid_L2_33 = sqrt(rnorm2 / bnorm2)

      if (present(COMMtime)) COMMtime = COMMtime + Tcomm

      deallocate(r)
      end function hecmw_rel_resid_L2_33

!C
!C***
!C*** hecmw_Tvec_33
!C***
!C
      subroutine hecmw_Tvec_33 (hecMESH, X, Y, COMMtime)
      use hecmw_util
      use m_hecmw_comm_f
      implicit none
      type (hecmwST_local_mesh), intent(in) :: hecMESH
      real(kind=kreal), intent(in) :: X(:)
      real(kind=kreal), intent(out) :: Y(:)
      real(kind=kreal), intent(inout) :: COMMtime

      real(kind=kreal) :: START_TIME, END_TIME
      integer(kind=kint) :: i, j, jj, k, kk

      START_TIME= HECMW_WTIME()
      call hecmw_update_3_R (hecMESH, X, hecMESH%n_node)
      END_TIME= HECMW_WTIME()
      COMMtime = COMMtime + END_TIME - START_TIME

      do i= 1, hecMESH%nn_internal * hecMESH%n_dof
        Y(i)= X(i)
      enddo

      do i= 1, hecMESH%mpc%n_mpc
        k = hecMESH%mpc%mpc_index(i-1) + 1
        kk = 3 * (hecMESH%mpc%mpc_item(k) - 1) + hecMESH%mpc%mpc_dof(k)
        Y(kk) = 0.d0
        do j= hecMESH%mpc%mpc_index(i-1) + 2, hecMESH%mpc%mpc_index(i)
          jj = 3 * (hecMESH%mpc%mpc_item(j) - 1) + hecMESH%mpc%mpc_dof(j)
          Y(kk) = Y(kk) - hecMESH%mpc%mpc_val(j) * X(jj)
        enddo
      enddo

      end subroutine hecmw_Tvec_33

!C
!C***
!C*** hecmw_Ttvec_33
!C***
!C
      subroutine hecmw_Ttvec_33 (hecMESH, X, Y, COMMtime)
      use hecmw_util
      use m_hecmw_comm_f
      implicit none
      type (hecmwST_local_mesh), intent(in) :: hecMESH
      real(kind=kreal), intent(in) :: X(:)
      real(kind=kreal), intent(out) :: Y(:)
      real(kind=kreal), intent(inout) :: COMMtime

      real(kind=kreal) :: START_TIME, END_TIME
      integer(kind=kint) :: i, j, jj, k, kk

      START_TIME= HECMW_WTIME()
      call hecmw_update_3_R (hecMESH, X, hecMESH%n_node)
      END_TIME= HECMW_WTIME()
      COMMtime = COMMtime + END_TIME - START_TIME

      do i= 1, hecMESH%nn_internal * hecMESH%n_dof
        Y(i)= X(i)
      enddo

      do i= 1, hecMESH%mpc%n_mpc
        k = hecMESH%mpc%mpc_index(i-1) + 1
        kk = 3 * (hecMESH%mpc%mpc_item(k) - 1) + hecMESH%mpc%mpc_dof(k)
        Y(kk) = 0.d0
        do j= hecMESH%mpc%mpc_index(i-1) + 2, hecMESH%mpc%mpc_index(i)
          jj = 3 * (hecMESH%mpc%mpc_item(j) - 1) + hecMESH%mpc%mpc_dof(j)
          Y(jj) = Y(jj) - hecMESH%mpc%mpc_val(j) * X(kk)
        enddo
      enddo

      end subroutine hecmw_Ttvec_33

!C
!C***
!C*** hecmw_TtmatTvec_33
!C***
!C
      subroutine hecmw_TtmatTvec_33 (hecMESH, hecMAT, X, Y, W, COMMtime)
      use hecmw_util
      implicit none
      type (hecmwST_local_mesh), intent(in) :: hecMESH
      type (hecmwST_matrix), intent(in)     :: hecMAT
      real(kind=kreal), intent(in) :: X(:)
      real(kind=kreal), intent(out) :: Y(:), W(:)
      real(kind=kreal), intent(inout) :: COMMtime

      call hecmw_Tvec_33(hecMESH, X, Y, COMMtime)
      call hecmw_matvec_33(hecMESH, hecMAT, Y, W, COMMtime)
      call hecmw_Ttvec_33(hecMESH, W, Y, COMMtime)

      end subroutine hecmw_TtmatTvec_33

!C
!C***
!C*** hecmw_precond_33_setup
!C***
!C
      subroutine hecmw_precond_33_setup(hecMAT)
      use hecmw_util
      use hecmw_matrix_misc
      use hecmw_precond_BILU_33
      use hecmw_precond_DIAG_33
      use hecmw_precond_SSOR_33
      implicit none
      type (hecmwST_matrix), intent(inout) :: hecMAT

      integer(kind=kint ) :: PRECOND, iterPREmax

      iterPREmax = hecmw_mat_get_iterpremax( hecMAT )
      if (iterPREmax.le.0) return

      PRECOND = hecmw_mat_get_precond( hecMAT )

      if (PRECOND.le.2) then
        call hecmw_precond_SSOR_33_setup(hecMAT)
      else if (PRECOND.eq.3) then
        call hecmw_precond_DIAG_33_setup(hecMAT)
      else if (PRECOND.eq.10.or.PRECOND.eq.11.or.PRECOND.eq.12) then
        call hecmw_precond_BILU_33_setup(hecMAT)
      endif

      end subroutine hecmw_precond_33_setup

!C
!C***
!C*** hecmw_precond_33_clear
!C***
!C
      subroutine hecmw_precond_33_clear(hecMAT)
      use hecmw_util
      use hecmw_matrix_misc
      use hecmw_precond_BILU_33
      use hecmw_precond_DIAG_33
      use hecmw_precond_SSOR_33
      implicit none
      type (hecmwST_matrix), intent(inout) :: hecMAT

      integer(kind=kint ) :: PRECOND, iterPREmax

      iterPREmax = hecmw_mat_get_iterpremax( hecMAT )
      if (iterPREmax.le.0) return

      PRECOND = hecmw_mat_get_precond( hecMAT )

      if (PRECOND.le.2) then
        call hecmw_precond_SSOR_33_clear(hecMAT)
      else if (PRECOND.eq.3) then
        call hecmw_precond_DIAG_33_clear()
      else if (PRECOND.eq.10.or.PRECOND.eq.11.or.PRECOND.eq.12) then
        call hecmw_precond_BILU_33_clear()
      endif

      end subroutine hecmw_precond_33_clear

!C
!C***
!C*** hecmw_precond_33
!C***
!C
      subroutine hecmw_precond_33(hecMESH, hecMAT, R, Z, ZP, COMMtime)
      use hecmw_util
      use hecmw_matrix_misc
      use hecmw_precond_BILU_33
      use hecmw_precond_DIAG_33
      use hecmw_precond_SSOR_33
      implicit none
      type (hecmwST_local_mesh), intent(in) :: hecMESH
      type (hecmwST_matrix), intent(in)     :: hecMAT
      real(kind=kreal), intent(in) :: R(:)
      real(kind=kreal), intent(out) :: Z(:), ZP(:)
      real(kind=kreal), intent(inout) :: COMMtime

      integer(kind=kint ) :: N, NP, NNDOF, NPNDOF
      integer(kind=kint ) :: PRECOND, iterPREmax
      integer(kind=kint ) :: i, iterPRE

      N = hecMAT%N
      NP = hecMAT%NP
      NNDOF = N * 3
      NPNDOF = NP * 3
      PRECOND = hecmw_mat_get_precond( hecMAT )
      iterPREmax = hecmw_mat_get_iterpremax( hecMAT )

      if (iterPREmax.le.0) then
        do i= 1, NNDOF
          Z(i)= R(i)
        enddo
        return
      endif

!C===
!C +----------------+
!C | {z}= [Minv]{r} |
!C +----------------+
!C===

      do i= 1, NNDOF
        ZP(i)= R(i)
      enddo
      do i= NNDOF+1, NPNDOF
        ZP(i) = 0.d0
      enddo

      do i= 1, NPNDOF
        Z(i)= 0.d0
      enddo

      do iterPRE= 1, iterPREmax

        if (PRECOND.le.2) then
          call hecmw_precond_SSOR_33_apply(ZP)
        else if (PRECOND.eq.3) then
          call hecmw_precond_DIAG_33_apply(ZP)
        else if (PRECOND.eq.10.or.PRECOND.eq.11.or.PRECOND.eq.12) then
          call hecmw_precond_BILU_33_apply(ZP)
        endif
!C
!C-- additive Schwartz
!C
        do i= 1, NNDOF
          Z(i)= Z(i) + ZP(i)
        enddo

        if (iterPRE.eq.iterPREmax) exit

!C--    {ZP} = {R} - [A] {Z}

        call hecmw_matresid_33 (hecMESH, hecMAT, Z, R, ZP, COMMtime)

      enddo

      end subroutine hecmw_precond_33

!C
!C***
!C*** hecmw_mpc_scale
!C***
!C
      subroutine hecmw_mpc_scale(hecMESH)
      use hecmw_util
      implicit none
      type (hecmwST_local_mesh), intent(inout) :: hecMESH
      integer(kind=kint) :: i, j, k
      real(kind=kreal) :: WVAL

      do i = 1, hecMESH%mpc%n_mpc
        k = hecMESH%mpc%mpc_index(i-1)+1
        WVAL = 1.d0 / hecMESH%mpc%mpc_val(k)
        hecMESH%mpc%mpc_val(k) = 1.d0
        do j = hecMESH%mpc%mpc_index(i-1)+2, hecMESH%mpc%mpc_index(i)
          hecMESH%mpc%mpc_val(j) = hecMESH%mpc%mpc_val(j) * WVAL
        enddo
        hecMESH%mpc%mpc_const(i) = hecMESH%mpc%mpc_const(i) * WVAL
      enddo

      end subroutine hecmw_mpc_scale

!C
!C***
!C*** hecmw_trans_b_33
!C***
!C
      subroutine hecmw_trans_b_33(hecMESH, hecMAT, B, BT, W, COMMtime)
      use hecmw_util
      implicit none
      type (hecmwST_local_mesh), intent(in) :: hecMESH
      type (hecmwST_matrix), intent(in)     :: hecMAT
      real(kind=kreal), intent(in) :: B(:)
      real(kind=kreal), intent(out), target :: BT(:)
      real(kind=kreal), intent(out) :: W(:)
      real(kind=kreal), intent(inout) :: COMMtime

      real(kind=kreal), pointer :: XG(:)
      integer(kind=kint) :: i, k, kk

!C===
!C +---------------------------+
!C | {bt}= [T']({b} - [A]{xg}) |
!C +---------------------------+
!C===
      XG => BT
      XG = 0.d0

!C-- Generate {xg} from mpc_const
      do i = 1, hecMESH%mpc%n_mpc
        k = hecMESH%mpc%mpc_index(i-1) + 1
        kk = 3 * hecMESH%mpc%mpc_item(k) + hecMESH%mpc%mpc_dof(k) - 3
        XG(kk) = hecMESH%mpc%mpc_const(i)
      enddo

!C-- {w} = {b} - [A]{xg}
      call hecmw_matresid_33 (hecMESH, hecMAT, XG, B, W, COMMtime)

!C-- {bt} = [T'] {w}
      call hecmw_Ttvec_33(hecMESH, W, BT, COMMtime)

      end subroutine hecmw_trans_b_33

!C
!C***
!C*** hecmw_tback_x_33
!C***
!C
      subroutine hecmw_tback_x_33(hecMESH, X, W, COMMtime)
      use hecmw_util
      implicit none
      type (hecmwST_local_mesh), intent(in) :: hecMESH
      real(kind=kreal), intent(inout) :: X(:)
      real(kind=kreal), intent(out) :: W(:)
      real(kind=kreal) :: COMMtime

      integer(kind=kint) :: i, k, kk

!C-- {tx} = [T]{x}
      call hecmw_Tvec_33(hecMESH, X, W, COMMtime)

!C-- {x} = {tx} + {xg}

      do i= 1, hecMESH%nn_internal * 3
        X(i)= W(i)
      enddo

      do i = 1, hecMESH%mpc%n_mpc
        k = hecMESH%mpc%mpc_index(i-1) + 1
        kk = 3 * hecMESH%mpc%mpc_item(k) + hecMESH%mpc%mpc_dof(k) - 3
        X(kk) = X(kk) + hecMESH%mpc%mpc_const(i)
      enddo

      end subroutine hecmw_tback_x_33

end module hecmw_solver_misc_33
