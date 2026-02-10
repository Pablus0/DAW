#!/bin/bash

# ===== CONFIGURACIÓN =====
REPO_DIR="$HOME/NOMBRE_REPOSITORIO"
APP_NAME="hola"
BUILD_DIR="$REPO_DIR/build"

TOMCAT_WEBAPPS="/var/lib/tomcat10/webapps"
SERVLET_API="/usr/share/tomcat10/lib/servlet-api.jar"

echo "🚀 Iniciando despliegue automático"

# 1. Actualizar código
cd $REPO_DIR || exit 1
git pull || exit 1

# 2. Limpiar y preparar build
rm -rf $BUILD_DIR
mkdir -p $BUILD_DIR/WEB-INF/classes

# 3. Compilar
echo "⚙️ Compilando servlets..."
javac -classpath $SERVLET_API \
      -d $BUILD_DIR/WEB-INF/classes \
      $(find src -name "*.java") || exit 1

# 4. Crear web.xml
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

# 5. Generar WAR
cd $BUILD_DIR
jar -cvf $APP_NAME.war *

# 6. Desplegar
echo "📤 Copiando WAR a Tomcat..."
sudo rm -rf $TOMCAT_WEBAPPS/$APP_NAME*
sudo cp $APP_NAME.war $TOMCAT_WEBAPPS/

# 7. Reiniciar Tomcat
echo "🔄 Reiniciando Tomcat..."
sudo systemctl restart tomcat10
sleep 5

# 8. Verificación
echo "🔍 Verificando aplicación..."
curl -s http://localhost:8080/$APP_NAME/hola | grep -i hola \
&& echo "✅ Despliegue correcto" \
|| echo "❌ Error en el despliegue"
