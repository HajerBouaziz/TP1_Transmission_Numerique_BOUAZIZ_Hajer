%% Partie 5 - Question 4 : TEB de la chaine QPSK (Gray) compare a la chaine binaire
% TEB simule de la QPSK pour Eb/N0 = 0..9 dB, compare a Q(sqrt(2 Eb/N0)),
% qui est aussi le TEB de la chaine binaire de la partie 3.
clear; close all; clc;
mdl = 'chaine_qpsk';
if ~exist([mdl '.slx'], 'file'), construire_chaine_qpsk; end
if ~bdIsLoaded(mdl), load_system(mdl); end

%% Parametres (mapping de Gray)
P = mes_parametres('BOUAZIZ Hajer');  graine = P.graine;
Tb = 1;  Ts = 2 * Tb;  p1 = 0.5;  Es = 1;  Eb = Es / 2;
tabI  = [1 1 -1 -1] / sqrt(2);   tabQ  = [1 -1 1 -1] / sqrt(2);
tabB1 = [0 0 1 1];               tabB2 = [0 1 0 1];
Q = @(x) 0.5 * erfc(x / sqrt(2));
EbN0_dB = 0:9;

teb = zeros(size(EbN0_dB));
fprintf('%8s %10s %12s %12s %12s\n', 'Eb/N0', 'Nbits', 'TEB QPSK', 'Theorie', 'TES QPSK');
for i = 1:numel(EbN0_dB)
    e = 10^(EbN0_dB(i) / 10);
    N0 = Eb / e;  sigma2v = N0 / 2;
    Nbits = 2 * ceil(min(max(1e5, 200 / Q(sqrt(2*e))), 4e6) / 2);
    Tsim  = (Nbits - 1) * Tb;
    out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    [ne, n] = compter_erreurs(out.b_emis(:), out.b_recu(:), 6);
    teb(i) = ne / n;
    r = out.s_recu(2:end);  s = out.s_emis(2:end);
    tes = mean((sign(real(r)) ~= sign(real(s))) | (sign(imag(r)) ~= sign(imag(s))));
    fprintf('%6d dB %10d %12.2e %12.2e %12.2e\n', EbN0_dB(i), n, teb(i), Q(sqrt(2*e)), tes);
end

x = linspace(0, 10, 200);
figure('Name', 'TEB QPSK');
semilogy(x, Q(sqrt(2 * 10.^(x/10))), 'b-', 'LineWidth', 1.5); hold on;
semilogy(EbN0_dB, max(teb, eps), 'rs', 'MarkerSize', 8, 'LineWidth', 1.5);
grid on; xlabel('E_b/N_0 (dB)'); ylabel('TEB');
title('TEB de la chaine QPSK (mapping de Gray) et de la chaine binaire');
legend('Theorie : Q(\surd(2E_b/N_0)), chaine binaire et QPSK', 'Simulation QPSK (Gray)', ...
       'Location', 'southwest');
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