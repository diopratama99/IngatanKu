package com.temanlabs.ingatanku

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import org.json.JSONArray

/**
 * Homescreen widget that displays the user's three most recent notes.
 *
 * Data flow:
 *  - Flutter's `HomeWidgetService.pushRecentNotes(...)` writes a JSON
 *    payload (`recent_notes`) and a "HH.mm" timestamp (`updated_at`) into
 *    the home_widget shared prefs, then invokes `HomeWidget.updateWidget`.
 *  - The plugin calls back into [onUpdate] here, which inflates the layout
 *    and binds note rows / pending intents.
 *
 * Tap targets all use [HomeWidgetLaunchIntent] so the URI lands in the
 * Flutter side's `widgetClicked` stream:
 *  - tap on a row → `ingatanku://note?id=<noteId>`
 *  - tap on "Catat baru" pill → `ingatanku://capture`
 */
class RecentNotesWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            try {
                renderWidget(context, appWidgetManager, widgetId)
            } catch (e: Throwable) {
                // Defensive: never let onUpdate throw, otherwise the launcher
                // shows the system "Can't load widget" placeholder. Log and
                // push a minimal fallback RemoteViews so something still
                // renders while we debug from logcat.
                android.util.Log.e(
                    "RecentNotesWidget",
                    "onUpdate failed for id=$widgetId",
                    e
                )
                renderFallback(context, appWidgetManager, widgetId, e)
            }
        }
    }

    private fun renderFallback(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
        cause: Throwable
    ) {
        try {
            val views = RemoteViews(context.packageName, R.layout.widget_recent_notes)
            for (id in intArrayOf(R.id.widget_row_0, R.id.widget_row_1, R.id.widget_row_2)) {
                views.setViewVisibility(id, View.GONE)
            }
            for (id in intArrayOf(R.id.widget_divider_0, R.id.widget_divider_1)) {
                views.setViewVisibility(id, View.GONE)
            }
            views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
            views.setTextViewText(
                R.id.widget_empty,
                "Belum ada catatan."
            )
            manager.updateAppWidget(widgetId, views)
        } catch (_: Throwable) {
            // If even the fallback fails, swallow — anything we do here would
            // also throw and cascade into the system error UI.
        }
    }

    private fun renderWidget(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_recent_notes)
        val prefs = HomeWidgetPlugin.getData(context)

        val recentJson = prefs.getString("recent_notes", null)
        val updatedAt = prefs.getString("updated_at", null)

        // Decode the JSON payload from Flutter. Be permissive — if anything
        // is malformed, render the empty state instead of crashing.
        val notes = parseNotes(recentJson)

        val rowIds = intArrayOf(
            R.id.widget_row_0,
            R.id.widget_row_1,
            R.id.widget_row_2
        )
        val titleIds = intArrayOf(
            R.id.widget_title_0,
            R.id.widget_title_1,
            R.id.widget_title_2
        )
        val tagIds = intArrayOf(
            R.id.widget_tag_0,
            R.id.widget_tag_1,
            R.id.widget_tag_2
        )
        val dividerIds = intArrayOf(
            R.id.widget_divider_0,
            R.id.widget_divider_1
        )

        if (notes.isEmpty()) {
            // No notes — collapse all rows + dividers, show empty caption.
            for (i in 0..2) views.setViewVisibility(rowIds[i], View.GONE)
            for (id in dividerIds) views.setViewVisibility(id, View.GONE)
            views.setViewVisibility(R.id.widget_empty, View.VISIBLE)
        } else {
            views.setViewVisibility(R.id.widget_empty, View.GONE)
            for (i in 0..2) {
                if (i < notes.size) {
                    val note = notes[i]
                    views.setViewVisibility(rowIds[i], View.VISIBLE)
                    views.setTextViewText(titleIds[i], note.title)
                    if (note.tag.isEmpty()) {
                        views.setViewVisibility(tagIds[i], View.GONE)
                    } else {
                        views.setViewVisibility(tagIds[i], View.VISIBLE)
                        views.setTextViewText(tagIds[i], note.tag)
                    }
                    views.setOnClickPendingIntent(
                        rowIds[i],
                        HomeWidgetLaunchIntent.getActivity(
                            context,
                            MainActivity::class.java,
                            Uri.parse("ingatanku://note?id=${Uri.encode(note.id)}")
                        )
                    )
                } else {
                    views.setViewVisibility(rowIds[i], View.GONE)
                }
            }
            // Divider visibility tracks how many rows are populated.
            // 1 note → no dividers; 2 → one divider; 3 → two dividers.
            for (i in dividerIds.indices) {
                views.setViewVisibility(
                    dividerIds[i],
                    if (i < notes.size - 1) View.VISIBLE else View.GONE
                )
            }
        }

        // "Catat baru" capture pill → opens add-note page in the app.
        views.setOnClickPendingIntent(
            R.id.widget_capture,
            HomeWidgetLaunchIntent.getActivity(
                context,
                MainActivity::class.java,
                Uri.parse("ingatanku://capture")
            )
        )

        // Footer timestamp.
        if (updatedAt.isNullOrEmpty()) {
            views.setViewVisibility(R.id.widget_updated, View.GONE)
        } else {
            views.setViewVisibility(R.id.widget_updated, View.VISIBLE)
            views.setTextViewText(R.id.widget_updated, "diperbarui $updatedAt")
        }

        manager.updateAppWidget(widgetId, views)
    }

    private fun parseNotes(json: String?): List<NoteRow> {
        if (json.isNullOrEmpty()) return emptyList()
        return try {
            val arr = JSONArray(json)
            val out = mutableListOf<NoteRow>()
            for (i in 0 until arr.length()) {
                val o = arr.getJSONObject(i)
                out.add(
                    NoteRow(
                        id = o.optString("id"),
                        title = o.optString("title", "(tanpa judul)")
                            .ifEmpty { "(tanpa judul)" },
                        tag = o.optString("tag", "")
                    )
                )
            }
            out
        } catch (_: Exception) {
            emptyList()
        }
    }

    private data class NoteRow(
        val id: String,
        val title: String,
        val tag: String
    )
}
