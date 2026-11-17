%% Partie 4 - Question 3 : validation du codeur et du decodeur de Hamming
% Utilise les fonctions matrices_hamming, codeur_hamming et decodeur_hamming.
clear; clc;
[G, H] = matrices_hamming();
M = dec2bin(0:15, 4) - '0';            % les 16 messages possibles

%% 1) Table de decodage par syndrome
fprintf('Table de decodage par syndrome :\n');
fprintf('  syndrome 000 -> pas d''erreur\n');
for j = 1:7
    fprintf('  syndrome %d%d%d -> erreur en position %d\n', H(:, j), j);
end

%% 2) Sans erreur : les 16 messages
ok = 0;
for i = 1:16
    c = codeur_hamming(M(i, :));
    [m, ncorr] = decodeur_hamming(c);
    ok = ok + (isequal(m, M(i, :)) && ncorr == 0);
end
fprintf('\nSans erreur : %d messages sur 16 correctement decodes\n', ok);

%% 3) Une erreur simple a chacune des 7 positions, pour les 16 messages
ok = 0;
fprintf('\nExemple avec m = 1011 :\n');
for i = 1:16
    c = codeur_hamming(M(i, :));
    for j = 1:7
        r = c;  r(j) = 1 - r(j);                 % erreur en position j
        [m, ~, S] = decodeur_hamming(r);
        ok = ok + isequal(m, M(i, :));
        if isequal(M(i, :), [1 0 1 1])
            fprintf('  erreur en %d : r = %s, syndrome = %s -> m decode = %s\n', j, ...
                    num2str(r, '%d'), num2str(S, '%d'), num2str(m, '%d'));
        end
    end
end
fprintf('Une erreur simple : %d cas sur 112 (16 messages x 7 positions) corriges\n', ok);

%% 4) Deux erreurs : le decodeur se trompe
c = codeur_hamming([1 0 1 1]);
r = c;  r([1 2]) = 1 - r([1 2]);               % erreurs en positions 1 et 2
[m, ~, S] = decodeur_hamming(r);
fprintf('\nDeux erreurs (positions 1 et 2) sur m = 1011 : syndrome = %s -> m decode = %s (faux)\n', ...
        num2str(S, '%d'), num2str(m, '%d'));

%% 5) Test sur un long message aleatoire
rng(1);
mlong = randi([0 1], 1, 4000);
assert(isequal(decodeur_hamming(codeur_hamming(mlong)), mlong));
fprintf('Message aleatoire de 4000 bits code puis decode sans erreur : OK\n');