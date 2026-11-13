
%% ================================================================
%  UNBALANCED FAULT ANALYSIS - TWO BUS POWER SYSTEM
%  AG, BC and BCG Faults
%  Theoretical vs Simulink Simulation Comparison
%
%  MATLAB R2024a
%  Frequency: 50 Hz
%  Two PI sections: 25 km each
%  Fault location: Midpoint
%% ================================================================

clc;
close all;

fprintf('\n============================================\n');
fprintf('       UNBALANCED FAULT ANALYSIS\n');
fprintf('============================================\n');

%% 1. CHECK SIMULATION OUTPUT

if ~all(isfield(whos, {'outAG','outBC','outBCG'}))
    error('Run and save all three fault simulations first.');
end

simOut = out;

%% 2. SYSTEM PARAMETERS

f = 50;
w = 2*pi*f;

% Three-phase source
VLL = 11000;
Vph = VLL/sqrt(3);

Rs = 0.1;
Ls = 0.001;

Zsource = Rs + 1i*w*Ls;

% Transmission line
lineLength = 25;       % km per PI section

r1 = 0.2;              % Positive sequence resistance (Ohm/km)
r0 = 0.6;              % Zero sequence resistance (Ohm/km)

l1 = 0.001;            % Positive sequence inductance (H/km)
l0 = 0.003;            % Zero sequence inductance (H/km)

c1 = 12e-9;            % Positive sequence capacitance (F/km)
c0 = 6e-9;             % Zero sequence capacitance (F/km)

% Two identical PI sections
Zline1 = lineLength*(r1 + 1i*w*l1);
Zline0 = lineLength*(r0 + 1i*w*l0);

% Load parameters
Pload = 1.5e6;
QL = 0.5e6;
Qc = 0;

Qload = QL - Qc;

% Per-phase grounded-Y load impedance
Sphase = (Pload + 1i*Qload)/3;

Zload = Vph^2/conj(Sphase);

% Fault block parameters
Ron = 0.01;
Rg  = 0.01;

% Fault time window
faultWindow = [0.12 0.28];

%% 3. SEQUENCE NETWORK THEVENIN EQUIVALENTS
%
% Fault is at the midpoint between two 25 km lines.
%
% Left network:
% Source + first PI section
%
% Right network:
% Second PI section + grounded-Y load
%
% Shunt capacitance is neglected in the analytical
% series-equivalent calculation.

% Positive sequence
Zleft1 = Zsource + Zline1;
Zright1 = Zline1 + Zload;

Z1th = (Zleft1*Zright1)/(Zleft1+Zright1);

% Negative sequence
Z2th = Z1th;

% Zero sequence
% Source and grounded-Y load are assumed to provide
% zero-sequence return paths.

Zleft0 = Zsource + Zline0;
Zright0 = Zline0 + Zload;

Z0th = (Zleft0*Zright0)/(Zleft0+Zright0);

% Prefault positive-sequence voltage at fault location
Vth = Vph*(Zright1/(Zleft1+Zright1));

fprintf('\n========== SEQUENCE NETWORK ==========\n');

fprintf('Source impedance       = %.4f + j%.4f Ohm\n', ...
    real(Zsource),imag(Zsource));

fprintf('Positive line Z        = %.4f + j%.4f Ohm\n', ...
    real(Zline1),imag(Zline1));

fprintf('Zero sequence line Z   = %.4f + j%.4f Ohm\n', ...
    real(Zline0),imag(Zline0));

fprintf('Load impedance         = %.4f + j%.4f Ohm\n', ...
    real(Zload),imag(Zload));

fprintf('Z1 Thevenin            = %.4f + j%.4f Ohm\n', ...
    real(Z1th),imag(Z1th));

fprintf('Z2 Thevenin            = %.4f + j%.4f Ohm\n', ...
    real(Z2th),imag(Z2th));

fprintf('Z0 Thevenin            = %.4f + j%.4f Ohm\n', ...
    real(Z0th),imag(Z0th));

fprintf('Prefault voltage       = %.2f V RMS\n',abs(Vth));

%% 4. THEORETICAL AG FAULT

% A-G fault:
% I1 = I2 = I0

Zf_AG = Ron + Rg;

Iseq_AG = Vth/(Z1th + Z2th + Z0th + 3*Zf_AG);

IA_AG = 3*Iseq_AG;

Itheory_AG = [abs(IA_AG), 0, 0];

%% 5. THEORETICAL BC FAULT

% B-C line-to-line fault:
% I0 = 0
% I2 = -I1

Zf_BC = Ron;

