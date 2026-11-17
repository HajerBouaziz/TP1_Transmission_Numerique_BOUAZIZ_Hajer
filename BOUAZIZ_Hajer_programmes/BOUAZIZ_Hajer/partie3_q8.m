% =========================================================================
% Partie 3 - Question 8 : TEB en fonction du seuil par simulation (Canal Gaussien)
% =========================================================================
clear; clc;

% Paramètres
A = 1;                  % Amplitude du signal (+A ou -A)
p1 = 0.3;               % Probabilité d'émettre un 1 (source volontairement déséquilibrée)
p0 = 1 - p1;            % Probabilité d'émettre un 0
Eb_N0_dB = 5;           % Rapport Eb/N0 en dB

Eb = A^2;               % Énergie par bit (Tb = 1)
N0 = Eb / (10^(Eb_N0_dB / 10));
sigma = sqrt(N0 / 2);   % Écart-type du bruit gaussien

% 1. Calcul du seuil optimal théorique
s_opt = (sigma^2 / (2 * A)) * log(p0 / p1);
fprintf('Seuil de décision optimal théorique s* = %.4f\n', s_opt);

% 2. Simulation sur N bits
N = 10^5;
bits_emis = (rand(1, N) < p1);          % Génération des bits (0 ou 1)
x = (2 * bits_emis - 1) * A;            % Modulation antipodale : 0 -> -A, 1 -> +A

% Ajout du bruit blanc gaussien additif (AWGN)
bruit = sigma * randn(1, N);
r = x + bruit;                          % Signal reçu brut

% 3. Test de plusieurs valeurs de seuil s pour évaluer le TEB
s_vec = linspace(-1.5 * A, 1.5 * A, 150);
teb_sim = zeros(size(s_vec));

for i = 1:length(s_vec)
    s = s_vec(i);
    % Comparateur à seuil : si r > s, on décide 1, sinon 0
    bits_recus = (r > s);
    % Calcul du taux d'erreur binaire
    teb_sim(i) = mean(bits_recus ~= bits_emis);
end

% 4. Tracé des résultats
figure('Name', 'TEB en fonction du seuil', 'Color', 'w');
plot(s_vec, teb_sim, '-b', 'LineWidth', 2);
hold on;
xline(s_opt, '--r', 'LineWidth', 1.5, 'DisplayName', sprintf('Seuil optimal s* = %.3f', s_opt));
xline(0, ':k', 'LineWidth', 1.5, 'DisplayName', 'Seuil par défaut s = 0');
xlabel('Seuil de décision s');
ylabel('Taux d''Erreur Binaire (TEB)');
title(sprintf('TEB simulé en fonction du seuil (Eb/N0 = %d dB, p1 = %.1f)', Eb_N0_dB, p1));
legend('Location', 'northeast');
grid on;