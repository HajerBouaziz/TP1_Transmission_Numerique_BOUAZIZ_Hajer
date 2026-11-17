%% Partie 4 - Question 1 : matrices G et H du code de Hamming C(7,4)
clear; clc;
g = [1 1 0 1];                 % g(x) = 1 + x + x^3 (coefficients par puissances croissantes)

P = zeros(4, 3);
for i = 0:3                    % messages de poids 1 : m(x) = x^i
    num = zeros(1, i + 4);  num(i + 4) = 1;     % x^(3+i)
    r = reste_mod2(num, g);                     % x^3 m(x) mod g(x)
    P(i + 1, :) = r;
    fprintf('m(x) = x^%d : x^%d mod g(x) -> r = [%d %d %d]\n', i, i + 3, r);
end

G = [eye(4), P];
H = [P', eye(3)];
disp('G ='); disp(G);
disp('H ='); disp(H);
disp('G * H'' mod 2 ='); disp(mod(G * H', 2));

function r = reste_mod2(num, g)
% Reste de la division de num(x) par g(x) dans GF(2)
% (coefficients par puissances croissantes).
    d = numel(g) - 1;
    num = mod(num, 2);
    for k = numel(num):-1:d + 1          % du terme de plus haut degre vers le bas
        if num(k)
            num(k - d:k) = mod(num(k - d:k) + g, 2);
        end
    end
    r = num(1:d);
end