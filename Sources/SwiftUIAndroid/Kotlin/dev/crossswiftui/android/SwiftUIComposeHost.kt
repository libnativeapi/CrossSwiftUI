package dev.crossswiftui.android

import android.graphics.Typeface
import android.os.Build
import android.os.Looper
import androidx.annotation.Keep
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Button
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clipToBounds
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.Layout
import androidx.compose.ui.layout.onSizeChanged
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.hideFromAccessibility
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.rememberTextMeasurer
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Constraints
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.IntSize
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import org.json.JSONArray
import org.json.JSONObject
import kotlin.math.roundToInt

/** Presents one Swift renderer inside a bounded Compose layout. */
@Keep
class SwiftUIComposeHost(private var handle: Long) : AutoCloseable {
    private var controls by mutableStateOf(emptyList<Control>())
    private var textMetrics: TextMetrics? = null

    init {
        requireMainThread()
        require(handle != 0L) { "Missing Swift renderer" }
    }

    @Composable
    fun Content(modifier: Modifier = Modifier) {
        var viewport by remember(this) { mutableStateOf(IntSize.Zero) }
        val measurer = rememberTextMeasurer()
        val density = LocalDensity.current
        val metrics = remember(measurer, density) { TextMetrics(measurer, density) }

        // Mount after Compose has measured the viewport, outside its measure/layout pass.
        LaunchedEffect(this, viewport, metrics) {
            if (handle != 0L && viewport.width > 0 && viewport.height > 0) {
                val invalidateMeasurements = textMetrics != metrics
                textMetrics = metrics
                update(nativeResize(
                    handle,
                    viewport.width / density.density.toDouble(),
                    viewport.height / density.density.toDouble(),
                    invalidateMeasurements,
                ))
            }
        }

        val snapshot = controls
        Layout(
            modifier = modifier.fillMaxSize().clipToBounds().onSizeChanged { viewport = it },
            content = {
                snapshot.forEach { control ->
                    key(control.id) { RenderControl(control, metrics) }
                }
            },
        ) { children, constraints ->
            val scale = density.density
            val placeables = children.mapIndexed { index, child ->
                val frame = snapshot[index]
                val width = (frame.width * scale).roundToInt().coerceAtLeast(0)
                val height = (frame.height * scale).roundToInt().coerceAtLeast(0)
                child.measure(Constraints.fitPrioritizingWidth(width, width, height, height))
            }
            layout(constraints.minWidth, constraints.minHeight) {
                placeables.forEachIndexed { index, child ->
                    val frame = snapshot[index]
                    // Swift has already resolved absolute coordinates for each control.
                    child.place((frame.x * scale).roundToInt(), (frame.y * scale).roundToInt())
                }
            }
        }
    }

