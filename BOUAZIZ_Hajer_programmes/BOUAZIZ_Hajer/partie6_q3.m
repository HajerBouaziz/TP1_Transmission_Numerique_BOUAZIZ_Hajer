%% Partie 6 - Question 3 : h, h*h, interference entre symboles et effet de la troncature
clear; close all; clc;
P = mes_parametres('BOUAZIZ Hajer');
alpha = P.alpha;  L = P.L;  span = 10;

%% 1) h et g = h * h (span = 10)
h = coef_rrc(alpha, L, span);
g = conv(h, h);                              % reponse globale emission + reception
nh = (-(numel(h)-1)/2 : (numel(h)-1)/2);     % indices centres
ng = (-(numel(g)-1)/2 : (numel(g)-1)/2);
kT_h = mod(nh, L) == 0;  kT_g = mod(ng, L) == 0;
c = (numel(g) + 1) / 2;

% cosinus sureleve theorique (filtre non tronque), pour comparaison
rc = @(t) sinc_(t) .* cos(pi*alpha*t) ./ (1 - (2*alpha*t).^2);
tt = linspace(-span, span, 4001);
rct = rc(tt);  rct(abs(abs(tt) - 1/(2*alpha)) < 1e-6) = pi/4 * sinc_(1/(2*alpha));

figure('Name', 'h et h*h', 'Position', [100 100 1100 700]);
subplot(2, 1, 1);
stem(nh / L, h, 'Color', [0.6 0.6 0.6]); hold on;
stem(nh(kT_h) / L, h(kT_h), 'r', 'filled', 'LineWidth', 1.2);
grid on; xlabel('t / T'); ylabel('h(t)');
title(sprintf('Filtre en racine de cosinus sureleve h (\\alpha = %.2f, span = %d) : ne s''annule pas en kT', ...
      alpha, span));
legend('h[n]', 'valeurs en t = kT', 'Location', 'northeast');
subplot(2, 1, 2);
plot(tt, rct, 'k-', 'LineWidth', 1); hold on;
stem(ng / L, g, 'Color', [0.6 0.6 0.6]);
stem(ng(kT_g) / L, g(kT_g), 'r', 'filled', 'LineWidth', 1.2);
grid on; xlabel('t / T'); ylabel('(h * h)(t)');
title('Reponse globale g = h * h : cosinus sureleve, nul en t = kT (k \neq 0)');
legend('Cosinus sureleve theorique', 'g[n] = h * h', 'valeurs en t = kT', 'Location', 'northeast');

%% 2) Valeurs aux multiples de T
fprintf('Valeurs aux instants t = kT (alpha = %.2f, span = %d) :\n', alpha, span);
fprintf('%5s %12s %12s\n', 'k', 'h(kT)', '(h*h)(kT)');
for k = 0:6
    fprintf('%5d %12.5f %12.5f\n', k, h((numel(h)+1)/2 + k*L), g(c + k*L));
end

%% 3) Effet de la troncature : IES residuelle en fonction de la longueur du filtre
fprintf('\nEffet de la troncature (IES residuelle aux instants kT, k ~= 0) :\n');
fprintf('%8s %6s %12s %14s %18s\n', 'span', 'N', 'g(0)', 'max |g(kT)|', 'somme |g(kT)|');
for sp = [6 10 20 40]
    hs = coef_rrc(alpha, L, sp);  gs = conv(hs, hs);  cs = (numel(gs) + 1) / 2;
    isi = gs([cs - L:-L:1, cs + L:L:numel(gs)]);
    fprintf('%8d %6d %12.5f %14.2e %18.2e\n', sp, numel(hs), gs(cs), max(abs(isi)), sum(abs(isi)));
end
isi10 = g([c - L:-L:1, c + L:L:numel(g)]);
D = sum(abs(isi10));
fprintf('\nDistorsion maximale (span = 10) : D = %.4f -> echantillon de la voie I entre\n', D);
fprintf('  %.4f et %.4f pour un symbole de 0.7071 (sans bruit)\n', ...
        (1 - D)/sqrt(2), (1 + D)/sqrt(2));

function y = sinc_(x)
% sinc normalise sin(pi x)/(pi x), sans toolbox
    y = ones(size(x));  k = x ~= 0;
    y(k) = sin(pi*x(k)) ./ (pi*x(k));
end