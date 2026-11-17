%% Construction du modele chaine_qpsk_codee.slx (partie 5, question 6)
% Deux chaines QPSK (mapping de Gray) en parallele, alimentees par la meme source :
%   - SANS codage : bits (Tb) -> Buffer 2 -> QPSK (Ts = 2 Tb) -> bruit -> demodulation -> Unbuffer 2
%   - AVEC codage : Buffer 4 -> codeur de Hamming -> Unbuffer 7 (bits codes a Tc = 4 Tb/7)
%                   -> Buffer 2 -> QPSK (Ts = 2 Tc = 8 Tb/7) -> bruit -> demodulation
%                   -> Unbuffer 2 -> Buffer 7 -> decodeur de Hamming -> Unbuffer 4
% Les couples de bits codes sont formes sur le flux continu : 2 mots-codes = 14 bits = 7 symboles,
% sans bit de bourrage.
% Variables definies par partie5_q6.m : Tb, Tc, Ts_nc, Ts_c, p1, graine, sigma2v,
%   tabI, tabQ, tabIc, tabQc, tabB1, tabB2, dw, Tsim.
mdl = 'chaine_qpsk_codee';
if bdIsLoaded(mdl), close_system(mdl, 0); end
if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
new_system(mdl);
open_system(mdl);
set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
          'FixedStep', 'auto', 'StopTime', 'Tsim', 'EnableMultiTasking', 'off', ...
          'BooleanDataType', 'off');

b   = @(nom) [mdl '/' nom];
pos = @(x, y, w, h) [x, y, x + w, y + h];
porte = @(nom, op, n, x, y) add_block('simulink/Logic and Bit Operations/Logical Operator', ...
          b(nom), 'Position', pos(x, y, 45, 18 + 10*n), 'Operator', op, 'Inputs', num2str(n));
L = cell(0, 2);

%% ======================= Source (commune) =======================
add_block('simulink/Sources/Uniform Random Number', b('Uniforme'), 'Position', pos(20, 300, 70, 30), ...
          'Minimum', '0', 'Maximum', '1', 'Seed', 'graine', 'SampleTime', 'Tb');
add_block('simulink/Logic and Bit Operations/Compare To Constant', b('Bit'), ...
          'Position', pos(110, 300, 60, 30), 'relop', '<', 'const', 'p1');
add_block('simulink/Signal Attributes/Data Type Conversion', b('Bit double'), ...
          'Position', pos(190, 300, 60, 30), 'OutDataTypeStr', 'double');
