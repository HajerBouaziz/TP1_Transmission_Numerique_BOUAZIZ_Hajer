%% Partie 4 - Question 5 : codeur a registre a decalage sous Simulink
% 1) table des etats du registre pour m = [1 0 1 1] ;
% 2) comparaison avec le codeur matriciel (codeur_hamming) pour les 16 messages.
% Le circuit emet chaque mot en serie : m3 m2 m1 m0 r2 r1 r0.
clear; clc;
mdl = 'codeur_registre';
if ~exist([mdl '.slx'], 'file'), construire_codeur_registre; end
if ~bdIsLoaded(mdl), load_system(mdl); end

%% 1) Table des etats pour m = [m0 m1 m2 m3] = [1 0 1 1]
m = [1 0 1 1];
bits  = [fliplr(m), 0 0 0];                 % entree : m3 m2 m1 m0 puis 3 coups de vidage
entree = [(0:6)', bits'];                    % [temps, valeur]
Tstop = 6;
out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
E = out.etats;  f = out.f_log;  cs = out.c_serie(:)';

fprintf('Table des etats du registre pour m = [%d %d %d %d]\n', m);
fprintf('%6s %8s %4s %4s | %4s %4s %4s | %8s\n', 'Coup', 'Entree', 'K', 'f', 's0', 's1', 's2', 'Sortie');
fprintf('%6d %8s %4s %4s | %4d %4d %4d |\n', 0, '-', '-', '-', 0, 0, 0);
K = [1 1 1 1 0 0 0];
for t = 1:7
    % etat apres le coup t = sortie des Unit Delay a l'instant t (ligne t+1)
    if t < 7, et = E(t + 1, :); else, et = [NaN NaN NaN]; end
    fprintf('%6d %8d %4d %4d | %4g %4g %4g | %8d\n', t, bits(t), K(t), f(t), et, cs(t));
end
r = E(5, :);                                 % etat apres 4 coups = (r0, r1, r2)
fprintf('Apres 4 coups : (r0, r1, r2) = (%d, %d, %d)\n', r);
fprintf('Mot emis en serie : %s  ->  c = [m0 m1 m2 m3 | r0 r1 r2] = %s\n', ...
        num2str(cs, '%d'), num2str(serie_vers_mot(cs), '%d'));
fprintf('Codeur matriciel   : c = %s\n\n', num2str(codeur_hamming(m), '%d'));

%% 2) Les 16 messages a la suite
M = dec2bin(0:15, 4) - '0';                  % [m0 m1 m2 m3] sur chaque ligne
bits = [];
for i = 1:16
    bits = [bits, fliplr(M(i, :)), 0 0 0];   %#ok<AGROW>
end
n = numel(bits);
entree = [(0:n-1)', bits'];
Tstop = n - 1;
out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
cs = out.c_serie(:)';

ok = 0;
fprintf('%8s %12s %12s %6s\n', 'Message', 'Registre', 'Matriciel', 'Egal');
for i = 1:16
    c_reg = serie_vers_mot(cs(7*(i-1) + (1:7)));
    c_mat = codeur_hamming(M(i, :));
    egal  = isequal(c_reg, c_mat);
    ok    = ok + egal;
    fprintf('%8s %12s %12s %6s\n', num2str(M(i, :), '%d'), num2str(c_reg, '%d'), ...
            num2str(c_mat, '%d'), ternaire(egal, 'oui', 'NON'));
end
fprintf('\n%d mots-codes sur 16 identiques au codeur matriciel\n', ok);

%% ======================= Fonctions locales =======================
function c = serie_vers_mot(s)
% Remet le mot emis en serie (m3 m2 m1 m0 r2 r1 r0) dans l'ordre de l'enonce
% c = [m0 m1 m2 m3 | r0 r1 r2].
    c = [s(4) s(3) s(2) s(1) s(7) s(6) s(5)];
end

function s = ternaire(c, a, b)
    if c, s = a; else, s = b; end
end