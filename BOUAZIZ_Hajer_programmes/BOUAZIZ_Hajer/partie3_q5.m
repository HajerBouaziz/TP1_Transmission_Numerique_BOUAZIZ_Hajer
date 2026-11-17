%% Partie 3 - Question 5 : probabilite d'erreur Pe(s), canal a bruit uniforme
clear; close all; clc;
P  = mes_parametres('BOUAZIZ Hajer');
A  = P.A;  a = P.a_unif;  p1 = P.p1;  p0 = 1 - p1;

clip  = @(x) min(max(x, 0), 1);                       % borne entre 0 et 1
Pe0   = @(s) clip((a - A - s) / (2*a));               % P(erreur | 0)
Pe1   = @(s) clip((s - A + a) / (2*a));               % P(erreur | 1)
Pe    = @(s) p0 * Pe0(s) + p1 * Pe1(s);

s_opt = a - A;                                        % seuil optimal (p1 < p0)
fprintf('Pe(0)  = %.4f\n', Pe(0));
fprintf('Pe(s*) = %.4f  (s* = %.2f)\n', Pe(s_opt), s_opt);
fprintf('Reduction des erreurs : %.1f %%\n', 100 * (1 - Pe(s_opt) / Pe(0)));

s = linspace(-A - a - 0.5, A + a + 0.5, 2001);
figure('Name', 'Pe(s) - bruit uniforme');
plot(s, Pe(s), 'LineWidth', 1.5); hold on;
plot(s, p0 * Pe0(s), '--', s, p1 * Pe1(s), '--');
xline(s_opt, 'k--', sprintf('s* = %.2f', s_opt));
xline(0, 'r:', 's = 0');
plot(s_opt, Pe(s_opt), 'ko', 'MarkerFaceColor', 'k');
grid on; xlabel('Seuil s'); ylabel('Probabilite d''erreur');
title(sprintf('Canal a bruit uniforme : P_e(s) (a = %.2f, A = %g, p_1 = %.2f)', a, A, p1));
legend('P_e(s)', 'p_0 P(erreur|0)', 'p_1 P(erreur|1)', 'Location', 'north');