%getET0fromNLDAS.m
%Carolyn Voter

%ASSUMES:
%met forcing file arranged as follows:
% met = load(textFileName);
% DSWR = met(:,1); %W/m^2
% DLWR = met(:,2); %W/m^2
% APCP = met(:,3); %kg/m^2 mm/s
% Temp = met(:,4); %K
% UGRD = met(:,5); %m/s
% VGRD = met(:,6); %m/s
% Press = met(:,7); %pa
% SPFH = met(:,8); %kg/kg

%Also assumees timeseries is continuous hourly data, starting at the
%beginning of a water year and continuing for some number of complete water
%years.

close all; clear all; clc;

%% DEFINE PATHS AND FILENAMES
nldasFile = 'FondDuLac.1983.2013.1hr.txt';

%% DEFINE LOCATION
%Note that NLDAS datasets are recorded in UTC (Greenwich Mean Time), so longZ = 0.
elev = 265; %elevation [m]
lat = 43.773782; %[degrees]
longZ = 0; %longitude of the center of the local time zone [degrees west of Greenwich]
longM = 88.448950; %longitude of the measurement site [degrees west of Greenwich]

%% DEFINE TIMING
%Starting water year-type
%  0 = include leap year, e.g. WY2000
%  1 = just after leap year, e.g. WY2001
%  2 = next year after leap year, e.g. WY2002
%  3 = next year after that, e.g. WY2003
startYr = 0; %starting water year type
nYears = 1; %number of full water years to analyze

%% CALCULATE ET0
%Load forcing data
met = load(nldasFile);
Rs = met(:,1)*(60*60/1e6); %incoming solar radiaton [W/m^2] --> [MJ/hr*m^2]
precip = met(:,3)*3600; %precipitation [mm/s] --> [mm/hr]
TK = met(:,4); %temperature [K]
uz = (met(:,5).^2+met(:,6).^2).^0.5; %wind speed [m/s]
P = met(:,7)/1000; %pressure [Pa] --> [kPa]
q = met(:,8); %specific humidity [kg/kg]

%Pass to ET0 function
ET0 = []; startHr = 0;
for i = 1:nYears
    thisYr = mod(startYr+(i-1),4);
    if thisYr == 0
        %Leap year
        nt = 8784;
        JulianDay = floor([(274:1/24:365.99),(1:1/24:274.99)]); %Oct 1 --> Sept 30
    else
        %Not a leap year
        nt=8760; %Number of hours in a year
        JulianDay = floor([(274:1/24:365.99),(1:1/24:273.99)]); %Oct 1 --> Sept 30
    end
    endHr = startHr + nt; %calculate end index of input data for this water year
    ET0 = [ET0;PenmanMonteithET(elev,lat,longZ,longM,JulianDay,...
        P(startHr+1:endHr),uz(startHr+1:endHr),TK(startHr+1:endHr),...
        Rs(startHr+1:endHr),q(startHr+1:endHr),nt)]; %mm/hr, append to current ET0 vector
    startHr = endHr; %update index for input data for next water year
end