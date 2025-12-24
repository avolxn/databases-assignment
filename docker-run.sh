#!/bin/bash

docker stop sqlserver 2>/dev/null
docker rm sqlserver 2>/dev/null

docker run \
  -e "ACCEPT_EULA=Y" \
  -e "SA_PASSWORD=Test123!" \
  -p 1433:1433 \
  --name sqlserver \
  -d \
  mcr.microsoft.com/mssql/server:2022-latest

echo "Параметры подключения:"
echo "  Server Host: localhost"
echo "  Port: 1433"
echo "  Database: master"
echo "  Authentication: SQL Server Authentication"
echo "  User name: sa"
echo "  Password: Test123!"
