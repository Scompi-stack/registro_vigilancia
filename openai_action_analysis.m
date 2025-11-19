function accion = openai_action_analysis(frame, API_KEY)
% openai_action_analysis - Analiza acciones humanas usando OpenAI Vision API

%% 1. VALIDACIÓN DE ENTRADA
if nargin < 2
    error('Se requieren dos argumentos: frame y API_KEY');
end

if isempty(API_KEY) || ~ischar(API_KEY)
    error('API_KEY debe ser un string válido');
end

if size(frame, 3) ~= 3
    error('El frame debe ser una imagen RGB (MxNx3)');
end

%% 2. CONSTANTES DE CONFIGURACIÓN
URL_API = 'https://api.openai.com/v1/chat/completions';
MODELO = 'gpt-4o';
MAX_TOKENS = 50;
TIMEOUT = 30;

PROMPT = 'Describe la accion principal que esta realizando la persona en esta imagen. Responde con maximo 3 palabras en espanol. Ejemplos: Caminando, Usando telefono, Sentado trabajando.';

%% 3. CODIFICACIÓN DE IMAGEN A BASE64
try
    [alto, ancho, ~] = size(frame);
    if max(alto, ancho) > 512
        factor = 512 / max(alto, ancho);
        frame = imresize(frame, factor);
    end
    
    if ~isa(frame, 'uint8')
        frame = im2uint8(frame);
    end
    
    tempFile = [tempname, '.jpg'];
    imwrite(frame, tempFile, 'jpeg', 'Quality', 85);
    
    fid = fopen(tempFile, 'rb');
    imageBytes = fread(fid, '*uint8');
    fclose(fid);
    
    delete(tempFile);
    
    imageBase64 = matlab.net.base64encode(imageBytes);
    imageDataURI = sprintf('data:image/jpeg;base64,%s', imageBase64);
    
    fprintf('   -> Imagen codificada: %d bytes\n', length(imageBase64));
    
catch ME
    warning('Error en codificación de imagen: %s', ME.message);
    accion = 'Error de codificación';
    return;
end

%% 4. CONSTRUCCIÓN DEL PAYLOAD - MÉTODO CORREGIDO
try
    % Crear estructura de datos de forma segura
    payload = struct();
    payload.model = MODELO;
    payload.max_tokens = MAX_TOKENS;
    
    % Crear contenido del mensaje como cell array
    contenido = cell(2, 1);
    
    % Elemento 1: texto
    contenido{1} = struct('type', 'text', 'text', PROMPT);
    
    % Elemento 2: imagen
    contenido{2} = struct('type', 'image_url', ...
                          'image_url', struct('url', imageDataURI));
    
    % Crear mensaje
    mensaje = struct();
    mensaje.role = 'user';
    mensaje.content = contenido;
    
    % CRÍTICO: messages debe ser un ARRAY, no un objeto único
    payload.messages = {mensaje};  % Corchetes para crear array
    
    fprintf('   -> Payload estructurado creado\n');
    
catch ME
    warning('Error construyendo payload: %s', ME.message);
    accion = 'Error de payload';
    return;
end

%% 5. ENVIAR SOLICITUD A LA API
try
    fprintf('   -> Enviando frame a OpenAI API...\n');
    
    options = weboptions(...
        'RequestMethod', 'POST', ...
        'MediaType', 'application/json', ...
        'Timeout', TIMEOUT, ...
        'ContentType', 'json', ...
        'HeaderFields', {'Authorization', ['Bearer ', API_KEY]} ...
    );
    
    respuesta = webwrite(URL_API, payload, options);
    
    fprintf('   -> Respuesta recibida exitosamente\n');
    
catch ME
    if contains(ME.message, '401')
        warning('Error de autenticación: Verifica tu API_KEY');
        accion = 'Error: API Key inválida';
    elseif contains(ME.message, '429')
        warning('Límite de tasa excedido');
        accion = 'Error: Límite de tasa';
    elseif contains(ME.message, '400')
        warning('Error 400 - Bad Request');
        fprintf('\nMENSAJE DE ERROR COMPLETO:\n%s\n\n', ME.message);
        
        % Guardar payload para debug
        try
            debugPayload = payload;
            % Truncar base64 para debug
            if isfield(debugPayload, 'messages') && ~isempty(debugPayload.messages)
                msg = debugPayload.messages{1};
                if isfield(msg, 'content')
                    for i = 1:length(msg.content)
                        if isfield(msg.content{i}, 'image_url')
                            url = msg.content{i}.image_url.url;
                            if length(url) > 150
                                msg.content{i}.image_url.url = [url(1:150) '...[TRUNCADO]'];
                            end
                        end
                    end
                    debugPayload.messages{1} = msg;
                end
            end
            
            debugFile = 'debug_payload.json';
            fid = fopen(debugFile, 'w');
            fprintf(fid, '%s', jsonencode(debugPayload));
            fclose(fid);
            fprintf('Payload debug guardado en: %s\n', debugFile);
        catch
            fprintf('No se pudo guardar debug payload\n');
        end
        
        accion = 'Error: Bad Request (ver consola)';
    else
        warning('Error en solicitud a API: %s', ME.message);
        accion = 'Error de API';
    end
    return;
end

%% 6. PROCESAR RESPUESTA Y EXTRAER ACCIÓN
try
    if ischar(respuesta) || isstring(respuesta)
        respuesta = jsondecode(respuesta);
    end
    
    if isfield(respuesta, 'choices') && ~isempty(respuesta.choices)
        if length(respuesta.choices) >= 1
            contenido = respuesta.choices(1).message.content;
            accion = strtrim(contenido);
            
            if length(accion) > 50
                accion = accion(1:50);
            end
        else
            warning('Array choices vacío');
            accion = 'Respuesta vacía';
        end
    else
        warning('Formato de respuesta inesperado');
        if isstruct(respuesta)
            fprintf('Campos en respuesta: %s\n', strjoin(fieldnames(respuesta), ', '));
        end
        accion = 'Respuesta inválida';
    end
    
catch ME
    warning('Error procesando respuesta: %s', ME.message);
    accion = 'Error de parseo';
end

%% 7. VALIDACIÓN FINAL
if isempty(accion)
    accion = 'Sin acción detectada';
end

end