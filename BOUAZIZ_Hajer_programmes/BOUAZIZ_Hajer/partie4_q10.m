%% Partie 4 - Question 10 : TEB avec et sans codage de Hamming, Eb/N0 de 0 a 9 dB
% Simulation pilotee par script du modele chaine_codee.slx (deux chaines en parallele).
% Courbes theoriques :
%   sans codage : Q(sqrt(2 Eb/N0))
%   avec codage : Pb ~ somme_{j=2..7} (j/7) C(7,j) p^j (1-p)^(7-j),  p = Q(sqrt(2 (4/7) Eb/N0))
%                 et valeur exacte (enumeration des 128 motifs d'erreur, decodage par syndrome)
% Limites de Shannon : (2^(2R)-1)/(2R) pour R = 4/7 (0,24 dB) et ln 2 (-1,59 dB).
clear; close all; clc;
mdl = 'chaine_codee';
if ~exist([mdl '.slx'], 'file'), error('Lancer d''abord construire_chaine_codee'); end
if ~bdIsLoaded(mdl), load_system(mdl); end

%% Parametres
P      = mes_parametres('BOUAZIZ Hajer');
L      = P.L;   A = P.A;   graine = P.graine;
p1     = 0.5;   seuil = 0;            % bits equiprobables, seuil nul
R      = 4/7;                         % rendement du code
Tb     = 7;                           % duree d'un bit d'information (choisie pour des temps exacts)
Tc     = R * Tb;                      % duree d'un bit code : 4 Tb / 7
Te_nc  = Tb / L;                      % periode d'echantillonnage sans codage
Te_c   = Tc / L;                      % periode d'echantillonnage avec codage (L echantillons par bit code)
Ac     = A * sqrt(R);                 % amplitude d'un bit code
EbN0_dB = 0:9;
Q = @(x) 0.5 * erfc(x / sqrt(2));

%% 1) Calages, sans bruit
sigma2 = 0;  Nbits = 400;  Tsim = (Nbits - 1) * Tb;  dw = 1;
eNC = inf(1, L);  eC = inf(1, L);
for d = 1:L
    d_nc = d;  d_c = d;
    out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    eNC(d) = max(abs(abs(out.z_nc(20:end)) - A));
    eC(d)  = max(abs(abs(out.z_c(20:end)) - Ac));
end
[~, d_nc] = min(eNC);  [~, d_c] = min(eC);
nerr_w = inf(1, 7);
for w = 1:7                            % alignement des mots de 7 bits recus
    dw = w;
    out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    nerr_w(w) = compter_erreurs(out.b_emis(:), out.b_c(:), 40);
end
[~, dw] = min(nerr_w);
fprintf('Calages : integrateur sans codage %d, avec codage %d, alignement des mots %d\n', d_nc, d_c, dw);
fprintf('Sans bruit, erreurs avec codage = %d (doit etre 0)\n\n', nerr_w(dw));

%% 2) Boucle sur Eb/N0
teb_nc = zeros(size(EbN0_dB));  teb_c = teb_nc;  ne_nc = teb_nc;  ne_c = teb_nc;  nb = teb_nc;
fprintf('(simulation de quelques minutes : une ligne par valeur de Eb/N0)\n');
fprintf('%6s %9s | %10s %10s | %10s %10s %10s %10s\n', 'Eb/N0', 'Nbits', 'TEB sans', 'Theorie', ...
        'TEB avec', 'Exact', 'Approx.', 'p (code)');
for i = 1:numel(EbN0_dB)
    e      = 10^(EbN0_dB(i) / 10);
    N0     = A^2 * Tb / e;
    sigma2 = N0 * L / (2 * Tb);       % meme variance par echantillon dans les deux chaines
    p      = Q(sqrt(2 * R * e));
    Pb_th  = pb_hamming(p);
    Nbits  = 4 * ceil(min(max(5e4, 200 / min(pb_exact(p), Q(sqrt(2*e)))), 1e6) / 4);
    Tsim   = (Nbits - 1) * Tb;

    out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    [ne_nc(i), n1] = compter_erreurs(out.b_emis(:), out.b_nc(:), 5);
    [ne_c(i),  n2] = compter_erreurs(out.b_emis(:), out.b_c(:), 40);
    teb_nc(i) = ne_nc(i) / n1;   teb_c(i) = ne_c(i) / n2;   nb(i) = n2;
    fprintf('%4d dB %9d | %10.2e %10.2e | %10.2e %10.2e %10.2e %10.2e\n', EbN0_dB(i), n2, ...
            teb_nc(i), Q(sqrt(2*e)), teb_c(i), pb_exact(p), Pb_th, p);
end

