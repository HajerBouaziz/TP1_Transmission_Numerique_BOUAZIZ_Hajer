%% Construction du modele chaine_codee.slx (partie 4, question 10)
% Deux chaines en parallele, alimentees par la meme source :
%   - chaine SANS codage : bits (Tb) -> +/-A -> L echantillons -> bruit -> integrateur -> decision
%   - chaine AVEC codage : Buffer 4 -> codeur de Hamming -> Unbuffer 7 (bits codes a Tc = 4Tb/7)
%                          -> +/-A*sqrt(4/7) -> L echantillons -> bruit -> integrateur -> decision
%                          -> Buffer 7 -> decodeur de Hamming -> Unbuffer 4 -> bits (Tb)
% Codeur et decodeur realises avec des portes logiques (memes equations qu'aux questions 5-6).
% Buffer / Unbuffer realises avec des blocs Simulink de base (Tapped Delay, Zero-Order Hold,
% Rate Transition, Selector), sans toolbox supplementaire.
% Les variables (Tb, Tc, L, A, Ac, sigma2, ...) sont definies par partie4_q10.m.
mdl = 'chaine_codee';
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
lignes = cell(0, 2);

%% ======================= Source (commune) =======================
add_block('simulink/Sources/Uniform Random Number', b('Uniforme'), 'Position', pos(20, 300, 70, 30), ...
          'Minimum', '0', 'Maximum', '1', 'Seed', 'graine', 'SampleTime', 'Tb');
add_block('simulink/Logic and Bit Operations/Compare To Constant', b('Bit'), ...
          'Position', pos(120, 300, 60, 30), 'relop', '<', 'const', 'p1');
add_block('simulink/Signal Attributes/Data Type Conversion', b('Bit double'), ...
          'Position', pos(210, 300, 60, 30), 'OutDataTypeStr', 'double');
add_block('simulink/Sinks/To Workspace', b('Bits emis'), 'Position', pos(300, 360, 80, 25), ...
          'VariableName', 'b_emis', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');
lignes(end+1, :) = {'Uniforme/1', 'Bit/1'}; lignes(end+1, :) = {'Bit/1', 'Bit double/1'}; lignes(end+1, :) = {'Bit double/1', 'Bits emis/1'};

%% ======================= Chaine SANS codage (en haut) =======================
add_block('simulink/Math Operations/Gain', b('NC Gain 2A'), 'Position', pos(320, 60, 50, 30), 'Gain', '2*A');
add_block('simulink/Math Operations/Bias', b('NC Bias -A'), 'Position', pos(400, 60, 50, 30), 'Bias', '-A');
add_block('simulink/Signal Attributes/Rate Transition', b('NC Passage a Te'), ...
          'Position', pos(480, 60, 50, 30), 'OutPortSampleTime', 'Te_nc');
add_block('simulink/Sources/Random Number', b('NC Bruit'), 'Position', pos(480, 120, 60, 30), ...
          'Mean', '0', 'Variance', 'sigma2', 'Seed', 'graine + 1', 'SampleTime', 'Te_nc');
add_block('simulink/Math Operations/Sum', b('NC Somme'), 'Position', pos(570, 62, 25, 25), 'Inputs', '++');
add_block('simulink/Discrete/Discrete FIR Filter', b('NC Integrateur'), 'Position', pos(630, 60, 60, 30), ...
          'Coefficients', 'ones(1, L) / L', 'SampleTime', 'Te_nc');
add_block('simulink/Discrete/Delay', b('NC Calage'), 'Position', pos(720, 60, 50, 30), 'DelayLength', 'd_nc');
add_block('simulink/Discrete/Zero-Order Hold', b('NC Echantillonneur'), ...
          'Position', pos(800, 60, 50, 30), 'SampleTime', 'Tb');
add_block('simulink/Logic and Bit Operations/Compare To Constant', b('NC Comparateur'), ...
          'Position', pos(880, 60, 50, 30), 'relop', '>', 'const', 'seuil');
add_block('simulink/Signal Attributes/Data Type Conversion', b('NC Bit recu'), ...
          'Position', pos(960, 60, 50, 30), 'OutDataTypeStr', 'double');
add_block('simulink/Sinks/To Workspace', b('Bits recus sans codage'), 'Position', pos(1050, 60, 80, 25), ...
          'VariableName', 'b_nc', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');
add_block('simulink/Sinks/To Workspace', b('z sans codage'), 'Position', pos(880, 120, 80, 25), ...
          'VariableName', 'z_nc', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');
lignes(end+1, :) = {'Bit double/1', 'NC Gain 2A/1'}; lignes(end+1, :) = {'NC Gain 2A/1', 'NC Bias -A/1'};
lignes(end+1, :) = {'NC Bias -A/1', 'NC Passage a Te/1'}; lignes(end+1, :) = {'NC Passage a Te/1', 'NC Somme/1'};
lignes(end+1, :) = {'NC Bruit/1', 'NC Somme/2'}; lignes(end+1, :) = {'NC Somme/1', 'NC Integrateur/1'};
lignes(end+1, :) = {'NC Integrateur/1', 'NC Calage/1'}; lignes(end+1, :) = {'NC Calage/1', 'NC Echantillonneur/1'};
lignes(end+1, :) = {'NC Echantillonneur/1', 'NC Comparateur/1'}; lignes(end+1, :) = {'NC Echantillonneur/1', 'z sans codage/1'};
lignes(end+1, :) = {'NC Comparateur/1', 'NC Bit recu/1'}; lignes(end+1, :) = {'NC Bit recu/1', 'Bits recus sans codage/1'};

%% ======================= Chaine AVEC codage (en bas) =======================
y0 = 500;
% --- Buffer 4 : 4 bits successifs -> un vecteur [m0 m1 m2 m3] toutes les 4 Tb
add_block('simulink/Discrete/Tapped Delay', b('Buffer4 retards'), 'Position', pos(320, y0, 60, 40), ...
          'vinit', '0', 'samptime', 'Tb', 'NumDelays', '3', 'DelayOrder', 'Oldest', 'includeCurrent', 'on');
add_block('simulink/Discrete/Zero-Order Hold', b('Buffer4 bloc'), 'Position', pos(400, y0, 50, 40), ...
          'SampleTime', '4*Tb');
lignes(end+1, :) = {'Bit double/1', 'Buffer4 retards/1'}; lignes(end+1, :) = {'Buffer4 retards/1', 'Buffer4 bloc/1'};

% --- Codeur de Hamming (portes XOR) : r0 = m0+m2+m3, r1 = m0+m1+m2, r2 = m1+m2+m3
add_block('simulink/Signal Routing/Demux', b('C Bits m'), 'Position', pos(480, y0 - 20, 8, 80), 'Outputs', '4');
porte('C r0', 'XOR', 3, 530, y0 + 80);
porte('C r1', 'XOR', 3, 530, y0 + 140);
porte('C r2', 'XOR', 3, 530, y0 + 200);
add_block('simulink/Signal Routing/Mux', b('C Mot code'), 'Position', pos(610, y0 - 20, 8, 260), 'Inputs', '7');
lignes(end+1, :) = {'Buffer4 bloc/1', 'C Bits m/1'};
lignes(end+1, :) = {'C Bits m/1', 'C r0/1'}; lignes(end+1, :) = {'C Bits m/3', 'C r0/2'}; lignes(end+1, :) = {'C Bits m/4', 'C r0/3'};
lignes(end+1, :) = {'C Bits m/1', 'C r1/1'}; lignes(end+1, :) = {'C Bits m/2', 'C r1/2'}; lignes(end+1, :) = {'C Bits m/3', 'C r1/3'};
lignes(end+1, :) = {'C Bits m/2', 'C r2/1'}; lignes(end+1, :) = {'C Bits m/3', 'C r2/2'}; lignes(end+1, :) = {'C Bits m/4', 'C r2/3'};
for j = 1:4, lignes(end+1, :) = {sprintf('C Bits m/%d', j), sprintf('C Mot code/%d', j)}; end
% conversion en double des bits de redondance (le Mux exige un seul type de donnees)
for j = 0:2
    add_block('simulink/Signal Attributes/Data Type Conversion', b(sprintf('C r%d double', j)), ...
              'Position', pos(570, y0 + 85 + 60*j, 30, 20), 'OutDataTypeStr', 'double');
    lignes(end+1, :) = {sprintf('C r%d/1', j), sprintf('C r%d double/1', j)};
    lignes(end+1, :) = {sprintf('C r%d double/1', j), sprintf('C Mot code/%d', 5 + j)};
end

% --- Unbuffer 7 : le mot de 7 bits est emis bit par bit au rythme Tc = 4 Tb / 7
add_block('simulink/Signal Attributes/Rate Transition', b('Unbuffer7 maintien'), ...
          'Position', pos(650, y0 + 80, 50, 40), 'OutPortSampleTime', 'Tc');
add_block('simulink/Sources/Repeating Sequence Stair', b('Unbuffer7 compteur'), ...
          'Position', pos(650, y0 + 150, 60, 30), 'OutValues', '1:7', 'tsamp', 'Tc');
add_block('simulink/Signal Routing/Selector', b('Unbuffer7 selection'), 'Position', pos(740, y0 + 85, 50, 60), ...
          'NumberOfDimensions', '1', 'IndexMode', 'One-based', ...
          'IndexOptions', 'Index vector (port)', 'InputPortWidth', '7');
lignes(end+1, :) = {'C Mot code/1', 'Unbuffer7 maintien/1'}; lignes(end+1, :) = {'Unbuffer7 maintien/1', 'Unbuffer7 selection/1'};
lignes(end+1, :) = {'Unbuffer7 compteur/1', 'Unbuffer7 selection/2'};

% --- Emetteur, canal, detecteur pour les bits codes (amplitude Ac = A sqrt(4/7))
add_block('simulink/Math Operations/Gain', b('C Gain 2Ac'), 'Position', pos(820, y0 + 95, 50, 30), 'Gain', '2*Ac');
add_block('simulink/Math Operations/Bias', b('C Bias -Ac'), 'Position', pos(890, y0 + 95, 50, 30), 'Bias', '-Ac');
add_block('simulink/Signal Attributes/Rate Transition', b('C Passage a Te'), ...
          'Position', pos(960, y0 + 95, 50, 30), 'OutPortSampleTime', 'Te_c');
add_block('simulink/Sources/Random Number', b('C Bruit'), 'Position', pos(960, y0 + 160, 60, 30), ...
          'Mean', '0', 'Variance', 'sigma2', 'Seed', 'graine + 2', 'SampleTime', 'Te_c');
add_block('simulink/Math Operations/Sum', b('C Somme'), 'Position', pos(1040, y0 + 97, 25, 25), 'Inputs', '++');
add_block('simulink/Discrete/Discrete FIR Filter', b('C Integrateur'), 'Position', pos(1090, y0 + 95, 60, 30), ...
          'Coefficients', 'ones(1, L) / L', 'SampleTime', 'Te_c');
add_block('simulink/Discrete/Delay', b('C Calage'), 'Position', pos(1170, y0 + 95, 50, 30), 'DelayLength', 'd_c');
add_block('simulink/Discrete/Zero-Order Hold', b('C Echantillonneur'), ...
          'Position', pos(1240, y0 + 95, 50, 30), 'SampleTime', 'Tc');
add_block('simulink/Logic and Bit Operations/Compare To Constant', b('C Comparateur'), ...
          'Position', pos(1310, y0 + 95, 50, 30), 'relop', '>', 'const', 'seuil');
add_block('simulink/Signal Attributes/Data Type Conversion', b('C Bit code recu'), ...
          'Position', pos(1380, y0 + 95, 50, 30), 'OutDataTypeStr', 'double');
add_block('simulink/Sinks/To Workspace', b('z avec codage'), 'Position', pos(1310, y0 + 160, 80, 25), ...
          'VariableName', 'z_c', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');
lignes(end+1, :) = {'Unbuffer7 selection/1', 'C Gain 2Ac/1'}; lignes(end+1, :) = {'C Gain 2Ac/1', 'C Bias -Ac/1'};
lignes(end+1, :) = {'C Bias -Ac/1', 'C Passage a Te/1'}; lignes(end+1, :) = {'C Passage a Te/1', 'C Somme/1'};
lignes(end+1, :) = {'C Bruit/1', 'C Somme/2'}; lignes(end+1, :) = {'C Somme/1', 'C Integrateur/1'};
lignes(end+1, :) = {'C Integrateur/1', 'C Calage/1'}; lignes(end+1, :) = {'C Calage/1', 'C Echantillonneur/1'};
lignes(end+1, :) = {'C Echantillonneur/1', 'C Comparateur/1'}; lignes(end+1, :) = {'C Echantillonneur/1', 'z avec codage/1'};
lignes(end+1, :) = {'C Comparateur/1', 'C Bit code recu/1'};

% --- Buffer 7 : regroupe 7 bits codes recus en un mot (alignement reglable par dw)
y1 = 800;
add_block('simulink/Discrete/Delay', b('Buffer7 alignement'), 'Position', pos(320, y1, 50, 30), 'DelayLength', 'dw');
add_block('simulink/Discrete/Tapped Delay', b('Buffer7 retards'), 'Position', pos(400, y1, 60, 40), ...
          'vinit', '0', 'samptime', 'Tc', 'NumDelays', '6', 'DelayOrder', 'Oldest', 'includeCurrent', 'on');
add_block('simulink/Discrete/Zero-Order Hold', b('Buffer7 bloc'), 'Position', pos(480, y1, 50, 40), ...
          'SampleTime', '4*Tb');
lignes(end+1, :) = {'C Bit code recu/1', 'Buffer7 alignement/1'}; lignes(end+1, :) = {'Buffer7 alignement/1', 'Buffer7 retards/1'};
lignes(end+1, :) = {'Buffer7 retards/1', 'Buffer7 bloc/1'};

% --- Decodeur de Hamming (portes, comme a la question 6)
add_block('simulink/Signal Routing/Demux', b('D Bits r'), 'Position', pos(560, y1 - 40, 8, 200), 'Outputs', '7');
porte('D s1', 'XOR', 4, 620, y1 - 60);  porte('D s2', 'XOR', 4, 620, y1);  porte('D s3', 'XOR', 4, 620, y1 + 60);
porte('D non s1', 'NOT', 1, 700, y1 + 130); porte('D non s2', 'NOT', 1, 700, y1 + 170); porte('D non s3', 'NOT', 1, 700, y1 + 210);
porte('D e1', 'AND', 3, 780, y1 - 60); porte('D e2', 'AND', 3, 780, y1);
porte('D e3', 'AND', 3, 780, y1 + 60); porte('D e4', 'AND', 3, 780, y1 + 120);
porte('D m1', 'XOR', 2, 860, y1 - 60); porte('D m2', 'XOR', 2, 860, y1);
porte('D m3', 'XOR', 2, 860, y1 + 60); porte('D m4', 'XOR', 2, 860, y1 + 120);
add_block('simulink/Signal Routing/Mux', b('D Message'), 'Position', pos(940, y1 - 50, 8, 200), 'Inputs', '4');
lignes(end+1, :) = {'Buffer7 bloc/1', 'D Bits r/1'};
S = {[1 3 4 5], [1 2 3 6], [2 3 4 7]};
for i = 1:3
    for k = 1:4, lignes(end+1, :) = {sprintf('D Bits r/%d', S{i}(k)), sprintf('D s%d/%d', i, k)}; end
    lignes(end+1, :) = {sprintf('D s%d/1', i), sprintf('D non s%d/1', i)};
end
E = {{'D s1', 'D s2', 'D non s3'}, {'D non s1', 'D s2', 'D s3'}, ...
     {'D s1', 'D s2', 'D s3'},     {'D s1', 'D non s2', 'D s3'}};
for j = 1:4
    for k = 1:3, lignes(end+1, :) = {[E{j}{k} '/1'], sprintf('D e%d/%d', j, k)}; end
    lignes(end+1, :) = {sprintf('D Bits r/%d', j), sprintf('D m%d/1', j)};
    lignes(end+1, :) = {sprintf('D e%d/1', j), sprintf('D m%d/2', j)};
    lignes(end+1, :) = {sprintf('D m%d/1', j), sprintf('D Message/%d', j)};
end

% --- Unbuffer 4 : les 4 bits decodes ressortent un par un au rythme Tb
add_block('simulink/Signal Attributes/Rate Transition', b('Unbuffer4 maintien'), ...
          'Position', pos(990, y1, 50, 40), 'OutPortSampleTime', 'Tb');
add_block('simulink/Sources/Repeating Sequence Stair', b('Unbuffer4 compteur'), ...
          'Position', pos(990, y1 + 70, 60, 30), 'OutValues', '1:4', 'tsamp', 'Tb');
add_block('simulink/Signal Routing/Selector', b('Unbuffer4 selection'), 'Position', pos(1080, y1 + 5, 50, 60), ...
          'NumberOfDimensions', '1', 'IndexMode', 'One-based', ...
          'IndexOptions', 'Index vector (port)', 'InputPortWidth', '4');
add_block('simulink/Sinks/To Workspace', b('Bits recus avec codage'), 'Position', pos(1170, y1 + 20, 80, 25), ...
          'VariableName', 'b_c', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');
lignes(end+1, :) = {'D Message/1', 'Unbuffer4 maintien/1'}; lignes(end+1, :) = {'Unbuffer4 maintien/1', 'Unbuffer4 selection/1'};
lignes(end+1, :) = {'Unbuffer4 compteur/1', 'Unbuffer4 selection/2'}; lignes(end+1, :) = {'Unbuffer4 selection/1', 'Bits recus avec codage/1'};

%% ======================= Connexions =======================
for i = 1:size(lignes, 1)
    add_line(mdl, lignes{i, 1}, lignes{i, 2}, 'autorouting', 'on');
end

%% ======================= Sous-systemes =======================
blocs = get_param(find_system(mdl, 'SearchDepth', 1, 'Type', 'Block'), 'Name');
grp = @(prefixe) blocs(startsWith(blocs, prefixe));
groupes = {'Source',              {'Uniforme', 'Bit', 'Bit double'};
           'Emetteur sans codage', {'NC Gain 2A', 'NC Bias -A', 'NC Passage a Te'};
           'Canal sans codage',    {'NC Bruit', 'NC Somme'};
           'Detecteur sans codage', {'NC Integrateur', 'NC Calage', 'NC Echantillonneur', 'NC Comparateur', 'NC Bit recu'};
           'Buffer 4',            grp('Buffer4');
           'Codeur Hamming',      grp('C Bits m');
           'Unbuffer 7',          grp('Unbuffer7');
           'Emetteur code',       {'C Gain 2Ac', 'C Bias -Ac', 'C Passage a Te'};
           'Canal code',          {'C Bruit', 'C Somme'};
           'Detecteur code',      {'C Integrateur', 'C Calage', 'C Echantillonneur', 'C Comparateur', 'C Bit code recu'};
           'Buffer 7',            grp('Buffer7');
           'Decodeur Hamming',    grp('D ');
           'Unbuffer 4',          grp('Unbuffer4')};
groupes{6, 2} = [grp('C Bits m'); grp('C r'); grp('C Mot code')];
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