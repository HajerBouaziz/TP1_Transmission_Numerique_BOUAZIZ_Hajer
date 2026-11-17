function c = codeur_hamming(m)
%CODEUR_HAMMING  Codeur de Hamming C(7,4) (produit matriciel modulo 2).
%   c = codeur_hamming(m) : m est un vecteur de bits dont la longueur est un
%   multiple de 4 ; c est le vecteur des mots-codes de 7 bits mis bout a bout.
    [G, ~] = matrices_hamming();
    m = double(m(:)');
    assert(mod(numel(m), 4) == 0, 'La longueur du message doit etre un multiple de 4');
    M = reshape(m, 4, [])';          % un bloc de 4 bits par ligne
    C = mod(M * G, 2);               % un mot-code de 7 bits par ligne
    c = reshape(C', 1, []);
end