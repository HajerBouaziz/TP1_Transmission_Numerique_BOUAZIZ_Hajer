%% Question 10 : test du modele chaine_base.slx pour un Eb/N0 donne
% 1) cale l'instant d'echantillonnage sur la fin des bits (simulation sans bruit) ;
% 2) simule la chaine bruitee, compense le retard et compare le TEB a Q(sqrt(2 Eb/N0)).
clear; clc;
EbN0dB = 5;                     % rapport Eb/N0 teste (dB)
Nbits  = 1e5;
parametres_chaine;
mdl = 'chaine_base';
if ~bdIsLoaded(mdl), load_system(mdl); end

fprintf('L = %d echantillons par bit, Eb/N0 = %g dB\n', L, EbN0dB);
fprintf('N0 = %.4f, variance du bruit par echantillon sigma2 = N0 L/(2 Tb) = %.4f\n\n', N0, sigma2);

%% 1) Calage de l'echantillonneur : sans bruit, z doit valoir exactement +/-A
sigma2_bruit = sigma2;  Nbits_sim = Nbits;
sigma2 = 0;  Nbits = 200;  Tsim = (Nbits - 1) * Tb;
ecart = inf(1, L);
for d = 1:L
    d_ech = d;
    out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
    zz = out.z(4:end);
    ecart(d) = max(abs(abs(zz) - A));     % 0 si on integre exactement un bit
end
[~, d_ech] = min(ecart);
fprintf('Calage : retard d''echantillonnage = %d echantillon(s) (ecart max sans bruit = %.2g)\n', ...
        d_ech, ecart(d_ech));

%% 2) Simulation avec bruit
sigma2 = sigma2_bruit;  Nbits = Nbits_sim;  Tsim = (Nbits - 1) * Tb;
out = sim(mdl, 'ReturnWorkspaceOutputs', 'on');
be = out.b_emis(:);  br = out.b_recu(:);

% Retard de la chaine (en bits) : celui qui minimise le nombre d'erreurs
nerr = zeros(1, 6);
for D = 0:5
    nerr(D + 1) = sum(be(1:end - D - 5) ~= br(1 + D:end - 5));
end
[nmin, iD] = min(nerr);  D = iD - 1;
Nc  = numel(be) - D - 5;                     % nombre de bits compares
teb = nmin / Nc;
ic  = 1.96 * sqrt(teb * (1 - teb) / Nc);
Q   = @(x) 0.5 * erfc(x / sqrt(2));
teb_th = Q(sqrt(2 * 10^(EbN0dB / 10)));

fprintf('Retard de la chaine : %d bit(s)\n', D);
fprintf('TEB simule   = %.5f  (IC 95 %% : [%.5f ; %.5f], %d erreurs sur %d bits)\n', ...
        teb, teb - ic, teb + ic, nmin, Nc);
fprintf('TEB theorique Q(sqrt(2 Eb/N0)) = %.5f\n', teb_th);
fprintf('Variance de z mesuree = %.4f (theorie sigma2/L = %.4f)\n', ...
        var(out.z(6:end) - A * (2 * be(6 - D:end - D) - 1)), sigma2 / L);