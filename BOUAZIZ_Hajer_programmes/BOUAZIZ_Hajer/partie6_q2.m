%% Partie 6 - Question 2 : coefficients du filtre en racine de cosinus sureleve
% 1) valeurs aux points singuliers ; 2) coefficients (alpha, L, span = 10) ;
% 3) comparaison avec rcosdesign (Communications Toolbox) si disponible ;
% 4) utilisation dans les blocs Discrete FIR Filter du modele chaine_filtres.slx.
clear; close all; clc;
P = mes_parametres('BOUAZIZ Hajer');
alpha = P.alpha;  L = P.L;  span = 10;  N = span * L + 1;
fprintf('alpha = %.2f, L = %d, span = %d symboles -> N = %d coefficients\n\n', alpha, L, span, N);

%% 1) Points singuliers (formule non normalisee, T = 1)
h0   = 1 - alpha + 4*alpha/pi;
hsing = alpha/sqrt(2) * ((1 + 2/pi)*sin(pi/(4*alpha)) + (1 - 2/pi)*cos(pi/(4*alpha)));
f = @(t) (4*alpha/pi*cos(pi*(1+alpha)*t) + (1-alpha)*sin(pi*(1-alpha)*t)./(pi*(1-alpha)*t)) ...
         ./ (1 - (4*alpha*t).^2);
ts = 1/(4*alpha);
fprintf('h(0)         : formule limite = %.6f, formule en t = 1e-6 : %.6f\n', h0, f(1e-6));
fprintf('h(T/(4 alpha)) : formule limite = %.6f, formule en t = T/(4a) +/- 1e-6 : %.6f / %.6f\n', ...
        hsing, f(ts + 1e-6), f(ts - 1e-6));
fprintf('T/(4 alpha) = %.3f T, soit %.2f echantillons du centre', ts, ts * L);
if abs(ts*L - round(ts*L)) < 1e-9
    fprintf(' -> point singulier SUR un echantillon du filtre\n\n');
else
    fprintf(' -> entre deux echantillons\n\n');
end

%% 2) Coefficients
h = coef_rrc(alpha, L, span);
fprintf('Energie sum(h^2) = %.4f, coefficient central = %.4f, symetrie : %s\n', ...
        sum(h.^2), h((N+1)/2), mat2str(isequal(round(h, 12), round(fliplr(h), 12))));
fprintf('Aucune valeur NaN : %s\n\n', mat2str(~any(isnan(h))));

figure('Name', 'Coefficients RRC');
n = -(N-1)/2 : (N-1)/2;
stem(n / L, h, 'filled'); grid on; hold on;
xlabel('t / T (en durees symbole)'); ylabel('h[n]');
title(sprintf('Filtre en racine de cosinus sureleve : \\alpha = %.2f, L = %d, N = %d', alpha, L, N));

%% 3) Comparaison avec la Communications Toolbox
if exist('rcosdesign', 'file')
    hc = rcosdesign(alpha, span, L, 'sqrt');
    fprintf('rcosdesign disponible : ecart maximal avec coef_rrc = %.2e\n\n', max(abs(hc - h)));
    plot(n / L, hc, 'rx', 'MarkerSize', 8, 'LineWidth', 1.2);
    legend('coef\_rrc (notre fonction)', 'rcosdesign (Communications Toolbox)');
else
    fprintf('rcosdesign non disponible (pas de Communications Toolbox) : comparaison non faite\n\n');
end

%% 4) Utilisation dans les blocs Discrete FIR Filter (sans bruit)
mdl = 'chaine_filtres';
if ~exist([mdl '.slx'], 'file'), construire_chaine_filtres; end
if ~bdIsLoaded(mdl), load_system(mdl); end
graine = P.graine;  Tb = 1;  Ts = 2 * Tb;  Te = Ts / L;  p1 = 0.5;
tabI  = [1 1 -1 -1] / sqrt(2);   tabQ  = [1 -1 1 -1] / sqrt(2);
tabB1 = [0 0 1 1];               tabB2 = [0 1 0 1];
sigma2 = 0;  Nbits = 1000;  Tsim = (Nbits - 1) * Tb;
crit = inf(1, L);
for k = 1:L
    d_ech = k;
    out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    zz = out.z(40:end);
    crit(k) = mean(abs(abs(real(zz)) - 1/sqrt(2)) + abs(abs(imag(zz)) - 1/sqrt(2)));
end
[~, d_ech] = min(crit);
out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
zz = out.z(40:end);
fprintf('Dans le modele (filtres RRC, sans bruit) : calage = %d echantillon(s)\n', d_ech);
fprintf('Echantillons preleves sur la voie I : entre %.4f et %.4f (symbole : +/-0.7071)\n', ...
        min(abs(real(zz))), max(abs(real(zz))));
fprintf('Erreurs sans bruit : %d\n', compter_erreurs(out.b_emis(:), out.b_recu(:), 30));

function [nerr, n] = compter_erreurs(be, br, Dmax)
    N = min(numel(be), numel(br));
    idx = 60:N - Dmax;
    nerr = inf;
    for D = 0:Dmax
        nerr = min(nerr, sum(be(idx) ~= br(idx + D)));
    end
    n = numel(idx);
end