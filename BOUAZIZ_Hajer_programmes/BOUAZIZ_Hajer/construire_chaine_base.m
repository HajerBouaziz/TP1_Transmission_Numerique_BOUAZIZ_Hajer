%% Construction automatique du modele Simulink chaine_base.slx (question 10)
% Emetteur a L echantillons par bit + canal gaussien + detecteur optimal
% (integrateur a remise a zero, echantillonneur, comparateur a seuil).
%
%  Source (Tb) -> Emetteur (Tb -> Te, niveaux +/-A) -> Canal (+ bruit, Te)
%       -> Detecteur (integration sur un bit, echantillonnage a Tb)
%       -> Decision (comparaison au seuil) -> bits recus
%
% A lancer une seule fois (le modele est enregistre dans le dossier courant).
clear; clc;
parametres_chaine;               % definit Tb, Te, L, A, sigma2, ...

mdl = 'chaine_base';
if bdIsLoaded(mdl), close_system(mdl, 0); end
if exist([mdl '.slx'], 'file'), delete([mdl '.slx']); end
new_system(mdl);
open_system(mdl);

% Solveur discret a pas fixe, pas fondamental Te
set_param(mdl, 'SolverType', 'Fixed-step', 'Solver', 'FixedStepDiscrete', ...
          'FixedStep', 'Te', 'StopTime', 'Tsim', 'EnableMultiTasking', 'off');

b = @(nom) [mdl '/' nom];
pos = @(x, y) [x, y, x + 90, y + 40];

%% ---------- Source binaire, cadencee a Tb ----------
add_block('simulink/Sources/Uniform Random Number', b('Uniforme'), 'Position', pos(30, 50), ...
          'Minimum', '0', 'Maximum', '1', 'Seed', 'graine', 'SampleTime', 'Tb');
add_block('simulink/Logic and Bit Operations/Compare To Constant', b('Bit'), ...
          'Position', pos(160, 50), 'relop', '<', 'const', 'p1');
add_block('simulink/Signal Attributes/Data Type Conversion', b('Bit double'), ...
          'Position', pos(290, 50), 'OutDataTypeStr', 'double');
