%% Partie 5 - Question 3 : constellations recues pour Eb/N0 = 0, 5 et 10 dB
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
Nbits = 4000;  Tsim = (Nbits - 1) * Tb;     % 2000 symboles par constellation

EbN0_dB = [0 5 10];
ideal = [1+1j, -1+1j, -1-1j, 1-1j] / sqrt(2);
etiq  = {'00', '10', '11', '01'};
figure('Name', 'Constellations recues', 'Position', [100 100 1200 420]);
fprintf('%8s %12s %14s %14s %12s\n', 'Eb/N0', 'sigma/voie', 'Symb. faux', 'TEB', 'Theorie');
for i = 1:3
    e = 10^(EbN0_dB(i) / 10);
    N0 = Eb / e;  sigma2v = N0 / 2;
    out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    r = out.s_recu(2:end);  s = out.s_emis(2:end);

    % symboles faux : le point recu n'est pas dans le quadrant du symbole emis
    faux = (sign(real(r)) ~= sign(real(s))) | (sign(imag(r)) ~= sign(imag(s)));
    err  = [sign(real(r)) ~= sign(real(s)); sign(imag(r)) ~= sign(imag(s))];
    teb  = mean(err(:));                     % un bit par voie (mapping de Gray)
    fprintf('%6d dB %12.3f %13.2f %% %14.4f %12.4f\n', EbN0_dB(i), sqrt(sigma2v), ...
            100 * mean(faux), teb, Q(sqrt(2 * e)));

    subplot(1, 3, i);
    plot(real(r), imag(r), '.', 'MarkerSize', 4); hold on;
    plot(real(ideal), imag(ideal), 'r+', 'MarkerSize', 14, 'LineWidth', 2);
    text(real(ideal) * 1.25, imag(ideal) * 1.25, etiq, 'Color', 'r', 'FontWeight', 'bold', ...
         'HorizontalAlignment', 'center');
    xline(0, 'k-');  yline(0, 'k-');
    axis equal;  grid on;  xlim([-2.2 2.2]);  ylim([-2.2 2.2]);
    xlabel('Voie I');  ylabel('Voie Q');
    title(sprintf('E_b/N_0 = %d dB (\\sigma = %.2f par voie)', EbN0_dB(i), sqrt(sigma2v)));
end
sgtitle('Constellations QPSK recues (mapping de Gray, 2000 symboles)');