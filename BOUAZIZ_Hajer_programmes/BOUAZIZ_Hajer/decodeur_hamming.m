function [m, ncorr, S] = decodeur_hamming(r)
%DECODEUR_HAMMING  Decodeur de Hamming C(7,4) par calcul du syndrome.
%   [m, ncorr, S] = decodeur_hamming(r)
%   r     : bits recus (longueur multiple de 7)
%   m     : bits d'information decodes (4 par mot)
%   ncorr : nombre de mots dans lesquels un bit a ete corrige
%   S     : syndromes (un par ligne)
    [~, H] = matrices_hamming();
    r = double(r(:)');
    assert(mod(numel(r), 7) == 0, 'La longueur du mot recu doit etre un multiple de 7');
    R = reshape(r, 7, [])';           % un mot recu par ligne
    S = mod(R * H', 2);               % syndromes s = r H^T

    % Table syndrome -> position : la colonne j de H donne la position j
    poids = [4; 2; 1];
    table = zeros(1, 7);
    for j = 1:7
        table(H(:, j)' * poids) = j;
    end

    s_int = S * poids;                % syndrome en entier (0 = pas d'erreur)
    k = find(s_int > 0);              % mots avec un syndrome non nul
    pos = table(s_int(k));            % position de l'erreur supposee
    idx = sub2ind(size(R), k(:), pos(:));
    R(idx) = 1 - R(idx);              % correction : inversion du bit
    ncorr = numel(k);

    m = reshape(R(:, 1:4)', 1, []);   % le message est en tete du mot-code
end