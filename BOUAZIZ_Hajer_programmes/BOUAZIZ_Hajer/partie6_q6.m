%% Partie 6 - Question 6 : decalage de l'instant d'echantillonnage de T/4
% Comparaison alpha = 0,22 et alpha = 1 : diagrammes de l'oeil, constellations (10 dB),
% TEB en fonction de Eb/N0 avec et sans decalage.
clear; close all; clc;
mdl = 'chaine_filtres';
if ~exist([mdl '.slx'], 'file'), construire_chaine_filtres; end
if ~bdIsLoaded(mdl), load_system(mdl); end

%% Parametres
P = mes_parametres('BOUAZIZ Hajer');  graine = P.graine;
L = P.L;  span = 10;  decal = L / 4;          % T/4 = L/4 echantillons
Tb = 1;  Ts = 2 * Tb;  Te = Ts / L;  p1 = 0.5;  Eb = 1/2;
tabI  = [1 1 -1 -1] / sqrt(2);   tabQ  = [1 -1 1 -1] / sqrt(2);
tabB1 = [0 0 1 1];               tabB2 = [0 1 0 1];
Q = @(x) 0.5 * erfc(x / sqrt(2));
alphas = [0.22 1];
fprintf('Decalage de l''instant d''echantillonnage : T/4 = %g echantillon(s)\n\n', decal);

%% 1) Prediction theorique : IES pour un decalage de T/4 (cosinus sureleve)
fprintf('%8s %12s %16s %18s\n', 'alpha', 'g(T/4)', 'IES max (somme)', 'Ouverture pire cas');
for a = alphas
    k = -40:40;  g = rc(k + 0.25, a);
    g0 = g(k == 0);  isi = sum(abs(g(k ~= 0)));
    fprintf('%8.2f %12.3f %16.3f %18.3f\n', a, g0, isi, g0 - isi);
end
fprintf('\n');

%% 2) Diagrammes de l'oeil et constellations
fig_oeil = figure('Name', 'Oeil', 'Position', [50 50 1100 450]);
fig_cons = figure('Name', 'Constellations decalees', 'Position', [80 80 1100 750]);
d0 = zeros(size(alphas));
for m = 1:numel(alphas)
    h = coef_rrc(alphas(m), L, span);
    d0(m) = calage(mdl, L);
    sigma2 = 0;  d_ech = d0(m);  Nbits = 2000;  Tsim = (Nbits - 1) * Tb;
    out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    figure(fig_oeil);  subplot(1, 2, m);
    diagramme_oeil(real(out.y_fa(:)), L, 8, 300);
    xline(0.25, 'm-', 'T/4', 'LineWidth', 1.5);
    title(sprintf('Oeil sans bruit, \\alpha = %.2f', alphas(m)));
    for c = 1:2                                % c = 1 : instant optimal, c = 2 : decale de T/4
        sigma2 = Eb / 10 / 2;  d_ech = d0(m) + (c - 1) * decal;
        out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
        zz = out.z(40:end);
        figure(fig_cons);  subplot(2, 2, 2*(m-1) + c);
        plot(real(zz), imag(zz), '.', 'MarkerSize', 5); hold on;
        plot([1 -1 -1 1]/sqrt(2), [1 1 -1 -1]/sqrt(2), 'r+', 'MarkerSize', 14, 'LineWidth', 2);
        xline(0); yline(0); axis equal; grid on; xlim([-1.6 1.6]); ylim([-1.6 1.6]);
        xlabel('Voie I'); ylabel('Voie Q');
        if c == 1, t2 = 'instant optimal'; else, t2 = 'decalage T/4'; end
        title(sprintf('\\alpha = %.2f, %s, 10 dB', alphas(m), t2));
    end
end
figure(fig_oeil);  sgtitle('Diagrammes de l''oeil (voie I) : instant optimal t = 0 et instant decale t = T/4');
figure(fig_cons);  sgtitle('Constellations recues a E_b/N_0 = 10 dB');

%% 3) TEB avec et sans decalage
EbN0_dB = 0:9;  teb = zeros(numel(alphas), 2, numel(EbN0_dB));
fprintf('%8s | %12s %12s | %12s %12s | %10s\n', 'Eb/N0', 'a=0.22 opt.', 'a=0.22 T/4', ...
        'a=1 opt.', 'a=1 T/4', 'Theorie');