I1_BC = Vth/(Z1th + Z2th + Zf_BC);

IBC = sqrt(3)*abs(I1_BC);

Itheory_BC = [0, IBC, IBC];

%% 6. THEORETICAL BCG FAULT

% B-C-G double line-to-ground fault

Zf_BCG = Rg;

Z0_ground = Z0th + 3*Zf_BCG;

% Parallel combination of negative and zero networks
Zparallel = (Z2th*Z0_ground)/(Z2th+Z0_ground);

I1_BCG = Vth/(Z1th+Zparallel);

I2_BCG = -I1_BCG*Z0_ground/(Z2th+Z0_ground);

I0_BCG = -I1_BCG*Z2th/(Z2th+Z0_ground);

% Symmetrical component transformation
a = exp(1i*2*pi/3);

IA_BCG = I0_BCG + I1_BCG + I2_BCG;

IB_BCG = I0_BCG + a^2*I1_BCG + a*I2_BCG;

IC_BCG = I0_BCG + a*I1_BCG + a^2*I2_BCG;

Itheory_BCG = [abs(IA_BCG), abs(IB_BCG), abs(IC_BCG)];

%% 7. EXTRACT SIMULINK DATA

% Expected To Workspace variables:
% out.If_AG
% out.If_BC
% out.If_BCG
%
% Each signal should contain three-phase currents.

%% 7. EXTRACT SIMULINK DATA

%% 7. EXTRACT SIMULINK DATA

[t_AG,I_AG] = readThreePhase(outAG,'If_AG');

[t_BC,I_BC] = readThreePhase(outBC,'If_BC');

[t_BCG,I_BCG] = readThreePhase(outBCG,'If_BCG');

%% 8. CALCULATE SIMULATION RMS AND PEAK VALUES

idx_AG = t_AG >= faultWindow(1) & t_AG <= faultWindow(2);
idx_BC = t_BC >= faultWindow(1) & t_BC <= faultWindow(2);
idx_BCG = t_BCG >= faultWindow(1) & t_BCG <= faultWindow(2);

if ~any(idx_AG) || ~any(idx_BC) || ~any(idx_BCG)
    error('Fault analysis window contains no simulation samples.');
end

% RMS values
Irms_AG = sqrt(mean(I_AG(idx_AG,:).^2,1));
Irms_BC = sqrt(mean(I_BC(idx_BC,:).^2,1));
Irms_BCG = sqrt(mean(I_BCG(idx_BCG,:).^2,1));

% Peak values
Ipeak_AG = max(abs(I_AG(idx_AG,:)),[],1);
Ipeak_BC = max(abs(I_BC(idx_BC,:)),[],1);
Ipeak_BCG = max(abs(I_BCG(idx_BCG,:)),[],1);

%% 9. COMBINE RESULTS

Fault = [repmat("AG",3,1);
         repmat("BC",3,1);
         repmat("BCG",3,1)];

Phase = repmat(["A";"B";"C"],3,1);

Simulated_RMS_A = [Irms_AG(:);
                   Irms_BC(:);
                   Irms_BCG(:)];

Theoretical_RMS_A = [Itheory_AG(:);
                     Itheory_BC(:);
                     Itheory_BCG(:)];

Simulated_Peak_A = [Ipeak_AG(:);
                    Ipeak_BC(:);
                    Ipeak_BCG(:)];

Absolute_Error_A = abs(Simulated_RMS_A-Theoretical_RMS_A);

Error_Percent = NaN(9,1);

valid = Theoretical_RMS_A > 1e-6;

Error_Percent(valid) = ...
    100*Absolute_Error_A(valid)./Theoretical_RMS_A(valid);

Results = table(Fault,Phase,Simulated_RMS_A, ...
    Theoretical_RMS_A,Simulated_Peak_A, ...
    Absolute_Error_A,Error_Percent);

%% 10. DISPLAY RESULTS

fprintf('\n\n============================================\n');
fprintf('           FAULT ANALYSIS RESULTS\n');
fprintf('============================================\n');

fprintf('\nTHEORETICAL AG: %.3f A\n',Itheory_AG(1));
fprintf('THEORETICAL BC: B = %.3f A, C = %.3f A\n', ...
    Itheory_BC(2),Itheory_BC(3));

fprintf('THEORETICAL BCG: B = %.3f A, C = %.3f A\n', ...
    Itheory_BCG(2),Itheory_BCG(3));

fprintf('\n========== SIMULATION COMPARISON ==========\n');

disp(Results);

%% 11. PLOT AG FAULT

figure('Name','AG Fault Current','Color','w');

