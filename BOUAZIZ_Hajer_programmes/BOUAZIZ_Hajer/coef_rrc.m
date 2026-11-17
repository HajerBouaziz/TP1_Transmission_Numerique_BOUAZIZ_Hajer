function h = coef_rrc(alpha, L, span)
%COEF_RRC  Coefficients du filtre en racine de cosinus sureleve (RRC).
%   h = coef_rrc(alpha, L, span)
%   alpha : coefficient de retombee (roll-off), 0 < alpha <= 1
%   L     : nombre d'echantillons par symbole
%   span  : longueur du filtre en symboles (N = span*L + 1 coefficients)
%   h est normalise a energie unite : sum(h.^2) = 1, de sorte que le produit
%   filtre d'emission x filtre adapte vaut 1 a l'instant optimal.
%
%   h(t) = [ (4a/pi) cos(pi(1+a)t/T) + (1-a) sinc((1-a)t/T) ] / [ 1 - (4at/T)^2 ]   (T = 1)
%   Points singuliers :
%     t = 0          : h = 1 - a + 4a/pi
%     t = +/-T/(4a)  : h = a/sqrt(2) [ (1+2/pi) sin(pi/(4a)) + (1-2/pi) cos(pi/(4a)) ]

    if nargin < 3, span = 10; end
    t = (-span*L/2 : span*L/2) / L;              % temps en durees symbole (T = 1)
    h = zeros(size(t));
    for k = 1:numel(t)
        tk = t(k);
        if abs(tk) < 1e-12                        % t = 0
            h(k) = 1 - alpha + 4*alpha/pi;
        elseif abs(abs(tk) - 1/(4*alpha)) < 1e-12 % t = +/- T/(4 alpha)
            h(k) = alpha/sqrt(2) * ((1 + 2/pi) * sin(pi/(4*alpha)) + ...
                                    (1 - 2/pi) * cos(pi/(4*alpha)));
        else
            x = (1 - alpha) * tk;
            if x == 0
                sincx = 1;                        % cas alpha = 1 : sinc(0) = 1
            else
                sincx = sin(pi*x) / (pi*x);       % sinc sans toolbox
            end
            h(k) = (4*alpha/pi * cos(pi*(1 + alpha)*tk) + (1 - alpha) * sincx) ...
                   / (1 - (4*alpha*tk)^2);
        end
    end
    h = h / sqrt(sum(h.^2));                      % energie unite
end