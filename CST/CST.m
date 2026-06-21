clc;
clear;

% Cálculo de chapa fina (CST)
% Importando valores
importNo = readtable('Dados de entrada.xlsx', 'Sheet', 'Dados', 'Range', 'A3:G14');
importNo = rmmissing(importNo);

importBarra = readtable('Dados de entrada.xlsx', 'Sheet', 'Dados', 'Range', 'J3:P14');
importBarra = rmmissing(importBarra);

% Definindo valores nos objetos
for i = 1:height(importNo) % nós
    id = importNo.Var1(i);
    x  = importNo.Coordenada(i);
    y  = importNo.Coordenada_1(i);
    cx = importNo.Carga(i);
    cy = importNo.Carga_1(i);
    tx = double(importNo.Fixo(i));
    ty = double(importNo.Fixo_1(i));
    
    no(id).coordenada = [x y];         % (x,y)
    no(id).restricao  = [tx ty];       % 1 para travado e 0 para livre (x,y)
    no(id).carga      = [cx cy];       % Forças em X e Y
end

for i = 1:height(importBarra) % elementos
    id = importBarra.ID(i);
    n1 = importBarra.N1(i);
    n2 = importBarra.N2(i);
    n3 = importBarra.N3(i);
    
    barra(id).nos          = [n1 n2 n3];
    barra(id).elasticidade = importBarra.E_elasticidade_(i);
    barra(id).poisson      = importBarra.V_poisson_(i);
    barra(id).espessura    = importBarra.t_espessura_(i);
end
% ___________________________________________________________________

% Iteração sobre as barras
for i = 1:length(barra)
    [Ke, B, D] = KeCST(barra(i), no); 
    
    barra(i).ke = Ke;
    barra(i).B = B;
    barra(i).D = D;
end

% Iteração sobre nos

dof = length(no(1).restricao);

% Matriz global

KG = Kg(barra,no,dof);

% Adiciona condição de contorno na matriz global
trava = reshape([no.restricao], [], 1);
F = reshape([no.carga], [], 1);

% Faz a trava na matriz global
for i = 1:length(trava)
    if trava(i)
        KG(:,i) = 0; % Coluna
        KG(i,:) = 0; % Linha
        KG(i,i) = 1; % Diagonal
        F(i) = 0;
    end
end

% Resolve deslocamentos
deslocamento = KG\F;

% Cálculo das tensões e separação nodal
for i = 1:length(barra)

    % Identifica os nós de cada elemento
    n1 = barra(i).nos(1);
    n2 = barra(i).nos(2);
    n3 = barra(i).nos(3);
    
    % Mapa dos GL
    gl_x1 = (n1-1)*dof + 1; gl_y1 = (n1-1)*dof + 2;
    gl_x2 = (n2-1)*dof + 1; gl_y2 = (n2-1)*dof + 2;
    gl_x3 = (n3-1)*dof + 1; gl_y3 = (n3-1)*dof + 2;
    
    gl_elemento = [gl_x1, gl_y1, gl_x2, gl_y2, gl_x3, gl_y3];
    
    % Vetor deslocamento para cada elemento
    U_elemento = deslocamento(gl_elemento);
    barra(i).deslocamentoNodal = U_elemento;

    % Cálculo das tensões
    barra(i).tensao = barra(i).D * barra(i).B * U_elemento;
end

%% Apresentação dos valores

% Valores importados
disp("Nós importados:")
disp(importNo)
fprintf('\n');

disp("Elementos importados:")
disp(importBarra)
fprintf('\n');

% Valores calculados
for i = 1:length(barra)
    fprintf('=== Elemento CST %d ===\n', i);
    
    % Recupera os IDs dos 3 nós deste elemento
    n1 = barra(i).nos(1);
    n2 = barra(i).nos(2);
    n3 = barra(i).nos(3);
    
    disp('Deslocamentos Nodais:')
    fprintf('  Nó %d -> u: %5.4e, v: %5.4e\n', n1, barra(i).deslocamentoNodal(1), barra(i).deslocamentoNodal(2));
    fprintf('  Nó %d -> u: %5.4e, v: %5.4e\n', n2, barra(i).deslocamentoNodal(3), barra(i).deslocamentoNodal(4));
    fprintf('  Nó %d -> u: %5.4e, v: %5.4e\n', n3, barra(i).deslocamentoNodal(5), barra(i).deslocamentoNodal(6));
    fprintf('\n');
    
    disp('Tensões [σ_x; σ_y; τ_xy]:')
    disp(barra(i).tensao)
    
    disp('________________________________')
