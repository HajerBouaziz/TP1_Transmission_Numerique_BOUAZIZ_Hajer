%% Construction du modele chaine_qpsk.slx (partie 5, questions 2 a 5)
% Chaine QPSK en bande de base equivalente, un echantillon par symbole :
%   source (Tb) -> Buffer 2 -> modulateur QPSK -> bruit complexe -> demodulateur -> Unbuffer 2
% Modulateur : indice n = 2 b1 + b2, puis tables tabI(n), tabQ(n) (mapping) -> s = I + jQ.
% Demodulateur : decision sur le signe de chaque voie (sI = I<0, sQ = Q<0),
%                puis tables tabB1, tabB2 (demapping ; identite pour le mapping de Gray).
% Variables definies par les scripts partie5_q*.m : Tb, Ts, p1, graine, sigma2v,
%   tabI, tabQ, tabB1, tabB2, Tsim.
mdl = 'chaine_qpsk';
if bdIsLoaded(mdl), close_system(mdl, 0); end
if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
new_system(mdl);
open_system(mdl);
set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
          'FixedStep', 'auto', 'StopTime', 'Tsim', 'EnableMultiTasking', 'off', ...
          'BooleanDataType', 'off');

b   = @(nom) [mdl '/' nom];
pos = @(x, y, w, h) [x, y, x + w, y + h];
L = cell(0, 2);

%% Source
add_block('simulink/Sources/Uniform Random Number', b('Uniforme'), 'Position', pos(20, 100, 70, 30), ...
          'Minimum', '0', 'Maximum', '1', 'Seed', 'graine', 'SampleTime', 'Tb');
add_block('simulink/Logic and Bit Operations/Compare To Constant', b('Bit'), ...
          'Position', pos(110, 100, 60, 30), 'relop', '<', 'const', 'p1');
add_block('simulink/Signal Attributes/Data Type Conversion', b('Bit double'), ...
          'Position', pos(190, 100, 60, 30), 'OutDataTypeStr', 'double');
