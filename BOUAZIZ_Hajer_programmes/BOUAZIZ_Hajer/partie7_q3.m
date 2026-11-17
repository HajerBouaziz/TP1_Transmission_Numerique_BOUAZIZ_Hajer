%% Partie 7 - Question 3 : transmission d'un texte, sans et avec code de Hamming
% Texte -> octets (UTF-8) -> bits -> bloc From Workspace -> chaine QPSK (sans codage et
% avec codage de Hamming, en parallele) -> bloc To Workspace -> bits -> octets -> texte.
% Essais a Eb/N0 = 3 dB et 6 dB.
clear; clc;
mdl = 'chaine_texte';
if ~exist([mdl '.slx'], 'file'), construire_chaine_texte; end
if ~bdIsLoaded(mdl), load_system(mdl); end

%% Parametres (identiques a la partie 5, question 6)
P = mes_parametres('BOUAZIZ Hajer');  graine = P.graine;
R = 4/7;  Tb = 7;  Tc = R * Tb;  Ts_nc = 2 * Tb;  Ts_c = 2 * Tc;  Eb = 1/2;
tabI  = [1 1 -1 -1] * sqrt(Eb);    tabQ  = [1 -1 1 -1] * sqrt(Eb);
tabIc = tabI * sqrt(R);            tabQc = tabQ * sqrt(R);
tabB1 = [0 0 1 1];                 tabB2 = [0 1 0 1];
Q = @(x) 0.5 * erfc(x / sqrt(2));

%% 1) Texte -> caracteres -> octets -> bits
if exist('texte_fr.txt', 'file')
    fid = fopen('texte_fr.txt', 'r', 'n', 'UTF-8');  txt = fread(fid, '*char')';  fclose(fid);
    txt = regexprep(txt, '\s+', ' ');             % un seul espace entre les mots
    txt = strtrim(txt(1:min(600, end)));
else
    txt = ['La theorie de l''information fixe les limites de la compression et de la ' ...
           'transmission fiable. Le codage de canal ajoute de la redondance pour corriger ' ...
           'les erreurs introduites par le bruit du canal.'];
end
octets = unicode2native(txt, 'UTF-8');               % caracteres -> octets
bits   = reshape(dec2bin(octets, 8)', 1, []) - '0';  % octets -> bits (poids fort d'abord)
nb     = numel(bits);
fprintf('Texte emis : %d caracteres, %d octets, %d bits\n', numel(txt), numel(octets), nb);
fprintf('Debut : "%s..."\n', txt(1:min(80, end)));
fprintf('Premier caractere ''%c'' -> octet %d -> bits %s\n\n', txt(1), octets(1), ...
        num2str(bits(1:8), '%d'));

%% 2) Alignement des mots de Hamming (bits aleatoires, sans bruit)
rng(1);  essai = double(rand(1, 800) < 0.5);
entree = [(0:numel(essai)-1)' * Tb, essai'];
sigma2v = 0;  Tsim = (numel(essai) + 200) * Tb;
nerr_w = inf(1, 7);
for w = 1:7
    dw = w;
    out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    nerr_w(w) = aligner(essai, out.b_c(:)', 60);
end
[~, dw] = min(nerr_w);
fprintf('Alignement des mots de 7 bits : %d (erreurs sans bruit : %d)\n\n', dw, nerr_w(dw));

%% 3) Transmission du texte
src = [bits, zeros(1, 8)];                           % 8 bits de garde (2 mots de Hamming)
entree = [(0:numel(src)-1)' * Tb, src'];
Tsim = (numel(src) + 200) * Tb;                      % temps pour vider la chaine
for EbN0_dB = [3 6]
    e = 10^(EbN0_dB / 10);  sigma2v = Eb / e / 2;
    out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    [~, D1] = aligner(bits, out.b_nc(:)', 20);
    [~, D2] = aligner(bits, out.b_c(:)', 60);
    br = {out.b_nc(D1 + (1:nb))', out.b_c(D2 + (1:nb))'};
    noms = {'SANS codage', 'AVEC code de Hamming'};
    fprintf('==================== Eb/N0 = %d dB ====================\n', EbN0_dB);
    for m = 1:2
        bm = round(br{m});
        nerr = sum(bm ~= bits);
        oct_r = uint8(bin2dec(char(reshape(bm, 8, [])' + '0')))';    % bits -> octets
        oct_faux = sum(oct_r ~= octets);
        txt_r = native2unicode(oct_r, 'UTF-8');                       % octets -> texte
        fprintf('\n--- %s : %d bits faux sur %d (TEB = %.2e), %d octets faux sur %d (%.1f %%)\n', ...
                noms{m}, nerr, nb, nerr/nb, oct_faux, numel(octets), 100*oct_faux/numel(octets));
        fprintf('%s\n', txt_r);
    end
    fprintf('\nTEB theoriques : sans codage %.2e, avec codage %.2e\n\n', ...
            Q(sqrt(2*e)), pb_exact(Q(sqrt(2*R*e))));
end

%% ======================= Fonctions locales =======================
function [nerr, D] = aligner(be, br, Dmax)
% Retard D (0 a Dmax bits) qui minimise le nombre d'erreurs entre be et br.
    n = numel(be);  nerr = inf;  D = 0;
    for d = 0:Dmax
        if d + n > numel(br), break; end
        e = sum(be ~= round(br(d + (1:n))));
        if e < nerr, nerr = e;  D = d; end
    end
end

function Pb = pb_exact(p)
% TEB exact apres decodage de Hamming par syndrome (enumeration des 128 motifs).
    [~, H] = matrices_hamming();
    E = dec2bin(0:127, 7) - '0';  w = sum(E, 2);  S = mod(E * H', 2);
    for k = 1:128
        if any(S(k, :)), j = find(all(H == S(k, :)', 1)); E(k, j) = 1 - E(k, j); end
    end
    nfaux = sum(E(:, 1:4), 2) / 4;  Pb = 0;
    for k = 1:128, Pb = Pb + nfaux(k) * p^w(k) * (1 - p)^(7 - w(k)); end
end