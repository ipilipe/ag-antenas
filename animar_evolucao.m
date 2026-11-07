function animar_evolucao(res, passo, arquivoVideo)
% ANIMAR_EVOLUCAO  Mostra o melhor individuo mudando a cada geracao.
%   Ideal para o video: da para ver as antenas "se arrumando" na regiao.
%
%   animar_evolucao(res)                     anima de 1 em 1 geracao
%   animar_evolucao(res, 2)                  anima de 2 em 2 geracoes
%   animar_evolucao(res, 1, 'evolucao.mp4')  tambem grava um video MP4

    if nargin < 2 || isempty(passo)
        passo = 1;
    end
    gravar = nargin >= 3 && ~isempty(arquivoVideo);

    p  = res.params;
    hs = res.historico;
    L  = p.lado;
    G  = numel(hs.melhorFitness);
    t  = linspace(0, 2*pi, 200);
    n  = p.resolucao;
    GX = res.grade.GX;
    GY = res.grade.GY;

    fig = figure('Name', 'Evolucao do AG', 'Color', 'w', 'Position', [150 100 1100 480]);

    if gravar
        vw = VideoWriter(arquivoVideo, 'MPEG-4');
        vw.FrameRate = 12;
        open(vw);
    end

    for g = [1:passo:G, G]
        clf(fig);

        % ---- Regiao com o melhor individuo da geracao g ----
        subplot(1, 2, 1); hold on; axis equal; box on;
        coberto = false(size(GX));
        ativas = find(hs.melhorAtivo(g, :));
        for j = ativas
            coberto = coberto | ((GX - hs.melhorX(g, j)).^2 + (GY - hs.melhorY(g, j)).^2 <= p.raio^2);
        end
        imagesc([GX(1) GX(end)], [GY(1) GY(end)], reshape(coberto, n, n));
        colormap(gca, [1 1 1; 0.70 0.85 1.00]);
        set(gca, 'YDir', 'normal');
        for j = ativas
            plot(hs.melhorX(g, j) + p.raio*cos(t), hs.melhorY(g, j) + p.raio*sin(t), 'b--');
            plot(hs.melhorX(g, j), hs.melhorY(g, j), 'r^', 'MarkerFaceColor', 'r', 'MarkerSize', 9);
        end
        rectangle('Position', [0 0 L L], 'EdgeColor', 'k', 'LineWidth', 2);
        xlim([-p.raio, L + p.raio]); ylim([-p.raio, L + p.raio]);
        xlabel('x (km)'); ylabel('y (km)');
        title(sprintf('Geracao %d | %d antena(s) | cobertura %.2f%%', ...
            g, hs.melhorNumAntenas(g), 100*hs.melhorCobertura(g)));

        % ---- Curva de fitness ate a geracao g ----
        subplot(1, 2, 2); hold on; grid on;
        plot(1:g, hs.melhorFitness(1:g), 'LineWidth', 2);
        plot(1:g, hs.mediaFitness(1:g), 'LineWidth', 1.2);
        xlim([1 G]);
        ylim([min(hs.mediaFitness) - 0.05, max(hs.melhorFitness) + 0.05]);
        xlabel('Geracao'); ylabel('Fitness');
        legend('Melhor', 'Media', 'Location', 'southeast');
        title(sprintf('Fitness do melhor: %.4f', hs.melhorFitness(g)));

        drawnow;
        if gravar
            writeVideo(vw, getframe(fig));
        else
            pause(0.05);
        end
    end

    if gravar
        close(vw);
        fprintf('Video salvo em %s\n', arquivoVideo);
    end
end
