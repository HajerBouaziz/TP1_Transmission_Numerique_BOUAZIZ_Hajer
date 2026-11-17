%% Partie 4 - Question 2 : colonnes de H, distance minimale, capacites du code
clear; clc;

%% Matrices du code (question 1)
g = [1 1 0 1];                         % g(x) = 1 + x + x^3
P = zeros(4, 3);
for i = 0:3                            % messages de poids 1 : m(x) = x^i
    num = zeros(1, i + 4);  num(i + 4) = 1;   % x^(3+i)
    P(i + 1, :) = reste_mod2(num, g);         % x^3 m(x) mod g(x)
end
G = [eye(4), P];                       % G = [I4 | P]
H = [P', eye(3)];                      % H = [P^T | I3]

%% 1) Colonnes de H : distinctes et non nulles ?
fprintf('Colonnes de H :\n');
for j = 1:7
    fprintf('  c%d = [%d %d %d]\n', j, H(:, j));
end
non_nulles = all(any(H, 1));
distinctes = size(unique(H', 'rows'), 1) == 7;
fprintf('Toutes non nulles : %s\n', oui_non(non_nulles));
fprintf('Toutes distinctes : %s\n', oui_non(distinctes));
fprintf('-> ce sont les 2^3 - 1 = 7 vecteurs non nuls de 3 bits\n\n');

%% 2) Exemple de 3 colonnes de somme nulle
trouve = false;
for a = 1:7
    for b = a+1:7
        for c = b+1:7
            if ~any(mod(H(:, a) + H(:, b) + H(:, c), 2))
                fprintf('Exemple : c%d + c%d + c%d = 0 -> mot-code de poids 3\n\n', a, b, c);
                trouve = true;  break;
            end
        end
        if trouve, break; end
    end
    if trouve, break; end
end

%% 3) Distance minimale a partir des 16 mots-codes
M = dec2bin(0:15, 4) - '0';            % les 16 messages (une ligne par message)
C = mod(M * G, 2);                     % les 16 mots-codes
w = sum(C, 2);                         % poids de Hamming de chaque mot-code
dmin = min(w(w > 0));

fprintf('Les 16 mots-codes et leur poids :\n');
for i = 1:16
    fprintf('  m = %s  ->  c = %s   (poids %d)\n', num2str(M(i, :), '%d'), ...
            num2str(C(i, :), '%d'), w(i));
end
fprintf('\nDistribution des poids (0 a 7) : %s\n', mat2str(histcounts(w, -0.5:1:7.5)));
fprintf('Distance minimale d_min = %d\n', dmin);
fprintf('Capacite de detection  : %d erreurs\n', dmin - 1);
fprintf('Capacite de correction : %d erreur\n', floor((dmin - 1) / 2));

%% 4) Code parfait : borne de Hamming atteinte
fprintf('\nCode parfait : 2^k * (1 + n) = %d * %d = %d = 2^n = %d\n', ...
        2^4, 1 + 7, 2^4 * (1 + 7), 2^7);

%% ======================= Fonctions locales =======================
function r = reste_mod2(num, g)
% Reste de la division de num(x) par g(x) dans GF(2)
% (coefficients par puissances croissantes).
    d = numel(g) - 1;
    num = mod(num, 2);
    for k = numel(num):-1:d + 1
        if num(k)
            num(k - d:k) = mod(num(k - d:k) + g, 2);
        end
    end
    r = num(1:d);
end

function s = oui_non(c)
    if c, s = 'oui'; else, s = 'non'; end
end