# Étape 1 : Build du projet avec Maven
FROM maven:3.9.6-eclipse-temurin-17 AS build

WORKDIR /app

# Copie le code source et les fichiers de configuration Maven

COPY pom.xml .
COPY src ./src

# Générer la clé et injecter dans le vrai fichier
RUN SECRET=$(openssl rand -base64 64 | tr -d '\n') && \
    sed -i "s|__SECRET_KEY_PLACEHOLDER__|${SECRET}|g" src/main/resources/application.yml

# Générer le keystore
RUN keytool -genkeypair \
    -alias localhost \
    -keyalg RSA \
    -keysize 2048 \
    -storetype PKCS12 \
    -keystore keystore.p12 \
    -storepass password \
    -validity 3650 \
    -dname "CN=localhost, OU=Dev, O=Example, L=City, S=State, C=FR" && mv /app/keystore.p12 src/main/resources/keystore.p12

# Compile le projet et package le jar exécutable
RUN mvn clean package -DskipTests

# Étape 2 : Exécution de l'application avec une image plus légère
FROM eclipse-temurin:17-jdk-alpine
RUN apk add --no-cache bash
WORKDIR /app
# Copie le jar généré de l'étape précédente
COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080
EXPOSE 8443
ENTRYPOINT ["java", "-jar", "app.jar"]


