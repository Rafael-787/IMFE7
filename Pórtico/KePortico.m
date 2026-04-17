function [Ke] = KePortico(barra)
E = barra.elasticidade;
A = barra.area;
I = barra.inercia;
L = barra.comprimento;

k1 = E*A/L;
k2 = 12*E*I/(L^3);
k3 = 6*E*I/(L^2);
k4 = 4*E*I/L;
k5 = 2*E*I/L;

% Montagem da Matriz de Rigidez Local (k)
Ke = [ k1,  0,   0,  -k1,  0,   0;
      0,   k2,  k3,  0,  -k2,  k3;
      0,   k3,  k4,  0,  -k3,  k5;
     -k1,  0,   0,   k1,  0,   0;
      0,  -k2, -k3,  0,   k2, -k3;
      0,   k3,  k5,  0,  -k3,  k4 ];

end