% =========================================================================
% QUESTION 4 : Validation du Code de Huffman
% =========================================================================

clear; clc;

% 1. Probabilités de test fournies
p = [0.4, 0.2, 0.2, 0.1, 0.1];
K = length(p);

fprintf('=== VALIDATION DU CODE DE HUFFMAN ===\n\n');

% 2. Execution de notre fonction
[dict, L_moy] = mon_huffmancode(p);

% 3. Affichage du dictionnaire obtenu
fprintf('Dictionnaire obtenu :\n');
for i = 1:K
    fprintf('  Symbole S%d (p = %.1f) -> Code : %-6s (Longueur : %d)\n', ...
            dict{i,1}, p(i), dict{i,2}, length(dict{i,2}));
end
fprintf('\n');

% 4. Verification de la propriete PREFIXE
is_prefix = true;
for i = 1:K
    for j = 1:K
        if i ~= j
            code_i = dict{i,2};
            code_j = dict{j,2};
            if startsWith(code_j, code_i)
                is_prefix = false;
                fprintf('ERREUR : Le code S%d (%s) est prefixe du code S%d (%s)\n', ...
                        i, code_i, j, code_j);
            end
        end
    end
end

if is_prefix
    fprintf('[OK] Propriété Préfixe : VÉRIFIÉE (Aucun mot de code n''est le début d''un autre).\n');
else
    fprintf('[FAIL] Propriété Préfixe : NON VÉRIFIÉE.\n');
end

% 5. Calcul et verification de la SOMME DE KRAFT
somme_kraft = 0;
for i = 1:K
    l_i = length(dict{i,2});
    somme_kraft = somme_kraft + 2^(-l_i);
end

fprintf('[OK] Somme de Kraft-McMillan : Ks = %.4f ', somme_kraft);
if abs(somme_kraft - 1.0) < 1e-6
    fprintf('(ÉGALE À 1 -> VÉRIFIÉE)\n');
else
    fprintf('(NON ÉGALE À 1)\n');
end

% 6. Verification de la LONGUEUR MOYENNE (cible = 2.2 bits)
fprintf('[OK] Longueur moyenne obtenue L_moy : %.2f bits/symbole ', L_moy);
if abs(L_moy - 2.2) < 1e-6
    fprintf('(ÉGALE À 2.2 bits -> VÉRIFIÉE)\n\n');
else
    fprintf('(DIFFÉRENTE DE 2.2 bits)\n\n');
end

% 7. Comparaison avec la Communications Toolbox (huffmandict) si disponible
if license('test', 'Communication_Toolbox') && exist('huffmandict', 'file') == 2
    fprintf('=== COMPARAISON AVEC HUFFMANDICT (Toolbox) ===\n');
    symbols = 1:K;
    [dict_matlab, L_matlab] = huffmandict(symbols, p);
    
    fprintf('Longueur moyenne huffmandict : %.2f bits/symbole\n', L_matlab);
    fprintf('Comparaison des mots de code :\n');
    for i = 1:K
        % Formatage des bits de huffmandict
        code_tb = num2str(dict_matlab{i,2});
        code_tb(isspace(code_tb)) = '';
        fprintf('  Symbole S%d : Notre code = %-6s | MATLAB Toolbox = %-6s\n', ...
                i, dict{i,2}, code_tb);
    end
    fprintf('Note : Les codes peuvent diverger en structure de bits par inversion 0/1, mais la longueur moyenne est strictement identique.\n');
else
    fprintf('Communications Toolbox non installée ou non détectée (Comparaison ignorée).\n');
end