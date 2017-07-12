% This function is used to resample an array of timeseries data (position) 
% with a non-constant samle frequency to a timeseries array with a constant 
% sampling frequency. A constant sampling frequency is required to pass the 
% timeserie into the butterworth filter .m file for filtering. This function 
% plots out unfiltered and filtered position, velocity, and acceleration
% data for visualization.
%
% Input:
%- ResampleFreq: the frequency you would like to resample the data at
%- Cutoff_freq: cutoff frequency for the filter
%- xlsxDataFileName: name of the xlsx file containing the original time series data
%- DataColumn: which column do you want to filter in the time serie data?
%- sheetnumber: sheet number to read the original data from xlsx file
%
% Output:
% - Filtered_data: time dependant data array with the specified time axis
% with the resampled and filtered data
%
% 20150318 Written by Tina Hung
% 20150320 Modified by Navid Shirzad
% 20150805 Modified by Derek Schaper


function [Filtered_data] = ResampleData(ResampleFreq, Cutoff_freq, Original_t, DataToResample)

% Shift the timestamps so it starts from 0 seconds
Shifted_t = [0;Original_t(2:end,1)-Original_t(1,1)];

% create a timeseries object from the original data
Original_timeseries = timeseries(DataToResample,Shifted_t); 

% create a timeline based on the desired resampling frequency
Desired_timeseries = [0:1/ResampleFreq:Shifted_t(end,1)]';

% resample the originaltimeseries
Resampled_data = resample(Original_timeseries,Desired_timeseries);

% filter the data using a butterworth filter
Filtered_data_wo_time = ButterworthFilter(ResampleFreq, Cutoff_freq, Resampled_data);
Filtered_data = [Desired_timeseries, Filtered_data_wo_time]; 

%% 
% % plot position x (column 1 of data)
% figure()
% plot(Shifted_t,DataToResample(:,1),'-b'); 
% hold on;
% plot(Filtered_data(:,1),Filtered_data(:,2),'-r'); 
% xlabel('Time (s)');
% ylabel('Position x'); 
% %saveas(h, strcat('C:\Users\Tina\Desktop\Phase II Temp Data\x',num2str(TrialNum)),'jpg');
% hold off;
% 
% % plot position y (column 2 of data)
% figure()
% plot(Shifted_t,DataToResample(:,2),'-b'); 
% hold on;
% plot(Filtered_data(:,1),Filtered_data(:,3),'-r'); 
% xlabel('Time (s)');
% ylabel('Position y'); 
% %saveas(h, strcat('C:\Users\Tina\Desktop\Phase II Temp Data\z',num2str(TrialNum)),'jpg');
% hold off;

% % calculate velocity & acceleration
% TimeSteps = (Resampled_data.time(2:end)-Resampled_data.time(1:end-1));
% TimeSteps = [TimeSteps TimeSteps]; % create a two column time steps for matrix calculation
% OriginalTimeSteps = (Shifted_t(2:end)-Shifted_t(1:end-1));
% OriginalTimeSteps = [OriginalTimeSteps OriginalTimeSteps]; % create a two column time steps for matrix calculation
% 
% filtered_vel = (Filtered_data(2:end, 2:3) - Filtered_data(1:end-1, 2:3))./TimeSteps;
% filtered_acc = (filtered_vel(2:end, 1:2) - filtered_vel(1:end-1, 1:2))./TimeSteps(2:end,:);
% filtered_vel = [0 0 ; filtered_vel];
% filtered_acc = [0 0 ;0 0 ;filtered_acc];
% 
% unfiltered_vel = (DataToResample(2:end,:) - DataToResample(1:end-1,:))./OriginalTimeSteps;
% unfiltered_acc = (unfiltered_vel(2:end,:) - unfiltered_vel(1:end-1,:))./OriginalTimeSteps(2:end,:);
% unfiltered_vel = [0 0 ; unfiltered_vel];
% unfiltered_acc = [0 0 ;0 0 ; unfiltered_acc];
% 
% % try plotting the unfiltered and filtered velocity data to see the difference.
% % plot vel_x (column 1 of data)
% figure()
% plot(Shifted_t,unfiltered_vel(1:end,1),'-b'); 
% hold on;
% plot(Resampled_data.time,filtered_vel(1:end,1),'-r'); 
% xlabel('Time (s)');
% ylabel('Vel x'); 
% hold off;
% 
% % plot vel_y (column 2 of data)
% figure()
% plot(Shifted_t,unfiltered_vel(1:end,2),'-b'); 
% hold on;
% plot(Resampled_data.time,filtered_vel(1:end,2),'-r'); 
% xlabel('Time (s)');
% ylabel('Vel y'); 
% hold off;
% 
% % try plotting the unfiltered and filtered acceleration data to see the difference.
% % plot acc_x (column 1 of data)
% figure()
% plot(Shifted_t,unfiltered_acc(1:end,1),'-b'); 
% hold on;
% plot(Resampled_data.time,filtered_acc(1:end,1),'-r'); 
% xlabel('Time (s)');
% ylabel('Acc x'); 
% hold off;
% 
% % plot acc_y (column 2 of data)
% figure()
% plot(Shifted_t,unfiltered_acc(1:end,2),'-b'); 
% hold on;
% plot(Resampled_data.time,filtered_acc(1:end,2),'-r'); 
% xlabel('Time (s)');
% ylabel('Acc y'); 
% hold off;

% Filtered_data = [Filtered_data, filtered_vel, filtered_acc]; %contains time stamp, xy position, velocity, acceleration
% xlswrite(filepath, Filtered_data, toSheet)
end