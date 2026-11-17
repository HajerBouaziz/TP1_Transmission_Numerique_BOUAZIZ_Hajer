% =========================================================================
% QUESTION 3 : Analyse statistique et figure pour texte_fr.txt
% =========================================================================

clear; clc; close all;

% 1. Lecture du fichier texte
filename = 'texte_fr.txt'; % Utilisation du fichier fourni
fid = fopen(filename, 'r', 'native', 'UTF-8');

if fid == -1
    error('Fichier "%s" introuvable dans le dossier courant.', filename);
end

texte = fread(fid, '*char')';
fclose(fid);

N_char = length(texte);

% 2. Extraction des symboles et probabilités
[symboles, ~, idx] = unique(texte);
counts = accumarray(idx, 1);
p = counts / N_char;
K = length(symboles);

% 3. Entropie empirique H, codage fixe et redondance
H_emp = -sum(p .* log2(p));
L_fixe = ceil(log2(K));
R_8bits = 8 - H_emp;

% 4. Affichage des résultats dans la console
fprintf('=== ANALYSE DE TEXTE_FR.TXT ===\n');
fprintf('Nombre total de caractères (N) : %d\n', N_char);
fprintf('Taille de l''alphabet (K)       : %d symboles\n', K);
fprintf('Entropie empirique H          : %.4f bits/symbole\n', H_emp);
fprintf('Code à longueur fixe          : %d bits/symbole\n', L_fixe);
fprintf('Redondance (vs 8 bits)        : %.4f bits/symbole\n\n', R_8bits);

% =========================================================================
% TRACÉ DE LA FIGURE (Histogramme des 15 caractères les plus fréquents)
% =========================================================================

% Tri des probabilités par ordre décroissant
[p_sorted, sort_idx] = sort(p, 'descend');
top_n = min(15, K);

% Titre personnalisé de la fenêtre graphique
figure('Name', 'Figure 1 : Analyse des fréquences des caractères (Question 3)', ...
       'NumberTitle', 'off', 'Color', 'w');

% Graphique en barres
bar(1:top_n, p_sorted(1:top_n), 0.6, 'FaceColor', [0.15 0.45 0.75], 'EdgeColor', 'none');
grid on;
set(gca, 'GridLineStyle', ':', 'GridAlpha', 0.5);

% Conversion correcte des symboles en cell array individuel
top_symb = symboles(sort_idx(1:top_n));
labels = num2cell(top_symb);

for i = 1:top_n
    if strcmp(labels{i}, ' ')
        labels{i} = '[Espace]';
    elseif strcmp(labels{i}, sprintf('\n')) || strcmp(labels{i}, sprintf('\r'))
        labels{i} = '[Retour]';
    end
end

set(gca, 'XTick', 1:top_n, 'XTickLabel', labels, 'FontSize', 10, 'FontWeight', 'bold');
xtickangle(45);

% Titre principal affiché au-dessus du graphique
title('Figure 1 — Fréquence relative des 15 caractères les plus fréquents (texte\_fr.txt)', ...
      'FontSize', 12, 'FontWeight', 'bold');
xlabel('Symboles / Caractères', 'FontSize', 11);
ylabel('Probabilité d''apparition p_i', 'FontSize', 11);

ylim([0 max(p_sorted) * 1.15]);
