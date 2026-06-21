function [Ke, B, D] = KeCST(barra, no)
% KeCST - Calcula a matriz de rigidez (6x6) de um elemento CST
% Entradas:
%   barra : estrutura do elemento contendo propriedades (elasticidade, poisson, espessura, nos)
%   no    : estrutura global de nós contendo as coordenadas

    E = barra.elasticidade;
    V = barra.poisson;
    t = barra.espessura;

    % 2. Coordenadas dos três nós do elemento triangular (i, j, m)
    id_nos = barra.nos; % Vetor com os IDs dos 3 nós [n1, n2, n3]
    
    x1 = no(id_nos(1)).coordenada(1);
    y1 = no(id_nos(1)).coordenada(2);
    
    x2 = no(id_nos(2)).coordenada(1);
    y2 = no(id_nos(2)).coordenada(2);
    
    x3 = no(id_nos(3)).coordenada(1);
    y3 = no(id_nos(3)).coordenada(2);

    % 3. Cálculo da Área do elemento triangular (via determinante)
    A2 = (x1*(y2 - y3) + x2*(y3 - y1) + x3*(y1 - y2));
    Area = abs(A2) / 2;

    % 4. Coeficientes das funções de forma (derivadas geométricas)
    beta1  = y2 - y3;
    beta2  = y3 - y1;
    beta3  = y1 - y2;
    
    gamma1 = x3 - x2;
    gamma2 = x1 - x3;
    gamma3 = x2 - x1;

    % 5. Montagem da Matriz Cinemática B (3x6)
    B = (1 / A2) * [beta1,  0,     beta2,  0,     beta3,  0;
                    0,      gamma1, 0,     gamma2, 0,      gamma3;
                    gamma1, beta1,  gamma2, beta2,  gamma3, beta3];

    barra.B = B;

    % 6. Montagem da Matriz de Estado Plano de Tensões D (3x3)
    C = E / (1 - V^2);
    D = C * [1, V, 0; 
             V, 1, 0; 
             0, 0, (1 - V) / 2];

    barra.D = D;
    % 7. Cálculo da Matriz de Rigidez Local/Global Ke (6x6)
    Ke = t * Area * (B' * D * B);
end