%% 3) Courbes
x  = linspace(-2, 10, 400);  ex = 10.^(x/10);
pc = Q(sqrt(2 * R * ex));
lim_R   = 10*log10((2^(2*R) - 1) / (2*R));
lim_abs = 10*log10(log(2));
figure('Name', 'TEB avec et sans codage');
semilogy(x, Q(sqrt(2*ex)), 'b-', 'LineWidth', 1.5); hold on;
semilogy(EbN0_dB, teb_nc, 'bo', 'MarkerSize', 7, 'LineWidth', 1.5);
semilogy(x, pb_exact(pc), 'r-', 'LineWidth', 1.5);
semilogy(x, pb_hamming(pc), 'r--', 'LineWidth', 1.2);
semilogy(EbN0_dB, max(teb_c, eps), 'rs', 'MarkerSize', 7, 'LineWidth', 1.5);
xline(lim_R, 'k--', sprintf('Shannon R = 4/7 : %.2f dB', lim_R), 'LineWidth', 1.2, ...
      'LabelVerticalAlignment', 'bottom');
xline(lim_abs, 'k:', sprintf('Limite absolue ln 2 : %.2f dB', lim_abs), 'LineWidth', 1.2, ...
      'LabelVerticalAlignment', 'bottom');
yline(1e-4, 'g:', 'TEB = 10^{-4}');
grid on; xlabel('E_b/N_0 (dB)'); ylabel('TEB');
title(sprintf('Chaine de base avec et sans code de Hamming (7,4), L = %d', L));
legend('Theorie sans codage', 'Simulation sans codage', 'Theorie avec codage (exacte)', ...
       'Approximation de l''enonce (question 8)', 'Simulation avec codage', 'Location', 'southwest');
xlim([-2 10]);  ylim([1e-6 0.5]);

%% 4) Points utiles pour la question 11
f_nc = @(xdb) Q(sqrt(2*10.^(xdb/10)));
f_c  = @(xdb) pb_exact(Q(sqrt(2*R*10.^(xdb/10))));       % courbe exacte
f_ca = @(xdb) pb_hamming(Q(sqrt(2*R*10.^(xdb/10))));     % approximation
x_croise = fzero(@(xdb) log(f_c(xdb)) - log(f_nc(xdb)), [0 9]);
x_nc4 = fzero(@(xdb) log(f_nc(xdb)) - log(1e-4), [0 15]);
x_c4  = fzero(@(xdb) log(f_c(xdb))  - log(1e-4), [0 15]);
x_croise_a = fzero(@(xdb) log(f_ca(xdb)) - log(f_nc(xdb)), [0 9]);
x_c4a = fzero(@(xdb) log(f_ca(xdb)) - log(1e-4), [0 15]);
fprintf('\nCodage avantageux au-dela de %.2f dB (exact) / %.2f dB (approximation)\n', x_croise, x_croise_a);
fprintf('TEB = 1e-4 : %.2f dB sans codage, %.2f dB avec codage (exact) -> gain de codage %.2f dB\n', ...
        x_nc4, x_c4, x_nc4 - x_c4);
fprintf('             (avec l''approximation : %.2f dB -> gain %.2f dB)\n', x_c4a, x_nc4 - x_c4a);
fprintf('Ecart a la limite de Shannon (R = 4/7, %.2f dB) : %.2f dB\n', lim_R, x_c4 - lim_R);

%% ======================= Fonctions locales =======================
function Pb = pb_hamming(p)
% Approximation de la probabilite d'erreur par bit apres correction (question 8).
    Pb = zeros(size(p));
    for j = 2:7
        Pb = Pb + j/7 * nchoosek(7, j) * p.^j .* (1 - p).^(7 - j);
    end
end

function Pb = pb_exact(p)
% TEB exact sur les bits d'information apres decodage par syndrome :
% on enumere les 128 motifs d'erreur e, on decode, on compte les bits faux.
    [~, H] = matrices_hamming();
    E = dec2bin(0:127, 7) - '0';                 % les 128 motifs d'erreur
    S = mod(E * H', 2);                          % leurs syndromes
    for k = 1:128
        if any(S(k, :))
            j = find(all(H == S(k, :)', 1));     % position designee par le syndrome
            E(k, j) = 1 - E(k, j);               % correction
        end
    end
    nfaux = sum(E(:, 1:4), 2) / 4;               % proportion de bits d'information faux
    w = sum(dec2bin(0:127, 7) - '0', 2);         % poids des motifs avant correction
    Pb = zeros(size(p));
    for k = 1:128
        Pb = Pb + nfaux(k) * p.^w(k) .* (1 - p).^(7 - w(k));
    end
end

function [nerr, n] = compter_erreurs(be, br, Dmax)
% Compense le retard de la chaine (0 a Dmax bits) en retenant celui qui minimise
% le nombre d'erreurs, puis compte les erreurs (on ignore les 30 premiers bits).
    N = min(numel(be), numel(br));
    idx = 30:N - Dmax;
    nerr = inf;
    for D = 0:Dmax
        nerr = min(nerr, sum(be(idx) ~= br(idx + D)));
    end
    n = numel(idx);
end