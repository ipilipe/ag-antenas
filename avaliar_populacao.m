function [fit, cob, nAnt] = avaliar_populacao(ATIVO, X, Y, ~, ~, p)
% AVALIAR_POPULACAO  Calcula fitness, cobertura e numero de antenas.
%
%   A regiao e dividida em uma grade de p.resolucao x p.resolucao celulas.
%   Uma celula conta como coberta se o seu centro estiver dentro de PELO
%   MENOS uma antena. Assim:
%     - so a parte do circulo que fica dentro da regiao e contada;
%     - areas sobrepostas sao contadas uma unica vez (uniao dos circulos).
%
%   Para ficar rapido mesmo com grades grandes, cada antena so testa as
%   celulas do quadrado que a envolve (bounding box), e nao a regiao toda.
%   A uniao entre antenas e feita pelos indices das celulas (unique).
%
%   Os argumentos 4 e 5 (grade) sao ignorados e mantidos so por
%   compatibilidade: a grade e calculada a partir de p.lado e p.resolucao.
%
%   Saidas:
%     fit  : fitness de cada individuo
%     cob  : fracao da regiao coberta (0 a 1)
%     nAnt : quantidade de antenas ligadas

    N    = size(ATIVO, 1);
    cob  = zeros(N, 1);
    nAnt = sum(ATIVO, 2);
    n    = p.resolucao;
    h    = p.lado / n;          % tamanho de cada celula (km)
    r    = p.raio;
    r2   = r^2;

    for i = 1:N
        ativas = find(ATIVO(i, :));
        if isempty(ativas)
            continue;
        end
        indices = cell(numel(ativas), 1);
        for k = 1:numel(ativas)
            j = ativas(k);
            % celulas cujo centro pode estar dentro do circulo
            ix0 = max(1, ceil((X(i, j) - r) / h + 0.5));
            ix1 = min(n, floor((X(i, j) + r) / h + 0.5));
            iy0 = max(1, ceil((Y(i, j) - r) / h + 0.5));
            iy1 = min(n, floor((Y(i, j) + r) / h + 0.5));
            if ix1 < ix0 || iy1 < iy0
                indices{k} = zeros(0, 1);
                continue;
            end
            ix = ix0:ix1;                          % colunas (eixo x)
            iy = (iy0:iy1)';                       % linhas  (eixo y)
            dx2 = ((ix - 0.5) * h - X(i, j)).^2;   % vetor linha
            dy2 = ((iy - 0.5) * h - Y(i, j)).^2;   % vetor coluna
            dentro = (dy2 + dx2) <= r2;            % matriz (linhas x colunas)
            [a, b] = find(dentro);
            indices{k} = (iy(a) - 1) * n + ix(b)';
        end
        cob(i) = numel(unique(vertcat(indices{:}))) / n^2;
    end

    fit = p.pesoCobertura * cob - p.penalidadeAntena * nAnt;
end
