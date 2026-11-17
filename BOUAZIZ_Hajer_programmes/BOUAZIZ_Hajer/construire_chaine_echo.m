%% Construction du modele chaine_echo.slx (partie 7) : chaine_filtres + canal a echo
% Canal : hc(t) = delta(t) + beta delta(t - tau), tau = retard * T (retard en symboles),
% realise par un retard de retard*L echantillons, un gain beta et une somme, avant le bruit.
% Chaine QPSK (mapping de Gray) en temps suresechantillonne, L echantillons par symbole :
%   source (Tb) -> Buffer 2 -> modulateur QPSK (Ts) -> insertion de zeros (Te = Ts/L)
%   -> filtre de mise en forme h -> bruit complexe (variance sigma2 par voie et par echantillon)
%   -> filtre adapte h(-t) -> calage + echantillonnage (Ts) -> demodulateur -> Unbuffer 2
% Les filtres sont des Discrete FIR Filter de coefficients h (normalises : sum(h.^2) = 1).
% Variables definies par les scripts partie6_q*.m : Tb, Ts, Te, L, p1, graine, h, sigma2,
%   tabI, tabQ, tabB1, tabB2, d_ech, Tsim, beta, retard.
mdl = 'chaine_echo';
if bdIsLoaded(mdl), close_system(mdl, 0); end
if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
new_system(mdl);
open_system(mdl);
set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
          'FixedStep', 'auto', 'StopTime', 'Tsim', 'EnableMultiTasking', 'off', ...
          'BooleanDataType', 'off');

b   = @(nom) [mdl '/' nom];
pos = @(x, y, w, hh) [x, y, x + w, y + hh];
L_ = cell(0, 2);

%% Source
add_block('simulink/Sources/Uniform Random Number', b('Uniforme'), 'Position', pos(20, 100, 70, 30), ...
          'Minimum', '0', 'Maximum', '1', 'Seed', 'graine', 'SampleTime', 'Tb');
add_block('simulink/Logic and Bit Operations/Compare To Constant', b('Bit'), ...
          'Position', pos(110, 100, 60, 30), 'relop', '<', 'const', 'p1');
add_block('simulink/Signal Attributes/Data Type Conversion', b('Bit double'), ...
          'Position', pos(190, 100, 60, 30), 'OutDataTypeStr', 'double');