add_block('simulink/Sinks/To Workspace', b('Bits emis'), 'Position', pos(420, 120), ...
          'VariableName', 'b_emis', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');

%% ---------- Emetteur : niveaux +/-A et passage a L echantillons par bit ----------
add_block('simulink/Math Operations/Gain', b('Gain 2A'), 'Position', pos(420, 50), 'Gain', '2*A');
add_block('simulink/Math Operations/Bias', b('Bias -A'), 'Position', pos(550, 50), 'Bias', '-A');
add_block('simulink/Signal Attributes/Rate Transition', b('Passage a Te'), ...
          'Position', pos(680, 50), 'OutPortSampleTime', 'Te');

%% ---------- Canal : bruit blanc gaussien additif, variance sigma2 par echantillon ----------
add_block('simulink/Sources/Random Number', b('Bruit'), 'Position', pos(680, 140), ...
          'Mean', '0', 'Variance', 'sigma2', 'Seed', 'graine + 1', 'SampleTime', 'Te');
add_block('simulink/Math Operations/Sum', b('Somme'), 'Position', [820 55 850 85], 'Inputs', '++');

%% ---------- Detecteur optimal ----------
% Integrateur a remise a zero : z_k = (1/L) * somme des L echantillons du bit k,
% realise par une moyenne glissante sur L echantillons...
add_block('simulink/Discrete/Discrete FIR Filter', b('Integrateur'), 'Position', pos(900, 50), ...
          'Coefficients', 'ones(1, L) / L', 'SampleTime', 'Te');
% ... calage de l'instant d'echantillonnage sur la fin du bit ...
add_block('simulink/Discrete/Delay', b('Calage'), 'Position', pos(1030, 50), ...
          'DelayLength', 'd_ech');
% ... echantillonneur a t = (k+1) Tb (retour au rythme Tb)
add_block('simulink/Discrete/Zero-Order Hold', b('Echantillonneur'), 'Position', pos(1160, 50), ...
          'SampleTime', 'Tb');
add_block('simulink/Sinks/To Workspace', b('Sortie z'), 'Position', pos(1290, 140), ...
          'VariableName', 'z', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');

%% ---------- Decision : comparateur a seuil ----------
add_block('simulink/Logic and Bit Operations/Compare To Constant', b('Comparateur'), ...
          'Position', pos(1290, 50), 'relop', '>', 'const', 'seuil');
add_block('simulink/Signal Attributes/Data Type Conversion', b('Bit recu'), ...
          'Position', pos(1420, 50), 'OutDataTypeStr', 'double');
add_block('simulink/Sinks/To Workspace', b('Bits recus'), 'Position', pos(1550, 50), ...
          'VariableName', 'b_recu', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');

%% ---------- Branche sans integration (question 12) ----------
% Un seul echantillon preleve au milieu de chaque bit, puis decision.
add_block('simulink/Discrete/Delay', b('Calage milieu'), 'Position', pos(900, 260), ...
          'DelayLength', 'd_ech + L/2 - 1');
add_block('simulink/Discrete/Zero-Order Hold', b('Echantillonneur milieu'), ...
          'Position', pos(1030, 260), 'SampleTime', 'Tb');
add_block('simulink/Logic and Bit Operations/Compare To Constant', b('Comparateur milieu'), ...
          'Position', pos(1160, 260), 'relop', '>', 'const', 'seuil');
add_block('simulink/Signal Attributes/Data Type Conversion', b('Bit recu milieu'), ...
          'Position', pos(1290, 260), 'OutDataTypeStr', 'double');
add_block('simulink/Sinks/To Workspace', b('Bits recus milieu'), 'Position', pos(1420, 260), ...
          'VariableName', 'b_recu_mil', 'SaveFormat', 'Array', 'MaxDataPoints', 'inf');

%% ---------- Connexions ----------
lignes = {'Uniforme/1', 'Bit/1';  'Bit/1', 'Bit double/1';  'Bit double/1', 'Bits emis/1';
          'Bit double/1', 'Gain 2A/1';  'Gain 2A/1', 'Bias -A/1';  'Bias -A/1', 'Passage a Te/1';
          'Passage a Te/1', 'Somme/1';  'Bruit/1', 'Somme/2';  'Somme/1', 'Integrateur/1';
          'Integrateur/1', 'Calage/1';  'Calage/1', 'Echantillonneur/1';
          'Echantillonneur/1', 'Sortie z/1';  'Echantillonneur/1', 'Comparateur/1';
          'Comparateur/1', 'Bit recu/1';  'Bit recu/1', 'Bits recus/1';
          'Somme/1', 'Calage milieu/1';  'Calage milieu/1', 'Echantillonneur milieu/1';
          'Echantillonneur milieu/1', 'Comparateur milieu/1';
          'Comparateur milieu/1', 'Bit recu milieu/1';  'Bit recu milieu/1', 'Bits recus milieu/1'};
for i = 1:size(lignes, 1)
    add_line(mdl, lignes{i, 1}, lignes{i, 2}, 'autorouting', 'on');
end

%% ---------- Regroupement en sous-systemes (structure modulaire) ----------
groupes = {'Source',     {'Uniforme', 'Bit', 'Bit double'};
           'Emetteur',   {'Gain 2A', 'Bias -A', 'Passage a Te'};
           'Canal',      {'Bruit', 'Somme'};
           'Detecteur',  {'Integrateur', 'Calage', 'Echantillonneur'};
           'Decision',   {'Comparateur', 'Bit recu'};
           'Sans integration', {'Calage milieu', 'Echantillonneur milieu', ...
                                'Comparateur milieu', 'Bit recu milieu'}};
for i = 1:size(groupes, 1)
    h = cellfun(@(n) get_param(b(n), 'Handle'), groupes{i, 2});
    try
        Simulink.BlockDiagram.createSubsystem(h, 'Name', groupes{i, 1});
    catch
        % versions anciennes : sous-systeme cree avec un nom par defaut
        try, Simulink.BlockDiagram.createSubsystem(h); catch, end
    end
end

save_system(mdl);
fprintf('Modele %s.slx cree dans %s\n', mdl, pwd);