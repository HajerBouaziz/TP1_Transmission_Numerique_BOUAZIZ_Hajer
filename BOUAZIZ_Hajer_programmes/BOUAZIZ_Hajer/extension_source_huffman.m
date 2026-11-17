%% Partie 2.3 - Extension de la source binaire et codage de Huffman
% Question 7 : code de Huffman des blocs de k bits (k = 1..10),
% longueur moyenne par bit de source Lk/k, verification sur 1e5 bits,
% comparaison a l'entropie H et a la borne H + 1/k.
clear; close all; clc;

%% Parametres
p1ext = 0.1;        % <-- remplacer par TA valeur personnelle p1,ext
kmax  = 10;         % taille maximale des blocs
N     = 1e5;        % nombre de bits de source pour la verification
graine = 1;
rng(graine);

%% Entropie de la source binaire
p0ext = 1 - p1ext;
H = -p1ext*log2(p1ext) - p0ext*log2(p0ext);
fprintf('p1,ext = %.3f   ->   H = %.4f bit/bit de source\n\n', p1ext, H);

%% Source binaire (meme modele que la partie 2.1)
b = double(rand(1, N) < p1ext);
fprintf('Frequence empirique des 1 : %.4f\n\n', mean(b));

%% Boucle sur la taille des blocs
Lth  = zeros(1, kmax);   % Lk/k theorique (a partir des probabilites)
Lmes = zeros(1, kmax);   % Lk/k mesure en codant les N bits
Hk   = zeros(1, kmax);   % entropie de l'extension / k (doit valoir H)

fprintf('  k   2^k    Lk/k theo   Lk/k mesure   H+1/k\n');
for k = 1:kmax
    % --- Probabilites des 2^k blocs : p1^w (1-p1)^(k-w)
    s = (0:2^k-1)';                       % indices des blocs
    w = sum(dec2bin(s, k) == '1', 2);     % nombre de 1 dans chaque bloc
    p = p1ext.^w .* p0ext.^(k - w);       % somme = 1

    % --- Code de Huffman de l'extension d'ordre k
    [codes, len] = huffman_code(p);

    % --- Longueur moyenne theorique par bit de source
    Lth(k) = sum(p .* len) / k;
    Hk(k)  = -sum(p .* log2(p)) / k;      % verification : H(X^k) = kH

    % --- Verification : codage de N bits de source
    nb     = floor(N / k);                        % nombre de blocs complets
    blocs  = reshape(b(1:nb*k), k, nb)';          % un bloc par ligne
    idx    = blocs * 2.^(k-1:-1:0)';              % indice du bloc (MSB en tete, comme dec2bin)
    flux   = [codes{idx + 1}];                    % train binaire code
    Lmes(k) = length(flux) / (nb * k);

    fprintf('%3d  %5d    %.4f      %.4f      %.4f\n', ...
            k, 2^k, Lth(k), Lmes(k), H + 1/k);
end

% Controle : le code doit verifier H <= Lk/k < H + 1/k
assert(all(Lth >= H - 1e-12) && all(Lth < H + 1./(1:kmax)), ...
       'Borne du premier theoreme de Shannon non verifiee');
fprintf('\nH(X^k)/k = H pour tout k : ecart max = %.2e\n', max(abs(Hk - H)));

%% Trace
k = 1:kmax;
figure('Name', 'Extension de la source');
plot(k, Lth, 'o-', 'LineWidth', 1.5); hold on;
plot(k, Lmes, 'x', 'MarkerSize', 10, 'LineWidth', 1.5);
plot(k, H*ones(size(k)), 'k--', 'LineWidth', 1.2);
plot(k, H + 1./k, 'r:', 'LineWidth', 1.5);
grid on;
xlabel('Taille des blocs k (bits)');
ylabel('Longueur moyenne par bit de source (bit)');
title(sprintf('Huffman sur l''extension d''ordre k  (p_{1,ext} = %.2f)', p1ext));
legend('L_k/k theorique', sprintf('L_k/k mesure (%g bits)', N), ...
       'Entropie H', 'Borne H + 1/k', 'Location', 'northeast');
ylim([0, max(1.1, H + 1.05)]);

%% ======================= Fonctions locales =======================
function [codes, len] = huffman_code(p)
% Construit un code de Huffman binaire pour les probabilites p.
% codes : cellule de mots binaires (char '0'/'1'), len : longueurs.
% Principe : on fusionne a chaque etape les deux groupes les moins
% probables ; on prefixe '0' aux mots du premier, '1' a ceux du second.
    n = numel(p);
    codes = repmat({''}, n, 1);
    if n == 1
        codes{1} = '0'; len = 1; return;
    end
    probs  = p(:)';
    groups = num2cell(1:n);          % chaque noeud = liste de symboles
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