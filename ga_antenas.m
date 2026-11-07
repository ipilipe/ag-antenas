function res = ga_antenas(params)
% GA_ANTENAS  Algoritmo Genetico para posicionamento de antenas.
%
%   res = ga_antenas()        roda com os parametros padrao
%   res = ga_antenas(params)  roda com os parametros informados (struct)
%
%   Representacao (cromossomo) de um individuo:
%     Cada individuo tem maxAntenas "vagas". Cada vaga guarda 3 genes:
%       ativo (0/1), x (km), y (km)
%     Ex. com 5 vagas: [a1 x1 y1 | a2 x2 y2 | ... | a5 x5 y5]
%     Na implementacao os genes ficam em 3 matrizes N x maxAntenas:
%     ATIVO, X e Y (linha = individuo, coluna = vaga).
%
%   Operadores:
%     Selecao    : torneio
%     Cruzamento : uniforme por vaga (troca antenas inteiras entre os pais)
%     Mutacao    : liga/desliga antena + deslocamento gaussiano da posicao
%                  (passo diminui ao longo das geracoes)
%     Elitismo   : os melhores individuos passam direto
%
%   Saida (struct res):
%     melhor   : struct com ativo, x, y, numAntenas, cobertura, areaCoberta, fitness
%     historico: curvas por geracao (melhor fitness, fitness medio,
%                cobertura do melhor, antenas do melhor)
%     params   : parametros usados
%     grade    : pontos usados no calculo de area (para o grafico)

    if nargin < 1
        params = struct();
    end
    p = parametros_padrao(params);

    if ~isempty(p.semente)
        rng(p.semente);
    end

    % ---------- Grade de pontos para o calculo de area ----------
    h = p.lado / p.resolucao;
    v = (h/2):h:(p.lado - h/2);
    [GX, GY] = meshgrid(v, v);
    GX = GX(:);
    GY = GY(:);

    N = p.tamPopulacao;
    M = p.maxAntenas;

    % ---------- Populacao inicial ----------
    ATIVO = rand(N, M) < p.probAtivaInicial;
    ATIVO = garantir_uma_antena(ATIVO);
    X = rand(N, M) * p.lado;
    Y = rand(N, M) * p.lado;

    hist.melhorFitness    = zeros(p.numGeracoes, 1);
    hist.mediaFitness     = zeros(p.numGeracoes, 1);
    hist.melhorCobertura  = zeros(p.numGeracoes, 1);
    hist.melhorNumAntenas = zeros(p.numGeracoes, 1);
    hist.melhorAtivo      = false(p.numGeracoes, M);   % melhor individuo de cada geracao
    hist.melhorX          = zeros(p.numGeracoes, M);   % (usado na animacao)
    hist.melhorY          = zeros(p.numGeracoes, M);
    hist.desvioFitness    = zeros(p.numGeracoes, 1);   % diversidade da populacao

    for g = 1:p.numGeracoes
        % ----- Avaliacao -----
        [fit, cob, nAnt] = avaliar_populacao(ATIVO, X, Y, GX, GY, p);
        [~, ordem] = sort(fit, 'descend');
        b = ordem(1);

        hist.melhorFitness(g)    = fit(b);
        hist.mediaFitness(g)     = mean(fit);
        hist.melhorCobertura(g)  = cob(b);
        hist.melhorNumAntenas(g) = nAnt(b);
        hist.melhorAtivo(g, :)   = ATIVO(b, :);
        hist.melhorX(g, :)       = X(b, :);
        hist.melhorY(g, :)       = Y(b, :);
        hist.desvioFitness(g)    = std(fit);

        if p.mostrarProgresso && (g == 1 || mod(g, 10) == 0 || g == p.numGeracoes)
            fprintf('Geracao %4d | fitness = %.4f | cobertura = %6.2f%% | antenas = %d\n', ...
                g, fit(b), 100*cob(b), nAnt(b));
        end

        if g == p.numGeracoes
            break;   % ultima geracao avaliada, nao precisa gerar filhos
        end

        % Passo da mutacao diminui linearmente: explora no inicio, refina no fim
        sigma = p.lado * (p.sigmaInicial - (p.sigmaInicial - p.sigmaFinal) * (g - 1) / max(1, p.numGeracoes - 2));

        % ----- Elitismo -----
        novoA = false(N, M);
        novoX = zeros(N, M);
        novoY = zeros(N, M);
        E = p.numElite;
        novoA(1:E, :) = ATIVO(ordem(1:E), :);
        novoX(1:E, :) = X(ordem(1:E), :);
        novoY(1:E, :) = Y(ordem(1:E), :);

        % ----- Selecao, cruzamento e mutacao -----
        k = E + 1;
        while k <= N
            p1 = torneio(fit, p.tamTorneio);
            p2 = torneio(fit, p.tamTorneio);

            aA = ATIVO(p1, :); aX = X(p1, :); aY = Y(p1, :);
            bA = ATIVO(p2, :); bX = X(p2, :); bY = Y(p2, :);

            if rand < p.taxaCruzamento
                mascara = rand(1, M) < 0.5;          % vagas que serao trocadas
                [aA(mascara), bA(mascara)] = deal(bA(mascara), aA(mascara));
                [aX(mascara), bX(mascara)] = deal(bX(mascara), aX(mascara));
                [aY(mascara), bY(mascara)] = deal(bY(mascara), aY(mascara));
            end

            [aA, aX, aY] = mutar(aA, aX, aY, p, sigma);
            novoA(k, :) = aA; novoX(k, :) = aX; novoY(k, :) = aY;
            k = k + 1;

            if k <= N
                [bA, bX, bY] = mutar(bA, bX, bY, p, sigma);
                novoA(k, :) = bA; novoX(k, :) = bX; novoY(k, :) = bY;
                k = k + 1;
            end
        end

        ATIVO = novoA;
        X = novoX;
        Y = novoY;
    end

    % ---------- Melhor solucao da ultima geracao ----------
    melhor.ativo       = ATIVO(b, :);
    melhor.x           = X(b, :);
    melhor.y           = Y(b, :);
    melhor.numAntenas  = nAnt(b);
    melhor.cobertura   = cob(b);
    melhor.areaCoberta = cob(b) * p.areaRegiao;
    melhor.fitness     = fit(b);
    melhor.posicoes    = [X(b, ATIVO(b, :))', Y(b, ATIVO(b, :))'];

    % Geracao em que o melhor fitness final apareceu pela primeira vez
    melhor.geracaoConvergencia = find(hist.melhorFitness >= fit(b) - 1e-9, 1, 'first');

    res.melhor    = melhor;
    res.historico = hist;
    res.params    = p;
    res.grade.GX  = GX;
    res.grade.GY  = GY;
end

% =====================================================================
function idx = torneio(fit, k)
% Sorteia k individuos e devolve o de maior fitness.
    candidatos = randi(numel(fit), 1, k);
    [~, pos] = max(fit(candidatos));
    idx = candidatos(pos);
end

% =====================================================================
function [A, X, Y] = mutar(A, X, Y, p, sigma)
% Liga/desliga antenas e desloca suas posicoes.
% A posicao e limitada a [0, lado], entao a antena nunca sai da regiao.
    M = numel(A);
    for j = 1:M
        if rand < p.taxaMutacaoAtivacao
            A(j) = ~A(j);
        end
        if rand < p.taxaMutacao
            X(j) = min(max(X(j) + sigma * randn, 0), p.lado);
            Y(j) = min(max(Y(j) + sigma * randn, 0), p.lado);
        end
    end
    if ~any(A)
        A(randi(M)) = true;   % todo individuo precisa ter pelo menos 1 antena
    end
end

% =====================================================================
function A = garantir_uma_antena(A)
    [N, M] = size(A);
    for i = 1:N
        if ~any(A(i, :))
            A(i, randi(M)) = true;
        end
    end
end
