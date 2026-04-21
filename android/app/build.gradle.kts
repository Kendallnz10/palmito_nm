plugins {
    id("com.android.application")
    id("kotlin-android")
    // El plugin de Flutter debe ir después de Android y Kotlin
    id("dev.flutter.flutter-gradle-plugin")
    
}

android {
    namespace = "com.example.palmito_nm"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // 2. CORRECCIÓN DE JVM TARGET (Migrado a la nueva sintaxis para evitar advertencias)
    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "com.example.palmito_nm"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Configuración de firma para release
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// 3. SE ELIMINA LA LÍNEA ANTIGUA DE 'apply plugin' PORQUE YA SE INCLUYÓ EN EL BLOQUE 'plugins' ARRIBA