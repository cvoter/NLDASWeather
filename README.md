# Accessing and Using NLDAS-2 Forcing Data
Carolyn Voter  
Last updated: 2018.01

## Downloading NLDAS-2 data
The North American Land Data Assimilation (NLDAS) forcing data is hosted by NASA. This reanalysis data is available at hourly temporal resolution and 1/8 degree spatial resolution. For more information about the dataset, see the information page [here](https://ldas.gsfc.nasa.gov/nldas/NLDAS2forcing.php). To download:

1. **Register** for an [Earthdata login](https://wiki.earthdata.nasa.gov/display/EL/How+To+Register+With+Earthdata+Login)
2. **Add a .netrc file and a .urs_cookies file** to your home directory, [as instructed here](https://disc.gsfc.nasa.gov/information/howto/5761bc6a5ad5a18811681bae). These store your Earthdata username, password, etc. which are now required to access files.
3. **Select data** to download by navigating to the [mirador landing page](http://mirador.gsfc.nasa.gov/). 
    - Enter NLDAS in the **keyword** section and select a **time period** of interest. All times are in coordinate universal time (UTC) aka Greenwich Mean Time (GMT).
    - Note there are **limits on how many files** you can download in a batch (30,000, which equates to a little over 3 years of hourly forcing data files). The best way I know to do this is the tedious way: break your time period of interest down into ~3year batches, and repeat the process ad nauseam.
    - It's possible to define a **spatial subsection** at this point as well, but since I often want information for different locations in the U.S., I find it easier to download the whole thing just one time. In the past, I've also found that defining spatial subsections adds a lot of extra information to the *.grb filenames, which make them a little more annoying to process.
    - Click **Search GES-DISC** to continue.
4. Scroll/page until you see **NLDAS Primary Forcing Data Hourly 0.125x0.125 degree V002 (NLDAS_FORA0125_H)**.
    - Note that this is different than NLDAS Forcing Data Hourly 0.125x0.125 (NLDAS_FOR0125_H), aka NLDAS-1, which is only available for a more limited time period and has a different source. Read more about NLDAS-1 [here](https://ldas.gsfc.nasa.gov/nldas/NLDAS1forcing.php). The NLDAS-2 data may be on the second page. 
    - When you find it, check the box, and **Add Selected Files to Cart** (button at bottom). At this point, a warning will appear if you have selected a large timespan with <30,000 files.
5. No need to add a select service option (keep "none" checked). Then, **Continue to cart**.
6. Warnings will appear if you tried to add more than 30,000 files (~3 yrs of data). If there are no issues with the time period you selected, just click **Checkout**.
7. Click the button for **URL List (Data)**. 
    - Instructions should appear here for using wget or curl, if needed. They should match what I have in this README, but it is always good to check that nothing has change.
8. Right click on the html page of urls, **save as myfile.dat** or a more descriptive name if you will have multiple files like this (i.e., for a long time series).
9. **In your working directory** (on desktop or server), make sure you have:
    - myfile.dat (or equivalent)
    - Ability to use wget or curl
    - the .net_rc and .urs_cookies files in your home directory
10. In your preferred shell terminal, from the working directory to which you saved "myfile.dat", **begin downloading files** with: wget --content-disposition --load-cookies ~/.urs_cookies --save-cookies ~/.urs_cookies --auth-no-challenge=on --keep-session-cookies -i myfile.dat
    - Replace location of name of myfile.dat as needed
    - I always stick with wget, but I believe curl works similarly. Refer to the instructions from NASA in Step #7 if needed.
    - This can take a very long time - several hours to over a day depending on your connection and how many files you're downloading. On my system, a *.tar.gz file with files for WY1981-WY2016 is 352GB.

## Reading *.grb files into *.txt files
To read forcing data from *.grb files into a *.txt file, this approach requires (in the same directory):
  - _wgrib_, a program available through NOAA
  - _batch.get_nldas_, a text file with information about location, timeframe, filenames
  - _get\_nldas.1D.f90_, a script developed by Ian Ferguson and modified by Carolyn Voter

1. **Install the program _wgrib_** on your system.
    - Source code available [here](http://www.cpc.ncep.noaa.gov/products/wesley/wgrib.html)
    - Compile within shell, e.g.: gcc wgrib.c -o wgrib
	- Note: I have trouble getting wgrib to work properly on Windows (with either GitBash or cygwin as the shell). On linux, simply having the compiled wgrib within your working directory is sufficient.
2. **Modify _batch.get_nldas_** for your situation. Generally, this should include:  
  "/path/to/NLDAS/data"  
  "desiredOutputFilename.txt"  
  lat long  
  yyyy mm dd hh (start)  
  yyyy mm dd hh (end)  
  **As an example**, for Fond du Lac, WI I entered:  
  "/mnt/gluster/cvoter/WY1981_WY2016"  
  "FondDuLac.WY1983.WY2013.1hr.txt"  
  43.773782 -88.448950  
  1983 10 01 00  
  2014 09 30 23  

3. **Compile _get\_nldas.1D.f90_** within shell, e.g.: gfortran -o get_nldas.1D get_nldas.1D.f90
4. **Run** with the command: ./get_nldas.1D
    - This step may also take a while (many hours) depending on the length of the time series of interest.
5. This process should yield the **final text file**, "FondDuLac.WY1983.WY2013.1hr.txt" (or specified filename). There will be one row per hour and the format of the columns should be:
    - Column 1: DSWR, visible or short-wave radiation (W/m^2)
    - Column 2: DLWR, long wave radiation (W/m^2) 
    - Column 3: APCP, precipitation (mm/s)
    - Column 4: Temp, air temperature 2m above ground (K)
    - Column 5: UGRD, east-west wind speed 10m above ground (m/s)
    - Column 6: VGRD, north-south wind speed 10m above ground (m/s)
    - Column 7: Press, atmospheric pressure (pa)
    - Column 8: SPFH, specific humidity 2m above ground (kg/kg)

## Calculating FAO Penman-Monteith reference ET from forcing data
I use the matlab function, _PenmanMonteithET.m_, called from within  _getET0fromNLDAS.m_. Those scripts should be well-commented.
  
## Additional notes
Depending on the number of locations and length of time series, I sometimes split this into several batches and send them through high throughput computational resources. I can share those scripts if interested - I'm not sure how relevant they'll be in different (non-HTCondor) systems.
