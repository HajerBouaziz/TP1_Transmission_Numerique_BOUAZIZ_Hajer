%% Question 2 : TEB et intervalle de confiance a 95 %
nerr = sum(r ~= b);                          % nombre d'erreurs
teb  = nerr / N;                             % TEB mesure
ic   = 1.96 * sqrt(teb * (1 - teb) / N);     % demi-largeur de l'IC a 95 %

fprintf('\nNombre d''erreurs : %d sur %d bits\n', nerr, N);
fprintf('TEB = %.5f, IC 95 %% = [%.5f ; %.5f]\n', teb, teb - ic, teb + ic);
if abs(teb - P.pe_cbs) <= ic
    fprintf('pe = %.3f est dans l''intervalle de confiance\n', P.pe_cbs);
else
    fprintf('pe = %.3f est hors de l''intervalle de confiance\n', P.pe_cbs);
end