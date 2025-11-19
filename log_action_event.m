function log_action_event(logFileName, identidad, accion, confianza)
% log_action_event - Función para añadir un registro de evento al archivo CSV

% 1. Obtener la hora actual
timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');

% 2. Formatear la línea de log
% Reemplazar comas en la acción/identidad por puntos (si las hubiera)
% para no romper el formato CSV.
accion = strrep(accion, ',', '.');
identidad = strrep(identidad, ',', '.');

% Linea CSV: Timestamp,Identity,Action,Confidence
logLine = sprintf('%s,%s,%s,%.4f\n', timestamp, identidad, accion, confianza);

% 3. Abrir y escribir en el archivo (modo append 'a')
fid = fopen(logFileName, 'a');
if fid ~= -1
    fprintf(fid, logLine);
    fclose(fid);
else
    warning('No se pudo abrir el archivo de log: %s', logFileName);
end

end