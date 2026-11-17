%% Partie 2.4 - Sources avec memoire et compresseurs reels
% Question 8 : comparaison, en bits par caractere, du code de longueur fixe,
%              de l'entropie d'ordre 0, du code de Huffman, de H(X1X2)/2
%              et des compresseurs (gzip, et bzip2 / 7z si 7-Zip est installe),
%              sur le texte complet puis sur ses 5000 premiers caracteres.
% Question 9 : proportion de 1 et entropie des paires de bits en sortie
%              du codeur de Huffman (comparaison avec les octets UTF-8 bruts).
clear; close all; clc;

%% Parametres
fichier = 'texte_fr.txt';      % <-- remplacer par ton roman (>= 100 000 caracteres, UTF-8)
Ncourt  = 5000;                % longueur de l'extrait
exe7z   = 'C:\Program Files\7-Zip\7z.exe';   % chemin de 7-Zip (optionnel)

%% Lecture du texte
txt = lire_texte(fichier);
n   = numel(txt);
fprintf('Texte : %s  (%d caracteres)\n', fichier, n);
if n < 1e5
    warning(['Texte court (%d caracteres) : l''enonce demande au moins 100 000 ', ...
             'caracteres. Resultats utilisables pour tester seulement.'], n);
end
if Ncourt >= n                         % le texte de test est plus court que l'extrait
    Ncourt = floor(n / 2);
    fprintf('Extrait ramene a %d caracteres (texte trop court).\n', Ncourt);
end
fprintf('\n');

%% Question 8 : analyse du texte complet et de l'extrait
R(1) = analyser_texte(txt,           'Texte complet', exe7z);
R(2) = analyser_texte(txt(1:Ncourt), sprintf('%d premiers car.', Ncourt), exe7z);

noms = {'Fichier brut UTF-8', 'Code longueur fixe', 'Entropie ordre 0 H0', ...
        'Huffman (L moyen)', 'H(X1X2)/2', 'gzip (LZ77+Huffman)', ...
        'bzip2 (BWT)', '7z (LZMA2)'};
champs = {'Lbrut', 'Lfixe', 'H0', 'Lhuff', 'H2', 'Lgzip', 'Lbzip2', 'L7z'};

fprintf('%-22s %18s %18s\n', 'Bits par caractere', R(1).nom, R(2).nom);
for i = 1:numel(champs)
    fprintf('%-22s', noms{i});
    for j = 1:2
        v = R(j).(champs{i});
        if isnan(v), fprintf('%18s', 'n.d.'); else, fprintf('%18.3f', v); end
    end
    fprintf('\n');
end
fprintf('\nTaille de l''alphabet        : %d (complet), %d (extrait)\n', R(1).M, R(2).M);
fprintf('Nombre de paires distinctes : %d (complet), %d (extrait)\n', ...
        R(1).nPaires, R(2).nPaires);
fprintf('Efficacite Huffman H0/L     : %.2f %% (complet), %.2f %% (extrait)\n', ...
        100*R(1).H0/R(1).Lhuff, 100*R(2).H0/R(2).Lhuff);
fprintf('Taux de compression gzip    : %.2f (complet), %.2f (extrait)\n\n', ...
        R(1).Lbrut/R(1).Lgzip, R(2).Lbrut/R(2).Lgzip);

% --- Figure 1 : comparaison des debits en bits/caractere
vals = zeros(numel(champs), 2);
for i = 1:numel(champs)
    vals(i, :) = [R(1).(champs{i}), R(2).(champs{i})];
end
garde = ~all(isnan(vals), 2);          % retire les compresseurs non disponibles
figure('Name', 'Comparaison des codages');
bar(categorical(noms(garde), noms(garde)), vals(garde, :));
grid on; ylabel('Bits par caractere');
title('Codage de source du texte : bits par caractere');
legend(R(1).nom, R(2).nom, 'Location', 'northeast');

