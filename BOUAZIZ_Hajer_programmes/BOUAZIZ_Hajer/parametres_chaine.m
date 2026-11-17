%% Parametres de la chaine de transmission (partie 3, question 10 et suite)
% Script a executer avant chaque simulation du modele chaine_base.slx.
% Il ne contient pas de "clear" : on peut fixer EbN0dB avant de l'appeler.

P = mes_parametres('BOUAZIZ Hajer');   % parametres personnels

%% Temps
Tb = 1;                 % duree d'un bit (unite de reference)
L  = P.L;               % nombre d'echantillons par bit
Te = Tb / L;            % periode d'echantillonnage (pas du solveur)

%% Source et emetteur
A      = P.A;           % amplitude : bit 0 -> -A, bit 1 -> +A
p1     = 0.5;           % bits equiprobables (a partir de la question 10)
seuil  = 0;             % seuil de decision nul
graine = P.graine;      % graine des generateurs aleatoires

%% Bruit : variance par echantillon pour un Eb/N0 donne
if ~exist('EbN0dB', 'var')
    EbN0dB = 5;         % valeur par defaut (dB)
end
Eb     = A^2 * Tb;                  % energie par bit
N0     = Eb / 10^(EbN0dB / 10);     % densite spectrale du bruit
sigma2 = N0 * L / (2 * Tb);         % variance par echantillon : N0/(2 Te)

%% Simulation
if ~exist('Nbits', 'var')
    Nbits = 1e5;        % nombre de bits simules
end
Tsim  = (Nbits - 1) * Tb;           % duree simulee (Nbits instants k*Tb)
d_ech = 1;              % retard (en echantillons) avant l'echantillonneur,
                        % ajuste automatiquement par test_q10.m