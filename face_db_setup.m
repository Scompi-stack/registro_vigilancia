% face_db_setup.m
% Script para generar la base de datos biométrica inicial
% Sistema de vigilancia y reconocimiento facial

%% 1. INICIALIZACIÓN
clear all;
close all;
clc;

fprintf('=== Iniciando generación de base de datos biométrica ===\n\n');

% Definir ruta al directorio de imágenes
rutaImagenes = 'datos_rostros/';

% Verificar que el directorio existe
if ~exist(rutaImagenes, 'dir')
    error('El directorio %s no existe. Por favor créelo y añada imágenes.', rutaImagenes);
end

%% 2. CARGAR MODELOS
fprintf('Cargando modelos...\n');

% Detector de rostros Viola-Jones con clasificador CART
detectorRostros = vision.CascadeObjectDetector('FrontalFaceCART');

% Red neuronal ResNet50 para extracción de características
fprintf('Cargando ResNet50 (esto puede tardar unos momentos)...\n');
net = resnet50;

fprintf('Modelos cargados correctamente.\n\n');

%% 3. OBTENER LISTA DE IMÁGENES
% Buscar archivos de imagen en el directorio
extensionesValidas = {'*.jpg', '*.jpeg', '*.png', '*.bmp'};
listaImagenes = [];

for i = 1:length(extensionesValidas)
    archivos = dir(fullfile(rutaImagenes, extensionesValidas{i}));
    listaImagenes = [listaImagenes; archivos];
end

numImagenes = length(listaImagenes);

if numImagenes == 0
    error('No se encontraron imágenes en el directorio %s', rutaImagenes);
end

fprintf('Se encontraron %d imágenes para procesar.\n\n', numImagenes);

%% 4. PROCESAMIENTO Y EXTRACCIÓN DE EMBEDDINGS
% Inicializar variables de almacenamiento
vectoresDB = [];
nombresDB = {};
contadorExitoso = 0;

fprintf('Procesando imágenes:\n');
fprintf('--------------------\n');

for i = 1:numImagenes
    % Construir ruta completa del archivo
    nombreArchivo = listaImagenes(i).name;
    rutaCompleta = fullfile(rutaImagenes, nombreArchivo);
    
    fprintf('[%d/%d] Procesando: %s\n', i, numImagenes, nombreArchivo);
    
    try
        % Leer imagen
        img = imread(rutaCompleta);
        
        % Convertir a escala de grises si es necesario (para detección)
        if size(img, 3) == 3
            imgGris = rgb2gray(img);
        else
            imgGris = img;
        end
        
        % Detectar rostros
        bboxes = step(detectorRostros, imgGris);
        
        if isempty(bboxes)
            warning('No se detectó rostro en %s. Omitiendo...', nombreArchivo);
            continue;
        end
        
        % Si hay múltiples rostros, tomar el más grande
        if size(bboxes, 1) > 1
            areas = bboxes(:,3) .* bboxes(:,4);
            [~, idx] = max(areas);
            bbox = bboxes(idx, :);
            fprintf('  -> Se detectaron %d rostros. Usando el más grande.\n', size(bboxes, 1));
        else
            bbox = bboxes(1, :);
        end
        
        % Recortar rostro (trabajar con imagen original en color si está disponible)
        if size(img, 3) == 3
            rostroRecortado = imcrop(img, bbox);
        else
            rostroRecortado = imcrop(img, bbox);
            % Convertir a RGB si es necesario
            rostroRecortado = cat(3, rostroRecortado, rostroRecortado, rostroRecortado);
        end
        
        % Redimensionar a 224x224 (entrada de ResNet50)
        rostroRedimensionado = imresize(rostroRecortado, [224, 224]);
        
        % Extraer embedding usando ResNet50
        embedding = activations(net, rostroRedimensionado, 'avg_pool', 'OutputAs', 'rows');
        
        % Normalizar el vector (L2)
        embeddingNormalizado = embedding / norm(embedding);
        
        % Extraer nombre de la persona del nombre del archivo
        % (remover extensión y usar el nombre base)
        [~, nombrePersona, ~] = fileparts(nombreArchivo);
        
        % Almacenar en la base de datos
        vectoresDB = [vectoresDB; embeddingNormalizado];
        nombresDB{end+1} = nombrePersona;
        
        contadorExitoso = contadorExitoso + 1;
        fprintf('  -> Embedding extraído correctamente para: %s\n', nombrePersona);
        
    catch ME
        warning('Error procesando %s: %s', nombreArchivo, ME.message);
        continue;
    end
end

fprintf('\n--------------------\n');
fprintf('Procesamiento completado: %d/%d imágenes exitosas.\n\n', contadorExitoso, numImagenes);

%% 5. VALIDACIÓN
if isempty(vectoresDB)
    error('No se pudo procesar ninguna imagen. Verifique el contenido del directorio.');
end

% Convertir nombresDB a array de columna para consistencia
nombresDB = nombresDB';

fprintf('Resumen de la base de datos:\n');
fprintf('  - Total de registros: %d\n', size(vectoresDB, 1));
fprintf('  - Dimensión de embeddings: %d\n', size(vectoresDB, 2));
fprintf('  - Personas registradas: %s\n', strjoin(unique(nombresDB), ', '));

%% 6. GUARDADO
nombreArchivo = 'face_db.mat';
fprintf('\nGuardando base de datos en: %s\n', nombreArchivo);

save(nombreArchivo, 'vectoresDB', 'nombresDB');

fprintf('¡Base de datos biométrica generada exitosamente!\n');
fprintf('=== Proceso finalizado ===\n');