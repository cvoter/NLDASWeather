! Program to extract NLDAS forcing variables over a given problem domain
! and interpolate to problem grid via nearest neighbor

! Modified by Carolyn Voter 2014.04.08 and 2014.09.25
! Adjuseted NLDAS filenames to match my downloads (get rid of unique ending numbers with bash script)
! Also switch k values during printing step to be correct (order of variables not correct in original)

! Program reads user-specified batch file containing file paths and domain info
! Batch file is currently hard-wired as batch.get_nldas in current directory
! Batch file must be in the following format:
! "/path_to_top_level_nldas_dir/"
! "/path_to_output_directory/"
! "/path_to_lat-lon_file/lat-lon_file_name.txt"
! nx ny nz                      (note that for forcing data, nz always equals 1)
! x0 y0 z0                      (i.e., ComputationalGrid.Lower.X, --.Lower.Y, --.Lower.Z)
! dx dy dz                      (i.e., ComputationalGrid.DX, etc.)
! start_year start_month start_day start_hour (YYYY MM DD HH)
! end_year end_month end_day end_hour         (YYYY MM DD HH)

! Output vars:
! Downward SW radiation at surface (DSWR) [W/m^2]
! Downward LW radiation at surface (DLWR) [W/m^2]
! Precipitation (APCP) [kg/m^2 (accumulated per hour) --> convert --> kg/m^2/s (precipitation rate)]
! Air temperature (2m) (Temp) [K]
! U-wind speed (10m) (UGRD) [m/s]
! V-wind speed (10m) (VGRD) [m/s]
! Surface air pressure (Press) [Pa]
! Air specific humidity (2m) (SPFH) [kg/kg]

program extract_nldas

 ! Logicals for directory tests:
 logical :: dir_e

 ! Integers for array sizes, loops
 integer i,j,k,ni,nj,npdi,npdj,npdk,lwbdi,lwbdj,upbdi,upbdj,startyear,endyear,startmonth,endmonth
 integer startday,endday,t,t_day,t_month,t_year,t_hour,newmonth,starthour,endhour,done,interp

 ! Reals for lat/lon, input values, output values, grid information
 real*8                dummy1,dummy2,x0,y0,x1,y1,z1,dx,dy,dz
 real*8                lat,lon,GLAT,GLON,DSWR,DLWR,APCP,TMP,UGRD,VGRD,PRESS,SPFH
 real*8,allocatable :: data_in(:,:,:)
 character*200         outdir,filename,gribfile,gribdate,gribparmextract,filenumber,timestep,endfilenumber
 character*200         daydirectory,monthdirectory,yeardirectory
 character*20 	 	 hour
 character*200         domain_latlon,nldasdirectory
 character*100         frmt

 ! Set done = 0
 done = 0

 ! Dataset constants:
 ! ni = number of longitude cells in NLDAS forcing dataset (constant)
 ! nj = number of latitude cells in NLDAS forcing dataset (constant)
 ! x0 = lowest longitude in NLDAS forcing dataset (constant)
 ! y0 = lowest latitude in NLDAS forcing dataset (constant)
 ni   =  464
 nj   =  224
 x0   = -124.938
 y0   =  25.063
 !ni   =  3
 !nj   =  3
 !x0   = -89.563
 !y0   =  42.938

 ! User input:
 print*, "READING BATCH FILE: batch.get_nldas"
 open(99,file="batch.get_nldas",action="read")
 read(99,*), nldasdirectory
! read(99,*), outdir
 read(99,*), filename
 read(99,*), lat,lon
 read(99,*), startyear,startmonth,startday,starthour
 read(99,*), endyear,endmonth,endday,endhour
 close(99)

 ! Print start time, end time
 print*, "start date =",startyear,startmonth,startday,starthour
 print*, "end date =",endyear,endmonth,endday,endhour

 ! Set time to t_start
 print*, "Set up time slice and problem domain, allocate arrays"
 t_year=startyear
 t_month=startmonth
 t_day=startday
 t_hour=starthour
 t=1

 ! Allocate arrays
 allocate( data_in(8,ni,nj) )

 ! Define formatting
 12345 Format (i6.6)
 98768 Format (i2.2)
 98767 Format (i4.4,i2.2)
 98766 Format (i4.4,i2.2,i2.2) 
 98765 Format (i4.4,i2.2,i2.2,i2.2)

 ! Find indices of 1D location
 do j = 1,nj
  do i = 1,ni
   
   ! Calculate lat/lon of NLDAS cell center
   GLAT = y0 + (dble(j-1)*0.125)   !Latitude of NLDAS cell center   
   GLON = x0 + (dble(i-1)*0.125)   !Longitude of NLDAS cell center

   ! If abs(GLAT-lat) <= (.125/2.) --> set jj == j 
   ! If abs(GLON-lon) <= (.125/2.) --> set ii == i
   ! NOTE: for points that fall exactly on cell boundary,
   !       this loop will automatically set jj or ii to the higher index
   !       value of the two cells 
   if ( abs(GLAT-lat) <= (0.125/2.0) ) jj = j
   if ( abs(GLON-lon) <= (0.125/2.0) ) ii = i

  enddo ! i
 enddo ! j

