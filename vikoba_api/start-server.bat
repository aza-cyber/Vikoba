@echo off
REM ---- VICOBA API server launcher (double-click to run) ----
title VICOBA API server

REM PostgreSQL connection + HTTP port
set PGHOST=localhost
set PGDATABASE=vikoba
set PGUSER=postgres
set PGPASSWORD=12345
set PORT=8090

cd /d C:\dev\vikoba_api

echo Starting VICOBA API on port %PORT% (database: %PGDATABASE%)...
echo Leave this window open. Press Ctrl+C to stop.
echo.

C:\src\flutter\bin\dart.bat run bin/server.dart

echo.
echo Server stopped. Press any key to close.
pause >nul
