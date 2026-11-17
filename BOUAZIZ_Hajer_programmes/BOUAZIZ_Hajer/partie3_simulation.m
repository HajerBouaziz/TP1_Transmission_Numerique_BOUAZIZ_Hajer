% =========================================================================
% Script de simulation et pilotage - Partie 3 (Chaîne de base)
% =========================================================================
clear; clc; close all;

% 1. Chargement des paramètres officiels et configuration
P = mes_parametres('BOUAZIZ Hajer'); 
Tb = 1;                     
A = P.A;                    
L = P.L;                    
Te = Tb / L;                
p1 = 0.5;                   % Bits équiprobables
s_seuil = 0;                % Seuil nul

% 2. Vecteur des rapports Eb/N0 en dB à tester (de 0 à 9 dB)
EbN0_dB_vec = 0:1:9;
teb_simul = zeros(size(EbN0_dB_vec));
teb_theorique = zeros(size(EbN0_dB_vec));

% Nom du modèle Simulink (assurez-vous qu'il s'appelle ainsi ou changez le nom)
modele_simulink = 'chaine_transmission_base'; 

% S'assurer que le modèle est chargé
load_system(modele_simulink);

for i = 1:length(EbN0_dB_vec)
    EbN0_dB = EbN0_dB_vec(i);
    
    % Calcul de la variance du bruit pour ce Eb/N0
    Eb = (A^2) * Tb;
    EbN0_lin = 10^(EbN0_dB / 10);
    N0 = Eb / EbN0_lin;
    sigma2_echantillon = (N0 * L) / (2 * Tb); 
    sigma_echantillon = sqrt(sigma2_echantillon); 
    
    % (Optionnel) Si vous stockez ces variables dans le Workspace de MATLAB 
    % pour que Simulink les lise directement, assignez-les :
    assignin('base', 'sigma_echantillon', sigma_echantillon);
    
    % Lancement de la simulation Simulink
    % (Le bloc Error Rate Calculation doit renvoyer les résultats, par exemple dans une variable 'out')
    simOut = sim(modele_simulink, 'StopTime', '10000'); 
    
    % Récupération du TEB mesuré (selon le nom de votre variable de sortie dans Simulink)
    % Si vous utilisez un bloc Error Rate Calculation avec "Save to workspace", adaptez le nom :
    % teb_simul(i) = ...; 
    
    % Courbe théorique de référence pour le canal AWGN : TEB = Q(sqrt(2 Eb / N0))
    teb_theorique(i) = 0.5 * erfc(sqrt(EbN0_lin));
end

% 3. Tracé comparatif du TEB
figure('Name', 'TEB de la chaîne de base', 'Color', 'w');
semilogy(EbN0_dB_vec, teb_theorique, '-r', 'LineWidth', 2, 'DisplayName', 'Théorique Q(\sqrt{2Eb/N0})');
hold on;
% semilogy(EbN0_dB_vec, teb_simul, '--bo', 'LineWidth', 1.5, 'DisplayName', 'Simulé Simulink');
xlabel('E_b / N_0 (dB)');
ylabel('Taux d''Erreur Binaire (TEB)');
title('Performance de la chaîne de transmission de base');
legend('Location', 'southwest');
grid on;