add_block('simulink/Sinks/To Workspace', b('Bits emis'), 'Position', pos(190, 170, 80, 25), ...
          'VariableName', 'b_emis', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');
L_(end+1, :) = {'Uniforme/1', 'Bit/1'};  L_(end+1, :) = {'Bit/1', 'Bit double/1'};
L_(end+1, :) = {'Bit double/1', 'Bits emis/1'};

%% Buffer 2
add_block('simulink/Discrete/Tapped Delay', b('Buffer2 retards'), 'Position', pos(290, 95, 60, 40), ...
          'vinit', '0', 'samptime', 'Tb', 'NumDelays', '1', 'DelayOrder', 'Oldest', 'includeCurrent', 'on');
add_block('simulink/Discrete/Zero-Order Hold', b('Buffer2 bloc'), 'Position', pos(370, 95, 50, 40), ...
          'SampleTime', 'Ts');
L_(end+1, :) = {'Bit double/1', 'Buffer2 retards/1'};  L_(end+1, :) = {'Buffer2 retards/1', 'Buffer2 bloc/1'};

%% Modulateur QPSK (mapping de Gray)
add_block('simulink/Math Operations/Gain', b('Mod indice'), 'Position', pos(450, 100, 60, 30), ...
          'Gain', '[2 1]', 'Multiplication', 'Matrix(K*u)');
add_block('simulink/Lookup Tables/1-D Lookup Table', b('Mod table I'), 'Position', pos(540, 60, 60, 40), ...
          'Table', 'tabI', 'BreakpointsForDimension1', '0:3');
add_block('simulink/Lookup Tables/1-D Lookup Table', b('Mod table Q'), 'Position', pos(540, 140, 60, 40), ...
          'Table', 'tabQ', 'BreakpointsForDimension1', '0:3');
add_block('simulink/Math Operations/Real-Imag to Complex', b('Mod complexe'), 'Position', pos(630, 95, 50, 50));
add_block('simulink/Sinks/To Workspace', b('Symboles emis'), 'Position', pos(630, 180, 80, 25), ...
          'VariableName', 's_emis', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');
L_(end+1, :) = {'Buffer2 bloc/1', 'Mod indice/1'};
L_(end+1, :) = {'Mod indice/1', 'Mod table I/1'};  L_(end+1, :) = {'Mod indice/1', 'Mod table Q/1'};
L_(end+1, :) = {'Mod table I/1', 'Mod complexe/1'};  L_(end+1, :) = {'Mod table Q/1', 'Mod complexe/2'};
L_(end+1, :) = {'Mod complexe/1', 'Symboles emis/1'};

%% Emission : insertion de L-1 zeros entre les symboles, puis filtre de mise en forme
add_block('simulink/Signal Attributes/Rate Transition', b('Em passage a Te'), ...
          'Position', pos(710, 100, 50, 40), 'OutPortSampleTime', 'Te');
add_block('simulink/Sources/Repeating Sequence Stair', b('Em peigne'), 'Position', pos(710, 170, 60, 30), ...
          'OutValues', '[1 zeros(1, L-1)]', 'tsamp', 'Te');
add_block('simulink/Math Operations/Product', b('Em insertion zeros'), 'Position', pos(790, 105, 40, 40), ...
          'Inputs', '2');
add_block('simulink/Discrete/Discrete FIR Filter', b('Filtre emission'), 'Position', pos(860, 105, 70, 40), ...
          'Coefficients', 'h', 'SampleTime', 'Te');
add_block('simulink/Sinks/To Workspace', b('Signal emis'), 'Position', pos(960, 180, 80, 25), ...
          'VariableName', 'x_emis', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');
L_(end+1, :) = {'Mod complexe/1', 'Em passage a Te/1'};
L_(end+1, :) = {'Em passage a Te/1', 'Em insertion zeros/1'};  L_(end+1, :) = {'Em peigne/1', 'Em insertion zeros/2'};
L_(end+1, :) = {'Em insertion zeros/1', 'Filtre emission/1'};  L_(end+1, :) = {'Filtre emission/1', 'Signal emis/1'};

%% Canal : bruit complexe, variance sigma2 par voie et par echantillon
add_block('simulink/Sources/Random Number', b('Bruit I'), 'Position', pos(960, 260, 60, 30), ...
          'Mean', '0', 'Variance', 'sigma2', 'Seed', 'graine + 1', 'SampleTime', 'Te');
add_block('simulink/Sources/Random Number', b('Bruit Q'), 'Position', pos(960, 320, 60, 30), ...
          'Mean', '0', 'Variance', 'sigma2', 'Seed', 'graine + 2', 'SampleTime', 'Te');
add_block('simulink/Math Operations/Real-Imag to Complex', b('Bruit complexe'), 'Position', pos(1040, 270, 50, 50));
add_block('simulink/Math Operations/Sum', b('Somme'), 'Position', pos(1110, 110, 30, 30), 'Inputs', '++');
% Echo : hc(t) = delta(t) + beta delta(t - retard T)
add_block('simulink/Discrete/Delay', b('Echo retard'), 'Position', pos(960, 20, 50, 30), ...
          'DelayLength', 'retard * L');
add_block('simulink/Math Operations/Gain', b('Echo gain'), 'Position', pos(1030, 20, 50, 30), 'Gain', 'beta');
add_block('simulink/Math Operations/Sum', b('Echo somme'), 'Position', pos(1060, 110, 30, 30), 'Inputs', '++');
L_(end+1, :) = {'Bruit I/1', 'Bruit complexe/1'};  L_(end+1, :) = {'Bruit Q/1', 'Bruit complexe/2'};
L_(end+1, :) = {'Filtre emission/1', 'Echo somme/1'};
L_(end+1, :) = {'Filtre emission/1', 'Echo retard/1'};  L_(end+1, :) = {'Echo retard/1', 'Echo gain/1'};
L_(end+1, :) = {'Echo gain/1', 'Echo somme/2'};
L_(end+1, :) = {'Echo somme/1', 'Somme/1'};  L_(end+1, :) = {'Bruit complexe/1', 'Somme/2'};

%% Reception : filtre adapte, calage, echantillonnage
add_block('simulink/Discrete/Discrete FIR Filter', b('Filtre adapte'), 'Position', pos(1170, 105, 70, 40), ...
          'Coefficients', 'fliplr(h)', 'SampleTime', 'Te');
add_block('simulink/Sinks/To Workspace', b('Sortie filtre adapte'), 'Position', pos(1170, 180, 80, 25), ...
          'VariableName', 'y_fa', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');
add_block('simulink/Discrete/Delay', b('Calage'), 'Position', pos(1270, 110, 50, 30), 'DelayLength', 'd_ech');
add_block('simulink/Discrete/Zero-Order Hold', b('Echantillonneur'), 'Position', pos(1340, 110, 50, 30), ...
          'SampleTime', 'Ts');
add_block('simulink/Sinks/To Workspace', b('Symboles recus'), 'Position', pos(1340, 180, 80, 25), ...
          'VariableName', 'z', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');
L_(end+1, :) = {'Somme/1', 'Filtre adapte/1'};  L_(end+1, :) = {'Filtre adapte/1', 'Sortie filtre adapte/1'};
L_(end+1, :) = {'Filtre adapte/1', 'Calage/1'};  L_(end+1, :) = {'Calage/1', 'Echantillonneur/1'};
L_(end+1, :) = {'Echantillonneur/1', 'Symboles recus/1'};

%% Demodulateur QPSK : decision sur le signe de chaque voie
add_block('simulink/Math Operations/Complex to Real-Imag', b('Demod I et Q'), ...
          'Position', pos(1420, 100, 50, 50), 'Output', 'Real and imag');
add_block('simulink/Logic and Bit Operations/Compare To Constant', b('Demod signe I'), ...
          'Position', pos(1490, 75, 60, 30), 'relop', '<', 'const', '0');
add_block('simulink/Logic and Bit Operations/Compare To Constant', b('Demod signe Q'), ...
          'Position', pos(1490, 145, 60, 30), 'relop', '<', 'const', '0');
add_block('simulink/Signal Attributes/Data Type Conversion', b('Demod sI'), ...
          'Position', pos(1570, 75, 50, 30), 'OutDataTypeStr', 'double');
add_block('simulink/Signal Attributes/Data Type Conversion', b('Demod sQ'), ...
          'Position', pos(1570, 145, 50, 30), 'OutDataTypeStr', 'double');
add_block('simulink/Signal Routing/Mux', b('Demod quadrant'), 'Position', pos(1640, 85, 8, 80), 'Inputs', '2');
add_block('simulink/Math Operations/Gain', b('Demod indice'), 'Position', pos(1670, 110, 60, 30), ...
          'Gain', '[2 1]', 'Multiplication', 'Matrix(K*u)');
add_block('simulink/Lookup Tables/1-D Lookup Table', b('Demod table b1'), 'Position', pos(1750, 70, 60, 40), ...
          'Table', 'tabB1', 'BreakpointsForDimension1', '0:3');
add_block('simulink/Lookup Tables/1-D Lookup Table', b('Demod table b2'), 'Position', pos(1750, 145, 60, 40), ...
          'Table', 'tabB2', 'BreakpointsForDimension1', '0:3');
add_block('simulink/Signal Routing/Mux', b('Demod bits'), 'Position', pos(1830, 85, 8, 80), 'Inputs', '2');
L_(end+1, :) = {'Echantillonneur/1', 'Demod I et Q/1'};
L_(end+1, :) = {'Demod I et Q/1', 'Demod signe I/1'};  L_(end+1, :) = {'Demod I et Q/2', 'Demod signe Q/1'};
L_(end+1, :) = {'Demod signe I/1', 'Demod sI/1'};  L_(end+1, :) = {'Demod signe Q/1', 'Demod sQ/1'};
L_(end+1, :) = {'Demod sI/1', 'Demod quadrant/1'};  L_(end+1, :) = {'Demod sQ/1', 'Demod quadrant/2'};
L_(end+1, :) = {'Demod quadrant/1', 'Demod indice/1'};
L_(end+1, :) = {'Demod indice/1', 'Demod table b1/1'};  L_(end+1, :) = {'Demod indice/1', 'Demod table b2/1'};
L_(end+1, :) = {'Demod table b1/1', 'Demod bits/1'};  L_(end+1, :) = {'Demod table b2/1', 'Demod bits/2'};

%% Unbuffer 2
add_block('simulink/Signal Attributes/Rate Transition', b('Unbuffer2 maintien'), ...
          'Position', pos(1860, 100, 50, 40), 'OutPortSampleTime', 'Tb');
add_block('simulink/Sources/Repeating Sequence Stair', b('Unbuffer2 compteur'), ...
          'Position', pos(1860, 170, 60, 30), 'OutValues', '1:2', 'tsamp', 'Tb');
add_block('simulink/Signal Routing/Selector', b('Unbuffer2 selection'), 'Position', pos(1940, 105, 50, 60), ...
          'NumberOfDimensions', '1', 'IndexMode', 'One-based', ...
          'IndexOptions', 'Index vector (port)', 'InputPortWidth', '2');
add_block('simulink/Sinks/To Workspace', b('Bits recus'), 'Position', pos(2020, 120, 80, 25), ...
          'VariableName', 'b_recu', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');
L_(end+1, :) = {'Demod bits/1', 'Unbuffer2 maintien/1'};
L_(end+1, :) = {'Unbuffer2 maintien/1', 'Unbuffer2 selection/1'};
L_(end+1, :) = {'Unbuffer2 compteur/1', 'Unbuffer2 selection/2'};
L_(end+1, :) = {'Unbuffer2 selection/1', 'Bits recus/1'};

%% Connexions
for i = 1:size(L_, 1)
    add_line(mdl, L_{i, 1}, L_{i, 2}, 'autorouting', 'on');
end

%% Sous-systemes
blocs = get_param(find_system(mdl, 'SearchDepth', 1, 'Type', 'Block'), 'Name');
grp = @(prefixe) blocs(startsWith(blocs, prefixe));
groupes = {'Source', {'Uniforme', 'Bit', 'Bit double'};
           'Buffer 2', grp('Buffer2');
           'Modulateur QPSK', grp('Mod ');
           'Mise en forme', [grp('Em '); {'Filtre emission'}];
           'Canal a echo', {'Echo retard', 'Echo gain', 'Echo somme'};
           'Bruit complexe', {'Bruit I', 'Bruit Q', 'Bruit complexe', 'Somme'};
           'Filtre adapte et echantillonnage', {'Filtre adapte', 'Calage', 'Echantillonneur'};
           'Demodulateur QPSK', grp('Demod ');
           'Unbuffer 2', grp('Unbuffer2')};
for i = 1:size(groupes, 1)
    hh = cellfun(@(n) get_param(b(n), 'Handle'), groupes{i, 2});
    try
        Simulink.BlockDiagram.createSubsystem(hh, 'Name', groupes{i, 1});
    catch
        try, Simulink.BlockDiagram.createSubsystem(hh); catch, end
    end
end

save_system(mdl);
fprintf('Modele %s.slx cree dans %s\n', mdl, pwd);