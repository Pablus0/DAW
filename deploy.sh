#!/bin/bash

# ==========================================
# PRÁCTICA: DESPLIEGUE AUTOMATIZADO
# Script para desplegar automáticamente una
# aplicación Java en Tomcat 10 en Ubuntu AWS.
# ==========================================

# ===== CONFIGURACIÓN =====
REPO_DIR="$HOME/DAW"                        # Ruta del repositorio clonado
SRC_DIR="$REPO_DIR/src"                     # Código fuente
BUILD_DIR="$REPO_DIR/build"                 # Directorio temporal para compilación
APP_NAME="hola"                             # Nombre de la aplicación
TOMCAT_WEBAPPS="/var/lib/tomcat10/webapps" # Directorio webapps de Tomcat
SERVLET_API="/usr/share/tomcat10/lib/servlet-api.jar" # Librería servlet de Tomcat
APP_URL="http://localhost:8080/$APP_NAME/hola"

echo "🚀 Iniciando despliegue automático de la aplicación $APP_NAME"

# ===== 1. Actualizar código desde GitHub =====
echo "📥 Actualizando repositorio..."
cd $REPO_DIR || { echo "❌ Error: no se encontró el repositorio"; exit 1; }
git pull || { echo "❌ Error al actualizar desde GitHub"; exit 1; }

# ===== 2. Limpiar y preparar compilación =====
echo "🧹 Limpiando compilaciones anteriores..."
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR/WEB-INF/classes

# ===== 3. Compilar el servlet Java =====
echo "⚙️ Compilando código Java..."
# Verifica que solo compile archivos Java válidos
javac -classpath $SERVLET_API \
      -d $BUILD_DIR/WEB-INF/classes \
      $(find $SRC_DIR -name "*.java" ! -name "*.txt") || { echo "❌ Error de compilación"; exit 1; }

# ===== 4. Generar web.xml dinámicamente =====
echo "📝 Generando web.xml..."
mkdir -p $BUILD_DIR/WEB-INF
cat <<EOF > $BUILD_DIR/WEB-INF/web.xml
<web-app xmlns="https://jakarta.ee/xml/ns/jakartaee" version="5.0">
    <servlet>
        <servlet-name>HolaServlet</servlet-name>
        <servlet-class>hola.HolaServlet</servlet-class>
    </servlet>
    <servlet-mapping>
        <servlet-name>HolaServlet</servlet-name>
        <url-pattern>/hola</url-pattern>
    </servlet-mapping>
</web-app>
EOF

# ===== 5. Generar archivo WAR =====
echo "📦 Creando archivo WAR..."
cd $BUILD_DIR || exit 1
jar -cvf $APP_NAME.war * || { echo "❌ Error al generar WAR"; exit 1; }

# ===== 6. Copiar WAR al directorio webapps de Tomcat =====
echo "📤 Desplegando WAR en Tomcat..."
sudo rm -rf $TOMCAT_WEBAPPS/$APP_NAME*
sudo cp $BUILD_DIR/$APP_NAME.war $TOMCAT_WEBAPPS/

# ===== 7. Reiniciar servicio Tomcat =====
echo "🔄 Reiniciando Tomcat..."
sudo systemctl restart tomcat10
sleep 5

# ===== 8. Comprobar que la aplicación responde =====
echo "🔍 Verificando despliegue..."
if curl -s $APP_URL | grep -i "hola" >/dev/null; then
    echo "✅ Despliegue completado correctamente"
else
    echo "❌ Error: la aplicación no responde correctamente"
    exit 1
fi

echo "🎯 Despliegue finalizado con éxito"

