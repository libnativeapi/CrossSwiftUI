package dev.swiftuiport.android.counter

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import dev.swiftuiport.android.SwiftUIComposeHost

class CounterActivity : ComponentActivity() {
    private lateinit var host: SwiftUIComposeHost

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        host = SwiftUIComposeHost(nativeCreate())
        setContent {
            MaterialTheme {
                Surface(Modifier.fillMaxSize()) {
                    host.Content(Modifier.windowInsetsPadding(WindowInsets.safeDrawing))
                }
            }
        }
    }

    override fun onDestroy() {
        host.close()
        super.onDestroy()
    }

    private external fun nativeCreate(): Long

    companion object {
        init {
            System.loadLibrary("AndroidCounter")
        }
    }
}
