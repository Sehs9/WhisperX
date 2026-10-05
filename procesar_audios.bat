@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ============================================================
REM Configuración
REM ============================================================

set "BASE=C:\ProyectosIA\WhisperX"
set "INPUT=%BASE%\audios"
set "OUTPUT=%BASE%\transcripciones"
set "ENV=%BASE%\whisper-env"
set "CONVERTER=%BASE%\scripts\json_a_txt.py"
set "LOG=%OUTPUT%\procesamiento.log"

REM ============================================================
REM Verificaciones
REM ============================================================

if not exist "%ENV%\Scripts\python.exe" (
    echo ERROR: No existe el entorno virtual:
    echo %ENV%
    pause
    exit /b 1
)

if not exist "%INPUT%" (
    echo ERROR: No existe la carpeta de audios:
    echo %INPUT%
    pause
    exit /b 1
)

if not exist "%CONVERTER%" (
    echo ERROR: No existe el convertidor:
    echo %CONVERTER%
    pause
    exit /b 1
)

if "%HF_TOKEN%"=="" (
    echo ERROR: La variable HF_TOKEN no esta definida.
    echo.
    echo Ejecuta antes:
    echo set "HF_TOKEN=hf_TU_TOKEN"
    pause
    exit /b 1
)

if not exist "%OUTPUT%" mkdir "%OUTPUT%"

call "%ENV%\Scripts\activate.bat"

echo ============================================================ >> "%LOG%"
echo Inicio: %date% %time% >> "%LOG%"
echo ============================================================ >> "%LOG%"

REM ============================================================
REM Procesar M4A
REM ============================================================

for %%F in ("%INPUT%\*.m4a") do (
    set "NAME=%%~nF"
    set "JSON=%OUTPUT%\%%~nF.json"
    set "TXT=%OUTPUT%\%%~nF.txt"

    echo.
    echo ============================================================
    echo Procesando: %%~nxF
    echo ============================================================

    echo [%date% %time%] Inicio: %%~nxF >> "%LOG%"

    REM Si el JSON ya existe, no vuelve a transcribir.
    if exist "!JSON!" (
        echo JSON existente. Se omite la transcripcion.
        echo [%date% %time%] Omitido, JSON existente: %%~nxF >> "%LOG%"
    ) else (
        whisperx "%%~fF" ^
            --device cuda ^
            --compute_type float16 ^
            --model large-v3 ^
            --language es ^
            --batch_size 4 ^
            --diarize ^
   		--min_speakers 2 ^
    		--max_speakers 5 ^
            --hf_token "%HF_TOKEN%" ^
            --output_format json ^
            --output_dir "%OUTPUT%"

        if errorlevel 1 (
            echo ERROR procesando: %%~nxF
            echo [%date% %time%] ERROR WhisperX: %%~nxF >> "%LOG%"
        ) else (
            echo Transcripcion terminada: %%~nxF
            echo [%date% %time%] WhisperX OK: %%~nxF >> "%LOG%"
        )
    )

    REM Convertir JSON a TXT si existe.
    if exist "!JSON!" (
        "%ENV%\Scripts\python.exe" "%CONVERTER%" "!JSON!"

        if errorlevel 1 (
            echo ERROR convirtiendo JSON a TXT: %%~nxF
            echo [%date% %time%] ERROR TXT: %%~nxF >> "%LOG%"
        ) else (
            echo TXT terminado: %%~nxF
            echo [%date% %time%] TXT OK: %%~nxF >> "%LOG%"
        )
    )
)

echo.
echo ============================================================
echo Procesamiento finalizado
echo ============================================================

echo Fin: %date% %time% >> "%LOG%"
echo. >> "%LOG%"

pause
endlocal