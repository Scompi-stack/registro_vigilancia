# 👁️‍🗨️ Sistema de Vigilancia Biométrica con IA Asistida en MATLAB

[![Made with MATLAB](https://img.shields.io/badge/Made%20with-MATLAB-B9372F?style=flat&logo=matlab)](https://www.mathworks.com/products/matlab.html)
[![OpenAI API](https://img-url-in-the-future-for-openai-logo)](https://openai.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Este proyecto implementa un sistema robusto en **MATLAB** capaz de realizar **vigilancia y análisis situacional en tiempo real** utilizando la cámara web. Fusiona el reconocimiento facial biométrico con la interpretación contextual de acciones humanas asistida por la **OpenAI Vision API**.

El objetivo es transformar el *video crudo* en **información accionable** (*Actionable Intelligence*), registrando el **quién** y el **qué** está ocurriendo.

---

## 💡 Inspiración: La Filosofía de Palantir

La arquitectura del proyecto se inspira en la filosofía de **integración de datos y detección proactiva** de plataformas de análisis avanzadas. El sistema replica esto fusionando tres *feeds* de información en tiempo real para generar un registro de inteligencia completo:

1.  **Identidad Biométrica:** ¿Quién está presente? (Reconocimiento Facial basado en ResNet50).
2.  **Actividad Comportamental:** ¿Qué está haciendo la persona? (Análisis contextual asistido por IA).
3.  **Registro Histórico:** ¿Cuándo ocurrió este evento? (Sistema de *logging* en CSV).

Este enfoque permite la **detección de anomalías** y la trazabilidad de eventos clave en el *log* de actividad.

---

## 🛠️ Componentes Técnicos Clave

| Archivo | Función Principal | Tecnología Utilizada |
| :--- | :--- | :--- |
| `main_surveillance_loop.m` | **Motor de Ejecución.** Controla la cámara, gestiona el reconocimiento y la toma de decisiones para enviar a la IA. | MATLAB, Webcam, ResNet50 |
| `openai_action_analysis.m` | **Capa de Inteligencia.** Función que codifica el frame y realiza la **llamada segura a la API de OpenAI** (GPT-4o Vision API) para interpretar la acción. | OpenAI API, JSON |
| `face_db_setup.m` | Script para la **configuración inicial** y generación de la base de datos biométrica (`face_db.mat`). | ResNet50, Viola-Jones |
| `log_action_event.m` | Función dedicada a **escribir el log de eventos** (Identidad, Acción, Confianza) en el archivo CSV. | MATLAB File I/O |

---

## 🚀 Requisitos y Configuración

### 1. Requisitos de Software

* **MATLAB** (Versión R2021b o posterior recomendada).
* **Toolboxes requeridas:**
    * **Computer Vision Toolbox™** (para la cámara, detección facial y display).
    * **Deep Learning Toolbox™** (para ResNet-50 y extracción de *embeddings*).

### 2. Configuración de la API (Paso CRÍTICO de Seguridad) 🔒

La clave de la API de OpenAI **NO debe estar codificada** en el archivo `main_surveillance_loop.m`. El sistema está configurado para cargarla de forma segura:

1.  **Obtén tu Clave:** Consigue una clave de API válida de OpenAI.
2.  **Configura la Variable de Entorno:** Debes configurar la variable de entorno global llamada **`OPENAI_API_KEY`** con tu clave secreta.

| Sistema Operativo | Comando de Configuración (Ejemplo) |
| :--- | :--- |
| **Windows (CMD)** | `set OPENAI_API_KEY=sk-proj-TU-CLAVE` |
| **Mac/Linux** | `export OPENAI_API_KEY=sk-proj-TU-CLAVE` |

### 3. Generación de la Base de Datos Biométrica

El sistema requiere una base de datos de rostros (`face_db.mat`) para identificar a las personas.

1.  **Directorio de Entrenamiento:** Asegúrate de que existe la carpeta **`datos_rostros/`** en el directorio raíz.
2.  **Imágenes:** Coloca las imágenes de entrenamiento dentro de esta carpeta. **El nombre del archivo será la identidad reconocida** (ej. `Juan_Perez.jpg`, `Administrador.png`).
3.  **Ejecución del Setup:** Abre MATLAB, navega al directorio del proyecto y ejecuta:

    ```matlab
    face_db_setup
    ```

### 4. Iniciando el Sistema de Vigilancia

Una vez que la base de datos y la clave API están configuradas, ejecuta el *loop* principal:

```matlab
main_surveillance_loop
