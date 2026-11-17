%% Partie 3 - Question 12 : TEB en fonction de Eb/N0 (0 a 9 dB), pilote par script
% Pour chaque Eb/N0 : calcul de la variance du bruit, simulation du modele
% chaine_base.slx avec sim, comptage des erreurs
%   - avec le detecteur optimal (integrateur + echantillonneur),
%   - sans integration (un seul echantillon au milieu de chaque bit).
% Comparaison avec les courbes theoriques Q(sqrt(2 Eb/N0)) et Q(sqrt(2 Eb/(L N0))).
clear; close all; clc;
EbN0_dB = 0:9;
mdl = 'chaine_base';
Q = @(x) 0.5 * erfc(x / sqrt(2));

parametres_chaine;                 % Tb, L, Te, A, graine, ...
if ~bdIsLoaded(mdl), load_system(mdl); end

%% 1) Calage de l'echantillonneur (une seule fois, sans bruit)
sigma2 = 0;  Nbits = 200;  Tsim = (Nbits - 1) * Tb;
ecart = inf(1, L);
for d = 1:L
    d_ech = d;
    out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    ecart(d) = max(abs(abs(out.z(4:end)) - A));
end
[~, d_ech] = min(ecart);
fprintf('L = %d, calage de l''echantillonneur : %d echantillon(s)\n\n', L, d_ech);

%% 2) Boucle sur Eb/N0
teb_int = zeros(size(EbN0_dB));   teb_mil = teb_int;
nerr_int = teb_int;               nerr_mil = teb_int;   nb = teb_int;
fprintf('%8s %10s %12s %12s %12s %12s %10s\n', 'Eb/N0', 'Nbits', 'TEB integ.', ...
        'Theorie', 'TEB milieu', 'Theorie', 'sigma2');
for i = 1:numel(EbN0_dB)
    EbN0   = 10^(EbN0_dB(i) / 10);
    N0     = A^2 * Tb / EbN0;
    sigma2 = N0 * L / (2 * Tb);                  % variance par echantillon

    % Nombre de bits : au moins ~200 erreurs attendues (min 1e5, max 3e6)
    Nbits = min(max(1e5, ceil(200 / Q(sqrt(2 * EbN0)))), 3e6);
    Tsim  = (Nbits - 1) * Tb;

    out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    be  = out.b_emis(:);
    [nerr_int(i), nb(i)] = compter_erreurs(be, out.b_recu(:));
    [nerr_mil(i), ~]     = compter_erreurs(be, out.b_recu_mil(:));
    teb_int(i) = nerr_int(i) / nb(i);
    teb_mil(i) = nerr_mil(i) / nb(i);

    fprintf('%6d dB %10d %12.2e %12.2e %12.2e %12.2e %10.4f\n', EbN0_dB(i), nb(i), ...
            teb_int(i), Q(sqrt(2*EbN0)), teb_mil(i), Q(sqrt(2*EbN0/L)), sigma2);
end

%% 3) Courbes
x = linspace(0, 9, 200);
figure('Name', 'TEB chaine de base');
semilogy(x, Q(sqrt(2 * 10.^(x/10))), 'b-', 'LineWidth', 1.5); hold on;
semilogy(EbN0_dB, teb_int, 'bo', 'MarkerSize', 7, 'LineWidth', 1.5);
semilogy(x, Q(sqrt(2 * 10.^(x/10) / L)), 'r--', 'LineWidth', 1.5);
semilogy(EbN0_dB, teb_mil, 'rs', 'MarkerSize', 7, 'LineWidth', 1.5);
grid on; xlabel('E_b/N_0 (dB)'); ylabel('TEB');
title(sprintf('Chaine de base, bruit blanc gaussien (L = %d echantillons par bit)', L));
legend('Theorie avec integration : Q(\surd(2E_b/N_0))', 'Simulation avec integration', ...
       sprintf('Theorie sans integration : Q(\\surd(2E_b/(%d N_0)))', L), ...
       'Simulation sans integration (echantillon au milieu)', 'Location', 'southwest');
ylim([1e-6 1]);

fprintf('\nEcart entre les deux courbes theoriques : 10 log10(L) = %.2f dB\n', 10*log10(L));

%% ======================= Fonction locale =======================
function [nerr, n] = compter_erreurs(be, br)
% Compense le retard de la chaine (0 a 5 bits) en retenant celui qui
% minimise le nombre d'erreurs, puis compte les erreurs.
    m = zeros(1, 6);
    for D = 0:5
        m(D + 1) = sum(be(1:end - D - 5) ~= br(1 + D:end - 5));
    end
    [nerr, iD] = min(m);
    n = numel(be) - (iD - 1) - 5;
end