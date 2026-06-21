function [K] = Kg(barra,nos,dof)

dofPorNo = dof; % Quantidade de dof por nó

K = zeros(dofPorNo*length(nos)); % Inicializa global

for e = 1:length(barra)
    % Extrai os 3 nós do elemento triangular CST
    no1 = barra(e).nos(1);
    no2 = barra(e).nos(2);
    no3 = barra(e).nos(3);
    
    % Lógica de Índices para cada nó (2 DoFs por nó)
    idx1 = (no1-1)*dofPorNo + (1:dofPorNo);
    idx2 = (no2-1)*dofPorNo + (1:dofPorNo);
    idx3 = (no3-1)*dofPorNo + (1:dofPorNo);
    
    % Vetor de DoFs globais do elemento (agora com 6 posições)
    indices = [idx1, idx2, idx3]; 
    
    % Montagem (espalhamento) na matriz de rigidez global
    K(indices, indices) = K(indices, indices) + barra(e).ke;
end

end