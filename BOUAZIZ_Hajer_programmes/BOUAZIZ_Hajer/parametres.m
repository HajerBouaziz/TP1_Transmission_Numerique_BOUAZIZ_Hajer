
clear; clc; 
close all;
P = mes_parametres('BOUAZIZ Hajer');   % parametres personnels (meme nom que tous les autres scripts)

Tb = 1;                     % Durée d'un bit de référence
A = P.A;                    % Amplitude de transmission
L = P.L;                    % Échantillons par bit/symbole
Te = Tb / L;                % Période d'échantillonnage discret

p1 = P.p1;                  % Probabilité d'émettre un 1
p0 = 1 - p1;
pe_cbs = P.pe_cbs;          % Probabilité d'erreur du CBS
a_unif = P.a_unif;          % Bruit uniforme [-a, a]
sigma_gauss = P.sigma;      % Écart-type bruit gaussien
alpha_rrc = P.alpha;        % Roll-off du filtre RRC
beta_echo = P.beta;         % Amplitude de l'écho
retard_trajet = P.retard_trajet; % Retard en symboles

% 3. Énergie par bit et calcul de la variance du bruit
Eb = (A^2) * Tb;            % Énergie par bit d'information

% Exemple de calcul pour un Eb/N0 donné (en dB)
EbN0_dB = 5; 
EbN0_lin = 10^(EbN0_dB/10);
N0 = Eb / EbN0_lin;
sigma_bruit_ech = sqrt(N0 * L / (2 * Tb)); % Variance par échantillon

disp('Paramètres chargés avec succès !');