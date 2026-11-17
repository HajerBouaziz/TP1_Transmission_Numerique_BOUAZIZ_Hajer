%% Construction du decodeur de Hamming C(7,4) sous Simulink (question 6)
% Decodeur combinatoire, uniquement avec des portes logiques :
%   1) syndrome  : s1 = r1+r3+r4+r5, s2 = r1+r2+r3+r6, s3 = r2+r3+r4+r7 (XOR) ;
%   2) erreur    : e_j = 1 si (s1 s2 s3) = colonne j de H (AND, NOT) ;
%   3) correction: m_j = r_j XOR e_j, j = 1..4 ;
%   4) detection : erreur detectee = s1 OR s2 OR s3.
% Entree : un mot recu de 7 bits par periode (vecteur), sortie : 4 bits decodes.
mdl = 'decodeur_hamming_slx';
if bdIsLoaded(mdl), close_system(mdl, 0); end
if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
new_system(mdl);
open_system(mdl);
set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
          'FixedStep', '1', 'StopTime', 'Tstop', 'BooleanDataType', 'off');

b   = @(nom) [mdl '/' nom];
pos = @(x, y, w, h) [x, y, x + w, y + h];
porte = @(nom, op, n, x, y) add_block('simulink/Logic and Bit Operations/Logical Operator', ...
          b(nom), 'Position', pos(x, y, 50, 20 + 12*n), 'Operator', op, 'Inputs', num2str(n));

%% Entree : mot recu (7 bits) et separation des bits
add_block('simulink/Sources/From Workspace', b('Mot recu'), 'Position', pos(20, 230, 80, 30), ...
          'VariableName', 'recu', 'SampleTime', '1', 'Interpolate', 'off', ...
          'OutputAfterFinalValue', 'Setting to zero');
add_block('simulink/Signal Routing/Demux', b('Bits r'), 'Position', pos(140, 100, 10, 300), ...
          'Outputs', '7');

%% 1) Syndrome (lignes de H)
porte('s1', 'XOR', 4, 260, 40);
porte('s2', 'XOR', 4, 260, 130);
porte('s3', 'XOR', 4, 260, 220);
%% NOT des bits du syndrome
porte('non s1', 'NOT', 1, 380, 300);
porte('non s2', 'NOT', 1, 380, 350);
porte('non s3', 'NOT', 1, 380, 400);
%% 2) Localisation de l'erreur (colonnes 1 a 4 de H : 110, 011, 111, 101)
porte('e1', 'AND', 3, 500, 40);
porte('e2', 'AND', 3, 500, 120);
porte('e3', 'AND', 3, 500, 200);
porte('e4', 'AND', 3, 500, 280);
%% 3) Correction des bits du message
porte('m1', 'XOR', 2, 640, 40);
porte('m2', 'XOR', 2, 640, 120);
porte('m3', 'XOR', 2, 640, 200);
porte('m4', 'XOR', 2, 640, 280);
%% 4) Detection
porte('Detection', 'OR', 3, 500, 420);

%% Sorties
add_block('simulink/Signal Routing/Mux', b('Mux m'), 'Position', pos(760, 60, 10, 260), 'Inputs', '4');
add_block('simulink/Sinks/To Workspace', b('Message decode'), 'Position', pos(820, 175, 90, 30), ...
          'VariableName', 'm_dec', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');
add_block('simulink/Signal Routing/Mux', b('Mux s'), 'Position', pos(380, 470, 10, 90), 'Inputs', '3');
add_block('simulink/Sinks/To Workspace', b('Syndrome'), 'Position', pos(440, 500, 90, 30), ...
          'VariableName', 'synd', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');
add_block('simulink/Sinks/To Workspace', b('Erreur detectee'), 'Position', pos(620, 425, 90, 30), ...
          'VariableName', 'detect', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');

%% Connexions
L = {'Mot recu/1', 'Bits r/1';
     % syndrome
     'Bits r/1', 's1/1'; 'Bits r/3', 's1/2'; 'Bits r/4', 's1/3'; 'Bits r/5', 's1/4';
     'Bits r/1', 's2/1'; 'Bits r/2', 's2/2'; 'Bits r/3', 's2/3'; 'Bits r/6', 's2/4';
     'Bits r/2', 's3/1'; 'Bits r/3', 's3/2'; 'Bits r/4', 's3/3'; 'Bits r/7', 's3/4';
     's1/1', 'non s1/1'; 's2/1', 'non s2/1'; 's3/1', 'non s3/1';
     % localisation
     's1/1', 'e1/1';     's2/1', 'e1/2';     'non s3/1', 'e1/3';
     'non s1/1', 'e2/1'; 's2/1', 'e2/2';     's3/1', 'e2/3';
     's1/1', 'e3/1';     's2/1', 'e3/2';     's3/1', 'e3/3';
     's1/1', 'e4/1';     'non s2/1', 'e4/2'; 's3/1', 'e4/3';
     % correction
     'Bits r/1', 'm1/1'; 'e1/1', 'm1/2';
     'Bits r/2', 'm2/1'; 'e2/1', 'm2/2';
     'Bits r/3', 'm3/1'; 'e3/1', 'm3/2';
     'Bits r/4', 'm4/1'; 'e4/1', 'm4/2';
     % detection et sorties
     's1/1', 'Detection/1'; 's2/1', 'Detection/2'; 's3/1', 'Detection/3';
     'Detection/1', 'Erreur detectee/1';
     'm1/1', 'Mux m/1'; 'm2/1', 'Mux m/2'; 'm3/1', 'Mux m/3'; 'm4/1', 'Mux m/4';
     'Mux m/1', 'Message decode/1';
     's1/1', 'Mux s/1'; 's2/1', 'Mux s/2'; 's3/1', 'Mux s/3'; 'Mux s/1', 'Syndrome/1'};
for i = 1:size(L, 1)
    add_line(mdl, L{i, 1}, L{i, 2}, 'autorouting', 'on');
end

save_system(mdl);
fprintf('Modele %s.slx cree dans %s\n', mdl, pwd);