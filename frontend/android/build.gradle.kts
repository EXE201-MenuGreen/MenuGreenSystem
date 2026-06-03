allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Windows: project ổ D:, Pub cache ổ C: → không redirect build của plugin sang frontend/build/.
// Chỉ :app dùng frontend/build/app để Flutter CLI tìm được APK.
subprojects {
    afterEvaluate {
        val projectPath = project.projectDir.canonicalPath.replace('\\', '/')
        when {
            project.name == "app" -> {
                val flutterAppBuild =
                    rootProject.layout.projectDirectory.dir("../build").dir("app")
                project.layout.buildDirectory.value(flutterAppBuild)
            }
            projectPath.contains("/Pub/Cache/") -> {
                project.layout.buildDirectory.value(
                    project.layout.projectDirectory.dir("build"),
                )
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
    delete(rootProject.layout.projectDirectory.dir("../build"))
}
