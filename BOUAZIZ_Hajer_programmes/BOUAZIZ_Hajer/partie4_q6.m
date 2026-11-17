%% Partie 4 - Question 6 : validation du decodeur de Hamming sous Simulink
% On envoie au decodeur les 128 mots possibles de 7 bits :
%   - les 16 mots-codes (sans erreur),
%   - les 112 mots a une erreur (16 messages x 7 positions).
% Le decodeur doit restituer le bon message dans tous les cas, comme la
% fonction de reference decodeur_hamming (question 3).
clear; clc;
mdl = 'decodeur_hamming_slx';
if ~exist([mdl '.slx'], 'file'), construire_decodeur_hamming; end
if ~bdIsLoaded(mdl), load_system(mdl); end

[G, H] = matrices_hamming();
M = dec2bin(0:15, 4) - '0';                 % les 16 messages
C = mod(M * G, 2);                          % les 16 mots-codes

%% Construction des 128 mots recus
R = zeros(128, 7);  Mattendu = zeros(128, 4);  pos_err = zeros(128, 1);
k = 0;
for i = 1:16                                % sans erreur
    k = k + 1;  R(k, :) = C(i, :);  Mattendu(k, :) = M(i, :);
end
for i = 1:16                                % une erreur a chaque position
    for j = 1:7
        k = k + 1;  r = C(i, :);  r(j) = 1 - r(j);
        R(k, :) = r;  Mattendu(k, :) = M(i, :);  pos_err(k) = j;
    end
end
fprintf('Mots testes : %d, dont %d distincts (2^7 = 128 : code parfait)\n\n', ...
        size(R, 1), size(unique(R, 'rows'), 1));

%% Simulation du decodeur Simulink
recu  = [(0:127)', R];                      % un mot par periode
Tstop = 127;
out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
m_dec = out.m_dec;  S = out.synd;  det = out.detect(:);

%% Comparaisons
ok_sans = all(all(m_dec(1:16, :) == Mattendu(1:16, :), 2));
ok_une  = sum(all(m_dec(17:128, :) == Mattendu(17:128, :), 2));
ok_ref  = 0;
for k = 1:128
    ok_ref = ok_ref + isequal(m_dec(k, :), decodeur_hamming(R(k, :)));
end
fprintf('Sans erreur        : %s (16 mots-codes, aucune erreur detectee : %s)\n', ...
        ternaire(ok_sans, 'OK', 'ECHEC'), ternaire(~any(det(1:16)), 'oui', 'non'));
fprintf('Une erreur simple  : %d cas sur 112 corriges (erreur detectee dans %d cas)\n', ...
        ok_une, sum(det(17:128)));
fprintf('Accord avec decodeur_hamming (MATLAB) : %d mots sur 128\n\n', ok_ref);

%% Exemple : m = 1011, erreur a chaque position
i = bin2dec('1011') + 1;
fprintf('Exemple : m = 1011, c = %s\n', num2str(C(i, :), '%d'));
for j = 1:7
    k = 16 + 7*(i - 1) + j;
    fprintf('  erreur en %d : r = %s, syndrome = %s -> m decode = %s\n', j, ...
            num2str(R(k, :), '%d'), num2str(S(k, :), '%d'), num2str(m_dec(k, :), '%d'));
end

function s = ternaire(c, a, b)
    if c, s = a; else, s = b; end
end