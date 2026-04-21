// 1. Configuración de plugins y dependencias del build del proyecto
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Asegúrate de que la versión de Gradle sea compatible (normalmente se maneja en el gradle-wrapper)
        classpath("com.android.tools.build:gradle:8.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:1.8.22")
    }
}

// 2. Repositorios para todos los subproyectos
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// 3. Configuración del directorio de build (para mantener la raíz limpia)
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// 4. Dependencias de evaluación entre proyectos
subprojects {
    project.evaluationDependsOn(":app")
}

// 5. Tarea de limpieza (Clean)
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}