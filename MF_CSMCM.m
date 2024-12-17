clc
clear

% Discrete number
A = 50;
% Substrate thickness (um)
t = logspace(log10(3),log10(200),A);
% Young's modulus (kPa)
Es = logspace(-1,2,A);
% Poisson ratio
niu = 0.45;
% Initial spreading radius (um)
R0 = 3.2;
% Effective stiffness of cell membrane (pN)
kcy= 150;
% Clutch stiffness (pN/nm)
kc = 5;
% Clutch number
Nc = 1000;
% Characteristic breaking force (pN)
Fb = 4.1;
% Initial on-rate (1/s)
ron0 = 0.4;
% Initial off-rate (1/s)
roff0 = 5;
% Force-sensitive coefficient (s^-1*pN^-1)
alpha = 7;
% Talin unfolding threshold force (pN)
Ftalin = 6;
% Retrograde speed of actin (nm/s)
vf = 85;
% Nacent adhesion radius (um)
a0 = sqrt(0.1/pi);
% Characteristic protein complex length (um)
beta = 0.06;
%% Import data of dimensionless Pi function

opts = spreadsheetImportOptions("NumVariables", 2);
opts.Sheet = "Sheet1";
opts.DataRange = "A4:B56";
opts.VariableNames = ["L", "pi_f"];
opts.VariableTypes = ["double", "double"];

% pif = readtable("D:\坚果云\Gong Lab\Cell Adhesion\Contact Stiffness\data\pi_f.xlsx", opts, "UseExcel", false);

pif = readtable("pi_f.xlsx", opts, "UseExcel", false);

clear opts
%% functions
options = optimoptions('fsolve', 'Display', 'off');
% Define rate functions:
Roni = @(fcmean) ron0 + alpha * (fcmean >= Ftalin) .* (fcmean - Ftalin);  % On-rate; reinforcement
Roff = @(fcmean) roff0 * exp(fcmean ./ Fb);                                                 % Off-rate; Bell's function

% Define bound fraction and related variables:
PB = @(fcmean) Roni(fcmean) ./ (Roni(fcmean) + Roff(fcmean)); % Bound fraction of clutches
Nb = @(fcmean) PB(fcmean) * Nc;                                                 % Number of bound clutches

% Define traction force and spreading radius:
FA = @(fcmean) Nb(fcmean) .* fcmean;               % Traction force generated by FA
R = @(fcmean) R0 + FA(fcmean) * R0 / kcy;         % Cell spreading radius

% Define contact radius based on spreading area:
gamma = 4e-2;                                                      % Ratio of total FA area to cell area
a = @(fcmean) sqrt(gamma) * R(fcmean);            % Contact radius, proportional to spreading radius

for j = 1:A
    parfor i =1:A
        s = @(fcmean) 2*Es(j)/(1-niu^2)*a(fcmean)*PI(a(fcmean),t(i),niu,pif); %Contact stiffness
        keff1=@(fcmean) kc*s(fcmean)/(kc*Nb(fcmean)+s(fcmean));  %Effect stiffness
        F1=@(fcmean)  fcmean-keff1(fcmean)*vf*(1/Roff(fcmean));
        exitflag = 0;
        f0 =10;
        while exitflag<=0
            [Fcmean(i,j),~,exitflag] = fsolve(F1,f0,options);
            f0 = f0-0.5;
        end      
    end
    j
end
Rs=R(Fcmean);
aa =sqrt(gamma)*Rs;
% Focal adhesion length (um)
Ad= a0+ beta*PB(Fcmean).*(Roni(Fcmean)/ron0-1);

for j = 1:A
    for i =1:A
        S(i,j) = 2*Es(j)/(1-niu^2)*aa(i,j).*PI(a(Fcmean(i,j)),t(i),niu,pif);
    end
end


%% Usage
plot_pcolor(t, Es, pi*Rs.^2, [1e1 1e4], [1e1 1e2 1e3 1e4], {"10^{1}", "10^{2}", "10^{3}", "10^{4}"}, 1); %Cell spreading area
plot_pcolor(t, Es, pi*Ad.^2, [0.1 4], [0.1 1 4], {"0.1", "1.0", "4.0"}, 2); % FA area
plot_pcolor(t, Es, S, [2e-1 2e4], [1e0 1e2 1e4], {"10^{0}", "10^{2}", "10^{4}"}, 3); % Contact stiffness

function plot_pcolor(t, Es, data, clim_vals, cbar_ticks, cbar_labels, figure_num)
    figure(figure_num);
    pcolor(t, Es, data');
    colormap('parula');
    shading interp;

    % Configure colorbar
    colorbar('FontSize', 12, 'FontName', 'Arial', 'TickLength', 0.03, ...
        'LineWidth', 1, 'Ticks', cbar_ticks, 'TickLabels', cbar_labels, ...
        'Color', [0 0 0]);

    % Configure axes
    set(gca, 'YDir', 'reverse', 'FontSize', 12, 'Color', 'none', ...
        'Xcolor', [0, 0, 0], 'Ycolor', [0, 0, 0], ...
        'XScale', 'log', 'YScale', 'log', 'ColorScale', 'log', ...
        'TickLength', [0.03 0.02], 'LineWidth', 1, 'Layer', 'top');

    % Configure figure
    set(gcf, "Units", "centimeters", "Position", [20, 10, 7.5, 5.5]);

    % Configure ticks
    xticks([3 10 30 100]);
    xticklabels([3 10 30 100]);
    yticks([0.1 1 10 100]);
    yticklabels([0.1 1 10 100]);
    
    % Set color limits
    clim(clim_vals);
end



