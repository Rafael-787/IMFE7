function [K] = Kg(barra,nos,dof)

dofPorNo = dof; % Quantidade de dof por nó

K = zeros(dofPorNo*length(nos)); % Inicializa global

for e = 1:length(barra)
    % Extrai os nós do elemento (barra)
    no1 = barra(e).nos(1);
    no2 = barra(e).nos(2);
    
    % Lógica Universal de Índices
    idx1 = (no1-1)*dofPorNo + (1:dofPorNo);
    idx2 = (no2-1)*dofPorNo + (1:dofPorNo);
    
    indices = [idx1, idx2]; % Vetor de DoFs globais do elemento
    
    % Montagem na matriz global
    K(indices, indices) = K(indices, indices) + barra(e).ke_global;
end

end