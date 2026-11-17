clear; clc; close all;

% 1. Chargement des paramètres personnels (p1 = 0,38 et Tb = 1 pour 'BOUAZIZ Hajer')
parametres;
rng(P.graine);              % graine fixee : resultats reproductibles

% 2. Génération de N = 10^5 bits
N = 1e5;
bits = source(N, p1);

% 3. Fréquence empirique des 1
p1_empirique = sum(bits) / N;

fprintf('====================================================\n');
fprintf('  PARTIE 2.1 : SOURCE BINAIRE ET ENTROPIE\n');
fprintf('====================================================\n');
fprintf('Nombre de bits générés N = %d\n', N);
fprintf('Probabilité théorique p1 = %.4f\n', p1);
fprintf('Fréquence empirique  p1  = %.4f\n', p1_empirique);
fprintf('Écart (erreur)          = %.4f\n\n', abs(p1 - p1_empirique));

% 4. Calcul de l'entropie
p0 = 1 - p1;
H_p1 = -p1 * log2(p1) - p0 * log2(p0); % bits/symbole

% 5. Débit d'information (pour Tb = 1 s, soit D = 1 symbole/s)
D = 1 / Tb;       % Débit de symboles (symbole/s)
R_I = D * H_p1;   % Débit d'information (bit/s)

fprintf('Entropie de la source H(p1)     = %.4f bits/symbole\n', H_p1);
fprintf('Débit d''information R_I (à 1 bit/s) = %.4f bit/s\n', R_I);
fprintf('====================================================\n');

% 6. Tracé de la courbe H(p) pour p dans [0, 1]
p_vec = linspace(1e-6, 1 - 1e-6, 500); % Évite log2(0)
H_vec = -p_vec .* log2(p_vec) - (1 - p_vec) .* log2(1 - p_vec);

figure('Name', 'Partie 2.1 - Entropie de la source');
plot(p_vec, H_vec, 'b-', 'LineWidth', 2); hold on;
plot(p1, H_p1, 'ro', 'MarkerSize', 8, 'LineWidth', 2, 'MarkerFaceColor', 'r');
grid on;
xlabel('Probabilité p_1');
ylabel('Entropie H(p) (bits/symbole)');
title('Entropie d''une source binaire sans mémoire');
legend('H(p)', sprintf('Votre source (p_1 = %.2f, H = %.4f)', p1, H_p1), 'Location', 'South');