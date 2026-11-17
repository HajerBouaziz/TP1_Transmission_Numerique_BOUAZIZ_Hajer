%% Partie 5 - Question 5 : mapping naturel compare au mapping de Gray
% Mapping naturel : 00 -> k=1, 01 -> k=3, 10 -> k=5, 11 -> k=7.
% Meme modele chaine_qpsk.slx : seules les tables de mapping et de demapping changent.
clear; close all; clc;
mdl = 'chaine_qpsk';
if ~exist([mdl '.slx'], 'file'), construire_chaine_qpsk; end
if ~bdIsLoaded(mdl), load_system(mdl); end

P = mes_parametres('BOUAZIZ Hajer');  graine = P.graine;
Tb = 1;  Ts = 2 * Tb;  p1 = 0.5;  Es = 1;  Eb = Es / 2;
Q = @(x) 0.5 * erfc(x / sqrt(2));
EbN0_dB = 0:9;

% Tables : mapping n = 2 b1 + b2 -> (I, Q) ; demapping quadrant q = 2 sI + sQ -> (b1, b2)
M(1).nom = 'Gray';
M(1).tabI = [1 1 -1 -1]/sqrt(2);  M(1).tabQ = [1 -1 1 -1]/sqrt(2);
M(1).tabB1 = [0 0 1 1];           M(1).tabB2 = [0 1 0 1];
M(2).nom = 'Naturel';
M(2).tabI = [1 -1 -1 1]/sqrt(2);  M(2).tabQ = [1 1 -1 -1]/sqrt(2);
M(2).tabB1 = [0 1 0 1];           M(2).tabB2 = [0 1 1 0];

%% Verification sans bruit du mapping naturel
tabI = M(2).tabI;  tabQ = M(2).tabQ;  tabB1 = M(2).tabB1;  tabB2 = M(2).tabB2;
sigma2v = 0;  Nbits = 2000;  Tsim = (Nbits - 1) * Tb;
out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
be = out.b_emis(:);  s = out.s_emis(:);
fprintf('Mapping naturel observe (sans bruit) :\n');
vus = zeros(0, 2);
for k = 2:numel(s)
    couple = be([2*k - 2, 2*k - 1])';
    if isempty(vus) || ~ismember(couple, vus, 'rows')
        vus(end+1, :) = couple;  %#ok<SAGROW>
        fprintf('  %d%d -> k = %d\n', couple, mod(round(angle(s(k)) / (pi/4)), 8));
    end
    if size(vus, 1) == 4, break; end
end
fprintf('Sans bruit : %d erreur(s)\n\n', compter_erreurs(be, out.b_recu(:), 6));

%% TEB des deux mappings
teb = zeros(2, numel(EbN0_dB));
fprintf('%8s %12s %12s %14s %14s %8s\n', 'Eb/N0', 'TEB Gray', 'Theo. Gray', 'TEB naturel', ...
        'Theo. naturel', 'Rapport');
for i = 1:numel(EbN0_dB)
    e = 10^(EbN0_dB(i) / 10);  p = Q(sqrt(2 * e));
    sigma2v = Eb / e / 2;
    Nbits = 2 * ceil(min(max(1e5, 200 / p), 2e6) / 2);   Tsim = (Nbits - 1) * Tb;
    for m = 1:2
        tabI = M(m).tabI;  tabQ = M(m).tabQ;  tabB1 = M(m).tabB1;  tabB2 = M(m).tabB2;
        out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
        [ne, n] = compter_erreurs(out.b_emis(:), out.b_recu(:), 6);
        teb(m, i) = ne / n;
    end
    fprintf('%6d dB %12.2e %12.2e %14.2e %14.2e %8.2f\n', EbN0_dB(i), teb(1, i), p, ...
            teb(2, i), (3*p - 2*p^2) / 2, teb(2, i) / teb(1, i));
end

x = linspace(0, 10, 200);  px = Q(sqrt(2 * 10.^(x/10)));
figure('Name', 'Gray et naturel');
semilogy(x, px, 'b-', 'LineWidth', 1.5); hold on;
semilogy(EbN0_dB, max(teb(1, :), eps), 'bo', 'MarkerSize', 7, 'LineWidth', 1.5);
semilogy(x, (3*px - 2*px.^2) / 2, 'r-', 'LineWidth', 1.5);
semilogy(EbN0_dB, max(teb(2, :), eps), 'rs', 'MarkerSize', 7, 'LineWidth', 1.5);
grid on; xlabel('E_b/N_0 (dB)'); ylabel('TEB');
title('QPSK : mapping de Gray et mapping naturel');
legend('Theorie Gray : p', 'Simulation Gray', 'Theorie naturel : (3p - 2p^2)/2', ...
       'Simulation naturel', 'Location', 'southwest');
ylim([1e-6 0.5]);

%% ======================= Fonction locale =======================
function [nerr, n] = compter_erreurs(be, br, Dmax)
    N = min(numel(be), numel(br));
    idx = 10:N - Dmax;
    nerr = inf;
    for D = 0:Dmax
        nerr = min(nerr, sum(be(idx) ~= br(idx + D)));
    end
    n = numel(idx);
end