for i = 1:numel(EbN0_dB)
    e = 10^(EbN0_dB(i) / 10);  sigma2 = Eb / e / 2;
    Nbits = 2 * ceil(min(max(5e4, 100 / Q(sqrt(2*e))), 4e5) / 2);   Tsim = (Nbits - 1) * Tb;
    for m = 1:numel(alphas)
        h = coef_rrc(alphas(m), L, span);
        for c = 1:2
            d_ech = d0(m) + (c - 1) * decal;
            out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
            [ne, n] = compter_erreurs(out.b_emis(:), out.b_recu(:), 40);
            teb(m, c, i) = ne / n;
        end
    end
    fprintf('%6d dB | %12.2e %12.2e | %12.2e %12.2e | %10.2e\n', EbN0_dB(i), teb(1, 1, i), ...
            teb(1, 2, i), teb(2, 1, i), teb(2, 2, i), Q(sqrt(2*e)));
end
x = linspace(0, 10, 200);
figure('Name', 'TEB decalage');
semilogy(x, Q(sqrt(2 * 10.^(x/10))), 'k-', 'LineWidth', 1.5); hold on;
sty = {'bo-', 'bo--'; 'rs-', 'rs--'};
for m = 1:numel(alphas)
    for c = 1:2
        semilogy(EbN0_dB, max(squeeze(teb(m, c, :)), 1e-7), sty{m, c}, 'LineWidth', 1.3, 'MarkerSize', 6);
    end
end
grid on; xlabel('E_b/N_0 (dB)'); ylabel('TEB'); ylim([1e-6 0.5]);
title('TEB avec echantillonnage optimal et decale de T/4');
legend('Theorie (instant optimal)', '\alpha = 0,22 optimal', '\alpha = 0,22 decale T/4', ...
       '\alpha = 1 optimal', '\alpha = 1 decale T/4', 'Location', 'southwest');

%% ======================= Fonctions locales =======================
function g = rc(t, a)
% Cosinus sureleve (T = 1), avec la limite aux points t = +/- 1/(2a).
    g = zeros(size(t));
    for k = 1:numel(t)
        if abs(1 - (2*a*t(k))^2) < 1e-10
            g(k) = pi/4 * sinc_(1/(2*a));
        else
            g(k) = sinc_(t(k)) * cos(pi*a*t(k)) / (1 - (2*a*t(k))^2);
        end
    end
end

function y = sinc_(x)
    if x == 0, y = 1; else, y = sin(pi*x) / (pi*x); end
end

function diagramme_oeil(y, L, sur, ntraces)
    y = y(:);  y = y(20*L:end);
    crit = zeros(1, L);
    for ph = 1:L, crit(ph) = mean(abs(y(ph:L:end))); end
    [~, ph] = max(crit);
    n  = (0:numel(y)-1)';  nf = (0:1/sur:numel(y)-1)';
    yf = interp1(n, y, nf, 'spline');
    tr = (-L*sur : L*sur)';
    hold on;  k0 = ph - 1 + 2*L;
    for k = 0:ntraces-1
        c = (k0 + k*L) * sur + 1;
        if c + L*sur > numel(yf), break; end
        plot(tr / (L*sur), yf(c + tr), '-', 'Color', [0.35 0.55 0.9]);
    end
    xline(0, 'r--', 'LineWidth', 1.2);
    grid on; xlim([-1 1]); ylim([-1.6 1.6]);
    xlabel('t / T (0 = instant optimal)'); ylabel('Voie I');
end

function d = calage(mdl, L)
    assignin('base', 'sigma2', 0);  assignin('base', 'Tsim', 399);
    crit = inf(1, L);
    for k = 1:L
        assignin('base', 'd_ech', k);
        out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
        zz = out.z(40:end);
        crit(k) = mean(abs(abs(real(zz)) - 1/sqrt(2)) + abs(abs(imag(zz)) - 1/sqrt(2)));
    end
    [~, d] = min(crit);
    assignin('base', 'd_ech', d);
end

function [nerr, n] = compter_erreurs(be, br, Dmax)
    N = min(numel(be), numel(br));
    idx = 60:N - Dmax;
    nerr = inf;
    for D = 0:Dmax
        nerr = min(nerr, sum(be(idx) ~= br(idx + D)));
    end
    n = numel(idx);
end