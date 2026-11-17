function [dict, L_moy] = mon_huffmancode(p)
    % MON_HUFFMANCODE Construit le code de Huffman d'une source sans memoire
    
    p = p(:) / sum(p); % Normalisation
    K = length(p);
    
    % Initialisation des feuilles
    nodes = cell(K, 1);
    for i = 1:K
        nodes{i} = struct('symb', i, 'prob', p(i), 'code', '');
    end
    
    % Construction de l'arbre par fusion successive
    while length(nodes) > 1
        % Tri des noeuds par probabilite croissante
        node_probs = cellfun(@(x) x.prob, nodes);
        [~, idx] = sort(node_probs, 'ascend');
        nodes = nodes(idx);
        
        % Les deux plus faibles
        n1 = nodes{1};
        n2 = nodes{2};
        
        % Ajout des bits '0' a gauche et '1' a droite
        n1 = add_prefix(n1, '0');
        n2 = add_prefix(n2, '1');
        
        % Noeud fusionne
        merged.symb = [n1.symb, n2.symb];
        merged.prob = n1.prob + n2.prob;
        merged.left = n1;
        merged.right = n2;
        
        nodes = [nodes(3:end); {merged}];
    end
    
    % Extraction des mots de code depuis la racine
    dict_list = extract_codes(nodes{1});
    
    % Reordonnancement selon l'ordre initial des symboles (1 à K)
    dict = cell(K, 2);
    for i = 1:K
        for j = 1:length(dict_list)
            if dict_list{j}.symb == i
                dict{i, 1} = i;
                dict{i, 2} = dict_list{j}.code;
            end
        end
    end
    
    % Calcul de la longueur moyenne L_moy
    L_moy = 0;
    for i = 1:K
        L_moy = L_moy + p(i) * length(dict{i, 2});
    end
end

% --- Fonctions auxiliaires indispensables ---
function node = add_prefix(node, bit)
    if isfield(node, 'left')
        node.left = add_prefix(node.left, bit);
        node.right = add_prefix(node.right, bit);
    else
        node.code = [bit, node.code];
    end
end

function list = extract_codes(node)
    if ~isfield(node, 'left')
        list = {struct('symb', node.symb, 'code', node.code)};
    else
        list = [extract_codes(node.left); extract_codes(node.right)];
    end
end