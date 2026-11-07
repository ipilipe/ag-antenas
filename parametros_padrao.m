function p = parametros_padrao(params)
% PARAMETROS_PADRAO  Junta os parametros informados com os valores padrao.
%   p = parametros_padrao(params) devolve uma struct com todos os
%   parametros do problema e do Algoritmo Genetico. Qualquer campo
%   informado em "params" substitui o valor padrao.

    if nargin < 1 || isempty(params)
        params = struct();
    end

    % ---------------- Parametros do problema ----------------
    p.areaRegiao  = 200;              % area da regiao quadrada (km^2)
    p.lado        = [];               % lado da regiao (km); se vazio, usa sqrt(areaRegiao)
    p.raio        = 10;               % raio de cada antena (km), diametro = 20 km
    p.maxAntenas  = 5;                % numero maximo de antenas
    p.resolucao   = 150;              % pontos por eixo na grade de calculo de area

    % ---------------- Parametros da funcao fitness ----------------
    % fitness = pesoCobertura * cobertura(0 a 1) - penalidadeAntena * numAntenas
    p.pesoCobertura    = 1.0;
    p.penalidadeAntena = 0.05;        % cada antena "custa" 5 pontos percentuais de cobertura

    % ---------------- Parametros do Algoritmo Genetico ----------------
    p.tamPopulacao        = 60;
    p.numGeracoes         = 150;
    p.taxaCruzamento      = 0.85;
    p.taxaMutacao         = 0.15;     % probabilidade de mexer na posicao de cada antena
    p.taxaMutacaoAtivacao = 0.05;     % probabilidade de ligar/desligar cada antena
    p.sigmaInicial        = 0.20;     % passo da mutacao no inicio (fracao do lado)
    p.sigmaFinal          = 0.01;     % passo da mutacao no fim (fracao do lado)
    p.numElite            = 2;        % individuos copiados direto para a proxima geracao
    p.tamTorneio          = 3;        % participantes do torneio de selecao
    p.probAtivaInicial    = 0.5;      % chance de cada antena nascer ligada
    p.semente             = [];       % semente aleatoria (vazio = aleatorio)
    p.mostrarProgresso    = true;     % imprime o andamento no Command Window

    % Sobrescreve com o que foi informado
    campos = fieldnames(params);
    for k = 1:numel(campos)
        p.(campos{k}) = params.(campos{k});
    end

    if isempty(p.lado)
        p.lado = sqrt(p.areaRegiao);
    end
    p.areaRegiao = p.lado^2;
    p.numElite = min(p.numElite, p.tamPopulacao);
end
