classdef util
    %UTIL Funções gerais
    %   Funções gerais de suporte para manipulação dos cálculos para
    %   elementos finitos


    methods (Static)
        function [K] = transformada(Ke,a)

            transformada = [cosd(a) sind(a) 0 0;
                0 0 cosd(a) sind(a)];
        
            K = transformada' * Ke * transformada;
        end
        
        function [M] = transformadaPortico(a)
            M = [ cosd(a)  sind(a)  0   0       0       0;
                              -sind(a)  cosd(a)  0   0       0       0;
                                 0       0       1   0       0       0;
                                 0       0       0   cosd(a)  sind(a)  0;
                                 0       0       0  -sind(a)  cosd(a)  0;
                                 0       0       0   0       0       1 ];
        
            %M = MTransformacao' * Ke * MTransformacao;
        end

        function d = distancia(n1,n2)
            n1 = n1.coordenada;
            n2 = n2.coordenada;
        
            x1 = n1(1);
            x2 = n2(1);
        
            y1 = n1(2);
            y2 = n2(2);
        
            d = sqrt((x2-x1)^2 + (y2-y1)^2);
        end
        
        function rho = angulo(n1,n2)
            n1 = n1.coordenada;
            n2 = n2.coordenada;
            
            x1 = n1(1);
            x2 = n2(1);
        
            y1 = n1(2);
            y2 = n2(2);
        
            rho = atand((y2-y1)/(x2-x1));
        end
    end
end