%% Partie 5 - Question 6 : QPSK dans la chaine avec codage de Hamming
% TEB de la chaine QPSK sans codage et avec codage, Eb/N0 = 0..9 dB,
% compares aux resultats theoriques de la partie 4 (chaine binaire).
clear; close all; clc;
mdl = 'chaine_qpsk_codee';
if ~exist([mdl '.slx'], 'file'), error('Lancer d''abord construire_chaine_qpsk_codee'); end
if ~bdIsLoaded(mdl), load_system(mdl); end

%% Parametres
P = mes_parametres('BOUAZIZ Hajer');  graine = P.graine;
p1 = 0.5;  R = 4/7;
Tb = 7;                       % duree d'un bit d'information (temps exacts)
Tc = R * Tb;                  % bit code : 4 Tb / 7 = 4
Ts_nc = 2 * Tb;               % symbole QPSK sans codage : 2 Tb
Ts_c  = 2 * Tc;               % symbole QPSK avec codage : 2 Tc = 8 Tb / 7
Eb = 1/2;                     % energie par bit d'information (Es = 1 sans codage)
% Mapping de Gray : amplitude sqrt(Eb) par voie sans codage, sqrt(Ec) = sqrt(4/7 Eb) avec codage
tabI  = [1 1 -1 -1] * sqrt(Eb);    tabQ  = [1 -1 1 -1] * sqrt(Eb);
tabIc = tabI * sqrt(R);            tabQc = tabQ * sqrt(R);
tabB1 = [0 0 1 1];                 tabB2 = [0 1 0 1];
Q = @(x) 0.5 * erfc(x / sqrt(2));
EbN0_dB = 0:9;

fprintf('Symboles : Ts = %g sans codage (2 Tb), Ts = %g avec codage (2 Tc = 8 Tb/7)\n', Ts_nc, Ts_c);
fprintf('Energie par symbole : Es = %.3f sans codage, %.3f avec codage (8/7 Eb)\n\n', ...
        sum(tabI(1)^2 + tabQ(1)^2), sum(tabIc(1)^2 + tabQc(1)^2));

%% 1) Alignement des mots de 7 bits, sans bruit
sigma2v = 0;  Nbits = 560;  Tsim = (Nbits - 1) * Tb;
nerr_w = inf(1, 7);
for w = 1:7
    dw = w;
    out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    nerr_w(w) = compter_erreurs(out.b_emis(:), out.b_c(:), 50);
end
[~, dw] = min(nerr_w);
out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
fprintf('Alignement des mots : %d. Sans bruit : %d erreur(s) sans codage, %d avec codage\n\n', dw, ...
        compter_erreurs(out.b_emis(:), out.b_nc(:), 10), compter_erreurs(out.b_emis(:), out.b_c(:), 50));

%% 2) Boucle sur Eb/N0
teb_nc = zeros(size(EbN0_dB));  teb_c = teb_nc;
fprintf('%6s %9s | %10s %10s | %10s %10s\n', 'Eb/N0', 'Nbits', 'QPSK sans', 'Theorie', 'QPSK avec', 'Theorie');
for i = 1:numel(EbN0_dB)
    e = 10^(EbN0_dB(i) / 10);
    N0 = Eb / e;  sigma2v = N0 / 2;            % variance N0/2 par voie
    p  = Q(sqrt(2 * R * e));
    Nbits = 8 * ceil(min(max(5e4, 200 / min(pb_exact(p), Q(sqrt(2*e)))), 1e6) / 8);
    Tsim  = (Nbits - 1) * Tb;
    out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    [n1e, n1] = compter_erreurs(out.b_emis(:), out.b_nc(:), 10);
    [n2e, n2] = compter_erreurs(out.b_emis(:), out.b_c(:), 50);
    teb_nc(i) = n1e / n1;  teb_c(i) = n2e / n2;
    fprintf('%4d dB %9d | %10.2e %10.2e | %10.2e %10.2e\n', EbN0_dB(i), n2, ...
            teb_nc(i), Q(sqrt(2*e)), teb_c(i), pb_exact(p));
end

%% 3) Courbes
x = linspace(0, 10, 300);  ex = 10.^(x/10);
figure('Name', 'QPSK avec et sans codage');
semilogy(x, Q(sqrt(2*ex)), 'b-', 'LineWidth', 1.5); hold on;
semilogy(EbN0_dB, max(teb_nc, eps), 'bo', 'MarkerSize', 7, 'LineWidth', 1.5);
semilogy(x, pb_exact(Q(sqrt(2*R*ex))), 'r-', 'LineWidth', 1.5);
semilogy(EbN0_dB, max(teb_c, eps), 'rs', 'MarkerSize', 7, 'LineWidth', 1.5);
yline(1e-4, 'g:', 'TEB = 10^{-4}');
grid on; xlabel('E_b/N_0 (dB)'); ylabel('TEB');
title('Chaine QPSK (Gray) avec et sans code de Hamming (7,4)');
legend('Theorie sans codage (= partie 4)', 'Simulation QPSK sans codage', ...
       'Theorie avec codage (= partie 4)', 'Simulation QPSK avec codage', 'Location', 'southwest');
ylim([1e-6 0.5]);

%% ======================= Fonctions locales =======================
function Pb = pb_exact(p)
% TEB exact apres decodage de Hamming par syndrome (enumeration des 128 motifs).
    [~, H] = matrices_hamming();
    E = dec2bin(0:127, 7) - '0';
    w = sum(E, 2);
    S = mod(E * H', 2);
    for k = 1:128
        if any(S(k, :))
            j = find(all(H == S(k, :)', 1));
            E(k, j) = 1 - E(k, j);
        end
    end
    nfaux = sum(E(:, 1:4), 2) / 4;
    Pb = zeros(size(p));
    for k = 1:128
        Pb = Pb + nfaux(k) * p.^w(k) .* (1 - p).^(7 - w(k));
    end
end

function [nerr, n] = compter_erreurs(be, br, Dmax)
    N = min(numel(be), numel(br));
    idx = 30:N - Dmax;
    nerr = inf;
    for D = 0:Dmax
        nerr = min(nerr, sum(be(idx) ~= br(idx + D)));
    end
    n = numel(idx);
end