%% Partie 6 - Question 1 : filtre porte = detecteur optimal de la figure 3
% Mise en forme par une porte de L echantillons (h = 1/sqrt(L)), filtre adapte identique,
% echantillonnage une fois par symbole. On verifie que le TEB est inchange : Q(sqrt(2 Eb/N0)).
clear; close all; clc;
mdl = 'chaine_filtres';
if ~exist([mdl '.slx'], 'file'), construire_chaine_filtres; end
if ~bdIsLoaded(mdl), load_system(mdl); end

%% Parametres
P = mes_parametres('BOUAZIZ Hajer');  graine = P.graine;  L = P.L;
Tb = 1;  Ts = 2 * Tb;  Te = Ts / L;  p1 = 0.5;
Eb = 1/2;                                         % Es = 1, 2 bits par symbole
tabI  = [1 1 -1 -1] / sqrt(2);   tabQ  = [1 -1 1 -1] / sqrt(2);
tabB1 = [0 0 1 1];               tabB2 = [0 1 0 1];
h = ones(1, L) / sqrt(L);                         % filtre porte, energie unite
Q = @(x) 0.5 * erfc(x / sqrt(2));
fprintf('Filtre porte : L = %d coefficients egaux a 1/sqrt(L) = %.4f, energie sum(h^2) = %.3f\n', ...
        L, h(1), sum(h.^2));

%% 1) Calage de l'echantillonnage, sans bruit
d_ech = calage(mdl, L);
fprintf('Calage de l''echantillonneur : %d echantillon(s)\n', d_ech);
sigma2 = 0;  Nbits = 400;  Tsim = (Nbits - 1) * Tb;
out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
zz = out.z(20:end);
fprintf('Sans bruit : echantillons preleves = %s (symboles emis : +/-0.7071 +/-0.7071j)\n', ...
        mat2str(unique(round([real(zz); imag(zz)], 4))'));
fprintf('Sans bruit : %d erreur(s)\n\n', compter_erreurs(out.b_emis(:), out.b_recu(:), 30));

%% 2) TEB en fonction de Eb/N0
EbN0_dB = 0:9;  teb = zeros(size(EbN0_dB));  vz = teb;
fprintf('%8s %10s %12s %12s %16s\n', 'Eb/N0', 'Nbits', 'TEB porte', 'Theorie', 'Var. bruit sortie');
for i = 1:numel(EbN0_dB)
    e = 10^(EbN0_dB(i) / 10);  N0 = Eb / e;
    sigma2 = N0 / 2;                              % par voie et par echantillon
    Nbits = 2 * ceil(min(max(1e5, 200 / Q(sqrt(2*e))), 2e6) / 2);   Tsim = (Nbits - 1) * Tb;
    out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    [ne, n] = compter_erreurs(out.b_emis(:), out.b_recu(:), 30);
    teb(i) = ne / n;
    vz(i) = var_bruit(out.z(:), out.s_emis(:));  % variance du bruit sur la voie I apres filtrage
    fprintf('%6d dB %10d %12.2e %12.2e %9.4f (N0/2 = %.4f)\n', EbN0_dB(i), n, teb(i), ...
            Q(sqrt(2*e)), vz(i), N0/2);
end

x = linspace(0, 10, 200);
figure('Name', 'Filtre porte');
semilogy(x, Q(sqrt(2 * 10.^(x/10))), 'b-', 'LineWidth', 1.5); hold on;
semilogy(EbN0_dB, max(teb, eps), 'rs', 'MarkerSize', 8, 'LineWidth', 1.5);
grid on; xlabel('E_b/N_0 (dB)'); ylabel('TEB');
title(sprintf('QPSK avec filtre porte et filtre adapte (L = %d)', L));
legend('Theorie Q(\surd(2E_b/N_0)) (detecteur de la figure 3)', 'Simulation avec filtre porte', ...
       'Location', 'southwest');
ylim([1e-6 0.5]);

%% ======================= Fonctions locales =======================
function d = calage(mdl, L)
% Choisit le retard d'echantillonnage (1 a L echantillons) pour lequel, sans bruit,
% les echantillons preleves sont les plus proches des symboles (+/-1/sqrt(2) sur chaque voie).
    assignin('base', 'sigma2', 0);
    assignin('base', 'Tsim', 399);
    crit = inf(1, L);
    for k = 1:L
        assignin('base', 'd_ech', k);
        out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
        zz = out.z(20:end);
        crit(k) = mean(abs(abs(real(zz)) - 1/sqrt(2)) + abs(abs(imag(zz)) - 1/sqrt(2)));
    end
    [~, d] = min(crit);
    assignin('base', 'd_ech', d);
end

function v = var_bruit(z, s)
% Variance du bruit sur la voie I : z est aligne sur s (retard de 0 a 20 symboles).
    N = min(numel(z), numel(s));  idx = 30:N - 20;  best = inf;
    for D = 0:20
        m = mean(abs(z(idx + D) - s(idx)).^2);
        if m < best, best = m;  v = var(real(z(idx + D) - s(idx))); end
    end
end

function [nerr, n] = compter_erreurs(be, br, Dmax)
    N = min(numel(be), numel(br));
    idx = 40:N - Dmax;
    nerr = inf;
    for D = 0:Dmax
        nerr = min(nerr, sum(be(idx) ~= br(idx + D)));
    end
    n = numel(idx);
end