end

%% Salvando resultados em arquivo .txt

% Inicalização do arquivo
nomeArquivo = 'resultados_cst.txt';
fileID = fopen(nomeArquivo, 'w');

% Valores importados
fprintf(fileID, '=======================================================\n');
fprintf(fileID, '         RELATÓRIO DE RESULTADOS - ELEMENTO CST        \n');
fprintf(fileID, '=======================================================\n\n');

fprintf(fileID, '--- NÓS IMPORTADOS ---\n');
fprintf(fileID, '%-6s %-12s %-6s %-8s %-14s %-8s %-8s\n', ...
    'ID', 'Coord_X', 'Fixo_X', 'Carga_X', 'Coord_Y', 'Fixo_Y', 'Carga_Y');
fprintf(fileID, '%-6s %-12s %-6s %-8s %-14s %-8s %-8s\n', ...
    '--', '-------', '------', '-------', '-------', '------', '-------');

for i = 1:height(importNo)
    fprintf(fileID, '%-6d %-12.2f %-6d %-8.2f %-14.2f %-8d %-8.2f\n', ...
        importNo.Var1(i), ...
        importNo.Coordenada(i), ...
        importNo.Fixo(i), ...
        importNo.Carga(i), ...
        importNo.Coordenada_1(i), ...
        importNo.Fixo_1(i), ...
        importNo.Carga_1(i));
end
fprintf(fileID, '\n');

fprintf(fileID, '--- ELEMENTOS IMPORTADOS ---\n');
fprintf(fileID, '%-5s %-4s %-4s %-4s %-15s %-11s %-12s\n', ...
    'ID', 'N1', 'N2', 'N3', 'Elasticidade(E)', 'Poisson(V)', 'Espessura(t)');
fprintf(fileID, '%-5s %-4s %-4s %-4s %-15s %-11s %-12s\n', ...
    '--', '--', '--', '--', '---------------', '----------', '------------');

for i = 1:height(importBarra)
    fprintf(fileID, '%-5d %-4d %-4d %-4d %-15.1f %-11.2f %-12.2f\n', ...
        importBarra.ID(i), ...
        importBarra.N1(i), ...
        importBarra.N2(i), ...
        importBarra.N3(i), ...
        importBarra.E_elasticidade_(i), ...
        importBarra.V_poisson_(i), ...
        importBarra.t_espessura_(i));
end

% Valores calculados
fprintf(fileID, '\n=======================================================\n');
fprintf(fileID, '                  VALORES CALCULADOS                   \n');
fprintf(fileID, '=======================================================\n\n');

for i = 1:length(barra)
    fprintf(fileID, '=== Elemento CST %d ===\n', i);
    
    n1 = barra(i).nos(1);
    n2 = barra(i).nos(2);
    n3 = barra(i).nos(3);
    
    fprintf(fileID, 'Deslocamentos Nodais:\n');
    fprintf(fileID, '  Nó %d -> u: %5.4e, v: %5.4e\n', n1, barra(i).deslocamentoNodal(1), barra(i).deslocamentoNodal(2));
    fprintf(fileID, '  Nó %d -> u: %5.4e, v: %5.4e\n', n2, barra(i).deslocamentoNodal(3), barra(i).deslocamentoNodal(4));
    fprintf(fileID, '  Nó %d -> u: %5.4e, v: %5.4e\n', n3, barra(i).deslocamentoNodal(5), barra(i).deslocamentoNodal(6));
    fprintf('\n');
    
    fprintf(fileID, 'Tensões [sigma_x; sigma_y; tau_xy]:\n');
    fprintf(fileID, '  %5.4e\n', barra(i).tensao(1));
    fprintf(fileID, '  %5.4e\n', barra(i).tensao(2));
    fprintf(fileID, '  %5.4e\n', barra(i).tensao(3));
    
    fprintf(fileID, '________________________________\n\n');
end

% Finaliza escrita
fclose(fileID);
disp('Resultados exportados com sucesso para o arquivo "resultados_cst.txt"!');
