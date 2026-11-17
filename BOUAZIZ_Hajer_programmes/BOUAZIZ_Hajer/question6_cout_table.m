% =========================================================================
% QUESTION 6 : Evaluation du cout de la table de codage
% =========================================================================

clear; clc; close all;

% Parametres de texte_fr.txt
N_real = 4488;
K = 64;
L_moy = 4.3790;

% 1. Calcul des couts de la table (en bits)
C_explicite = 8 + K*12 + (L_moy * K); % Symbole (8b) + L_i (4b) + Code (L_i b)
C_canonique = 8 + K*8 + K*4;          % Symbole (8b) + L_i (4b)

% 2. Seuils critiques (Format canonique)
N_min = C_canonique / (8 - L_moy);
N_negli = (99 * C_canonique) / L_moy;

% Pour notre texte réel (N = 4488)
ratio_table_real = (C_canonique / (C_canonique + N_real * L_moy)) * 100;
taux_reell_comp = (1 - (C_canonique + N_real * L_moy) / (N_real * 8)) * 100;

% Affichage console
fprintf('=== RESULTATS QUESTION 6 : COUT DE LA TABLE ===\n');
fprintf('Cout table (Format Explicite) : %d bits (%.1f octets)\n', round(C_explicite), C_explicite/8);
fprintf('Cout table (Format Canonique) : %d bits (%d octets)\n\n', C_canonique, C_canonique/8);

fprintf('=== SEUILS CRITIQUES (Table canonique) ===\n');
fprintf('Texte minimum pour gain (N_min)   : %d caracteres\n', ceil(N_min));
fprintf('Texte pour cout negligable (<1%%)  : %d caracteres\n', ceil(N_negli));
fprintf('Part de la table pour texte_fr.txt: %.2f %%\n', ratio_table_real);
fprintf('Taux de compression net (vs 8b)  : %.2f %%\n\n', taux_reell_comp);

% 3. Trace de la courbe d'impact du cout de la table
N_vec = 100:50:25000;
ratio_table = (C_canonique ./ (C_canonique + N_vec .* L_moy)) * 100;

figure('Name', 'Question 6 : Impact du cout de la table', 'Color', 'w');
plot(N_vec, ratio_table, 'LineWidth', 2, 'Color', [0.85 0.33 0.1]);
grid on;
hold on;

% Lignes repères
yline(1, '--r', 'Seuil 1% (Négligeable)', 'LineWidth', 1.5, 'LabelVerticalAlignment', 'bottom');
xline(N_real, ':b', sprintf('texte\\_fr.txt (N=%d)', N_real), 'LineWidth', 1.5);

title('Proportion du coût de la table dans le message compressé', 'FontSize', 12);
xlabel('Longueur du texte N (nombre de caractères)', 'FontSize', 11);
ylabel('Part de la table (%)', 'FontSize', 11);
ylim([0 15]);