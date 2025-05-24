package com.flutter.gradle

class VersionUtils {
    companion object {
        @JvmStatic
        fun mostRecentSemanticVersion(version1: String?, version2: String?): String? {
            if (version1 == null) return version2
            if (version2 == null) return version1

            val v1Parts = version1.split('.')
            val v2Parts = version2.split('.')

            for (i in 0 until minOf(v1Parts.size, v2Parts.size)) {
                val v1Part = v1Parts[i].toIntOrNull() ?: 0
                val v2Part = v2Parts[i].toIntOrNull() ?: 0
                if (v1Part > v2Part) return version1
                if (v1Part < v2Part) return version2
            }

            return if (v1Parts.size >= v2Parts.size) version1 else version2
        }
    }
} 