add_block('simulink/Sinks/To Workspace', b('Bits emis'), 'Position', pos(190, 170, 80, 25), ...
          'VariableName', 'b_emis', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');
L(end+1, :) = {'Uniforme/1', 'Bit/1'};  L(end+1, :) = {'Bit/1', 'Bit double/1'};
L(end+1, :) = {'Bit double/1', 'Bits emis/1'};

%% Buffer 2 : couple [b1 b2] toutes les Ts = 2 Tb
add_block('simulink/Discrete/Tapped Delay', b('Buffer2 retards'), 'Position', pos(290, 95, 60, 40), ...
          'vinit', '0', 'samptime', 'Tb', 'NumDelays', '1', 'DelayOrder', 'Oldest', 'includeCurrent', 'on');
add_block('simulink/Discrete/Zero-Order Hold', b('Buffer2 bloc'), 'Position', pos(370, 95, 50, 40), ...
          'SampleTime', 'Ts');
L(end+1, :) = {'Bit double/1', 'Buffer2 retards/1'};  L(end+1, :) = {'Buffer2 retards/1', 'Buffer2 bloc/1'};

%% Modulateur QPSK
add_block('simulink/Math Operations/Gain', b('Mod indice'), 'Position', pos(450, 100, 60, 30), ...
          'Gain', '[2 1]', 'Multiplication', 'Matrix(K*u)');
add_block('simulink/Lookup Tables/1-D Lookup Table', b('Mod table I'), 'Position', pos(540, 60, 60, 40), ...
          'Table', 'tabI', 'BreakpointsForDimension1', '0:3');
add_block('simulink/Lookup Tables/1-D Lookup Table', b('Mod table Q'), 'Position', pos(540, 140, 60, 40), ...
          'Table', 'tabQ', 'BreakpointsForDimension1', '0:3');
add_block('simulink/Math Operations/Real-Imag to Complex', b('Mod complexe'), 'Position', pos(630, 95, 50, 50));
add_block('simulink/Sinks/To Workspace', b('Symboles emis'), 'Position', pos(700, 180, 80, 25), ...
          'VariableName', 's_emis', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');
L(end+1, :) = {'Buffer2 bloc/1', 'Mod indice/1'};
L(end+1, :) = {'Mod indice/1', 'Mod table I/1'};  L(end+1, :) = {'Mod indice/1', 'Mod table Q/1'};
L(end+1, :) = {'Mod table I/1', 'Mod complexe/1'};  L(end+1, :) = {'Mod table Q/1', 'Mod complexe/2'};
L(end+1, :) = {'Mod complexe/1', 'Symboles emis/1'};

%% Canal : bruit complexe, variance sigma2v = N0/2 sur chaque voie
add_block('simulink/Sources/Random Number', b('Bruit I'), 'Position', pos(630, 260, 60, 30), ...
          'Mean', '0', 'Variance', 'sigma2v', 'Seed', 'graine + 1', 'SampleTime', 'Ts');
add_block('simulink/Sources/Random Number', b('Bruit Q'), 'Position', pos(630, 320, 60, 30), ...
          'Mean', '0', 'Variance', 'sigma2v', 'Seed', 'graine + 2', 'SampleTime', 'Ts');
add_block('simulink/Math Operations/Real-Imag to Complex', b('Bruit complexe'), 'Position', pos(720, 270, 50, 50));
add_block('simulink/Math Operations/Sum', b('Somme'), 'Position', pos(800, 105, 30, 30), 'Inputs', '++');
add_block('simulink/Sinks/To Workspace', b('Symboles recus'), 'Position', pos(860, 180, 80, 25), ...
          'VariableName', 's_recu', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');
L(end+1, :) = {'Bruit I/1', 'Bruit complexe/1'};  L(end+1, :) = {'Bruit Q/1', 'Bruit complexe/2'};
L(end+1, :) = {'Mod complexe/1', 'Somme/1'};  L(end+1, :) = {'Bruit complexe/1', 'Somme/2'};
L(end+1, :) = {'Somme/1', 'Symboles recus/1'};

%% Demodulateur : decision sur le signe de chaque voie, puis demapping
add_block('simulink/Math Operations/Complex to Real-Imag', b('Demod I et Q'), ...
          'Position', pos(860, 95, 50, 50), 'Output', 'Real and imag');
add_block('simulink/Logic and Bit Operations/Compare To Constant', b('Demod signe I'), ...
          'Position', pos(940, 70, 60, 30), 'relop', '<', 'const', '0');
add_block('simulink/Logic and Bit Operations/Compare To Constant', b('Demod signe Q'), ...
          'Position', pos(940, 140, 60, 30), 'relop', '<', 'const', '0');
add_block('simulink/Signal Attributes/Data Type Conversion', b('Demod sI'), ...
          'Position', pos(1020, 70, 50, 30), 'OutDataTypeStr', 'double');
add_block('simulink/Signal Attributes/Data Type Conversion', b('Demod sQ'), ...
          'Position', pos(1020, 140, 50, 30), 'OutDataTypeStr', 'double');
add_block('simulink/Signal Routing/Mux', b('Demod quadrant'), 'Position', pos(1090, 80, 8, 80), 'Inputs', '2');
add_block('simulink/Math Operations/Gain', b('Demod indice'), 'Position', pos(1120, 105, 60, 30), ...
          'Gain', '[2 1]', 'Multiplication', 'Matrix(K*u)');
add_block('simulink/Lookup Tables/1-D Lookup Table', b('Demod table b1'), 'Position', pos(1210, 65, 60, 40), ...
          'Table', 'tabB1', 'BreakpointsForDimension1', '0:3');
add_block('simulink/Lookup Tables/1-D Lookup Table', b('Demod table b2'), 'Position', pos(1210, 140, 60, 40), ...
          'Table', 'tabB2', 'BreakpointsForDimension1', '0:3');
add_block('simulink/Signal Routing/Mux', b('Demod bits'), 'Position', pos(1300, 80, 8, 80), 'Inputs', '2');
L(end+1, :) = {'Somme/1', 'Demod I et Q/1'};
L(end+1, :) = {'Demod I et Q/1', 'Demod signe I/1'};  L(end+1, :) = {'Demod I et Q/2', 'Demod signe Q/1'};
L(end+1, :) = {'Demod signe I/1', 'Demod sI/1'};  L(end+1, :) = {'Demod signe Q/1', 'Demod sQ/1'};
L(end+1, :) = {'Demod sI/1', 'Demod quadrant/1'};  L(end+1, :) = {'Demod sQ/1', 'Demod quadrant/2'};
L(end+1, :) = {'Demod quadrant/1', 'Demod indice/1'};
L(end+1, :) = {'Demod indice/1', 'Demod table b1/1'};  L(end+1, :) = {'Demod indice/1', 'Demod table b2/1'};
L(end+1, :) = {'Demod table b1/1', 'Demod bits/1'};  L(end+1, :) = {'Demod table b2/1', 'Demod bits/2'};

%% Unbuffer 2 : les deux bits ressortent un par un au rythme Tb
add_block('simulink/Signal Attributes/Rate Transition', b('Unbuffer2 maintien'), ...
          'Position', pos(1340, 95, 50, 40), 'OutPortSampleTime', 'Tb');
add_block('simulink/Sources/Repeating Sequence Stair', b('Unbuffer2 compteur'), ...
          'Position', pos(1340, 170, 60, 30), 'OutValues', '1:2', 'tsamp', 'Tb');
add_block('simulink/Signal Routing/Selector', b('Unbuffer2 selection'), 'Position', pos(1420, 100, 50, 60), ...
          'NumberOfDimensions', '1', 'IndexMode', 'One-based', ...
          'IndexOptions', 'Index vector (port)', 'InputPortWidth', '2');
add_block('simulink/Sinks/To Workspace', b('Bits recus'), 'Position', pos(1500, 115, 80, 25), ...
          'VariableName', 'b_recu', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');
L(end+1, :) = {'Demod bits/1', 'Unbuffer2 maintien/1'};
L(end+1, :) = {'Unbuffer2 maintien/1', 'Unbuffer2 selection/1'};
L(end+1, :) = {'Unbuffer2 compteur/1', 'Unbuffer2 selection/2'};
L(end+1, :) = {'Unbuffer2 selection/1', 'Bits recus/1'};

%% Connexions
for i = 1:size(L, 1)
    add_line(mdl, L{i, 1}, L{i, 2}, 'autorouting', 'on');
end

%% Sous-systemes
blocs = get_param(find_system(mdl, 'SearchDepth', 1, 'Type', 'Block'), 'Name');
grp = @(prefixe) blocs(startsWith(blocs, prefixe));
groupes = {'Source', {'Uniforme', 'Bit', 'Bit double'};
           'Buffer 2', grp('Buffer2');
           'Modulateur QPSK', grp('Mod ');
           'Canal (bruit complexe)', {'Bruit I', 'Bruit Q', 'Bruit complexe', 'Somme'};
           'Demodulateur QPSK', grp('Demod ');
           'Unbuffer 2', grp('Unbuffer2')};
for i = 1:size(groupes, 1)
    h = cellfun(@(n) get_param(b(n), 'Handle'), groupes{i, 2});
    try
        Simulink.BlockDiagram.createSubsystem(h, 'Name', groupes{i, 1});
    catch
        try, Simulink.BlockDiagram.createSubsystem(h); catch, end
    end
end

save_system(mdl);
fprintf('Modele %s.slx cree dans %s\n', mdl, pwd);