package com.temanlabs.ingatanku

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.graphics.BitmapFactory
import android.net.Uri
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Locale

/**
 * The pet on the home screen, looking the way it feels, with one button
 * for what to do about it:
 *
 *  - egg: save a first link to hatch it;
 *  - locked: snacking on notes until the daily quiz opens;
 *  - ready: hungry, today's quiz is waiting ("Feed it" opens the quiz);
 *  - late: still unfed in the evening, and sad about it;
 *  - full: today's quiz is done.
 *
 * Flutter (`HomeWidgetService`) writes the pet's state, every line in the
 * app's language and a still of each face. Which moment it is *now* is
 * worked out here, so the widget turns hungry at midnight and sad in the
 * evening without the app being opened (the system refreshes it about
 * every half hour).
 */
class PetWidget : AppWidgetProvider() {

    private enum class Moment(val face: String) {
        EGG("egg"), LOCKED("happy"), READY("hungry"), LATE("sad"), FULL("happy")
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (widgetId in appWidgetIds) {
            try {
                appWidgetManager.updateAppWidget(widgetId, render(context))
            } catch (e: Throwable) {
                // Never let onUpdate throw, or the launcher shows "Can't
                // load widget"; the layout's own picture and lines stay.
                android.util.Log.e("PetWidget", "onUpdate failed for id=$widgetId", e)
            }
        }
    }

    private fun render(context: Context): RemoteViews {
        val data = HomeWidgetPlugin.getData(context)
        val now = Calendar.getInstance()
        val today = day(now)
        val yesterday = day((now.clone() as Calendar).apply { add(Calendar.DAY_OF_YEAR, -1) })

        val moment = when {
            data.getString("pet.hatched", null) != "1" -> Moment.EGG
            data.getString("pet.unlocked", null) != "1" -> Moment.LOCKED
            data.getString("pet.mealDay", null) == today -> Moment.FULL
            now.get(Calendar.HOUR_OF_DAY) >= LATE_FROM_HOUR -> Moment.LATE
            else -> Moment.READY
        }
        val key = moment.name.lowercase(Locale.ROOT)
        val hungry = moment == Moment.READY || moment == Moment.LATE

        val views = RemoteViews(context.packageName, R.layout.widget_pet)
        data.getString("pet.t.${key}Title", null)?.let { views.setTextViewText(R.id.pet_title, it) }
        data.getString("pet.t.${key}Body", null)?.let { views.setTextViewText(R.id.pet_body, it) }
        data.getString(if (hungry) "pet.t.feed" else "pet.t.save", null)
            ?.let { views.setTextViewText(R.id.pet_cta, it) }

        // Until the app has drawn its faces, the layout's picture shows.
        data.getString("pet.img.${moment.face}", null)
            ?.let { BitmapFactory.decodeFile(it) }
            ?.let { views.setImageViewBitmap(R.id.pet_image, it) }

        // Its meal streak, while it was fed today or yesterday.
        val streak = data.getString("pet.t.streak", null)
        val alive = data.getString("pet.streakDay", null).let { it == today || it == yesterday }
        if (!streak.isNullOrEmpty() && alive && moment != Moment.EGG) {
            views.setViewVisibility(R.id.pet_streak, View.VISIBLE)
            views.setTextViewText(R.id.pet_streak, streak)
        } else {
            views.setViewVisibility(R.id.pet_streak, View.GONE)
        }

        views.setOnClickPendingIntent(R.id.pet_root, open(context, "ingatanku://home"))
        views.setOnClickPendingIntent(
            R.id.pet_cta,
            open(context, if (hungry) "ingatanku://quiz" else "ingatanku://home")
        )
        return views
    }

    private fun open(context: Context, uri: String) =
        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java, Uri.parse(uri))

    /** The day as the app writes it (`PetState.dayKey`), e.g. "2026-10-28". */
    private fun day(c: Calendar): String =
        SimpleDateFormat("yyyy-MM-dd", Locale.ROOT).format(c.time)

    private companion object {
        /** From this hour an unfed pet stops asking and starts moping. */
        const val LATE_FROM_HOUR = 18
    }
}
