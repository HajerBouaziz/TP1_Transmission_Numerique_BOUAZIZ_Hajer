function r = cbs(b, pe)
%CBS Canal binaire symetrique.
%   r = cbs(b, pe) inverse chaque bit de b avec la probabilite pe.
e = rand(size(b)) < pe;          % bit d'erreur : 1 avec la probabilite pe
r = double(xor(b, e));           % bit recu = bit emis XOR erreur
end
