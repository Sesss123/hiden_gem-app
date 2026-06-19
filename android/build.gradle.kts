buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.1.0")
    }
    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "org.jetbrains.kotlin" && requested.name == "kotlin-gradle-plugin") {
                useVersion("2.1.0")
            }
        }
    }
}

allprojects {
    buildscript {
        repositories {
            google()
            mavenCentral()
        }
        configurations.all {
            resolutionStrategy.eachDependency {
                if (requested.group == "org.jetbrains.kotlin" && requested.name == "kotlin-gradle-plugin") {
                    useVersion("2.1.0")
                }
            }
        }
    }
    repositories {
        google()
        mavenCentral()
    }
    
    // Java lint දෝෂ මඟහරවා ගැනීමට
    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.add("-Xlint:-options")
    }

    configurations.all {
        resolutionStrategy.eachDependency {
            if (requested.group == "org.jetbrains.kotlin" && (requested.name == "kotlin-gradle-plugin" || requested.name.startsWith("kotlin-stdlib"))) {
                useVersion("2.1.0")
            }
        }
    }
}

subprojects {
    afterEvaluate {
        if (project.plugins.hasPlugin("com.android.library") || project.plugins.hasPlugin("com.android.application")) {
            val android = project.extensions.findByName("android")
            if (android != null) {
                // 1. Fixing namespace issues (Crucial for ARCore and newer AGP versions)
                try {
                    val getNamespace = android.javaClass.getMethod("getNamespace")
                    val currentNamespace = getNamespace.invoke(android)
                    
                    if (currentNamespace == null) {
                        var fallbackNamespace = project.group.toString()
                        if (fallbackNamespace.isEmpty() || fallbackNamespace == "unspecified") {
                            fallbackNamespace = "com.hidden.gems.${project.name.replace("-", "_").replace(".", "_")}"
                        }
                        
                        if (project.name.contains("arcore_flutter_plugin")) {
                            fallbackNamespace = "com.difrancescogianmarco.arcore_flutter_plugin"
                        }
                        android.javaClass.getMethod("setNamespace", String::class.java).invoke(android, fallbackNamespace)
                    }
                } catch (e: Exception) {}

                // 2. Stronger SDK Enforcement (Force overrides for older plugins)
                try {
                    val compileSdkMethod = android.javaClass.methods.find { it.name == "setCompileSdk" }
                                           ?: android.javaClass.methods.find { it.name == "setCompileSdkVersion" }
                    
                    if (compileSdkMethod != null) {
                        try {
                            val paramType = compileSdkMethod.parameterTypes[0]
                            if (paramType == String::class.java) {
                                compileSdkMethod.invoke(android, "android-36")
                            } else {
                                compileSdkMethod.invoke(android, 36)
                            }
                        } catch (e: Exception) {
                            println("[Fix] SDK Error for ${project.name}: ${e.message}")
                        }
                    }

                    val defaultConfig = android.javaClass.getMethod("getDefaultConfig").invoke(android)
                    if (defaultConfig != null) {
                        defaultConfig.javaClass.methods.find { it.name == "setTargetSdk" }?.let { method ->
                            try {
                                method.invoke(defaultConfig, 35)
                            } catch (e: Exception) {
                                try {
                                    method.invoke(defaultConfig, "35")
                                } catch (e2: Exception) {}
                            }
                        }
                        
                        defaultConfig.javaClass.methods.find { it.name == "setMinSdk" }?.let { method ->
                            try {
                                method.invoke(defaultConfig, 24)
                            } catch (e: Exception) {
                                try {
                                    method.invoke(defaultConfig, "24")
                                } catch (e2: Exception) {}
                            }
                        }
                    }
                } catch (e: Exception) {
                    println("[Fix] Failed to enforce SDK for ${project.name}: ${e.message}")
                }

                // 3. Enforce JVM 17
                try {
                    val compileOptions = android.javaClass.getMethod("getCompileOptions").invoke(android)
                    compileOptions.javaClass.getMethod("setSourceCompatibility", JavaVersion::class.java).invoke(compileOptions, JavaVersion.VERSION_17)
                    compileOptions.javaClass.getMethod("setTargetCompatibility", JavaVersion::class.java).invoke(compileOptions, JavaVersion.VERSION_17)
                } catch (e: Exception) {}
            }

            project.tasks.withType<JavaCompile>().configureEach {
                sourceCompatibility = JavaVersion.VERSION_17.toString()
                targetCompatibility = JavaVersion.VERSION_17.toString()
            }
            
            project.tasks.matching { it.name.contains("Kotlin") }.configureEach {
                try {
                    val options = if (this.hasProperty("compilerOptions")) this.property("compilerOptions") else this.property("kotlinOptions")
                    val setJvmTarget = options?.javaClass?.methods?.find { it.name == "setJvmTarget" }
                    if (setJvmTarget != null) {
                        try {
                            setJvmTarget.invoke(options, "17")
                        } catch (e: Exception) {
                            try {
                                val jvmTargetClass = Class.forName("org.jetbrains.kotlin.gradle.dsl.JvmTarget")
                                val field = jvmTargetClass.getField("JVM_17")
                                setJvmTarget.invoke(options, field.get(null))
                            } catch (e2: Exception) {}
                        }
                    }
                } catch (e: Exception) {}
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
