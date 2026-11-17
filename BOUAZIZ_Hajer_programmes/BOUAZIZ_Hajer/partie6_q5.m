%% Partie 6 - Question 5 : filtres porte et RRC dans la chaine QPSK
% 1) diagrammes de l'oeil (sortie du filtre adapte, voie I), sans bruit et a 10 dB ;
% 2) constellations recues ;
% 3) TEB en fonction de Eb/N0 pour les deux filtres.
clear; close all; clc;
mdl = 'chaine_filtres';
if ~exist([mdl '.slx'], 'file'), construire_chaine_filtres; end
if ~bdIsLoaded(mdl), load_system(mdl); end

%% Parametres
P = mes_parametres('BOUAZIZ Hajer');  graine = P.graine;
alpha = P.alpha;  L = P.L;  span = 10;
Tb = 1;  Ts = 2 * Tb;  Te = Ts / L;  p1 = 0.5;  Eb = 1/2;
tabI  = [1 1 -1 -1] / sqrt(2);   tabQ  = [1 -1 1 -1] / sqrt(2);
tabB1 = [0 0 1 1];               tabB2 = [0 1 0 1];
Q = @(x) 0.5 * erfc(x / sqrt(2));
filtres = {ones(1, L) / sqrt(L), coef_rrc(alpha, L, span)};
noms    = {'Filtre porte', sprintf('Filtre RRC \\alpha = %.2f', alpha)};

%% 1) et 2) Diagrammes de l'oeil et constellations
fig_oeil = figure('Name', 'Diagrammes de l''oeil', 'Position', [50 50 1100 700]);
fig_cons = figure('Name', 'Constellations', 'Position', [100 100 1100 420]);
d_cal = zeros(1, 2);
for m = 1:2
    h = filtres{m};
    d_ech = calage(mdl, L);  d_cal(m) = d_ech;
    for c = 1:2                                   % c = 1 : sans bruit, c = 2 : 10 dB
        if c == 1, sigma2 = 0; titre = 'sans bruit';
        else, sigma2 = Eb / 10^(10/10) / 2; titre = 'E_b/N_0 = 10 dB'; end
        Nbits = 2000;  Tsim = (Nbits - 1) * Tb;
        out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
        figure(fig_oeil);  subplot(2, 2, 2*(m-1) + c);
        diagramme_oeil(real(out.y_fa(:)), L, 8, 300);
        title(sprintf('%s, %s', noms{m}, titre));
        if c == 2
            figure(fig_cons);  subplot(1, 3, m);
            zz = out.z(40:end);
            plot(real(zz), imag(zz), '.', 'MarkerSize', 5); hold on;
            plot([1 -1 -1 1]/sqrt(2), [1 1 -1 -1]/sqrt(2), 'r+', 'MarkerSize', 14, 'LineWidth', 2);
            xline(0); yline(0); axis equal; grid on; xlim([-1.5 1.5]); ylim([-1.5 1.5]);
            xlabel('Voie I'); ylabel('Voie Q'); title(sprintf('%s, 10 dB', noms{m}));
        end
        if m == 2 && c == 1
            figure(fig_cons);  subplot(1, 3, 3);
            zz = out.z(40:end);
            plot(real(zz), imag(zz), '.', 'MarkerSize', 8); hold on;
            plot([1 -1 -1 1]/sqrt(2), [1 1 -1 -1]/sqrt(2), 'r+', 'MarkerSize', 14, 'LineWidth', 2);
            xline(0); yline(0); axis equal; grid on; xlim([-1.5 1.5]); ylim([-1.5 1.5]);
            xlabel('Voie I'); ylabel('Voie Q'); title('Filtre RRC, sans bruit (IES de troncature)');
        end
    end
end
figure(fig_oeil);  sgtitle('Diagrammes de l''oeil en sortie du filtre adapte (voie I)');
figure(fig_cons);  sgtitle('Constellations recues apres echantillonnage');
fprintf('Calage de l''echantillonnage : %d echantillon(s) (porte), %d (RRC)\n', d_cal);
fprintf('Retard des filtres RRC : N - 1 = %d echantillons = %d symboles\n\n', 2*(span*L/2), span);

%% 3) TEB
EbN0_dB = 0:9;  teb = zeros(2, numel(EbN0_dB));
fprintf('%8s %10s %12s %12s %12s\n', 'Eb/N0', 'Nbits', 'TEB porte', 'TEB RRC', 'Theorie');
for i = 1:numel(EbN0_dB)
    e = 10^(EbN0_dB(i) / 10);  sigma2 = Eb / e / 2;
    Nbits = 2 * ceil(min(max(5e4, 200 / Q(sqrt(2*e))), 1e6) / 2);   Tsim = (Nbits - 1) * Tb;
    for m = 1:2
        h = filtres{m};  d_ech = d_cal(m);
        out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
        [ne, n] = compter_erreurs(out.b_emis(:), out.b_recu(:), 40);
        teb(m, i) = ne / n;
    end
    fprintf('%6d dB %10d %12.2e %12.2e %12.2e\n', EbN0_dB(i), n, teb(1, i), teb(2, i), Q(sqrt(2*e)));
end
x = linspace(0, 10, 200);
figure('Name', 'TEB porte et RRC');
semilogy(x, Q(sqrt(2 * 10.^(x/10))), 'k-', 'LineWidth', 1.5); hold on;
semilogy(EbN0_dB, max(teb(1, :), eps), 'bo', 'MarkerSize', 7, 'LineWidth', 1.5);
semilogy(EbN0_dB, max(teb(2, :), eps), 'rs', 'MarkerSize', 7, 'LineWidth', 1.5);
grid on; xlabel('E_b/N_0 (dB)'); ylabel('TEB'); ylim([1e-6 0.5]);
title('TEB de la chaine QPSK avec filtre porte et avec filtre RRC');
legend('Theorie Q(\surd(2E_b/N_0))', noms{1}, noms{2}, 'Location', 'southwest');

%% ======================= Fonctions locales =======================
function diagramme_oeil(y, L, sur, ntraces)
% Superpose des traces de 2 symboles centrees sur les instants d'echantillonnage optimaux.
% Le signal est interpole (facteur sur) pour l'affichage seulement.
    y = y(:);  y = y(20*L:end);                   % on ignore le debut (retard des filtres)
    crit = zeros(1, L);
    for ph = 1:L, crit(ph) = mean(abs(y(ph:L:end))); end
    [~, ph] = max(crit);                          % phase des instants optimaux
    n  = (0:numel(y)-1)';
    nf = (0:1/sur:numel(y)-1)';
    yf = interp1(n, y, nf, 'spline');
    tr = (-L*sur : L*sur)';                        % -1 a +1 symbole autour de l'instant optimal
    hold on;
    k0 = ph - 1 + 2*L;
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
% Retard d'echantillonnage (1 a L) donnant, sans bruit, les echantillons les plus proches des symboles.
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