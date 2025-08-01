% demod.m
% Esquema 1 - Paso 7: Demodulación OFDM + reconstrucción y evaluación
% Señal original: sensores temperatura, humedad, luz

clear; clc; close all;

% -------------------------
% Parámetros
% -------------------------
M = 8;             % 8-PSK
k = log2(M);       % bits/símbolo
N = 64;            % subportadoras
cp_len = 16;       % prefijo cíclico
mu = 255;
pilot_pos = 1;

% -------------------------
% Cargar señal OFDM transmitida
% -------------------------
load('raw_signal.mat');        % Señal original x
x_mu = compand(x, mu, max(abs(x)), 'mu/compressor');
x_norm = rescale(x_mu, 0, 1);
symbols_q = round(x_norm * (2^k - 1));
data_bin = de2bi(symbols_q, k, 'left-msb');
tx_bits = reshape(data_bin.', [], 1);

% Remodular OFDM (idéntico al paso 6 para reproducir el canal)
num_bits = floor(length(tx_bits)/(k*N)) * k*N;
tx_bits = tx_bits(1:num_bits);
symbols = bi2de(reshape(tx_bits, k, []).', 'left-msb');
mod_data = pskmod(symbols, M, pi/M);
mod_blocks = reshape(mod_data, N, []);
ofdm_tx = [];

for i = 1:size(mod_blocks,2)
    block = mod_blocks(:,i);
    block(pilot_pos) = 1 + 1i;
    time_block = ifft(block);
    cp = time_block(end - cp_len + 1:end);
    ofdm_symbol = [cp; time_block];
    ofdm_tx = [ofdm_tx; ofdm_symbol];
end

% Transmitir por canal
snr_db = 20;
rx = channel_mod(ofdm_tx, snr_db);

% -------------------------
% Recepción y demodulación
% -------------------------
rx_blocks = reshape(rx, N + cp_len, []);
rx_blocks = rx_blocks(cp_len+1:end, :);
rx_freq = fft(rx_blocks, N);

% Ecualización MMSE usando piloto en subportadora 1
pilot_rx = rx_freq(pilot_pos, :);
H_est = repmat(pilot_rx, N, 1);  % asume canal plano por subportadora
rx_eq = rx_freq ./ H_est;        % ecualización MMSE básica

% Quitar piloto y demodular
rx_eq(pilot_pos, :) = [];  % quitar subportadora piloto
rx_symbols = rx_eq(:);
rx_symb = pskdemod(rx_symbols, M, pi/M);
rx_bits = de2bi(rx_symb, k, 'left-msb');
rx_bits = reshape(rx_bits.', [], 1);

% -------------------------
% Reconstrucción de señal
% -------------------------
% Truncar para que coincidan longitudes
min_len = min(length(rx_bits), length(tx_bits));
rx_bits = rx_bits(1:min_len);
tx_bits = tx_bits(1:min_len);

% Reconstrucción de símbolo a señal
rx_bin_matrix = reshape(rx_bits, k, []).';
rx_sym_q = bi2de(rx_bin_matrix, 'left-msb');
rx_norm = rx_sym_q / (2^k - 1);
rx_mu = rescale(rx_norm, 0, 1);
x_rec = compand(rx_mu, mu, max(abs(x)), 'mu/expander');

% Truncar x original a la misma longitud
x_orig = x(1:length(x_rec));

% -------------------------
% Evaluación
% -------------------------
mse_val = mean((x_orig - x_rec).^2);
snr_val = snr(x_orig, x_orig - x_rec);

fprintf('\n📊 MÉTRICAS DE RECONSTRUCCIÓN:\n');
fprintf('SNR reconstruida: %.2f dB\n', snr_val);
fprintf('MSE reconstruida: %.6f\n', mse_val);

% -------------------------
% Guardar figura
% -------------------------
figure;
plot(x_orig, 'b'); hold on;
plot(x_rec, 'r--');
legend('Original', 'Reconstruida');
xlabel('Muestra'); ylabel('Amplitud');
title('Reconstrucción de señal IoT');
grid on;
saveas(gcf, 'reconstruccion.png');
disp('✅ Imagen guardada como reconstruccion.png');

% -------------------------
% Guardar métricas CSV
% -------------------------
T = table(snr_val, mse_val, ...
    'VariableNames', {'SNR_dB', 'MSE'});
writetable(T, 'metricas_reconstruccion.csv');
disp('📄 Métricas guardadas en metricas_reconstruccion.csv');