    @Composable
    private fun RenderControl(control: Control, metrics: TextMetrics) {
        val modifier = Modifier.alpha(control.opacity).semantics {
            if (control.accessibilityLabel.isNotEmpty()) contentDescription = control.accessibilityLabel
            if (control.accessibilityHidden) hideFromAccessibility()
        }
        val style = control.font.style()

        if (control.button) {
            Button(
                onClick = { if (handle != 0L) update(nativeTap(handle, control.id)) },
                modifier = modifier,
                enabled = control.enabled,
                // Swift's button layout reserves 16 dp per horizontal edge.
                contentPadding = PaddingValues(horizontal = 12.dp),
            ) {
                Text(
                    control.text,
                    color = control.color,
                    style = style,
                    softWrap = false,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        } else {
            val lineHeight = if (control.lineSpacing == 0.0) style.lineHeight else with(metrics.density) {
                val naturalHeight = metrics.measurer.measure("M", style, softWrap = false).size.height.toDp()
                (naturalHeight + control.lineSpacing.dp).coerceAtLeast(0.dp).toSp()
            }
            Text(
                control.text,
                modifier,
                color = control.color,
                style = style,
                textAlign = control.alignment,
                lineHeight = lineHeight,
                softWrap = false,
            )
        }
    }

    private fun update(snapshot: String) {
        val nodes = JSONArray(snapshot)
        controls = List(nodes.length()) { Control(nodes.getJSONObject(it)) }
    }

    // Swift calls this during nativeResize/nativeTap. Coordinates return in logical points.
    private fun measureText(text: String, size: Double, family: String, weight: Int): Long {
        val metrics = checkNotNull(textMetrics)
        val style = ControlFont(size, family, weight).style()
        val measured = metrics.measurer.measure(text, style, softWrap = false).size
        val width = measured.width / metrics.density.density
        val height = measured.height / metrics.density.density
        return width.toRawBits().toLong().shl(32) or (height.toRawBits().toLong() and 0xffffffffL)
    }

    override fun close() {
        requireMainThread()
        val oldHandle = handle
        if (oldHandle == 0L) return
        handle = 0
        textMetrics = null
        nativeDestroy(oldHandle)
        controls = emptyList()
    }

    private fun requireMainThread() {
        check(Looper.myLooper() == Looper.getMainLooper()) { "SwiftUIComposeHost requires the UI thread" }
    }

    private data class TextMetrics(val measurer: TextMeasurer, val density: Density)

    private data class ControlFont(val size: Double, val family: String, val weight: Int) {
        fun style(): TextStyle {
            val fontWeight = weight.coerceIn(1, 1000)
            val fontFamily = when (family) {
                "Segoe UI", "sans-serif" -> FontFamily.SansSerif
                "Consolas", "monospace" -> FontFamily.Monospace
                "Georgia", "serif" -> FontFamily.Serif
                else -> {
                    val face = if (Build.VERSION.SDK_INT >= 28) {
                        Typeface.create(Typeface.create(family, Typeface.NORMAL), fontWeight, false)
                    } else {
                        Typeface.create(family, if (fontWeight >= 600) Typeface.BOLD else Typeface.NORMAL)
                    }
                    FontFamily(face)
                }
            }
            return TextStyle(fontSize = size.sp, fontFamily = fontFamily, fontWeight = FontWeight(fontWeight))
        }
    }

    private data class Control(
        val id: Long,
        val button: Boolean,
        val text: String,
        val x: Double,
        val y: Double,
        val width: Double,
        val height: Double,
        val font: ControlFont,
        val alignment: TextAlign,
        val lineSpacing: Double,
        val enabled: Boolean,
        val opacity: Float,
        val color: Color,
        val accessibilityLabel: String,
        val accessibilityHidden: Boolean,
    ) {
        constructor(node: JSONObject) : this(
            id = node.getLong("id"),
            button = node.getBoolean("button"),
            text = node.getString("text"),
            x = node.getDouble("x"),
            y = node.getDouble("y"),
            width = node.getDouble("width"),
            height = node.getDouble("height"),
            font = ControlFont(node.getDouble("fontSize"), node.getString("fontFamily"), node.getInt("fontWeight")),
            alignment = when (node.getString("alignment")) {
                "center" -> TextAlign.Center
                "trailing" -> TextAlign.End
                else -> TextAlign.Start
            },
            lineSpacing = node.getDouble("lineSpacing"),
            enabled = node.getBoolean("enabled"),
            opacity = node.getDouble("opacity").toFloat().coerceIn(0f, 1f),
            color = if (node.has("foreground")) Color(node.getLong("foreground").toInt()) else Color.Unspecified,
            accessibilityLabel = node.getString("accessibilityLabel"),
            accessibilityHidden = node.getBoolean("accessibilityHidden"),
        )
    }

    private external fun nativeResize(handle: Long, width: Double, height: Double, invalidateMeasurements: Boolean): String
    private external fun nativeTap(handle: Long, id: Long): String
    private external fun nativeDestroy(handle: Long)
}
