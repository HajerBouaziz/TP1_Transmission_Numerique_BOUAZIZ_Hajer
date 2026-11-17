%% Partie 2.5 - Complement : codage de Lempel-Ziv (LZ78)
% Question 10 : codeur et decodeur LZ78, validation sur l'exemple de l'enonce.
% Question 11 : bits par symbole sur le texte (complet et extrait), puis sur
%               la source binaire de probabilite p1,ext pour des messages de
%               1e3 a 1e6 bits, compares a l'entropie de la source.
%
% Cout du i-eme couple : ceil(log2(i)) bits pour l'indice
%                      + ceil(log2(|A|)) bits pour le symbole.
clear; close all; clc;

%% Parametres
P       = mes_parametres('BOUAZIZ Hajer');   % <-- ton nom, comme sur la liste d'appel
p1ext   = P.p1_ext;
graine  = P.graine;
fichier = 'texte_fr.txt';      % texte utilise dans les parties 2.2 et 2.4
Ncourt  = 5000;                % longueur de l'extrait
Nmax    = 1e6;                 % longueur maximale du message binaire
Ns      = round(logspace(3, 6, 13));   % longueurs testees : 1e3 ... 1e6

%% ===================== Question 10 : validation =====================
ex = 'ABAABABAABAB';
[I, S, alph] = lz78_encode(ex);
fprintf('Question 10 : exemple de l''enonce\n');
fprintf('Message : %s\n', ex);
fprintf('Couples : ');
for i = 1:numel(I), fprintf('(%d,%c) ', I(i), alph(S(i))); end
fprintf('\nPhrases : %s\n', strjoin(lz78_phrases(I, S, alph), ' | '));

% Comparaison avec le resultat attendu : (0,A)(0,B)(1,A)(2,A)(4,A)(4,B)
assert(isequal(I, [0 0 1 2 4 4]) && isequal(alph(S), 'ABAAAB'), ...
       'Codeur LZ78 : resultat different de l''enonce');
dec = lz78_decode(I, S, alph);
assert(isequal(dec, ex), 'Decodeur LZ78 : message mal restitue');
fprintf('Codeur et decodeur valides (message restitue : %s)\n', dec);
fprintf('Cout : %d bits pour %d symboles\n\n', lz78_cout(I, numel(alph)), numel(ex));

%% ===================== Question 11 : texte =====================
txt = lire_texte(fichier);
n   = numel(txt);
if Ncourt >= n
    Ncourt = floor(n / 2);
    fprintf('Texte de %d caracteres : extrait ramene a %d caracteres.\n', n, Ncourt);
end

textes = {txt, txt(1:Ncourt)};
nomsT  = {sprintf('Texte complet (%d car.)', n), sprintf('Extrait (%d car.)', Ncourt)};
fprintf('Question 11 : texte %s\n', fichier);
fprintf('%-28s %8s %8s %10s %10s %10s\n', '', '|A|', 'Phrases', 'H0', 'LZ78', 'Fixe');
for j = 1:2
    t = textes{j};
    [I, S, alph] = lz78_encode(t);
    assert(isequal(lz78_decode(I, S, alph), t), 'Decodage LZ78 du texte incorrect');
    M   = numel(alph);
    bps = lz78_cout(I, M) / numel(t);
    fprintf('%-28s %8d %8d %10.3f %10.3f %10d\n', nomsT{j}, M, numel(I), ...
            entropie_empirique(t), bps, ceil(log2(M)));
end
fprintf('(en bits par caractere ; texte restitue sans erreur)\n\n');

%% ===================== Question 11 : source binaire =====================
H = -p1ext*log2(p1ext) - (1-p1ext)*log2(1-p1ext);
rng(graine);
b = double(rand(1, Nmax) < p1ext);     % un seul tirage, on prend des prefixes

bpsB   = zeros(size(Ns));
nPhr   = zeros(size(Ns));
fprintf('Source binaire : p1,ext = %.2f, H = %.4f bit/bit\n', p1ext, H);
fprintf('%10s %10s %12s %12s\n', 'N (bits)', 'Phrases', 'LZ78 (b/b)', 'LZ78 / H');
for j = 1:numel(Ns)
    x = b(1:Ns(j));
    [I, S, alph] = lz78_encode(x);
    assert(isequal(lz78_decode(I, S, alph), x), 'Decodage LZ78 binaire incorrect');
    nPhr(j) = numel(I);
    bpsB(j) = lz78_cout(I, 2) / Ns(j);          % alphabet binaire : 1 bit par symbole
    fprintf('%10d %10d %12.4f %12.3f\n', Ns(j), nPhr(j), bpsB(j), bpsB(j) / H);
