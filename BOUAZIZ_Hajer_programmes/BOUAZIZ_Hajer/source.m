function bits = source(N, p1)
% SOURCE Génère N symboles binaires avec P(1) = p1
    u = rand(1, N);
    bits = double(u < p1);
end