% =========================================================================
% QUESTION 5 : Codage/Décodage de Huffman et Performances sur texte_fr.txt
% =========================================================================

clear; clc; close all;

% 1. Lecture du fichier texte
filename = 'texte_fr.txt';
fid = fopen(filename, 'r', 'native', 'UTF-8');
if fid == -1
    error('Fichier "%s" introuvable.', filename);
end
texte = fread(fid, '*char')';
fclose(fid);

N_char = length(texte);

% 2. Extraction des probabilités et calcul de l'entropie H
[symboles, ~, idx_texte] = unique(texte);
counts = accumarray(idx_texte, 1);
p = counts / N_char;
K = length(symboles);
H = -sum(p .* log2(p));

% 3. Construction du dictionnaire de Huffman
[dict, L_moy] = mon_huffmancode(p);

% 4. CODEUR : Conversion du texte en flux binaire concaténé
code_map = containers.Map();
for i = 1:K
    code_map(symboles(i)) = dict{i, 2};
end

flux_binaire = cell(1, N_char);
for i = 1:N_char
    flux_binaire{i} = code_map(texte(i));
end
flux_binaire = [flux_binaire{:}]; % Concaténation en une seule chaîne de '0' et '1'

% 5. DÉCODEUR INSTANTANÉ (Parcours par préfixe)
% Inversion du dictionnaire : code binaire -> symbole
decode_map = containers.Map();
for i = 1:K
    decode_map(dict{i, 2}) = symboles(i);
end

texte_reconstitue = char(zeros(1, N_char));
buf = '';
symb_count = 0;

for b = 1:length(flux_binaire)
    buf = [buf, flux_binaire(b)]; %#ok<AGROW>
    if isKey(decode_map, buf)
        symb_count = symb_count + 1;
        texte_reconstitue(symb_count) = decode_map(buf);
        buf = ''; % Réinitialisation du tampon
    end
end

% 6. Vérification de la restitution sans erreur
erreur = ~isequal(texte, texte_reconstitue);

% 7. Calcul des métriques de performance
efficacite = (H / L_moy) * 100;
taux_compression = (1 - (L_moy / 8)) * 100;

% 8. Affichage des résultats
fprintf('=== RÉSULTATS QUESTION 5 : TEXTE_FR.TXT ===\n');
fprintf('Entropie H                  : %.4f bits/symbole\n', H);
fprintf('Longueur moyenne L_moy      : %.4f bits/symbole\n', L_moy);
fprintf('Efficacité (H / L_moy)      : %.2f %%\n', efficacite);
fprintf('Taux de compression vs 8b  : %.2f %%\n', taux_compression);
fprintf('Taille originale (8 bits)   : %d bits (%d octets)\n', N_char * 8, N_char);
fprintf('Taille compressée Huffman   : %d bits (~%.1f octets)\n', length(flux_binaire), length(flux_binaire)/8);

fprintf('\n=== VÉRIFICATION DU THÉORÈME DE SHANNON ===\n');
if (H <= L_moy) && (L_moy < H + 1)
    fprintf('[OK] Encadrement H <= L_moy < H + 1 VÉRIFIÉ (%.4f <= %.4f < %.4f)\n', H, L_moy, H+1);
else
    fprintf('[FAIL] Encadrement NON VÉRIFIÉ\n');
end

fprintf('\n=== VALIDATION DU DÉCODAGE ===\n');
if ~erreur
    fprintf('[OK] Restitution du texte : SANS ERREUR (100%% identique au texte d''origine)\n');
else
    fprintf('[FAIL] Erreur de reconstruction détectée !\n');
end