add_block('simulink/Sinks/To Workspace', b('Bits emis'), 'Position', pos(190, 360, 80, 25), ...
          'VariableName', 'b_emis', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');
L(end+1, :) = {'Uniforme/1', 'Bit/1'};  L(end+1, :) = {'Bit/1', 'Bit double/1'};
L(end+1, :) = {'Bit double/1', 'Bits emis/1'};

%% ======================= Deux chaines QPSK (sans codage : NC, avec codage : C) =======================
% Pour chaque branche : Buffer 2, modulateur, canal, demodulateur, Unbuffer 2.
br = struct('p', {'NC', 'C'}, 'Tbit', {'Tb', 'Tc'}, 'Ts', {'Ts_nc', 'Ts_c'}, ...
            'tI', {'tabI', 'tabIc'}, 'tQ', {'tabQ', 'tabQc'}, 'seed', {'graine + 1', 'graine + 3'}, ...
            'y', {60, 600}, 'x', {300, 760});
for k = 1:2
    p = br(k).p;  x = br(k).x;  y = br(k).y;  nm = @(s) sprintf('%s %s', p, s);
    add_block('simulink/Discrete/Tapped Delay', b(nm('Buffer2 retards')), 'Position', pos(x, y, 60, 40), ...
              'vinit', '0', 'samptime', br(k).Tbit, 'NumDelays', '1', 'DelayOrder', 'Oldest', 'includeCurrent', 'on');
    add_block('simulink/Discrete/Zero-Order Hold', b(nm('Buffer2 bloc')), 'Position', pos(x + 80, y, 50, 40), ...
              'SampleTime', br(k).Ts);
    add_block('simulink/Math Operations/Gain', b(nm('Mod indice')), 'Position', pos(x + 150, y + 5, 60, 30), ...
              'Gain', '[2 1]', 'Multiplication', 'Matrix(K*u)');
    add_block('simulink/Lookup Tables/1-D Lookup Table', b(nm('Mod table I')), 'Position', pos(x + 230, y - 30, 60, 40), ...
              'Table', br(k).tI, 'BreakpointsForDimension1', '0:3');
    add_block('simulink/Lookup Tables/1-D Lookup Table', b(nm('Mod table Q')), 'Position', pos(x + 230, y + 40, 60, 40), ...
              'Table', br(k).tQ, 'BreakpointsForDimension1', '0:3');
    add_block('simulink/Math Operations/Real-Imag to Complex', b(nm('Mod complexe')), 'Position', pos(x + 310, y, 50, 50));
    add_block('simulink/Sources/Random Number', b(nm('Bruit I')), 'Position', pos(x + 310, y + 100, 60, 30), ...
              'Mean', '0', 'Variance', 'sigma2v', 'Seed', br(k).seed, 'SampleTime', br(k).Ts);
    add_block('simulink/Sources/Random Number', b(nm('Bruit Q')), 'Position', pos(x + 310, y + 150, 60, 30), ...
              'Mean', '0', 'Variance', 'sigma2v', 'Seed', [br(k).seed ' + 1'], 'SampleTime', br(k).Ts);
    add_block('simulink/Math Operations/Real-Imag to Complex', b(nm('Bruit complexe')), 'Position', pos(x + 390, y + 110, 50, 50));
    add_block('simulink/Math Operations/Sum', b(nm('Somme')), 'Position', pos(x + 460, y + 10, 30, 30), 'Inputs', '++');
    add_block('simulink/Math Operations/Complex to Real-Imag', b(nm('Demod I et Q')), ...
              'Position', pos(x + 520, y, 50, 50), 'Output', 'Real and imag');
    add_block('simulink/Logic and Bit Operations/Compare To Constant', b(nm('Demod signe I')), ...
              'Position', pos(x + 590, y - 25, 60, 30), 'relop', '<', 'const', '0');
    add_block('simulink/Logic and Bit Operations/Compare To Constant', b(nm('Demod signe Q')), ...
              'Position', pos(x + 590, y + 45, 60, 30), 'relop', '<', 'const', '0');
    add_block('simulink/Signal Attributes/Data Type Conversion', b(nm('Demod sI')), ...
              'Position', pos(x + 670, y - 25, 50, 30), 'OutDataTypeStr', 'double');
    add_block('simulink/Signal Attributes/Data Type Conversion', b(nm('Demod sQ')), ...
              'Position', pos(x + 670, y + 45, 50, 30), 'OutDataTypeStr', 'double');
    add_block('simulink/Signal Routing/Mux', b(nm('Demod quadrant')), 'Position', pos(x + 740, y - 15, 8, 80), 'Inputs', '2');
    add_block('simulink/Math Operations/Gain', b(nm('Demod indice')), 'Position', pos(x + 770, y + 10, 60, 30), ...
              'Gain', '[2 1]', 'Multiplication', 'Matrix(K*u)');
    add_block('simulink/Lookup Tables/1-D Lookup Table', b(nm('Demod table b1')), 'Position', pos(x + 850, y - 30, 60, 40), ...
              'Table', 'tabB1', 'BreakpointsForDimension1', '0:3');
    add_block('simulink/Lookup Tables/1-D Lookup Table', b(nm('Demod table b2')), 'Position', pos(x + 850, y + 40, 60, 40), ...
              'Table', 'tabB2', 'BreakpointsForDimension1', '0:3');
    add_block('simulink/Signal Routing/Mux', b(nm('Demod bits')), 'Position', pos(x + 930, y - 15, 8, 80), 'Inputs', '2');
    add_block('simulink/Signal Attributes/Rate Transition', b(nm('Unbuffer2 maintien')), ...
              'Position', pos(x + 960, y, 50, 40), 'OutPortSampleTime', br(k).Tbit);
    add_block('simulink/Sources/Repeating Sequence Stair', b(nm('Unbuffer2 compteur')), ...
              'Position', pos(x + 960, y + 70, 60, 30), 'OutValues', '1:2', 'tsamp', br(k).Tbit);
    add_block('simulink/Signal Routing/Selector', b(nm('Unbuffer2 selection')), 'Position', pos(x + 1040, y + 5, 50, 60), ...
              'NumberOfDimensions', '1', 'IndexMode', 'One-based', ...
              'IndexOptions', 'Index vector (port)', 'InputPortWidth', '2');
    c = {'Buffer2 retards/1', 'Buffer2 bloc/1';  'Buffer2 bloc/1', 'Mod indice/1';
         'Mod indice/1', 'Mod table I/1';  'Mod indice/1', 'Mod table Q/1';
         'Mod table I/1', 'Mod complexe/1';  'Mod table Q/1', 'Mod complexe/2';
         'Bruit I/1', 'Bruit complexe/1';  'Bruit Q/1', 'Bruit complexe/2';
         'Mod complexe/1', 'Somme/1';  'Bruit complexe/1', 'Somme/2';  'Somme/1', 'Demod I et Q/1';
         'Demod I et Q/1', 'Demod signe I/1';  'Demod I et Q/2', 'Demod signe Q/1';
         'Demod signe I/1', 'Demod sI/1';  'Demod signe Q/1', 'Demod sQ/1';
         'Demod sI/1', 'Demod quadrant/1';  'Demod sQ/1', 'Demod quadrant/2';
         'Demod quadrant/1', 'Demod indice/1';
         'Demod indice/1', 'Demod table b1/1';  'Demod indice/1', 'Demod table b2/1';
         'Demod table b1/1', 'Demod bits/1';  'Demod table b2/1', 'Demod bits/2';
         'Demod bits/1', 'Unbuffer2 maintien/1';  'Unbuffer2 maintien/1', 'Unbuffer2 selection/1';
         'Unbuffer2 compteur/1', 'Unbuffer2 selection/2'};
    for i = 1:size(c, 1)
        L(end+1, :) = {nm(c{i, 1}), nm(c{i, 2})};  %#ok<SAGROW>
    end
end

%% Branche sans codage : entree et sortie
add_block('simulink/Sinks/To Workspace', b('Bits recus sans codage'), 'Position', pos(1440, 65, 80, 25), ...
          'VariableName', 'b_nc', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');
L(end+1, :) = {'Bit double/1', 'NC Buffer2 retards/1'};
L(end+1, :) = {'NC Unbuffer2 selection/1', 'Bits recus sans codage/1'};

%% ======================= Codage de Hamming (branche avec codage) =======================
y0 = 420;
add_block('simulink/Discrete/Tapped Delay', b('Buffer4 retards'), 'Position', pos(300, y0, 60, 40), ...
          'vinit', '0', 'samptime', 'Tb', 'NumDelays', '3', 'DelayOrder', 'Oldest', 'includeCurrent', 'on');
add_block('simulink/Discrete/Zero-Order Hold', b('Buffer4 bloc'), 'Position', pos(380, y0, 50, 40), ...
          'SampleTime', '4*Tb');
add_block('simulink/Signal Routing/Demux', b('Cod Bits m'), 'Position', pos(450, y0 - 20, 8, 80), 'Outputs', '4');
porte('Cod r0', 'XOR', 3, 480, y0 + 70);
porte('Cod r1', 'XOR', 3, 480, y0 + 120);
porte('Cod r2', 'XOR', 3, 480, y0 + 170);
for j = 0:2
    add_block('simulink/Signal Attributes/Data Type Conversion', b(sprintf('Cod r%d double', j)), ...
              'Position', pos(545, y0 + 75 + 50*j, 30, 20), 'OutDataTypeStr', 'double');
end
add_block('simulink/Signal Routing/Mux', b('Cod Mot code'), 'Position', pos(600, y0 - 20, 8, 230), 'Inputs', '7');
add_block('simulink/Signal Attributes/Rate Transition', b('Unbuffer7 maintien'), ...
          'Position', pos(630, y0 + 60, 50, 40), 'OutPortSampleTime', 'Tc');
add_block('simulink/Sources/Repeating Sequence Stair', b('Unbuffer7 compteur'), ...
          'Position', pos(630, y0 + 130, 60, 30), 'OutValues', '1:7', 'tsamp', 'Tc');
add_block('simulink/Signal Routing/Selector', b('Unbuffer7 selection'), 'Position', pos(700, y0 + 65, 50, 60), ...
          'NumberOfDimensions', '1', 'IndexMode', 'One-based', ...
          'IndexOptions', 'Index vector (port)', 'InputPortWidth', '7');
L(end+1, :) = {'Bit double/1', 'Buffer4 retards/1'};  L(end+1, :) = {'Buffer4 retards/1', 'Buffer4 bloc/1'};
L(end+1, :) = {'Buffer4 bloc/1', 'Cod Bits m/1'};
R = {[1 3 4], [1 2 3], [2 3 4]};               % r0 = m0+m2+m3, r1 = m0+m1+m2, r2 = m1+m2+m3
for j = 0:2
    for k = 1:3, L(end+1, :) = {sprintf('Cod Bits m/%d', R{j+1}(k)), sprintf('Cod r%d/%d', j, k)}; end %#ok<SAGROW>
    L(end+1, :) = {sprintf('Cod r%d/1', j), sprintf('Cod r%d double/1', j)};
    L(end+1, :) = {sprintf('Cod r%d double/1', j), sprintf('Cod Mot code/%d', 5 + j)};
end
for j = 1:4, L(end+1, :) = {sprintf('Cod Bits m/%d', j), sprintf('Cod Mot code/%d', j)}; end
L(end+1, :) = {'Cod Mot code/1', 'Unbuffer7 maintien/1'};
L(end+1, :) = {'Unbuffer7 maintien/1', 'Unbuffer7 selection/1'};
L(end+1, :) = {'Unbuffer7 compteur/1', 'Unbuffer7 selection/2'};
L(end+1, :) = {'Unbuffer7 selection/1', 'C Buffer2 retards/1'};

%% ======================= Decodage de Hamming =======================
y1 = 900;
add_block('simulink/Discrete/Delay', b('Buffer7 alignement'), 'Position', pos(300, y1, 50, 30), 'DelayLength', 'dw');
add_block('simulink/Discrete/Tapped Delay', b('Buffer7 retards'), 'Position', pos(380, y1, 60, 40), ...
          'vinit', '0', 'samptime', 'Tc', 'NumDelays', '6', 'DelayOrder', 'Oldest', 'includeCurrent', 'on');
add_block('simulink/Discrete/Zero-Order Hold', b('Buffer7 bloc'), 'Position', pos(460, y1, 50, 40), ...
          'SampleTime', '4*Tb');
add_block('simulink/Signal Routing/Demux', b('Dec Bits r'), 'Position', pos(540, y1 - 40, 8, 200), 'Outputs', '7');
porte('Dec s1', 'XOR', 4, 600, y1 - 60);  porte('Dec s2', 'XOR', 4, 600, y1);  porte('Dec s3', 'XOR', 4, 600, y1 + 60);
porte('Dec non s1', 'NOT', 1, 680, y1 + 130); porte('Dec non s2', 'NOT', 1, 680, y1 + 170); porte('Dec non s3', 'NOT', 1, 680, y1 + 210);
porte('Dec e1', 'AND', 3, 760, y1 - 60); porte('Dec e2', 'AND', 3, 760, y1);
porte('Dec e3', 'AND', 3, 760, y1 + 60); porte('Dec e4', 'AND', 3, 760, y1 + 120);
porte('Dec m1', 'XOR', 2, 840, y1 - 60); porte('Dec m2', 'XOR', 2, 840, y1);
porte('Dec m3', 'XOR', 2, 840, y1 + 60); porte('Dec m4', 'XOR', 2, 840, y1 + 120);
add_block('simulink/Signal Routing/Mux', b('Dec Message'), 'Position', pos(920, y1 - 50, 8, 200), 'Inputs', '4');
add_block('simulink/Signal Attributes/Rate Transition', b('Unbuffer4 maintien'), ...
          'Position', pos(960, y1, 50, 40), 'OutPortSampleTime', 'Tb');
add_block('simulink/Sources/Repeating Sequence Stair', b('Unbuffer4 compteur'), ...
          'Position', pos(960, y1 + 70, 60, 30), 'OutValues', '1:4', 'tsamp', 'Tb');
add_block('simulink/Signal Routing/Selector', b('Unbuffer4 selection'), 'Position', pos(1040, y1 + 5, 50, 60), ...
          'NumberOfDimensions', '1', 'IndexMode', 'One-based', ...
          'IndexOptions', 'Index vector (port)', 'InputPortWidth', '4');
add_block('simulink/Sinks/To Workspace', b('Bits recus avec codage'), 'Position', pos(1120, y1 + 20, 80, 25), ...
          'VariableName', 'b_c', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');
L(end+1, :) = {'C Unbuffer2 selection/1', 'Buffer7 alignement/1'};
L(end+1, :) = {'Buffer7 alignement/1', 'Buffer7 retards/1'};  L(end+1, :) = {'Buffer7 retards/1', 'Buffer7 bloc/1'};
L(end+1, :) = {'Buffer7 bloc/1', 'Dec Bits r/1'};
S = {[1 3 4 5], [1 2 3 6], [2 3 4 7]};
for i = 1:3
    for k = 1:4, L(end+1, :) = {sprintf('Dec Bits r/%d', S{i}(k)), sprintf('Dec s%d/%d', i, k)}; end %#ok<SAGROW>
    L(end+1, :) = {sprintf('Dec s%d/1', i), sprintf('Dec non s%d/1', i)};
end
E = {{'Dec s1', 'Dec s2', 'Dec non s3'}, {'Dec non s1', 'Dec s2', 'Dec s3'}, ...
     {'Dec s1', 'Dec s2', 'Dec s3'},     {'Dec s1', 'Dec non s2', 'Dec s3'}};
for j = 1:4
    for k = 1:3, L(end+1, :) = {[E{j}{k} '/1'], sprintf('Dec e%d/%d', j, k)}; end %#ok<SAGROW>
    L(end+1, :) = {sprintf('Dec Bits r/%d', j), sprintf('Dec m%d/1', j)};
    L(end+1, :) = {sprintf('Dec e%d/1', j), sprintf('Dec m%d/2', j)};
    L(end+1, :) = {sprintf('Dec m%d/1', j), sprintf('Dec Message/%d', j)};
end
L(end+1, :) = {'Dec Message/1', 'Unbuffer4 maintien/1'};
L(end+1, :) = {'Unbuffer4 maintien/1', 'Unbuffer4 selection/1'};
L(end+1, :) = {'Unbuffer4 compteur/1', 'Unbuffer4 selection/2'};
L(end+1, :) = {'Unbuffer4 selection/1', 'Bits recus avec codage/1'};

%% ======================= Connexions =======================
for i = 1:size(L, 1)
    add_line(mdl, L{i, 1}, L{i, 2}, 'autorouting', 'on');
end

%% ======================= Sous-systemes =======================
blocs = get_param(find_system(mdl, 'SearchDepth', 1, 'Type', 'Block'), 'Name');
grp = @(prefixe) blocs(startsWith(blocs, prefixe));
groupes = {'Source', {'Uniforme', 'Bit', 'Bit double'};
           'Buffer 2 (sans codage)', grp('NC Buffer2');
           'Modulateur QPSK (sans codage)', grp('NC Mod ');
           'Canal (sans codage)', [grp('NC Bruit'); grp('NC Somme')];
           'Demodulateur QPSK (sans codage)', grp('NC Demod ');
           'Unbuffer 2 (sans codage)', grp('NC Unbuffer2');
           'Buffer 4', grp('Buffer4');
           'Codeur Hamming', grp('Cod ');
           'Unbuffer 7', grp('Unbuffer7');
           'Buffer 2 (bits codes)', grp('C Buffer2');
           'Modulateur QPSK (bits codes)', grp('C Mod ');
           'Canal (bits codes)', [grp('C Bruit'); grp('C Somme')];
           'Demodulateur QPSK (bits codes)', grp('C Demod ');
           'Unbuffer 2 (bits codes)', grp('C Unbuffer2');
           'Buffer 7', grp('Buffer7');
           'Decodeur Hamming', grp('Dec ');
           'Unbuffer 4', grp('Unbuffer4')};
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