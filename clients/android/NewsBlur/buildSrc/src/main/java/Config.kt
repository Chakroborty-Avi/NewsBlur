import org.gradle.api.JavaVersion

object Config {

    const val compileSdk = 33
    const val minSdk = 23
    const val targetSdk = 33
    const val versionCode = 215
    const val versionName = "13.1.2"

    const val androidTestInstrumentation = "androidx.test.runner.AndroidJUnitRunner"

    val javaVersion = JavaVersion.VERSION_17
}