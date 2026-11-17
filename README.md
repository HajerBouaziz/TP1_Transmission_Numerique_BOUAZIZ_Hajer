# TP Chaîne de transmission numérique en bande de base (Matlab/Simulink)

**Hajer BOUAZIZ** – ENSIM 5A ASTRE – Théorie de l'information et du codage
Guide d'utilisation des programmes

---

## Vidéo de la présentation

La vidéo de la soutenance (environ 200 Mo, trop lourde pour GitHub) est disponible ici :
[Enregistrement de la présentation (Google Drive)](https://drive.google.com/file/d/1dJ5EzRND17jem0sHKoiwmzw63lHe9WUK/view?usp=sharing)

## 1. Contenu du dossier

- 56 fichiers Matlab (`.m`) : scripts des questions et fonctions ;
- 9 modèles Simulink (`.slx`) ;
- `texte_fr.txt` : texte utilisé dans les parties 2.2, 2.4, 2.5 et 7.

Le dépôt contient aussi le compte rendu (`Compte_rendu_BOUAZIZ_Hajer.pdf`), la présentation de l'oral et la déclaration d'usage de l'IA.

## 2. Prérequis

- **Matlab et Simulink R2023b** ou plus récent (version avec laquelle les modèles ont été enregistrés).
- **Aucune toolbox n'est nécessaire.** Si la Communications Toolbox est installée, deux scripts font en plus une comparaison facultative : `rcosdesign` dans `partie6_q2.m` et `huffmandict` dans `validation_huffman.m`.

## 3. Mise en route

1. Télécharger le dépôt : bouton vert **Code** → **Download ZIP**, puis décompresser l'archive.
2. Dans Matlab, choisir comme dossier courant (*Current Folder*) le dossier qui contient les fichiers `.m` et `.slx`. Tous ces fichiers doivent rester ensemble dans ce dossier.
3. Lancer un script en tapant son nom dans la *Command Window*, par exemple :

   ```matlab
   >> partie4_q10
   ```

   Les fichiers qui sont des fonctions (`cbs.m`, `coef_rrc.m`, etc.) ne se lancent pas avec le bouton *Run* : ils sont appelés par les scripts.

### Paramètres personnels

Tous les scripts appellent :

```matlab
P = mes_parametres('BOUAZIZ Hajer');
```

`mes_parametres.m` est une copie exacte de la fonction `parametres_perso` fournie. On obtient :

| p1 | p1_ext | pe | A | a | σ | L | α | β | retard |
|---|---|---|---|---|---|---|---|---|---|
| 0,38 | 0,06 | 0,093 | 1 | 1,78 | 0,67 | 4 | 0,25 | 0,34 | 1 T |

## 4. Scripts par partie (dans l'ordre du compte rendu)

### Partie 2 – Codage de source

| Script | Question | Contenu |
|---|---|---|
| `partie2_1.m` | 2.1 Q1-2 | source binaire, fréquence des 1, entropie H(p) |
| `analyse_texte.m` | 2.2 Q3 | fréquences des caractères du texte |
| `validation_huffman.m` | 2.2 Q4 | validation du code de Huffman |
| `question5_huffman.m` | 2.2 Q5 | codage et décodage du texte |
| `question6_cout_table.m` | 2.2 Q6 | coût de la table de codage |
| `extension_source_huffman.m` | 2.3 Q7 | Huffman sur l'extension d'ordre k |
| `partie_2_4.m` | 2.4 Q8-9 | entropie des paires, gzip / bzip2 / 7z, bits en sortie de Huffman |
| `partie_2_5.m` | 2.5 Q10-11 | codeur et décodeur LZ78 |

### Partie 3 – Chaîne de base

| Script | Question | Contenu |
|---|---|---|
| `partie3_q1.m`, `partie3_q2.m` | Q1-2 | canal binaire symétrique, TEB et intervalle de confiance à 95 % |
| `partie3_q3.m` | Q3 | capacité du canal |
| `partie3_q4.m` | Q4 | bruit uniforme : densités, seuil optimal |
| `partie3_q5.m` | Q5 | probabilité d'erreur Pe(s), bruit uniforme |
| `partie3_q8.m` | Q8 | bruit gaussien : TEB en fonction du seuil |
| `test_q10.m` | Q10 | test du modèle `chaine_base.slx` |
| `partie3_q12.m` | Q12 | TEB de 0 à 9 dB, avec et sans intégration |

> `partie3_simulation.m` est une première version de travail, non utilisée : elle appelle un ancien nom de modèle. Utiliser `partie3_q12.m`.

### Partie 4 – Codage de canal (Hamming 7,4)

| Script | Question | Contenu |
|---|---|---|
| `partie4_q1.m` | Q1 | matrices G et H |
| `partie4_q2.m` | Q2 | colonnes de H, distance minimale |
| `partie4_q3.m` | Q3 | validation du codeur et du décodeur |
| `partie4_q5.m` | Q5 | codeur à registre (`codeur_registre.slx`) |
| `partie4_q6.m` | Q6 | décodeur Simulink (`decodeur_hamming_slx.slx`) |
| `partie4_q10.m` | Q10-11 | TEB avec et sans codage (`chaine_codee.slx`) |

### Partie 5 – Modulation QPSK

| Script | Question | Contenu |
|---|---|---|
| `partie5_q2.m` | Q2 | validation du modulateur et du démodulateur |
| `partie5_q3.m` | Q3 | constellations à 0, 5 et 10 dB |
| `partie5_q4.m` | Q4 | TEB de la QPSK (mapping de Gray) |
| `partie5_q5.m` | Q5 | mapping naturel contre mapping de Gray |
| `partie5_q6.m` | Q6 | QPSK avec codage de Hamming |

### Partie 6 – Filtres de mise en forme

| Script | Question | Contenu |
|---|---|---|
| `partie6_q1.m` | Q1 | filtre porte = détecteur optimal |
| `partie6_q2.m` | Q2 | coefficients du filtre RRC (`coef_rrc.m`) |
| `partie6_q3.m` | Q3 | h, h∗h, critère de Nyquist, troncature |
| `partie6_q4.m` | Q4 | DSP (porte et RRC) et bande occupée |
| `partie6_q5.m` | Q5 | diagrammes de l'œil, TEB porte et RRC |
| `partie6_q6.m` | Q6 | décalage d'échantillonnage de T/4 |

### Partie 7 – Canal à écho

| Script | Question | Contenu |
|---|---|---|
| `partie7_q1.m` | Q1 | canal à écho : œil, TEB |
| `partie7_q3.m` | Q3 | transmission du texte (`chaine_texte.slx`) |

## 5. Modèles Simulink

Les 9 modèles sont fournis. Chacun peut aussi être reconstruit par script :

| Modèle | Script de construction |
|---|---|
| `chaine_base.slx` | `construire_chaine_base.m` |
| `codeur_registre.slx` | `construire_codeur_registre.m` |
| `decodeur_hamming_slx.slx` | `construire_decodeur_hamming.m` |
| `chaine_codee.slx` | `construire_chaine_codee.m` |
| `chaine_qpsk.slx` | `construire_chaine_qpsk.m` |
| `chaine_qpsk_codee.slx` | `construire_chaine_qpsk_codee.m` |
| `chaine_filtres.slx` | `construire_chaine_filtres.m` |
| `chaine_echo.slx` | `construire_chaine_echo.m` |
| `chaine_texte.slx` | `construire_chaine_texte.m` |

La plupart des scripts reconstruisent automatiquement leur modèle s'il est absent, sauf `test_q10`, `partie3_q12`, `partie4_q10` et `partie5_q6`, qui utilisent directement les modèles fournis. Les modèles utilisent un solveur discret à pas fixe.

## 6. Fonctions utilisées par les scripts

| Fichier | Rôle |
|---|---|
| `mes_parametres.m`, `parametres_perso.m` | paramètres personnels |
| `parametres.m`, `parametres_chaine.m` | paramètres communs (Tb, L, A, variance du bruit) |
| `source.m` | source binaire de probabilité p1 |
| `cbs.m` | canal binaire symétrique |
| `mon_huffmancode.m` | code de Huffman |
| `matrices_hamming.m` | matrices G et H |
| `codeur_hamming.m`, `decodeur_hamming.m` | codeur et décodeur (syndrome) |
| `coef_rrc.m` | coefficients du filtre RRC |

## 7. Remarques

- Les simulations de TEB (`partie3_q12`, `partie4_q10`, `partie5_q4` à `q6`, `partie6_q5`, `partie6_q6`, `partie7_q1`) simulent jusqu'à plusieurs millions de bits aux forts Eb/N0 : elles peuvent prendre quelques minutes.
- Les résultats s'affichent dans la *Command Window* et dans des figures ; ce sont ceux présentés dans le compte rendu, à l'aléa des tirages aléatoires près.
