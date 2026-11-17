%% Partie 3 - Question 4 : canal a bruit uniforme, densites et seuil optimal
clear; close all; clc;
P  = mes_parametres('BOUAZIZ Hajer');
A  = P.A;  a = P.a_unif;  p1 = P.p1;  p0 = 1 - p1;
fprintf('A = %g, a = %.2f, p1 = %.2f, p0 = %.2f\n', A, a, p1, p0);

r  = linspace(-A - a - 0.5, A + a + 0.5, 2001);
f0 = (abs(r + A) <= a) / (2*a);          % f(r|0)
f1 = (abs(r - A) <= a) / (2*a);          % f(r|1)

% Seuil optimal (critere MAP : decider 1 si p1 f(r|1) > p0 f(r|0))
if a <= A
    s_opt = 0;
    fprintf('a <= A : supports disjoints, aucune erreur pour s dans [%.2f ; %.2f]\n', a-A, A-a);
else
    fprintf('a > A : recouvrement [A-a ; a-A] = [%.2f ; %.2f]\n', A-a, a-A);
    if p1 < p0
        s_opt = a - A;
    elseif p1 > p0
        s_opt = A - a;
    else
        s_opt = 0;
    end
    fprintf('Seuil optimal s* = %.2f\n', s_opt);
end

figure('Name', 'Densites - bruit uniforme');
subplot(2,1,1);
plot(r, f0, 'LineWidth', 1.5); hold on; plot(r, f1, 'LineWidth', 1.5);
if a > A
    patch([A-a a-A a-A A-a], [0 0 1/(2*a) 1/(2*a)], [0.85 0.85 0.85], ...
          'EdgeColor', 'none', 'FaceAlpha', 0.6);
end
grid on; ylabel('densite'); ylim([0, 1.3/(2*a)]);
legend('f(r|0)', 'f(r|1)', 'Recouvrement', 'Location', 'northeast');
title(sprintf('Vraisemblances, bruit uniforme sur [-a, a] (a = %.2f, A = %g)', a, A));

subplot(2,1,2);
plot(r, p0*f0, 'LineWidth', 1.5); hold on; plot(r, p1*f1, 'LineWidth', 1.5);
xline(s_opt, 'k--', sprintf('s* = %.2f', s_opt), 'LineWidth', 1.2);
grid on; xlabel('r'); ylabel('densite ponderee'); ylim([0, 1.3/(2*a)]);
legend(sprintf('p_0 f(r|0), p_0 = %.2f', p0), sprintf('p_1 f(r|1), p_1 = %.2f', p1), ...
       'Seuil optimal', 'Location', 'northeast');
title('Critere MAP : decider 1 la ou p_1 f(r|1) > p_0 f(r|0)');