plot(t_AG,I_AG,'LineWidth',1.2);
grid on;

xlabel('Time (s)');
ylabel('Fault Current (A)');
title('AG Single Line-to-Ground Fault Current');

legend('Phase A','Phase B','Phase C');

%% 12. PLOT BC FAULT

figure('Name','BC Fault Current','Color','w');

plot(t_BC,I_BC,'LineWidth',1.2);
grid on;

xlabel('Time (s)');
ylabel('Fault Current (A)');
title('BC Line-to-Line Fault Current');

legend('Phase A','Phase B','Phase C');

%% 13. PLOT BCG FAULT

figure('Name','BCG Fault Current','Color','w');

plot(t_BCG,I_BCG,'LineWidth',1.2);
grid on;

xlabel('Time (s)');
ylabel('Fault Current (A)');
title('BCG Double Line-to-Ground Fault Current');

legend('Phase A','Phase B','Phase C');

%% 14. THEORETICAL VS SIMULATION COMPARISON

figure('Name','Theoretical vs Simulation','Color','w');

labels = Fault + "-" + Phase;

bar(categorical(labels), ...
    [Simulated_RMS_A,Theoretical_RMS_A]);

grid on;

ylabel('RMS Current (A)');
title('Theoretical vs Simulation Fault Current');

legend('Simulated','Theoretical','Location','best');

%% 15. PERCENTAGE ERROR

figure('Name','Percentage Error','Color','w');

bar(categorical(labels),Error_Percent);

grid on;

ylabel('Percentage Error (%)');
xlabel('Fault and Phase');

title('Theoretical vs Simulation Percentage Error');

%% 16. SAVE ALL RESULTS

Parameters = struct();

Parameters.Frequency = f;
Parameters.SourceVoltage_LL = VLL;
Parameters.SourceImpedance = Zsource;

Parameters.LineLengthPerSection_km = lineLength;
Parameters.TotalLineLength_km = 2*lineLength;

Parameters.PositiveSequenceLineImpedance = Zline1;
Parameters.ZeroSequenceLineImpedance = Zline0;

Parameters.LoadImpedance = Zload;

Parameters.FaultResistance_Ron = Ron;
Parameters.GroundResistance_Rg = Rg;

Parameters.FaultWindow = faultWindow;

Theoretical = struct();

Theoretical.AG = Itheory_AG;
Theoretical.BC = Itheory_BC;
Theoretical.BCG = Itheory_BCG;

Theoretical.Z1th = Z1th;
Theoretical.Z2th = Z2th;
Theoretical.Z0th = Z0th;

Simulation = struct();

Simulation.AG_RMS = Irms_AG;
Simulation.BC_RMS = Irms_BC;
Simulation.BCG_RMS = Irms_BCG;

Simulation.AG_Peak = Ipeak_AG;
Simulation.BC_Peak = Ipeak_BC;
Simulation.BCG_Peak = Ipeak_BCG;

save('Unbalanced_Fault_Complete_Results.mat', ...
    'Results','Parameters','Theoretical','Simulation', ...
    'I_AG','I_BC','I_BCG', ...
    't_AG','t_BC','t_BCG');

writetable(Results,'Unbalanced_Fault_Comparison.csv');

fprintf('\n============================================\n');
fprintf('       RESULTS SUCCESSFULLY SAVED\n');
fprintf('============================================\n');

fprintf('MAT file: Unbalanced_Fault_Complete_Results.mat\n');
fprintf('CSV file: Unbalanced_Fault_Comparison.csv\n');

%% ================================================================
% LOCAL FUNCTION: READ THREE-PHASE TIMESERIES
%% ================================================================

function [t,x] = readThreePhase(simOut,varName)

    try
        sig = simOut.get(varName);
    catch
        error('Could not find simulation output: %s',varName);
    end

    if isa(sig,'timeseries')

        t = sig.Time(:);
        x = squeeze(sig.Data);

    elseif isstruct(sig) && isfield(sig,'time')

        t = sig.time(:);

        if isfield(sig,'signals')
            x = squeeze(sig.signals.values);
        else
            error('Unexpected structure format for %s.',varName);
        end

    else
        error(['Output %s is not a Timeseries or supported ', ...
               'Structure. Check your To Workspace block.'],varName);
    end

    if size(x,1) ~= numel(t) && size(x,2) == numel(t)
        x = x.';
    end

    if size(x,1) ~= numel(t) || size(x,2) ~= 3
        error(['%s must contain three-phase data with dimensions ', ...
               'N x 3. Actual dimensions: %s'], ...
               varName,mat2str(size(x)));
    end

    x = double(x);

end
