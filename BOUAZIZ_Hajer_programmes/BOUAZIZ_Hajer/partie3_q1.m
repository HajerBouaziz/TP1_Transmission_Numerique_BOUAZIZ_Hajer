%% Partie 3 - Question 1 : validation du canal binaire symetrique
clear; clc;
P = mes_parametres('BOUAZIZ Hajer');
rng(P.graine);

N  = 1e6;
b  = source(N, P.p1);            % bits emis (partie 2.1)
r  = cbs(b, P.pe_cbs);           % bits recus apres le CBS

fprintf('pe = %.3f\n', P.pe_cbs);
fprintf('Proportion de bits inverses : %.5f\n', mean(r ~= b));