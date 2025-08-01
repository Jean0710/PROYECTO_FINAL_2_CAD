% acquisition.m
% Esquema 1 - Paso 1: Simulación de sensores IoT
% Sensores: temperatura, humedad, luz
% Entregables: acquisition.m, raw_signal.mat, grafica_tiempo_frecuencia.png

clear; clc; close all;

% -------------------------
% Parámetros de simulación
% -------------------------
fs = 1000;                  % Frecuencia de muestreo (Hz)
duration = 10;              % Duración de la señal (segundos)
t = (0:1/fs:duration-1/fs)'; % Vector de tiempo (columna)

% -------------------------
% Simulación de señales IoT
% -------------------------

% Sensor 1: Temperatura (°C)
temp = 25 + 0.5*sin(2*pi*0.2*t) + 0.2*randn(size(t));

% Sensor 2: Humedad relativa (%)
hume = 60 + 10*sin(2*pi*0.05*t) + 5*randn(size(t));

% Sensor 3: Luz (lux)
light = 500 + 300*sin(2*pi*0.07*t) + 50*randn(size(t));

% -------------------------
% Normalizar y multiplexar
% -------------------------
signals = [temp hume light];                 % Matriz N×3
signals_norm = rescale(signals, -1, 1);      % Normalizar [-1, 1]
x = reshape(signals_norm.', [], 1);          % Multiplexar por tiempo

% -------------------------
% Guardar señal
% -------------------------
save('raw_signal.mat', 'x', 'fs');
disp('✅ raw_signal.mat creado con sensores: temperatura, humedad y luz');

% -------------------------
% Gráfica señal + espectro
% -------------------------
figure('Name','Señal IoT - Tiempo y Frecuencia');

subplot(2,1,1);
plot((0:length(x)-1)/fs, x, 'b');
xlabel('Tiempo [s]');
ylabel('Amplitud normalizada');
title('Señal combinada (temperatura, humedad, luz)');
grid on;

N = length(x);
X = abs(fft(x));
f = linspace(0, fs, N);
subplot(2,1,2);
plot(f(1:floor(N/2)), 20*log10(X(1:floor(N/2))), 'r');
xlabel('Frecuencia [Hz]');
ylabel('Magnitud [dB]');
title('Espectro de la señal (FFT)');
grid on;

% -------------------------
% Guardar imagen
% -------------------------
saveas(gcf, 'grafica_tiempo_frecuencia.png');
disp('🖼️ Gráfica guardada como grafica_tiempo_frecuencia.png');