print*,lat,long

 ! Open output file:
 open(99,file=trim(filename),action="write")
    
 ! Loop over timesteps:
 write(endfilenumber,98765) endyear,endmonth,endday,endhour
 do while (done.lt.1) 
 
  ! Marker
  print*, "******************************************************************************" 
  print*, "DATE: ", t_year,t_month,t_day,t_hour
  print*, "END:  ", endyear,endmonth,endday,endhour
  print*, " "

  ! Set directory and file names
  print*, "Set file name for GRIB input"
  write(filenumber,98765) t_year,t_month,t_day,t_hour
  write(daydirectory,98766) t_year,t_month,t_day
  write(monthdirectory,98767) t_year,t_month
  write(yeardirectory,98768) t_hour
  write(hour,98768) t_hour

  ! Set grib file path, wgrib parameters
  gribfile=trim(nldasdirectory)//"/"//"NLDAS_FORA0125_H.A"//trim(daydirectory)//"."//trim(hour)//"00.002.grb"
  gribparmextract=' | egrep "(:DSWRF:|:DLWRF:|:APCP:|:TMP:|:UGRD:|:VGRD:|:PRES:|:SPFH:)" | '

  ! Execute wgrib
  print*, "Execute wgrib (grb -> txt): "//trim(gribfile)//trim(gribparmextract)
  call system ("./wgrib -s "//trim(adjustl(gribfile))//trim(adjustl(gribparmextract))//&
               "./wgrib -i -s -text "//trim(gribfile)//" -o nldas_full.txt")

  ! Read data over full domain
  print*, "Read in data over full domain from nldas_full.txt"
  open(10,file="nldas_full.txt",action='read')
  do k=1,8                                   !Loop over vars
   read(10,*) dummy1, dummy2                 !(Skip first line -- nx,ny)
   do j=1,nj                                 !Loop over y
    do i=1,ni                                !Loop over x
     read(10,*) data_in(k,i,j)
    enddo
   enddo
  enddo
  close (10)

  ! Print values at ii,jj to output file
  DSWR  = data_in(8,ii,jj)
  DLWR  = data_in(6,ii,jj)
  APCP  = data_in(7,ii,jj) / 3600.
  TMP   = data_in(1,ii,jj)
  UGRD  = data_in(4,ii,jj)
  VGRD  = data_in(5,ii,jj)
  PRESS = data_in(3,ii,jj)
  SPFH  = data_in(2,ii,jj)


  
  print*, "Print point values to output"
  frmt  = "(8(f16.8))"
  write(99,trim(frmt)) DSWR, DLWR, APCP, TMP, UGRD, VGRD, PRESS, SPFH 
  
  ! Test if completed all timesteps
  if ((t_year.eq.endyear).and.(t_month.eq.endmonth).and.(t_day.eq.endday).and.(t_hour.eq.endhour)) then
   done=1
  endif

  ! Increment hour, day, year
  if (t_hour.eq.23) then 

   ! Increment hour from 23 -> 0
   t_hour = 0

   ! See if need to increment month
   call months_end(t_year,t_month,t_day,newmonth)

   ! If not incrementing month, increment day only
   if (newmonth.eq.0) then
    t_day=t_day+1

   ! If incrementing month, reset day -> 1, increment month
   else
    t_day=1

    if (t_month.eq.12) then
     t_month=1
     t_year=t_year+1
    else
     t_month=t_month+1
    endif

   endif

  ! If t_hour != 23, increment hour only
  else
   t_hour=t_hour+1
  endif

  ! Increment filenumber
  print*, "filenumber =", trim(filenumber), ",   endfilenumber =", trim(endfilenumber)
  print*, " "
  t=t+1

 enddo! hour loop
! print*, "Meteorological Forcing files are available in ",outdir   

 ! Close output file:
 close(99) 


end program


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
! Subroutine to handle days per month, leap years
subroutine months_end(year,mon,day,gotend)

 integer year,mon,day,gotend, month(12)

 ! February -- leap years
 if (MOD(year,4).eq.0) then
  month(2)=29
 else 
  if(MOD(year,400).eq.0) then
   month(2)=29
  else
   month(2)=28
  endif
 endif

 ! All other months
 month(1)=31
 month(3)=31
 month(4)=30
 month(5)=31
 month(6)=30
 month(7)=31
 month(8)=31
 month(9)=30
 month(10)=31
 month(11)=30
 month(12)=31

 ! Increment month
 if (day.eq.month(mon)) then
  gotend = 1 !Got to last day in the month
 else
  gotend=0
 endif 

end subroutine


