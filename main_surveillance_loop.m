% main_surveillance_loop.m
% Sistema de vigilancia biométrica con reconocimiento facial y análisis de acciones
% Captura video en tiempo real, identifica personas y detecta acciones

%% ========================================================================
%  SECCIÓN 1: INICIALIZACIÓN Y CONFIGURACIÓN
%  ========================================================================

clear all;
close all;
clc;

fprintf('=== SISTEMA DE VIGILANCIA BIOMÉTRICA ===\n\n');

%% 1.1 Parámetros de Configuración
fprintf('[1/5] Configurando parámetros del sistema...\n');

% Parámetros de reconocimiento facial
UMBRAL_RECONOCIMIENTO = 0.3;  % Umbral de similitud para reconocer (ajustar según necesidad)
                               % Valores típicos: 0.5-0.7 (más bajo = más permisivo)

% Parámetros de análisis de acciones
INTERVALO_ANALISIS_ACCION = 15;  % Analizar acción cada 15 frames (~0.5 seg a 30fps)
API_KEY = 'NO_API_FOR_YOU';     % Reemplazar con tu API key de OpenAI

% Parámetros de visualización
GROSOR_BBOX = 3;                 % Grosor del rectángulo de detección
TAMANO_FUENTE = 16;              % Tamaño de fuente para etiquetas

% Contador de frames
FRAME_COUNTER = 0;

% Variables de estado
accion_detectada_actual = 'Sin acción';  % Acción detectada más reciente

fprintf('   -> Umbral de reconocimiento: %.2f\n', UMBRAL_RECONOCIMIENTO);
fprintf('   -> Intervalo de análisis: cada %d frames\n', INTERVALO_ANALISIS_ACCION);

% --- ADICIONES PARA REGISTRO DE ACCIONES (LOGGING) ---
% Parámetros de Registro de Acciones
LOG_FILE_NAME = 'registro_actividad.csv'; % Nombre del archivo de log
% Mapa para rastrear la última acción registrada para cada usuario
last_logged_actions = containers.Map('KeyType', 'char', 'ValueType', 'char'); 

% Inicializar el archivo de log (solo si no existe)
if ~exist(LOG_FILE_NAME, 'file')
    fid = fopen(LOG_FILE_NAME, 'w');
    if fid ~= -1
        fprintf(fid, 'Timestamp,Identity,Action,Confidence\n');
        fclose(fid);
        fprintf('   -> Archivo de log %s creado.\n', LOG_FILE_NAME);
    else
        warning('No se pudo crear el archivo de log.');
    end
end
% ----------------------------------------------------

%% 1.2 Cargar Base de Datos Biométrica
fprintf('[2/5] Cargando base de datos biométrica...\n');

if ~exist('face_db.mat', 'file')
    error(['No se encontró el archivo face_db.mat.\n' ...
           'Ejecute primero face_db_setup.m para generar la base de datos.']);
end

load('face_db.mat', 'vectoresDB', 'nombresDB');

