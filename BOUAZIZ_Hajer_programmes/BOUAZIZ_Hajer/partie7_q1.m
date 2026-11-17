%% Partie 7 - Question 1 : canal a echo hc(t) = delta(t) + beta delta(t - tau)
% Chaine QPSK avec filtres RRC (partie 6) et canal a echo (beta, tau = retard * T).
% 1) reponse globale aux instants kT (critere de Nyquist) ;
% 2) diagrammes de l'oeil et constellations sans et avec echo ;
% 3) TEB en fonction de Eb/N0, compare a la theorie.
clear; close all; clc;
mdl = 'chaine_echo';
if ~exist([mdl '.slx'], 'file'), construire_chaine_echo; end
if ~bdIsLoaded(mdl), load_system(mdl); end

%% Parametres
P = mes_parametres('BOUAZIZ Hajer');  graine = P.graine;
alpha = P.alpha;  L = P.L;  span = 10;
beta_echo = P.beta;  retard = P.retard_trajet;
Tb = 1;  Ts = 2 * Tb;  Te = Ts / L;  p1 = 0.5;  Eb = 1/2;
tabI  = [1 1 -1 -1] / sqrt(2);   tabQ  = [1 -1 1 -1] / sqrt(2);
tabB1 = [0 0 1 1];               tabB2 = [0 1 0 1];
h = coef_rrc(alpha, L, span);
Q = @(x) 0.5 * erfc(x / sqrt(2));
fprintf('Canal a echo : beta = %.2f, tau = %d symbole(s) ; filtre RRC alpha = %.2f, L = %d\n\n', ...
        beta_echo, retard, alpha, L);

%% 1) Reponse globale aux instants kT
g  = conv(h, h);                                   % emission + reception
hc = [1, zeros(1, retard*L - 1), beta_echo];       % canal a echo (echantillonne a Te)
gc = conv(g, hc);
c  = (numel(g) + 1) / 2;
fprintf('Reponse globale aux instants kT :\n%5s %16s %16s\n', 'k', 'sans echo', 'avec echo');
for k = -2:3
    v1 = 0;  if c + k*L >= 1 && c + k*L <= numel(g), v1 = g(c + k*L); end
    fprintf('%5d %16.4f %16.4f\n', k, v1, gc(c + k*L));
end
fprintf('-> avec echo, la reponse vaut %.2f en t = %d T : critere de Nyquist non verifie\n\n', ...
        gc(c + retard*L), retard);

%% 2) Calage (sans echo), puis oeil et constellations
beta = 0;  d_ech = calage(mdl, L);
fig_oeil = figure('Name', 'Oeil avec echo', 'Position', [50 50 1100 450]);
fig_cons = figure('Name', 'Constellations avec echo', 'Position', [80 80 1100 420]);
cas = {0, 0; beta_echo, 0; beta_echo, 10};         % {beta, Eb/N0 (0 = sans bruit)}
titres = {'sans echo, sans bruit', sprintf('echo \\beta = %.2f, sans bruit', beta_echo), ...
          sprintf('echo \\beta = %.2f, E_b/N_0 = 10 dB', beta_echo)};
for c = 1:3
    beta = cas{c, 1};
    if cas{c, 2} == 0, sigma2 = 0; else, sigma2 = Eb / 10^(cas{c, 2}/10) / 2; end
    Nbits = 2000;  Tsim = (Nbits - 1) * Tb;
    out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    if c <= 2
        figure(fig_oeil);  subplot(1, 2, c);
        diagramme_oeil(real(out.y_fa(:)), L, 8, 300);
        if c == 2
            yline((1 - beta_echo)/sqrt(2) * [1 -1], 'm--', 'A(1-\beta)');
            yline((1 + beta_echo)/sqrt(2) * [1 -1], 'g--', 'A(1+\beta)');
        end
        title(['Oeil (voie I), ' titres{c}]);
    end
    figure(fig_cons);  subplot(1, 3, c);
    zz = out.z(40:end);
    plot(real(zz), imag(zz), '.', 'MarkerSize', 6); hold on;
    plot([1 -1 -1 1]/sqrt(2), [1 1 -1 -1]/sqrt(2), 'r+', 'MarkerSize', 14, 'LineWidth', 2);
    xline(0); yline(0); axis equal; grid on; xlim([-1.6 1.6]); ylim([-1.6 1.6]);
    xlabel('Voie I'); ylabel('Voie Q'); title(titres{c});
end
figure(fig_cons);  sgtitle('Constellations recues');

%% 3) TEB
EbN0_dB = 0:9;  teb = zeros(2, numel(EbN0_dB));
th_echo = @(e) 0.5 * (Q((1 + beta_echo) * sqrt(2*e)) + Q((1 - beta_echo) * sqrt(2*e)));
fprintf('%8s %10s %12s %12s %14s\n', 'Eb/N0', 'Nbits', 'Sans echo', 'Avec echo', 'Theorie echo');
for i = 1:numel(EbN0_dB)
    e = 10^(EbN0_dB(i) / 10);  sigma2 = Eb / e / 2;
    Nbits = 2 * ceil(min(max(5e4, 100 / Q(sqrt(2*e))), 1e6) / 2);   Tsim = (Nbits - 1) * Tb;
    for m = 1:2
        if m == 1, beta = 0; else, beta = beta_echo; end
        out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
        [ne, n] = compter_erreurs(out.b_emis(:), out.b_recu(:), 40);
        teb(m, i) = ne / n;
    end
    fprintf('%6d dB %10d %12.2e %12.2e %14.2e\n', EbN0_dB(i), n, teb(1, i), teb(2, i), th_echo(e));
end
x = linspace(0, 12, 300);  ex = 10.^(x/10);
figure('Name', 'TEB avec echo');
semilogy(x, Q(sqrt(2*ex)), 'b-', 'LineWidth', 1.5); hold on;
semilogy(EbN0_dB, max(teb(1, :), eps), 'bo', 'MarkerSize', 7, 'LineWidth', 1.5);
semilogy(x, th_echo(ex), 'r-', 'LineWidth', 1.5);
semilogy(EbN0_dB, max(teb(2, :), eps), 'rs', 'MarkerSize', 7, 'LineWidth', 1.5);
grid on; xlabel('E_b/N_0 (dB)'); ylabel('TEB'); ylim([1e-6 0.5]);
title(sprintf('TEB avec canal a echo (\\beta = %.2f, \\tau = %d T)', beta_echo, retard));
legend('Theorie sans echo', 'Simulation sans echo', ...
       'Theorie avec echo : [Q((1+\beta)\surd(2E_b/N_0)) + Q((1-\beta)\surd(2E_b/N_0))] / 2', ...
       'Simulation avec echo', 'Location', 'southwest');
x4 = fzero(@(xd) log(Q(sqrt(2*10^(xd/10)))) - log(1e-4), [0 15]);
x4e = fzero(@(xd) log(th_echo(10^(xd/10))) - log(1e-4), [0 20]);
fprintf('\nTEB = 1e-4 : %.2f dB sans echo, %.2f dB avec echo -> perte %.2f dB\n', x4, x4e, x4e - x4);
fprintf('Perte asymptotique 20 log10(1/(1-beta)) = %.2f dB\n', 20*log10(1/(1 - beta_echo)));

%% ======================= Fonctions locales =======================
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
    xlabel('t / T (0 = instant d''echantillonnage)'); ylabel('Voie I');
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