end

% --- Figure : convergence de LZ78 vers l'entropie
figure('Name', 'LZ78 - source binaire');
semilogx(Ns, bpsB, 'o-', 'LineWidth', 1.5); hold on;
yline(H, 'k--', sprintf('Entropie H = %.3f', H), 'LineWidth', 1.2, ...
      'LabelHorizontalAlignment', 'left');
yline(1, 'r:', 'Sans compression (1 bit/bit)', 'LineWidth', 1.2, ...
      'LabelHorizontalAlignment', 'left');
grid on;
xlabel('Longueur du message N (bits)');
ylabel('Bits codes par bit de source');
title(sprintf('Codage LZ78 de la source binaire (p_{1,ext} = %.2f)', p1ext));
legend('LZ78', 'Location', 'northeast');
ylim([0, max(1.2, max(bpsB) * 1.1)]);

%% ======================= Fonctions locales =======================
function [I, S, alph] = lz78_encode(x)
% Codeur LZ78.
%   x    : message (vecteur de caracteres ou de nombres)
%   I    : indices des phrases connues (0 = phrase vide)
%   S    : symboles ajoutes (indices dans alph)
%   alph : alphabet du message
% Le dictionnaire est un arbre : enfants(i+1, m) = indice de la phrase
% obtenue en prolongeant la phrase i par le symbole m (0 si absente).
    [alph, ~, s] = unique(x(:)');
    s = s(:)';
    n = numel(s);  M = numel(alph);
    enfants = zeros(n + 1, M);
    I = zeros(1, n);  S = zeros(1, n);
    c = 0;      % nombre de couples emis
    D = 0;      % taille du dictionnaire
    cur = 0;    % phrase courante (0 = phrase vide)
    for t = 1:n
        m = s(t);
        nxt = enfants(cur + 1, m);
        if nxt > 0 && t < n
            cur = nxt;                    % la phrase prolongee est connue : on continue
        else
            c = c + 1;  I(c) = cur;  S(c) = m;   % on emet (phrase connue, symbole)
            if nxt == 0                   % nouvelle phrase : ajout au dictionnaire
                D = D + 1;
                enfants(cur + 1, m) = D;
            end
            cur = 0;
        end
    end
    I = I(1:c);  S = S(1:c);
end

function x = lz78_decode(I, S, alph)
% Decodeur LZ78 : reconstruit chaque phrase = phrase(I) + symbole S.
    c = numel(I);
    Ph = cell(1, c + 1);
    Ph{1} = zeros(1, 0);                  % phrase d'indice 0 : phrase vide
    for i = 1:c
        Ph{i + 1} = [Ph{I(i) + 1}, S(i)];
    end
    x = alph([Ph{2:end}]);
end

function ph = lz78_phrases(I, S, alph)
% Liste des phrases (pour l'affichage de l'exemple).
    c = numel(I);
    Ph = cell(1, c + 1);  Ph{1} = '';
    for i = 1:c, Ph{i + 1} = [Ph{I(i) + 1}, alph(S(i))]; end
    ph = Ph(2:end);
end

function nb = lz78_cout(I, M)
% Nombre de bits : ceil(log2(i)) pour l'indice du i-eme couple
%                  + ceil(log2(M)) pour le symbole.
    c  = numel(I);
    nb = sum(ceil(log2(1:c))) + c * ceil(log2(M));
end

function txt = lire_texte(fichier)
% Lit un fichier texte UTF-8 et renvoie une ligne de caracteres.
    fid = fopen(fichier, 'r', 'n', 'UTF-8');
    if fid < 0
        error('Impossible d''ouvrir "%s" (verifier dir *.txt et pwd).', fichier);
    end
    txt = fread(fid, '*char')';
    fclose(fid);
    if ~isempty(txt) && txt(1) == char(65279), txt = txt(2:end); end
end

function H = entropie_empirique(seq)
% Entropie empirique (bits/symbole) d'une sequence de symboles.
    [~, ~, ic] = unique(seq(:));
    p = accumarray(ic, 1) / numel(ic);
    H = -sum(p .* log2(p));
end