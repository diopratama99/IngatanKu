import com.android.build.api.variant.ApplicationAndroidComponentsExtension
import com.android.build.api.variant.LibraryAndroidComponentsExtension
import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// Some Flutter plugins (e.g. receive_sharing_intent 1.8.x) ship Kotlin
// compiled at JVM 21, while their own Java compile task defaults to 1.8.
// This causes "Inconsistent JVM-target compatibility" build failures.
//
// `androidComponents.finalizeDsl` is the AGP-canonical hook: it fires DURING
// AGP's DSL finalization phase, after the plugin set its defaults but before
// Gradle locks the values — so we can safely override them here.
subprojects {
    pluginManager.withPlugin("com.android.library") {
        extensions.configure<LibraryAndroidComponentsExtension> {
            finalizeDsl { ext ->
                ext.compileOptions.sourceCompatibility = JavaVersion.VERSION_17
                ext.compileOptions.targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }
    pluginManager.withPlugin("com.android.application") {
        extensions.configure<ApplicationAndroidComponentsExtension> {
            finalizeDsl { ext ->
                ext.compileOptions.sourceCompatibility = JavaVersion.VERSION_17
                ext.compileOptions.targetCompatibility = JavaVersion.VERSION_17
            }
        }
    }
    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
