package com.ares.soundwave

import android.content.ContentUris
import android.content.Context
import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.os.Build
import android.provider.MediaStore
import android.util.Size
import java.io.ByteArrayOutputStream

/** Lecture seule de la bibliothèque musicale via MediaStore. */
object MediaLibrary {

    fun queryTracks(context: Context): List<Map<String, Any?>> {
        val projection = mutableListOf(
            MediaStore.Audio.Media._ID,
            MediaStore.Audio.Media.DISPLAY_NAME,
            MediaStore.Audio.Media.TITLE,
            MediaStore.Audio.Media.ARTIST,
            MediaStore.Audio.Media.ALBUM,
            MediaStore.Audio.Media.DURATION,
            MediaStore.Audio.Media.SIZE,
            MediaStore.Audio.Media.DATE_ADDED,
            MediaStore.Audio.Media.DATE_MODIFIED,
            MediaStore.Audio.Media.DATA,
        )
        // Le genre n'est disponible directement qu'à partir d'Android 11
        if (Build.VERSION.SDK_INT >= 30) projection.add(MediaStore.Audio.Media.GENRE)

        val selection = "${MediaStore.Audio.Media.IS_MUSIC} != 0"
        val out = ArrayList<Map<String, Any?>>()

        context.contentResolver.query(
            MediaStore.Audio.Media.EXTERNAL_CONTENT_URI,
            projection.toTypedArray(),
            selection,
            null,
            null,
        )?.use { c ->
            val iId = c.getColumnIndexOrThrow(MediaStore.Audio.Media._ID)
            val iName = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DISPLAY_NAME)
            val iTitle = c.getColumnIndexOrThrow(MediaStore.Audio.Media.TITLE)
            val iArtist = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ARTIST)
            val iAlbum = c.getColumnIndexOrThrow(MediaStore.Audio.Media.ALBUM)
            val iDuration = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DURATION)
            val iSize = c.getColumnIndexOrThrow(MediaStore.Audio.Media.SIZE)
            val iAdded = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_ADDED)
            val iModified = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATE_MODIFIED)
            val iData = c.getColumnIndexOrThrow(MediaStore.Audio.Media.DATA)
            val iGenre = c.getColumnIndex(MediaStore.Audio.Media.GENRE)

            while (c.moveToNext()) {
                out.add(
                    hashMapOf(
                        "id" to c.getLong(iId),
                        "displayName" to (c.getString(iName) ?: ""),
                        "title" to c.getString(iTitle),
                        "artist" to c.getString(iArtist),
                        "album" to c.getString(iAlbum),
                        "genre" to (if (iGenre >= 0) c.getString(iGenre) else null),
                        "duration" to c.getLong(iDuration),
                        "size" to c.getLong(iSize),
                        "dateAdded" to c.getLong(iAdded),
                        "dateModified" to c.getLong(iModified),
                        "data" to (c.getString(iData) ?: ""),
                    )
                )
            }
        }
        return out
    }

    /** Pochette en JPEG, ou null si le morceau n'en a pas. */
    fun artwork(context: Context, id: Long, size: Int): ByteArray? {
        val uri = ContentUris.withAppendedId(MediaStore.Audio.Media.EXTERNAL_CONTENT_URI, id)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            return try {
                val bitmap = context.contentResolver.loadThumbnail(uri, Size(size, size), null)
                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.JPEG, 88, stream)
                stream.toByteArray()
            } catch (_: Throwable) {
                null
            }
        }

        val retriever = MediaMetadataRetriever()
        return try {
            retriever.setDataSource(context, uri)
            retriever.embeddedPicture
        } catch (_: Throwable) {
            null
        } finally {
            retriever.release()
        }
    }
}