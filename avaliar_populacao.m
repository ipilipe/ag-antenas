function [fit, cob, nAnt] = avaliar_populacao(ATIVO, X, Y, GX, GY, p)
% AVALIAR_POPULACAO  Calcula fitness, cobertura e numero de antenas.
%
%   A area coberta e calculada por uma grade de pontos dentro da regiao.
%   Um ponto conta como coberto se estiver dentro de PELO MENOS uma antena.
%   Assim:
%     - so a parte do circulo que fica dentro da regiao e contada;
%     - areas sobrepostas sao contadas uma unica vez (uniao dos circulos).
%
%   Saidas:
%     fit  : fitness de cada individuo
%     cob  : fracao da regiao coberta (0 a 1)
%     nAnt : quantidade de antenas ligadas

    N    = size(ATIVO, 1);
    cob  = zeros(N, 1);
    nAnt = sum(ATIVO, 2);
    r2   = p.raio^2;

    for i = 1:N
        ativas = find(ATIVO(i, :));
        if isempty(ativas)
            continue;
        end
        coberto = false(size(GX));
        for j = ativas
            coberto = coberto | ((GX - X(i, j)).^2 + (GY - Y(i, j)).^2 <= r2);
        end
        cob(i) = mean(coberto);
    end

    fit = p.pesoCobertura * cob - p.penalidadeAntena * nAnt;
end
