%Functional Zoology - LoadCell on demand
%Remco Pieters WUR - March 2017

%Definitions
LoadCellPin = 'A4';
LEDPin='D2';
convertVoltForce = 1;

%% Connect Arduino
%User input COMport and type
if exist('a')==false
    prompt = {'Enter COM-port:','Enter Arduino type:'};
    dlg_title = 'Input Arduino port settings';
    defaultans = {'COM10','uno'};
    answer = inputdlg(prompt,dlg_title,1,defaultans);
    if isempty(answer)
        disp('User selected cancel')
    else
        a=arduino(answer{1,1},answer{2,1});
    end
end

%% Measurement
%Two types: single measurement time independent or fixed rate
%User input for measurement type
choice = questdlg('Choose measurement type?', ...
    'Measurement type', ...
    'Single','Timed','Single');
% Handle response
switch choice
    case 'Single'
        meas_type = 'single';
    case 'Timed'
        meas_type = 'timed';
end

%Single Measurement
if strcmp(meas_type,'single')
    %Tare scale
    disp('Prepare test sample');
    LoadCellVolt = readVoltage(a,LoadCellPin);
    disp(['Current load ',num2str(LoadCellVolt*convertVoltForce),' N']);
    disp('Tare load cell?')
    disp('Start measurement')
    single_measurement = true;
    datapoint=1;
    while single_measurement
        input_str=input('Press M to take a measurement or Q to quite measement series: ','s');
        if strcmpi(input_str,'m')
            DataPoint(datapoint,1)=datapoint;
            LoadCellVoltage(datapoint,1) = readVoltage(a,LoadCellPin);
            Force(datapoint,1)=LoadCellVoltage(datapoint,1)*convertVoltForce;
            Length(datapoint,1)=input('Enter sample length: ');
            %Increase datapoint number for next measurement
            datapoint=datapoint+1;
            %Show measurement data in table
            ForceTable=table(DataPoint,LoadCellVoltage,Force,Length)
        elseif strcmpi(input_str,'q')
            single_measurement = false;
            disp('Measurement series done')
            disp('Save data')
            [FileName,PathName] = uiputfile('ForceMeasurement.xlsx','Save Force Measurement');
            if isequal(FileName,0) || isequal(PathName,0)
                disp('User selected Cancel')
            else
                writetable(ForceTable,fullfile(PathName,FileName));
            end
            
        else
            disp('Invalid user input')
        end
    end
elseif strcmp(meas_type,'timed')
    %Set up timer
    t = timer;
    t.BusyMode = 'drop';
    t.ExecutionMode = 'fixedSpacing';
    t.Period = 0.1; %in seconds
    t.StartFcn = {@initMeasurement, a,LoadCellPin,LEDPin};
    t.TimerFcn = {@takeMeasurement, a, LoadCellPin,LEDPin};
    LoadCellVolt = readVoltage(a,LoadCellPin);
    disp(['Current load ',num2str(LoadCellVolt*convertVoltForce),' N']);
    disp('Tare load cell?')
    timed_measurement = true;
    while timed_measurement
        input_str=input('Press M to take start measurement series or Q to quite measement series: ','s');
        if strcmpi(input_str,'m')
            start(t);
        elseif strcmpi(input_str,'q')
            timed_measurement = false;
            stop(t)
            meas = t.UserData;
            delete(t)
            %Reorganize data
            DataPoint(1:meas.counter,1)=1:meas.counter;
            Time(1:meas.counter,1)=etime(datevec(meas.time.'),datevec(meas.time(1)));
            LoadCellVoltage(1:meas.counter,1) = meas.loadcellvoltage.';
            Force=LoadCellVoltage.*convertVoltForce;
            ForceTable=table(DataPoint,Time,LoadCellVoltage,Force)
            disp('Save data')
            [FileName,Pathname] = uiputfile('ForceMeasurement.xlsx','Save Force Measurement');
            if isequal(FileName,0) || isequal(PathName,0)
                disp('User selected Cancel')
            else
                writetable(ForceTable,fullfile(PathName,FileName));
            end
        else
            disp('Invalid user input')
        end
    end
end

clear all

function initMeasurement(obj, event, a,LoadCellPin,LEDPin)
writeDigitalPin(a,LEDPin,1)
measurement.counter=1;
measurement.time(measurement.counter) = now;
measurement.loadcellvoltage(measurement.counter) = readVoltage(a,LoadCellPin);
writeDigitalPin(a,LEDPin,0)
obj.UserData = measurement;
end

function takeMeasurement(obj, event, a,LoadCellPin,LEDPin)
writeDigitalPin(a,LEDPin,1)
measurement=obj.UserData;
measurement.counter=measurement.counter+1;
measurement.time(measurement.counter) = now;
measurement.loadcellvoltage(measurement.counter) = readVoltage(a,LoadCellPin);
obj.UserData = measurement;
disp(measurement.loadcellvoltage(measurement.counter));
writeDigitalPin(a,LEDPin,0)
end