fprintf('   -> Base de datos cargada: %d personas registradas\n', length(nombresDB));
fprintf('   -> Personas: %s\n', strjoin(nombresDB', ', '));

%% 1.3 Cargar Modelos de IA
fprintf('[3/5] Cargando modelos de inteligencia artificial...\n');

% Detector de rostros Viola-Jones
detectorRostros = vision.CascadeObjectDetector('FrontalFaceCART');
fprintf('   -> Detector de rostros cargado\n');

% Red neuronal ResNet50 para embeddings
fprintf('   -> Cargando ResNet50 (puede tardar unos segundos)...\n');
net = resnet50;
fprintf('   -> ResNet50 cargado correctamente\n');

%% 1.4 Inicializar Webcam
fprintf('[4/5] Inicializando cámara web...\n');

try
    infoCamaras = webcamlist;
    numCamaras = length(infoCamaras);
    
    if numCamaras == 0
        error('No se detectó ninguna cámara web conectada.');
    end
    
    fprintf('   -> Se encontraron %d cámaras:\n', numCamaras);
    
    % Mostrar opciones al usuario
    for i = 1:numCamaras
        fprintf('      [%d] %s\n', i, infoCamaras{i});
    end
    
    % Pedir al usuario que seleccione una cámara
    seleccion = input(sprintf('   -> Escriba el número de la cámara a usar (1-%d): ', numCamaras));
    
    if isempty(seleccion) || ~isnumeric(seleccion) || seleccion < 1 || seleccion > numCamaras || seleccion ~= floor(seleccion)
        warning('Selección inválida. Usando la primera cámara por defecto.');
        indiceSeleccionado = 1;
    else
        indiceSeleccionado = seleccion;
    end
    
    nombreCamara = infoCamaras{indiceSeleccionado};
    cam = webcam(nombreCamara);
    
    fprintf('   -> Cámara seleccionada: [%d] %s\n', indiceSeleccionado, nombreCamara);
    fprintf('   -> Resolución: %s\n', cam.Resolution);
    
catch ME
    error('No se pudo inicializar la webcam: %s', ME.message);
end

%% 1.5 Configurar Ventana de Visualización
fprintf('[5/5] Configurando interfaz de visualización...\n');

% Crear figura para mostrar el video
fig = figure('Name', 'Sistema de Vigilancia Biométrica', ...
             'NumberTitle', 'off', ...
             'MenuBar', 'none', ...
             'ToolBar', 'none', ...
             'Position', [100, 100, 1200, 700]);

% Crear botón de parada
btnParar = uicontrol('Style', 'pushbutton', ...
                     'String', 'DETENER SISTEMA', ...
                     'Position', [20, 20, 150, 40], ...
                     'FontSize', 12, ...
                     'FontWeight', 'bold', ...
                     'BackgroundColor', [0.8, 0.2, 0.2], ...
                     'ForegroundColor', 'white', ...
                     'Callback', @(~,~) set(gcf, 'UserData', false));

% Variable para controlar el bucle
set(fig, 'UserData', true);

fprintf('\n¡Sistema listo! Iniciando vigilancia...\n');
fprintf('Presione el botón "DETENER SISTEMA" o cierre la ventana para finalizar.\n');
fprintf('========================================\n\n');

%% ========================================================================
%  SECCIÓN 2: BUCLE PRINCIPAL DE VIGILANCIA
%  ========================================================================

while ishandle(fig) && get(fig, 'UserData')
    
    % Incrementar contador de frames
    FRAME_COUNTER = FRAME_COUNTER + 1;
    
    try
        %% 2.1 CAPTURA DE FRAME
        frame = snapshot(cam);
        frameOriginal = frame;  % Guardar copia para procesamiento
        
        %% 2.2 DETECCIÓN DE ROSTROS
        % Convertir a escala de grises para la detección
        if size(frame, 3) == 3
            frameGris = rgb2gray(frame);
        else
            frameGris = frame;
        end
        
        % Detectar rostros en el frame
        bboxes = step(detectorRostros, frameGris);
        numRostros = size(bboxes, 1);
        
        %% 2.3 PROCESAMIENTO DE ROSTROS DETECTADOS
        if numRostros > 0
            
            % Eliminamos la lógica de seleccionar solo el rostro más grande
            % e iteramos sobre todos los rostros detectados.
            fprintf('[Frame %d] Detectados %d rostros. Procesando todos.\n', ...
                    FRAME_COUNTER, numRostros);

            % --- INICIO: BUCLE PARA PROCESAR CADA ROSTRO ---
            for k = 1:numRostros
                
                % Obtener la bounding box del rostro actual
                bbox = bboxes(k, :);
            
                %% 2.4 RECONOCIMIENTO FACIAL
                % Llamar a la función de reconocimiento
                [identidad, confianza] = recognize_face(frameOriginal, bbox, net, ...
                                                         vectoresDB, nombresDB, ...
                                                         UMBRAL_RECONOCIMIENTO);
                                                         
                %% 2.4.1 LÓGICA DE REGISTRO DE EVENTOS (LOGGING)
                % Solo registra si la persona es reconocida
                if ~strcmp(identidad, 'Desconocido')
                    
                    current_action = accion_detectada_actual;
                    
                    % Verificar si ya tenemos un registro para esta persona
                    if isKey(last_logged_actions, identidad)
                        last_action = last_logged_actions(identidad);
                        
                        % Registrar si la acción ha cambiado
                        if ~strcmp(last_action, current_action) 
                            
                            % Llamar a la función de registro (log_action_event.m)
                            log_action_event(LOG_FILE_NAME, identidad, current_action, confianza);
                            
                            % Actualizar el estado del último evento registrado
                            last_logged_actions(identidad) = current_action;
                            fprintf('   [LOG] Registrada nueva acción para %s: %s\n', identidad, current_action);
                        end
                        
                    % Si es la primera vez que vemos esta persona, registrar su primera acción
                    else 
                        log_action_event(LOG_FILE_NAME, identidad, current_action, confianza);
                        last_logged_actions(identidad) = current_action;
                        fprintf('   [LOG] Registrada primera acción para %s: %s\n', identidad, current_action);
                    end
                end
                % FIN DE LÓGICA DE REGISTRO
                
                %% 2.6 GENERAR ETIQUETA COMBINADA
                % Usamos la acción global 'accion_detectada_actual' (actualizada periódicamente)
                % para etiquetar a todos los individuos.
                if strcmp(identidad, 'Desconocido')
                    etiqueta = sprintf('DESCONOCIDO (%.1f%%) - %s', ...
                                       confianza * 100, accion_detectada_actual);
                    colorBbox = [1, 0, 0];  % Rojo para desconocidos
                else
                    etiqueta = sprintf('%s (%.1f%%) - %s', ...
                                       identidad, confianza * 100, accion_detectada_actual);
                    colorBbox = [0, 1, 0];  % Verde para conocidos
                end
                
                %% 2.7 DIBUJAR ANOTACIONES EN EL FRAME
                % Dibujar rectángulo alrededor del rostro actual
                frame = insertShape(frame, 'Rectangle', bbox, ...
                                   'Color', colorBbox * 255, ...
                                   'LineWidth', GROSOR_BBOX);
                
                % Calcular posición para la etiqueta (encima del rostro)
                posX = bbox(1);
                posY = max(bbox(2) - 10, 10);  % Evitar salirse del frame
                
                % Dibujar etiqueta con fondo
                frame = insertText(frame, [posX, posY], etiqueta, ...
                                  'FontSize', TAMANO_FUENTE, ...
                                  'BoxColor', colorBbox * 255, ...
                                  'BoxOpacity', 0.8, ...
                                  'TextColor', 'white', ...
                                  'AnchorPoint', 'LeftBottom');
            end
            % --- FIN: BUCLE PARA PROCESAR CADA ROSTRO ---
            
            % Dibujar información adicional en la esquina (solo una vez)
            infoTexto = sprintf('Frame: %d | Rostros: %d', FRAME_COUNTER, numRostros);
            frame = insertText(frame, [10, 10], infoTexto, ...
                              'FontSize', 12, ...
                              'BoxColor', [0, 0, 0], ...
                              'BoxOpacity', 0.6, ...
                              'TextColor', 'white');
            
        else
            % No hay rostros detectados
            frame = insertText(frame, [10, 10], ...
                              sprintf('Frame: %d | Sin rostros detectados', FRAME_COUNTER), ...
                              'FontSize', 12, ...
                              'BoxColor', [100, 100, 100], ...
                              'BoxOpacity', 0.6, ...
                              'TextColor', 'white');
        end
        
        %% 2.5 ANÁLISIS DE ACCIONES (cada N frames)
        if mod(FRAME_COUNTER, INTERVALO_ANALISIS_ACCION) == 0
            fprintf('[Frame %d] Analizando acción...\n', FRAME_COUNTER);
            
            % La acción se analiza sobre el frame completo y se guarda en la variable global.
            accion_detectada_actual = openai_action_analysis(frameOriginal, API_KEY);
            
            fprintf('   -> Acción detectada: %s\n', accion_detectada_actual);
        end
        
        %% 2.8 MOSTRAR FRAME PROCESADO
        imshow(frame);
        drawnow;
        
    catch ME
        warning('Error en el frame %d: %s', FRAME_COUNTER, ME.message);
        continue;
    end
    
end

%% ========================================================================
%  SECCIÓN 3: LIMPIEZA Y FINALIZACIÓN
%  ========================================================================

fprintf('\n========================================\n');
fprintf('Deteniendo sistema de vigilancia...\n');

% Liberar recursos
clear cam;
if ishandle(fig)
    close(fig);
end

fprintf('Cámara liberada.\n');
fprintf('Total de frames procesados: %d\n', FRAME_COUNTER);
fprintf('Sistema finalizado correctamente.\n');
fprintf('========================================\n');


% ------------------------------------------------------------------------
% FUNCIÓN: recognize_face
% Reconoce un rostro comparando su embedding con la base de datos
% ------------------------------------------------------------------------
function [identidad, confianza] = recognize_face(frame, bbox, net, ...
                                                  vectoresDB, nombresDB, umbral)
    % ENTRADA:
    %   frame: Imagen completa (RGB)
    %   bbox: Bounding box del rostro [x, y, ancho, alto]
    %   net: Red ResNet50
    %   vectoresDB: Matriz de embeddings conocidos
    %   nombresDB: Cell array con nombres correspondientes
    %   umbral: Umbral mínimo de similitud para reconocer
    %
    % SALIDA:
    %   identidad: Nombre de la persona o 'Desconocido'
    %   confianza: Valor de similitud [0, 1]
    
    try
        % Recortar rostro del frame
        rostroRecortado = imcrop(frame, bbox);
        
        % Asegurar que sea RGB
        if size(rostroRecortado, 3) == 1
            rostroRecortado = cat(3, rostroRecortado, rostroRecortado, rostroRecortado);
        end
        
        % Redimensionar a 224x224
        rostroRedimensionado = imresize(rostroRecortado, [224, 224]);
        
        % Extraer embedding
        embedding = activations(net, rostroRedimensionado, 'avg_pool', ...
                               'OutputAs', 'rows');
        
        % Normalizar (L2)
        embeddingNormalizado = embedding / norm(embedding);
        
        % Calcular similitud coseno con todos los embeddings en la DB
        similitudes = vectoresDB * embeddingNormalizado';
        
        % Encontrar el más similar
        [maxSimilitud, idx] = max(similitudes);
        
        % Decidir si es un match
        if maxSimilitud >= umbral
            identidad = nombresDB{idx};
            confianza = maxSimilitud;
        else
            identidad = 'Desconocido';
            confianza = maxSimilitud;
        end
        
    catch ME
        warning('Error en recognize_face: %s', ME.message);
        identidad = 'Error';
        confianza = 0;
    end
end