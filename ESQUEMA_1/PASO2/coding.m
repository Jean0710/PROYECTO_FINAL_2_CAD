% coding.m
% Esquema 1 - Paso 2: Codificación PCM y DPCM
% Señal proveniente de sensores: temperatura, humedad y luz
% Entregables: coding.m, figuras FFT, tabla CSV

clear; clc; close all;

% -------------------------
% Cargar señal original
% -------------------------
load('raw_signal.mat');  % Variables: x (combinación de 3 sensores), fs

% -------------------------
% Configuraciones
% -------------------------
bit_depths = [8, 12, 16];             % Profundidades de cuantización PCM
snr_pcm = zeros(size(bit_depths));
snr_dpcm = zeros(size(bit_depths));
bit_rates = bit_depths * fs;         % Tasa de bits en bps

% -------------------------
% Procesamiento para cada resolución
% -------------------------
for i = 1:length(bit_depths)
    B = bit_depths(i);

    % -------- PCM --------
    xmax = max(abs(x));
    x_pcm = round((x + xmax) / (2*xmax) * (2^B - 1));       % Codificación PCM
    x_rec = (x_pcm / (2^B - 1)) * 2*xmax - xmax;            % Reconstrucción
    snr_pcm(i) = snr(x, x - x_rec);                         % SNR PCM

    % -------- DPCM --------
    x_dif = [x(1); diff(x)];                                % Diferencias sucesivas
    xmax_d = max(abs(x_dif));
    dpcm = round((x_dif + xmax_d) / (2*xmax_d) * (2^B - 1));
    dpcm_rec = (dpcm / (2^B - 1)) * 2*xmax_d - xmax_d;
    x_dpcm = cumsum(dpcm_rec);                             % Reconstrucción por integración
    snr_dpcm(i) = snr(x, x - x_dpcm);                       % SNR DPCM

    % -------- FFT PCM --------
    N = length(x_rec);
    X = abs(fft(x_rec, N));
    f = linspace(0, fs, N);
    halfN = floor(N/2);

    figure('Name',['PCM FFT - ' num2str(B) ' bits']);
    plot(f(1:halfN), 20*log10(X(1:halfN)));
    title(['Espectro PCM (' num2str(B) '-bit)']);
    xlabel('Frecuencia [Hz]');
    ylabel('Magnitud [dB]');
    grid on;
    saveas(gcf, ['fft_pcm_' num2str(B) 'bit.png']);
end

% -------------------------
% Crear tabla y exportar como CSV
% -------------------------
tabla = table( ...
    bit_depths(:), ...
    bit_rates(:), ...
    snr_pcm(:), ...
    snr_dpcm(:), ...
    'VariableNames', {'Bits', 'Bitrate_bps', 'SNR_PCM_dB', 'SNR_DPCM_dB'});

disp('📊 Tabla Bit-rate vs SNR (PCM y DPCM)');
disp(tabla);

% Exportar solo como CSV
writetable(tabla, 'tabla_snr_pcm_dpcm.csv');
disp('✅ Tabla exportada como tabla_snr_pcm_dpcm.csv');