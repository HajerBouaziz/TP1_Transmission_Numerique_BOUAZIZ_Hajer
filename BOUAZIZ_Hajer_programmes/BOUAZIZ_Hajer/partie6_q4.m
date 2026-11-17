%% Partie 6 - Question 4 : DSP du signal emis avec le filtre porte et le filtre RRC
% La DSP est estimee par la methode de Welch (periodogrammes moyennes, fenetre de Hann),
% codee directement (pas besoin de la Signal Processing Toolbox).
% Frequences exprimees en unites de 1/T (T = duree d'un symbole QPSK = 2 Tb).
clear; close all; clc;
mdl = 'chaine_filtres';
if ~exist([mdl '.slx'], 'file'), construire_chaine_filtres; end
if ~bdIsLoaded(mdl), load_system(mdl); end

%% Parametres
P = mes_parametres('BOUAZIZ Hajer');  graine = P.graine;
alpha = P.alpha;  L = P.L;  span = 10;
Tb = 1;  Ts = 2 * Tb;  Te = Ts / L;  p1 = 0.5;
tabI  = [1 1 -1 -1] / sqrt(2);   tabQ  = [1 -1 1 -1] / sqrt(2);
tabB1 = [0 0 1 1];               tabB2 = [0 1 0 1];
sigma2 = 0;  d_ech = 1;  Nbits = 2e5;  Tsim = (Nbits - 1) * Tb;   % 1e5 symboles
Nfft = 1024;

filtres = {ones(1, L) / sqrt(L), coef_rrc(alpha, L, span)};
noms    = {'Filtre porte', sprintf('Filtre RRC (\\alpha = %.2f)', alpha)};
f = ((0:Nfft-1) - Nfft/2) / Nfft * L;        % frequence en unites de 1/T (fs = L/T)
S = zeros(2, Nfft);
for m = 1:2
    h = filtres{m};
    out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    x = out.x_emis(:);
    S(m, :) = dsp_welch(x, Nfft);
end
S = S / max(S(:));                            % normalisation commune (0 dB = maximum)

%% Bande occupee
fprintf('Bande occupee (frequences en unites de 1/T, T = %g = duree symbole) :\n', Ts);
fprintf('%-24s %14s %14s %14s\n', '', 'B a -20 dB', 'B 99 % puiss.', 'B 99,9 %');
for m = 1:2
    Sm = S(m, :) / max(S(m, :));
    b20 = max(abs(f(10*log10(Sm) > -20)));
    fprintf('%-24s %14.3f %14.3f %14.3f\n', strrep(noms{m}, '\', ''), b20, ...
            bande_puissance(f, S(m, :), 0.99), bande_puissance(f, S(m, :), 0.999));
end
fprintf('Theorie RRC : (1 + alpha)/(2T) = %.3f /T\n', (1 + alpha) / 2);
fprintf('Theorie porte : lobe principal jusqu''a 1/T, lobes secondaires en 1/f^2\n');

%% Courbes
fth = linspace(-L/2, L/2, 2000);
porte_th = sinc_(fth).^2;
rc_th = zeros(size(fth));  af = abs(fth);
rc_th(af <= (1-alpha)/2) = 1;
z = af > (1-alpha)/2 & af <= (1+alpha)/2;
rc_th(z) = 0.5 * (1 - sin(pi/alpha * (af(z) - 0.5)));

figure('Name', 'DSP', 'Position', [100 100 1000 500]);
plot(f, 10*log10(S(1, :) + 1e-12), 'b', 'LineWidth', 1.2); hold on;
plot(f, 10*log10(S(2, :) + 1e-12), 'r', 'LineWidth', 1.2);
plot(fth, 10*log10(porte_th + 1e-12), 'b:', 'LineWidth', 1);
plot(fth, 10*log10(rc_th + 1e-12), 'r:', 'LineWidth', 1);
xline([-1 1] * (1 + alpha)/2, 'k--', 'LineWidth', 1);
grid on; xlim([-L/2 L/2]); ylim([-70 5]);
xlabel('f \times T (frequence normalisee par le debit symbole)'); ylabel('DSP (dB)');
title('Densite spectrale de puissance du signal emis (QPSK, bande de base equivalente)');
legend(noms{1}, noms{2}, 'Theorie porte : sinc^2(fT)', 'Theorie RRC : C_\alpha(f)', ...
       '\pm(1+\alpha)/(2T)', 'Location', 'southoutside', 'NumColumns', 3);

%% ======================= Fonctions locales =======================
function S = dsp_welch(x, Nfft)
% DSP par la methode de Welch : segments de Nfft points, fenetre de Hann, recouvrement 50 %.
    w = 0.5 - 0.5 * cos(2*pi*(0:Nfft-1)' / (Nfft - 1));
    pas = Nfft / 2;  nseg = floor((numel(x) - Nfft) / pas) + 1;
    S = zeros(1, Nfft);
    for k = 1:nseg
        seg = x((k-1)*pas + (1:Nfft));
        S = S + abs(fftshift(fft(seg .* w))).'.^2;
    end
    S = S / nseg;
end

function B = bande_puissance(f, S, frac)
% Plus petite demi-largeur B telle que la bande [-B, B] contienne la fraction frac de la puissance.
    [fa, ord] = sort(abs(f));
    cumul = cumsum(S(ord)) / sum(S);
    B = fa(find(cumul >= frac, 1));
end

function y = sinc_(x)
    y = ones(size(x));  k = x ~= 0;
    y(k) = sin(pi*x(k)) ./ (pi*x(k));
end