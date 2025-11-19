# 👁️‍🗨️ Sistema de Vigilancia Biométrica: Plataforma de Análisis Situacional en Tiempo Real

[![Made with MATLAB](https://img.shields.io/badge/Made%20with-MATLAB-B9372F?style=flat&logo=matlab)](https://www.mathworks.com/products/matlab.html)
[![OpenAI API](https://img.shields.io/badge/Powered%20by-OpenAI%20Vision%20API-412991?style=flat&logo=openai)](https://openai.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Este proyecto implementa un sistema robusto en **MATLAB** capaz de realizar **vigilancia y análisis situacional en tiempo real** utilizando la cámara web. Fusiona el reconocimiento facial biométrico con la interpretación contextual de acciones humanas asistida por la **OpenAI Vision API**.

El objetivo es transformar el *video crudo* en información accionable (*Actionable Intelligence*), registrando el **quién** y el **qué** está ocurriendo.

---

## 💡 Inspiración: La Filosofía de Palantir

La arquitectura y el propósito de este sistema se inspiran en las plataformas avanzadas de análisis de datos. En lugar de limitarse a la detección, el sistema replica una filosofía de **fusión de inteligencia y detección proactiva**, combinando tres *feeds* de información esenciales:

1.  **Identidad Biométrica:** ¿Quién está presente? (Reconocimiento Facial basado en ResNet50).
2.  **Actividad Comportamental:** ¿Qué está haciendo la persona? (Análisis contextual asistido por IA).
3.  **Registro Histórico:** ¿Cuándo ocurrió este evento? (Sistema de *logging* en CSV).

Este enfoque permite la **identificación de patrones de riesgo** y la trazabilidad de eventos clave en el *log* de actividad.

---

## 🛠️ Componentes Técnicos Clave

| Archivo | Función Principal | Tecnología Utilizada |
| :--- | :--- | :--- |
| `main_surveillance_loop.m` | **Motor de Ejecución.** Llama a la cámara, procesa frames, realiza el reconocimiento de múltiples rostros y gestiona el display. | MATLAB, Webcam, ResNet50 |
| `openai_action_analysis.m` | **Capa de Inteligencia.** Codifica el frame y realiza la llamada segura a la API de OpenAI (GPT-4o Vision API) para interpretar la acción. | OpenAI API, JSON |
| `face_db_setup.m` | Script para **configuración inicial** y generación de la base de datos biométrica (`face_db.mat`). | ResNet50 |
| `log_action_event.m` | Función para la **escritura segura** de los registros de evento (Timestamp, Identidad, Acción) en el archivo `registro_actividad.csv`. | MATLAB File I/O |

---

## 🚀 Requisitos y Configuración

### 1. Requisitos de Software

* **MATLAB** (Versión R2021b o posterior recomendada).
* **Toolboxes requeridas:**
    * Deep Learning Toolbox™
    * Computer Vision Toolbox™
    * Deep Learning Toolbox Model for ResNet-50 network™
    * Image Processing Toolbox™
    * MATLAB Support Package for USB Webcams™

### 2. Configuración de la API (Paso CRÍTICO de Seguridad) 🔒

La clave de la API de OpenAI **NO debe estar codificada** en el archivo `main_surveillance_loop.m`. El sistema está configurado para cargarla de forma segura:

1.  **Obtén tu Clave:** Consigue una clave de API válida de OpenAI.
2.  **Configura la Variable de Entorno:** Configura la variable de entorno global llamada `OPENAI_API_KEY` con tu clave secreta.

| Sistema Operativo | Comando de Configuración (Ejemplo) |
| :--- | :--- |
| **Windows (CMD)** | `set OPENAI_API_KEY=sk-proj-TU-CLAVE` |
| **Mac/Linux** | `export OPENAI_API_KEY=sk-proj-TU-CLAVE` |

### 3. Generación de la Base de Datos Biométrica

Antes de iniciar la vigilancia, debes entrenar el sistema con las identidades conocidas.

1.  **Directorio de Entrenamiento:** Asegúrate de que existe la carpeta **`datos_rostros/`** en el directorio raíz.
2.  **Imágenes:** Coloca las imágenes de entrenamiento dentro de esta carpeta. **El nombre del archivo será la identidad** (ej. `Admin.jpg`, `Doctor_Lopez.png`).
3.  **Ejecución del Setup:** Abre MATLAB, navega al directorio del proyecto y ejecuta:

    ```matlab
    face_db_setup
    ```
    Esto generará el archivo `face_db.mat`.

### 4. Iniciando el Sistema de Vigilancia

Una vez que la base de datos (`face_db.mat`) y la clave API (`OPENAI_API_KEY`) están configuradas, ejecuta el *loop* principal:

```matlab
main_surveillance_loop
