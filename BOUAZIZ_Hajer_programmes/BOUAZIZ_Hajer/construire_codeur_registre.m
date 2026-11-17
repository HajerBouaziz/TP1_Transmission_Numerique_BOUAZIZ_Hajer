%% Construction du codeur de Hamming C(7,4) a registre a decalage (question 5)
% Blocs utilises : Unit Delay (bascules D), Logical Operator (XOR, AND), Switch.
% Aucun produit matriciel ni division de polynomes.
%
% Une periode d'horloge = un bit. Pour chaque mot de 7 coups d'horloge :
%   coups 1 a 4 (K = 1) : les bits du message entrent (m3, m2, m1, m0) et sortent
%                         directement ; le registre calcule le reste ;
%   coups 5 a 7 (K = 0) : la retroaction est coupee, le registre se vide par s2
%                         et la sortie emet r2, r1, r0.
% Le registre est vide a la fin de chaque mot (pas besoin de remise a zero).
mdl = 'codeur_registre';
if bdIsLoaded(mdl), close_system(mdl, 0); end
if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
new_system(mdl);
open_system(mdl);
set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
          'FixedStep', '1', 'StopTime', 'Tstop', ...
          'BooleanDataType', 'off');     % les portes logiques sortent des doubles

b   = @(nom) [mdl '/' nom];
pos = @(x, y, w, h) [x, y, x + w, y + h];

%% Entrees : bits du message et commande K
add_block('simulink/Sources/From Workspace', b('Message'), 'Position', pos(30, 100, 90, 30), ...
          'VariableName', 'entree', 'SampleTime', '1', 'Interpolate', 'off', ...
          'OutputAfterFinalValue', 'Setting to zero');
add_block('simulink/Sources/Repeating Sequence Stair', b('Commande K'), ...
          'Position', pos(30, 260, 90, 30), 'OutValues', '[1 1 1 1 0 0 0]', 'tsamp', '1');

%% Retroaction : f = (m XOR s2) AND K
add_block('simulink/Logic and Bit Operations/Logical Operator', b('XOR f'), ...
          'Position', pos(200, 95, 50, 40), 'Operator', 'XOR', 'Inputs', '2');
add_block('simulink/Logic and Bit Operations/Logical Operator', b('AND K'), ...
          'Position', pos(300, 100, 50, 40), 'Operator', 'AND', 'Inputs', '2');

%% Registre : bascules D (Unit Delay) et XOR en entree de s1
add_block('simulink/Discrete/Unit Delay', b('s0'), 'Position', pos(420, 100, 50, 40), ...
          'InitialCondition', '0');
add_block('simulink/Logic and Bit Operations/Logical Operator', b('XOR s1'), ...
          'Position', pos(520, 100, 50, 40), 'Operator', 'XOR', 'Inputs', '2');
add_block('simulink/Discrete/Unit Delay', b('s1'), 'Position', pos(620, 100, 50, 40), ...
          'InitialCondition', '0');
add_block('simulink/Discrete/Unit Delay', b('s2'), 'Position', pos(720, 100, 50, 40), ...
          'InitialCondition', '0');

%% Interrupteur message / redondance
add_block('simulink/Signal Routing/Switch', b('Interrupteur'), 'Position', pos(860, 180, 50, 70), ...
          'Criteria', 'u2 > Threshold', 'Threshold', '0.5');

%% Sorties vers le Workspace
add_block('simulink/Sinks/To Workspace', b('Mot code serie'), 'Position', pos(980, 200, 90, 30), ...
          'VariableName', 'c_serie', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');
add_block('simulink/Signal Routing/Mux', b('Mux etats'), 'Position', pos(860, 20, 10, 60), ...
          'Inputs', '3');
add_block('simulink/Sinks/To Workspace', b('Etats'), 'Position', pos(980, 35, 90, 30), ...
          'VariableName', 'etats', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');
add_block('simulink/Sinks/To Workspace', b('Retroaction f'), 'Position', pos(420, 200, 90, 30), ...
          'VariableName', 'f_log', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');

%% Connexions
lignes = {'Message/1', 'XOR f/1';   's2/1', 'XOR f/2';
          'XOR f/1', 'AND K/1';     'Commande K/1', 'AND K/2';
          'AND K/1', 's0/1';        's0/1', 'XOR s1/1';   'AND K/1', 'XOR s1/2';
          'XOR s1/1', 's1/1';       's1/1', 's2/1';
          'Message/1', 'Interrupteur/1';  'Commande K/1', 'Interrupteur/2';
          's2/1', 'Interrupteur/3';       'Interrupteur/1', 'Mot code serie/1';
          's0/1', 'Mux etats/1';    's1/1', 'Mux etats/2';  's2/1', 'Mux etats/3';
          'Mux etats/1', 'Etats/1'; 'AND K/1', 'Retroaction f/1'};
for i = 1:size(lignes, 1)
    add_line(mdl, lignes{i, 1}, lignes{i, 2}, 'autorouting', 'on');
end

save_system(mdl);
fprintf('Modele %s.slx cree dans %s\n', mdl, pwd);