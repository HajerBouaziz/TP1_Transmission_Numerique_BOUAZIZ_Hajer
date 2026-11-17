%% Partie 3 - Question 3 : capacite du canal binaire symetrique
clear; close all; clc;
P  = mes_parametres('BOUAZIZ Hajer');
pe = P.pe_cbs;
R  = 4/7;                                   % rendement du code de Hamming

hb = @(p) -p.*log2(p) - (1-p).*log2(1-p);   % entropie binaire (0 < p < 1)
C  = 1 - hb(pe);
fprintf('pe = %.3f : H(pe) = %.4f, C = %.4f bit/bit emis\n', pe, hb(pe), C);
fprintf('R = 4/7 = %.4f -> R - C = %+.4f\n', R, R - C);

pe_lim = fzero(@(p) 1 - hb(p) - R, [0.01 0.4]);   % pe tel que C = R
fprintf('C = R pour pe = %.4f\n', pe_lim);

% Trace de C(pe)
pp = linspace(1e-6, 1 - 1e-6, 1001);
figure('Name', 'Capacite du CBS');
plot(pp, 1 - hb(pp), 'LineWidth', 1.5); hold on;
yline(R, 'r--', 'R = 4/7', 'LineWidth', 1.2);
plot(pe, C, 'ko', 'MarkerFaceColor', 'k');
xline(0.5, 'k:', 'p_e = 0,5');
grid on; xlabel('p_e'); ylabel('C (bit par bit emis)');
title('Capacite du canal binaire symetrique : C(p_e) = 1 - H(p_e)');
legend('C(p_e)', 'Rendement du code de Hamming', ...
       sprintf('Mon canal : p_e = %.3f, C = %.4f', pe, C), 'Location', 'north');

% Zoom autour de mon canal
figure('Name', 'Zoom');
pz = linspace(0.06, 0.12, 401);
plot(pz, 1 - hb(pz), 'LineWidth', 1.5); hold on;
yline(R, 'r--', 'R = 4/7', 'LineWidth', 1.2);
plot(pe, C, 'ko', 'MarkerFaceColor', 'k');
xline(pe_lim, 'k:', sprintf('p_e = %.4f', pe_lim));
grid on; xlabel('p_e'); ylabel('C (bit par bit emis)');
title('Zoom : capacite au voisinage de R = 4/7');
legend('C(p_e)', 'R = 4/7', 'Mon canal', 'Location', 'northeast');