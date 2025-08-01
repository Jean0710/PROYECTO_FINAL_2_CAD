% channel_mod.m
% Esquema 1 - Paso 4: Canal multipath ITU Pedestrian A + AWGN
% Fuente: sensores de temperatura, humedad y luz

function y_out = channel_mod(x_in, snr_db)
    % x_in   : señal de entrada (vector columna)
    % snr_db : relación señal/ruido deseada (en dB)
    % y_out  : señal afectada por canal multipath + ruido

    % -------------------------
    % Validaciones
    % -------------------------
    if size(x_in, 2) > 1
        x_in = x_in(:);  % asegurar columna
    end

    % -------------------------
    % Modelo de canal ITU PedA (4 trayectorias)
    % -------------------------
    % Retardos aproximados (en muestras)
    delays = [0, 1, 2, 4];  % basado en 1000 Hz
    gains_dB = [0, -9.7, -19.2, -22.8];
    gains_lin = 10.^(gains_dB/20);  % convertir dB a lineal

    % Crear respuesta al impulso del canal
    max_delay = delays(end);
    h = zeros(max_delay+1, 1);
    h(delays+1) = gains_lin .* (randn(1,4) + 1i*randn(1,4)) / sqrt(2);  % Rayleigh fading

    % Filtrado por canal multipath
    y_channel = conv(x_in, h, 'same');

    % Añadir ruido AWGN
    y_out = awgn(y_channel, snr_db, 'measured');
end