%% Partie 5 - Question 2 : validation du modulateur et du demodulateur QPSK (mapping de Gray)
% 1) sans bruit : constellation emise, table couple de bits -> symbole, aucune erreur ;
% 2) avec bruit (Eb/N0 = 4 dB) : TEB simule compare a Q(sqrt(2 Eb/N0)).
clear; clc;
mdl = 'chaine_qpsk';
if ~exist([mdl '.slx'], 'file'), construire_chaine_qpsk; end
if ~bdIsLoaded(mdl), load_system(mdl); end

%% Parametres
P = mes_parametres('BOUAZIZ Hajer');  graine = P.graine;
Tb = 1;  Ts = 2 * Tb;  p1 = 0.5;
Es = 1;  Eb = Es / 2;                         % 2 bits par symbole
% Mapping de Gray : n = 2 b1 + b2 -> (I, Q) ;  00 -> k=1, 01 -> k=7, 10 -> k=3, 11 -> k=5
tabI  = [ 1  1 -1 -1] / sqrt(2);
tabQ  = [ 1 -1  1 -1] / sqrt(2);
% Demapping : quadrant q = 2 sI + sQ (sI = 1 si I < 0, sQ = 1 si Q < 0) -> (b1, b2)
tabB1 = [0 0 1 1];
tabB2 = [0 1 0 1];
Q = @(x) 0.5 * erfc(x / sqrt(2));

%% 1) Sans bruit
sigma2v = 0;  Nbits = 2000;  Tsim = (Nbits - 1) * Tb;
out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
be = out.b_emis(:);  s = out.s_emis(:);

fprintf('Mapping de Gray observe (couple de bits -> symbole emis) :\n');
vus = zeros(0, 2);
for k = 2:numel(s)
    couple = be([2*k - 2, 2*k - 1])';         % les deux bits groupes dans le symbole k
    if isempty(vus) || ~ismember(couple, vus, 'rows')
        vus(end+1, :) = couple;               %#ok<SAGROW>
        kk = mod(round(angle(s(k)) / (pi/4)), 8);
        fprintf('  %d%d -> s = %+.4f %+.4fj  (|s| = %.3f, k = %d)\n', couple, ...
                real(s(k)), imag(s(k)), abs(s(k)), kk);
    end
    if size(vus, 1) == 4, break; end
end
fprintf('Energie moyenne par symbole Es = %.3f, donc Eb = Es/2 = %.3f\n', mean(abs(s(2:end)).^2), Eb);
[ne, n] = compter_erreurs(be, out.b_recu(:), 6);
fprintf('Sans bruit : %d erreur(s) sur %d bits\n\n', ne, n);

%% 2) Avec bruit
EbN0_dB = 4;  e = 10^(EbN0_dB / 10);
N0 = Eb / e;  sigma2v = N0 / 2;               % variance N0/2 sur chaque voie
Nbits = 2e5;  Tsim = (Nbits - 1) * Tb;
out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
[ne, n] = compter_erreurs(out.b_emis(:), out.b_recu(:), 6);
teb = ne / n;  ic = 1.96 * sqrt(teb * (1 - teb) / n);
fprintf('Eb/N0 = %d dB : N0 = %.4f, variance par voie N0/2 = %.4f\n', EbN0_dB, N0, sigma2v);
fprintf('TEB simule = %.5f  (IC 95 %% : [%.5f ; %.5f], %d erreurs sur %d bits)\n', ...
        teb, teb - ic, teb + ic, ne, n);
fprintf('TEB theorique Q(sqrt(2 Eb/N0)) = %.5f\n', Q(sqrt(2 * e)));

%% ======================= Fonction locale =======================
function [nerr, n] = compter_erreurs(be, br, Dmax)
% Compense le retard (0 a Dmax bits) en retenant celui qui minimise les erreurs.
    N = min(numel(be), numel(br));
    idx = 10:N - Dmax;
    nerr = inf;
    for D = 0:Dmax
        nerr = min(nerr, sum(be(idx) ~= br(idx + D)));
    end
    n = numel(idx);
end