%% Question 9 : statistiques des bits en sortie du codeur de Huffman
bHuff  = R(1).flux == '1';                             % sortie de Huffman (texte complet)
octets = unicode2native(txt, 'UTF-8');                 % texte brut, 8 bits par octet
bBrut  = reshape(dec2bin(octets, 8)', 1, []) == '1';

[p1H, HpH, PpH] = stats_bits(bHuff);
[p1B, HpB, PpB] = stats_bits(bBrut);

fprintf('Question 9 : statistiques des bits\n');
fprintf('%-28s %14s %14s\n', '', 'Sortie Huffman', 'Octets bruts');
fprintf('%-28s %14d %14d\n',     'Nombre de bits',            numel(bHuff), numel(bBrut));
fprintf('%-28s %14.4f %14.4f\n', 'Proportion de 1',           p1H, p1B);
fprintf('%-28s %14.4f %14.4f\n', 'H(paires de bits)/2 (bit)', HpH, HpB);
fprintf('%-28s %14.4f %14.4f\n', 'H(proportion de 1) (bit)',  hb(p1H), hb(p1B));

% --- Figure 2 : probabilite des paires de bits
figure('Name', 'Paires de bits');
bar(categorical({'00','01','10','11'}), [PpH(:), PpB(:)]); hold on;
yline(0.25, 'k--', 'Equiprobable (1/4)', 'LineWidth', 1.2);
grid on; ylabel('Probabilite empirique');
title('Probabilite des paires de bits');
legend('Sortie du codeur de Huffman', 'Octets UTF-8 bruts', 'Location', 'northwest');

%% ======================= Fonctions locales =======================
function txt = lire_texte(fichier)
% Lit un fichier texte UTF-8 et renvoie une ligne de caracteres.
    fid = fopen(fichier, 'r', 'n', 'UTF-8');
    if fid < 0
        error(['Impossible d''ouvrir "%s". Verifier le nom (dir *.txt) ', ...
               'et le dossier courant (pwd).'], fichier);
    end
    txt = fread(fid, '*char')';
    fclose(fid);
    if ~isempty(txt) && txt(1) == char(65279)   % retire l'eventuel BOM
        txt = txt(2:end);
    end
end

function H = entropie_empirique(seq)
% Entropie empirique (bits/symbole) d'une sequence de symboles (char ou nombres).
    [~, ~, ic] = unique(seq(:));
    p = accumarray(ic, 1) / numel(ic);
    H = -sum(p .* log2(p));
end

function R = analyser_texte(txt, nom, exe7z)
% Calcule les differents debits (bits/caractere) pour un texte.
    R.nom = nom;
    n = numel(txt);

    % --- Source sans memoire : alphabet, entropie d'ordre 0, Huffman
    [symb, ~, ic] = unique(txt(:));
    R.M     = numel(symb);
    p       = accumarray(ic, 1) / n;
    R.Lfixe = ceil(log2(R.M));
    R.H0    = entropie_empirique(txt);
    [codes, len] = huffman_code(p);
    R.Lhuff = sum(p .* len);
    R.flux  = [codes{ic}];                       % texte code par Huffman

    % --- Paires de caracteres consecutifs (fenetre glissante)
    v = double(txt(:));
    paires    = v(1:end-1) * 65536 + v(2:end);   % un entier par paire
    R.H2      = entropie_empirique(paires) / 2;
    R.nPaires = numel(unique(paires));

    % --- Compresseurs : on ecrit le texte dans un fichier temporaire UTF-8
    f = [tempname '.txt'];
    fid = fopen(f, 'w', 'n', 'UTF-8'); fprintf(fid, '%s', txt); fclose(fid);
    R.Lbrut = 8 * taille(f) / n;

    gz = gzip(f, tempdir);
    R.Lgzip = 8 * taille(gz{1}) / n;

    R.Lbzip2 = NaN;  R.L7z = NaN;
    if exist(exe7z, 'file')
        fb = [tempname '.bz2'];
        [st1, ~] = system(sprintf('"%s" a -tbzip2 -mx=9 "%s" "%s"', exe7z, fb, f));
        if st1 == 0, R.Lbzip2 = 8 * taille(fb) / n; end
        f7 = [tempname '.7z'];
        [st2, ~] = system(sprintf('"%s" a -t7z -m0=lzma2 -mx=9 "%s" "%s"', exe7z, f7, f));
        if st2 == 0, R.L7z = 8 * taille(f7) / n; end
    end
end

function o = taille(f)
% Taille d'un fichier en octets.
    d = dir(f);  o = d.bytes;
end

function [p1, Hpaire, Ppaires] = stats_bits(b)
% Proportion de 1, entropie des paires de bits (par bit) et probabilites
% des paires 00, 01, 10, 11 (paires disjointes : bits 1-2, 3-4, ...).
    p1 = mean(b);
    m  = floor(numel(b) / 2);
    q  = 2 * b(1:2:2*m) + b(2:2:2*m);            % 0..3 pour 00, 01, 10, 11
    Ppaires = accumarray(q(:) + 1, 1, [4 1]) / m;
    pp = Ppaires(Ppaires > 0);
    Hpaire = -sum(pp .* log2(pp)) / 2;
end

function h = hb(p)
% Entropie binaire H(p).
    if p <= 0 || p >= 1, h = 0; else, h = -p*log2(p) - (1-p)*log2(1-p); end
end

function [codes, len] = huffman_code(p)
% Construit un code de Huffman binaire pour les probabilites p.
% (meme fonction que dans extension_source_huffman.m)
    n = numel(p);
    codes = repmat({''}, n, 1);
    if n == 1
        codes{1} = '0'; len = 1; return;
    end
    probs  = p(:)';
    groups = num2cell(1:n);
    while numel(probs) > 1
        [probs, ord] = sort(probs, 'ascend');
        groups = groups(ord);
        g0 = groups{1};  g1 = groups{2};
        for i = g0, codes{i} = ['0' codes{i}]; end
        for i = g1, codes{i} = ['1' codes{i}]; end
        probs  = [probs(1) + probs(2), probs(3:end)];
        groups = [{[g0 g1]}, groups(3:end)];
    end
    len = cellfun(@length, codes);
end