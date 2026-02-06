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

    fun fixNamespace(p: Project) {
        val android = p.extensions.findByName("android")
        if (android != null) {
            try {
                val namespaceMethod = android.javaClass.getMethod("getNamespace")
                val currentNamespace = namespaceMethod.invoke(android)
                if (currentNamespace == null) {
                    val setNamespaceMethod = android.javaClass.getMethod("setNamespace", String::class.java)
                    val newNamespace = "com.deliverymaker.generated.${p.name.replace("-", "_")}"
                    setNamespaceMethod.invoke(android, newNamespace)
                    println("Injected namespace '$newNamespace' for project ${p.name}")
                }
            } catch (e: Exception) {
                // Ignore
            }
        }
    }

    if (project.state.executed) {
        fixNamespace(project)
    } else {
        project.afterEvaluate {
            fixNamespace(project)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
