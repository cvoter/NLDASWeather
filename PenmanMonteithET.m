function [ET0] = PenmanMonteithET(elev,lat,longZ,longM,JulianDay,P,uz,TK,Rs,q,hours)
%PenmanMonteithET.m
%Carolyn Voter
%March 5, 2016

%Calculated FAO Penman-Monteith reference evapotranspiration based on
%hourly meteorological input data. If timestep for input data is anything
%other than 1hr, these equations are not valid - must check all eqns with
%FAO 56 (Allen et al., 2006).

%INPUT:
%elev = elevation above sea level [m]
%lat = latitude north of equator [degrees]
%longZ = longitude of the center of the local time zone [degrees west of Greenwich]
%longM = longitude of the measurement site [degrees west of Greenwich]
%JulianDay = Julian day of all hourly time steps
%P = pressure [kPa]
%uz = wind speed at 10m [m/s]
%TK = air temperature [K]
%Rs = incoming solar radiation [MJ/hr*m^2]
%q = specific humidity [kg/kg]
%hours = number of hourly time steps to evaluate (from begining)

%OUTPUT
%ET0 = reference evapotranspiration [mm/hr]

%% ADDITIONAL PARAMETERS
albedo = 0.23; %albedo for green grass reference crop (FAO p.43)
wz = 10; %distance above ground at which wind speed was measured [m]
TC = TK-273.15; %tempreature [C] - need temp in both C and K

%% REFERNCE ET
for i=1:hours
    %Time & Location Variables
    latRad = toRadians('degrees',lat); %[radians]
    J = JulianDay(i);
    dr = 1+0.033*cos(2*pi/365*J); %inverse relative distance Earth-Sun
    b = 2*pi*(J - 81)/364; %constant used in eqn for Sc
    Sc = 0.1645*sin(2*b)-0.1255*cos(b)-0.025*sin(b); %seasonal correction for solar time
    omega = (pi/12)*(((mod(i,24)+0.5)+0.06667*(longZ-longM)+Sc)-12); %solar time angle at midpoint of period
    omega1 = omega - pi*1/24; %solar time angle at beginning of period
    omega2 = omega + pi*1/24; %solar time angle at end of period
    sdec = 0.409*sin(2*pi*J/365-1.39); %solar declination
    omegaS = acos(-tan(latRad)*tan(sdec)); %sunset solar angle
    if omega > -omegaS && omega < omegaS
        day = 1; night = 0;
    else day = 0; night = 1;
    end
    timeDay(i) = day;
    %Air Humidity Parameters
    atmP = 101.3*((293-0.0065*elev)/293)^5.26; %atmospheric pressure [kPa]
    gamma = (0.665e-3)*atmP; %Psychrometric constant [kPa/degC]
    e0 = 0.6108*exp(17.27*TC(i)/(TC(i)+237.3)); %Saturation vapor pressure [kPa]
    delta = 4098*e0/((TC(i)+237.3)^2); %Slope of saturation vapor pressure curve [kPa/degC]
    ea = P(i)*q(i)/(0.622+q(i)); %Actual vapor pressure (from Bolton, 1980), assume sp. hum. = mixing ratio. ea has same units as P [kPa]
    %Radiation
    Ra = 12*60/pi*0.0820*dr*((omega2-omega1)*sin(latRad)*sin(sdec)+cos(latRad)*cos(sdec)*(sin(omega2)-sin(omega1))); %extraterrestrial radiation [MJ/m^2*hr]
    Rso = 0.75+(2*10^-5)*elev*Ra; %clear-sky radiation [MJ/m^2*hr]
    SBconst = (4.903e-9)/24; %Stefan-Boltzman constant [MJ/K^4*m^2*d] --> [MJ/K^4*m^2*hr]
    Rnl = SBconst*TK(i)^4*(0.34-0.14*sqrt(ea))*(1.35*Rs(i)/Rso-0.35); %net longwave radiation. Thr should be [K] here.
    Rns = (1-albedo)*Rs(i); %net shortwave radiation [MJ/m^2*hr]
    Rn = Rns - Rnl; %net radiation
    %Ground Heat
    G = 0.1*Rn*day+0.5*Rn*night;
    %Wind Speed
    u2(i,1) = uz(i)*4.87/(log(67.8*wz-5.42)); %Wind speed at 2m off ground
    %Penman-Monteith reference ET
    ET0(i,1)=(0.408*delta*(Rn-G) + gamma*(37/TK(i))*u2(i)*(e0-ea))/(delta + gamma*(1+0.34*u2(i)));
end
end
