clc;
clear;
% Cálculo de portico

% Importando valores
importNo = readtable('Dados de entrada.xlsx', 'Sheet', 'Dados', 'Range', 'A3:I14');
importNo = rmmissing(importNo)

importBarra = readtable('Dados de entrada.xlsx', 'Sheet', 'Dados', 'Range', 'L3:R14');
importBarra = rmmissing(importBarra)

% Definindo valores nos objetos
for i = 1:height(importNo) % nós
    id = importNo.Var1(i);
    x = importNo.Coordenada(i);
    y = importNo.Coordenada_1(i);
    cx = importNo.Carga(i);
    cy = importNo.Carga_1(i);
    cr = importNo.Momento(i);
    tx = double(importNo.Fixo(i));
    ty = double(importNo.Fixo_1(i));
    tr = double(importNo.Fixo_2(i));

    no(id).coordenada = [x y]; %(x,y)
    no(id).restricao = [tx ty tr]; % 1 para travado e 0 para livre (x,y,rotação)
    no(id).carga = [cx cy cr];

end

for i=1:height(importBarra)
    id = importBarra.ID(i);
    ni = importBarra.N_Incial(i);
    nf = importBarra.N_Final(i);

    barra(id).nos = [ni nf];
    barra(id).elasticidade = importBarra.E_elasticidade_(i);
    barra(id).area = importBarra.A__rea_(i);
    barra(id).inercia = importBarra.I_in_rcia_(i);
    barra(id).q = importBarra.q_cargaDistribu_da_(i);

end
% ___________________________________________________________________

% Iteração sobre as barras
for i = 1:length(barra)
    n1 = no(barra(i).nos(1));
    n2 = no(barra(i).nos(2));
    barra(i).comprimento = util.distancia(n1,n2); 
    barra(i).transformada = util.transformadaPortico(util.angulo(n1,n2));
    barra(i).ke = KePortico(barra(i));

    barra(i).ke_global = barra(i).transformada' * barra(i).ke * barra(i).transformada;
end

% Iteração sobre nos

dof = length(no(1).restricao);

% Matriz global

KG = Kg(barra,no,dof);

% Adiciona condição de contorno na matriz global

trava = [no.restricao]';
F = [no.carga]';

% Processamento das cargas distribuídas
for i = 1:length(barra)

    % Verifica se a barra atual possui o parâmetro 'q'
    if isfield(barra, 'q') && ~isempty(barra(i).q)
        q = barra(i).q;
    else
        q = 0; % Assume zero se o campo não existir
    end
    L = barra(i).comprimento;
    
    % Vetor de Forças Nodais Equivalentes (Local) [Fx1, Fy1, M1, Fx2, Fy2, M2]'
    % Assume q constante perpendicular ao eixo da barra
    barra(i).F_eq_local = [0; q*L/2; q*L^2/12; 0; q*L/2; -q*L^2/12];
    
    % Transforma para global e soma no vetor F da estrutura
    Mt = barra(i).transformada;
    F_eq_global = Mt' * barra(i).F_eq_local;
    
    no1 = barra(i).nos(1);
    no2 = barra(i).nos(2);
    gl_elemento = [(no1-1)*3+1 : no1*3, (no2-1)*3+1 : no2*3]; 
    
    F(gl_elemento) = F(gl_elemento) - F_eq_global;
end

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

for i = 1:length(barra)
    % Identifica os graus de liberdade (GL) globais da barra atual
    n1 = barra(i).nos(1);
    n2 = barra(i).nos(2);
    gl_elemento = [(n1-1)*3+1 : n1*3, (n2-1)*3+1 : n2*3]; 
    
    % Extração e transformação
    deslocGlobalElemento = deslocamento(gl_elemento);
    
    % Salva resultados diretamente na estrutura da barra
    barra(i).deslocamentoLocal = barra(i).transformada * deslocGlobalElemento;
    barra(i).forcaLocal = KePortico(barra(i)) * barra(i).deslocamentoLocal;

    % Soma as forças de engastamento perfeito (se existirem)
    if isfield(barra, 'F_eq_local') && ~isempty(barra(i).F_eq_local)
        barra(i).forcaLocal = barra(i).forcaLocal + barra(i).F_eq_local;
    end
end

for i = 1:length(barra)
    disp("Barra" + i)
    disp("Deslocamento local")
    disp(barra(i).deslocamentoLocal)
    disp("ForçaLocal")
    disp(barra(i).forcaLocal)
    disp("________________________________")
end