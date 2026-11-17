function [G, H] = matrices_hamming()
%MATRICES_HAMMING  Matrices du code cyclique C(7,4) de polynome g(x) = 1 + x + x^3,
%   sous forme systematique c = [m0 m1 m2 m3 | r0 r1 r2], r(x) = x^3 m(x) mod g(x).
%   G = [I4 | P] (4x7), H = [P' | I3] (3x7).
    P = [1 1 0;     % x^3 mod g = 1 + x
         0 1 1;     % x^4 mod g = x + x^2
         1 1 1;     % x^5 mod g = 1 + x + x^2
         1 0 1];    % x^6 mod g = 1 + x^2
    G = [eye(4), P];
    H = [P', eye(3)];
end